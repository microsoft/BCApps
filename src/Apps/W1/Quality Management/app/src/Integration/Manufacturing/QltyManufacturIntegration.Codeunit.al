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
using Microsoft.QualityManagement.Setup;

/// <summary>
/// Used to integrate with manufacturing related events.
/// </summary>
codeunit 20407 "Qlty. Manufactur. Integration"
{
    var
        QltyTraversal: Codeunit "Qlty. Traversal";

    /// <summary>
    /// We subscribe to OnAfterPostOutput to see if we need to create an inspection related to the output.
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
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        VerifiedItemLedgerEntry: Record "Item Ledger Entry";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        IsHandled: Boolean;
    begin
        if not QltyManagementSetup.GetSetupRecord() then
            exit;

        case QltyManagementSetup."Prod. trigger output condition" of
            QltyManagementSetup."Prod. trigger output condition"::OnAnyQuantity:
                if (ItemJournalLine.Quantity = 0) and (ItemJournalLine."Scrap Quantity" = 0) then
                    exit;
            QltyManagementSetup."Prod. trigger output condition"::OnlyWithQuantity:
                if ItemJournalLine.Quantity = 0 then
                    exit;
            QltyManagementSetup."Prod. trigger output condition"::OnlyWithScrap:
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

        OnBeforeProductionHandleOnAfterPostOutput(VerifiedItemLedgerEntry, ProdOrderLine, ItemJournalLine, IsHandled);
        if IsHandled then
            exit;

        ProdOrderRoutingLine.SetRange(Status, ProdOrderLine.Status);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderRoutingLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
        ProdOrderRoutingLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
        ProdOrderRoutingLine.SetRange("Operation No.", ItemJournalLine."Operation No.");
        if ProdOrderRoutingLine.FindFirst() then
            if ProdOrderRoutingLine."Next Operation No." <> '' then
                Clear(VerifiedItemLedgerEntry);

        QltyInspectionGenRule.SetRange("Production Order Trigger", QltyInspectionGenRule."Production Order Trigger"::OnProductionOutputPost);
        QltyInspectionGenRule.SetFilter("Activation Trigger", '%1|%2', QltyInspectionGenRule."Activation Trigger"::"Manual or Automatic", QltyInspectionGenRule."Activation Trigger"::"Automatic only");
        if not QltyInspectionGenRule.IsEmpty() then
            AttemptCreateInspectionPosting(ProdOrderRoutingLine, VerifiedItemLedgerEntry, ProdOrderLine, ItemJournalLine, QltyInspectionGenRule);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Prod. Order Status Management", 'OnAfterChangeStatusOnProdOrder', '', true, true)]
    local procedure HandleOnAfterChangeStatusOnProdOrder(var ProdOrder: Record "Production Order"; var ToProdOrder: Record "Production Order"; NewStatus: Enum "Production Order Status"; NewPostingDate: Date; NewUpdateUnitCost: Boolean; var SuppressCommit: Boolean; xProductionOrder: Record "Production Order")
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        IsHandled: Boolean;
    begin
        if not QltyManagementSetup.GetSetupRecord() then
            exit;

        OnBeforeProductionHandleOnAfterChangeStatusOnProdOrder(xProductionOrder, ToProdOrder, IsHandled);
        if IsHandled then
            exit;

        if QltyManagementSetup."Production Update Control" in [QltyManagementSetup."Production Update Control"::"Update when source changes"] then
            UpdateReferencesForProductionOrder(xProductionOrder, ToProdOrder);

        if ToProdOrder.Status <> ToProdOrder.Status::Released then
            exit;

        QltyInspectionGenRule.SetRange("Production Order Trigger", QltyInspectionGenRule."Production Order Trigger"::OnProductionOrderRelease);
        QltyInspectionGenRule.SetFilter("Activation Trigger", '%1|%2', QltyInspectionGenRule."Activation Trigger"::"Manual or Automatic", QltyInspectionGenRule."Activation Trigger"::"Automatic only");
        if not QltyInspectionGenRule.IsEmpty() then
            AttemptCreateInspectionReleased(ToProdOrder, QltyInspectionGenRule);
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
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
    begin
        if ErrorOccured then
            exit;

        if ProductionOrder.Status <> ProductionOrder.Status::Released then
            exit;

        if not QltyManagementSetup.GetSetupRecord() then
            exit;

        QltyInspectionGenRule.SetRange("Production Order Trigger", QltyInspectionGenRule."Production Order Trigger"::OnReleasedProductionOrderRefresh);
        QltyInspectionGenRule.SetFilter("Activation Trigger", '%1|%2', QltyInspectionGenRule."Activation Trigger"::"Manual or Automatic", QltyInspectionGenRule."Activation Trigger"::"Automatic only");
        if not QltyInspectionGenRule.IsEmpty() then
            AttemptCreateInspectionReleased(ProductionOrder, QltyInspectionGenRule);
    end;

    /// <summary>
    /// Updates source records for inspections where the source is a production order
    /// </summary>
    /// <param name="OldProductionOrder"></param>
    /// <param name="NewProductionOrder"></param>
    [InherentPermissions(PermissionObjectType::TableData, Database::"Qlty. Inspection Header", 'rm')]
    local procedure UpdateReferencesForProductionOrder(OldProductionOrder: Record "Production Order"; NewProductionOrder: Record "Production Order")
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TargetRecordRef: RecordRef;
    begin
        TargetRecordRef.GetTable(NewProductionOrder);

        // Use filter groups to find records where any of the Source RecordId fields match
        QltyInspectionHeader.FilterGroup(-1); // Cross-column filtering
        QltyInspectionHeader.SetRange("Source RecordId", OldProductionOrder.RecordId());
        QltyInspectionHeader.SetRange("Source RecordId 2", OldProductionOrder.RecordId());
        QltyInspectionHeader.SetRange("Source RecordId 3", OldProductionOrder.RecordId());
        QltyInspectionHeader.SetRange("Source RecordId 4", OldProductionOrder.RecordId());
        QltyInspectionHeader.FilterGroup(0);

        if QltyInspectionHeader.FindSet(true) then
            repeat
                if QltyInspectionHeader."Source RecordId" = OldProductionOrder.RecordId() then
                    QltyInspectionHeader."Source RecordId" := NewProductionOrder.RecordId()
                else
                    if QltyInspectionHeader."Source RecordId 2" = OldProductionOrder.RecordId() then
                        QltyInspectionHeader."Source RecordId 2" := NewProductionOrder.RecordId()
                    else
                        if QltyInspectionHeader."Source RecordId 3" = OldProductionOrder.RecordId() then
                            QltyInspectionHeader."Source RecordId 3" := NewProductionOrder.RecordId()
                        else
                            if QltyInspectionHeader."Source RecordId 4" = OldProductionOrder.RecordId() then
                                QltyInspectionHeader."Source RecordId 4" := NewProductionOrder.RecordId();
                UpdateSourceDocumentForSpecificInspectionOnOrder(QltyInspectionHeader, TargetRecordRef, OldProductionOrder, NewProductionOrder);
            until QltyInspectionHeader.Next() = 0;
    end;

    /// <summary>
    /// Updates inspections where the source is a production order line
    /// </summary>
    /// <param name="OldProdOrderLine"></param>
    /// <param name="NewProdOrderLine"></param>
    [InherentPermissions(PermissionObjectType::TableData, Database::"Qlty. Inspection Header", 'rm')]
    local procedure UpdateReferencesForProductionOrderLine(OldProdOrderLine: Record "Prod. Order Line"; NewProdOrderLine: Record "Prod. Order Line")
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TargetRecordRef: RecordRef;
    begin
        TargetRecordRef.GetTable(NewProdOrderLine);

        // Use filter groups to find records where any of the Source RecordId fields match
        QltyInspectionHeader.FilterGroup(-1); // Cross-column filtering
        QltyInspectionHeader.SetRange("Source RecordId", OldProdOrderLine.RecordId());
        QltyInspectionHeader.SetRange("Source RecordId 2", OldProdOrderLine.RecordId());
        QltyInspectionHeader.SetRange("Source RecordId 3", OldProdOrderLine.RecordId());
        QltyInspectionHeader.SetRange("Source RecordId 4", OldProdOrderLine.RecordId());
        QltyInspectionHeader.FilterGroup(0);

        if QltyInspectionHeader.FindSet(true) then
            repeat
                if QltyInspectionHeader."Source RecordId" = OldProdOrderLine.RecordId() then
                    QltyInspectionHeader."Source RecordId" := NewProdOrderLine.RecordId()
                else
                    if QltyInspectionHeader."Source RecordId 2" = OldProdOrderLine.RecordId() then
                        QltyInspectionHeader."Source RecordId 2" := NewProdOrderLine.RecordId()
                    else
                        if QltyInspectionHeader."Source RecordId 3" = OldProdOrderLine.RecordId() then
                            QltyInspectionHeader."Source RecordId 3" := NewProdOrderLine.RecordId()
                        else
                            if QltyInspectionHeader."Source RecordId 4" = OldProdOrderLine.RecordId() then
                                QltyInspectionHeader."Source RecordId 4" := NewProdOrderLine.RecordId();
                UpdateSourceDocumentForSpecificInspectionOnLine(QltyInspectionHeader, TargetRecordRef, OldProdOrderLine, NewProdOrderLine);
            until QltyInspectionHeader.Next() = 0;
    end;

    /// <summary>
    /// Updates inspections where the source is a production order routing line
    /// </summary>
    /// <param name="OldProdOrderRoutingLine"></param>
    /// <param name="NewProdOrderRoutingLine"></param>
    [InherentPermissions(PermissionObjectType::TableData, Database::"Qlty. Inspection Header", 'rm')]
    local procedure UpdateReferencesForProductionOrderRoutingLine(OldProdOrderRoutingLine: Record "Prod. Order Routing Line"; NewProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TargetRecordRef: RecordRef;
    begin
        TargetRecordRef.GetTable(NewProdOrderRoutingLine);

        // Use filter groups to find records where any of the Source RecordId fields match
        QltyInspectionHeader.FilterGroup(-1); // Cross-column filtering
        QltyInspectionHeader.SetRange("Source RecordId", OldProdOrderRoutingLine.RecordId());
        QltyInspectionHeader.SetRange("Source RecordId 2", OldProdOrderRoutingLine.RecordId());
        QltyInspectionHeader.SetRange("Source RecordId 3", OldProdOrderRoutingLine.RecordId());
        QltyInspectionHeader.SetRange("Source RecordId 4", OldProdOrderRoutingLine.RecordId());
        QltyInspectionHeader.FilterGroup(0);

        if QltyInspectionHeader.FindSet(true) then
            repeat
                if QltyInspectionHeader."Source RecordId" = OldProdOrderRoutingLine.RecordId() then
                    QltyInspectionHeader."Source RecordId" := NewProdOrderRoutingLine.RecordId()
                else
                    if QltyInspectionHeader."Source RecordId 2" = OldProdOrderRoutingLine.RecordId() then
                        QltyInspectionHeader."Source RecordId 2" := NewProdOrderRoutingLine.RecordId()
                    else
                        if QltyInspectionHeader."Source RecordId 3" = OldProdOrderRoutingLine.RecordId() then
                            QltyInspectionHeader."Source RecordId 3" := NewProdOrderRoutingLine.RecordId()
                        else
                            if QltyInspectionHeader."Source RecordId 4" = OldProdOrderRoutingLine.RecordId() then
                                QltyInspectionHeader."Source RecordId 4" := NewProdOrderRoutingLine.RecordId();
                UpdateSourceDocumentForSpecificInspectionOnOperation(QltyInspectionHeader, TargetRecordRef, OldProdOrderRoutingLine, NewProdOrderRoutingLine);
            until QltyInspectionHeader.Next() = 0;
    end;

    local procedure UpdateSourceDocumentForSpecificInspectionOnOrder(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TargetRecordRef: RecordRef; OldProductionOrder: Record "Production Order"; NewProductionOrder: Record "Production Order")
    var
        OldStatusValue: Integer;
        NewStatusValue: Integer;
    begin
        OldStatusValue := OldProductionOrder.Status.AsInteger();
        NewStatusValue := NewProductionOrder.Status.AsInteger();
        if not QltyTraversal.ApplySourceFields(TargetRecordRef, QltyInspectionHeader, false, true) then begin
            if QltyInspectionHeader."Source Type" = OldStatusValue then
                QltyInspectionHeader."Source Type" := NewStatusValue;

            if QltyInspectionHeader."Source Document No." = OldProductionOrder."No." then
                QltyInspectionHeader."Source Document No." := NewProductionOrder."No.";
        end;

        if QltyInspectionHeader.Modify(false) then;
    end;

    local procedure UpdateSourceDocumentForSpecificInspectionOnLine(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TargetRecordRef: RecordRef; OldProdOrderLine: Record "Prod. Order Line"; NewProdOrderLine: Record "Prod. Order Line")
    var
        OldStatusValue: Integer;
        NewStatusValue: Integer;
    begin
        OldStatusValue := OldProdOrderLine.Status.AsInteger();
        NewStatusValue := NewProdOrderLine.Status.AsInteger();
        if not QltyTraversal.ApplySourceFields(TargetRecordRef, QltyInspectionHeader, false, true) then begin
            if QltyInspectionHeader."Source Type" = OldStatusValue then
                QltyInspectionHeader."Source Type" := NewStatusValue;

            if QltyInspectionHeader."Source Document No." = OldProdOrderLine."Prod. Order No." then
                QltyInspectionHeader."Source Document No." := NewProdOrderLine."Prod. Order No.";

            if QltyInspectionHeader."Source Document Line No." = OldProdOrderLine."Line No." then
                QltyInspectionHeader."Source Document Line No." := NewProdOrderLine."Line No.";
        end;
        if QltyInspectionHeader.Modify(false) then;
    end;

    local procedure UpdateSourceDocumentForSpecificInspectionOnOperation(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TargetRecordRef: RecordRef; OldProdOrderRoutingLine: Record "Prod. Order Routing Line"; NewProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        OldStatusValue: Integer;
        NewStatusValue: Integer;
    begin
        OldStatusValue := OldProdOrderRoutingLine.Status.AsInteger();
        NewStatusValue := NewProdOrderRoutingLine.Status.AsInteger();
        if not QltyTraversal.ApplySourceFields(TargetRecordRef, QltyInspectionHeader, false, true) then begin
            if QltyInspectionHeader."Source Type" = OldStatusValue then
                QltyInspectionHeader."Source Type" := NewStatusValue;

            if QltyInspectionHeader."Source Document No." = OldProdOrderRoutingLine."Prod. Order No." then
                QltyInspectionHeader."Source Document No." := NewProdOrderRoutingLine."Prod. Order No.";

            if QltyInspectionHeader."Source Task No." = OldProdOrderRoutingLine."Operation No." then
                QltyInspectionHeader."Source Task No." := NewProdOrderRoutingLine."Operation No.";
        end;
        if QltyInspectionHeader.Modify(false) then;
    end;

    /// <summary>
    /// Intended to be used with production releasing.
    /// For production releasing it will use either the prod order routing line, or prod order line, or prod order.
    /// What we can do is automatically apply them.
    /// </summary>
    /// <param name="ProductionOrder">The production order</param>
    /// <param name="OptionalFiltersQltyInspectionGenRule">Optional generation rule filters.</param>
    local procedure AttemptCreateInspectionReleased(var ProductionOrder: Record "Production Order"; var OptionalFiltersQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule")
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        ProdOrderLine: Record "Prod. Order Line";
        ReservationEntry: Record "Reservation Entry";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        ProdOrderLineReserve: Codeunit "Prod. Order Line-Reserve";
        ListOfInspectionIds: List of [RecordId];
        HasReservationEntries: Boolean;
        IsHandled: Boolean;
        CreatedAtLeastOneInspectionForRoutingLine: Boolean;
        CreatedAtLeastOneInspectionForOrderLine: Boolean;
        CreatedInspectionForProdOrder: Boolean;
        MadeInspection: Boolean;
        DummyVariant: Variant;
    begin
        OnBeforeProductionAttemptCreateReleaseAutomaticInspection(ProductionOrder, IsHandled);
        if IsHandled then
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

                                MadeInspection := QltyInspectionCreate.CreateInspectionWithMultiVariants(ProdOrderRoutingLine, TempTrackingSpecification, ProdOrderLine, ProductionOrder, false, OptionalFiltersQltyInspectionGenRule);

                                if MadeInspection then begin
                                    QltyInspectionCreate.GetCreatedInspection(QltyInspectionHeader);
                                    ListOfInspectionIds.Add(QltyInspectionHeader.RecordId());
                                    CreatedAtLeastOneInspectionForRoutingLine := true;
                                end;
                            until ReservationEntry.Next() = 0;
                        end else begin
                            MadeInspection := QltyInspectionCreate.CreateInspectionWithMultiVariants(ProdOrderRoutingLine, ProdOrderLine, ProductionOrder, DummyVariant, false, OptionalFiltersQltyInspectionGenRule);

                            if MadeInspection then begin
                                QltyInspectionCreate.GetCreatedInspection(QltyInspectionHeader);
                                ListOfInspectionIds.Add(QltyInspectionHeader.RecordId());
                                CreatedAtLeastOneInspectionForRoutingLine := true;
                            end;
                        end;
                    until ProdOrderRoutingLine.Next() = 0;

                if not CreatedAtLeastOneInspectionForRoutingLine then
                    if HasReservationEntries then begin
                        ReservationEntry.FindSet();
                        repeat
                            Clear(TempTrackingSpecification);
                            TempTrackingSpecification.DeleteAll(false);
                            TempTrackingSpecification.SetSourceFromReservEntry(ReservationEntry);
                            TempTrackingSpecification.CopyTrackingFromReservEntry(ReservationEntry);
                            TempTrackingSpecification.Insert();

                            MadeInspection := QltyInspectionCreate.CreateInspectionWithMultiVariants(TempTrackingSpecification, ProdOrderLine, ProductionOrder, DummyVariant, false, OptionalFiltersQltyInspectionGenRule);

                            if MadeInspection then begin
                                QltyInspectionCreate.GetCreatedInspection(QltyInspectionHeader);
                                ListOfInspectionIds.Add(QltyInspectionHeader.RecordId());
                                CreatedAtLeastOneInspectionForOrderLine := true;
                            end;

                        until ReservationEntry.Next() = 0;
                    end else begin
                        MadeInspection := QltyInspectionCreate.CreateInspectionWithMultiVariants(ProdOrderLine, ProductionOrder, DummyVariant, DummyVariant, false, OptionalFiltersQltyInspectionGenRule);
                        if MadeInspection then begin
                            QltyInspectionCreate.GetCreatedInspection(QltyInspectionHeader);
                            ListOfInspectionIds.Add(QltyInspectionHeader.RecordId());
                            CreatedAtLeastOneInspectionForOrderLine := true;
                        end;
                    end;
            until ProdOrderLine.Next() = 0;
        end;
        if (not CreatedAtLeastOneInspectionForOrderLine) and (not CreatedAtLeastOneInspectionForRoutingLine) then begin
            MadeInspection := QltyInspectionCreate.CreateInspectionWithMultiVariants(ProductionOrder, DummyVariant, DummyVariant, DummyVariant, false, OptionalFiltersQltyInspectionGenRule);
            if MadeInspection then begin
                QltyInspectionCreate.GetCreatedInspection(QltyInspectionHeader);
                ListOfInspectionIds.Add(QltyInspectionHeader.RecordId());
                CreatedInspectionForProdOrder := MadeInspection;
            end;
        end;

        OnAfterProductionAttemptCreateReleaseAutomaticInspection(ProductionOrder, CreatedAtLeastOneInspectionForRoutingLine, CreatedAtLeastOneInspectionForOrderLine, CreatedInspectionForProdOrder, ListOfInspectionIds);
    end;

    /// <summary>
    /// Intended to be used with production related posting.
    /// For production posting we have three references, any of which could be used as a trigger depending on the scenario.
    /// What we can do is automatically apply them.
    /// </summary>
    /// <param name="ItemLedgerEntry">The item ledger entry related to this sequence of events</param>
    /// <param name="ProdOrderLine"></param>
    /// <param name="ItemJournalLine"></param>
    local procedure AttemptCreateInspectionPosting(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var ItemLedgerEntry: Record "Item Ledger Entry"; var ProdOrderLine: Record "Prod. Order Line"; var ItemJournalLine: Record "Item Journal Line"; var OptionalFiltersQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule")
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        IsHandled: Boolean;
        HasInspection: Boolean;
        DummyVariant: Variant;
    begin
        OnBeforeProductionAttemptCreatePostAutomaticInspection(ProdOrderRoutingLine, ItemLedgerEntry, ProdOrderLine, ItemJournalLine, IsHandled);
        if IsHandled then
            exit;

        if (ItemLedgerEntry."Entry Type" <> ItemLedgerEntry."Entry Type"::Output) or (ItemLedgerEntry."Item No." = '') then
            HasInspection := QltyInspectionCreate.CreateInspectionWithMultiVariants(ProdOrderRoutingLine, ItemJournalLine, ProdOrderLine, DummyVariant, false, OptionalFiltersQltyInspectionGenRule)

        else
            if ProdOrderRoutingLine."Operation No." <> '' then
                HasInspection := QltyInspectionCreate.CreateInspectionWithMultiVariants(ItemLedgerEntry, ProdOrderRoutingLine, ItemJournalLine, ProdOrderLine, false, OptionalFiltersQltyInspectionGenRule)
            else
                HasInspection := QltyInspectionCreate.CreateInspectionWithMultiVariants(ItemLedgerEntry, ItemJournalLine, ProdOrderLine, DummyVariant, false, OptionalFiltersQltyInspectionGenRule);

        if HasInspection then
            QltyInspectionCreate.GetCreatedInspection(QltyInspectionHeader);

        OnAfterProductionAttemptCreateAutomaticInspection(ProdOrderRoutingLine, ItemLedgerEntry, ProdOrderLine, ItemJournalLine);
    end;

    /// <summary>
    /// OnBeforeProductionAttemptCreatePostAutomaticInspection is called before attempting to automatically create an inspection for production related events prior to posting to posting.
    /// </summary>
    /// <param name="ProdOrderRoutingLine">Typically the 'main' record the inspections are associated against.</param>
    /// <param name="ItemLedgerEntry">The item ledger entry related to this sequence of events</param>
    /// <param name="ProdOrderLine">The production order line involved in this sequence of events</param>
    /// <param name="ItemJournalLine">The item journal line record involved in this transaction.  Important: this record may no longer exist, and should not be altered.</param>
    /// <param name="IsHandled">Set to true to replace the default behavior</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeProductionAttemptCreatePostAutomaticInspection(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var ItemLedgerEntry: Record "Item Ledger Entry"; var ProdOrderLine: Record "Prod. Order Line"; var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// OnAfterProductionAttemptCreateAutomaticInspection is called after attempting to automatically create an inspection for production.
    /// </summary>
    /// <param name="ProdOrderRoutingLine">Typically the 'main' record the inspections are associated against.</param>
    /// <param name="ItemLedgerEntry">The item ledger entry related to this sequence of events</param>
    /// <param name="ProdOrderLine">The production order line involved in this sequence of events</param>
    /// <param name="ItemJournalLine">The item journal line record involved in this transaction.  Important: this record may no longer exist, and should not be altered.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterProductionAttemptCreateAutomaticInspection(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var ItemLedgerEntry: Record "Item Ledger Entry"; var ProdOrderLine: Record "Prod. Order Line"; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    /// <summary>
    /// OnBeforeProductionAttemptCreateReleaseAutomaticInspection is called before attempting to automatically create an inspection for production related releasing.
    /// </summary>
    /// <param name="ProductionOrder">The production order</param>
    /// <param name="IsHandled">Set to true to replace the default behavior</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeProductionAttemptCreateReleaseAutomaticInspection(var ProductionOrder: Record "Production Order"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// OnAfterProductionAttemptCreateReleaseAutomaticInspection is called before attempting to automatically create an inspection for production related releasing.
    /// Use this if you need to collect multiple inspections that could be created as part of a posting sequence.
    /// </summary>
    /// <param name="ProductionOrder">The production order</param>
    /// <param name="CreatedAtLeastOneInspectionForRoutingLine">A flag indicating if at least one inspection for the production order routing line was created</param>
    /// <param name="CreatedAtLeastOneInspectionForOrderLine">A flag indicating if at least one inspection for the production order line was created</param>
    /// <param name="CreatedInspectionForProdOrder">A flag indicating if at least one inspection for the production order was created</param>
    /// <param name="ListOfInspectionIds">A list of record ids of the inspections that were created</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterProductionAttemptCreateReleaseAutomaticInspection(var ProductionOrder: Record "Production Order"; CreatedAtLeastOneInspectionForRoutingLine: Boolean; CreatedAtLeastOneInspectionForOrderLine: Boolean; CreatedInspectionForProdOrder: Boolean; ListOfInspectionIds: List of [RecordId])
    begin
    end;

    /// <summary>
    /// Gives an opportunity to override any handle of onafterpostoutput.
    /// Use this to completely replace any automatic inspection creation on output and/or any automatic inspection validation on output
    /// </summary>
    /// <param name="ItemLedgerEntry">The item ledger entry related to this sequence of events</param>
    /// <param name="ProdOrderLine">The production order line involved in this sequence of events</param>
    /// <param name="ItemJournalLine">The item journal line record involved in this transaction.  Important: this record may no longer exist, and should not be altered.</param>
    /// <param name="IsHandled">Set to true to replace the default behavior</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeProductionHandleOnAfterPostOutput(var ItemLedgerEntry: Record "Item Ledger Entry"; var ProdOrderLine: Record "Prod. Order Line"; var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Gives an opportunity to supplement or replace automatic inspection creation on finish, and validation of inspections on finish.
    /// </summary>
    /// <param name="FromProductionOrder"></param>
    /// <param name="ToProductionOrder"></param>
    /// <param name="IsHandled">Set to true to replace the default behavior</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeProductionHandleOnAfterChangeStatusOnProdOrder(var FromProductionOrder: Record "Production Order"; var ToProductionOrder: Record "Production Order"; var IsHandled: Boolean)
    begin
    end;
}
