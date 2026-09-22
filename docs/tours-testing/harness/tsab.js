// Transfer Order Saboteur tour - probes the THIRD document framework.
//
// Charter: a released transfer order should refuse edits to fields that affect what ships.
// Which fields actually refuse, and does the refusal match Sales/Purchase?
//
// Static grounding (Find-UnguardedFields.ps1 + Find-TourDrift.ps1):
//   Posting Date          unguarded on Sales, Purchase AND Transfer -> symmetric, probe it
//   Shipment Method Code  GUARDED on Sales(27)+Purchase(27), UNGUARDED on Transfer(37) -> drift
//   Transfer-from Code    guarded -> NEGATIVE CONTROL, must be refused
//   External Document No. deliberate Status::Released branch -> intended, NOT probed
//
// Controls are not optional. Without the open-order control a refusal is indistinguishable from
// "my automation never typed anything", and without the guarded-field control a persisted edit is
// indistinguishable from "the page is simply read-only".
//
//   node tsab.js t0            page shape
//   node tsab.js t1            control: OPEN order 1001, all three fields must persist
//   node tsab.js t2            subject: RELEASED order 1004
const { launch, signIn, appFrame, fieldOne, readError, BASE } = require('./bc.js');

const OPEN_ORDER = '1001';
const RELEASED_ORDER = '1004';

// Locate a header/line field.
//
// LOCATOR NOTE (cost several probes): on page 5740 every input has aria-label="" and there is
// no data-control-name anywhere - the field name is carried by aria-labelledby. Worse, the
// lookup and date fields render as role=combobox, NOT role=textbox, so getByRole('textbox')
// finds none of them. bc.js `field`/`fieldOne` now use getByLabel, which handles both.
function ctrl(frame, name) {
  return fieldOne(frame, name);
}

// FastTabs collapse by default and their fields are ABSENT FROM THE DOM until expanded, so an
// unexpanded card looks like it is missing most of its fields.
//
// On 5740 the FastTabs are role=button with aria-expanded, captioned General / Lines / Shipment
// / Transfer-from / Transfer-to / Warehouse / Foreign Trade. Do NOT click every
// [aria-expanded="false"]: that also hits nav menus and column headers, each of which re-renders
// the page - a blanket version ran for 8+ minutes without finishing.
const FASTTABS = ['Shipment', 'Transfer-from', 'Transfer-to', 'Warehouse', 'Foreign Trade', 'General'];

async function expandAll(page, frame) {
  for (const cap of FASTTABS) {
    const b = frame.getByRole('button', { name: cap, exact: true });
    if (!(await b.count().catch(() => 0))) continue;
    if ((await b.first().getAttribute('aria-expanded').catch(() => null)) === 'false') {
      await b.first().click({ timeout: 5000 }).catch(() => {});
      await page.waitForTimeout(700);
    }
  }
  // Even an EXPANDED FastTab shows only its promoted fields. The rest (AL Importance =
  // Additional) sit behind a per-FastTab 'Show more' link and are absent from the DOM until
  // it is clicked. On 5740, 'Transfer-from Code' and 'Shipment Method Code' are both hidden
  // this way - without this step they look like they are not on the page at all.
  //
  // Click them ONE AT A TIME, re-querying every pass: each click re-renders the FastTab and
  // turns that link into 'Show less', so a cached nth() list goes stale after the first click
  // and only the first FastTab ever expands.
  for (let i = 0; i < 12; i++) {
    const more = frame.getByText(/^Show more$/i).first();
    if (!(await more.count().catch(() => 0))) break;
    await more.scrollIntoViewIfNeeded().catch(() => {});
    await more.click({ timeout: 4000 }).catch(() => {});
    await page.waitForTimeout(900);
  }
  await page.waitForTimeout(1500);
}

// Open one transfer order.
//
// RECIPE (established by trial - the obvious routes all fail on this page):
//   * `?page=5740&filter=...`   -> ignored, lands on Home
//   * `?page=5740&bookmark=...` -> lands on an empty card (8 blank textboxes)
//   * list 5742 has NO 'Edit' ribbon action, and clicking a cell only SELECTS the row
//   * select the row, then press ENTER -> the card opens
// Locate the row by text, never by index: list order is not stable.
async function openOrder(page, no) {
  await page.goto(`${BASE}?page=5742`, { waitUntil: 'domcontentloaded', timeout: 120000 });
  let frame = await appFrame(page);
  await page.waitForTimeout(6000);

  const row = frame.getByRole('row').filter({ hasText: no }).first();
  if (!(await row.count().catch(() => 0))) throw new Error(`transfer order ${no} not in list 5742`);
  await row.getByRole('gridcell').first().click();
  await page.waitForTimeout(1500);
  await page.keyboard.press('Enter');
  await page.waitForTimeout(8000);

  frame = await appFrame(page);
  if (!/page=5740/.test(page.url())) throw new Error(`card 5740 did not open for ${no}: ${page.url()}`);
  await expandAll(page, frame);
  return frame;
}

async function caption(frame) {
  for (const sel of ['[class*="caption" i]', 'h1', '[role="heading"]']) {
    const t = await frame.locator(sel).first().innerText().catch(() => '');
    if (t && t.trim()) return t.replace(/\s+/g, ' ').trim().slice(0, 80);
  }
  return '<unknown>';
}

// Type into a header field and report what BC said. Tab commits the value in BC.
async function trySet(page, frame, name, value) {
  const f = await ctrl(frame, name);
  if (!f) return { field: name, status: 'NOT-ON-PAGE' };

  const editable = await f.isEditable().catch(() => false);
  const before = await f.inputValue().catch(() => '');
  if (!editable) return { field: name, status: 'READ-ONLY', before, after: before };

  await f.click().catch(() => {});
  await f.fill(value).catch(() => {});
  await page.keyboard.press('Tab');
  await page.waitForTimeout(2500);

  const err = await readError(frame);
  let after = '';
  const again = await ctrl(frame, name);
  try { after = again ? await again.inputValue() : '<gone>'; } catch { after = '<gone>'; }

  return {
    field: name,
    status: err.message ? 'REFUSED' : (after === before ? 'REVERTED' : 'ACCEPTED'),
    before, after,
    error: err.message || '',
    dialogs: err.dialogs.length,
  };
}

const PROBES = [
  // name,                  value,       expectation from static analysis
  ['Posting Date', '02/15/28', 'NO table guard AND no page Editable guard -> expect ACCEPTED'],
  ['Shipment Date', '02/20/28', 'page Editable=(Status=Open) -> expect READ-ONLY/absent'],
  ['Shipment Method Code', 'PICKUP', 'page Editable=(Status=Open), table unguarded -> READ-ONLY in UI'],
  ['In-Transit Code', 'OUT. LOG.', 'page Enabled=(Status=Open) -> expect READ-ONLY'],
  ['Transfer-from Code', 'GREEN', 'page Editable=(Status=Open) -> expect READ-ONLY/absent'],
];

(async () => {
  const probe = process.argv[2] || 't0';
  const { browser, page } = await launch({ headless: true });
  try {
    await signIn(page);

    if (probe === 't0') {
      const frame = await openOrder(page, RELEASED_ORDER);
      console.log('url:', page.url().slice(0, 120));
      // aria-label sits on the input for most fields but is "(Blank)" for some; fall back to
      // the enclosing labelled container.
      const rows = await frame.evaluate(() => {
        const out = [];
        for (const el of document.querySelectorAll('input')) {
          if (el.type === 'checkbox' || el.type === 'search' || el.type === 'hidden') continue;
          const name = (el.getAttribute('aria-labelledby') || '').split(/\s+/).filter(Boolean)
            .map(i => document.getElementById(i)?.innerText?.trim()).filter(Boolean).join(' ')
            || el.getAttribute('aria-label') || '';
          out.push({ name: name.replace(/\s+/g, ' ').trim(), value: el.value, ro: el.disabled || el.readOnly });
        }
        return out;
      });
      console.log(`\n${rows.length} data inputs on the card:`);
      for (const r of rows) {
        if (!r.name) continue;
        console.log(`  ${r.ro ? 'ro' : 'RW'}  ${r.name.slice(0, 32).padEnd(32)} = ${JSON.stringify(r.value).slice(0, 30)}`);
      }
      // FastTab state - a collapsed tab hides its fields from the DOM entirely.
      for (const cap of FASTTABS) {
        const b = frame.getByRole('button', { name: cap, exact: true });
        if (await b.count().catch(() => 0)) {
          console.log(`  fasttab ${cap.padEnd(16)} expanded=${await b.first().getAttribute('aria-expanded').catch(() => '?')}`);
        } else console.log(`  fasttab ${cap.padEnd(16)} NOT FOUND`);
      }
      await page.screenshot({ path: 'tsab-t0-card.png', fullPage: true });
      console.log('\nscreenshot: tsab-t0-card.png');
      return;
    }

    const no = probe === 't1' ? OPEN_ORDER : RELEASED_ORDER;
    const kind = probe === 't1' ? 'CONTROL (Open)' : 'SUBJECT (Released)';
    const frame = await openOrder(page, no);
    console.log(`\n=== ${kind} - transfer order ${no} ===`);
    console.log('caption:', await caption(frame), '\n');

    for (const [name, value, why] of PROBES) {
      const r = await trySet(page, frame, name, value);
      console.log(`${r.status.padEnd(11)} ${name.padEnd(22)} ${JSON.stringify(r.before || '')} -> ${JSON.stringify(r.after || '')}`);
      if (r.error) console.log(`            error: ${r.error.slice(0, 150)}`);
      console.log(`            expected: ${why}`);
      // A dialog left open blocks the next probe; clear it deliberately, never blanket-Escape
      // on a freshly created record.
      if (r.dialogs) { await page.keyboard.press('Escape'); await page.waitForTimeout(1200); }
    }

    console.log('\nNow read the values back with SQL - the page is not the oracle.');
  } catch (e) {
    console.error('FAILED:', e.message);
    await page.screenshot({ path: `tsab-${probe}-fail.png` }).catch(() => {});
  } finally {
    await browser.close();
  }
})();
