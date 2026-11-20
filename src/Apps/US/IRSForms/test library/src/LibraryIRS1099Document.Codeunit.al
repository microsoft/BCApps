// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Payables;

codeunit 148001 "Library IRS 1099 Document"
{
    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryIRSReportingPeriod: Codeunit "Library IRS Reporting Period";
        LibraryIRS1099FormBox: Codeunit "Library IRS 1099 Form Box";
        Assert: Codeunit "Assert";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        Supplemental: Codeunit "IRS 1099 Supplemental";

    procedure CreateFormDocuments(ReportingDate: Date)
    begin
        CreateFormDocuments(ReportingDate, ReportingDate, '', '');
    end;

    procedure CreateSupplementalDocument(var DocHeader: Record "IRS 1099 Form Doc. Header"; FormNo: Code[20])
    var
        IRS1099Form: Record "IRS 1099 Form";
        FormBox: Record "IRS 1099 Form Box";
        DocLine: Record "IRS 1099 Form Doc. Line";
        PeriodNo: Code[20];
        ParentBoxNo: Code[20];
    begin
        PeriodNo := '2026';
        LibraryIRSReportingPeriod.CreateSpecificReportingPeriod(PeriodNo, DMY2Date(1, 1, 2026), DMY2Date(31, 12, 2026));
        IRS1099Form."Period No." := PeriodNo;
        IRS1099Form."No." := FormNo;
        IRS1099Form.Insert(true);
        if FormNo = 'NEC' then
            ParentBoxNo := 'NEC-01'
        else
            ParentBoxNo := 'MISC-03';
        FormBox."Period No." := PeriodNo;
        FormBox."Form No." := FormNo;
        FormBox."No." := ParentBoxNo;
        FormBox.Insert(true);
        DocHeader.Init();
        DocHeader."Period No." := PeriodNo;
        DocHeader."Vendor No." := LibraryPurchase.CreateVendorNo();
        DocHeader."Form No." := FormNo;
        DocHeader.Insert(true);
        MockFormDocumentLineForVendor(DocLine, DocHeader.ID, PeriodNo, DocHeader."Vendor No.", FormNo, ParentBoxNo);
        DocLine.Validate(Amount, 5000);
        DocLine.Modify(true);
        if FormNo = 'NEC' then begin
            CreateSupplementalDefinition(PeriodNo, FormNo, 'NEC-01B');
            CreateSupplementalDefinition(PeriodNo, FormNo, 'NEC-01C');
            CreateSupplementalDefinition(PeriodNo, FormNo, 'NEC-01D');
        end else begin
            CreateSupplementalDefinition(PeriodNo, FormNo, 'MISC-13A');
            CreateSupplementalDefinition(PeriodNo, FormNo, 'MISC-13B');
            CreateSupplementalDefinition(PeriodNo, FormNo, 'MISC-14');
        end;
    end;

    procedure CreateSupplementalDefinition(PeriodNo: Code[20]; FormNo: Code[20]; BoxNo: Code[20])
    var
        ReportingPeriod: Record "IRS Reporting Period";
        IRS1099SupplBox: Record "IRS 1099 Suppl. Box";
    begin
        IRS1099SupplBox."Period No." := PeriodNo;
        IRS1099SupplBox."Form No." := FormNo;
        IRS1099SupplBox."No." := BoxNo;
        ReportingPeriod.Get(PeriodNo);
        Supplemental.GetMapping(Format(Date2DMY(ReportingPeriod."Starting Date", 3), 0, 9), FormNo, BoxNo, IRS1099SupplBox."Parent Form Box No.",
            IRS1099SupplBox."XML Element Name", IRS1099SupplBox."Value Type");
        IRS1099SupplBox.Description := BoxNo;
        IRS1099SupplBox.Insert(true);
    end;

    procedure FilterAvailableSupplementalBoxes(var IRS1099SupplBox: Record "IRS 1099 Suppl. Box"; DocumentID: Integer)
    begin
        Supplemental.FilterAvailableDefinitions(IRS1099SupplBox, DocumentID);
    end;

    procedure ReleaseDocument(var DocHeader: Record "IRS 1099 Form Doc. Header")
    var
        FormDocument: Codeunit "IRS 1099 Form Document";
    begin
        FormDocument.Release(DocHeader);
    end;

    procedure UpdateTransmission(var Transmission: Record "Transmission IRIS")
    var
        ProcessTransmission: Codeunit "Process Transmission IRIS";
    begin
        ProcessTransmission.Update(Transmission);
    end;

    procedure GetDocumentUpdateCandidates(var TempDocLine: Record "IRS 1099 Form Doc. Line" temporary; var TempDetails: Record "IRS 1099 Form Doc. Line Detail" temporary; PeriodNo: Code[20])
    var
        ProcessTransmission: Codeunit "Process Transmission IRIS";
    begin
        Assert.IsTrue(StrLen(PeriodNo) <= 4, 'Transmission update fixtures require a four-character reporting period.');
        ProcessTransmission.GetIRS1099FormDocsToUpdate(TempDocLine, TempDetails, CopyStr(PeriodNo, 1, 4));
    end;

    procedure IsSupplementalReportable(SupplLine: Record "IRS 1099 Doc. Suppl. Line"): Boolean
    begin
        exit(Supplemental.IsReportable(SupplLine));
    end;

    procedure GetStatementDataset(DocHeader: Record "IRS 1099 Form Doc. Header") Lines: JsonArray
    var
        TempReportLine: Record "IRS 1099 Report Line";
        Dataset: Codeunit "IRS 1099 Dataset";
        Line: JsonObject;
    begin
        Dataset.Get1099Dataset(DocHeader, TempReportLine);
        if TempReportLine.FindSet() then
            repeat
                Clear(Line);
                Line.Add('name', TempReportLine.Name);
                Line.Add('value', TempReportLine.Value);
                Lines.Add(Line);
            until TempReportLine.Next() = 0;
    end;

    procedure RecalculateIncludeIn1099(DocumentID: Integer)
    begin
        Supplemental.RecalculateIncludeIn1099(DocumentID);
    end;

    procedure ApplyDocumentCreationCandidates(var TempDocLine: Record "IRS 1099 Form Doc. Line" temporary; var TempDetails: Record "IRS 1099 Form Doc. Line Detail" temporary) NewDocumentIDs: List of [Integer]
    var
        ProcessTransmission: Codeunit "Process Transmission IRIS";
    begin
        exit(ProcessTransmission.UpdateIRS1099FormDocuments(TempDocLine, TempDetails));
    end;

    procedure GetSupplementalExplanation(SupplLine: Record "IRS 1099 Doc. Suppl. Line"): Text
    begin
        exit(Supplemental.GetExclusionExplanation(SupplLine));
    end;

    procedure CreateFormDocuments(StartingDate: Date; EndingDate: Date)
    begin
        CreateFormDocuments(StartingDate, EndingDate, '', '');
    end;

    procedure CreateFormDocuments(StartingDate: Date; EndingDate: Date; VendorNo: Code[20])
    begin
        CreateFormDocuments(StartingDate, EndingDate, VendorNo, '');
    end;

    procedure CreateFormDocuments(StartingDate: Date; EndingDate: Date; VendorNo: Code[20]; FormNo: Code[20])
    begin
        CreateFormDocuments(StartingDate, EndingDate, VendorNo, FormNo, false);
    end;

    procedure CreateFormDocuments(StartingDate: Date; EndingDate: Date; VendorNo: Code[20]; FormNo: Code[20]; Replace: Boolean)
    var
        TempIRS1099CalcParameters: Record "IRS 1099 Calc. Params";
        IRS1099FormDocument: Codeunit "IRS 1099 Form Document";
    begin
        TempIRS1099CalcParameters."Period No." := LibraryIRSReportingPeriod.GetReportingPeriod(StartingDate, EndingDate);
        TempIRS1099CalcParameters."Vendor No." := VendorNo;
        TempIRS1099CalcParameters."Form No." := FormNo;
        TempIRS1099CalcParameters.Replace := Replace;
        IRS1099FormDocument.CreateFormDocs(TempIRS1099CalcParameters);
    end;

    procedure CreateFormDocuments(var TempVendFormBoxBuffer: Record "IRS 1099 Vend. Form Box Buffer" temporary);
    var
        TempDummyIRS1099CalcParameters: Record "IRS 1099 Calc. Params";
    begin
        CreateFormDocuments(TempVendFormBoxBuffer, TempDummyIRS1099CalcParameters);
    end;

    procedure CreateFormDocuments(var TempVendFormBoxBuffer: Record "IRS 1099 Vend. Form Box Buffer" temporary; IRS1099CalcParameters: Record "IRS 1099 Calc. Params");
    var
        IRS1099FormDocImpl: Codeunit "IRS 1099 Form Docs Impl.";
    begin
        IRS1099FormDocImpl.CreateFormDocs(TempVendFormBoxBuffer, IRS1099CalcParameters);
    end;

    procedure CreateAndPostPurchaseDocument(DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; Year: Integer; FormNo: Code[20]; FormBoxNo: Code[20]) PostedDocNo: Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PostingDate: Date;
        i: Integer;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PostingDate := LibraryRandom.RandDateFrom(DMY2Date(1, 1, Year), 360);
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Validate("Document Date", PostingDate);
        PurchaseHeader.Validate("IRS 1099 Reporting Period", Format(Year));
        PurchaseHeader.Validate("IRS 1099 Form No.", FormNo);
        PurchaseHeader.Validate("IRS 1099 Form Box No.", FormBoxNo);
        PurchaseHeader.Modify(true);

        for i := 1 to 2 do begin
            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, "Purchase Line Type"::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(10, 20));
            PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));
            PurchaseLine.Modify(true);
        end;

        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    procedure MockInvVendLedgEntry(var VendLedgEntry: Record "Vendor Ledger Entry"; StartingDate: Date; EndingDate: Date; VendorNo: Code[20]; FormNo: Code[20]; FormBoxNo: Code[20]): Integer
    begin
        MockVendLedgEntry(VendLedgEntry, "Gen. Journal Document Type"::Invoice, StartingDate, EndingDate, VendorNo, FormNo, FormBoxNo);
        MockInitialDtldLedgEntry(VendLedgEntry."Entry No.", VendorNo, -LibraryRandom.RandDec(100, 2));
    end;

    procedure MockPmtVendLedgEntry(var VendLedgEntry: Record "Vendor Ledger Entry"; StartingDate: Date; EndingDate: Date; VendorNo: Code[20]; FormNo: Code[20]; FormBoxNo: Code[20]): Integer
    begin
        MockVendLedgEntry(VendLedgEntry, "Gen. Journal Document Type"::Payment, StartingDate, EndingDate, VendorNo, FormNo, FormBoxNo);
        MockInitialDtldLedgEntry(VendLedgEntry."Entry No.", VendorNo, LibraryRandom.RandDec(100, 2));
    end;

    procedure MockVendLedgEntry(var VendLedgEntry: Record "Vendor Ledger Entry"; DocType: Enum "Gen. Journal Document Type"; StartingDate: Date; EndingDate: Date; VendorNo: Code[20]; FormNo: Code[20]; FormBoxNo: Code[20]): Integer
    begin
        VendLedgEntry."Entry No." := LibraryUtility.GetNewRecNo(VendLedgEntry, VendLedgEntry.FieldNo("Entry No."));
        VendLedgEntry."Document Type" := DocType;
        VendLedgEntry."Vendor No." := VendorNo;
        VendLedgEntry."Posting Date" := StartingDate;
        VendLedgEntry.Insert();
    end;

    procedure MockVendLedgEntryWithIRSData(var VendorLedgerEntry: Record "Vendor Ledger Entry"; StartingDate: Date; EndingDate: Date; FormNo: Code[20]; FormBoxNo: Code[20]; Amount: Decimal)
    begin
        MockVendLedgEntryWithIRSDataCustom(VendorLedgerEntry, "Gen. Journal Document Type"::" ", StartingDate, EndingDate, FormNo, FormBoxNo, Amount);
    end;

    procedure MockInvVendLedgEntryWithIRSData(var VendorLedgerEntry: Record "Vendor Ledger Entry"; StartingDate: Date; EndingDate: Date; FormNo: Code[20]; FormBoxNo: Code[20]; Amount: Decimal)
    begin
        MockVendLedgEntryWithIRSDataCustom(VendorLedgerEntry, "Gen. Journal Document Type"::Invoice, StartingDate, EndingDate, FormNo, FormBoxNo, Amount);
    end;

    procedure MockCrMemoVendLedgEntryWithIRSData(var VendorLedgerEntry: Record "Vendor Ledger Entry"; StartingDate: Date; EndingDate: Date; FormNo: Code[20]; FormBoxNo: Code[20]; Amount: Decimal)
    begin
        MockVendLedgEntryWithIRSDataCustom(VendorLedgerEntry, "Gen. Journal Document Type"::"Credit Memo", StartingDate, EndingDate, FormNo, FormBoxNo, Amount);
    end;

    procedure MockVendLedgEntryWithIRSDataCustom(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocType: Enum "Gen. Journal Document Type"; StartingDate: Date; EndingDate: Date; FormNo: Code[20]; FormBoxNo: Code[20]; Amount: Decimal)
    begin
        VendorLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(VendorLedgerEntry, VendorLedgerEntry.FieldNo("Entry No."));
        VendorLedgerEntry."Document Type" := DocType;
        VendorLedgerEntry."IRS 1099 Subject For Reporting" := true;
        VendorLedgerEntry."IRS 1099 Reporting Period" := LibraryIRSReportingPeriod.GetReportingPeriod(StartingDate, EndingDate);
        VendorLedgerEntry."IRS 1099 Form No." := FormNo;
        VendorLedgerEntry."IRS 1099 Form Box No." := FormBoxNo;
        vendorLedgerEntry."IRS 1099 Reporting Amount" := Amount;
        VendorLedgerEntry.Insert();
        MockInitialDtldLedgEntry(VendorLedgerEntry."Entry No.", '', Amount);
    end;

    procedure MockFormDocumentForVendor(PeriodNo: Code[20]; VendNo: Code[20]; FormNo: Code[20]; Status: Enum "IRS 1099 Form Doc. Status"): Integer
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        NewId: Integer;
    begin
        if IRS1099FormDocHeader.FindLast() then
            NewId := IRS1099FormDocHeader.ID;
        NewId += 1;
        IRS1099FormDocHeader.Id := NewId;
        IRS1099FormDocHeader."Period No." := PeriodNo;
        IRS1099FormDocHeader."Vendor No." := VendNo;
        IRS1099FormDocHeader."Form No." := FormNo;
        IRS1099FormDocHeader.Status := Status;
        IRS1099FormDocHeader.Insert();
        exit(IRS1099FormDocHeader.ID);
    end;

    procedure MockFormDocumentLineForVendor(DocId: Integer; PeriodNo: Code[20]; VendNo: Code[20]; FormNo: Code[20]; FormBoxNo: Code[20])
    var
        IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
    begin
        MockFormDocumentLineForVendor(IRS1099FormDocLine, DocId, PeriodNo, VendNo, FormNo, FormBoxNo);
    end;

    procedure MockFormDocumentLineForVendor(var IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line"; DocId: Integer; PeriodNo: Code[20]; VendNo: Code[20]; FormNo: Code[20]; FormBoxNo: Code[20])
    begin
        IRS1099FormDocLine."Document ID" := DocId;
        IRS1099FormDocLine."Period No." := PeriodNo;
        IRS1099FormDocLine."Vendor No." := VendNo;
        IRS1099FormDocLine."Form No." := FormNo;
        IRS1099FormDocLine."Form Box No." := FormBoxNo;
        IRS1099FormDocLine."Calculated Amount" := LibraryRandom.RandDec(100, 2);
        IRS1099FormDocLine.Amount := IRS1099FormDocLine."Calculated Amount";
        IRS1099FormDocLine.Insert();
    end;

    procedure MockVendorFormBoxBuffer(var TempIRS1099VendFormBoxBuffer: Record "IRS 1099 Vend. Form Box Buffer" temporary; var EntryNo: Integer; PeriodNo: Code[20]; VendNo: Code[20]; FormNo: Code[20]; FormBoxNo: Code[20])
    var
        BufferEntryNo: Integer;
    begin
        TempIRS1099VendFormBoxBuffer.Reset();
        if TempIRS1099VendFormBoxBuffer.FindLast() then
            BufferEntryNo := TempIRS1099VendFormBoxBuffer."Entry No."
        else
            BufferEntryNo := 0;
        BufferEntryNo += 1;
        TempIRS1099VendFormBoxBuffer."Entry No." := BufferEntryNo;
        TempIRS1099VendFormBoxBuffer."Period No." := PeriodNo;
        TempIRS1099VendFormBoxBuffer."Vendor No." := VendNo;
        TempIRS1099VendFormBoxBuffer."Form No." := FormNo;
        TempIRS1099VendFormBoxBuffer."Form Box No." := FormBoxNo;
        TempIRS1099VendFormBoxBuffer."Buffer Type" := TempIRS1099VendFormBoxBuffer."Buffer Type"::Amount;
        TempIRS1099VendFormBoxBuffer.Amount := LibraryRandom.RandDec(100, 2);
        TempIRS1099VendFormBoxBuffer."Reporting Amount" := LibraryRandom.RandDec(100, 2);
        TempIRS1099VendFormBoxBuffer."Include In 1099" := true;
        TempIRS1099VendFormBoxBuffer.Insert(true);
        EntryNo := LibraryIRS1099FormBox.MockConnectedEntryForVendFormBoxBuffer(TempIRS1099VendFormBoxBuffer);
    end;

    procedure FindIRS1099FormDocHeader(var IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; PeriodNo: Code[20]; VendNo: Code[20]; FormNo: Code[20])
    begin
        IRS1099FormDocHeader.SetRange("Period No.", PeriodNo);
        IRS1099FormDocHeader.SetRange("Vendor No.", VendNo);
        IRS1099FormDocHeader.SetRange("Form No.", FormNo);
        IRS1099FormDocHeader.FindFirst();
    end;

    procedure FindIRS1099FormDocLine(var IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line"; PeriodNo: Code[20]; VendNo: Code[20]; FormNo: Code[20]; FormBoxNo: Code[20])
    begin
        IRS1099FormDocLine.SetRange("Period No.", PeriodNo);
        IRS1099FormDocLine.SetRange("Vendor No.", VendNo);
        IRS1099FormDocLine.SetRange("Form No.", FormNo);
        IRS1099FormDocLine.SetRange("Form Box No.", FormBoxNo);
        IRS1099FormDocLine.FindFirst();
    end;

    local procedure MockInitialDtldLedgEntry(VendorLedgerEntryNo: Integer; VendorNo: Code[20]; Amount: Decimal)
    begin
        MockDtldLedgEntry(VendorLedgerEntryNo, "Detailed CV Ledger Entry Type"::"Initial Entry", VendorNo, Amount);
    end;

    local procedure MockDtldLedgEntry(VendorLedgerEntryNo: Integer; EntryType: Enum "Detailed CV Ledger Entry Type"; VendorNo: Code[20]; Amount: Decimal)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgEntry."Entry No." := LibraryUtility.GetNewRecNo(DetailedVendorLedgEntry, DetailedVendorLedgEntry.FieldNo("Entry No."));
        DetailedVendorLedgEntry."Vendor Ledger Entry No." := VendorLedgerEntryNo;
        DetailedVendorLedgEntry."Ledger Entry Amount" := true;
        DetailedVendorLedgEntry."Entry Type" := EntryType;
        DetailedVendorLedgEntry."Vendor No." := VendorNo;
        DetailedVendorLedgEntry.Amount := Amount;
        DetailedVendorLedgEntry."Amount (LCY)" := Amount;
        DetailedVendorLedgEntry.Insert();
    end;

    procedure PostPaymentAppliedToInvoice(VendNo: Code[20]; InvNo: Code[20]; Amount: Decimal)
    begin
        PostPaymentAppliedToInvoiceCustom(
            WorkDate(), "Gen. Journal Document Type"::Payment, VendNo, "Gen. Journal Document Type"::Invoice, InvNo, Amount);
    end;

    procedure PostPaymentAppliedToInvoice(PostingDate: Date; VendNo: Code[20]; InvNo: Code[20]; Amount: Decimal)
    begin
        PostPaymentAppliedToInvoiceCustom(
            PostingDate, "Gen. Journal Document Type"::Payment, VendNo, "Gen. Journal Document Type"::Invoice, InvNo, Amount);
    end;

    procedure PostRefundAppliedToCreditMemo(VendNo: Code[20]; CrMemoNo: Code[20]; Amount: Decimal)
    begin
        PostPaymentAppliedToInvoiceCustom(
            WorkDate(), "Gen. Journal Document Type"::Refund, VendNo, "Gen. Journal Document Type"::"Credit Memo", CrMemoNo, Amount);
    end;

    procedure PostRefundAppliedToCreditMemo(PostingDate: Date; VendNo: Code[20]; CrMemoNo: Code[20]; Amount: Decimal)
    begin
        PostPaymentAppliedToInvoiceCustom(
            PostingDate, "Gen. Journal Document Type"::Refund, VendNo, "Gen. Journal Document Type"::"Credit Memo", CrMemoNo, Amount);
    end;

    local procedure PostPaymentAppliedToInvoiceCustom(PostingDate: Date; DocType: Enum "Gen. Journal Document Type"; VendNo: Code[20]; AppliesToDocType: Enum "Gen. Journal Document Type"; AppliedToDocNo: Code[20]; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
            GenJournalLine, DocType, GenJournalLine."Account Type"::Vendor, VendNo, Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Applies-to Doc. Type", AppliesToDocType);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliedToDocNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    procedure VerifyIRS1099CodeInPurchaseHeader(PurchaseHeader: Record "Purchase Header"; FormNo: Code[20]; FormBoxNo: Code[20])
    begin
        PurchaseHeader.TestField("IRS 1099 Reporting Period", LibraryIRSReportingPeriod.GetReportingPeriod(PurchaseHeader."Posting Date"));
        PurchaseHeader.TestField("IRS 1099 Form No.", FormNo);
        PurchaseHeader.TestField("IRS 1099 Form Box No.", FormBoxNo);
    end;

    procedure VerifyIRSDataInVendorLedgerEntry(VendLedgEntry: Record "Vendor Ledger Entry"; StartingDate: Date; EndingDate: Date; FormNo: Code[20]; FormBoxNo: Code[20]; Amount: Decimal)
    begin
        VendLedgEntry.TestField("IRS 1099 Subject For Reporting", true);
        //VendLedgEntry.TestField("IRS 1099 Reporting Period");
        VendLedgEntry.TestField("IRS 1099 Form No.", FormNo);
        VendLedgEntry.TestField("IRS 1099 Form Box No.", FormBoxNo);
        VendLedgEntry.TestField("IRS 1099 Reporting Amount", Amount);
    end;

    procedure VerifyFormDocumentsCount(ExpectedCount: Integer)
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
    begin
        Assert.RecordCount(IRS1099FormDocHeader, ExpectedCount);
    end;

    procedure VerifyNumberOfLinesInFormDocument(StartingDate: Date; EndingDate: Date; VendorNo: Code[20]; FormNo: Code[20]; ExpectedCount: Integer)
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
    begin
        IRS1099FormDocHeader.SetRange("Period No.", LibraryIRSReportingPeriod.GetReportingPeriod(StartingDate, EndingDate));
        IRS1099FormDocHeader.SetRange("Vendor No.", VendorNo);
        IRS1099FormDocHeader.SetRange("Form No.", FormNo);
        IRS1099FormDocHeader.FindFirst();
        IRS1099FormDocLine.SetRange("Period No.", IRS1099FormDocHeader."Period No.");
        IRS1099FormDocLine.SetRange("Vendor No.", IRS1099FormDocHeader."Vendor No.");
        IRS1099FormDocLine.SetRange("Form No.", IRS1099FormDocHeader."Form No.");
        Assert.RecordCount(IRS1099FormDocLine, ExpectedCount);
    end;

    procedure DeleteFormDocuments()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
    begin
        IRS1099FormDocHeader.ModifyAll(Status, Enum::"IRS 1099 Form Doc. Status"::Open, false);
        IRS1099FormDocHeader.DeleteAll(true);
    end;

}
