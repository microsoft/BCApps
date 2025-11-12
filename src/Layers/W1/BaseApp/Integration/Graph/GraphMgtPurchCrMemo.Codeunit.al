// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Graph;

using Microsoft.Integration.Entity;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Posting;
using Microsoft.Utilities;
using System.Reflection;
using Microsoft.API.Upgrade;

codeunit 5511 "Graph Mgt - Purch. Cr. Memo"
{
    Permissions = tabledata "Purch. Cr. Memo Hdr." = rimd,
                  tabledata "Purch. Cr. Memo Entity Buffer" = r;

    trigger OnRun()
    begin
    end;

    var
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        DocumentIDNotSpecifiedErr: Label 'You must specify a document id to get the lines.';
        DocumentDoesNotExistErr: Label 'No document with the specified ID exists.';
        MultipleDocumentsFoundForIdErr: Label 'Multiple documents have been found for the specified criteria.';
        CannotModifyPostedCrMemoErr: Label 'The credit memo has been posted and can no longer be modified.';
        CannotInsertALineThatAlreadyExistsErr: Label 'You cannot insert the line because  line already exists.';
        CannotModifyALineThatDoesntExistErr: Label 'You cannot modify a line that does not exist.';
        CannotInsertPostedCrMemoErr: Label 'Credit memos created through the API must be in Draft state.';
        CreditMemoIdIsNotSpecifiedErr: Label 'Credit Memo ID is not specified.', Locked = true;
        EntityIsNotFoundErr: Label 'Purchase Credit Memo Entity is not found.', Locked = true;
        AggregatorCategoryLbl: Label 'Purchase Credit Memo Aggregator', Locked = true;
        OrphanedRecordsFoundMsg: Label 'Found orphaned records.', Locked = true;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertPurchaseHeader(var Rec: Record "Purchase Header"; RunTrigger: Boolean)
    begin
        if not CheckValidRecord(Rec) or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        if CheckUpdatesDisabled(Rec.SystemId) then
            exit;

        InsertOrModifyFromPurchaseHeader(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyPurchaseHeader(var Rec: Record "Purchase Header"; var xRec: Record "Purchase Header"; RunTrigger: Boolean)
    begin
        if not CheckValidRecord(Rec) or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        if CheckUpdatesDisabled(Rec.SystemId) then
            exit;

        if IsBackgroundPosting(Rec) then
            exit;

        InsertOrModifyFromPurchaseHeader(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeletePurchaseHeader(var Rec: Record "Purchase Header"; RunTrigger: Boolean)
    var
        PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer";
    begin
        if not CheckValidRecord(Rec) or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        if CheckUpdatesDisabled(Rec.SystemId) then
            exit;

        TransferRecordIDs(Rec);

        if not PurchCrMemoEntityBuffer.Get(Rec."No.") then
            exit;

        PurchCrMemoEntityBuffer.Delete();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch - Calc Disc. By Type", 'OnAfterResetRecalculateInvoiceDisc', '', false, false)]
    local procedure OnAfterResetRecalculateCreditMemoDisc(var PurchaseHeader: Record "Purchase Header")
    begin
        if not CheckValidRecord(PurchaseHeader) or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        if CheckUpdatesDisabled(PurchaseHeader.SystemId) then
            exit;

        InsertOrModifyFromPurchaseHeader(PurchaseHeader);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertPurchaseLine(var Rec: Record "Purchase Line"; RunTrigger: Boolean)
    begin
        if not CheckValidLineRecord(Rec) then
            exit;

        if CheckUpdatesDisabled(Rec.SystemId) then
            exit;

        ModifyTotalsPurchaseLine(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyPurchaseLine(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; RunTrigger: Boolean)
    begin
        if not CheckValidLineRecord(Rec) then
            exit;

        if CheckUpdatesDisabled(Rec.SystemId) then
            exit;

        ModifyTotalsPurchaseLine(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeletePurchaseLine(var Rec: Record "Purchase Line"; RunTrigger: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if not CheckValidLineRecord(Rec) then
            exit;

        if CheckUpdatesDisabled(Rec.SystemId) then
            exit;

        PurchaseLine.SetRange("Document No.", Rec."Document No.");
        PurchaseLine.SetRange("Document Type", Rec."Document Type");
        PurchaseLine.SetRange("Recalculate Invoice Disc.", true);

        if PurchaseLine.FindFirst() then begin
            ModifyTotalsPurchaseLine(PurchaseLine);
            exit;
        end;

        PurchaseLine.SetRange("Recalculate Invoice Disc.");

        if PurchaseLine.IsEmpty() then
            BlankTotals(Rec."Document No.", false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purch. Cr. Memo Hdr.", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertPurchaseCreditMemoHeader(var Rec: Record "Purch. Cr. Memo Hdr."; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        if CheckUpdatesDisabled(Rec.SystemId) then
            exit;

        InsertOrModifyFromPurchaseCreditMemoHeader(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purch. Cr. Memo Hdr.", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyPurchaseCreditMemoHeader(var Rec: Record "Purch. Cr. Memo Hdr."; var xRec: Record "Purch. Cr. Memo Hdr."; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        if CheckUpdatesDisabled(Rec.SystemId) then
            exit;

        InsertOrModifyFromPurchaseCreditMemoHeader(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purch. Cr. Memo Hdr.", 'OnAfterRenameEvent', '', false, false)]
    local procedure OnAfterRenamePurchaseCreditMemoHeader(var Rec: Record "Purch. Cr. Memo Hdr."; var xRec: Record "Purch. Cr. Memo Hdr."; RunTrigger: Boolean)
    var
        PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer";
    begin
        if Rec.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        if CheckUpdatesDisabled(Rec.SystemId) then
            exit;

        if not PurchCrMemoEntityBuffer.Get(xRec."No.", true) then
            exit;

        PurchCrMemoEntityBuffer.SetIsRenameAllowed(true);
        PurchCrMemoEntityBuffer.Rename(Rec."No.", true);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purch. Cr. Memo Hdr.", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeletePurchaseCreditMemoHeader(var Rec: Record "Purch. Cr. Memo Hdr."; RunTrigger: Boolean)
    var
        PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer";
    begin
        if Rec.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        if CheckUpdatesDisabled(Rec.SystemId) then
            exit;

        if not PurchCrMemoEntityBuffer.Get(Rec."No.", true) then
            exit;

        PurchCrMemoEntityBuffer.Delete();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Calc.Discount", 'OnAfterCalcPurchaseDiscount', '', false, false)]
    local procedure OnAfterCalculatePurchaseDiscountOnPurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    begin
        if not CheckValidRecord(PurchaseHeader) or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        if CheckUpdatesDisabled(PurchaseHeader.SystemId) then
            exit;

        InsertOrModifyFromPurchaseHeader(PurchaseHeader);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor Ledger Entry", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertVendorLedgerEntry(var Rec: Record "Vendor Ledger Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        if CheckUpdatesDisabled(Rec.SystemId) then
            exit;

        SetStatusOptionFromVendorLedgerEntry(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor Ledger Entry", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyVendorLedgerEntry(var Rec: Record "Vendor Ledger Entry"; var xRec: Record "Vendor Ledger Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        if CheckUpdatesDisabled(Rec.SystemId) then
            exit;

        SetStatusOptionFromVendorLedgerEntry(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor Ledger Entry", 'OnAfterRenameEvent', '', false, false)]
    local procedure OnAfterRenameVendorLedgerEntry(var Rec: Record "Vendor Ledger Entry"; var xRec: Record "Vendor Ledger Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        if CheckUpdatesDisabled(Rec.SystemId) then
            exit;

        SetStatusOptionFromVendorLedgerEntry(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor Ledger Entry", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeleteVendorLedgerEntry(var Rec: Record "Vendor Ledger Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        if CheckUpdatesDisabled(Rec.SystemId) then
            exit;

        SetStatusOptionFromVendorLedgerEntry(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Cancelled Document", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertCancelledDocument(var Rec: Record "Cancelled Document"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        if CheckUpdatesDisabled(Rec.SystemId) then
            exit;

        SetStatusOptionFromCancelledDocument(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Cancelled Document", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyCancelledDocument(var Rec: Record "Cancelled Document"; var xRec: Record "Cancelled Document"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        if CheckUpdatesDisabled(Rec.SystemId) then
            exit;

        SetStatusOptionFromCancelledDocument(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Cancelled Document", 'OnAfterRenameEvent', '', false, false)]
    local procedure OnAfterRenameCancelledDocument(var Rec: Record "Cancelled Document"; var xRec: Record "Cancelled Document"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        if CheckUpdatesDisabled(Rec.SystemId) then
            exit;

        SetStatusOptionFromCancelledDocument(xRec);
        SetStatusOptionFromCancelledDocument(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Cancelled Document", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeleteCancelledDocument(var Rec: Record "Cancelled Document"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        if CheckUpdatesDisabled(Rec.SystemId) then
            exit;

        SetStatusOptionFromCancelledDocument(Rec);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforePurchCrMemoHeaderInsert', '', false, false)]
    local procedure OnBeforePurchCrMemoHeaderInsert(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; PurchHeader: Record "Purchase Header"; CommitIsSupressed: Boolean)
    var
        PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer";
        ExistingPurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer";
        IsRenameAllowed: Boolean;
    begin
        if PurchCrMemoHdr.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        if CheckUpdatesDisabled(PurchCrMemoHdr.SystemId) then
            exit;

        if IsNullGuid(PurchHeader.SystemId) then begin
            Session.LogMessage('0000K1V', CreditMemoIdIsNotSpecifiedErr, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AggregatorCategoryLbl);
            exit;
        end;

        if PurchCrMemoHdr."Pre-Assigned No." <> PurchHeader."No." then
            exit;

        if not PurchCrMemoEntityBuffer.Get(PurchHeader."No.", false) then begin
            Session.LogMessage('0000K1W', EntityIsNotFoundErr, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AggregatorCategoryLbl);
            exit;
        end;

        if PurchCrMemoEntityBuffer.Id <> PurchHeader.SystemId then
            exit;

        if ExistingPurchCrMemoEntityBuffer.Get(PurchCrMemoHdr."No.", true) then begin
            Session.LogMessage('0000K1X', OrphanedRecordsFoundMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AggregatorCategoryLbl);
            ExistingPurchCrMemoEntityBuffer.Delete();
        end;

        IsRenameAllowed := PurchCrMemoEntityBuffer.GetIsRenameAllowed();
        PurchCrMemoEntityBuffer.SetIsRenameAllowed(true);
        PurchCrMemoEntityBuffer.Rename(PurchCrMemoHdr."No.", true);
        PurchCrMemoEntityBuffer.SetIsRenameAllowed(IsRenameAllowed);
        PurchCrMemoHdr."Draft Cr. Memo SystemId" := PurchHeader.SystemId;
    end;

    procedure PropagateOnInsert(var PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer"; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        PurchaseHeader: Record "Purchase Header";
        TypeHelper: Codeunit "Type Helper";
        TargetRecordRef: RecordRef;
        DocTypeFieldRef: FieldRef;
        NoFieldRef: FieldRef;
    begin
        if PurchCrMemoEntityBuffer.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        if PurchCrMemoEntityBuffer.Posted then
            Error(CannotInsertPostedCrMemoErr);

        TargetRecordRef.Open(Database::"Purchase Header");

        DocTypeFieldRef := TargetRecordRef.Field(PurchaseHeader.FieldNo("Document Type"));
        DocTypeFieldRef.Value(PurchaseHeader."Document Type"::"Credit Memo");

        NoFieldRef := TargetRecordRef.Field(PurchaseHeader.FieldNo("No."));

        TypeHelper.TransferFieldsWithValidate(TempFieldBuffer, PurchCrMemoEntityBuffer, TargetRecordRef);

        TargetRecordRef.Insert(true);

        PurchCrMemoEntityBuffer."No." := NoFieldRef.Value();
        PurchCrMemoEntityBuffer.Get(PurchCrMemoEntityBuffer."No.", PurchCrMemoEntityBuffer.Posted);
    end;

    procedure PropagateOnModify(var PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer"; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        PurchaseHeader: Record "Purchase Header";
        TypeHelper: Codeunit "Type Helper";
        TargetRecordRef: RecordRef;
        Exists: Boolean;
    begin
        if PurchCrMemoEntityBuffer.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        if PurchCrMemoEntityBuffer.Posted then
            Error(CannotModifyPostedCrMemoErr);

        Exists := PurchaseHeader.Get(PurchaseHeader."Document Type"::"Credit Memo", PurchCrMemoEntityBuffer."No.");
        if Exists then
            TargetRecordRef.GetTable(PurchaseHeader)
        else
            TargetRecordRef.Open(Database::"Purchase Header");

        TypeHelper.TransferFieldsWithValidate(TempFieldBuffer, PurchCrMemoEntityBuffer, TargetRecordRef);

        if Exists then
            TargetRecordRef.Modify(true)
        else
            TargetRecordRef.Insert(true);
    end;

    procedure PropagateOnDelete(var PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer")
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchaseHeader: Record "Purchase Header";
    begin
        if PurchCrMemoEntityBuffer.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        if PurchCrMemoEntityBuffer.Posted then begin
            PurchCrMemoHdr.Get(PurchCrMemoEntityBuffer."No.");
            if PurchCrMemoHdr."No. Printed" = 0 then
                PurchCrMemoHdr."No. Printed" := 1;
            PurchCrMemoHdr.Delete(true);
        end else begin
            PurchaseHeader.Get(PurchaseHeader."Document Type"::"Credit Memo", PurchCrMemoEntityBuffer."No.");
            PurchaseHeader.Delete(true);
        end;
    end;

    procedure UpdateBufferTableRecords()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer";
        APIDataUpgrade: Codeunit "API Data Upgrade";
        RecordCount: Integer;
    begin
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::"Credit Memo");
        if PurchaseHeader.FindSet() then
            repeat
                InsertOrModifyFromPurchaseHeader(PurchaseHeader);
                APIDataUpgrade.CountRecordsAndCommit(RecordCount);
            until PurchaseHeader.Next() = 0;

        if PurchCrMemoHdr.FindSet() then
            repeat
                InsertOrModifyFromPurchaseCreditMemoHeader(PurchCrMemoHdr);
                APIDataUpgrade.CountRecordsAndCommit(RecordCount);
            until PurchCrMemoHdr.Next() = 0;

        PurchCrMemoEntityBuffer.SetRange(Posted, false);
        if PurchCrMemoEntityBuffer.FindSet(true) then
            repeat
                if not PurchaseHeader.Get(PurchaseHeader."Document Type"::"Credit Memo", PurchCrMemoEntityBuffer."No.") then begin
                    PurchCrMemoEntityBuffer.Delete(true);
                    APIDataUpgrade.CountRecordsAndCommit(RecordCount);
                end;
            until PurchCrMemoEntityBuffer.Next() = 0;

        PurchCrMemoEntityBuffer.SetRange(Posted, true);
        if PurchCrMemoEntityBuffer.FindSet(true) then
            repeat
                if not PurchCrMemoHdr.Get(PurchCrMemoEntityBuffer."No.") then begin
                    PurchCrMemoEntityBuffer.Delete(true);
                    APIDataUpgrade.CountRecordsAndCommit(RecordCount);
                end;
            until PurchCrMemoEntityBuffer.Next() = 0;
    end;

    local procedure InsertOrModifyFromPurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    var
        PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer";
        RecordExists: Boolean;
    begin
        PurchCrMemoEntityBuffer.LockTable();
        RecordExists := PurchCrMemoEntityBuffer.Get(PurchaseHeader."No.", false);

        PurchCrMemoEntityBuffer.TransferFields(PurchaseHeader, true);
        PurchCrMemoEntityBuffer.Id := PurchaseHeader.SystemId;
        PurchCrMemoEntityBuffer.Posted := false;
        SetStatusOptionFromPurchaseHeader(PurchaseHeader, PurchCrMemoEntityBuffer);
        AssignTotalsFromPurchaseHeader(PurchaseHeader, PurchCrMemoEntityBuffer);
        PurchCrMemoEntityBuffer.UpdateReferencedRecordIds();

        if RecordExists then
            PurchCrMemoEntityBuffer.Modify(true)
        else
            PurchCrMemoEntityBuffer.Insert(true);
    end;

    procedure GetPurchaseCrMemoHeaderId(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."): Guid
    begin
        if (not IsNullGuid(PurchCrMemoHdr."Draft Cr. Memo SystemId")) then
            exit(PurchCrMemoHdr."Draft Cr. Memo SystemId");

        exit(PurchCrMemoHdr.SystemId);
    end;

    procedure GetPurchaseCrMemoHeaderFromId(Id: Text; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."): Boolean
    begin
        PurchCrMemoHdr.SetFilter("Draft Cr. Memo SystemId", Id);
        if PurchCrMemoHdr.FindFirst() then
            exit(true);

        PurchCrMemoHdr.SetRange("Draft Cr. Memo SystemId");

        exit(PurchCrMemoHdr.GetBySystemId(Id));
    end;

    local procedure InsertOrModifyFromPurchaseCreditMemoHeader(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    var
        PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer";
        RecordExists: Boolean;
    begin
        PurchCrMemoEntityBuffer.LockTable();
        RecordExists := PurchCrMemoEntityBuffer.Get(PurchCrMemoHdr."No.", true);
        PurchCrMemoEntityBuffer.TransferFields(PurchCrMemoHdr, true);
        PurchCrMemoEntityBuffer.Id := GetPurchaseCrMemoHeaderId(PurchCrMemoHdr);

        PurchCrMemoEntityBuffer.Posted := true;
        SetStatusOptionFromPurchaseCreditMemoHeader(PurchCrMemoHdr, PurchCrMemoEntityBuffer);
        AssignTotalsFromPurchaseCreditMemoHeader(PurchCrMemoHdr, PurchCrMemoEntityBuffer);
        PurchCrMemoEntityBuffer.UpdateReferencedRecordIds();

        if RecordExists then
            PurchCrMemoEntityBuffer.Modify(true)
        else
            PurchCrMemoEntityBuffer.Insert(true);
    end;

    local procedure SetStatusOptionFromPurchaseCreditMemoHeader(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer")
    begin
        PurchCrMemoHdr.CalcFields(Cancelled, Corrective, Paid);
        if PurchCrMemoHdr.Cancelled then begin
            PurchCrMemoEntityBuffer.Status := PurchCrMemoEntityBuffer.Status::Canceled;
            exit;
        end;

        if PurchCrMemoHdr.Corrective then begin
            PurchCrMemoEntityBuffer.Status := PurchCrMemoEntityBuffer.Status::Corrective;
            exit;
        end;

        if PurchCrMemoHdr.Paid then begin
            PurchCrMemoEntityBuffer.Status := PurchCrMemoEntityBuffer.Status::Paid;
            exit;
        end;

        PurchCrMemoEntityBuffer.Status := PurchCrMemoEntityBuffer.Status::Open;
    end;

    local procedure SetStatusOptionFromPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; var PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer")
    begin
        if PurchaseHeader.Status = PurchaseHeader.Status::"Pending Approval" then begin
            PurchCrMemoEntityBuffer.Status := PurchCrMemoEntityBuffer.Status::"In Review";
            exit;
        end;

        if (PurchaseHeader.Status = PurchaseHeader.Status::Released) or
           (PurchaseHeader.Status = PurchaseHeader.Status::"Pending Prepayment")
        then begin
            PurchCrMemoEntityBuffer.Status := PurchCrMemoEntityBuffer.Status::Open;
            exit;
        end;

        PurchCrMemoEntityBuffer.Status := PurchCrMemoEntityBuffer.Status::Draft;
    end;

    local procedure SetStatusOptionFromVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer";
    begin
        if not GraphMgtGeneralTools.IsApiEnabled() then
            exit;

        PurchCrMemoEntityBuffer.SetRange("Vendor Ledger Entry No.", VendorLedgerEntry."Entry No.");
        PurchCrMemoEntityBuffer.SetRange(Posted, true);

        if not PurchCrMemoEntityBuffer.FindSet(true) then
            exit;

        repeat
            UpdateStatusIfChanged(PurchCrMemoEntityBuffer);
        until PurchCrMemoEntityBuffer.Next() = 0;
    end;

    local procedure SetStatusOptionFromCancelledDocument(var CancelledDocument: Record "Cancelled Document")
    var
        PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer";
    begin
        if not GraphMgtGeneralTools.IsApiEnabled() then
            exit;

        case CancelledDocument."Source ID" of
            Database::"Purch. Cr. Memo Hdr.":
                if not PurchCrMemoEntityBuffer.Get(CancelledDocument."Cancelled Doc. No.", true) then
                    exit;
            Database::"Purch. Inv. Header":
                if not PurchCrMemoEntityBuffer.Get(CancelledDocument."Cancelled By Doc. No.", true) then
                    exit;
            else
                exit;
        end;

        UpdateStatusIfChanged(PurchCrMemoEntityBuffer);
    end;

    local procedure UpdateStatusIfChanged(var PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer")
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        CurrentStatus: Enum "Purch. Cr. Memo Entity Status";
    begin
        if CheckUpdatesDisabled(PurchCrMemoEntityBuffer.SystemId) then
            exit;

        if not PurchCrMemoHdr.Get(PurchCrMemoEntityBuffer."No.") then
            exit;
        CurrentStatus := PurchCrMemoEntityBuffer.Status;

        SetStatusOptionFromPurchaseCreditMemoHeader(PurchCrMemoHdr, PurchCrMemoEntityBuffer);
        if CurrentStatus <> PurchCrMemoEntityBuffer.Status then
            PurchCrMemoEntityBuffer.Modify(true);
    end;

    local procedure AssignTotalsFromPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; var PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");

        if not PurchaseLine.FindFirst() then begin
            BlankTotals(PurchaseLine."Document No.", false);
            exit;
        end;

        AssignTotalsFromPurchaseLine(PurchaseLine, PurchCrMemoEntityBuffer, PurchaseHeader);
    end;

    local procedure AssignTotalsFromPurchaseCreditMemoHeader(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer")
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        PurchCrMemoLine.SetRange("Document No.", PurchCrMemoHdr."No.");

        if not PurchCrMemoLine.FindFirst() then begin
            BlankTotals(PurchCrMemoLine."Document No.", true);
            exit;
        end;

        AssignTotalsFromPurchaseCreditMemoLine(PurchCrMemoLine, PurchCrMemoEntityBuffer);
    end;

    local procedure AssignTotalsFromPurchaseLine(var PurchaseLine: Record "Purchase Line"; var PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer"; var PurchaseHeader: Record "Purchase Header")
    var
        TotalPurchaseLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        VATAmount: Decimal;
    begin
        if PurchaseLine."VAT Calculation Type" = PurchaseLine."VAT Calculation Type"::"Sales Tax" then begin
            PurchCrMemoEntityBuffer."Discount Applied Before Tax" := true;
            PurchCrMemoEntityBuffer."Prices Including VAT" := false;
        end else
            PurchCrMemoEntityBuffer."Discount Applied Before Tax" := not PurchaseHeader."Prices Including VAT";

        DocumentTotals.CalculatePurchaseTotals(TotalPurchaseLine, VATAmount, PurchaseLine);

        PurchCrMemoEntityBuffer."Invoice Discount Amount" := TotalPurchaseLine."Inv. Discount Amount";
        PurchCrMemoEntityBuffer.Amount := TotalPurchaseLine.Amount;
        PurchCrMemoEntityBuffer."Total Tax Amount" := VATAmount;
        PurchCrMemoEntityBuffer."Amount Including VAT" := TotalPurchaseLine."Amount Including VAT";
    end;

    local procedure AssignTotalsFromPurchaseCreditMemoLine(var PurchCrMemoLine: Record "Purch. Cr. Memo Line"; var PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer")
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        TotalPurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        DocumentTotals: Codeunit "Document Totals";
        VATAmount: Decimal;
    begin
        if PurchCrMemoLine."VAT Calculation Type" = PurchCrMemoLine."VAT Calculation Type"::"Sales Tax" then
            PurchCrMemoEntityBuffer."Discount Applied Before Tax" := true
        else begin
            PurchCrMemoHdr.Get(PurchCrMemoLine."Document No.");
            PurchCrMemoEntityBuffer."Discount Applied Before Tax" := not PurchCrMemoHdr."Prices Including VAT";
        end;

        DocumentTotals.CalculatePostedPurchCreditMemoTotals(TotalPurchCrMemoHdr, VATAmount, PurchCrMemoLine);

        PurchCrMemoEntityBuffer."Invoice Discount Amount" := TotalPurchCrMemoHdr."Invoice Discount Amount";
        PurchCrMemoEntityBuffer.Amount := TotalPurchCrMemoHdr.Amount;
        PurchCrMemoEntityBuffer."Total Tax Amount" := VATAmount;
        PurchCrMemoEntityBuffer."Amount Including VAT" := TotalPurchCrMemoHdr."Amount Including VAT";
    end;

    local procedure BlankTotals(DocumentNo: Code[20]; Posted: Boolean)
    var
        PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer";
    begin
        if not PurchCrMemoEntityBuffer.Get(DocumentNo, Posted) then
            exit;

        if CheckUpdatesDisabled(PurchCrMemoEntityBuffer.Id) then
            exit;

        PurchCrMemoEntityBuffer."Invoice Discount Amount" := 0;
        PurchCrMemoEntityBuffer."Total Tax Amount" := 0;

        PurchCrMemoEntityBuffer.Amount := 0;
        PurchCrMemoEntityBuffer."Amount Including VAT" := 0;
        PurchCrMemoEntityBuffer.Modify();
    end;

    local procedure CheckValidRecord(var PurchaseHeader: Record "Purchase Header"): Boolean
    begin
        if PurchaseHeader.IsTemporary then
            exit(false);

        if PurchaseHeader."Document Type" <> PurchaseHeader."Document Type"::"Credit Memo" then
            exit(false);

        exit(true);
    end;

    local procedure CheckValidLineRecord(var PurchaseLine: Record "Purchase Line"): Boolean
    begin
        if PurchaseLine.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit(false);

        if PurchaseLine."Document Type" <> PurchaseLine."Document Type"::"Credit Memo" then
            exit(false);

        exit(true);
    end;

    local procedure ModifyTotalsPurchaseLine(var PurchaseLine: Record "Purchase Line")
    var
        PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer";
        PurchaseHeader: Record "Purchase Header";
    begin
        if PurchaseLine.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        if PurchaseLine."Document Type" <> PurchaseLine."Document Type"::"Credit Memo" then
            exit;

        if not PurchaseLine."Recalculate Invoice Disc." then
            exit;

        if not PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.") then
            exit;

        if CheckUpdatesDisabled(PurchaseHeader.SystemId) then
            exit;

        if not PurchCrMemoEntityBuffer.Get(PurchaseLine."Document No.", false) then
            exit;

        AssignTotalsFromPurchaseLine(PurchaseLine, PurchCrMemoEntityBuffer, PurchaseHeader);
        PurchCrMemoEntityBuffer.Modify(true);
    end;

    local procedure TransferPurchaseCreditMemoLineAggregateToPurchaseLine(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate"; var PurchaseLine: Record "Purchase Line"; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        TypeHelper: Codeunit "Type Helper";
        PurchaseLineRecordRef: RecordRef;
    begin
        PurchaseLine."Document Type" := PurchaseLine."Document Type"::"Credit Memo";
        PurchaseLineRecordRef.GetTable(PurchaseLine);

        TypeHelper.TransferFieldsWithValidate(TempFieldBuffer, PurchInvLineAggregate, PurchaseLineRecordRef);

        PurchaseLineRecordRef.SetTable(PurchaseLine);
    end;

    local procedure TransferRecordIDs(var PurchaseHeader: Record "Purchase Header")
    var
        PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        IsRenameAllowed: Boolean;
    begin
        PurchCrMemoHdr.SetRange("Pre-Assigned No.", PurchaseHeader."No.");
        if not PurchCrMemoHdr.FindFirst() then
            exit;

        if PurchCrMemoHdr."Draft Cr. Memo SystemId" = PurchaseHeader.SystemId then
            exit;

        if PurchCrMemoEntityBuffer.Get(PurchCrMemoHdr."No.", true) then
            PurchCrMemoEntityBuffer.Delete(true);

        if PurchCrMemoEntityBuffer.Get(PurchaseHeader."No.", false) then begin
            IsRenameAllowed := PurchCrMemoEntityBuffer.GetIsRenameAllowed();
            PurchCrMemoEntityBuffer.SetIsRenameAllowed(true);
            PurchCrMemoEntityBuffer.Rename(PurchCrMemoHdr."No.", true);
            PurchCrMemoEntityBuffer.SetIsRenameAllowed(IsRenameAllowed);
        end;

        PurchCrMemoHdr."Draft Cr. Memo SystemId" := PurchaseHeader.SystemId;
        PurchCrMemoHdr.Modify(true);
    end;

    procedure RedistributeCreditMemoDiscounts(var PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if PurchCrMemoEntityBuffer.Posted then
            exit;

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::"Credit Memo");
        PurchaseLine.SetRange("Document No.", PurchCrMemoEntityBuffer."No.");
        PurchaseLine.SetRange("Recalculate Invoice Disc.", true);
        if PurchaseLine.FindFirst() then
            Codeunit.Run(Codeunit::"Purch - Calc Disc. By Type", PurchaseLine);

        PurchCrMemoEntityBuffer.Get(PurchCrMemoEntityBuffer."No.", PurchCrMemoEntityBuffer.Posted);
    end;

    procedure LoadLines(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate"; DocumentIdFilter: Text)
    var
        PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer";
    begin
        if DocumentIdFilter = '' then
            Error(DocumentIDNotSpecifiedErr);

        PurchCrMemoEntityBuffer.SetFilter(Id, DocumentIdFilter);
        if not PurchCrMemoEntityBuffer.FindFirst() then
            exit;

        if PurchCrMemoEntityBuffer.Posted then
            LoadPurchaseCreditMemoLines(PurchInvLineAggregate, PurchCrMemoEntityBuffer)
        else
            LoadPurchaseLines(PurchInvLineAggregate, PurchCrMemoEntityBuffer);
    end;

    local procedure LoadPurchaseCreditMemoLines(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate"; var PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer")
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        PurchInvAggregator: Codeunit "Purch. Inv. Aggregator";
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
    begin
        PurchCrMemoLine.SetRange("Document No.", PurchCrMemoEntityBuffer."No.");

        if PurchCrMemoLine.FindSet(false) then
            repeat
                Clear(PurchInvLineAggregate);
                PurchInvLineAggregate.TransferFields(PurchCrMemoLine, true);
                PurchInvLineAggregate.Id :=
                  SalesInvoiceAggregator.GetIdFromDocumentIdAndSequence(PurchCrMemoEntityBuffer.Id, PurchCrMemoLine."Line No.");
                PurchInvLineAggregate.SystemId := PurchCrMemoLine.SystemId;
                PurchInvLineAggregate."Document Id" := PurchCrMemoEntityBuffer.Id;
                PurchInvAggregator.SetTaxGroupIdAndCode(
                  PurchInvLineAggregate,
                  PurchCrMemoLine."Tax Group Code",
                  PurchCrMemoLine."VAT Prod. Posting Group",
                  PurchCrMemoLine."VAT Identifier");
                PurchInvLineAggregate."VAT %" := PurchCrMemoLine."VAT %";
                PurchInvLineAggregate."Tax Amount" := PurchCrMemoLine."Amount Including VAT" - PurchCrMemoLine."VAT Base Amount";
                PurchInvLineAggregate."Currency Code" := PurchCrMemoLine.GetCurrencyCode();
                PurchInvLineAggregate."Prices Including Tax" := PurchCrMemoEntityBuffer."Prices Including VAT";
                PurchInvLineAggregate.UpdateReferencedRecordIds();
                UpdateLineAmountsFromPurchaseInvoiceLine(PurchInvLineAggregate, PurchCrMemoLine);
                PurchInvAggregator.SetItemVariantId(PurchInvLineAggregate, PurchCrMemoLine."No.", PurchCrMemoLine."Variant Code");
                PurchInvLineAggregate.Insert(true);
            until PurchCrMemoLine.Next() = 0;
    end;

    local procedure LoadPurchaseLines(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate"; var PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::"Credit Memo");
        PurchaseLine.SetRange("Document No.", PurchCrMemoEntityBuffer."No.");

        if PurchaseLine.FindSet(false) then
            repeat
                TransferFromPurchaseLine(PurchInvLineAggregate, PurchaseLine, PurchCrMemoEntityBuffer);
                PurchInvLineAggregate.Insert(true);
            until PurchaseLine.Next() = 0;
    end;

    local procedure TransferFromPurchaseLine(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate"; var PurchaseLine: Record "Purchase Line"; var PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer")
    var
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
        PurchInvAggregator: Codeunit "Purch. Inv. Aggregator";
    begin
        Clear(PurchInvLineAggregate);
        PurchInvLineAggregate.TransferFields(PurchaseLine, true);
        PurchInvLineAggregate."Document Id" := PurchCrMemoEntityBuffer.Id;
        PurchInvLineAggregate.Id :=
          SalesInvoiceAggregator.GetIdFromDocumentIdAndSequence(PurchCrMemoEntityBuffer.Id, PurchaseLine."Line No.");
        PurchInvLineAggregate.SystemId := PurchaseLine.SystemId;
        PurchInvAggregator.SetTaxGroupIdAndCode(
            PurchInvLineAggregate,
            PurchaseLine."Tax Group Code",
            PurchaseLine."VAT Prod. Posting Group",
            PurchaseLine."VAT Identifier");
        PurchInvLineAggregate."VAT %" := PurchaseLine."VAT %";
        PurchInvLineAggregate."Tax Amount" := PurchaseLine."Amount Including VAT" - PurchaseLine."VAT Base Amount";
        PurchInvLineAggregate."Prices Including Tax" := PurchCrMemoEntityBuffer."Prices Including VAT";
        PurchInvLineAggregate.UpdateReferencedRecordIds();
        PurchInvAggregator.UpdateLineAmountsFromPurchaseLine(PurchInvLineAggregate);
        PurchInvAggregator.SetItemVariantId(PurchInvLineAggregate, PurchaseLine."No.", PurchaseLine."Variant Code");
    end;

    procedure PropagateInsertLine(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate"; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer";
        PurchaseLine: Record "Purchase Line";
        LastUsedPurchaseLine: Record "Purchase Line";
    begin
        VerifyCRUDIsPossibleForLine(PurchInvLineAggregate, PurchCrMemoEntityBuffer);

        PurchaseLine."Document Type" := PurchaseLine."Document Type"::"Credit Memo";
        PurchaseLine."Document No." := PurchCrMemoEntityBuffer."No.";

        if PurchInvLineAggregate."Line No." = 0 then begin
            LastUsedPurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::"Credit Memo");
            LastUsedPurchaseLine.SetRange("Document No.", PurchCrMemoEntityBuffer."No.");
            if LastUsedPurchaseLine.FindLast() then
                PurchInvLineAggregate."Line No." := LastUsedPurchaseLine."Line No." + 10000
            else
                PurchInvLineAggregate."Line No." := 10000;

            PurchaseLine."Line No." := PurchInvLineAggregate."Line No.";
        end else
            if PurchaseLine.Get(PurchaseLine."Document Type"::"Credit Memo", PurchCrMemoEntityBuffer."No.", PurchInvLineAggregate."Line No.") then
                Error(CannotInsertALineThatAlreadyExistsErr);

        TransferPurchaseCreditMemoLineAggregateToPurchaseLine(PurchInvLineAggregate, PurchaseLine, TempFieldBuffer);
        PurchaseLine.Insert(true);

        RedistributeCreditMemoDiscounts(PurchCrMemoEntityBuffer);

        PurchaseLine.Find();
        TransferFromPurchaseLine(PurchInvLineAggregate, PurchaseLine, PurchCrMemoEntityBuffer);
    end;

    procedure PropagateModifyLine(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate"; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer";
        PurchaseLine: Record "Purchase Line";
    begin
        VerifyCRUDIsPossibleForLine(PurchInvLineAggregate, PurchCrMemoEntityBuffer);

        if not PurchaseLine.Get(PurchaseLine."Document Type"::"Credit Memo", PurchCrMemoEntityBuffer."No.", PurchInvLineAggregate."Line No.") then
            Error(CannotModifyALineThatDoesntExistErr);

        TransferPurchaseCreditMemoLineAggregateToPurchaseLine(PurchInvLineAggregate, PurchaseLine, TempFieldBuffer);

        PurchaseLine.Modify(true);

        RedistributeCreditMemoDiscounts(PurchCrMemoEntityBuffer);

        PurchaseLine.Find();
        TransferFromPurchaseLine(PurchInvLineAggregate, PurchaseLine, PurchCrMemoEntityBuffer);
    end;

    procedure PropagateDeleteLine(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate")
    var
        PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer";
        PurchaseLine: Record "Purchase Line";
    begin
        VerifyCRUDIsPossibleForLine(PurchInvLineAggregate, PurchCrMemoEntityBuffer);

        if PurchaseLine.Get(PurchaseLine."Document Type"::"Credit Memo", PurchCrMemoEntityBuffer."No.", PurchInvLineAggregate."Line No.") then begin
            PurchaseLine.Delete(true);
            RedistributeCreditMemoDiscounts(PurchCrMemoEntityBuffer);
        end;
    end;

    local procedure VerifyCRUDIsPossibleForLine(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate"; var PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer")
    var
        SearchPurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer";
        DocumentIDFilter: Text;
    begin
        if IsNullGuid(PurchInvLineAggregate."Document Id") then begin
            DocumentIDFilter := PurchInvLineAggregate.GetFilter("Document Id");
            if DocumentIDFilter = '' then
                Error(DocumentIDNotSpecifiedErr);
            PurchCrMemoEntityBuffer.SetFilter(Id, DocumentIDFilter);
            if not PurchCrMemoEntityBuffer.FindFirst() then
                Error(DocumentDoesNotExistErr);
        end else begin
            PurchCrMemoEntityBuffer.SetRange(Id, PurchInvLineAggregate."Document Id");
            if not PurchCrMemoEntityBuffer.FindFirst() then
                Error(DocumentDoesNotExistErr);
        end;

        SearchPurchCrMemoEntityBuffer.Copy(PurchCrMemoEntityBuffer);
        if SearchPurchCrMemoEntityBuffer.Next() <> 0 then
            Error(MultipleDocumentsFoundForIdErr);

        if PurchCrMemoEntityBuffer.Posted then
            Error(CannotModifyPostedCrMemoErr);
    end;

    local procedure UpdateLineAmountsFromPurchaseInvoiceLine(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate"; var PurchCrMemoLine: Record "Purch. Cr. Memo Line")
    var
        PurchInvAggregator: Codeunit "Purch. Inv. Aggregator";
    begin
        PurchInvLineAggregate."Line Amount Excluding Tax" := PurchCrMemoLine.GetLineAmountExclVAT();
        PurchInvLineAggregate."Line Amount Including Tax" := PurchCrMemoLine.GetLineAmountInclVAT();
        PurchInvLineAggregate."Line Tax Amount" :=
          PurchInvLineAggregate."Line Amount Including Tax" - PurchInvLineAggregate."Line Amount Excluding Tax";
        PurchInvAggregator.UpdateInvoiceDiscountAmount(PurchInvLineAggregate);
    end;

    local procedure IsBackgroundPosting(var PurchaseHeader: Record "Purchase Header"): Boolean
    begin
        if PurchaseHeader.IsTemporary then
            exit(false);

        exit(PurchaseHeader."Job Queue Status" in [PurchaseHeader."Job Queue Status"::"Scheduled for Posting", PurchaseHeader."Job Queue Status"::Posting]);
    end;

    local procedure CheckUpdatesDisabled(RecSystemId: Guid): Boolean
    var
        DisableAggregateTableUpdate: Codeunit "Disable Aggregate Table Update";
        UpdatesDisabled: Boolean;
    begin
        DisableAggregateTableUpdate.OnGetAggregateTablesUpdateEnabled(UpdatesDisabled, Database::"Purch. Cr. Memo Hdr.", RecSystemId);

        if UpdatesDisabled then
            exit(true);

        exit(false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Graph Mgt - General Tools", 'ApiSetup', '', false, false)]
    local procedure HandleApiSetup()
    begin
        UpdateBufferTableRecords();
    end;
}

