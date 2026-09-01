// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
codeunit 99001556 "Subc. Create Prod. Ord. Opt."
{
    TableNo = "Purchase Line";

    var
        SubcManagementSetup: Record "Subc. Management Setup";
        SubcTempDataInitializer: Codeunit "Subc. Temp Data Initializer";
        SubcVersionMgmt: Codeunit "Subc. Version Mgmt.";
        BOMCreated, BOMVersionCreated : Boolean;
        HasSubManagementSetup: Boolean;
        ProdCompRoutingModified: Boolean;
        ProdOrderCompRoutingCreated: Boolean;
        RoutingCreated, RoutingVersionCreated : Boolean;
        GlobalSubcRtngBOMSourceType: Enum "Subc. RtngBOMSourceType";

    trigger OnRun()
    begin
        CreateProductionOrderWithTemporaryData(Rec);
    end;

    /// <summary>
    /// Main orchestration method for creating production orders with temporary data handling
    /// </summary>
    local procedure CreateProductionOrderWithTemporaryData(var PurchaseLine: Record "Purchase Line")
    var
        Item: Record Item;
        SubcScenarioType: Enum "Subc. Scenario Type";
    begin
        ValidateAndPrepareCreation(PurchaseLine, Item);
        SubcScenarioType := DetermineScenarioAndPrepareData(Item, PurchaseLine);

        if not ExecuteBOMRoutingWizardProcess(Item, SubcScenarioType) then
            Error('');

        TransferTemporaryDataToRealTables(PurchaseLine);
    end;

    /// <summary>
    /// Determines the scenario type based on existing BOM and Routing data from best source
    /// </summary>
    local procedure DetermineScenarioAndPrepareData(Item: Record Item; PurchaseLine: Record "Purchase Line") SubcScenarioType: Enum "Subc. Scenario Type"
    var
        BOMNo, RoutingNo : Code[20];
        SubcRtngBOMSourceType: Enum "Subc. RtngBOMSourceType";
    begin
        SubcTempDataInitializer.InitializeTemporaryProdOrder(PurchaseLine);

        GetBOMAndRoutingFromBestSource(Item, BOMNo, RoutingNo, SubcRtngBOMSourceType);

        SubcTempDataInitializer.SetRtngBOMSourceType(SubcRtngBOMSourceType);

        SubcScenarioType := GetScenarioTypeFromBOMRouting(BOMNo, RoutingNo);

        PrepareBOMAndRoutingDataForScenario(BOMNo, RoutingNo);

        exit(SubcScenarioType);
    end;

    /// <summary>
    /// Gets BOM and routing from best source (Stockkeeping Unit or Item)
    /// </summary>
    local procedure GetBOMAndRoutingFromBestSource(var Item: Record Item; var BOMNo: Code[20]; var RoutingNo: Code[20]; var SubcRtngBOMSourceType: Enum "Subc. RtngBOMSourceType")
    var
        LocationCode, VariantCode : Code[10];
    begin
        Clear(BOMNo);
        Clear(RoutingNo);
        SubcRtngBOMSourceType := SubcRtngBOMSourceType::Empty;

        GetLocationAndVariantForStockkeepingUnit(LocationCode, VariantCode);

        if GetBOMAndRoutingFromStockkeepingUnit(Item."No.", VariantCode, LocationCode, BOMNo, RoutingNo) then begin
            SubcRtngBOMSourceType := SubcRtngBOMSourceType::StockkeepingUnit;
            exit;
        end;

        BOMNo := Item."Production BOM No.";
        RoutingNo := Item."Routing No.";

        if (BOMNo <> '') or (RoutingNo <> '') then
            SubcRtngBOMSourceType := SubcRtngBOMSourceType::Item;
    end;

    /// <summary>
    /// Gets BOM and routing from Stockkeeping Unit
    /// </summary>
    local procedure GetBOMAndRoutingFromStockkeepingUnit(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; var BOMNo: Code[20]; var RoutingNo: Code[20]): Boolean
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        StockkeepingUnit.SetLoadFields("Production BOM No.", "Routing No.");
        if not StockkeepingUnit.Get(LocationCode, ItemNo, VariantCode) then
            exit(false);

        BOMNo := StockkeepingUnit."Production BOM No.";
        RoutingNo := StockkeepingUnit."Routing No.";

        exit((BOMNo <> '') or (RoutingNo <> ''));
    end;

    /// <summary>
    /// Determines scenario type based on BOM and Routing presence
    /// </summary>
    local procedure GetScenarioTypeFromBOMRouting(BOMNo: Code[20]; RoutingNo: Code[20]): Enum "Subc. Scenario Type"
    var
        SubcScenarioType: Enum "Subc. Scenario Type";
    begin
        if (BOMNo <> '') and (RoutingNo <> '') then
            exit(SubcScenarioType::BothAvailable);

        if (BOMNo <> '') or (RoutingNo <> '') then
            exit(SubcScenarioType::PartiallyAvailable);

        exit(SubcScenarioType::NothingAvailable);
    end;

    /// <summary>
    /// Validates purchase line and prepares item data
    /// </summary>
    local procedure ValidateAndPrepareCreation(var PurchaseLine: Record "Purchase Line"; var Item: Record Item)
    begin
        ValidateMandatoryFields(PurchaseLine);
        Item.SetLoadFields("Production BOM No.", "Routing No.", "Scrap %", "Inventory Posting Group");
        Item.Get(PurchaseLine."No.");
    end;

    /// <summary>
    /// Prepares BOM and Routing data based on scenario requirements
    /// </summary>
    local procedure PrepareBOMAndRoutingDataForScenario(BOMNo: Code[20]; RoutingNo: Code[20])
    var
        BOMVersionCode, RoutingVersionCode : Code[20];
    begin
        SubcTempDataInitializer.InitializeNewTemporaryBOMInformation();
        if BOMNo <> '' then begin
            BOMVersionCode := SubcVersionMgmt.GetDefaultBOMVersion(BOMNo);
            SubcTempDataInitializer.LoadBOMLines(BOMNo, BOMVersionCode);
        end;

        SubcTempDataInitializer.InitializeNewTemporaryRoutingInformation();
        if RoutingNo <> '' then begin
            RoutingVersionCode := SubcVersionMgmt.GetDefaultRoutingVersion(RoutingNo);
            SubcTempDataInitializer.LoadRoutingLines(RoutingNo, RoutingVersionCode);
        end;
    end;

    /// <summary>
    /// Executes the BOM/Routing wizard process with user interaction
    /// </summary>
    local procedure ExecuteBOMRoutingWizardProcess(Item: Record Item; SubcScenarioType: Enum "Subc. Scenario Type"): Boolean
    begin
        exit(RunBOMRoutingWizardWithUserInteraction(Item, SubcScenarioType));
    end;

    /// <summary>
    /// Handles the wizard interaction with show/edit type determination
    /// </summary>
    local procedure RunBOMRoutingWizardWithUserInteraction(Item: Record Item; SubcScenarioType: Enum "Subc. Scenario Type"): Boolean
    var
        SubcTempProdOrdBind: Codeunit "Subc. TempProdOrdBind";
        BOMRoutingShowEditType: Enum "Subc. Show/Edit Type";
        ProdCompRoutingShowEditType: Enum "Subc. Show/Edit Type";
    begin
        BindSubscription(SubcTempProdOrdBind);
        GetShowEditTypesForScenario(SubcScenarioType, BOMRoutingShowEditType, ProdCompRoutingShowEditType);

        if ShouldSkipUserInteraction(BOMRoutingShowEditType, ProdCompRoutingShowEditType) then begin
            SubcTempDataInitializer.BuildTemporaryStructureFromBOMRouting();
            exit(true);
        end;

        exit(ExecuteWizardPageWithTemporaryData(Item, BOMRoutingShowEditType, ProdCompRoutingShowEditType));
    end;

    /// <summary>
    /// Gets show/edit types for both BOM/Routing and Production Components/Routing in one call
    /// </summary>
    local procedure GetShowEditTypesForScenario(SubcScenarioType: Enum "Subc. Scenario Type"; var BOMRoutingShowEditType: Enum "Subc. Show/Edit Type"; var ProdCompRoutingShowEditType: Enum "Subc. Show/Edit Type")
    begin
        GetSubManagementSetupCached();

        case SubcScenarioType of
            SubcScenarioType::BothAvailable:
                begin
                    BOMRoutingShowEditType := SubcManagementSetup.ShowRtngBOMSelect_Both;
                    ProdCompRoutingShowEditType := SubcManagementSetup.ShowProdRtngCompSelect_Both;
                end;
            SubcScenarioType::PartiallyAvailable:
                begin
                    BOMRoutingShowEditType := SubcManagementSetup.ShowRtngBOMSelect_Partial;
                    ProdCompRoutingShowEditType := SubcManagementSetup.ShowProdRtngCompSelect_Partial;
                end;
            SubcScenarioType::NothingAvailable:
                begin
                    BOMRoutingShowEditType := SubcManagementSetup.ShowRtngBOMSelect_Nothing;
                    ProdCompRoutingShowEditType := SubcManagementSetup.ShowProdRtngCompSelect_Nothing;
                end
        end;
    end;

    /// <summary>
    /// Determines if user interaction can be skipped
    /// </summary>
    local procedure ShouldSkipUserInteraction(BOMRoutingShowEditType: Enum "Subc. Show/Edit Type"; ProdCompRoutingShowEditType: Enum "Subc. Show/Edit Type"): Boolean
    begin
        exit((BOMRoutingShowEditType = BOMRoutingShowEditType::Hide) and
             (ProdCompRoutingShowEditType = ProdCompRoutingShowEditType::Hide));
    end;

    /// <summary>
    /// Executes the wizard page with temporary data binding
    /// </summary>
    local procedure ExecuteWizardPageWithTemporaryData(Item: Record Item; BOMRoutingShowEditType: Enum "Subc. Show/Edit Type"; ProdCompRoutingShowEditType: Enum "Subc. Show/Edit Type"): Boolean
    var
        SubcPurchProvisionWizard: Page "Subc. PurchProvisionWizard";
    begin
        SetupWizardPageWithTemporaryData(SubcPurchProvisionWizard, Item, BOMRoutingShowEditType, ProdCompRoutingShowEditType);
        SubcPurchProvisionWizard.RunModal();

        if SubcPurchProvisionWizard.GetFinished() then begin
            UpdateWizardResults(SubcPurchProvisionWizard);
            exit(true);
        end;

        exit(false);
    end;

    /// <summary>
    /// Updates internal flags based on wizard results
    /// </summary>
    local procedure UpdateWizardResults(var SubcPurchProvisionWizard: Page "Subc. PurchProvisionWizard")
    begin
        ProdCompRoutingModified := SubcPurchProvisionWizard.GetApplyChangesComponents() or SubcPurchProvisionWizard.GetApplyChangesProdRouting();
        GlobalSubcRtngBOMSourceType := SubcPurchProvisionWizard.GetApplyBomRtngToSource();
    end;

    /// <summary>
    /// Configures the wizard page with temporary data
    /// </summary>
    local procedure SetupWizardPageWithTemporaryData(var SubcPurchProvisionWizard: Page "Subc. PurchProvisionWizard"; Item: Record Item; BOMRoutingShowEditType: Enum "Subc. Show/Edit Type"; ProdCompRoutingShowEditType: Enum "Subc. Show/Edit Type")
    begin
        SubcPurchProvisionWizard.SetItem(Item);
        SubcPurchProvisionWizard.SetBOMRoutingShowEditType(BOMRoutingShowEditType);
        SubcPurchProvisionWizard.SetProdCompRoutingShowEditType(ProdCompRoutingShowEditType);
        SubcPurchProvisionWizard.SetTempDataInitializer(SubcTempDataInitializer);
    end;

    /// <summary>
    /// Main method for transferring temporary data to real tables with transaction safety
    /// </summary>
    [CommitBehavior(CommitBehavior::Ignore)]
    local procedure TransferTemporaryDataToRealTables(var PurchaseLine: Record "Purchase Line")
    var
        ProductionOrder: Record "Production Order";
        SubcProdOrderCreateBind: Codeunit "Subc. ProdOrderCreateBind";
    begin
        BindSubscription(SubcProdOrderCreateBind);
        SubcProdOrderCreateBind.SetSubcontractingPurchaseLine(PurchaseLine);

        UpdateItemWithBOMAndRoutingFromTemp(PurchaseLine);
        CreateReleasedProductionOrderFromTemp(ProductionOrder);
        TransferTemporaryDataToProductionOrder(ProductionOrder);
        RefreshProductionOrderWithOptimalSettings(ProductionOrder);
        FinalizeProductionOrderCreation(PurchaseLine, ProductionOrder);

        UnbindSubscription(SubcProdOrderCreateBind);
    end;

    /// <summary>
    /// Refreshes production order based on modification state
    /// </summary>
    local procedure RefreshProductionOrderWithOptimalSettings(var ProductionOrder: Record "Production Order")
    var
        Direction: Option Forward,Backward;
    begin
        if ProdOrderCompRoutingCreated then
            RefreshProductionOrderAfterUpdate(ProductionOrder, Direction::Backward, false, false, false)
        else
            RefreshProductionOrderAfterUpdate(ProductionOrder, Direction::Backward, true, true, false);
    end;

    /// <summary>
    /// Finalizes production order creation with all related operations
    /// </summary>
    local procedure FinalizeProductionOrderCreation(var PurchaseLine: Record "Purchase Line"; var ProductionOrder: Record "Production Order")
    begin
        TransferReservationEntryFromPurchOrderCompToProdOrderLine(PurchaseLine, ProductionOrder);
        UpdatePurchaseLineWithProdOrder(PurchaseLine, ProductionOrder);
        CleanupTemporaryBOMAndRoutingIfNotNeeded();
        HandleSubcontractingAfterUpdate(PurchaseLine);
    end;

    /// <summary>
    /// Creates released production order from temporary data
    /// </summary>
    local procedure CreateReleasedProductionOrderFromTemp(var ProductionOrder: Record "Production Order")
    var
        TempProductionOrder: Record "Production Order" temporary;
    begin
        SubcTempDataInitializer.GetGlobalProdOrder(TempProductionOrder);

        InitializeProductionOrder(ProductionOrder);

        ConfigureProductionOrderFromTemp(ProductionOrder, TempProductionOrder);

        ProductionOrder."Created from Purch. Order" := true;
        ProductionOrder.Modify(true);
    end;

    /// <summary>
    /// Initializes production order with basic settings
    /// </summary>
    local procedure InitializeProductionOrder(var ProductionOrder: Record "Production Order")
    begin
        Clear(ProductionOrder);
        ProductionOrder.Init();
        ProductionOrder.Validate(Status, "Production Order Status"::Released);
        ProductionOrder.Insert(true);

    end;

    /// <summary>
    /// Configures production order with data from temporary record
    /// </summary>
    local procedure ConfigureProductionOrderFromTemp(var ProductionOrder: Record "Production Order"; var TempProductionOrder: Record "Production Order" temporary)
    begin
        ProductionOrder."Source Type" := TempProductionOrder."Source Type";
        ProductionOrder.Validate("Source No.", TempProductionOrder."Source No.");

        if TempProductionOrder."Variant Code" <> '' then
            ProductionOrder.Validate("Variant Code", TempProductionOrder."Variant Code");

        ProductionOrder.Validate("Due Date", TempProductionOrder."Due Date");
        ProductionOrder.Validate(Quantity, TempProductionOrder.Quantity);
        ProductionOrder.Validate("Location Code", TempProductionOrder."Location Code");
    end;

    /// <summary>
    /// Transfers temporary data to production order
    /// </summary>
    local procedure TransferTemporaryDataToProductionOrder(ProductionOrder: Record "Production Order")
    var
        ProdOrderLine: Record "Prod. Order Line";
        TempProdOrderLine: Record "Prod. Order Line" temporary;
    begin
        SubcTempDataInitializer.GetGlobalProdOrderLine(TempProdOrderLine);
        if not TempProdOrderLine.FindFirst() then
            exit;

        CreateProdOrderLineFromTemp(ProdOrderLine, ProductionOrder, TempProdOrderLine);
        TransferComponentsAndRoutingLines(ProdOrderLine);
    end;

    /// <summary>
    /// Transfers components and routing lines
    /// </summary>
    local procedure TransferComponentsAndRoutingLines(var ProdOrderLine: Record "Prod. Order Line")
    begin
        if not CheckCreateProdOrderCompRtng() then
            exit;

        TransferProductionOrderComponents(ProdOrderLine);
        TransferProductionOrderRoutingLines(ProdOrderLine);

        ProdOrderCompRoutingCreated := true;
    end;

    /// <summary>
    /// Transfers production order components
    /// </summary>
    local procedure TransferProductionOrderComponents(var ProdOrderLine: Record "Prod. Order Line")
    var
        ProdOrderComponent: Record "Prod. Order Component";
        TempProdOrderComponent: Record "Prod. Order Component" temporary;
    begin
        SubcTempDataInitializer.GetGlobalProdOrderComponent(TempProdOrderComponent);
        if TempProdOrderComponent.FindSet() then
            repeat
                CreateProdOrderComponentFromTemp(ProdOrderComponent, TempProdOrderComponent, ProdOrderLine);
            until TempProdOrderComponent.Next() = 0;
    end;

    /// <summary>
    /// Transfers production order routing lines
    /// </summary>
    local procedure TransferProductionOrderRoutingLines(var ProdOrderLine: Record "Prod. Order Line")
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary;
    begin
        SubcTempDataInitializer.GetGlobalProdOrderRoutingLine(TempProdOrderRoutingLine);
        if TempProdOrderRoutingLine.FindSet() then
            repeat
                CreateProdOrderRoutingLineFromTemp(ProdOrderRoutingLine, TempProdOrderRoutingLine, ProdOrderLine);
            until TempProdOrderRoutingLine.Next() = 0;
    end;

    /// <summary>
    /// Updates purchase line with production order information
    /// </summary>
    local procedure UpdatePurchaseLineWithProdOrder(var PurchaseLine: Record "Purchase Line"; ProductionOrder: Record "Production Order")
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        InitializePurchaseLineFields(PurchaseLine, ProductionOrder);
        FindAndSetProdOrderLineNo(PurchaseLine, ProductionOrder, ProdOrderLine);
        UpdatePurchLineWithRoutingInfo(PurchaseLine, ProdOrderLine);
        PurchaseLine.Modify(true);
    end;

    /// <summary>
    /// Initializes basic purchase line fields
    /// </summary>
    local procedure InitializePurchaseLineFields(var PurchaseLine: Record "Purchase Line"; ProductionOrder: Record "Production Order")
    begin
        PurchaseLine."Prod. Order No." := ProductionOrder."No.";
        PurchaseLine."Qty. per Unit of Measure" := 0;
        PurchaseLine."Quantity (Base)" := 0;
        PurchaseLine."Qty. to Invoice (Base)" := 0;
        PurchaseLine."Qty. to Receive (Base)" := 0;
        PurchaseLine."Outstanding Qty. (Base)" := 0;
    end;

    /// <summary>
    /// Finds and sets production order line number
    /// </summary>
    local procedure FindAndSetProdOrderLineNo(var PurchaseLine: Record "Purchase Line"; ProductionOrder: Record "Production Order"; var ProdOrderLine: Record "Prod. Order Line")
    begin
        ProdOrderLine.SetLoadFields("Line No.");
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.SetRange("Item No.", PurchaseLine."No.");
        if ProdOrderLine.FindFirst() then
            PurchaseLine."Prod. Order Line No." := ProdOrderLine."Line No.";
    end;

    /// <summary>
    /// Updates purchase line with routing information
    /// </summary>
    local procedure UpdatePurchLineWithRoutingInfo(var PurchaseLine: Record "Purchase Line"; var ProdOrderLine: Record "Prod. Order Line")
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenter: Record "Work Center";
    begin
        if not FindRoutingLinesForProdOrderLine(ProdOrderRoutingLine, ProdOrderLine) then
            exit;

        if FindMatchingWorkCenterForVendor(ProdOrderRoutingLine, WorkCenter, PurchaseLine."Buy-from Vendor No.") or
           FindAnySubcontractorWorkCenter(ProdOrderRoutingLine, WorkCenter) then begin
            UpdatePurchLineFromRoutingLine(PurchaseLine, ProdOrderRoutingLine);
            exit;
        end;

        ProdOrderRoutingLine.FindFirst();
        UpdatePurchLineFromRoutingLine(PurchaseLine, ProdOrderRoutingLine);
    end;

    /// <summary>
    /// Finds routing lines for production order line
    /// </summary>
    local procedure FindRoutingLinesForProdOrderLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var ProdOrderLine: Record "Prod. Order Line"): Boolean
    begin
        ProdOrderRoutingLine.SetLoadFields("Work Center No.", "Operation No.", Description, "Routing No.", "Routing Reference No.");
        ProdOrderRoutingLine.SetRange(Status, ProdOrderLine.Status);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderRoutingLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
        ProdOrderRoutingLine.SetRange("Routing Reference No.", ProdOrderLine."Line No.");
        ProdOrderRoutingLine.SetRange(Type, "Capacity Type"::"Work Center");
        exit(not ProdOrderRoutingLine.IsEmpty());
    end;

    /// <summary>
    /// Finds work center matching specific vendor
    /// </summary>
    local procedure FindMatchingWorkCenterForVendor(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var WorkCenter: Record "Work Center"; VendorNo: Code[20]): Boolean
    begin
        if ProdOrderRoutingLine.FindSet() then
            repeat
                WorkCenter.SetLoadFields("Gen. Prod. Posting Group");
                WorkCenter.SetRange("No.", ProdOrderRoutingLine."Work Center No.");
                WorkCenter.SetRange("Subcontractor No.", VendorNo);
                if WorkCenter.FindFirst() then
                    exit(true);
            until ProdOrderRoutingLine.Next() = 0;
        exit(false);
    end;

    /// <summary>
    /// Finds any work center with subcontractor
    /// </summary>
    local procedure FindAnySubcontractorWorkCenter(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var WorkCenter: Record "Work Center"): Boolean
    begin
        ProdOrderRoutingLine.FindSet();
        repeat
            WorkCenter.SetLoadFields("Gen. Prod. Posting Group");
            WorkCenter.SetRange("No.", ProdOrderRoutingLine."Work Center No.");
            WorkCenter.SetFilter("Subcontractor No.", '<>%1', '');
            if WorkCenter.FindFirst() then
                exit(true);
        until ProdOrderRoutingLine.Next() = 0;
        exit(false);
    end;

    local procedure UpdatePurchLineFromRoutingLine(var PurchaseLine: Record "Purchase Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        SubcPriceManagement: Codeunit "Subc. Price Management";
    begin
        PurchaseLine.Description := ProdOrderRoutingLine.Description;
        PurchaseLine."Routing No." := ProdOrderRoutingLine."Routing No.";
        PurchaseLine."Routing Reference No." := ProdOrderRoutingLine."Routing Reference No.";
        PurchaseLine."Operation No." := ProdOrderRoutingLine."Operation No.";
        PurchaseLine."Expected Receipt Date" := ProdOrderRoutingLine."Ending Date";
        PurchaseLine.Validate("Work Center No.", ProdOrderRoutingLine."Work Center No.");

        SubcPriceManagement.GetSubcPriceForPurchLine(PurchaseLine);
        PurchaseLine.GetItemTranslation();
    end;

    /// <summary>
    /// Transfers reservation entries
    /// </summary>
    local procedure TransferReservationEntryFromPurchOrderCompToProdOrderLine(PurchaseLine: Record "Purchase Line"; ProductionOrder: Record "Production Order")
    var
        ProdOrderLine: Record "Prod. Order Line";
        TempReservationEntry: Record "Reservation Entry" temporary;
        PurchLineReserve: Codeunit "Purch. Line-Reserve";
    begin
        if not FindProdOrderLineForReservation(ProdOrderLine, ProductionOrder, PurchaseLine."No.") then
            exit;

        CollectReservationEntries(PurchaseLine, TempReservationEntry, PurchLineReserve);
        ReassignReservationEntries(ProdOrderLine, TempReservationEntry);
    end;

    /// <summary>
    /// Finds production order line for reservation transfer
    /// </summary>
    local procedure FindProdOrderLineForReservation(var ProdOrderLine: Record "Prod. Order Line"; ProductionOrder: Record "Production Order"; ItemNo: Code[20]): Boolean
    begin
        ProdOrderLine.SetLoadFields("Line No.");
        ProdOrderLine.SetRange(Status, "Production Order Status"::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.SetRange("Item No.", ItemNo);
        exit(ProdOrderLine.FindFirst());
    end;

    /// <summary>
    /// Collects reservation entries into temporary table
    /// </summary>
    local procedure CollectReservationEntries(PurchaseLine: Record "Purchase Line"; var TempReservationEntry: Record "Reservation Entry" temporary; var PurchLineReserve: Codeunit "Purch. Line-Reserve")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        PurchLineReserve.FindReservEntry(PurchaseLine, ReservationEntry);
        if ReservationEntry.FindSet() then begin
            repeat
                TempReservationEntry := ReservationEntry;
                TempReservationEntry.Insert();
            until ReservationEntry.Next() = 0;
            ReservationEntry.DeleteAll();
        end;
    end;

    /// <summary>
    /// Reassigns reservation entries to production order line
    /// </summary>
    local procedure ReassignReservationEntries(ProdOrderLine: Record "Prod. Order Line"; var TempReservationEntry: Record "Reservation Entry" temporary)
    begin
        if TempReservationEntry.FindSet() then
            repeat
                ReassignSingleReservationEntry(ProdOrderLine, TempReservationEntry);
            until TempReservationEntry.Next() = 0;
    end;

    local procedure ReassignSingleReservationEntry(ProdOrderLine: Record "Prod. Order Line"; var TempReservationEntry: Record "Reservation Entry" temporary)
    var
        ReservationEntry2: Record "Reservation Entry";
    begin
        ReservationEntry2 := TempReservationEntry;
        ReservationEntry2."Source Type" := Database::"Prod. Order Line";
        ReservationEntry2."Source Subtype" := ProdOrderLine.Status.AsInteger();
        ReservationEntry2."Source ID" := ProdOrderLine."Prod. Order No.";
        ReservationEntry2."Source Ref. No." := 0;
        ReservationEntry2."Source Batch Name" := '';
        ReservationEntry2."Source Prod. Order Line" := ProdOrderLine."Line No.";
        ReservationEntry2.Insert();
    end;

    local procedure HandleSubcontractingAfterUpdate(var PurchaseLine: Record "Purchase Line")
    var
        RequisitionLine: Record "Requisition Line";
        SubcPurchaseOrderCreator: Codeunit "Subc. Purchase Order Creator";
        SubcontractingManagementExt: Codeunit "Subcontracting Management Ext.";
        NextLineNo: Integer;
    begin
        RequisitionLine."Prod. Order No." := PurchaseLine."Prod. Order No.";
        RequisitionLine."Prod. Order Line No." := PurchaseLine."Prod. Order Line No.";
        RequisitionLine."Operation No." := PurchaseLine."Operation No.";
        RequisitionLine."Routing No." := PurchaseLine."Routing No.";
        RequisitionLine."Routing Reference No." := PurchaseLine."Routing Reference No.";

        NextLineNo := PurchaseLine."Line No." + 10000;
        BindSubscription(SubcontractingManagementExt);
        SubcPurchaseOrderCreator.TransferSubcontractingProdOrderComp(PurchaseLine, RequisitionLine, NextLineNo);
        UnbindSubscription(SubcontractingManagementExt);
    end;

    /// <summary>
    /// Validates mandatory fields
    /// </summary>
    local procedure ValidateMandatoryFields(PurchaseLine: Record "Purchase Line")
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        Vendor: Record Vendor;
    begin
        GetSubManagementSetupCached();
        SubcManagementSetup.TestField("Rtng. Link Code Purch. Prov.");
        SubcManagementSetup.TestField("Component at Location");
        SubcManagementSetup.TestField("Preset Component Item No.");
        SubcManagementSetup.TestField("Common Work Center No.");

        ManufacturingSetup.Get();
        ManufacturingSetup.TestField("Released Order Nos.");
        ManufacturingSetup.TestField("Planned Order Nos.");
        ManufacturingSetup.TestField("Production BOM Nos.");
        ManufacturingSetup.TestField("Routing Nos.");

        Vendor.Get(PurchaseLine."Buy-from Vendor No.");
        Vendor.TestField("Subcontr. Location Code");

        PurchaseLine.TestField(Type, "Purchase Line Type"::Item);
        PurchaseLine.TestField("Prod. Order No.", '');
        PurchaseLine.TestField("Prod. Order Line No.", 0);
        PurchaseLine.TestField(Quantity);
        PurchaseLine.TestField("Location Code");
        PurchaseLine.TestField("Expected Receipt Date");
        PurchaseLine.TestField("Qty. Assigned", 0);
        PurchaseLine.TestField("Qty. Rcd. Not Invoiced", 0);
        PurchaseLine.TestField("Drop Shipment", false);
        PurchaseLine.TestField("Special Order", false);

        PurchaseLine.TestStatusOpen();
    end;

    /// <summary>
    /// Gets Sub Management Setup with caching
    /// </summary>
    local procedure GetSubManagementSetupCached()
    begin
        if HasSubManagementSetup then
            exit;
        if SubcManagementSetup.Get() then
            HasSubManagementSetup := true;
    end;

    /// <summary>
    /// Updates item with BOM and routing from temporary data
    /// </summary>
    local procedure UpdateItemWithBOMAndRoutingFromTemp(var PurchaseLine: Record "Purchase Line")
    var
        SkipProcessBOMAndRouting: Boolean;
    begin
        SkipProcessBOMAndRouting := CheckCreateProdOrderCompRtng() and (GlobalSubcRtngBOMSourceType = "Subc. RtngBOMSourceType"::Empty);
        if SkipProcessBOMAndRouting then
            exit;

        ProcessBOMAndRoutingData(PurchaseLine."No.");
    end;

    /// <summary>
    /// Processes BOM and routing data
    /// </summary>
    local procedure ProcessBOMAndRoutingData(ItemNo: Code[20])
    var
        TempProductionBOMHeader: Record "Production BOM Header" temporary;
        TempProductionBOMLine: Record "Production BOM Line" temporary;
        TempRoutingHeader: Record "Routing Header" temporary;
        TempRoutingLine: Record "Routing Line" temporary;
        BOMNo, BOMVersionCode, RoutingNo, RoutingVersionCode : Code[20];
    begin
        GetTemporaryBOMAndRoutingData(TempProductionBOMHeader, TempProductionBOMLine, TempRoutingHeader, TempRoutingLine);
        GetBOMAndRoutingInfoFromTempData(BOMNo, BOMVersionCode, RoutingNo, RoutingVersionCode);

        if BOMVersionCode = '' then
            CreateBOMIfNotExists(TempProductionBOMHeader, TempProductionBOMLine, BOMNo)
        else
            SaveBOMVersionIfRequired(TempProductionBOMHeader, TempProductionBOMLine, BOMNo, BOMVersionCode);

        if RoutingVersionCode = '' then
            CreateRoutingIfNotExists(TempRoutingHeader, TempRoutingLine, RoutingNo)
        else
            SaveRoutingVersionIfRequired(TempRoutingHeader, TempRoutingLine, RoutingNo, RoutingVersionCode);

        UpdateSourceWithBOMRoutingNumbers(ItemNo, BOMNo, RoutingNo);
    end;

    /// <summary>
    /// Gets temporary BOM and routing data
    /// </summary>
    local procedure GetTemporaryBOMAndRoutingData(var TempProductionBOMHeader: Record "Production BOM Header" temporary; var TempProductionBOMLine: Record "Production BOM Line" temporary; var TempRoutingHeader: Record "Routing Header" temporary; var TempRoutingLine: Record "Routing Line" temporary)
    begin
        SubcTempDataInitializer.GetGlobalBOMHeader(TempProductionBOMHeader);
        SubcTempDataInitializer.GetGlobalBOMLines(TempProductionBOMLine);
        SubcTempDataInitializer.GetGlobalRoutingHeader(TempRoutingHeader);
        SubcTempDataInitializer.GetGlobalRoutingLines(TempRoutingLine);
    end;

    /// <summary>
    /// Saves BOM version if required
    /// </summary>
    local procedure SaveBOMVersionIfRequired(var TempProductionBOMHeader: Record "Production BOM Header" temporary; var TempProductionBOMLine: Record "Production BOM Line" temporary; BomNo: Code[20]; BOMVersionCode: Code[20])
    var
        ProductionBOMLine: Record "Production BOM Line";
        ProductionBOMVersion: Record "Production BOM Version";
        NoSeries: Codeunit "No. Series";
        NewBOMVersionCode: Code[20];
    begin
        if BOMVersionCode = '' then
            exit;

        if SubcVersionMgmt.CheckBOMExists(BomNo, BOMVersionCode) then
            exit;

        NewBOMVersionCode := NoSeries.GetNextNo(SubcVersionMgmt.GetBOMVersionNoSeries(BomNo));
        SubcTempDataInitializer.UpdateBOMVersionCode(NewBOMVersionCode);

        ProductionBOMVersion.Init();
        ProductionBOMVersion."Production BOM No." := BomNo;
        ProductionBOMVersion."Version Code" := NewBOMVersionCode;
        ProductionBOMVersion.Status := "BOM Status"::Certified;
        ProductionBOMVersion.Description := TempProductionBOMHeader.Description;
        ProductionBOMVersion."Unit of Measure Code" := TempProductionBOMHeader."Unit of Measure Code";
        ProductionBOMVersion."Starting Date" := WorkDate();
        ProductionBOMVersion.Status := TempProductionBOMHeader.Status;
        ProductionBOMVersion.Insert(true);
        BOMVersionCreated := true;

        if TempProductionBOMLine.FindSet() then
            repeat
                ProductionBOMLine := TempProductionBOMLine;
                ProductionBOMLine.Insert(true);
            until TempProductionBOMLine.Next() = 0;
        ProductionBOMVersion.Validate(Status, "BOM Status"::Certified);
        ProductionBOMVersion.Modify(true);

    end;

    /// <summary>
    /// Saves routing version if required
    /// </summary>
    local procedure SaveRoutingVersionIfRequired(var TempRoutingHeader: Record "Routing Header" temporary; var TempRoutingLine: Record "Routing Line" temporary; RoutingNo: Code[20]; RoutingVersionCode: Code[20])
    var
        RoutingLine: Record "Routing Line";
        RoutingVersion: Record "Routing Version";
        NoSeries: Codeunit "No. Series";
        NewRoutingVersionCode: Code[20];
    begin
        if SubcVersionMgmt.CheckRoutingExists(RoutingNo, RoutingVersionCode) then
            exit;

        NewRoutingVersionCode := NoSeries.GetNextNo(SubcVersionMgmt.GetRoutingVersionNoSeries(RoutingNo));
        SubcTempDataInitializer.UpdateRoutingVersionCode(NewRoutingVersionCode);

        RoutingVersion.Init();
        RoutingVersion."Routing No." := RoutingNo;
        RoutingVersion."Version Code" := NewRoutingVersionCode;
        RoutingVersion.Description := TempRoutingHeader.Description;
        RoutingVersion."Starting Date" := WorkDate();
        RoutingVersion.Status := TempRoutingHeader.Status;
        RoutingVersion.Insert(true);
        RoutingVersionCreated := true;

        if TempRoutingLine.FindSet() then
            repeat
                RoutingLine := TempRoutingLine;
                RoutingLine.Insert(true);
            until TempRoutingLine.Next() = 0;
        RoutingVersion.Validate(Status, "Routing Status"::Certified);
        RoutingVersion.Modify(true);
    end;

    /// <summary>
    /// Creates BOM if it doesn't exist
    /// </summary>
    local procedure CreateBOMIfNotExists(var TempProductionBOMHeader: Record "Production BOM Header" temporary; var TempProductionBOMLine: Record "Production BOM Line" temporary; var BOMNo: Code[20])
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        NoSeries: Codeunit "No. Series";
    begin
        if SubcVersionMgmt.CheckBOMExists(BOMNo, '') then
            exit;

        ManufacturingSetup.Get();
        BOMNo := NoSeries.GetNextNo(ManufacturingSetup."Production BOM Nos.");

        ProductionBOMHeader.Init();
        ProductionBOMHeader."No." := BOMNo;
        ProductionBOMHeader.Description := TempProductionBOMHeader.Description;
        ProductionBOMHeader.Validate("Unit of Measure Code", TempProductionBOMHeader."Unit of Measure Code");
        ProductionBOMHeader.Insert(true);
        BOMCreated := true;

        if TempProductionBOMLine.FindSet() then
            repeat
                ProductionBOMLine := TempProductionBOMLine;
                ProductionBOMLine."Production BOM No." := BOMNo;
                ProductionBOMLine."Version Code" := '';
                ProductionBOMLine.Insert(true);
            until TempProductionBOMLine.Next() = 0;
        ProductionBOMHeader.Status := "BOM Status"::Certified;
        ProductionBOMHeader.Modify(true);
        SubcTempDataInitializer.LoadBOMLines(BOMNo, '');
    end;

    /// <summary>
    /// Checks if BOM and routing exist and if the production components or routing have to be created out of the temporary data.
    /// </summary>
    /// <returns></returns>
    local procedure CheckCreateProdOrderCompRtng(): Boolean
    var
        TempProductionBOMLine: Record "Production BOM Line" temporary;
        TempRoutingLine: Record "Routing Line" temporary;
        BOMRoutingExists: Boolean;
    begin
        SubcTempDataInitializer.GetGlobalBOMLines(TempProductionBOMLine);
        SubcTempDataInitializer.GetGlobalRoutingLines(TempRoutingLine);

        BOMRoutingExists := SubcVersionMgmt.CheckBOMExists(TempProductionBOMLine."Production BOM No.", '') and SubcVersionMgmt.CheckRoutingExists(TempRoutingLine."Routing No.", '');
        exit(not BOMRoutingExists or ProdCompRoutingModified);
    end;
    /// <summary>
    /// Creates routing if it doesn't exist
    /// </summary>
    local procedure CreateRoutingIfNotExists(var TempRoutingHeader: Record "Routing Header" temporary; var TempRoutingLine: Record "Routing Line" temporary; var RoutingNo: Code[20])
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        NoSeries: Codeunit "No. Series";
    begin
        if not TempRoutingHeader.FindFirst() then
            exit;

        if SubcVersionMgmt.CheckRoutingExists(RoutingNo, '') then
            exit;

        ManufacturingSetup.Get();
        RoutingNo := NoSeries.GetNextNo(ManufacturingSetup."Routing Nos.");

        RoutingHeader.Init();
        RoutingHeader."No." := RoutingNo;
        RoutingHeader.Description := TempRoutingHeader.Description;
        RoutingHeader.Insert(true);
        RoutingCreated := true;

        if TempRoutingLine.FindSet() then
            repeat
                RoutingLine := TempRoutingLine;
                RoutingLine."Routing No." := RoutingNo;
                RoutingLine."Version Code" := '';
                RoutingLine.Insert(true);
            until TempRoutingLine.Next() = 0;

        RoutingHeader.Validate(Status, "Routing Status"::Certified);
        RoutingHeader.Modify(true);
        SubcTempDataInitializer.LoadRoutingLines(RoutingNo, '');
    end;

    /// <summary>
    /// Updates item or stockkeeping unit with BOM and routing numbers based on SubcRtngBOMSourceType
    /// </summary>
    local procedure UpdateSourceWithBOMRoutingNumbers(ItemNo: Code[20]; BOMNo: Code[20]; RoutingNo: Code[20])
    var
        Item: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
        LocationCode: Code[10];
        VariantCode: Code[10];
    begin
        case GlobalSubcRtngBOMSourceType of
            GlobalSubcRtngBOMSourceType::Item:

                if Item.Get(ItemNo) and ((Item."Production BOM No." <> BOMNo) or (Item."Routing No." <> RoutingNo)) then begin
                    Item."Production BOM No." := BOMNo;
                    Item."Routing No." := RoutingNo;
                    Item.Modify(true);
                end;
            GlobalSubcRtngBOMSourceType::StockkeepingUnit:
                begin
                    GetLocationAndVariantForStockkeepingUnit(LocationCode, VariantCode);
                    if StockkeepingUnit.Get(LocationCode, ItemNo, VariantCode) then begin
                        if (StockkeepingUnit."Production BOM No." <> BOMNo) or (StockkeepingUnit."Routing No." <> RoutingNo) then begin
                            StockkeepingUnit."Production BOM No." := BOMNo;
                            StockkeepingUnit."Routing No." := RoutingNo;
                            StockkeepingUnit.Modify(true);
                        end;
                    end else
                        CreateStockkeepingUnitWithBOMRouting(LocationCode, ItemNo, VariantCode, BOMNo, RoutingNo);
                end;
        end;
    end;

    /// <summary>
    /// Gets location and variant codes for stockkeeping unit operations
    /// </summary>
    local procedure GetLocationAndVariantForStockkeepingUnit(var LocationCode: Code[10]; var VariantCode: Code[10])
    var
        TempPurchaseLine: Record "Purchase Line" temporary;
    begin
        SubcTempDataInitializer.GetGlobalPurchLine(TempPurchaseLine);
        if TempPurchaseLine.FindFirst() then begin
            LocationCode := TempPurchaseLine."Location Code";
            VariantCode := TempPurchaseLine."Variant Code";
        end;
    end;

    /// <summary>
    /// Creates a new stockkeeping unit with BOM and routing information
    /// </summary>
    local procedure CreateStockkeepingUnitWithBOMRouting(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; BOMNo: Code[20]; RoutingNo: Code[20])
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        StockkeepingUnit.Init();
        StockkeepingUnit."Location Code" := LocationCode;
        StockkeepingUnit."Item No." := ItemNo;
        StockkeepingUnit."Variant Code" := VariantCode;
        StockkeepingUnit."Production BOM No." := BOMNo;
        StockkeepingUnit."Routing No." := RoutingNo;
        StockkeepingUnit.Insert(true);

    end;

    /// <summary>
    /// Cleans up temporary BOM and routing if not needed
    /// </summary>
    local procedure CleanupTemporaryBOMAndRoutingIfNotNeeded()
    var
        BOMNo, BOMVersionCode, RoutingNo, RoutingVersionCode : Code[20];
    begin
        GetSubManagementSetupCached();
        GetBOMAndRoutingInfoFromTempData(BOMNo, BOMVersionCode, RoutingNo, RoutingVersionCode);

        if (GlobalSubcRtngBOMSourceType = GlobalSubcRtngBOMSourceType::Empty) then begin
            DeleteCreatedBOMIfExists(BOMNo);
            DeleteCreatedRoutingIfExists(RoutingNo);

            if not SubcManagementSetup."Always Save Modified Versions" then begin
                DeleteCreatedBOMVersionIfExists(BOMNo, BOMVersionCode);
                DeleteCreatedRoutingVersionIfExists(RoutingNo, RoutingVersionCode);
            end;
        end;
    end;

    local procedure DeleteCreatedBOMIfExists(BOMNo: Code[20])
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        if not BOMCreated then
            exit;

        if BOMNo = '' then
            exit;

        if ProductionBOMHeader.Get(BOMNo) then begin
            ProductionBOMHeader.Validate(Status, "BOM Status"::"Under Development");
            ProductionBOMHeader.Modify(true);
            ProductionBOMHeader.Delete(true);
        end;
    end;

    local procedure DeleteCreatedRoutingIfExists(RoutingNo: Code[20])
    var
        RoutingHeader: Record "Routing Header";
    begin
        if not RoutingCreated then
            exit;

        if RoutingNo = '' then
            exit;

        if RoutingHeader.Get(RoutingNo) then begin
            RoutingHeader.Validate(Status, "Routing Status"::"Under Development");
            RoutingHeader.Modify(true);
            RoutingHeader.Delete(true);
        end;
    end;

    local procedure DeleteCreatedBOMVersionIfExists(BOMNo: Code[20]; BOMVersionCode: Code[20])
    var
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        if not BOMVersionCreated then
            exit;

        if (BOMNo = '') or (BOMVersionCode = '') then
            exit;

        if ProductionBOMVersion.Get(BOMNo, BOMVersionCode) then begin
            ProductionBOMVersion.Validate(Status, "BOM Status"::"Under Development");
            ProductionBOMVersion.Modify();
            ProductionBOMVersion.Delete(true);
        end;
    end;

    local procedure DeleteCreatedRoutingVersionIfExists(RoutingNo: Code[20]; RoutingVersionCode: Code[20])
    var
        RoutingVersion: Record "Routing Version";
    begin
        if not RoutingVersionCreated then
            exit;

        if (RoutingNo = '') or (RoutingVersionCode = '') then
            exit;

        if RoutingVersion.Get(RoutingNo, RoutingVersionCode) then begin
            RoutingVersion.Validate(Status, "Routing Status"::"Under Development");
            RoutingVersion.Modify(true);
            RoutingVersion.Delete(true);
        end;
    end;

    /// <summary>
    /// Refreshes production order after update
    /// </summary>
    local procedure RefreshProductionOrderAfterUpdate(var ProductionOrder: Record "Production Order"; NewDirection: Option; CalcRoutings: Boolean; CalcComponents: Boolean; DeleteRelations: Boolean)
    var
        ProdOrderLine: Record "Prod. Order Line";
        CalculateProdOrder: Codeunit "Calculate Prod. Order";
    begin
        ProdOrderLine.SetLoadFields("Prod. Order No.", Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        if not ProdOrderLine.FindFirst() then
            exit;
        CalculateProdOrder.Calculate(ProdOrderLine, NewDirection, CalcRoutings, CalcComponents, DeleteRelations, true);
    end;

    /// <summary>
    /// Creates production order line from temporary data
    /// </summary>
    local procedure CreateProdOrderLineFromTemp(var ProdOrderLine: Record "Prod. Order Line"; ProductionOrder: Record "Production Order"; TempProdOrderLine: Record "Prod. Order Line" temporary)
    var
        Item: Record Item;
        CalculateProdOrder: Codeunit "Calculate Prod. Order";
        BOMNo, BOMVersionCode, RoutingNo, RoutingVersionCode : Code[20];
    begin
        GetBOMAndRoutingInfoFromTempData(BOMNo, BOMVersionCode, RoutingNo, RoutingVersionCode);

        ProdOrderLine.Init();
        ProdOrderLine.SetIgnoreErrors();
        ProdOrderLine.Status := ProductionOrder.Status;
        ProdOrderLine."Prod. Order No." := ProductionOrder."No.";
        ProdOrderLine."Line No." := TempProdOrderLine."Line No.";
        ProdOrderLine."Routing Reference No." := ProdOrderLine."Line No.";

        ProdOrderLine.Validate("Item No.", ProductionOrder."Source No.");
        ProdOrderLine."Location Code" := ProductionOrder."Location Code";
        ProdOrderLine.Validate("Variant Code", ProductionOrder."Variant Code");

        if not CheckCreateProdOrderCompRtng() then begin
            if BOMNo <> '' then begin
                ProdOrderLine.Validate("Production BOM No.", BOMNo);
                ProdOrderLine.Validate("Production BOM Version Code", BOMVersionCode);
            end;

            if RoutingNo <> '' then begin
                ProdOrderLine.Validate("Routing No.", RoutingNo);
                ProdOrderLine.Validate("Routing Version Code", RoutingVersionCode);
            end;
        end else
            ProdOrderLine."Routing No." := TempProdOrderLine."Routing No.";

        if ProductionOrder."Bin Code" <> '' then
            ProdOrderLine.Validate("Bin Code", ProductionOrder."Bin Code")
        else
            CalculateProdOrder.SetProdOrderLineBinCodeFromRoute(ProdOrderLine, ProdOrderLine."Location Code", ProdOrderLine."Routing No.");

        Item.SetLoadFields("Scrap %", "Inventory Posting Group");
        Item.Get(ProductionOrder."Source No.");
        ProdOrderLine."Scrap %" := Item."Scrap %";

        ProdOrderLine."Due Date" := ProductionOrder."Due Date";
        ProdOrderLine."Starting Date-Time" := ProductionOrder."Starting Date-Time";
        ProdOrderLine."Ending Date-Time" := ProductionOrder."Ending Date-Time";
        ProdOrderLine."Planning Level Code" := 0;
        ProdOrderLine."Inventory Posting Group" := Item."Inventory Posting Group";
        ProdOrderLine.UpdateDatetime();
        ProdOrderLine.Validate("Unit Cost");

        ProdOrderLine.Description := ProductionOrder.Description;
        ProdOrderLine."Description 2" := ProductionOrder."Description 2";
        ProdOrderLine.Validate(Quantity, ProductionOrder.Quantity);
        ProdOrderLine.UpdateDatetime();
        ProdOrderLine.Insert();
    end;

    /// <summary>
    /// Gets BOM and routing information from temporary data
    /// </summary>
    local procedure GetBOMAndRoutingInfoFromTempData(var BOMNo: Code[20]; var BOMVersionCode: Code[20]; var RoutingNo: Code[20]; var RoutingVersionCode: Code[20])
    var
        TempProductionBOMLine: Record "Production BOM Line" temporary;
        TempRoutingLine: Record "Routing Line" temporary;
    begin
        SubcTempDataInitializer.GetGlobalRoutingLines(TempRoutingLine);
        SubcTempDataInitializer.GetGlobalBOMLines(TempProductionBOMLine);

        if TempRoutingLine.FindFirst() then begin
            RoutingNo := TempRoutingLine."Routing No.";
            RoutingVersionCode := TempRoutingLine."Version Code";
        end;

        if TempProductionBOMLine.FindFirst() then begin
            BOMNo := TempProductionBOMLine."Production BOM No.";
            BOMVersionCode := TempProductionBOMLine."Version Code";
        end;
    end;

    /// <summary>
    /// Creates production order component from temporary data
    /// </summary>
    local procedure CreateProdOrderComponentFromTemp(var ProdOrderComponent: Record "Prod. Order Component"; TempProdOrderComponent: Record "Prod. Order Component" temporary; var ProdOrderLine: Record "Prod. Order Line")
    begin
        GetSubManagementSetupCached();

        ProdOrderComponent.Init();
        ProdOrderComponent.Validate(Status, ProdOrderLine.Status);
        ProdOrderComponent.Validate("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderComponent.Validate("Prod. Order Line No.", ProdOrderLine."Line No.");
        ProdOrderComponent.Validate("Line No.", TempProdOrderComponent."Line No.");
        ProdOrderComponent.Insert(true);

        ProdOrderComponent.Validate("Item No.", TempProdOrderComponent."Item No.");
        ProdOrderComponent.Validate("Variant Code", TempProdOrderComponent."Variant Code");
        ProdOrderComponent.Description := TempProdOrderComponent.Description;
        ProdOrderComponent.Validate("Quantity per", TempProdOrderComponent."Quantity per");
        ProdOrderComponent.Validate("Unit of Measure Code", TempProdOrderComponent."Unit of Measure Code");
        ProdOrderComponent.Validate("Location Code", TempProdOrderComponent."Location Code");
        if ProdOrderComponent."Bin Code" <> '' then
            ProdOrderComponent.Validate("Bin Code", TempProdOrderComponent."Bin Code");
        ProdOrderComponent."Routing Link Code" := TempProdOrderComponent."Routing Link Code";
        ProdOrderComponent."Flushing Method" := TempProdOrderComponent."Flushing Method";
        ProdOrderComponent."Subcontracting Type" := TempProdOrderComponent."Subcontracting Type";
        ProdOrderComponent."Orig. Location Code" := TempProdOrderComponent."Orig. Location Code";
        ProdOrderComponent."Orig. Bin Code" := TempProdOrderComponent."Orig. Bin Code";
        ProdOrderComponent."Subcontracting Type" := TempProdOrderComponent."Subcontracting Type";
        ProdOrderComponent.Modify(true);
    end;

    /// <summary>
    /// Creates production order routing line from temporary data
    /// </summary>
    local procedure CreateProdOrderRoutingLineFromTemp(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary; var ProdOrderLine: Record "Prod. Order Line")
    begin
        ProdOrderRoutingLine.Init();
        ProdOrderRoutingLine.Validate(Status, ProdOrderLine.Status);
        ProdOrderRoutingLine.Validate("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderRoutingLine.Validate("Routing Reference No.", ProdOrderLine."Line No.");
        ProdOrderRoutingLine."Routing No." := ProdOrderLine."Routing No.";
        ProdOrderRoutingLine.Validate("Operation No.", TempProdOrderRoutingLine."Operation No.");
        ProdOrderRoutingLine.Insert(true);

        ProdOrderRoutingLine."Vendor No. Subc. Price" := TempProdOrderRoutingLine."Vendor No. Subc. Price";
        ProdOrderRoutingLine.Validate(Type, TempProdOrderRoutingLine.Type);
        ProdOrderRoutingLine.Validate("No.", TempProdOrderRoutingLine."No.");
        ProdOrderRoutingLine.Description := TempProdOrderRoutingLine.Description;
        ProdOrderRoutingLine."Setup Time" := TempProdOrderRoutingLine."Setup Time";
        ProdOrderRoutingLine."Run Time" := TempProdOrderRoutingLine."Run Time";
        ProdOrderRoutingLine."Wait Time" := TempProdOrderRoutingLine."Wait Time";
        ProdOrderRoutingLine."Move Time" := TempProdOrderRoutingLine."Move Time";
        ProdOrderRoutingLine."Ending Date" := TempProdOrderRoutingLine."Ending Date";
        ProdOrderRoutingLine."Ending Time" := TempProdOrderRoutingLine."Ending Time";
        ProdOrderRoutingLine.UpdateDatetime();
        ProdOrderRoutingLine."Routing Link Code" := TempProdOrderRoutingLine."Routing Link Code";
        ProdOrderRoutingLine.Modify(true);
    end;
}