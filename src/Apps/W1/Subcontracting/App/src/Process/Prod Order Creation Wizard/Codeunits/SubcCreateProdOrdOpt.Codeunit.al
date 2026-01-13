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
        SubManagementSetup: Record "Subc. Management Setup";
        TempDataInitializer: Codeunit "Subc. Temp Data Initializer";
        SubVersionSelectionMgmt: Codeunit "Subc. Version Mgmt.";
        BOMCreated, BOMVersionCreated : Boolean;
        HasSubManagementSetup: Boolean;
        ProdCompRoutingModified: Boolean;
        ProdOrderCompRoutingCreated: Boolean;
        RoutingCreated, RoutingVersionCreated : Boolean;
        ApplyBomRtngToSource: Enum "Subc. RtngBOMSourceType";

    trigger OnRun()
    begin
        CreateProductionOrderWithTemporaryData(Rec);
    end;

    /// <summary>
    /// Main orchestration method for creating production orders with temporary data handling
    /// </summary>
    local procedure CreateProductionOrderWithTemporaryData(var PurchLine: Record "Purchase Line")
    var
        Item: Record Item;
        ScenarioType: Enum "Subc. Scenario Type";
    begin
        ValidateAndPrepareCreation(PurchLine, Item);
        ScenarioType := DetermineScenarioAndPrepareData(Item, PurchLine);

        if not ExecuteBOMRoutingWizardProcess(Item, ScenarioType) then
            Error('');

        TransferTemporaryDataToRealTables(PurchLine);
    end;

    /// <summary>
    /// Determines the scenario type based on existing BOM and Routing data from best source
    /// </summary>
    local procedure DetermineScenarioAndPrepareData(Item: Record Item; PurchLine: Record "Purchase Line") ScenarioType: Enum "Subc. Scenario Type"
    var
        BOMNo, RoutingNo : Code[20];
        SourceType: Enum "Subc. RtngBOMSourceType";
    begin
        TempDataInitializer.InitializeTemporaryProdOrder(PurchLine);

        GetBOMAndRoutingFromBestSource(Item, BOMNo, RoutingNo, SourceType);

        TempDataInitializer.SetRtngBOMSourceType(SourceType);

        ScenarioType := GetScenarioTypeFromBOMRouting(BOMNo, RoutingNo);

        PrepareBOMAndRoutingDataForScenario(BOMNo, RoutingNo);

        exit(ScenarioType);
    end;

    /// <summary>
    /// Gets BOM and routing from best source (Stockkeeping Unit or Item)
    /// </summary>
    local procedure GetBOMAndRoutingFromBestSource(var Item: Record Item; var BOMNo: Code[20]; var RoutingNo: Code[20]; var SourceType: Enum "Subc. RtngBOMSourceType")
    var
        LocationCode, VariantCode : Code[10];
    begin
        Clear(BOMNo);
        Clear(RoutingNo);
        SourceType := SourceType::Empty;

        GetLocationAndVariantForStockkeepingUnit(LocationCode, VariantCode);

        if GetBOMAndRoutingFromStockkeepingUnit(Item."No.", VariantCode, LocationCode, BOMNo, RoutingNo) then begin
            SourceType := SourceType::StockkeepingUnit;
            exit;
        end;

        BOMNo := Item."Production BOM No.";
        RoutingNo := Item."Routing No.";

        if (BOMNo <> '') or (RoutingNo <> '') then
            SourceType := SourceType::Item;
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
        ScenarioType: Enum "Subc. Scenario Type";
    begin
        if (BOMNo <> '') and (RoutingNo <> '') then
            exit(ScenarioType::BothAvailable);

        if (BOMNo <> '') or (RoutingNo <> '') then
            exit(ScenarioType::PartiallyAvailable);

        exit(ScenarioType::NothingAvailable);
    end;

    /// <summary>
    /// Validates purchase line and prepares item data
    /// </summary>
    local procedure ValidateAndPrepareCreation(var PurchLine: Record "Purchase Line"; var Item: Record Item)
    begin
        ValidateMandatoryFields(PurchLine);
        Item.SetLoadFields("Production BOM No.", "Routing No.", "Scrap %", "Inventory Posting Group");
        Item.Get(PurchLine."No.");
    end;

    /// <summary>
    /// Prepares BOM and Routing data based on scenario requirements
    /// </summary>
    local procedure PrepareBOMAndRoutingDataForScenario(BOMNo: Code[20]; RoutingNo: Code[20])
    var
        BOMVersionCode, RoutingVersionCode : Code[20];
    begin
        TempDataInitializer.InitializeNewTemporaryBOMInformation();
        if BOMNo <> '' then begin
            BOMVersionCode := SubVersionSelectionMgmt.GetDefaultBOMVersion(BOMNo);
            TempDataInitializer.LoadBOMLines(BOMNo, BOMVersionCode);
        end;

        TempDataInitializer.InitializeNewTemporaryRoutingInformation();
        if RoutingNo <> '' then begin
            RoutingVersionCode := SubVersionSelectionMgmt.GetDefaultRoutingVersion(RoutingNo);
            TempDataInitializer.LoadRoutingLines(RoutingNo, RoutingVersionCode);
        end;
    end;

    /// <summary>
    /// Executes the BOM/Routing wizard process with user interaction
    /// </summary>
    local procedure ExecuteBOMRoutingWizardProcess(Item: Record Item; ScenarioType: Enum "Subc. Scenario Type"): Boolean
    begin
        exit(RunBOMRoutingWizardWithUserInteraction(Item, ScenarioType));
    end;

    /// <summary>
    /// Handles the wizard interaction with show/edit type determination
    /// </summary>
    local procedure RunBOMRoutingWizardWithUserInteraction(Item: Record Item; ScenarioType: Enum "Subc. Scenario Type"): Boolean
    var
        SubTempProdOrdBind: Codeunit "Subc. TempProdOrdBind";
        BOMRoutingShowEditType: Enum "Subc. Show/Edit Type";
        ProdCompRoutingShowEditType: Enum "Subc. Show/Edit Type";
    begin
        BindSubscription(SubTempProdOrdBind);
        GetShowEditTypesForScenario(ScenarioType, BOMRoutingShowEditType, ProdCompRoutingShowEditType);

        if ShouldSkipUserInteraction(BOMRoutingShowEditType, ProdCompRoutingShowEditType) then begin
            TempDataInitializer.BuildTemporaryStructureFromBOMRouting();
            exit(true);
        end;

        exit(ExecuteWizardPageWithTemporaryData(Item, BOMRoutingShowEditType, ProdCompRoutingShowEditType));
    end;

    /// <summary>
    /// Gets show/edit types for both BOM/Routing and Production Components/Routing in one call
    /// </summary>
    local procedure GetShowEditTypesForScenario(ScenarioType: Enum "Subc. Scenario Type"; var BOMRoutingShowEditType: Enum "Subc. Show/Edit Type"; var ProdCompRoutingShowEditType: Enum "Subc. Show/Edit Type")
    begin
        GetSubManagementSetupCached();

        case ScenarioType of
            ScenarioType::BothAvailable:
                begin
                    BOMRoutingShowEditType := SubManagementSetup.ShowRtngBOMSelect_Both;
                    ProdCompRoutingShowEditType := SubManagementSetup.ShowProdRtngCompSelect_Both;
                end;
            ScenarioType::PartiallyAvailable:
                begin
                    BOMRoutingShowEditType := SubManagementSetup.ShowRtngBOMSelect_Partial;
                    ProdCompRoutingShowEditType := SubManagementSetup.ShowProdRtngCompSelect_Partial;
                end;
            ScenarioType::NothingAvailable:
                begin
                    BOMRoutingShowEditType := SubManagementSetup.ShowRtngBOMSelect_Nothing;
                    ProdCompRoutingShowEditType := SubManagementSetup.ShowProdRtngCompSelect_Nothing;
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
        PurchProvisionWizard: Page "Subc. PurchProvisionWizard";
    begin
        SetupWizardPageWithTemporaryData(PurchProvisionWizard, Item, BOMRoutingShowEditType, ProdCompRoutingShowEditType);
        PurchProvisionWizard.RunModal();

        if PurchProvisionWizard.GetFinished() then begin
            UpdateWizardResults(PurchProvisionWizard);
            exit(true);
        end;

        exit(false);
    end;

    /// <summary>
    /// Updates internal flags based on wizard results
    /// </summary>
    local procedure UpdateWizardResults(var PurchProvisionWizard: Page "Subc. PurchProvisionWizard")
    begin
        ProdCompRoutingModified := PurchProvisionWizard.GetApplyChangesComponents() or PurchProvisionWizard.GetApplyChangesProdRouting();
        ApplyBomRtngToSource := PurchProvisionWizard.GetApplyBomRtngToSource();
    end;

    /// <summary>
    /// Configures the wizard page with temporary data
    /// </summary>
    local procedure SetupWizardPageWithTemporaryData(var PurchProvisionWizard: Page "Subc. PurchProvisionWizard"; Item: Record Item; BOMRoutingShowEditType: Enum "Subc. Show/Edit Type"; ProdCompRoutingShowEditType: Enum "Subc. Show/Edit Type")
    begin
        PurchProvisionWizard.SetItem(Item);
        PurchProvisionWizard.SetBOMRoutingShowEditType(BOMRoutingShowEditType);
        PurchProvisionWizard.SetProdCompRoutingShowEditType(ProdCompRoutingShowEditType);
        PurchProvisionWizard.SetTempDataInitializer(TempDataInitializer);
    end;

    /// <summary>
    /// Main method for transferring temporary data to real tables with transaction safety
    /// </summary>
    [CommitBehavior(CommitBehavior::Ignore)]
    local procedure TransferTemporaryDataToRealTables(var PurchLine: Record "Purchase Line")
    var
        ProdOrder: Record "Production Order";
        SubProdOrderCreateBind: Codeunit "Subc. ProdOrderCreateBind";
    begin
        BindSubscription(SubProdOrderCreateBind);
        SubProdOrderCreateBind.SetSubcontractingPurchaseLine(PurchLine);

        UpdateItemWithBOMAndRoutingFromTemp(PurchLine);
        CreateReleasedProductionOrderFromTemp(ProdOrder);
        TransferTemporaryDataToProductionOrder(ProdOrder);
        RefreshProductionOrderWithOptimalSettings(ProdOrder);
        FinalizeProductionOrderCreation(PurchLine, ProdOrder);

        UnbindSubscription(SubProdOrderCreateBind);
    end;

    /// <summary>
    /// Refreshes production order based on modification state
    /// </summary>
    local procedure RefreshProductionOrderWithOptimalSettings(var ProdOrder: Record "Production Order")
    var
        Direction: Option Forward,Backward;
    begin
        if ProdOrderCompRoutingCreated then
            RefreshProductionOrderAfterUpdate(ProdOrder, Direction::Backward, false, false, false)
        else
            RefreshProductionOrderAfterUpdate(ProdOrder, Direction::Backward, true, true, false);
    end;

    /// <summary>
    /// Finalizes production order creation with all related operations
    /// </summary>
    local procedure FinalizeProductionOrderCreation(var PurchLine: Record "Purchase Line"; var ProdOrder: Record "Production Order")
    begin
        TransferReservationEntryFromPurchOrderCompToProdOrderLine(PurchLine, ProdOrder);
        UpdatePurchaseLineWithProdOrder(PurchLine, ProdOrder);
        CleanupTemporaryBOMAndRoutingIfNotNeeded();
        HandleSubcontractingAfterUpdate(PurchLine);
    end;

    /// <summary>
    /// Creates released production order from temporary data
    /// </summary>
    local procedure CreateReleasedProductionOrderFromTemp(var ProdOrder: Record "Production Order")
    var
        TempProdOrder: Record "Production Order" temporary;
    begin
        TempDataInitializer.GetGlobalProdOrder(TempProdOrder);

        InitializeProductionOrder(ProdOrder);

        ConfigureProductionOrderFromTemp(ProdOrder, TempProdOrder);

        ProdOrder."Created from Purch. Order" := true;
        ProdOrder.Modify(true);
    end;

    /// <summary>
    /// Initializes production order with basic settings
    /// </summary>
    local procedure InitializeProductionOrder(var ProdOrder: Record "Production Order")
    begin
        Clear(ProdOrder);
        ProdOrder.Init();
        ProdOrder.Validate(Status, "Production Order Status"::Released);
        ProdOrder.Insert(true);

    end;

    /// <summary>
    /// Configures production order with data from temporary record
    /// </summary>
    local procedure ConfigureProductionOrderFromTemp(var ProdOrder: Record "Production Order"; var TempProdOrder: Record "Production Order" temporary)
    begin
        ProdOrder."Source Type" := TempProdOrder."Source Type";
        ProdOrder.Validate("Source No.", TempProdOrder."Source No.");

        if TempProdOrder."Variant Code" <> '' then
            ProdOrder.Validate("Variant Code", TempProdOrder."Variant Code");

        ProdOrder.Validate("Due Date", TempProdOrder."Due Date");
        ProdOrder.Validate(Quantity, TempProdOrder.Quantity);
        ProdOrder.Validate("Location Code", TempProdOrder."Location Code");
    end;

    /// <summary>
    /// Transfers temporary data to production order
    /// </summary>
    local procedure TransferTemporaryDataToProductionOrder(ProdOrder: Record "Production Order")
    var
        ProdOrderLine: Record "Prod. Order Line";
        TempProdOrderLine: Record "Prod. Order Line" temporary;
    begin
        TempDataInitializer.GetGlobalProdOrderLine(TempProdOrderLine);
        if not TempProdOrderLine.FindFirst() then
            exit;

        CreateProdOrderLineFromTemp(ProdOrderLine, ProdOrder, TempProdOrderLine);
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
        TempDataInitializer.GetGlobalProdOrderComponent(TempProdOrderComponent);
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
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        TempProdOrderRtngLine: Record "Prod. Order Routing Line" temporary;
    begin
        TempDataInitializer.GetGlobalProdOrderRoutingLine(TempProdOrderRtngLine);
        if TempProdOrderRtngLine.FindSet() then
            repeat
                CreateProdOrderRoutingLineFromTemp(ProdOrderRtngLine, TempProdOrderRtngLine, ProdOrderLine);
            until TempProdOrderRtngLine.Next() = 0;
    end;

    /// <summary>
    /// Updates purchase line with production order information
    /// </summary>
    local procedure UpdatePurchaseLineWithProdOrder(var PurchLine: Record "Purchase Line"; ProdOrder: Record "Production Order")
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        InitializePurchaseLineFields(PurchLine, ProdOrder);
        FindAndSetProdOrderLineNo(PurchLine, ProdOrder, ProdOrderLine);
        UpdatePurchLineWithRoutingInfo(PurchLine, ProdOrderLine);
        PurchLine.Modify(true);
    end;

    /// <summary>
    /// Initializes basic purchase line fields
    /// </summary>
    local procedure InitializePurchaseLineFields(var PurchLine: Record "Purchase Line"; ProdOrder: Record "Production Order")
    begin
        PurchLine."Prod. Order No." := ProdOrder."No.";
        PurchLine."Qty. per Unit of Measure" := 0;
        PurchLine."Quantity (Base)" := 0;
        PurchLine."Qty. to Invoice (Base)" := 0;
        PurchLine."Qty. to Receive (Base)" := 0;
        PurchLine."Outstanding Qty. (Base)" := 0;
    end;

    /// <summary>
    /// Finds and sets production order line number
    /// </summary>
    local procedure FindAndSetProdOrderLineNo(var PurchLine: Record "Purchase Line"; ProdOrder: Record "Production Order"; var ProdOrderLine: Record "Prod. Order Line")
    begin
        ProdOrderLine.SetLoadFields("Line No.");
        ProdOrderLine.SetRange(Status, ProdOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderLine.SetRange("Item No.", PurchLine."No.");
        if ProdOrderLine.FindFirst() then
            PurchLine."Prod. Order Line No." := ProdOrderLine."Line No.";
    end;

    /// <summary>
    /// Updates purchase line with routing information
    /// </summary>
    local procedure UpdatePurchLineWithRoutingInfo(var PurchLine: Record "Purchase Line"; var ProdOrderLine: Record "Prod. Order Line")
    var
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        WorkCenter: Record "Work Center";
    begin
        if not FindRoutingLinesForProdOrderLine(ProdOrderRtngLine, ProdOrderLine) then
            exit;

        if FindMatchingWorkCenterForVendor(ProdOrderRtngLine, WorkCenter, PurchLine."Buy-from Vendor No.") or
           FindAnySubcontractorWorkCenter(ProdOrderRtngLine, WorkCenter) then begin
            UpdatePurchLineFromRoutingLine(PurchLine, ProdOrderRtngLine);
            exit;
        end;

        ProdOrderRtngLine.FindFirst();
        UpdatePurchLineFromRoutingLine(PurchLine, ProdOrderRtngLine);
    end;

    /// <summary>
    /// Finds routing lines for production order line
    /// </summary>
    local procedure FindRoutingLinesForProdOrderLine(var ProdOrderRtngLine: Record "Prod. Order Routing Line"; var ProdOrderLine: Record "Prod. Order Line"): Boolean
    begin
        ProdOrderRtngLine.SetLoadFields("Work Center No.", "Operation No.", Description, "Routing No.", "Routing Reference No.");
        ProdOrderRtngLine.SetRange(Status, ProdOrderLine.Status);
        ProdOrderRtngLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderRtngLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
        ProdOrderRtngLine.SetRange("Routing Reference No.", ProdOrderLine."Line No.");
        ProdOrderRtngLine.SetRange(Type, "Capacity Type"::"Work Center");
        exit(not ProdOrderRtngLine.IsEmpty());
    end;

    /// <summary>
    /// Finds work center matching specific vendor
    /// </summary>
    local procedure FindMatchingWorkCenterForVendor(var ProdOrderRtngLine: Record "Prod. Order Routing Line"; var WorkCenter: Record "Work Center"; VendorNo: Code[20]): Boolean
    begin
        if ProdOrderRtngLine.FindSet() then
            repeat
                WorkCenter.SetLoadFields("Gen. Prod. Posting Group");
                WorkCenter.SetRange("No.", ProdOrderRtngLine."Work Center No.");
                WorkCenter.SetRange("Subcontractor No.", VendorNo);
                if WorkCenter.FindFirst() then
                    exit(true);
            until ProdOrderRtngLine.Next() = 0;
        exit(false);
    end;

    /// <summary>
    /// Finds any work center with subcontractor
    /// </summary>
    local procedure FindAnySubcontractorWorkCenter(var ProdOrderRtngLine: Record "Prod. Order Routing Line"; var WorkCenter: Record "Work Center"): Boolean
    begin
        ProdOrderRtngLine.FindSet();
        repeat
            WorkCenter.SetLoadFields("Gen. Prod. Posting Group");
            WorkCenter.SetRange("No.", ProdOrderRtngLine."Work Center No.");
            WorkCenter.SetFilter("Subcontractor No.", '<>%1', '');
            if WorkCenter.FindFirst() then
                exit(true);
        until ProdOrderRtngLine.Next() = 0;
        exit(false);
    end;

    local procedure UpdatePurchLineFromRoutingLine(var PurchLine: Record "Purchase Line"; ProdOrderRtngLine: Record "Prod. Order Routing Line")
    var
        SubcontractingPriceMgt: Codeunit "Subc. Price Management";
    begin
        PurchLine.Description := ProdOrderRtngLine.Description;
        PurchLine."Routing No." := ProdOrderRtngLine."Routing No.";
        PurchLine."Routing Reference No." := ProdOrderRtngLine."Routing Reference No.";
        PurchLine."Operation No." := ProdOrderRtngLine."Operation No.";
        PurchLine."Expected Receipt Date" := ProdOrderRtngLine."Ending Date";
        PurchLine.Validate("Work Center No.", ProdOrderRtngLine."Work Center No.");

        SubcontractingPriceMgt.GetSubcPriceForPurchLine(PurchLine);
        PurchLine.GetItemTranslation();
    end;

    /// <summary>
    /// Transfers reservation entries
    /// </summary>
    local procedure TransferReservationEntryFromPurchOrderCompToProdOrderLine(PurchLine: Record "Purchase Line"; ProdOrder: Record "Production Order")
    var
        ProdOrderLine: Record "Prod. Order Line";
        TempReservEntry: Record "Reservation Entry" temporary;
        PurchLineReserve: Codeunit "Purch. Line-Reserve";
    begin
        if not FindProdOrderLineForReservation(ProdOrderLine, ProdOrder, PurchLine."No.") then
            exit;

        CollectReservationEntries(PurchLine, TempReservEntry, PurchLineReserve);
        ReassignReservationEntries(ProdOrderLine, TempReservEntry);
    end;

    /// <summary>
    /// Finds production order line for reservation transfer
    /// </summary>
    local procedure FindProdOrderLineForReservation(var ProdOrderLine: Record "Prod. Order Line"; ProdOrder: Record "Production Order"; ItemNo: Code[20]): Boolean
    begin
        ProdOrderLine.SetLoadFields("Line No.");
        ProdOrderLine.SetRange(Status, "Production Order Status"::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderLine.SetRange("Item No.", ItemNo);
        exit(ProdOrderLine.FindFirst());
    end;

    /// <summary>
    /// Collects reservation entries into temporary table
    /// </summary>
    local procedure CollectReservationEntries(PurchLine: Record "Purchase Line"; var TempReservEntry: Record "Reservation Entry" temporary; var PurchLineReserve: Codeunit "Purch. Line-Reserve")
    var
        ReservEntry: Record "Reservation Entry";
    begin
        PurchLineReserve.FindReservEntry(PurchLine, ReservEntry);
        if ReservEntry.FindSet() then begin
            repeat
                TempReservEntry := ReservEntry;
                TempReservEntry.Insert();
            until ReservEntry.Next() = 0;
            ReservEntry.DeleteAll();
        end;
    end;

    /// <summary>
    /// Reassigns reservation entries to production order line
    /// </summary>
    local procedure ReassignReservationEntries(ProdOrderLine: Record "Prod. Order Line"; var TempReservEntry: Record "Reservation Entry" temporary)
    begin
        if TempReservEntry.FindSet() then
            repeat
                ReassignSingleReservationEntry(ProdOrderLine, TempReservEntry);
            until TempReservEntry.Next() = 0;
    end;

    local procedure ReassignSingleReservationEntry(ProdOrderLine: Record "Prod. Order Line"; var TempReservEntry: Record "Reservation Entry" temporary)
    var
        ReservEntry2: Record "Reservation Entry";
    begin
        ReservEntry2 := TempReservEntry;
        ReservEntry2."Source Type" := Database::"Prod. Order Line";
        ReservEntry2."Source Subtype" := ProdOrderLine.Status.AsInteger();
        ReservEntry2."Source ID" := ProdOrderLine."Prod. Order No.";
        ReservEntry2."Source Ref. No." := 0;
        ReservEntry2."Source Batch Name" := '';
        ReservEntry2."Source Prod. Order Line" := ProdOrderLine."Line No.";
        ReservEntry2.Insert();
    end;

    local procedure HandleSubcontractingAfterUpdate(var PurchLine: Record "Purchase Line")
    var
        RequisitionLine: Record "Requisition Line";
        SubcontractingMgmt: Codeunit "Subcontracting Management";
        SubcontractingMgmtExt: Codeunit "Subcontracting Management";
        NextLineNo: Integer;
    begin
        RequisitionLine."Prod. Order No." := PurchLine."Prod. Order No.";
        RequisitionLine."Prod. Order Line No." := PurchLine."Prod. Order Line No.";
        RequisitionLine."Operation No." := PurchLine."Operation No.";
        RequisitionLine."Routing No." := PurchLine."Routing No.";
        RequisitionLine."Routing Reference No." := PurchLine."Routing Reference No.";

        NextLineNo := PurchLine."Line No." + 10000;
        BindSubscription(SubcontractingMgmtExt);
        SubcontractingMgmt.TransferSubcontractingProdOrderComp(PurchLine, RequisitionLine, NextLineNo);
        UnbindSubscription(SubcontractingMgmtExt);
    end;

    /// <summary>
    /// Validates mandatory fields
    /// </summary>
    local procedure ValidateMandatoryFields(PurchLine: Record "Purchase Line")
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        Vendor: Record Vendor;
    begin
        GetSubManagementSetupCached();
        SubManagementSetup.TestField("Rtng. Link Code Purch. Prov.");
        SubManagementSetup.TestField("Component at Location");
        SubManagementSetup.TestField("Preset Component Item No.");
        SubManagementSetup.TestField("Common Work Center No.");

        ManufacturingSetup.Get();
        ManufacturingSetup.TestField("Released Order Nos.");
        ManufacturingSetup.TestField("Planned Order Nos.");
        ManufacturingSetup.TestField("Production BOM Nos.");
        ManufacturingSetup.TestField("Routing Nos.");

        Vendor.Get(PurchLine."Buy-from Vendor No.");
        Vendor.TestField("Subcontr. Location Code");

        PurchLine.TestField(Type, "Purchase Line Type"::Item);
        PurchLine.TestField("Prod. Order No.", '');
        PurchLine.TestField("Prod. Order Line No.", 0);
        PurchLine.TestField(Quantity);
        PurchLine.TestField("Location Code");
        PurchLine.TestField("Expected Receipt Date");
        PurchLine.TestField("Qty. Assigned", 0);
        PurchLine.TestField("Qty. Rcd. Not Invoiced", 0);
        PurchLine.TestField("Drop Shipment", false);
        PurchLine.TestField("Special Order", false);

        PurchLine.TestStatusOpen();
    end;

    /// <summary>
    /// Gets Sub Management Setup with caching
    /// </summary>
    local procedure GetSubManagementSetupCached()
    begin
        if HasSubManagementSetup then
            exit;
        if SubManagementSetup.Get() then
            HasSubManagementSetup := true;
    end;

    /// <summary>
    /// Updates item with BOM and routing from temporary data
    /// </summary>
    local procedure UpdateItemWithBOMAndRoutingFromTemp(var PurchLine: Record "Purchase Line")
    var
        SkipProcessBOMAndRouting: Boolean;
    begin
        SkipProcessBOMAndRouting := CheckCreateProdOrderCompRtng() and (ApplyBomRtngToSource = "Subc. RtngBOMSourceType"::Empty);
        if SkipProcessBOMAndRouting then
            exit;

        ProcessBOMAndRoutingData(PurchLine."No.");
    end;

    /// <summary>
    /// Processes BOM and routing data
    /// </summary>
    local procedure ProcessBOMAndRoutingData(ItemNo: Code[20])
    var
        TempBOMHeader: Record "Production BOM Header" temporary;
        TempBOMLine: Record "Production BOM Line" temporary;
        TempRoutingHeader: Record "Routing Header" temporary;
        TempRoutingLine: Record "Routing Line" temporary;
        BOMNo, BOMVersionCode, RoutingNo, RoutingVersionCode : Code[20];
    begin
        GetTemporaryBOMAndRoutingData(TempBOMHeader, TempBOMLine, TempRoutingHeader, TempRoutingLine);
        GetBOMAndRoutingInfoFromTempData(BOMNo, BOMVersionCode, RoutingNo, RoutingVersionCode);

        if BOMVersionCode = '' then
            CreateBOMIfNotExists(TempBOMHeader, TempBOMLine, BOMNo)
        else
            SaveBOMVersionIfRequired(TempBOMHeader, TempBOMLine, BOMNo, BOMVersionCode);

        if RoutingVersionCode = '' then
            CreateRoutingIfNotExists(TempRoutingHeader, TempRoutingLine, RoutingNo)
        else
            SaveRoutingVersionIfRequired(TempRoutingHeader, TempRoutingLine, RoutingNo, RoutingVersionCode);

        UpdateSourceWithBOMRoutingNumbers(ItemNo, BOMNo, RoutingNo);
    end;

    /// <summary>
    /// Gets temporary BOM and routing data
    /// </summary>
    local procedure GetTemporaryBOMAndRoutingData(var TempBOMHeader: Record "Production BOM Header" temporary; var TempBOMLine: Record "Production BOM Line" temporary; var TempRoutingHeader: Record "Routing Header" temporary; var TempRoutingLine: Record "Routing Line" temporary)
    begin
        TempDataInitializer.GetGlobalBOMHeader(TempBOMHeader);
        TempDataInitializer.GetGlobalBOMLines(TempBOMLine);
        TempDataInitializer.GetGlobalRoutingHeader(TempRoutingHeader);
        TempDataInitializer.GetGlobalRoutingLines(TempRoutingLine);
    end;

    /// <summary>
    /// Saves BOM version if required
    /// </summary>
    local procedure SaveBOMVersionIfRequired(var TempBOMHeader: Record "Production BOM Header" temporary; var TempBOMLine: Record "Production BOM Line" temporary; BomNo: Code[20]; BOMVersionCode: Code[20])
    var
        BOMLine: Record "Production BOM Line";
        BOMVersion: Record "Production BOM Version";
        NoSeries: Codeunit "No. Series";
        NewBOMVersionCode: Code[20];
    begin
        if BOMVersionCode = '' then
            exit;

        if SubVersionSelectionMgmt.CheckBOMExists(BomNo, BOMVersionCode) then
            exit;

        NewBOMVersionCode := NoSeries.GetNextNo(SubVersionSelectionMgmt.GetBOMVersionNoSeries(BomNo));
        TempDataInitializer.UpdateBOMVersionCode(NewBOMVersionCode);

        BOMVersion.Init();
        BOMVersion."Production BOM No." := BomNo;
        BOMVersion."Version Code" := NewBOMVersionCode;
        BOMVersion.Status := "BOM Status"::Certified;
        BOMVersion.Description := TempBOMHeader.Description;
        BOMVersion."Unit of Measure Code" := TempBOMHeader."Unit of Measure Code";
        BOMVersion."Starting Date" := WorkDate();
        BOMVersion.Status := TempBOMHeader.Status;
        BOMVersion.Insert(true);
        BOMVersionCreated := true;

        if TempBOMLine.FindSet() then
            repeat
                BOMLine := TempBOMLine;
                BOMLine.Insert(true);
            until TempBOMLine.Next() = 0;
        BOMVersion.Validate(Status, "BOM Status"::Certified);
        BOMVersion.Modify(true);

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
        if SubVersionSelectionMgmt.CheckRoutingExists(RoutingNo, RoutingVersionCode) then
            exit;

        NewRoutingVersionCode := NoSeries.GetNextNo(SubVersionSelectionMgmt.GetRoutingVersionNoSeries(RoutingNo));
        TempDataInitializer.UpdateRoutingVersionCode(NewRoutingVersionCode);

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
    local procedure CreateBOMIfNotExists(var TempBOMHeader: Record "Production BOM Header" temporary; var TempBOMLine: Record "Production BOM Line" temporary; var BOMNo: Code[20])
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        BOMHeader: Record "Production BOM Header";
        BOMLine: Record "Production BOM Line";
        NoSeries: Codeunit "No. Series";
    begin
        if SubVersionSelectionMgmt.CheckBOMExists(BOMNo, '') then
            exit;

        ManufacturingSetup.Get();
        BOMNo := NoSeries.GetNextNo(ManufacturingSetup."Production BOM Nos.");

        BOMHeader.Init();
        BOMHeader."No." := BOMNo;
        BOMHeader.Description := TempBOMHeader.Description;
        BOMHeader.Validate("Unit of Measure Code", TempBOMHeader."Unit of Measure Code");
        BOMHeader.Insert(true);
        BOMCreated := true;

        if TempBOMLine.FindSet() then
            repeat
                BOMLine := TempBOMLine;
                BOMLine."Production BOM No." := BOMNo;
                BOMLine."Version Code" := '';
                BOMLine.Insert(true);
            until TempBOMLine.Next() = 0;
        BOMHeader.Status := "BOM Status"::Certified;
        BOMHeader.Modify(true);
        TempDataInitializer.LoadBOMLines(BOMNo, '');
    end;

    /// <summary>
    /// Checks if BOM and routing exist and if the production components or routing have to be created out of the temporary data.
    /// </summary>
    /// <returns></returns>
    local procedure CheckCreateProdOrderCompRtng(): Boolean
    var
        TempBOMLine: Record "Production BOM Line" temporary;
        TempRoutingLine: Record "Routing Line" temporary;
        BOMRoutingExists: Boolean;
    begin
        TempDataInitializer.GetGlobalBOMLines(TempBOMLine);
        TempDataInitializer.GetGlobalRoutingLines(TempRoutingLine);

        BOMRoutingExists := SubVersionSelectionMgmt.CheckBOMExists(TempBOMLine."Production BOM No.", '') and SubVersionSelectionMgmt.CheckRoutingExists(TempRoutingLine."Routing No.", '');
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

        if SubVersionSelectionMgmt.CheckRoutingExists(RoutingNo, '') then
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
        TempDataInitializer.LoadRoutingLines(RoutingNo, '');
    end;

    /// <summary>
    /// Updates item or stockkeeping unit with BOM and routing numbers based on ApplyBomRtngToSource
    /// </summary>
    local procedure UpdateSourceWithBOMRoutingNumbers(ItemNo: Code[20]; BOMNo: Code[20]; RoutingNo: Code[20])
    var
        Item: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
        LocationCode: Code[10];
        VariantCode: Code[10];
    begin
        case ApplyBomRtngToSource of
            ApplyBomRtngToSource::Item:

                if Item.Get(ItemNo) and ((Item."Production BOM No." <> BOMNo) or (Item."Routing No." <> RoutingNo)) then begin
                    Item."Production BOM No." := BOMNo;
                    Item."Routing No." := RoutingNo;
                    Item.Modify(true);
                end;
            ApplyBomRtngToSource::StockkeepingUnit:
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
        TempPurchLine: Record "Purchase Line" temporary;
    begin
        TempDataInitializer.GetGlobalPurchLine(TempPurchLine);
        if TempPurchLine.FindFirst() then begin
            LocationCode := TempPurchLine."Location Code";
            VariantCode := TempPurchLine."Variant Code";
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

        if (ApplyBomRtngToSource = ApplyBomRtngToSource::Empty) then begin
            DeleteCreatedBOMIfExists(BOMNo);
            DeleteCreatedRoutingIfExists(RoutingNo);

            if not SubManagementSetup."Always Save Modified Versions" then begin
                DeleteCreatedBOMVersionIfExists(BOMNo, BOMVersionCode);
                DeleteCreatedRoutingVersionIfExists(RoutingNo, RoutingVersionCode);
            end;
        end;
    end;

    local procedure DeleteCreatedBOMIfExists(BOMNo: Code[20])
    var
        BOMHeader: Record "Production BOM Header";
    begin
        if not BOMCreated then
            exit;

        if BOMNo = '' then
            exit;

        if BOMHeader.Get(BOMNo) then begin
            BOMHeader.Validate(Status, "BOM Status"::"Under Development");
            BOMHeader.Modify(true);
            BOMHeader.Delete(true);
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
        BOMVersion: Record "Production BOM Version";
    begin
        if not BOMVersionCreated then
            exit;

        if (BOMNo = '') or (BOMVersionCode = '') then
            exit;

        if BOMVersion.Get(BOMNo, BOMVersionCode) then begin
            BOMVersion.Validate(Status, "BOM Status"::"Under Development");
            BOMVersion.Modify();
            BOMVersion.Delete(true);
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
    local procedure RefreshProductionOrderAfterUpdate(var ProdOrder: Record "Production Order"; NewDirection: Option; CalcRoutings: Boolean; CalcComponents: Boolean; DeleteRelations: Boolean)
    var
        ProdOrderLine: Record "Prod. Order Line";
        CalculateProdOrder: Codeunit "Calculate Prod. Order";
    begin
        ProdOrderLine.SetLoadFields("Prod. Order No.", Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderLine.SetRange(Status, ProdOrder.Status);
        if not ProdOrderLine.FindFirst() then
            exit;
        CalculateProdOrder.Calculate(ProdOrderLine, NewDirection, CalcRoutings, CalcComponents, DeleteRelations, true);
    end;

    /// <summary>
    /// Creates production order line from temporary data
    /// </summary>
    local procedure CreateProdOrderLineFromTemp(var ProdOrderLine: Record "Prod. Order Line"; ProdOrder: Record "Production Order"; TempProdOrderLine: Record "Prod. Order Line" temporary)
    var
        Item: Record Item;
        CalcProdOrder: Codeunit "Calculate Prod. Order";
        BOMNo, BOMVersionCode, RoutingNo, RoutingVersionCode : Code[20];
    begin
        GetBOMAndRoutingInfoFromTempData(BOMNo, BOMVersionCode, RoutingNo, RoutingVersionCode);

        ProdOrderLine.Init();
        ProdOrderLine.SetIgnoreErrors();
        ProdOrderLine.Status := ProdOrder.Status;
        ProdOrderLine."Prod. Order No." := ProdOrder."No.";
        ProdOrderLine."Line No." := TempProdOrderLine."Line No.";
        ProdOrderLine."Routing Reference No." := ProdOrderLine."Line No.";

        ProdOrderLine.Validate("Item No.", ProdOrder."Source No.");
        ProdOrderLine."Location Code" := ProdOrder."Location Code";
        ProdOrderLine.Validate("Variant Code", ProdOrder."Variant Code");

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

        if ProdOrder."Bin Code" <> '' then
            ProdOrderLine.Validate("Bin Code", ProdOrder."Bin Code")
        else
            CalcProdOrder.SetProdOrderLineBinCodeFromRoute(ProdOrderLine, ProdOrderLine."Location Code", ProdOrderLine."Routing No.");

        Item.SetLoadFields("Scrap %", "Inventory Posting Group");
        Item.Get(ProdOrder."Source No.");
        ProdOrderLine."Scrap %" := Item."Scrap %";

        ProdOrderLine."Due Date" := ProdOrder."Due Date";
        ProdOrderLine."Starting Date-Time" := ProdOrder."Starting Date-Time";
        ProdOrderLine."Ending Date-Time" := ProdOrder."Ending Date-Time";
        ProdOrderLine."Planning Level Code" := 0;
        ProdOrderLine."Inventory Posting Group" := Item."Inventory Posting Group";
        ProdOrderLine.UpdateDatetime();
        ProdOrderLine.Validate("Unit Cost");

        ProdOrderLine.Description := ProdOrder.Description;
        ProdOrderLine."Description 2" := ProdOrder."Description 2";
        ProdOrderLine.Validate(Quantity, ProdOrder.Quantity);
        ProdOrderLine.UpdateDatetime();
        ProdOrderLine.Insert();
    end;

    /// <summary>
    /// Gets BOM and routing information from temporary data
    /// </summary>
    local procedure GetBOMAndRoutingInfoFromTempData(var BOMNo: Code[20]; var BOMVersionCode: Code[20]; var RoutingNo: Code[20]; var RoutingVersionCode: Code[20])
    var
        TempProdBOMLine: Record "Production BOM Line" temporary;
        TempRoutingLine: Record "Routing Line" temporary;
    begin
        TempDataInitializer.GetGlobalRoutingLines(TempRoutingLine);
        TempDataInitializer.GetGlobalBOMLines(TempProdBOMLine);

        if TempRoutingLine.FindFirst() then begin
            RoutingNo := TempRoutingLine."Routing No.";
            RoutingVersionCode := TempRoutingLine."Version Code";
        end;

        if TempProdBOMLine.FindFirst() then begin
            BOMNo := TempProdBOMLine."Production BOM No.";
            BOMVersionCode := TempProdBOMLine."Version Code";
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
    local procedure CreateProdOrderRoutingLineFromTemp(var ProdOrderRtngLine: Record "Prod. Order Routing Line"; TempProdOrderRtngLine: Record "Prod. Order Routing Line" temporary; var ProdOrderLine: Record "Prod. Order Line")
    begin
        ProdOrderRtngLine.Init();
        ProdOrderRtngLine.Validate(Status, ProdOrderLine.Status);
        ProdOrderRtngLine.Validate("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderRtngLine.Validate("Routing Reference No.", ProdOrderLine."Line No.");
        ProdOrderRtngLine."Routing No." := ProdOrderLine."Routing No.";
        ProdOrderRtngLine.Validate("Operation No.", TempProdOrderRtngLine."Operation No.");
        ProdOrderRtngLine.Insert(true);

        ProdOrderRtngLine."Vendor No. Subc. Price" := TempProdOrderRtngLine."Vendor No. Subc. Price";
        ProdOrderRtngLine.Validate(Type, TempProdOrderRtngLine.Type);
        ProdOrderRtngLine.Validate("No.", TempProdOrderRtngLine."No.");
        ProdOrderRtngLine.Description := TempProdOrderRtngLine.Description;
        ProdOrderRtngLine."Setup Time" := TempProdOrderRtngLine."Setup Time";
        ProdOrderRtngLine."Run Time" := TempProdOrderRtngLine."Run Time";
        ProdOrderRtngLine."Wait Time" := TempProdOrderRtngLine."Wait Time";
        ProdOrderRtngLine."Move Time" := TempProdOrderRtngLine."Move Time";
        ProdOrderRtngLine."Ending Date" := TempProdOrderRtngLine."Ending Date";
        ProdOrderRtngLine."Ending Time" := TempProdOrderRtngLine."Ending Time";
        ProdOrderRtngLine.UpdateDatetime();
        ProdOrderRtngLine."Routing Link Code" := TempProdOrderRtngLine."Routing Link Code";
        ProdOrderRtngLine.Modify(true);
    end;
}