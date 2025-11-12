// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Entity;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Integration.Graph;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Posting;
using Microsoft.Upgrade;
using Microsoft.Utilities;
using System.Reflection;
using System.Upgrade;
using Microsoft.API.Upgrade;

codeunit 5529 "Purch. Inv. Aggregator"
{
    Permissions = tabledata "Purch. Inv. Header" = rimd,
                  tabledata "Purch. Inv. Entity Aggregate" = rimd;

    trigger OnRun()
    begin
    end;

    var
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        DocumentIDNotSpecifiedErr: Label 'You must specify a document id to get the lines.';
        DocumentDoesNotExistErr: Label 'No document with the specified ID exists.';
        MultipleDocumentsFoundForIdErr: Label 'Multiple documents have been found for the specified criteria.';
        CannotModifyPostedInvioceErr: Label 'The invoice has been posted and can no longer be modified.';
        CannotInsertALineThatAlreadyExistsErr: Label 'You cannot insert a line with a duplicate sequence number.';
        CannotModifyALineThatDoesntExistErr: Label 'You cannot modify a line that does not exist.';
        CannotInsertPostedInvoiceErr: Label 'Invoices created through the API must be in Draft state.';
        CanOnlySetUOMForTypeItemErr: Label 'Unit of Measure can be set only for lines with type Item.';
        InvoiceIdIsNotSpecifiedErr: Label 'Invoice ID is not specified.';
        EntityIsNotFoundErr: Label 'Purchase Invoice Entity is not found.';
        AggregatorCategoryLbl: Label 'Purchase Invoice Aggregator';
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

        if IsBackgroundPosting(Rec) then
            exit;

        if CheckUpdatesDisabled(Rec.SystemId) then
            exit;

        InsertOrModifyFromPurchaseHeader(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeletePurchaseHeader(var Rec: Record "Purchase Header"; RunTrigger: Boolean)
    var
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
    begin
        if not CheckValidRecord(Rec) or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        if CheckUpdatesDisabled(Rec.SystemId) then
            exit;

        TransferRecordIDs(Rec);

        if not PurchInvEntityAggregate.Get(Rec."No.", false) then
            exit;

        PurchInvEntityAggregate.Delete();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch - Calc Disc. By Type", 'OnAfterResetRecalculateInvoiceDisc', '', false, false)]
    local procedure OnAfterResetRecalculateInvoiceDisc(var PurchaseHeader: Record "Purchase Header")
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
        if Rec.IsTemporary() then
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

        if not PurchaseLine.FindFirst() then
            BlankTotals(Rec."Document No.", false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purch. Inv. Header", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertPurchaseInvoiceHeader(var Rec: Record "Purch. Inv. Header"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        if CheckUpdatesDisabled(Rec.SystemId) then
            exit;

        InsertOrModifyFromPurchaseInvoiceHeader(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purch. Inv. Header", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyPurchaseInvoiceHeader(var Rec: Record "Purch. Inv. Header"; var xRec: Record "Purch. Inv. Header"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        if CheckUpdatesDisabled(Rec.SystemId) then
            exit;

        InsertOrModifyFromPurchaseInvoiceHeader(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purch. Inv. Header", 'OnAfterRenameEvent', '', false, false)]
    local procedure OnAfterRenamePurchaseInvoiceHeader(var Rec: Record "Purch. Inv. Header"; var xRec: Record "Purch. Inv. Header"; RunTrigger: Boolean)
    var
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
    begin
        if Rec.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        if CheckUpdatesDisabled(Rec.SystemId) then
            exit;

        if not PurchInvEntityAggregate.Get(xRec."No.", true) then
            exit;

        PurchInvEntityAggregate.SetIsRenameAllowed(true);
        PurchInvEntityAggregate.Rename(Rec."No.", true);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purch. Inv. Header", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeletePurchaseInvoiceHeader(var Rec: Record "Purch. Inv. Header"; RunTrigger: Boolean)
    var
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
    begin
        if Rec.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        if CheckUpdatesDisabled(Rec.SystemId) then
            exit;

        if not PurchInvEntityAggregate.Get(Rec."No.", true) then
            exit;

        PurchInvEntityAggregate.Delete();
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

        SetStatusOptionFromVendLedgerEntry(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor Ledger Entry", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyVendorLedgerEntry(var Rec: Record "Vendor Ledger Entry"; var xRec: Record "Vendor Ledger Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        if CheckUpdatesDisabled(Rec.SystemId) then
            exit;

        SetStatusOptionFromVendLedgerEntry(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor Ledger Entry", 'OnAfterRenameEvent', '', false, false)]
    local procedure OnAfterRenameVendorLedgerEntry(var Rec: Record "Vendor Ledger Entry"; var xRec: Record "Vendor Ledger Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        if CheckUpdatesDisabled(Rec.SystemId) then
            exit;

        SetStatusOptionFromVendLedgerEntry(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor Ledger Entry", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeleteVendorLedgerEntry(var Rec: Record "Vendor Ledger Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        if CheckUpdatesDisabled(Rec.SystemId) then
            exit;

        SetStatusOptionFromVendLedgerEntry(Rec);
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

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforePurchInvHeaderInsert', '', false, false)]
    local procedure OnBeforePurchInvHeaderInsert(var PurchInvHeader: Record "Purch. Inv. Header"; var PurchHeader: Record "Purchase Header"; CommitIsSupressed: Boolean)
    var
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
        ExistingPurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
        IsRenameAllowed: Boolean;
    begin
        if PurchInvHeader.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        if IsNullGuid(PurchHeader.SystemId) then begin
            Session.LogMessage('00006TQ', InvoiceIdIsNotSpecifiedErr, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AggregatorCategoryLbl);
            exit;
        end;

        if CheckUpdatesDisabled(PurchInvHeader.SystemId) then
            exit;

        if PurchInvHeader."Pre-Assigned No." <> PurchHeader."No." then
            exit;

        if not PurchInvEntityAggregate.Get(PurchHeader."No.", false) then begin
            Session.LogMessage('00006TR', EntityIsNotFoundErr, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AggregatorCategoryLbl);
            exit;
        end;

        if PurchInvEntityAggregate.Id <> PurchHeader.SystemId then
            exit;

        if ExistingPurchInvEntityAggregate.Get(PurchInvHeader."No.", true) then begin
            Session.LogMessage('0000DPX', OrphanedRecordsFoundMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AggregatorCategoryLbl);
            ExistingPurchInvEntityAggregate.Delete();
        end;

        IsRenameAllowed := PurchInvEntityAggregate.GetIsRenameAllowed();
        PurchInvEntityAggregate.SetIsRenameAllowed(true);
        PurchInvEntityAggregate.Rename(PurchInvHeader."No.", true);
        PurchInvEntityAggregate.SetIsRenameAllowed(IsRenameAllowed);
        PurchInvHeader."Draft Invoice SystemId" := PurchHeader.SystemId;
    end;

    procedure PropagateOnInsert(var PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate"; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        PurchaseHeader: Record "Purchase Header";
        TargetRecordRef: RecordRef;
        DocTypeFieldRef: FieldRef;
        NoFieldRef: FieldRef;
    begin
        if PurchInvEntityAggregate.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        if PurchInvEntityAggregate.Posted then
            Error(CannotInsertPostedInvoiceErr);

        TargetRecordRef.Open(DATABASE::"Purchase Header");

        DocTypeFieldRef := TargetRecordRef.Field(PurchaseHeader.FieldNo("Document Type"));
        DocTypeFieldRef.Value(PurchaseHeader."Document Type"::Invoice);

        NoFieldRef := TargetRecordRef.Field(PurchaseHeader.FieldNo("No."));

        TransferFieldsWithValidate(TempFieldBuffer, PurchInvEntityAggregate, TargetRecordRef);

        TargetRecordRef.Insert(true);

        // Save ship-to address because OnInsert trigger inserted company address instead
        // Safe Due Date as it is determined based on what payment terms is set on the vendor and invoiceDate
        TempFieldBuffer.SetRange("Table ID", DATABASE::"Purch. Inv. Entity Aggregate");
        TempFieldBuffer.SetFilter("Field ID", '%1|%2|%3|%4|%5|%6|%7|%8',
          PurchInvEntityAggregate.FieldNo("Ship-to Address"),
          PurchInvEntityAggregate.FieldNo("Ship-to Address 2"),
          PurchInvEntityAggregate.FieldNo("Ship-to City"),
          PurchInvEntityAggregate.FieldNo("Ship-to Country/Region Code"),
          PurchInvEntityAggregate.FieldNo("Ship-to County"),
          PurchInvEntityAggregate.FieldNo("Ship-to Post Code"),
          PurchInvEntityAggregate.FieldNo("Ship-to Phone No."),
          PurchInvEntityAggregate.FieldNo("Due Date"));
        if TempFieldBuffer.FindSet() then begin
            TransferFieldsWithValidate(TempFieldBuffer, PurchInvEntityAggregate, TargetRecordRef);
            TargetRecordRef.Modify(true);
        end;

        PurchInvEntityAggregate."No." := NoFieldRef.Value();
        PurchInvEntityAggregate.Get(PurchInvEntityAggregate."No.", PurchInvEntityAggregate.Posted);
    end;

    procedure PropagateOnModify(var PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate"; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        PurchaseHeader: Record "Purchase Header";
        TargetRecordRef: RecordRef;
        Exists: Boolean;
    begin
        if PurchInvEntityAggregate.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        if PurchInvEntityAggregate.Posted then
            Error(CannotModifyPostedInvioceErr);

        Exists := PurchaseHeader.Get(PurchaseHeader."Document Type"::Invoice, PurchInvEntityAggregate."No.");
        if Exists then
            TargetRecordRef.GetTable(PurchaseHeader)
        else
            TargetRecordRef.Open(DATABASE::"Purchase Header");

        TransferFieldsWithValidate(TempFieldBuffer, PurchInvEntityAggregate, TargetRecordRef);

        if Exists then
            TargetRecordRef.Modify(true)
        else
            TargetRecordRef.Insert(true);

        TempFieldBuffer.SetRange("Table ID", DATABASE::"Purch. Inv. Entity Aggregate");
        TempFieldBuffer.SetRange("Field ID", PurchInvEntityAggregate.FieldNo("Due Date"));
        if TempFieldBuffer.FindSet() then begin
            TransferFieldsWithValidate(TempFieldBuffer, PurchInvEntityAggregate, TargetRecordRef);
            TargetRecordRef.Modify(true);
        end;

    end;

    procedure PropagateOnDelete(var PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseHeader: Record "Purchase Header";
    begin
        if PurchInvEntityAggregate.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        if PurchInvEntityAggregate.Posted then begin
            PurchInvHeader.Get(PurchInvEntityAggregate."No.");
            if PurchInvHeader."No. Printed" = 0 then
                PurchInvHeader."No. Printed" := 1;
            PurchInvHeader.Delete(true);
        end else begin
            PurchaseHeader.Get(PurchaseHeader."Document Type"::Invoice, PurchInvEntityAggregate."No.");
            PurchaseHeader.Delete(true);
        end;
    end;

    procedure UpdateAggregateTableRecords()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
        APIDataUpgrade: Codeunit "API Data Upgrade";
        RecordCount: Integer;
    begin
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Invoice);
        if PurchaseHeader.FindSet() then
            repeat
                InsertOrModifyFromPurchaseHeader(PurchaseHeader);
                APIDataUpgrade.CountRecordsAndCommit(RecordCount);
            until PurchaseHeader.Next() = 0;

        if PurchInvHeader.FindSet() then
            repeat
                InsertOrModifyFromPurchaseInvoiceHeader(PurchInvHeader);
                APIDataUpgrade.CountRecordsAndCommit(RecordCount);
            until PurchInvHeader.Next() = 0;

        PurchInvEntityAggregate.SetRange(Posted, false);
        if PurchInvEntityAggregate.FindSet(true) then
            repeat
                if not PurchaseHeader.Get(PurchaseHeader."Document Type"::Invoice, PurchInvEntityAggregate."No.") then begin
                    PurchInvEntityAggregate.Delete(true);
                    APIDataUpgrade.CountRecordsAndCommit(RecordCount);
                end;
            until PurchInvEntityAggregate.Next() = 0;

        PurchInvEntityAggregate.SetRange(Posted, true);
        if PurchInvEntityAggregate.FindSet(true) then
            repeat
                if not PurchInvHeader.Get(PurchInvEntityAggregate."No.") then begin
                    PurchInvEntityAggregate.Delete(true);
                    APIDataUpgrade.CountRecordsAndCommit(RecordCount);
                end;
            until PurchInvEntityAggregate.Next() = 0;
    end;

    local procedure InsertOrModifyFromPurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    var
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
        RecordExists: Boolean;
    begin
        PurchInvEntityAggregate.LockTable();
        RecordExists := PurchInvEntityAggregate.Get(PurchaseHeader."No.", false);

        PurchInvEntityAggregate.TransferFields(PurchaseHeader, true);
        PurchInvEntityAggregate.Id := PurchaseHeader.SystemId;
        PurchInvEntityAggregate.Posted := false;
        PurchInvEntityAggregate.Status := PurchInvEntityAggregate.Status::Draft;
        AssignTotalsFromPurchaseHeader(PurchaseHeader, PurchInvEntityAggregate);
        PurchInvEntityAggregate.UpdateReferencedRecordIds();

        if RecordExists then
            PurchInvEntityAggregate.Modify(true)
        else
            PurchInvEntityAggregate.Insert(true);
    end;

    procedure GetPurchaseInvoiceHeaderId(var PurchInvHeader: Record "Purch. Inv. Header"): Guid
    begin
        if (not IsNullGuid(PurchInvHeader."Draft Invoice SystemId")) then
            exit(PurchInvHeader."Draft Invoice SystemId");

        exit(PurchInvHeader.SystemId);
    end;

    procedure GetPurchaseInvoiceHeaderFromId(Id: Text; var PurchInvHeader: Record "Purch. Inv. Header"): Boolean
    begin
        PurchInvHeader.SetFilter("Draft Invoice SystemId", Id);
        if PurchInvHeader.FINDFIRST() then
            exit(true);

        PurchInvHeader.SetRange("Draft Invoice SystemId");

        exit(PurchInvHeader.GetBySystemId(Id));
    end;

    local procedure InsertOrModifyFromPurchaseInvoiceHeader(var PurchInvHeader: Record "Purch. Inv. Header")
    var
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
        RecordExists: Boolean;
    begin
        PurchInvEntityAggregate.LockTable();
        RecordExists := PurchInvEntityAggregate.Get(PurchInvHeader."No.", true);
        PurchInvEntityAggregate.TransferFields(PurchInvHeader, true);
        PurchInvEntityAggregate.Id := GetPurchaseInvoiceHeaderId(PurchInvHeader);

        PurchInvEntityAggregate.Posted := true;
        SetStatusOptionFromPurchaseInvoiceHeader(PurchInvHeader, PurchInvEntityAggregate);
        AssignTotalsFromPurchaseInvoiceHeader(PurchInvHeader, PurchInvEntityAggregate);
        PurchInvEntityAggregate.UpdateReferencedRecordIds();

        if RecordExists then
            PurchInvEntityAggregate.Modify(true)
        else
            PurchInvEntityAggregate.Insert(true);
    end;

    local procedure SetStatusOptionFromPurchaseInvoiceHeader(var PurchInvHeader: Record "Purch. Inv. Header"; var PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate")
    begin
        PurchInvHeader.CalcFields(Cancelled, Closed, Corrective);
        if PurchInvHeader.Cancelled then begin
            PurchInvEntityAggregate.Status := PurchInvEntityAggregate.Status::Canceled;
            exit;
        end;

        if PurchInvHeader.Corrective then begin
            PurchInvEntityAggregate.Status := PurchInvEntityAggregate.Status::Corrective;
            exit;
        end;

        if PurchInvHeader.Closed then begin
            PurchInvEntityAggregate.Status := PurchInvEntityAggregate.Status::Paid;
            exit;
        end;

        PurchInvEntityAggregate.Status := PurchInvEntityAggregate.Status::Open;
    end;

    local procedure SetStatusOptionFromVendLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
    begin
        if not GraphMgtGeneralTools.IsApiEnabled() then
            exit;

        PurchInvEntityAggregate.SetRange("No.", VendorLedgerEntry."Document No.");
        PurchInvEntityAggregate.SetRange(Posted, true);

        if not PurchInvEntityAggregate.FindSet(true) then
            exit;

        repeat
            if PurchInvEntityAggregate."Vendor Ledger Entry No." = VendorLedgerEntry."Entry No." then
                UpdateStatusIfChanged(PurchInvEntityAggregate);
        until PurchInvEntityAggregate.Next() = 0;
    end;

    local procedure SetStatusOptionFromCancelledDocument(var CancelledDocument: Record "Cancelled Document")
    var
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
    begin
        if not GraphMgtGeneralTools.IsApiEnabled() then
            exit;

        case CancelledDocument."Source ID" of
            DATABASE::"Purch. Inv. Header":
                if not PurchInvEntityAggregate.Get(CancelledDocument."Cancelled Doc. No.", true) then
                    exit;
            DATABASE::"Purch. Cr. Memo Hdr.":
                if not PurchInvEntityAggregate.Get(CancelledDocument."Cancelled By Doc. No.", true) then
                    exit;
            else
                exit;
        end;

        UpdateStatusIfChanged(PurchInvEntityAggregate);
    end;

    procedure UpdateUnitOfMeasure(var Item: Record Item; JSONUnitOfMeasureTxt: Text)
    var
        TempFieldSet: Record "Field" temporary;
        GraphCollectionMgtItem: Codeunit "Graph Collection Mgt - Item";
        ItemModified: Boolean;
    begin
        GraphCollectionMgtItem.UpdateOrCreateItemUnitOfMeasureFromSalesDocument(JSONUnitOfMeasureTxt, Item, TempFieldSet, ItemModified);

        if ItemModified then
            Item.Modify(true);
    end;

    local procedure UpdateStatusIfChanged(var PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        CurrentStatus: Enum "Invoice Entity Aggregate Status";
    begin
        if not PurchInvHeader.Get(PurchInvEntityAggregate."No.") then
            exit;

        if CheckUpdatesDisabled(PurchInvEntityAggregate.SystemId) then
            exit;

        CurrentStatus := PurchInvEntityAggregate.Status;

        SetStatusOptionFromPurchaseInvoiceHeader(PurchInvHeader, PurchInvEntityAggregate);
        if CurrentStatus <> PurchInvEntityAggregate.Status then
            PurchInvEntityAggregate.Modify(true);
    end;

    local procedure AssignTotalsFromPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; var PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");

        if not PurchaseLine.FindFirst() then begin
            BlankTotals(PurchaseLine."Document No.", false);
            exit;
        end;

        AssignTotalsFromPurchaseLine(PurchaseLine, PurchInvEntityAggregate, PurchaseHeader);
    end;

    local procedure AssignTotalsFromPurchaseInvoiceHeader(var PurchInvHeader: Record "Purch. Inv. Header"; var PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate")
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");

        if not PurchInvLine.FindFirst() then begin
            BlankTotals(PurchInvLine."Document No.", true);
            exit;
        end;

        AssignTotalsFromPurchaseInvoiceLine(PurchInvLine, PurchInvEntityAggregate);
    end;

    local procedure AssignTotalsFromPurchaseLine(var PurchaseLine: Record "Purchase Line"; var PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate"; var PurchaseHeader: Record "Purchase Header")
    var
        TotalPurchaseLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        VATAmount: Decimal;
    begin
        if PurchaseLine."VAT Calculation Type" = PurchaseLine."VAT Calculation Type"::"Sales Tax" then begin
            PurchInvEntityAggregate."Discount Applied Before Tax" := true;
            PurchInvEntityAggregate."Prices Including VAT" := false;
        end else
            PurchInvEntityAggregate."Discount Applied Before Tax" := not PurchaseHeader."Prices Including VAT";

        DocumentTotals.CalculatePurchaseTotals(TotalPurchaseLine, VATAmount, PurchaseLine);

        PurchInvEntityAggregate."Invoice Discount Amount" := TotalPurchaseLine."Inv. Discount Amount";
        PurchInvEntityAggregate.Amount := TotalPurchaseLine.Amount;
        PurchInvEntityAggregate."Total Tax Amount" := VATAmount;
        PurchInvEntityAggregate."Amount Including VAT" := TotalPurchaseLine."Amount Including VAT";
    end;

    local procedure AssignTotalsFromPurchaseInvoiceLine(var PurchInvLine: Record "Purch. Inv. Line"; var PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        TotalPurchInvHeader: Record "Purch. Inv. Header";
        DocumentTotals: Codeunit "Document Totals";
        VATAmount: Decimal;
    begin
        if PurchInvLine."VAT Calculation Type" = PurchInvLine."VAT Calculation Type"::"Sales Tax" then
            PurchInvEntityAggregate."Discount Applied Before Tax" := true
        else begin
            PurchInvHeader.Get(PurchInvLine."Document No.");
            PurchInvEntityAggregate."Discount Applied Before Tax" := not PurchInvHeader."Prices Including VAT";
        end;

        DocumentTotals.CalculatePostedPurchInvoiceTotals(TotalPurchInvHeader, VATAmount, PurchInvLine);

        PurchInvEntityAggregate."Invoice Discount Amount" := TotalPurchInvHeader."Invoice Discount Amount";
        PurchInvEntityAggregate.Amount := TotalPurchInvHeader.Amount;
        PurchInvEntityAggregate."Total Tax Amount" := VATAmount;
        PurchInvEntityAggregate."Amount Including VAT" := TotalPurchInvHeader."Amount Including VAT";
    end;

    local procedure BlankTotals(DocumentNo: Code[20]; Posted: Boolean)
    var
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
    begin
        if not PurchInvEntityAggregate.Get(DocumentNo, Posted) then
            exit;

        if CheckUpdatesDisabled(PurchInvEntityAggregate.Id) then
            exit;

        PurchInvEntityAggregate."Invoice Discount Amount" := 0;
        PurchInvEntityAggregate."Total Tax Amount" := 0;

        PurchInvEntityAggregate.Amount := 0;
        PurchInvEntityAggregate."Amount Including VAT" := 0;
        PurchInvEntityAggregate.Modify();
    end;

    local procedure CheckValidRecord(var PurchaseHeader: Record "Purchase Header"): Boolean
    begin
        if PurchaseHeader.IsTemporary then
            exit(false);

        if PurchaseHeader."Document Type" <> PurchaseHeader."Document Type"::Invoice then
            exit(false);

        exit(true);
    end;

    local procedure ModifyTotalsPurchaseLine(var PurchaseLine: Record "Purchase Line")
    var
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
        PurchaseHeader: Record "Purchase Header";
    begin
        if PurchaseLine.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        if PurchaseLine."Document Type" <> PurchaseLine."Document Type"::Invoice then
            exit;

        if not PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.") then
            exit;

        if CheckUpdatesDisabled(PurchaseHeader.SystemId) then
            exit;

        if not PurchInvEntityAggregate.Get(PurchaseLine."Document No.", false) then
            exit;

        if (not PurchaseLine."Recalculate Invoice Disc.") and (PurchaseLine.Type = PurchaseLine.Type::Item) then
            exit;

        AssignTotalsFromPurchaseLine(PurchaseLine, PurchInvEntityAggregate, PurchaseHeader);
        PurchInvEntityAggregate.Modify(true);
    end;

    local procedure TransferPurchaseInvoiceLineAggregateToPurchaseLine(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate"; var PurchaseLine: Record "Purchase Line"; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        PurchaseLineRecordRef: RecordRef;
    begin
        PurchaseLine."Document Type" := PurchaseLine."Document Type"::Invoice;
        PurchaseLineRecordRef.GetTable(PurchaseLine);

        TransferFieldsWithValidate(TempFieldBuffer, PurchInvLineAggregate, PurchaseLineRecordRef);

        PurchaseLineRecordRef.SetTable(PurchaseLine);
    end;

    local procedure TransferRecordIDs(var PurchaseHeader: Record "Purchase Header")
    var
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
        PurchInvHeader: Record "Purch. Inv. Header";
        IsRenameAllowed: Boolean;
    begin
        if IsNullGuid(PurchaseHeader.SystemId) then
            exit;

        PurchInvHeader.SetRange("Pre-Assigned No.", PurchaseHeader."No.");
        if not PurchInvHeader.FindFirst() then
            exit;

        if PurchInvHeader."Draft Invoice SystemId" = PurchaseHeader.SystemId then
            exit;

        if PurchInvEntityAggregate.Get(PurchInvHeader."No.", true) then
            PurchInvEntityAggregate.Delete(true);

        if PurchInvEntityAggregate.Get(PurchaseHeader."No.", false) then begin
            IsRenameAllowed := PurchInvEntityAggregate.GetIsRenameAllowed();
            PurchInvEntityAggregate.SetIsRenameAllowed(true);
            PurchInvEntityAggregate.Rename(PurchInvHeader."No.", true);
            PurchInvEntityAggregate.SetIsRenameAllowed(IsRenameAllowed);
        end;

        PurchInvHeader."Draft Invoice SystemId" := PurchaseHeader.SystemId;
        PurchInvHeader.Modify(true);
    end;

    local procedure TransferFieldsWithValidate(var TempFieldBuffer: Record "Field Buffer" temporary; RecordVariant: Variant; var TargetTableRecRef: RecordRef)
    var
        DataTypeManagement: Codeunit "Data Type Management";
        SourceRecRef: RecordRef;
        TargetFieldRef: FieldRef;
        SourceFieldRef: FieldRef;
    begin
        DataTypeManagement.GetRecordRef(RecordVariant, SourceRecRef);

        TempFieldBuffer.Reset();
        if not TempFieldBuffer.FindFirst() then
            exit;

        repeat
            if TargetTableRecRef.FieldExist(TempFieldBuffer."Field ID") then begin
                SourceFieldRef := SourceRecRef.Field(TempFieldBuffer."Field ID");
                TargetFieldRef := TargetTableRecRef.Field(TempFieldBuffer."Field ID");
                if TargetFieldRef.Class = FieldClass::Normal then
                    if TargetFieldRef.Value <> SourceFieldRef.Value then
                        TargetFieldRef.Validate(SourceFieldRef.Value);
            end;
        until TempFieldBuffer.Next() = 0;
    end;

    procedure RedistributeInvoiceDiscounts(var PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if PurchInvEntityAggregate.Posted then
            exit;

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Invoice);
        PurchaseLine.SetRange("Document No.", PurchInvEntityAggregate."No.");
        PurchaseLine.SetRange("Recalculate Invoice Disc.", true);
        if PurchaseLine.FindFirst() then
            CODEUNIT.Run(CODEUNIT::"Purch - Calc Disc. By Type", PurchaseLine);

        PurchInvEntityAggregate.Get(PurchInvEntityAggregate."No.", PurchInvEntityAggregate.Posted);
    end;

    procedure LoadLines(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate"; DocumentIdFilter: Text)
    var
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
    begin
        if DocumentIdFilter = '' then
            Error(DocumentIDNotSpecifiedErr);

        PurchInvEntityAggregate.SetFilter(Id, DocumentIdFilter);
        if not PurchInvEntityAggregate.FindFirst() then
            exit;

        if PurchInvEntityAggregate.Posted then
            LoadPurchaseInvoiceLines(PurchInvLineAggregate, PurchInvEntityAggregate)
        else
            LoadPurchaseLines(PurchInvLineAggregate, PurchInvEntityAggregate);
    end;

    local procedure LoadPurchaseInvoiceLines(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate"; var PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate")
    var
        PurchInvLine: Record "Purch. Inv. Line";
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
    begin
        PurchInvLine.SetRange("Document No.", PurchInvEntityAggregate."No.");

        if PurchInvLine.FindSet(false) then
            repeat
                Clear(PurchInvLineAggregate);
                PurchInvLineAggregate.TransferFields(PurchInvLine, true);
                PurchInvLineAggregate.Id :=
                  SalesInvoiceAggregator.GetIdFromDocumentIdAndSequence(PurchInvEntityAggregate.Id, PurchInvLine."Line No.");
                PurchInvLineAggregate.SystemId := PurchInvLine.SystemId;
                PurchInvLineAggregate."Document Id" := PurchInvEntityAggregate.Id;
                if PurchInvLine."VAT Calculation Type" = PurchInvLine."VAT Calculation Type"::"Sales Tax" then
                    PurchInvLineAggregate."Tax Code" := PurchInvLine."Tax Group Code"
                else
                    PurchInvLineAggregate."Tax Code" := PurchInvLine."VAT Identifier";

                PurchInvLineAggregate."VAT %" := PurchInvLine."VAT %";
                PurchInvLineAggregate."Tax Amount" := PurchInvLine."Amount Including VAT" - PurchInvLine."VAT Base Amount";
                PurchInvLineAggregate."Currency Code" := PurchInvLine.GetCurrencyCode();
                PurchInvLineAggregate."Prices Including Tax" := PurchInvEntityAggregate."Prices Including VAT";
                PurchInvLineAggregate.UpdateReferencedRecordIds();
                UpdateLineAmountsFromPurchaseInvoiceLine(PurchInvLineAggregate);
                SetItemVariantId(PurchInvLineAggregate, PurchInvLine."No.", PurchInvLine."Variant Code");
                PurchInvLineAggregate.Insert(true);
            until PurchInvLine.Next() = 0;
    end;

    local procedure LoadPurchaseLines(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate"; var PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Invoice);
        PurchaseLine.SetRange("Document No.", PurchInvEntityAggregate."No.");

        if PurchaseLine.FindSet(false) then
            repeat
                TransferFromPurchaseLine(PurchInvLineAggregate, PurchInvEntityAggregate, PurchaseLine);
                PurchInvLineAggregate.Insert(true);
            until PurchaseLine.Next() = 0;
    end;

    local procedure TransferFromPurchaseLine(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate"; var PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate"; var PurchaseLine: Record "Purchase Line")
    var
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
    begin
        Clear(PurchInvLineAggregate);
        PurchInvLineAggregate.TransferFields(PurchaseLine, true);
        PurchInvLineAggregate."Document Id" := PurchInvEntityAggregate.Id;
        PurchInvLineAggregate.Id :=
          SalesInvoiceAggregator.GetIdFromDocumentIdAndSequence(PurchInvEntityAggregate.Id, PurchaseLine."Line No.");
        PurchInvLineAggregate.SystemId := PurchaseLine.SystemId;
        SetTaxGroupIdAndCode(
            PurchInvLineAggregate,
            PurchaseLine."Tax Group Code",
            PurchaseLine."VAT Prod. Posting Group",
            PurchaseLine."VAT Identifier");
        PurchInvLineAggregate."VAT %" := PurchaseLine."VAT %";
        PurchInvLineAggregate."Tax Amount" := PurchaseLine."Amount Including VAT" - PurchaseLine."VAT Base Amount";
        PurchInvLineAggregate."Prices Including Tax" := PurchInvEntityAggregate."Prices Including VAT";
        PurchInvLineAggregate.UpdateReferencedRecordIds();
        UpdateLineAmountsFromPurchaseLine(PurchInvLineAggregate);
        SetItemVariantId(PurchInvLineAggregate, PurchaseLine."No.", PurchaseLine."Variant Code");
    end;

    procedure PropagateInsertLine(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate"; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
        PurchaseLine: Record "Purchase Line";
        LastUsedPurchaseLine: Record "Purchase Line";
    begin
        VerifyCRUDIsPossibleForLine(PurchInvLineAggregate, PurchInvEntityAggregate);

        PurchaseLine."Document Type" := PurchaseLine."Document Type"::Invoice;
        PurchaseLine."Document No." := PurchInvEntityAggregate."No.";

        if PurchInvLineAggregate."Line No." = 0 then begin
            LastUsedPurchaseLine.SetRange("Document No.", PurchInvEntityAggregate."No.");
            LastUsedPurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Invoice);
            if LastUsedPurchaseLine.FindLast() then
                PurchInvLineAggregate."Line No." := LastUsedPurchaseLine."Line No." + 10000
            else
                PurchInvLineAggregate."Line No." := 10000;

            PurchaseLine."Line No." := PurchInvLineAggregate."Line No.";
        end else
            if PurchaseLine.Get(PurchaseLine."Document Type"::Invoice, PurchInvEntityAggregate."No.", PurchInvLineAggregate."Line No.") then
                Error(CannotInsertALineThatAlreadyExistsErr);

        TransferPurchaseInvoiceLineAggregateToPurchaseLine(PurchInvLineAggregate, PurchaseLine, TempFieldBuffer);
        PurchaseLine.Insert(true);

        RedistributeInvoiceDiscounts(PurchInvEntityAggregate);

        PurchaseLine.Find();
        TransferFromPurchaseLine(PurchInvLineAggregate, PurchInvEntityAggregate, PurchaseLine);
    end;

    procedure PropagateModifyLine(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate"; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
        PurchaseLine: Record "Purchase Line";
    begin
        VerifyCRUDIsPossibleForLine(PurchInvLineAggregate, PurchInvEntityAggregate);

        if not PurchaseLine.Get(PurchaseLine."Document Type"::Invoice, PurchInvEntityAggregate."No.", PurchInvLineAggregate."Line No.") then
            Error(CannotModifyALineThatDoesntExistErr);

        TransferPurchaseInvoiceLineAggregateToPurchaseLine(PurchInvLineAggregate, PurchaseLine, TempFieldBuffer);

        PurchaseLine.Modify(true);

        RedistributeInvoiceDiscounts(PurchInvEntityAggregate);

        PurchaseLine.Find();
        TransferFromPurchaseLine(PurchInvLineAggregate, PurchInvEntityAggregate, PurchaseLine);
    end;

    procedure PropagateDeleteLine(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate")
    var
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
        PurchaseLine: Record "Purchase Line";
    begin
        VerifyCRUDIsPossibleForLine(PurchInvLineAggregate, PurchInvEntityAggregate);

        if PurchaseLine.Get(PurchaseLine."Document Type"::Invoice, PurchInvEntityAggregate."No.", PurchInvLineAggregate."Line No.") then begin
            PurchaseLine.Delete(true);
            RedistributeInvoiceDiscounts(PurchInvEntityAggregate);
        end;
    end;

    local procedure VerifyCRUDIsPossibleForLine(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate"; var PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate")
    var
        SearchPurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
        DocumentIDFilter: Text;
    begin
        if IsNullGuid(PurchInvLineAggregate."Document Id") then begin
            DocumentIDFilter := PurchInvLineAggregate.GetFilter("Document Id");
            if DocumentIDFilter = '' then
                Error(DocumentIDNotSpecifiedErr);
            PurchInvEntityAggregate.SetFilter(Id, DocumentIDFilter);
            if not PurchInvEntityAggregate.FindFirst() then
                Error(DocumentDoesNotExistErr);
        end else begin
            PurchInvEntityAggregate.SetRange(Id, PurchInvLineAggregate."Document Id");
            if not PurchInvEntityAggregate.FindFirst() then
                Error(DocumentDoesNotExistErr);
        end;

        SearchPurchInvEntityAggregate.Copy(PurchInvEntityAggregate);
        if SearchPurchInvEntityAggregate.Next() <> 0 then
            Error(MultipleDocumentsFoundForIdErr);

        if PurchInvEntityAggregate.Posted then
            Error(CannotModifyPostedInvioceErr);
    end;

    procedure UpdateLineAmountsFromPurchaseLine(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate")
    begin
        PurchInvLineAggregate."Line Tax Amount" :=
          PurchInvLineAggregate."Line Amount Including Tax" - PurchInvLineAggregate."Line Amount Excluding Tax";
        UpdateInvoiceDiscountAmount(PurchInvLineAggregate);
    end;

    procedure SetItemVariantId(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate"; ItemNo: Code[20]; VariantCode: Code[20])
    var
        ItemVariant: Record "Item Variant";
    begin
        if ItemVariant.Get(ItemNo, VariantCode) then
            PurchInvLineAggregate."Variant Id" := ItemVariant.SystemId;
    end;

    local procedure UpdateLineAmountsFromPurchaseInvoiceLine(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate")
    begin
        PurchInvLineAggregate."Line Tax Amount" :=
          PurchInvLineAggregate."Line Amount Including Tax" - PurchInvLineAggregate."Line Amount Excluding Tax";
        UpdateInvoiceDiscountAmount(PurchInvLineAggregate);
    end;

    procedure UpdateInvoiceDiscountAmount(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate")
    begin
        if PurchInvLineAggregate."Prices Including Tax" then
            PurchInvLineAggregate."Inv. Discount Amount Excl. VAT" :=
              PurchInvLineAggregate."Line Amount Excluding Tax" - PurchInvLineAggregate.Amount
        else
            PurchInvLineAggregate."Inv. Discount Amount Excl. VAT" := PurchInvLineAggregate."Inv. Discount Amount";
    end;

    procedure VerifyCanUpdateUOM(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate")
    begin
        if PurchInvLineAggregate."API Type" <> PurchInvLineAggregate."API Type"::Item then
            Error(CanOnlySetUOMForTypeItemErr);
    end;

    local procedure CheckValidLineRecord(var PurchaseLine: Record "Purchase Line"): Boolean
    begin
        if PurchaseLine.IsTemporary then
            exit(false);

        if not GraphMgtGeneralTools.IsApiEnabled() then
            exit(false);

        if PurchaseLine."Document Type" <> PurchaseLine."Document Type"::Invoice then
            exit(false);

        exit(true);
    end;

    local procedure IsBackgroundPosting(var PurchaseHeader: Record "Purchase Header"): Boolean
    begin
        if PurchaseHeader.IsTemporary then
            exit(false);

        exit(PurchaseHeader."Job Queue Status" in [PurchaseHeader."Job Queue Status"::"Scheduled for Posting", PurchaseHeader."Job Queue Status"::Posting]);
    end;

    local procedure CheckUpdatesDisabled(RecSystemId: Guid): Boolean
    var
        DisableAggregateTableUpgrade: Codeunit "Disable Aggregate Table Update";
        UpdatesDisabled: Boolean;
    begin
        DisableAggregateTableUpgrade.OnGetAggregateTablesUpdateEnabled(UpdatesDisabled, Database::"Purch. Inv. Entity Aggregate", RecSystemId);

        if UpdatesDisabled then
            exit(true);

        exit(false);
    end;

    procedure FixInvoicesCreatedFromOrders()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
        NullGuid: Guid;
    begin
        PurchInvHeader.SetFilter("Order No.", '<>''''');
        PurchInvHeader.SetFilter("Draft Invoice SystemId", '<>%1', NullGuid);
        PurchInvHeader.ModifyAll("Draft Invoice SystemId", NullGuid, true);

        if not (UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetFixAPIPurchaseInvoicesCreatedFromOrders())) then
            UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetFixAPIPurchaseInvoicesCreatedFromOrders());
    end;

    procedure SetTaxGroupIdAndCode(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate"; TaxGroupCode: Code[20]; VATProductPostingGroupCode: Code[20]; VATIdentifier: Code[20])
    var
        TaxGroup: Record "Tax Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        if GeneralLedgerSetup.UseVat() then begin
            PurchInvLineAggregate."Tax Code" := VATIdentifier;
            if VATProductPostingGroup.Get(VATProductPostingGroupCode) then
                PurchInvLineAggregate."Tax Id" := VATProductPostingGroup.SystemId;
        end else begin
            PurchInvLineAggregate."Tax Code" := TaxGroupCode;
            if TaxGroup.Get(TaxGroupCode) then
                PurchInvLineAggregate."Tax Id" := TaxGroup.SystemId;
        end;
    end;
}

