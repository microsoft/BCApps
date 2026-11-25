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
        ParentAmountRangeErr: Label 'between zero and the amount %1 on the parent document line', Locked = true;
        CopySourceDocIDVisibleErr: Label 'Document IDs must be visible when selecting a source for copying supplemental lines.';

    trigger OnRun()
    begin
        // [FEATURE] [1099]
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

    [Test]
    procedure SupplementalReleaseRequiresCodesForPositiveTips()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        SupplementalLine: Record "IRS 1099 Doc. Suppl. Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Positive cash tips cannot be released without occupation codes.
        Initialize();

        // [GIVEN] Form Document with positive tips and no codes.
        LibraryIRS1099Document.CreateSupplementalDocument(IRS1099FormDocHeader, 'NEC');
        CreateSupplementalLine(SupplementalLine, IRS1099FormDocHeader.ID, 'NEC-01B');
        SupplementalLine.Validate(Amount, 100);
        SupplementalLine.Modify(true);
        Commit();

        // [WHEN] Release is attempted.
        asserterror LibraryIRS1099Document.ReleaseDocument(IRS1099FormDocHeader);

        // [THEN] Actionable error leaves Form Document Open.
        Assert.ExpectedError('positive cash tips require one or two valid Treasury tipped occupation codes');
        Assert.ExpectedErrorCode('Dialog');
        IRS1099FormDocHeader.Get(IRS1099FormDocHeader.ID);
        Assert.AreEqual(IRS1099FormDocHeader.Status::Open, IRS1099FormDocHeader.Status, 'Disclosures that fail validation must not be released.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalCodesAreRetainedSuppressedAndRestored()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        TipsSupplementalLine: Record "IRS 1099 Doc. Suppl. Line";
        CodesSupplementalLine: Record "IRS 1099 Doc. Suppl. Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Clearing and restoring tips suppresses and restores saved codes without re-entry.
        Initialize();

        // [GIVEN] Form Document with tips and valid codes.
        CreateSupplementalUpdateDocument(IRS1099FormDocHeader, 5000, 100);
        CodesSupplementalLine.Get(IRS1099FormDocHeader.ID, 'NEC-01C');
        Assert.IsTrue(LibraryIRS1099Document.IsSupplementalReportable(CodesSupplementalLine), 'Positive tips should report codes.');
        TipsSupplementalLine.Get(IRS1099FormDocHeader.ID, 'NEC-01B');

        // [WHEN] Tips are cleared.
        TipsSupplementalLine.Validate(Amount, 0);
        TipsSupplementalLine.Modify(true);

        // [THEN] Codes remain stored but are excluded with explanation.
        VerifyRetainedExcludedCodes(CodesSupplementalLine);

        // [WHEN] Positive tips are restored.
        TipsSupplementalLine.Validate(Amount, 100);
        TipsSupplementalLine.Modify(true);

        // [THEN] Same codes become reportable without re-entry.
        Assert.IsTrue(LibraryIRS1099Document.IsSupplementalReportable(CodesSupplementalLine), 'Restoring tips must restore code eligibility.');
        Assert.AreEqual('', LibraryIRS1099Document.GetSupplementalExplanation(CodesSupplementalLine), 'Restored codes should not show a zero-tip explanation.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalMISCUsesSpecificParentNotEligibleRent()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        ParentIRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
        TipsSupplementalLine: Record "IRS 1099 Doc. Suppl. Line";
        CodesSupplementalLine: Record "IRS 1099 Doc. Suppl. Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Eligible rent does not qualify excluded other-income disclosures.
        Initialize();

        // [GIVEN] Form Document has rent 2500, other income 500 and tips 100 with valid codes.
        LibraryIRS1099Document.CreateSupplementalDocument(IRS1099FormDocHeader, 'MISC');
        SetParentDocLineAmount(IRS1099FormDocHeader.ID, 500, 2000);
        CreateFormBoxAndDocLine(IRS1099FormDocHeader, 'MISC-01', 2500, 2000);
        CreateSupplementalLine(TipsSupplementalLine, IRS1099FormDocHeader.ID, 'MISC-13A');
        TipsSupplementalLine.Validate(Amount, 100);
        TipsSupplementalLine.Modify(true);
        CreateSupplementalLine(CodesSupplementalLine, IRS1099FormDocHeader.ID, 'MISC-13B');
        CodesSupplementalLine.Validate("Occupation Code 1", '000');
        CodesSupplementalLine.Modify(true);

        // [WHEN] Form Document is released.
        LibraryIRS1099Document.ReleaseDocument(IRS1099FormDocHeader);

        // [THEN] Tips are validated against 500 and excluded, rather than qualified by rent.
        FindParentDocLine(IRS1099FormDocHeader.ID, ParentIRS1099FormDocLine);
        Assert.AreEqual(500, ParentIRS1099FormDocLine.Amount, 'Excluded income is not a zero validation ceiling.');
        Assert.IsFalse(LibraryIRS1099Document.IsSupplementalReportable(TipsSupplementalLine), 'Rent must not qualify another parent.');
        Assert.IsFalse(LibraryIRS1099Document.IsSupplementalReportable(CodesSupplementalLine), 'Codes follow their specific parent.');
        Assert.IsTrue(LibraryIRS1099Document.GetSupplementalExplanation(TipsSupplementalLine) <> '', 'Excluded income needs an explanation.');
        Assert.AreEqual(100, TipsSupplementalLine.Amount, 'Excluded tips must remain stored.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalWithholdingQualifiesBelowThresholdParent()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        ParentIRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
        TipsSupplementalLine: Record "IRS 1099 Doc. Suppl. Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Positive backup withholding preserves income and its disclosures below the threshold.
        Initialize();

        // [GIVEN] Form Document has compensation 500, tips 100, 2000 threshold and withholding 50.
        CreateSupplementalUpdateDocument(IRS1099FormDocHeader, 500, 100);
        CreateFormBoxAndDocLine(IRS1099FormDocHeader, 'NEC-04', 50, 0);

        // [WHEN] Form Document is released.
        LibraryIRS1099Document.ReleaseDocument(IRS1099FormDocHeader);

        // [THEN] Both income and its tips are reportable.
        FindParentDocLine(IRS1099FormDocHeader.ID, ParentIRS1099FormDocLine);
        TipsSupplementalLine.Get(IRS1099FormDocHeader.ID, 'NEC-01B');
        Assert.IsTrue(ParentIRS1099FormDocLine."Include In 1099", 'Withholding must preserve the nonzero payment.');
        Assert.IsTrue(LibraryIRS1099Document.IsSupplementalReportable(TipsSupplementalLine), 'Tips follow the withholding-qualified parent.');
        Assert.AreEqual(500, ParentIRS1099FormDocLine.Amount, 'Tips cannot increase income.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure WithholdingDoesNotQualifyNegativeNecIncome()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Withholding Does Not Qualify Negative Nec Income.
        Initialize();

        // [GIVEN] Form Document has negative NEC income and positive backup withholding.

        // [WHEN] Requested operation is executed through its existing entry point.
        VerifyNegativeIncomeWithWithholding('NEC', 'NEC-04');

        // [THEN] Expected result and preserved data are verified.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure WithholdingDoesNotQualifyNegativeMiscIncome()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Withholding Does Not Qualify Negative Misc Income.
        Initialize();

        // [GIVEN] Form Document has negative MISC income and positive backup withholding.

        // [WHEN] Requested operation is executed through its existing entry point.
        VerifyNegativeIncomeWithWithholding('MISC', 'MISC-04');

        // [THEN] Expected result and preserved data are verified.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalReleaseRejectsPopulatedUnknownMapping()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        SupplementalBox: Record "IRS 1099 Suppl. Box";
        SupplementalLine: Record "IRS 1099 Doc. Suppl. Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A custom stored disclosure is not silently omitted at release.
        Initialize();

        // [GIVEN] Form Document contains populated unmapped custom supplemental box.
        LibraryIRS1099Document.CreateSupplementalDocument(IRS1099FormDocHeader, 'NEC');
        SupplementalBox.Get(IRS1099FormDocHeader."Period No.", 'NEC', 'NEC-01D');
        SupplementalBox."No." := 'CUSTOM';
        SupplementalBox."XML Element Name" := '';
        SupplementalBox.Insert(true);
        CreateSupplementalLine(SupplementalLine, IRS1099FormDocHeader.ID, 'CUSTOM');
        SupplementalLine.Validate(Amount, 50);
        SupplementalLine.Modify(true);

        // [WHEN] Release is attempted.
        asserterror LibraryIRS1099Document.ReleaseDocument(IRS1099FormDocHeader);

        // [THEN] Unsupported populated mappings fail explicitly.
        Assert.ExpectedError('contains values that cannot be reported in IRIS XML');
        Assert.ExpectedErrorCode('Dialog');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('AcceptDocumentUpdateHandler')]
    procedure LifecycleAcceptedThresholdUpdateIsRejected()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        Transmission: Record "Transmission IRIS";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] An accepted 1500 return cannot be detached by changing only its minimum from 600 to 2000.
        Initialize();

        // [GIVEN] Form Document is accepted and linked, with its original receipt and correction state.
        CreateLifecycleThresholdCandidate(IRS1099FormDocHeader, Transmission);
        IRS1099FormDocHeader.Status := IRS1099FormDocHeader.Status::Submitted;
        IRS1099FormDocHeader."IRIS Submission Status" := IRS1099FormDocHeader."IRIS Submission Status"::Accepted;
        IRS1099FormDocHeader."IRIS Submission ID" := 'SAVED-SUBMISSION';
        IRS1099FormDocHeader."IRIS Record ID" := 'SAVED-RECORD';
        IRS1099FormDocHeader."IRIS Last Receipt ID" := 'SAVED-RECEIPT';
        IRS1099FormDocHeader."IRIS Last Accepted Receipt ID" := 'ACCEPTED-RECEIPT';
        IRS1099FormDocHeader."IRIS Needs Correction" := true;
        IRS1099FormDocHeader.Modify(true);
        Commit();

        // [WHEN] Eligibility-only update is selected.
        asserterror LibraryIRS1099Document.UpdateTransmission(Transmission);

        // [THEN] Correction route is explicit and every stored filing value survives.
        VerifyRejectedLifecycleUpdate(IRS1099FormDocHeader);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('AcceptDocumentUpdateHandler')]
    procedure LifecycleInProgressWithoutReceiptIsRejected()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        Transmission: Record "Transmission IRIS";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] In Progress is unsafe even before any receipt or submission identifiers arrive.
        Initialize();

        // [GIVEN] Form Document is processing with no receipt.
        CreateLifecycleThresholdCandidate(IRS1099FormDocHeader, Transmission);
        IRS1099FormDocHeader.Status := IRS1099FormDocHeader.Status::"In Progress";
        IRS1099FormDocHeader.Modify(true);
        Commit();

        // [WHEN] Nonfiling update is selected.
        asserterror LibraryIRS1099Document.UpdateTransmission(Transmission);

        // [THEN] Pending state and association are not cleared.
        VerifyRejectedLifecycleUpdate(IRS1099FormDocHeader);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('AcceptDocumentUpdateHandler')]
    procedure LifecycleReopenedReceiptUpdateIsRejected()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        Transmission: Record "Transmission IRIS";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Reopening does not make an old receipt safe to detach.
        Initialize();

        // [GIVEN] Open Form Document retains previous accepted receipt.
        CreateLifecycleThresholdCandidate(IRS1099FormDocHeader, Transmission);
        IRS1099FormDocHeader."IRIS Last Accepted Receipt ID" := 'OLD-ACCEPTED-RECEIPT';
        IRS1099FormDocHeader.Modify(true);
        Commit();

        // [WHEN] Nonfiling update is selected.
        asserterror LibraryIRS1099Document.UpdateTransmission(Transmission);

        // [THEN] Editable status does not authorize unlinking.
        VerifyRejectedLifecycleUpdate(IRS1099FormDocHeader);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('AcceptDocumentUpdateHandler')]
    procedure LifecycleReopenedCorrectionStateIsRejected()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        Transmission: Record "Transmission IRIS";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A reopened correction cannot be treated as unsent when receipts are absent.
        Initialize();

        // [GIVEN] Open Form Document retains correction state but no receipts.
        CreateLifecycleThresholdCandidate(IRS1099FormDocHeader, Transmission);
        IRS1099FormDocHeader."Allow Correction" := true;
        IRS1099FormDocHeader."IRIS Needs Correction" := true;
        IRS1099FormDocHeader."IRIS Updated Not Sent" := true;
        IRS1099FormDocHeader."IRIS Corrected" := true;
        IRS1099FormDocHeader."IRIS Corrected to Zeros" := true;
        IRS1099FormDocHeader.Modify(true);
        Commit();

        // [WHEN] Nonfiling update is selected.
        asserterror LibraryIRS1099Document.UpdateTransmission(Transmission);

        // [THEN] All correction flags remain available to existing correction workflow.
        VerifyRejectedLifecycleUpdate(IRS1099FormDocHeader);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('AcceptDocumentUpdateHandler')]
    procedure LifecycleExactAttemptUpdateIsRejected()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        Transmission: Record "Transmission IRIS";
        Attempt: Record "Transmission Log IRIS";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] An exact document's failed send attempt in an older transmission remains unsafe without a receipt.
        Initialize();

        // [GIVEN] Released Form Document has no header filing markers but is linked to earlier send attempt.
        CreateLifecycleThresholdCandidate(IRS1099FormDocHeader, Transmission);
        IRS1099FormDocHeader.Status := IRS1099FormDocHeader.Status::Released;
        IRS1099FormDocHeader.Modify(true);
        CreateLifecycleAttempt(Attempt, IRS1099FormDocHeader, Transmission."Document ID" + 1, true);
        Commit();

        // [WHEN] Nonfiling update is selected.
        asserterror LibraryIRS1099Document.UpdateTransmission(Transmission);

        // [THEN] Exact attempt metadata, link and saved disclosures survive.
        VerifyRejectedLifecycleUpdate(IRS1099FormDocHeader);
        VerifyLifecycleAttempt(Attempt, IRS1099FormDocHeader.ID);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('AcceptDocumentUpdateHandler')]
    procedure LifecycleOrphanAttemptUpdateIsRejected()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        Transmission: Record "Transmission IRIS";
        Attempt: Record "Transmission Log IRIS";
        StoredAttempt: Record "Transmission Log IRIS";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Missing attempt-header metadata cannot turn an exact document association into proof of no send.
        Initialize();

        // [GIVEN] Form Document has orphaned log line and no header filing markers.
        CreateLifecycleThresholdCandidate(IRS1099FormDocHeader, Transmission);
        CreateLifecycleAttempt(Attempt, IRS1099FormDocHeader, Transmission."Document ID", false);
        Commit();

        // [WHEN] Nonfiling update is selected.
        asserterror LibraryIRS1099Document.UpdateTransmission(Transmission);

        // [THEN] Ambiguous history is retained and requires existing attempt resolution.
        VerifyRejectedLifecycleUpdate(IRS1099FormDocHeader);
        Assert.IsFalse(StoredAttempt.Get(Attempt."Line ID"), 'No attempt header may be invented.');
        VerifyLifecycleAttemptLine(Attempt."Line ID", IRS1099FormDocHeader.ID);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('AcceptDocumentUpdateHandler')]
    procedure LifecycleMixedUnsafeSelectionRollsBack()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        UnsafeIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        UnlinkedIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        Transmission: Record "Transmission IRIS";
        ParentIRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
        Details: Record "IRS 1099 Form Doc. Line Detail";
        DetailEntryNo: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] An unsafe threshold update rolls back valid line changes, details and proposed attachments together.
        Initialize();

        // [GIVEN] First Form Document has valid amount update, second has been filed, and unlinked document is staged for attachment.
        CreateSupplementalUpdateDocument(IRS1099FormDocHeader, 5000, 100);
        CreateAdditionalSupplementalDocument(UnsafeIRS1099FormDocHeader, IRS1099FormDocHeader, 1500, 100);
        SetParentDocLineAmount(UnsafeIRS1099FormDocHeader.ID, 1500, 600);
        CreateAdditionalSupplementalDocument(UnlinkedIRS1099FormDocHeader, IRS1099FormDocHeader, 5000, 100);
        LibraryIRS1099Document.ReleaseDocument(UnlinkedIRS1099FormDocHeader);
        SetDocumentAdjustment(IRS1099FormDocHeader, 'NEC-01', 4000);
        FindParentDocLine(IRS1099FormDocHeader.ID, ParentIRS1099FormDocLine);
        DetailEntryNo := CreateRoutingDetail(Details, ParentIRS1099FormDocLine, 5000);
        InitializeUpdateTransmission(Transmission, IRS1099FormDocHeader);
        UnsafeIRS1099FormDocHeader.Status := UnsafeIRS1099FormDocHeader.Status::Submitted;
        UnsafeIRS1099FormDocHeader."IRIS Submission Status" := UnsafeIRS1099FormDocHeader."IRIS Submission Status"::Accepted;
        UnsafeIRS1099FormDocHeader."IRIS Transmission Document ID" := Transmission."Document ID";
        UnsafeIRS1099FormDocHeader.Modify(true);
        Commit();

        // [WHEN] All candidates are selected.
        asserterror LibraryIRS1099Document.UpdateTransmission(Transmission);

        // [THEN] No selected financial change, detail deletion or staged attachment survives.
        VerifyRejectedLifecycleUpdate(UnsafeIRS1099FormDocHeader);
        VerifyParentDocLineState(IRS1099FormDocHeader.ID, 5000, true);
        VerifySavedTips(IRS1099FormDocHeader.ID, 100);
        VerifyRoutedDetail(IRS1099FormDocHeader.ID, 'NEC-01', DetailEntryNo, 5000);
        VerifyDocumentLink(UnlinkedIRS1099FormDocHeader.ID, 0);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('AcceptDocumentUpdateHandler,IgnoreLifecycleMessageHandler')]
    procedure LifecycleOtherDocumentHistoryAllowsUnsentUpdate()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        OtherIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        Transmission: Record "Transmission IRIS";
        Attempt: Record "Transmission Log IRIS";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Another document's history in the same transmission does not make a new released return sent.
        Initialize();

        // [GIVEN] Released Form Document is unsent, while another document has history in same Transmission.
        CreateLifecycleThresholdCandidate(IRS1099FormDocHeader, Transmission);
        IRS1099FormDocHeader.Status := IRS1099FormDocHeader.Status::Released;
        IRS1099FormDocHeader.Modify(true);
        CreateAdditionalSupplementalDocument(OtherIRS1099FormDocHeader, IRS1099FormDocHeader, 5000, 100);
        CreateLifecycleAttempt(Attempt, OtherIRS1099FormDocHeader, Transmission."Document ID", true);
        Commit();

        // [WHEN] Unsent Form Document's eligibility-only update is selected.
        LibraryIRS1099Document.UpdateTransmission(Transmission);

        // [THEN] Unsent Form Document becomes Open and unlinked with saved values; other document's history is unchanged.
        IRS1099FormDocHeader.Get(IRS1099FormDocHeader.ID);
        Assert.AreEqual(IRS1099FormDocHeader.Status::Open, IRS1099FormDocHeader.Status, 'A demonstrably unsent nonfiling document stays editable.');
        VerifyDocumentLink(IRS1099FormDocHeader.ID, 0);
        VerifyParentDocLineState(IRS1099FormDocHeader.ID, 1500, false);
        VerifySavedTips(IRS1099FormDocHeader.ID, 100);
        VerifyLifecycleAttempt(Attempt, OtherIRS1099FormDocHeader.ID);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('InspectEligibilityDeclineUpdateHandler,IgnoreLifecycleMessageHandler')]
    procedure SupplementalThresholdOnlyChangeIsOffered()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        TempIRS1099FormDocLine: Record "IRS 1099 Form Doc. Line" temporary;
        TempIRS1099FormDocLineDetail: Record "IRS 1099 Form Doc. Line Detail" temporary;
        FormBox: Record "IRS 1099 Form Box";
        Transmission: Record "Transmission IRIS";
        Details: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] An unchanged 1500 payment is offered after its threshold changes from 600 to 2000.
        Initialize();

        // [GIVEN] Form Document stores included 1500 payment under threshold 600.
        CreateSupplementalUpdateDocument(IRS1099FormDocHeader, 1500, 100);
        SetParentDocLineAmount(IRS1099FormDocHeader.ID, 1500, 600);
        FormBox.Get(IRS1099FormDocHeader."Period No.", 'NEC', 'NEC-01');
        FormBox."Minimum Reportable Amount" := 600;
        FormBox.Modify(true);

        // [WHEN] Annual setup identifies Form Document and recalculation candidates are explicitly staged.
        Details := LibraryIRSReportingPeriod.UpdateAnnualSetup(IRS1099FormDocHeader."Period No.", CompanyName());
        LibraryIRS1099Document.GetDocumentUpdateCandidates(TempIRS1099FormDocLine, TempIRS1099FormDocLineDetail, IRS1099FormDocHeader."Period No.");

        // [THEN] Unchanged amount has explicit threshold/inclusion update.
        Assert.IsTrue(Details.Contains('needs recalculation'), 'Annual setup must identify stale Open documents.');
        Assert.RecordCount(TempIRS1099FormDocLine, 1);
        TempIRS1099FormDocLine.FindFirst();
        Assert.AreEqual(1500, TempIRS1099FormDocLine.Amount, 'The amount has not changed.');
        Assert.AreEqual(2000, TempIRS1099FormDocLine."Minimum Reportable Amount", 'The proposed threshold must be refreshed.');
        Assert.IsFalse(TempIRS1099FormDocLine."Include In 1099", 'The proposed parent is below threshold.');
        VerifyParentDocLineState(IRS1099FormDocHeader.ID, 1500, true);

        // [WHEN] Operator reviews eligibility comparison and explicitly deselects Form Document.
        InitializeUpdateTransmission(Transmission, IRS1099FormDocHeader);
        Commit();
        LibraryIRS1099Document.UpdateTransmission(Transmission);

        // [THEN] Equal amounts still display minimum/inclusion change without applying it.
        VerifyEligibilityPageRow(true, 1500, 600, true, 1500, 2000, false, false);
        VerifyParentDocLineState(IRS1099FormDocHeader.ID, 1500, true);
        VerifyStoredMinimum(IRS1099FormDocHeader.ID, 600);
        VerifyDocumentLink(IRS1099FormDocHeader.ID, 0);
        VerifySavedTips(IRS1099FormDocHeader.ID, 100);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('InspectEligibilityTransitionCancelHandler,IgnoreLifecycleMessageHandler')]
    procedure EligibilityComparisonCreateTransitionCancellation()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        Transmission: Record "Transmission IRIS";
        IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Moving existing -> Create -> existing clears missing current values and cancellation persists nothing.
        Initialize();

        // [GIVEN] Form Document has threshold-only update and proposed new Form Box.
        CreateLifecycleThresholdCandidate(IRS1099FormDocHeader, Transmission);
        CreateFormBox(IRS1099FormDocHeader, 'NEC-03', 0);
        SetDocumentAdjustment(IRS1099FormDocHeader, 'NEC-03', 200);
        Commit();

        // [WHEN] Operator inspects both rows and cancels.
        LibraryIRS1099Document.UpdateTransmission(Transmission);

        // [THEN] Create has no predecessor, returning restores Form Document's current values, and nothing is applied.
        VerifyEligibilityPageRow(true, 1500, 600, true, 1500, 2000, false, true);
        VerifyEligibilityPageRow(false, 0, 0, false, 200, 0, true, true);
        VerifyEligibilityPageRow(true, 1500, 600, true, 1500, 2000, false, true);
        VerifyParentDocLineState(IRS1099FormDocHeader.ID, 1500, true);
        VerifyStoredMinimum(IRS1099FormDocHeader.ID, 600);
        VerifyDocumentLink(IRS1099FormDocHeader.ID, Transmission."Document ID");
        VerifySavedTips(IRS1099FormDocHeader.ID, 100);
        IRS1099FormDocLine.SetRange("Document ID", IRS1099FormDocHeader.ID);
        Assert.RecordCount(IRS1099FormDocLine, 1);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CancelDocumentUpdateHandler,IgnoreLifecycleMessageHandler')]
    procedure SupplementalUpdateCancellationDoesNotAttachDocuments()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        UnlinkedIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        Transmission: Record "Transmission IRIS";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Cancelling selection does not attach an otherwise eligible unlinked document.
        Initialize();

        // [GIVEN] One Form Document needs recalculation and another is unlinked Released document.
        CreateSupplementalUpdateDocument(IRS1099FormDocHeader, 5000, 100);
        CreateAdditionalSupplementalDocument(UnlinkedIRS1099FormDocHeader, IRS1099FormDocHeader, 5000, 100);
        LibraryIRS1099Document.ReleaseDocument(UnlinkedIRS1099FormDocHeader);
        SetDocumentAdjustment(IRS1099FormDocHeader, 'NEC-01', 4000);
        InitializeUpdateTransmission(Transmission, IRS1099FormDocHeader);
        Commit();

        // [WHEN] Selection is cancelled.
        LibraryIRS1099Document.UpdateTransmission(Transmission);

        // [THEN] Documents, links and disclosures are unchanged.
        VerifyParentDocLineState(IRS1099FormDocHeader.ID, 5000, true);
        VerifyDocumentLink(UnlinkedIRS1099FormDocHeader.ID, 0);
        VerifySavedTips(IRS1099FormDocHeader.ID, 100);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('AcceptDocumentUpdateHandler')]
    procedure SupplementalRejectedUpdateRollsBackAllDocumentsAndLinks()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        SecondIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        UnlinkedIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        Transmission: Record "Transmission IRIS";
        PostedPayment: Record "Vendor Ledger Entry";
        DetailedEntry: Record "Detailed Vendor Ledg. Entry";
        DetailedEntryCount: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A retained breakdown exceeding its parent amount rolls back every selected document and proposed attachment.
        Initialize();

        // [GIVEN] Two Form Documents need updates and unlinked document is proposed for attachment.
        CreateSupplementalUpdateDocument(IRS1099FormDocHeader, 5000, 100);
        CreateAdditionalSupplementalDocument(SecondIRS1099FormDocHeader, IRS1099FormDocHeader, 5000, 100);
        CreateAdditionalSupplementalDocument(UnlinkedIRS1099FormDocHeader, IRS1099FormDocHeader, 5000, 100);
        PostSupplementalFixturePayment(PostedPayment, IRS1099FormDocHeader."Vendor No.");
        DetailedEntry.SetRange("Vendor Ledger Entry No.", PostedPayment."Entry No.");
        DetailedEntryCount := DetailedEntry.Count();
        LibraryIRS1099Document.ReleaseDocument(UnlinkedIRS1099FormDocHeader);
        SetDocumentAdjustment(IRS1099FormDocHeader, 'NEC-01', 4000);
        SetDocumentAdjustment(SecondIRS1099FormDocHeader, 'NEC-01', 50);
        InitializeUpdateTransmission(Transmission, IRS1099FormDocHeader);
        Commit();

        // [WHEN] All candidates are accepted, including second Form Document's parent amount of 50, below its saved tips.
        asserterror LibraryIRS1099Document.UpdateTransmission(Transmission);

        // [THEN] No selected financial change or association survives.
        VerifyParentAmountError(50);
        VerifyParentDocLineState(IRS1099FormDocHeader.ID, 5000, true);
        VerifyParentDocLineState(SecondIRS1099FormDocHeader.ID, 5000, true);
        VerifyDocumentLink(UnlinkedIRS1099FormDocHeader.ID, 0);
        VerifySavedTips(SecondIRS1099FormDocHeader.ID, 100);
        VerifyPostedPaymentUnchanged(PostedPayment, DetailedEntryCount);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalAmountsHaveNoCombinedCeiling()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        OvertimeSupplementalLine: Record "IRS 1099 Doc. Suppl. Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Individually valid tips and overtime are not subject to an invented combined ceiling.
        Initialize();

        // [GIVEN] Each breakdown is 4000 against compensation 5000.
        CreateSupplementalUpdateDocument(IRS1099FormDocHeader, 5000, 4000);
        CreateSupplementalLine(OvertimeSupplementalLine, IRS1099FormDocHeader.ID, 'NEC-01D');
        OvertimeSupplementalLine.Validate(Amount, 4000);
        OvertimeSupplementalLine.Modify(true);

        // [WHEN] Form Document is released.
        LibraryIRS1099Document.ReleaseDocument(IRS1099FormDocHeader);

        // [THEN] Both breakdowns survive and income is unchanged.
        VerifyParentDocLineState(IRS1099FormDocHeader.ID, 5000, true);
        VerifySavedTips(IRS1099FormDocHeader.ID, 4000);
        Assert.AreEqual(4000, OvertimeSupplementalLine.Amount, 'No combined ceiling may truncate overtime.');
        Assert.IsTrue(LibraryIRS1099Document.IsSupplementalReportable(OvertimeSupplementalLine), 'Overtime must follow compensation eligibility.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('AcceptDocumentUpdateHandler')]
    procedure SupplementalMissingParentUpdateRollsBack()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        Adjustment: Record "IRS 1099 Vendor Form Box Adj.";
        Transmission: Record "Transmission IRIS";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Recalculation is not consent to delete a populated supplemental parent.
        Initialize();

        // [GIVEN] Form Document's only calculation source is removed, but saved tips remain.
        CreateSupplementalUpdateDocument(IRS1099FormDocHeader, 5000, 100);
        Adjustment.Get(IRS1099FormDocHeader."Period No.", IRS1099FormDocHeader."Vendor No.", IRS1099FormDocHeader."Form No.", 'NEC-01');
        Adjustment.Delete(true);
        CreateFormBox(IRS1099FormDocHeader, 'NEC-03', 0);
        SetDocumentAdjustment(IRS1099FormDocHeader, 'NEC-03', 200);
        InitializeUpdateTransmission(Transmission, IRS1099FormDocHeader);
        Commit();

        // [WHEN] Removal of missing financial parent is accepted.
        asserterror LibraryIRS1099Document.UpdateTransmission(Transmission);

        // [THEN] Form Document and its saved disclosures survive unchanged.
        Assert.ExpectedError('Recalculation would remove the document line for that form box');
        Assert.ExpectedErrorCode('Dialog');
        VerifyParentDocLineState(IRS1099FormDocHeader.ID, 5000, true);
        VerifySavedTips(IRS1099FormDocHeader.ID, 100);
        IRS1099FormDocHeader.Get(IRS1099FormDocHeader.ID);
        Assert.AreEqual(IRS1099FormDocHeader.Status::Open, IRS1099FormDocHeader.Status, 'Failure must preserve the original document.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalNonfilingRecreationRetainsStoredDisclosures()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        OldDocumentID: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Same-identity recreation retains valid disclosures even with no filing eligibility.
        Initialize();

        // [GIVEN] Form Document will recalculate from 5000 to excluded compensation 500.
        CreateSupplementalUpdateDocument(IRS1099FormDocHeader, 5000, 100);
        OldDocumentID := IRS1099FormDocHeader.ID;
        SetDocumentAdjustment(IRS1099FormDocHeader, 'NEC-01', 500);

        // [WHEN] Document is recreated.
        LibraryIRS1099Document.CreateFormDocuments(DMY2Date(1, 1, 2026), DMY2Date(31, 12, 2026),
            IRS1099FormDocHeader."Vendor No.", IRS1099FormDocHeader."Form No.", true);

        // [THEN] New identity remains Open and unlinked with its valid stored values.
        FindReplacementDocument(IRS1099FormDocHeader);
        Assert.AreNotEqual(OldDocumentID, IRS1099FormDocHeader.ID, 'Recreation must allocate a new identity.');
        Assert.AreEqual(IRS1099FormDocHeader.Status::Open, IRS1099FormDocHeader.Status, 'Nonfiling disclosures must remain editable.');
        VerifyParentDocLineState(IRS1099FormDocHeader.ID, 500, false);
        VerifyDocumentLink(IRS1099FormDocHeader.ID, 0);
        VerifySavedTips(IRS1099FormDocHeader.ID, 100);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalParentReassignmentIsRejected()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        ParentIRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A linked parent cannot be reassigned to another form box.
        Initialize();

        // [GIVEN] Form Document has financial parent referenced by saved tips.
        CreateSupplementalUpdateDocument(IRS1099FormDocHeader, 5000, 100);
        CreateFormBox(IRS1099FormDocHeader, 'NEC-03', 0);
        FindParentDocLine(IRS1099FormDocHeader.ID, ParentIRS1099FormDocLine);
        Commit();

        // [WHEN] Parent box is changed without correcting disclosures.
        asserterror ParentIRS1099FormDocLine.Validate("Form Box No.", 'NEC-03');

        // [THEN] Actionable error preserves original parent relationship.
        Assert.ExpectedError('Remove those lines in Supplemental Lines before changing the form box');
        Assert.ExpectedErrorCode('Dialog');
        VerifyParentDocLineState(IRS1099FormDocHeader.ID, 5000, true);
        VerifySavedTips(IRS1099FormDocHeader.ID, 100);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalAttachOnlyFailureRollsBackEarlierAttachment()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        ExcessTipsIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        TipsSupplementalLine: Record "IRS 1099 Doc. Suppl. Line";
        Transmission: Record "Transmission IRIS";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Stored tips exceeding parent income on a proposed attachment roll back the attach-only operation.
        Initialize();

        // [GIVEN] Two Form Documents have no calculation changes, but second contains imported tips exceeding parent income.
        CreateSupplementalUpdateDocument(IRS1099FormDocHeader, 5000, 100);
        CreateAdditionalSupplementalDocument(ExcessTipsIRS1099FormDocHeader, IRS1099FormDocHeader, 5000, 100);
        LibraryIRS1099Document.ReleaseDocument(IRS1099FormDocHeader);
        LibraryIRS1099Document.ReleaseDocument(ExcessTipsIRS1099FormDocHeader);
        TipsSupplementalLine.Get(ExcessTipsIRS1099FormDocHeader.ID, 'NEC-01B');
        TipsSupplementalLine.Amount := 6000;
        TipsSupplementalLine.Modify(false);
        InitializeUpdateTransmission(Transmission, IRS1099FormDocHeader);
        Commit();

        // [WHEN] Both proposed attachments are applied without selection page.
        asserterror LibraryIRS1099Document.UpdateTransmission(Transmission);

        // [THEN] Neither association survives validation failure.
        Assert.ExpectedError('supplemental box NEC-01B');
        Assert.ExpectedError('must be between zero and the amount');
        Assert.ExpectedErrorCode('Dialog');
        VerifyDocumentLink(IRS1099FormDocHeader.ID, 0);
        VerifyDocumentLink(ExcessTipsIRS1099FormDocHeader.ID, 0);
        VerifySavedTips(ExcessTipsIRS1099FormDocHeader.ID, 6000);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('InspectWithholdingUpdateHandler,AcceptDependentEligibilityHandler,IgnoreLifecycleMessageHandler')]
    procedure SupplementalWithholdingRemovalRefreshesEligibility()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        Transmission: Record "Transmission IRIS";
        TipsSupplementalLine: Record "IRS 1099 Doc. Suppl. Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Removing backup withholding requires confirmation of the unselected income eligibility change.
        Initialize();

        // [GIVEN] Released Form Document has compensation 500 qualified by withholding 50.
        CreateWithholdingRemovalCandidate(IRS1099FormDocHeader, Transmission);
        Commit();

        // [WHEN] Explicitly selected recalculation removes withholding.
        LibraryIRS1099Document.UpdateTransmission(Transmission);

        // [THEN] Income remains 500, but its saved tips no longer qualify for filing.
        VerifyDependentEligibilityConfirmation(IRS1099FormDocHeader.ID);
        VerifyParentDocLineState(IRS1099FormDocHeader.ID, 500, false);
        VerifySavedTips(IRS1099FormDocHeader.ID, 100);
        TipsSupplementalLine.Get(IRS1099FormDocHeader.ID, 'NEC-01B');
        Assert.IsFalse(LibraryIRS1099Document.IsSupplementalReportable(TipsSupplementalLine), 'Removed withholding cannot continue qualifying tips.');
        VerifyDocumentLink(IRS1099FormDocHeader.ID, 0);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalSetupThresholdChangePreservesSubmittedDocument()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        FormBox: Record "IRS 1099 Form Box";
        ParentIRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A setup threshold edit does not rewrite a submitted document or its saved eligibility.
        Initialize();

        // [GIVEN] Submitted Form Document stores income 1500 under threshold 600 and saved disclosures.
        CreateSupplementalUpdateDocument(IRS1099FormDocHeader, 1500, 100);
        SetParentDocLineAmount(IRS1099FormDocHeader.ID, 1500, 600);
        IRS1099FormDocHeader.Status := IRS1099FormDocHeader.Status::Submitted;
        IRS1099FormDocHeader."IRIS Last Receipt ID" := 'SAVED-RECEIPT';
        IRS1099FormDocHeader.Modify(true);
        FormBox.Get(IRS1099FormDocHeader."Period No.", 'NEC', 'NEC-01');

        FormBox."Minimum Reportable Amount" := 600;
        FormBox.Modify(true);

        // [WHEN] Annual reconciliation changes setup to threshold 2000.
        LibraryIRSReportingPeriod.UpdateAnnualSetup(IRS1099FormDocHeader."Period No.", CompanyName());

        // [THEN] Submitted data retains its stored amount, threshold, inclusion, disclosures and receipt.
        IRS1099FormDocHeader.Get(IRS1099FormDocHeader.ID);
        Assert.AreEqual(IRS1099FormDocHeader.Status::Submitted, IRS1099FormDocHeader.Status, 'Setup must not rewrite submitted status.');
        Assert.AreEqual('SAVED-RECEIPT', IRS1099FormDocHeader."IRIS Last Receipt ID", 'Setup must preserve submitted identity.');
        VerifyParentDocLineState(IRS1099FormDocHeader.ID, 1500, true);
        FindParentDocLine(IRS1099FormDocHeader.ID, ParentIRS1099FormDocLine);
        Assert.AreEqual(600, ParentIRS1099FormDocLine."Minimum Reportable Amount", 'Submitted thresholds are stored snapshots.');
        VerifySavedTips(IRS1099FormDocHeader.ID, 100);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SelectVendorDocumentUpdateHandler,IgnoreLifecycleMessageHandler')]
    procedure SupplementalSelectedUpdatePreservesUnselectedManualAmount()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        OtherIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        ParentIRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
        Transmission: Record "Transmission IRIS";
        FormBox: Record "IRS 1099 Form Box";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Only the selected manual amount and threshold are replaced by explicit recalculation.
        Initialize();

        // [GIVEN] Two documents store manual income 1750 under threshold 600; current calculation is 1500/2000.
        CreateSupplementalUpdateDocument(IRS1099FormDocHeader, 1500, 100);
        CreateAdditionalSupplementalDocument(OtherIRS1099FormDocHeader, IRS1099FormDocHeader, 1500, 100);
        SetManualParentDocLineAmount(IRS1099FormDocHeader.ID, 1750, 600);
        SetManualParentDocLineAmount(OtherIRS1099FormDocHeader.ID, 1750, 600);
        FormBox.Get(IRS1099FormDocHeader."Period No.", 'NEC', 'NEC-01');
        FormBox."Minimum Reportable Amount" := 600;
        FormBox.Modify(true);
        LibraryIRSReportingPeriod.UpdateAnnualSetup(IRS1099FormDocHeader."Period No.", CompanyName());
        InitializeUpdateTransmission(Transmission, IRS1099FormDocHeader);
        LibraryVariableStorage.Enqueue(IRS1099FormDocHeader."Vendor No.");
        Commit();

        // [WHEN] Only first Form Document is selected.
        LibraryIRS1099Document.UpdateTransmission(Transmission);

        // [THEN] First Form Document recalculates explicitly; second document's manual amount and stored threshold remain unchanged.
        VerifyParentDocLineState(IRS1099FormDocHeader.ID, 1500, false);
        VerifyParentDocLineState(OtherIRS1099FormDocHeader.ID, 1750, true);
        FindParentDocLine(OtherIRS1099FormDocHeader.ID, ParentIRS1099FormDocLine);
        Assert.AreEqual(600, ParentIRS1099FormDocLine."Minimum Reportable Amount", 'Unselected thresholds must remain stored snapshots.');
        Assert.IsTrue(ParentIRS1099FormDocLine."Manually Changed", 'Unselected manual values must remain manual.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('IgnoreLifecycleMessageHandler')]
    procedure SupplementalAttachOnlyUpdateIsPreserved()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        Transmission: Record "Transmission IRIS";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] An up-to-date released document can still be attached without a selection page.
        Initialize();

        // [GIVEN] Form Document has valid disclosures and no financial changes.
        CreateSupplementalUpdateDocument(IRS1099FormDocHeader, 5000, 100);
        LibraryIRS1099Document.ReleaseDocument(IRS1099FormDocHeader);
        InitializeUpdateTransmission(Transmission, IRS1099FormDocHeader);
        Commit();

        // [WHEN] Transmission is updated.
        LibraryIRS1099Document.UpdateTransmission(Transmission);

        // [THEN] Form Document is attached with its original financial and supplemental amounts.
        VerifyDocumentLink(IRS1099FormDocHeader.ID, Transmission."Document ID");
        VerifyParentDocLineState(IRS1099FormDocHeader.ID, 5000, true);
        VerifySavedTips(IRS1099FormDocHeader.ID, 100);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('AcceptDocumentUpdateHandler,IgnoreLifecycleMessageHandler')]
    procedure SupplementalNonfilingUpdateRetainsOpenDocument()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        Transmission: Record "Transmission IRIS";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Valid disclosures survive an update that excludes every financial line.
        Initialize();

        // [GIVEN] Released Form Document has 5000 income and valid tips, and will recalculate to 500.
        CreateSupplementalUpdateDocument(IRS1099FormDocHeader, 5000, 100);
        LibraryIRS1099Document.ReleaseDocument(IRS1099FormDocHeader);
        SetDocumentAdjustment(IRS1099FormDocHeader, 'NEC-01', 500);
        InitializeUpdateTransmission(Transmission, IRS1099FormDocHeader);
        Commit();

        // [WHEN] Recalculation is accepted.
        LibraryIRS1099Document.UpdateTransmission(Transmission);

        // [THEN] Form Document remains Open and unlinked with excluded parent and tips.
        IRS1099FormDocHeader.Get(IRS1099FormDocHeader.ID);
        Assert.AreEqual(IRS1099FormDocHeader.Status::Open, IRS1099FormDocHeader.Status, 'A nonfiling document must remain editable.');
        VerifyParentDocLineState(IRS1099FormDocHeader.ID, 500, false);
        VerifyDocumentLink(IRS1099FormDocHeader.ID, 0);
        VerifySavedTips(IRS1099FormDocHeader.ID, 100);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalRecreationTransfersBeforeHeaderCleanup()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        SupplementalLine: Record "IRS 1099 Doc. Suppl. Line";
        OldDocumentID: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Deleting and recreating a Form Document transfers disclosures to its actual new identity.
        Initialize();

        // [GIVEN] Form Document has saved tips and parent that will be renumbered.
        CreateSupplementalUpdateDocument(IRS1099FormDocHeader, 5000, 100);
        OldDocumentID := IRS1099FormDocHeader.ID;

        // [WHEN] Same year/vendor/form is recreated.
        LibraryIRS1099Document.CreateFormDocuments(DMY2Date(1, 1, 2026), DMY2Date(31, 12, 2026),
            IRS1099FormDocHeader."Vendor No.", IRS1099FormDocHeader."Form No.", true);

        // [THEN] Only new document owns transferred values.
        FindReplacementDocument(IRS1099FormDocHeader);
        Assert.AreNotEqual(OldDocumentID, IRS1099FormDocHeader.ID, 'The new identity must not be assumed equal to the old one.');
        VerifySavedTips(IRS1099FormDocHeader.ID, 100);
        SupplementalLine.SetRange("Document ID", OldDocumentID);
        Assert.RecordIsEmpty(SupplementalLine);
        VerifyParentDocLineState(IRS1099FormDocHeader.ID, 5000, true);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalRejectedRecreationRestoresOriginalDocument()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        OldDocumentID: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Rejected recreation cannot destroy the source header or its supplements.
        Initialize();

        // [GIVEN] Form Document's recalculated income of 50 is smaller than saved tips of 100.
        CreateSupplementalUpdateDocument(IRS1099FormDocHeader, 5000, 100);
        OldDocumentID := IRS1099FormDocHeader.ID;
        SetDocumentAdjustment(IRS1099FormDocHeader, 'NEC-01', 50);
        Commit();

        // [WHEN] Same-identity recreation is attempted.
        asserterror LibraryIRS1099Document.CreateFormDocuments(DMY2Date(1, 1, 2026), DMY2Date(31, 12, 2026),
            IRS1099FormDocHeader."Vendor No.", IRS1099FormDocHeader."Form No.", true);

        // [THEN] Original identity and values survive.
        VerifyParentAmountError(50);
        IRS1099FormDocHeader.Get(OldDocumentID);
        VerifyParentDocLineState(OldDocumentID, 5000, true);
        VerifySavedTips(OldDocumentID, 100);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('AcceptDocumentUpdateHandler,IgnoreLifecycleMessageHandler')]
    procedure SupplementalAbandonedReplacementCopiesWithoutDeletingHistory()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        OldIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        Transmission: Record "Transmission IRIS";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A replacement copies disclosures while retaining the Abandoned source values.
        Initialize();

        // [GIVEN] Form Document needs additional Form Box.
        CreateSupplementalUpdateDocument(IRS1099FormDocHeader, 5000, 100);
        CreateFormBox(IRS1099FormDocHeader, 'NEC-03', 0);
        SetDocumentAdjustment(IRS1099FormDocHeader, 'NEC-03', 200);
        OldIRS1099FormDocHeader := IRS1099FormDocHeader;
        InitializeUpdateTransmission(Transmission, IRS1099FormDocHeader);
        Commit();

        // [WHEN] Creation of additional box is accepted.
        LibraryIRS1099Document.UpdateTransmission(Transmission);

        // [THEN] Source history and new document have separate, preserved disclosures.
        OldIRS1099FormDocHeader.Get(OldIRS1099FormDocHeader.ID);
        Assert.AreEqual(OldIRS1099FormDocHeader.Status::Abandoned, OldIRS1099FormDocHeader.Status, 'The source must remain in history.');
        FindReplacementDocument(IRS1099FormDocHeader);
        Assert.AreNotEqual(OldIRS1099FormDocHeader.ID, IRS1099FormDocHeader.ID, 'A replacement must have its own identity.');
        VerifySavedTips(OldIRS1099FormDocHeader.ID, 100);
        VerifySavedTips(IRS1099FormDocHeader.ID, 100);
        VerifyDocumentLink(IRS1099FormDocHeader.ID, Transmission."Document ID");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalReplacementUsesExactSourcesAndDetails()
    var
        FirstIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        SecondIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        OtherIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        ParentIRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
        TempIRS1099FormDocLine: Record "IRS 1099 Form Doc. Line" temporary;
        TempIRS1099FormDocLineDetail: Record "IRS 1099 Form Doc. Line Detail" temporary;
        StoredDetails: Record "IRS 1099 Form Doc. Line Detail";
        RoutingSubscriber: Codeunit "IRS 1099 Document Tests";
        NewDocumentIDs: List of [Integer];
        FirstParentEntryNo: Integer;
        SecondParentEntryNo: Integer;
        FirstNewEntryNo: Integer;
        SecondNewEntryNo: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Exact source IDs isolate replacement disclosures and both retained and new financial details.
        Initialize();

        // [GIVEN] First two Form Documents share vendor and form but have different saved values; third belongs to another vendor.
        CreateSupplementalUpdateDocument(FirstIRS1099FormDocHeader, 5000, 100);
        CreateSameVendorSupplementalDocument(SecondIRS1099FormDocHeader, FirstIRS1099FormDocHeader, 6000, 200);
        CreateAdditionalSupplementalDocument(OtherIRS1099FormDocHeader, FirstIRS1099FormDocHeader, 7000, 300);
        CreateFormBox(FirstIRS1099FormDocHeader, 'NEC-03', 0);
        FindParentDocLine(FirstIRS1099FormDocHeader.ID, ParentIRS1099FormDocLine);
        FirstParentEntryNo := CreateRoutingDetail(StoredDetails, ParentIRS1099FormDocLine, 5000);
        FindParentDocLine(SecondIRS1099FormDocHeader.ID, ParentIRS1099FormDocLine);
        SecondParentEntryNo := CreateRoutingDetail(StoredDetails, ParentIRS1099FormDocLine, 6000);
        AddCreateCandidate(TempIRS1099FormDocLine, FirstIRS1099FormDocHeader, FirstIRS1099FormDocHeader.ID, 7000, 201);
        FirstNewEntryNo := CreateRoutingDetail(TempIRS1099FormDocLineDetail, TempIRS1099FormDocLine, 201);
        AddCreateCandidate(TempIRS1099FormDocLine, SecondIRS1099FormDocHeader, SecondIRS1099FormDocHeader.ID, 3000, 202);
        SecondNewEntryNo := CreateRoutingDetail(TempIRS1099FormDocLineDetail, TempIRS1099FormDocLine, 202);

        // [WHEN] Real replacement apply accepts exact-source candidates together.
        BindSubscription(RoutingSubscriber);
        NewDocumentIDs := LibraryIRS1099Document.ApplyDocumentCreationCandidates(TempIRS1099FormDocLine, TempIRS1099FormDocLineDetail);
        UnbindSubscription(RoutingSubscriber);

        // [THEN] Each replacement has only its source's saved values and ledger details after renumbering.
        Assert.AreEqual(2, NewDocumentIDs.Count(), 'Both exact sources need independent replacements.');
        VerifyReplacementRouting(NewDocumentIDs.Get(1), 100, FirstParentEntryNo, 5000, FirstNewEntryNo, 201);
        VerifyReplacementRouting(NewDocumentIDs.Get(2), 200, SecondParentEntryNo, 6000, SecondNewEntryNo, 202);
        VerifyAbandonedSource(FirstIRS1099FormDocHeader.ID, 100);
        VerifyAbandonedSource(SecondIRS1099FormDocHeader.ID, 200);
        VerifySavedTips(OtherIRS1099FormDocHeader.ID, 300);
        OtherIRS1099FormDocHeader.Get(OtherIRS1099FormDocHeader.ID);
        Assert.AreEqual(OtherIRS1099FormDocHeader.Status::Open, OtherIRS1099FormDocHeader.Status, 'Another vendor must not be replaced.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalReplacementRequiresUnambiguousSource()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        SecondIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        TempIRS1099FormDocLine: Record "IRS 1099 Form Doc. Line" temporary;
        TempIRS1099FormDocLineDetail: Record "IRS 1099 Form Doc. Line Detail" temporary;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] An unspecified source must not silently choose one of several active documents.
        Initialize();

        // [GIVEN] Two active documents share candidate's period/vendor/form.
        CreateSupplementalUpdateDocument(IRS1099FormDocHeader, 5000, 100);
        CreateSameVendorSupplementalDocument(SecondIRS1099FormDocHeader, IRS1099FormDocHeader, 6000, 200);
        CreateFormBox(IRS1099FormDocHeader, 'NEC-03', 0);
        AddCreateCandidate(TempIRS1099FormDocLine, IRS1099FormDocHeader, 0, 7000, 201);
        Commit();

        // [WHEN] Replacement is attempted without exact source.
        asserterror LibraryIRS1099Document.ApplyDocumentCreationCandidates(TempIRS1099FormDocLine, TempIRS1099FormDocLineDetail);

        // [THEN] Neither source is changed or guessed.
        Assert.ExpectedError('Select the source document');
        Assert.ExpectedErrorCode('Dialog');
        VerifyOpenRoutingSource(IRS1099FormDocHeader.ID, 100);
        VerifyOpenRoutingSource(SecondIRS1099FormDocHeader.ID, 200);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalReplacementRejectsCrossFormSource()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        OtherIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        Form: Record "IRS 1099 Form";
        TempIRS1099FormDocLine: Record "IRS 1099 Form Doc. Line" temporary;
        TempIRS1099FormDocLineDetail: Record "IRS 1099 Form Doc. Line Detail" temporary;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A supplied source from another form is rejected rather than substituted.
        Initialize();

        // [GIVEN] NEC candidate carries ID of same vendor's MISC document.
        CreateSupplementalUpdateDocument(IRS1099FormDocHeader, 5000, 100);
        Form."Period No." := IRS1099FormDocHeader."Period No.";
        Form."No." := 'MISC';
        Form.Insert(true);
        OtherIRS1099FormDocHeader."Period No." := IRS1099FormDocHeader."Period No.";
        OtherIRS1099FormDocHeader."Vendor No." := IRS1099FormDocHeader."Vendor No.";
        OtherIRS1099FormDocHeader."Form No." := 'MISC';
        OtherIRS1099FormDocHeader.Insert(true);
        CreateFormBox(IRS1099FormDocHeader, 'NEC-03', 0);
        AddCreateCandidate(TempIRS1099FormDocLine, IRS1099FormDocHeader, OtherIRS1099FormDocHeader.ID, 7000, 201);
        Commit();

        // [WHEN] Incompatible exact source is applied.
        asserterror LibraryIRS1099Document.ApplyDocumentCreationCandidates(TempIRS1099FormDocLine, TempIRS1099FormDocLineDetail);

        // [THEN] Both identities and NEC disclosures are unchanged.
        Assert.ExpectedError('Form No.');
        Assert.ExpectedErrorCode('TestField');
        VerifyOpenRoutingSource(IRS1099FormDocHeader.ID, 100);
        OtherIRS1099FormDocHeader.Get(OtherIRS1099FormDocHeader.ID);
        Assert.AreEqual(OtherIRS1099FormDocHeader.Status::Open, OtherIRS1099FormDocHeader.Status, 'The other form must remain unchanged.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('AcceptDocumentUpdateHandler,IgnoreLifecycleMessageHandler')]
    procedure SupplementalMixedCreateAbandonDoesNotResurrectRemovedBox()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        OldIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        ParentIRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
        RemovedIRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
        Details: Record "IRS 1099 Form Doc. Line Detail";
        Transmission: Record "Transmission IRIS";
        ParentEntryNo: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A selected removal stays removed when another form box creates a replacement.
        Initialize();

        // [GIVEN] Form Document retains compensation and details, removes withholding, and adds different box.
        CreateSupplementalUpdateDocument(IRS1099FormDocHeader, 5000, 100);
        CreateFormBoxAndDocLine(IRS1099FormDocHeader, 'NEC-04', 50, 0);
        CreateFormBox(IRS1099FormDocHeader, 'NEC-03', 0);
        SetDocumentAdjustment(IRS1099FormDocHeader, 'NEC-03', 200);
        FindParentDocLine(IRS1099FormDocHeader.ID, ParentIRS1099FormDocLine);
        ParentEntryNo := CreateRoutingDetail(Details, ParentIRS1099FormDocLine, 5000);
        OldIRS1099FormDocHeader := IRS1099FormDocHeader;
        InitializeUpdateTransmission(Transmission, IRS1099FormDocHeader);
        Commit();

        // [WHEN] Actual transmission update accepts Create and Abandon together.
        LibraryIRS1099Document.UpdateTransmission(Transmission);

        // [THEN] New document retains parent and its detail, but not removed box.
        FindReplacementDocument(IRS1099FormDocHeader);
        RemovedIRS1099FormDocLine.SetRange("Document ID", IRS1099FormDocHeader.ID);
        RemovedIRS1099FormDocLine.SetRange("Form Box No.", 'NEC-04');
        Assert.RecordIsEmpty(RemovedIRS1099FormDocLine);
        VerifyRoutedDetail(IRS1099FormDocHeader.ID, 'NEC-01', ParentEntryNo, 5000);
        VerifySavedTips(IRS1099FormDocHeader.ID, 100);
        VerifyAbandonedSource(OldIRS1099FormDocHeader.ID, 100);
        VerifyDocumentLink(IRS1099FormDocHeader.ID, Transmission."Document ID");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('DeclineSupplementalCascadeHandler')]
    procedure SupplementalParentDeletionCancellationIsAtomic()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        ParentIRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Declining the explicit supplemental cascade preserves parent and disclosures.
        Initialize();

        // [GIVEN] Form Document has financial parent with saved supplemental lines.
        CreateSupplementalUpdateDocument(IRS1099FormDocHeader, 5000, 100);
        FindParentDocLine(IRS1099FormDocHeader.ID, ParentIRS1099FormDocLine);
        Commit();

        // [WHEN] User declines deliberate parent deletion.
        asserterror ParentIRS1099FormDocLine.Delete(true);

        // [THEN] No values are removed.
        Assert.AreEqual('', GetLastErrorText(), 'Declining deletion must cancel without an error message.');
        VerifyParentDocLineState(IRS1099FormDocHeader.ID, 5000, true);
        VerifySavedTips(IRS1099FormDocHeader.ID, 100);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('AcceptSupplementalCascadeHandler')]
    procedure SupplementalParentDeletionCascadesOnlyLinkedRows()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        ParentIRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
        SupplementalLine: Record "IRS 1099 Doc. Suppl. Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Confirmed deletion removes the parent and its supplements but not other financial lines.
        Initialize();

        // [GIVEN] Form Document has supplemental parent and unrelated financial line.
        CreateSupplementalUpdateDocument(IRS1099FormDocHeader, 5000, 100);
        CreateFormBoxAndDocLine(IRS1099FormDocHeader, 'NEC-03', 200, 0);
        FindParentDocLine(IRS1099FormDocHeader.ID, ParentIRS1099FormDocLine);

        // [WHEN] Explicit supplemental cascade is confirmed.
        ParentIRS1099FormDocLine.Delete(true);

        // [THEN] Only linked data is removed.
        ParentIRS1099FormDocLine.Reset();
        ParentIRS1099FormDocLine.SetRange("Document ID", IRS1099FormDocHeader.ID);
        Assert.RecordCount(ParentIRS1099FormDocLine, 1);
        ParentIRS1099FormDocLine.FindFirst();
        Assert.AreEqual('NEC-03', ParentIRS1099FormDocLine."Form Box No.", 'Unrelated financial data must remain.');
        SupplementalLine.SetRange("Document ID", IRS1099FormDocHeader.ID);
        Assert.RecordIsEmpty(SupplementalLine);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalMISCMappingRejectsRents()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        SupplementalBox: Record "IRS 1099 Suppl. Box";
        FormBox: Record "IRS 1099 Form Box";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] An unused MISC cash-tip definition cannot point at rents.
        Initialize();

        // [GIVEN] MISC other income and separate valid rents box.
        LibraryIRS1099Document.CreateSupplementalDocument(IRS1099FormDocHeader, 'MISC');
        FormBox."Period No." := IRS1099FormDocHeader."Period No.";
        FormBox."Form No." := 'MISC';
        FormBox."No." := 'MISC-01';
        FormBox.Insert(true);
        SupplementalBox.Get(IRS1099FormDocHeader."Period No.", 'MISC', 'MISC-13A');
        SupplementalBox."Parent Form Box No." := 'MISC-01';

        // [WHEN] Otherwise existing form box is assigned as tip parent.
        asserterror SupplementalBox.Modify(true);

        // [THEN] Full mapping tuple, not just parent existence, is enforced.
        Assert.ExpectedError('does not meet the reporting requirements');
        Assert.ExpectedErrorCode('Dialog');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalMappingRejectsWrongValueType()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        SupplementalBox: Record "IRS 1099 Suppl. Box";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A known amount mapping cannot be configured as codes.
        Initialize();

        // [GIVEN] Unused NEC cash-tip definition.
        LibraryIRS1099Document.CreateSupplementalDocument(IRS1099FormDocHeader, 'NEC');
        SupplementalBox.Get(IRS1099FormDocHeader."Period No.", 'NEC', 'NEC-01B');
        SupplementalBox."Value Type" := SupplementalBox."Value Type"::"Occupation Codes";

        // [WHEN] Its stored type is changed.
        asserterror SupplementalBox.Modify(true);

        // [THEN] Mapping cannot reinterpret amounts.
        Assert.ExpectedError('does not meet the reporting requirements');
        Assert.ExpectedErrorCode('Dialog');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalMappingRejectsWrongElement()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        SupplementalBox: Record "IRS 1099 Suppl. Box";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A known cash-tip identifier cannot serialize overtime.
        Initialize();

        // [GIVEN] Unused NEC cash-tip definition.
        LibraryIRS1099Document.CreateSupplementalDocument(IRS1099FormDocHeader, 'NEC');
        SupplementalBox.Get(IRS1099FormDocHeader."Period No.", 'NEC', 'NEC-01B');
        SupplementalBox."XML Element Name" := 'OvertimeCompensationAmt';

        // [WHEN] Its XML element is changed.
        asserterror SupplementalBox.Modify(true);

        // [THEN] Valid but different XML element is rejected.
        Assert.ExpectedError('does not meet the reporting requirements');
        Assert.ExpectedErrorCode('Dialog');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure CustomSupplBoxRemainsEditable()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        SupplementalBox: Record "IRS 1099 Suppl. Box";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Compatible descriptions and unmapped custom definitions remain editable.
        Initialize();

        // [GIVEN] Unused standard definition.
        LibraryIRS1099Document.CreateSupplementalDocument(IRS1099FormDocHeader, 'NEC');
        SupplementalBox.Get(IRS1099FormDocHeader."Period No.", 'NEC', 'NEC-01B');

        // [WHEN] Its description is customized and separate unmapped amount definition is added.
        SupplementalBox.Description := 'Qualified cash tips';
        SupplementalBox.Modify(true);
        SupplementalBox."No." := 'CUSTOM';
        SupplementalBox."XML Element Name" := '';
        SupplementalBox.Insert(true);
        SupplementalBox.Rename(SupplementalBox."Period No.", 'NEC', 'CUSTOM-RENAMED');

        // [THEN] Custom setup has its own identity without claiming XML mapping.
        SupplementalBox.Get(IRS1099FormDocHeader."Period No.", 'NEC', 'CUSTOM-RENAMED');
        Assert.AreEqual('Qualified cash tips', SupplementalBox.Description, 'Description customization was lost.');
        Assert.AreEqual('', SupplementalBox."XML Element Name", 'A custom definition must not acquire an XML mapping.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalCodesRemainTextAndSeparateFromIncome()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        SupplementalLine: Record "IRS 1099 Doc. Suppl. Line";
        IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Occupation codes preserve leading zeros without creating financial lines.
        Initialize();

        // [GIVEN] NEC income document.
        LibraryIRS1099Document.CreateSupplementalDocument(IRS1099FormDocHeader, 'NEC');
        CreateSupplementalLine(SupplementalLine, IRS1099FormDocHeader.ID, 'NEC-01C');

        // [WHEN] Two valid text codes are stored.
        SupplementalLine.Validate("Occupation Code 1", '101');
        SupplementalLine.Validate("Occupation Code 2", '000');
        SupplementalLine.Modify(true);

        // [THEN] Codes and saved parent remain typed and financial income remains unchanged.
        SupplementalLine.Get(IRS1099FormDocHeader.ID, 'NEC-01C');
        VerifySupplementalCodes(SupplementalLine);
        IRS1099FormDocLine.SetRange("Document ID", IRS1099FormDocHeader.ID);
        Assert.RecordCount(IRS1099FormDocLine, 1);
        IRS1099FormDocLine.FindFirst();
        Assert.AreEqual(5000, IRS1099FormDocLine.Amount, 'Codes must not add financial income.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalBoxChangeDoesNotReinterpretAmount()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        SupplementalLine: Record "IRS 1099 Doc. Suppl. Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Selecting a code box cannot silently reinterpret an entered amount.
        Initialize();

        // [GIVEN] Amount row with entered tips.
        LibraryIRS1099Document.CreateSupplementalDocument(IRS1099FormDocHeader, 'NEC');
        CreateSupplementalLine(SupplementalLine, IRS1099FormDocHeader.ID, 'NEC-01B');
        SupplementalLine.Validate(Amount, 100);
        SupplementalLine.Modify(true);

        // [WHEN] Box is changed to occupation codes.
        asserterror SupplementalLine.Validate("Supplemental Box No.", 'NEC-01C');

        // [THEN] Typed values must be corrected explicitly.
        Assert.ExpectedError('Clear the incompatible values before changing the supplemental box');
        Assert.ExpectedErrorCode('Dialog');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalAmountRowRejectsCodes()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        SupplementalLine: Record "IRS 1099 Doc. Suppl. Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Amount rows cannot store occupation codes even through record writes.
        Initialize();

        // [GIVEN] NEC tip amount row.
        LibraryIRS1099Document.CreateSupplementalDocument(IRS1099FormDocHeader, 'NEC');
        CreateSupplementalLine(SupplementalLine, IRS1099FormDocHeader.ID, 'NEC-01B');
        SupplementalLine."Occupation Code 1" := '101';

        // [WHEN] Code is assigned without field validation.
        asserterror SupplementalLine.Modify(true);

        // [THEN] Table trigger still enforces value kind.
        Assert.ExpectedError('Amount lines cannot contain occupation codes, and Occupation Codes lines cannot contain an amount');
        Assert.ExpectedErrorCode('Dialog');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalCodeGapIsRejected()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        SupplementalLine: Record "IRS 1099 Doc. Suppl. Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A three-digit value outside the exact XSD enumeration is rejected.
        Initialize();

        // [GIVEN] Occupation-code row.
        LibraryIRS1099Document.CreateSupplementalDocument(IRS1099FormDocHeader, 'NEC');
        CreateSupplementalLine(SupplementalLine, IRS1099FormDocHeader.ID, 'NEC-01C');

        // [WHEN] Gap immediately after code 110 is entered.
        asserterror SupplementalLine.Validate("Occupation Code 1", '111');

        // [THEN] Three numeric-looking characters alone are insufficient.
        Assert.ExpectedError('Enter a three-character Treasury tipped occupation code supported for the reporting year');
        Assert.ExpectedErrorCode('Dialog');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalAmountRejectsParentOverflow()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        SupplementalLine: Record "IRS 1099 Doc. Suppl. Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] An individual breakdown cannot exceed its stored income.
        Initialize();

        // [GIVEN] Parent amount of 5000.
        LibraryIRS1099Document.CreateSupplementalDocument(IRS1099FormDocHeader, 'NEC');
        CreateSupplementalLine(SupplementalLine, IRS1099FormDocHeader.ID, 'NEC-01D');

        // [WHEN] Overtime exceeds that parent.
        asserterror SupplementalLine.Validate(Amount, 5001);

        // [THEN] Error identifies document breakdown constraint.
        Assert.ExpectedError('must be between zero and the amount');
        Assert.ExpectedErrorCode('Dialog');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalSnapshotSurvivesFormBoxRenumbering()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        SupplementalLine: Record "IRS 1099 Doc. Suppl. Line";
        IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Parent lookup uses document ID and saved box rather than financial line number.
        Initialize();

        // [GIVEN] Saved tip row and its financial parent.
        LibraryIRS1099Document.CreateSupplementalDocument(IRS1099FormDocHeader, 'NEC');
        CreateSupplementalLine(SupplementalLine, IRS1099FormDocHeader.ID, 'NEC-01B');
        IRS1099FormDocLine.SetRange("Document ID", IRS1099FormDocHeader.ID);
        IRS1099FormDocLine.FindFirst();

        // [WHEN] Financial line is renumbered and tips are subsequently edited.
        IRS1099FormDocLine.Rename(IRS1099FormDocLine."Period No.", IRS1099FormDocLine."Vendor No.",
            IRS1099FormDocLine."Form No.", IRS1099FormDocHeader.ID, 30000);
        SupplementalLine.Validate(Amount, 100);
        SupplementalLine.Modify(true);

        // [THEN] Saved parent box still resolves same income.
        Assert.AreEqual('NEC-01', SupplementalLine."Parent Form Box No.", 'Renumbering must not redirect the parent.');
        Assert.AreEqual(100, SupplementalLine.Amount, 'The breakdown should remain editable.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalInUseDescriptionIsEditable()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        SupplementalLine: Record "IRS 1099 Doc. Suppl. Line";
        SupplementalBox: Record "IRS 1099 Suppl. Box";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Nonstructural edits remain allowed for an in-use definition.
        Initialize();

        // [GIVEN] Used cash-tip definition.
        LibraryIRS1099Document.CreateSupplementalDocument(IRS1099FormDocHeader, 'NEC');
        CreateSupplementalLine(SupplementalLine, IRS1099FormDocHeader.ID, 'NEC-01B');
        SupplementalBox.Get(IRS1099FormDocHeader."Period No.", 'NEC', 'NEC-01B');

        // [WHEN] Its description is edited.
        SupplementalBox.Description := 'Customized tips label';
        SupplementalBox.Modify(true);

        // [THEN] Existing saved parent relationships remain unchanged.
        SupplementalLine.Get(IRS1099FormDocHeader.ID, 'NEC-01B');
        Assert.AreEqual('NEC-01', SupplementalLine."Parent Form Box No.", 'A label edit must not change the snapshot.');
        Assert.AreEqual('Customized tips label', SupplementalBox.Description, 'Compatible edits must remain allowed.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplBoxInUseCannotBeDeleted()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        SupplementalLine: Record "IRS 1099 Doc. Suppl. Line";
        SupplementalBox: Record "IRS 1099 Suppl. Box";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Deleting an in-use definition cannot orphan stored disclosures.
        Initialize();

        // [GIVEN] Used cash-tip definition.
        LibraryIRS1099Document.CreateSupplementalDocument(IRS1099FormDocHeader, 'NEC');
        CreateSupplementalLine(SupplementalLine, IRS1099FormDocHeader.ID, 'NEC-01B');
        SupplementalBox.Get(IRS1099FormDocHeader."Period No.", 'NEC', 'NEC-01B');

        // [WHEN] Setup row is deleted.
        asserterror SupplementalBox.Delete(true);

        // [THEN] Dependent document is identified.
        Assert.ExpectedError('is used by document');
        Assert.ExpectedErrorCode('Dialog');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplBoxInUseCannotBeRenamed()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        SupplementalLine: Record "IRS 1099 Doc. Suppl. Line";
        SupplementalBox: Record "IRS 1099 Suppl. Box";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Renaming an in-use definition cannot redirect its identity.
        Initialize();

        // [GIVEN] Used cash-tip definition.
        LibraryIRS1099Document.CreateSupplementalDocument(IRS1099FormDocHeader, 'NEC');
        CreateSupplementalLine(SupplementalLine, IRS1099FormDocHeader.ID, 'NEC-01B');
        SupplementalBox.Get(IRS1099FormDocHeader."Period No.", 'NEC', 'NEC-01B');

        // [WHEN] Setup identity is renamed.
        asserterror SupplementalBox.Rename(SupplementalBox."Period No.", 'NEC', 'CUSTOM');

        // [THEN] Dependent document is identified.
        Assert.ExpectedError('is used by document');
        Assert.ExpectedErrorCode('Dialog');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalLookupExcludesAddedAndMissingParents()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        SupplementalLine: Record "IRS 1099 Doc. Suppl. Line";
        SupplementalBox: Record "IRS 1099 Suppl. Box";
        FormBox: Record "IRS 1099 Form Box";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] The lookup shows only same-form available definitions with financial parents.
        Initialize();

        // [GIVEN] Three definitions, one already selected on document.
        LibraryIRS1099Document.CreateSupplementalDocument(IRS1099FormDocHeader, 'NEC');
        CreateSupplementalLine(SupplementalLine, IRS1099FormDocHeader.ID, 'NEC-01B');
        FormBox."Period No." := IRS1099FormDocHeader."Period No.";
        FormBox."Form No." := 'NEC';
        FormBox."No." := 'UNUSED-PARENT';
        FormBox.Insert(true);
        SupplementalBox."Period No." := IRS1099FormDocHeader."Period No.";
        SupplementalBox."Form No." := 'NEC';
        SupplementalBox."No." := 'CUSTOM';
        SupplementalBox."Parent Form Box No." := 'UNUSED-PARENT';
        SupplementalBox.Insert(true);

        // [WHEN] Available boxes are resolved.
        LibraryIRS1099Document.FilterAvailableSupplementalBoxes(SupplementalBox, IRS1099FormDocHeader.ID);

        // [THEN] Only two remaining definitions are offered.
        Assert.RecordCount(SupplementalBox, 2);
        SupplementalBox.FindFirst();
        Assert.AreEqual('NEC-01C', SupplementalBox."No.", 'The already selected box must not be offered again.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalSetupRejectsEarlierTaxYear()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        SupplementalBox: Record "IRS 1099 Suppl. Box";
        ReportingPeriod: Record "IRS Reporting Period";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Supplemental definitions cannot be saved for an earlier year.
        Initialize();

        // [GIVEN] Fixture whose reporting period is changed to 2025.
        LibraryIRS1099Document.CreateSupplementalDocument(IRS1099FormDocHeader, 'NEC');
        ReportingPeriod.Get(IRS1099FormDocHeader."Period No.");
        ReportingPeriod."Starting Date" := DMY2Date(1, 1, 2025);
        ReportingPeriod."Ending Date" := DMY2Date(31, 12, 2025);
        ReportingPeriod.Modify();
        SupplementalBox.Get(IRS1099FormDocHeader."Period No.", 'NEC', 'NEC-01B');

        // [WHEN] Otherwise compatible definition is saved.
        SupplementalBox.Description := 'Earlier year';
        asserterror SupplementalBox.Modify(true);

        // [THEN] Scope is validated independently of mapping identifier.
        Assert.ExpectedError('supported for tax years 2026 and later on forms MISC and NEC within a single calendar year');
        Assert.ExpectedErrorCode('Dialog');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalReleaseSupportsFutureTaxYear()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        ReportingPeriod: Record "IRS Reporting Period";
        TipsSupplementalLine: Record "IRS 1099 Doc. Suppl. Line";
        CodesSupplementalLine: Record "IRS 1099 Doc. Suppl. Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Supplemental validation accepts later single-year dates while retaining the numeric period's mappings.
        Initialize();

        // [GIVEN] Form Document has tips and occupation codes in single 2027 reporting period.
        LibraryIRS1099Document.CreateSupplementalDocument(IRS1099FormDocHeader, 'NEC');
        ReportingPeriod.Get(IRS1099FormDocHeader."Period No.");
        ReportingPeriod."Starting Date" := 20270101D;
        ReportingPeriod."Ending Date" := 20271231D;
        ReportingPeriod.Modify();
        CreateSupplementalLine(TipsSupplementalLine, IRS1099FormDocHeader.ID, 'NEC-01B');
        TipsSupplementalLine.Validate(Amount, 100);
        TipsSupplementalLine.Modify(true);
        CreateSupplementalLine(CodesSupplementalLine, IRS1099FormDocHeader.ID, 'NEC-01C');
        CodesSupplementalLine.Validate("Occupation Code 1", '000');
        CodesSupplementalLine.Modify(true);

        // [WHEN] Requested operation is executed through its existing entry point.
        LibraryIRS1099Document.ReleaseDocument(IRS1099FormDocHeader);

        // [THEN] Expected result and preserved data are verified.
        Assert.AreEqual(IRS1099FormDocHeader.Status::Released, IRS1099FormDocHeader.Status, 'Status must match the expected value.');
        Assert.IsTrue(LibraryIRS1099Document.IsSupplementalReportable(TipsSupplementalLine), 'Future-year tips must remain reportable.');
        Assert.IsTrue(LibraryIRS1099Document.IsSupplementalReportable(CodesSupplementalLine), 'Future-year codes must remain reportable.');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalSetupRejectsSpanningTaxYears()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        ReportingPeriod: Record "IRS Reporting Period";
        SupplementalBox: Record "IRS 1099 Suppl. Box";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Removing the upper year limit must not allow a period spanning two calendar years.
        Initialize();

        // [GIVEN] Form Document's reporting period spans 2026 and 2027.
        LibraryIRS1099Document.CreateSupplementalDocument(IRS1099FormDocHeader, 'NEC');
        ReportingPeriod.Get(IRS1099FormDocHeader."Period No.");
        ReportingPeriod."Ending Date" := 20271231D;
        ReportingPeriod.Modify();
        SupplementalBox.Get(IRS1099FormDocHeader."Period No.", 'NEC', 'NEC-01B');

        // [WHEN] Requested operation is executed through its existing entry point.
        SupplementalBox.Description := 'Spanning tax years';
        asserterror SupplementalBox.Modify(true);

        // [THEN] Expected result and preserved data are verified.
        Assert.ExpectedError('within a single calendar year');
        Assert.ExpectedErrorCode('Dialog');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalBoxIsNotJournalDestination()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A supplemental box is not an ordinary financial posting destination.
        Initialize();

        // [GIVEN] Definitions stored separately from financial form boxes.
        LibraryIRS1099Document.CreateSupplementalDocument(IRS1099FormDocHeader, 'NEC');
        GenJournalLine."IRS 1099 Reporting Period" := IRS1099FormDocHeader."Period No.";
        GenJournalLine."IRS 1099 Form No." := 'NEC';

        // [WHEN] Supplemental tip box is selected as journal destination.
        asserterror GenJournalLine.Validate("IRS 1099 Form Box No.", 'NEC-01B');

        // [THEN] Financial table relation rejects it.
        Assert.ExpectedError('NEC-01B');
        Assert.ExpectedErrorCode('DB:RecordNotFound');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalEmptyLinesHiddenUntilShown()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        SupplementalLine: Record "IRS 1099 Doc. Suppl. Line";
        IRS1099FormDocument: TestPage "IRS 1099 Form Document";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Empty supplemental lines are hidden until explicitly shown without creating rows.
        Initialize();

        // [GIVEN] Form Document has no supplemental lines.
        LibraryIRS1099Document.CreateSupplementalDocument(IRS1099FormDocHeader, 'NEC');
        IRS1099FormDocument.OpenEdit();
        IRS1099FormDocument.GoToRecord(IRS1099FormDocHeader);
        VerifySupplementalLinesVisibility(IRS1099FormDocument, false);

        // [WHEN] User reveals supplemental lines.
        IRS1099FormDocument.ShowSupplementalLines.Invoke();

        // [THEN] Part is visible without inserting unused rows.
        VerifySupplementalLinesVisibility(IRS1099FormDocument, true);
        IRS1099FormDocument.Close();
        SupplementalLine.SetRange("Document ID", IRS1099FormDocHeader.ID);
        Assert.IsTrue(SupplementalLine.IsEmpty(), 'Showing supplemental lines must not create rows.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalExistingOpenLinesVisible()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        SupplementalLine: Record "IRS 1099 Doc. Suppl. Line";
        IRS1099FormDocument: TestPage "IRS 1099 Form Document";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Existing supplemental lines are automatically shown on an Open document.
        Initialize();

        // [GIVEN] Open Form Document has supplemental line.
        LibraryIRS1099Document.CreateSupplementalDocument(IRS1099FormDocHeader, 'NEC');
        CreateSupplementalLine(SupplementalLine, IRS1099FormDocHeader.ID, 'NEC-01B');

        // [WHEN] Document card is opened.
        IRS1099FormDocument.OpenEdit();
        IRS1099FormDocument.GoToRecord(IRS1099FormDocHeader);

        // [THEN] Existing disclosures are visible and editable.
        VerifySupplementalLinesVisibility(IRS1099FormDocument, true);
        Assert.IsTrue(IRS1099FormDocument.SupplementalLines.Amount.Editable(), 'Open supplemental lines must remain editable.');
        IRS1099FormDocument.Close();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalExistingReleasedLinesVisible()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        SupplementalLine: Record "IRS 1099 Doc. Suppl. Line";
        IRS1099FormDocument: TestPage "IRS 1099 Form Document";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Existing supplemental lines remain visible and read-only on a Released document.
        Initialize();

        // [GIVEN] Released Form Document has supplemental line.
        LibraryIRS1099Document.CreateSupplementalDocument(IRS1099FormDocHeader, 'NEC');
        CreateSupplementalLine(SupplementalLine, IRS1099FormDocHeader.ID, 'NEC-01B');
        IRS1099FormDocHeader.Status := IRS1099FormDocHeader.Status::Released;
        IRS1099FormDocHeader.Modify(true);

        // [WHEN] Document card is opened.
        IRS1099FormDocument.OpenEdit();
        IRS1099FormDocument.GoToRecord(IRS1099FormDocHeader);

        // [THEN] Existing disclosures are visible but cannot be edited.
        VerifySupplementalLinesVisibility(IRS1099FormDocument, true);
        Assert.IsFalse(IRS1099FormDocument.SupplementalLines.Amount.Editable(), 'Released supplemental lines must remain read-only.');
        IRS1099FormDocument.Close();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalVisibilityResetsOnNavigation()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        OtherIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        IRS1099FormDocument: TestPage "IRS 1099 Form Document";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Revealing empty supplemental lines applies only to the current document.
        Initialize();

        // [GIVEN] Two Form Documents have no supplemental lines, and first document's part is explicitly shown.
        LibraryIRS1099Document.CreateSupplementalDocument(IRS1099FormDocHeader, 'NEC');
        OtherIRS1099FormDocHeader."Period No." := IRS1099FormDocHeader."Period No.";
        OtherIRS1099FormDocHeader."Vendor No." := LibraryPurchase.CreateVendorNo();
        OtherIRS1099FormDocHeader."Form No." := IRS1099FormDocHeader."Form No.";
        OtherIRS1099FormDocHeader.Insert(true);
        IRS1099FormDocument.OpenEdit();
        IRS1099FormDocument.GoToRecord(IRS1099FormDocHeader);
        IRS1099FormDocument.ShowSupplementalLines.Invoke();

        // [WHEN] User navigates to second Form Document.
        IRS1099FormDocument.GoToRecord(OtherIRS1099FormDocHeader);

        // [THEN] Second Form Document's empty supplemental lines are hidden.
        VerifySupplementalLinesVisibility(IRS1099FormDocument, false);

        // [WHEN] User returns to first Form Document without having entered supplemental line.
        IRS1099FormDocument.GoToRecord(IRS1099FormDocHeader);

        // [THEN] First Form Document's empty supplemental lines are hidden again.
        VerifySupplementalLinesVisibility(IRS1099FormDocument, false);
        IRS1099FormDocument.Close();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SupplementalBoxLookupHandler')]
    procedure SupplementalManualLookupAssignsReadOnlyParent()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        SupplementalLine: Record "IRS 1099 Doc. Suppl. Line";
        IRS1099FormDocument: TestPage "IRS 1099 Form Document";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Manual lookup fills the parent without inserting unused supplemental rows.
        Initialize();

        // [GIVEN] Document with definitions and no supplemental rows.
        LibraryIRS1099Document.CreateSupplementalDocument(IRS1099FormDocHeader, 'NEC');
        IRS1099FormDocument.OpenEdit();
        IRS1099FormDocument.GoToRecord(IRS1099FormDocHeader);

        // [WHEN] User explicitly selects first descriptive lookup choice.
        IRS1099FormDocument.ShowSupplementalLines.Invoke();
        IRS1099FormDocument.SupplementalLines.New();
        IRS1099FormDocument.SupplementalLines."Supplemental Box No.".Lookup();
        IRS1099FormDocument.SupplementalLines.Amount.SetValue(100);

        // [THEN] Assigned parent is read-only and only selected row is saved.
        Assert.IsFalse(IRS1099FormDocument.SupplementalLines."Parent Form Box No.".Editable(), 'The parent snapshot must be read-only.');
        IRS1099FormDocument.Close();
        SupplementalLine.SetRange("Document ID", IRS1099FormDocHeader.ID);
        Assert.RecordCount(SupplementalLine, 1);
        SupplementalLine.FindFirst();
        Assert.AreEqual('NEC-01', SupplementalLine."Parent Form Box No.", 'Lookup must assign the definition parent.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalReleasedDocumentRejectsEdits()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        SupplementalLine: Record "IRS 1099 Doc. Suppl. Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Stored disclosures cannot be changed while their document is Released.
        Initialize();

        // [GIVEN] Supplemental row on released document.
        LibraryIRS1099Document.CreateSupplementalDocument(IRS1099FormDocHeader, 'NEC');
        CreateSupplementalLine(SupplementalLine, IRS1099FormDocHeader.ID, 'NEC-01B');
        IRS1099FormDocHeader.Status := IRS1099FormDocHeader.Status::Released;
        IRS1099FormDocHeader.Modify(true);

        // [WHEN] Its amount is edited directly.
        asserterror SupplementalLine.Validate(Amount, 100);

        // [THEN] Normal document status restriction applies.
        Assert.ExpectedError('Open');
        Assert.ExpectedErrorCode('TestField');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('InspectWithholdingUpdateHandler,DeclineDependentEligibilityHandler')]
    procedure DecliningDependentEligibilityChangesPreservesAllLines()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        Transmission: Record "Transmission IRIS";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Declining dependent eligibility changes rolls back the selected withholding update.
        Initialize();

        // [GIVEN] Form Document has income qualified by withholding, and only withholding is selected for removal.
        CreateWithholdingRemovalCandidate(IRS1099FormDocHeader, Transmission);
        Commit();

        // [WHEN] Dependent change to unselected income line is declined.
        asserterror LibraryIRS1099Document.UpdateTransmission(Transmission);

        // [THEN] Neither selected withholding nor its dependent income and disclosures change.
        Assert.ExpectedError('');
        Assert.ExpectedErrorCode('Dialog');
        VerifyDependentEligibilityConfirmation(IRS1099FormDocHeader.ID);
        VerifyUnchangedWithholdingDocument(IRS1099FormDocHeader);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('InspectWithholdingUpdateHandler,AcceptDependentEligibilityHandler,IgnoreLifecycleMessageHandler')]
    procedure CreatingWithholdingConfirmsCopiedIncomeEligibility()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        OriginalIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        Transmission: Record "Transmission IRIS";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Selecting a new withholding line confirms the changed eligibility of copied unselected income.
        Initialize();

        // [GIVEN] Form Document stores manual excluded income 750 while proposed financial recalculation is 500.
        CreateWithholdingCreationCandidate(IRS1099FormDocHeader, Transmission);
        OriginalIRS1099FormDocHeader := IRS1099FormDocHeader;
        Commit();

        // [WHEN] Only new withholding line is selected and its dependent eligibility change is accepted.
        LibraryIRS1099Document.UpdateTransmission(Transmission);

        // [THEN] Replacement keeps copied amount and minimum while confirming inclusion change.
        VerifyDependentEligibilityConfirmation(OriginalIRS1099FormDocHeader.ID);
        VerifyWithholdingCreation(IRS1099FormDocHeader, OriginalIRS1099FormDocHeader, Transmission."Document ID");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('InspectWithholdingUpdateHandler,DeclineDependentEligibilityHandler')]
    procedure DecliningCopiedIncomeEligibilityPreservesSource()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        Transmission: Record "Transmission IRIS";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Declining a copied-line eligibility change rolls back replacement creation and source abandonment.
        Initialize();

        // [GIVEN] Form Document has saved excluded income and selected new withholding line.
        CreateWithholdingCreationCandidate(IRS1099FormDocHeader, Transmission);
        Commit();

        // [WHEN] Dependent copied-income eligibility change is declined.
        asserterror LibraryIRS1099Document.UpdateTransmission(Transmission);

        // [THEN] Original document and disclosures survive without replacement.
        Assert.ExpectedError('');
        Assert.ExpectedErrorCode('Dialog');
        VerifyDependentEligibilityConfirmation(IRS1099FormDocHeader.ID);
        VerifyWithholdingCreationCancellation(IRS1099FormDocHeader);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SelectSupplementalSourceHandler,AcceptSupplementalCascadeHandler')]
    procedure CopySupplementalLinesFromAbandonedDocument()
    var
        SourceDocHeader: Record "IRS 1099 Form Doc. Header";
        OtherSourceDocHeader: Record "IRS 1099 Form Doc. Header";
        TargetDocHeader: Record "IRS 1099 Form Doc. Header";
        DocumentPage: TestPage "IRS 1099 Form Document";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Copying from an Abandoned source document replaces all supplemental lines on an Open target document without changing the source.
        Initialize();

        // [GIVEN] Two Abandoned source documents share vendor, year and form; target document has different supplemental values.
        CreateSupplementalCopyDocuments(SourceDocHeader, TargetDocHeader);
        CreateSameVendorSupplementalDocument(OtherSourceDocHeader, SourceDocHeader, 5000, 200);
        OtherSourceDocHeader.Status := OtherSourceDocHeader.Status::Abandoned;
        OtherSourceDocHeader.Modify(true);
        LibraryVariableStorage.Enqueue(SourceDocHeader.ID);
        Commit();
        DocumentPage.OpenEdit();
        DocumentPage.GoToRecord(TargetDocHeader);

        // [WHEN] User selects first source document and confirms replacement.
        DocumentPage.CopySupplementalLines.Invoke();

        // [THEN] Document IDs distinguish sources, target receives first source's values, and both sources are unchanged.
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), CopySourceDocIDVisibleErr);
        VerifySupplementalCopyTarget(TargetDocHeader.ID, 100, 2, '101', '000');
        VerifySupplementalCopySource(SourceDocHeader.ID);
        VerifyAbandonedSource(OtherSourceDocHeader.ID, 200);
        VerifyParentDocLineState(TargetDocHeader.ID, 5000, true);
        VerifySupplementalLinesVisibility(DocumentPage, true);
        DocumentPage.Close();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SelectSupplementalSourceHandler,DeclineSupplementalCascadeHandler')]
    procedure CopySupplementalLinesCancellationPreservesTarget()
    var
        SourceDocHeader: Record "IRS 1099 Form Doc. Header";
        TargetDocHeader: Record "IRS 1099 Form Doc. Header";
        DocumentPage: TestPage "IRS 1099 Form Document";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Declining replacement preserves every existing supplemental line.
        Initialize();

        // [GIVEN] Source and target documents have different supplemental values.
        CreateSupplementalCopyDocuments(SourceDocHeader, TargetDocHeader);
        LibraryVariableStorage.Enqueue(SourceDocHeader.ID);
        Commit();
        DocumentPage.OpenEdit();
        DocumentPage.GoToRecord(TargetDocHeader);

        // [WHEN] Source is selected but replacement is declined.
        DocumentPage.CopySupplementalLines.Invoke();

        // [THEN] Both documents retain all their original values.
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), CopySourceDocIDVisibleErr);
        VerifyUnchangedSupplementalCopyTarget(TargetDocHeader.ID);
        VerifySupplementalCopySource(SourceDocHeader.ID);
        DocumentPage.Close();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure CopySupplementalLinesRejectsReleasedTarget()
    var
        SourceDocHeader: Record "IRS 1099 Form Doc. Header";
        TargetDocHeader: Record "IRS 1099 Form Doc. Header";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Copying cannot bypass the target document's Open status requirement.
        Initialize();

        // [GIVEN] Target document is Released with its existing supplemental values.
        CreateSupplementalCopyDocuments(SourceDocHeader, TargetDocHeader);
        LibraryIRS1099Document.ReleaseDocument(TargetDocHeader);
        Commit();

        // [WHEN] Copying into target document is attempted directly.
        asserterror LibraryIRS1099Document.CopySupplementalLines(SourceDocHeader.ID, TargetDocHeader.ID);

        // [THEN] Status error leaves both documents unchanged.
        Assert.ExpectedError('Open');
        Assert.ExpectedErrorCode('TestField');
        VerifyUnchangedSupplementalCopyTarget(TargetDocHeader.ID);
        VerifySupplementalCopySource(SourceDocHeader.ID);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure CopySupplementalLinesRejectsUnsupportedMapping()
    var
        SourceDocHeader: Record "IRS 1099 Form Doc. Header";
        TargetDocHeader: Record "IRS 1099 Form Doc. Header";
        SupplBox: Record "IRS 1099 Suppl. Box";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] An unsupported XML mapping cannot replace the target's saved supplemental lines.
        Initialize();

        // [GIVEN] Setup for copied box specifies unsupported XML element.
        CreateSupplementalCopyDocuments(SourceDocHeader, TargetDocHeader);
        SupplBox.Get(TargetDocHeader."Period No.", TargetDocHeader."Form No.", 'NEC-01B');
        SupplBox."XML Element Name" := 'UnsupportedElement';
        SupplBox.Modify(false);
        Commit();

        // [WHEN] Copying is attempted against current target setup.
        asserterror LibraryIRS1099Document.CopySupplementalLines(SourceDocHeader.ID, TargetDocHeader.ID);

        // [THEN] Setup error preserves original rows on both documents.
        Assert.ExpectedError('setup for supplemental box NEC-01B does not meet the reporting requirements');
        Assert.ExpectedErrorCode('Dialog');
        VerifyUnchangedSupplementalCopyTarget(TargetDocHeader.ID);
        VerifySupplementalCopySource(SourceDocHeader.ID);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure CopySupplementalLinesRejectsMissingTargetParent()
    var
        SourceDocHeader: Record "IRS 1099 Form Doc. Header";
        TargetDocHeader: Record "IRS 1099 Form Doc. Header";
        ParentDocLine: Record "IRS 1099 Form Doc. Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A missing target parent rejects copying without removing saved supplemental rows.
        Initialize();

        // [GIVEN] Target document has saved lines but its financial parent is missing.
        CreateSupplementalCopyDocuments(SourceDocHeader, TargetDocHeader);
        FindParentDocLine(TargetDocHeader.ID, ParentDocLine);
        ParentDocLine.Delete(false);
        Commit();

        // [WHEN] Copying is attempted.
        asserterror LibraryIRS1099Document.CopySupplementalLines(SourceDocHeader.ID, TargetDocHeader.ID);

        // [THEN] Missing-parent error preserves every existing supplemental row.
        Assert.ExpectedError('must have a document line for form box NEC-01');
        Assert.ExpectedErrorCode('Dialog');
        VerifyUnchangedSupplementalCopyTarget(TargetDocHeader.ID);
        VerifySupplementalCopySource(SourceDocHeader.ID);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure CopySupplementalLinesRejectsExcessTargetAmount()
    var
        SourceDocHeader: Record "IRS 1099 Form Doc. Header";
        TargetDocHeader: Record "IRS 1099 Form Doc. Header";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Source tips exceeding the target parent amount cannot replace valid existing lines.
        Initialize();

        // [GIVEN] Source document has tips of 100; target document has parent of 50 and valid smaller disclosures.
        CreateSupplementalCopyDocuments(SourceDocHeader, TargetDocHeader);
        SetParentDocLineAmount(TargetDocHeader.ID, 50, 0);
        Commit();

        // [WHEN] Copying source values into target document is attempted.
        asserterror LibraryIRS1099Document.CopySupplementalLines(SourceDocHeader.ID, TargetDocHeader.ID);

        // [THEN] Amount error leaves target's smaller values and source unchanged.
        Assert.ExpectedError('must be between zero and the amount');
        Assert.ExpectedErrorCode('Dialog');
        VerifyUnchangedSupplementalCopyTarget(TargetDocHeader.ID);
        VerifySupplementalCopySource(SourceDocHeader.ID);
        VerifyParentDocLineState(TargetDocHeader.ID, 50, true);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplementalMappingUsesPeriodNumber()
    var
        SupplementalBox: Record "IRS 1099 Suppl. Box";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Supplemental mappings follow the period number even when the period dates identify a different year.
        Initialize();

        // [GIVEN] Period 2025 has 2026 dates and a standard NEC parent box.
        LibraryIRSReportingPeriod.CreateSpecificReportingPeriod('2025', 20260101D, 20261231D);
        LibraryIRS1099FormBox.CreateSpecificFormInReportingPeriod(20260101D, 20261231D, 'NEC');
        LibraryIRS1099FormBox.CreateSpecificFormBoxInReportingPeriod(20260101D, 20261231D, 'NEC', 'NEC-01');
        SupplementalBox."Period No." := '2025';
        SupplementalBox."Form No." := 'NEC';
        SupplementalBox."No." := 'NEC-01B';
        SupplementalBox."Parent Form Box No." := 'NEC-01';
        SupplementalBox."Value Type" := SupplementalBox."Value Type"::Amount;
        SupplementalBox."XML Element Name" := 'CashTipsAmt';

        // [WHEN] A supplemental mapping introduced in 2026 is saved.
        asserterror SupplementalBox.Insert(true);

        // [THEN] The 2025 mapping rejects the definition instead of using the period's 2026 dates.
        Assert.ExpectedError('The setup for supplemental box NEC-01B does not meet the reporting requirements');
        Assert.ExpectedErrorCode('Dialog');
        LibraryVariableStorage.AssertEmpty();
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

    local procedure AddCreateCandidate(var TempIRS1099FormDocLine: Record "IRS 1099 Form Doc. Line" temporary; IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; SourceDocumentID: Integer; LineNo: Integer; Amount: Decimal)
    begin
        TempIRS1099FormDocLine.Init();
        TempIRS1099FormDocLine."Document ID" := SourceDocumentID;
        TempIRS1099FormDocLine."Period No." := IRS1099FormDocHeader."Period No.";
        TempIRS1099FormDocLine."Vendor No." := IRS1099FormDocHeader."Vendor No.";
        TempIRS1099FormDocLine."Form No." := IRS1099FormDocHeader."Form No.";
        TempIRS1099FormDocLine."Line No." := LineNo;
        TempIRS1099FormDocLine."Form Box No." := 'NEC-03';
        TempIRS1099FormDocLine.Amount := Amount;
        TempIRS1099FormDocLine."Calculated Amount" := Amount;
        TempIRS1099FormDocLine."Include In 1099" := true;
        TempIRS1099FormDocLine."Line Action" := TempIRS1099FormDocLine."Line Action"::Create;
        TempIRS1099FormDocLine.Insert(true);
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

    local procedure CreateAdditionalSupplementalDocument(var IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; ExistingIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; ParentAmount: Decimal; TipsAmount: Decimal)
    begin
        IRS1099FormDocHeader.Init();
        IRS1099FormDocHeader."Period No." := ExistingIRS1099FormDocHeader."Period No.";
        IRS1099FormDocHeader."Vendor No." := LibraryPurchase.CreateVendorNo();
        IRS1099FormDocHeader."Form No." := ExistingIRS1099FormDocHeader."Form No.";
        IRS1099FormDocHeader.Insert(true);
        LibraryIRS1099Document.MockFormDocumentLineForVendor(IRS1099FormDocHeader.ID, IRS1099FormDocHeader."Period No.", IRS1099FormDocHeader."Vendor No.", IRS1099FormDocHeader."Form No.", 'NEC-01');
        InitializeSupplementalUpdateDocument(IRS1099FormDocHeader, ParentAmount, TipsAmount);
    end;

    local procedure CreateFormBox(IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; BoxNo: Code[20]; MinimumAmount: Decimal)
    var
        FormBox: Record "IRS 1099 Form Box";
    begin
        FormBox."Period No." := IRS1099FormDocHeader."Period No.";
        FormBox."Form No." := IRS1099FormDocHeader."Form No.";
        FormBox."No." := BoxNo;
        FormBox."Minimum Reportable Amount" := MinimumAmount;
        FormBox.Insert(true);
    end;

    local procedure CreateFormBoxAndDocLine(IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; BoxNo: Code[20]; Amount: Decimal; MinimumAmount: Decimal)
    var
        IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
    begin
        CreateFormBox(IRS1099FormDocHeader, BoxNo, MinimumAmount);
        IRS1099FormDocLine."Document ID" := IRS1099FormDocHeader.ID;
        IRS1099FormDocLine."Period No." := IRS1099FormDocHeader."Period No.";
        IRS1099FormDocLine."Vendor No." := IRS1099FormDocHeader."Vendor No.";
        IRS1099FormDocLine."Form No." := IRS1099FormDocHeader."Form No.";
        IRS1099FormDocLine."Line No." := 9000;
        IRS1099FormDocLine.Validate("Form Box No.", BoxNo);
        IRS1099FormDocLine."Minimum Reportable Amount" := MinimumAmount;
        IRS1099FormDocLine.Validate(Amount, Amount);
        IRS1099FormDocLine.Insert(true);
    end;

    local procedure CreateLifecycleAttempt(var Attempt: Record "Transmission Log IRIS"; IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; TransmissionID: Integer; InsertAttempt: Boolean)
    var
        AttemptLine: Record "Transmission Log Line IRIS";
    begin
        Attempt."Line ID" := LibraryUtility.GetNewRecNo(Attempt, Attempt.FieldNo("Line ID"));
        // Deliberate orphan lines must also reserve their absent parent's ID.
        if AttemptLine.FindLast() then
            if Attempt."Line ID" <= AttemptLine."Transmission Log ID" then
                Attempt."Line ID" := AttemptLine."Transmission Log ID" + 1;
        Attempt."Period No." := CopyStr(IRS1099FormDocHeader."Period No.", 1, MaxStrLen(Attempt."Period No."));
        Attempt."Transmission Document ID" := TransmissionID;
        Attempt."Unique Transmission ID" := 'UNRESOLVED-ATTEMPT';
        Attempt."Transmission Date/Time" := CurrentDateTime();
        Attempt."Response Http Status Code" := 500;
        if InsertAttempt then
            Attempt.Insert();
        AttemptLine.Init();
        AttemptLine."Transmission Log ID" := Attempt."Line ID";
        AttemptLine."Line ID" := 1;
        AttemptLine."IRS 1099 Form Document ID" := IRS1099FormDocHeader.ID;
        AttemptLine."Vendor No." := IRS1099FormDocHeader."Vendor No.";
        AttemptLine."Form No." := IRS1099FormDocHeader."Form No.";
        AttemptLine."Submission ID" := 'ATTEMPT-SUBMISSION';
        AttemptLine."Record ID" := 'ATTEMPT-RECORD';
        AttemptLine.Insert();
    end;

    local procedure CreateLifecycleThresholdCandidate(var IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; var Transmission: Record "Transmission IRIS")
    begin
        CreateSupplementalUpdateDocument(IRS1099FormDocHeader, 1500, 100);
        SetParentDocLineAmount(IRS1099FormDocHeader.ID, 1500, 600);
        InitializeUpdateTransmission(Transmission, IRS1099FormDocHeader);
        IRS1099FormDocHeader."IRIS Transmission Document ID" := Transmission."Document ID";
        IRS1099FormDocHeader.Modify(true);
    end;

    local procedure CreateRoutingDetail(var Details: Record "IRS 1099 Form Doc. Line Detail"; IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line"; Amount: Decimal): Integer
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        IRSFormsSetup: Record "IRS Forms Setup";
    begin
        IRSFormsSetup.Get();
        IRSFormsSetup."Collect Details For Line" := true;
        IRSFormsSetup.Modify(true);
        LibraryIRS1099Document.MockVendLedgEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment,
            DMY2Date(1, 1, 2026), DMY2Date(31, 12, 2026), IRS1099FormDocLine."Vendor No.", IRS1099FormDocLine."Form No.", IRS1099FormDocLine."Form Box No.");
        Details.Init();
        Details."Document ID" := IRS1099FormDocLine."Document ID";
        Details."Line No." := IRS1099FormDocLine."Line No.";
        Details."Vendor Ledger Entry No." := VendorLedgerEntry."Entry No.";
        Details."Calculated Amount" := Amount;
        Details.Insert(true);
        exit(VendorLedgerEntry."Entry No.");
    end;

    local procedure CreateSameVendorSupplementalDocument(var IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; SourceIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; ParentAmount: Decimal; TipsAmount: Decimal)
    begin
        IRS1099FormDocHeader."Period No." := SourceIRS1099FormDocHeader."Period No.";
        IRS1099FormDocHeader."Vendor No." := SourceIRS1099FormDocHeader."Vendor No.";
        IRS1099FormDocHeader."Form No." := SourceIRS1099FormDocHeader."Form No.";
        IRS1099FormDocHeader.Insert(true);
        LibraryIRS1099Document.MockFormDocumentLineForVendor(IRS1099FormDocHeader.ID, IRS1099FormDocHeader."Period No.", IRS1099FormDocHeader."Vendor No.", IRS1099FormDocHeader."Form No.", 'NEC-01');
        InitializeSupplementalUpdateDocument(IRS1099FormDocHeader, ParentAmount, TipsAmount);
    end;

    local procedure CreateSupplementalLine(var SupplementalLine: Record "IRS 1099 Doc. Suppl. Line"; DocumentID: Integer; BoxNo: Code[20])
    begin
        SupplementalLine.Init();
        SupplementalLine."Document ID" := DocumentID;
        SupplementalLine.Validate("Supplemental Box No.", BoxNo);
        SupplementalLine.Insert(true);
    end;

    local procedure CreateSupplementalUpdateDocument(var IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; ParentAmount: Decimal; TipsAmount: Decimal)
    var
        IRSFormsSetup: Record "IRS Forms Setup";
    begin
        IRSFormsSetup.InitSetup();
        LibraryIRS1099Document.CreateSupplementalDocument(IRS1099FormDocHeader, 'NEC');
        InitializeSupplementalUpdateDocument(IRS1099FormDocHeader, ParentAmount, TipsAmount);
    end;

    local procedure CreateWithholdingRemovalCandidate(var IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; var Transmission: Record "Transmission IRIS")
    begin
        CreateSupplementalUpdateDocument(IRS1099FormDocHeader, 500, 100);
        CreateFormBoxAndDocLine(IRS1099FormDocHeader, 'NEC-04', 50, 0);
        SetDocumentAdjustment(IRS1099FormDocHeader, 'NEC-04', 50);
        LibraryIRS1099Document.ReleaseDocument(IRS1099FormDocHeader);
        SetDocumentAdjustment(IRS1099FormDocHeader, 'NEC-04', 0);
        InitializeUpdateTransmission(Transmission, IRS1099FormDocHeader);
    end;

    local procedure CreateWithholdingCreationCandidate(var IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; var Transmission: Record "Transmission IRIS")
    begin
        CreateSupplementalUpdateDocument(IRS1099FormDocHeader, 500, 100);
        SetManualParentDocLineAmount(IRS1099FormDocHeader.ID, 750, 2000);
        LibraryIRS1099Document.ReleaseDocument(IRS1099FormDocHeader);
        CreateFormBox(IRS1099FormDocHeader, 'NEC-04', 0);
        SetDocumentAdjustment(IRS1099FormDocHeader, 'NEC-04', 50);
        InitializeUpdateTransmission(Transmission, IRS1099FormDocHeader);
    end;

    local procedure CreateSupplementalCopyDocuments(var SourceDocHeader: Record "IRS 1099 Form Doc. Header"; var TargetDocHeader: Record "IRS 1099 Form Doc. Header")
    var
        SupplLine: Record "IRS 1099 Doc. Suppl. Line";
    begin
        CreateSupplementalUpdateDocument(SourceDocHeader, 5000, 100);
        SourceDocHeader.Status := SourceDocHeader.Status::Abandoned;
        SourceDocHeader."IRIS Last Receipt ID" := 'SAVED-SOURCE-RECEIPT';
        SourceDocHeader.Modify(true);
        CreateSameVendorSupplementalDocument(TargetDocHeader, SourceDocHeader, 5000, 25);
        CreateSupplementalLine(SupplLine, TargetDocHeader.ID, 'NEC-01D');
        SupplLine.Validate(Amount, 50);
        SupplLine.Modify(true);
        SupplLine.Get(TargetDocHeader.ID, 'NEC-01C');
        SupplLine."Occupation Code 1" := '000';
        SupplLine."Occupation Code 2" := '101';
        SupplLine.Modify(true);
    end;

    procedure DeleteDocuments()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
    begin
        IRS1099FormDocHeader.ModifyAll(Status, Enum::"IRS 1099 Form Doc. Status"::Open, false);
        IRS1099FormDocHeader.ModifyAll("IRIS Transmission Document ID", 0, false);
        IRS1099FormDocHeader.DeleteAll(true);
    end;

    local procedure FindParentDocLine(DocumentID: Integer; var ParentIRS1099FormDocLine: Record "IRS 1099 Form Doc. Line")
    begin
        ParentIRS1099FormDocLine.Reset();
        ParentIRS1099FormDocLine.SetRange("Document ID", DocumentID);
        ParentIRS1099FormDocLine.SetFilter("Form Box No.", '%1|%2', 'NEC-01', 'MISC-03');
        ParentIRS1099FormDocLine.FindFirst();
    end;

    local procedure FindReplacementDocument(var IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header")
    begin
        IRS1099FormDocHeader.SetRange("Period No.", IRS1099FormDocHeader."Period No.");
        IRS1099FormDocHeader.SetRange("Vendor No.", IRS1099FormDocHeader."Vendor No.");
        IRS1099FormDocHeader.SetRange("Form No.", IRS1099FormDocHeader."Form No.");
        IRS1099FormDocHeader.SetFilter(Status, '<>%1', IRS1099FormDocHeader.Status::Abandoned);
        IRS1099FormDocHeader.FindFirst();
        IRS1099FormDocHeader.Reset();
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

    local procedure InitializeSupplementalUpdateDocument(IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; ParentAmount: Decimal; TipsAmount: Decimal)
    var
        SupplementalLine: Record "IRS 1099 Doc. Suppl. Line";
        FormBox: Record "IRS 1099 Form Box";
    begin
        FormBox.Get(IRS1099FormDocHeader."Period No.", 'NEC', 'NEC-01');
        FormBox."Minimum Reportable Amount" := 2000;
        FormBox.Modify(true);
        SetParentDocLineAmount(IRS1099FormDocHeader.ID, ParentAmount, 2000);
        SetDocumentAdjustment(IRS1099FormDocHeader, 'NEC-01', ParentAmount);
        CreateSupplementalLine(SupplementalLine, IRS1099FormDocHeader.ID, 'NEC-01B');
        SupplementalLine.Validate(Amount, TipsAmount);
        SupplementalLine.Modify(true);
        CreateSupplementalLine(SupplementalLine, IRS1099FormDocHeader.ID, 'NEC-01C');
        SupplementalLine.Validate("Occupation Code 1", '101');
        SupplementalLine.Validate("Occupation Code 2", '000');
        SupplementalLine.Modify(true);
    end;

    local procedure InitializeUpdateTransmission(var Transmission: Record "Transmission IRIS"; IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header")
    begin
        Transmission."Document ID" := LibraryUtility.GetNewRecNo(Transmission, Transmission.FieldNo("Document ID"));
        Transmission."Period No." := CopyStr(IRS1099FormDocHeader."Period No.", 1, MaxStrLen(Transmission."Period No."));
        Transmission.Insert(true);
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

    local procedure SetDocumentAdjustment(IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; BoxNo: Code[20]; Amount: Decimal)
    var
        Adjustment: Record "IRS 1099 Vendor Form Box Adj.";
    begin
        if not Adjustment.Get(IRS1099FormDocHeader."Period No.", IRS1099FormDocHeader."Vendor No.", IRS1099FormDocHeader."Form No.", BoxNo) then begin
            Adjustment.Validate("Period No.", IRS1099FormDocHeader."Period No.");
            Adjustment.Validate("Vendor No.", IRS1099FormDocHeader."Vendor No.");
            Adjustment.Validate("Form No.", IRS1099FormDocHeader."Form No.");
            Adjustment.Validate("Form Box No.", BoxNo);
            Adjustment.Insert(true);
        end;
        Adjustment.Amount := Amount;
        Adjustment.Modify(true);
    end;

    local procedure SetManualParentDocLineAmount(DocumentID: Integer; Amount: Decimal; MinimumAmount: Decimal)
    var
        ParentIRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
    begin
        SetParentDocLineAmount(DocumentID, Amount, MinimumAmount);
        FindParentDocLine(DocumentID, ParentIRS1099FormDocLine);
        ParentIRS1099FormDocLine."Manually Changed" := true;
        ParentIRS1099FormDocLine.Modify(true);
    end;

    local procedure SetParentDocLineAmount(DocumentID: Integer; ParentAmount: Decimal; MinimumAmount: Decimal)
    var
        ParentIRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
    begin
        FindParentDocLine(DocumentID, ParentIRS1099FormDocLine);
        ParentIRS1099FormDocLine."Minimum Reportable Amount" := MinimumAmount;
        ParentIRS1099FormDocLine.Validate(Amount, ParentAmount);
        ParentIRS1099FormDocLine."Calculated Amount" := ParentAmount;
        ParentIRS1099FormDocLine.Modify(true);
    end;

    local procedure VerifyIRS1099DataInGenJnlLine(GenJournalLine: Record "Gen. Journal Line"; ReportingDate: Date; FormNo: Code[20]; FormBoxNo: Code[20])
    begin
        Assert.AreEqual(LibraryIRSReportingPeriod.GetReportingPeriod(ReportingDate), GenJournalLine."IRS 1099 Reporting Period", 'IRS 1099 Reporting Period mismatch');
        Assert.AreEqual(FormNo, GenJournalLine."IRS 1099 Form No.", 'IRS 1099 Form No. mismatch');
        Assert.AreEqual(FormBoxNo, GenJournalLine."IRS 1099 Form Box No.", 'IRS 1099 Form Box No. mismatch');
    end;

    local procedure VerifyAbandonedSource(DocumentID: Integer; TipsAmount: Decimal)
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
    begin
        IRS1099FormDocHeader.Get(DocumentID);
        Assert.AreEqual(IRS1099FormDocHeader.Status::Abandoned, IRS1099FormDocHeader.Status, 'The source must remain in history.');
        VerifySavedTips(DocumentID, TipsAmount);
    end;

    local procedure VerifyDocumentLink(DocumentID: Integer; ExpectedTransmissionID: Integer)
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
    begin
        IRS1099FormDocHeader.Get(DocumentID);
        Assert.AreEqual(ExpectedTransmissionID, IRS1099FormDocHeader."IRIS Transmission Document ID", 'The transmission association changed unexpectedly.');
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

    local procedure VerifyNegativeIncomeWithWithholding(FormNo: Code[20]; WithholdingBoxNo: Code[20])
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
    begin
        LibraryIRS1099Document.CreateSupplementalDocument(IRS1099FormDocHeader, FormNo);
        SetParentDocLineAmount(IRS1099FormDocHeader.ID, -100, 2000);
        CreateFormBoxAndDocLine(IRS1099FormDocHeader, WithholdingBoxNo, 50, 0);

        LibraryIRS1099Document.ReleaseDocument(IRS1099FormDocHeader);

        VerifyParentDocLineState(IRS1099FormDocHeader.ID, -100, false);
        IRS1099FormDocLine.Get(IRS1099FormDocHeader."Period No.", IRS1099FormDocHeader."Vendor No.", IRS1099FormDocHeader."Form No.", IRS1099FormDocHeader.ID, 9000);
        Assert.IsTrue(IRS1099FormDocLine."Include In 1099", 'Positive withholding remains reportable without negative income.');
    end;

    local procedure VerifyOpenRoutingSource(DocumentID: Integer; TipsAmount: Decimal)
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
    begin
        IRS1099FormDocHeader.Get(DocumentID);
        Assert.AreEqual(IRS1099FormDocHeader.Status::Open, IRS1099FormDocHeader.Status, 'The source status must be unchanged.');
        VerifySavedTips(DocumentID, TipsAmount);
    end;

    local procedure VerifyParentAmountError(ExpectedParentAmount: Decimal)
    begin
        Assert.ExpectedError(StrSubstNo(ParentAmountRangeErr, Format(ExpectedParentAmount, 0, '<Precision,2:2><Standard Format,0>')));
        Assert.ExpectedErrorCode('Dialog');
    end;

    local procedure VerifyParentDocLineState(DocumentID: Integer; ExpectedAmount: Decimal; ExpectedIncluded: Boolean)
    var
        ParentIRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
    begin
        FindParentDocLine(DocumentID, ParentIRS1099FormDocLine);
        Assert.AreEqual(ExpectedAmount, ParentIRS1099FormDocLine.Amount, 'The financial amount changed unexpectedly.');
        Assert.AreEqual(ExpectedIncluded, ParentIRS1099FormDocLine."Include In 1099", 'The financial inclusion changed unexpectedly.');
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

    local procedure VerifyRejectedLifecycleUpdate(OriginalIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header")
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        ParentIRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
        CodesSupplementalLine: Record "IRS 1099 Doc. Suppl. Line";
    begin
        Assert.ExpectedError(StrSubstNo(DocumentContextTxt, OriginalIRS1099FormDocHeader.ID));
        Assert.ExpectedError('has submission or correction information, or a recorded send attempt');
        Assert.ExpectedErrorCode('Dialog');
        IRS1099FormDocHeader.Get(OriginalIRS1099FormDocHeader.ID);
        Assert.AreEqual(OriginalIRS1099FormDocHeader.Status, IRS1099FormDocHeader.Status, 'Document status must survive.');
        Assert.AreEqual(OriginalIRS1099FormDocHeader."IRIS Transmission Document ID", IRS1099FormDocHeader."IRIS Transmission Document ID", 'The link must survive.');
        Assert.AreEqual(OriginalIRS1099FormDocHeader."IRIS Submission Status", IRS1099FormDocHeader."IRIS Submission Status", 'Submission status must survive.');
        Assert.AreEqual(OriginalIRS1099FormDocHeader."IRIS Submission ID", IRS1099FormDocHeader."IRIS Submission ID", 'Submission ID must survive.');
        Assert.AreEqual(OriginalIRS1099FormDocHeader."IRIS Record ID", IRS1099FormDocHeader."IRIS Record ID", 'Record ID must survive.');
        Assert.AreEqual(OriginalIRS1099FormDocHeader."IRIS Last Receipt ID", IRS1099FormDocHeader."IRIS Last Receipt ID", 'Last receipt must survive.');
        Assert.AreEqual(OriginalIRS1099FormDocHeader."IRIS Last Accepted Receipt ID", IRS1099FormDocHeader."IRIS Last Accepted Receipt ID", 'Accepted receipt must survive.');
        Assert.AreEqual(OriginalIRS1099FormDocHeader."Allow Correction", IRS1099FormDocHeader."Allow Correction", 'Correction permission must survive.');
        Assert.AreEqual(OriginalIRS1099FormDocHeader."IRIS Needs Correction", IRS1099FormDocHeader."IRIS Needs Correction", 'Correction selection must survive.');
        Assert.AreEqual(OriginalIRS1099FormDocHeader."IRIS Updated Not Sent", IRS1099FormDocHeader."IRIS Updated Not Sent", 'Pending update state must survive.');
        Assert.AreEqual(OriginalIRS1099FormDocHeader."IRIS Corrected", IRS1099FormDocHeader."IRIS Corrected", 'Correction history must survive.');
        Assert.AreEqual(OriginalIRS1099FormDocHeader."IRIS Corrected to Zeros", IRS1099FormDocHeader."IRIS Corrected to Zeros", 'Zero-correction state must survive.');
        VerifyParentDocLineState(IRS1099FormDocHeader.ID, 1500, true);
        FindParentDocLine(IRS1099FormDocHeader.ID, ParentIRS1099FormDocLine);
        Assert.AreEqual(600, ParentIRS1099FormDocLine."Minimum Reportable Amount", 'The stored minimum must not change.');
        Assert.AreEqual(1500, ParentIRS1099FormDocLine."Calculated Amount", 'The calculated amount must not change.');
        VerifySavedTips(IRS1099FormDocHeader.ID, 100);
        CodesSupplementalLine.Get(IRS1099FormDocHeader.ID, 'NEC-01C');
        VerifySupplementalCodes(CodesSupplementalLine);
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

    local procedure VerifyRetainedExcludedCodes(CodesSupplementalLine: Record "IRS 1099 Doc. Suppl. Line")
    begin
        CodesSupplementalLine.Get(CodesSupplementalLine."Document ID", CodesSupplementalLine."Supplemental Box No.");
        VerifySupplementalCodes(CodesSupplementalLine);
        Assert.IsFalse(LibraryIRS1099Document.IsSupplementalReportable(CodesSupplementalLine), 'Zero tips must suppress codes.');
        Assert.IsTrue(LibraryIRS1099Document.GetSupplementalExplanation(CodesSupplementalLine) <> '', 'Retained codes need an exclusion explanation.');
    end;

    local procedure VerifyRoutedDetail(DocumentID: Integer; BoxNo: Code[20]; EntryNo: Integer; Amount: Decimal)
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
        Details: Record "IRS 1099 Form Doc. Line Detail";
    begin
        IRS1099FormDocHeader.Get(DocumentID);
        Details.SetRange("Document ID", DocumentID);
        Details.SetRange("Vendor Ledger Entry No.", EntryNo);
        Details.FindFirst();
        IRS1099FormDocLine.Get(IRS1099FormDocHeader."Period No.", IRS1099FormDocHeader."Vendor No.", IRS1099FormDocHeader."Form No.", DocumentID, Details."Line No.");
        Assert.AreEqual(BoxNo, IRS1099FormDocLine."Form Box No.", 'The ledger detail was assigned to a different form box.');
        Assert.AreEqual(Amount, Details."Calculated Amount", 'The financial detail must follow its exact line.');
    end;

    local procedure VerifySavedTips(DocumentID: Integer; ExpectedAmount: Decimal)
    var
        TipsSupplementalLine: Record "IRS 1099 Doc. Suppl. Line";
    begin
        TipsSupplementalLine.Get(DocumentID, 'NEC-01B');
        Assert.AreEqual(ExpectedAmount, TipsSupplementalLine.Amount, 'The saved breakdown changed unexpectedly.');
        Assert.AreEqual('NEC-01', TipsSupplementalLine."Parent Form Box No.", 'The stored parent must survive lifecycle changes.');
    end;

    local procedure VerifyStoredMinimum(DocumentID: Integer; ExpectedMinimum: Decimal)
    var
        ParentIRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
    begin
        FindParentDocLine(DocumentID, ParentIRS1099FormDocLine);
        Assert.AreEqual(ExpectedMinimum, ParentIRS1099FormDocLine."Minimum Reportable Amount", 'Unselected minimum must remain stored.');
    end;

    local procedure VerifySupplementalCodes(SupplementalLine: Record "IRS 1099 Doc. Suppl. Line")
    begin
        Assert.AreEqual('101', SupplementalLine."Occupation Code 1", 'The first code must remain text.');
        Assert.AreEqual('000', SupplementalLine."Occupation Code 2", 'Leading zeros must not be lost.');
        Assert.AreEqual(0, SupplementalLine.Amount, 'A code row cannot hold money.');
        Assert.AreEqual('NEC-01', SupplementalLine."Parent Form Box No.", 'The definition must assign the parent snapshot.');
    end;

    local procedure VerifySupplementalLinesVisibility(IRS1099FormDocument: TestPage "IRS 1099 Form Document"; ExpectedVisible: Boolean)
    begin
        Assert.AreEqual(ExpectedVisible, IRS1099FormDocument.SupplementalLines.Visible(), 'The supplemental part has unexpected visibility.');
        Assert.AreEqual(not ExpectedVisible, IRS1099FormDocument.ShowSupplementalLines.Visible(), 'The reveal action must be shown only when the part is hidden.');
    end;

    local procedure VerifyDependentEligibilityConfirmation(DocumentID: Integer)
    var
        Question: Text;
    begin
        Question := LibraryVariableStorage.DequeueText();
        Assert.IsTrue(Question.Contains('unselected lines'), 'Dependent eligibility changes require an explicit confirmation.');
        Assert.IsTrue(Question.Contains(Format(DocumentID)), 'The confirmation must identify the affected document.');
        Assert.IsTrue(Question.Contains('NEC-01'), 'The confirmation must identify the unselected income box.');
    end;

    local procedure VerifyUnchangedWithholdingDocument(IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header")
    var
        DocLine: Record "IRS 1099 Form Doc. Line";
    begin
        VerifyParentDocLineState(IRS1099FormDocHeader.ID, 500, true);
        VerifySavedTips(IRS1099FormDocHeader.ID, 100);
        VerifyDocumentLink(IRS1099FormDocHeader.ID, IRS1099FormDocHeader."IRIS Transmission Document ID");
        DocLine.SetRange("Document ID", IRS1099FormDocHeader.ID);
        DocLine.SetRange("Form Box No.", 'NEC-04');
        Assert.IsTrue(DocLine.FindFirst(), 'The cancelled update must preserve the withholding line.');
        Assert.AreEqual(50, DocLine.Amount, 'Declining dependent changes must roll back the selected amount.');
        Assert.IsTrue(DocLine."Include In 1099", 'Declining dependent changes must preserve withholding eligibility.');
    end;

    local procedure VerifyCopiedIncomeState(DocumentID: Integer; ExpectedIncluded: Boolean)
    var
        ParentIRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
    begin
        VerifyParentDocLineState(DocumentID, 750, ExpectedIncluded);
        FindParentDocLine(DocumentID, ParentIRS1099FormDocLine);
        Assert.AreEqual(2000, ParentIRS1099FormDocLine."Minimum Reportable Amount", 'The unselected copied minimum must remain stored.');
        Assert.IsTrue(ParentIRS1099FormDocLine."Manually Changed", 'The unselected copied amount must remain manual.');
        VerifySavedTips(DocumentID, 100);
    end;

    local procedure VerifyWithholdingCreation(var IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; OriginalIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; TransmissionID: Integer)
    begin
        FindReplacementDocument(IRS1099FormDocHeader);
        Assert.AreNotEqual(OriginalIRS1099FormDocHeader.ID, IRS1099FormDocHeader.ID, 'The selected new box must create a replacement.');
        Assert.AreEqual(IRS1099FormDocHeader.Status::Released, IRS1099FormDocHeader.Status, 'The replacement must be released.');
        Assert.IsFalse(IRS1099FormDocHeader."IRIS Updated Not Sent", 'A first-time filing must not acquire a previously sent marker.');
        VerifyCopiedIncomeState(IRS1099FormDocHeader.ID, true);
        VerifyDocumentLink(IRS1099FormDocHeader.ID, TransmissionID);
        OriginalIRS1099FormDocHeader.Get(OriginalIRS1099FormDocHeader.ID);
        Assert.AreEqual(OriginalIRS1099FormDocHeader.Status::Abandoned, OriginalIRS1099FormDocHeader.Status, 'The source must be superseded only after confirmation.');
        VerifyCopiedIncomeState(OriginalIRS1099FormDocHeader.ID, false);
    end;

    local procedure VerifyWithholdingCreationCancellation(OriginalIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header")
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        WithholdingDocumentLine: Record "IRS 1099 Form Doc. Line";
    begin
        IRS1099FormDocHeader.Get(OriginalIRS1099FormDocHeader.ID);
        Assert.AreEqual(OriginalIRS1099FormDocHeader.Status, IRS1099FormDocHeader.Status, 'Declining must roll back source abandonment.');
        VerifyCopiedIncomeState(IRS1099FormDocHeader.ID, false);
        VerifyDocumentLink(IRS1099FormDocHeader.ID, OriginalIRS1099FormDocHeader."IRIS Transmission Document ID");
        IRS1099FormDocHeader.SetRange("Period No.", OriginalIRS1099FormDocHeader."Period No.");
        IRS1099FormDocHeader.SetRange("Vendor No.", OriginalIRS1099FormDocHeader."Vendor No.");
        IRS1099FormDocHeader.SetRange("Form No.", OriginalIRS1099FormDocHeader."Form No.");
        Assert.RecordCount(IRS1099FormDocHeader, 1);
        WithholdingDocumentLine.SetRange("Document ID", OriginalIRS1099FormDocHeader.ID);
        WithholdingDocumentLine.SetRange("Form Box No.", 'NEC-04');
        Assert.RecordIsEmpty(WithholdingDocumentLine);
    end;

    local procedure VerifySupplementalCopySource(DocumentID: Integer)
    var
        SourceDocHeader: Record "IRS 1099 Form Doc. Header";
    begin
        VerifyAbandonedSource(DocumentID, 100);
        VerifySupplementalCopyTarget(DocumentID, 100, 2, '101', '000');
        VerifyParentDocLineState(DocumentID, 5000, true);
        SourceDocHeader.Get(DocumentID);
        Assert.AreEqual('SAVED-SOURCE-RECEIPT', SourceDocHeader."IRIS Last Receipt ID", 'Copying must not change source filing identity.');
    end;

    local procedure VerifySupplementalCopyTarget(DocumentID: Integer; TipsAmount: Decimal; LineCount: Integer; FirstOccupationCode: Text[3]; SecondOccupationCode: Text[3])
    var
        SupplLine: Record "IRS 1099 Doc. Suppl. Line";
    begin
        SupplLine.SetRange("Document ID", DocumentID);
        Assert.RecordCount(SupplLine, LineCount);
        VerifySavedTips(DocumentID, TipsAmount);
        SupplLine.Get(DocumentID, 'NEC-01C');
        Assert.AreEqual(FirstOccupationCode, SupplLine."Occupation Code 1", 'The first occupation code was not preserved.');
        Assert.AreEqual(SecondOccupationCode, SupplLine."Occupation Code 2", 'The second occupation code was not preserved.');
        Assert.AreEqual(0, SupplLine.Amount, 'Occupation codes must not acquire an amount.');
        Assert.AreEqual('NEC-01', SupplLine."Parent Form Box No.", 'The copied codes must use the target parent.');
    end;

    local procedure VerifyUnchangedSupplementalCopyTarget(DocumentID: Integer)
    var
        SupplLine: Record "IRS 1099 Doc. Suppl. Line";
    begin
        VerifySupplementalCopyTarget(DocumentID, 25, 3, '000', '101');
        SupplLine.Get(DocumentID, 'NEC-01D');
        Assert.AreEqual(50, SupplLine.Amount, 'Cancelling or rejecting copying must preserve the target-only line.');
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
        UpdatePage.Filter.SetFilter("Form Box No.", '');
        UpdatePage.First();
        repeat
            UpdatePage."Process Line".SetValue(UpdatePage."Form Box No.".Value = 'NEC-04');
        until not UpdatePage.Next();
        UpdatePage.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure CancelDocumentUpdateHandler(var UpdatePage: TestPage "IRS 1099 Form Doc. Update")
    begin
        UpdatePage.Cancel().Invoke();
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
    procedure AcceptDependentEligibilityHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        LibraryVariableStorage.Enqueue(Question);
        Reply := true;
    end;

    [ConfirmHandler]
    procedure DeclineDependentEligibilityHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        LibraryVariableStorage.Enqueue(Question);
        Reply := false;
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

    [ModalPageHandler]
    procedure SelectSupplementalSourceHandler(var SourceDocuments: TestPage "IRS 1099 Form Documents")
    var
        SourceDocHeader: Record "IRS 1099 Form Doc. Header";
    begin
        SourceDocHeader.Get(LibraryVariableStorage.DequeueInteger());
        SourceDocuments.GoToRecord(SourceDocHeader);
        LibraryVariableStorage.Enqueue(SourceDocuments.ID.Visible());
        SourceDocuments.OK().Invoke();
    end;

    [MessageHandler]
    procedure MessageHandler(Text: Text)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Text);
    end;

    [EventSubscriber(ObjectType::Table, Database::"IRS 1099 Form Doc. Header", 'OnAddPeriodFormVendUniquenessFilters', '', false, false)]
    local procedure AllowMultipleRoutingDocuments(var IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header")
    begin
        IRS1099FormDocHeader.SetRange(ID, 0);
    end;
}