// parseDs.js — summarise a report 400 dataset XML by entry-number identity.
// BC writes columns as <Column name="X">v</Column> inside nested <DataItem> blocks.
// Usage: node parseDs.js <file.xml>
const fs = require('fs');
const raw = fs.readFileSync(process.argv[2], 'utf8').replace(/^\uFEFF/, '');

function cols(block) {
    const o = {};
    for (const m of block.matchAll(/<Column name="([^"]+)"[^>]*>([\s\S]*?)<\/Column>/g)) o[m[1]] = m[2];
    return o;
}

const headerBlocks = [...raw.matchAll(/<DataItem [^>]*name="Vendor_Ledger_Entry"[^>]*>/g)];
console.log('advice sections (payment VLEs):', headerBlocks.length);
for (const m of raw.matchAll(/<Column name="EntryNo_VendLedgEntry">([^<]*)<\/Column>/g))
    console.log('  header payment entry no:', m[1]);

const lines = [...raw.matchAll(/<DataItem name="VendLedgEntry2"[^>]*>([\s\S]*?)<DataItems ?\/?>/g)]
    .map(m => cols(m[1]));
const totals = [...raw.matchAll(/<DataItem name="Integer"[^>]*>\s*<Columns>([\s\S]*?)<\/Columns>/g)]
    .map(m => cols(m[1]));
const subs = [...raw.matchAll(/<DataItem name="Detailed_Vendor_Ledg__Entry"[^>]*>([\s\S]*?)<DataItems ?\/?>/g)]
    .map(m => cols(m[1]));

console.log('\nLINE ROWS (VendLedgEntry2)');
let sumL = 0, sumNeg = 0;
for (const l of lines) {
    const la = parseFloat(l.LAmountWDiscCur || '0');
    const neg = parseFloat(l.NegAmount_VendLedgEntry2 || '0');
    sumL += la; sumNeg += neg;
    console.log(`  entry ${String(l.EntryNo_VendLedgEntry2).padEnd(6)} ${String(l.DocType_VendLedgEntry2).padEnd(12)}` +
        ` extdoc=${String(l.ExtDocNo_VendLedgEntry2).padEnd(10)}` +
        ` curr=${String(l.CurrCode_VendLedgEntry2).padEnd(5)}` +
        ` LAmountWDiscCur=${String(la).padStart(11)}` +
        ` NegAmount=${String(neg).padStart(11)}` +
        ` RemAmt=${String(l.RemAmt_VendLedgEntry2).padStart(10)}` +
        ` LineDisc=${l.LineDiscount_VendLedgEntry2}`);
}
if (subs.length) {
    console.log('\nCREDIT-MEMO SUB-LINES (Detailed Vendor Ledg. Entry)');
    for (const s of subs) console.log('  ', JSON.stringify(s));
}
console.log('\nTOTAL rows (Integer dataitem):');
for (const t of totals) console.log(`   Amount_VendLedgEntry=${t.Amount_VendLedgEntry}  curr=${t.CurrCode_VendLedgEntry}`);

console.log('\nRECONCILIATION');
console.log('  sum(LAmountWDiscCur)         =', sumL.toFixed(2));
console.log('  sum(NegAmount_VendLedgEntry2) =', sumNeg.toFixed(2));
console.log('  printed total(s)             =', totals.map(t => t.Amount_VendLedgEntry).join(', '));
