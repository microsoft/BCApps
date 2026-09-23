// Regression test for readError().
//
//   node readError.test.js
//
// No container and no BC_CREDS needed - the frame is mocked, so this runs anywhere.
// Every case below is a real false result that readError() once produced during a tour.
//
// The guide's rule is "validate the helper against a case you know must fail before trusting
// any negative result from it" (playwright-bc.instructions.md §8). This file is that check.
// Run it after touching readError; an empty `message` is the most dangerous possible bug in
// this harness, because it is indistinguishable from the product silently accepting bad data.
// The frame is mocked, but bc.js validates BC_CREDS at require time (deliberately - it is what
// stops two parallel tours signing in to each other's container). Point it at a throwaway stub.
const os = require('os');
const fsx = require('fs');
const pathx = require('path');
if (!process.env.BC_CREDS) {
  const stub = pathx.join(os.tmpdir(), 'bc-tours-test-creds.json');
  fsx.writeFileSync(stub, JSON.stringify({ containerName: 'mock', user: 'mock', password: 'mock' }));
  process.env.BC_CREDS = stub;
}

const { readError } = require('./bc.js');

function mockFrame({ dialogs = [], alerts = [], marked = [], described = [],
                    title = '', gridRows = null }) {
  const listOf = (sel) => {
    if (/alert/.test(sel)) return alerts;
    if (/error|validation/.test(sel)) return marked;
    return [];
  };
  // Minimal stand-in for the Error Messages list page: one grid with a Description column.
  const grid = {
    getByRole: (role) => ({
      allInnerTexts: async () => (role === 'columnheader' ? ['Description', 'Message Type'] : []),
      all: async () => (role === 'row'
        ? ['Description Message Type', ...(gridRows || [])].map(t => ({ innerText: async () => t }))
        : []),
    }),
  };
  return {
    page: () => ({ title: async () => title }),
    getByRole: (role) => ({
      allInnerTexts: async () => (role === 'dialog' ? dialogs : []),
      all: async () => (role === 'grid' && gridRows ? [grid] : []),
    }),
    locator: (sel) => ({ allInnerTexts: async () => listOf(sel) }),
    evaluate: async () => described,
  };
}

// Page 6510 (Item Tracking Lines) is itself rendered as role=dialog, so dialogs[0] is a
// screenful of column headers rather than a message.
const ITL_CHROME = 'Item Tracking Lines ' +
  'Serial No. Lot No. Package No. Quantity (Base) Qty. to Handle (Base) Qty. to Invoice (Base) Expiration Date Warranty Date '.repeat(6);

const REAL_QUESTION =
  'The corrections cannot be saved as excess quantity has been defined. Close the form anyway? Yes No';

const MUST_ADJUST =
  'Item tracking defined for item 1000 in the Purchase Line accounts for more than the quantity ' +
  'you have entered. You must adjust the existing item tracking and then reenter the new quantity.';

let failed = 0;
function check(name, actual, expected) {
  const ok = actual === expected;
  if (!ok) failed++;
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}`);
  if (!ok) {
    console.log(`        expected: ${JSON.stringify(expected)}`);
    console.log(`        actual:   ${JSON.stringify(actual)}`);
  }
}

(async () => {
  // H1 - dialogs stack. The question sat in dialogs[1] behind the page in dialogs[0]; reading
  // dialogs[0] only returned '' and the probe looked like silent data loss.
  let r = await readError(mockFrame({ dialogs: [ITL_CHROME, REAL_QUESTION] }));
  check('H1 stacked confirmation is found in dialogs[1]', r.confirmation, REAL_QUESTION);
  check('H1 chrome is not reported as the message', r.message, '');

  // H2 - a page rendered as a dialog is not a message. Every clean step on 6510 used to
  // report a 600-character "error".
  r = await readError(mockFrame({ dialogs: [ITL_CHROME] }));
  check('H2 clean step on 6510 reports no error', r.message, '');
  check('H2 filtered chrome stays visible for debugging', r.chrome.length, 1);

  // H2 again, from a live smoke test: the teaching tip on the Items list (page 31). It is
  // ~390 characters, so a pure length threshold let it through and a CLEAN page reported an
  // error. Page help is prose with navigation in it, never a message.
  const TEACHING_TIP = 'About items Items represent the products and services you buy and sell. ' +
    'For each item, you can manage the default sales and purchase prices used when creating ' +
    'documents, as well as track inventory numbers. With Item Templates you can quickly create ' +
    'new items having common details defined by the template. Show Help Take a tour';
  r = await readError(mockFrame({ dialogs: [TEACHING_TIP] }));
  check('H2 teaching tip on a clean list is not an error', r.message, '');

  // H3 - "must be" is not the only shape of a refusal. This genuine message says
  // "must adjust", was missed, and would have made a guarded case read as UNGUARDED.
  r = await readError(mockFrame({ dialogs: [ITL_CHROME], marked: [MUST_ADJUST] }));
  check('H3 "must adjust" is returned as the message', r.message, MUST_ADJUST);

  // Plural forms. `\balready exist\b` does not match "exists" - the same word-boundary trap
  // as H3, found by this test while fixing H3.
  r = await readError(mockFrame({ dialogs: ['Serial No. 1 already exists.'] }));
  check('plural "exists" matches', r.message, 'Serial No. 1 already exists.');
  r = await readError(mockFrame({ dialogs: ['Quantity exceeds the available amount.'] }));
  check('plural "exceeds" matches', r.message, 'Quantity exceeds the available amount.');

  // When several dialogs say something, the one on top is the one the user is looking at.
  r = await readError(mockFrame({
    dialogs: ['Quantity must be positive.', 'Serial No. 1 already exists.'],
  }));
  check('topmost stacked dialog wins', r.message, 'Serial No. 1 already exists.');

  // H6 - a POSTING failure does not raise a dialog at all: BC navigates to an Error Messages
  // LIST PAGE. No dialog, no alert, no error class, no aria-describedby - every other surface
  // returns nothing. This produced total silence on the item-tracking posting tour and would
  // have been filed as two false "posts silently" findings.
  const POST_ERR = 'The quantity to invoice does not match the quantity Purchase Line';
  r = await readError(mockFrame({ title: 'Error Messages - Microsoft Dynamics 365 Business Central',
                                 gridRows: [POST_ERR] }));
  check('H6 Error Messages page is not silence', r.message, POST_ERR);
  check('H6 rows are exposed separately', r.errorPage.length, 1);

  // The header row must not be mistaken for a message.
  check('H6 header row is not returned', r.errorPage[0], POST_ERR);

  // An ordinary page with grids must NOT be scanned for error rows.
  r = await readError(mockFrame({ title: 'Purchase Order - 106043', gridRows: ['some grid row'] }));
  check('H6 ordinary page is not treated as an error page', r.message, '');
  check('H6 ordinary page yields no errorPage rows', r.errorPage.length, 0);

  // --- regressions that must keep holding ---------------------------------
  r = await readError(mockFrame({ marked: ['There is nothing to show in this view'] }));
  check('FactBox caption is still filtered', r.message, '');

  r = await readError(mockFrame({ dialogs: ['Do you want to change Transfer-from Code? Yes No'] }));
  check('confirmation is not an error', r.message, '');
  check('confirmation is classified', r.confirmation,
    'Do you want to change Transfer-from Code? Yes No');

  r = await readError(mockFrame({ marked: ["Status must be equal to 'Open' in Purchase Header."] }));
  check('inline bubble is still read', r.message, "Status must be equal to 'Open' in Purchase Header.");

  r = await readError(mockFrame({ marked: ['The page has an error. Refresh (F5) to undo the change.'] }));
  check('generic banner sets pageHasError', r.pageHasError, true);

  console.log(failed ? `\n${failed} FAILED` : '\nall passed');
  process.exit(failed ? 1 : 0);
})();
