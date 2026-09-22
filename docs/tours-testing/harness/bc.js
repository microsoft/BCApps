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

// Always scope a field to the real <input>: the list behind the card is still in the DOM
// and .first() silently resolves to a read-only grid cell.
function field(frame, name) {
  return frame.getByRole('textbox', { name }).and(frame.locator('input'));
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
async function readError(frame) {
  const dialogs = await frame.getByRole('dialog').allInnerTexts().catch(() => []);
  const body = await frame.locator('body').innerText().catch(() => '');
  const m = body.match(/.*(?:must be|cannot|not valid|is not|already exists|between 0 and 100|too long).*/i);
  return { dialogs, message: m ? m[0].trim() : '' };
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
  BASE, CREDS, appFrame, signIn, openPage, field, launch,
  newDocument, linesGrid, lineCell, readError, dismissDialog,
};
