// Offset-tolerant comparison: are the same ROW TUPLES present in both workbooks,
// and is every value still under the same COLUMN?  A count delta cannot tell a
// correct skip from a dropped cell (tours 5.5), so compare by identity.
const { execFileSync } = require('child_process');
const path = require('path');
const fs = require('fs');
const zlib = require('zlib');

function unzipEntry(file, entryName) {
  const buf = fs.readFileSync(file);
  const eocd = buf.lastIndexOf(Buffer.from([0x50, 0x4b, 0x05, 0x06]));
  const cdOffset = buf.readUInt32LE(eocd + 16);
  const cdCount = buf.readUInt16LE(eocd + 10);
  let p = cdOffset;
  for (let i = 0; i < cdCount; i++) {
    const nameLen = buf.readUInt16LE(p + 28);
    const extraLen = buf.readUInt16LE(p + 30);
    const commentLen = buf.readUInt16LE(p + 32);
    const localOff = buf.readUInt32LE(p + 42);
    const name = buf.slice(p + 46, p + 46 + nameLen).toString('utf8');
    const method = buf.readUInt16LE(p + 10);
    const compSize = buf.readUInt32LE(p + 20);
    if (name === entryName) {
      const lNameLen = buf.readUInt16LE(localOff + 26);
      const lExtraLen = buf.readUInt16LE(localOff + 28);
      const dataStart = localOff + 30 + lNameLen + lExtraLen;
      const data = buf.slice(dataStart, dataStart + compSize);
      return method === 0 ? data : zlib.inflateRawSync(data);
    }
    p += 46 + nameLen + extraLen + commentLen;
  }
  throw new Error(`entry not found: ${entryName}`);
}

function rows(file) {
  const xml = unzipEntry(file, 'xl/worksheets/sheet1.xml').toString('utf8');
  const map = new Map();
  const re = /<x:c r="([A-Z]+)(\d+)"[^>]*?(\/>|>([\s\S]*?)<\/x:c>)/g;
  let m;
  while ((m = re.exec(xml)) !== null) {
    const colLetters = m[1], r = parseInt(m[2], 10), body = m[4] || '';
    let value = '';
    const is = /<x:is><x:t[^>]*>([\s\S]*?)<\/x:t><\/x:is>/.exec(body);
    const v = /<x:v>([\s\S]*?)<\/x:v>/.exec(body);
    if (is) value = is[1]; else if (v) value = v[1];
    if (!map.has(r)) map.set(r, {});
    map.get(r)[colLetters] = value;
  }
  return [...map.entries()].sort((a, b) => a[0] - b[0]);
}

// A row tuple keyed by column letter, so a value that moved to another COLUMN
// produces a mismatch even when the row number changed.
const sig = o => JSON.stringify(Object.keys(o).sort().map(k => [k, o[k]]));

const [a, b] = process.argv.slice(2);
const A = rows(a), B = rows(b);
const bagA = new Map(), bagB = new Map();
for (const [r, o] of A) { const s = sig(o); bagA.set(s, (bagA.get(s) || 0) + 1); }
for (const [r, o] of B) { const s = sig(o); bagB.set(s, (bagB.get(s) || 0) + 1); }

const missing = [], added = [];
for (const [s, n] of bagA) { const d = n - (bagB.get(s) || 0); if (d > 0) missing.push([s, d]); }
for (const [s, n] of bagB) { const d = n - (bagA.get(s) || 0); if (d > 0) added.push([s, d]); }

console.log(`A = ${path.basename(a)}  rows=${A.length}`);
console.log(`B = ${path.basename(b)}  rows=${B.length}`);
console.log(`\nROW TUPLES PRESENT IN A BUT NOT B (${missing.length}):`);
missing.forEach(([s, n]) => console.log(`  x${n}  ${s}`));
console.log(`\nROW TUPLES PRESENT IN B BUT NOT A (${added.length}):`);
added.forEach(([s, n]) => console.log(`  x${n}  ${s}`));
if (!missing.length && !added.length) console.log('\n==> IDENTICAL ROW CONTENT (column-for-column); only row numbering may differ.');
