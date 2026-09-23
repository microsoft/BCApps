// Shared helpers for driving BC from an exploratory tour.
//
// Per-session configuration comes from ONE environment variable:
//
//   BC_CREDS   path to the bc-credentials.json written by New-TourContainer.ps1
//
// That file carries the container name, so the web client URL is derived from it and
// two tours running in parallel cannot silently share a container. Set BC_BASE only to
// override the URL - e.g. when the container name does not resolve and you need its IP.
// `playwright` is required lazily inside launch(), not at import time. The pure helpers
// (readError, field, lineCell...) need no browser, so readError.test.js can exercise them
// against a mocked frame from a checkout with no node_modules.
const fs = require('fs');

const credsPath = process.env.BC_CREDS;
if (!credsPath) {
  throw new Error(
    'BC_CREDS is not set. It must point at the bc-credentials.json for THIS tour\'s container.\n' +
    'Without it a parallel session would sign in to another tour\'s container and its SQL\n' +
    'deltas would measure the other session\'s writes.\n' +
    '  $env:BC_CREDS = "<path>\\<container>-credentials.json"');
}
if (!fs.existsSync(credsPath)) {
  throw new Error(`BC_CREDS points at a file that does not exist: ${credsPath}`);
}

const CREDS = JSON.parse(fs.readFileSync(credsPath, 'utf8'));
if (!CREDS.containerName) {
  throw new Error(`${credsPath} has no containerName - regenerate it with New-TourContainer.ps1`);
}

const CONTAINER = CREDS.containerName;
const BASE = process.env.BC_BASE || `http://${CONTAINER}/BC/`;


async function appFrame(page, timeoutMs = 120000) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    for (const f of page.frames()) {
      if (f === page.mainFrame()) continue;
      const n = await f.locator('[aria-label]').count().catch(() => 0);
      if (n > 20) return f;
    }
    await page.waitForTimeout(500);
  }
  throw new Error('BC app frame not found');
}

async function signIn(page, url = BASE) {
  await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 120000 });
  if (await page.locator('#UserName').count()) {
    await page.fill('#UserName', CREDS.user);
    await page.fill('#Password', CREDS.password);
    await page.click('#submitButton');
  }
  return appFrame(page);
}

// Open a page by ID. Re-acquires the frame, since navigation staleness is the classic trap.
async function openPage(page, pageId) {
  await page.goto(`${BASE}?page=${pageId}`, { waitUntil: 'domcontentloaded', timeout: 120000 });
  return appFrame(page);
}

// Locate a field's real <input> by its label.
//
// USE getByLabel, NOT getByRole('textbox'). BC renders plain text fields as role=textbox but
// renders LOOKUP and DATE fields (anything with a TableRelation or a date picker) as
// role=combobox. A helper built on getByRole('textbox') therefore silently fails to find a
// large fraction of a card's fields - on Transfer Order 5740 it missed Posting Date,
// Transfer-from Code, Transfer-to Code and In-Transit Code, every one of which reported as
// "not on the page" when all four were present and visible.
//
// getByLabel resolves aria-label AND aria-labelledby, and BC puts the field name in
// aria-labelledby on most card pages, so it covers both renderings.
//
// Scope to `input`: the list page behind the card is still in the DOM and its grid cells are
// SPANs carrying the same label, so an unscoped locator resolves to a read-only cell.
function field(frame, name) {
  return frame.getByLabel(name, { exact: true }).and(frame.locator('input'));
}

// Same lookup, but tolerant of the label appearing in both the card and the list behind it.
// Returns the first VISIBLE, ENABLED input, falling back to the first visible one so that a
// deliberately read-only field is still reported (rather than looking absent).
//
// `root` scopes the search. Pass the result of topDialog() when driving a REQUEST PAGE: its
// captions collide with the worksheet grid underneath, so `Starting Date`, `No.` and
// `Description` each resolve to two inputs and an unscoped locator silently drives the GRID
// instead of the dialog.
async function fieldOne(frame, name, { root = null } = {}) {
  const all = root ? root.getByLabel(name, { exact: true }).and(root.locator('input'))
                   : field(frame, name);
  const n = await all.count().catch(() => 0);
  if (!n) return null;
  let firstVisible = null;
  for (let i = 0; i < n; i++) {
    const el = all.nth(i);
    if (!(await el.isVisible().catch(() => false))) continue;
    if (!firstVisible) firstVisible = el;
    if (await el.isEditable().catch(() => false)) return el;
  }
  return firstVisible;
}

// The dialog currently on top, or the frame if there is none. Dialogs stack (see readError),
// and for INPUT the newest is the one the user is typing into.
async function topDialog(frame) {
  const d = frame.getByRole('dialog');
  const n = await d.count().catch(() => 0);
  return n ? d.nth(n - 1) : frame;
}

async function launch({ headless = true } = {}) {
  const { chromium } = require('playwright');
  const browser = await chromium.launch({ headless });
  const context = await browser.newContext({ viewport: { width: 1400, height: 900 } });
  const page = await context.newPage();
  page.on('dialog', d => d.accept());
  return { browser, context, page };
}

// --- Document helpers -------------------------------------------------------
// Learned the hard way during the Couch Potato and Obsessive-Compulsive tours.
// See docs/tours-testing/playwright-bc.instructions.md.

// Open a list page, click New, and wait for the CARD to take over. Clicking New
// navigates (e.g. 9305 -> 42); waiting a fixed time races the navigation.
async function newDocument(page, listPageId, cardPageId) {
  let frame = await openPage(page, listPageId);
  await page.waitForTimeout(2500);
  for (let attempt = 1; attempt <= 3; attempt++) {
    await frame.getByRole('menuitem', { name: 'New' }).first().click().catch(() => {});
    try { await page.waitForURL(new RegExp(`page=${cardPageId}`), { timeout: 20000 }); break; }
    catch {
      if (attempt === 3) throw new Error(`New did not open page ${cardPageId}`);
      frame = await appFrame(page);
    }
  }
  await page.waitForTimeout(6000);
  return appFrame(page);
}

// A document card's DOM still contains the LIST page's grid, so getByRole('grid')
// returns more than one. Pick the grid by a column header only the lines grid has.
async function linesGrid(frame, markerHeader = 'Type') {
  const grids = frame.getByRole('grid');
  for (let i = 0, n = await grids.count(); i < n; i++) {
    const heads = await grids.nth(i).getByRole('columnheader').allInnerTexts().catch(() => []);
    if (heads.includes(markerHeader)) return grids.nth(i);
  }
  throw new Error(`lines grid (marker column '${markerHeader}') not found`);
}

// Returns cell(headerText) for one row of the lines grid. Grid cells ARE exposed as
// role=gridcell, but they carry no column name, so match the header's x-centre
// against each cell's x-range.
async function lineCell(frame, rowIndex = 1, markerHeader = 'Type') {
  const lg = await linesGrid(frame, markerHeader);
  const row = lg.getByRole('row').nth(rowIndex);          // row 0 is the header row
  await row.scrollIntoViewIfNeeded().catch(() => {});
  const page = frame.page();

  return async (headerText, { click = true } = {}) => {
    let hx = null;
    for (const h of await lg.getByRole('columnheader').all()) {
      if ((await h.innerText().catch(() => '')).trim() !== headerText) continue;
      const b = await h.boundingBox().catch(() => null);
      if (b) { hx = b.x + b.width / 2; break; }
    }
    if (hx === null) throw new Error(`column '${headerText}' not found`);
    for (const c of await row.getByRole('gridcell').all()) {
      const b = await c.boundingBox().catch(() => null);
      if (b && hx >= b.x && hx <= b.x + b.width) {
        if (click) { await c.click(); await page.waitForTimeout(1000); }
        return c;
      }
    }
    throw new Error(`no cell under column '${headerText}'`);
  };
}

// BC reports validation failures as a modal error dialog, an inline notification, or
// a red field. Collect all three; never use loose page text as an oracle.
// Read whatever BC is complaining about.
//
// BC reports validation failures on FOUR different surfaces, and a tour that reads
// only one of them will report false "silent failure" defects:
//   1. modal dialogs                     role=dialog
//   2. the page-level error bar          "The page has an error. Refresh (F5) ..."
//   3. an inline bubble next to the cell "Status must be equal to 'Open' in ..."
//   4. notifications                     the collapsible bar under the title
//
// A FIFTH surface looks identical in the DOM but means the opposite: a Yes/No CONFIRMATION
// ("Do you want to change Transfer-from Code?"). It is returned separately as `confirmation`,
// because counting it as an error makes a working field look rejected.
//
// Do NOT fall back to scanning body text with a loose regex. The original version did,
// and /is not/ matched the substring inside "There is nothing to show in this view"
// (a FactBox caption), so every probe returned that string as its "error" while the
// real message sat further down the page. That single bug made a correctly behaving
// product look like it was silently discarding edits on a released document.
//
// THREE further traps, each of which manufactured a false result on page 6510
// (Item Tracking Lines) during the item-tracking tour:
//
//   * DIALOGS STACK. This helper used to read `dialogs[0]` only. On 6510 `dialogs[0]` is the
//     Item Tracking Lines PAGE - it is itself rendered as role=dialog - so the real question
//     ("The corrections cannot be saved as excess quantity has been defined. Close the form
//     anyway?") sat in `dialogs[1]` and was never returned. The probe logged an empty error and
//     looked exactly like silent data loss. The Playwright guide already warns that dialogs
//     stack when DISMISSING; the same is true when READING. Scan them all, newest last.
//
//   * A PAGE RENDERED AS A DIALOG IS NOT A MESSAGE. Because 6510 is a dialog, the old fallback
//     returned the entire page caption - 600 characters of chrome - as `message`, so every
//     clean step reported an "error". Never treat the containing page's own text as an error.
//
//   * `must be` IS NOT THE ONLY SHAPE OF A REAL MESSAGE. The genuine BC message
//     "...accounts for more than the quantity you have entered. You must adjust the existing
//     item tracking..." contains "must adjust", which the old regex missed, so it surfaced only
//     in `surfaces[]`. A probe reading `message` alone would have called a guarded case UNGUARDED.

// A real validation sentence. Deliberately broader than "must be": BC phrases refusals many
// ways, and every shape missing from this list becomes a false "no error" somewhere.
const VALIDATION_RE = /\b(must|cannot|can ?not|can't|may not|is not valid|not allowed|already exists?|out of balance|does not exist|do not exist|exceeds?|insufficient|is required|too (?:long|large|small|many|high|low))\b/i;

const CONFIRM_RE = /\b(do you want to|are you sure)\b/i;
const YESNO_RE = /\byes\b[\s\S]{0,6}\bno\b/i;
// An OK/Cancel chooser is a PROMPT, not a refusal - the post dialog
// ("Receive Invoice Receive and Invoice OK Cancel") is the common one. Classifying it as an
// error makes a document that is merely waiting for an answer look rejected.
const OKCANCEL_RE = /\bok\b[\s\S]{0,4}\bcancel\b/i;
const isConfirm = (t) => CONFIRM_RE.test(t) || YESNO_RE.test(t) || OKCANCEL_RE.test(t);

// A page that happens to be rendered as role=dialog (Item Tracking Lines, Enter Quantity to
// Create, most "worksheet" sub-pages), or a teaching tip. Neither is a message.
//
// Two signals, because neither alone is enough. Length caught Item Tracking Lines but NOT the
// "About items ... Show Help Take a tour" teaching tip on the Items list, which is ~390
// characters and was returned as an error by a live smoke test against a clean page. A real BC
// message is a sentence; page help is prose with navigation in it.
const CHROME_MIN_LEN = 240;
const HELP_RE = /\b(show help|take a tour|learn more|read more about|what's new|about (?:this|the) page)\b/i;
const isChrome = (t) =>
  !VALIDATION_RE.test(t) && !isConfirm(t) && (t.length >= CHROME_MIN_LEN || HELP_RE.test(t));

// A SIXTH surface, and the nastiest: BC does not always use a dialog at all.
//
// A POSTING failure navigates the whole window to an "Error Messages" LIST PAGE. It is not
// role=dialog, not role=alert, carries no error/validation class and no aria-describedby - so
// every surface above returns nothing and readError() reports total silence while BC is
// displaying a precise, correct refusal naming the exact document line. Found on the
// item-tracking posting tour, where it would have produced two false "posts silently" findings
// had the probe not also taken a screenshot and asserted in SQL.
//
// ⚠️ The grid TRUNCATES the message ("The quantity to invoice does not match the ..."). Treat
// these rows as evidence that a refusal happened and roughly why; open the Details pane if you
// need the full sentence.
async function readErrorPage(page, frame) {
  const title = await page.title().catch(() => '');
  if (!/error messages/i.test(title)) return null;
  const rows = [];
  for (const g of await frame.getByRole('grid').all().catch(() => [])) {
    const heads = (await g.getByRole('columnheader').allInnerTexts().catch(() => []))
      .map((h) => h.replace(/\s+/g, ' ').trim()).filter(Boolean);
    if (!heads.some((h) => /description/i.test(h))) continue;
    // The header is itself a role=row, and on this page it does NOT start with "Description" -
    // the Error Messages grid leads with Type, No., Item Reference No. and a dozen others. An
    // earlier version skipped only rows starting with /^description/, so the header survived as
    // rows[0] and became the "message". Drop row 0, and drop anything that is just the headers
    // concatenated, whatever order they happen to be in.
    const headSet = new Set(heads.map((h) => h.toLowerCase()));
    const isHeaderish = (t) => {
      const words = t.toLowerCase().split(' ').filter(Boolean);
      if (!words.length) return false;
      const covered = heads.filter((h) => t.toLowerCase().includes(h.toLowerCase())).length;
      return covered >= Math.max(3, Math.ceil(heads.length * 0.6)) || headSet.has(t.toLowerCase());
    };
    const all = await g.getByRole('row').all().catch(() => []);
    for (let i = 0; i < all.length; i++) {
      if (i === 0) continue;                       // row 0 is the header row
      const t = (await all[i].innerText().catch(() => '')).replace(/\s+/g, ' ').trim();
      if (!t || isHeaderish(t)) continue;
      if (!/[a-z]/i.test(t)) continue;             // filler cells such as "0 0"
      rows.push(t);
    }
  }
  return { title, rows };
}

async function readError(frame) {
  const texts = async (sel) => (await frame.locator(sel).allInnerTexts().catch(() => []))
    .map(s => s.replace(/\s+/g, ' ').trim()).filter(Boolean);

  const dialogs = await frame.getByRole('dialog').allInnerTexts().catch(() => []);
  const alerts = await texts('[role="alert"]');
  // Class-based surfaces: BC marks the error bar and inline bubbles with 'error' or
  // 'validation' somewhere in the class name.
  const marked = await texts('[class*="error" i], [class*="validation" i]');
  // The inline bubble is wired to the offending input via aria-describedby.
  const described = await frame.evaluate(() => {
    const out = [];
    for (const el of document.querySelectorAll('[aria-invalid="true"], input:focus')) {
      for (const id of (el.getAttribute('aria-describedby') || '').split(/\s+/).filter(Boolean)) {
        const t = document.getElementById(id)?.innerText?.trim();
        if (t) out.push(t.replace(/\s+/g, ' '));
      }
    }
    return out;
  }).catch(() => []);

  const all = [...new Set([...alerts, ...marked, ...described])]
    .filter(t => !/there is nothing to show/i.test(t));

  // Every dialog, normalised, in DOM order - the LAST is the one stacked on top.
  const dialogTexts = dialogs.map(s => s.replace(/\s+/g, ' ').trim()).filter(Boolean);
  const dialogChrome = dialogTexts.filter(isChrome);
  // Candidate dialogs are the ones that actually say something. Reversed so the topmost
  // (most recently stacked) dialog wins - that is the one the user is looking at.
  const dialogMessages = dialogTexts.filter(t => !isChrome(t)).reverse();

  // A Yes/No CONFIRMATION is not a refusal. BC asks "Do you want to change <field>?" when you
  // edit a key field on a document that already has lines. Treating that prompt as an error
  // reports a working field as REFUSED - seen on Transfer-from Code during the Transfer tour.
  const confirmation = [...dialogMessages, ...all].find(t => t && isConfirm(t)) || '';

  // Surface 6: BC navigated away to an Error Messages list page instead of raising a dialog.
  // Checked HERE rather than left to the caller on purpose - the failure mode is silence, and a
  // tour that does not already know about this surface will never think to go looking for it.
  let errorPage = null;
  try {
    const p = typeof frame.page === 'function' ? frame.page() : null;
    if (p) errorPage = await readErrorPage(p, frame);
  } catch { /* mocked frame, or no page - fall through */ }

  // Prefer a real validation sentence over the generic "the page has an error" banner, and
  // prefer it over page chrome. Dialogs first: a modal outranks an inline bubble.
  const specific = [...dialogMessages, ...all]
    .find(t => !isConfirm(t) && VALIDATION_RE.test(t));
  const firstDialogMessage = dialogMessages.find(t => !isConfirm(t)) || '';
  const pageHasError = all.some(t => /the page has an error/i.test(t));

  // Prefer a row that actually reads like a refusal. The Error Messages grid interleaves filler
  // and layout rows with the real sentence, so errorPage[0] is NOT reliably the message - taking
  // it blindly once returned a whole column header as BC's "error text", which is worse than the
  // silence this surface was added to fix: a plausible wrong string gets quoted in a finding,
  // whereas an empty one gets questioned.
  const errorPageMessage = (errorPage?.rows || []).find(t => VALIDATION_RE.test(t))
    || (errorPage?.rows || [])[0] || '';

  return {
    dialogs,
    message: specific || firstDialogMessage || errorPageMessage,
    confirmation,
    pageHasError,
    surfaces: all,
    // Rows from the Error Messages page, when BC navigated instead of raising a dialog.
    // Truncated by the grid - open the Details pane for the full sentence.
    errorPage: errorPage?.rows || [],
    // Everything that was discarded as page chrome. Present so a probe that gets an
    // unexpected empty `message` can see what was filtered rather than guess.
    chrome: dialogChrome,
  };
}

// Dismiss a BC error/confirmation dialog. Pointer clicks are unreliable here (the
// dialog container intercepts them); Escape is the only route that works reliably.
async function dismissDialog(page, frame) {
  if (!(await frame.getByRole('dialog').count().catch(() => 0))) return false;
  await page.keyboard.press('Escape');
  await page.waitForTimeout(1500);
  await settleOverlay(page, frame);
  return true;
}

// Wait for a dismissed dialog's fade overlay to actually leave the DOM.
//
// BC keeps `.spa-dialog.appear-fadeout` alive after the dialog has visually gone, and it
// still intercepts pointer events. The next grid click then fails with Playwright's
// "intercepts pointer events" timeout after a full 30 s - which reads like a hung page
// but is pure harness noise. Seen on every round-trip through Item Tracking Lines (6510).
async function settleOverlay(page, frame, timeoutMs = 8000) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    const n = await frame.locator('.spa-dialog.appear-fadeout, .spa-dialog-overlay')
      .count().catch(() => 0);
    if (!n) return true;
    await page.waitForTimeout(250);
  }
  return false;
}

// Click something that a fading overlay may be sitting on top of.
async function clickSettled(page, frame, locator, attempts = 3) {
  for (let i = 1; i <= attempts; i++) {
    await settleOverlay(page, frame);
    try { await locator.click({ timeout: 5000 }); return true; }
    catch (e) { if (i === attempts) throw e; await page.waitForTimeout(1000); }
  }
  return false;
}

// Answer a Yes/No confirmation.
//
// A pointer click on *Yes* is NOT reliable: during the item-tracking tour one neither answered
// nor errored - the delete simply did not happen, the dialog closed, and the surviving rows
// read as orphaned records. Only the SQL check caught it, and it cost a withdrawn finding.
// Focusing the button and pressing Enter is the route that works.
//
// ⚠️ THE ANSWER IS NOT EVIDENCE. After answering, assert in SQL that the underlying record
// actually changed. "I clicked Yes and no error appeared" proves nothing about what BC did.
async function answerConfirm(page, frame, answer = 'Yes') {
  const btn = frame.getByRole('button', { name: answer, exact: true }).last();
  if (!(await btn.count().catch(() => 0))) return false;
  await btn.focus().catch(() => {});
  await page.keyboard.press('Enter');
  await page.waitForTimeout(1500);
  if (await frame.getByRole('button', { name: answer, exact: true }).count().catch(() => 0)) {
    await clickSettled(page, frame, btn).catch(() => {});
    await page.waitForTimeout(1500);
  }
  await settleOverlay(page, frame);
  return true;
}

// --- Request pages ----------------------------------------------------------
// A report/batch request page (Calculate Regenerative Plan, Carry Out Action Message) is
// rendered as role="dialog" and is where a tour is most likely to be silently defeated.

// Set an OPTION (dropdown) field and PROVE it committed.
//
// This is the helper whose absence ended a Charter mid-session. `Carry Out Action Message`
// defaults its four Create-* options to "Last used options and filters", so a run that inherits
// blank completes with no error and CREATES NOTHING. The probe and its control were both
// silent, which is the §5.3 signature of a broken instrument rather than a product defect.
//
// TWO TRAPS, both of which made the field look undriveable:
//
//   1. BC renders an ENUM option on a request page as a native `<select>`, not as the
//      combobox-style `<input>` used everywhere else. `getByLabel(...).and(locator('input'))`
//      therefore finds nothing and the field reports as absent. Playwright's selectOption()
//      drives a real <select> reliably - no typing, no clicking the list open.
//
//   2. A `<select>`'s `.value` is the option INDEX, not its caption. Reading it back gives
//      "0" / "1", so a probe that sets "Firm Planned" and reads "0" concludes the write was
//      refused when it may well have succeeded. Always read `selectedOptions[0].text`.
//
// The caption is also not what the AL source suggests: the field labelled `Create Production
// Order` in code is labelled just **"Production Order"** in the DOM, so matching is fuzzy on
// purpose.
//
// ⚠️ THROWS if the value did not commit. That is the point: a dropdown that silently refuses
// to change turns every downstream probe into a false negative.
async function findOptionControl(frame, label) {
  return frame.evaluate((wanted) => {
    const norm = (s) => (s || '').replace(/\s+/g, ' ').trim().toLowerCase();
    const want = norm(wanted);
    const labelOf = (el) => {
      const byId = (el.getAttribute('aria-labelledby') || '').split(/\s+/).filter(Boolean)
        .map((id) => document.getElementById(id)?.innerText || '').join(' ');
      return norm(el.getAttribute('aria-label') || byId);
    };
    const match = (t) => !!t && (t === want || t.includes(want) || want.includes(t));
    const scan = (sel, kind) => {
      const els = [...document.querySelectorAll(sel)];
      for (let i = 0; i < els.length; i++) {
        const t = labelOf(els[i]);
        if (match(t)) {
          return {
            kind, index: i, label: t,
            options: kind === 'select' ? [...els[i].options].map((o) => o.text) : [],
          };
        }
      }
      return null;
    };
    return scan('select', 'select') || scan('input[role="combobox"]', 'input');
  }, label);
}

async function setOption(page, frame, label, value) {
  const ctl = await findOptionControl(frame, label);
  if (!ctl) throw new Error(`option field '${label}' not found on the request page`);

  if (ctl.kind === 'select') {
    const sel = frame.locator('select').nth(ctl.index);
    const readText = () => frame.evaluate(
      (i) => { const s = document.querySelectorAll('select')[i];
               return s && s.selectedOptions[0] ? s.selectedOptions[0].text.trim() : ''; },
      ctl.index);

    if ((await readText()) === value) return value;
    await sel.selectOption({ label: value }).catch(async () => {
      // Fall back to the keyboard when the caption does not match exactly.
      await sel.focus();
      for (let i = 0; i < 40 && (await readText()) !== value; i++) {
        await page.keyboard.press('ArrowDown');
        await page.waitForTimeout(100);
      }
    });
    await page.waitForTimeout(800);

    const got = await readText();
    if (got === value) return got;
    throw new Error(
      `could not set option '${label}' to '${value}' - it reads '${got}'. ` +
      `Available: ${JSON.stringify(ctl.options)}. Do NOT continue: a request page whose ` +
      `options did not commit produces a silent no-op, and every probe after this point ` +
      `would be a false negative.`);
  }

  // Combobox-style option field: type the caption and commit.
  const input = frame.locator('input[role="combobox"]').nth(ctl.index);
  const read = async () => (await input.inputValue().catch(() => '')).trim();
  for (const key of ['Enter', 'Tab']) {
    await input.click().catch(() => {});
    await page.keyboard.press('Control+a').catch(() => {});
    await input.type(value, { delay: 30 }).catch(() => {});
    await page.keyboard.press(key).catch(() => {});
    await page.waitForTimeout(800);
    if ((await read()) === value) return value;
  }
  throw new Error(
    `could not set option '${label}' to '${value}' - it reads '${await read()}'. ` +
    `Do NOT continue: every probe after this point would be a false negative.`);
}

// Read an option field's CAPTION (never its index - see the trap above).
async function getOption(frame, label) {
  const ctl = await findOptionControl(frame, label);
  if (!ctl) return null;
  if (ctl.kind === 'select') {
    return frame.evaluate(
      (i) => { const s = document.querySelectorAll('select')[i];
               return s && s.selectedOptions[0] ? s.selectedOptions[0].text.trim() : ''; },
      ctl.index);
  }
  return (await frame.locator('input[role="combobox"]').nth(ctl.index)
    .inputValue().catch(() => '')).trim();
}

// Click a ribbon action, opening its GROUP first if necessary.
//
// Ribbon groups collapse their contents out of the DOM entirely: `Calculate Regenerative Plan`
// and `Carry Out Action Message` do not exist until the `Prepare` group is clicked. A zero
// count is therefore a claim about the locator, never proof the action is absent (§6.3).
async function openAction(page, frame, name, group = null) {
  const find = () => frame.getByRole('menuitem', { name, exact: false });
  if (!(await find().count().catch(() => 0)) && group) {
    await frame.getByRole('menuitem', { name: group, exact: false }).first()
      .click().catch(() => {});
    await page.waitForTimeout(1200);
  }
  if (!(await find().count().catch(() => 0))) {
    throw new Error(
      `action '${name}' not found${group ? ` (tried opening group '${group}')` : ''} - ` +
      `ribbon groups hide their actions, so try passing the group name before concluding ` +
      `the action does not exist`);
  }
  await clickSettled(page, frame, find().first());
  await page.waitForTimeout(2000);
  return appFrame(page);
}

// Dismiss the "About <page>" teaching tip that greets a first visit.
//
// ⚠️ It must be closed with its own "Got it" button. Escape would close the PAGE behind it
// (playwright-bc §6), which looks like the page failing to open.
async function dismissTeachingTip(page, frame) {
  const btn = frame.getByRole('button', { name: /got it/i }).last();
  if (!(await btn.count().catch(() => 0))) return false;
  await clickSettled(page, frame, btn).catch(() => {});
  await page.waitForTimeout(800);
  return true;
}

// Set a BOOLEAN cell in a lines grid, and PROVE it committed against the database.
//
// Three traps stack here, and together they produce confident false evidence:
//
//   1. The clickable control is the `div[role="checkbox"]`. The `input[type=checkbox]` inside it
//      is `aria-hidden` with `tabindex="-1"` and ignores clicks, and a row-level locator like
//      `row.locator('input[type=checkbox]')` resolves to the ROW-SELECTION checkbox instead -
//      a different control that reports success while the field never changes.
//   2. Clicking the cell and pressing Space does nothing at all.
//   3. Worst: `aria-checked` flips to "true" IMMEDIATELY, but BC commits a field on focus EXIT.
//      Read the DOM straight after the click and it says the value changed; close the browser
//      there and the database never hears about it. A planning tour hit exactly this - DOM said
//      checked, SQL said 0 accepted - and lost a charter to it.
//
// So `verify` is REQUIRED, not optional. It must query the database and return the boolean that
// is actually stored. This is the generalised form of the confirmation rule: after ANY DOM
// readback, assert in SQL. The DOM is a claim; the database is the oracle.
async function setBoolean(page, frame, { row = 1, column, value = true,
                                         markerHeader = 'Type', verify } = {}) {
  if (typeof verify !== 'function') {
    throw new Error(
      `setBoolean('${column}') requires a verify() callback that reads the value back from SQL. ` +
      `aria-checked flips before BC commits, so a DOM readback here is not evidence - it is ` +
      `exactly how a tour convinces itself a flag was set when the database says otherwise.`);
  }

  const cellFor = await lineCell(frame, row, markerHeader);
  const cell = await cellFor(column, { click: false });
  const box = cell.locator('[role="checkbox"]').first();
  if (!(await box.count().catch(() => 0))) {
    throw new Error(`cell '${column}' on row ${row} has no [role="checkbox"] - is it a boolean?`);
  }

  const domState = async () => (await box.getAttribute('aria-checked').catch(() => null)) === 'true';

  if ((await domState()) !== value) {
    await clickSettled(page, frame, box);
    await page.waitForTimeout(600);
    // BC commits when focus leaves the ROW, not merely the cell - Tab alone moves within the
    // row and is NOT enough. ArrowDown/Up moves to the neighbouring row, which is what flushes
    // the record. Measured: with Tab only, SQL still read the old value.
    await page.keyboard.press('Tab');
    await page.waitForTimeout(500);
    await page.keyboard.press('ArrowDown');
    await page.waitForTimeout(1200);
    await page.keyboard.press('ArrowUp');
    await page.waitForTimeout(1200);
  }

  // The commit is asynchronous, so poll the DATABASE rather than sampling it once - a single
  // early read is indistinguishable from a write that never happened.
  const deadline = Date.now() + 12000;
  let verified = await verify();
  while (verified !== value && Date.now() < deadline) {
    await page.waitForTimeout(1000);
    verified = await verify();
  }

  const dom = await domState();
  if (verified !== value) {
    throw new Error(
      `setBoolean('${column}', row ${row}) did not commit: DOM reads ${dom}, database reads ` +
      `${verified}. Do NOT continue - this is the failure mode where the UI agrees with you ` +
      `and the record does not.`);
  }
  return { dom, verified };
}

// Choose an option in a radio-button control - most importantly the POST dialog
// (Receive / Invoice / Receive and Invoice).
//
// BC renders these as bare `input[type=radio]` inside `<li>` elements in a
// `ul.radiobuttoncontrol-edit`. The inputs carry NO aria-label, NO aria-labelledby and no role,
// so `getByLabel` and `getByRole('radio', {name})` both find nothing - the caption lives only in
// the surrounding `<li>` text. Clicking around the control lands on whatever is already selected,
// and the default is "Receive and Invoice", so a tour that cannot drive this silently posts a
// full receipt+invoice every time. That quietly rules out any probe needing a receive-only
// document - an Undo Receipt charter, for instance.
//
// `check({force: true})` on the right index is what works; the index comes from the <li> text.
// Exact caption match is tried first on purpose: "Receive" is a prefix of "Receive and Invoice".
async function chooseRadio(page, frame, label) {
  const found = await frame.evaluate((want) => {
    const norm = (s) => (s || '').replace(/\s+/g, ' ').trim().toLowerCase();
    const w = norm(want);
    const rs = [...document.querySelectorAll('input[type=radio]')];
    const caps = rs.map((r) => norm(r.closest('li')?.innerText));
    let i = caps.indexOf(w);
    if (i < 0) i = caps.findIndex((c) => c && c.includes(w));
    return { index: i, captions: caps };
  }, label);

  if (found.index < 0) {
    throw new Error(
      `radio option '${label}' not found. Available: ${JSON.stringify(found.captions)}`);
  }

  const radio = frame.locator('input[type=radio]').nth(found.index);
  await radio.check({ force: true });
  await page.waitForTimeout(800);
  if (!(await radio.isChecked().catch(() => false))) {
    throw new Error(`radio option '${label}' did not take - it still reads unchecked`);
  }
  return found.captions[found.index];
}

// Post the open document, choosing explicitly rather than accepting the default.
//
// ⚠️ The selection is client state, so `isChecked()` proves only that the dialog agrees with
// you. What was actually posted is a question for SQL: a Receive-only post writes a
// Purch. Rcpt. Header and NO Purch. Inv. Header. Assert that, not the radio.
async function postDocument(page, frame, choice = 'Receive and Invoice') {
  await page.keyboard.press('F9');
  await page.waitForTimeout(4000);
  const chosen = await chooseRadio(page, frame, choice);

  // Enter does NOT submit this dialog - measured: the radio takes, Enter does nothing, and the
  // dialog is still sitting there while SQL shows no document posted. Drive OK explicitly.
  const ok = frame.getByRole('button', { name: /^OK$/i }).last();
  if (await ok.count().catch(() => 0)) {
    await ok.focus().catch(() => {});
    await page.keyboard.press('Enter');
    await page.waitForTimeout(2000);
    if (await ok.count().catch(() => 0)) await clickSettled(page, frame, ok).catch(() => {});
  } else {
    await page.keyboard.press('Enter');
  }
  await page.waitForTimeout(9000);
  return chosen;
}

// Identity oracle for an open card.
//
// There is no usable record identity INSIDE the app frame. On a Service Order card:
//   h1                     -> 0 matches
//   [class*="pageCaption"] -> 0 matches
//   [role="heading"]       -> 29 matches, the first of which is the COMPANY name
// So an assertion written against the frame silently passes on anything, and a probe that
// opened the wrong document - or no document - reports results anyway.
//
// The browser title is authoritative and cheap:
//   "Service Order - SO000005 - Deerfield Graphics Company"
//
// Always assert this after opening a card and BEFORE mutating anything.
async function assertCard(page, expected) {
  const title = await page.title();
  if (!title.includes(expected)) {
    throw new Error(`wrong record: expected "${expected}", card title is "${title}"`);
  }
  return title;
}

module.exports = {
  BASE, CREDS, CONTAINER, appFrame, signIn, openPage, field, fieldOne, launch,
  newDocument, linesGrid, lineCell, readError, dismissDialog, assertCard,
  settleOverlay, clickSettled, answerConfirm,
  topDialog, setOption, getOption, findOptionControl, openAction, dismissTeachingTip,
  readErrorPage, setBoolean, chooseRadio, postDocument,
};
