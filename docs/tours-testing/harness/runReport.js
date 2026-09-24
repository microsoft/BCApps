// runReport.js — run report 400 and capture its DATASET as XML.
//
// Two harness notes this probe exists to work around:
//  * bc.js appFrame() requires >20 [aria-label] elements. A report REQUEST PAGE opened via
//    ?report=<id> is a bare dialog with ~7, so appFrame() throws "BC app frame not found"
//    and the request page reads as "no app frame at all". It is there; the heuristic is wrong.
//  * "Send to... > XML Document" is the only oracle that yields the report DATASET rather
//    than rendered RDLC layout.
//
// Usage: node runReport.js <entryNoFilter> <outfile>
const { launch, signIn, BASE } = require('./bc');
const fs = require('fs');

async function reportFrame(page, timeoutMs = 60000) {
    const deadline = Date.now() + timeoutMs;
    let best = null, bestN = -1;
    while (Date.now() < deadline) {
        best = null; bestN = -1;
        for (const f of page.frames()) {
            if (f === page.mainFrame()) continue;
            const n = await f.locator('[aria-label]').count().catch(() => 0);
            if (n > bestN) { bestN = n; best = f; }
        }
        if (best && bestN >= 5) {
            // Confirm it is the request dialog, not the shell.
            if (await best.getByRole('button', { name: /^Send to/ }).count().catch(() => 0)) return best;
        }
        await page.waitForTimeout(500);
    }
    if (best) return best;
    throw new Error('report request frame not found');
}

(async () => {
    const entryNo = process.argv[2];
    const out = process.argv[3] || `dataset-${entryNo}.xml`;
    const { browser, page } = await launch();
    try {
        await signIn(page);
        await page.goto(`${BASE}?report=400`, { waitUntil: 'domcontentloaded', timeout: 120000 });
        await page.waitForTimeout(6000);
        const frame = await reportFrame(page);

        if (entryNo) {
            const inp = frame.getByLabel('Entry No.', { exact: false })
                .and(frame.locator('input')).first();
            await inp.click();
            await page.keyboard.type(String(entryNo), { delay: 40 });
            await page.keyboard.press('Tab');
            await page.waitForTimeout(1500);
            const back = await inp.inputValue().catch(() => '(unreadable)');
            console.log('Entry No. filter reads back as:', JSON.stringify(back));
            if (String(back).trim() !== String(entryNo).trim())
                throw new Error(`filter did not take: wanted ${entryNo}, got ${back}`);
        }

        await frame.getByRole('button', { name: /^Send to/ }).first().click();
        await page.waitForTimeout(3000);

        // The Send-to dialog is a fresh frame; re-acquire.
        let sendFrame = null;
        for (const f of page.frames()) {
            if (f === page.mainFrame()) continue;
            if (await f.getByText(/XML Document/i).count().catch(() => 0)) { sendFrame = f; break; }
        }
        if (!sendFrame) {
            await page.screenshot({ path: 'sendto-fail.png', fullPage: true });
            throw new Error('Send-to dialog: no "XML Document" option found');
        }
        const opts = await sendFrame.locator('[role="option"],li,button').allInnerTexts().catch(() => []);
        console.log('SEND-TO OPTIONS:', JSON.stringify(opts.filter(Boolean).slice(0, 20)));

        const dl = page.waitForEvent('download', { timeout: 120000 });
        await sendFrame.getByText(/XML Document/i).first().click();
        await page.waitForTimeout(1500);
        // Some builds need an explicit OK after picking the format.
        for (const f of page.frames()) {
            const ok = f.getByRole('button', { name: /^OK$/ });
            if (await ok.count().catch(() => 0)) { await ok.first().click().catch(() => { }); break; }
        }
        const download = await dl;
        await download.saveAs(out);
        console.log('SAVED', out, fs.statSync(out).size, 'bytes');
    } catch (e) {
        await page.screenshot({ path: 'runreport-error.png', fullPage: true });
        console.error('ERROR:', e.message);
        process.exitCode = 1;
    } finally { await browser.close(); }
})();
