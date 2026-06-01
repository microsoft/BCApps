// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.QualityManagement.TestLibraries;

using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Family;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Document;

/// <summary>
/// Generates random Prod. Orders and all related records for use with automated testing.
/// </summary>
codeunit 139942 "Qlty. Prod. Order Generator"
{
    TableNo = "Production Order";
    EventSubscriberInstance = Manual;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        Sources: Dictionary of [Enum "Prod. Order Source Type", boolean];
        ProdOrderStatus: Enum "Production Order Status";
        OrderLinesMin: Integer;
        OrderLinesMax: Integer;
        BoMsMin: Integer;
        BoMsMax: Integer;
        RoutingsMin: Integer;
        RoutingsMax: Integer;
        SetupTimeMin: Decimal;
        SetupTimeMax: Decimal;
        RunTimeMin: Decimal;
        RunTimeMax: Decimal;
        SendAheadQty: Decimal;
        DecimalPrecision: Integer;
        QuantityToCreate: Decimal;

    /// <summary>
    /// Initializes the Prod. Order Generator. Must be called before Generate().
    /// </summary>
    /// <param name="Seed">A seed for the random number generator. Using the same seed should give 
    /// the same results every time for stable testing.</param>
    internal procedure Init(Seed: Integer)
    var
        UnitOfMeasure: Record "Unit of Measure";
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        LibraryRandom.SetSeed(Seed);
        ToggleAllSources(true);
        ProdOrderStatus := "Production Order Status"::Released;
        OrderLinesMin := 3;
        OrderLinesMax := 5;
        SendAheadQty := 1;
        BoMsMin := 3;
        BoMsMax := 5;
        RoutingsMin := 3;
        RoutingsMax := 5;
        SetupTimeMin := 5;
        SetupTimeMax := 60;
        RunTimeMin := 5;
        RunTimeMax := 60;
        DecimalPrecision := 2;

        if UnitOfMeasure.IsEmpty() then
            LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);

        ManufacturingSetup.Get();
        if ManufacturingSetup."Normal Starting Time" = 0T then begin
            ManufacturingSetup."Normal Starting Time" := 080000T;
            ManufacturingSetup."Normal Ending Time" := 160000T;
            ManufacturingSetup.Modify();
        end;

        SetupVAT();

        LibrarySales.SetOrderNoSeriesInSetup();
    end;

    internal procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var Vendor: Record vendor; var Item: Record Item)
    var
        PurchaseLine: Record "Purchase Line";
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        SetupVAT(Vendor."VAT Bus. Posting Group", Item."VAT Prod. Posting Group");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 4);
        PurchaseLine.Validate("Direct Unit Cost", 1.23);
        PurchaseLine.Modify(true);
    end;

    /// <summary>
    /// Creates Item and Production Order
    /// </summary>
    /// <param name="OutItem"></param>
    /// <param name="OutProdProductionOrder"></param>
    /// <param name="OutProdOrderRoutingLine"></param>
    internal procedure CreateItemAndProductionOrder(var OutItem: Record Item; var OutProdProductionOrder: Record "Production Order"; var OutProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        OrdersList: List of [Code[20]];
        ProductionOrder: Code[20];
    begin
        QltyProdOrderGenerator.Init(100);
        QltyProdOrderGenerator.ToggleAllSources(false);
        QltyProdOrderGenerator.ToggleSourceType("Prod. Order Source Type"::Item, true);
        QltyProdOrderGenerator.Generate(2, OrdersList);
        OrdersList.Get(1, ProductionOrder);
        OutProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder);
        OutProdOrderRoutingLine.SetRange(Status, OutProdOrderRoutingLine.Status::Released);
        OutProdOrderRoutingLine.FindLast();

        OutProdProductionOrder.Get(OutProdProductionOrder.Status::Released, ProductionOrder);
        OutItem.Get(OutProdProductionOrder."Source No.");
    end;

    /// <summary>
    /// Generates production orders from Item source type and returns the list of created order codes.
    /// This is a convenience wrapper that initializes the generator, configures it for Item source type,
    /// and generates the specified quantity of orders.
    /// </summary>
    /// <param name="Quantity">The number of production orders to generate.</param>
    /// <param name="OutOrdersList">Returns the list of generated production order codes.</param>
    internal procedure GenerateItemSourceProdOrders(Quantity: Integer; var OutOrdersList: List of [Code[20]])
    var
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
    begin
        QltyProdOrderGenerator.Init(100);
        QltyProdOrderGenerator.ToggleAllSources(false);
        QltyProdOrderGenerator.ToggleSourceType("Prod. Order Source Type"::Item, true);
        QltyProdOrderGenerator.Generate(Quantity, OutOrdersList);
    end;

    /// <summary>
    /// Creates Lot-Tracked Item and Production Order
    /// </summary>
    /// <param name="OutItem"></param>
    /// <param name="OutProdProductionOrder"></param>
    /// <param name="OutProdOrderRoutingLine"></param>
    internal procedure CreateLotTrackedItemAndProductionOrder(var OutItem: Record Item; var OutProdProductionOrder: Record "Production Order"; var OutProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
    begin
        QltyProdOrderGenerator.CreateLotTrackedItemAndProductionOrder(ProdOrderStatus, OutItem, OutProdProductionOrder, OutProdOrderRoutingLine);
    end;

    /// <summary>
    /// Creates Lot-Tracked Item and Production Order
    /// </summary>
    /// <param name="OutItem"></param>
    /// <param name="OutProdProductionOrder"></param>
    /// <param name="OutProdOrderRoutingLine"></param>
    internal procedure CreateLotTrackedItemAndProductionOrder(ProdOrderStatusToCreate: Enum "Production Order Status"; var OutItem: Record Item; var OutProdProductionOrder: Record "Production Order"; var OutProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
    begin
        QltyProdOrderGenerator.Init(100);
        QltyProdOrderGenerator.ToggleAllSources(false);
        QltyProdOrderGenerator.ToggleSourceType("Prod. Order Source Type"::Item, true);
        CreateOrderFromLotTrackedItem(ProdOrderStatusToCreate, OutProdProductionOrder);
        OutProdOrderRoutingLine.SetRange("Prod. Order No.", OutProdProductionOrder."No.");
        OutProdOrderRoutingLine.SetRange(Status, ProdOrderStatusToCreate);
        if OutProdOrderRoutingLine.FindLast() then;

        OutProdProductionOrder.Get(ProdOrderStatusToCreate, OutProdProductionOrder."No.");
        OutItem.Get(OutProdProductionOrder."Source No.");
    end;

    internal procedure CreateProdOrderLine(var ProdProductionOrder: Record "Production Order"; var Item: Record Item; Qty: Decimal; var OutProdOrderLine: Record "Prod. Order Line")
    begin
        LibraryManufacturing.CreateProdOrderLine(OutProdOrderLine, ProdProductionOrder.Status, ProdProductionOrder."No.", Item."No.", '', '', Qty);
    end;

    internal procedure CreateOutputJournal(var Item: Record Item; var ProdOrderLine: Record "Prod. Order Line"; var ItemJournalBatch: Record "Item Journal Batch"; var OutItemJournalLine: Record "Item Journal Line"; OutputQty: Decimal)
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        ItemJournalTemplate.Get(ItemJournalBatch."Journal Template Name");
        LibraryManufacturing.CreateOutputJournal(OutItemJournalLine, ItemJournalTemplate, ItemJournalBatch, Item."No.", ProdOrderLine."Prod. Order No.");
        OutItemJournalLine.Validate("Order Line No.", ProdOrderLine."Line No.");
        OutItemJournalLine.Validate("Output Quantity", OutputQty);
        OutItemJournalLine.Modify();
    end;

    internal procedure SetupVAT()
    begin
        SetupVAT('', '');
    end;
    /// <summary>
    /// Sets up Value-Added-Tax for testing in blank companies.
    /// </summary>
    internal procedure SetupVAT(VATBusPostingGroup: Text; VATProdPostingGroup: Text)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        VATProductPostingGroup.Init();
        VATProductPostingGroup.Code := 'VAT PRODUCT DEMO';
        if not VATProductPostingGroup.Insert() then
            exit;

        if VATBusPostingGroup <> '' then begin
            VATPostingSetup.Init();
            VATPostingSetup."VAT Bus. Posting Group" := CopyStr(VATBusPostingGroup, 1, MaxStrLen(VATPostingSetup."VAT Bus. Posting Group"));
            VATPostingSetup."VAT Prod. Posting Group" := CopyStr(VATProdPostingGroup, 1, maxstrlen(VATPostingSetup."VAT Prod. Posting Group"));
            if VATPostingSetup.Insert() then;
        end;

        VATPostingSetup.Init();
        VATPostingSetup."VAT Prod. Posting Group" := VATProductPostingGroup.Code;
        if VATPostingSetup.Insert() then;
        if VATBusinessPostingGroup.FindSet() then
            repeat
                VATPostingSetup.Reset();
                VATPostingSetup.SetRange("VAT Bus. Posting Group", VATBusinessPostingGroup.Code);
                VATPostingSetup.SetRange("VAT Prod. Posting Group", VATProductPostingGroup.Code);
                if VATPostingSetup.IsEmpty() then begin
                    VATPostingSetup.Init();
                    VATPostingSetup."VAT Prod. Posting Group" := VATProductPostingGroup.Code;
                    VATPostingSetup."VAT Bus. Posting Group" := VATBusinessPostingGroup.Code;
                    VATPostingSetup.Insert();
                end;
            until VATBusinessPostingGroup.Next() = 0;
    end;

    /// <summary>
    /// Creates a text that can be used to filter records to only those with a value in the given 
    /// list. Useful for applying inspections to only generated test data.
    /// </summary>
    /// <param name="pliCodes">A list of Record No's to filter by.</param>
    /// <returns>A text of every element of the input delimited by '|'.</returns>
    internal procedure CreateFilter(pliCodes: List of [Code[20]]) Filter: Text
    var
        Index: Integer;
    begin
        Filter := pliCodes.Get(1);
        for Index := 2 to pliCodes.Count() do
            Filter := StrSubstNo('%1|%2', Filter, pliCodes.Get(Index));
    end;

    /// <summary>
    /// Toggles whether a given Prod. Order Source Type is used to generate test data.
    /// </summary>
    /// <param name="Type">The Prod. Order Source Type to toggle.</param>
    /// <param name="Value">A boolean to enable/disable the type.</param>
    internal procedure ToggleSourceType(Type: Enum "Prod. Order Source Type"; Value: Boolean)
    begin
        Sources.Set(Type, Value);
    end;

    /// <summary>
    /// Toggles all Prod. Order Source Types used by the generator to the given value.
    /// </summary>
    /// <param name="Value">A boolean to enable/disable all types.</param>
    internal procedure ToggleAllSources(Value: Boolean)
    var
        Type: Enum "Prod. Order Source Type";
    begin
        for Type := "Prod. Order Source Type"::Item to "Prod. Order Source Type"::"Sales Header" do
            ToggleSourceType(Type, Value);
    end;

    /// <summary>
    /// Generates randomized data for automated testing. Should have no dependencies on exsisting 
    /// records in the test environment. When initalized with the same seed, should always create 
    /// the same output.
    /// </summary>
    /// <param name="Quantity">The quantity of Prod. Orders of each source type to create.</param>
    /// <param name="pliOutOrders">A list of the Prod. Order No's generated.</param>
    internal procedure Generate(Quantity: Integer; var pliOutOrders: List of [Code[20]])
    var
        ProductionOrder: Record "Production Order";
        Type: Enum "Prod. Order Source Type";
        Orders: Integer;
    begin
        foreach Type in Sources.Keys() do
            if Sources.Get(Type) then
                for Orders := Quantity downto 1 do begin
                    Clear(ProductionOrder);
                    CreateProductionOrder(Type, ProductionOrder);
                    pliOutOrders.Add(ProductionOrder."No.");
                end;
    end;

    local procedure CreateProductionOrder(Type: Enum "Prod. Order Source Type"; var OutProductionOrder: Record "Production Order")
    var
        Lines: Integer;
    begin
        Lines := LibraryRandom.RandIntInRange(OrderLinesMin, OrderLinesMax);
        case Type of
            "Prod. Order Source Type"::Item:
                CreateOrderFromItem(OutProductionOrder);
            "Prod. Order Source Type"::"Sales Header":
                CreateOrderFromSale(Lines, OutProductionOrder);
            "Prod. Order Source Type"::Family:
                CreateOrderFromFamily(Lines, OutProductionOrder);
        end;
    end;

    internal procedure CreateItem(var Item: Record "Item")
    var
        RoutingHeader: Record "Routing Header";
    begin
        LibraryInventory.CreateItem(Item);
        CreateBoM(Item);
        CreateSerialRouting(RoutingHeader);

        Item."Routing No." := RoutingHeader."No.";
        Item."Replenishment System" := "Replenishment System"::"Prod. Order";
        Item."VAT Prod. Posting Group" := 'VAT PRODUCT DEMO';
        Item.Modify();

        SetupVAT();
    end;

    internal procedure CreateLotTrackedItem(var Item: Record "Item")
    var
        RoutingHeader: Record "Routing Header";
    begin
        QltyInspectionUtility.CreateLotTrackedItem(Item);

        CreateBoM(Item);
        CreateSerialRouting(RoutingHeader);

        Item."Routing No." := RoutingHeader."No.";
        Item."Replenishment System" := "Replenishment System"::"Prod. Order";
        Item."VAT Prod. Posting Group" := 'VAT PRODUCT DEMO';
        Item.Modify();

        SetupVAT();
    end;

    local procedure CreateBoM(var Item: Record "Item")
    var
        ProductionBOMHeader: Record "Production BOM Header";
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Lines: Integer;
    begin
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure.Code, 1);
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, UnitOfMeasure.Code);
        for Lines := LibraryRandom.RandIntInRange(BoMsMin, BoMsMax) downto 1 do
            CreateBoMLine(ProductionBOMHeader);

        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, "BoM Status"::Certified);

        Item."Production BOM No." := ProductionBOMHeader."No.";
        Item.Modify();
    end;

    local procedure CreateBoMLine(var ProductionBOMHeader: Record "Production BOM Header")
    var
        Item: Record "Item";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", 'VAT PRODUCT DEMO');
        Item.Modify();

        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', "Production Bom Line Type"::Item, Item."No.", 1);
    end;

    local procedure CreateRandomCapacity(var OutType: Enum "Capacity Type"; var OutNo: Code[20])
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
    begin
        OutType := "Capacity Type".FromInteger(LibraryRandom.RandInt(2) - 1);
        case OutType of
            "Capacity Type"::"Work Center":
                begin
                    CreateWorkCenter(WorkCenter);
                    OutNo := WorkCenter."No.";
                end;
            "Capacity Type"::"Machine Center":
                begin
                    CreateMachineCenter(MachineCenter);
                    OutNo := MachineCenter."No.";
                end;
        end;
    end;

    local procedure CreateMachineCenter(var OutMachineCenter: Record "Machine Center")
    var
        WorkCenter: Record "Work Center";
    begin
        CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateMachineCenterWithCalendar(OutMachineCenter, WorkCenter."No.", 8);
    end;

    local procedure CreateWorkCenter(var OutWorkCenter: Record "Work Center")
    begin
        LibraryManufacturing.CreateWorkCenterWithCalendar(OutWorkCenter);
    end;

    local procedure CreateSerialRouting(var RoutingHeader: Record "Routing Header")
    var
        RoutingVersion: Record "Routing Version";
        NumLines: Integer;
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingVersion(RoutingVersion, RoutingHeader."No.", CopyStr(LibraryRandom.RandText(MaxStrLen(RoutingVersion."Version Code")), 1, MaxStrLen(RoutingVersion."Version Code")));
        for NumLines := LibraryRandom.RandIntInRange(RoutingsMin, RoutingsMax) downto 1 do
            CreateRoutingLine(RoutingHeader);

        LibraryManufacturing.UpdateRoutingStatus(RoutingHeader, "Routing Status"::Certified);
    end;

    local procedure CreateRoutingLine(var RoutingHeader: Record "Routing Header")
    var
        RoutingLine: Record "Routing Line";
        CapacityType: Enum "Capacity Type";
        CapacityNo: Code[20];
    begin
        CreateRandomCapacity(CapacityType, CapacityNo);
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, RoutingHeader."Version Nos.", CopyStr(LibraryRandom.RandText(MaxStrLen(RoutingLine."Operation No.")), 1, 10), CapacityType, CapacityNo);
        RoutingLine."Setup Time" := LibraryRandom.RandDecInDecimalRange(SetupTimeMin, SetupTimeMax, DecimalPrecision);
        RoutingLine."Run Time" := LibraryRandom.RandDecInDecimalRange(RunTimeMin, RunTimeMax, DecimalPrecision);
        RoutingLine."Send-Ahead Quantity" := SendAheadQty;
        RoutingLine.Modify();
    end;

    internal procedure SetQuantity(Quantity: Decimal)
    begin
        QuantityToCreate := Quantity;
    end;

    local procedure CreateOrderFromItem(var OutProductionOrder: Record "Production Order")
    var
        Item: Record "Item";
    begin
        CreateItem(Item);
        if QuantityToCreate = 0 then
            QuantityToCreate := 1;
        LibraryManufacturing.CreateAndRefreshProductionOrder(OutProductionOrder, ProdOrderStatus, "Prod. Order Source Type"::Item, Item."No.", QuantityToCreate);

        LibraryManufacturing.RefreshProdOrder(OutProductionOrder, false, false, true, true, true);
    end;

    local procedure CreateOrderFromLotTrackedItem(ProdOrderStatusToCreate: Enum "Production Order Status"; var OutProductionOrder: Record "Production Order")
    var
        Item: Record "Item";
    begin
        CreateLotTrackedItem(Item);
        LibraryManufacturing.CreateAndRefreshProductionOrder(OutProductionOrder, ProdOrderStatusToCreate, "Prod. Order Source Type"::Item, Item."No.", 1);

        LibraryManufacturing.RefreshProdOrder(OutProductionOrder, false, false, true, true, true);
    end;

    local procedure CreateOrderFromSale(NumLines: Integer; var OutProductionOrder: Record "Production Order")
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.InitInsert();
        SalesHeader."No." := CopyStr(LibraryRandom.RandText(MaxStrLen(SalesHeader."No.")), 1, maxstrlen(SalesHeader."No."));
        SalesHeader."Sell-to Customer No." := LibrarySales.CreateCustomerNo();
        SalesHeader."Bill-to Customer No." := SalesHeader."Sell-to Customer No.";
        SalesHeader."Document Type" := "Sales Document Type"::Order;
        SalesHeader.Insert();

        for NumLines := NumLines downto 1 do
            CreateSalesLine(SalesHeader);

        LibraryManufacturing.CreateAndRefreshProductionOrder(OutProductionOrder, ProdOrderStatus, "Prod. Order Source Type"::"Sales Header", SalesHeader."No.", 1);
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header")
    var
        Item: Record "Item";
        SalesLine: Record "Sales Line";
    begin
        CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, "Sales Line Type"::Item, Item."No.", 1);
        SalesLine.Modify();
    end;

    local procedure CreateOrderFromFamily(NumLines: Integer; var OutProductionOrder: Record "Production Order")
    var
        Family: Record Family;
        RoutingHeader: Record "Routing Header";
    begin
        LibraryManufacturing.CreateFamily(Family);

        CreateSerialRouting(RoutingHeader);
        Family."Routing No." := RoutingHeader."No.";
        Family.Modify();

        for NumLines := NumLines downto 1 do
            CreateFamilyLine(Family);

        LibraryManufacturing.CreateAndRefreshProductionOrder(OutProductionOrder, ProdOrderStatus, "Prod. Order Source Type"::Family, Family."No.", 1);
    end;

    local procedure CreateFamilyLine(var Family: Record "Family")
    var
        Item: Record "Item";
        FamilyLine: Record "Family Line";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryManufacturing.CreateFamilyLine(FamilyLine, Family."No.", Item."No.", 1);
    end;

    #region Event Subscribers

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Library - Inventory", 'OnAfterCreateItem', '', true, true)]
    local procedure OnAfterCreateItem(var Item: Record Item)
    var
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
    begin
        QltyProdOrderGenerator.SetupVAT();
    end;

    #endregion Event Subscribers
}
