// Saboteur tour on PURCHASE Orders - the mirror of sab.js (Sales).
//
// Purpose is generalisation, not novelty. Sales gave us:
//   SAB-1  Release tooltip states an absolute that is untrue (External Document No.
//          remains editable on a released order, by explicit design).
//   SAB-3  WITHDRAWN - the released lines grid accepts typing. Source now explains it:
//          SalesLinesEditable()/PurchaseLinesEditable() key off whether a PARTY is
//          selected, NOT off Status. The guard is TestStatusOpen() in the TABLE.
//
// Static differential (SalesHeader vs PurchaseHeader, TestStatusOpen per field):
//   Sales guards 30/183 fields, Purchase guards 20/166.
//   Genuine divergences on analogous fields:
//     Assigned User ID     Sales=guarded  Purchase=UNGUARDED  (and it IS on page 50)
//     VAT Base Discount %  Sales=guarded  Purchase=UNGUARDED  (not on page 50; API only)
//   Vendor Invoice No. is unguarded in Purchase, matching Sales External Document No.
//
// Page 50 = Purchase Order card, 9307 = Purchase Order List.
//
// Usage: node psab.js <probeId>
const {
  BASE, signIn, appFrame, openPage, field, newDocument,
  lineCell, readError, dismissDialog, launch,
} = require('./bc');

const probeId = process.argv[2];
const log = (...a) => console.log(...a);

const VENDOR = '01254796';
const ITEM = '1896-S';

function vendorNameBox(frame) {
  return frame.getByRole('combobox', { name: 'Vendor Name' })
    .or(frame.getByRole('textbox', { name: 'Vendor Name' }).and(frame.locator('input')));
}

async function orderWithLine(page, qty = '1') {
  let frame = await newDocument(page, 9307, 50);
  await vendorNameBox(frame).first().waitFor({ state: 'visible', timeout: 60000 });
  await vendorNameBox(frame).first().click();
  await page.keyboard.type(VENDOR, { delay: 50 });
  await page.keyboard.press('Tab');
  await page.waitForTimeout(7000);
  frame = await appFrame(page);
  // NB: do NOT dismissDialog here. Escape on a freshly created card navigates away,
  // which silently destroys the document and makes every later probe read "nothing
  // to show in this view". That mistake produced a full run of fake negatives.

  const cell = await lineCell(frame, 1);
  await cell('No.');
  await page.keyboard.type(ITEM, { delay: 50 });
  await page.keyboard.press('Enter');
  await page.waitForTimeout(6000);
  await cell('Quantity');
  await page.keyboard.type(qty, { delay: 50 });
  await page.keyboard.press('Enter');
  await page.waitForTimeout(5000);
  return { frame: await appFrame(page), cell };
}

// Page 50 shows no editable "No." field - the document number lives only in the page
// caption ("106027 - Progressive Home Furnishings"). Reading field('No.') returns the
// LINE's No. or nothing, so parse the heading instead.
async function docNo(frame) {
  const txt = await frame.locator('[class*="caption"], h1, [role="heading"]')
    .allInnerTexts().catch(() => []);
  for (const t of txt) {
    const m = String(t).match(/\b(10\d{4})\b/);
    if (m) return m[1];
  }
  return '<unknown>';
}

// One-off: report what the purchase lines grid actually offers, so probes target
// columns that exist rather than the Sales column names.
async function dumpColumns(frame) {
  const { linesGrid } = require('./bc');
  const lg = await linesGrid(frame);
  const heads = await lg.getByRole('columnheader').allInnerTexts().catch(() => []);
  return heads.map(h => h.replace(/\s+/g, ' ').trim()).filter(Boolean);
}

async function release(page, frame) {
  await page.keyboard.press('Control+F9');
  await page.waitForTimeout(7000);
  const err = await readError(frame);
  await dismissDialog(page, frame);
  return err;
}

async function tryCell(page, frame, cell, header, value) {
  let target;
  try { target = await cell(header); }
  catch (e) { return { skipped: e.message.slice(0, 90) }; }
  await page.keyboard.press('Control+a');
  await page.keyboard.type(value, { delay: 15 });
  await page.keyboard.press('Enter');
  await page.waitForTimeout(3500);
  const err = await readError(frame);
  await dismissDialog(page, frame);
  await page.waitForTimeout(1200);
  const after = await cell(header, { click: false }).catch(() => null);
  const shown = after ? (await after.innerText().catch(() => '<n/a>')).trim() : '<gone>';
  return { shown, dialogs: err.dialogs, message: err.message };
}

async function tryHeader(page, f, name, value) {
  const box = field(f, name).first();
  if (!(await box.count().catch(() => 0))) return { skipped: 'not on page' };
  await box.click().catch(() => {});
  await page.keyboard.press('Control+a');
  await page.keyboard.type(value, { delay: 20 });
  await page.keyboard.press('Tab');
  await page.waitForTimeout(3500);
  const err = await readError(f);
  await dismissDialog(page, f);
  const now = await field(f, name).first().inputValue().catch(() => '<gone>');
  return { stored: now, dialogs: err.dialogs, message: err.message };
}

// Columns verified present on the Purchase Order subform (p0-columns).
// 'Line Discount %' is NOT in the default column set here, unlike the Sales subform.
// Expectations from PurchaseLine.Table.al TestStatusOpen analysis:
//   Quantity                    guarded   -> expect refusal when released
//   Direct Unit Cost Excl. VAT  UNGUARDED -> expect it to be accepted
//   Expected Receipt Date       UNGUARDED -> accepted (Sales guards its Shipment Date)
const LINE_EDITS = [
  ['Quantity', '7'],
  ['Direct Unit Cost Excl. VAT', '12.34'],
  ['Expected Receipt Date', '02/02/2028'],
];
const HEADER_EDITS = [
  ['Vendor Invoice No.', 'SABOTEUR-INV'],
  ['Your Reference', 'SABOTEUR-REF'],
  ['Assigned User ID', 'admin'],
  ['Posting Date', '02/02/2028'],
  ['Due Date', '02/02/2028'],
];

(async () => {
  const { browser, page } = await launch();
  try {
    await signIn(page);
    log('signed in');

    if (probeId === 'p0-columns') {
      const { frame } = await orderWithLine(page);
      log('order', await docNo(frame));
      log('line columns:', JSON.stringify(await dumpColumns(frame)));
      const c = await lineCell(frame, 1);
      for (const h of ['Quantity', 'Direct Unit Cost Excl. VAT', 'Line Discount %']) {
        const got = await c(h, { click: false }).catch(e => null);
        log(`  ${h} ->`, got ? (await got.innerText().catch(() => '?')).trim() || '<empty>' : 'NOT FOUND');
      }
    }

    // p1b - disambiguate the p1 negative. SQL showed NOTHING changed on the released
    // order, including Direct Unit Cost which has no TestStatusOpen guard. Two rival
    // explanations: (a) the product refused, (b) the grid was never editable so the
    // keystrokes went nowhere. This is the SAB-3 trap - measure the instrument.
    if (probeId === 'p1b-diagnose') {
      const probe = async (f, label) => {
        // Is the card in view mode (pencil shown) rather than edit mode?
        const pencil = f.locator('button[title="Make changes on the page"]');
        log(`${label}: 'Make changes' button present =`, await pencil.count().catch(() => '?'));
        const c = await lineCell(f, 1);
        const target = await c('Direct Unit Cost Excl. VAT').catch(e => {
          log(`${label}: cannot click cell -`, e.message.slice(0, 80)); return null;
        });
        if (!target) return;
        log(`${label}: focused input after click =`, await f.locator('input:focus').count());
        log(`${label}: cell aria-readonly =`, await target.getAttribute('aria-readonly'));
        await page.keyboard.type('55.55', { delay: 60 });
        await page.waitForTimeout(1200);
        log(`${label}: focused input value while typing =`,
          await f.locator('input:focus').inputValue().catch(() => '<no focused input>'));
        await page.keyboard.press('Enter');
        await page.waitForTimeout(4000);
        const err = await readError(f);
        log(`${label}: after Enter ->`, JSON.stringify(err));
        await page.screenshot({ path: `psab-p1b-${label}.png` });
      };

      log('--- CONTROL: open order ---');
      const open = await orderWithLine(page);
      const openNo = await docNo(open.frame);
      log('open order', openNo);
      await probe(await appFrame(page), 'OPEN');

      log('--- SUBJECT: released order ---');
      const rel = await orderWithLine(page);
      const relNo = await docNo(rel.frame);
      log('released order', relNo);
      log('release ->', JSON.stringify(await release(page, rel.frame)));
      await probe(await appFrame(page), 'RELEASED');
      log('VERIFY IN SQL: open=' + openNo + ' released=' + relNo + ' (expect 55.55 where accepted)');
    }

    // p1 - released line edits, WITH the open-order control run first.
    if (probeId === 'p1-lines') {
      log('--- CONTROL: open purchase order ---');
      const open = await orderWithLine(page);
      log('open order', await docNo(open.frame));
      let f = await appFrame(page);
      let c = await lineCell(f, 1);
      for (const [col, val] of LINE_EDITS) {
        log(`OPEN ${col} ->`, JSON.stringify(await tryCell(page, f, c, col, val)));
      }

      log('--- SUBJECT: released purchase order ---');
      const rel = await orderWithLine(page);
      const relNo = await docNo(rel.frame);
      log('released order', relNo);
      log('release ->', JSON.stringify(await release(page, rel.frame)));
      f = await appFrame(page);
      c = await lineCell(f, 1);
      for (const [col, val] of LINE_EDITS) {
        log(`RELEASED ${col} ->`, JSON.stringify(await tryCell(page, f, c, col, val)));
      }
      log('VERIFY IN SQL:', relNo);
    }

    // p2 - the SAB-1 claim, plus the Assigned User ID divergence.
    if (probeId === 'p2-header') {
      log('--- CONTROL: open purchase order ---');
      const open = await orderWithLine(page);
      log('open order', await docNo(open.frame));
      let f = await appFrame(page);
      for (const [n, v] of HEADER_EDITS) {
        log(`OPEN ${n} ->`, JSON.stringify(await tryHeader(page, f, n, v)));
      }

      log('--- SUBJECT: released purchase order ---');
      const rel = await orderWithLine(page);
      const relNo = await docNo(rel.frame);
      log('released order', relNo);
      log('release ->', JSON.stringify(await release(page, rel.frame)));
      f = await appFrame(page);
      for (const [n, v] of HEADER_EDITS) {
        log(`RELEASED ${n} ->`, JSON.stringify(await tryHeader(page, f, n, v)));
      }
      log('VERIFY IN SQL:', relNo);
    }

    // p3 - Enabled = Status <> Released. Does the shortcut respect it?
    if (probeId === 'p3-release-twice') {
      const { frame } = await orderWithLine(page);
      const no = await docNo(frame);
      log('order', no);
      log('release #1 ->', JSON.stringify(await release(page, frame)));
      log('release #2 ->', JSON.stringify(await release(page, await appFrame(page))));
      log('release #3 ->', JSON.stringify(await release(page, await appFrame(page))));
      log('VERIFY IN SQL:', no);
    }

    log('probe', probeId, 'completed');
  } catch (e) {
    log('PROBE ERROR:', e.message);
    await page.screenshot({ path: `psab-${probeId}-fail.png` }).catch(() => {});
  } finally {
    await browser.close();
  }
})();
