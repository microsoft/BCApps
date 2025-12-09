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
        ApplicableReceivingQltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";

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

        ApplicableReceivingQltyInTestGenerationRule.Reset();
        ApplicableReceivingQltyInTestGenerationRule.SetRange("Purchase Trigger", ApplicableReceivingQltyInTestGenerationRule."Purchase Trigger"::OnPurchaseOrderPostReceive);
        ApplicableReceivingQltyInTestGenerationRule.SetFilter("Activation Trigger", '%1|%2', ApplicableReceivingQltyInTestGenerationRule."Activation Trigger"::"Manual or Automatic", ApplicableReceivingQltyInTestGenerationRule."Activation Trigger"::"Automatic only");
        if ApplicableReceivingQltyInTestGenerationRule.IsEmpty() then
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
            if not ApplicableReceivingQltyInTestGenerationRule.IsEmpty() then begin
                TempSingleBufferTrackingSpecification := TempTrackingSpecification;
                TempSingleBufferTrackingSpecification.Insert(false);
                TempSingleBufferTrackingSpecification.SetRecFilter();
                AttemptCreateTestWithPurchaseLineAndTracking(PurchaseLine, PurchaseHeader, TempSingleBufferTrackingSpecification);
            end
        end else
            if not ApplicableReceivingQltyInTestGenerationRule.IsEmpty() then
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

        ApplicableReceivingQltyInTestGenerationRule.Reset();
        ApplicableReceivingQltyInTestGenerationRule.SetRange("Warehouse Receive Trigger", ApplicableReceivingQltyInTestGenerationRule."Warehouse Receive Trigger"::OnWarehouseReceiptPost);
        ApplicableReceivingQltyInTestGenerationRule.SetFilter("Activation Trigger", '%1|%2', ApplicableReceivingQltyInTestGenerationRule."Activation Trigger"::"Manual or Automatic", ApplicableReceivingQltyInTestGenerationRule."Activation Trigger"::"Automatic only");
        if not ApplicableReceivingQltyInTestGenerationRule.IsEmpty() then
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

        ApplicableReceivingQltyInTestGenerationRule.Reset();
        ApplicableReceivingQltyInTestGenerationRule.SetRange("Warehouse Receive Trigger", ApplicableReceivingQltyInTestGenerationRule."Warehouse Receive Trigger"::OnWarehouseReceiptCreate);
        ApplicableReceivingQltyInTestGenerationRule.SetFilter("Activation Trigger", '%1|%2', ApplicableReceivingQltyInTestGenerationRule."Activation Trigger"::"Manual or Automatic", ApplicableReceivingQltyInTestGenerationRule."Activation Trigger"::"Automatic only");
        if not ApplicableReceivingQltyInTestGenerationRule.IsEmpty() then begin
            OptionalSource := PurchaseLine;
            AttemptCreateTestWithReceiptLine(WarehouseReceiptLine, WarehouseReceiptHeader, OptionalSource);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforePostItemTrackingLine', '', true, true)]
    local procedure HandleOnBeforePostItemTrackingLine(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var TempItemLedgEntryNotInvoiced: Record "Item Ledger Entry" temporary; HasATOShippedNotInvoiced: Boolean; var IsHandled: Boolean; var ItemLedgShptEntryNo: Integer; var RemQtyToBeInvoiced: Decimal; var RemQtyToBeInvoicedBase: Decimal; SalesInvoiceHeader: Record "Sales Invoice Header"; SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyWarehouseIntegration: Codeunit "Qlty. - Warehouse Integration";
        QltyInspectionTestCreate: Codeunit "Qlty. Inspection Test - Create";
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

        QltyInTestGenerationRule.SetRange("Sales Return Trigger", QltyInTestGenerationRule."Sales Return Trigger"::OnSalesReturnOrderPostReceive);
        QltyInTestGenerationRule.SetFilter("Activation Trigger", '%1|%2', QltyInTestGenerationRule."Activation Trigger"::"Manual or Automatic", QltyInTestGenerationRule."Activation Trigger"::"Automatic only");
        if not QltyInTestGenerationRule.IsEmpty() then begin
            SourceVariant := SalesLine;
            QltyWarehouseIntegration.CollectSourceItemTracking(SourceVariant, TempTrackingSpecification);
            OnBeforeSalesReturnCreateTestWithSalesLine(SalesHeader, SalesLine, TempItemLedgEntryNotInvoiced, TempTrackingSpecification, Handled);
            if Handled then
                exit;

            TempTrackingSpecification.Reset();
            if TempTrackingSpecification.FindSet() then
                repeat
                    if QltyInspectionTestCreate.CreateTestWithMultiVariants(SalesLine, TempTrackingSpecification, DummyVariant, DummyVariant, false, QltyInTestGenerationRule) then begin
                        HasTest := true;
                        QltyInspectionTestCreate.GetCreatedTest(QltyInspectionTestHeader);
                    end;
                until TempTrackingSpecification.Next() = 0
            else
                if QltyInspectionTestCreate.CreateTestWithMultiVariants(SalesLine, DummyVariant, DummyVariant, DummyVariant, false, QltyInTestGenerationRule) then begin
                    HasTest := true;
                    QltyInspectionTestCreate.GetCreatedTest(QltyInspectionTestHeader);
                end;
        end;

        OnAfterSalesReturnCreateTestWithSalesLine(SalesHeader, SalesLine, TempItemLedgEntryNotInvoiced, TempTrackingSpecification, HasTest, QltyInspectionTestHeader);
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

        ApplicableReceivingQltyInTestGenerationRule.Reset();
        ApplicableReceivingQltyInTestGenerationRule.SetRange("Transfer Trigger", ApplicableReceivingQltyInTestGenerationRule."Transfer Trigger"::OnTransferOrderPostReceive);
        ApplicableReceivingQltyInTestGenerationRule.SetFilter("Activation Trigger", '%1|%2', ApplicableReceivingQltyInTestGenerationRule."Activation Trigger"::"Manual or Automatic", ApplicableReceivingQltyInTestGenerationRule."Activation Trigger"::"Automatic only");
        if not ApplicableReceivingQltyInTestGenerationRule.IsEmpty() then
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

        ApplicableReceivingQltyInTestGenerationRule.Reset();
        ApplicableReceivingQltyInTestGenerationRule.SetRange("Transfer Trigger", ApplicableReceivingQltyInTestGenerationRule."Transfer Trigger"::OnTransferOrderPostReceive);
        ApplicableReceivingQltyInTestGenerationRule.SetFilter("Activation Trigger", '%1|%2', ApplicableReceivingQltyInTestGenerationRule."Activation Trigger"::"Manual or Automatic", ApplicableReceivingQltyInTestGenerationRule."Activation Trigger"::"Automatic only");
        if not ApplicableReceivingQltyInTestGenerationRule.IsEmpty() then
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

        ApplicableReceivingQltyInTestGenerationRule.Reset();
        ApplicableReceivingQltyInTestGenerationRule.SetRange("Purchase Trigger", ApplicableReceivingQltyInTestGenerationRule."Purchase Trigger"::OnPurchaseOrderRelease);
        ApplicableReceivingQltyInTestGenerationRule.SetFilter("Activation Trigger", '%1|%2', ApplicableReceivingQltyInTestGenerationRule."Activation Trigger"::"Manual or Automatic", ApplicableReceivingQltyInTestGenerationRule."Activation Trigger"::"Automatic only");
        if ApplicableReceivingQltyInTestGenerationRule.IsEmpty() then
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
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        TempQltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule" temporary;
        QltyInspectionTestCreate: Codeunit "Qlty. Inspection Test - Create";
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
                TempQltyInTestGenerationRule.DeleteAll();
                TempQltyInTestGenerationRule.CopyFilters(ApplicableReceivingQltyInTestGenerationRule);
                if QltyInspectionTestCreate.CreateTestWithMultiVariants(WarehouseReceiptLine, OptionalSourceLineVariant, WarehouseReceiptHeader, TempTrackingSpecification, false, TempQltyInTestGenerationRule) then begin
                    HasTest := true;
                    QltyInspectionTestCreate.GetCreatedTest(QltyInspectionTestHeader);
                end;
            until TempTrackingSpecification.Next() = 0
        else begin
            TempQltyInTestGenerationRule.CopyFilters(ApplicableReceivingQltyInTestGenerationRule);
            if QltyInspectionTestCreate.CreateTestWithMultiVariants(WarehouseReceiptLine, OptionalSourceLineVariant, WarehouseReceiptHeader, DummyVariant, false, TempQltyInTestGenerationRule) then begin
                HasTest := true;
                QltyInspectionTestCreate.GetCreatedTest(QltyInspectionTestHeader);
            end;
        end;

        OnAfterAttemptCreateTestWithReceiptLine(HasTest, QltyInspectionTestHeader, WarehouseReceiptLine, WarehouseReceiptHeader, OptionalSourceLineVariant, TempTrackingSpecification, Handled);
    end;

    local procedure AttemptCreateTestWithWhseJournalLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header")
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        TempQltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule" temporary;
        QltyInspectionTestCreate: Codeunit "Qlty. Inspection Test - Create";
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
                TempQltyInTestGenerationRule.DeleteAll();
                TempQltyInTestGenerationRule.CopyFilters(ApplicableReceivingQltyInTestGenerationRule);
                if QltyInspectionTestCreate.CreateTestWithMultiVariants(WarehouseJournalLine, OptionalSourceRecordVariant, PostedWhseReceiptHeader, TempTrackingSpecification, false, TempQltyInTestGenerationRule) then begin
                    HasTest := true;
                    QltyInspectionTestCreate.GetCreatedTest(QltyInspectionTestHeader);
                end;
            until TempTrackingSpecification.Next() = 0
        else begin
            TempQltyInTestGenerationRule.CopyFilters(ApplicableReceivingQltyInTestGenerationRule);
            if QltyInspectionTestCreate.CreateTestWithMultiVariants(WarehouseJournalLine, OptionalSourceRecordVariant, PostedWhseReceiptHeader, DummyVariant, false, TempQltyInTestGenerationRule) then begin
                HasTest := true;
                QltyInspectionTestCreate.GetCreatedTest(QltyInspectionTestHeader);
            end;
        end;

        OnAfterPurchaseAttemptCreateTestWithWhseJournalLine(HasTest, QltyInspectionTestHeader, WarehouseJournalLine, PostedWhseReceiptHeader, Handled);
    end;

    local procedure AttemptCreateTestWithPurchaseLineAndTracking(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        TempQltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule" temporary;
        QltyInspectionTestCreate: Codeunit "Qlty. Inspection Test - Create";
        Handled: Boolean;
        HasTest: Boolean;
        DummyVariant: Variant;
    begin
        OnBeforePurchaseAttemptCreateTestWithPurchaseLine(PurchaseLine, PurchaseHeader, TempTrackingSpecification, Handled);
        if Handled then
            exit;

        TempQltyInTestGenerationRule.CopyFilters(ApplicableReceivingQltyInTestGenerationRule);
        HasTest := QltyInspectionTestCreate.CreateTestWithMultiVariants(PurchaseLine, PurchaseHeader, TempTrackingSpecification, DummyVariant, false, TempQltyInTestGenerationRule);
        if HasTest then
            QltyInspectionTestCreate.GetCreatedTest(QltyInspectionTestHeader);

        OnAfterPurchaseAttemptCreateTestWithPurchaseLine(HasTest, QltyInspectionTestHeader, PurchaseLine, PurchaseHeader, TempTrackingSpecification, Handled);
    end;

    local procedure AttemptCreateTestWithReceiveTransferLine(var TransTransferLine: Record "Transfer Line"; var OptionalTransferReceiptHeader: Record "Transfer Receipt Header"; var OptionalDirectTransHeader: Record "Direct Trans. Header")
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        TempQltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule" temporary;
        QltyWarehouseIntegration: Codeunit "Qlty. - Warehouse Integration";
        QltyInspectionTestCreate: Codeunit "Qlty. Inspection Test - Create";
        Handled: Boolean;
        HasTest: Boolean;
        CurrentVariant: Variant;

    begin
        OnBeforeAttemptCreateTestWithInboundTransferLine(TransTransferLine, OptionalTransferReceiptHeader, OptionalDirectTransHeader, TempTrackingSpecification, QltyInspectionTestHeader, HasTest, Handled);
        if Handled then
            exit;
        CurrentVariant := TransTransferLine;
        QltyWarehouseIntegration.CollectSourceItemTracking(CurrentVariant, TempTrackingSpecification);
        TempTrackingSpecification.Reset();
        if TempTrackingSpecification.FindSet() then
            repeat
                TempQltyInTestGenerationRule.DeleteAll();
                TempQltyInTestGenerationRule.CopyFilters(ApplicableReceivingQltyInTestGenerationRule);
                if OptionalTransferReceiptHeader."No." <> '' then
                    HasTest := QltyInspectionTestCreate.CreateTestWithMultiVariants(TransTransferLine, OptionalTransferReceiptHeader, TempTrackingSpecification, OptionalDirectTransHeader, false, TempQltyInTestGenerationRule);

                if OptionalDirectTransHeader."No." <> '' then
                    HasTest := QltyInspectionTestCreate.CreateTestWithMultiVariants(TransTransferLine, OptionalDirectTransHeader, TempTrackingSpecification, OptionalTransferReceiptHeader, false, TempQltyInTestGenerationRule);

                if HasTest then
                    QltyInspectionTestCreate.GetCreatedTest(QltyInspectionTestHeader);
            until TempTrackingSpecification.Next() = 0
        else begin
            TempQltyInTestGenerationRule.CopyFilters(ApplicableReceivingQltyInTestGenerationRule);
            if OptionalTransferReceiptHeader."No." <> '' then
                HasTest := QltyInspectionTestCreate.CreateTestWithMultiVariants(TransTransferLine, OptionalTransferReceiptHeader, OptionalDirectTransHeader, TempTrackingSpecification, false, TempQltyInTestGenerationRule);

            if OptionalDirectTransHeader."No." <> '' then
                HasTest := QltyInspectionTestCreate.CreateTestWithMultiVariants(TransTransferLine, OptionalDirectTransHeader, OptionalTransferReceiptHeader, TempTrackingSpecification, false, TempQltyInTestGenerationRule);

            if HasTest then
                QltyInspectionTestCreate.GetCreatedTest(QltyInspectionTestHeader);
        end;
        OnAfterTransferAttemptCreateTestWithInboundTransferLine(TransTransferLine, OptionalTransferReceiptHeader, OptionalDirectTransHeader, TempTrackingSpecification, QltyInspectionTestHeader, HasTest);
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
    /// <param name="QltyInspectionTestHeader">The quality inspection test involved. When multiple item tracking lines are involved this is the last test.</param>
    /// <param name="WarehouseReceiptLine"></param>
    /// <param name="WarehouseReceiptHeader"></param>
    /// <param name="pvarOptionalSourceLine">The optional source line (purchase line, sales line, transfer line)</param>
    /// <param name="TempTrackingSpecification">Optional. When set contains all of the related item tracking details involved. Could be multiple records</param>
    /// <param name="Handled">Set to true to replace the default behavior</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterAttemptCreateTestWithReceiptLine(var HasTest: Boolean; var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var WarehouseReceiptLine: Record "Warehouse Receipt Line"; var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var OptionalSourceLineVariant: Variant; var TempTrackingSpecification: Record "Tracking Specification" temporary; var Handled: Boolean)
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
    /// <param name="QltyInspectionTestHeader">The quality inspection test involved</param>
    /// <param name="WarehouseJournalLine">var Record "Warehouse Journal Line".</param>
    /// <param name="PostedWhseReceiptHeader">Record "Posted Whse. Receipt Header".</param>
    /// <param name="Handled">Set to true to replace the default behavior</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchaseAttemptCreateTestWithWhseJournalLine(var HasTest: Boolean; var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var WarehouseJournalLine: Record "Warehouse Journal Line"; PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header"; var Handled: Boolean)
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
    /// <param name="QltyInspectionTestHeader">The quality inspection test involved</param>
    /// <param name="PurchaseLine">The purchase line</param>
    /// <param name="PurchaseHeader">The purchase header</param>
    /// <param name="TempSpecTrackingSpecification">Temporary var Record "Tracking Specification".</param>
    /// <param name="Handled">Set to true to replace the default behavior</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchaseAttemptCreateTestWithPurchaseLine(var HasTest: Boolean; var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var Handled: Boolean)
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
    /// <param name="QltyInspectionTestHeader"></param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesReturnCreateTestWithSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var TempLedgNotInvoicedItemLedgerEntry: Record "Item Ledger Entry" temporary; var TempTrackingSpecification: Record "Tracking Specification" temporary; var HasTest: Boolean; var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header")
    begin
    end;

    /// <summary>
    /// Provides an opportunity to modify the create test behavior when triggered from posting an inbound Transfer Line.
    /// </summary>
    /// <param name="TransTransferLine">Transfer Line</param>
    /// <param name="TransferReceiptHeader">Transfer Receipt Header</param>
    /// <param name="DirectTransHeader">Direct Transfer Header</param>
    /// <param name="TempSpecTrackingSpecification">Tracking Specification</param>
    /// <param name="QltyInspectionTestHeader">Created Test</param>
    /// <param name="HasTest">Signifies a test was created or an existing test was found</param>
    /// <param name="Handled">Provides an opportunity to replace the default behavior</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeAttemptCreateTestWithInboundTransferLine(var TransTransferLine: Record "Transfer Line"; var TransferReceiptHeader: Record "Transfer Receipt Header"; var DirectTransHeader: Record "Direct Trans. Header"; var TempSpecTrackingSpecification: Record "Tracking Specification" temporary; var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var HasTest: Boolean; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// Provides an opportunity to modify the created test triggered from posting an inbound Transfer Line.
    /// </summary>
    /// <param name="TransTransferLine">Transfer Line</param>
    /// <param name="TransferReceiptHeader">Transfer Receipt Header</param>
    /// <param name="DirectTransHeader">Direct Transfer Header</param>
    /// <param name="TempSpecTrackingSpecification">Tracking Specification</param>
    /// <param name="QltyInspectionTestHeader">Created Test</param>
    /// <param name="HasTest">Signifies a test was created or an existing test was found</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferAttemptCreateTestWithInboundTransferLine(var TransTransferLine: Record "Transfer Line"; var TransferReceiptHeader: Record "Transfer Receipt Header"; var DirectTransHeader: Record "Direct Trans. Header"; var TempSpecTrackingSpecification: Record "Tracking Specification" temporary; var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var HasTest: Boolean)
    begin
    end;
}
