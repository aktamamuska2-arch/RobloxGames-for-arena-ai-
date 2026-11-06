/* Menyediakan resolusi bare-import "three" untuk Node (dipakai tes saja).
   Browser memakai import map di web/index.html, jadi tidak butuh node_modules. */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const rootDir = path.join(path.dirname(fileURLToPath(import.meta.url)), '..');
const threeDir = path.join(rootDir, 'node_modules', 'three');

export function ensureVendor() {
  if (fs.existsSync(path.join(threeDir, 'three.module.js'))) return;
  fs.mkdirSync(threeDir, { recursive: true });
  fs.writeFileSync(
    path.join(threeDir, 'package.json'),
    JSON.stringify({ name: 'three', version: '0.169.0', type: 'module', main: 'three.module.js', exports: './three.module.js' }, null, 2)
  );
  fs.copyFileSync(path.join(rootDir, 'web', 'vendor', 'three.module.js'), path.join(threeDir, 'three.module.js'));
}

ensureVendor();
