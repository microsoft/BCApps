// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Manufacturing;

using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Document;
using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Configuration.SourceConfiguration;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup.Setup;
using Microsoft.QualityManagement.Utilities;

/// <summary>
/// Used to integrate with manufacturing related events.
/// </summary>
codeunit 20407 "Qlty. Manufactur. Integration"
{
    var
        QltyTraversal: Codeunit "Qlty. Traversal";
        QltyMfgSessionHelper: Codeunit "Qlty. Mfg. Session Helper";
        PermissionErr: Label 'User %1 not have permission to modify Quality Inspection Results tables, this will prevent test being updated.', Comment = '%1:User ID';
        ProductionRegisteredLogEventIDTok: Label 'QMERR0002', Locked = true;
        TargetDetailRecordTok: Label 'Target', Locked = true;
        UnknownRecordTok: Label 'Unknown record', Locked = true;

    /// <summary>
    /// We subscribe to OnAfterPostOutput to see if we need to create a test related to the output.
    /// This will get called a minimum of 1 per output journal line, and 'n' times per item tracking line.
    /// For example, if you have an item journal line that has 2 item tracking lines, this will get called twice, where the ItemLedgerEntry
    /// will change on each subsequent call.
    /// </summary>
    /// <param name="ItemLedgerEntry"></param>
    /// <param name="ProdOrderLine"></param>
    /// <param name="ItemJournalLine"></param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Mfg. Item Jnl.-Post Line", 'OnAfterPostOutput', '', true, true)]
    local procedure HandleOnAfterPostOutput(var ItemLedgerEntry: Record "Item Ledger Entry"; var ProdOrderLine: Record "Prod. Order Line"; var ItemJournalLine: Record "Item Journal Line")
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        VerifiedItemLedgerEntry: Record "Item Ledger Entry";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        Handled: Boolean;
    begin
        if not QltyManagementSetup.GetSetupRecord() then
            exit;

        case QltyManagementSetup."Auto Output Configuration" of
            1: // OnAnyQuantity
                if (ItemJournalLine.Quantity = 0) and (ItemJournalLine."Scrap Quantity" = 0) then
                    exit;
            2: // OnlyWithQuantity
                if ItemJournalLine.Quantity = 0 then
                    exit;
            3: // OnlyWithScrap
                if ItemJournalLine."Scrap Quantity" = 0 then
                    exit;
        end;

        if (ItemLedgerEntry."Entry Type" = ItemLedgerEntry."Entry Type"::Output) and
           (ItemLedgerEntry."Order Type" = ItemLedgerEntry."Order Type"::Production) and
           (ItemLedgerEntry."Order No." = ProdOrderLine."Prod. Order No.") and
           (ItemLedgerEntry."Order Line No." = ProdOrderLine."Line No.") and
           (ItemLedgerEntry."Item No." = ProdOrderLine."Item No.")
        then
            VerifiedItemLedgerEntry := ItemLedgerEntry
        else
            Clear(VerifiedItemLedgerEntry);

        OnBeforeProductionHandleOnAfterPostOutput(VerifiedItemLedgerEntry, ProdOrderLine, ItemJournalLine, Handled);
        if Handled then
            exit;

        ProdOrderRoutingLine.SetRange(Status, ProdOrderLine.Status);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderRoutingLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
        ProdOrderRoutingLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
        ProdOrderRoutingLine.SetRange("Operation No.", ItemJournalLine."Operation No.");
        if ProdOrderRoutingLine.FindFirst() then
            if ProdOrderRoutingLine."Next Operation No." <> '' then
                Clear(VerifiedItemLedgerEntry);

        QltyInTestGenerationRule.SetRange("Production Trigger", 1); // OnProductionOutputPost
        QltyInTestGenerationRule.SetFilter("Activation Trigger", '%1|%2', QltyInTestGenerationRule."Activation Trigger"::"Manual or Automatic", QltyInTestGenerationRule."Activation Trigger"::"Automatic only");
        if not QltyInTestGenerationRule.IsEmpty() then
            AttemptCreateTestPosting(ProdOrderRoutingLine, VerifiedItemLedgerEntry, ProdOrderLine, ItemJournalLine, QltyInTestGenerationRule);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Prod. Order Status Management", 'OnBeforeChangeStatusOnProdOrder', '', true, true)]
    local procedure HandleOnBeforeChangeStatusOnProdOrder(var ProductionOrder: Record "Production Order"; NewStatus: Option Quote,Planned,"Firm Planned",Released,Finished; var IsHandled: Boolean; NewPostingDate: Date; NewUpdateUnitCost: Boolean)
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
    begin
        if not QltyManagementSetup.GetSetupRecord() then
            exit;

        QltyMfgSessionHelper.SetProductionOrderBeforeChangingStatus(ProductionOrder);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Prod. Order Status Management", 'OnAfterChangeStatusOnProdOrder', '', true, true)]
    local procedure HandleOnAfterChangeStatusOnProdOrder(var ProdOrder: Record "Production Order"; var ToProdOrder: Record "Production Order"; NewStatus: Enum "Production Order Status"; NewPostingDate: Date; NewUpdateUnitCost: Boolean; var SuppressCommit: Boolean)
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        OldProductionOrder: Record "Production Order";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        Handled: Boolean;
    begin
        if not QltyManagementSetup.GetSetupRecord() then
            exit;

        QltyMfgSessionHelper.GetProductionOrderBeforeChangingStatus(OldProductionOrder);

        OnBeforeProductionHandleOnAfterChangeStatusOnProdOrder(OldProductionOrder, ToProdOrder, Handled);
        if Handled then
            exit;

        if QltyManagementSetup."Production Update Control" in [QltyManagementSetup."Production Update Control"::"Update when source changes"] then
            UpdateReferencesForProductionOrder(OldProductionOrder, ToProdOrder);

        if ToProdOrder.Status <> ToProdOrder.Status::Released then
            exit;

        QltyInTestGenerationRule.SetRange("Production Trigger", 2); // OnProductionOrderRelease
        QltyInTestGenerationRule.SetFilter("Activation Trigger", '%1|%2', QltyInTestGenerationRule."Activation Trigger"::"Manual or Automatic", QltyInTestGenerationRule."Activation Trigger"::"Automatic only");
        if not QltyInTestGenerationRule.IsEmpty() then
            AttemptCreateTestReleased(ToProdOrder, QltyInTestGenerationRule);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Prod. Order Status Management", 'OnAfterToProdOrderLineModify', '', true, true)]
    local procedure HandleOnAfterToProdOrderLineModify(var ToProdOrderLine: Record "Prod. Order Line"; var FromProdOrderLine: Record "Prod. Order Line"; var NewStatus: Option Quote,Planned,"Firm Planned",Released,Finished)
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
    begin
        if not QltyManagementSetup.GetSetupRecord() then
            exit;

        if not (QltyManagementSetup."Production Update Control" in [QltyManagementSetup."Production Update Control"::"Update when source changes"]) then
            exit;

        UpdateReferencesForProductionOrderLine(FromProdOrderLine, ToProdOrderLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Prod. Order Status Management", 'OnAfterToProdOrderRtngLineInsert', '', true, true)]
    local procedure HandleOnAfterToProdOrderRtngLineInsert(var ToProdOrderRoutingLine: Record "Prod. Order Routing Line"; var FromProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
    begin
        if not QltyManagementSetup.GetSetupRecord() then
            exit;

        if not (QltyManagementSetup."Production Update Control" in [QltyManagementSetup."Production Update Control"::"Update when source changes"]) then
            exit;

        UpdateReferencesForProductionOrderRoutingLine(FromProdOrderRoutingLine, ToProdOrderRoutingLine);
    end;

    [EventSubscriber(ObjectType::Report, Report::"Refresh Production Order", 'OnAfterRefreshProdOrder', '', true, true)]
    local procedure HandleOnAfterRefreshProdOrder(var ProductionOrder: Record "Production Order"; ErrorOccured: Boolean)
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
    begin
        if ErrorOccured then
            exit;

        if ProductionOrder.Status <> ProductionOrder.Status::Released then
            exit;

        if not QltyManagementSetup.GetSetupRecord() then
            exit;

        QltyInTestGenerationRule.SetRange("Production Trigger", 3); // OnReleasedProductionOrderRefresh
        QltyInTestGenerationRule.SetFilter("Activation Trigger", '%1|%2', QltyInTestGenerationRule."Activation Trigger"::"Manual or Automatic", QltyInTestGenerationRule."Activation Trigger"::"Automatic only");
        if not QltyInTestGenerationRule.IsEmpty() then
            AttemptCreateTestReleased(ProductionOrder, QltyInTestGenerationRule);
    end;

    /// <summary>
    /// Updates source records for tests where the source is a production order
    /// </summary>
    /// <param name="OldProductionOrder"></param>
    /// <param name="NewProductionOrder"></param>
    local procedure UpdateReferencesForProductionOrder(OldProductionOrder: Record "Production Order"; NewProductionOrder: Record "Production Order")
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        TargetRecordRef: RecordRef;
    begin
        TargetRecordRef.GetTable(NewProductionOrder);
        if not QltyInspectionTestHeader.WritePermission() then begin
            LogProductionProblemWith1(TargetRecordRef, PermissionErr, UserId());
            exit;
        end;

        QltyInspectionTestHeader.SetRange("Source RecordId", OldProductionOrder.RecordId());
        if QltyInspectionTestHeader.FindSet(true) then
            repeat
                QltyInspectionTestHeader."Source RecordId" := NewProductionOrder.RecordId();
                UpdateSourceDocumentForSpecificTestOnOrder(QltyInspectionTestHeader, TargetRecordRef, OldProductionOrder, NewProductionOrder);
            until QltyInspectionTestHeader.Next() = 0
        else begin
            QltyInspectionTestHeader.Reset();
            QltyInspectionTestHeader.SetRange("Source RecordId 2", OldProductionOrder.RecordId());
            if QltyInspectionTestHeader.FindSet(true) then
                repeat
                    QltyInspectionTestHeader."Source RecordId 2" := NewProductionOrder.RecordId();
                    UpdateSourceDocumentForSpecificTestOnOrder(QltyInspectionTestHeader, TargetRecordRef, OldProductionOrder, NewProductionOrder);
                until QltyInspectionTestHeader.Next() = 0
            else begin
                QltyInspectionTestHeader.Reset();
                QltyInspectionTestHeader.SetRange("Source RecordId 3", OldProductionOrder.RecordId());
                if QltyInspectionTestHeader.FindSet(true) then
                    repeat
                        QltyInspectionTestHeader."Source RecordId 3" := NewProductionOrder.RecordId();
                        UpdateSourceDocumentForSpecificTestOnOrder(QltyInspectionTestHeader, TargetRecordRef, OldProductionOrder, NewProductionOrder);
                    until QltyInspectionTestHeader.Next() = 0
                else begin
                    QltyInspectionTestHeader.Reset();
                    QltyInspectionTestHeader.SetRange("Source RecordId 4", OldProductionOrder.RecordId());
                    if QltyInspectionTestHeader.FindSet(true) then
                        repeat
                            QltyInspectionTestHeader."Source RecordId 4" := NewProductionOrder.RecordId();
                            UpdateSourceDocumentForSpecificTestOnOrder(QltyInspectionTestHeader, TargetRecordRef, OldProductionOrder, NewProductionOrder);
                        until QltyInspectionTestHeader.Next() = 0;
                end;
            end;
        end;
    end;

    /// <summary>
    /// Updates tests where the source is a production order line
    /// </summary>
    /// <param name="OldProdOrderLine"></param>
    /// <param name="NewProdOrderLine"></param>
    local procedure UpdateReferencesForProductionOrderLine(OldProdOrderLine: Record "Prod. Order Line"; NewProdOrderLine: Record "Prod. Order Line")
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        TargetRecordRef: RecordRef;
    begin
        TargetRecordRef.GetTable(NewProdOrderLine);
        if not QltyInspectionTestHeader.WritePermission() then begin
            LogProductionProblemWith1(TargetRecordRef, PermissionErr, UserId());
            exit;
        end;

        QltyInspectionTestHeader.SetRange("Source RecordId", OldProdOrderLine.RecordId());
        if QltyInspectionTestHeader.FindSet(true) then
            repeat
                QltyInspectionTestHeader."Source RecordId" := NewProdOrderLine.RecordId();
                UpdateSourceDocumentForSpecificTestOnLine(QltyInspectionTestHeader, TargetRecordRef, OldProdOrderLine, NewProdOrderLine);
            until QltyInspectionTestHeader.Next() = 0
        else begin
            QltyInspectionTestHeader.Reset();
            QltyInspectionTestHeader.SetRange("Source RecordId 2", OldProdOrderLine.RecordId());
            if QltyInspectionTestHeader.FindSet(true) then
                repeat
                    QltyInspectionTestHeader."Source RecordId 2" := NewProdOrderLine.RecordId();
                    UpdateSourceDocumentForSpecificTestOnLine(QltyInspectionTestHeader, TargetRecordRef, OldProdOrderLine, NewProdOrderLine);
                until QltyInspectionTestHeader.Next() = 0
            else begin
                QltyInspectionTestHeader.Reset();
                QltyInspectionTestHeader.SetRange("Source RecordId 3", OldProdOrderLine.RecordId());
                if QltyInspectionTestHeader.FindSet(true) then
                    repeat
                        QltyInspectionTestHeader."Source RecordId 3" := NewProdOrderLine.RecordId();
                        UpdateSourceDocumentForSpecificTestOnLine(QltyInspectionTestHeader, TargetRecordRef, OldProdOrderLine, NewProdOrderLine);
                    until QltyInspectionTestHeader.Next() = 0
                else begin
                    QltyInspectionTestHeader.Reset();
                    QltyInspectionTestHeader.SetRange("Source RecordId 4", OldProdOrderLine.RecordId());
                    if QltyInspectionTestHeader.FindSet(true) then
                        repeat
                            QltyInspectionTestHeader."Source RecordId 4" := NewProdOrderLine.RecordId();
                            UpdateSourceDocumentForSpecificTestOnLine(QltyInspectionTestHeader, TargetRecordRef, OldProdOrderLine, NewProdOrderLine);
                        until QltyInspectionTestHeader.Next() = 0
                end;
            end;
        end;
    end;

    /// <summary>
    /// Updates tests where the source is a production order routing line
    /// </summary>
    /// <param name="OldProdOrderRoutingLine"></param>
    /// <param name="NewProdOrderRoutingLine"></param>
    local procedure UpdateReferencesForProductionOrderRoutingLine(OldProdOrderRoutingLine: Record "Prod. Order Routing Line"; NewProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        TargetRecordRef: RecordRef;
    begin
        TargetRecordRef.GetTable(NewProdOrderRoutingLine);
        if not QltyInspectionTestHeader.WritePermission() then begin
            LogProductionProblemWith1(TargetRecordRef, PermissionErr, UserId());
            exit;
        end;

        QltyInspectionTestHeader.SetRange("Source RecordId", OldProdOrderRoutingLine.RecordId());
        if QltyInspectionTestHeader.FindSet(true) then
            repeat
                QltyInspectionTestHeader."Source RecordId" := NewProdOrderRoutingLine.RecordId();
                UpdateSourceDocumentForSpecificTestOnOperation(QltyInspectionTestHeader, TargetRecordRef, OldProdOrderRoutingLine, NewProdOrderRoutingLine);
            until QltyInspectionTestHeader.Next() = 0
        else begin
            QltyInspectionTestHeader.Reset();
            QltyInspectionTestHeader.SetRange("Source RecordId 2", OldProdOrderRoutingLine.RecordId());
            if QltyInspectionTestHeader.FindSet(true) then
                repeat
                    QltyInspectionTestHeader."Source RecordId 2" := NewProdOrderRoutingLine.RecordId();
                    UpdateSourceDocumentForSpecificTestOnOperation(QltyInspectionTestHeader, TargetRecordRef, OldProdOrderRoutingLine, NewProdOrderRoutingLine);
                until QltyInspectionTestHeader.Next() = 0
            else begin
                QltyInspectionTestHeader.Reset();
                QltyInspectionTestHeader.SetRange("Source RecordId 3", OldProdOrderRoutingLine.RecordId());
                if QltyInspectionTestHeader.FindSet(true) then
                    repeat
                        QltyInspectionTestHeader."Source RecordId 3" := NewProdOrderRoutingLine.RecordId();
                        UpdateSourceDocumentForSpecificTestOnOperation(QltyInspectionTestHeader, TargetRecordRef, OldProdOrderRoutingLine, NewProdOrderRoutingLine);
                    until QltyInspectionTestHeader.Next() = 0
                else begin
                    QltyInspectionTestHeader.Reset();
                    QltyInspectionTestHeader.SetRange("Source RecordId 4", OldProdOrderRoutingLine.RecordId());
                    if QltyInspectionTestHeader.FindSet(true) then
                        repeat
                            QltyInspectionTestHeader."Source RecordId 4" := NewProdOrderRoutingLine.RecordId();
                            UpdateSourceDocumentForSpecificTestOnOperation(QltyInspectionTestHeader, TargetRecordRef, OldProdOrderRoutingLine, NewProdOrderRoutingLine);
                        until QltyInspectionTestHeader.Next() = 0
                end;
            end;
        end;
    end;

    local procedure UpdateSourceDocumentForSpecificTestOnOrder(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TargetRecordRef: RecordRef; OldProductionOrder: Record "Production Order"; NewProductionOrder: Record "Production Order")
    var
        OldStatusValue: Integer;
        NewStatusValue: Integer;
    begin
        OldStatusValue := OldProductionOrder.Status.AsInteger();
        NewStatusValue := NewProductionOrder.Status.AsInteger();

        // Update source fields directly
        if QltyInspectionTestHeader."Source Type" = OldStatusValue then
            QltyInspectionTestHeader."Source Type" := NewStatusValue;

        if QltyInspectionTestHeader."Source Document No." = OldProductionOrder."No." then
            QltyInspectionTestHeader."Source Document No." := NewProductionOrder."No.";

        if QltyInspectionTestHeader.Modify(false) then;
    end;

    local procedure UpdateSourceDocumentForSpecificTestOnLine(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TargetRecordRef: RecordRef; OldProdOrderLine: Record "Prod. Order Line"; NewProdOrderLine: Record "Prod. Order Line")
    var
        OldStatusValue: Integer;
        NewStatusValue: Integer;
    begin
        OldStatusValue := OldProdOrderLine.Status.AsInteger();
        NewStatusValue := NewProdOrderLine.Status.AsInteger();

        // Update source fields directly
        if QltyInspectionTestHeader."Source Type" = OldStatusValue then
            QltyInspectionTestHeader."Source Type" := NewStatusValue;

        if QltyInspectionTestHeader."Source Document No." = OldProdOrderLine."Prod. Order No." then
            QltyInspectionTestHeader."Source Document No." := NewProdOrderLine."Prod. Order No.";

        if QltyInspectionTestHeader."Source Document Line No." = OldProdOrderLine."Line No." then
            QltyInspectionTestHeader."Source Document Line No." := NewProdOrderLine."Line No.";

        if QltyInspectionTestHeader.Modify(false) then;
    end;

    local procedure UpdateSourceDocumentForSpecificTestOnOperation(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TargetRecordRef: RecordRef; OldProdOrderRoutingLine: Record "Prod. Order Routing Line"; NewProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        OldStatusValue: Integer;
        NewStatusValue: Integer;
    begin
        OldStatusValue := OldProdOrderRoutingLine.Status.AsInteger();
        NewStatusValue := NewProdOrderRoutingLine.Status.AsInteger();

        // Update source fields directly
        if QltyInspectionTestHeader."Source Type" = OldStatusValue then
            QltyInspectionTestHeader."Source Type" := NewStatusValue;

        if QltyInspectionTestHeader."Source Document No." = OldProdOrderRoutingLine."Prod. Order No." then
            QltyInspectionTestHeader."Source Document No." := NewProdOrderRoutingLine."Prod. Order No.";

        if QltyInspectionTestHeader."Source Task No." = OldProdOrderRoutingLine."Operation No." then
            QltyInspectionTestHeader."Source Task No." := NewProdOrderRoutingLine."Operation No.";

        if QltyInspectionTestHeader.Modify(false) then;
    end;

    /// <summary>
    /// Intended to be used with production releasing.
    /// For production releasing it will use either the prod order routing line, or prod order line, or prod order.
    /// What we can do is automatically apply them.
    /// </summary>
    /// <param name="ProductionOrder">The production order</param>
    /// <param name="OptionalFiltersQltyInTestGenerationRule">Optional generation rule filters.</param>
    local procedure AttemptCreateTestReleased(var ProductionOrder: Record "Production Order"; var OptionalFiltersQltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule")
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ProdOrderLine: Record "Prod. Order Line";
        ReservationEntry: Record "Reservation Entry";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        QltyInspectionTestCreate: Codeunit "Qlty. Inspection Test - Create";
        ProdOrderLineReserve: Codeunit "Prod. Order Line-Reserve";
        OfTestIds: List of [RecordId];
        HasReservationEntries: Boolean;
        Handled: Boolean;
        CreatedAtLeastOneTestForRoutingLine: Boolean;
        CreatedAtLeastOneTestForOrderLine: Boolean;
        CreatedTestForProdOrder: Boolean;
        MadeTest: Boolean;
        DummyVariant: Variant;
    begin
        OnBeforeProductionAttemptCreateReleaseAutomaticTest(ProductionOrder, Handled);
        if Handled then
            exit;

        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        if ProdOrderLine.FindSet() then begin
            Clear(ReservationEntry);
            HasReservationEntries := ProdOrderLineReserve.FindReservEntry(ProdOrderLine, ReservationEntry);
            repeat
                ProdOrderRoutingLine.SetRange(Status, ProdOrderLine.Status);
                ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
                ProdOrderRoutingLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
                ProdOrderRoutingLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
                if ProdOrderRoutingLine.FindSet() then
                    repeat
                        if HasReservationEntries then begin
                            ReservationEntry.FindSet();
                            repeat
                                Clear(TempTrackingSpecification);
                                TempTrackingSpecification.DeleteAll(false);
                                TempTrackingSpecification.SetSourceFromReservEntry(ReservationEntry);
                                TempTrackingSpecification.CopyTrackingFromReservEntry(ReservationEntry);
                                TempTrackingSpecification.Insert();

                                MadeTest := QltyInspectionTestCreate.CreateTestWithMultiVariants(ProdOrderRoutingLine, TempTrackingSpecification, ProdOrderLine, ProductionOrder, false, OptionalFiltersQltyInTestGenerationRule);

                                if MadeTest then begin
                                    QltyInspectionTestCreate.GetCreatedTest(QltyInspectionTestHeader);
                                    OfTestIds.Add(QltyInspectionTestHeader.RecordId());
                                    CreatedAtLeastOneTestForRoutingLine := true;
                                end;
                            until ReservationEntry.Next() = 0;
                        end else begin
                            MadeTest := QltyInspectionTestCreate.CreateTestWithMultiVariants(ProdOrderRoutingLine, ProdOrderLine, ProductionOrder, DummyVariant, false, OptionalFiltersQltyInTestGenerationRule);

                            if MadeTest then begin
                                QltyInspectionTestCreate.GetCreatedTest(QltyInspectionTestHeader);
                                OfTestIds.Add(QltyInspectionTestHeader.RecordId());
                                CreatedAtLeastOneTestForRoutingLine := true;
                            end;
                        end;
                    until ProdOrderRoutingLine.Next() = 0;

                if not CreatedAtLeastOneTestForRoutingLine then
                    if HasReservationEntries then begin
                        ReservationEntry.FindSet();
                        repeat
                            Clear(TempTrackingSpecification);
                            TempTrackingSpecification.DeleteAll(false);
                            TempTrackingSpecification.SetSourceFromReservEntry(ReservationEntry);
                            TempTrackingSpecification.CopyTrackingFromReservEntry(ReservationEntry);
                            TempTrackingSpecification.Insert();

                            MadeTest := QltyInspectionTestCreate.CreateTestWithMultiVariants(TempTrackingSpecification, ProdOrderLine, ProductionOrder, DummyVariant, false, OptionalFiltersQltyInTestGenerationRule);

                            if MadeTest then begin
                                QltyInspectionTestCreate.GetCreatedTest(QltyInspectionTestHeader);
                                OfTestIds.Add(QltyInspectionTestHeader.RecordId());
                                CreatedAtLeastOneTestForOrderLine := true;
                            end;

                        until ReservationEntry.Next() = 0;
                    end else begin
                        MadeTest := QltyInspectionTestCreate.CreateTestWithMultiVariants(ProdOrderLine, ProductionOrder, DummyVariant, DummyVariant, false, OptionalFiltersQltyInTestGenerationRule);
                        if MadeTest then begin
                            QltyInspectionTestCreate.GetCreatedTest(QltyInspectionTestHeader);
                            OfTestIds.Add(QltyInspectionTestHeader.RecordId());
                            CreatedAtLeastOneTestForOrderLine := true;
                        end;
                    end;
            until ProdOrderLine.Next() = 0;
        end;
        if (not CreatedAtLeastOneTestForOrderLine) and (not CreatedAtLeastOneTestForRoutingLine) then begin
            MadeTest := QltyInspectionTestCreate.CreateTestWithMultiVariants(ProductionOrder, DummyVariant, DummyVariant, DummyVariant, false, OptionalFiltersQltyInTestGenerationRule);
            if MadeTest then begin
                QltyInspectionTestCreate.GetCreatedTest(QltyInspectionTestHeader);
                OfTestIds.Add(QltyInspectionTestHeader.RecordId());
                CreatedTestForProdOrder := MadeTest;
            end;
        end;

        OnAfterProductionAttemptCreateReleaseAutomaticTest(ProductionOrder, CreatedAtLeastOneTestForRoutingLine, CreatedAtLeastOneTestForOrderLine, CreatedTestForProdOrder, OfTestIds);
    end;

    /// <summary>
    /// Intended to be used with production related posting.
    /// For production posting we have three references, any of which could be used as a trigger depending on the scenario.
    /// What we can do is automatically apply them.
    /// </summary>
    /// <param name="ItemLedgerEntry">The item ledger entry related to this sequence of events</param>
    /// <param name="ProdOrderLine"></param>
    /// <param name="ItemJournalLine"></param>
    local procedure AttemptCreateTestPosting(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var ItemLedgerEntry: Record "Item Ledger Entry"; var ProdOrderLine: Record "Prod. Order Line"; var ItemJournalLine: Record "Item Journal Line"; var OptionalFiltersQltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule")
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyInspectionTestCreate: Codeunit "Qlty. Inspection Test - Create";
        Handled: Boolean;
        HasTest: Boolean;
        DummyVariant: Variant;
    begin
        OnBeforeProductionAttemptCreatePostAutomaticTest(ProdOrderRoutingLine, ItemLedgerEntry, ProdOrderLine, ItemJournalLine, Handled);
        if Handled then
            exit;

        if (ItemLedgerEntry."Entry Type" <> ItemLedgerEntry."Entry Type"::Output) or (ItemLedgerEntry."Item No." = '') then
            HasTest := QltyInspectionTestCreate.CreateTestWithMultiVariants(ProdOrderRoutingLine, ItemJournalLine, ProdOrderLine, DummyVariant, false, OptionalFiltersQltyInTestGenerationRule)

        else
            if ProdOrderRoutingLine."Operation No." <> '' then
                HasTest := QltyInspectionTestCreate.CreateTestWithMultiVariants(ItemLedgerEntry, ProdOrderRoutingLine, ItemJournalLine, ProdOrderLine, false, OptionalFiltersQltyInTestGenerationRule)
            else
                HasTest := QltyInspectionTestCreate.CreateTestWithMultiVariants(ItemLedgerEntry, ItemJournalLine, ProdOrderLine, DummyVariant, false, OptionalFiltersQltyInTestGenerationRule);

        if HasTest then
            QltyInspectionTestCreate.GetCreatedTest(QltyInspectionTestHeader);

        OnAfterProductionAttemptCreateAutomaticTest(ProdOrderRoutingLine, ItemLedgerEntry, ProdOrderLine, ItemJournalLine);
    end;

    /// <summary>
    /// Use this to log QMERR0002
    /// </summary>
    /// <param name="ContextVariant"></param>
    /// <param name="Input"></param>
    local procedure LogProductionProblem(ContextVariant: Variant; Input: Text)
    var
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
        ContextRecordRef: RecordRef;
        DetailRecord: Text;
    begin
        if QltyMiscHelpers.GetRecordRefFromVariant(ContextVariant, ContextRecordRef) then
            DetailRecord := Format(ContextRecordRef.RecordId())
        else
            DetailRecord := UnknownRecordTok;

        LogMessage(ProductionRegisteredLogEventIDTok, Input, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, TargetDetailRecordTok, DetailRecord);
    end;

    local procedure LogProductionProblemWith1(ContextVariant: Variant; Input: Text; Variable1: Text)
    begin
        LogProductionProblem(ContextVariant, StrSubstNo(Input, Variable1));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Qlty. In. Test Generation Rule", 'OnInferItemJournalIntent', '', false, false)]
    local procedure HandleOnInferItemJournalIntent(QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule"; var QltyGenRuleIntent: Enum "Qlty. Gen. Rule Intent"; var QltyCertainty: Enum "Qlty. Certainty")
    begin
        if QltyCertainty in [QltyCertainty::Yes, QltyCertainty::Maybe] then
            exit;

        if GetIsOnlyAutoTriggerInSetupForProduction() then begin
            QltyGenRuleIntent := "Qlty. Gen. Rule Intent".FromInteger(20470); // Production
            QltyCertainty := QltyCertainty::Maybe;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Qlty. In. Test Generation Rule", 'OnInferItemLedgerIntent', '', false, false)]
    local procedure HandleOnInferItemLedgerIntent(QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule"; var QltyGenRuleIntent: Enum "Qlty. Gen. Rule Intent"; var QltyCertainty: Enum "Qlty. Certainty")
    begin
        if QltyCertainty in [QltyCertainty::Yes, QltyCertainty::Maybe] then
            exit;

        if GetIsOnlyAutoTriggerInSetupForProduction() then begin
            QltyGenRuleIntent := "Qlty. Gen. Rule Intent".FromInteger(20470); // Production
            QltyCertainty := QltyCertainty::Maybe;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Qlty. In. Test Generation Rule", 'OnGetIsOnlyAutoTriggerInSetup', '', false, false)]
    local procedure HandleOnGetIsOnlyAutoTriggerInSetup(QltyManagementSetup: Record "Qlty. Management Setup"; IntentToCheck: Enum "Qlty. Gen. Rule Intent"; var TriggerCount: Integer; var IntentSet: Boolean)
    begin
        if QltyManagementSetup."Production Trigger" <> 0 then begin
            TriggerCount += 1;
            if IntentToCheck = "Qlty. Gen. Rule Intent".FromInteger(20470) then // Production
                IntentSet := true;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Qlty. In. Test Generation Rule", 'OnSetIntentDefaultTriggerValues', '', false, false)]
    local procedure HandleOnSetIntentDefaultTriggerValues(var QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule"; QltyManagementSetup: Record "Qlty. Management Setup"; InferredIntent: Enum "Qlty. Gen. Rule Intent")
    begin
        if InferredIntent = "Qlty. Gen. Rule Intent".FromInteger(20470) then // Production
            QltyInTestGenerationRule."Production Trigger" := QltyManagementSetup."Production Trigger";
    end;

    local procedure GetIsOnlyAutoTriggerInSetupForProduction(): Boolean
    begin
        if not QltyManagementSetup.Get() then
            exit(false);

        exit(QltyManagementSetup."Production Trigger" <> 0);
    end;

    /// <summary>
    /// OnBeforeProductionAttemptCreatePostAutomaticTest is called before attempting to automatically create a test for production related events prior to posting to posting.
    /// </summary>
    /// <param name="ProdOrderRoutingLine">Typically the 'main' record the tests are associated against.</param>
    /// <param name="ItemLedgerEntry">The item ledger entry related to this sequence of events</param>
    /// <param name="ProdOrderLine">The production order line involved in this sequence of events</param>
    /// <param name="ItemJournalLine">The item journal line record involved in this transaction.  Important: this record may no longer exist, and should not be altered.</param>
    /// <param name="Handled">Set to true to replace the default behavior</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeProductionAttemptCreatePostAutomaticTest(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var ItemLedgerEntry: Record "Item Ledger Entry"; var ProdOrderLine: Record "Prod. Order Line"; var ItemJournalLine: Record "Item Journal Line"; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// OnAfterProductionAttemptCreateAutomaticTest is called after attempting to automatically create a test for production.
    /// </summary>
    /// <param name="ProdOrderRoutingLine">Typically the 'main' record the tests are associated against.</param>
    /// <param name="ItemLedgerEntry">The item ledger entry related to this sequence of events</param>
    /// <param name="ProdOrderLine">The production order line involved in this sequence of events</param>
    /// <param name="ItemJournalLine">The item journal line record involved in this transaction.  Important: this record may no longer exist, and should not be altered.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterProductionAttemptCreateAutomaticTest(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var ItemLedgerEntry: Record "Item Ledger Entry"; var ProdOrderLine: Record "Prod. Order Line"; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    /// <summary>
    /// OnBeforeProductionAttemptCreateReleaseAutomaticTest is called before attempting to automatically create a test for production related releasing.
    /// </summary>
    /// <param name="ProductionOrder">The production order</param>
    /// <param name="Handled">Set to true to replace the default behavior</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeProductionAttemptCreateReleaseAutomaticTest(var ProductionOrder: Record "Production Order"; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// OnAfterProductionAttemptCreateReleaseAutomaticTest is called before attempting to automatically create a test for production related releasing.
    /// Use this if you need to collect multiple tests that could be created as part of a posting sequence.
    /// </summary>
    /// <param name="ProductionOrder">The production order</param>
    /// <param name="CreatedAtLeastOneTestForRoutingLine">A flag indicating if at least one test for the production order routing line was created</param>
    /// <param name="CreatedAtLeastOneTestForOrderLine">A flag indicating if at least one test for the production order line was created</param>
    /// <param name="CreatedTestForProdOrder">A flag indicating if at least one test for the production order was created</param>
    /// <param name="OfTests">A list of record ids of the tests that were created</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterProductionAttemptCreateReleaseAutomaticTest(var ProductionOrder: Record "Production Order"; CreatedAtLeastOneTestForRoutingLine: Boolean; CreatedAtLeastOneTestForOrderLine: Boolean; CreatedTestForProdOrder: Boolean; OfTestIds: List of [RecordId])
    begin
    end;

    /// <summary>
    /// Gives an opportunity to override any handle of onafterpostoutput.
    /// Use this to completely replace any automatic test creation on output and/or any automatic test validation on output
    /// </summary>
    /// <param name="ItemLedgerEntry">The item ledger entry related to this sequence of events</param>
    /// <param name="ProdOrderLine">The production order line involved in this sequence of events</param>
    /// <param name="ItemJournalLine">The item journal line record involved in this transaction.  Important: this record may no longer exist, and should not be altered.</param>
    /// <param name="Handled">Set to true to replace the default behavior</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeProductionHandleOnAfterPostOutput(var ItemLedgerEntry: Record "Item Ledger Entry"; var ProdOrderLine: Record "Prod. Order Line"; var ItemJournalLine: Record "Item Journal Line"; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// Gives an opportunity to supplement or replace automatic test creation on finish, and validation of tests on finish.
    /// </summary>
    /// <param name="FromProductionOrder"></param>
    /// <param name="ToProductionOrder"></param>
    /// <param name="Handled">Set to true to replace the default behavior</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeProductionHandleOnAfterChangeStatusOnProdOrder(var FromProductionOrder: Record "Production Order"; var ToProductionOrder: Record "Production Order"; var Handled: Boolean)
    begin
    end;
}

