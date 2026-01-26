// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;
using System.Reflection;

codeunit 10757 "SII Recreate Missing Entries"
{

    trigger OnRun()
    var
        SIISetup: Record "SII Setup";
        TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary;
        TempCustLedgEntry: Record "Cust. Ledger Entry" temporary;
        TempDetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry" temporary;
        TempDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry" temporary;
    begin
        if not SIISetup.IsEnabled() then
            exit;

        GetSourceEntries(
          TempVendorLedgerEntry, TempCustLedgEntry, TempDetailedVendorLedgEntry, TempDetailedCustLedgEntry, true, SIISetup."Starting Date");
    end;

    var
        Window: Dialog;
        CollectEntriesMsg: Label 'Collecting entries to handle';
        CreateRequestMsg: Label 'Creating missing SII entries';
        ProgressMsg: Label 'Processing #1##########\@2@@@@@@@@@@', Comment = '1 - table name, such as Vendor/Customer Ledger Entry or Detailed Vendor/Customer Ledger Entry; 2 - progress.';
        JobType: Option HandlePending,HandleCommError,InitialUpload;
        RecreateMissingEntryJobTxt: Label 'Recreating missing SII entries';
        EntriesMissingTxt: Label '%1 SII entries missing', Comment = '%1 - number';
        MissingEntriesRecreateTxt: Label '%1 missing entries have been recreated', Comment = '%1 - number';

    [Scope('OnPrem')]
    procedure UploadMissingSIIDocuments(var TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary; var TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary; var TempDetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry" temporary; var TempDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry" temporary)
    var
        SIIMissingEntriesState: Record "SII Missing Entries State";
        SIIJobManagement: Codeunit "SII Job Management";
        EntriesMissing: Integer;
    begin
        SIIMissingEntriesState.Initialize();
        EntriesMissing := SIIMissingEntriesState."Entries Missing";
        UploadMissingVendInvoices(TempVendorLedgerEntry, SIIMissingEntriesState."Last VLE No.");
        UploadMissingVendPayments(TempDetailedVendorLedgEntry, SIIMissingEntriesState."Last DVLE No.");
        UploadMissingCustInvoices(TempCustLedgerEntry, SIIMissingEntriesState."Last CLE No.");
        UploadMissingCustPayments(TempDetailedCustLedgEntry, SIIMissingEntriesState."Last DCLE No.");
        SIIMissingEntriesState."Entries Missing" := 0;
        SIIMissingEntriesState.Modify();
        SIIJobManagement.RenewJobQueueEntry(JobType::HandlePending);
        SendTraceTagOn(StrSubstNo(MissingEntriesRecreateTxt, Format(EntriesMissing)));
    end;

    local procedure UploadMissingVendInvoices(var TempVendLedgerEntry: Record "Vendor Ledger Entry" temporary; var LastEntryNo: Integer)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIJobUploadPendingDocs: Codeunit "SII Job Upload Pending Docs.";
        TotalRecNo: Integer;
        RecNo: Integer;
    begin
        if TempVendLedgerEntry.FindSet() then begin
            SetWindowSource(TotalRecNo, CreateRequestMsg, TempVendLedgerEntry);
            repeat
                UpdateWindowProgress(RecNo, TotalRecNo);
                VendorLedgerEntry := TempVendLedgerEntry;
                SIIJobUploadPendingDocs.CreateSIIRequestForVendLedgEntry(VendorLedgerEntry);
            until TempVendLedgerEntry.Next() = 0;
            CloseWindow();
            LastEntryNo := TempVendLedgerEntry."Entry No.";
        end;
    end;

    local procedure UploadMissingVendPayments(var TempDetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry" temporary; var LastEntryNo: Integer)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        SIIJobUploadPendingDocs: Codeunit "SII Job Upload Pending Docs.";
        TotalRecNo: Integer;
        RecNo: Integer;
    begin
        if TempDetailedVendorLedgEntry.FindSet() then begin
            SetWindowSource(TotalRecNo, CreateRequestMsg, TempDetailedVendorLedgEntry);
            repeat
                UpdateWindowProgress(RecNo, TotalRecNo);
                DetailedVendorLedgEntry := TempDetailedVendorLedgEntry;
                SIIJobUploadPendingDocs.CreateSIIRequestForDtldVendLedgEntry(DetailedVendorLedgEntry);
            until TempDetailedVendorLedgEntry.Next() = 0;
            CloseWindow();
            LastEntryNo := TempDetailedVendorLedgEntry."Entry No.";
        end;
    end;

    local procedure UploadMissingCustInvoices(var TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary; var LastEntryNo: Integer)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIJobUploadPendingDocs: Codeunit "SII Job Upload Pending Docs.";
        TotalRecNo: Integer;
        RecNo: Integer;
    begin
        if TempCustLedgerEntry.FindSet() then begin
            SetWindowSource(TotalRecNo, CreateRequestMsg, TempCustLedgerEntry);
            repeat
                UpdateWindowProgress(RecNo, TotalRecNo);
                CustLedgerEntry := TempCustLedgerEntry;
                SIIJobUploadPendingDocs.CreateSIIRequestForCustLedgEntry(CustLedgerEntry);
            until TempCustLedgerEntry.Next() = 0;
            CloseWindow();
            LastEntryNo := TempCustLedgerEntry."Entry No.";
        end;
    end;

    local procedure UploadMissingCustPayments(var TempDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry" temporary; var LastEntryNo: Integer)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        SIIJobUploadPendingDocs: Codeunit "SII Job Upload Pending Docs.";
        TotalRecNo: Integer;
        RecNo: Integer;
    begin
        if TempDetailedCustLedgEntry.FindSet() then begin
            SetWindowSource(TotalRecNo, CreateRequestMsg, TempDetailedCustLedgEntry);
            repeat
                UpdateWindowProgress(RecNo, TotalRecNo);
                DetailedCustLedgEntry := TempDetailedCustLedgEntry;
                SIIJobUploadPendingDocs.CreateSIIRequestForDtldCustLedgEntry(DetailedCustLedgEntry);
            until TempDetailedCustLedgEntry.Next() = 0;
            CloseWindow();
            LastEntryNo := TempDetailedCustLedgEntry."Entry No.";
        end;
    end;

    local procedure RequestNeedsToBeCreated(PostingDate: Date; DocSource: Enum "SII Doc. Upload State Document Source"; EntryNo: Integer): Boolean
    var
        SIIInitialDocUpload: Codeunit "SII Initial Doc. Upload";
    begin
        exit(
          (not SIIInitialDocUpload.DateWithinInitialUploadPeriod(PostingDate)) and
          SIIDocUploadStateDoesNotExist(DocSource, EntryNo));
    end;

    local procedure SIIDocUploadStateDoesNotExist(DocSource: Enum "SII Doc. Upload State Document Source"; EntryNo: Integer): Boolean
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        SIIDocUploadState.SetRange("Document Source", DocSource);
        SIIDocUploadState.SetRange("Entry No", EntryNo);
        exit(SIIDocUploadState.IsEmpty);
    end;

    local procedure GetMaxDate(Date1: Date; Date2: Date): Date
    begin
        if Date1 > Date2 then
            exit(Date1);
        exit(Date2);
    end;

    procedure GetMissingVendInvoices(var TempVendLedgerEntry: Record "Vendor Ledger Entry" temporary; var LastEntryNo: Integer; RecreateFromDate: Date)
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIInitialDocUpload: Codeunit "SII Initial Doc. Upload";
        TotalRecNo: Integer;
        RecNo: Integer;
    begin
        TempVendLedgerEntry.Reset();
        TempVendLedgerEntry.DeleteAll();

        if LastEntryNo <> 0 then
            VendLedgerEntry.SetFilter("Entry No.", '>%1', LastEntryNo);
        VendLedgerEntry.SetFilter(
          "Document Type", '%1|%2', VendLedgerEntry."Document Type"::Invoice, VendLedgerEntry."Document Type"::"Credit Memo");
        VendLedgerEntry.SetFilter(
          "Posting Date", '>%1', GetMaxDate(SIIInitialDocUpload.GetInitialEndDate(), CalcDate('<-1D>', RecreateFromDate)));
        VendLedgerEntry.SetRange("Do Not Send To SII", false);
        if VendLedgerEntry.FindSet() then begin
            SetWindowSource(TotalRecNo, CollectEntriesMsg, VendLedgerEntry);
            repeat
                UpdateWindowProgress(RecNo, TotalRecNo);
                if RequestNeedsToBeCreated(VendLedgerEntry."Posting Date", SIIDocUploadState."Document Source"::"Vendor Ledger",
                     VendLedgerEntry."Entry No.")
                then begin
                    TempVendLedgerEntry.Init();
                    TempVendLedgerEntry := VendLedgerEntry;
                    TempVendLedgerEntry.Insert();
                end;
            until VendLedgerEntry.Next() = 0;
            LastEntryNo := VendLedgerEntry."Entry No.";
            CloseWindow();
        end;
    end;

    procedure GetMissingDetailedVendLedgerEntries(var TempDetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry" temporary; var LastEntryNo: Integer; RecreateFromDate: Date)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        SIIDocUploadState: Record "SII Doc. Upload State";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIInitialDocUpload: Codeunit "SII Initial Doc. Upload";
        DataTypeManagement: Codeunit "Data Type Management";
        SIIManagement: Codeunit "SII Management";
        DetailedVendorLedgerRecRef: RecordRef;
        TotalRecNo: Integer;
        RecNo: Integer;
    begin
        TempDetailedVendorLedgEntry.Reset();
        TempDetailedVendorLedgEntry.DeleteAll();

        if LastEntryNo <> 0 then
            DetailedVendorLedgEntry.SetFilter("Entry No.", '>%1', LastEntryNo);
        DetailedVendorLedgEntry.SetFilter(
          "Document Type", '%1|%2', DetailedVendorLedgEntry."Document Type"::Payment, DetailedVendorLedgEntry."Document Type"::Refund);
        DetailedVendorLedgEntry.SetRange("Entry Type", DetailedVendorLedgEntry."Entry Type"::Application);
        DetailedVendorLedgEntry.SetFilter(
          "Initial Document Type", '<>%1&<>%2',
          DetailedVendorLedgEntry."Initial Document Type"::Payment, DetailedVendorLedgEntry."Initial Document Type"::Refund);
        DetailedVendorLedgEntry.SetFilter(
          "Posting Date", '>%1', GetMaxDate(SIIInitialDocUpload.GetInitialEndDate(), CalcDate('<-1D>', RecreateFromDate)));
        DetailedVendorLedgEntry.SetRange(Unapplied, false);
        if DetailedVendorLedgEntry.FindSet() then begin
            SetWindowSource(TotalRecNo, CollectEntriesMsg, DetailedVendorLedgEntry);
            repeat
                UpdateWindowProgress(RecNo, TotalRecNo);
                DataTypeManagement.GetRecordRef(DetailedVendorLedgEntry, DetailedVendorLedgerRecRef);
                if SIIManagement.IsDetailedLedgerCashFlowBased(DetailedVendorLedgerRecRef) then begin
                    VendorLedgerEntry.Get(DetailedVendorLedgEntry."Vendor Ledger Entry No.");
                    if not VendorLedgerEntry."Do Not Send To SII" then
                        if RequestNeedsToBeCreated(DetailedVendorLedgEntry."Posting Date",
                             SIIDocUploadState."Document Source"::"Detailed Vendor Ledger",
                             DetailedVendorLedgEntry."Entry No.")
                        then begin
                            TempDetailedVendorLedgEntry.Init();
                            TempDetailedVendorLedgEntry := DetailedVendorLedgEntry;
                            TempDetailedVendorLedgEntry.Insert();
                        end;
                end;
            until DetailedVendorLedgEntry.Next() = 0;
            LastEntryNo := DetailedVendorLedgEntry."Entry No.";
            CloseWindow();
        end;
    end;

    procedure GetMissingCustInvoices(var TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary; var LastEntryNo: Integer; RecreateFromDate: Date)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIInitialDocUpload: Codeunit "SII Initial Doc. Upload";
        TotalRecNo: Integer;
        RecNo: Integer;
    begin
        TempCustLedgerEntry.Reset();
        TempCustLedgerEntry.DeleteAll();

        if LastEntryNo <> 0 then
            CustLedgerEntry.SetFilter("Entry No.", '>%1', LastEntryNo);
        CustLedgerEntry.SetFilter(
          "Document Type", '%1|%2', CustLedgerEntry."Document Type"::Invoice, CustLedgerEntry."Document Type"::"Credit Memo");
        CustLedgerEntry.SetFilter(
          "Posting Date", '>%1', GetMaxDate(SIIInitialDocUpload.GetInitialEndDate(), CalcDate('<-1D>', RecreateFromDate)));
        CustLedgerEntry.SetRange("Do Not Send To SII", false);
        if CustLedgerEntry.FindSet() then begin
            SetWindowSource(TotalRecNo, CollectEntriesMsg, CustLedgerEntry);
            repeat
                UpdateWindowProgress(RecNo, TotalRecNo);
                if RequestNeedsToBeCreated(CustLedgerEntry."Posting Date", SIIDocUploadState."Document Source"::"Customer Ledger",
                     CustLedgerEntry."Entry No.")
                then begin
                    TempCustLedgerEntry.Init();
                    TempCustLedgerEntry := CustLedgerEntry;
                    TempCustLedgerEntry.Insert();
                end;
            until CustLedgerEntry.Next() = 0;
            LastEntryNo := CustLedgerEntry."Entry No.";
            CloseWindow();
        end;
    end;

    procedure GetMissingDetailedCustLedgerEntries(var TempDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry" temporary; var LastEntryNo: Integer; RecreateFromDate: Date)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        SIIDocUploadState: Record "SII Doc. Upload State";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIInitialDocUpload: Codeunit "SII Initial Doc. Upload";
        DataTypeManagement: Codeunit "Data Type Management";
        SIIManagement: Codeunit "SII Management";
        DetailedCustomerLedgerRecRef: RecordRef;
        TotalRecNo: Integer;
        RecNo: Integer;
    begin
        TempDetailedCustLedgEntry.Reset();
        TempDetailedCustLedgEntry.DeleteAll();

        if LastEntryNo <> 0 then
            DetailedCustLedgEntry.SetFilter("Entry No.", '>%1', LastEntryNo);
        DetailedCustLedgEntry.SetFilter(
          "Document Type", '%1|%2', DetailedCustLedgEntry."Document Type"::Payment, DetailedCustLedgEntry."Document Type"::Refund);
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::Application);
        DetailedCustLedgEntry.SetFilter(
          "Initial Document Type", '<>%1&<>%2',
          DetailedCustLedgEntry."Initial Document Type"::Payment, DetailedCustLedgEntry."Initial Document Type"::Refund);
        DetailedCustLedgEntry.SetFilter(
          "Posting Date", '>%1', GetMaxDate(SIIInitialDocUpload.GetInitialEndDate(), CalcDate('<-1D>', RecreateFromDate)));
        DetailedCustLedgEntry.SetRange(Unapplied, false);
        if DetailedCustLedgEntry.FindSet() then begin
            SetWindowSource(TotalRecNo, CollectEntriesMsg, DetailedCustLedgEntry);
            repeat
                UpdateWindowProgress(RecNo, TotalRecNo);
                DataTypeManagement.GetRecordRef(DetailedCustLedgEntry, DetailedCustomerLedgerRecRef);
                if SIIManagement.IsDetailedLedgerCashFlowBased(DetailedCustomerLedgerRecRef) then begin
                    CustLedgerEntry.Get(DetailedCustLedgEntry."Cust. Ledger Entry No.");
                    if not CustLedgerEntry."Do Not Send To SII" then
                        if RequestNeedsToBeCreated(DetailedCustLedgEntry."Posting Date",
                             SIIDocUploadState."Document Source"::"Detailed Customer Ledger",
                             DetailedCustLedgEntry."Entry No.")
                        then begin
                            TempDetailedCustLedgEntry.Init();
                            TempDetailedCustLedgEntry := DetailedCustLedgEntry;
                            TempDetailedCustLedgEntry.Insert();
                        end;
                end;
            until DetailedCustLedgEntry.Next() = 0;
            LastEntryNo := DetailedCustLedgEntry."Entry No.";
            CloseWindow();
        end;
    end;

    procedure GetMissingEntriesCount(): Integer
    var
        SIIMissingEntriesState: Record "SII Missing Entries State";
    begin
        if not SIIMissingEntriesState.Get() then
            exit(0);
        exit(SIIMissingEntriesState."Entries Missing");
    end;

    procedure GetDaysSinceLastCheck(): Integer
    var
        SIIMissingEntriesState: Record "SII Missing Entries State";
    begin
        if not SIIMissingEntriesState.Get() then
            exit(0);
        if SIIMissingEntriesState."Last Missing Entries Check" = 0D then
            exit(10); // if "Missing Entries Check" never run some value needs to be returned to pay attention of the user
        exit(Today - SIIMissingEntriesState."Last Missing Entries Check");
    end;

    local procedure SetWindowSource(var TotalRecNo: Integer; SourceMessage: Text; Rec: Variant)
    var
        RecRef: RecordRef;
    begin
        if not GuiAllowed then
            exit;

        if SourceMessage <> '' then
            Window.Open(GetWindowOpenMessage(SourceMessage));
        RecRef.GetTable(Rec);
        Window.Update(1, RecRef.Caption);
        TotalRecNo := RecRef.Count();
    end;

    [Scope('OnPrem')]
    procedure SendTraceTagOn(TraceMessage: Text)
    begin
        Session.LogMessage('000023W', TraceMessage, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', RecreateMissingEntryJobTxt);
    end;

    procedure GetSourceEntries(var TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary; var TempCustLedgEntry: Record "Cust. Ledger Entry" temporary; var TempDetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry" temporary; var TempDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry" temporary; AllEntries: Boolean; FromDate: Date)
    var
        SIIMissingEntriesState: Record "SII Missing Entries State";
        CustLedgEntryNo: Integer;
        VendLedgEntryNo: Integer;
        DtldCustLedgEntryNo: Integer;
        DtldVendLedgEntryNo: Integer;
    begin
        SIIMissingEntriesState.Initialize();
        if not AllEntries then begin
            VendLedgEntryNo := SIIMissingEntriesState."Last VLE No.";
            CustLedgEntryNo := SIIMissingEntriesState."Last CLE No.";
            DtldVendLedgEntryNo := SIIMissingEntriesState."Last DVLE No.";
            DtldCustLedgEntryNo := SIIMissingEntriesState."Last DCLE No.";
        end;

        GetMissingVendInvoices(TempVendorLedgerEntry, VendLedgEntryNo, FromDate);
        GetMissingCustInvoices(TempCustLedgEntry, CustLedgEntryNo, FromDate);
        GetMissingDetailedVendLedgerEntries(TempDetailedVendorLedgEntry, DtldVendLedgEntryNo, FromDate);
        GetMissingDetailedCustLedgerEntries(TempDetailedCustLedgEntry, DtldCustLedgEntryNo, FromDate);
        SIIMissingEntriesState."Last VLE No." := VendLedgEntryNo;
        SIIMissingEntriesState."Last CLE No." := CustLedgEntryNo;
        SIIMissingEntriesState."Last DVLE No." := DtldVendLedgEntryNo;
        SIIMissingEntriesState."Last DCLE No." := DtldCustLedgEntryNo;
        SIIMissingEntriesState."Entries Missing" :=
          TempVendorLedgerEntry.Count +
          TempCustLedgEntry.Count +
          TempDetailedVendorLedgEntry.Count +
          TempDetailedCustLedgEntry.Count();
        SIIMissingEntriesState."Last Missing Entries Check" := Today;
        SIIMissingEntriesState.Modify();
        SendTraceTagOn(StrSubstNo(EntriesMissingTxt, Format(SIIMissingEntriesState."Entries Missing")));
    end;

    procedure ShowRecreateMissingEntriesPage()
    begin
        PAGE.Run(PAGE::"Recreate Missing SII Entries");
    end;

    local procedure UpdateWindowProgress(var RecNo: Integer; TotalRecNo: Integer)
    begin
        if not GuiAllowed then
            exit;

        RecNo += 1;
        Window.Update(2, Round(RecNo / TotalRecNo * 10000, 1));
    end;

    local procedure CloseWindow()
    begin
        if GuiAllowed then
            Window.Close();
    end;

    local procedure GetWindowOpenMessage(SourceMessage: Text): Text
    begin
        exit(SourceMessage + '\' + ProgressMsg);
    end;
}

