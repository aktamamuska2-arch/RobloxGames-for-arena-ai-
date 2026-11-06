#!/usr/bin/env node
/* =========================================================================
   server.js — static dev server untuk game web.
   Tanpa dependency: hanya modul `http`, `fs`, `path` bawaan Node.

   Jalankan:
     node server.js            → http://localhost:8080
     PORT=3000 node server.js  → port lain

   Server bind ke 0.0.0.0 supaya bisa diakses dari preview/browser lain,
   dan tidak memeriksa header Host (aman untuk reverse proxy / iframe).
   ========================================================================= */

const http = require('http');
const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, 'web');
const PORT = Number(process.env.PORT || 8080);
const HOST = process.env.HOST || '0.0.0.0';

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.woff2': 'font/woff2',
  '.txt': 'text/plain; charset=utf-8',
  '.map': 'application/json; charset=utf-8',
};

function send(res, status, body, headers = {}) {
  res.writeHead(status, {
    'Cache-Control': 'no-store',
    'X-Content-Type-Options': 'nosniff',
    ...headers,
  });
  res.end(body);
}

const server = http.createServer((req, res) => {
  let urlPath;
  try {
    urlPath = decodeURIComponent(new URL(req.url, 'http://local').pathname);
  } catch {
    return send(res, 400, 'Bad request');
  }

  if (urlPath === '/health') {
    return send(res, 200, JSON.stringify({ ok: true, uptime: process.uptime() }), {
      'Content-Type': 'application/json',
    });
  }

  if (urlPath === '/') urlPath = '/index.html';

  // cegah path traversal
  const filePath = path.join(ROOT, path.normalize(urlPath).replace(/^(\.\.[/\\])+/, ''));
  if (!filePath.startsWith(ROOT)) return send(res, 403, 'Forbidden');

  fs.stat(filePath, (err, stat) => {
    if (err || !stat.isFile()) {
      // fallback ke index.html (SPA)
      const index = path.join(ROOT, 'index.html');
      return fs.readFile(index, (e2, data) => {
        if (e2) return send(res, 404, 'Not found');
        send(res, 200, data, { 'Content-Type': MIME['.html'] });
      });
    }
    const ext = path.extname(filePath).toLowerCase();
    const type = MIME[ext] || 'application/octet-stream';
    res.writeHead(200, {
      'Content-Type': type,
      'Cache-Control': 'no-store',
      'X-Content-Type-Options': 'nosniff',
    });
    fs.createReadStream(filePath).pipe(res);
  });
});

server.listen(PORT, HOST, () => {
  console.log(`\n  BROKEN. web port`);
  console.log(`  ➜  http://localhost:${PORT}`);
  console.log(`  ➜  http://${HOST}:${PORT} (bind)\n`);
});
