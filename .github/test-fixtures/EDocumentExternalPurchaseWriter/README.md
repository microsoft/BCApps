# External E-Document purchase draft writer compilation fixture

This is a **separately compiled AL app**, deliberately outside the E-Document Core and Core Tests app source trees. Its app ID is not present in E-Document Core's `internalsVisibleTo`.

To verify the public-symbol contract:

1. Build E-Document Core on the working branch and obtain its `.app` symbol package, together with the standard BC dependency packages.
2. Copy this fixture directory to a temporary, standalone AL project folder **outside the BCApps workspace app directories**.
3. Rename `app.json.template` to `app.json` in that temporary copy; the template filename deliberately prevents AL-Go project discovery in the BCApps repository.
4. Compile the temporary project using the same BC 30 compiler/symbols as E-Document Core. No friend-app or `internalsVisibleTo` entry should be added.
5. Confirm `IStructuredFormatReader` implementation, `E-Doc. Read into Draft` enum extension, the public staging table types, and `E-Doc. Purchase Draft Writer.PersistDraft()` all compile without internal-access or permission-symbol errors.

This fixture is a **symbol accessibility check**, not an end-to-end import test. The example intentionally does not parse its input or provide a production-ready format reader. The Core Tests app provides runtime assertions for persistence, replacement, matching cleanup, and status neutrality. Do not publish or install the fixture as a production extension.
