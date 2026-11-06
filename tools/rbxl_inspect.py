#!/usr/bin/env python3
"""Minimal, dependency-light reader for Roblox binary place files (.rbxl).

This is NOT a general-purpose Roblox file library. It implements just enough of
the binary format (rbx-dom documentation) to answer questions we needed for the
web port:

  * which classes/instances exist and how they are named
  * the parent/child tree
  * the Luau source of Script / ModuleScript / LocalScript instances
    (stored as SharedString references into the SSTR chunk)

Usage:
    python3 tools/rbxl_inspect.py <file.rbxl>            # summary
    python3 tools/rbxl_inspect.py <file.rbxl> --dump out # write scripts/*.lua + tree.txt
"""
from __future__ import annotations

import argparse
import os
import struct
import sys
from dataclasses import dataclass, field
from typing import BinaryIO

try:
    import lz4.block
except ImportError:  # pragma: no cover
    lz4 = None


# --------------------------------------------------------------------------
# low level reader helpers
# --------------------------------------------------------------------------
class Reader:
    def __init__(self, data: bytes):
        self.d = data
        self.i = 0

    def bytes(self, n: int) -> bytes:
        b = self.d[self.i : self.i + n]
        if len(b) != n:
            raise EOFError(f"wanted {n} bytes at {self.i}, got {len(b)}")
        self.i += n
        return b

    def u8(self) -> int:
        return self.bytes(1)[0]

    def u32(self) -> int:
        return struct.unpack("<I", self.bytes(4))[0]

    def i32(self) -> int:
        return struct.unpack("<i", self.bytes(4))[0]

    def f32(self) -> float:
        return struct.unpack("<f", self.bytes(4))[0]

    def f64(self) -> float:
        return struct.unpack("<d", self.bytes(8))[0]

    def string(self) -> str:
        n = self.u32()
        return self.bytes(n).decode("utf-8", "replace")

    def interleaved(self, n: int, fmt: str) -> list:
        """Roblox stores typed arrays byte-plane interleaved:

        [value0.byte0, value1.byte0, ...][value0.byte1, value1.byte1, ...]...
        """
        size = struct.calcsize(fmt)
        raw = self.bytes(n * size)
        out = []
        for k in range(n):
            buf = bytes(raw[b * n + k] for b in range(size))
            out.append(struct.unpack(fmt, buf)[0])
        return out


def read_chunks(data: bytes):
    r = Reader(data)
    r.bytes(8)                       # "<roblox!"
    r.bytes(6)                       # signature bytes
    version = struct.unpack("<H", r.bytes(2))[0]
    classes = r.u32()
    instances = r.u32()
    r.bytes(8)                       # reserved
    chunks = []
    while r.i < len(data):
        name = data[r.i : r.i + 4].decode("latin1").rstrip("\x00")
        r.i += 4
        comp = r.u32()
        uncomp = r.u32()
        r.bytes(4)                   # reserved
        if name == "END":
            chunks.append((name, data[r.i : r.i + uncomp]))
            break
        payload = r.bytes(comp)
        if comp == 0 or uncomp == 0:
            chunks.append((name, b""))
            continue
        if comp != uncomp:
            if lz4 is None:
                raise RuntimeError("LZ4 compressed file; pip install lz4")
            payload = lz4.block.decompress(payload, uncompressed_size=uncomp)
        chunks.append((name, payload))
    return version, classes, instances, chunks


# --------------------------------------------------------------------------
# chunk parsers
# --------------------------------------------------------------------------
STRING, BOOL, INT32, FLOAT32, FLOAT64 = 0x01, 0x02, 0x03, 0x04, 0x05
UDIM, UDIM2, RAY, FACES, AXES, BRICKCOLOR, COLOR3, VECTOR2, VECTOR3 = range(0x06, 0x0F)
VECTOR2I16, CFrame, QUATERNION, ENUM, REF, VECTOR3I16 = range(0x0F, 0x15)
NUMBERSEQ, COLORSEQ, NUMBERRANGE, RECT, PHYSICALPROPS = range(0x15, 0x1A)
COLOR3UINT8, INT64, SHAREDSTRING, PROTECTEDSTRING = range(0x1A, 0x1E)


def parse_sstr(payload: bytes) -> list[str]:
    r = Reader(payload)
    out = []
    while r.i < len(payload):
        out.append(r.string())
    return out


@dataclass
class Instance:
    referent: int
    class_name: str
    name: str = ""
    parent: int = -1
    props: dict = field(default_factory=dict)

    def __repr__(self):
        return f"<{self.class_name} {self.name!r} #{self.referent}>"


def parse_inst(payload: bytes):
    r = Reader(payload)
    class_id = r.u32()
    class_name = r.string()
    fmt = r.u8()
    count = r.u32()
    refs = read_referent_array(r.bytes(count * 4), count)
    return class_id, class_name, fmt, refs


def untransform_int(x: int) -> int:
    """Roblox menyimpan Int32 dengan transformasi zig-zag."""
    return (x >> 1) if x % 2 == 0 else -((x + 1) // 2)


def read_referent_array(arr: bytes, count: int) -> list[int]:
    """Array Referent = Int32 big-endian, byte-interleaved, dan AKUMULATIF.

    Tanpa akumulasi nilainya terlihat seperti [682, 1, 1, 3, ...]; nilai
    sebenarnya adalah penjumlahan berjalan (prefix sum).
    """
    vals = []
    prev = 0
    for k in range(count):
        raw = (arr[k] << 24) | (arr[count + k] << 16) | (arr[2 * count + k] << 8) | arr[3 * count + k]
        delta = untransform_int(raw)
        prev = prev + delta
        vals.append(prev)
    return vals


def parse_prnt(payload: bytes):
    r = Reader(payload)
    r.u8()  # version
    count = r.u32()
    raw = r.bytes(count * 8)
    children = read_referent_array(raw[: count * 4], count)
    parents = read_referent_array(raw[count * 4 :], count)
    return list(zip(children, parents))


def parse_prop_strings(payload: bytes):
    """Return (class_id, prop_name, type_id, values) handling the simple types."""
    r = Reader(payload)
    class_id = r.u32()
    prop = r.string()
    type_id = r.u8()
    if type_id == STRING or type_id == PROTECTEDSTRING:
        # Strings are length prefixed. We cannot know the instance count here,
        # so read greedily until the buffer is exhausted.
        vals = []
        while r.i < len(payload):
            vals.append(r.string())
        return class_id, prop, type_id, vals
    if type_id == SHAREDSTRING:
        n = (len(payload) - r.i) // 4
        vals = r.interleaved(n, "<I")
        return class_id, prop, type_id, vals
    if type_id == BOOL:
        return class_id, prop, type_id, list(payload[r.i :])
    if type_id == INT32:
        n = (len(payload) - r.i) // 4
        return class_id, prop, type_id, r.interleaved(n, "<i")
    if type_id == ENUM:
        n = (len(payload) - r.i) // 4
        return class_id, prop, type_id, r.interleaved(n, "<I")
    if type_id == INT64:
        n = (len(payload) - r.i) // 8
        return class_id, prop, type_id, r.interleaved(n, "<q")
    return class_id, prop, type_id, None


# --------------------------------------------------------------------------
# place model
# --------------------------------------------------------------------------
class Place:
    def __init__(self, path: str):
        with open(path, "rb") as fh:
            data = fh.read()
        self.version, nclasses, ninstances, chunks = read_chunks(data)
        self.sstr: list[str] = []
        self.classes: dict[int, tuple[str, list[int]]] = {}
        self.instances: dict[int, Instance] = {}
        self.name_props: dict[int, dict[int, str]] = {}
        self.source_props: dict[int, dict[int, str]] = {}
        for name, payload in chunks:
            if name == "SSTR":
                # Some newer writers compress this chunk differently; string
                # properties we care about are stored inline, so treat it as
                # best-effort only.
                try:
                    self.sstr = parse_sstr(payload)
                except Exception:
                    self.sstr = []
            elif name == "INST":
                try:
                    cid, cname, fmt, refs = parse_inst(payload)
                except Exception:
                    continue
                self.classes[cid] = (cname, refs)
                for ref in refs:
                    self.instances[ref] = Instance(ref, cname)
            elif name == "PRNT":
                for child, parent in parse_prnt(payload):
                    if child in self.instances:
                        self.instances[child].parent = parent
            elif name == "PROP":
                try:
                    cid, prop, tid, vals = parse_prop_strings(payload)
                except Exception:
                    continue
                if cid not in self.classes or vals is None:
                    continue
                refs = self.classes[cid][1]
                if len(vals) < len(refs):
                    continue
                for ref, val in zip(refs, vals):
                    inst = self.instances.get(ref)
                    if inst is None:
                        continue
                    inst.props[prop] = val
                    if prop == "Name" and isinstance(val, str):
                        inst.name = val
                    if prop == "Source" and isinstance(val, int):
                        if 0 <= val < len(self.sstr):
                            self.source_props.setdefault(ref, {})["Source"] = self.sstr[val]
                    elif prop == "Source" and isinstance(val, str):
                        self.source_props.setdefault(ref, {})["Source"] = val

    # -- helpers ---------------------------------------------------------
    def roots(self) -> list[Instance]:
        """Place file tidak punya instance DataModel, jadi setiap service
        (parent = -1) adalah root."""
        return sorted(
            (i for i in self.instances.values()
             if i.parent < 0 or i.parent not in self.instances),
            key=lambda i: (i.class_name, i.name),
        )

    def root(self) -> Instance | None:
        roots = self.roots()
        for r in roots:
            if r.class_name == "Workspace":
                return r
        return roots[0] if roots else None

    def children(self, ref: int) -> list[Instance]:
        return sorted(
            (i for i in self.instances.values() if i.parent == ref),
            key=lambda i: (i.class_name, i.name),
        )

    def path_of(self, inst: Instance) -> str:
        parts = []
        cur = inst
        seen = set()
        while cur is not None and cur.referent not in seen:
            seen.add(cur.referent)
            parts.append(cur.name or cur.class_name)
            cur = self.instances.get(cur.parent)
        return "/".join(reversed(parts))

    def walk(self, ref: int | None = None, depth: int = 0):
        insts = self.roots() if ref is None else self.children(ref)
        for inst in insts:
            if inst is None:
                continue
            yield depth, inst
            yield from self.walk(inst.referent, depth + 1)

    def scripts(self):
        for inst in self.instances.values():
            src = self.source_props.get(inst.referent, {}).get("Source")
            if src:
                yield inst, src


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument("file")
    ap.add_argument("--dump", help="directory to write tree.txt and scripts/")
    ap.add_argument("--max-depth", type=int, default=3)
    args = ap.parse_args(argv)

    place = Place(args.file)
    counts: dict[str, int] = {}
    for inst in place.instances.values():
        counts[inst.class_name] = counts.get(inst.class_name, 0) + 1

    print(f"file        : {os.path.basename(args.file)}")
    print(f"format ver  : {place.version}")
    print(f"instances   : {len(place.instances)}")
    print(f"sharedstr   : {len(place.sstr)}")
    print("classes     : " + ", ".join(f"{k}×{v}" for k, v in sorted(counts.items(), key=lambda kv: -kv[1])[:24]))
    print()

    root = place.root()
    if root is not None:
        for depth, inst in place.walk():
            if depth <= args.max_depth:
                print("  " * depth + f"{inst.class_name}  [{inst.name}]")

    total = 0
    for inst, src in place.scripts():
        total += len(src)
    print(f"\nscripts     : {sum(1 for _ in place.scripts())} ({total:,} chars)")

    if args.dump:
        os.makedirs(os.path.join(args.dump, "scripts"), exist_ok=True)
        with open(os.path.join(args.dump, "tree.txt"), "w", encoding="utf-8") as fh:
            for depth, inst in place.walk():
                fh.write(
                    "  " * depth
                    + f"{inst.class_name}  {inst.name!r}  props={sorted(inst.props)[:12]}\n"
                )
        for n, (inst, src) in enumerate(sorted(place.scripts(), key=lambda p: p[0].name)):
            safe = "".join(c if c.isalnum() or c in "._-" else "_" for c in inst.name)[:60]
            fname = f"{n:03d}_{inst.class_name}_{safe}.lua"
            with open(os.path.join(args.dump, "scripts", fname), "w", encoding="utf-8") as fh:
                fh.write(f"-- {place.path_of(inst)}\n" + src)
        print(f"wrote dump to {args.dump}")


if __name__ == "__main__":
    main(sys.argv[1:])
