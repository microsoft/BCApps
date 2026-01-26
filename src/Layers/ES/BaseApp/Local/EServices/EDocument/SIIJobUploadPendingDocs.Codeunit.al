// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Posting;
using Microsoft.Sales.Document;
using Microsoft.Sales.Posting;
using Microsoft.Sales.Receivables;
using System.Reflection;

codeunit 10753 "SII Job Upload Pending Docs."
{
    // Uploads invoices 1 min after their creation, using event subscribers on Sales Invoices and Purchase invoices


    trigger OnRun()
    begin
        UploadPendingDocuments();
        SIIJobManagement.TriggerNextHandlePendingJobQueueEntry();
    end;

    var
        SIIJobManagement: Codeunit "SII Job Management";
        JobType: Option HandlePending,HandleCommError,InitialUpload;

    [Scope('OnPrem')]
    procedure GenJnlLineHasSIIDocType(var GenJnlLine: Record "Gen. Journal Line"): Boolean
    var
        GenJnlLine2: Record "Gen. Journal Line";
        SIISetup: Record "SII Setup";
    begin
        if not SIISetup.IsEnabled() then
            exit(false);

        if GenJnlLine.IsTemporary() then
            exit(false);

        GenJnlLine2.Copy(GenJnlLine);
        GenJnlLine2.SetFilter(
          "Document Type", '%1|%2', GenJnlLine2."Document Type"::Invoice, GenJnlLine2."Document Type"::"Credit Memo");
        exit(not GenJnlLine2.IsEmpty());
    end;

    [Scope('OnPrem')]
    procedure HandlePendingEntries()
    begin
        SIIJobManagement.RenewJobQueueEntry(JobType::HandlePending);
    end;

    local procedure UploadPendingDocuments()
    var
        SIIDocUploadManagement: Codeunit "SII Doc. Upload Management";
    begin
        SIIDocUploadManagement.UploadPendingDocuments();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Cust. Ledger Entry", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnCustomerLedgerEntryCreated(var Rec: Record "Cust. Ledger Entry"; RunTrigger: Boolean)
    begin
        CreateSIIRequestForCustLedgEntry(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor Ledger Entry", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnVendorLedgerEntryCreated(var Rec: Record "Vendor Ledger Entry"; RunTrigger: Boolean)
    begin
        CreateSIIRequestForVendLedgEntry(Rec);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterPostSalesDoc', '', false, false)]
    local procedure OnAfterPostSalesDoc(var SalesHeader: Record "Sales Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; SalesShptHdrNo: Code[20]; RetRcpHdrNo: Code[20]; SalesInvHdrNo: Code[20]; SalesCrMemoHdrNo: Code[20])
    var
        SIISetup: Record "SII Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnAfterPostSalesDoc(SalesHeader, IsHandled);
        if IsHandled then
            exit;

        if not SIISetup.IsEnabled() then
            exit;

        if SalesHeader.IsTemporary or SalesHeader."Do Not Send To SII" then
            exit;

        if (SalesInvHdrNo = '') and (SalesCrMemoHdrNo = '') then
            exit;

        SIIJobManagement.RenewJobQueueEntry(JobType::HandlePending);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterPostPurchaseDoc', '', false, false)]
    local procedure OnAfterPostPurchDoc(var PurchaseHeader: Record "Purchase Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PurchRcpHdrNo: Code[20]; RetShptHdrNo: Code[20]; PurchInvHdrNo: Code[20]; PurchCrMemoHdrNo: Code[20])
    var
        SIISetup: Record "SII Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnAfterPostPurchDoc(PurchaseHeader, IsHandled);
        if IsHandled then
            exit;

        if not SIISetup.IsEnabled() then
            exit;

        if PurchaseHeader.IsTemporary or PurchaseHeader."Do Not Send To SII" then
            exit;

        if (PurchInvHdrNo = '') and (PurchCrMemoHdrNo = '') then
            exit;

        SIIJobManagement.RenewJobQueueEntry(JobType::HandlePending);
    end;

#if not CLEAN27
    [Obsolete('Moved to codeunit Serv. SII Management', '27.0')]
    [Scope('OnPrem')]
    procedure OnAfterPostServiceDoc(var ServiceHeader: Record Microsoft.Service.Document."Service Header")
    var
        ServSIIManagement: Codeunit Microsoft.EServices.EDocument."Serv. SII Management";
    begin
        ServSIIManagement.OnAfterPostServiceDoc(ServiceHeader);
    end;
#endif

    [Scope('OnPrem')]
    procedure OnAfterGLLinePost(GenJnlLine: Record "Gen. Journal Line")
    var
        SIISetup: Record "SII Setup";
    begin
        OnBeforeOnAfterGLLinesPost(GenJnlLine);

        if not SIISetup.IsEnabled() then
            exit;

        if GenJnlLine.IsTemporary then
            exit;

        if GenJnlLine."Do Not Send To SII" then
            exit;

        if GenJnlLine."Document Type" in [GenJnlLine."Document Type"::"Credit Memo",
                                          GenJnlLine."Document Type"::Invoice,
                                          GenJnlLine."Document Type"::Payment]
        then
            SIIJobManagement.RenewJobQueueEntry(JobType::HandlePending);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Detailed Vendor Ledg. Entry", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnDetailedVendorLedgerEntryCreated(var Rec: Record "Detailed Vendor Ledg. Entry"; RunTrigger: Boolean)
    begin
        CreateSIIRequestForDtldVendLedgEntry(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Detailed Cust. Ledg. Entry", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnDetailedCustomerLedgerEntryCreated(var Rec: Record "Detailed Cust. Ledg. Entry"; RunTrigger: Boolean)
    begin
        CreateSIIRequestForDtldCustLedgEntry(Rec);
    end;

    procedure CreateSIIRequestForCustLedgEntry(var CustLedgEntry: Record "Cust. Ledger Entry")
    var
        SIISetup: Record "SII Setup";
        SIIDocUploadState: Record "SII Doc. Upload State";
        IsHandled: Boolean;
    begin
        if not SIISetup.IsEnabled() then
            exit;

        IsHandled := false;
        OnBeforeCreateSIIRequestForCustLedgEntry(CustLedgEntry, IsHandled);
        if IsHandled then
            exit;

        if CustLedgEntry.IsTemporary() or
           (not (CustLedgEntry."Document Type" in [CustLedgEntry."Document Type"::"Credit Memo", CustLedgEntry."Document Type"::Invoice])) or
           CustLedgEntry."Do Not Send To SII"
        then
            exit;

        IsHandled := false;
        OnCreateSIIRequestForCustLedgEntryOnBeforeCreateNewRequest(CustLedgEntry, IsHandled);
        if not IsHandled then
            SIIDocUploadState.CreateNewRequest(
              CustLedgEntry."Entry No.",
              SIIDocUploadState."Document Source"::"Customer Ledger".AsInteger(),
              CustLedgEntry."Document Type".AsInteger(),
              CustLedgEntry."Document No.", CustLedgEntry."External Document No.",
              CustLedgEntry."Posting Date")
    end;

    procedure CreateSIIRequestForVendLedgEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        SIISetup: Record "SII Setup";
        SIIDocUploadState: Record "SII Doc. Upload State";
        IsHandled: Boolean;
    begin
        if not SIISetup.IsEnabled() then
            exit;

        IsHandled := false;
        OnBeforeCreateSIIRequestForVendLedgEntry(VendorLedgerEntry, IsHandled);
        if IsHandled then
            exit;

        if VendorLedgerEntry.IsTemporary() or
           (not (VendorLedgerEntry."Document Type" in [VendorLedgerEntry."Document Type"::"Credit Memo", VendorLedgerEntry."Document Type"::Invoice])) or
           VendorLedgerEntry."Do Not Send To SII"
        then
            exit;

        SIIDocUploadState.CreateNewRequest(
          VendorLedgerEntry."Entry No.",
          SIIDocUploadState."Document Source"::"Vendor Ledger".AsInteger(),
          VendorLedgerEntry."Document Type".AsInteger(),
          VendorLedgerEntry."Document No.", VendorLedgerEntry."External Document No.",
          VendorLedgerEntry."Posting Date")
    end;

    [Scope('OnPrem')]
    procedure CreateSIIRequestForDtldVendLedgEntry(var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry")
    var
        SIISetup: Record "SII Setup";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIDocUploadState: Record "SII Doc. Upload State";
        IsHandled: Boolean;
    begin
        if not SIISetup.IsEnabled() then
            exit;

        IsHandled := false;
        OnBeforeCreateSIIRequestForDtldVendLedgEntry(DetailedVendorLedgEntry, IsHandled);
        if IsHandled then
            exit;

        if DetailedVendorLedgEntry.IsTemporary then
            exit;

        if (not (DetailedVendorLedgEntry."Document Type" in [DetailedVendorLedgEntry."Document Type"::Payment, DetailedVendorLedgEntry."Document Type"::Refund])) or
           (DetailedVendorLedgEntry."Entry Type" <> DetailedVendorLedgEntry."Entry Type"::Application) or
           DetailedVendorLedgEntry.Unapplied or
           (DetailedVendorLedgEntry."Initial Document Type" in [DetailedVendorLedgEntry."Initial Document Type"::Payment, DetailedVendorLedgEntry."Initial Document Type"::Refund]) or
           (not IsVendCashflowBased(DetailedVendorLedgEntry))
        then
            exit;

        VendorLedgerEntry.Get(DetailedVendorLedgEntry."Vendor Ledger Entry No.");
        if VendorLedgerEntry."Do Not Send To SII" then
            exit;
        if VendorLedgerEntry."Document Type" = VendorLedgerEntry."Document Type"::Bill then begin
            VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
            VendorLedgerEntry.SetRange("Document No.", VendorLedgerEntry."Document No.");
            if not VendorLedgerEntry.FindFirst() then
                exit;
        end;

        case DetailedVendorLedgEntry."Document Type" of
            DetailedVendorLedgEntry."Document Type"::Payment:
                SIIDocUploadState.CreateNewVendPmtRequest(
                  DetailedVendorLedgEntry."Entry No.",
                  VendorLedgerEntry."Entry No.",
                  VendorLedgerEntry."External Document No.", DetailedVendorLedgEntry."Posting Date");
            DetailedVendorLedgEntry."Document Type"::Refund:
                SIIDocUploadState.CreateNewVendRefundRequest(
                  DetailedVendorLedgEntry."Entry No.",
                  VendorLedgerEntry."Entry No.",
                  VendorLedgerEntry."External Document No.", DetailedVendorLedgEntry."Posting Date");
        end;
        SIIJobManagement.RenewJobQueueEntry(JobType::HandlePending);
    end;

    [Scope('OnPrem')]
    procedure CreateSIIRequestForDtldCustLedgEntry(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    var
        SIISetup: Record "SII Setup";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIDocUploadState: Record "SII Doc. Upload State";
        IsHandled: Boolean;
    begin
        if not SIISetup.IsEnabled() then
            exit;

        IsHandled := false;
        OnBeforeCreateSIIRequestForDtldCustLedgEntry(DetailedCustLedgEntry, IsHandled);
        if IsHandled then
            exit;

        if DetailedCustLedgEntry.IsTemporary then
            exit;

        if (not (DetailedCustLedgEntry."Document Type" in [DetailedCustLedgEntry."Document Type"::Payment, DetailedCustLedgEntry."Document Type"::Refund])) or
           (DetailedCustLedgEntry."Entry Type" <> DetailedCustLedgEntry."Entry Type"::Application) or
           DetailedCustLedgEntry.Unapplied or
           (DetailedCustLedgEntry."Initial Document Type" in [DetailedCustLedgEntry."Initial Document Type"::Payment, DetailedCustLedgEntry."Initial Document Type"::Refund]) or
           (not IsCustCashflowBased(DetailedCustLedgEntry))
        then
            exit;

        CustLedgerEntry.Get(DetailedCustLedgEntry."Cust. Ledger Entry No.");
        if CustLedgerEntry."Do Not Send To SII" then
            exit;
        if CustLedgerEntry."Document Type" = CustLedgerEntry."Document Type"::Bill then begin
            CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
            CustLedgerEntry.SetRange("Document No.", CustLedgerEntry."Document No.");
            if not CustLedgerEntry.FindFirst() then
                exit;
        end;

        IsHandled := false;
        OnCreateSIIRequestForDtldCustLedgEntryOnBeforeCreateNewCustPmtRequest(DetailedCustLedgEntry, IsHandled);
        if not IsHandled then
            case DetailedCustLedgEntry."Document Type" of
                DetailedCustLedgEntry."Document Type"::Payment:
                    SIIDocUploadState.CreateNewCustPmtRequest(
                    DetailedCustLedgEntry."Entry No.",
                    CustLedgerEntry."Entry No.",
                    CustLedgerEntry."Document No.", DetailedCustLedgEntry."Posting Date");
                DetailedCustLedgEntry."Document Type"::Refund:
                    SIIDocUploadState.CreateNewCustRefundRequest(
                    DetailedCustLedgEntry."Entry No.",
                    CustLedgerEntry."Entry No.",
                    CustLedgerEntry."Document No.", DetailedCustLedgEntry."Posting Date");
            end;
        SIIJobManagement.RenewJobQueueEntry(JobType::HandlePending);
    end;

    local procedure IsVendCashflowBased(DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"): Boolean
    var
        DataTypeManagement: Codeunit "Data Type Management";
        SIIManagement: Codeunit "SII Management";
        DetailedVendorLedgerRecRef: RecordRef;
    begin
        DataTypeManagement.GetRecordRef(DetailedVendorLedgEntry, DetailedVendorLedgerRecRef);
        exit(SIIManagement.IsDetailedLedgerCashFlowBased(DetailedVendorLedgerRecRef));
    end;

    local procedure IsCustCashflowBased(DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"): Boolean
    var
        DataTypeManagement: Codeunit "Data Type Management";
        SIIManagement: Codeunit "SII Management";
        DetailedCustomerLedgerRecRef: RecordRef;
    begin
        DataTypeManagement.GetRecordRef(DetailedCustLedgEntry, DetailedCustomerLedgerRecRef);
        exit(SIIManagement.IsDetailedLedgerCashFlowBased(DetailedCustomerLedgerRecRef));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnAfterPostSalesDoc(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnAfterPostPurchDoc(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnBeforeOnAfterPostServiceDoc(var ServiceHeader: Record Microsoft.Service.Document."Service Header"; var IsHandled: Boolean)
    begin
        OnBeforeOnAfterPostServiceDoc(ServiceHeader, IsHandled);
    end;

    [Obsolete('Moved to codeunit Serv. SII Management', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnAfterPostServiceDoc(var ServiceHeader: Record Microsoft.Service.Document."Service Header"; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnAfterGLLinesPost(var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateSIIRequestForCustLedgEntry(var CustLedgEntry: Record "Cust. Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateSIIRequestForDtldCustLedgEntry(var DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateSIIRequestForVendLedgEntry(var VendLedgEntry: Record "Vendor Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateSIIRequestForDtldVendLedgEntry(var DtldVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSIIRequestForCustLedgEntryOnBeforeCreateNewRequest(CustLedgEntry: Record "Cust. Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSIIRequestForDtldCustLedgEntryOnBeforeCreateNewCustPmtRequest(DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var IsHandled: Boolean)
    begin
    end;
}

