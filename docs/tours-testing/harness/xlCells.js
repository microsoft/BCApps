// Reads cell addresses and values straight out of the OOXML sheet part.
// No spreadsheet library sits between the measurement and the verdict.
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const zlib = require('zlib');

function unzipEntry(file, entryName) {
  // Minimal zip reader: locate the local file header for entryName and inflate.
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

function colOf(addr) {
  const m = /^([A-Z]+)(\d+)$/.exec(addr);
  let n = 0;
  for (const ch of m[1]) n = n * 26 + (ch.charCodeAt(0) - 64);
  return { col: n, colLetters: m[1], row: parseInt(m[2], 10) };
}

function cells(file) {
  const xml = unzipEntry(file, 'xl/worksheets/sheet1.xml').toString('utf8');
  const out = [];
  const re = /<x:c r="([A-Z]+\d+)"[^>]*?(\/>|>([\s\S]*?)<\/x:c>)/g;
  let m;
  while ((m = re.exec(xml)) !== null) {
    const addr = m[1];
    const body = m[3] || '';
    let value = '';
    const is = /<x:is><x:t[^>]*>([\s\S]*?)<\/x:t><\/x:is>/.exec(body);
    const v = /<x:v>([\s\S]*?)<\/x:v>/.exec(body);
    if (is) value = is[1];
    else if (v) value = v[1];
    const { row, col } = colOf(addr);
    out.push({ addr, row, col, value });
  }
  return out;
}

function sheetName(file) {
  const xml = unzipEntry(file, 'xl/workbook.xml').toString('utf8');
  const m = /<x:sheet name="([^"]*)"/.exec(xml) || /name="([^"]*)"/.exec(xml);
  return m ? m[1] : '?';
}

function fmt(c) { return `${c.addr}=${JSON.stringify(c.value)}`; }

const [a, b] = process.argv.slice(2);
if (!b) {
  const A = cells(a);
  console.log(`${path.basename(a)}  sheet=${sheetName(a)}  cells=${A.length}`);
  let lastRow = 0;
  for (const c of A) {
    if (c.row !== lastRow) { process.stdout.write(`\nrow ${c.row}: `); lastRow = c.row; }
    process.stdout.write(fmt(c) + '  ');
  }
  console.log('');
} else {
  const A = cells(a), B = cells(b);
  const ma = new Map(A.map(x => [x.addr, x])), mb = new Map(B.map(x => [x.addr, x]));
  const onlyA = A.filter(x => !mb.has(x.addr));
  const onlyB = B.filter(x => !ma.has(x.addr));
  const diff = A.filter(x => mb.has(x.addr) && mb.get(x.addr).value !== x.value);
  console.log(`A = ${path.basename(a)}  cells=${A.length}  sheet=${sheetName(a)}`);
  console.log(`B = ${path.basename(b)}  cells=${B.length}  sheet=${sheetName(b)}`);
  console.log(`\nONLY IN A (${onlyA.length}):`); onlyA.forEach(x => console.log('  ' + fmt(x)));
  console.log(`\nONLY IN B (${onlyB.length}):`); onlyB.forEach(x => console.log('  ' + fmt(x)));
  console.log(`\nSAME ADDRESS DIFFERENT VALUE (${diff.length}):`);
  diff.forEach(x => console.log(`  ${x.addr}: A=${JSON.stringify(x.value)}  B=${JSON.stringify(mb.get(x.addr).value)}`));
}
