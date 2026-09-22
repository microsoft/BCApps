// Shared helpers for driving BC in the Cancelled Bus session.
const { chromium } = require('playwright');
const fs = require('fs');

const CREDS = JSON.parse(fs.readFileSync(
  'C:\\Users\\jonasbl\\.copilot\\session-state\\ca19d914-b190-4409-a2c5-2c23c566afcc\\files\\bc-credentials.json', 'utf8'));
const BASE = process.env.BC_BASE || 'http://BCApps-Tours/BC/';

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

  // A Yes/No CONFIRMATION is not a refusal. BC asks "Do you want to change <field>?" when you
  // edit a key field on a document that already has lines. Treating that prompt as an error
  // reports a working field as REFUSED - seen on Transfer-from Code during the Transfer tour.
  const isConfirm = (t) => /\b(do you want to|are you sure)\b/i.test(t)
    || /\byes\b[\s\S]{0,6}\bno\b/i.test(t);

  const dialogText = (dialogs[0] || '').replace(/\s+/g, ' ').trim();
  const confirmation = [...all, dialogText].find(t => t && isConfirm(t)) || '';

  // Prefer a real validation sentence over the generic "the page has an error" banner.
  const specific = all.find(t => !isConfirm(t)
    && /\b(must be|cannot|is not valid|already exists|out of balance|does not exist)\b/i.test(t));
  const pageHasError = all.some(t => /the page has an error/i.test(t));

  return {
    dialogs,
    message: specific || (isConfirm(dialogText) ? '' : dialogText) || '',
    confirmation,
    pageHasError,
    surfaces: all,
  };
}

// Dismiss a BC error/confirmation dialog. Pointer clicks are unreliable here (the
// dialog container intercepts them); Escape is the only route that works reliably.
async function dismissDialog(page, frame) {
  if (!(await frame.getByRole('dialog').count().catch(() => 0))) return false;
  await page.keyboard.press('Escape');
  await page.waitForTimeout(1500);
  return true;
}

module.exports = {
  BASE, CREDS, appFrame, signIn, openPage, field, fieldOne, launch,
  newDocument, linesGrid, lineCell, readError, dismissDialog,
};
