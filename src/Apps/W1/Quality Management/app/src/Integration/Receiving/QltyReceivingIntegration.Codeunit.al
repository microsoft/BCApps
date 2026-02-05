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
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Posting;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Journal;

codeunit 20411 "Qlty. Receiving Integration"
{
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        ApplicableReceivingQltyInspectCreationRule: Record "Qlty. Inspect. Creation Rule";

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

        ApplicableReceivingQltyInspectCreationRule.Reset();
        ApplicableReceivingQltyInspectCreationRule.SetRange("Purchase Order Trigger", ApplicableReceivingQltyInspectCreationRule."Purchase Order Trigger"::OnPurchaseOrderPostReceive);
        ApplicableReceivingQltyInspectCreationRule.SetFilter("Activation Trigger", '%1|%2', ApplicableReceivingQltyInspectCreationRule."Activation Trigger"::"Manual or Automatic", ApplicableReceivingQltyInspectCreationRule."Activation Trigger"::"Automatic only");
        if ApplicableReceivingQltyInspectCreationRule.IsEmpty() then
            exit;
        if PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.") then;

        TempTrackingSpecification.SetFilter("Quantity Handled (Base)", '<>0');
        TempTrackingSpecification.SetFilter("Buffer Status", '<>%1', TempTrackingSpecification."Buffer Status"::MODIFY);
        TempTrackingSpecification.SetRange("Item No.", PurchaseLine."No.");
        TempTrackingSpecification.SetRange("Source ID", PurchaseLine."Document No.");
        TempTrackingSpecification.SetRange("Source Ref. No.", PurchaseLine."Line No.");
        TempTrackingSpecification.SetRange("Source Type", Database::"Purchase Line");

        ExpectedCountOfInspections := TempTrackingSpecification.Count();
        if ExpectedCountOfInspections = 0 then begin
            ExpectedCountOfInspections := 1;
            if not ApplicableReceivingQltyInspectCreationRule.IsEmpty() then begin
                TempSingleBufferTrackingSpecification.Init();
                TempSingleBufferTrackingSpecification.Insert(false);
                AttemptCreateInspectionWithPurchaseLineAndTracking(PurchaseLine, PurchaseHeader, TempSingleBufferTrackingSpecification);
            end
        end else
            if not ApplicableReceivingQltyInspectCreationRule.IsEmpty() then
                if TempTrackingSpecification.FindSet() then
                    repeat
                        Clear(TempSingleBufferTrackingSpecification);
                        TempSingleBufferTrackingSpecification := TempTrackingSpecification;
                        TempSingleBufferTrackingSpecification.Insert(false);
                        TempSingleBufferTrackingSpecification.SetRecFilter();
                        AttemptCreateInspectionWithPurchaseLineAndTracking(PurchaseLine, PurchaseHeader, TempTrackingSpecification);
                    until TempTrackingSpecification.Next() = 0;

        TempTrackingSpecification.SetRange("Qty. to Invoice (Base)");
        TempTrackingSpecification.SetRange("Source ID");
        TempTrackingSpecification.SetRange("Source Ref. No.");
        TempTrackingSpecification.SetRange("Source Type");
        TempTrackingSpecification.SetRange("Item No.");
        TempTrackingSpecification.SetRange("Buffer Status");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Receipt", 'OnPostWhseJnlLineOnBeforeWhseJnlRegisterLineRun', '', true, true)]
    local procedure HandleOnPostWhseJnlLineOnBeforeWhseJnlRegisterLineRun(var WarehouseJournalLine: Record "Warehouse Journal Line"; PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header")
    begin
        if DetectIsPreviewPosting() then
            exit;

        if not QltyManagementSetup.GetSetupRecord() then
            exit;

        ApplicableReceivingQltyInspectCreationRule.Reset();
        ApplicableReceivingQltyInspectCreationRule.SetRange("Warehouse Receipt Trigger", ApplicableReceivingQltyInspectCreationRule."Warehouse Receipt Trigger"::OnWarehouseReceiptPost);
        ApplicableReceivingQltyInspectCreationRule.SetFilter("Activation Trigger", '%1|%2', ApplicableReceivingQltyInspectCreationRule."Activation Trigger"::"Manual or Automatic", ApplicableReceivingQltyInspectCreationRule."Activation Trigger"::"Automatic only");
        if not ApplicableReceivingQltyInspectCreationRule.IsEmpty() then
            AttemptCreateInspectionWithWhseJournalLine(WarehouseJournalLine, PostedWhseReceiptHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purchases Warehouse Mgt.", 'OnAfterCreateRcptLineFromPurchLine', '', true, true)]
    local procedure HandleOnAfterCreateRcptLineFromPurchLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; WarehouseReceiptHeader: Record "Warehouse Receipt Header"; PurchaseLine: Record "Purchase Line")
    var
        OptionalSource: Variant;
    begin
        if DetectIsPreviewPosting() then
            exit;

        if not QltyManagementSetup.GetSetupRecord() then
            exit;

        ApplicableReceivingQltyInspectCreationRule.Reset();
        ApplicableReceivingQltyInspectCreationRule.SetRange("Warehouse Receipt Trigger", ApplicableReceivingQltyInspectCreationRule."Warehouse Receipt Trigger"::OnWarehouseReceiptCreate);
        ApplicableReceivingQltyInspectCreationRule.SetFilter("Activation Trigger", '%1|%2', ApplicableReceivingQltyInspectCreationRule."Activation Trigger"::"Manual or Automatic", ApplicableReceivingQltyInspectCreationRule."Activation Trigger"::"Automatic only");
        if not ApplicableReceivingQltyInspectCreationRule.IsEmpty() then begin
            OptionalSource := PurchaseLine;
            AttemptCreateInspectionWithReceiptLine(WarehouseReceiptLine, WarehouseReceiptHeader, OptionalSource);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforePostItemTrackingLine', '', true, true)]
    local procedure HandleOnBeforePostItemTrackingLine(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var TempItemLedgEntryNotInvoiced: Record "Item Ledger Entry" temporary; HasATOShippedNotInvoiced: Boolean; var IsHandled: Boolean; var ItemLedgShptEntryNo: Integer; var RemQtyToBeInvoiced: Decimal; var RemQtyToBeInvoicedBase: Decimal; SalesInvoiceHeader: Record "Sales Invoice Header"; SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        QltyInspectCreationRule: Record "Qlty. Inspect. Creation Rule";
        QltyWarehouseIntegration: Codeunit "Qlty. - Warehouse Integration";
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        Handled: Boolean;
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

        QltyInspectCreationRule.SetRange("Sales Return Trigger", QltyInspectCreationRule."Sales Return Trigger"::OnSalesReturnOrderPostReceive);
        QltyInspectCreationRule.SetFilter("Activation Trigger", '%1|%2', QltyInspectCreationRule."Activation Trigger"::"Manual or Automatic", QltyInspectCreationRule."Activation Trigger"::"Automatic only");
        if not QltyInspectCreationRule.IsEmpty() then begin
            SourceVariant := SalesLine;
            QltyWarehouseIntegration.CollectSourceItemTracking(SourceVariant, TempTrackingSpecification);
            OnBeforeSalesReturnCreateInspectionWithSalesLine(SalesHeader, SalesLine, TempItemLedgEntryNotInvoiced, TempTrackingSpecification, Handled);
            if Handled then
                exit;

            TempTrackingSpecification.Reset();
            if TempTrackingSpecification.FindSet() then
                repeat
                    if QltyInspectionCreate.CreateInspectionWithMultiVariants(SalesLine, TempTrackingSpecification, DummyVariant, DummyVariant, false, QltyInspectCreationRule) then begin
                        HasInspection := true;
                        QltyInspectionCreate.GetCreatedInspection(QltyInspectionHeader);
                    end;
                until TempTrackingSpecification.Next() = 0
            else
                if QltyInspectionCreate.CreateInspectionWithMultiVariants(SalesLine, DummyVariant, DummyVariant, DummyVariant, false, QltyInspectCreationRule) then begin
                    HasInspection := true;
                    QltyInspectionCreate.GetCreatedInspection(QltyInspectionHeader);
                end;
        end;

        OnAfterSalesReturnCreateInspectionWithSalesLine(SalesHeader, SalesLine, TempItemLedgEntryNotInvoiced, TempTrackingSpecification, HasInspection, QltyInspectionHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Transfer", 'OnAfterInsertDirectTransLine', '', true, true)]
    local procedure HandleOnAfterInsertDirectTransLine(var DirectTransLine: Record "Direct Trans. Line"; DirectTransHeader: Record "Direct Trans. Header"; TransLine: Record "Transfer Line")
    var
        UnusedTransTransferReceiptHeader: Record "Transfer Receipt Header";
    begin
        if DetectIsPreviewPosting() then
            exit;

        if not QltyManagementSetup.GetSetupRecord() then
            exit;

        ApplicableReceivingQltyInspectCreationRule.Reset();
        ApplicableReceivingQltyInspectCreationRule.SetRange("Transfer Order Trigger", ApplicableReceivingQltyInspectCreationRule."Transfer Order Trigger"::OnTransferOrderPostReceive);
        ApplicableReceivingQltyInspectCreationRule.SetFilter("Activation Trigger", '%1|%2', ApplicableReceivingQltyInspectCreationRule."Activation Trigger"::"Manual or Automatic", ApplicableReceivingQltyInspectCreationRule."Activation Trigger"::"Automatic only");
        if not ApplicableReceivingQltyInspectCreationRule.IsEmpty() then
            AttemptCreateInspectionWithReceiveTransferLine(TransLine, UnusedTransTransferReceiptHeader, DirectTransHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Receipt", 'OnAfterInsertTransRcptLine', '', true, true)]
    local procedure HandleOnAfterInsertTransRcptLine(var TransRcptLine: Record "Transfer Receipt Line"; TransLine: Record "Transfer Line"; CommitIsSuppressed: Boolean; TransferReceiptHeader: Record "Transfer Receipt Header")
    var
        UnusedDirectTransHeader: Record "Direct Trans. Header";
    begin
        if DetectIsPreviewPosting() then
            exit;

        if not QltyManagementSetup.GetSetupRecord() then
            exit;

        ApplicableReceivingQltyInspectCreationRule.Reset();
        ApplicableReceivingQltyInspectCreationRule.SetRange("Transfer Order Trigger", ApplicableReceivingQltyInspectCreationRule."Transfer Order Trigger"::OnTransferOrderPostReceive);
        ApplicableReceivingQltyInspectCreationRule.SetFilter("Activation Trigger", '%1|%2', ApplicableReceivingQltyInspectCreationRule."Activation Trigger"::"Manual or Automatic", ApplicableReceivingQltyInspectCreationRule."Activation Trigger"::"Automatic only");
        if not ApplicableReceivingQltyInspectCreationRule.IsEmpty() then
            AttemptCreateInspectionWithReceiveTransferLine(TransLine, TransferReceiptHeader, UnusedDirectTransHeader);
    end;

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

        ApplicableReceivingQltyInspectCreationRule.Reset();
        ApplicableReceivingQltyInspectCreationRule.SetRange("Purchase Order Trigger", ApplicableReceivingQltyInspectCreationRule."Purchase Order Trigger"::OnPurchaseOrderRelease);
        ApplicableReceivingQltyInspectCreationRule.SetFilter("Activation Trigger", '%1|%2', ApplicableReceivingQltyInspectCreationRule."Activation Trigger"::"Manual or Automatic", ApplicableReceivingQltyInspectCreationRule."Activation Trigger"::"Automatic only");
        if ApplicableReceivingQltyInspectCreationRule.IsEmpty() then
            exit;

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
                            TempTrackingSpecification."Package No." := ReservationEntry."Package No.";
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
    end;

    local procedure AttemptCreateInspectionWithReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var OptionalSourceLineVariant: Variant)
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        TempQltyInspectCreationRule: Record "Qlty. Inspect. Creation Rule" temporary;
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        QltyWarehouseIntegration: Codeunit "Qlty. - Warehouse Integration";
        Handled: Boolean;
        HasInspection: Boolean;
        DummyVariant: Variant;
    begin
        OnBeforeAttemptCreateInspectionWithReceiptLine(WarehouseReceiptLine, WarehouseReceiptHeader, OptionalSourceLineVariant, Handled);
        if Handled then
            exit;

        QltyWarehouseIntegration.CollectSourceItemTracking(OptionalSourceLineVariant, TempTrackingSpecification);

        TempTrackingSpecification.Reset();
        if TempTrackingSpecification.FindSet() then
            repeat
                TempQltyInspectCreationRule.DeleteAll();
                TempQltyInspectCreationRule.CopyFilters(ApplicableReceivingQltyInspectCreationRule);
                if QltyInspectionCreate.CreateInspectionWithMultiVariants(WarehouseReceiptLine, OptionalSourceLineVariant, WarehouseReceiptHeader, TempTrackingSpecification, false, TempQltyInspectCreationRule) then begin
                    HasInspection := true;
                    QltyInspectionCreate.GetCreatedInspection(QltyInspectionHeader);
                end;
            until TempTrackingSpecification.Next() = 0
        else begin
            TempQltyInspectCreationRule.CopyFilters(ApplicableReceivingQltyInspectCreationRule);
            if QltyInspectionCreate.CreateInspectionWithMultiVariants(WarehouseReceiptLine, OptionalSourceLineVariant, WarehouseReceiptHeader, DummyVariant, false, TempQltyInspectCreationRule) then begin
                HasInspection := true;
                QltyInspectionCreate.GetCreatedInspection(QltyInspectionHeader);
            end;
        end;

        OnAfterAttemptCreateInspectionWithReceiptLine(HasInspection, QltyInspectionHeader, WarehouseReceiptLine, WarehouseReceiptHeader, OptionalSourceLineVariant, TempTrackingSpecification, Handled);
    end;

    local procedure AttemptCreateInspectionWithWhseJournalLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header")
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        TempQltyInspectCreationRule: Record "Qlty. Inspect. Creation Rule" temporary;
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        QltyWarehouseIntegration: Codeunit "Qlty. - Warehouse Integration";
        OptionalSourceRecordVariant: Variant;
        Handled: Boolean;
        HasInspection: Boolean;
        DummyVariant: Variant;
    begin
        OnBeforePurchaseAttemptCreateInspectionWithWhseJournalLine(WarehouseJournalLine, PostedWhseReceiptHeader, Handled);
        if Handled then
            exit;

        if QltyWarehouseIntegration.GetOptionalSourceVariantForWarehouseJournalLine(WarehouseJournalLine, OptionalSourceRecordVariant) then
            QltyWarehouseIntegration.CollectSourceItemTracking(OptionalSourceRecordVariant, TempTrackingSpecification);

        TempTrackingSpecification.Reset();
        if TempTrackingSpecification.FindSet() then
            repeat
                TempQltyInspectCreationRule.DeleteAll();
                TempQltyInspectCreationRule.CopyFilters(ApplicableReceivingQltyInspectCreationRule);
                if QltyInspectionCreate.CreateInspectionWithMultiVariants(WarehouseJournalLine, OptionalSourceRecordVariant, PostedWhseReceiptHeader, TempTrackingSpecification, false, TempQltyInspectCreationRule) then begin
                    HasInspection := true;
                    QltyInspectionCreate.GetCreatedInspection(QltyInspectionHeader);
                end;
            until TempTrackingSpecification.Next() = 0
        else begin
            TempQltyInspectCreationRule.CopyFilters(ApplicableReceivingQltyInspectCreationRule);
            if QltyInspectionCreate.CreateInspectionWithMultiVariants(WarehouseJournalLine, OptionalSourceRecordVariant, PostedWhseReceiptHeader, DummyVariant, false, TempQltyInspectCreationRule) then begin
                HasInspection := true;
                QltyInspectionCreate.GetCreatedInspection(QltyInspectionHeader);
            end;
        end;

        OnAfterPurchaseAttemptCreateInspectionWithWhseJournalLine(HasInspection, QltyInspectionHeader, WarehouseJournalLine, PostedWhseReceiptHeader, Handled);
    end;

    local procedure AttemptCreateInspectionWithPurchaseLineAndTracking(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempQltyInspectCreationRule: Record "Qlty. Inspect. Creation Rule" temporary;
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        Handled: Boolean;
        HasInspection: Boolean;
        DummyVariant: Variant;
    begin
        OnBeforePurchaseAttemptCreateInspectionWithPurchaseLine(PurchaseLine, PurchaseHeader, TempTrackingSpecification, Handled);
        if Handled then
            exit;

        TempQltyInspectCreationRule.CopyFilters(ApplicableReceivingQltyInspectCreationRule);
        HasInspection := QltyInspectionCreate.CreateInspectionWithMultiVariants(PurchaseLine, PurchaseHeader, TempTrackingSpecification, DummyVariant, false, TempQltyInspectCreationRule);
        if HasInspection then
            QltyInspectionCreate.GetCreatedInspection(QltyInspectionHeader);

        OnAfterPurchaseAttemptCreateInspectionWithPurchaseLine(HasInspection, QltyInspectionHeader, PurchaseLine, PurchaseHeader, TempTrackingSpecification, Handled);
    end;

    local procedure AttemptCreateInspectionWithReceiveTransferLine(var TransTransferLine: Record "Transfer Line"; var OptionalTransferReceiptHeader: Record "Transfer Receipt Header"; var OptionalDirectTransHeader: Record "Direct Trans. Header")
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        TempQltyInspectCreationRule: Record "Qlty. Inspect. Creation Rule" temporary;
        QltyWarehouseIntegration: Codeunit "Qlty. - Warehouse Integration";
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        Handled: Boolean;
        HasInspection: Boolean;
        CurrentVariant: Variant;

    begin
        OnBeforeAttemptCreateInspectionWithInboundTransferLine(TransTransferLine, OptionalTransferReceiptHeader, OptionalDirectTransHeader, TempTrackingSpecification, QltyInspectionHeader, HasInspection, Handled);
        if Handled then
            exit;
        CurrentVariant := TransTransferLine;
        QltyWarehouseIntegration.CollectSourceItemTracking(CurrentVariant, TempTrackingSpecification);
        TempTrackingSpecification.Reset();
        if TempTrackingSpecification.FindSet() then
            repeat
                TempQltyInspectCreationRule.DeleteAll();
                TempQltyInspectCreationRule.CopyFilters(ApplicableReceivingQltyInspectCreationRule);
                if OptionalTransferReceiptHeader."No." <> '' then
                    HasInspection := QltyInspectionCreate.CreateInspectionWithMultiVariants(TransTransferLine, OptionalTransferReceiptHeader, TempTrackingSpecification, OptionalDirectTransHeader, false, TempQltyInspectCreationRule);

                if OptionalDirectTransHeader."No." <> '' then
                    HasInspection := QltyInspectionCreate.CreateInspectionWithMultiVariants(TransTransferLine, OptionalDirectTransHeader, TempTrackingSpecification, OptionalTransferReceiptHeader, false, TempQltyInspectCreationRule);

                if HasInspection then
                    QltyInspectionCreate.GetCreatedInspection(QltyInspectionHeader);
            until TempTrackingSpecification.Next() = 0
        else begin
            TempQltyInspectCreationRule.CopyFilters(ApplicableReceivingQltyInspectCreationRule);
            if OptionalTransferReceiptHeader."No." <> '' then
                HasInspection := QltyInspectionCreate.CreateInspectionWithMultiVariants(TransTransferLine, OptionalTransferReceiptHeader, OptionalDirectTransHeader, TempTrackingSpecification, false, TempQltyInspectCreationRule);

            if OptionalDirectTransHeader."No." <> '' then
                HasInspection := QltyInspectionCreate.CreateInspectionWithMultiVariants(TransTransferLine, OptionalDirectTransHeader, OptionalTransferReceiptHeader, TempTrackingSpecification, false, TempQltyInspectCreationRule);

            if HasInspection then
                QltyInspectionCreate.GetCreatedInspection(QltyInspectionHeader);
        end;
        OnAfterTransferAttemptCreateInspectionWithInboundTransferLine(TransTransferLine, OptionalTransferReceiptHeader, OptionalDirectTransHeader, TempTrackingSpecification, QltyInspectionHeader, HasInspection);
    end;

    local procedure DetectIsPreviewPosting() IsInPreviewPostingMode: Boolean
    var
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        IsInPreviewPostingMode := GenJnlPostPreview.IsActive();
    end;

    /// <summary>
    /// UUse this to integrate with auto inspections before the inspections are created from warehouse receipt lines.
    /// </summary>
    /// <param name="WarehouseReceiptLine"></param>
    /// <param name="WarehouseReceiptHeader"></param>
    /// <param name="pvarOptionalSourceLine">The optional source line (purchase line, sales line, transfer line)</param>
    /// <param name="Handled">Set to true to replace the default behavior</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeAttemptCreateInspectionWithReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var OptionalSourceLineVariant: Variant; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// Use this to integrate after an inspection has been automatically created
    /// </summary>
    /// <param name="HasInspection"></param>
    /// <param name="QltyInspectionHeader">The quality inspection involved. When multiple item tracking lines are involved this is the last inspection.</param>
    /// <param name="WarehouseReceiptLine"></param>
    /// <param name="WarehouseReceiptHeader"></param>
    /// <param name="pvarOptionalSourceLine">The optional source line (purchase line, sales line, transfer line)</param>
    /// <param name="TempTrackingSpecification">Optional. When set contains all of the related item tracking details involved. Could be multiple records</param>
    /// <param name="Handled">Set to true to replace the default behavior</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterAttemptCreateInspectionWithReceiptLine(var HasInspection: Boolean; var QltyInspectionHeader: Record "Qlty. Inspection Header"; var WarehouseReceiptLine: Record "Warehouse Receipt Line"; var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var OptionalSourceLineVariant: Variant; var TempTrackingSpecification: Record "Tracking Specification" temporary; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// UUse this to integrate with purchase auto inspections before the inspections are created.
    /// </summary>
    /// <param name="WarehouseJournalLine">var Record "Warehouse Journal Line".</param>
    /// <param name="PostedWhseReceiptHeader">Record "Posted Whse. Receipt Header".</param>
    /// <param name="Handled">Set to true to replace the default behavior</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchaseAttemptCreateInspectionWithWhseJournalLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header"; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// Use this to integrate after an inspection has been automatically created
    /// </summary>
    /// <param name="HasInspection"></param>
    /// <param name="QltyInspectionHeader">The quality inspection involved</param>
    /// <param name="WarehouseJournalLine">var Record "Warehouse Journal Line".</param>
    /// <param name="PostedWhseReceiptHeader">Record "Posted Whse. Receipt Header".</param>
    /// <param name="Handled">Set to true to replace the default behavior</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchaseAttemptCreateInspectionWithWhseJournalLine(var HasInspection: Boolean; var QltyInspectionHeader: Record "Qlty. Inspection Header"; var WarehouseJournalLine: Record "Warehouse Journal Line"; PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header"; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// Use this to integrate with purchase auto inspections before the inspections are created.
    /// </summary>
    /// <param name="PurchaseLine">The purchase line</param>
    /// <param name="PurchaseHeader">The purchase header</param>
    /// <param name="TempTrackingSpecification">Temporary var Record "Tracking Specification".</param>
    /// <param name="Handled">Set to true to replace the default behavior</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchaseAttemptCreateInspectionWithPurchaseLine(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// Use this to integrate after an inspection has been automatically created
    /// </summary>
    /// <param name="HasInspection"></param>
    /// <param name="QltyInspectionHeader">The quality inspection involved</param>
    /// <param name="PurchaseLine">The purchase line</param>
    /// <param name="PurchaseHeader">The purchase header</param>
    /// <param name="TempSpecTrackingSpecification">Temporary var Record "Tracking Specification".</param>
    /// <param name="Handled">Set to true to replace the default behavior</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchaseAttemptCreateInspectionWithPurchaseLine(var HasInspection: Boolean; var QltyInspectionHeader: Record "Qlty. Inspection Header"; var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// Occurs before an inspection is about to be created with a sales return line.
    /// </summary>
    /// <param name="SalesHeader"></param>
    /// <param name="SalesLine"></param>
    /// <param name="TempLedgNotInvoicedItemLedgerEntry"></param>
    /// <param name="TempTrackingSpecification"></param>
    /// <param name="Handled"></param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesReturnCreateInspectionWithSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var TempLedgNotInvoicedItemLedgerEntry: Record "Item Ledger Entry" temporary; var TempTrackingSpecification: Record "Tracking Specification" temporary; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// Occurs after an inspection has been created with a sales return line.
    /// </summary>
    /// <param name="SalesHeader"></param>
    /// <param name="SalesLine"></param>
    /// <param name="TempLedgNotInvoicedItemLedgerEntry"></param>
    /// <param name="TempTrackingSpecification"></param>
    /// <param name="HasInspection"></param>
    /// <param name="QltyInspectionHeader"></param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesReturnCreateInspectionWithSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var TempLedgNotInvoicedItemLedgerEntry: Record "Item Ledger Entry" temporary; var TempTrackingSpecification: Record "Tracking Specification" temporary; var HasInspection: Boolean; var QltyInspectionHeader: Record "Qlty. Inspection Header")
    begin
    end;

    /// <summary>
    /// Provides an opportunity to modify the Inspection Creation Option when triggered from posting an inbound Transfer Line.
    /// </summary>
    /// <param name="TransTransferLine">Transfer Line</param>
    /// <param name="TransferReceiptHeader">Transfer Receipt Header</param>
    /// <param name="DirectTransHeader">Direct Transfer Header</param>
    /// <param name="TempSpecTrackingSpecification">Tracking Specification</param>
    /// <param name="QltyInspectionHeader">Created Inspection</param>
    /// <param name="HasInspection">Signifies an inspection was created or an existing inspection was found</param>
    /// <param name="Handled">Provides an opportunity to replace the default behavior</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeAttemptCreateInspectionWithInboundTransferLine(var TransTransferLine: Record "Transfer Line"; var TransferReceiptHeader: Record "Transfer Receipt Header"; var DirectTransHeader: Record "Direct Trans. Header"; var TempSpecTrackingSpecification: Record "Tracking Specification" temporary; var QltyInspectionHeader: Record "Qlty. Inspection Header"; var HasInspection: Boolean; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// Provides an opportunity to modify the created inspection triggered from posting an inbound Transfer Line.
    /// </summary>
    /// <param name="TransTransferLine">Transfer Line</param>
    /// <param name="TransferReceiptHeader">Transfer Receipt Header</param>
    /// <param name="DirectTransHeader">Direct Transfer Header</param>
    /// <param name="TempSpecTrackingSpecification">Tracking Specification</param>
    /// <param name="QltyInspectionHeader">Created Inspection</param>
    /// <param name="HasInspection">Signifies an inspection was created or an existing inspection was found</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferAttemptCreateInspectionWithInboundTransferLine(var TransTransferLine: Record "Transfer Line"; var TransferReceiptHeader: Record "Transfer Receipt Header"; var DirectTransHeader: Record "Direct Trans. Header"; var TempSpecTrackingSpecification: Record "Tracking Specification" temporary; var QltyInspectionHeader: Record "Qlty. Inspection Header"; var HasInspection: Boolean)
    begin
    end;
}
