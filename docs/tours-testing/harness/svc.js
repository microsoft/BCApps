// Saboteur tour - Service Orders (page 5900, list 9318).
//
// Why this tour exists: Service is the ODD ONE OUT of the four document frameworks.
// It never calls TestStatusOpen(), its status field is "Release Status" (not "Status"),
// and only 6 of 139 header fields are guarded on release - all of them shipping fields.
// Its high-consequence fields (Customer No., Currency Code) are instead gated on whether
// the document already HAS LINES, and the gate is a Confirm dialog, not an Error:
//
//   Customer No.   if ServItemLineExists() then Confirmed := ConfirmManagement.GetResponseOrDefault(...)
//   Currency Code  if ServLineExists() and ("Contract No." <> '') then Error(Text058, ...)
//
// So the question this tour asks is NOT "is it refused?" but "is the user warned, and does
// the warning mention the consequence?" - and, separately, whether releasing the document
// changes anything at all.
//
// See exploratory-tours.instructions.md 9.10 and playwright-bc.instructions.md 10.

const { launch, appFrame, signIn, readError, fieldOne, assertCard, BASE } = require('./bc');

const LIST = 9318;

// Opening one document: page 5900 + filter= is unreliable (see Playwright 3).
// list -> click the row's first gridcell -> Enter. Then ASSERT via the browser title -
// there is no usable record identity inside the app frame (see assertCard in bc.js).
async function openOrder(page, no) {
  await page.goto(`${BASE}?page=${LIST}`);
  let frame = await appFrame(page);
  const row = frame.locator('[role="row"]').filter({ hasText: no }).first();
  await row.waitFor({ timeout: 30000 });
  await row.locator('[role="gridcell"]').first().click();
  await frame.locator('body').press('Enter');
  await page.waitForTimeout(4000);
  frame = await appFrame(page);
  await assertCard(page, no);   // throws - never continue on the wrong record
  return frame;
}

// Report editable / read-only / absent as three DIFFERENT things. A guarded field renders
// without an input, so requiring `input` alone makes it look absent - a misleading result.
async function state(frame, name) {
  const anyEl = frame.getByLabel(name, { exact: true });
  const input = anyEl.and(frame.locator('input'));
  if (await input.count()) return 'editable';
  if (await anyEl.count()) return 'read-only';
  return 'absent';
}

async function trySet(frame, name, value) {
  const st = await state(frame, name);
  if (st !== 'editable') return { field: name, result: st.toUpperCase() };

  const el = await fieldOne(frame, name);
  await el.click();
  await el.fill(value);
  await el.press('Tab');
  await frame.page().waitForTimeout(2500);

  const err = await readError(frame);
  if (err.confirmation) {
    // The whole point of the probe: a confirmation is NOT a refusal. Record the wording,
    // then answer Yes so we learn what the product actually does when the user proceeds.
    const yes = frame.getByRole('button', { name: /^Yes$/i }).first();
    if (await yes.count()) await yes.click();
    await frame.page().waitForTimeout(3000);
    const after = await readError(frame);
    return {
      field: name, result: 'CONFIRMED-THEN-PROCEEDED',
      prompt: err.confirmation,
      thenError: after.message || '(none)',
    };
  }
  if (err.message) return { field: name, result: 'REFUSED', message: err.message };
  return { field: name, result: 'ACCEPTED-SILENTLY' };
}

const PROBES = {
  // Control: an open order. Establishes the baseline wording of the confirmation.
  async t1(page) {
    const frame = await openOrder(page, 'SO000008');
    console.log(JSON.stringify(await trySet(frame, 'Customer No.', '20000'), null, 2));
  },

  // Subject: release the order first, then attempt the same edit.
  // Prediction from the scan: Release Status is not consulted for Customer No.,
  // so the released document should behave identically to the open one.
  //
  // The action is "Release to Ship" (not "Release") and lives under Warehouse.
  // Use its shortcut Ctrl+F9 rather than hunting the ribbon - and VERIFY the release
  // landed, because a probe that silently fails to release just repeats the control.
  async t2(page) {
    const frame = await openOrder(page, 'SO000005');

    await frame.locator('body').press('Control+F9');
    await page.waitForTimeout(5000);
    let relErr = await readError(frame);
    let status = await frame.getByLabel('Release Status', { exact: true }).first()
      .innerText().catch(() => '');

    // Ctrl+F9 on <body> does not always reach the app. Fall back to the action by its REAL
    // caption - it is "Release to Ship", not "Release", and it sits under Warehouse.
    // (ApplicationArea = Warehouse is enabled in CRONUS, so a missing action is a locator
    // problem, not a configuration one - verified in Application Area Setup.)
    if (!status.trim().toLowerCase().includes('ship')) {
      const act = frame.getByRole('menuitem', { name: /Release to Ship/i }).first();
      if (await act.count()) {
        await act.click();
        await page.waitForTimeout(5000);
        relErr = await readError(frame);
      } else {
        console.log('  !! "Release to Ship" not found in the ribbon');
      }
      status = await frame.getByLabel('Release Status', { exact: true }).first()
        .innerText().catch(() => '');
    }
    console.log(`  release attempt: error=${relErr.message || '(none)'} releaseStatus="${status.trim()}"`);

    console.log(JSON.stringify(await trySet(frame, 'Customer No.', '30000'), null, 2));
  },
};

(async () => {
  const name = process.argv[2];
  if (!PROBES[name]) { console.log('probes:', Object.keys(PROBES).join(', ')); process.exit(1); }
  const { browser, page } = await launch();
  try {
    await signIn(page);
    await PROBES[name](page);
  } finally {
    await browser.close();
  }
})();
