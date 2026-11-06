#!/usr/bin/env node
/* Cek sintaks semua modul ES di web/js tanpa browser.
   Node memperlakukan .js sebagai CommonJS secara default, jadi file disalin
   ke direktori temp dengan ekstensi .mjs lalu dijalankan `node --check`. */

const fs = require('fs');
const os = require('os');
const path = require('path');
const { execFileSync } = require('child_process');

const dir = path.join(__dirname, '..', 'web', 'js');
const files = fs.readdirSync(dir).filter((f) => f.endsWith('.js'));
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'bw-check-'));
let failed = 0;

for (const file of files) {
  const src = path.join(dir, file);
  const dst = path.join(tmp, file.replace(/\.js$/, '.mjs'));
  fs.copyFileSync(src, dst);
  try {
    execFileSync(process.execPath, ['--check', dst], { stdio: 'pipe' });
    console.log(`  ok   ${file}`);
  } catch (err) {
    failed++;
    console.error(`  FAIL ${file}`);
    console.error(String(err.stderr || err.message));
  }
}

fs.rmSync(tmp, { recursive: true, force: true });
console.log(failed ? `\n${failed} file gagal dicek` : `\nSemua ${files.length} modul lolos cek sintaks`);
process.exit(failed ? 1 : 0);
