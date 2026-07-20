# Vendor Match by Name Only with Draft-Page Infotip — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** On the V2 purchase-draft path, accept a vendor matched by name only (address mismatch) and mark the `Vendor No.` field on the draft page with an Activity Log infotip explaining the address did not match.

**Architecture:** Refactor the shared name/address matcher in `E-Document Import Helper` into a private best-match routine plus two public wrappers (strict legacy 2-arg; new 3-arg with a `var MatchedByAddress` flag). Only `E-Doc. Providers.GetVendor` (V2 path) uses the new overload; when it accepts a name-only match it logs an `Activity Log Builder` entry on `E-Document Purchase Header."[BC] Vendor No."` — the same field-infotip mechanism already used for `Total VAT`. The dead notification wiring is removed.

**Tech Stack:** AL / Business Central (BCApps), `Activity Log Builder` (codeunit 3111, `System.Log`), AL MCP tools (`al_build`, `al_publish`, `al_run_tests`) against the local `Navision_NAV` server instance.

---

## Reference facts (verified)

- Matcher lives in `src/Apps/W1/EDocument/App/src/Helpers/EDocumentImportHelper.Codeunit.al` (codeunit 6109 `"E-Document Import Helper"`).
  - Current procs: `FindVendorByNameAndAddress(VendorName: Text; VendorAddress: Text): Code[20]` (lines ~558-561) delegates to `FindVendorByNameAndAddressWithNotification(VendorName: Text; VendorAddress: Text; EDocEntryNoForNotification: Integer): Code[20]` (lines ~570-602).
  - Helpers already present in the same codeunit: `MatchThreshold()`, `RequiredNearness()`, `NormalizingFactor()` (all `local`), and it uses `RecordMatchMgt.CalculateStringNearness`.
- V2 provider: `src/Apps/W1/EDocument/App/src/Processing/Import/PrepareDraft/EDocProviders.Codeunit.al` (codeunit 6124 `"E-Doc. Providers"`), `GetVendor` at lines ~29-74; the name/address call is at lines ~68-71; `GetVendor`'s var block is lines ~30-36. `using System.Log;` is already imported (line 17).
- Infotip precedent: `EDoc Prepare Purch. Draft.ComputeAndApplyVATAmountDifference` logs `ActivityLog.Init(Database::"E-Document Purchase Header", FieldNo("Total VAT"), Header.SystemId).SetExplanation(...).SetType("AL").Log();`.
- Draft field: `E-Document Purchase Header."[BC] Vendor No."` (bound on the draft page as `Vendor No.`).
- Notification to delete: `E-Document Notification.AddVendorMatchedByNameNotAddressNotification` (codeunit 6123, `src/Apps/W1/EDocument/App/src/Document/Notification/EDocumentNotification.Codeunit.al`, lines ~19-37). Its only caller is the matcher.
- Tests: `src/Apps/W1/EDocument/Test/src/Processing/EDocProcessTest.Codeunit.al` (codeunit 139883 `"E-Doc Process Test"`, `Subtype = Test`). The test app is in the E-Document Core app's `internalsVisibleTo`, so it can call internal `"E-Doc. Providers".GetVendor` and access internal tables/fields. `LibraryPurchase` (`Codeunit "Library - Purchase"`) and `Assert` are already declared in that codeunit.
- Activity-log assertion: `Codeunit "Activity Log Builder".Query(TableNo: Integer; RecSystemId: Guid): Text` returns the logged entries as JSON text.
- Empty inputs to `FindVendor`/`FindVendorByGLN`/`FindVendorByVATRegistrationNo` return `''` (guarded), so a header with only Company Name + Address set reaches the name/address matcher deterministically.

## File structure

- **Modify** `src/Apps/W1/EDocument/App/src/Helpers/EDocumentImportHelper.Codeunit.al` — replace the notification-based matcher with `FindBestVendorMatchByNameAndAddress` (private) + two public `FindVendorByNameAndAddress` overloads.
- **Modify** `src/Apps/W1/EDocument/App/src/Processing/Import/PrepareDraft/EDocProviders.Codeunit.al` — use the 3-arg overload; add `LogVendorMatchedByNameOnlyInfotip`; refine telemetry.
- **Modify** `src/Apps/W1/EDocument/App/src/Document/Notification/EDocumentNotification.Codeunit.al` — delete `AddVendorMatchedByNameNotAddressNotification`.
- **Modify (tests)** `src/Apps/W1/EDocument/Test/src/Processing/EDocProcessTest.Codeunit.al` — add matcher unit tests + one infotip integration test.

---

## Task 1: Matcher refactor in `E-Document Import Helper` (unit tests first)

**Files:**
- Test: `src/Apps/W1/EDocument/Test/src/Processing/EDocProcessTest.Codeunit.al`
- Modify: `src/Apps/W1/EDocument/App/src/Helpers/EDocumentImportHelper.Codeunit.al`

- [ ] **Step 1: Add the `using System.Log;` import to the test codeunit**

In `EDocProcessTest.Codeunit.al`, add this line to the `using` block (e.g. right after line 28 `using System.IO;`):

```al
using System.Log;
```

- [ ] **Step 2: Write the four failing matcher unit tests**

Append these `[Test]` procedures to `EDocProcessTest.Codeunit.al` (before the final closing `}` of codeunit 139883). They reference the new 3-arg overload that does not exist yet, so the test app will fail to compile — that is the intended failing state.

```al
    [Test]
    procedure FindVendorByNameAndAddress_FullMatch_ReturnsVendorAndMatchedByAddressTrue()
    var
        VendorLocal: Record Vendor;
        EDocumentImportHelper: Codeunit "E-Document Import Helper";
        UniqueName: Text[100];
        UniqueAddress: Text[100];
        MatchedByAddress: Boolean;
        ResultNo: Code[20];
    begin
        // [SCENARIO] Name and address both match -> vendor returned, MatchedByAddress = true.
        UniqueName := CopyStr('VMN ' + Format(CreateGuid()), 1, 100);
        UniqueAddress := CopyStr('ADDR ' + Format(CreateGuid()), 1, 100);
        LibraryPurchase.CreateVendor(VendorLocal);
        VendorLocal.Name := CopyStr(UniqueName, 1, MaxStrLen(VendorLocal.Name));
        VendorLocal.Address := CopyStr(UniqueAddress, 1, MaxStrLen(VendorLocal.Address));
        VendorLocal.Modify();

        ResultNo := EDocumentImportHelper.FindVendorByNameAndAddress(UniqueName, UniqueAddress, MatchedByAddress);

        Assert.AreEqual(VendorLocal."No.", ResultNo, 'Full match should return the vendor.');
        Assert.IsTrue(MatchedByAddress, 'MatchedByAddress should be true for a full match.');
        Assert.AreEqual(VendorLocal."No.", EDocumentImportHelper.FindVendorByNameAndAddress(UniqueName, UniqueAddress), 'Legacy 2-arg should also return the vendor on a full match.');
    end;

    [Test]
    procedure FindVendorByNameAndAddress_NameOnly_ReturnsVendorAndMatchedByAddressFalse()
    var
        VendorLocal: Record Vendor;
        EDocumentImportHelper: Codeunit "E-Document Import Helper";
        UniqueName: Text[100];
        DifferentAddress: Text[100];
        MatchedByAddress: Boolean;
        ResultNo: Code[20];
    begin
        // [SCENARIO] Name matches, address differs -> name-only candidate returned, MatchedByAddress = false;
        //            legacy 2-arg still returns '' (strict).
        UniqueName := CopyStr('VMN ' + Format(CreateGuid()), 1, 100);
        DifferentAddress := CopyStr('OTHER ' + Format(CreateGuid()), 1, 100);
        LibraryPurchase.CreateVendor(VendorLocal);
        VendorLocal.Name := CopyStr(UniqueName, 1, MaxStrLen(VendorLocal.Name));
        VendorLocal.Address := CopyStr('123 Alpha Street', 1, MaxStrLen(VendorLocal.Address));
        VendorLocal.Modify();

        ResultNo := EDocumentImportHelper.FindVendorByNameAndAddress(UniqueName, DifferentAddress, MatchedByAddress);

        Assert.AreEqual(VendorLocal."No.", ResultNo, 'Name-only match should return the vendor via the 3-arg overload.');
        Assert.IsFalse(MatchedByAddress, 'MatchedByAddress should be false when only the name matches.');
        Assert.AreEqual('', EDocumentImportHelper.FindVendorByNameAndAddress(UniqueName, DifferentAddress), 'Legacy 2-arg must stay strict and return empty on a name-only match.');
    end;

    [Test]
    procedure FindVendorByNameAndAddress_NoMatch_ReturnsEmpty()
    var
        EDocumentImportHelper: Codeunit "E-Document Import Helper";
        NonExistentName: Text[100];
        MatchedByAddress: Boolean;
        ResultNo: Code[20];
    begin
        // [SCENARIO] No vendor matches the name -> '' and MatchedByAddress = false.
        NonExistentName := CopyStr('NOVENDOR ' + Format(CreateGuid()), 1, 100);

        ResultNo := EDocumentImportHelper.FindVendorByNameAndAddress(NonExistentName, 'nowhere', MatchedByAddress);

        Assert.AreEqual('', ResultNo, 'No name match should return empty.');
        Assert.IsFalse(MatchedByAddress, 'MatchedByAddress should be false when there is no match.');
    end;

    [Test]
    procedure FindVendorByNameAndAddress_EmptyDocumentAddress_TreatedAsMatched()
    var
        VendorLocal: Record Vendor;
        EDocumentImportHelper: Codeunit "E-Document Import Helper";
        UniqueName: Text[100];
        MatchedByAddress: Boolean;
        ResultNo: Code[20];
    begin
        // [SCENARIO] Empty document address counts as an address match -> MatchedByAddress = true.
        UniqueName := CopyStr('VMN ' + Format(CreateGuid()), 1, 100);
        LibraryPurchase.CreateVendor(VendorLocal);
        VendorLocal.Name := CopyStr(UniqueName, 1, MaxStrLen(VendorLocal.Name));
        VendorLocal.Modify();

        ResultNo := EDocumentImportHelper.FindVendorByNameAndAddress(UniqueName, '', MatchedByAddress);

        Assert.AreEqual(VendorLocal."No.", ResultNo, 'Vendor should match by name when the document address is empty.');
        Assert.IsTrue(MatchedByAddress, 'Empty document address should be treated as an address match.');
    end;
```

- [ ] **Step 3: Build the test app and verify it FAILS to compile**

Run (AL MCP): `al_build` on project **E-Document Core Tests**.
Expected: FAIL — compile error that `FindVendorByNameAndAddress` has no overload taking 3 arguments (the `var MatchedByAddress: Boolean` overload does not exist yet).

- [ ] **Step 4: Refactor the matcher in `EDocumentImportHelper.Codeunit.al`**

Replace the existing block (the `FindVendorByNameAndAddress` wrapper at ~lines 552-561 **and** the whole `FindVendorByNameAndAddressWithNotification` procedure at ~lines 563-602) with the following three procedures:

```al
    /// <summary>
    /// Use it to find a vendor by name and address. Returns a vendor only when both the name and the address match.
    /// </summary>
    /// <param name="VendorName">Vendor's name.</param>
    /// <param name="VendorAddress">Vendor's address.</param>
    /// <returns>Vendor number when name and address match, otherwise empty string.</returns>
    procedure FindVendorByNameAndAddress(VendorName: Text; VendorAddress: Text): Code[20]
    var
        VendorNo: Code[20];
        MatchedByAddress: Boolean;
    begin
        VendorNo := FindBestVendorMatchByNameAndAddress(VendorName, VendorAddress, MatchedByAddress);
        if not MatchedByAddress then
            exit('');
        exit(VendorNo);
    end;

    /// <summary>
    /// Use it to find a vendor by name and address, also reporting whether the address matched.
    /// Returns a full name+address match when available, otherwise the first name-only candidate.
    /// </summary>
    /// <param name="VendorName">Vendor's name.</param>
    /// <param name="VendorAddress">Vendor's address.</param>
    /// <param name="MatchedByAddress">Set to true when the returned vendor also matched by address.</param>
    /// <returns>Vendor number if a name match exists, otherwise empty string.</returns>
    procedure FindVendorByNameAndAddress(VendorName: Text; VendorAddress: Text; var MatchedByAddress: Boolean): Code[20]
    begin
        exit(FindBestVendorMatchByNameAndAddress(VendorName, VendorAddress, MatchedByAddress));
    end;

    local procedure FindBestVendorMatchByNameAndAddress(VendorName: Text; VendorAddress: Text; var MatchedByAddress: Boolean): Code[20]
    var
        Vendor: Record Vendor;
        RecordMatchMgt: Codeunit "Record Match Mgt.";
        EDocImpSessionTelemetry: Codeunit "E-Doc. Imp. Session Telemetry";
        NameNearness: Integer;
        AddressNearness: Integer;
        NameOnlyVendorNo: Code[20];
    begin
        MatchedByAddress := false;
        Vendor.SetCurrentKey(Blocked);
        Vendor.SetLoadFields(Name, Address);
        if Vendor.FindSet() then
            repeat
                NameNearness := RecordMatchMgt.CalculateStringNearness(VendorName, Vendor.Name, MatchThreshold(), NormalizingFactor());
                if VendorAddress = '' then
                    AddressNearness := RequiredNearness()
                else
                    AddressNearness := RecordMatchMgt.CalculateStringNearness(VendorAddress, Vendor.Address, MatchThreshold(), NormalizingFactor());
                if NameNearness >= RequiredNearness() then begin
                    if AddressNearness >= RequiredNearness() then begin
                        MatchedByAddress := true;
                        exit(Vendor."No.");
                    end;
                    if NameOnlyVendorNo = '' then
                        NameOnlyVendorNo := Vendor."No.";
                end;
            until Vendor.Next() = 0;

        if NameOnlyVendorNo <> '' then
            EDocImpSessionTelemetry.SetBool('Vendor Matched By Name Not Address', true);
        exit(NameOnlyVendorNo);
    end;
```

Note: this removes the only reference to `Codeunit "E-Document Notification"` inside the matcher. The `EDocumentNotification` local var was declared inside the deleted `FindVendorByNameAndAddressWithNotification` procedure, so nothing else needs adjusting. Do not touch `FindCustomerByNameAndAddress`.

- [ ] **Step 5: Build the app, publish, build+publish the test app**

Run (AL MCP) in order:
1. `al_build` on **E-Document Core** → expect success (0 diagnostics).
2. `al_publish` **E-Document Core** to serverInstance `Navision_NAV` → expect "Package published".
3. `al_restart` with the current country (e.g. `countryCode=W1`) so the rebuilt dependency symbols are re-ingested (al_reload does NOT refresh dependency symbols).
4. `al_build` on **E-Document Core Tests** → expect success.
5. `al_publish` **E-Document Core Tests** to `Navision_NAV` → expect "Package published".

- [ ] **Step 6: Run the matcher unit tests and verify they PASS**

Run (AL MCP): `al_run_tests` on serverInstance `Navision_NAV`, test codeunit `139883`, filtered to test methods:
`FindVendorByNameAndAddress_FullMatch_ReturnsVendorAndMatchedByAddressTrue`,
`FindVendorByNameAndAddress_NameOnly_ReturnsVendorAndMatchedByAddressFalse`,
`FindVendorByNameAndAddress_NoMatch_ReturnsEmpty`,
`FindVendorByNameAndAddress_EmptyDocumentAddress_TreatedAsMatched`.
Expected: all 4 PASS.

- [ ] **Step 7: Commit**

```bash
git add src/Apps/W1/EDocument/App/src/Helpers/EDocumentImportHelper.Codeunit.al src/Apps/W1/EDocument/Test/src/Processing/EDocProcessTest.Codeunit.al
git commit -m "Refactor E-Document vendor name/address matcher to report address match"
```

---

## Task 2: Accept name-only match + log Vendor No. infotip in `E-Doc. Providers`

**Files:**
- Test: `src/Apps/W1/EDocument/Test/src/Processing/EDocProcessTest.Codeunit.al`
- Modify: `src/Apps/W1/EDocument/App/src/Processing/Import/PrepareDraft/EDocProviders.Codeunit.al`

- [ ] **Step 1: Write the failing infotip integration test**

Append this `[Test]` procedure to `EDocProcessTest.Codeunit.al` (same codeunit 139883). It exercises the internal `"E-Doc. Providers".GetVendor` directly (allowed via internalsVisibleTo) and asserts the activity-log infotip on the header's `[BC] Vendor No.` field.

```al
    [Test]
    procedure GetVendor_NameOnlyMatch_LogsVendorNoInfotip()
    var
        VendorLocal: Record Vendor;
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        MatchedVendor: Record Vendor;
        EDocProviders: Codeunit "E-Doc. Providers";
        ActivityLogBuilder: Codeunit "Activity Log Builder";
        UniqueName: Text[100];
        ActivityLogJson: Text;
    begin
        // [SCENARIO] The V2 provider matches a vendor by name only and logs an infotip on the Vendor No. field.

        // [GIVEN] A vendor whose name is unique and whose address differs from the document
        UniqueName := CopyStr('VMN ' + Format(CreateGuid()), 1, 100);
        LibraryPurchase.CreateVendor(VendorLocal);
        VendorLocal.Name := CopyStr(UniqueName, 1, MaxStrLen(VendorLocal.Name));
        VendorLocal.Address := CopyStr('123 Alpha Street', 1, MaxStrLen(VendorLocal.Address));
        VendorLocal.Modify();

        // [GIVEN] An E-Document with a purchase header carrying that vendor name but a different address
        EDocument.Init();
        EDocument.Insert(true);
        EDocumentPurchaseHeader.InsertForEDocument(EDocument);
        EDocumentPurchaseHeader."Vendor Company Name" := CopyStr(UniqueName, 1, MaxStrLen(EDocumentPurchaseHeader."Vendor Company Name"));
        EDocumentPurchaseHeader."Vendor Address" := CopyStr('999 Beta Avenue', 1, MaxStrLen(EDocumentPurchaseHeader."Vendor Address"));
        // Unique External Id so the service-participant lookup in GetVendor cannot match a stray participant
        EDocumentPurchaseHeader."Vendor External Id" := CopyStr('EXT ' + Format(CreateGuid()), 1, MaxStrLen(EDocumentPurchaseHeader."Vendor External Id"));
        EDocumentPurchaseHeader.Modify();

        // [WHEN] The provider resolves the vendor
        MatchedVendor := EDocProviders.GetVendor(EDocument);

        // [THEN] It returns the name-only vendor
        Assert.AreEqual(VendorLocal."No.", MatchedVendor."No.", 'The provider should accept the name-only vendor match.');

        // [THEN] An activity-log infotip exists on the E-Document Purchase Header record
        EDocumentPurchaseHeader.GetFromEDocument(EDocument);
        ActivityLogJson := ActivityLogBuilder.Query(Database::"E-Document Purchase Header", EDocumentPurchaseHeader.SystemId);
        Assert.IsTrue(StrPos(ActivityLogJson, 'name only') > 0, 'An infotip explaining the name-only match should be logged. Got: ' + ActivityLogJson);
    end;
```

- [ ] **Step 2: Build+publish the test app and run the new test to verify it FAILS**

Run (AL MCP): `al_build` on **E-Document Core Tests** (expect success — it compiles), `al_publish` to `Navision_NAV`, then `al_run_tests` codeunit `139883` method `GetVendor_NameOnlyMatch_LogsVendorNoInfotip`.
Expected: FAIL — `GetVendor` currently returns an empty vendor for a name-only match (address mismatch), so `MatchedVendor."No."` is `''` and the assertion fails (and no infotip is logged).

- [ ] **Step 3: Update `GetVendor` and add the infotip logger in `EDocProviders.Codeunit.al`**

3a. Add two locals to the `GetVendor` var block (after `EDocumentHasNoVendorInformation: Boolean;`):

```al
        MatchedByAddress: Boolean;
        VendorNo: Code[20];
```

3b. Replace the name/address block (current lines ~68-71):

```al
        if Vendor.Get(EDocumentImportHelper.FindVendorByNameAndAddress(EDocumentPurchaseHeader."Vendor Company Name", EDocumentPurchaseHeader."Vendor Address")) then begin
            EDocImpSessionTelemetry.SetText('Vendor Match Method', 'Name and Address');
            exit;
        end;
```

with:

```al
        VendorNo := EDocumentImportHelper.FindVendorByNameAndAddress(EDocumentPurchaseHeader."Vendor Company Name", EDocumentPurchaseHeader."Vendor Address", MatchedByAddress);
        if Vendor.Get(VendorNo) then begin
            if MatchedByAddress then
                EDocImpSessionTelemetry.SetText('Vendor Match Method', 'Name and Address')
            else begin
                LogVendorMatchedByNameOnlyInfotip(EDocumentPurchaseHeader);
                EDocImpSessionTelemetry.SetText('Vendor Match Method', 'Name Only');
            end;
            exit;
        end;
```

3c. Add this local procedure to the codeunit (e.g. immediately after `GetVendor` ends, before `GetUnitOfMeasure`):

```al
    local procedure LogVendorMatchedByNameOnlyInfotip(EDocumentPurchaseHeader: Record "E-Document Purchase Header")
    var
        ActivityLog: Codeunit "Activity Log Builder";
        VendorMatchedByNameOnlyMsg: Label 'Vendor was matched by name only. The address on the document does not match this vendor.';
    begin
        ActivityLog
            .Init(Database::"E-Document Purchase Header", EDocumentPurchaseHeader.FieldNo("[BC] Vendor No."), EDocumentPurchaseHeader.SystemId)
            .SetExplanation(VendorMatchedByNameOnlyMsg)
            .SetType(Enum::"Activity Log Type"::"AL")
            .Log();
    end;
```

(`using System.Log;` is already imported in this file, so `"Activity Log Builder"` and `Enum::"Activity Log Type"` resolve.)

- [ ] **Step 4: Build the app, publish, restart, and re-run the infotip test to verify it PASSES**

Run (AL MCP) in order:
1. `al_build` **E-Document Core** → expect success.
2. `al_publish` **E-Document Core** to `Navision_NAV`.
3. `al_restart` `countryCode=W1` (re-ingest updated dependency symbols).
4. `al_build` **E-Document Core Tests** → expect success.
5. `al_publish` **E-Document Core Tests** to `Navision_NAV`.
6. `al_run_tests` codeunit `139883` method `GetVendor_NameOnlyMatch_LogsVendorNoInfotip` → expect PASS.

- [ ] **Step 5: Commit**

```bash
git add src/Apps/W1/EDocument/App/src/Processing/Import/PrepareDraft/EDocProviders.Codeunit.al src/Apps/W1/EDocument/Test/src/Processing/EDocProcessTest.Codeunit.al
git commit -m "Accept name-only vendor match and log Vendor No. infotip on purchase draft"
```

---

## Task 3: Remove the dead vendor-match notification

**Files:**
- Modify: `src/Apps/W1/EDocument/App/src/Document/Notification/EDocumentNotification.Codeunit.al`

- [ ] **Step 1: Delete the unused procedure**

In `EDocumentNotification.Codeunit.al`, delete the entire `AddVendorMatchedByNameNotAddressNotification` procedure (its doc-comment plus the procedure body, ~lines 15-37, i.e. from the `/// <summary>` above it through its closing `end;`).

Leave everything else in the codeunit untouched (`SendPurchaseDocumentDraftNotifications`, `Dismiss...`, `Disable...`, `SendNotification`, `AddActionsToNotification`, `GetVendorMatchedByNameNotAddressNotificationId`), and do not change the `E-Document Notification` table, the `E-Document Notification Type` enum, or the draft page's `SendPurchaseDocumentDraftNotifications` call.

- [ ] **Step 2: Verify no remaining references**

Run: `git grep -n "AddVendorMatchedByNameNotAddressNotification" -- src/Apps/W1/EDocument`
Expected: no output (zero references).

- [ ] **Step 3: Build the app and the test app to confirm nothing broke**

Run (AL MCP): `al_build` **E-Document Core** (expect success), then `al_build` **E-Document Core Tests** (expect success).

- [ ] **Step 4: Commit**

```bash
git add src/Apps/W1/EDocument/App/src/Document/Notification/EDocumentNotification.Codeunit.al
git commit -m "Remove unused vendor-matched-by-name notification (superseded by infotip)"
```

---

## Task 4: Final regression pass

- [ ] **Step 1: Publish latest app + test app**

Run (AL MCP): `al_build` + `al_publish` **E-Document Core** to `Navision_NAV`; `al_restart countryCode=W1`; `al_build` + `al_publish` **E-Document Core Tests** to `Navision_NAV`.

- [ ] **Step 2: Run the full E-Doc Process test codeunit to check for regressions**

Run (AL MCP): `al_run_tests` on `Navision_NAV`, test codeunit `139883` (all methods).
Expected: all tests PASS (the 5 new ones plus the pre-existing draft/vendor tests — confirms the strict 2-arg wrapper preserved legacy behavior).

- [ ] **Step 3: Confirm the branch is clean and push**

```bash
git status
git push -u origin vendor-match-name-with-address-notification
```

---

## Notes for the implementer

- **Do not** add explanatory inline code comments in the AL changes; keep the diff minimal (rationale belongs in commit messages).
- **Telemetry event tags:** none are added by this change. (The infotip uses `Activity Log Builder`, not `Session.LogMessage`.)
- If `al_run_tests` cannot find codeunit `139883` by number, filter by name `"E-Doc Process Test"`.
- The `Navision_NAV` serverInstance is the NST ServerInstance for the local W1 environment; publishing to `Nav` returns 404.
