// Saboteur tours on Sales Orders.
//
// Tour A - release/reopen state machine. The Release action's own tooltip claims:
//   "You must reopen the document before you can make changes to it."
// Treat that as an assertion and attack it. SalesLine.TestStatusOpen() is called from
// 30 places; the interesting question is which fields are NOT among them.
//
// Tour B - blocked entities. Named targets:
//   SalesLine.SalesBlockedErr (4816)  'You cannot sell %1 %2 because the %3 check box...'
//   SalesLine.BlockedItemNotificationMsg (4461) 'blocked, but it is allowed on this type of document'
//   Customer Text006 (2544) 'You cannot %1 this type of document when Customer %2 is blocked with type %3'
// The real question is not entry-time validation but POST-time: block the entity AFTER
// the line exists, then post.
//
// Usage: node sab.js <probeId>
const {
  BASE, signIn, appFrame, openPage, field, newDocument,
  lineCell, readError, dismissDialog, launch,
} = require('./bc');

const probeId = process.argv[2];
const log = (...a) => console.log(...a);

const CUSTOMER = '10000';
const ITEM = '1896-S';

function customerNameBox(frame) {
  return frame.getByRole('combobox', { name: 'Customer Name' })
    .or(frame.getByRole('textbox', { name: 'Customer Name' }).and(frame.locator('input')));
}

async function orderWithLine(page, qty = '1') {
  let frame = await newDocument(page, 9305, 42);
  await customerNameBox(frame).first().waitFor({ state: 'visible', timeout: 60000 });
  await customerNameBox(frame).first().click();
  await page.keyboard.type(CUSTOMER, { delay: 50 });
  await page.keyboard.press('Tab');
  await page.waitForTimeout(5000);
  frame = await appFrame(page);

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

// The order number, read from the card header. Verified against SQL afterwards.
async function docNo(frame) {
  const f = field(frame, 'No.').first();
  return (await f.inputValue().catch(() => '')) || '<unknown>';
}

async function release(page, frame) {
  await page.keyboard.press('Control+F9');
  await page.waitForTimeout(6000);
  const err = await readError(frame);
  await dismissDialog(page, frame);
  return err;
}

// Type into a line cell and report what BC said. Same shape as the Intellectual tour.
async function tryCell(page, frame, cell, header, value) {
  let target;
  try { target = await cell(header); }
  catch (e) { return { skipped: e.message }; }
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

// Deep-link to a filtered card page, and leave it editable.
async function openFiltered(page, pageId, fieldName, value) {
  const url = `${BASE}?page=${pageId}&filter=${encodeURIComponent(`'${fieldName}' IS '${value}'`)}`;
  await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 120000 });
  const frame = await appFrame(page);
  await page.waitForTimeout(4000);
  const edit = frame.locator('button[title="Make changes on the page"]');
  if (await edit.count().catch(() => 0)) {
    await edit.first().click().catch(() => {});
    await page.waitForTimeout(3000);
  }
  return appFrame(page);
}

async function setCheckbox(page, frame, name, want) {
  const cb = frame.getByRole('checkbox', { name });
  if (!(await cb.count().catch(() => 0))) return `checkbox '${name}' not found`;
  const box = cb.first();
  const before = await box.isChecked().catch(() => null);
  if (before === want) return `already ${want}`;
  await box.click().catch(() => {});
  await page.keyboard.press('Tab');
  await page.waitForTimeout(3000);
  return `set ${name} -> ${want} (was ${before})`;
}

(async () => {
  const { browser, page } = await launch();
  try {
    const frame0 = await signIn(page);
    log('signed in');

    // ---- Tour A: release/reopen ------------------------------------------

    if (probeId === 's1-release-then-edit') {
      // Claim under test: after Release, the document cannot be changed.
      const { frame, cell } = await orderWithLine(page);
      const no = await docNo(frame);
      log('order', no);
      const rel = await release(page, frame);
      log('release ->', JSON.stringify(rel));
      const f = await appFrame(page);
      const c = await lineCell(f, 1);
      for (const col of ['Quantity', 'Unit Price Excl. VAT', 'Line Discount %', 'Shipment Date']) {
        const r = await tryCell(page, f, c, col, col === 'Shipment Date' ? '02/02/2028' : '7');
        log(`released + edit ${col} ->`, JSON.stringify(r));
      }
    }

    if (probeId === 's2-release-then-header') {
      // The header is a different record with its own TestStatusOpen calls.
      const { frame } = await orderWithLine(page);
      const no = await docNo(frame);
      log('order', no);
      log('release ->', JSON.stringify(await release(page, frame)));
      const f = await appFrame(page);
      for (const name of ['External Document No.', 'Your Reference', 'Posting Date', 'Due Date']) {
        const box = field(f, name).first();
        if (!(await box.count().catch(() => 0))) { log(`header ${name} -> <not on page>`); continue; }
        await box.click().catch(() => {});
        await page.keyboard.press('Control+a');
        await page.keyboard.type(name.includes('Date') ? '02/02/2028' : 'SABOTEUR', { delay: 20 });
        await page.keyboard.press('Tab');
        await page.waitForTimeout(3000);
        const err = await readError(f);
        await dismissDialog(page, f);
        const now = await field(f, name).first().inputValue().catch(() => '<gone>');
        log(`released + header ${name} -> stored='${now}'`, JSON.stringify(err));
      }
    }

    if (probeId === 's3-release-then-delete-line') {
      // SalesLine.OnDelete calls TestStatusOpen - so this should be refused.
      const { frame } = await orderWithLine(page);
      log('order', await docNo(frame));
      log('release ->', JSON.stringify(await release(page, frame)));
      const f = await appFrame(page);
      const c = await lineCell(f, 1);
      await c('Quantity');
      await page.keyboard.press('Control+Delete');
      await page.waitForTimeout(4000);
      const err = await readError(f);
      log('released + delete line ->', JSON.stringify(err));
      await dismissDialog(page, f);
    }

    if (probeId === 's3b-confirm-delete-released-line') {
      // s3 showed BC asks "Go ahead and delete?" on a RELEASED order. Answer Yes and
      // see whether OnDelete's TestStatusOpen actually refuses.
      const { frame } = await orderWithLine(page);
      const no = await docNo(frame);
      log('order', no);
      log('release ->', JSON.stringify(await release(page, frame)));
      const f = await appFrame(page);
      const c = await lineCell(f, 1);
      await c('Quantity');
      await page.keyboard.press('Control+Delete');
      await page.waitForTimeout(4000);
      log('confirm dialog ->', JSON.stringify(await readError(f)));
      await page.keyboard.press('Enter');          // answer the confirmation
      await page.waitForTimeout(5000);
      const after = await readError(await appFrame(page));
      log('after Yes ->', JSON.stringify(after));
      log('NOTE order', no, '- check in SQL whether the line survives');
      await dismissDialog(page, await appFrame(page));
    }

    if (probeId === 's4-release-then-add-line') {
      const { frame } = await orderWithLine(page);
      log('order', await docNo(frame));
      log('release ->', JSON.stringify(await release(page, frame)));
      const f = await appFrame(page);
      const c2 = await lineCell(f, 2);          // the next, empty line
      const r = await tryCell(page, f, c2, 'No.', ITEM);
      log('released + add line ->', JSON.stringify(r));
    }

    if (probeId === 's4b-diagnose-add-line') {
      // SAB-3 needs evidence: is the released grid READ-ONLY (so the keystrokes never
      // land, which is its own feedback), or does it ACCEPT typing and then discard it
      // silently? Same measurement on an open order as the control.
      const inspect = async (f, label) => {
        const lg = await require('./bc').linesGrid(f);
        const row = lg.getByRole('row').nth(2);
        const cells = await row.getByRole('gridcell').all();
        const state = await Promise.all(cells.slice(0, 4).map(async c => ({
          ro: await c.getAttribute('aria-readonly'),
          dis: await c.getAttribute('aria-disabled'),
          cls: ((await c.getAttribute('class')) || '').split(' ').filter(x => /read|disab|edit/i.test(x)).join(','),
        })));
        log(`${label}: row2 cell attrs`, JSON.stringify(state));
        log(`${label}: grid aria-readonly =`, await lg.getAttribute('aria-readonly'));
      };

      const typeAndSee = async (f, label) => {
        const c = await lineCell(f, 2);
        const target = await c('No.').catch(e => { log(`${label}: cannot click cell -`, e.message); return null; });
        if (!target) return;
        const page2 = f.page();
        log(`${label}: input present after click =`, await f.locator('input:focus').count());
        await page2.keyboard.type(ITEM, { delay: 60 });
        await page2.waitForTimeout(1500);
        // What is on screen BEFORE committing?
        const focusedVal = await f.locator('input:focus').inputValue().catch(() => '<no focused input>');
        const cellText = (await target.innerText().catch(() => '<n/a>')).trim();
        log(`${label}: typed '${ITEM}' -> focused input shows '${focusedVal}', cell shows '${cellText}'`);
        await page2.keyboard.press('Enter');
        await page2.waitForTimeout(4000);
        log(`${label}: after Enter ->`, JSON.stringify(await readError(f)));
      };

      log('--- CONTROL: open order ---');
      const open = await orderWithLine(page);
      const openNo = await docNo(open.frame);
      log('open order', openNo);
      let f = await appFrame(page);
      await inspect(f, 'OPEN');
      await typeAndSee(f, 'OPEN');

      log('--- SUBJECT: released order ---');
      const rel = await orderWithLine(page);
      log('released order', await docNo(rel.frame));
      log('release ->', JSON.stringify(await release(page, rel.frame)));
      f = await appFrame(page);
      await inspect(f, 'RELEASED');
      await typeAndSee(f, 'RELEASED');
    }

    if (probeId === 's5-release-twice') {
      // The action is Enabled = Status <> Released. Does the SHORTCUT respect that?
      const { frame } = await orderWithLine(page);
      log('order', await docNo(frame));
      log('release #1 ->', JSON.stringify(await release(page, frame)));
      log('release #2 ->', JSON.stringify(await release(page, await appFrame(page))));
      log('release #3 ->', JSON.stringify(await release(page, await appFrame(page))));
    }

    // ---- Tour B: blocked entities ----------------------------------------

    if (probeId === 's6-block-item') {
      const f = await openFiltered(page, 30, 'No.', ITEM);
      log('sales blocked ->', await setCheckbox(page, f, 'Sales Blocked', true));
      log('blocked      ->', await setCheckbox(page, f, 'Blocked', true));
    }

    if (probeId === 's7-unblock-item') {
      const f = await openFiltered(page, 30, 'No.', ITEM);
      log('sales blocked ->', await setCheckbox(page, f, 'Sales Blocked', false));
      log('blocked      ->', await setCheckbox(page, f, 'Blocked', false));
    }

    if (probeId === 's8-sell-blocked-item') {
      // Entry-time: expect SalesBlockedErr.
      let frame = await newDocument(page, 9305, 42);
      await customerNameBox(frame).first().waitFor({ state: 'visible', timeout: 60000 });
      await customerNameBox(frame).first().click();
      await page.keyboard.type(CUSTOMER, { delay: 50 });
      await page.keyboard.press('Tab');
      await page.waitForTimeout(5000);
      frame = await appFrame(page);
      const c = await lineCell(frame, 1);
      const r = await tryCell(page, frame, c, 'No.', ITEM);
      log('add blocked item ->', JSON.stringify(r));
    }

    if (probeId === 's9-block-after-line') {
      // The interesting one: line first, block second, post third.
      // Unblock first so the line can actually be created - otherwise the order is
      // empty and posting fails for an unrelated reason.
      const pre = await openFiltered(page, 30, 'No.', ITEM);
      log('pre-unblock ->', await setCheckbox(page, pre, 'Blocked', false));

      const { frame } = await orderWithLine(page, '2');
      const no = await docNo(frame);
      log('order', no);

      const itemFrame = await openFiltered(page, 30, 'No.', ITEM);
      // 'Sales Blocked' is not exposed on the Item Card in this build - use 'Blocked'.
      log('blocking item ->', await setCheckbox(page, itemFrame, 'Blocked', true));

      // Back to the order and post it.
      await page.goto(`${BASE}?page=42&filter=${encodeURIComponent(`'No.' IS '${no}'`)}`,
        { waitUntil: 'domcontentloaded', timeout: 120000 });
      let f = await appFrame(page);
      await page.waitForTimeout(5000);
      const edit = f.locator('button[title="Make changes on the page"]');
      if (await edit.count().catch(() => 0)) { await edit.first().click().catch(() => {}); await page.waitForTimeout(2500); }
      f = await appFrame(page);
      await page.keyboard.press('F9');
      await page.waitForTimeout(9000);
      const dlg = await readError(f);
      log('post dialog ->', JSON.stringify(dlg));
      // Answer the Ship/Invoice/Ship and Invoice dialog, then read what posting says.
      await page.keyboard.press('Enter');
      await page.waitForTimeout(12000);
      const err = await readError(await appFrame(page));
      log('post with blocked item ->', JSON.stringify(err));
      await dismissDialog(page, await appFrame(page));
      await page.waitForTimeout(1500);
      await dismissDialog(page, await appFrame(page));
      log('NOTE order', no, '- verify in SQL whether it posted');
    }

    if (probeId === 's10-block-customer') {
      const f = await openFiltered(page, 21, 'No.', CUSTOMER);
      const combo = f.getByRole('combobox', { name: 'Blocked' })
        .or(field(f, 'Blocked'));
      if (!(await combo.count().catch(() => 0))) { log('Blocked field not found'); }
      else {
        await combo.first().click();
        await page.keyboard.press('Control+a');
        await page.keyboard.type('All', { delay: 50 });
        await page.keyboard.press('Tab');
        await page.waitForTimeout(3500);
        const err = await readError(f);
        await dismissDialog(page, f);
        log('customer Blocked=All ->', JSON.stringify(err));
      }
    }

    if (probeId === 's11-unblock-customer') {
      // Typing into an option field does NOT clear it - the first attempt reported
      // success while leaving Blocked=All. Open the dropdown and pick the blank entry.
      const f = await openFiltered(page, 21, 'No.', CUSTOMER);
      const combo = f.getByRole('combobox', { name: 'Blocked' }).or(field(f, 'Blocked'));
      await combo.first().click();
      await page.waitForTimeout(1000);
      await page.keyboard.press('Alt+ArrowDown');       // open the option list
      await page.waitForTimeout(2000);
      await page.keyboard.press('Home');                // first option is blank
      await page.waitForTimeout(800);
      await page.keyboard.press('Enter');
      await page.waitForTimeout(2500);
      await page.keyboard.press('Escape');
      await page.waitForTimeout(2500);
      const shown = await combo.first().inputValue().catch(() => '<n/a>');
      log('customer Blocked now shows', JSON.stringify(shown), '- CONFIRM IN SQL');
    }

    if (probeId === 's12-order-for-blocked-customer') {
      let frame = await newDocument(page, 9305, 42);
      await customerNameBox(frame).first().waitFor({ state: 'visible', timeout: 60000 });
      await customerNameBox(frame).first().click();
      await page.keyboard.type(CUSTOMER, { delay: 50 });
      await page.keyboard.press('Tab');
      await page.waitForTimeout(6000);
      frame = await appFrame(page);
      const err = await readError(frame);
      log('order for blocked customer ->', JSON.stringify(err));
      await dismissDialog(page, frame);
    }

    log('probe', probeId, 'completed');
  } catch (e) {
    log('PROBE ERROR:', e.message);
    await page.screenshot({ path: `sab-${probeId}-fail.png` }).catch(() => {});
  } finally {
    await browser.close();
  }
})();
