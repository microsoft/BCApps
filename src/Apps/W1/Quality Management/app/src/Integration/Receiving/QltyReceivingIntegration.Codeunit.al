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
using Microsoft.QualityManagement.Setup.Setup;
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
        ApplicableReceivingQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterPurchRcptLineInsert', '', true, true)]
    local procedure HandleOnAfterPurchRcptLineInsert(PurchaseLine: Record "Purchase Line"; var PurchRcptLine: Record "Purch. Rcpt. Line"; ItemLedgShptEntryNo: Integer; WhseShip: Boolean; WhseReceive: Boolean; CommitIsSupressed: Boolean; PurchInvHeader: Record "Purch. Inv. Header"; var TempTrackingSpecification: Record "Tracking Specification" temporary; PurchRcptHeader: Record "Purch. Rcpt. Header"; TempWhseRcptHeader: Record "Warehouse Receipt Header"; xPurchLine: Record "Purchase Line"; var TempPurchLineGlobal: Record "Purchase Line" temporary)
    var
        PurchaseHeader: Record "Purchase Header";
        TempSingleBufferTrackingSpecification: Record "Tracking Specification" temporary;
        ExpectedAmountOfTests: Integer;
    begin
        if (PurchaseLine.Type <> PurchaseLine.Type::Item) or (PurchaseLine."Qty. to Receive (Base)" = 0) then
            exit;

        if DetectIsPreviewPosting() then
            exit;

        if not QltyManagementSetup.GetSetupRecord() then
            exit;

        ApplicableReceivingQltyInspectionGenRule.Reset();
        ApplicableReceivingQltyInspectionGenRule.SetRange("Purchase Trigger", ApplicableReceivingQltyInspectionGenRule."Purchase Trigger"::OnPurchaseOrderPostReceive);
        ApplicableReceivingQltyInspectionGenRule.SetFilter("Activation Trigger", '%1|%2', ApplicableReceivingQltyInspectionGenRule."Activation Trigger"::"Manual or Automatic", ApplicableReceivingQltyInspectionGenRule."Activation Trigger"::"Automatic only");
        if ApplicableReceivingQltyInspectionGenRule.IsEmpty() then
            exit;
        if PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.") then;

        TempTrackingSpecification.SetFilter("Quantity Handled (Base)", '<>0');
        TempTrackingSpecification.SetFilter("Buffer Status", '<>%1', TempTrackingSpecification."Buffer Status"::MODIFY);
        TempTrackingSpecification.SetRange("Item No.", PurchaseLine."No.");
        TempTrackingSpecification.SetRange("Source ID", PurchaseLine."Document No.");
        TempTrackingSpecification.SetRange("Source Ref. No.", PurchaseLine."Line No.");
        TempTrackingSpecification.SetRange("Source Type", Database::"Purchase Line");

        ExpectedAmountOfTests := TempTrackingSpecification.Count();
        if ExpectedAmountOfTests = 0 then begin
            ExpectedAmountOfTests := 1;
            if not ApplicableReceivingQltyInspectionGenRule.IsEmpty() then begin
                TempSingleBufferTrackingSpecification := TempTrackingSpecification;
                TempSingleBufferTrackingSpecification.Insert(false);
                TempSingleBufferTrackingSpecification.SetRecFilter();
                AttemptCreateTestWithPurchaseLineAndTracking(PurchaseLine, PurchaseHeader, TempSingleBufferTrackingSpecification);
            end
        end else
            if not ApplicableReceivingQltyInspectionGenRule.IsEmpty() then
                if TempTrackingSpecification.FindSet() then
                    repeat
                        Clear(TempSingleBufferTrackingSpecification);
                        TempSingleBufferTrackingSpecification := TempTrackingSpecification;
                        TempSingleBufferTrackingSpecification.Insert(false);
                        TempSingleBufferTrackingSpecification.SetRecFilter();
                        AttemptCreateTestWithPurchaseLineAndTracking(PurchaseLine, PurchaseHeader, TempTrackingSpecification);
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

        ApplicableReceivingQltyInspectionGenRule.Reset();
        ApplicableReceivingQltyInspectionGenRule.SetRange("Warehouse Receive Trigger", ApplicableReceivingQltyInspectionGenRule."Warehouse Receive Trigger"::OnWarehouseReceiptPost);
        ApplicableReceivingQltyInspectionGenRule.SetFilter("Activation Trigger", '%1|%2', ApplicableReceivingQltyInspectionGenRule."Activation Trigger"::"Manual or Automatic", ApplicableReceivingQltyInspectionGenRule."Activation Trigger"::"Automatic only");
        if not ApplicableReceivingQltyInspectionGenRule.IsEmpty() then
            AttemptCreateTestWithWhseJournalLine(WarehouseJournalLine, PostedWhseReceiptHeader);
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

        ApplicableReceivingQltyInspectionGenRule.Reset();
        ApplicableReceivingQltyInspectionGenRule.SetRange("Warehouse Receive Trigger", ApplicableReceivingQltyInspectionGenRule."Warehouse Receive Trigger"::OnWarehouseReceiptCreate);
        ApplicableReceivingQltyInspectionGenRule.SetFilter("Activation Trigger", '%1|%2', ApplicableReceivingQltyInspectionGenRule."Activation Trigger"::"Manual or Automatic", ApplicableReceivingQltyInspectionGenRule."Activation Trigger"::"Automatic only");
        if not ApplicableReceivingQltyInspectionGenRule.IsEmpty() then begin
            OptionalSource := PurchaseLine;
            AttemptCreateTestWithReceiptLine(WarehouseReceiptLine, WarehouseReceiptHeader, OptionalSource);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforePostItemTrackingLine', '', true, true)]
    local procedure HandleOnBeforePostItemTrackingLine(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var TempItemLedgEntryNotInvoiced: Record "Item Ledger Entry" temporary; HasATOShippedNotInvoiced: Boolean; var IsHandled: Boolean; var ItemLedgShptEntryNo: Integer; var RemQtyToBeInvoiced: Decimal; var RemQtyToBeInvoicedBase: Decimal; SalesInvoiceHeader: Record "Sales Invoice Header"; SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyWarehouseIntegration: Codeunit "Qlty. - Warehouse Integration";
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        Handled: Boolean;
        HasTest: Boolean;
        SourceVariant: Variant;
        DummyVariant: Variant;
    begin
        if not (SalesLine."Document Type" = SalesLine."Document Type"::"Return Order") or (SalesLine."Return Qty. to Receive" = 0) then
            exit;

        if DetectIsPreviewPosting() then
            exit;

        if not QltyManagementSetup.GetSetupRecord() then
            exit;

        QltyInspectionGenRule.SetRange("Sales Return Trigger", QltyInspectionGenRule."Sales Return Trigger"::OnSalesReturnOrderPostReceive);
        QltyInspectionGenRule.SetFilter("Activation Trigger", '%1|%2', QltyInspectionGenRule."Activation Trigger"::"Manual or Automatic", QltyInspectionGenRule."Activation Trigger"::"Automatic only");
        if not QltyInspectionGenRule.IsEmpty() then begin
            SourceVariant := SalesLine;
            QltyWarehouseIntegration.CollectSourceItemTracking(SourceVariant, TempTrackingSpecification);
            OnBeforeSalesReturnCreateTestWithSalesLine(SalesHeader, SalesLine, TempItemLedgEntryNotInvoiced, TempTrackingSpecification, Handled);
            if Handled then
                exit;

            TempTrackingSpecification.Reset();
            if TempTrackingSpecification.FindSet() then
                repeat
                    if QltyInspectionCreate.CreateTestWithMultiVariants(SalesLine, TempTrackingSpecification, DummyVariant, DummyVariant, false, QltyInspectionGenRule) then begin
                        HasTest := true;
                        QltyInspectionCreate.GetCreatedTest(QltyInspectionHeader);
                    end;
                until TempTrackingSpecification.Next() = 0
            else
                if QltyInspectionCreate.CreateTestWithMultiVariants(SalesLine, DummyVariant, DummyVariant, DummyVariant, false, QltyInspectionGenRule) then begin
                    HasTest := true;
                    QltyInspectionCreate.GetCreatedTest(QltyInspectionHeader);
                end;
        end;

        OnAfterSalesReturnCreateTestWithSalesLine(SalesHeader, SalesLine, TempItemLedgEntryNotInvoiced, TempTrackingSpecification, HasTest, QltyInspectionHeader);
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

        ApplicableReceivingQltyInspectionGenRule.Reset();
        ApplicableReceivingQltyInspectionGenRule.SetRange("Transfer Trigger", ApplicableReceivingQltyInspectionGenRule."Transfer Trigger"::OnTransferOrderPostReceive);
        ApplicableReceivingQltyInspectionGenRule.SetFilter("Activation Trigger", '%1|%2', ApplicableReceivingQltyInspectionGenRule."Activation Trigger"::"Manual or Automatic", ApplicableReceivingQltyInspectionGenRule."Activation Trigger"::"Automatic only");
        if not ApplicableReceivingQltyInspectionGenRule.IsEmpty() then
            AttemptCreateTestWithReceiveTransferLine(TransLine, UnusedTransTransferReceiptHeader, DirectTransHeader);
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

        ApplicableReceivingQltyInspectionGenRule.Reset();
        ApplicableReceivingQltyInspectionGenRule.SetRange("Transfer Trigger", ApplicableReceivingQltyInspectionGenRule."Transfer Trigger"::OnTransferOrderPostReceive);
        ApplicableReceivingQltyInspectionGenRule.SetFilter("Activation Trigger", '%1|%2', ApplicableReceivingQltyInspectionGenRule."Activation Trigger"::"Manual or Automatic", ApplicableReceivingQltyInspectionGenRule."Activation Trigger"::"Automatic only");
        if not ApplicableReceivingQltyInspectionGenRule.IsEmpty() then
            AttemptCreateTestWithReceiveTransferLine(TransLine, TransferReceiptHeader, UnusedDirectTransHeader);
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

        ApplicableReceivingQltyInspectionGenRule.Reset();
        ApplicableReceivingQltyInspectionGenRule.SetRange("Purchase Trigger", ApplicableReceivingQltyInspectionGenRule."Purchase Trigger"::OnPurchaseOrderRelease);
        ApplicableReceivingQltyInspectionGenRule.SetFilter("Activation Trigger", '%1|%2', ApplicableReceivingQltyInspectionGenRule."Activation Trigger"::"Manual or Automatic", ApplicableReceivingQltyInspectionGenRule."Activation Trigger"::"Automatic only");
        if ApplicableReceivingQltyInspectionGenRule.IsEmpty() then
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
                            AttemptCreateTestWithPurchaseLineAndTracking(PurchaseLine, PurchaseHeader, TempTrackingSpecification);
                        until ReservationEntry.Next() = 0
                    else begin
                        Clear(TempTrackingSpecification);
                        AttemptCreateTestWithPurchaseLineAndTracking(PurchaseLine, PurchaseHeader, TempTrackingSpecification);
                    end;
                end else begin
                    Clear(TempTrackingSpecification);
                    AttemptCreateTestWithPurchaseLineAndTracking(PurchaseLine, PurchaseHeader, TempTrackingSpecification);
                end;
            until PurchaseLine.Next() = 0;
    end;

    local procedure AttemptCreateTestWithReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var OptionalSourceLineVariant: Variant)
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        TempQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary;
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        QltyWarehouseIntegration: Codeunit "Qlty. - Warehouse Integration";
        Handled: Boolean;
        HasTest: Boolean;
        DummyVariant: Variant;
    begin
        OnBeforeAttemptCreateTestWithReceiptLine(WarehouseReceiptLine, WarehouseReceiptHeader, OptionalSourceLineVariant, Handled);
        if Handled then
            exit;

        QltyWarehouseIntegration.CollectSourceItemTracking(OptionalSourceLineVariant, TempTrackingSpecification);

        TempTrackingSpecification.Reset();
        if TempTrackingSpecification.FindSet() then
            repeat
                TempQltyInspectionGenRule.DeleteAll();
                TempQltyInspectionGenRule.CopyFilters(ApplicableReceivingQltyInspectionGenRule);
                if QltyInspectionCreate.CreateTestWithMultiVariants(WarehouseReceiptLine, OptionalSourceLineVariant, WarehouseReceiptHeader, TempTrackingSpecification, false, TempQltyInspectionGenRule) then begin
                    HasTest := true;
                    QltyInspectionCreate.GetCreatedTest(QltyInspectionHeader);
                end;
            until TempTrackingSpecification.Next() = 0
        else begin
            TempQltyInspectionGenRule.CopyFilters(ApplicableReceivingQltyInspectionGenRule);
            if QltyInspectionCreate.CreateTestWithMultiVariants(WarehouseReceiptLine, OptionalSourceLineVariant, WarehouseReceiptHeader, DummyVariant, false, TempQltyInspectionGenRule) then begin
                HasTest := true;
                QltyInspectionCreate.GetCreatedTest(QltyInspectionHeader);
            end;
        end;

        OnAfterAttemptCreateTestWithReceiptLine(HasTest, QltyInspectionHeader, WarehouseReceiptLine, WarehouseReceiptHeader, OptionalSourceLineVariant, TempTrackingSpecification, Handled);
    end;

    local procedure AttemptCreateTestWithWhseJournalLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header")
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        TempQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary;
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        QltyWarehouseIntegration: Codeunit "Qlty. - Warehouse Integration";
        OptionalSourceRecordVariant: Variant;
        Handled: Boolean;
        HasTest: Boolean;
        DummyVariant: Variant;
    begin
        OnBeforePurchaseAttemptCreateTestWithWhseJournalLine(WarehouseJournalLine, PostedWhseReceiptHeader, Handled);
        if Handled then
            exit;

        if QltyWarehouseIntegration.GetOptionalSourceVariantForWarehouseJournalLine(WarehouseJournalLine, OptionalSourceRecordVariant) then
            QltyWarehouseIntegration.CollectSourceItemTracking(OptionalSourceRecordVariant, TempTrackingSpecification);

        TempTrackingSpecification.Reset();
        if TempTrackingSpecification.FindSet() then
            repeat
                TempQltyInspectionGenRule.DeleteAll();
                TempQltyInspectionGenRule.CopyFilters(ApplicableReceivingQltyInspectionGenRule);
                if QltyInspectionCreate.CreateTestWithMultiVariants(WarehouseJournalLine, OptionalSourceRecordVariant, PostedWhseReceiptHeader, TempTrackingSpecification, false, TempQltyInspectionGenRule) then begin
                    HasTest := true;
                    QltyInspectionCreate.GetCreatedTest(QltyInspectionHeader);
                end;
            until TempTrackingSpecification.Next() = 0
        else begin
            TempQltyInspectionGenRule.CopyFilters(ApplicableReceivingQltyInspectionGenRule);
            if QltyInspectionCreate.CreateTestWithMultiVariants(WarehouseJournalLine, OptionalSourceRecordVariant, PostedWhseReceiptHeader, DummyVariant, false, TempQltyInspectionGenRule) then begin
                HasTest := true;
                QltyInspectionCreate.GetCreatedTest(QltyInspectionHeader);
            end;
        end;

        OnAfterPurchaseAttemptCreateTestWithWhseJournalLine(HasTest, QltyInspectionHeader, WarehouseJournalLine, PostedWhseReceiptHeader, Handled);
    end;

    local procedure AttemptCreateTestWithPurchaseLineAndTracking(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary;
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        Handled: Boolean;
        HasTest: Boolean;
        DummyVariant: Variant;
    begin
        OnBeforePurchaseAttemptCreateTestWithPurchaseLine(PurchaseLine, PurchaseHeader, TempTrackingSpecification, Handled);
        if Handled then
            exit;

        TempQltyInspectionGenRule.CopyFilters(ApplicableReceivingQltyInspectionGenRule);
        HasTest := QltyInspectionCreate.CreateTestWithMultiVariants(PurchaseLine, PurchaseHeader, TempTrackingSpecification, DummyVariant, false, TempQltyInspectionGenRule);
        if HasTest then
            QltyInspectionCreate.GetCreatedTest(QltyInspectionHeader);

        OnAfterPurchaseAttemptCreateTestWithPurchaseLine(HasTest, QltyInspectionHeader, PurchaseLine, PurchaseHeader, TempTrackingSpecification, Handled);
    end;

    local procedure AttemptCreateTestWithReceiveTransferLine(var TransTransferLine: Record "Transfer Line"; var OptionalTransferReceiptHeader: Record "Transfer Receipt Header"; var OptionalDirectTransHeader: Record "Direct Trans. Header")
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        TempQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary;
        QltyWarehouseIntegration: Codeunit "Qlty. - Warehouse Integration";
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        Handled: Boolean;
        HasTest: Boolean;
        CurrentVariant: Variant;

    begin
        OnBeforeAttemptCreateTestWithInboundTransferLine(TransTransferLine, OptionalTransferReceiptHeader, OptionalDirectTransHeader, TempTrackingSpecification, QltyInspectionHeader, HasTest, Handled);
        if Handled then
            exit;
        CurrentVariant := TransTransferLine;
        QltyWarehouseIntegration.CollectSourceItemTracking(CurrentVariant, TempTrackingSpecification);
        TempTrackingSpecification.Reset();
        if TempTrackingSpecification.FindSet() then
            repeat
                TempQltyInspectionGenRule.DeleteAll();
                TempQltyInspectionGenRule.CopyFilters(ApplicableReceivingQltyInspectionGenRule);
                if OptionalTransferReceiptHeader."No." <> '' then
                    HasTest := QltyInspectionCreate.CreateTestWithMultiVariants(TransTransferLine, OptionalTransferReceiptHeader, TempTrackingSpecification, OptionalDirectTransHeader, false, TempQltyInspectionGenRule);

                if OptionalDirectTransHeader."No." <> '' then
                    HasTest := QltyInspectionCreate.CreateTestWithMultiVariants(TransTransferLine, OptionalDirectTransHeader, TempTrackingSpecification, OptionalTransferReceiptHeader, false, TempQltyInspectionGenRule);

                if HasTest then
                    QltyInspectionCreate.GetCreatedTest(QltyInspectionHeader);
            until TempTrackingSpecification.Next() = 0
        else begin
            TempQltyInspectionGenRule.CopyFilters(ApplicableReceivingQltyInspectionGenRule);
            if OptionalTransferReceiptHeader."No." <> '' then
                HasTest := QltyInspectionCreate.CreateTestWithMultiVariants(TransTransferLine, OptionalTransferReceiptHeader, OptionalDirectTransHeader, TempTrackingSpecification, false, TempQltyInspectionGenRule);

            if OptionalDirectTransHeader."No." <> '' then
                HasTest := QltyInspectionCreate.CreateTestWithMultiVariants(TransTransferLine, OptionalDirectTransHeader, OptionalTransferReceiptHeader, TempTrackingSpecification, false, TempQltyInspectionGenRule);

            if HasTest then
                QltyInspectionCreate.GetCreatedTest(QltyInspectionHeader);
        end;
        OnAfterTransferAttemptCreateTestWithInboundTransferLine(TransTransferLine, OptionalTransferReceiptHeader, OptionalDirectTransHeader, TempTrackingSpecification, QltyInspectionHeader, HasTest);
    end;

    local procedure DetectIsPreviewPosting() IsInPreviewPostingMode: Boolean
    var
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        IsInPreviewPostingMode := GenJnlPostPreview.IsActive();
    end;

    /// <summary>
    /// USe this to integrate with  auto tests before the tests are created from warehouse receipt lines.
    /// </summary>
    /// <param name="WarehouseReceiptLine"></param>
    /// <param name="WarehouseReceiptHeader"></param>
    /// <param name="pvarOptionalSourceLine">The optional source line (purchase line, sales line, transfer line)</param>
    /// <param name="Handled">Set to true to replace the default behavior</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeAttemptCreateTestWithReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var OptionalSourceLineVariant: Variant; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// Use this to integrate after a test has been automatically created
    /// </summary>
    /// <param name="HasTest"></param>
    /// <param name="QltyInspectionHeader">The quality inspection involved. When multiple item tracking lines are involved this is the last test.</param>
    /// <param name="WarehouseReceiptLine"></param>
    /// <param name="WarehouseReceiptHeader"></param>
    /// <param name="pvarOptionalSourceLine">The optional source line (purchase line, sales line, transfer line)</param>
    /// <param name="TempTrackingSpecification">Optional. When set contains all of the related item tracking details involved. Could be multiple records</param>
    /// <param name="Handled">Set to true to replace the default behavior</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterAttemptCreateTestWithReceiptLine(var HasTest: Boolean; var QltyInspectionHeader: Record "Qlty. Inspection Header"; var WarehouseReceiptLine: Record "Warehouse Receipt Line"; var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var OptionalSourceLineVariant: Variant; var TempTrackingSpecification: Record "Tracking Specification" temporary; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// USe this to integrate with purchase auto tests before the tests are created.
    /// </summary>
    /// <param name="WarehouseJournalLine">var Record "Warehouse Journal Line".</param>
    /// <param name="PostedWhseReceiptHeader">Record "Posted Whse. Receipt Header".</param>
    /// <param name="Handled">Set to true to replace the default behavior</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchaseAttemptCreateTestWithWhseJournalLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header"; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// Use this to integrate after a test has been automatically created
    /// </summary>
    /// <param name="HasTest"></param>
    /// <param name="QltyInspectionHeader">The quality inspection involved</param>
    /// <param name="WarehouseJournalLine">var Record "Warehouse Journal Line".</param>
    /// <param name="PostedWhseReceiptHeader">Record "Posted Whse. Receipt Header".</param>
    /// <param name="Handled">Set to true to replace the default behavior</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchaseAttemptCreateTestWithWhseJournalLine(var HasTest: Boolean; var QltyInspectionHeader: Record "Qlty. Inspection Header"; var WarehouseJournalLine: Record "Warehouse Journal Line"; PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header"; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// Use this to integrate with purchase auto tests before the tests are created.
    /// </summary>
    /// <param name="PurchaseLine">The purchase line</param>
    /// <param name="PurchaseHeader">The purchase header</param>
    /// <param name="TempTrackingSpecification">Temporary var Record "Tracking Specification".</param>
    /// <param name="Handled">Set to true to replace the default behavior</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchaseAttemptCreateTestWithPurchaseLine(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// Use this to integrate after a test has been automatically created
    /// </summary>
    /// <param name="HasTest"></param>
    /// <param name="QltyInspectionHeader">The quality inspection involved</param>
    /// <param name="PurchaseLine">The purchase line</param>
    /// <param name="PurchaseHeader">The purchase header</param>
    /// <param name="TempSpecTrackingSpecification">Temporary var Record "Tracking Specification".</param>
    /// <param name="Handled">Set to true to replace the default behavior</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchaseAttemptCreateTestWithPurchaseLine(var HasTest: Boolean; var QltyInspectionHeader: Record "Qlty. Inspection Header"; var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// Occurs before a test is about to be created with a sales return line.
    /// </summary>
    /// <param name="SalesHeader"></param>
    /// <param name="SalesLine"></param>
    /// <param name="TempLedgNotInvoicedItemLedgerEntry"></param>
    /// <param name="TempTrackingSpecification"></param>
    /// <param name="Handled"></param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesReturnCreateTestWithSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var TempLedgNotInvoicedItemLedgerEntry: Record "Item Ledger Entry" temporary; var TempTrackingSpecification: Record "Tracking Specification" temporary; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// Occurs after a test has been created with a sales return line.
    /// </summary>
    /// <param name="SalesHeader"></param>
    /// <param name="SalesLine"></param>
    /// <param name="TempLedgNotInvoicedItemLedgerEntry"></param>
    /// <param name="TempTrackingSpecification"></param>
    /// <param name="HasTest"></param>
    /// <param name="QltyInspectionHeader"></param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesReturnCreateTestWithSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var TempLedgNotInvoicedItemLedgerEntry: Record "Item Ledger Entry" temporary; var TempTrackingSpecification: Record "Tracking Specification" temporary; var HasTest: Boolean; var QltyInspectionHeader: Record "Qlty. Inspection Header")
    begin
    end;

    /// <summary>
    /// Provides an opportunity to modify the create inspection behavior when triggered from posting an inbound Transfer Line.
    /// </summary>
    /// <param name="TransTransferLine">Transfer Line</param>
    /// <param name="TransferReceiptHeader">Transfer Receipt Header</param>
    /// <param name="DirectTransHeader">Direct Transfer Header</param>
    /// <param name="TempSpecTrackingSpecification">Tracking Specification</param>
    /// <param name="QltyInspectionHeader">Created Test</param>
    /// <param name="HasTest">Signifies a test was created or an existing test was found</param>
    /// <param name="Handled">Provides an opportunity to replace the default behavior</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeAttemptCreateTestWithInboundTransferLine(var TransTransferLine: Record "Transfer Line"; var TransferReceiptHeader: Record "Transfer Receipt Header"; var DirectTransHeader: Record "Direct Trans. Header"; var TempSpecTrackingSpecification: Record "Tracking Specification" temporary; var QltyInspectionHeader: Record "Qlty. Inspection Header"; var HasTest: Boolean; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// Provides an opportunity to modify the created test triggered from posting an inbound Transfer Line.
    /// </summary>
    /// <param name="TransTransferLine">Transfer Line</param>
    /// <param name="TransferReceiptHeader">Transfer Receipt Header</param>
    /// <param name="DirectTransHeader">Direct Transfer Header</param>
    /// <param name="TempSpecTrackingSpecification">Tracking Specification</param>
    /// <param name="QltyInspectionHeader">Created Test</param>
    /// <param name="HasTest">Signifies a test was created or an existing test was found</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferAttemptCreateTestWithInboundTransferLine(var TransTransferLine: Record "Transfer Line"; var TransferReceiptHeader: Record "Transfer Receipt Header"; var DirectTransHeader: Record "Direct Trans. Header"; var TempSpecTrackingSpecification: Record "Tracking Specification" temporary; var QltyInspectionHeader: Record "Qlty. Inspection Header"; var HasTest: Boolean)
    begin
    end;
}
