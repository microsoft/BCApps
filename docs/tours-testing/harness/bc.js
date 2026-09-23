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
async function fieldOne(frame, name) {
  const all = field(frame, name);
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
const isConfirm = (t) => CONFIRM_RE.test(t) || YESNO_RE.test(t);

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

  // Prefer a real validation sentence over the generic "the page has an error" banner, and
  // prefer it over page chrome. Dialogs first: a modal outranks an inline bubble.
  const specific = [...dialogMessages, ...all]
    .find(t => !isConfirm(t) && VALIDATION_RE.test(t));
  const firstDialogMessage = dialogMessages.find(t => !isConfirm(t)) || '';
  const pageHasError = all.some(t => /the page has an error/i.test(t));

  return {
    dialogs,
    message: specific || firstDialogMessage || '',
    confirmation,
    pageHasError,
    surfaces: all,
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
};
