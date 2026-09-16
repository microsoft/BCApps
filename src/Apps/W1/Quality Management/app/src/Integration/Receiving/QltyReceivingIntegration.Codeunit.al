// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Receiving;

using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Posting;
using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Integration.Warehouse;
using Microsoft.QualityManagement.Setup;
using Microsoft.QualityManagement.Utilities;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Posting;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Journal;

codeunit 20411 "Qlty. Receiving Integration"
{
    Permissions =
        tabledata "Qlty. Management Setup" = r,
        tabledata "Qlty. Inspection Gen. Rule" = r,
        tabledata "Qlty. Inspection Header" = r;

    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        ApplicableReceivingQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyBatchNotifHelper: Codeunit "Qlty. Batch Notif. Helper";

    /// <summary>
    /// Creates inspections for received purchase lines and their posted item tracking details.
    /// </summary>
    /// <param name="PurchaseLine">The purchase line being received.</param>
    /// <param name="PurchRcptLine">The posted purchase receipt line.</param>
    /// <param name="ItemLedgShptEntryNo">The item ledger shipment entry number supplied by posting.</param>
    /// <param name="WhseShip">Indicates whether warehouse shipment processing is active.</param>
    /// <param name="WhseReceive">Indicates whether warehouse receipt processing is active.</param>
    /// <param name="CommitIsSupressed">Indicates whether commits are suppressed.</param>
    /// <param name="PurchInvHeader">The purchase invoice header supplied by posting.</param>
    /// <param name="TempTrackingSpecification">The temporary tracking details for the receipt.</param>
    /// <param name="PurchRcptHeader">The posted purchase receipt header.</param>
    /// <param name="TempWhseRcptHeader">The temporary warehouse receipt header supplied by posting.</param>
    /// <param name="xPurchLine">The purchase line state before posting.</param>
    /// <param name="TempPurchLineGlobal">The temporary global purchase line supplied by posting.</param>
    [InherentPermissions(PermissionObjectType::TableData, Database::"Qlty. Management Setup", 'R', InherentPermissionsScope::Permissions)]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterPurchRcptLineInsert', '', true, true)]
    local procedure HandleOnAfterPurchRcptLineInsert(PurchaseLine: Record "Purchase Line"; var PurchRcptLine: Record "Purch. Rcpt. Line"; ItemLedgShptEntryNo: Integer; WhseShip: Boolean; WhseReceive: Boolean; CommitIsSupressed: Boolean; PurchInvHeader: Record "Purch. Inv. Header"; var TempTrackingSpecification: Record "Tracking Specification" temporary; PurchRcptHeader: Record "Purch. Rcpt. Header"; TempWhseRcptHeader: Record "Warehouse Receipt Header"; xPurchLine: Record "Purchase Line"; var TempPurchLineGlobal: Record "Purchase Line" temporary)
    var
        PurchaseHeader: Record "Purchase Header";
        TempSingleBufferTrackingSpecification: Record "Tracking Specification" temporary;
        ExpectedCountOfInspections: Integer;
    begin
        if (PurchaseLine.Type <> PurchaseLine.Type::Item) or (PurchaseLine."Qty. to Receive (Base)" = 0) then
            exit;

        if DetectIsPreviewPosting() then
            exit;

        if not QltyManagementSetup.GetSetupRecord() then
            exit;

        if not HasPurchaseOrderPostReceiveGenRule(ApplicableReceivingQltyInspectionGenRule) then
            exit;

        if PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.") then;

        TempTrackingSpecification.SetFilter("Quantity Handled (Base)", '<>0');
        TempTrackingSpecification.SetFilter("Buffer Status", '<>%1', TempTrackingSpecification."Buffer Status"::MODIFY);
        TempTrackingSpecification.SetRange("Item No.", PurchaseLine."No.");
        TempTrackingSpecification.SetRange("Source ID", PurchaseLine."Document No.");
        TempTrackingSpecification.SetRange("Source Ref. No.", PurchaseLine."Line No.");
        TempTrackingSpecification.SetRange("Source Type", Database::"Purchase Line");

        QltyBatchNotifHelper.BeginBatch();
        ExpectedCountOfInspections := TempTrackingSpecification.Count();
        if ExpectedCountOfInspections = 0 then begin
            ExpectedCountOfInspections := 1;
            if not ApplicableReceivingQltyInspectionGenRule.IsEmpty() then begin
                TempSingleBufferTrackingSpecification.Init();
                TempSingleBufferTrackingSpecification.Insert(false);
                AttemptCreateInspectionWithPurchaseLineAndTracking(PurchaseLine, PurchaseHeader, TempSingleBufferTrackingSpecification);
            end
        end else
            if not ApplicableReceivingQltyInspectionGenRule.IsEmpty() then
                if TempTrackingSpecification.FindSet() then
                    repeat
                        Clear(TempSingleBufferTrackingSpecification);
                        TempSingleBufferTrackingSpecification := TempTrackingSpecification;
                        TempSingleBufferTrackingSpecification.Insert(false);
                        TempSingleBufferTrackingSpecification.SetRecFilter();
                        AttemptCreateInspectionWithPurchaseLineAndTracking(PurchaseLine, PurchaseHeader, TempTrackingSpecification);
                    until TempTrackingSpecification.Next() = 0;
        QltyBatchNotifHelper.EndBatch();

        TempTrackingSpecification.SetRange("Qty. to Invoice (Base)");
        TempTrackingSpecification.SetRange("Source ID");
        TempTrackingSpecification.SetRange("Source Ref. No.");
        TempTrackingSpecification.SetRange("Source Type");
        TempTrackingSpecification.SetRange("Item No.");
        TempTrackingSpecification.SetRange("Buffer Status");
    end;

    /// <summary>
    /// Creates inspections before a posted warehouse receipt journal line is registered.
    /// </summary>
    /// <param name="WarehouseJournalLine">The warehouse journal line being registered.</param>
    /// <param name="PostedWhseReceiptHeader">The posted warehouse receipt header.</param>
    [InherentPermissions(PermissionObjectType::TableData, Database::"Qlty. Management Setup", 'R', InherentPermissionsScope::Permissions)]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Receipt", 'OnPostWhseJnlLineOnBeforeWhseJnlRegisterLineRun', '', true, true)]
    local procedure HandleOnPostWhseJnlLineOnBeforeWhseJnlRegisterLineRun(var WarehouseJournalLine: Record "Warehouse Journal Line"; PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header")
    begin
        if DetectIsPreviewPosting() then
            exit;

        if not QltyManagementSetup.GetSetupRecord() then
            exit;

        if not HasWarehouseReceiptPostGenRule(ApplicableReceivingQltyInspectionGenRule) then
            exit;

        QltyBatchNotifHelper.BeginBatch();
        AttemptCreateInspectionWithWhseJournalLine(WarehouseJournalLine, PostedWhseReceiptHeader);
        QltyBatchNotifHelper.EndBatch();
    end;

    /// <summary>
    /// Creates inspections after a warehouse receipt line is created from a purchase line.
    /// </summary>
    /// <param name="WarehouseReceiptLine">The created warehouse receipt line.</param>
    /// <param name="WarehouseReceiptHeader">The warehouse receipt header.</param>
    /// <param name="PurchaseLine">The source purchase line.</param>
    [InherentPermissions(PermissionObjectType::TableData, Database::"Qlty. Management Setup", 'R', InherentPermissionsScope::Permissions)]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purchases Warehouse Mgt.", 'OnAfterCreateRcptLineFromPurchLine', '', true, true)]
    local procedure HandleOnAfterCreateRcptLineFromPurchLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; WarehouseReceiptHeader: Record "Warehouse Receipt Header"; PurchaseLine: Record "Purchase Line")
    var
        OptionalSource: Variant;
    begin
        if DetectIsPreviewPosting() then
            exit;

        if not QltyManagementSetup.GetSetupRecord() then
            exit;

        if not HasWarehouseReceiptCreateGenRule(ApplicableReceivingQltyInspectionGenRule) then
            exit;

        OptionalSource := PurchaseLine;
        QltyBatchNotifHelper.BeginBatch();
        AttemptCreateInspectionWithReceiptLine(WarehouseReceiptLine, WarehouseReceiptHeader, OptionalSource);
        QltyBatchNotifHelper.EndBatch();
    end;

    /// <summary>
    /// Creates inspections from sales return lines and their inbound item tracking before posting.
    /// </summary>
    /// <param name="SalesHeader">The sales return order header.</param>
    /// <param name="SalesLine">The sales return line being received.</param>
    /// <param name="TempItemLedgEntryNotInvoiced">Temporary non-invoiced item ledger entries supplied by posting.</param>
    /// <param name="HasATOShippedNotInvoiced">Indicates whether assemble-to-order quantities were shipped but not invoiced.</param>
    /// <param name="IsHandled">Indicates whether the publisher event has been handled.</param>
    /// <param name="ItemLedgShptEntryNo">The item ledger shipment entry number.</param>
    /// <param name="RemQtyToBeInvoiced">The remaining quantity to invoice.</param>
    /// <param name="RemQtyToBeInvoicedBase">The remaining base quantity to invoice.</param>
    /// <param name="SalesInvoiceHeader">The sales invoice header supplied by posting.</param>
    /// <param name="SalesCrMemoHeader">The sales credit memo header supplied by posting.</param>
    [InherentPermissions(PermissionObjectType::TableData, Database::"Qlty. Management Setup", 'R', InherentPermissionsScope::Permissions)]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforePostItemTrackingLine', '', true, true)]
    local procedure HandleOnBeforePostItemTrackingLine(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var TempItemLedgEntryNotInvoiced: Record "Item Ledger Entry" temporary; HasATOShippedNotInvoiced: Boolean; var IsHandled: Boolean; var ItemLedgShptEntryNo: Integer; var RemQtyToBeInvoiced: Decimal; var RemQtyToBeInvoicedBase: Decimal; SalesInvoiceHeader: Record "Sales Invoice Header"; SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyWarehouseIntegration: Codeunit "Qlty. Warehouse Integration";
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        HasInspection: Boolean;
        SourceVariant: Variant;
        DummyVariant: Variant;
    begin
        if not (SalesLine."Document Type" = SalesLine."Document Type"::"Return Order") or (SalesLine."Return Qty. to Receive" = 0) then
            exit;

        if DetectIsPreviewPosting() then
            exit;

        if not QltyManagementSetup.GetSetupRecord() then
            exit;

        if HasSalesReturnOrderPostReceiveGenRule(QltyInspectionGenRule) then begin

            SourceVariant := SalesLine;
            QltyWarehouseIntegration.CollectSourceItemTracking(SourceVariant, TempTrackingSpecification);
            IsHandled := false;
            OnBeforeSalesReturnCreateInspectionWithSalesLine(SalesHeader, SalesLine, TempItemLedgEntryNotInvoiced, TempTrackingSpecification, IsHandled);
            if IsHandled then
                exit;

            QltyBatchNotifHelper.BeginBatch();
            QltyBatchNotifHelper.ConfigureForBatch(QltyInspectionCreate);
            TempTrackingSpecification.Reset();
            if TempTrackingSpecification.FindSet() then
                repeat
                    if QltyInspectionCreate.CreateInspectionWithMultiVariants(SalesLine, TempTrackingSpecification, DummyVariant, DummyVariant, false, QltyInspectionGenRule) then begin
                        HasInspection := true;
                        QltyInspectionCreate.GetCreatedInspection(QltyInspectionHeader);
                        QltyBatchNotifHelper.TrackCreatedInspection(QltyInspectionHeader."No.", QltyInspectionCreate.IsLastInspectionNewlyCreated());
                    end;
                until TempTrackingSpecification.Next() = 0
            else
                if QltyInspectionCreate.CreateInspectionWithMultiVariants(SalesLine, DummyVariant, DummyVariant, DummyVariant, false, QltyInspectionGenRule) then begin
                    HasInspection := true;
                    QltyInspectionCreate.GetCreatedInspection(QltyInspectionHeader);
                    QltyBatchNotifHelper.TrackCreatedInspection(QltyInspectionHeader."No.", QltyInspectionCreate.IsLastInspectionNewlyCreated());
                end;
            QltyBatchNotifHelper.EndBatch();
        end;

        OnAfterSalesReturnCreateInspectionWithSalesLine(SalesHeader, SalesLine, TempItemLedgEntryNotInvoiced, TempTrackingSpecification, HasInspection, QltyInspectionHeader);
    end;

    /// <summary>
    /// Creates inspections after a direct transfer line is posted as an inbound transfer.
    /// </summary>
    /// <param name="DirectTransLine">The posted direct transfer line.</param>
    /// <param name="DirectTransHeader">The posted direct transfer header.</param>
    /// <param name="TransLine">The source transfer line.</param>
    [InherentPermissions(PermissionObjectType::TableData, Database::"Qlty. Management Setup", 'R', InherentPermissionsScope::Permissions)]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Transfer", 'OnAfterInsertDirectTransLine', '', true, true)]
    local procedure HandleOnAfterInsertDirectTransLine(var DirectTransLine: Record "Direct Trans. Line"; DirectTransHeader: Record "Direct Trans. Header"; TransLine: Record "Transfer Line")
    var
        UnusedTransTransferReceiptHeader: Record "Transfer Receipt Header";
    begin
        if DetectIsPreviewPosting() then
            exit;

        if not QltyManagementSetup.GetSetupRecord() then
            exit;

        if not HasTransferOrderPostReceiveGenRule(ApplicableReceivingQltyInspectionGenRule) then
            exit;

        QltyBatchNotifHelper.BeginBatch();
        AttemptCreateInspectionWithReceiveTransferLine(TransLine, UnusedTransTransferReceiptHeader, DirectTransHeader);
        QltyBatchNotifHelper.EndBatch();
    end;

    /// <summary>
    /// Creates inspections after a transfer receipt line is posted.
    /// </summary>
    /// <param name="TransRcptLine">The posted transfer receipt line.</param>
    /// <param name="TransLine">The source transfer line.</param>
    /// <param name="CommitIsSuppressed">Indicates whether commits are suppressed.</param>
    /// <param name="TransferReceiptHeader">The posted transfer receipt header.</param>
    [InherentPermissions(PermissionObjectType::TableData, Database::"Qlty. Management Setup", 'R', InherentPermissionsScope::Permissions)]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Receipt", 'OnAfterInsertTransRcptLine', '', true, true)]
    local procedure HandleOnAfterInsertTransRcptLine(var TransRcptLine: Record "Transfer Receipt Line"; TransLine: Record "Transfer Line"; CommitIsSuppressed: Boolean; TransferReceiptHeader: Record "Transfer Receipt Header")
    var
        UnusedDirectTransHeader: Record "Direct Trans. Header";
    begin
        if DetectIsPreviewPosting() then
            exit;

        if not QltyManagementSetup.GetSetupRecord() then
            exit;

        if not HasTransferOrderPostReceiveGenRule(ApplicableReceivingQltyInspectionGenRule) then
            exit;

        QltyBatchNotifHelper.BeginBatch();
        AttemptCreateInspectionWithReceiveTransferLine(TransLine, TransferReceiptHeader, UnusedDirectTransHeader);
        QltyBatchNotifHelper.EndBatch();
    end;

    /// <summary>
    /// Creates inspections for purchase order lines after a purchase document is released.
    /// </summary>
    /// <param name="PurchaseHeader">The released purchase header.</param>
    /// <param name="PreviewMode">Indicates whether the release is running in preview mode.</param>
    /// <param name="LinesWereModified">Indicates whether release modified purchase lines.</param>
    /// <param name="SkipWhseRequestOperations">Indicates whether warehouse request operations are skipped.</param>
    [InherentPermissions(PermissionObjectType::TableData, Database::"Qlty. Management Setup", 'R', InherentPermissionsScope::Permissions)]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Purchase Document", 'OnAfterReleasePurchaseDoc', '', true, true)]
    local procedure HandleOnAfterReleasePurchDoc(var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean; var LinesWereModified: Boolean; SkipWhseRequestOperations: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        ReservationEntry: Record "Reservation Entry";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
    begin
        if PreviewMode then
            exit;

        if not QltyManagementSetup.GetSetupRecord() then
            exit;

        if not HasPurchaseOrderReleaseGenRule(ApplicableReceivingQltyInspectionGenRule) then
            exit;

        QltyBatchNotifHelper.BeginBatch();
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        if PurchaseLine.FindSet() then
            repeat
                Item.Get(PurchaseLine."No.");
                if Item."Item Tracking Code" <> '' then begin
                    Clear(ReservationEntry);
                    PurchaseLine.SetReservationFilters(ReservationEntry);
                    if ReservationEntry.FindSet() then
                        repeat
                            Clear(TempTrackingSpecification);
                            TempTrackingSpecification.DeleteAll(false);
                            TempTrackingSpecification.SetSourceFromReservEntry(ReservationEntry);
                            TempTrackingSpecification.CopyTrackingFromReservEntry(ReservationEntry);
                            TempTrackingSpecification."Quantity (Base)" := ReservationEntry."Quantity (Base)";
                            TempTrackingSpecification.Insert();
                            AttemptCreateInspectionWithPurchaseLineAndTracking(PurchaseLine, PurchaseHeader, TempTrackingSpecification);
                        until ReservationEntry.Next() = 0
                    else begin
                        Clear(TempTrackingSpecification);
                        AttemptCreateInspectionWithPurchaseLineAndTracking(PurchaseLine, PurchaseHeader, TempTrackingSpecification);
                    end;
                end else begin
                    Clear(TempTrackingSpecification);
                    AttemptCreateInspectionWithPurchaseLineAndTracking(PurchaseLine, PurchaseHeader, TempTrackingSpecification);
                end;
            until PurchaseLine.Next() = 0;
        QltyBatchNotifHelper.EndBatch();
    end;

    /// <summary>
    /// Attempts to create inspections for a warehouse receipt line and its source tracking details.
    /// </summary>
    /// <param name="WarehouseReceiptLine">The warehouse receipt line.</param>
    /// <param name="WarehouseReceiptHeader">The warehouse receipt header.</param>
    /// <param name="OptionalSourceLineVariant">The optional purchase, sales, or transfer source line.</param>
    local procedure AttemptCreateInspectionWithReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var OptionalSourceLineVariant: Variant)
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        TempQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary;
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        QltyWarehouseIntegration: Codeunit "Qlty. Warehouse Integration";
        IsHandled: Boolean;
        HasInspection: Boolean;
        DummyVariant: Variant;
    begin
        OnBeforeAttemptCreateInspectionWithReceiptLine(WarehouseReceiptLine, WarehouseReceiptHeader, OptionalSourceLineVariant, IsHandled);
        if IsHandled then
            exit;

        QltyBatchNotifHelper.ConfigureForBatch(QltyInspectionCreate);

        QltyWarehouseIntegration.CollectSourceItemTracking(OptionalSourceLineVariant, TempTrackingSpecification);

        TempTrackingSpecification.Reset();
        if TempTrackingSpecification.FindSet() then
            repeat
                TempQltyInspectionGenRule.DeleteAll();
                TempQltyInspectionGenRule.CopyFilters(ApplicableReceivingQltyInspectionGenRule);
                if QltyInspectionCreate.CreateInspectionWithMultiVariants(WarehouseReceiptLine, OptionalSourceLineVariant, WarehouseReceiptHeader, TempTrackingSpecification, false, TempQltyInspectionGenRule) then begin
                    HasInspection := true;
                    QltyInspectionCreate.GetCreatedInspection(QltyInspectionHeader);
                    QltyBatchNotifHelper.TrackCreatedInspection(QltyInspectionHeader."No.", QltyInspectionCreate.IsLastInspectionNewlyCreated());
                end;
            until TempTrackingSpecification.Next() = 0
        else begin
            TempQltyInspectionGenRule.CopyFilters(ApplicableReceivingQltyInspectionGenRule);
            if QltyInspectionCreate.CreateInspectionWithMultiVariants(WarehouseReceiptLine, OptionalSourceLineVariant, WarehouseReceiptHeader, DummyVariant, false, TempQltyInspectionGenRule) then begin
                HasInspection := true;
                QltyInspectionCreate.GetCreatedInspection(QltyInspectionHeader);
                QltyBatchNotifHelper.TrackCreatedInspection(QltyInspectionHeader."No.", QltyInspectionCreate.IsLastInspectionNewlyCreated());
            end;
        end;

        OnAfterAttemptCreateInspectionWithReceiptLine(HasInspection, QltyInspectionHeader, WarehouseReceiptLine, WarehouseReceiptHeader, OptionalSourceLineVariant, TempTrackingSpecification);
    end;

    /// <summary>
    /// Attempts to create inspections for a warehouse receipt journal line and its source tracking details.
    /// </summary>
    /// <param name="WarehouseJournalLine">The warehouse journal line.</param>
    /// <param name="PostedWhseReceiptHeader">The posted warehouse receipt header.</param>
    local procedure AttemptCreateInspectionWithWhseJournalLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header")
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        TempQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary;
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        QltyWarehouseIntegration: Codeunit "Qlty. Warehouse Integration";
        OptionalSourceRecordVariant: Variant;
        IsHandled: Boolean;
        HasInspection: Boolean;
        DummyVariant: Variant;
    begin
        OnBeforePurchaseAttemptCreateInspectionWithWhseJournalLine(WarehouseJournalLine, PostedWhseReceiptHeader, IsHandled);
        if IsHandled then
            exit;

        QltyBatchNotifHelper.ConfigureForBatch(QltyInspectionCreate);

        if QltyWarehouseIntegration.GetOptionalSourceVariantForWarehouseJournalLine(WarehouseJournalLine, OptionalSourceRecordVariant) then
            QltyWarehouseIntegration.CollectSourceItemTracking(OptionalSourceRecordVariant, TempTrackingSpecification);

        TempTrackingSpecification.Reset();
        if TempTrackingSpecification.FindSet() then
            repeat
                TempQltyInspectionGenRule.DeleteAll();
                TempQltyInspectionGenRule.CopyFilters(ApplicableReceivingQltyInspectionGenRule);
                if QltyInspectionCreate.CreateInspectionWithMultiVariants(WarehouseJournalLine, OptionalSourceRecordVariant, PostedWhseReceiptHeader, TempTrackingSpecification, false, TempQltyInspectionGenRule) then begin
                    HasInspection := true;
                    QltyInspectionCreate.GetCreatedInspection(QltyInspectionHeader);
                    QltyBatchNotifHelper.TrackCreatedInspection(QltyInspectionHeader."No.", QltyInspectionCreate.IsLastInspectionNewlyCreated());
                end;
            until TempTrackingSpecification.Next() = 0
        else begin
            TempQltyInspectionGenRule.CopyFilters(ApplicableReceivingQltyInspectionGenRule);
            if QltyInspectionCreate.CreateInspectionWithMultiVariants(WarehouseJournalLine, OptionalSourceRecordVariant, PostedWhseReceiptHeader, DummyVariant, false, TempQltyInspectionGenRule) then begin
                HasInspection := true;
                QltyInspectionCreate.GetCreatedInspection(QltyInspectionHeader);
                QltyBatchNotifHelper.TrackCreatedInspection(QltyInspectionHeader."No.", QltyInspectionCreate.IsLastInspectionNewlyCreated());
            end;
        end;

        OnAfterPurchaseAttemptCreateInspectionWithWhseJournalLine(HasInspection, QltyInspectionHeader, WarehouseJournalLine, PostedWhseReceiptHeader);
    end;

    /// <summary>
    /// Attempts to create an inspection for a purchase line and one set of tracking details.
    /// </summary>
    /// <param name="PurchaseLine">The purchase line.</param>
    /// <param name="PurchaseHeader">The purchase header.</param>
    /// <param name="TempTrackingSpecification">The temporary tracking details to associate with the inspection.</param>
    local procedure AttemptCreateInspectionWithPurchaseLineAndTracking(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary;
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        IsHandled: Boolean;
        HasInspection: Boolean;
        DummyVariant: Variant;
    begin
        OnBeforePurchaseAttemptCreateInspectionWithPurchaseLine(PurchaseLine, PurchaseHeader, TempTrackingSpecification, IsHandled);
        if IsHandled then
            exit;

        QltyBatchNotifHelper.ConfigureForBatch(QltyInspectionCreate);

        TempQltyInspectionGenRule.CopyFilters(ApplicableReceivingQltyInspectionGenRule);
        HasInspection := QltyInspectionCreate.CreateInspectionWithMultiVariants(PurchaseLine, PurchaseHeader, TempTrackingSpecification, DummyVariant, false, TempQltyInspectionGenRule);
        if HasInspection then begin
            QltyInspectionCreate.GetCreatedInspection(QltyInspectionHeader);
            QltyBatchNotifHelper.TrackCreatedInspection(QltyInspectionHeader."No.", QltyInspectionCreate.IsLastInspectionNewlyCreated());
        end;

        OnAfterPurchaseAttemptCreateInspectionWithPurchaseLine(HasInspection, QltyInspectionHeader, PurchaseLine, PurchaseHeader, TempTrackingSpecification);
    end;

    /// <summary>
    /// Attempts to create inspections for an inbound transfer line and its available posted header.
    /// </summary>
    /// <param name="TransTransferLine">The source transfer line.</param>
    /// <param name="OptionalTransferReceiptHeader">The posted transfer receipt header, when available.</param>
    /// <param name="OptionalDirectTransHeader">The posted direct transfer header, when available.</param>
    local procedure AttemptCreateInspectionWithReceiveTransferLine(var TransTransferLine: Record "Transfer Line"; var OptionalTransferReceiptHeader: Record "Transfer Receipt Header"; var OptionalDirectTransHeader: Record "Direct Trans. Header")
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        TempQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary;
        QltyWarehouseIntegration: Codeunit "Qlty. Warehouse Integration";
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        IsHandled: Boolean;
        HasInspection: Boolean;
        CurrentVariant: Variant;

    begin
        OnBeforeAttemptCreateInspectionWithInboundTransferLine(TransTransferLine, OptionalTransferReceiptHeader, OptionalDirectTransHeader, TempTrackingSpecification, QltyInspectionHeader, HasInspection, IsHandled);
        if IsHandled then
            exit;

        QltyBatchNotifHelper.ConfigureForBatch(QltyInspectionCreate);

        CurrentVariant := TransTransferLine;
        QltyWarehouseIntegration.CollectSourceItemTracking(CurrentVariant, TempTrackingSpecification);
        TempTrackingSpecification.Reset();
        if TempTrackingSpecification.FindSet() then
            repeat
                TempQltyInspectionGenRule.DeleteAll();
                TempQltyInspectionGenRule.CopyFilters(ApplicableReceivingQltyInspectionGenRule);
                if OptionalTransferReceiptHeader."No." <> '' then
                    HasInspection := QltyInspectionCreate.CreateInspectionWithMultiVariants(TransTransferLine, OptionalTransferReceiptHeader, TempTrackingSpecification, OptionalDirectTransHeader, false, TempQltyInspectionGenRule);

                if OptionalDirectTransHeader."No." <> '' then
                    HasInspection := QltyInspectionCreate.CreateInspectionWithMultiVariants(TransTransferLine, OptionalDirectTransHeader, TempTrackingSpecification, OptionalTransferReceiptHeader, false, TempQltyInspectionGenRule);

                if HasInspection then begin
                    QltyInspectionCreate.GetCreatedInspection(QltyInspectionHeader);
                    QltyBatchNotifHelper.TrackCreatedInspection(QltyInspectionHeader."No.", QltyInspectionCreate.IsLastInspectionNewlyCreated());
                end;
            until TempTrackingSpecification.Next() = 0
        else begin
            TempQltyInspectionGenRule.CopyFilters(ApplicableReceivingQltyInspectionGenRule);
            if OptionalTransferReceiptHeader."No." <> '' then
                HasInspection := QltyInspectionCreate.CreateInspectionWithMultiVariants(TransTransferLine, OptionalTransferReceiptHeader, OptionalDirectTransHeader, TempTrackingSpecification, false, TempQltyInspectionGenRule);

            if OptionalDirectTransHeader."No." <> '' then
                HasInspection := QltyInspectionCreate.CreateInspectionWithMultiVariants(TransTransferLine, OptionalDirectTransHeader, OptionalTransferReceiptHeader, TempTrackingSpecification, false, TempQltyInspectionGenRule);

            if HasInspection then begin
                QltyInspectionCreate.GetCreatedInspection(QltyInspectionHeader);
                QltyBatchNotifHelper.TrackCreatedInspection(QltyInspectionHeader."No.", QltyInspectionCreate.IsLastInspectionNewlyCreated());
            end;
        end;
        OnAfterTransferAttemptCreateInspectionWithInboundTransferLine(TransTransferLine, OptionalTransferReceiptHeader, OptionalDirectTransHeader, TempTrackingSpecification, QltyInspectionHeader, HasInspection);
    end;

    /// <summary>
    /// Determines whether general journal posting preview is active.
    /// </summary>
    /// <returns>True if posting preview is active; otherwise, false.</returns>
    local procedure DetectIsPreviewPosting() IsInPreviewPostingMode: Boolean
    var
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        IsInPreviewPostingMode := GenJnlPostPreview.IsActive();
    end;

    /// <summary>
    /// Filters generation rules for automatic purchase order receipt posting.
    /// </summary>
    /// <param name="QltyInspectionGenRule">The generation rule record on which the applicable filters are set.</param>
    /// <returns>True if at least one applicable generation rule exists; otherwise, false.</returns>
    [InherentPermissions(PermissionObjectType::TableData, Database::"Qlty. Inspection Gen. Rule", 'R', InherentPermissionsScope::Permissions)]
    local procedure HasPurchaseOrderPostReceiveGenRule(var QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule"): Boolean
    begin
        QltyInspectionGenRule.Reset();
        QltyInspectionGenRule.SetRange("Purchase Order Trigger", QltyInspectionGenRule."Purchase Order Trigger"::OnPurchaseOrderPostReceive);
        QltyInspectionGenRule.SetFilter("Activation Trigger", '%1|%2', QltyInspectionGenRule."Activation Trigger"::"Manual or Automatic", QltyInspectionGenRule."Activation Trigger"::"Automatic only");
        exit(not QltyInspectionGenRule.IsEmpty());
    end;

    /// <summary>
    /// Filters generation rules for automatic warehouse receipt posting.
    /// </summary>
    /// <param name="QltyInspectionGenRule">The generation rule record on which the applicable filters are set.</param>
    /// <returns>True if at least one applicable generation rule exists; otherwise, false.</returns>
    [InherentPermissions(PermissionObjectType::TableData, Database::"Qlty. Inspection Gen. Rule", 'R', InherentPermissionsScope::Permissions)]
    local procedure HasWarehouseReceiptPostGenRule(var QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule"): Boolean
    begin
        QltyInspectionGenRule.Reset();
        QltyInspectionGenRule.SetRange("Warehouse Receipt Trigger", QltyInspectionGenRule."Warehouse Receipt Trigger"::OnWarehouseReceiptPost);
        QltyInspectionGenRule.SetFilter("Activation Trigger", '%1|%2', QltyInspectionGenRule."Activation Trigger"::"Manual or Automatic", QltyInspectionGenRule."Activation Trigger"::"Automatic only");
        exit(not QltyInspectionGenRule.IsEmpty());
    end;

    /// <summary>
    /// Filters generation rules for automatic warehouse receipt creation.
    /// </summary>
    /// <param name="QltyInspectionGenRule">The generation rule record on which the applicable filters are set.</param>
    /// <returns>True if at least one applicable generation rule exists; otherwise, false.</returns>
    [InherentPermissions(PermissionObjectType::TableData, Database::"Qlty. Inspection Gen. Rule", 'R', InherentPermissionsScope::Permissions)]
    local procedure HasWarehouseReceiptCreateGenRule(var QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule"): Boolean
    begin
        QltyInspectionGenRule.Reset();
        QltyInspectionGenRule.SetRange("Warehouse Receipt Trigger", QltyInspectionGenRule."Warehouse Receipt Trigger"::OnWarehouseReceiptCreate);
        QltyInspectionGenRule.SetFilter("Activation Trigger", '%1|%2', QltyInspectionGenRule."Activation Trigger"::"Manual or Automatic", QltyInspectionGenRule."Activation Trigger"::"Automatic only");
        exit(not QltyInspectionGenRule.IsEmpty());
    end;

    /// <summary>
    /// Filters generation rules for automatic sales return receipt posting.
    /// </summary>
    /// <param name="QltyInspectionGenRule">The generation rule record on which the applicable filters are set.</param>
    /// <returns>True if at least one applicable generation rule exists; otherwise, false.</returns>
    [InherentPermissions(PermissionObjectType::TableData, Database::"Qlty. Inspection Gen. Rule", 'R', InherentPermissionsScope::Permissions)]
    local procedure HasSalesReturnOrderPostReceiveGenRule(var QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule"): Boolean
    begin
        QltyInspectionGenRule.Reset();
        QltyInspectionGenRule.SetRange("Sales Return Trigger", QltyInspectionGenRule."Sales Return Trigger"::OnSalesReturnOrderPostReceive);
        QltyInspectionGenRule.SetFilter("Activation Trigger", '%1|%2', QltyInspectionGenRule."Activation Trigger"::"Manual or Automatic", QltyInspectionGenRule."Activation Trigger"::"Automatic only");
        exit(not QltyInspectionGenRule.IsEmpty());
    end;

    /// <summary>
    /// Filters generation rules for automatic inbound transfer receipt posting.
    /// </summary>
    /// <param name="QltyInspectionGenRule">The generation rule record on which the applicable filters are set.</param>
    /// <returns>True if at least one applicable generation rule exists; otherwise, false.</returns>
    [InherentPermissions(PermissionObjectType::TableData, Database::"Qlty. Inspection Gen. Rule", 'R', InherentPermissionsScope::Permissions)]
    local procedure HasTransferOrderPostReceiveGenRule(var QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule"): Boolean
    begin
        QltyInspectionGenRule.Reset();
        QltyInspectionGenRule.SetRange("Transfer Order Trigger", QltyInspectionGenRule."Transfer Order Trigger"::OnTransferOrderPostReceive);
        QltyInspectionGenRule.SetFilter("Activation Trigger", '%1|%2', QltyInspectionGenRule."Activation Trigger"::"Manual or Automatic", QltyInspectionGenRule."Activation Trigger"::"Automatic only");
        exit(not QltyInspectionGenRule.IsEmpty());
    end;

    /// <summary>
    /// Filters generation rules for automatic purchase order release.
    /// </summary>
    /// <param name="QltyInspectionGenRule">The generation rule record on which the applicable filters are set.</param>
    /// <returns>True if at least one applicable generation rule exists; otherwise, false.</returns>
    [InherentPermissions(PermissionObjectType::TableData, Database::"Qlty. Inspection Gen. Rule", 'R', InherentPermissionsScope::Permissions)]
    local procedure HasPurchaseOrderReleaseGenRule(var QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule"): Boolean
    begin
        QltyInspectionGenRule.Reset();
        QltyInspectionGenRule.SetRange("Purchase Order Trigger", QltyInspectionGenRule."Purchase Order Trigger"::OnPurchaseOrderRelease);
        QltyInspectionGenRule.SetFilter("Activation Trigger", '%1|%2', QltyInspectionGenRule."Activation Trigger"::"Manual or Automatic", QltyInspectionGenRule."Activation Trigger"::"Automatic only");
        exit(not QltyInspectionGenRule.IsEmpty());
    end;

    /// <summary>
    /// Notifies subscribers before inspections are created from a warehouse receipt line.
    /// </summary>
    /// <param name="WarehouseReceiptLine">The warehouse receipt line.</param>
    /// <param name="WarehouseReceiptHeader">The warehouse receipt header.</param>
    /// <param name="OptionalSourceLineVariant">The optional purchase, sales, or transfer source line.</param>
    /// <param name="IsHandled">Set to true to skip the default inspection creation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeAttemptCreateInspectionWithReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var OptionalSourceLineVariant: Variant; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Notifies subscribers after inspection creation is attempted for a warehouse receipt line.
    /// </summary>
    /// <param name="HasInspection">Indicates whether an inspection was created or resolved.</param>
    /// <param name="QltyInspectionHeader">The last inspection created or resolved.</param>
    /// <param name="WarehouseReceiptLine">The warehouse receipt line.</param>
    /// <param name="WarehouseReceiptHeader">The warehouse receipt header.</param>
    /// <param name="OptionalSourceLineVariant">The optional purchase, sales, or transfer source line.</param>
    /// <param name="TempTrackingSpecification">The temporary tracking details collected from the source line.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterAttemptCreateInspectionWithReceiptLine(var HasInspection: Boolean; var QltyInspectionHeader: Record "Qlty. Inspection Header"; var WarehouseReceiptLine: Record "Warehouse Receipt Line"; var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var OptionalSourceLineVariant: Variant; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    /// <summary>
    /// Notifies subscribers before inspections are created from a warehouse receipt journal line.
    /// </summary>
    /// <param name="WarehouseJournalLine">The warehouse journal line.</param>
    /// <param name="PostedWhseReceiptHeader">The posted warehouse receipt header.</param>
    /// <param name="IsHandled">Set to true to skip the default inspection creation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchaseAttemptCreateInspectionWithWhseJournalLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Notifies subscribers after inspection creation is attempted for a warehouse receipt journal line.
    /// </summary>
    /// <param name="HasInspection">Indicates whether an inspection was created or resolved.</param>
    /// <param name="QltyInspectionHeader">The last inspection created or resolved.</param>
    /// <param name="WarehouseJournalLine">The warehouse journal line.</param>
    /// <param name="PostedWhseReceiptHeader">The posted warehouse receipt header.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchaseAttemptCreateInspectionWithWhseJournalLine(var HasInspection: Boolean; var QltyInspectionHeader: Record "Qlty. Inspection Header"; var WarehouseJournalLine: Record "Warehouse Journal Line"; PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header")
    begin
    end;

    /// <summary>
    /// Notifies subscribers before an inspection is created from a purchase line.
    /// </summary>
    /// <param name="PurchaseLine">The purchase line.</param>
    /// <param name="PurchaseHeader">The purchase header.</param>
    /// <param name="TempTrackingSpecification">The temporary tracking details for the purchase line.</param>
    /// <param name="IsHandled">Set to true to skip the default inspection creation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchaseAttemptCreateInspectionWithPurchaseLine(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Notifies subscribers after inspection creation is attempted for a purchase line.
    /// </summary>
    /// <param name="HasInspection">Indicates whether an inspection was created or resolved.</param>
    /// <param name="QltyInspectionHeader">The inspection created or resolved.</param>
    /// <param name="PurchaseLine">The purchase line.</param>
    /// <param name="PurchaseHeader">The purchase header.</param>
    /// <param name="TempTrackingSpecification">The temporary tracking details for the purchase line.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchaseAttemptCreateInspectionWithPurchaseLine(var HasInspection: Boolean; var QltyInspectionHeader: Record "Qlty. Inspection Header"; var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    /// <summary>
    /// Notifies subscribers before inspections are created from a sales return line.
    /// </summary>
    /// <param name="SalesHeader">The sales return order header.</param>
    /// <param name="SalesLine">The sales return line.</param>
    /// <param name="TempLedgNotInvoicedItemLedgerEntry">Temporary non-invoiced item ledger entries supplied by posting.</param>
    /// <param name="TempTrackingSpecification">The temporary tracking details collected for the return line.</param>
    /// <param name="IsHandled">Set to true to skip the default inspection creation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesReturnCreateInspectionWithSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var TempLedgNotInvoicedItemLedgerEntry: Record "Item Ledger Entry" temporary; var TempTrackingSpecification: Record "Tracking Specification" temporary; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Notifies subscribers after inspection creation is attempted for a sales return line.
    /// </summary>
    /// <param name="SalesHeader">The sales return order header.</param>
    /// <param name="SalesLine">The sales return line.</param>
    /// <param name="TempLedgNotInvoicedItemLedgerEntry">Temporary non-invoiced item ledger entries supplied by posting.</param>
    /// <param name="TempTrackingSpecification">The temporary tracking details collected for the return line.</param>
    /// <param name="HasInspection">Indicates whether an inspection was created or resolved.</param>
    /// <param name="QltyInspectionHeader">The last inspection created or resolved.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesReturnCreateInspectionWithSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var TempLedgNotInvoicedItemLedgerEntry: Record "Item Ledger Entry" temporary; var TempTrackingSpecification: Record "Tracking Specification" temporary; var HasInspection: Boolean; var QltyInspectionHeader: Record "Qlty. Inspection Header")
    begin
    end;

    /// <summary>
    /// Notifies subscribers before inspections are created from an inbound transfer line.
    /// </summary>
    /// <param name="TransTransferLine">The source transfer line.</param>
    /// <param name="TransferReceiptHeader">The posted transfer receipt header, when available.</param>
    /// <param name="DirectTransHeader">The posted direct transfer header, when available.</param>
    /// <param name="TempSpecTrackingSpecification">The temporary tracking details available to the subscriber.</param>
    /// <param name="QltyInspectionHeader">The inspection header available to the subscriber.</param>
    /// <param name="HasInspection">Indicates whether an inspection was created or resolved.</param>
    /// <param name="IsHandled">Set to true to skip the default inspection creation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeAttemptCreateInspectionWithInboundTransferLine(var TransTransferLine: Record "Transfer Line"; var TransferReceiptHeader: Record "Transfer Receipt Header"; var DirectTransHeader: Record "Direct Trans. Header"; var TempSpecTrackingSpecification: Record "Tracking Specification" temporary; var QltyInspectionHeader: Record "Qlty. Inspection Header"; var HasInspection: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Notifies subscribers after inspection creation is attempted for an inbound transfer line.
    /// </summary>
    /// <param name="TransTransferLine">The source transfer line.</param>
    /// <param name="TransferReceiptHeader">The posted transfer receipt header, when available.</param>
    /// <param name="DirectTransHeader">The posted direct transfer header, when available.</param>
    /// <param name="TempSpecTrackingSpecification">The temporary tracking details collected for the transfer line.</param>
    /// <param name="QltyInspectionHeader">The last inspection created or resolved.</param>
    /// <param name="HasInspection">Indicates whether an inspection was created or resolved.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferAttemptCreateInspectionWithInboundTransferLine(var TransTransferLine: Record "Transfer Line"; var TransferReceiptHeader: Record "Transfer Receipt Header"; var DirectTransHeader: Record "Direct Trans. Header"; var TempSpecTrackingSpecification: Record "Tracking Specification" temporary; var QltyInspectionHeader: Record "Qlty. Inspection Header"; var HasInspection: Boolean)
    begin
    end;
}