// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Inventory.Tracking;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Setup;
using Microsoft.Utilities;
using Microsoft.Finance.GeneralLedger.Setup;

codeunit 364 "PostPurch-Delete"
{
    Permissions = TableData "Purch. Rcpt. Header" = ri,
                  TableData "Purch. Rcpt. Line" = rid,
                  TableData "Purch. Inv. Header" = ri,
                  TableData "Purch. Inv. Line" = rid,
                  TableData "Purch. Cr. Memo Hdr." = ri,
                  TableData "Purch. Cr. Memo Line" = rid,
                  TableData "Return Shipment Header" = ri,
                  TableData "Return Shipment Line" = rid;

    trigger OnRun()
    begin
    end;

    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        MoveEntries: Codeunit MoveEntries;
        DocumentDeletionErr: Label 'You cannot delete posted purchase documents that are posted after %1. \\The date is defined by the Allow Document Deletion Before field in the Purchases & Payables Setup window.', Comment = '%1 - Posting Date';
        AllowDocumentDeletionBeforeBlankErr: Label 'The date %1 must be set on the page %2 before deleting purchase documents.', Comment = '%1 = Field name, %2 = Page name';

    procedure DeleteHeader(PurchHeader: Record "Purchase Header"; var PurchRcptHeader: Record "Purch. Rcpt. Header"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var ReturnShptHeader: Record "Return Shipment Header"; var PurchInvHeaderPrepmt: Record "Purch. Inv. Header"; var PurchCrMemoHdrPrepmt: Record "Purch. Cr. Memo Hdr.")
    var
        PurchInvLine: Record "Purch. Inv. Line";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ReturnShptLine: Record "Return Shipment Line";
        SourceCode: Record "Source Code";
        SourceCodeSetup: Record "Source Code Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteHeader(PurchHeader, IsHandled, PurchRcptHeader, PurchInvHeader, PurchCrMemoHdr, ReturnShptHeader, PurchInvHeaderPrepmt, PurchCrMemoHdrPrepmt);
        if IsHandled then
            exit;

        SourceCodeSetup.Get();
        SourceCodeSetup.TestField("Deleted Document");
        SourceCode.Get(SourceCodeSetup."Deleted Document");

        InitDeleteHeader(
          PurchHeader, PurchRcptHeader, PurchInvHeader, PurchCrMemoHdr,
          ReturnShptHeader, PurchInvHeaderPrepmt, PurchCrMemoHdrPrepmt, SourceCode.Code);
        if PurchRcptHeader."No." <> '' then begin
            PurchRcptHeader.Insert();
            PurchRcptLine.Init();
            PurchRcptLine."Document No." := PurchRcptHeader."No.";
            PurchRcptLine."Line No." := 10000;
            PurchRcptLine.Description := SourceCode.Description;
            PurchRcptLine.Insert();
        end;

        if ReturnShptHeader."No." <> '' then begin
            ReturnShptHeader.Insert();
            ReturnShptLine.Init();
            ReturnShptLine."Document No." := ReturnShptHeader."No.";
            ReturnShptLine."Line No." := 10000;
            ReturnShptLine.Description := SourceCode.Description;
            ReturnShptLine.Insert();
        end;

        if PurchInvHeader."No." <> '' then begin
            PurchInvHeader.Insert();
            PurchInvLine.Init();
            PurchInvLine."Document No." := PurchInvHeader."No.";
            PurchInvLine."Line No." := 10000;
            PurchInvLine.Description := SourceCode.Description;
            PurchInvLine.Insert();
        end;

        if PurchCrMemoHdr."No." <> '' then begin
            PurchCrMemoHdr.Insert(true);
            PurchCrMemoLine.Init();
            PurchCrMemoLine."Document No." := PurchCrMemoHdr."No.";
            PurchCrMemoLine."Line No." := 10000;
            PurchCrMemoLine.Description := SourceCode.Description;
            PurchCrMemoLine.Insert();
        end;

        if PurchInvHeaderPrepmt."No." <> '' then begin
            PurchInvHeaderPrepmt.Insert();
            PurchInvLine."Document No." := PurchInvHeaderPrepmt."No.";
            PurchInvLine."Line No." := 10000;
            PurchInvLine.Description := SourceCode.Description;
            PurchInvLine.Insert();
        end;

        if PurchCrMemoHdrPrepmt."No." <> '' then begin
            PurchCrMemoHdrPrepmt.Insert();
            PurchCrMemoLine.Init();
            PurchCrMemoLine."Document No." := PurchCrMemoHdrPrepmt."No.";
            PurchCrMemoLine."Line No." := 10000;
            PurchCrMemoLine.Description := SourceCode.Description;
            PurchCrMemoLine.Insert();
        end;

        OnAfterDeleteHeader(
          PurchHeader, PurchRcptHeader, PurchInvHeader, PurchCrMemoHdr, ReturnShptHeader, PurchInvHeaderPrepmt, PurchCrMemoHdrPrepmt);
    end;

    procedure DeletePurchRcptLines(PurchRcptHeader: Record "Purch. Rcpt. Header")
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        if PurchRcptLine.Find('-') then
            repeat
                OnBeforeDeletePurchRcptLines(PurchRcptLine);
                PurchRcptLine.TestField("Quantity Invoiced", PurchRcptLine.Quantity);
                PurchRcptLine.Delete();
            until PurchRcptLine.Next() = 0;

        ItemChargeAssignmentPurch.CheckAssignment(
            Enum::"Purchase Applies-to Document Type"::Receipt, PurchRcptLine."Document No.", PurchRcptLine."Line No.");

        ItemTrackingMgt.DeleteItemEntryRelation(
            DATABASE::"Purch. Rcpt. Line", 0, PurchRcptHeader."No.", '', 0, 0, true);

        MoveEntries.MoveDocRelatedEntries(DATABASE::"Purch. Rcpt. Header", PurchRcptHeader."No.");
    end;

    procedure DeletePurchInvLines(PurchInvHeader: Record "Purch. Inv. Header")
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        if PurchInvLine.Find('-') then
            repeat
                OnBeforeDeletePurchInvLines(PurchInvLine);
                PurchInvLine.Delete();
                ItemTrackingMgt.DeleteValueEntryRelation(PurchInvLine.RowID1());
            until PurchInvLine.Next() = 0;

        MoveEntries.MoveDocRelatedEntries(DATABASE::"Purch. Inv. Header", PurchInvHeader."No.");
    end;

    procedure DeletePurchCrMemoLines(PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.")
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        PurchCrMemoLine.SetRange("Document No.", PurchCrMemoHeader."No.");
        if PurchCrMemoLine.Find('-') then
            repeat
                OnBeforeDeletePurchCrMemoLines(PurchCrMemoLine);
                PurchCrMemoLine.Delete();
            until PurchCrMemoLine.Next() = 0;
        ItemTrackingMgt.DeleteItemEntryRelation(
          DATABASE::"Purch. Cr. Memo Line", 0, PurchCrMemoHeader."No.", '', 0, 0, true);

        MoveEntries.MoveDocRelatedEntries(DATABASE::"Purch. Cr. Memo Hdr.", PurchCrMemoHeader."No.");
    end;

    procedure DeletePurchShptLines(ReturnShptHeader: Record "Return Shipment Header")
    var
        ReturnShipmentLine: Record "Return Shipment Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        ReturnShipmentLine.SetRange("Document No.", ReturnShptHeader."No.");
        if ReturnShipmentLine.Find('-') then
            repeat
                OnBeforeDeletePurchShptLines(ReturnShipmentLine);
                ReturnShipmentLine.TestField("Quantity Invoiced", ReturnShipmentLine.Quantity);
                ReturnShipmentLine.Delete();
            until ReturnShipmentLine.Next() = 0;

        ItemChargeAssignmentPurch.CheckAssignment(
            Enum::"Purchase Applies-to Document Type"::"Return Shipment", ReturnShipmentLine."Document No.", ReturnShipmentLine."Line No.");

        ItemTrackingMgt.DeleteItemEntryRelation(
          DATABASE::"Return Shipment Line", 0, ReturnShptHeader."No.", '', 0, 0, true);

        MoveEntries.MoveDocRelatedEntries(DATABASE::"Return Shipment Header", ReturnShptHeader."No.");
    end;

    procedure InitDeleteHeader(PurchHeader: Record "Purchase Header"; var PurchRcptHeader: Record "Purch. Rcpt. Header"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var ReturnShptHeader: Record "Return Shipment Header"; var PurchInvHeaderPrepmt: Record "Purch. Inv. Header"; var PurchCrMemoHdrPrepmt: Record "Purch. Cr. Memo Hdr."; SourceCode: Code[10])
    var
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        OnBeforeInitDeleteHeader(
          PurchHeader, PurchRcptHeader, PurchInvHeader, PurchCrMemoHdr, ReturnShptHeader, PurchInvHeaderPrepmt, PurchCrMemoHdrPrepmt,
          SourceCode);

        Clear(PurchRcptHeader);
        Clear(PurchInvHeader);
        Clear(PurchCrMemoHdr);
        Clear(ReturnShptHeader);
        PurchSetup.Get();

        if (PurchHeader."Receiving No. Series" <> '') and (PurchHeader."Receiving No." <> '') then begin
            PurchRcptHeader.TransferFields(PurchHeader);
            PurchRcptHeader."No." := PurchHeader."Receiving No.";
            PurchRcptHeader."Posting Date" := Today;
            PurchRcptHeader."User ID" := CopyStr(UserId(), 1, MaxStrLen(PurchRcptHeader."User ID"));
            PurchRcptHeader."Source Code" := SourceCode;
        end;

        if (PurchHeader."Return Shipment No. Series" <> '') and (PurchHeader."Return Shipment No." <> '') then begin
            ReturnShptHeader.TransferFields(PurchHeader);
            ReturnShptHeader."No." := PurchHeader."Return Shipment No.";
            ReturnShptHeader."Posting Date" := Today;
            ReturnShptHeader."User ID" := CopyStr(UserId(), 1, MaxStrLen(ReturnShptHeader."User ID"));
            ReturnShptHeader."Source Code" := SourceCode;
        end;

        if (PurchHeader."Posting No. Series" <> '') and
           ((PurchHeader."Document Type" in [PurchHeader."Document Type"::Order, PurchHeader."Document Type"::Invoice]) and
            (PurchHeader."Posting No." <> '') or
            (PurchHeader."Document Type" = PurchHeader."Document Type"::Invoice) and
            (PurchHeader."No. Series" = PurchHeader."Posting No. Series"))
        then
            InitPurchInvHeader(PurchInvHeader, PurchHeader, SourceCode);

        if (PurchHeader."Posting No. Series" <> '') and
           ((PurchHeader."Document Type" in [PurchHeader."Document Type"::"Return Order", PurchHeader."Document Type"::"Credit Memo"]) and
            (PurchHeader."Posting No." <> '') or
            (PurchHeader."Document Type" = PurchHeader."Document Type"::"Credit Memo") and
            (PurchHeader."No. Series" = PurchHeader."Posting No. Series"))
        then begin
            PurchCrMemoHdr.TransferFields(PurchHeader);
            if PurchHeader."Posting No." <> '' then
                PurchCrMemoHdr."No." := PurchHeader."Posting No.";
            PurchCrMemoHdr."Pre-Assigned No. Series" := PurchHeader."No. Series";
            PurchCrMemoHdr."Pre-Assigned No." := PurchHeader."No.";
            PurchCrMemoHdr."Posting Date" := Today;
            PurchCrMemoHdr."User ID" := CopyStr(UserId(), 1, MaxStrLen(PurchCrMemoHdr."User ID"));
            PurchCrMemoHdr."Source Code" := SourceCode;
        end;

        if (PurchHeader."Prepayment No. Series" <> '') and (PurchHeader."Prepayment No." <> '') then begin
            PurchHeader.TestField("Document Type", PurchHeader."Document Type"::Order);
            InitPurchInvHeaderPrepmt(PurchInvHeaderPrepmt, PurchHeader, SourceCode);
        end;

        if (PurchHeader."Prepmt. Cr. Memo No. Series" <> '') and (PurchHeader."Prepmt. Cr. Memo No." <> '') then begin
            PurchHeader.TestField("Document Type", PurchHeader."Document Type"::Order);
            PurchCrMemoHdrPrepmt.TransferFields(PurchHeader);
            PurchCrMemoHdrPrepmt."No." := PurchHeader."Prepmt. Cr. Memo No.";
            PurchCrMemoHdrPrepmt."Prepayment Order No." := PurchHeader."No.";
            PurchCrMemoHdrPrepmt."Posting Date" := Today;
            PurchCrMemoHdrPrepmt."Pre-Assigned No. Series" := '';
            PurchCrMemoHdrPrepmt."Pre-Assigned No." := '';
            PurchCrMemoHdrPrepmt."User ID" := CopyStr(UserId(), 1, MaxStrLen(PurchCrMemoHdrPrepmt."User ID"));
            PurchCrMemoHdrPrepmt."Source Code" := SourceCode;
            PurchCrMemoHdrPrepmt."Prepayment Credit Memo" := true;
        end;

        OnAfterInitDeleteHeader(
          PurchHeader, PurchRcptHeader, PurchInvHeader, PurchCrMemoHdr, ReturnShptHeader, PurchInvHeaderPrepmt, PurchCrMemoHdrPrepmt);
    end;

    local procedure InitPurchInvHeader(var PurchInvHeader: Record "Purch. Inv. Header"; PurchHeader: Record "Purchase Header"; SourceCode: Code[10])
    begin
        PurchInvHeader.TransferFields(PurchHeader);
        if PurchHeader."Posting No." <> '' then
            PurchInvHeader."No." := PurchHeader."Posting No.";
        if PurchHeader."Document Type" = PurchHeader."Document Type"::Invoice then begin
            PurchInvHeader."Pre-Assigned No. Series" := PurchHeader."No. Series";
            PurchInvHeader."Pre-Assigned No." := PurchHeader."No.";
        end else begin
            PurchInvHeader."Pre-Assigned No. Series" := '';
            PurchInvHeader."Pre-Assigned No." := '';
            PurchInvHeader."Order No. Series" := PurchHeader."No. Series";
            PurchInvHeader."Order No." := PurchHeader."No.";
        end;
        PurchInvHeader."Posting Date" := Today;
        PurchInvHeader."User ID" := CopyStr(UserId(), 1, MaxStrLen(PurchInvHeader."User ID"));
        PurchInvHeader."Source Code" := SourceCode;

        OnAfterInitPurchInvHeader(PurchInvHeader, PurchHeader);
    end;

    local procedure InitPurchInvHeaderPrepmt(var PurchInvHeaderPrepmt: Record "Purch. Inv. Header"; PurchHeader: Record "Purchase Header"; SourceCode: Code[10])
    begin
        PurchInvHeaderPrepmt.TransferFields(PurchHeader);
        PurchInvHeaderPrepmt."No." := PurchHeader."Prepayment No.";
        PurchInvHeaderPrepmt."Order No. Series" := PurchHeader."No. Series";
        PurchInvHeaderPrepmt."Prepayment Order No." := PurchHeader."No.";
        PurchInvHeaderPrepmt."Posting Date" := Today;
        PurchInvHeaderPrepmt."Pre-Assigned No. Series" := '';
        PurchInvHeaderPrepmt."Pre-Assigned No." := '';
        PurchInvHeaderPrepmt."User ID" := CopyStr(UserId(), 1, MaxStrLen(PurchInvHeaderPrepmt."User ID"));
        PurchInvHeaderPrepmt."Source Code" := SourceCode;
        PurchInvHeaderPrepmt."Prepayment Invoice" := true;

        OnAfterInitPurchInvHeaderPrepmt(PurchInvHeaderPrepmt, PurchHeader);
    end;

    procedure IsDocumentDeletionAllowed(PostingDate: Date)
    var
        PurchSetup: Record "Purchases & Payables Setup";
        GeneralLedgerSetup: Record "General Ledger Setup";
        DocumentsRetentionPeriod: Interface "Documents - Retention Period";
    begin
        GeneralLedgerSetup.Get();
        DocumentsRetentionPeriod := GeneralLedgerSetup."Document Retention Period";
        DocumentsRetentionPeriod.CheckDocumentDeletionAllowedByLaw(PostingDate);

        PurchSetup.Get();
        if PurchSetup."Allow Document Deletion Before" = 0D then
            Error(AllowDocumentDeletionBeforeBlankErr, PurchSetup.FieldCaption("Allow Document Deletion Before"), PurchSetup.TableCaption);
        if PostingDate >= PurchSetup."Allow Document Deletion Before" then
            Error(DocumentDeletionErr, PurchSetup."Allow Document Deletion Before");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteHeader(var PurchaseHeader: Record "Purchase Header"; var PurchRcptHeader: Record "Purch. Rcpt. Header"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var ReturnShipmentHeader: Record "Return Shipment Header"; var PurchInvHeaderPrepmt: Record "Purch. Inv. Header"; var PurchCrMemoHdrPrepmt: Record "Purch. Cr. Memo Hdr.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitDeleteHeader(var PurchHeader: Record "Purchase Header"; var PurchRcptHeader: Record "Purch. Rcpt. Header"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var ReturnShptHeader: Record "Return Shipment Header"; var PurchInvHeaderPrepmt: Record "Purch. Inv. Header"; var PurchCrMemoHdrPrepmt: Record "Purch. Cr. Memo Hdr.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitPurchInvHeader(var PurchInvHeader: Record "Purch. Inv. Header"; PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitPurchInvHeaderPrepmt(var PurchInvHeaderPrepmt: Record "Purch. Inv. Header"; PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteHeader(var PurchHeader: Record "Purchase Header"; var IsHandled: Boolean; var PurchRcptHeader: Record "Purch. Rcpt. Header"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var ReturnShipmentHeader: Record "Return Shipment Header"; var PurchInvHeaderPrepmt: Record "Purch. Inv. Header"; var PurchCrMemoHdrPrepmt: Record "Purch. Cr. Memo Hdr.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeletePurchRcptLines(PurchRcptLine: Record "Purch. Rcpt. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeletePurchInvLines(PurchInvLine: Record "Purch. Inv. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeletePurchCrMemoLines(PurchCrMemoLine: Record "Purch. Cr. Memo Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeletePurchShptLines(ReturnShptLine: Record "Return Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitDeleteHeader(var PurchHeader: Record "Purchase Header"; var PurchRcptHeader: Record "Purch. Rcpt. Header"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var ReturnShptHeader: Record "Return Shipment Header"; var PurchInvHeaderPrepmt: Record "Purch. Inv. Header"; var PurchCrMemoHdrPrepmt: Record "Purch. Cr. Memo Hdr."; var SourceCode: Code[10])
    begin
    end;
}

