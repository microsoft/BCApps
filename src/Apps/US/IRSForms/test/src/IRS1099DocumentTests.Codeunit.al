// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Setup;
using System.TestLibraries.Utilities;

codeunit 148010 "IRS 1099 Document Tests"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryIRSReportingPeriod: Codeunit "Library IRS Reporting Period";
        LibraryIRS1099FormBox: Codeunit "Library IRS 1099 Form Box";
        LibraryIRS1099Document: Codeunit "Library IRS 1099 Document";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit "Assert";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryERM: Codeunit "Library - ERM";
        LibraryJournals: Codeunit "Library - Journals";
        IsInitialized: Boolean;
        CannotChangeFormBoxWithCalculatedAmountErr: Label 'You cannot change the Form Box No. for the line with calculated amount.';
        CannotCreateFormDocSamePeriodVendorFormErr: Label 'You cannot create multiple form documents with the same period, vendor and form.';
        CreateCreateFormDocLineSameFormBoxErr: Label 'You cannot create two form document lines with the same form box.';
        CannotChangeIRSDataInEntryConnectedToFormDocumentErr: Label 'You cannot change the IRS data in the vendor ledger entry connected to the form document. Period = %1, Vendor No. = %2, Form No. = %3', Comment = '%1 = Period No., %2 = Vendor No., %3 = Form No.';
        PeriodNoFieldVisibleErr: Label 'Field Period No. should be visible.';
        PeriodNoNotVisibleErr: Label 'Field Period No. should not be visible.';
        ChangingPostingDateInPurchHeaderWhileHavingLineMsg: Label 'You have changed the Posting Date on the purchase header, which might affect the prices and discounts on the purchase lines.\You should review the lines and manually update prices and discounts if needed';
        VendorNotSetupForIRS1099Err: Label 'Vendor %1 is not set up for IRS 1099 reporting in the reporting period %2.', Comment = '%1 = Vendor No., %2 = Period No.';
        DocumentContextTxt: Label 'Document %1', Comment = '%1 - document ID', Locked = true;


    trigger OnRun()
    begin
        // [FEATURE] [1099]
    end;

    [Test]
    procedure SupplementalReleaseRequiresCodesForPositiveTips()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        SupplLine: Record "IRS 1099 Doc. Suppl. Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Positive cash tips cannot be released without occupation codes.
        Initialize();

        // [GIVEN] Document D with positive tips and no codes.
        LibraryIRS1099Document.CreateSupplementalDocument(DocHeader, 'NEC');
        CreateSupplementalLine(SupplLine, DocHeader.ID, 'NEC-01B');
        SupplLine.Validate(Amount, 100);
        SupplLine.Modify(true);
        Commit();

        // [WHEN] Release is attempted.
        asserterror LibraryIRS1099Document.ReleaseDocument(DocHeader);

        // [THEN] An actionable error leaves D Open.
        Assert.ExpectedError('positive cash tips require one or two valid Treasury tipped occupation codes');
        Assert.ExpectedErrorCode('Dialog');
        DocHeader.Get(DocHeader.ID);
        Assert.AreEqual(DocHeader.Status::Open, DocHeader.Status, 'Disclosures that fail validation must not be released.');
    end;

    [Test]
    procedure SupplementalCodesAreRetainedSuppressedAndRestored()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        TipsSupplLine: Record "IRS 1099 Doc. Suppl. Line";
        CodesSupplLine: Record "IRS 1099 Doc. Suppl. Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Clearing and restoring tips suppresses and restores saved codes without re-entry.
        Initialize();

        // [GIVEN] Document D with tips and valid codes.
        CreateSupplementalUpdateDocument(DocHeader, 5000, 100);
        CodesSupplLine.Get(DocHeader.ID, 'NEC-01C');
        Assert.IsTrue(LibraryIRS1099Document.IsSupplementalReportable(CodesSupplLine), 'Positive tips should report codes.');
        TipsSupplLine.Get(DocHeader.ID, 'NEC-01B');

        // [WHEN] Tips are cleared.
        TipsSupplLine.Validate(Amount, 0);
        TipsSupplLine.Modify(true);

        // [THEN] Codes remain stored but are excluded with an explanation.
        VerifyRetainedExcludedCodes(CodesSupplLine);

        // [WHEN] Positive tips are restored.
        TipsSupplLine.Validate(Amount, 100);
        TipsSupplLine.Modify(true);

        // [THEN] The same codes become reportable without re-entry.
        Assert.IsTrue(LibraryIRS1099Document.IsSupplementalReportable(CodesSupplLine), 'Restoring tips must restore code eligibility.');
        Assert.AreEqual('', LibraryIRS1099Document.GetSupplementalExplanation(CodesSupplLine), 'Restored codes should not show a zero-tip explanation.');
    end;

    [Test]
    procedure SupplementalMISCUsesSpecificParentNotEligibleRent()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        ParentDocLine: Record "IRS 1099 Form Doc. Line";
        TipsSupplLine: Record "IRS 1099 Doc. Suppl. Line";
        CodesSupplLine: Record "IRS 1099 Doc. Suppl. Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Eligible rent does not qualify excluded other-income disclosures.
        Initialize();

        // [GIVEN] D has rent 2500, other income 500 and tips 100 with valid codes.
        LibraryIRS1099Document.CreateSupplementalDocument(DocHeader, 'MISC');
        SetFinancialParent(DocHeader.ID, 500, 2000);
        AddFinancialBox(DocHeader, 'MISC-01', 2500, 2000);
        CreateSupplementalLine(TipsSupplLine, DocHeader.ID, 'MISC-13A');
        TipsSupplLine.Validate(Amount, 100);
        TipsSupplLine.Modify(true);
        CreateSupplementalLine(CodesSupplLine, DocHeader.ID, 'MISC-13B');
        CodesSupplLine.Validate("Occupation Code 1", '000');
        CodesSupplLine.Modify(true);

        // [WHEN] D is released.
        LibraryIRS1099Document.ReleaseDocument(DocHeader);

        // [THEN] Tips are validated against 500 and excluded, rather than qualified by rent.
        FindFinancialParent(DocHeader.ID, ParentDocLine);
        Assert.AreEqual(500, ParentDocLine.Amount, 'Excluded income is not a zero validation ceiling.');
        Assert.IsFalse(LibraryIRS1099Document.IsSupplementalReportable(TipsSupplLine), 'Rent must not qualify another parent.');
        Assert.IsFalse(LibraryIRS1099Document.IsSupplementalReportable(CodesSupplLine), 'Codes follow their specific parent.');
        Assert.IsTrue(LibraryIRS1099Document.GetSupplementalExplanation(TipsSupplLine) <> '', 'Excluded income needs an explanation.');
        Assert.AreEqual(100, TipsSupplLine.Amount, 'Excluded tips must remain stored.');
    end;

    [Test]
    procedure SupplementalWithholdingQualifiesBelowThresholdParent()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        ParentDocLine: Record "IRS 1099 Form Doc. Line";
        TipsSupplLine: Record "IRS 1099 Doc. Suppl. Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Positive backup withholding preserves income and its disclosures below the threshold.
        Initialize();

        // [GIVEN] D has compensation 500, tips 100, a 2000 threshold and withholding 50.
        CreateSupplementalUpdateDocument(DocHeader, 500, 100);
        AddFinancialBox(DocHeader, 'NEC-04', 50, 0);

        // [WHEN] D is released.
        LibraryIRS1099Document.ReleaseDocument(DocHeader);

        // [THEN] Both income and its tips are reportable.
        FindFinancialParent(DocHeader.ID, ParentDocLine);
        TipsSupplLine.Get(DocHeader.ID, 'NEC-01B');
        Assert.IsTrue(ParentDocLine."Include In 1099", 'Withholding must preserve the nonzero payment.');
        Assert.IsTrue(LibraryIRS1099Document.IsSupplementalReportable(TipsSupplLine), 'Tips follow the withholding-qualified parent.');
        Assert.AreEqual(500, ParentDocLine.Amount, 'Tips cannot increase income.');
    end;

    [Test]
    procedure SupplementalReleaseRejectsPopulatedUnknownMapping()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        Definition: Record "IRS 1099 Suppl. Box";
        SupplLine: Record "IRS 1099 Doc. Suppl. Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A custom stored disclosure is not silently omitted at release.
        Initialize();

        // [GIVEN] D contains a populated unmapped custom supplemental box.
        LibraryIRS1099Document.CreateSupplementalDocument(DocHeader, 'NEC');
        Definition.Get(DocHeader."Period No.", 'NEC', 'NEC-01D');
        Definition."No." := 'CUSTOM';
        Definition."XML Element Name" := '';
        Definition.Insert(true);
        CreateSupplementalLine(SupplLine, DocHeader.ID, 'CUSTOM');
        SupplLine.Validate(Amount, 50);
        SupplLine.Modify(true);

        // [WHEN] Release is attempted.
        asserterror LibraryIRS1099Document.ReleaseDocument(DocHeader);

        // [THEN] Unsupported populated mappings fail explicitly.
        Assert.ExpectedError('contains values that cannot be reported in IRIS XML');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [HandlerFunctions('AcceptDocumentUpdateHandler')]
    procedure LifecycleAcceptedThresholdUpdateIsRejected()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        Transmission: Record "Transmission IRIS";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] An accepted 1500 return cannot be detached by changing only its minimum from 600 to 2000.
        Initialize();

        // [GIVEN] D is accepted and linked, with its original receipt and correction state.
        CreateLifecycleThresholdCandidate(DocHeader, Transmission);
        DocHeader.Status := DocHeader.Status::Submitted;
        DocHeader."IRIS Submission Status" := DocHeader."IRIS Submission Status"::Accepted;
        DocHeader."IRIS Submission ID" := 'SAVED-SUBMISSION';
        DocHeader."IRIS Record ID" := 'SAVED-RECORD';
        DocHeader."IRIS Last Receipt ID" := 'SAVED-RECEIPT';
        DocHeader."IRIS Last Accepted Receipt ID" := 'ACCEPTED-RECEIPT';
        DocHeader."IRIS Needs Correction" := true;
        DocHeader.Modify(true);
        Commit();

        // [WHEN] The eligibility-only update is selected.
        asserterror LibraryIRS1099Document.UpdateTransmission(Transmission);

        // [THEN] The correction route is explicit and every stored filing value survives.
        VerifyRejectedLifecycleUpdate(DocHeader);
    end;

    [Test]
    [HandlerFunctions('AcceptDocumentUpdateHandler')]
    procedure LifecycleInProgressWithoutReceiptIsRejected()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        Transmission: Record "Transmission IRIS";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] In Progress is unsafe even before any receipt or submission identifiers arrive.
        Initialize();

        // [GIVEN] D is processing with no receipt.
        CreateLifecycleThresholdCandidate(DocHeader, Transmission);
        DocHeader.Status := DocHeader.Status::"In Progress";
        DocHeader.Modify(true);
        Commit();

        // [WHEN] The nonfiling update is selected.
        asserterror LibraryIRS1099Document.UpdateTransmission(Transmission);

        // [THEN] Pending state and association are not cleared.
        VerifyRejectedLifecycleUpdate(DocHeader);
    end;

    [Test]
    [HandlerFunctions('AcceptDocumentUpdateHandler')]
    procedure LifecycleReopenedReceiptUpdateIsRejected()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        Transmission: Record "Transmission IRIS";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Reopening does not make an old receipt safe to detach.
        Initialize();

        // [GIVEN] Open D retains a previous accepted receipt.
        CreateLifecycleThresholdCandidate(DocHeader, Transmission);
        DocHeader."IRIS Last Accepted Receipt ID" := 'OLD-ACCEPTED-RECEIPT';
        DocHeader.Modify(true);
        Commit();

        // [WHEN] The nonfiling update is selected.
        asserterror LibraryIRS1099Document.UpdateTransmission(Transmission);

        // [THEN] Editable status does not authorize unlinking.
        VerifyRejectedLifecycleUpdate(DocHeader);
    end;

    [Test]
    [HandlerFunctions('AcceptDocumentUpdateHandler')]
    procedure LifecycleReopenedCorrectionStateIsRejected()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        Transmission: Record "Transmission IRIS";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A reopened correction cannot be treated as unsent when receipts are absent.
        Initialize();

        // [GIVEN] Open D retains correction state but no receipts.
        CreateLifecycleThresholdCandidate(DocHeader, Transmission);
        DocHeader."Allow Correction" := true;
        DocHeader."IRIS Needs Correction" := true;
        DocHeader."IRIS Updated Not Sent" := true;
        DocHeader."IRIS Corrected" := true;
        DocHeader."IRIS Corrected to Zeros" := true;
        DocHeader.Modify(true);
        Commit();

        // [WHEN] The nonfiling update is selected.
        asserterror LibraryIRS1099Document.UpdateTransmission(Transmission);

        // [THEN] All correction flags remain available to the existing correction workflow.
        VerifyRejectedLifecycleUpdate(DocHeader);
    end;

    [Test]
    [HandlerFunctions('AcceptDocumentUpdateHandler')]
    procedure LifecycleExactAttemptUpdateIsRejected()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        Transmission: Record "Transmission IRIS";
        Attempt: Record "Transmission Log IRIS";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] An exact document's failed send attempt in an older transmission remains unsafe without a receipt.
        Initialize();

        // [GIVEN] Released D has no header filing markers but is linked to an earlier send attempt.
        CreateLifecycleThresholdCandidate(DocHeader, Transmission);
        DocHeader.Status := DocHeader.Status::Released;
        DocHeader.Modify(true);
        CreateLifecycleAttempt(Attempt, DocHeader, Transmission."Document ID" + 1, true);
        Commit();

        // [WHEN] The nonfiling update is selected.
        asserterror LibraryIRS1099Document.UpdateTransmission(Transmission);

        // [THEN] Exact attempt metadata, the link and saved disclosures survive.
        VerifyRejectedLifecycleUpdate(DocHeader);
        VerifyLifecycleAttempt(Attempt, DocHeader.ID);
    end;

    [Test]
    [HandlerFunctions('AcceptDocumentUpdateHandler')]
    procedure LifecycleOrphanAttemptUpdateIsRejected()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        Transmission: Record "Transmission IRIS";
        Attempt: Record "Transmission Log IRIS";
        StoredAttempt: Record "Transmission Log IRIS";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Missing attempt-header metadata cannot turn an exact document association into proof of no send.
        Initialize();

        // [GIVEN] D has an orphaned log line and no header filing markers.
        CreateLifecycleThresholdCandidate(DocHeader, Transmission);
        CreateLifecycleAttempt(Attempt, DocHeader, Transmission."Document ID", false);
        Commit();

        // [WHEN] The nonfiling update is selected.
        asserterror LibraryIRS1099Document.UpdateTransmission(Transmission);

        // [THEN] Ambiguous history is retained and requires existing attempt resolution.
        VerifyRejectedLifecycleUpdate(DocHeader);
        Assert.IsFalse(StoredAttempt.Get(Attempt."Line ID"), 'No attempt header may be invented.');
        VerifyLifecycleAttemptLine(Attempt."Line ID", DocHeader.ID);
    end;

    [Test]
    [HandlerFunctions('AcceptDocumentUpdateHandler')]
    procedure LifecycleMixedUnsafeSelectionRollsBack()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        UnsafeDocHeader: Record "IRS 1099 Form Doc. Header";
        UnlinkedDocHeader: Record "IRS 1099 Form Doc. Header";
        Transmission: Record "Transmission IRIS";
        ParentDocLine: Record "IRS 1099 Form Doc. Line";
        Details: Record "IRS 1099 Form Doc. Line Detail";
        DetailEntryNo: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] An unsafe threshold update rolls back valid line changes, details and proposed attachments together.
        Initialize();

        // [GIVEN] D1 has a valid amount update, D2 has filed, and U is a staged attachment.
        CreateSupplementalUpdateDocument(DocHeader, 5000, 100);
        CreateAdditionalSupplementalDocument(UnsafeDocHeader, DocHeader, 1500, 100);
        SetFinancialParent(UnsafeDocHeader.ID, 1500, 600);
        CreateAdditionalSupplementalDocument(UnlinkedDocHeader, DocHeader, 5000, 100);
        LibraryIRS1099Document.ReleaseDocument(UnlinkedDocHeader);
        SetDocumentAdjustment(DocHeader, 'NEC-01', 4000);
        FindFinancialParent(DocHeader.ID, ParentDocLine);
        DetailEntryNo := CreateRoutingDetail(Details, ParentDocLine, 5000);
        InitializeUpdateTransmission(Transmission, DocHeader);
        UnsafeDocHeader.Status := UnsafeDocHeader.Status::Submitted;
        UnsafeDocHeader."IRIS Submission Status" := UnsafeDocHeader."IRIS Submission Status"::Accepted;
        UnsafeDocHeader."IRIS Transmission Document ID" := Transmission."Document ID";
        UnsafeDocHeader.Modify(true);
        Commit();

        // [WHEN] All candidates are selected.
        asserterror LibraryIRS1099Document.UpdateTransmission(Transmission);

        // [THEN] No selected financial change, detail deletion or staged attachment survives.
        VerifyRejectedLifecycleUpdate(UnsafeDocHeader);
        VerifyFinancialState(DocHeader.ID, 5000, true);
        VerifySavedTips(DocHeader.ID, 100);
        VerifyRoutedDetail(DocHeader.ID, 'NEC-01', DetailEntryNo, 5000);
        VerifyDocumentLink(UnlinkedDocHeader.ID, 0);
    end;

    [Test]
    [HandlerFunctions('AcceptDocumentUpdateHandler,IgnoreLifecycleMessageHandler')]
    procedure LifecycleOtherDocumentHistoryAllowsUnsentUpdate()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        OtherDocHeader: Record "IRS 1099 Form Doc. Header";
        Transmission: Record "Transmission IRIS";
        Attempt: Record "Transmission Log IRIS";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Another document's history in the same transmission does not make a new released return sent.
        Initialize();

        // [GIVEN] Released D is unsent, while O has history in the same transmission.
        CreateLifecycleThresholdCandidate(DocHeader, Transmission);
        DocHeader.Status := DocHeader.Status::Released;
        DocHeader.Modify(true);
        CreateAdditionalSupplementalDocument(OtherDocHeader, DocHeader, 5000, 100);
        CreateLifecycleAttempt(Attempt, OtherDocHeader, Transmission."Document ID", true);
        Commit();

        // [WHEN] D's eligibility-only update is selected.
        LibraryIRS1099Document.UpdateTransmission(Transmission);

        // [THEN] D becomes Open/unlinked with saved values; O's history is unchanged.
        DocHeader.Get(DocHeader.ID);
        Assert.AreEqual(DocHeader.Status::Open, DocHeader.Status, 'A demonstrably unsent nonfiling document stays editable.');
        VerifyDocumentLink(DocHeader.ID, 0);
        VerifyFinancialState(DocHeader.ID, 1500, false);
        VerifySavedTips(DocHeader.ID, 100);
        VerifyLifecycleAttempt(Attempt, OtherDocHeader.ID);
    end;

    [Test]
    [HandlerFunctions('InspectEligibilityDeclineUpdateHandler,IgnoreLifecycleMessageHandler')]
    procedure SupplementalThresholdOnlyChangeIsOffered()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        TempDocLine: Record "IRS 1099 Form Doc. Line" temporary;
        TempDetails: Record "IRS 1099 Form Doc. Line Detail" temporary;
        FormBox: Record "IRS 1099 Form Box";
        Transmission: Record "Transmission IRIS";
        Details: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] An unchanged 1500 payment is offered after its threshold changes from 600 to 2000.
        Initialize();

        // [GIVEN] D stores an included 1500 payment under threshold 600.
        CreateSupplementalUpdateDocument(DocHeader, 1500, 100);
        SetFinancialParent(DocHeader.ID, 1500, 600);
        FormBox.Get(DocHeader."Period No.", 'NEC', 'NEC-01');
        FormBox."Minimum Reportable Amount" := 600;
        FormBox.Modify(true);

        // [WHEN] Annual setup identifies D and recalculation candidates are explicitly staged.
        Details := LibraryIRSReportingPeriod.ReconcileAnnualSetup(DocHeader."Period No.", CompanyName());
        LibraryIRS1099Document.GetDocumentUpdateCandidates(TempDocLine, TempDetails, DocHeader."Period No.");

        // [THEN] The unchanged amount has an explicit threshold/inclusion update.
        Assert.IsTrue(Details.Contains('needs recalculation'), 'Annual setup must identify stale Open documents.');
        Assert.RecordCount(TempDocLine, 1);
        TempDocLine.FindFirst();
        Assert.AreEqual(1500, TempDocLine.Amount, 'The amount has not changed.');
        Assert.AreEqual(2000, TempDocLine."Minimum Reportable Amount", 'The proposed threshold must be refreshed.');
        Assert.IsFalse(TempDocLine."Include In 1099", 'The proposed parent is below threshold.');
        VerifyFinancialState(DocHeader.ID, 1500, true);

        // [WHEN] The operator reviews the eligibility comparison and explicitly deselects D.
        InitializeUpdateTransmission(Transmission, DocHeader);
        Commit();
        LibraryIRS1099Document.UpdateTransmission(Transmission);

        // [THEN] Equal amounts still display the minimum/inclusion change without applying it.
        VerifyEligibilityPageRow(true, 1500, 600, true, 1500, 2000, false, false);
        VerifyFinancialState(DocHeader.ID, 1500, true);
        VerifyStoredMinimum(DocHeader.ID, 600);
        VerifyDocumentLink(DocHeader.ID, 0);
        VerifySavedTips(DocHeader.ID, 100);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('InspectEligibilityTransitionCancelHandler,IgnoreLifecycleMessageHandler')]
    procedure EligibilityComparisonCreateTransitionCancellation()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        Transmission: Record "Transmission IRIS";
        DocLine: Record "IRS 1099 Form Doc. Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Moving existing -> Create -> existing clears missing current values and cancellation persists nothing.
        Initialize();

        // [GIVEN] D has a threshold-only update and a proposed new form box.
        CreateLifecycleThresholdCandidate(DocHeader, Transmission);
        AddFinancialDefinition(DocHeader, 'NEC-03', 0);
        SetDocumentAdjustment(DocHeader, 'NEC-03', 200);
        Commit();

        // [WHEN] The operator inspects both rows and cancels.
        LibraryIRS1099Document.UpdateTransmission(Transmission);

        // [THEN] Create has no predecessor, returning restores D's current values, and nothing is applied.
        VerifyEligibilityPageRow(true, 1500, 600, true, 1500, 2000, false, true);
        VerifyEligibilityPageRow(false, 0, 0, false, 200, 0, true, true);
        VerifyEligibilityPageRow(true, 1500, 600, true, 1500, 2000, false, true);
        VerifyFinancialState(DocHeader.ID, 1500, true);
        VerifyStoredMinimum(DocHeader.ID, 600);
        VerifyDocumentLink(DocHeader.ID, Transmission."Document ID");
        VerifySavedTips(DocHeader.ID, 100);
        DocLine.SetRange("Document ID", DocHeader.ID);
        Assert.RecordCount(DocLine, 1);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CancelDocumentUpdateHandler,IgnoreLifecycleMessageHandler')]
    procedure SupplementalUpdateCancellationDoesNotAttachDocuments()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        UnlinkedDocHeader: Record "IRS 1099 Form Doc. Header";
        Transmission: Record "Transmission IRIS";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Cancelling selection does not attach an otherwise eligible unlinked document.
        Initialize();

        // [GIVEN] D needs recalculation and U is an unlinked released document.
        CreateSupplementalUpdateDocument(DocHeader, 5000, 100);
        CreateAdditionalSupplementalDocument(UnlinkedDocHeader, DocHeader, 5000, 100);
        LibraryIRS1099Document.ReleaseDocument(UnlinkedDocHeader);
        SetDocumentAdjustment(DocHeader, 'NEC-01', 4000);
        InitializeUpdateTransmission(Transmission, DocHeader);
        Commit();

        // [WHEN] The selection is cancelled.
        LibraryIRS1099Document.UpdateTransmission(Transmission);

        // [THEN] Documents, links and disclosures are unchanged.
        VerifyFinancialState(DocHeader.ID, 5000, true);
        VerifyDocumentLink(UnlinkedDocHeader.ID, 0);
        VerifySavedTips(DocHeader.ID, 100);
    end;

    [Test]
    [HandlerFunctions('AcceptDocumentUpdateHandler')]
    procedure SupplementalRejectedUpdateRollsBackAllDocumentsAndLinks()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        SecondDocHeader: Record "IRS 1099 Form Doc. Header";
        UnlinkedDocHeader: Record "IRS 1099 Form Doc. Header";
        Transmission: Record "Transmission IRIS";
        PostedPayment: Record "Vendor Ledger Entry";
        DetailedEntry: Record "Detailed Vendor Ledg. Entry";
        DetailedEntryCount: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A retained breakdown exceeding its parent amount rolls back every selected document and proposed attachment.
        Initialize();

        // [GIVEN] D1 and D2 need updates; U is a proposed attachment.
        CreateSupplementalUpdateDocument(DocHeader, 5000, 100);
        CreateAdditionalSupplementalDocument(SecondDocHeader, DocHeader, 5000, 100);
        CreateAdditionalSupplementalDocument(UnlinkedDocHeader, DocHeader, 5000, 100);
        PostSupplementalFixturePayment(PostedPayment, DocHeader."Vendor No.");
        DetailedEntry.SetRange("Vendor Ledger Entry No.", PostedPayment."Entry No.");
        DetailedEntryCount := DetailedEntry.Count();
        LibraryIRS1099Document.ReleaseDocument(UnlinkedDocHeader);
        SetDocumentAdjustment(DocHeader, 'NEC-01', 4000);
        SetDocumentAdjustment(SecondDocHeader, 'NEC-01', 50);
        InitializeUpdateTransmission(Transmission, DocHeader);
        Commit();

        // [WHEN] All candidates are accepted, including D2's parent amount of 50, below its saved tips.
        asserterror LibraryIRS1099Document.UpdateTransmission(Transmission);

        // [THEN] No selected financial change or association survives.
        Assert.ExpectedError('between zero and the amount 50 on the parent document line');
        Assert.ExpectedErrorCode('Dialog');
        VerifyFinancialState(DocHeader.ID, 5000, true);
        VerifyFinancialState(SecondDocHeader.ID, 5000, true);
        VerifyDocumentLink(UnlinkedDocHeader.ID, 0);
        VerifySavedTips(SecondDocHeader.ID, 100);
        VerifyPostedPaymentUnchanged(PostedPayment, DetailedEntryCount);
    end;

    [Test]
    procedure SupplementalBreakdownsDoNotIncreaseIncome()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        OvertimeSupplLine: Record "IRS 1099 Doc. Suppl. Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Tips 100 and overtime 50 are breakdowns of compensation 5000, not extra income.
        Initialize();

        // [GIVEN] D has compensation 5000 and tips 100.
        CreateSupplementalUpdateDocument(DocHeader, 5000, 100);
        CreateSupplementalLine(OvertimeSupplLine, DocHeader.ID, 'NEC-01D');
        OvertimeSupplLine.Validate(Amount, 50);
        OvertimeSupplLine.Modify(true);

        // [WHEN] D is validated and released.
        LibraryIRS1099Document.ReleaseDocument(DocHeader);

        // [THEN] Financial income stays 5000 and the separate overtime remains reportable.
        VerifyFinancialState(DocHeader.ID, 5000, true);
        VerifySavedTips(DocHeader.ID, 100);
        Assert.AreEqual(50, OvertimeSupplLine.Amount, 'Overtime must remain a separate breakdown.');
        Assert.IsTrue(LibraryIRS1099Document.IsSupplementalReportable(OvertimeSupplLine), 'Overtime must follow compensation eligibility.');
    end;

    [Test]
    procedure SupplementalAmountsHaveNoCombinedCeiling()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        OvertimeSupplLine: Record "IRS 1099 Doc. Suppl. Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Individually valid tips and overtime are not subject to an invented combined ceiling.
        Initialize();

        // [GIVEN] Each breakdown is 4000 against compensation 5000.
        CreateSupplementalUpdateDocument(DocHeader, 5000, 4000);
        CreateSupplementalLine(OvertimeSupplLine, DocHeader.ID, 'NEC-01D');
        OvertimeSupplLine.Validate(Amount, 4000);
        OvertimeSupplLine.Modify(true);

        // [WHEN] D is released.
        LibraryIRS1099Document.ReleaseDocument(DocHeader);

        // [THEN] Both breakdowns survive and income is unchanged.
        VerifyFinancialState(DocHeader.ID, 5000, true);
        VerifySavedTips(DocHeader.ID, 4000);
        Assert.AreEqual(4000, OvertimeSupplLine.Amount, 'No combined ceiling may truncate overtime.');
    end;

    [Test]
    [HandlerFunctions('AcceptDocumentUpdateHandler')]
    procedure SupplementalMissingParentUpdateRollsBack()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        Adjustment: Record "IRS 1099 Vendor Form Box Adj.";
        Transmission: Record "Transmission IRIS";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Recalculation is not consent to delete a populated supplemental parent.
        Initialize();

        // [GIVEN] D's only calculation source is removed, but saved tips remain.
        CreateSupplementalUpdateDocument(DocHeader, 5000, 100);
        Adjustment.Get(DocHeader."Period No.", DocHeader."Vendor No.", DocHeader."Form No.", 'NEC-01');
        Adjustment.Delete(true);
        AddFinancialDefinition(DocHeader, 'NEC-03', 0);
        SetDocumentAdjustment(DocHeader, 'NEC-03', 200);
        InitializeUpdateTransmission(Transmission, DocHeader);
        Commit();

        // [WHEN] Removal of the missing financial parent is accepted.
        asserterror LibraryIRS1099Document.UpdateTransmission(Transmission);

        // [THEN] D and its saved disclosures survive unchanged.
        Assert.ExpectedError('Recalculation would remove the document line for that form box');
        Assert.ExpectedErrorCode('Dialog');
        VerifyFinancialState(DocHeader.ID, 5000, true);
        VerifySavedTips(DocHeader.ID, 100);
        DocHeader.Get(DocHeader.ID);
        Assert.AreEqual(DocHeader.Status::Open, DocHeader.Status, 'Failure must preserve the original document.');
    end;

    [Test]
    procedure SupplementalNonfilingRecreationRetainsStoredDisclosures()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        OldDocumentID: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Same-identity recreation retains valid disclosures even with no filing eligibility.
        Initialize();

        // [GIVEN] D will recalculate from 5000 to excluded compensation 500.
        CreateSupplementalUpdateDocument(DocHeader, 5000, 100);
        OldDocumentID := DocHeader.ID;
        SetDocumentAdjustment(DocHeader, 'NEC-01', 500);

        // [WHEN] The document is recreated.
        LibraryIRS1099Document.CreateFormDocuments(DMY2Date(1, 1, 2026), DMY2Date(31, 12, 2026),
            DocHeader."Vendor No.", DocHeader."Form No.", true);

        // [THEN] The new identity remains Open and unlinked with its valid stored values.
        FindReplacementDocument(DocHeader);
        Assert.AreNotEqual(OldDocumentID, DocHeader.ID, 'Recreation must allocate a new identity.');
        Assert.AreEqual(DocHeader.Status::Open, DocHeader.Status, 'Nonfiling disclosures must remain editable.');
        VerifyFinancialState(DocHeader.ID, 500, false);
        VerifyDocumentLink(DocHeader.ID, 0);
        VerifySavedTips(DocHeader.ID, 100);
    end;

    [Test]
    procedure SupplementalParentReassignmentIsRejected()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        ParentDocLine: Record "IRS 1099 Form Doc. Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A linked parent cannot be reassigned to another form box.
        Initialize();

        // [GIVEN] D has a financial parent referenced by saved tips.
        CreateSupplementalUpdateDocument(DocHeader, 5000, 100);
        AddFinancialDefinition(DocHeader, 'NEC-03', 0);
        FindFinancialParent(DocHeader.ID, ParentDocLine);
        Commit();

        // [WHEN] The parent box is changed without correcting the disclosures.
        asserterror ParentDocLine.Validate("Form Box No.", 'NEC-03');

        // [THEN] An actionable error preserves the original parent relationship.
        Assert.ExpectedError('Remove those lines in Supplemental Lines before changing the form box');
        Assert.ExpectedErrorCode('Dialog');
        VerifyFinancialState(DocHeader.ID, 5000, true);
        VerifySavedTips(DocHeader.ID, 100);
    end;

    [Test]
    procedure SupplementalAttachOnlyFailureRollsBackEarlierAttachment()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        ExcessTipsDocHeader: Record "IRS 1099 Form Doc. Header";
        TipsSupplLine: Record "IRS 1099 Doc. Suppl. Line";
        Transmission: Record "Transmission IRIS";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Stored tips exceeding parent income on a proposed attachment roll back the attach-only operation.
        Initialize();

        // [GIVEN] D1 and D2 have no calculation changes, but D2 contains imported tips exceeding parent income.
        CreateSupplementalUpdateDocument(DocHeader, 5000, 100);
        CreateAdditionalSupplementalDocument(ExcessTipsDocHeader, DocHeader, 5000, 100);
        LibraryIRS1099Document.ReleaseDocument(DocHeader);
        LibraryIRS1099Document.ReleaseDocument(ExcessTipsDocHeader);
        TipsSupplLine.Get(ExcessTipsDocHeader.ID, 'NEC-01B');
        TipsSupplLine.Amount := 6000;
        TipsSupplLine.Modify(false);
        InitializeUpdateTransmission(Transmission, DocHeader);
        Commit();

        // [WHEN] Both proposed attachments are applied without a selection page.
        asserterror LibraryIRS1099Document.UpdateTransmission(Transmission);

        // [THEN] Neither association survives validation failure.
        Assert.ExpectedError('supplemental box NEC-01B');
        Assert.ExpectedError('must be between zero and the amount');
        Assert.ExpectedErrorCode('Dialog');
        VerifyDocumentLink(DocHeader.ID, 0);
        VerifyDocumentLink(ExcessTipsDocHeader.ID, 0);
        VerifySavedTips(ExcessTipsDocHeader.ID, 6000);
    end;

    [Test]
    [HandlerFunctions('InspectWithholdingUpdateHandler,IgnoreLifecycleMessageHandler')]
    procedure SupplementalWithholdingRemovalRefreshesEligibility()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        Transmission: Record "Transmission IRIS";
        TipsSupplLine: Record "IRS 1099 Doc. Suppl. Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Removing backup withholding offers unchanged compensation's inclusion-only update.
        Initialize();

        // [GIVEN] Released D has compensation 500 qualified by withholding 50.
        CreateSupplementalUpdateDocument(DocHeader, 500, 100);
        AddFinancialBox(DocHeader, 'NEC-04', 50, 0);
        SetDocumentAdjustment(DocHeader, 'NEC-04', 50);
        LibraryIRS1099Document.ReleaseDocument(DocHeader);
        SetDocumentAdjustment(DocHeader, 'NEC-04', 0);
        InitializeUpdateTransmission(Transmission, DocHeader);
        Commit();

        // [WHEN] The explicitly selected recalculation removes withholding.
        LibraryIRS1099Document.UpdateTransmission(Transmission);

        // [THEN] Income remains 500, but its saved tips no longer qualify for filing.
        VerifyEligibilityPageRow(true, 500, 2000, true, 500, 2000, false, true);
        VerifyFinancialState(DocHeader.ID, 500, false);
        VerifySavedTips(DocHeader.ID, 100);
        TipsSupplLine.Get(DocHeader.ID, 'NEC-01B');
        Assert.IsFalse(LibraryIRS1099Document.IsSupplementalReportable(TipsSupplLine), 'Removed withholding cannot continue qualifying tips.');
        VerifyDocumentLink(DocHeader.ID, 0);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalSetupThresholdChangePreservesSubmittedDocument()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        FormBox: Record "IRS 1099 Form Box";
        ParentDocLine: Record "IRS 1099 Form Doc. Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A setup threshold edit does not rewrite a submitted document or its saved eligibility.
        Initialize();

        // [GIVEN] Submitted D stores income 1500 under threshold 600 and saved disclosures.
        CreateSupplementalUpdateDocument(DocHeader, 1500, 100);
        SetFinancialParent(DocHeader.ID, 1500, 600);
        DocHeader.Status := DocHeader.Status::Submitted;
        DocHeader."IRIS Last Receipt ID" := 'SAVED-RECEIPT';
        DocHeader.Modify(true);
        FormBox.Get(DocHeader."Period No.", 'NEC', 'NEC-01');

        FormBox."Minimum Reportable Amount" := 600;
        FormBox.Modify(true);

        // [WHEN] Annual reconciliation changes setup to threshold 2000.
        LibraryIRSReportingPeriod.ReconcileAnnualSetup(DocHeader."Period No.", CompanyName());

        // [THEN] Submitted data retains its stored amount, threshold, inclusion, disclosures and receipt.
        DocHeader.Get(DocHeader.ID);
        Assert.AreEqual(DocHeader.Status::Submitted, DocHeader.Status, 'Setup must not rewrite submitted status.');
        Assert.AreEqual('SAVED-RECEIPT', DocHeader."IRIS Last Receipt ID", 'Setup must preserve submitted identity.');
        VerifyFinancialState(DocHeader.ID, 1500, true);
        FindFinancialParent(DocHeader.ID, ParentDocLine);
        Assert.AreEqual(600, ParentDocLine."Minimum Reportable Amount", 'Submitted thresholds are stored snapshots.');
        VerifySavedTips(DocHeader.ID, 100);
    end;

    [Test]
    [HandlerFunctions('SelectVendorDocumentUpdateHandler,IgnoreLifecycleMessageHandler')]
    procedure SupplementalSelectedUpdatePreservesUnselectedManualAmount()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        OtherDocHeader: Record "IRS 1099 Form Doc. Header";
        ParentDocLine: Record "IRS 1099 Form Doc. Line";
        Transmission: Record "Transmission IRIS";
        FormBox: Record "IRS 1099 Form Box";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Only the selected manual amount and threshold are replaced by explicit recalculation.
        Initialize();

        // [GIVEN] Two documents store manual income 1750 under threshold 600; current calculation is 1500/2000.
        CreateSupplementalUpdateDocument(DocHeader, 1500, 100);
        CreateAdditionalSupplementalDocument(OtherDocHeader, DocHeader, 1500, 100);
        SetManualFinancialParent(DocHeader.ID, 1750, 600);
        SetManualFinancialParent(OtherDocHeader.ID, 1750, 600);
        FormBox.Get(DocHeader."Period No.", 'NEC', 'NEC-01');
        FormBox."Minimum Reportable Amount" := 600;
        FormBox.Modify(true);
        LibraryIRSReportingPeriod.ReconcileAnnualSetup(DocHeader."Period No.", CompanyName());
        InitializeUpdateTransmission(Transmission, DocHeader);
        LibraryVariableStorage.Enqueue(DocHeader."Vendor No.");
        Commit();

        // [WHEN] Only D1 is selected.
        LibraryIRS1099Document.UpdateTransmission(Transmission);

        // [THEN] D1 recalculates explicitly; D2's manual amount and stored threshold remain unchanged.
        VerifyFinancialState(DocHeader.ID, 1500, false);
        VerifyFinancialState(OtherDocHeader.ID, 1750, true);
        FindFinancialParent(OtherDocHeader.ID, ParentDocLine);
        Assert.AreEqual(600, ParentDocLine."Minimum Reportable Amount", 'Unselected thresholds must remain stored snapshots.');
        Assert.IsTrue(ParentDocLine."Manually Changed", 'Unselected manual values must remain manual.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('IgnoreLifecycleMessageHandler')]
    procedure SupplementalAttachOnlyUpdateIsPreserved()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        Transmission: Record "Transmission IRIS";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] An up-to-date released document can still be attached without a selection page.
        Initialize();

        // [GIVEN] D has valid disclosures and no financial changes.
        CreateSupplementalUpdateDocument(DocHeader, 5000, 100);
        LibraryIRS1099Document.ReleaseDocument(DocHeader);
        InitializeUpdateTransmission(Transmission, DocHeader);
        Commit();

        // [WHEN] The transmission is updated.
        LibraryIRS1099Document.UpdateTransmission(Transmission);

        // [THEN] D is attached with its original financial and supplemental amounts.
        VerifyDocumentLink(DocHeader.ID, Transmission."Document ID");
        VerifyFinancialState(DocHeader.ID, 5000, true);
        VerifySavedTips(DocHeader.ID, 100);
    end;

    [Test]
    [HandlerFunctions('AcceptDocumentUpdateHandler,IgnoreLifecycleMessageHandler')]
    procedure SupplementalNonfilingUpdateRetainsOpenDocument()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        Transmission: Record "Transmission IRIS";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Valid disclosures survive an update that excludes every financial line.
        Initialize();

        // [GIVEN] Released D has 5000 income and valid tips, and will recalculate to 500.
        CreateSupplementalUpdateDocument(DocHeader, 5000, 100);
        LibraryIRS1099Document.ReleaseDocument(DocHeader);
        SetDocumentAdjustment(DocHeader, 'NEC-01', 500);
        InitializeUpdateTransmission(Transmission, DocHeader);
        Commit();

        // [WHEN] The recalculation is accepted.
        LibraryIRS1099Document.UpdateTransmission(Transmission);

        // [THEN] D remains Open and unlinked with the excluded parent and tips.
        DocHeader.Get(DocHeader.ID);
        Assert.AreEqual(DocHeader.Status::Open, DocHeader.Status, 'A nonfiling document must remain editable.');
        VerifyFinancialState(DocHeader.ID, 500, false);
        VerifyDocumentLink(DocHeader.ID, 0);
        VerifySavedTips(DocHeader.ID, 100);
    end;

    [Test]
    procedure SupplementalRecreationTransfersBeforeHeaderCleanup()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        SupplLine: Record "IRS 1099 Doc. Suppl. Line";
        OldDocumentID: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Deleting and recreating D transfers disclosures to its actual new identity.
        Initialize();

        // [GIVEN] D has saved tips and a parent that will be renumbered.
        CreateSupplementalUpdateDocument(DocHeader, 5000, 100);
        OldDocumentID := DocHeader.ID;

        // [WHEN] The same year/vendor/form is recreated.
        LibraryIRS1099Document.CreateFormDocuments(DMY2Date(1, 1, 2026), DMY2Date(31, 12, 2026),
            DocHeader."Vendor No.", DocHeader."Form No.", true);

        // [THEN] Only the new document owns the transferred values.
        FindReplacementDocument(DocHeader);
        Assert.AreNotEqual(OldDocumentID, DocHeader.ID, 'The new identity must not be assumed equal to the old one.');
        VerifySavedTips(DocHeader.ID, 100);
        SupplLine.SetRange("Document ID", OldDocumentID);
        Assert.RecordIsEmpty(SupplLine);
        VerifyFinancialState(DocHeader.ID, 5000, true);
    end;

    [Test]
    procedure SupplementalRejectedRecreationRestoresOriginalDocument()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        OldDocumentID: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Rejected recreation cannot destroy the source header or its supplements.
        Initialize();

        // [GIVEN] D's recalculated income of 50 is smaller than saved tips of 100.
        CreateSupplementalUpdateDocument(DocHeader, 5000, 100);
        OldDocumentID := DocHeader.ID;
        SetDocumentAdjustment(DocHeader, 'NEC-01', 50);
        Commit();

        // [WHEN] The same-identity recreation is attempted.
        asserterror LibraryIRS1099Document.CreateFormDocuments(DMY2Date(1, 1, 2026), DMY2Date(31, 12, 2026),
            DocHeader."Vendor No.", DocHeader."Form No.", true);

        // [THEN] Original identity and values survive.
        Assert.ExpectedError('between zero and the amount 50 on the parent document line');
        Assert.ExpectedErrorCode('Dialog');
        DocHeader.Get(OldDocumentID);
        VerifyFinancialState(OldDocumentID, 5000, true);
        VerifySavedTips(OldDocumentID, 100);
    end;

    [Test]
    [HandlerFunctions('AcceptDocumentUpdateHandler,IgnoreLifecycleMessageHandler')]
    procedure SupplementalAbandonedReplacementCopiesWithoutDeletingHistory()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        OldDocHeader: Record "IRS 1099 Form Doc. Header";
        Transmission: Record "Transmission IRIS";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A replacement copies disclosures while retaining the Abandoned source values.
        Initialize();

        // [GIVEN] D needs an additional form box.
        CreateSupplementalUpdateDocument(DocHeader, 5000, 100);
        AddFinancialDefinition(DocHeader, 'NEC-03', 0);
        SetDocumentAdjustment(DocHeader, 'NEC-03', 200);
        OldDocHeader := DocHeader;
        InitializeUpdateTransmission(Transmission, DocHeader);
        Commit();

        // [WHEN] Creation of the additional box is accepted.
        LibraryIRS1099Document.UpdateTransmission(Transmission);

        // [THEN] Source history and new document have separate, preserved disclosures.
        OldDocHeader.Get(OldDocHeader.ID);
        Assert.AreEqual(OldDocHeader.Status::Abandoned, OldDocHeader.Status, 'The source must remain in history.');
        FindReplacementDocument(DocHeader);
        Assert.AreNotEqual(OldDocHeader.ID, DocHeader.ID, 'A replacement must have its own identity.');
        VerifySavedTips(OldDocHeader.ID, 100);
        VerifySavedTips(DocHeader.ID, 100);
        VerifyDocumentLink(DocHeader.ID, Transmission."Document ID");
    end;

    [Test]
    procedure SupplementalReplacementUsesExactSourcesAndDetails()
    var
        FirstDocHeader: Record "IRS 1099 Form Doc. Header";
        SecondDocHeader: Record "IRS 1099 Form Doc. Header";
        OtherDocHeader: Record "IRS 1099 Form Doc. Header";
        ParentDocLine: Record "IRS 1099 Form Doc. Line";
        TempDocLine: Record "IRS 1099 Form Doc. Line" temporary;
        TempDetails: Record "IRS 1099 Form Doc. Line Detail" temporary;
        StoredDetails: Record "IRS 1099 Form Doc. Line Detail";
        RoutingSubscriber: Codeunit "IRS 1099 Document Tests";
        NewDocumentIDs: List of [Integer];
        FirstParentEntryNo: Integer;
        SecondParentEntryNo: Integer;
        FirstNewEntryNo: Integer;
        SecondNewEntryNo: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Exact source IDs isolate replacement disclosures and both retained and new financial details.
        Initialize();

        // [GIVEN] D1 and D2 share vendor/form but have different saved values; D3 belongs to another vendor.
        CreateSupplementalUpdateDocument(FirstDocHeader, 5000, 100);
        CreateSameVendorSupplementalDocument(SecondDocHeader, FirstDocHeader, 6000, 200);
        CreateAdditionalSupplementalDocument(OtherDocHeader, FirstDocHeader, 7000, 300);
        AddFinancialDefinition(FirstDocHeader, 'NEC-03', 0);
        FindFinancialParent(FirstDocHeader.ID, ParentDocLine);
        FirstParentEntryNo := CreateRoutingDetail(StoredDetails, ParentDocLine, 5000);
        FindFinancialParent(SecondDocHeader.ID, ParentDocLine);
        SecondParentEntryNo := CreateRoutingDetail(StoredDetails, ParentDocLine, 6000);
        AddCreateCandidate(TempDocLine, FirstDocHeader, FirstDocHeader.ID, 7000, 201);
        FirstNewEntryNo := CreateRoutingDetail(TempDetails, TempDocLine, 201);
        AddCreateCandidate(TempDocLine, SecondDocHeader, SecondDocHeader.ID, 3000, 202);
        SecondNewEntryNo := CreateRoutingDetail(TempDetails, TempDocLine, 202);

        // [WHEN] The real replacement apply accepts the exact-source candidates together.
        BindSubscription(RoutingSubscriber);
        NewDocumentIDs := LibraryIRS1099Document.ApplyDocumentCreationCandidates(TempDocLine, TempDetails);
        UnbindSubscription(RoutingSubscriber);

        // [THEN] Each replacement has only its source's saved values and ledger details after renumbering.
        Assert.AreEqual(2, NewDocumentIDs.Count(), 'Both exact sources need independent replacements.');
        VerifyReplacementRouting(NewDocumentIDs.Get(1), 100, FirstParentEntryNo, 5000, FirstNewEntryNo, 201);
        VerifyReplacementRouting(NewDocumentIDs.Get(2), 200, SecondParentEntryNo, 6000, SecondNewEntryNo, 202);
        VerifyAbandonedSource(FirstDocHeader.ID, 100);
        VerifyAbandonedSource(SecondDocHeader.ID, 200);
        VerifySavedTips(OtherDocHeader.ID, 300);
        OtherDocHeader.Get(OtherDocHeader.ID);
        Assert.AreEqual(OtherDocHeader.Status::Open, OtherDocHeader.Status, 'Another vendor must not be replaced.');
    end;

    [Test]
    procedure SupplementalReplacementRequiresUnambiguousSource()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        SecondDocHeader: Record "IRS 1099 Form Doc. Header";
        TempDocLine: Record "IRS 1099 Form Doc. Line" temporary;
        TempDetails: Record "IRS 1099 Form Doc. Line Detail" temporary;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] An unspecified source must not silently choose one of several active documents.
        Initialize();

        // [GIVEN] Two active documents share the candidate's period/vendor/form.
        CreateSupplementalUpdateDocument(DocHeader, 5000, 100);
        CreateSameVendorSupplementalDocument(SecondDocHeader, DocHeader, 6000, 200);
        AddFinancialDefinition(DocHeader, 'NEC-03', 0);
        AddCreateCandidate(TempDocLine, DocHeader, 0, 7000, 201);
        Commit();

        // [WHEN] A replacement is attempted without an exact source.
        asserterror LibraryIRS1099Document.ApplyDocumentCreationCandidates(TempDocLine, TempDetails);

        // [THEN] Neither source is changed or guessed.
        Assert.ExpectedError('Select the source document');
        Assert.ExpectedErrorCode('Dialog');
        VerifyOpenRoutingSource(DocHeader.ID, 100);
        VerifyOpenRoutingSource(SecondDocHeader.ID, 200);
    end;

    [Test]
    procedure SupplementalReplacementRejectsCrossFormSource()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        OtherDocHeader: Record "IRS 1099 Form Doc. Header";
        Form: Record "IRS 1099 Form";
        TempDocLine: Record "IRS 1099 Form Doc. Line" temporary;
        TempDetails: Record "IRS 1099 Form Doc. Line Detail" temporary;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A supplied source from another form is rejected rather than substituted.
        Initialize();

        // [GIVEN] A NEC candidate carries the ID of the same vendor's MISC document.
        CreateSupplementalUpdateDocument(DocHeader, 5000, 100);
        Form."Period No." := DocHeader."Period No.";
        Form."No." := 'MISC';
        Form.Insert(true);
        OtherDocHeader."Period No." := DocHeader."Period No.";
        OtherDocHeader."Vendor No." := DocHeader."Vendor No.";
        OtherDocHeader."Form No." := 'MISC';
        OtherDocHeader.Insert(true);
        AddFinancialDefinition(DocHeader, 'NEC-03', 0);
        AddCreateCandidate(TempDocLine, DocHeader, OtherDocHeader.ID, 7000, 201);
        Commit();

        // [WHEN] The incompatible exact source is applied.
        asserterror LibraryIRS1099Document.ApplyDocumentCreationCandidates(TempDocLine, TempDetails);

        // [THEN] Both identities and the NEC disclosures are unchanged.
        Assert.ExpectedError('Form No.');
        Assert.ExpectedErrorCode('TestField');
        VerifyOpenRoutingSource(DocHeader.ID, 100);
        OtherDocHeader.Get(OtherDocHeader.ID);
        Assert.AreEqual(OtherDocHeader.Status::Open, OtherDocHeader.Status, 'The other form must remain unchanged.');
    end;

    [Test]
    [HandlerFunctions('AcceptDocumentUpdateHandler,IgnoreLifecycleMessageHandler')]
    procedure SupplementalMixedCreateAbandonDoesNotResurrectRemovedBox()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        OldDocHeader: Record "IRS 1099 Form Doc. Header";
        ParentDocLine: Record "IRS 1099 Form Doc. Line";
        RemovedDocLine: Record "IRS 1099 Form Doc. Line";
        Details: Record "IRS 1099 Form Doc. Line Detail";
        Transmission: Record "Transmission IRIS";
        ParentEntryNo: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A selected removal stays removed when another form box creates a replacement.
        Initialize();

        // [GIVEN] D retains compensation/details, removes withholding, and adds a different box.
        CreateSupplementalUpdateDocument(DocHeader, 5000, 100);
        AddFinancialBox(DocHeader, 'NEC-04', 50, 0);
        AddFinancialDefinition(DocHeader, 'NEC-03', 0);
        SetDocumentAdjustment(DocHeader, 'NEC-03', 200);
        FindFinancialParent(DocHeader.ID, ParentDocLine);
        ParentEntryNo := CreateRoutingDetail(Details, ParentDocLine, 5000);
        OldDocHeader := DocHeader;
        InitializeUpdateTransmission(Transmission, DocHeader);
        Commit();

        // [WHEN] The actual transmission update accepts Create and Abandon together.
        LibraryIRS1099Document.UpdateTransmission(Transmission);

        // [THEN] The new document retains the parent and its detail, but not the removed box.
        FindReplacementDocument(DocHeader);
        RemovedDocLine.SetRange("Document ID", DocHeader.ID);
        RemovedDocLine.SetRange("Form Box No.", 'NEC-04');
        Assert.RecordIsEmpty(RemovedDocLine);
        VerifyRoutedDetail(DocHeader.ID, 'NEC-01', ParentEntryNo, 5000);
        VerifySavedTips(DocHeader.ID, 100);
        VerifyAbandonedSource(OldDocHeader.ID, 100);
        VerifyDocumentLink(DocHeader.ID, Transmission."Document ID");
    end;

    [Test]
    [HandlerFunctions('DeclineSupplementalCascadeHandler')]
    procedure SupplementalParentDeletionCancellationIsAtomic()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        ParentDocLine: Record "IRS 1099 Form Doc. Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Declining the explicit supplemental cascade preserves parent and disclosures.
        Initialize();

        // [GIVEN] D has a financial parent with saved supplemental lines.
        CreateSupplementalUpdateDocument(DocHeader, 5000, 100);
        FindFinancialParent(DocHeader.ID, ParentDocLine);
        Commit();

        // [WHEN] The user declines the deliberate parent deletion.
        asserterror ParentDocLine.Delete(true);

        // [THEN] No values are removed.
        Assert.AreEqual('', GetLastErrorText(), 'Declining deletion must cancel without an error message.');
        VerifyFinancialState(DocHeader.ID, 5000, true);
        VerifySavedTips(DocHeader.ID, 100);
    end;

    [Test]
    [HandlerFunctions('AcceptSupplementalCascadeHandler')]
    procedure SupplementalParentDeletionCascadesOnlyLinkedRows()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        ParentDocLine: Record "IRS 1099 Form Doc. Line";
        SupplLine: Record "IRS 1099 Doc. Suppl. Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Confirmed deletion removes the parent and its supplements but not other financial lines.
        Initialize();

        // [GIVEN] D has a supplemental parent and an unrelated financial line.
        CreateSupplementalUpdateDocument(DocHeader, 5000, 100);
        AddFinancialBox(DocHeader, 'NEC-03', 200, 0);
        FindFinancialParent(DocHeader.ID, ParentDocLine);

        // [WHEN] The explicit supplemental cascade is confirmed.
        ParentDocLine.Delete(true);

        // [THEN] Only linked data is removed.
        ParentDocLine.Reset();
        ParentDocLine.SetRange("Document ID", DocHeader.ID);
        Assert.RecordCount(ParentDocLine, 1);
        ParentDocLine.FindFirst();
        Assert.AreEqual('NEC-03', ParentDocLine."Form Box No.", 'Unrelated financial data must remain.');
        SupplLine.SetRange("Document ID", DocHeader.ID);
        Assert.RecordIsEmpty(SupplLine);
    end;

    [Test]
    procedure SupplementalMISCMappingRejectsRents()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        IRS1099SupplBox: Record "IRS 1099 Suppl. Box";
        FormBox: Record "IRS 1099 Form Box";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] An unused MISC cash-tip definition cannot point at rents.
        Initialize();

        // [GIVEN] MISC other income and a separate valid rents box.
        LibraryIRS1099Document.CreateSupplementalDocument(DocHeader, 'MISC');
        FormBox."Period No." := DocHeader."Period No.";
        FormBox."Form No." := 'MISC';
        FormBox."No." := 'MISC-01';
        FormBox.Insert(true);
        IRS1099SupplBox.Get(DocHeader."Period No.", 'MISC', 'MISC-13A');
        IRS1099SupplBox."Parent Form Box No." := 'MISC-01';

        // [WHEN] The otherwise existing form box is assigned as the tip parent.
        asserterror IRS1099SupplBox.Modify(true);

        // [THEN] The full mapping tuple, not just parent existence, is enforced.
        Assert.ExpectedError('does not meet the reporting requirements');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure SupplementalMappingRejectsWrongValueType()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        IRS1099SupplBox: Record "IRS 1099 Suppl. Box";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A known amount mapping cannot be configured as codes.
        Initialize();

        // [GIVEN] An unused NEC cash-tip definition.
        LibraryIRS1099Document.CreateSupplementalDocument(DocHeader, 'NEC');
        IRS1099SupplBox.Get(DocHeader."Period No.", 'NEC', 'NEC-01B');
        IRS1099SupplBox."Value Type" := IRS1099SupplBox."Value Type"::"Occupation Codes";

        // [WHEN] Its stored type is changed.
        asserterror IRS1099SupplBox.Modify(true);

        // [THEN] The mapping cannot reinterpret amounts.
        Assert.ExpectedError('does not meet the reporting requirements');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure SupplementalMappingRejectsWrongElement()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        IRS1099SupplBox: Record "IRS 1099 Suppl. Box";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A known cash-tip identifier cannot serialize overtime.
        Initialize();

        // [GIVEN] An unused NEC cash-tip definition.
        LibraryIRS1099Document.CreateSupplementalDocument(DocHeader, 'NEC');
        IRS1099SupplBox.Get(DocHeader."Period No.", 'NEC', 'NEC-01B');
        IRS1099SupplBox."XML Element Name" := 'OvertimeCompensationAmt';

        // [WHEN] Its XML element is changed.
        asserterror IRS1099SupplBox.Modify(true);

        // [THEN] A valid but different XML element is rejected.
        Assert.ExpectedError('does not meet the reporting requirements');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure SupplementalCustomDefinitionRemainsEditable()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        IRS1099SupplBox: Record "IRS 1099 Suppl. Box";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Compatible descriptions and unmapped custom definitions remain editable.
        Initialize();

        // [GIVEN] An unused standard definition.
        LibraryIRS1099Document.CreateSupplementalDocument(DocHeader, 'NEC');
        IRS1099SupplBox.Get(DocHeader."Period No.", 'NEC', 'NEC-01B');

        // [WHEN] Its description is customized and a separate unmapped amount definition is added.
        IRS1099SupplBox.Description := 'Qualified cash tips';
        IRS1099SupplBox.Modify(true);
        IRS1099SupplBox."No." := 'CUSTOM';
        IRS1099SupplBox."XML Element Name" := '';
        IRS1099SupplBox.Insert(true);
        IRS1099SupplBox.Rename(IRS1099SupplBox."Period No.", 'NEC', 'CUSTOM-RENAMED');

        // [THEN] Custom setup has its own identity without claiming an XML mapping.
        IRS1099SupplBox.Get(DocHeader."Period No.", 'NEC', 'CUSTOM-RENAMED');
        Assert.AreEqual('Qualified cash tips', IRS1099SupplBox.Description, 'Description customization was lost.');
        Assert.AreEqual('', IRS1099SupplBox."XML Element Name", 'A custom definition must not acquire an XML mapping.');
    end;

    [Test]
    procedure SupplementalCodesRemainTextAndSeparateFromIncome()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        SupplLine: Record "IRS 1099 Doc. Suppl. Line";
        DocLine: Record "IRS 1099 Form Doc. Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Occupation codes preserve leading zeros without creating financial lines.
        Initialize();

        // [GIVEN] A NEC income document.
        LibraryIRS1099Document.CreateSupplementalDocument(DocHeader, 'NEC');
        CreateSupplementalLine(SupplLine, DocHeader.ID, 'NEC-01C');

        // [WHEN] Two valid text codes are stored.
        SupplLine.Validate("Occupation Code 1", '101');
        SupplLine.Validate("Occupation Code 2", '000');
        SupplLine.Modify(true);

        // [THEN] Codes and the saved parent remain typed and financial income remains unchanged.
        SupplLine.Get(DocHeader.ID, 'NEC-01C');
        VerifySupplementalCodes(SupplLine);
        DocLine.SetRange("Document ID", DocHeader.ID);
        Assert.RecordCount(DocLine, 1);
        DocLine.FindFirst();
        Assert.AreEqual(5000, DocLine.Amount, 'Codes must not add financial income.');
    end;

    [Test]
    procedure SupplementalBoxChangeDoesNotReinterpretAmount()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        SupplLine: Record "IRS 1099 Doc. Suppl. Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Selecting a code box cannot silently reinterpret an entered amount.
        Initialize();

        // [GIVEN] An amount row with entered tips.
        LibraryIRS1099Document.CreateSupplementalDocument(DocHeader, 'NEC');
        CreateSupplementalLine(SupplLine, DocHeader.ID, 'NEC-01B');
        SupplLine.Validate(Amount, 100);
        SupplLine.Modify(true);

        // [WHEN] The box is changed to occupation codes.
        asserterror SupplLine.Validate("Supplemental Box No.", 'NEC-01C');

        // [THEN] Typed values must be corrected explicitly.
        Assert.ExpectedError('Clear the incompatible values before changing the supplemental box');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure SupplementalAmountRowRejectsCodes()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        SupplLine: Record "IRS 1099 Doc. Suppl. Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Amount rows cannot store occupation codes even through record writes.
        Initialize();

        // [GIVEN] A NEC tip amount row.
        LibraryIRS1099Document.CreateSupplementalDocument(DocHeader, 'NEC');
        CreateSupplementalLine(SupplLine, DocHeader.ID, 'NEC-01B');
        SupplLine."Occupation Code 1" := '101';

        // [WHEN] A code is assigned without field validation.
        asserterror SupplLine.Modify(true);

        // [THEN] The table trigger still enforces the value kind.
        Assert.ExpectedError('Amount lines cannot contain occupation codes, and Occupation Codes lines cannot contain an amount');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure SupplementalCodeGapIsRejected()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        SupplLine: Record "IRS 1099 Doc. Suppl. Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A three-digit value outside the exact XSD enumeration is rejected.
        Initialize();

        // [GIVEN] An occupation-code row.
        LibraryIRS1099Document.CreateSupplementalDocument(DocHeader, 'NEC');
        CreateSupplementalLine(SupplLine, DocHeader.ID, 'NEC-01C');

        // [WHEN] The gap immediately after code 110 is entered.
        asserterror SupplLine.Validate("Occupation Code 1", '111');

        // [THEN] Three numeric-looking characters alone are insufficient.
        Assert.ExpectedError('Enter a three-character Treasury tipped occupation code supported for the reporting year');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure SupplementalAmountUsesStoredExcludedParent()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        SupplLine: Record "IRS 1099 Doc. Suppl. Line";
        DocLine: Record "IRS 1099 Form Doc. Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Individual supplemental ceilings use stored income, not reportability.
        Initialize();

        // [GIVEN] A stored income amount excluded by its threshold.
        LibraryIRS1099Document.CreateSupplementalDocument(DocHeader, 'MISC');
        DocLine.SetRange("Document ID", DocHeader.ID);
        DocLine.FindFirst();
        DocLine."Minimum Reportable Amount" := 2000;
        DocLine.Validate(Amount, 500);
        DocLine.Modify(true);
        CreateSupplementalLine(SupplLine, DocHeader.ID, 'MISC-13A');

        // [WHEN] A valid breakdown is entered.
        SupplLine.Validate(Amount, 100);
        SupplLine.Modify(true);

        // [THEN] The excluded income is not treated as a zero validation ceiling.
        Assert.AreEqual(100, SupplLine.Amount, 'The stored breakdown should remain available.');
        Assert.IsFalse(DocLine."Include In 1099", 'The breakdown must not qualify its parent.');
    end;

    [Test]
    procedure SupplementalAmountRejectsParentOverflow()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        SupplLine: Record "IRS 1099 Doc. Suppl. Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] An individual breakdown cannot exceed its stored income.
        Initialize();

        // [GIVEN] A parent amount of 5000.
        LibraryIRS1099Document.CreateSupplementalDocument(DocHeader, 'NEC');
        CreateSupplementalLine(SupplLine, DocHeader.ID, 'NEC-01D');

        // [WHEN] Overtime exceeds that parent.
        asserterror SupplLine.Validate(Amount, 5001);

        // [THEN] The error identifies the document breakdown constraint.
        Assert.ExpectedError('must be between zero and the amount');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure SupplementalSnapshotSurvivesFinancialRenumbering()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        SupplLine: Record "IRS 1099 Doc. Suppl. Line";
        DocLine: Record "IRS 1099 Form Doc. Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Parent lookup uses document ID and saved box rather than financial line number.
        Initialize();

        // [GIVEN] A saved tip row and its financial parent.
        LibraryIRS1099Document.CreateSupplementalDocument(DocHeader, 'NEC');
        CreateSupplementalLine(SupplLine, DocHeader.ID, 'NEC-01B');
        DocLine.SetRange("Document ID", DocHeader.ID);
        DocLine.FindFirst();

        // [WHEN] The financial line is renumbered and tips are subsequently edited.
        DocLine.Rename(DocLine."Period No.", DocLine."Vendor No.",
            DocLine."Form No.", DocHeader.ID, 30000);
        SupplLine.Validate(Amount, 100);
        SupplLine.Modify(true);

        // [THEN] The saved parent box still resolves the same income.
        Assert.AreEqual('NEC-01', SupplLine."Parent Form Box No.", 'Renumbering must not redirect the parent.');
        Assert.AreEqual(100, SupplLine.Amount, 'The breakdown should remain editable.');
    end;

    [Test]
    procedure SupplementalInUseDescriptionIsEditable()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        SupplLine: Record "IRS 1099 Doc. Suppl. Line";
        IRS1099SupplBox: Record "IRS 1099 Suppl. Box";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Nonstructural edits remain allowed for an in-use definition.
        Initialize();

        // [GIVEN] A used cash-tip definition.
        LibraryIRS1099Document.CreateSupplementalDocument(DocHeader, 'NEC');
        CreateSupplementalLine(SupplLine, DocHeader.ID, 'NEC-01B');
        IRS1099SupplBox.Get(DocHeader."Period No.", 'NEC', 'NEC-01B');

        // [WHEN] Its description is edited.
        IRS1099SupplBox.Description := 'Customized tips label';
        IRS1099SupplBox.Modify(true);

        // [THEN] Existing saved parent relationships remain unchanged.
        SupplLine.Get(DocHeader.ID, 'NEC-01B');
        Assert.AreEqual('NEC-01', SupplLine."Parent Form Box No.", 'A label edit must not change the snapshot.');
        Assert.AreEqual('Customized tips label', IRS1099SupplBox.Description, 'Compatible edits must remain allowed.');
    end;

    [Test]
    procedure SupplementalInUseDefinitionCannotBeDeleted()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        SupplLine: Record "IRS 1099 Doc. Suppl. Line";
        IRS1099SupplBox: Record "IRS 1099 Suppl. Box";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Deleting an in-use definition cannot orphan stored disclosures.
        Initialize();

        // [GIVEN] A used cash-tip definition.
        LibraryIRS1099Document.CreateSupplementalDocument(DocHeader, 'NEC');
        CreateSupplementalLine(SupplLine, DocHeader.ID, 'NEC-01B');
        IRS1099SupplBox.Get(DocHeader."Period No.", 'NEC', 'NEC-01B');

        // [WHEN] The setup row is deleted.
        asserterror IRS1099SupplBox.Delete(true);

        // [THEN] The dependent document is identified.
        Assert.ExpectedError('is used by document');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure SupplementalInUseDefinitionCannotBeRenamed()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        SupplLine: Record "IRS 1099 Doc. Suppl. Line";
        IRS1099SupplBox: Record "IRS 1099 Suppl. Box";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Renaming an in-use definition cannot redirect its identity.
        Initialize();

        // [GIVEN] A used cash-tip definition.
        LibraryIRS1099Document.CreateSupplementalDocument(DocHeader, 'NEC');
        CreateSupplementalLine(SupplLine, DocHeader.ID, 'NEC-01B');
        IRS1099SupplBox.Get(DocHeader."Period No.", 'NEC', 'NEC-01B');

        // [WHEN] The setup identity is renamed.
        asserterror IRS1099SupplBox.Rename(IRS1099SupplBox."Period No.", 'NEC', 'CUSTOM');

        // [THEN] The dependent document is identified.
        Assert.ExpectedError('is used by document');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure SupplementalLookupExcludesAddedAndMissingParents()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        SupplLine: Record "IRS 1099 Doc. Suppl. Line";
        IRS1099SupplBox: Record "IRS 1099 Suppl. Box";
        FormBox: Record "IRS 1099 Form Box";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] The lookup shows only same-form available definitions with financial parents.
        Initialize();

        // [GIVEN] Three definitions, one already selected on the document.
        LibraryIRS1099Document.CreateSupplementalDocument(DocHeader, 'NEC');
        CreateSupplementalLine(SupplLine, DocHeader.ID, 'NEC-01B');
        FormBox."Period No." := DocHeader."Period No.";
        FormBox."Form No." := 'NEC';
        FormBox."No." := 'UNUSED-PARENT';
        FormBox.Insert(true);
        IRS1099SupplBox."Period No." := DocHeader."Period No.";
        IRS1099SupplBox."Form No." := 'NEC';
        IRS1099SupplBox."No." := 'CUSTOM';
        IRS1099SupplBox."Parent Form Box No." := 'UNUSED-PARENT';
        IRS1099SupplBox.Insert(true);

        // [WHEN] Available boxes are resolved.
        LibraryIRS1099Document.FilterAvailableSupplementalBoxes(IRS1099SupplBox, DocHeader.ID);

        // [THEN] Only the two remaining definitions are offered.
        Assert.RecordCount(IRS1099SupplBox, 2);
        IRS1099SupplBox.FindFirst();
        Assert.AreEqual('NEC-01C', IRS1099SupplBox."No.", 'The already selected box must not be offered again.');
    end;

    [Test]
    procedure SupplementalSetupRejectsEarlierTaxYear()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        IRS1099SupplBox: Record "IRS 1099 Suppl. Box";
        ReportingPeriod: Record "IRS Reporting Period";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Supplemental definitions cannot be saved for an earlier year.
        Initialize();

        // [GIVEN] A fixture whose reporting period is changed to 2025.
        LibraryIRS1099Document.CreateSupplementalDocument(DocHeader, 'NEC');
        ReportingPeriod.Get(DocHeader."Period No.");
        ReportingPeriod."Starting Date" := DMY2Date(1, 1, 2025);
        ReportingPeriod."Ending Date" := DMY2Date(31, 12, 2025);
        ReportingPeriod.Modify();
        IRS1099SupplBox.Get(DocHeader."Period No.", 'NEC', 'NEC-01B');

        // [WHEN] The otherwise compatible definition is saved.
        IRS1099SupplBox.Description := 'Earlier year';
        asserterror IRS1099SupplBox.Modify(true);

        // [THEN] Scope is validated independently of the mapping identifier.
        Assert.ExpectedError('supported for tax years 2026 and later on forms MISC and NEC within a single calendar year');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure SupplementalReleaseSupportsFutureTaxYear()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        ReportingPeriod: Record "IRS Reporting Period";
        TipsSupplLine: Record "IRS 1099 Doc. Suppl. Line";
        CodesSupplLine: Record "IRS 1099 Doc. Suppl. Line";
    begin
        // [SCENARIO] Supplemental validation uses the period dates, not its identifier or a fixed year.
        Initialize();
        LibraryIRS1099Document.CreateSupplementalDocument(DocHeader, 'NEC');
        ReportingPeriod.Get(DocHeader."Period No.");
        ReportingPeriod."Starting Date" := 20270101D;
        ReportingPeriod."Ending Date" := 20271231D;
        ReportingPeriod.Modify();
        CreateSupplementalLine(TipsSupplLine, DocHeader.ID, 'NEC-01B');
        TipsSupplLine.Validate(Amount, 100);
        TipsSupplLine.Modify(true);
        CreateSupplementalLine(CodesSupplLine, DocHeader.ID, 'NEC-01C');
        CodesSupplLine.Validate("Occupation Code 1", '000');
        CodesSupplLine.Modify(true);

        LibraryIRS1099Document.ReleaseDocument(DocHeader);

        DocHeader.TestField(Status, DocHeader.Status::Released);
        Assert.IsTrue(LibraryIRS1099Document.IsSupplementalReportable(TipsSupplLine), 'Future-year tips must remain reportable.');
        Assert.IsTrue(LibraryIRS1099Document.IsSupplementalReportable(CodesSupplLine), 'Future-year codes must remain reportable.');
    end;

    [Test]
    procedure SupplementalSetupRejectsSpanningTaxYears()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        ReportingPeriod: Record "IRS Reporting Period";
        Definition: Record "IRS 1099 Suppl. Box";
    begin
        // [SCENARIO] Removing the upper year limit must not allow a period spanning two calendar years.
        Initialize();
        LibraryIRS1099Document.CreateSupplementalDocument(DocHeader, 'NEC');
        ReportingPeriod.Get(DocHeader."Period No.");
        ReportingPeriod."Ending Date" := 20271231D;
        ReportingPeriod.Modify();
        Definition.Get(DocHeader."Period No.", 'NEC', 'NEC-01B');

        Definition.Description := 'Spanning tax years';
        asserterror Definition.Modify(true);

        Assert.ExpectedError('within a single calendar year');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure SupplementalBoxIsNotJournalDestination()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A supplemental box is not an ordinary financial posting destination.
        Initialize();

        // [GIVEN] Definitions stored separately from financial form boxes.
        LibraryIRS1099Document.CreateSupplementalDocument(DocHeader, 'NEC');
        GenJournalLine."IRS 1099 Reporting Period" := DocHeader."Period No.";
        GenJournalLine."IRS 1099 Form No." := 'NEC';

        // [WHEN] A supplemental tip box is selected as a journal destination.
        asserterror GenJournalLine.Validate("IRS 1099 Form Box No.", 'NEC-01B');

        // [THEN] The financial table relation rejects it.
        Assert.ExpectedError('NEC-01B');
        Assert.ExpectedErrorCode('DB:RecordNotFound');
    end;

    [Test]
    procedure SupplementalEmptyLinesHiddenUntilShown()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        SupplLine: Record "IRS 1099 Doc. Suppl. Line";
        IRS1099FormDocument: TestPage "IRS 1099 Form Document";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Empty supplemental lines are hidden until explicitly shown without creating rows.
        Initialize();

        // [GIVEN] Document D has no supplemental lines.
        LibraryIRS1099Document.CreateSupplementalDocument(DocHeader, 'NEC');
        IRS1099FormDocument.OpenEdit();
        IRS1099FormDocument.GoToRecord(DocHeader);
        VerifySupplementalLinesVisibility(IRS1099FormDocument, false);

        // [WHEN] The user reveals supplemental lines.
        IRS1099FormDocument.ShowSupplementalLines.Invoke();

        // [THEN] The part is visible without inserting unused rows.
        VerifySupplementalLinesVisibility(IRS1099FormDocument, true);
        IRS1099FormDocument.Close();
        SupplLine.SetRange("Document ID", DocHeader.ID);
        Assert.IsTrue(SupplLine.IsEmpty(), 'Showing supplemental lines must not create rows.');
    end;

    [Test]
    procedure SupplementalExistingOpenLinesVisible()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        SupplLine: Record "IRS 1099 Doc. Suppl. Line";
        IRS1099FormDocument: TestPage "IRS 1099 Form Document";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Existing supplemental lines are automatically shown on an Open document.
        Initialize();

        // [GIVEN] Open document D has a supplemental line.
        LibraryIRS1099Document.CreateSupplementalDocument(DocHeader, 'NEC');
        CreateSupplementalLine(SupplLine, DocHeader.ID, 'NEC-01B');

        // [WHEN] The document card is opened.
        IRS1099FormDocument.OpenEdit();
        IRS1099FormDocument.GoToRecord(DocHeader);

        // [THEN] Existing disclosures are visible and editable.
        VerifySupplementalLinesVisibility(IRS1099FormDocument, true);
        Assert.IsTrue(IRS1099FormDocument.SupplementalLines.Amount.Editable(), 'Open supplemental lines must remain editable.');
        IRS1099FormDocument.Close();
    end;

    [Test]
    procedure SupplementalExistingReleasedLinesVisible()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        SupplLine: Record "IRS 1099 Doc. Suppl. Line";
        IRS1099FormDocument: TestPage "IRS 1099 Form Document";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Existing supplemental lines remain visible and read-only on a Released document.
        Initialize();

        // [GIVEN] Released document D has a supplemental line.
        LibraryIRS1099Document.CreateSupplementalDocument(DocHeader, 'NEC');
        CreateSupplementalLine(SupplLine, DocHeader.ID, 'NEC-01B');
        DocHeader.Status := DocHeader.Status::Released;
        DocHeader.Modify(true);

        // [WHEN] The document card is opened.
        IRS1099FormDocument.OpenEdit();
        IRS1099FormDocument.GoToRecord(DocHeader);

        // [THEN] Existing disclosures are visible but cannot be edited.
        VerifySupplementalLinesVisibility(IRS1099FormDocument, true);
        Assert.IsFalse(IRS1099FormDocument.SupplementalLines.Amount.Editable(), 'Released supplemental lines must remain read-only.');
        IRS1099FormDocument.Close();
    end;

    [Test]
    procedure SupplementalVisibilityResetsOnNavigation()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        OtherDocHeader: Record "IRS 1099 Form Doc. Header";
        IRS1099FormDocument: TestPage "IRS 1099 Form Document";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Revealing empty supplemental lines applies only to the current document.
        Initialize();

        // [GIVEN] Documents D and E have no supplemental lines, and D's part is explicitly shown.
        LibraryIRS1099Document.CreateSupplementalDocument(DocHeader, 'NEC');
        OtherDocHeader."Period No." := DocHeader."Period No.";
        OtherDocHeader."Vendor No." := LibraryPurchase.CreateVendorNo();
        OtherDocHeader."Form No." := DocHeader."Form No.";
        OtherDocHeader.Insert(true);
        IRS1099FormDocument.OpenEdit();
        IRS1099FormDocument.GoToRecord(DocHeader);
        IRS1099FormDocument.ShowSupplementalLines.Invoke();

        // [WHEN] The user navigates to E.
        IRS1099FormDocument.GoToRecord(OtherDocHeader);

        // [THEN] E's empty supplemental lines are hidden.
        VerifySupplementalLinesVisibility(IRS1099FormDocument, false);

        // [WHEN] The user returns to D without having entered a supplemental line.
        IRS1099FormDocument.GoToRecord(DocHeader);

        // [THEN] D's empty supplemental lines are hidden again.
        VerifySupplementalLinesVisibility(IRS1099FormDocument, false);
        IRS1099FormDocument.Close();
    end;

    [Test]
    [HandlerFunctions('SupplementalBoxLookupHandler')]
    procedure SupplementalManualLookupAssignsReadOnlyParent()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        SupplLine: Record "IRS 1099 Doc. Suppl. Line";
        IRS1099FormDocument: TestPage "IRS 1099 Form Document";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Manual lookup fills the parent without inserting unused supplemental rows.
        Initialize();

        // [GIVEN] A document with definitions and no supplemental rows.
        LibraryIRS1099Document.CreateSupplementalDocument(DocHeader, 'NEC');
        IRS1099FormDocument.OpenEdit();
        IRS1099FormDocument.GoToRecord(DocHeader);

        // [WHEN] A user explicitly selects the first descriptive lookup choice.
        IRS1099FormDocument.ShowSupplementalLines.Invoke();
        IRS1099FormDocument.SupplementalLines.New();
        IRS1099FormDocument.SupplementalLines."Supplemental Box No.".Lookup();
        IRS1099FormDocument.SupplementalLines.Amount.SetValue(100);

        // [THEN] The assigned parent is read-only and only the selected row is saved.
        Assert.IsFalse(IRS1099FormDocument.SupplementalLines."Parent Form Box No.".Editable(), 'The parent snapshot must be read-only.');
        IRS1099FormDocument.Close();
        SupplLine.SetRange("Document ID", DocHeader.ID);
        Assert.RecordCount(SupplLine, 1);
        SupplLine.FindFirst();
        Assert.AreEqual('NEC-01', SupplLine."Parent Form Box No.", 'Lookup must assign the definition parent.');
    end;

    [Test]
    procedure SupplementalReleasedDocumentRejectsEdits()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        SupplLine: Record "IRS 1099 Doc. Suppl. Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Stored disclosures cannot be changed while their document is Released.
        Initialize();

        // [GIVEN] A supplemental row on a released document.
        LibraryIRS1099Document.CreateSupplementalDocument(DocHeader, 'NEC');
        CreateSupplementalLine(SupplLine, DocHeader.ID, 'NEC-01B');
        DocHeader.Status := DocHeader.Status::Released;
        DocHeader.Modify(true);

        // [WHEN] Its amount is edited directly.
        asserterror SupplLine.Validate(Amount, 100);

        // [THEN] The normal document status restriction applies.
        Assert.ExpectedError('Open');
        Assert.ExpectedErrorCode('TestField');
    end;

    [Test]
    procedure IRS1099CodeSetsInPurchaseHeaderFromVendor()
    var
        PurchaseHeader: Record "Purchase Header";
        VendNo: Code[20];
        FormNo: Code[20];
        FormBoxNo: Code[20];
    begin
        // [SCENARIO 495389] IRS 1099 code is taken from the vendor when creating a purchase header

        Initialize();
        LibraryIRSReportingPeriod.CreateOneDayReportingPeriod(WorkDate());
        FormNo :=
            LibraryIRS1099FormBox.CreateSingleFormInReportingPeriod(WorkDate(), WorkDate());
        FormBoxNo :=
            LibraryIRS1099FormBox.CreateSingleFormBoxInReportingPeriod(WorkDate(), WorkDate(), FormNo);
        VendNo := LibraryIRS1099FormBox.CreateVendorNoWithFormBox(WorkDate(), WorkDate(), FormNo, FormBoxNo);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendNo);
        LibraryIRS1099Document.VerifyIRS1099CodeInPurchaseHeader(PurchaseHeader, FormNo, FormBoxNo);
    end;

    [Test]
    procedure IRS1099CodeInPurchaseHeaderWhenChangePostingDate()
    var
        PurchaseHeader: Record "Purchase Header";
        VendNo: Code[20];
        FormNo: Code[20];
        FormBoxNo: Code[20];
        ReportingDate: Date;
    begin
        // [SCENARIO 495389] IRS 1099 code changes when change the posting date of the purchase header

        Initialize();
        ReportingDate := CalcDate('<1Y>', WorkDate());
        LibraryIRSReportingPeriod.CreateOneDayReportingPeriod(ReportingDate);
        FormNo :=
            LibraryIRS1099FormBox.CreateSingleFormInReportingPeriod(ReportingDate, ReportingDate);
        FormBoxNo :=
            LibraryIRS1099FormBox.CreateSingleFormBoxInReportingPeriod(ReportingDate, ReportingDate, FormNo);
        VendNo := LibraryIRS1099FormBox.CreateVendorNoWithFormBox(ReportingDate, ReportingDate, FormNo, FormBoxNo);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendNo);
        // [WHEN]
        PurchaseHeader.Validate("Posting Date", ReportingDate);
        // [THEN]
        LibraryIRS1099Document.VerifyIRS1099CodeInPurchaseHeader(PurchaseHeader, FormNo, FormBoxNo);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure IRS1099CodeInPurchaseHeaderWhenChangePostingDateAfterAddingLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvLine: Record "Purch. Inv. Line";
        VATPostingSetup: Record "VAT Posting Setup";
        Item: Record Item;
        VendorLedgEntry: Record "Vendor Ledger Entry";
        VendNo, FormNo, FormBoxNo, InvNo : Code[20];
        ReportingDate: Date;
    begin
        // [SCENARIO 597572] IRS 1099 code in vendor ledger entry is taken from the purchase invoice when change the posting date of the purchase header after adding a line

        Initialize();
        // [GIVEN] IRS Reporting Period is in 2026
        // [GIVEN] Vendor "X" with form box for the period
        ReportingDate := CalcDate('<1Y>', WorkDate());
        LibraryIRSReportingPeriod.CreateOneDayReportingPeriod(ReportingDate);
        FormNo :=
            LibraryIRS1099FormBox.CreateSingleFormInReportingPeriod(ReportingDate, ReportingDate);
        FormBoxNo :=
            LibraryIRS1099FormBox.CreateSingleFormBoxInReportingPeriod(ReportingDate, ReportingDate, FormNo);
        // [GIVEN] Purchase invoice with "Posting Date" in 2025 and vendor "X"
        // [GIVEN] Purchase line in the invoice
        VendNo := LibraryIRS1099FormBox.CreateVendorNoWithFormBox(ReportingDate, ReportingDate, FormNo, FormBoxNo);
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0);
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendNo);
        PurchaseHeader.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine, PurchaseHeader, Item."No.", 100, 1);
        // [GIVEN] Posting date is changed to 2026
        LibraryVariableStorage.Enqueue(ChangingPostingDateInPurchHeaderWhileHavingLineMsg);
        PurchaseHeader.Validate("Posting Date", ReportingDate);
        PurchaseHeader.Modify(true);
        // [WHEN] Post purchase invoice
        InvNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        // [THEN] Vendor ledger entry is created with IRS 1099 code taken from the vendor
        LibraryERM.FindVendorLedgerEntry(VendorLedgEntry, VendorLedgEntry."Document Type"::Invoice, InvNo);
        VendorLedgEntry.TestField("IRS 1099 Reporting Period", LibraryIRSReportingPeriod.GetReportingPeriod(ReportingDate));
        VendorLedgEntry.TestField("IRS 1099 Form No.", FormNo);
        VendorLedgEntry.TestField("IRS 1099 Form Box No.", FormBoxNo);
        PurchInvLine.Get(InvNo, PurchaseLine."Line No.");
        Assert.AreEqual(100, PurchInvLine."Amount Including VAT", 'The posted fixture must have deterministic untaxed income.');
        Assert.AreEqual(-PurchInvLine."Amount Including VAT", VendorLedgEntry."IRS 1099 Reporting Amount",
            'IRS reporting must use the actual posted invoice amount after the posting-date change.');
        LibraryVariableStorage.AssertEmpty();

    end;

    [Test]
    procedure CreateFormDocumentSamePeriodVendorAndForm()
    var
        TempIRS1099VendFormBoxBuffer: Record "IRS 1099 Vend. Form Box Buffer" temporary;
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
        IRS1099FormDocLineDetail: Record "IRS 1099 Form Doc. Line Detail";
        EntryNo: Integer;
    begin
        // [SCENARIO 495389] Create a single form document with the same period, vendor and form

        Initialize();
        // [GIVEN] Vendor form box buffer with "Period No." = "X", "Vendor No." = "Y", "Form No." = "MISC", "Form Box No." = "MISC-01"
        LibraryIRS1099Document.MockVendorFormBoxBuffer(
                TempIRS1099VendFormBoxBuffer, EntryNo, LibraryUtility.GenerateGUID(), LibraryPurchase.CreateVendorNo(),
                LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID());

        // [WHEN] Create form documents from the vendor form box buffer
        LibraryIRS1099Document.CreateFormDocuments(TempIRS1099VendFormBoxBuffer);

        // [THEN] A single form document is created with "Period No." = "X", "Vendor No." = "Y", "Form No." = "MISC"
        Assert.RecordCount(IRS1099FormDocHeader, 1);
        IRS1099FormDocHeader.FindFirst();
        IRS1099FormDocHeader.TestField("Period No.", TempIRS1099VendFormBoxBuffer."Period No.");
        IRS1099FormDocHeader.TestField("Vendor No.", TempIRS1099VendFormBoxBuffer."Vendor No.");
        IRS1099FormDocHeader.TestField("Form No.", TempIRS1099VendFormBoxBuffer."Form No.");
        Assert.RecordCount(IRS1099FormDocLine, 1);
        // [THEN] A single form document line is created with the same period, vendor and form
        IRS1099FormDocLine.SetRange("Document ID", IRS1099FormDocHeader.ID);
        IRS1099FormDocLine.FindFirst();
        IRS1099FormDocLine.TestField(Amount, TempIRS1099VendFormBoxBuffer."Reporting Amount");
        IRS1099FormDocLine.TestField("Calculated Amount", TempIRS1099VendFormBoxBuffer.Amount);
        IRS1099FormDocLine.TestField("Include In 1099", TempIRS1099VendFormBoxBuffer."Include In 1099");
        IRS1099FormDocLineDetail.Get(IRS1099FormDocLine."Document ID", IRS1099FormDocLine."Line No.", EntryNo);

        // tear down
        DeleteDocuments();
        Commit();
    end;

    [Test]
    procedure CreateMultipleFormDocumentsSamePeriodVendorForm()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        NewIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
    begin
        // [SCENARIO 495389] Stan cannot create multiple form documents with the same period, vendor and form

        Initialize();
        IRS1099FormDocHeader.Validate("Period No.", LibraryIRSReportingPeriod.CreateOneDayReportingPeriod(WorkDate()));
        IRS1099FormDocHeader.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        IRS1099FormDocHeader.Validate("Form No.", LibraryIRS1099FormBox.CreateSingleFormInReportingPeriod(WorkDate()));
        IRS1099FormDocHeader.Insert(true);
        NewIRS1099FormDocHeader.Validate("Period No.", IRS1099FormDocHeader."Period No.");
        NewIRS1099FormDocHeader.Validate("Vendor No.", IRS1099FormDocHeader."Vendor No.");
        asserterror NewIRS1099FormDocHeader.Validate("Form No.", IRS1099FormDocHeader."Form No.");
        Assert.ExpectedError(CannotCreateFormDocSamePeriodVendorFormErr);
    end;

    [Test]
    procedure CreateFormDocumentSameFormBoxes()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
        NewIRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
    begin
        // [SCENARIO 495389] Stan cannot create the form document with the same form boxes

        Initialize();
        IRS1099FormDocHeader.Validate("Period No.", LibraryIRSReportingPeriod.CreateOneDayReportingPeriod(WorkDate()));
        IRS1099FormDocHeader.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        IRS1099FormDocHeader.Validate("Form No.", LibraryIRS1099FormBox.CreateSingleFormInReportingPeriod(WorkDate()));
        IRS1099FormDocHeader.Insert(true);
        IRS1099FormDocLine.Validate("Document ID", IRS1099FormDocHeader.ID);
        IRS1099FormDocLine.Validate("Line No.", 10000);
        IRS1099FormDocLine.Validate("Period No.", IRS1099FormDocHeader."Period No.");
        IRS1099FormDocLine.Validate("Vendor No.", IRS1099FormDocHeader."Vendor No.");
        IRS1099FormDocLine.Validate("Form No.", IRS1099FormDocHeader."Form No.");
        IRS1099FormDocLine.Validate(
            "Form Box No.",
            LibraryIRS1099FormBox.CreateSingleFormBoxInReportingPeriod(WorkDate(), IRS1099FormDocHeader."Form No."));
        IRS1099FormDocLine.Insert(true);
        NewIRS1099FormDocLine.Validate("Document ID", IRS1099FormDocHeader.ID);
        NewIRS1099FormDocLine.Validate("Period No.", IRS1099FormDocHeader."Period No.");
        NewIRS1099FormDocLine.Validate("Vendor No.", IRS1099FormDocHeader."Vendor No.");
        NewIRS1099FormDocLine.Validate("Form No.", IRS1099FormDocHeader."Form No.");
        asserterror NewIRS1099FormDocLine.Validate("Form Box No.", IRS1099FormDocLine."Form Box No.");
        Assert.ExpectedError(CreateCreateFormDocLineSameFormBoxErr);
    end;

    [Test]
    procedure CreateFormDocumentSamePeriodVendorAndFormMultipleConnectedEntries()
    var
        TempIRS1099VendFormBoxBuffer: Record "IRS 1099 Vend. Form Box Buffer" temporary;
    begin
        // [SCENARIO 495389] Create a single form document with the same period, vendor and form and multiple connected entries

        Initialize();
        TempIRS1099VendFormBoxBuffer."Period No." := LibraryUtility.GenerateGUID();
        TempIRS1099VendFormBoxBuffer."Vendor No." := LibraryUtility.GenerateGUID();
        TempIRS1099VendFormBoxBuffer."Form No." := LibraryUtility.GenerateGUID();
        TempIRS1099VendFormBoxBuffer."Form Box No." := LibraryUtility.GenerateGUID();
        TempIRS1099VendFormBoxBuffer.Amount := LibraryRandom.RandDec(100, 2);
        TempIRS1099VendFormBoxBuffer."Reporting Amount" := LibraryRandom.RandDec(100, 2);
        TempIRS1099VendFormBoxBuffer."Include In 1099" := true;
        TempIRS1099VendFormBoxBuffer.Insert(true);
    end;

    [Test]
    procedure ChangeFormBoxInLineWithNonZeroCalculatedAmount()
    var
        IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
        PeriodNo, FormNo : Code[20];
        FormBoxNo: array[2] of Code[20];
    begin
        // [SCENARIO 495389] Stan cannot change the Form Box No. in the form document line with non-zero calculated amount

        Initialize();
        PeriodNo := LibraryIRSReportingPeriod.CreateOneDayReportingPeriod(WorkDate());
        FormNo :=
            LibraryIRS1099FormBox.CreateSingleFormInReportingPeriod(WorkDate(), WorkDate());
        FormBoxNo[1] :=
            LibraryIRS1099FormBox.CreateSingleFormBoxInReportingPeriod(WorkDate(), WorkDate(), FormNo);

        IRS1099FormDocLine."Period No." := PeriodNo;
        IRS1099FormDocLine."Form No." := FormNo;
        IRS1099FormDocLine."Form Box No." := FormBoxNo[1];
        IRS1099FormDocLine."Calculated Amount" := 1;

        FormBoxNo[2] :=
            LibraryIRS1099FormBox.CreateSingleFormBoxInReportingPeriod(WorkDate(), WorkDate(), FormNo);
        // [WHEN]
        asserterror IRS1099FormDocLine.Validate("Form Box No.", FormBoxNo[2]);

        // [THEN]
        Assert.ExpectedError(CannotChangeFormBoxWithCalculatedAmountErr);

    end;

    [Test]
    procedure ChangeFormBoxInLineWithZeroCalculatedAmount()
    var
        IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
        PeriodNo, FormNo : Code[20];
        FormBoxNo: array[2] of Code[20];
    begin
        // [SCENARIO 495389] Stan can change the Form Box No. in the form document line with non-zero calculated amount

        Initialize();
        PeriodNo := LibraryIRSReportingPeriod.CreateOneDayReportingPeriod(WorkDate());
        FormNo :=
            LibraryIRS1099FormBox.CreateSingleFormInReportingPeriod(WorkDate(), WorkDate());
        FormBoxNo[1] :=
            LibraryIRS1099FormBox.CreateSingleFormBoxInReportingPeriod(WorkDate(), WorkDate(), FormNo);

        IRS1099FormDocLine."Period No." := PeriodNo;
        IRS1099FormDocLine."Form No." := FormNo;
        IRS1099FormDocLine."Form Box No." := FormBoxNo[1];
        IRS1099FormDocLine."Calculated Amount" := 0;
        IRS1099FormDocLine.Amount := 1;

        FormBoxNo[2] :=
            LibraryIRS1099FormBox.CreateSingleFormBoxInReportingPeriod(WorkDate(), WorkDate(), FormNo);
        // [WHEN]
        IRS1099FormDocLine.Validate("Form Box No.", FormBoxNo[2]);

        // [THEN]
        IRS1099FormDocLine.TestField(Amount, 0);

    end;

    [Test]
    procedure ChangeIRSDataInVendorLedgerEntryConnectedToFormDocument()
    var
        VendorLedgEntry: Record "Vendor Ledger Entry";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
        IRS1099FormDocLineDetail: Record "IRS 1099 Form Doc. Line Detail";
        PeriodNo, FormNo, VendNo, FormBoxNo : Code[20];
    begin
        // [SCENARIO 495389] Stan cannot change the IRS data in the vendor ledger entry connected to the form document

        Initialize();
        PeriodNo := LibraryIRSReportingPeriod.CreateOneDayReportingPeriod(WorkDate());
        FormNo :=
            LibraryIRS1099FormBox.CreateSingleFormInReportingPeriod(WorkDate());
        FormBoxNo :=
            LibraryIRS1099FormBox.CreateSingleFormBoxInReportingPeriod(WorkDate(), FormNo);
        VendNo := LibraryIRS1099FormBox.CreateVendorNoWithFormBox(WorkDate(), FormNo, FormBoxNo);
        VendorLedgEntry."Entry No." := LibraryUtility.GetNewRecNo(VendorLedgEntry, VendorLedgEntry.FieldNo("Entry No."));
        VendorLedgEntry.Insert();

        IRS1099FormDocHeader."Period No." := PeriodNo;
        IRS1099FormDocHeader."Vendor No." := VendNo;
        IRS1099FormDocHeader."Form No." := FormNo;
        IRS1099FormDocHeader.Insert();
        IRS1099FormDocLine."Document ID" := IRS1099FormDocHeader.ID;
        IRS1099FormDocLine.Insert();
        IRS1099FormDocLineDetail."Document ID" := IRS1099FormDocLine."Document ID";
        IRS1099FormDocLineDetail."Vendor Ledger Entry No." := VendorLedgEntry."Entry No.";
        IRS1099FormDocLineDetail.Insert();
        Commit();

        asserterror VendorLedgEntry.Validate("IRS 1099 Form No.");
        Assert.ExpectedError(StrSubstNo(CannotChangeIRSDataInEntryConnectedToFormDocumentErr, PeriodNo, VendNo, FormNo));
        asserterror VendorLedgEntry.Validate("IRS 1099 Form Box No.");
        Assert.ExpectedError(StrSubstNo(CannotChangeIRSDataInEntryConnectedToFormDocumentErr, PeriodNo, VendNo, FormNo));
        asserterror VendorLedgEntry.Validate("IRS 1099 Reporting Amount");
        Assert.ExpectedError(StrSubstNo(CannotChangeIRSDataInEntryConnectedToFormDocumentErr, PeriodNo, VendNo, FormNo));

        // Tear down
        IRS1099FormDocHeader.Delete(true);

    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CreateFormDocumentForVendorWithExistingFormDocumentAndReplaceOption()
    var
        TempIRS1099VendFormBoxBuffer: Record "IRS 1099 Vend. Form Box Buffer" temporary;
        TempIRS1099CalcParameters: Record "IRS 1099 Calc. Params";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
        PeriodNo, FormNo, VendNo, FormBoxNo : Code[20];
        DocId, EntryNo : Integer;
    begin
        // [SCENARIO 534640] Stan can replace an existing form document when running a form documents creation for a vendor that already has a form document

        Initialize();
        // [GIVEN] Period = WorkDate(), Form No. = MISC, Form Box No. = MISC-01, Vendor No. = "X"
        PeriodNo := LibraryIRSReportingPeriod.CreateOneDayReportingPeriod(WorkDate());
        FormNo :=
            LibraryIRS1099FormBox.CreateSingleFormInReportingPeriod(WorkDate());
        FormBoxNo :=
            LibraryIRS1099FormBox.CreateSingleFormBoxInReportingPeriod(WorkDate(), FormNo);
        VendNo := LibraryIRS1099FormBox.CreateVendorNoWithFormBox(WorkDate(), FormNo, FormBoxNo);

        // [GIVEN] Existing open form document for MISC and "X" with "Reporting Amount" = 500, "Amount" = 600
        DocId := LibraryIRS1099Document.MockFormDocumentForVendor(PeriodNo, VendNo, FormNo, "IRS 1099 Form Doc. Status"::Open);
        LibraryIRS1099Document.MockFormDocumentLineForVendor(DocId, PeriodNo, VendNo, FormNo, FormBoxNo);

        // [GIVEN] Vendor form box buffer with "Reporting Amount" = 100, "Amount" = 200
        LibraryIRS1099Document.MockVendorFormBoxBuffer(TempIRS1099VendFormBoxBuffer, EntryNo, PeriodNo, VendNo, FormNo, FormBoxNo);

        // [WHEN] Run create form documents for MISC with Replace option
        TempIRS1099CalcParameters."Form No." := FormNo;
        TempIRS1099CalcParameters.Replace := true;
        LibraryIRS1099Document.CreateFormDocuments(TempIRS1099VendFormBoxBuffer, TempIRS1099CalcParameters);

        // [THEN] The form document for MISC and "X" exists after running create form documents function
        LibraryIRS1099Document.FindIRS1099FormDocHeader(IRS1099FormDocHeader, PeriodNo, VendNo, FormNo);
        // [THEN] There is only one form document for MISC and "X"
        Assert.RecordCount(IRS1099FormDocHeader, 1);
        // [THEN] Form document line has Amount = 100 and "Calculated Amount" = 200
        LibraryIRS1099Document.FindIRS1099FormDocLine(IRS1099FormDocLine, PeriodNo, VendNo, FormNo, FormBoxNo);
        IRS1099FormDocLine.TestField(Amount, TempIRS1099VendFormBoxBuffer."Reporting Amount");
        IRS1099FormDocLine.TestField("Calculated Amount", TempIRS1099VendFormBoxBuffer.Amount);
        // [THEN] There is only one form document line for MISC-01 and "X"
        Assert.RecordCount(IRS1099FormDocLine, 1);

    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CreateFormDocumentForVendorWithExistingSubmittedFormDocumentAndReplaceOption()
    var
        TempIRS1099VendFormBoxBuffer: Record "IRS 1099 Vend. Form Box Buffer" temporary;
        TempIRS1099CalcParameters: Record "IRS 1099 Calc. Params";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        OriginalIRS1099FormDocLine, IRS1099FormDocLine : Record "IRS 1099 Form Doc. Line";
        PeriodNo, FormNo, VendNo, FormBoxNo : Code[20];
        DocId, EntryNo : Integer;
    begin
        // [SCENARIO 534640] Stan cannot replace an existing form document when running a form documents creation for a vendor that already has a form document in submitted status

        Initialize();
        // [GIVEN] Period = WorkDate(), Form No. = MISC, Form Box No. = MISC-01, Vendor No. = "X"
        PeriodNo := LibraryIRSReportingPeriod.CreateOneDayReportingPeriod(WorkDate());
        FormNo :=
            LibraryIRS1099FormBox.CreateSingleFormInReportingPeriod(WorkDate());
        FormBoxNo :=
            LibraryIRS1099FormBox.CreateSingleFormBoxInReportingPeriod(WorkDate(), FormNo);
        VendNo := LibraryIRS1099FormBox.CreateVendorNoWithFormBox(WorkDate(), FormNo, FormBoxNo);

        // [GIVEN] Existing submitted form document for MISC and "X" with "Reporting Amount" = 500, "Amount" = 600
        DocId := LibraryIRS1099Document.MockFormDocumentForVendor(PeriodNo, VendNo, FormNo, "IRS 1099 Form Doc. Status"::Submitted);
        LibraryIRS1099Document.MockFormDocumentLineForVendor(OriginalIRS1099FormDocLine, DocId, PeriodNo, VendNo, FormNo, FormBoxNo);

        // [GIVEN] Vendor form box buffer with "Reporting Amount" = 100, "Amount" = 200
        LibraryIRS1099Document.MockVendorFormBoxBuffer(TempIRS1099VendFormBoxBuffer, EntryNo, PeriodNo, VendNo, FormNo, FormBoxNo);

        // [WHEN] Run create form documents for MISC with Replace option
        TempIRS1099CalcParameters."Form No." := FormNo;
        TempIRS1099CalcParameters.Replace := true;
        LibraryIRS1099Document.CreateFormDocuments(TempIRS1099VendFormBoxBuffer, TempIRS1099CalcParameters);

        // [THEN] The form document for MISC and "X" exists after running create form documents function
        LibraryIRS1099Document.FindIRS1099FormDocHeader(IRS1099FormDocHeader, PeriodNo, VendNo, FormNo);
        // [THEN] There is only one form document for MISC and "X"
        Assert.RecordCount(IRS1099FormDocHeader, 1);
        // [THEN] Form document line has Amount = 500 and "Calculated Amount" = 600
        LibraryIRS1099Document.FindIRS1099FormDocLine(IRS1099FormDocLine, PeriodNo, VendNo, FormNo, FormBoxNo);
        IRS1099FormDocLine.TestField(Amount, OriginalIRS1099FormDocLine.Amount);
        IRS1099FormDocLine.TestField("Calculated Amount", OriginalIRS1099FormDocLine."Calculated Amount");
        // [THEN] There is only one form document line for MISC-01 and "X"
        Assert.RecordCount(IRS1099FormDocLine, 1);

    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CreateFormDocumentForVendorWithExistingReleasedFormDocumentAndReplaceOption()
    var
        TempIRS1099VendFormBoxBuffer: Record "IRS 1099 Vend. Form Box Buffer" temporary;
        TempIRS1099CalcParameters: Record "IRS 1099 Calc. Params";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
        PeriodNo, FormNo, VendNo, FormBoxNo : Code[20];
        DocId, EntryNo : Integer;
    begin
        // [SCENARIO 534640] Stan can replace an existing form document when running a form documents creation for a vendor that already has a form document in released status

        Initialize();
        // [GIVEN] Period = WorkDate(), Form No. = MISC, Form Box No. = MISC-01, Vendor No. = "X"
        PeriodNo := LibraryIRSReportingPeriod.CreateOneDayReportingPeriod(WorkDate());
        FormNo :=
            LibraryIRS1099FormBox.CreateSingleFormInReportingPeriod(WorkDate());
        FormBoxNo :=
            LibraryIRS1099FormBox.CreateSingleFormBoxInReportingPeriod(WorkDate(), FormNo);
        VendNo := LibraryIRS1099FormBox.CreateVendorNoWithFormBox(WorkDate(), FormNo, FormBoxNo);

        // [GIVEN] Existing submitted form document for MISC and "X" with "Reporting Amount" = 500, "Amount" = 600
        DocId := LibraryIRS1099Document.MockFormDocumentForVendor(PeriodNo, VendNo, FormNo, "IRS 1099 Form Doc. Status"::Released);
        LibraryIRS1099Document.MockFormDocumentLineForVendor(DocId, PeriodNo, VendNo, FormNo, FormBoxNo);

        // [GIVEN] Vendor form box buffer with "Reporting Amount" = 100, "Amount" = 200
        LibraryIRS1099Document.MockVendorFormBoxBuffer(TempIRS1099VendFormBoxBuffer, EntryNo, PeriodNo, VendNo, FormNo, FormBoxNo);

        // [WHEN] Run create form documents for MISC with Replace option
        TempIRS1099CalcParameters."Form No." := FormNo;
        TempIRS1099CalcParameters.Replace := true;
        LibraryIRS1099Document.CreateFormDocuments(TempIRS1099VendFormBoxBuffer, TempIRS1099CalcParameters);

        // [THEN] The form document for MISC and "X" exists after running create form documents function
        LibraryIRS1099Document.FindIRS1099FormDocHeader(IRS1099FormDocHeader, PeriodNo, VendNo, FormNo);
        // [THEN] There is only one form document for MISC and "X"
        Assert.RecordCount(IRS1099FormDocHeader, 1);
        // [THEN] Form document line has Amount = 100 and "Calculated Amount" = 200
        LibraryIRS1099Document.FindIRS1099FormDocLine(IRS1099FormDocLine, PeriodNo, VendNo, FormNo, FormBoxNo);
        IRS1099FormDocLine.TestField(Amount, TempIRS1099VendFormBoxBuffer."Reporting Amount");
        IRS1099FormDocLine.TestField("Calculated Amount", TempIRS1099VendFormBoxBuffer.Amount);
        // [THEN] There is only one form document line for MISC-01 and "X"
        Assert.RecordCount(IRS1099FormDocLine, 1);

    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ValidateNotInsertedGenJnlLinePostingDateWithLineNo()
    var
        GenJnlLine: Record "Gen. Journal Line";
        PeriodNo: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 536496] It is possible to validate the posting date in the not inserted general journal line with line no. already specified

        Initialize();
        // [GIVEN] "IRS Reporting Period" = "X" with "Starting Date" = work date
        PeriodNo := LibraryIRSReportingPeriod.CreateOneDayReportingPeriod(WorkDate());
        // [GIVEN] "Gen. Journal Line" with "Document Type" = Invoice and "Line No." = 1
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Invoice;
        GenJnlLine."Line No." := 1;
        // [WHEN] Validate posting date with work date
        GenJnlLine.Validate("Posting Date", WorkDate());
        // [THEN] The IRS 1099 Reporting Period is "X"
        GenJnlLine.TestField("IRS 1099 Reporting Period", PeriodNo);

    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ValidateNotInsertedInvGenJnlLineAmountWithLineNo()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 536496] It is possible to validate the amount in the not inserted invoice general journal line with line no. already specified

        Initialize();
        // [GIVEN] "Gen. Journal Line" with "Document Type" = "Invoice" "Line No." = 1
        GenJnlLine."Line No." := 1;
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Invoice;
        // [WHEN] Validate Amount field with 100
        GenJnlLine.Validate(Amount, 100);
        // [THEN] The IRS 1099 Reporting Amount is 100
        GenJnlLine.TestField("IRS 1099 Reporting Amount", 100);

    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ValidateNotInsertedCrMemoGenJnlLineAmountWithLineNo()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 536496] It is possible to validate the amount in the not inserted credit memo general journal line with line no. already specified

        Initialize();
        // [GIVEN] "Gen. Journal Line" with "Document Type" = "Credit Memo" "Line No." = 1
        GenJnlLine."Line No." := 1;
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::"Credit Memo";
        // [WHEN] Validate Amount field with 100
        GenJnlLine.Validate(Amount, 100);
        // [THEN] The IRS 1099 Reporting Amount is 100
        GenJnlLine.TestField("IRS 1099 Reporting Amount", 100);

    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ValidateAmountInTempGenJnlLine()
    var
        TempGenJnlLine: Record "Gen. Journal Line" temporary;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 539449] The amount validation of the temporary general journal line does not affect the IRS amount

        Initialize();
        // [GIVEN] "Gen. Journal Line" with "Line No." = 1
        TempGenJnlLine."Line No." := 1;
        // [WHEN] Validate Amount field with 100
        TempGenJnlLine.Validate(Amount, 100);
        // [THEN] The IRS 1099 Reporting Amount is 0
        TempGenJnlLine.TestField("IRS 1099 Reporting Amount", 0);

    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ValidatePostingDateInTempGenJnlLine()
    var
        TempGenJnlLine: Record "Gen. Journal Line" temporary;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 539449] The posting date validation of the temporary general journal line does not affect the IRS period

        Initialize();
        // [GIVEN] "IRS Reporting Period" = "X" with "Starting Date" = work date
        LibraryIRSReportingPeriod.CreateOneDayReportingPeriod(WorkDate());
        // [GIVEN] "Gen. Journal Line" with "Document Type" = Invoice and "Line No." = 1
        TempGenJnlLine."Document Type" := TempGenJnlLine."Document Type"::Invoice;
        TempGenJnlLine."Line No." := 1;
        // [WHEN] Validate posting date with work date
        TempGenJnlLine.Validate("Posting Date", WorkDate());
        // [THEN] The IRS 1099 Reporting Period is blank
        TempGenJnlLine.TestField("IRS 1099 Reporting Period", '');

    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ValidateAmountInPaymentGenJnlLine()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 539449] The amount validation of the payment general journal line does not affect the IRS amount

        Initialize();
        // [GIVEN] "Gen. Journal Line" with "Document Type" = Payment and "Line No." = 1
        GenJnlLine."Line No." := 1;
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
        // [WHEN] Validate Amount field with 100
        GenJnlLine.Validate(Amount, 100);
        // [THEN] The IRS 1099 Reporting Amount is 0
        GenJnlLine.TestField("IRS 1099 Reporting Amount", 0);

    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ValidatePostingDateInPaymentGenJnlLine()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 539449] The posting date validation of the payment general journal line does not affect the IRS period

        Initialize();
        // [GIVEN] "IRS Reporting Period" = "X" with "Starting Date" = work date
        LibraryIRSReportingPeriod.CreateOneDayReportingPeriod(WorkDate());
        // [GIVEN] "Gen. Journal Line" with "Document Type" = Payment and "Line No." = 1
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
        GenJnlLine."Line No." := 1;
        // [WHEN] Validate posting date with work date
        GenJnlLine.Validate("Posting Date", WorkDate());
        // [THEN] The IRS 1099 Reporting Period is blank
        GenJnlLine.TestField("IRS 1099 Reporting Period", '');

    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CreateFormDocumentForVendorThatHasSubmittedFormWithInitialID()
    var
        TempIRS1099VendFormBoxBuffer: Record "IRS 1099 Vend. Form Box Buffer" temporary;
        TempIRS1099CalcParameters: Record "IRS 1099 Calc. Params";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        OriginalIRS1099FormDocLine, IRS1099FormDocLine : Record "IRS 1099 Form Doc. Line";
        PeriodNo, FormNo, VendNo, FormBoxNo : Code[20];
        DocId, EntryNo : Integer;
    begin
        // [SCENARIO 543741] Stan cannot create form documents when there is an existing form document with ID = 1

        Initialize();
        // [GIVEN] Period = WorkDate(), Form No. = MISC, Form Box No. = MISC-01, Vendor No. = "X"
        PeriodNo := LibraryIRSReportingPeriod.CreateOneDayReportingPeriod(WorkDate());
        FormNo :=
            LibraryIRS1099FormBox.CreateSingleFormInReportingPeriod(WorkDate());
        FormBoxNo :=
            LibraryIRS1099FormBox.CreateSingleFormBoxInReportingPeriod(WorkDate(), FormNo);

        // [GIVEN] Existing submitted form document with ID = 1, MISC and "X"
        VendNo := LibraryIRS1099FormBox.CreateVendorNoWithFormBox(WorkDate(), FormNo, FormBoxNo);
        LibraryIRS1099Document.MockVendorFormBoxBuffer(TempIRS1099VendFormBoxBuffer, EntryNo, PeriodNo, VendNo, FormNo, FormBoxNo);
        DocId := 1;
        MockFormDocumentForVendorWithFixedDocID(DocId, PeriodNo, VendNo, FormNo, "IRS 1099 Form Doc. Status"::Submitted);
        LibraryIRS1099Document.MockFormDocumentLineForVendor(OriginalIRS1099FormDocLine, DocId, PeriodNo, VendNo, FormNo, FormBoxNo);

        // [GIVEN] Period = WorkDate(), Form No. = MISC, Form Box No. = MISC-01, Vendor No. = "Y"
        VendNo := LibraryIRS1099FormBox.CreateVendorNoWithFormBox(WorkDate(), FormNo, FormBoxNo);
        LibraryIRS1099Document.MockVendorFormBoxBuffer(TempIRS1099VendFormBoxBuffer, EntryNo, PeriodNo, VendNo, FormNo, FormBoxNo);

        // [WHEN] Run create form documents for MISC form
        TempIRS1099CalcParameters."Form No." := FormNo;
        LibraryIRS1099Document.CreateFormDocuments(TempIRS1099VendFormBoxBuffer, TempIRS1099CalcParameters);

        // [THEN] Submitted form document for MISC and "X" still exists
        IRS1099FormDocHeader.Get(DocId);
        // [THEN] The form document for MISC and "Y" exists after running create form documents function
        LibraryIRS1099Document.FindIRS1099FormDocHeader(IRS1099FormDocHeader, PeriodNo, VendNo, FormNo);
        // [THEN] There is only one form document for MISC and "Y"
        Assert.RecordCount(IRS1099FormDocHeader, 1);
        // [THEN] Form document line exists
        LibraryIRS1099Document.FindIRS1099FormDocLine(IRS1099FormDocLine, PeriodNo, VendNo, FormNo, FormBoxNo);
        // [THEN] There is only one form document line for MISC-01 and "Y"
        Assert.RecordCount(IRS1099FormDocLine, 1);

    end;

    [Test]
    procedure ValidatePostingDateWhenPurchHeaderNotInitiazed()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 560148] It is possible to validate the posting date in the not initialized purchase header

        Initialize();

        // [GIVEN] IRS Forms app is enabled
        // [WHEN] Validate Posting Date field of the purchase header with current date
        PurchaseHeader.Validate("Posting Date", WorkDate());
        // [THEN] Posting date is equal current date in the purchase header
        PurchaseHeader.TestField("Posting Date", WorkDate());

    end;

    [Test]
    procedure AddSecondLineInFormDocWithDiffBoxNo()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        IRS1099FormDocLine, NewIRS1099FormDocLine : Record "IRS 1099 Form Doc. Line";
    begin
        // [SCENARIO 560523] Stan can add a second line to the form document with a different box number

        Initialize();
        // [GIVEN] IRS Form Document with MISC code
        IRS1099FormDocHeader.Validate("Period No.", LibraryIRSReportingPeriod.CreateOneDayReportingPeriod(WorkDate()));
        IRS1099FormDocHeader.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        IRS1099FormDocHeader.Validate("Form No.", LibraryIRS1099FormBox.CreateSingleFormInReportingPeriod(WorkDate()));
        IRS1099FormDocHeader.Insert(true);
        // [GIVEN] First line of the document has MISC-01
        IRS1099FormDocLine.Validate("Document ID", IRS1099FormDocHeader.ID);
        IRS1099FormDocLine.Validate("Line No.", 10000);
        IRS1099FormDocLine.Validate("Period No.", IRS1099FormDocHeader."Period No.");
        IRS1099FormDocLine.Validate("Vendor No.", IRS1099FormDocHeader."Vendor No.");
        IRS1099FormDocLine.Validate("Form No.", IRS1099FormDocHeader."Form No.");
        IRS1099FormDocLine.Validate(
            "Form Box No.",
            LibraryIRS1099FormBox.CreateSingleFormBoxInReportingPeriod(WorkDate(), IRS1099FormDocHeader."Form No."));
        IRS1099FormDocLine.Insert(true);
        // [GIVEN] Second line is added
        NewIRS1099FormDocLine.Validate("Document ID", IRS1099FormDocHeader.ID);
        NewIRS1099FormDocLine.Validate("Period No.", IRS1099FormDocHeader."Period No.");
        NewIRS1099FormDocLine.Validate("Vendor No.", IRS1099FormDocHeader."Vendor No.");
        NewIRS1099FormDocLine.Validate("Form No.", IRS1099FormDocHeader."Form No.");
        // [WHEN] Validate Form Box No. with MISC-02
        NewIRS1099FormDocLine.Validate(
            "Form Box No.",
            LibraryIRS1099FormBox.CreateSingleFormBoxInReportingPeriod(WorkDate(), IRS1099FormDocHeader."Form No."));
        // [THEN] Form Box No. is validated
        NewIRS1099FormDocLine.TestField("Form Box No.");

        // Tear down
        IRS1099FormDocHeader.Delete(true);
    end;

    [Test]
    procedure PurchInvWithManualNoSeries()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchPayablesSetup: Record "Purchases & Payables Setup";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 561813] It is possible to insert purchase invoice with manual series and 1099 information from vendor

        Initialize();

        // [GIVEN] IRS Forms app is enabled
        PurchPayablesSetup.Get();
        PurchPayablesSetup.Validate("Invoice Nos.", LibraryERM.CreateNoSeriesCode());
        PurchPayablesSetup.Modify(true);

        //PurchaseHeader.Validate("No. Series", PurchPayablesSetup."Invoice Nos.");
        PurchaseHeader.Validate("Document Type", PurchaseHeader."Document Type"::Invoice);
        PurchaseHeader.Validate("No.", LibraryUtility.GenerateGUID());
        // [WHEN] Validate "Buy-from Vendor No." of the purchase header
        PurchaseHeader.Validate("Buy-from Vendor No.", LibraryPurchase.CreateVendorNo());
        // [THEN] Posting date is equal current date in the purchase header
        PurchaseHeader.TestField("No.");

    end;

    [Test]
    procedure VerifyPeriodNoFieldVisible()
    var
        IRS1099FormDocument: TestPage "IRS 1099 Form Documents";
    begin
        // [SCENARIO 574754] "Period No." field is visible when open blank "IRS 1099 form Document" 
        Initialize();

        // [WHEN] Open the blank IRS 1099 Document card page.
        IRS1099FormDocument.OpenEdit();

        // [THEN] "Period No." field is visible
        Assert.IsTrue(IRS1099FormDocument."Period No.".Visible(), PeriodNoFieldVisibleErr);
    end;

    [Test]
    procedure VerifyPeriodNoFieldNotVisible()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        IRS1099FormDocuments: TestPage "IRS 1099 Form Documents";
        IRS1099FormDocument: TestPage "IRS 1099 Form Document";
    begin
        // [SCENARIO 574754] "Period No."" field is not visible when open "IRS 1099 form Documents" have some record
        Initialize();

        // [GIVEN] Create IRS1099FormDocHeader
        MockFormDocument(IRS1099FormDocHeader, "IRS 1099 Form Doc. Status"::Open);

        // [GIVEN] Open the list page and go to created record
        IRS1099FormDocuments.OpenView();
        IRS1099FormDocuments.Filter.SetFilter("Vendor No.", IRS1099FormDocHeader."Vendor No.");

        // [GIVEN] Trap the card page "IRS 1099 form Document"
        IRS1099FormDocument.Trap();

        // [WHEN] Edit the list page "IRS 1099 form Documents"
        IRS1099FormDocuments.Edit().Invoke();

        // [THEN] Verify the "Period No." field is not visible on page.
        Assert.IsFalse(IRS1099FormDocument."Period No.".Visible(), PeriodNoNotVisibleErr);
    end;

    [Test]
    procedure IRS1099DataUpdatedInPurchHeaderWhenPostingDateChangedToNewPeriod()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
        FormNo: array[2] of Code[20];
        FormBoxNo: array[2] of Code[20];
        ReportingDate: array[2] of Date;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 616165] IRS 1099 data is updated in purchase header when posting date changes to a different reporting period
        Initialize();

        // [GIVEN] Two IRS Reporting Periods: "P1" for WorkDate() and "P2" for WorkDate() + 1 year
        ReportingDate[1] := WorkDate();
        ReportingDate[2] := CalcDate('<1Y>', WorkDate());
        LibraryIRSReportingPeriod.CreateOneDayReportingPeriod(ReportingDate[1]);
        LibraryIRSReportingPeriod.CreateOneDayReportingPeriod(ReportingDate[2]);

        // [GIVEN] Form "F1" with form box "FB1" for period "P1"
        FormNo[1] := LibraryIRS1099FormBox.CreateSingleFormInReportingPeriod(ReportingDate[1]);
        FormBoxNo[1] := LibraryIRS1099FormBox.CreateSingleFormBoxInReportingPeriod(ReportingDate[1], FormNo[1]);

        // [GIVEN] Form "F2" with form box "FB2" for period "P2"
        FormNo[2] := LibraryIRS1099FormBox.CreateSingleFormInReportingPeriod(ReportingDate[2]);
        FormBoxNo[2] := LibraryIRS1099FormBox.CreateSingleFormBoxInReportingPeriod(ReportingDate[2], FormNo[2]);

        // [GIVEN] Vendor "V" with form box "FB1" for period "P1" and form box "FB2" for period "P2"
        VendorNo := LibraryIRS1099FormBox.CreateVendorNoWithFormBox(ReportingDate[1], FormNo[1], FormBoxNo[1]);
        LibraryIRS1099FormBox.AssignFormBoxForVendorInPeriod(VendorNo, ReportingDate[2], ReportingDate[2], FormNo[2], FormBoxNo[2]);

        // [GIVEN] Purchase invoice for vendor "V" with posting date in period "P1"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        LibraryIRS1099Document.VerifyIRS1099CodeInPurchaseHeader(PurchaseHeader, FormNo[1], FormBoxNo[1]);

        // [WHEN] Change posting date to period "P2"
        PurchaseHeader.Validate("Posting Date", ReportingDate[2]);

        // [THEN] IRS 1099 data is updated to reflect form box setup for period "P2"
        LibraryIRS1099Document.VerifyIRS1099CodeInPurchaseHeader(PurchaseHeader, FormNo[2], FormBoxNo[2]);
    end;

    [Test]
    procedure IRS1099DataUpdatedInGenJnlLineWhenPostingDateChangedToNewPeriod()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        VendorNo: Code[20];
        FormNo: array[2] of Code[20];
        FormBoxNo: array[2] of Code[20];
        ReportingDate: array[2] of Date;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 616165] IRS 1099 data is updated in general journal line when posting date changes to a different reporting period
        Initialize();

        // [GIVEN] Two IRS Reporting Periods: "P1" for WorkDate() and "P2" for WorkDate() + 1 year
        ReportingDate[1] := WorkDate();
        ReportingDate[2] := CalcDate('<1Y>', WorkDate());
        LibraryIRSReportingPeriod.CreateOneDayReportingPeriod(ReportingDate[1]);
        LibraryIRSReportingPeriod.CreateOneDayReportingPeriod(ReportingDate[2]);

        // [GIVEN] Form "F1" with form box "FB1" for period "P1"
        FormNo[1] := LibraryIRS1099FormBox.CreateSingleFormInReportingPeriod(ReportingDate[1]);
        FormBoxNo[1] := LibraryIRS1099FormBox.CreateSingleFormBoxInReportingPeriod(ReportingDate[1], FormNo[1]);

        // [GIVEN] Form "F2" with form box "FB2" for period "P2"
        FormNo[2] := LibraryIRS1099FormBox.CreateSingleFormInReportingPeriod(ReportingDate[2]);
        FormBoxNo[2] := LibraryIRS1099FormBox.CreateSingleFormBoxInReportingPeriod(ReportingDate[2], FormNo[2]);

        // [GIVEN] Vendor "V" with form box "FB1" for period "P1" and form box "FB2" for period "P2"
        VendorNo := LibraryIRS1099FormBox.CreateVendorNoWithFormBox(ReportingDate[1], FormNo[1], FormBoxNo[1]);
        LibraryIRS1099FormBox.AssignFormBoxForVendorInPeriod(VendorNo, ReportingDate[2], ReportingDate[2], FormNo[2], FormBoxNo[2]);

        // [GIVEN] General journal line with document type Invoice for vendor "V" with posting date in period "P1"
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, VendorNo,
            GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Posting Date", ReportingDate[1]);
        GenJournalLine.Modify(true);
        VerifyIRS1099DataInGenJnlLine(GenJournalLine, ReportingDate[1], FormNo[1], FormBoxNo[1]);

        // [WHEN] Change posting date to period "P2"
        GenJournalLine.Validate("Posting Date", ReportingDate[2]);

        // [THEN] IRS 1099 data is updated to reflect form box setup for period "P2"
        VerifyIRS1099DataInGenJnlLine(GenJournalLine, ReportingDate[2], FormNo[2], FormBoxNo[2]);
    end;

    [Test]
    procedure InsertPurchaseQuoteAfterInitExistingRecord()
    var
        ExistingPurchaseHeader: Record "Purchase Header";
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 616165] No error when inserting a purchase quote after calling Init() on an existing record
        Initialize();

        // [GIVEN] IRS Reporting Period for WorkDate()
        LibraryIRSReportingPeriod.CreateOneDayReportingPeriod(WorkDate());

        // [GIVEN] Vendor "V"
        VendorNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Existing purchase quote for vendor "V"
        LibraryPurchase.CreatePurchHeader(ExistingPurchaseHeader, ExistingPurchaseHeader."Document Type"::Quote, VendorNo);

        // [GIVEN] Find the existing purchase quote and call Init()
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Quote);
        PurchaseHeader.SetRange("Buy-from Vendor No.", VendorNo);
        PurchaseHeader.FindFirst();
        PurchaseHeader.Init();
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Quote;
        PurchaseHeader."No." := '';

        // [WHEN] Insert the new purchase header
        PurchaseHeader.Insert(true);

        // [THEN] No error occurs and purchase quote is created
        Assert.AreNotEqual('', PurchaseHeader."No.", 'Purchase quote should be created with a No.');
    end;

    [Test]
    procedure DeleteFormDocWithUniqueDocIDDoesNotAffectOtherDoc()
    var
        IRS1099FormDocHeader: array[2] of Record "IRS 1099 Form Doc. Header";
        IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
        IRS1099FormDocLineDetail: Record "IRS 1099 Form Doc. Line Detail";
        PeriodNo, FormNo, FormBoxNo : Code[20];
        VendNo: array[2] of Code[20];
        i: Integer;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 617498] Deleting one form document does not affect line details of another form document due to unique Document IDs

        Initialize();

        // [GIVEN] Period "P", Form "F" and Form Box "FB"
        PeriodNo := LibraryIRSReportingPeriod.CreateOneDayReportingPeriod(WorkDate());
        FormNo := LibraryIRS1099FormBox.CreateSingleFormInReportingPeriod(WorkDate());
        FormBoxNo := LibraryIRS1099FormBox.CreateSingleFormBoxInReportingPeriod(WorkDate(), FormNo);

        // [GIVEN] Two vendors "V1" and "V2" with form documents in period "P"
        for i := 1 to 2 do begin
            VendNo[i] := LibraryIRS1099FormBox.CreateVendorNoWithFormBox(WorkDate(), FormNo, FormBoxNo);
            IRS1099FormDocHeader[i]."Period No." := PeriodNo;
            IRS1099FormDocHeader[i]."Vendor No." := VendNo[i];
            IRS1099FormDocHeader[i]."Form No." := FormNo;
            IRS1099FormDocHeader[i].Insert(true);
            Clear(IRS1099FormDocLine);
            IRS1099FormDocLine."Document ID" := IRS1099FormDocHeader[i].ID;
            IRS1099FormDocLine."Period No." := PeriodNo;
            IRS1099FormDocLine."Vendor No." := VendNo[i];
            IRS1099FormDocLine."Form No." := FormNo;
            IRS1099FormDocLine."Line No." := 10000;
            IRS1099FormDocLine."Form Box No." := FormBoxNo;
            IRS1099FormDocLine.Insert();
            Clear(IRS1099FormDocLineDetail);
            IRS1099FormDocLineDetail."Document ID" := IRS1099FormDocHeader[i].ID;
            IRS1099FormDocLineDetail."Line No." := 10000;
            IRS1099FormDocLineDetail."Vendor Ledger Entry No." := i * 100;
            IRS1099FormDocLineDetail.Insert();
        end;

        // [WHEN] Delete form document for "V1"
        IRS1099FormDocHeader[1].Delete(true);

        // [THEN] Form document for "V2" exists with its line detail
        Assert.IsTrue(IRS1099FormDocHeader[2].Find(), 'Form document for V2 should exist');
        IRS1099FormDocLine.SetRange("Document ID", IRS1099FormDocHeader[2].ID);
        Assert.RecordCount(IRS1099FormDocLine, 1);
        IRS1099FormDocLineDetail.SetRange("Document ID", IRS1099FormDocHeader[2].ID);
        Assert.RecordCount(IRS1099FormDocLineDetail, 1);

        // Tear down
        IRS1099FormDocHeader[2].Delete(true);
    end;

    [Test]
    procedure PartialPaymentCreatesLineDetailWithDifferentCalculatedAndReportingAmounts()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
        IRS1099FormDocLineDetail: Record "IRS 1099 Form Doc. Line Detail";
        IRSFormsSetup: Record "IRS Forms Setup";
        PeriodNo, FormNo, FormBoxNo, VendNo : Code[20];
        InvoiceAmount, PaymentAmount : Decimal;
        PostingDate: Date;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 617498] Partial payment creates line detail with different "Calculated Amount" and "IRS 1099 Reporting Amount"

        Initialize();

        // [GIVEN] Collect Details For Line is enabled
        if not IRSFormsSetup.Get() then
            IRSFormsSetup.Insert();
        IRSFormsSetup."Collect Details For Line" := true;
        IRSFormsSetup.Modify();

        // [GIVEN] Period "P", Form "F" and Form Box "FB" for a unique future date
        PostingDate := CalcDate('<2Y>', WorkDate());
        PeriodNo := LibraryIRSReportingPeriod.CreateOneDayReportingPeriod(PostingDate);
        FormNo := LibraryIRS1099FormBox.CreateSingleFormInReportingPeriod(PostingDate);
        FormBoxNo := LibraryIRS1099FormBox.CreateSingleFormBoxInReportingPeriod(PostingDate, FormNo);
        VendNo := LibraryIRS1099FormBox.CreateVendorNoWithFormBox(PostingDate, FormNo, FormBoxNo);

        // [GIVEN] Posted purchase invoice with Amount = 1000 for vendor "V"
        InvoiceAmount := 1000;
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendNo);
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLineWithUnitCost(
            PurchaseLine, PurchaseHeader, LibraryInventory.CreateItemNo(), 1, InvoiceAmount);
        LibraryERM.FindVendorLedgerEntry(
            VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice,
            LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
        VendorLedgerEntry.CalcFields(Amount);
        InvoiceAmount := Abs(VendorLedgerEntry."IRS 1099 Reporting Amount");

        // [GIVEN] Payment with Amount = 500 applied to the invoice (partial payment - 50%)
        PaymentAmount := Round(InvoiceAmount / 2);
        LibraryIRS1099Document.PostPaymentAppliedToInvoice(PostingDate, VendNo, VendorLedgerEntry."Document No.", PaymentAmount);

        // [WHEN] Create form documents
        LibraryIRS1099Document.CreateFormDocuments(PostingDate, PostingDate, VendNo, FormNo);

        // [THEN] Form document line detail has different "Calculated Amount" and "IRS 1099 Reporting Amount"
        LibraryIRS1099Document.FindIRS1099FormDocHeader(IRS1099FormDocHeader, PeriodNo, VendNo, FormNo);
        LibraryIRS1099Document.FindIRS1099FormDocLine(IRS1099FormDocLine, PeriodNo, VendNo, FormNo, FormBoxNo);
        IRS1099FormDocLineDetail.SetRange("Document ID", IRS1099FormDocHeader.ID);
        IRS1099FormDocLineDetail.FindFirst();
        IRS1099FormDocLineDetail.CalcFields("IRS 1099 Reporting Amount");

        // [THEN] "IRS 1099 Reporting Amount" = Invoice Amount (sign may differ in form doc line detail)
        Assert.AreEqual(InvoiceAmount, Abs(IRS1099FormDocLineDetail."IRS 1099 Reporting Amount"), 'IRS 1099 Reporting Amount should be full invoice amount');

        // [THEN] "Calculated Amount" = Payment Amount / Invoice Amount * IRS Reporting Amount = 500 (proportional to payment)
        Assert.AreEqual(PaymentAmount, IRS1099FormDocLineDetail."Calculated Amount", 'Calculated Amount should reflect partial payment');

        // [THEN] "Calculated Amount" <> "IRS 1099 Reporting Amount"
        Assert.AreNotEqual(
            Abs(IRS1099FormDocLineDetail."Calculated Amount"),
            Abs(IRS1099FormDocLineDetail."IRS 1099 Reporting Amount"),
            'Calculated Amount and IRS 1099 Reporting Amount should be different for partial payment');

        // Tear down
        DeleteDocuments();
    end;

    [Test]
    procedure FormDocLineIncludeIn1099FalseWhenAmountBelowMinimum()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        IRS1099FormBox: Record "IRS 1099 Form Box";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        PeriodNo: Code[20];
        FormNo: Code[20];
        FormBoxNo: Code[20];
        VendNo: Code[20];
        PostingDate: Date;
        MinimumReportableAmount: Decimal;
        InvoiceAmount: Decimal;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 620124] No form document is created when payment amount is less than "Minimum Reportable Amount"
        Initialize();

        // [GIVEN] Minimum Reportable Amount = 600
        MinimumReportableAmount := 600;
        InvoiceAmount := 100;
        PostingDate := WorkDate();

        // [GIVEN] IRS Reporting Period "P" with Form "F" and Form Box "FB" with "Minimum Reportable Amount" = 600
        PeriodNo := LibraryIRSReportingPeriod.CreateOneDayReportingPeriod(PostingDate);
        FormNo := LibraryIRS1099FormBox.CreateSingleFormInReportingPeriod(PostingDate);
        FormBoxNo := LibraryIRS1099FormBox.CreateSingleFormBoxInReportingPeriod(PostingDate, FormNo);
        IRS1099FormBox.Get(PeriodNo, FormNo, FormBoxNo);
        IRS1099FormBox.Validate("Minimum Reportable Amount", MinimumReportableAmount);
        IRS1099FormBox.Modify(true);

        // [GIVEN] Vendor "V" with Form Box "FB"
        VendNo := LibraryIRS1099FormBox.CreateVendorNoWithFormBox(PostingDate, FormNo, FormBoxNo);

        // [GIVEN] Posted purchase invoice for vendor "V" with Amount = 100
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendNo);
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine, PurchaseHeader, LibraryInventory.CreateItemNo(), 1, InvoiceAmount);
        LibraryERM.FindVendorLedgerEntry(
            VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice,
            LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
        VendorLedgerEntry.CalcFields(Amount);

        // [GIVEN] Payment with amount 100 applied to the invoice
        LibraryIRS1099Document.PostPaymentAppliedToInvoice(PostingDate, VendNo, VendorLedgerEntry."Document No.", -VendorLedgerEntry.Amount);

        // [WHEN] Create form documents
        LibraryIRS1099Document.CreateFormDocuments(PostingDate, PostingDate, VendNo, FormNo);

        // [THEN] No form document header is created for vendor "V" when amount is below minimum reportable amount
        IRS1099FormDocHeader.SetRange("Period No.", PeriodNo);
        IRS1099FormDocHeader.SetRange("Vendor No.", VendNo);
        IRS1099FormDocHeader.SetRange("Form No.", FormNo);
        Assert.RecordIsEmpty(IRS1099FormDocHeader);

        // Tear down
        DeleteDocuments();
    end;

    [Test]
    procedure FormDocLineIncludeIn1099TrueWhenAmountEqualsMinimum()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
        IRS1099FormBox: Record "IRS 1099 Form Box";
        PeriodNo: Code[20];
        FormNo: Code[20];
        FormBoxNo: Code[20];
        VendNo: Code[20];
        MinimumReportableAmount: Decimal;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 620524] "Include In 1099" is TRUE when Amount equals "Minimum Reportable Amount"
        Initialize();
        MinimumReportableAmount := 600;

        // [GIVEN] IRS Reporting Period with Form "F" and Form Box "FB" having "Minimum Reportable Amount" = 600
        PeriodNo := LibraryIRSReportingPeriod.CreateOneDayReportingPeriod(WorkDate());
        FormNo := LibraryIRS1099FormBox.CreateSingleFormInReportingPeriod(WorkDate());
        FormBoxNo := LibraryIRS1099FormBox.CreateSingleFormBoxInReportingPeriod(WorkDate(), FormNo);
        IRS1099FormBox.Get(PeriodNo, FormNo, FormBoxNo);
        IRS1099FormBox.Validate("Minimum Reportable Amount", MinimumReportableAmount);
        IRS1099FormBox.Modify(true);

        // [GIVEN] Vendor "V" with form box "FB"
        VendNo := LibraryIRS1099FormBox.CreateVendorNoWithFormBox(WorkDate(), FormNo, FormBoxNo);

        // [GIVEN] Open form document for vendor "V"
        IRS1099FormDocHeader.Validate("Period No.", PeriodNo);
        IRS1099FormDocHeader.Validate("Vendor No.", VendNo);
        IRS1099FormDocHeader.Validate("Form No.", FormNo);
        IRS1099FormDocHeader.Insert(true);

        // [GIVEN] Form document line with "Minimum Reportable Amount" = 600
        IRS1099FormDocLine."Document ID" := IRS1099FormDocHeader.ID;
        IRS1099FormDocLine."Period No." := PeriodNo;
        IRS1099FormDocLine."Vendor No." := VendNo;
        IRS1099FormDocLine."Form No." := FormNo;
        IRS1099FormDocLine."Line No." := 10000;
        IRS1099FormDocLine."Form Box No." := FormBoxNo;
        IRS1099FormDocLine."Minimum Reportable Amount" := MinimumReportableAmount;
        IRS1099FormDocLine.Insert();

        // [WHEN] Validate Amount to exactly equal the Minimum Reportable Amount
        IRS1099FormDocLine.Validate(Amount, MinimumReportableAmount);

        // [THEN] "Include In 1099" is TRUE
        Assert.IsTrue(
            IRS1099FormDocLine."Include In 1099",
            'Include In 1099 should be TRUE when Amount equals Minimum Reportable Amount');
        IRS1099FormDocHeader.Delete(true);
    end;

    [Test]
    procedure FormDocLineIncludeIn1099TrueWhenAmountAboveMinimum()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
        IRS1099FormBox: Record "IRS 1099 Form Box";
        PeriodNo: Code[20];
        FormNo: Code[20];
        FormBoxNo: Code[20];
        VendNo: Code[20];
        MinimumReportableAmount: Decimal;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 620524] "Include In 1099" is TRUE when Amount is above "Minimum Reportable Amount"
        Initialize();
        MinimumReportableAmount := 600;

        // [GIVEN] IRS Reporting Period with Form "F" and Form Box "FB" having "Minimum Reportable Amount" = 600
        PeriodNo := LibraryIRSReportingPeriod.CreateOneDayReportingPeriod(WorkDate());
        FormNo := LibraryIRS1099FormBox.CreateSingleFormInReportingPeriod(WorkDate());
        FormBoxNo := LibraryIRS1099FormBox.CreateSingleFormBoxInReportingPeriod(WorkDate(), FormNo);
        IRS1099FormBox.Get(PeriodNo, FormNo, FormBoxNo);
        IRS1099FormBox.Validate("Minimum Reportable Amount", MinimumReportableAmount);
        IRS1099FormBox.Modify(true);

        // [GIVEN] Vendor "V" with form box "FB"
        VendNo := LibraryIRS1099FormBox.CreateVendorNoWithFormBox(WorkDate(), FormNo, FormBoxNo);

        // [GIVEN] Open form document for vendor "V"
        IRS1099FormDocHeader.Validate("Period No.", PeriodNo);
        IRS1099FormDocHeader.Validate("Vendor No.", VendNo);
        IRS1099FormDocHeader.Validate("Form No.", FormNo);
        IRS1099FormDocHeader.Insert(true);

        // [GIVEN] Form document line with "Minimum Reportable Amount" = 600
        IRS1099FormDocLine."Document ID" := IRS1099FormDocHeader.ID;
        IRS1099FormDocLine."Period No." := PeriodNo;
        IRS1099FormDocLine."Vendor No." := VendNo;
        IRS1099FormDocLine."Form No." := FormNo;
        IRS1099FormDocLine."Line No." := 10000;
        IRS1099FormDocLine."Form Box No." := FormBoxNo;
        IRS1099FormDocLine."Minimum Reportable Amount" := MinimumReportableAmount;
        IRS1099FormDocLine.Insert();

        // [WHEN] Validate Amount to be above the Minimum Reportable Amount
        IRS1099FormDocLine.Validate(Amount, MinimumReportableAmount + 100);

        // [THEN] "Include In 1099" is TRUE
        Assert.IsTrue(
            IRS1099FormDocLine."Include In 1099",
            'Include In 1099 should be TRUE when Amount is above Minimum Reportable Amount');
        IRS1099FormDocHeader.Delete(true);
    end;

    [Test]
    procedure FormDocLineIncludeIn1099FalseWhenAmountBelowMinimumUT()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
        IRS1099FormBox: Record "IRS 1099 Form Box";
        PeriodNo: Code[20];
        FormNo: Code[20];
        FormBoxNo: Code[20];
        VendNo: Code[20];
        MinimumReportableAmount: Decimal;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 620524] "Include In 1099" is FALSE when Amount is below "Minimum Reportable Amount"
        Initialize();
        MinimumReportableAmount := 600;

        // [GIVEN] IRS Reporting Period with Form "F" and Form Box "FB" having "Minimum Reportable Amount" = 600
        PeriodNo := LibraryIRSReportingPeriod.CreateOneDayReportingPeriod(WorkDate());
        FormNo := LibraryIRS1099FormBox.CreateSingleFormInReportingPeriod(WorkDate());
        FormBoxNo := LibraryIRS1099FormBox.CreateSingleFormBoxInReportingPeriod(WorkDate(), FormNo);
        IRS1099FormBox.Get(PeriodNo, FormNo, FormBoxNo);
        IRS1099FormBox.Validate("Minimum Reportable Amount", MinimumReportableAmount);
        IRS1099FormBox.Modify(true);

        // [GIVEN] Vendor "V" with form box "FB"
        VendNo := LibraryIRS1099FormBox.CreateVendorNoWithFormBox(WorkDate(), FormNo, FormBoxNo);

        // [GIVEN] Open form document for vendor "V"
        IRS1099FormDocHeader.Validate("Period No.", PeriodNo);
        IRS1099FormDocHeader.Validate("Vendor No.", VendNo);
        IRS1099FormDocHeader.Validate("Form No.", FormNo);
        IRS1099FormDocHeader.Insert(true);

        // [GIVEN] Form document line with "Minimum Reportable Amount" = 600
        IRS1099FormDocLine."Document ID" := IRS1099FormDocHeader.ID;
        IRS1099FormDocLine."Period No." := PeriodNo;
        IRS1099FormDocLine."Vendor No." := VendNo;
        IRS1099FormDocLine."Form No." := FormNo;
        IRS1099FormDocLine."Line No." := 10000;
        IRS1099FormDocLine."Form Box No." := FormBoxNo;
        IRS1099FormDocLine."Minimum Reportable Amount" := MinimumReportableAmount;
        IRS1099FormDocLine.Insert();

        // [WHEN] Validate Amount to be below the Minimum Reportable Amount
        IRS1099FormDocLine.Validate(Amount, MinimumReportableAmount - 100);

        // [THEN] "Include In 1099" is FALSE
        Assert.IsFalse(
            IRS1099FormDocLine."Include In 1099",
            'Include In 1099 should be FALSE when Amount is below Minimum Reportable Amount');
        IRS1099FormDocHeader.Delete(true);
    end;

    [Test]
    procedure IRS1099CodeInPurchInvHeaderUpdatedWhenChangedInVendLedgEntry()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorLedgEntry: Record "Vendor Ledger Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
        VendNo: Code[20];
        FormNo: Code[20];
        FormBoxNo: array[2] of Code[20];
        InvNo: Code[20];
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 611578] IRS 1099 Form Box No. in Purch. Inv. Header is updated when changed in the Vendor Ledger Entry
        Initialize();

        // [GIVEN] IRS Reporting Period for WorkDate with Form "F" and two Form Boxes "FB1" and "FB2"
        LibraryIRSReportingPeriod.CreateOneDayReportingPeriod(WorkDate());
        FormNo :=
            LibraryIRS1099FormBox.CreateSingleFormInReportingPeriod(WorkDate(), WorkDate());
        FormBoxNo[1] :=
            LibraryIRS1099FormBox.CreateSingleFormBoxInReportingPeriod(WorkDate(), WorkDate(), FormNo);
        FormBoxNo[2] :=
            LibraryIRS1099FormBox.CreateSingleFormBoxInReportingPeriod(WorkDate(), WorkDate(), FormNo);

        // [GIVEN] Vendor "V" with IRS 1099 setup pointing to Form Box "FB1"
        VendNo := LibraryIRS1099FormBox.CreateVendorNoWithFormBox(WorkDate(), WorkDate(), FormNo, FormBoxNo[1]);

        // [GIVEN] Posted purchase invoice for vendor "V"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendNo);
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine, PurchaseHeader, LibraryInventory.CreateItemNo(), 1, 1);
        InvNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Change "IRS 1099 Form Box No." in the Vendor Ledger Entry to "FB2"
        LibraryERM.FindVendorLedgerEntry(VendorLedgEntry, VendorLedgEntry."Document Type"::Invoice, InvNo);
        VendorLedgEntry.Validate("IRS 1099 Form Box No.", FormBoxNo[2]);
        VendorLedgEntry.Modify(true);

        // [THEN] "IRS 1099 Form Box No." in the related Purch. Inv. Header is updated to "FB2"
        PurchInvHeader.Get(InvNo);
        Assert.AreEqual(FormBoxNo[2], PurchInvHeader."IRS 1099 Form Box No.", 'IRS 1099 Form Box No. in Purch. Inv. Header should be updated');
    end;

    [Test]
    procedure IRS1099CodeInPurchCrMemoHeaderUpdatedWhenChangedInVendLedgEntry()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorLedgEntry: Record "Vendor Ledger Entry";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        VendNo: Code[20];
        FormNo: Code[20];
        FormBoxNo: array[2] of Code[20];
        CrMemoNo: Code[20];
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 611578] IRS 1099 Form Box No. in Purch. Cr. Memo Hdr. is updated when changed in the Vendor Ledger Entry
        Initialize();

        // [GIVEN] IRS Reporting Period for WorkDate with Form "F" and two Form Boxes "FB1" and "FB2"
        LibraryIRSReportingPeriod.CreateOneDayReportingPeriod(WorkDate());
        FormNo :=
            LibraryIRS1099FormBox.CreateSingleFormInReportingPeriod(WorkDate(), WorkDate());
        FormBoxNo[1] :=
            LibraryIRS1099FormBox.CreateSingleFormBoxInReportingPeriod(WorkDate(), WorkDate(), FormNo);
        FormBoxNo[2] :=
            LibraryIRS1099FormBox.CreateSingleFormBoxInReportingPeriod(WorkDate(), WorkDate(), FormNo);

        // [GIVEN] Vendor "V" with IRS 1099 setup pointing to Form Box "FB1"
        VendNo := LibraryIRS1099FormBox.CreateVendorNoWithFormBox(WorkDate(), WorkDate(), FormNo, FormBoxNo[1]);

        // [GIVEN] Posted purchase credit memo for vendor "V"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendNo);
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine, PurchaseHeader, LibraryInventory.CreateItemNo(), 1, 1);
        CrMemoNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Change "IRS 1099 Form Box No." in the Vendor Ledger Entry to "FB2"
        LibraryERM.FindVendorLedgerEntry(VendorLedgEntry, VendorLedgEntry."Document Type"::"Credit Memo", CrMemoNo);
        VendorLedgEntry.Validate("IRS 1099 Form Box No.", FormBoxNo[2]);
        VendorLedgEntry.Modify(true);

        // [THEN] "IRS 1099 Form Box No." in the related Purch. Cr. Memo Hdr. is updated to "FB2"
        PurchCrMemoHdr.Get(CrMemoNo);
        Assert.AreEqual(FormBoxNo[2], PurchCrMemoHdr."IRS 1099 Form Box No.", 'IRS 1099 Form Box No. in Purch. Cr. Memo Hdr. should be updated');
    end;

    [Test]
    procedure ValidateIRS1099PeriodOnVendLedgEntryForNon1099Vendor()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorLedgEntry: Record "Vendor Ledger Entry";
        VendNo: Code[20];
        FormNo: Code[20];
        PeriodNo: Code[20];
        InvNo: Code[20];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 620132] Setting IRS 1099 Reporting Period on vendor ledger entry of a vendor with no 1099 setup raises an error

        Initialize();
        // [GIVEN] IRS Reporting Period "P" with form "F" and form box "FB"
        PeriodNo := LibraryIRSReportingPeriod.CreateOneDayReportingPeriod(WorkDate());
        FormNo := LibraryIRS1099FormBox.CreateSingleFormInReportingPeriod(WorkDate(), WorkDate());
        LibraryIRS1099FormBox.CreateSingleFormBoxInReportingPeriod(WorkDate(), WorkDate(), FormNo);

        // [GIVEN] Vendor "V" with NO IRS 1099 form box setup (plain vendor)
        VendNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Posted purchase invoice for vendor "V"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendNo);
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine, PurchaseHeader, LibraryInventory.CreateItemNo(), 1, 100);
        InvNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Validate "IRS 1099 Reporting Period" in the vendor ledger entry
        LibraryERM.FindVendorLedgerEntry(VendorLedgEntry, VendorLedgEntry."Document Type"::Invoice, InvNo);
        // [THEN] An error is raised because vendor "V" has no 1099 setup for the period
        asserterror VendorLedgEntry.Validate("IRS 1099 Reporting Period", PeriodNo);
        Assert.ExpectedError(StrSubstNo(VendorNotSetupForIRS1099Err, VendNo, PeriodNo));
    end;

    [Test]
    procedure ValidateIRS1099FormBoxOnVendLedgEntryFor1099Vendor()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorLedgEntry: Record "Vendor Ledger Entry";
        VendNo: Code[20];
        FormNo: Code[20];
        FormBoxNo: Code[20];
        PeriodNo: Code[20];
        InvNo: Code[20];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 620132] Vendor WITH 1099 setup can still validate form box on its ledger entry without error

        Initialize();
        // [GIVEN] IRS Reporting Period with Form "F" and Form Box "FB"
        PeriodNo := LibraryIRSReportingPeriod.CreateOneDayReportingPeriod(WorkDate());
        FormNo := LibraryIRS1099FormBox.CreateSingleFormInReportingPeriod(WorkDate(), WorkDate());
        FormBoxNo := LibraryIRS1099FormBox.CreateSingleFormBoxInReportingPeriod(WorkDate(), WorkDate(), FormNo);

        // [GIVEN] Vendor "V" WITH IRS 1099 form box setup
        VendNo := LibraryIRS1099FormBox.CreateVendorNoWithFormBox(WorkDate(), WorkDate(), FormNo, FormBoxNo);

        // [GIVEN] Posted purchase invoice for vendor "V"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendNo);
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine, PurchaseHeader, LibraryInventory.CreateItemNo(), 1, 100);
        InvNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Validate the IRS 1099 fields in the vendor ledger entry
        LibraryERM.FindVendorLedgerEntry(VendorLedgEntry, VendorLedgEntry."Document Type"::Invoice, InvNo);
        // [THEN] No error is raised for a vendor that has 1099 setup
        VendorLedgEntry.Validate("IRS 1099 Reporting Period", PeriodNo);
        VendorLedgEntry.Validate("IRS 1099 Form No.", FormNo);
        VendorLedgEntry.Validate("IRS 1099 Form Box No.", FormBoxNo);
        VendorLedgEntry.TestField("IRS 1099 Form Box No.", FormBoxNo);
    end;

    [Test]
    procedure ValidateIRS1099FormAndFormBoxOnVendLedgEntryForNon1099Vendor()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorLedgEntry: Record "Vendor Ledger Entry";
        VendNo: Code[20];
        FormNo: Code[20];
        FormBoxNo: Code[20];
        PeriodNo: Code[20];
        InvNo: Code[20];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 620132] Setting IRS 1099 Form No. or Form Box No. on vendor ledger entry of a vendor with no 1099 setup raises an error

        Initialize();
        // [GIVEN] IRS Reporting Period "P" with form "F" and form box "FB"
        PeriodNo := LibraryIRSReportingPeriod.CreateOneDayReportingPeriod(WorkDate());
        FormNo := LibraryIRS1099FormBox.CreateSingleFormInReportingPeriod(WorkDate(), WorkDate());
        FormBoxNo := LibraryIRS1099FormBox.CreateSingleFormBoxInReportingPeriod(WorkDate(), WorkDate(), FormNo);

        // [GIVEN] Vendor "V" with NO IRS 1099 form box setup (plain vendor)
        VendNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Posted purchase invoice for vendor "V", with IRS period set directly (bypassing validation)
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendNo);
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine, PurchaseHeader, LibraryInventory.CreateItemNo(), 1, 100);
        InvNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryERM.FindVendorLedgerEntry(VendorLedgEntry, VendorLedgEntry."Document Type"::Invoice, InvNo);
        VendorLedgEntry."IRS 1099 Reporting Period" := PeriodNo;
        VendorLedgEntry.Modify();

        // [WHEN] Validate "IRS 1099 Form No." in the vendor ledger entry
        // [THEN] An error is raised because vendor "V" has no 1099 setup for the period
        asserterror VendorLedgEntry.Validate("IRS 1099 Form No.", FormNo);
        Assert.ExpectedError(StrSubstNo(VendorNotSetupForIRS1099Err, VendNo, PeriodNo));

        // [WHEN] Validate "IRS 1099 Form Box No." in the vendor ledger entry
        // [THEN] An error is raised because vendor "V" has no 1099 setup for the period
        LibraryERM.FindVendorLedgerEntry(VendorLedgEntry, VendorLedgEntry."Document Type"::Invoice, InvNo);
        VendorLedgEntry."IRS 1099 Reporting Period" := PeriodNo;
        VendorLedgEntry."IRS 1099 Form No." := FormNo;
        asserterror VendorLedgEntry.Validate("IRS 1099 Form Box No.", FormBoxNo);
        Assert.ExpectedError(StrSubstNo(VendorNotSetupForIRS1099Err, VendNo, PeriodNo));
    end;

    [Test]
    procedure ClearIRS1099PeriodOnVendLedgEntryForNon1099Vendor()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorLedgEntry: Record "Vendor Ledger Entry";
        VendNo: Code[20];
        FormNo: Code[20];
        PeriodNo: Code[20];
        InvNo: Code[20];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 620132] Clearing IRS 1099 Reporting Period on a non-1099 vendor ledger entry does not raise an error

        Initialize();
        // [GIVEN] IRS Reporting Period "P" with form "F" and form box "FB"
        PeriodNo := LibraryIRSReportingPeriod.CreateOneDayReportingPeriod(WorkDate());
        FormNo := LibraryIRS1099FormBox.CreateSingleFormInReportingPeriod(WorkDate(), WorkDate());
        LibraryIRS1099FormBox.CreateSingleFormBoxInReportingPeriod(WorkDate(), WorkDate(), FormNo);

        // [GIVEN] Vendor "V" with NO IRS 1099 form box setup
        VendNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Posted purchase invoice for vendor "V", with IRS period set directly (bypassing validation)
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendNo);
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine, PurchaseHeader, LibraryInventory.CreateItemNo(), 1, 100);
        InvNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryERM.FindVendorLedgerEntry(VendorLedgEntry, VendorLedgEntry."Document Type"::Invoice, InvNo);
        VendorLedgEntry."IRS 1099 Reporting Period" := PeriodNo;
        VendorLedgEntry.Modify();

        // [WHEN] Clear "IRS 1099 Reporting Period" by validating with ''
        // [THEN] No error is raised (clearing must always be allowed)
        VendorLedgEntry.Validate("IRS 1099 Reporting Period", '');
        VendorLedgEntry.TestField("IRS 1099 Reporting Period", '');
    end;

    [Test]
    procedure InvoiceLineScheduledForPostingSyncsIRSDataWithoutModifyError()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendNo: Code[20];
        FormNo: Code[20];
        FormBoxNo: Code[20];
        PeriodDate: Date;
    begin
        // [FEATURE] [Recurring Journal] [Background Posting] [AI test 1.0]
        // [SCENARIO 626641] Validating an IRS-relevant field on a Vendor Invoice journal line whose Job Queue Status
        //                   is "Scheduled for Posting" must not fail. Background posting re-validates the Posting Date
        //                   of recurring lines while the status is set; the IRS 1099 sync subscriber derives its fields
        //                   onto the record buffer without re-entering the line's OnModify posting guard, and the
        //                   owning posting engine persists them.
        Initialize();
        // [GIVEN] An IRS Reporting Period and a vendor with a 1099 form box setup in that period
        PeriodDate := WorkDate();
        LibraryIRSReportingPeriod.CreateOneDayReportingPeriod(PeriodDate);
        FormNo := LibraryIRS1099FormBox.CreateSingleFormInReportingPeriod(PeriodDate);
        FormBoxNo := LibraryIRS1099FormBox.CreateSingleFormBoxInReportingPeriod(PeriodDate, FormNo);
        VendNo := LibraryIRS1099FormBox.CreateVendorNoWithFormBox(PeriodDate, FormNo, FormBoxNo);
        // [GIVEN] A Vendor Invoice recurring journal line with Posting Date outside the IRS period, so validation will sync IRS data
        CreateRecurringGenJnlLineForVendor(GenJournalLine, VendNo, GenJournalLine."Document Type"::Invoice, CalcDate('<-1D>', PeriodDate));
        // [GIVEN] The line has been scheduled for background posting (status written without triggers)
        GenJournalLine."Job Queue Status" := GenJournalLine."Job Queue Status"::"Scheduled for Posting";
        GenJournalLine.Modify(false);

        // [WHEN] The posting engine re-validates the Posting Date to a date inside the IRS period
        GenJournalLine.Validate("Posting Date", PeriodDate);
        // [WHEN] The owning posting engine saves the recurring line (Modify without running OnModify)
        GenJournalLine.Modify(false);

        // [THEN] No "scheduled for posting" error is raised and the IRS data is synced and persisted
        Assert.AreEqual(PeriodDate, GenJournalLine."Posting Date", 'Posting Date mismatch');
        VerifyIRS1099DataInGenJnlLine(GenJournalLine, PeriodDate, FormNo, FormBoxNo);
        GenJournalLine.Find();
        VerifyIRS1099DataInGenJnlLine(GenJournalLine, PeriodDate, FormNo, FormBoxNo);
    end;

    [Test]
    procedure BlankDocTypeLineScheduledForPostingIsUnaffected()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendNo: Code[20];
        FormNo: Code[20];
        FormBoxNo: Code[20];
        PeriodDate: Date;
    begin
        // [FEATURE] [Recurring Journal] [Background Posting] [AI test 1.0]
        // [SCENARIO 626641] A journal line with blank Document Type is skipped by the IRS 1099 sync, so validating it
        //                   while scheduled for posting also succeeds.
        Initialize();
        // [GIVEN] An IRS Reporting Period and a vendor with a 1099 form box setup in that period
        PeriodDate := WorkDate();
        LibraryIRSReportingPeriod.CreateOneDayReportingPeriod(PeriodDate);
        FormNo := LibraryIRS1099FormBox.CreateSingleFormInReportingPeriod(PeriodDate);
        FormBoxNo := LibraryIRS1099FormBox.CreateSingleFormBoxInReportingPeriod(PeriodDate, FormNo);
        VendNo := LibraryIRS1099FormBox.CreateVendorNoWithFormBox(PeriodDate, FormNo, FormBoxNo);
        // [GIVEN] A Vendor recurring journal line with blank Document Type scheduled for background posting
        CreateRecurringGenJnlLineForVendor(GenJournalLine, VendNo, GenJournalLine."Document Type"::" ", CalcDate('<-1D>', PeriodDate));
        GenJournalLine."Job Queue Status" := GenJournalLine."Job Queue Status"::"Scheduled for Posting";
        GenJournalLine.Modify(false);

        // [WHEN] The posting engine re-validates the Posting Date
        GenJournalLine.Validate("Posting Date", PeriodDate);

        // [THEN] No error is raised
        Assert.AreEqual(PeriodDate, GenJournalLine."Posting Date", 'Posting Date mismatch');
    end;

    [Test]
    procedure ScheduledLineEditIsNotSilentlyPersistedBySubscriber()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        VendNo: Code[20];
        FormNo: Code[20];
        FormBoxNo: Code[20];
        PeriodDate: Date;
        OriginalPostingDate: Date;
    begin
        // [FEATURE] [Recurring Journal] [Background Posting] [AI test 1.0]
        // [SCENARIO 626641] The IRS 1099 sync subscriber must not save a line that is scheduled for posting.
        //                   Only the process that owns the line may persist it, so the Gen. Journal Line job
        //                   queue guard stays in force and an edit cannot slip past it.
        Initialize();
        // [GIVEN] An IRS Reporting Period and a vendor with a 1099 form box setup in that period
        PeriodDate := WorkDate();
        LibraryIRSReportingPeriod.CreateOneDayReportingPeriod(PeriodDate);
        FormNo := LibraryIRS1099FormBox.CreateSingleFormInReportingPeriod(PeriodDate);
        FormBoxNo := LibraryIRS1099FormBox.CreateSingleFormBoxInReportingPeriod(PeriodDate, FormNo);
        VendNo := LibraryIRS1099FormBox.CreateVendorNoWithFormBox(PeriodDate, FormNo, FormBoxNo);
        OriginalPostingDate := CalcDate('<-1D>', PeriodDate);
        // [GIVEN] A Vendor Invoice recurring journal line scheduled for background posting
        CreateRecurringGenJnlLineForVendor(GenJournalLine, VendNo, GenJournalLine."Document Type"::Invoice, OriginalPostingDate);
        GenJournalLine."Job Queue Status" := GenJournalLine."Job Queue Status"::"Scheduled for Posting";
        GenJournalLine.Modify(false);

        // [WHEN] An IRS-relevant field is validated while the line is scheduled
        GenJournalLine.Validate("Posting Date", PeriodDate);

        // [THEN] The subscriber ran and derived the IRS data onto the record buffer
        Assert.AreEqual(FormBoxNo, GenJournalLine."IRS 1099 Form Box No.", 'Subscriber should derive IRS data onto the record buffer');

        // [THEN] The subscriber leaves the change on the record and does not write the scheduled line to the database
        GenJournalLine2.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");
        Assert.AreEqual(OriginalPostingDate, GenJournalLine2."Posting Date", 'Scheduled line Posting Date must not be persisted by the subscriber');
        Assert.AreEqual('', GenJournalLine2."IRS 1099 Form Box No.", 'Scheduled line IRS data must not be persisted by the subscriber');

        // [WHEN] The scheduled line is modified directly through the table trigger
        asserterror GenJournalLine.Modify(true);

        // [THEN] The job queue guard still blocks the modification
        Assert.ExpectedError('scheduled for posting');
        Assert.ExpectedErrorCode('Dialog');
    end;

    local procedure CreateRecurringGenJnlLineForVendor(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; PostingDate: Date)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Recurring, true);
        GenJournalTemplate.Modify(true);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
            GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, DocumentType,
            GenJournalLine."Account Type"::Vendor, VendorNo,
            GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), -LibraryRandom.RandDec(1000, 2));
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
    end;

    local procedure Initialize()
    var
        IRSReportingPeriod: Record "IRS Reporting Period";
    begin
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        DeleteDocuments();
        IRSReportingPeriod.DeleteAll(true);
        LibraryTestInitialize.OnTestInitialize(Codeunit::"IRS 1099 Document Tests");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"IRS 1099 Document Tests");
        LibrarySetupStorage.SavePurchasesSetup();
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"IRS 1099 Document Tests");
    end;

    local procedure CreateLifecycleThresholdCandidate(var DocHeader: Record "IRS 1099 Form Doc. Header"; var Transmission: Record "Transmission IRIS")
    begin
        CreateSupplementalUpdateDocument(DocHeader, 1500, 100);
        SetFinancialParent(DocHeader.ID, 1500, 600);
        InitializeUpdateTransmission(Transmission, DocHeader);
        DocHeader."IRIS Transmission Document ID" := Transmission."Document ID";
        DocHeader.Modify(true);
    end;

    local procedure CreateLifecycleAttempt(var Attempt: Record "Transmission Log IRIS"; DocHeader: Record "IRS 1099 Form Doc. Header"; TransmissionID: Integer; InsertAttempt: Boolean)
    var
        AttemptLine: Record "Transmission Log Line IRIS";
    begin
        Attempt."Line ID" := LibraryUtility.GetNewRecNo(Attempt, Attempt.FieldNo("Line ID"));
        // Deliberate orphan lines must also reserve their absent parent's ID.
        if AttemptLine.FindLast() then
            if Attempt."Line ID" <= AttemptLine."Transmission Log ID" then
                Attempt."Line ID" := AttemptLine."Transmission Log ID" + 1;
        Attempt."Period No." := CopyStr(DocHeader."Period No.", 1, MaxStrLen(Attempt."Period No."));
        Attempt."Transmission Document ID" := TransmissionID;
        Attempt."Unique Transmission ID" := 'UNRESOLVED-ATTEMPT';
        Attempt."Transmission Date/Time" := CurrentDateTime();
        Attempt."Response Http Status Code" := 500;
        if InsertAttempt then
            Attempt.Insert();
        AttemptLine.Init();
        AttemptLine."Transmission Log ID" := Attempt."Line ID";
        AttemptLine."Line ID" := 1;
        AttemptLine."IRS 1099 Form Document ID" := DocHeader.ID;
        AttemptLine."Vendor No." := DocHeader."Vendor No.";
        AttemptLine."Form No." := DocHeader."Form No.";
        AttemptLine."Submission ID" := 'ATTEMPT-SUBMISSION';
        AttemptLine."Record ID" := 'ATTEMPT-RECORD';
        AttemptLine.Insert();
    end;

    local procedure VerifyRejectedLifecycleUpdate(OriginalDocHeader: Record "IRS 1099 Form Doc. Header")
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        ParentDocLine: Record "IRS 1099 Form Doc. Line";
        CodesSupplLine: Record "IRS 1099 Doc. Suppl. Line";
    begin
        Assert.ExpectedError(StrSubstNo(DocumentContextTxt, OriginalDocHeader.ID));
        Assert.ExpectedError('has submission history, correction details, or a recorded send attempt');
        Assert.ExpectedErrorCode('Dialog');
        DocHeader.Get(OriginalDocHeader.ID);
        Assert.AreEqual(OriginalDocHeader.Status, DocHeader.Status, 'Document status must survive.');
        Assert.AreEqual(OriginalDocHeader."IRIS Transmission Document ID", DocHeader."IRIS Transmission Document ID", 'The link must survive.');
        Assert.AreEqual(OriginalDocHeader."IRIS Submission Status", DocHeader."IRIS Submission Status", 'Submission status must survive.');
        Assert.AreEqual(OriginalDocHeader."IRIS Submission ID", DocHeader."IRIS Submission ID", 'Submission ID must survive.');
        Assert.AreEqual(OriginalDocHeader."IRIS Record ID", DocHeader."IRIS Record ID", 'Record ID must survive.');
        Assert.AreEqual(OriginalDocHeader."IRIS Last Receipt ID", DocHeader."IRIS Last Receipt ID", 'Last receipt must survive.');
        Assert.AreEqual(OriginalDocHeader."IRIS Last Accepted Receipt ID", DocHeader."IRIS Last Accepted Receipt ID", 'Accepted receipt must survive.');
        Assert.AreEqual(OriginalDocHeader."Allow Correction", DocHeader."Allow Correction", 'Correction permission must survive.');
        Assert.AreEqual(OriginalDocHeader."IRIS Needs Correction", DocHeader."IRIS Needs Correction", 'Correction selection must survive.');
        Assert.AreEqual(OriginalDocHeader."IRIS Updated Not Sent", DocHeader."IRIS Updated Not Sent", 'Pending update state must survive.');
        Assert.AreEqual(OriginalDocHeader."IRIS Corrected", DocHeader."IRIS Corrected", 'Correction history must survive.');
        Assert.AreEqual(OriginalDocHeader."IRIS Corrected to Zeros", DocHeader."IRIS Corrected to Zeros", 'Zero-correction state must survive.');
        VerifyFinancialState(DocHeader.ID, 1500, true);
        FindFinancialParent(DocHeader.ID, ParentDocLine);
        Assert.AreEqual(600, ParentDocLine."Minimum Reportable Amount", 'The stored minimum must not change.');
        Assert.AreEqual(1500, ParentDocLine."Calculated Amount", 'The calculated amount must not change.');
        VerifySavedTips(DocHeader.ID, 100);
        CodesSupplLine.Get(DocHeader.ID, 'NEC-01C');
        VerifySupplementalCodes(CodesSupplLine);
    end;

    local procedure VerifyLifecycleAttempt(OriginalAttempt: Record "Transmission Log IRIS"; DocumentID: Integer)
    var
        Attempt: Record "Transmission Log IRIS";
    begin
        Attempt.Get(OriginalAttempt."Line ID");
        Assert.AreEqual(OriginalAttempt."Transmission Document ID", Attempt."Transmission Document ID", 'Attempt transmission must survive.');
        Assert.AreEqual(OriginalAttempt."Unique Transmission ID", Attempt."Unique Transmission ID", 'Pending attempt ID must survive.');
        Assert.AreEqual(OriginalAttempt."Transmission Date/Time", Attempt."Transmission Date/Time", 'Attempt time must survive.');
        Assert.AreEqual(OriginalAttempt."Response Http Status Code", Attempt."Response Http Status Code", 'Attempt response must survive.');
        Assert.AreEqual(OriginalAttempt."Receipt ID", Attempt."Receipt ID", 'No receipt may be invented.');
        VerifyLifecycleAttemptLine(Attempt."Line ID", DocumentID);
    end;

    local procedure VerifyLifecycleAttemptLine(AttemptID: Integer; DocumentID: Integer)
    var
        AttemptLine: Record "Transmission Log Line IRIS";
    begin
        AttemptLine.Get(AttemptID, 1);
        Assert.AreEqual(DocumentID, AttemptLine."IRS 1099 Form Document ID", 'Exact document history must survive.');
        Assert.AreEqual('ATTEMPT-SUBMISSION', AttemptLine."Submission ID", 'Attempt submission ID must survive.');
        Assert.AreEqual('ATTEMPT-RECORD', AttemptLine."Record ID", 'Attempt record ID must survive.');
    end;

    procedure DeleteDocuments()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
    begin
        IRS1099FormDocHeader.ModifyAll(Status, Enum::"IRS 1099 Form Doc. Status"::Open, false);
        IRS1099FormDocHeader.ModifyAll("IRIS Transmission Document ID", 0, false);
        IRS1099FormDocHeader.DeleteAll(true);
    end;

    local procedure CreateSupplementalUpdateDocument(var DocHeader: Record "IRS 1099 Form Doc. Header"; ParentAmount: Decimal; TipsAmount: Decimal)
    var
        IRSFormsSetup: Record "IRS Forms Setup";
    begin
        IRSFormsSetup.InitSetup();
        LibraryIRS1099Document.CreateSupplementalDocument(DocHeader, 'NEC');
        InitializeSupplementalUpdateDocument(DocHeader, ParentAmount, TipsAmount);
    end;

    local procedure PostSupplementalFixturePayment(var PostedPayment: Record "Vendor Ledger Entry"; VendorNo: Code[20])
    var
        JournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(JournalLine, JournalLine."Document Type"::Payment,
            JournalLine."Account Type"::Vendor, VendorNo, 5000);
        LibraryERM.PostGeneralJnlLine(JournalLine);
        PostedPayment.SetRange("Vendor No.", VendorNo);
        PostedPayment.SetRange("Document Type", PostedPayment."Document Type"::Payment);
        PostedPayment.FindLast();
        PostedPayment.CalcFields(Amount, "Remaining Amount");
    end;

    local procedure CreateSameVendorSupplementalDocument(var DocHeader: Record "IRS 1099 Form Doc. Header"; SourceDocHeader: Record "IRS 1099 Form Doc. Header"; ParentAmount: Decimal; TipsAmount: Decimal)
    begin
        DocHeader."Period No." := SourceDocHeader."Period No.";
        DocHeader."Vendor No." := SourceDocHeader."Vendor No.";
        DocHeader."Form No." := SourceDocHeader."Form No.";
        DocHeader.Insert(true);
        LibraryIRS1099Document.MockFormDocumentLineForVendor(DocHeader.ID, DocHeader."Period No.", DocHeader."Vendor No.", DocHeader."Form No.", 'NEC-01');
        InitializeSupplementalUpdateDocument(DocHeader, ParentAmount, TipsAmount);
    end;

    local procedure AddCreateCandidate(var TempDocLine: Record "IRS 1099 Form Doc. Line" temporary; DocHeader: Record "IRS 1099 Form Doc. Header"; SourceDocumentID: Integer; LineNo: Integer; Amount: Decimal)
    begin
        TempDocLine.Init();
        TempDocLine."Document ID" := SourceDocumentID;
        TempDocLine."Period No." := DocHeader."Period No.";
        TempDocLine."Vendor No." := DocHeader."Vendor No.";
        TempDocLine."Form No." := DocHeader."Form No.";
        TempDocLine."Line No." := LineNo;
        TempDocLine."Form Box No." := 'NEC-03';
        TempDocLine.Amount := Amount;
        TempDocLine."Calculated Amount" := Amount;
        TempDocLine."Include In 1099" := true;
        TempDocLine."Line Action" := TempDocLine."Line Action"::Create;
        TempDocLine.Insert(true);
    end;

    local procedure CreateRoutingDetail(var Details: Record "IRS 1099 Form Doc. Line Detail"; DocLine: Record "IRS 1099 Form Doc. Line"; Amount: Decimal): Integer
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        IRSFormsSetup: Record "IRS Forms Setup";
    begin
        IRSFormsSetup.Get();
        IRSFormsSetup."Collect Details For Line" := true;
        IRSFormsSetup.Modify(true);
        LibraryIRS1099Document.MockVendLedgEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment,
            DMY2Date(1, 1, 2026), DMY2Date(31, 12, 2026), DocLine."Vendor No.", DocLine."Form No.", DocLine."Form Box No.");
        Details.Init();
        Details."Document ID" := DocLine."Document ID";
        Details."Line No." := DocLine."Line No.";
        Details."Vendor Ledger Entry No." := VendorLedgerEntry."Entry No.";
        Details."Calculated Amount" := Amount;
        Details.Insert(true);
        exit(VendorLedgerEntry."Entry No.");
    end;

    local procedure VerifyReplacementRouting(DocumentID: Integer; TipsAmount: Decimal; ParentEntryNo: Integer; ParentAmount: Decimal; NewEntryNo: Integer; NewAmount: Decimal)
    var
        Details: Record "IRS 1099 Form Doc. Line Detail";
    begin
        VerifySavedTips(DocumentID, TipsAmount);
        VerifyRoutedDetail(DocumentID, 'NEC-01', ParentEntryNo, ParentAmount);
        VerifyRoutedDetail(DocumentID, 'NEC-03', NewEntryNo, NewAmount);
        Details.SetRange("Document ID", DocumentID);
        Assert.RecordCount(Details, 2);
    end;

    local procedure VerifyRoutedDetail(DocumentID: Integer; BoxNo: Code[20]; EntryNo: Integer; Amount: Decimal)
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        DocLine: Record "IRS 1099 Form Doc. Line";
        Details: Record "IRS 1099 Form Doc. Line Detail";
    begin
        DocHeader.Get(DocumentID);
        Details.SetRange("Document ID", DocumentID);
        Details.SetRange("Vendor Ledger Entry No.", EntryNo);
        Details.FindFirst();
        DocLine.Get(DocHeader."Period No.", DocHeader."Vendor No.", DocHeader."Form No.", DocumentID, Details."Line No.");
        Assert.AreEqual(BoxNo, DocLine."Form Box No.", 'The ledger detail was assigned to a different form box.');
        Assert.AreEqual(Amount, Details."Calculated Amount", 'The financial detail must follow its exact line.');
    end;

    local procedure VerifyAbandonedSource(DocumentID: Integer; TipsAmount: Decimal)
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
    begin
        DocHeader.Get(DocumentID);
        Assert.AreEqual(DocHeader.Status::Abandoned, DocHeader.Status, 'The source must remain in history.');
        VerifySavedTips(DocumentID, TipsAmount);
    end;

    local procedure VerifyOpenRoutingSource(DocumentID: Integer; TipsAmount: Decimal)
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
    begin
        DocHeader.Get(DocumentID);
        Assert.AreEqual(DocHeader.Status::Open, DocHeader.Status, 'The source status must be unchanged.');
        VerifySavedTips(DocumentID, TipsAmount);
    end;

    local procedure VerifyPostedPaymentUnchanged(Snapshot: Record "Vendor Ledger Entry"; ExpectedDetailCount: Integer)
    var
        Payment: Record "Vendor Ledger Entry";
        DetailedEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        Payment.Get(Snapshot."Entry No.");
        Payment.CalcFields(Amount, "Remaining Amount");
        Assert.AreEqual(Snapshot.SystemId, Payment.SystemId, 'The posted payment identity changed.');
        Assert.AreEqual(Snapshot.SystemModifiedAt, Payment.SystemModifiedAt, 'Recalculation modified a posted payment.');
        Assert.AreEqual(Snapshot.Amount, Payment.Amount, 'Recalculation changed the posted payment amount.');
        Assert.AreEqual(Snapshot."Remaining Amount", Payment."Remaining Amount", 'Recalculation changed payment application.');
        Assert.AreEqual(Snapshot.Open, Payment.Open, 'Recalculation changed payment status.');
        Assert.AreEqual(Snapshot."IRS 1099 Reporting Amount", Payment."IRS 1099 Reporting Amount", 'Recalculation changed posted reporting data.');
        DetailedEntry.SetRange("Vendor Ledger Entry No.", Payment."Entry No.");
        Assert.RecordCount(DetailedEntry, ExpectedDetailCount);
    end;

    local procedure SetManualFinancialParent(DocumentID: Integer; Amount: Decimal; MinimumAmount: Decimal)
    var
        ParentDocLine: Record "IRS 1099 Form Doc. Line";
    begin
        SetFinancialParent(DocumentID, Amount, MinimumAmount);
        FindFinancialParent(DocumentID, ParentDocLine);
        ParentDocLine."Manually Changed" := true;
        ParentDocLine.Modify(true);
    end;

    local procedure CreateAdditionalSupplementalDocument(var DocHeader: Record "IRS 1099 Form Doc. Header"; ExistingDocHeader: Record "IRS 1099 Form Doc. Header"; ParentAmount: Decimal; TipsAmount: Decimal)
    begin
        DocHeader.Init();
        DocHeader."Period No." := ExistingDocHeader."Period No.";
        DocHeader."Vendor No." := LibraryPurchase.CreateVendorNo();
        DocHeader."Form No." := ExistingDocHeader."Form No.";
        DocHeader.Insert(true);
        LibraryIRS1099Document.MockFormDocumentLineForVendor(DocHeader.ID, DocHeader."Period No.", DocHeader."Vendor No.", DocHeader."Form No.", 'NEC-01');
        InitializeSupplementalUpdateDocument(DocHeader, ParentAmount, TipsAmount);
    end;

    local procedure InitializeSupplementalUpdateDocument(DocHeader: Record "IRS 1099 Form Doc. Header"; ParentAmount: Decimal; TipsAmount: Decimal)
    var
        SupplLine: Record "IRS 1099 Doc. Suppl. Line";
        FormBox: Record "IRS 1099 Form Box";
    begin
        FormBox.Get(DocHeader."Period No.", 'NEC', 'NEC-01');
        FormBox."Minimum Reportable Amount" := 2000;
        FormBox.Modify(true);
        SetFinancialParent(DocHeader.ID, ParentAmount, 2000);
        SetDocumentAdjustment(DocHeader, 'NEC-01', ParentAmount);
        CreateSupplementalLine(SupplLine, DocHeader.ID, 'NEC-01B');
        SupplLine.Validate(Amount, TipsAmount);
        SupplLine.Modify(true);
        CreateSupplementalLine(SupplLine, DocHeader.ID, 'NEC-01C');
        SupplLine.Validate("Occupation Code 1", '101');
        SupplLine.Validate("Occupation Code 2", '000');
        SupplLine.Modify(true);
    end;

    local procedure SetFinancialParent(DocumentID: Integer; ParentAmount: Decimal; MinimumAmount: Decimal)
    var
        ParentDocLine: Record "IRS 1099 Form Doc. Line";
    begin
        FindFinancialParent(DocumentID, ParentDocLine);
        ParentDocLine."Minimum Reportable Amount" := MinimumAmount;
        ParentDocLine.Validate(Amount, ParentAmount);
        ParentDocLine."Calculated Amount" := ParentAmount;
        ParentDocLine.Modify(true);
    end;

    local procedure FindFinancialParent(DocumentID: Integer; var ParentDocLine: Record "IRS 1099 Form Doc. Line")
    begin
        ParentDocLine.Reset();
        ParentDocLine.SetRange("Document ID", DocumentID);
        ParentDocLine.SetFilter("Form Box No.", '%1|%2', 'NEC-01', 'MISC-03');
        ParentDocLine.FindFirst();
    end;

    local procedure AddFinancialDefinition(DocHeader: Record "IRS 1099 Form Doc. Header"; BoxNo: Code[20]; MinimumAmount: Decimal)
    var
        FormBox: Record "IRS 1099 Form Box";
    begin
        FormBox."Period No." := DocHeader."Period No.";
        FormBox."Form No." := DocHeader."Form No.";
        FormBox."No." := BoxNo;
        FormBox."Minimum Reportable Amount" := MinimumAmount;
        FormBox.Insert(true);
    end;

    local procedure AddFinancialBox(DocHeader: Record "IRS 1099 Form Doc. Header"; BoxNo: Code[20]; Amount: Decimal; MinimumAmount: Decimal)
    var
        DocLine: Record "IRS 1099 Form Doc. Line";
    begin
        AddFinancialDefinition(DocHeader, BoxNo, MinimumAmount);
        DocLine."Document ID" := DocHeader.ID;
        DocLine."Period No." := DocHeader."Period No.";
        DocLine."Vendor No." := DocHeader."Vendor No.";
        DocLine."Form No." := DocHeader."Form No.";
        DocLine."Line No." := 9000;
        DocLine.Validate("Form Box No.", BoxNo);
        DocLine."Minimum Reportable Amount" := MinimumAmount;
        DocLine.Validate(Amount, Amount);
        DocLine.Insert(true);
    end;

    local procedure SetDocumentAdjustment(DocHeader: Record "IRS 1099 Form Doc. Header"; BoxNo: Code[20]; Amount: Decimal)
    var
        Adjustment: Record "IRS 1099 Vendor Form Box Adj.";
    begin
        if not Adjustment.Get(DocHeader."Period No.", DocHeader."Vendor No.", DocHeader."Form No.", BoxNo) then begin
            Adjustment.Validate("Period No.", DocHeader."Period No.");
            Adjustment.Validate("Vendor No.", DocHeader."Vendor No.");
            Adjustment.Validate("Form No.", DocHeader."Form No.");
            Adjustment.Validate("Form Box No.", BoxNo);
            Adjustment.Insert(true);
        end;
        Adjustment.Amount := Amount;
        Adjustment.Modify(true);
    end;

    local procedure InitializeUpdateTransmission(var Transmission: Record "Transmission IRIS"; DocHeader: Record "IRS 1099 Form Doc. Header")
    begin
        Transmission."Document ID" := LibraryUtility.GetNewRecNo(Transmission, Transmission.FieldNo("Document ID"));
        Transmission."Period No." := CopyStr(DocHeader."Period No.", 1, MaxStrLen(Transmission."Period No."));
        Transmission.Insert(true);
    end;

    local procedure FindReplacementDocument(var DocHeader: Record "IRS 1099 Form Doc. Header")
    begin
        DocHeader.SetRange("Period No.", DocHeader."Period No.");
        DocHeader.SetRange("Vendor No.", DocHeader."Vendor No.");
        DocHeader.SetRange("Form No.", DocHeader."Form No.");
        DocHeader.SetFilter(Status, '<>%1', DocHeader.Status::Abandoned);
        DocHeader.FindFirst();
        DocHeader.Reset();
    end;

    local procedure VerifyRetainedExcludedCodes(CodesSupplLine: Record "IRS 1099 Doc. Suppl. Line")
    begin
        CodesSupplLine.Get(CodesSupplLine."Document ID", CodesSupplLine."Supplemental Box No.");
        VerifySupplementalCodes(CodesSupplLine);
        Assert.IsFalse(LibraryIRS1099Document.IsSupplementalReportable(CodesSupplLine), 'Zero tips must suppress codes.');
        Assert.IsTrue(LibraryIRS1099Document.GetSupplementalExplanation(CodesSupplLine) <> '', 'Retained codes need an exclusion explanation.');
    end;

    local procedure VerifyFinancialState(DocumentID: Integer; ExpectedAmount: Decimal; ExpectedIncluded: Boolean)
    var
        ParentDocLine: Record "IRS 1099 Form Doc. Line";
    begin
        FindFinancialParent(DocumentID, ParentDocLine);
        Assert.AreEqual(ExpectedAmount, ParentDocLine.Amount, 'The financial amount changed unexpectedly.');
        Assert.AreEqual(ExpectedIncluded, ParentDocLine."Include In 1099", 'The financial inclusion changed unexpectedly.');
    end;

    local procedure VerifyDocumentLink(DocumentID: Integer; ExpectedTransmissionID: Integer)
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
    begin
        DocHeader.Get(DocumentID);
        Assert.AreEqual(ExpectedTransmissionID, DocHeader."IRIS Transmission Document ID", 'The transmission association changed unexpectedly.');
    end;

    local procedure VerifySavedTips(DocumentID: Integer; ExpectedAmount: Decimal)
    var
        TipsSupplLine: Record "IRS 1099 Doc. Suppl. Line";
    begin
        TipsSupplLine.Get(DocumentID, 'NEC-01B');
        Assert.AreEqual(ExpectedAmount, TipsSupplLine.Amount, 'The saved breakdown changed unexpectedly.');
        Assert.AreEqual('NEC-01', TipsSupplLine."Parent Form Box No.", 'The stored parent must survive lifecycle changes.');
    end;

    local procedure CreateSupplementalLine(var SupplLine: Record "IRS 1099 Doc. Suppl. Line"; DocumentID: Integer; BoxNo: Code[20])
    begin
        SupplLine.Init();
        SupplLine."Document ID" := DocumentID;
        SupplLine.Validate("Supplemental Box No.", BoxNo);
        SupplLine.Insert(true);
    end;

    local procedure VerifySupplementalLinesVisibility(IRS1099FormDocument: TestPage "IRS 1099 Form Document"; ExpectedVisible: Boolean)
    begin
        Assert.AreEqual(ExpectedVisible, IRS1099FormDocument.SupplementalLines.Visible(), 'The supplemental part has unexpected visibility.');
        Assert.AreEqual(not ExpectedVisible, IRS1099FormDocument.ShowSupplementalLines.Visible(), 'The reveal action must be shown only when the part is hidden.');
    end;

    local procedure VerifySupplementalCodes(SupplLine: Record "IRS 1099 Doc. Suppl. Line")
    begin
        Assert.AreEqual('101', SupplLine."Occupation Code 1", 'The first code must remain text.');
        Assert.AreEqual('000', SupplLine."Occupation Code 2", 'Leading zeros must not be lost.');
        Assert.AreEqual(0, SupplLine.Amount, 'A code row cannot hold money.');
        Assert.AreEqual('NEC-01', SupplLine."Parent Form Box No.", 'The definition must assign the parent snapshot.');
    end;

    local procedure MockFormDocumentForVendorWithFixedDocID(DocID: Integer; PeriodNo: Code[20]; VendNo: Code[20]; FormNo: Code[20]; Status: Enum "IRS 1099 Form Doc. Status")
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
    begin
        ClearExistingIRSFormDoc(DocID);
        IRS1099FormDocHeader.ID := DocID;
        IRS1099FormDocHeader."Period No." := PeriodNo;
        IRS1099FormDocHeader."Vendor No." := VendNo;
        IRS1099FormDocHeader."Form No." := FormNo;
        IRS1099FormDocHeader.Status := Status;
        IRS1099FormDocHeader.Insert();
    end;

    local procedure ClearExistingIRSFormDoc(DocID: Integer)
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
        IRS1099FormDocLineDetail: Record "IRS 1099 Form Doc. Line Detail";
    begin
        IRS1099FormDocHeader.SetRange(ID, DocID);
        IRS1099FormDocHeader.DeleteAll();
        IRS1099FormDocLine.SetRange("Document ID", DocID);
        IRS1099FormDocLine.DeleteAll();
        IRS1099FormDocLineDetail.SetRange("Document ID", DocID);
        IRS1099FormDocLineDetail.DeleteAll();
    end;

    local procedure MockFormDocument(var IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; Status: Enum "IRS 1099 Form Doc. Status")
    var
        PeriodNo, FormNo, VendorNo, FormBoxNo : Code[20];
        DocID: Integer;
    begin
        PeriodNo := LibraryIRSReportingPeriod.CreateOneDayReportingPeriod(WorkDate());
        FormNo := LibraryIRS1099FormBox.CreateSingleFormInReportingPeriod(WorkDate());
        FormBoxNo := LibraryIRS1099FormBox.CreateSingleFormBoxInReportingPeriod(WorkDate(), FormNo);
        VendorNo := LibraryIRS1099FormBox.CreateVendorNoWithFormBox(WorkDate(), FormNo, FormBoxNo);
        LibraryIRS1099FormBox.CreateSingleFormStatementLine(WorkDate(), FormNo, FormBoxNo);
        DocID := LibraryIRS1099Document.MockFormDocumentForVendor(PeriodNo, VendorNo, FormNo, Status);
        LibraryIRS1099Document.MockFormDocumentLineForVendor(DocID, PeriodNo, VendorNo, FormNo, FormBoxNo);
        IRS1099FormDocHeader.Get(DocID);
    end;

    local procedure VerifyIRS1099DataInGenJnlLine(GenJournalLine: Record "Gen. Journal Line"; ReportingDate: Date; FormNo: Code[20]; FormBoxNo: Code[20])
    begin
        Assert.AreEqual(LibraryIRSReportingPeriod.GetReportingPeriod(ReportingDate), GenJournalLine."IRS 1099 Reporting Period", 'IRS 1099 Reporting Period mismatch');
        Assert.AreEqual(FormNo, GenJournalLine."IRS 1099 Form No.", 'IRS 1099 Form No. mismatch');
        Assert.AreEqual(FormBoxNo, GenJournalLine."IRS 1099 Form Box No.", 'IRS 1099 Form Box No. mismatch');
    end;

    local procedure VerifyStoredMinimum(DocumentID: Integer; ExpectedMinimum: Decimal)
    var
        ParentDocLine: Record "IRS 1099 Form Doc. Line";
    begin
        FindFinancialParent(DocumentID, ParentDocLine);
        Assert.AreEqual(ExpectedMinimum, ParentDocLine."Minimum Reportable Amount", 'Unselected minimum must remain stored.');
    end;

    local procedure VerifyEligibilityPageRow(CurrentExists: Boolean; CurrentAmount: Decimal; CurrentMinimum: Decimal; CurrentIncluded: Boolean; ProposedAmount: Decimal; ProposedMinimum: Decimal; ProposedIncluded: Boolean; ExpectedSelected: Boolean)
    var
        CapturedRow: JsonObject;
    begin
        CapturedRow.ReadFrom(LibraryVariableStorage.DequeueText());
        Assert.AreEqual(CurrentExists, GetEligibilityBoolean(CapturedRow, 'currentExists'), 'The current predecessor marker is incorrect.');
        Assert.AreEqual(CurrentAmount, GetEligibilityDecimal(CapturedRow, 'currentAmount'), 'The displayed current amount is incorrect.');
        Assert.AreEqual(CurrentMinimum, GetEligibilityDecimal(CapturedRow, 'currentMinimum'), 'The displayed current minimum is incorrect.');
        Assert.AreEqual(CurrentIncluded, GetEligibilityBoolean(CapturedRow, 'currentIncluded'), 'The displayed current inclusion is incorrect.');
        Assert.AreEqual(ProposedAmount, GetEligibilityDecimal(CapturedRow, 'proposedAmount'), 'The displayed proposed amount is incorrect.');
        Assert.AreEqual(ProposedMinimum, GetEligibilityDecimal(CapturedRow, 'proposedMinimum'), 'The displayed proposed minimum is incorrect.');
        Assert.AreEqual(ProposedIncluded, GetEligibilityBoolean(CapturedRow, 'proposedIncluded'), 'The displayed proposed inclusion is incorrect.');
        Assert.AreEqual(ExpectedSelected, GetEligibilityBoolean(CapturedRow, 'selected'), 'The candidate selection is incorrect.');
        Assert.IsTrue(GetEligibilityBoolean(CapturedRow, 'comparisonReadOnly'), 'All comparison-only controls must be read-only.');
        Assert.IsTrue(GetEligibilityBoolean(CapturedRow, 'amountEditable'), 'Proposed amounts must remain editable.');
        Assert.IsTrue(GetEligibilityBoolean(CapturedRow, 'selectionEditable'), 'Per-line selection must remain editable.');
    end;

    local procedure GetEligibilityBoolean(CapturedRow: JsonObject; PropertyName: Text): Boolean
    var
        CapturedValue: JsonToken;
    begin
        CapturedRow.Get(PropertyName, CapturedValue);
        exit(CapturedValue.AsValue().AsBoolean());
    end;

    local procedure GetEligibilityDecimal(CapturedRow: JsonObject; PropertyName: Text): Decimal
    var
        CapturedValue: JsonToken;
    begin
        CapturedRow.Get(PropertyName, CapturedValue);
        exit(CapturedValue.AsValue().AsDecimal());
    end;

    local procedure CaptureEligibilityPageRow(var UpdatePage: TestPage "IRS 1099 Form Doc. Update")
    var
        CapturedRow: JsonObject;
        CapturedRowText: Text;
    begin
        // One queue entry per row keeps multirow inspection within the shared library's capacity.
        CapturedRow.Add('currentExists', UpdatePage.CurrentLineExists.AsBoolean());
        CapturedRow.Add('currentAmount', UpdatePage.CurrentAmount.AsDecimal());
        CapturedRow.Add('currentMinimum', UpdatePage.CurrentMinimumReportableAmount.AsDecimal());
        CapturedRow.Add('currentIncluded', UpdatePage.CurrentIncludeIn1099.AsBoolean());
        CapturedRow.Add('proposedAmount', UpdatePage.NewAmount.AsDecimal());
        CapturedRow.Add('proposedMinimum', UpdatePage.NewMinimumReportableAmount.AsDecimal());
        CapturedRow.Add('proposedIncluded', UpdatePage.NewIncludeIn1099.AsBoolean());
        CapturedRow.Add('selected', UpdatePage."Process Line".AsBoolean());
        CapturedRow.Add('comparisonReadOnly',
            not UpdatePage.CurrentLineExists.Editable() and not UpdatePage.CurrentAmount.Editable() and
            not UpdatePage.CurrentMinimumReportableAmount.Editable() and not UpdatePage.CurrentIncludeIn1099.Editable() and
            not UpdatePage.NewMinimumReportableAmount.Editable() and not UpdatePage.NewIncludeIn1099.Editable());
        CapturedRow.Add('amountEditable', UpdatePage.NewAmount.Editable());
        CapturedRow.Add('selectionEditable', UpdatePage."Process Line".Editable());
        CapturedRow.WriteTo(CapturedRowText);
        LibraryVariableStorage.Enqueue(CapturedRowText);
    end;

    [ModalPageHandler]
    procedure InspectEligibilityDeclineUpdateHandler(var UpdatePage: TestPage "IRS 1099 Form Doc. Update")
    begin
        UpdatePage.First();
        UpdatePage."Process Line".SetValue(false);
        CaptureEligibilityPageRow(UpdatePage);
        UpdatePage.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure InspectEligibilityTransitionCancelHandler(var UpdatePage: TestPage "IRS 1099 Form Doc. Update")
    begin
        UpdatePage.Filter.SetFilter("Form Box No.", 'NEC-01');
        UpdatePage.First();
        CaptureEligibilityPageRow(UpdatePage);
        UpdatePage.Filter.SetFilter("Form Box No.", 'NEC-03');
        UpdatePage.First();
        CaptureEligibilityPageRow(UpdatePage);
        UpdatePage.Filter.SetFilter("Form Box No.", 'NEC-01');
        UpdatePage.First();
        CaptureEligibilityPageRow(UpdatePage);
        UpdatePage.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure InspectWithholdingUpdateHandler(var UpdatePage: TestPage "IRS 1099 Form Doc. Update")
    begin
        UpdatePage.Filter.SetFilter("Form Box No.", 'NEC-01');
        UpdatePage.First();
        CaptureEligibilityPageRow(UpdatePage);
        UpdatePage.Filter.SetFilter("Form Box No.", '');
        UpdatePage.First();
        repeat
            UpdatePage."Process Line".SetValue(true);
        until not UpdatePage.Next();
        UpdatePage.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure CancelDocumentUpdateHandler(var UpdatePage: TestPage "IRS 1099 Form Doc. Update")
    begin
        UpdatePage.Cancel().Invoke();
    end;

    [EventSubscriber(ObjectType::Table, Database::"IRS 1099 Form Doc. Header", 'OnAddPeriodFormVendUniquenessFilters', '', false, false)]
    local procedure AllowMultipleRoutingDocuments(var IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header")
    begin
        IRS1099FormDocHeader.SetRange(ID, 0);
    end;

    [ModalPageHandler]
    procedure AcceptDocumentUpdateHandler(var UpdatePage: TestPage "IRS 1099 Form Doc. Update")
    begin
        UpdatePage.First();
        repeat
            UpdatePage."Process Line".SetValue(true);
        until not UpdatePage.Next();
        UpdatePage.OK().Invoke();
    end;

    [MessageHandler]
    procedure IgnoreLifecycleMessageHandler(MessageText: Text[1024])
    begin
    end;

    [ModalPageHandler]
    procedure SelectVendorDocumentUpdateHandler(var UpdatePage: TestPage "IRS 1099 Form Doc. Update")
    var
        VendorNo: Text;
    begin
        VendorNo := LibraryVariableStorage.DequeueText();
        UpdatePage.First();
        repeat
            UpdatePage."Process Line".SetValue(UpdatePage."Vendor No.".Value = VendorNo);
        until not UpdatePage.Next();
        UpdatePage.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure DeclineSupplementalCascadeHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ConfirmHandler]
    procedure AcceptSupplementalCascadeHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    procedure SupplementalBoxLookupHandler(var IRS1099SupplBoxes: TestPage "IRS 1099 Suppl. Boxes")
    begin
        IRS1099SupplBoxes.First();
        IRS1099SupplBoxes.OK().Invoke();
    end;

    [MessageHandler]
    procedure MessageHandler(Text: Text)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Text);
    end;
}