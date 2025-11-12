// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Inventory.Tracking;
using Microsoft.Sales.Document;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Sales.Setup;
using Microsoft.Utilities;

codeunit 363 "PostSales-Delete"
{
    Permissions = TableData "Sales Shipment Header" = ri,
                  TableData "Sales Shipment Line" = rid,
                  TableData "Sales Invoice Header" = ri,
                  TableData "Sales Invoice Line" = rid,
                  TableData "Sales Cr.Memo Header" = ri,
                  TableData "Sales Cr.Memo Line" = rid,
                  TableData "Return Receipt Header" = ri,
                  TableData "Return Receipt Line" = rid;

    trigger OnRun()
    begin
    end;

    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        MoveEntries: Codeunit MoveEntries;
        DocumentDeletionErr: Label 'You cannot delete posted sales documents that are posted after %1. \\The date is defined by the Allow Document Deletion Before field in the Sales & Receivables Setup window.', Comment = '%1 - Posting Date';
        AllowDocumentDeletionBeforeBlankErr: Label 'The date %1 must be set on the page %2 before deleting sales documents.', Comment = '%1 = Field name, %2 = Page name';

    procedure DeleteHeader(SalesHeader: Record "Sales Header"; var SalesShptHeader: Record "Sales Shipment Header"; var SalesInvHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var ReturnRcptHeader: Record "Return Receipt Header"; var SalesInvHeaderPrePmt: Record "Sales Invoice Header"; var SalesCrMemoHeaderPrePmt: Record "Sales Cr.Memo Header")
    var
        SalesInvLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        SalesShptLine: Record "Sales Shipment Line";
        ReturnRcptLine: Record "Return Receipt Line";
        SourceCode: Record "Source Code";
        SourceCodeSetup: Record "Source Code Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteHeader(SalesHeader, SalesShptHeader, SalesInvHeader, SalesCrMemoHeader, ReturnRcptHeader, SalesInvHeaderPrePmt, SalesCrMemoHeaderPrePmt, IsHandled);
        if IsHandled then
            exit;

        SourceCodeSetup.Get();
        SourceCodeSetup.TestField("Deleted Document");
        SourceCode.Get(SourceCodeSetup."Deleted Document");

        InitDeleteHeader(
          SalesHeader, SalesShptHeader, SalesInvHeader, SalesCrMemoHeader,
          ReturnRcptHeader, SalesInvHeaderPrePmt, SalesCrMemoHeaderPrePmt, SourceCode.Code);

        if SalesShptHeader."No." <> '' then begin
            SalesShptHeader.Insert();
            SalesShptLine.Init();
            SalesShptLine."Document No." := SalesShptHeader."No.";
            SalesShptLine."Line No." := 10000;
            SalesShptLine.Description := SourceCode.Description;
            SalesShptLine.Insert();
        end;

        if ReturnRcptHeader."No." <> '' then begin
            ReturnRcptHeader.Insert();
            ReturnRcptLine.Init();
            ReturnRcptLine."Document No." := ReturnRcptHeader."No.";
            ReturnRcptLine."Line No." := 10000;
            ReturnRcptLine.Description := SourceCode.Description;
            ReturnRcptLine.Insert();
        end;

        if SalesInvHeader."No." <> '' then begin
            SalesInvHeader.Insert();
            SalesInvLine.Init();
            SalesInvLine."Document No." := SalesInvHeader."No.";
            SalesInvLine."Line No." := 10000;
            SalesInvLine.Description := SourceCode.Description;
            SalesInvLine.Insert();
        end;

        if SalesCrMemoHeader."No." <> '' then begin
            SalesCrMemoHeader.Insert();
            SalesCrMemoLine.Init();
            SalesCrMemoLine."Document No." := SalesCrMemoHeader."No.";
            SalesCrMemoLine."Line No." := 10000;
            SalesCrMemoLine.Description := SourceCode.Description;
            SalesCrMemoLine.Insert();
        end;

        if SalesInvHeaderPrePmt."No." <> '' then begin
            SalesInvHeaderPrePmt.Insert();
            SalesInvLine."Document No." := SalesInvHeaderPrePmt."No.";
            SalesInvLine."Line No." := 10000;
            SalesInvLine.Description := SourceCode.Description;
            SalesInvLine.Insert();
        end;

        if SalesCrMemoHeaderPrePmt."No." <> '' then begin
            SalesCrMemoHeaderPrePmt.Insert();
            SalesCrMemoLine.Init();
            SalesCrMemoLine."Document No." := SalesCrMemoHeaderPrePmt."No.";
            SalesCrMemoLine."Line No." := 10000;
            SalesCrMemoLine.Description := SourceCode.Description;
            SalesCrMemoLine.Insert();
        end;

        OnAfterDeleteHeader(
          SalesHeader, SalesShptHeader, SalesInvHeader, SalesCrMemoHeader, ReturnRcptHeader, SalesInvHeaderPrePmt, SalesCrMemoHeaderPrePmt);
    end;

    procedure DeleteSalesShptLines(SalesShptHeader: Record "Sales Shipment Header")
    var
        SalesShptLine: Record "Sales Shipment Line";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
    begin
        SalesShptLine.SetRange("Document No.", SalesShptHeader."No.");
        if SalesShptLine.Find('-') then
            repeat
                OnDeleteSalesShptLinesOnBeforeSalesShptLineDelete(SalesShptLine);
                SalesShptLine.TestField("Quantity Invoiced", SalesShptLine.Quantity);
                SalesShptLine.Delete(true);
            until SalesShptLine.Next() = 0;

        ItemChargeAssignmentSales.CheckAssignment(
            Enum::"Sales Applies-to Document Type"::Shipment, SalesShptLine."Document No.", SalesShptLine."Line No.");

        ItemTrackingMgt.DeleteItemEntryRelation(
          DATABASE::"Sales Shipment Line", 0, SalesShptHeader."No.", '', 0, 0, true);

        MoveEntries.MoveDocRelatedEntries(DATABASE::"Sales Shipment Header", SalesShptHeader."No.");
    end;

    procedure DeleteSalesInvLines(SalesInvHeader: Record "Sales Invoice Header")
    var
        SalesInvLine: Record "Sales Invoice Line";
    begin
        OnBeforeDeleteSalesInvLines(SalesInvHeader);

        SalesInvLine.SetRange("Document No.", SalesInvHeader."No.");
        if SalesInvLine.Find('-') then
            repeat
                OnDeleteSalesInvLinesOnBeforeSalesInvLineDelete(SalesInvLine);
                SalesInvLine.Delete();
                ItemTrackingMgt.DeleteValueEntryRelation(SalesInvLine.RowID1());
            until SalesInvLine.Next() = 0;

        MoveEntries.MoveDocRelatedEntries(DATABASE::"Sales Invoice Header", SalesInvHeader."No.");
    end;

    procedure DeleteSalesCrMemoLines(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        if SalesCrMemoLine.Find('-') then
            repeat
                OnDeleteSalesCrMemoLinesOnBeforeSalesCrMemoLineDelete(SalesCrMemoLine);
                SalesCrMemoLine.Delete();
            until SalesCrMemoLine.Next() = 0;
        ItemTrackingMgt.DeleteItemEntryRelation(
          DATABASE::"Sales Cr.Memo Line", 0, SalesCrMemoHeader."No.", '', 0, 0, true);

        MoveEntries.MoveDocRelatedEntries(DATABASE::"Sales Cr.Memo Header", SalesCrMemoHeader."No.");
    end;

    procedure DeleteSalesRcptLines(ReturnRcptHeader: Record "Return Receipt Header")
    var
        ReturnRcptLine: Record "Return Receipt Line";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
    begin
        ReturnRcptLine.SetRange("Document No.", ReturnRcptHeader."No.");
        if ReturnRcptLine.Find('-') then
            repeat
                OnDeleteSalesRcptLinesOnBeforeSalesRcptLineDelete(ReturnRcptLine);
                ReturnRcptLine.TestField("Quantity Invoiced", ReturnRcptLine.Quantity);
                ReturnRcptLine.Delete();
            until ReturnRcptLine.Next() = 0;

        ItemChargeAssignmentSales.CheckAssignment(
            Enum::"Sales Applies-to Document Type"::"Return Receipt", ReturnRcptLine."Document No.", ReturnRcptLine."Line No.");

        ItemTrackingMgt.DeleteItemEntryRelation(
          DATABASE::"Return Receipt Line", 0, ReturnRcptHeader."No.", '', 0, 0, true);

        MoveEntries.MoveDocRelatedEntries(DATABASE::"Return Receipt Header", ReturnRcptHeader."No.");
    end;

    procedure InitDeleteHeader(SalesHeader: Record "Sales Header"; var SalesShptHeader: Record "Sales Shipment Header"; var SalesInvHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var ReturnRcptHeader: Record "Return Receipt Header"; var SalesInvHeaderPrePmt: Record "Sales Invoice Header"; var SalesCrMemoHeaderPrePmt: Record "Sales Cr.Memo Header"; SourceCode: Code[10])
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        OnBeforeInitDeleteHeader(
          SalesHeader, SalesShptHeader, SalesInvHeader, SalesCrMemoHeader, ReturnRcptHeader, SalesInvHeaderPrePmt, SalesCrMemoHeaderPrePmt,
          SourceCode);

        Clear(SalesShptHeader);
        Clear(SalesInvHeader);
        Clear(SalesCrMemoHeader);
        Clear(ReturnRcptHeader);
        SalesSetup.Get();

        if (SalesHeader."Shipping No. Series" <> '') and (SalesHeader."Shipping No." <> '') then begin
            SalesShptHeader.TransferFields(SalesHeader);
            SalesShptHeader."No." := SalesHeader."Shipping No.";
            SalesShptHeader."Posting Date" := Today;
            SalesShptHeader."User ID" := CopyStr(UserId(), 1, MaxStrLen(SalesShptHeader."User ID"));
            SalesShptHeader."Source Code" := SourceCode;
        end;

        if (SalesHeader."Return Receipt No. Series" <> '') and (SalesHeader."Return Receipt No." <> '') then begin
            ReturnRcptHeader.TransferFields(SalesHeader);
            ReturnRcptHeader."No." := SalesHeader."Return Receipt No.";
            ReturnRcptHeader."Posting Date" := Today;
            ReturnRcptHeader."User ID" := CopyStr(UserId(), 1, MaxStrLen(ReturnRcptHeader."User ID"));
            ReturnRcptHeader."Source Code" := SourceCode;
        end;

        if (SalesHeader."Posting No. Series" <> '') and
           ((SalesHeader."Document Type" in [SalesHeader."Document Type"::Order, SalesHeader."Document Type"::Invoice]) and
            (SalesHeader."Posting No." <> '') or
            (SalesHeader."Document Type" = SalesHeader."Document Type"::Invoice) and
            (SalesHeader."No. Series" = SalesHeader."Posting No. Series"))
        then
            InitSalesInvHeader(SalesInvHeader, SalesHeader, SourceCode);

        if (SalesHeader."Posting No. Series" <> '') and
           ((SalesHeader."Document Type" in [SalesHeader."Document Type"::"Return Order", SalesHeader."Document Type"::"Credit Memo"]) and
            (SalesHeader."Posting No." <> '') or
            (SalesHeader."Document Type" = SalesHeader."Document Type"::"Credit Memo") and
            (SalesHeader."No. Series" = SalesHeader."Posting No. Series"))
        then begin
            SalesCrMemoHeader.TransferFields(SalesHeader);
            OnInitDeleteHeaderOnAfterSalesCrMemoHeaderTransferFields(SalesCrMemoHeader);
            if SalesHeader."Posting No." <> '' then
                SalesCrMemoHeader."No." := SalesHeader."Posting No.";
            SalesCrMemoHeader."Pre-Assigned No. Series" := SalesHeader."No. Series";
            SalesCrMemoHeader."Pre-Assigned No." := SalesHeader."No.";
            SalesCrMemoHeader."Posting Date" := Today;
            SalesCrMemoHeader."User ID" := CopyStr(UserId(), 1, MaxStrLen(SalesCrMemoHeader."User ID"));
            SalesCrMemoHeader."Source Code" := SourceCode;
        end;
        if (SalesHeader."Prepayment No. Series" <> '') and (SalesHeader."Prepayment No." <> '') then begin
            SalesHeader.TestField("Document Type", SalesHeader."Document Type"::Order);
            SalesInvHeaderPrePmt.TransferFields(SalesHeader);
            SalesInvHeaderPrePmt."No." := SalesHeader."Prepayment No.";
            SalesInvHeaderPrePmt."Order No. Series" := SalesHeader."No. Series";
            SalesInvHeaderPrePmt."Prepayment Order No." := SalesHeader."No.";
            SalesInvHeaderPrePmt."Posting Date" := Today;
            SalesInvHeaderPrePmt."Pre-Assigned No. Series" := '';
            SalesInvHeaderPrePmt."Pre-Assigned No." := '';
            SalesInvHeaderPrePmt."User ID" := CopyStr(UserId(), 1, MaxStrLen(SalesInvHeaderPrePmt."User ID"));
            SalesInvHeaderPrePmt."Source Code" := SourceCode;
            SalesInvHeaderPrePmt."Prepayment Invoice" := true;
        end;

        if (SalesHeader."Prepmt. Cr. Memo No. Series" <> '') and (SalesHeader."Prepmt. Cr. Memo No." <> '') then begin
            SalesHeader.TestField("Document Type", SalesHeader."Document Type"::Order);
            SalesCrMemoHeaderPrePmt.TransferFields(SalesHeader);
            SalesCrMemoHeaderPrePmt."No." := SalesHeader."Prepmt. Cr. Memo No.";
            SalesCrMemoHeaderPrePmt."Prepayment Order No." := SalesHeader."No.";
            SalesCrMemoHeaderPrePmt."Posting Date" := Today;
            SalesCrMemoHeaderPrePmt."Pre-Assigned No. Series" := '';
            SalesCrMemoHeaderPrePmt."Pre-Assigned No." := '';
            SalesCrMemoHeaderPrePmt."User ID" := CopyStr(UserId(), 1, MaxStrLen(SalesCrMemoHeaderPrePmt."User ID"));
            SalesCrMemoHeaderPrePmt."Source Code" := SourceCode;
            SalesCrMemoHeaderPrePmt."Prepayment Credit Memo" := true;
        end;

        OnAfterInitDeleteHeader(
          SalesHeader, SalesShptHeader, SalesInvHeader, SalesCrMemoHeader, ReturnRcptHeader, SalesInvHeaderPrePmt, SalesCrMemoHeaderPrePmt);
    end;

    local procedure InitSalesInvHeader(var SalesInvHeader: Record "Sales Invoice Header"; SalesHeader: Record "Sales Header"; SourceCode: Code[10])
    begin
        SalesInvHeader.TransferFields(SalesHeader);
        if SalesHeader."Posting No." <> '' then
            SalesInvHeader."No." := SalesHeader."Posting No.";
        if SalesHeader."Document Type" = SalesHeader."Document Type"::Invoice then begin
            SalesInvHeader."Pre-Assigned No. Series" := SalesHeader."No. Series";
            SalesInvHeader."Pre-Assigned No." := SalesHeader."No.";
        end else begin
            SalesInvHeader."Pre-Assigned No. Series" := '';
            SalesInvHeader."Pre-Assigned No." := '';
            SalesInvHeader."Order No. Series" := SalesHeader."No. Series";
            SalesInvHeader."Order No." := SalesHeader."No.";
        end;
        SalesInvHeader."Posting Date" := Today;
        SalesInvHeader."User ID" := CopyStr(UserId(), 1, MaxStrLen(SalesInvHeader."User ID"));
        SalesInvHeader."Source Code" := SourceCode;

        OnAfterInitSalesInvHeader(SalesInvHeader, SalesHeader);
    end;

    procedure IsDocumentDeletionAllowed(PostingDate: Date)
    var
        SalesSetup: Record "Sales & Receivables Setup";
        GeneralLedgerSetup: Record "General Ledger Setup";
        DocumentsRetentionPeriod: Interface "Documents - Retention Period";
    begin
        GeneralLedgerSetup.Get();
        DocumentsRetentionPeriod := GeneralLedgerSetup."Document Retention Period";
        DocumentsRetentionPeriod.CheckDocumentDeletionAllowedByLaw(PostingDate);

        SalesSetup.Get();
        if SalesSetup."Allow Document Deletion Before" = 0D then
            Error(AllowDocumentDeletionBeforeBlankErr, SalesSetup.FieldCaption("Allow Document Deletion Before"), SalesSetup.TableCaption);
        if PostingDate >= SalesSetup."Allow Document Deletion Before" then
            Error(DocumentDeletionErr, SalesSetup."Allow Document Deletion Before");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitDeleteHeader(SalesHeader: Record "Sales Header"; var SalesShipmentHeader: Record "Sales Shipment Header"; var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var ReturnReceiptHeader: Record "Return Receipt Header"; var SalesInvoiceHeaderPrepmt: Record "Sales Invoice Header"; var SalesCrMemoHeaderPrepmt: Record "Sales Cr.Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitSalesInvHeader(var SalesInvHeader: Record "Sales Invoice Header"; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitDeleteHeaderOnAfterSalesCrMemoHeaderTransferFields(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteHeader(var SalesHeader: Record "Sales Header"; var SalesShipmentHeader: Record "Sales Shipment Header"; var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var ReturnReceiptHeader: Record "Return Receipt Header"; var SalesInvoiceHeaderPrepmt: Record "Sales Invoice Header"; var SalesCrMemoHeaderPrepmt: Record "Sales Cr.Memo Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteHeader(var SalesHeader: Record "Sales Header"; var SalesShipmentHeader: Record "Sales Shipment Header"; var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var ReturnReceiptHeader: Record "Return Receipt Header"; var SalesInvoiceHeaderPrepmt: Record "Sales Invoice Header"; var SalesCrMemoHeaderPrepmt: Record "Sales Cr.Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitDeleteHeader(var SalesHeader: Record "Sales Header"; var SalesShptHeader: Record "Sales Shipment Header"; var SalesInvHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var ReturnRcptHeader: Record "Return Receipt Header"; var SalesInvHeaderPrePmt: Record "Sales Invoice Header"; var SalesCrMemoHeaderPrePmt: Record "Sales Cr.Memo Header"; var SourceCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteSalesShptLinesOnBeforeSalesShptLineDelete(var SalesShptLine: Record "Sales Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteSalesInvLinesOnBeforeSalesInvLineDelete(var SalesInvoiceLine: Record "Sales Invoice Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteSalesCrMemoLinesOnBeforeSalesCrMemoLineDelete(var SalesCrMemoLine: Record "Sales Cr.Memo Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteSalesRcptLinesOnBeforeSalesRcptLineDelete(var SalesRcptLine: Record "Return Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteSalesInvLines(var SalesInvoiceHeader: Record "Sales Invoice Header");
    begin
    end;
}

