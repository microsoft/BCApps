// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Test;

using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using System.Environment.Configuration;
using Microsoft.Inventory;
using Microsoft.Assembly.Setup;
using Microsoft.Purchases.Setup;
using Microsoft.Sales.Setup;
using Microsoft.Inventory.Transfer;
using Microsoft.Warehouse.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.BOM;
using Microsoft.Assembly.Document;
using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Assembly.History;
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Availability;
using Microsoft.Foundation.UOM;
using Microsoft.Assembly.Posting;
using Microsoft.Inventory.Setup;

codeunit 137093 "SCM Kitting - D4"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Assembly] [Item Availability] [SCM]
        isInitialized := false;
    end;

    var
        TempAsmAvailTestBuf: Record "Asm. Availability Test Buffer" temporary;
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        LocationBlue: Record Location;
        LocationRed: Record Location;
        TransitLocation: Record Location;
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryAssembly: Codeunit "Library - Assembly";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LeadTimeMgt: Codeunit "Lead-Time Management";
        isInitialized: Boolean;
        ChangeLocationQst: Label 'Do you want to update the Location Code on the lines?';
        ComponentIsNotAvailableErr: Label 'Component availability issue for assembly item %1. Component should be available!', Comment = '%1: Item No.';
        ComponentIsAvailableErr: Label 'Component should not be available for assembly item %1!', Comment = '%1: Item No.';
        WorkDate2: Date;
        WorkDate10D: Date;
        WrongValueInAsmLineErr: Label 'Wrong %1 in Asm. Order line.', Comment = '%1: The name of the field where the error is found.';

    [Normal]
    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Kitting - D4");
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Kitting - D4");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();
        GlobalSetup();

        isInitialized := true;

        Commit();
        LibrarySetupStorage.Save(DATABASE::"Assembly Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Kitting - D4");
    end;

    local procedure GlobalSetup()
    begin
        WorkDate2 := CalcSafeDate(WorkDate()); // to avoid Due Date Before Work Date message.
        WorkDate10D := CalcDate('<10D>', WorkDate2);
        InitializeSetup();
        SetupItemJournal();

        LocationSetup(LocationBlue, false);
        LocationSetup(LocationRed, false);
        LocationSetup(TransitLocation, true);
        TransferRoutesSetup();
    end;

    local procedure CalcSafeDate(Date: Date): Date
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        exit(CalcDate(InventorySetup."Default Safety Lead Time", Date));
    end;

    [Normal]
    local procedure InitializeSetup()
    var
        AssemblySetup: Record "Assembly Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        AssemblySetup.Get();
        AssemblySetup.Validate("Assembly Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        AssemblySetup.Validate("Posted Assembly Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        AssemblySetup.Validate("Default Location for Orders", '');
        AssemblySetup.Modify(true);

        SalesSetup.Get();
        SalesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesSetup.Validate("Return Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesSetup.Modify(true);

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);
    end;

    [Normal]
    local procedure SetupItemJournal()
    begin
        Clear(ItemJournalTemplate);
        ItemJournalTemplate.Init();
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        ItemJournalTemplate.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalTemplate.Modify(true);

        Clear(ItemJournalBatch);
        ItemJournalBatch.Init();
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch.Modify(true);
    end;

    local procedure TransferRoutesSetup()
    var
        TransferRoute: Record "Transfer Route";
    begin
        LibraryWarehouse.CreateTransferRoute(TransferRoute, LocationRed.Code, LocationBlue.Code);
        LibraryWarehouse.CreateTransferRoute(TransferRoute, LocationBlue.Code, LocationRed.Code);
    end;

    local procedure LocationSetup(var Location: Record Location; UseAsInTransit: Boolean)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        Clear(Location);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        if UseAsInTransit then begin
            Location.Validate("Use As In-Transit", true);
            Location.Modify(true);
            exit;
        end;

        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
    end;

    local procedure AddComponent(ParentItem: Record Item; var BOMComponent: Record "BOM Component")
    begin
        AddComponent(ParentItem, BOMComponent, 1);
    end;

    local procedure AddComponent(ParentItem: Record Item; var BOMComponent: Record "BOM Component"; QtyPer: Decimal)
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        CreateAssemblyListComponent(
            BOMComponent, BOMComponent.Type::Item, Item."No.", ParentItem."No.", '',
            BOMComponent."Resource Usage Type"::Direct, Item."Base Unit of Measure", QtyPer);
    end;

    local procedure SetRandComponentQuantityPer(var BOMComponent: Record "BOM Component"): Decimal
    begin
        BOMComponent.Validate("Quantity per", RandInt5());
        BOMComponent.Modify();
        exit(BOMComponent."Quantity per");
    end;

    local procedure CreateAssemblyListComponent(var BOMComponent: Record "BOM Component"; ComponentType: Enum "BOM Component Type"; ComponentNo: Code[20]; ParentItemNo: Code[20]; VariantCode: Code[10]; ResourceUsage: Option; UOM: Code[10]; QtyPer: Decimal)
    begin
        LibraryInventory.CreateBOMComponent(BOMComponent, ParentItemNo, ComponentType, ComponentNo, QtyPer, UOM);
        if ComponentType = BOMComponent.Type::Resource then
            BOMComponent.Validate("Resource Usage Type", ResourceUsage);
        BOMComponent.Validate("Variant Code", VariantCode);
        BOMComponent.Validate(Description, LibraryUtility.GenerateRandomCode(BOMComponent.FieldNo(Description), DATABASE::"BOM Component"));
        BOMComponent.Modify(true);
    end;

    [Normal]
    local procedure CreateAssemblyOrder(var AssemblyHeader: Record "Assembly Header"; ParentItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; DueDate: Date; Quantity: Decimal): Decimal
    begin
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, DueDate, ParentItemNo, LocationCode, Quantity, VariantCode);
        NotificationLifecycleMgt.RecallAllNotifications();
        exit(Quantity);
    end;

    [Normal]
    local procedure CreateAssemblyOrderOnSafeDate(var AssemblyHeader: Record "Assembly Header"; ParentItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; DueDate: Date; Quantity: Decimal): Decimal
    var
        SafetyLeadTime: DateFormula;
    begin
        Evaluate(SafetyLeadTime, LeadTimeMgt.SafetyLeadTime(ParentItemNo, LocationCode, '')); // VSTF 256580
        LibraryAssembly.CreateAssemblyHeader(
          AssemblyHeader, CalcDate(SafetyLeadTime, DueDate), ParentItemNo, LocationCode, Quantity, VariantCode);
        NotificationLifecycleMgt.RecallAllNotifications();
        exit(Quantity);
    end;

    local procedure CreateAssemblyOrderMissingInventory(var AssemblyHeader: Record "Assembly Header"; var BOMComponentNo: Code[20]; DueDate: Date; LocationCode: Code[10]; Negative: Boolean) MissedQty: Decimal
    var
        Item: Record Item;
        BOMComponent: Record "BOM Component";
        QtyOnAssemble: Integer;
    begin
        // Create the assembled Item
        LibraryInventory.CreateItem(Item);
        AddComponent(Item, BOMComponent);

        QtyOnAssemble := RandInt();
        MissedQty := QtyOnAssemble div 7;
        if Negative then
            MissedQty := -MissedQty;

        // Add inventory for first component
        AddInventory(BOMComponent."No.", '', LocationCode, QtyOnAssemble - MissedQty);
        BOMComponentNo := BOMComponent."No.";

        // will also "jump" to availability handler as availability warning is triggered
        CreateAssemblyOrder(AssemblyHeader, Item."No.", LocationCode, '', DueDate, QtyOnAssemble);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    local procedure CreateProdOrderAndRefresh(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; DueDate: Date): Decimal
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, Quantity);

        if LocationCode <> '' then
            ProductionOrder.Validate("Location Code", LocationCode);

        // Needed for executing the validate trigger on due date
        ProductionOrder.SetUpdateEndDate();
        ProductionOrder.Validate("Due Date", DueDate);
        ProductionOrder.Modify(true);

        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        exit(Quantity);
    end;

    local procedure AddComponentToProdOrder(ProductionOrder: Record "Production Order"; ItemNo: Code[20]; VariantCode: Code[10]; QuantityPer: Decimal; LocationCode: Code[10]): Decimal
    var
        ProdOrderComponent: Record "Prod. Order Component";
        LineNo: Integer;
    begin
        Clear(ProdOrderComponent);
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");

        if ProdOrderComponent.FindLast() then
            LineNo := ProdOrderComponent."Line No." + 10000
        else
            LineNo := 10000;

        ProdOrderComponent.Validate(Status, ProductionOrder.Status);
        ProdOrderComponent.Validate("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.Validate("Line No.", LineNo);
        ProdOrderComponent.Validate("Prod. Order Line No.", 10000);
        ProdOrderComponent.Validate("Item No.", ItemNo);
        ProdOrderComponent.Validate("Variant Code", VariantCode);
        ProdOrderComponent.Validate("Location Code", LocationCode);
        ProdOrderComponent.Validate("Quantity per", QuantityPer);
        ProdOrderComponent.Insert(true);
        exit(QuantityPer);
    end;

    local procedure AddItemUOM(Item: Record Item; UOMCode: Code[10]): Decimal
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UOMCode, LibraryRandom.RandInt(5));
        exit(ItemUnitOfMeasure."Qty. per Unit of Measure");
    end;

    local procedure AddComponentUOM(var BOMComponent: Record "BOM Component"; QtyPerUOM: Integer; UOMCode: Code[10])
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, BOMComponent."No.", UOMCode, QtyPerUOM);

        BOMComponent.Validate("Unit of Measure Code", UOMCode);
        BOMComponent.Modify(true);
    end;

    local procedure CreateItemVariant(ItemNo: Code[20]): Code[10]
    var
        ItemVariant: Record "Item Variant";
    begin
        LibraryInventory.CreateItemVariant(ItemVariant, ItemNo);
        exit(ItemVariant.Code);
    end;

    local procedure CreatePurchaseDocType(var PurchaseHeader: Record "Purchase Header"; OrderType: Enum "Purchase Document Type"; ItemNo: Code[20]; VariantCode: Code[10]; PurchaseQty: Integer; LocationCode: Code[10]; ReceiptDate: Date)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        Clear(PurchaseHeader);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, OrderType, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, PurchaseQty);
        PurchaseLine.Validate("Variant Code", VariantCode);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Validate("Expected Receipt Date", ReceiptDate);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; VariantCode: Code[10]; PurchQty: Integer; LocationCode: Code[10]; ReceiptDate: Date): Integer
    begin
        CreatePurchaseDocType(PurchaseHeader, PurchaseHeader."Document Type"::Order, ItemNo, VariantCode, PurchQty, LocationCode, ReceiptDate);
        exit(PurchQty);
    end;

    local procedure CreatePurchaseReturnOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; VariantCode: Code[10]; PurchQty: Integer; LocationCode: Code[10]; ReceiptDate: Date): Integer
    begin
        CreatePurchaseDocType(
          PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", ItemNo, VariantCode, PurchQty, LocationCode, ReceiptDate);
        exit(PurchQty);
    end;

    local procedure CreateTransferOrder(var TransferHeader: Record "Transfer Header"; ItemNo: Code[20]; VariantCode: Code[10]; FromLocation: Code[10]; ToLocation: Code[10]; ReceiptDate: Date; Qty: Integer): Integer
    var
        TransferLine: Record "Transfer Line";
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocation, ToLocation, TransitLocation.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Qty);
        TransferLine.Validate("Receipt Date", ReceiptDate);
        TransferLine.Validate("Variant Code", VariantCode);
        TransferLine.Modify(true);
        exit(Qty);
    end;

    local procedure CreateSaleDocType(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; ItemNo: Code[20]; VariantCode: Code[10]; SalesQty: Integer; ShipmentDate: Date; LocationCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        Clear(SalesHeader);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, '');
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, SalesQty);
        SalesLine.Validate("Variant Code", VariantCode);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Validate("Shipment Date", ShipmentDate);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; VariantCode: Code[10]; SalesQty: Integer; ShipmentDate: Date; LocationCode: Code[10]): Integer
    begin
        CreateSaleDocType(SalesHeader, SalesHeader."Document Type"::Order, ItemNo, VariantCode, SalesQty, ShipmentDate, LocationCode);
        exit(SalesQty)
    end;

    local procedure CreateSalesReturnOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; VariantCode: Code[10]; SalesQty: Integer; LocationCode: Code[10]; ShipmentDate: Date): Integer
    begin
        CreateSaleDocType(SalesHeader, SalesHeader."Document Type"::"Return Order", ItemNo, VariantCode, SalesQty, ShipmentDate, LocationCode);
        exit(SalesQty)
    end;

    local procedure AddInventory(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; Qty: Integer)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ClearJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Qty);
        ItemJournalLine.Validate("Variant Code", VariantCode);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure FindPostedAssemblyHeaderNotReversed(var PostedAssemblyHeader: Record "Posted Assembly Header"; SourceAssemblyHeaderNo: Code[20])
    begin
        Clear(PostedAssemblyHeader);
        PostedAssemblyHeader.SetRange("Order No.", SourceAssemblyHeaderNo);
        PostedAssemblyHeader.SetRange(Reversed, false);
        PostedAssemblyHeader.FindFirst();
    end;

    local procedure ClearJournal(ItemJournalTemplate: Record "Item Journal Template"; ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        Clear(ItemJournalLine);
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalTemplate.Name);
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.DeleteAll();
    end;

    local procedure SetVariantOnComponent(var BOMComponent: Record "BOM Component"; VariantCode: Code[10])
    begin
        BOMComponent.Validate("Variant Code", VariantCode);
        BOMComponent.Modify(true);
    end;

    local procedure ChangeUOMOnAsmOrder(var AssemblyHeader: Record "Assembly Header"; UOMCode: Code[10])
    begin
        AssemblyHeader.Validate("Unit of Measure Code", UOMCode);
        AssemblyHeader.Modify(true);
    end;

    local procedure PostAssemblyOrderQty(var AssemblyHeader: Record "Assembly Header"; Qty: Decimal)
    begin
        AssemblyHeader.Validate("Quantity to Assemble", Qty);
        AssemblyHeader.Modify(true);

        CODEUNIT.Run(CODEUNIT::"Assembly-Post", AssemblyHeader);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    local procedure MinValue(Val1: Decimal; Val2: Decimal): Decimal
    begin
        if Val1 >= Val2 then
            exit(Val2);

        exit(Val1);
    end;

    local procedure RandInt(): Integer
    begin
        exit(LibraryRandom.RandInt(1000))
    end;

    local procedure RandInt5(): Integer
    begin
        exit(LibraryRandom.RandInt(5) + 1)
    end;

    local procedure AssertAvailabilityHeader(AssemblyHeader: Record "Assembly Header"; ExpAsmAvailTestBuf: Record "Asm. Availability Test Buffer")
    begin
        TempAsmAvailTestBuf.VerifyHeader(AssemblyHeader, ExpAsmAvailTestBuf);
    end;

    local procedure AssertAvailabilityHeaderStatic(AssemblyHeader: Record "Assembly Header")
    begin
        TempAsmAvailTestBuf.VerifyHeaderStatic(AssemblyHeader);
    end;

    local procedure AssertAvailabilityLine(AssemblyHeader: Record "Assembly Header"; ExpAsmAvailTestBuf: Record "Asm. Availability Test Buffer")
    var
        AssemblyLine: Record "Assembly Line";
    begin
        FindAssemblyLine(AssemblyHeader, ExpAsmAvailTestBuf."Document Line No.", AssemblyLine);
        TempAsmAvailTestBuf.VerifyLine(AssemblyLine, ExpAsmAvailTestBuf);
    end;

    local procedure AssertAvailabilityLineStatic(AssemblyHeader: Record "Assembly Header"; LineNo: Integer)
    var
        AssemblyLine: Record "Assembly Line";
    begin
        FindAssemblyLine(AssemblyHeader, LineNo, AssemblyLine);
        TempAsmAvailTestBuf.VerifyLineStatic(AssemblyLine, LineNo);
    end;

    local procedure VerifyLineGrossReqExpInv(AssemblyHeader: Record "Assembly Header"; GrossReq: Decimal; ExpInventory: Decimal)
    var
        ExpAsmAvailTestBuf: Record "Asm. Availability Test Buffer";
    begin
        ExpAsmAvailTestBuf.Init();
        ExpAsmAvailTestBuf."Document Line No." := 1;
        ExpAsmAvailTestBuf.Validate("Gross Requirement", GrossReq);
        ExpAsmAvailTestBuf.Validate("Expected Inventory", ExpInventory);
        AssertAvailabilityLine(AssemblyHeader, ExpAsmAvailTestBuf);
    end;

    local procedure VerifyHrdGrossReqSchedRcpts(AssemblyHeader: Record "Assembly Header"; GrossReq: Decimal; SchedRcpts: Decimal)
    var
        ExpAsmAvailTestBuf: Record "Asm. Availability Test Buffer";
    begin
        ExpAsmAvailTestBuf.Init();
        ExpAsmAvailTestBuf.Validate("Gross Requirement", GrossReq);
        ExpAsmAvailTestBuf.Validate("Scheduled Receipts", SchedRcpts);
        AssertAvailabilityLine(AssemblyHeader, ExpAsmAvailTestBuf);
    end;

    local procedure FindAssemblyLine(AssemblyHeader: Record "Assembly Header"; LineNo: Integer; var AssemblyLine: Record "Assembly Line")
    begin
        Clear(AssemblyLine);
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.FindSet();
        AssemblyLine.Next(LineNo - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ComponentAvailable()
    var
        Item: Record Item;
        BOMComponent: Record "BOM Component";
        AssemblyHeader: Record "Assembly Header";
        LocationCode: Code[10];
    begin
        // [FEATURE] [Component]
        // [SCENARIO 411] Component is available when assembling an Item with enough Components in inventory
        Initialize();
        LocationCode := LocationBlue.Code;
        // [GIVEN] Create the assembled Item "X"
        LibraryInventory.CreateItem(Item);
        AddComponent(Item, BOMComponent);
        // [GIVEN] The Component "C" is in inventory
        AddInventory(BOMComponent."No.", '', LocationCode, 1);

        // [WHEN] Create Assembly Order for assembling 1 pcs Item "X"
        CreateAssemblyOrder(AssemblyHeader, Item."No.", LocationCode, '', WorkDate2, 1);

        // [THEN] Component is available
        Assert.IsTrue(ComponentsAvailable(AssemblyHeader), StrSubstNo(ComponentIsNotAvailableErr, Item."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ComponentNotAvailable()
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        BOMComponent: Record "BOM Component";
        LocationCode: Code[10];
    begin
        // [FEATURE] [Component]
        // [SCENARIO 412] Component is NOT available when assembling an Item with missing Components in inventory
        Initialize();

        LocationCode := '';
        // [GIVEN] Create the assembled Item "X"
        LibraryInventory.CreateItem(Item);
        // [GIVEN] The Component "C" is NOT in inventory
        AddComponent(Item, BOMComponent);

        // [WHEN] Create Assembly Order for assembling 1 pcs Item "X"
        CreateAssemblyOrder(AssemblyHeader, Item."No.", LocationCode, '', WorkDate2, 1);

        // [THEN] Component is NOT available
        Assert.IsFalse(ComponentsAvailable(AssemblyHeader), StrSubstNo(ComponentIsAvailableErr, Item."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ComponentVariantAvailable()
    var
        Item: Record Item;
        BOMComponent1: Record "BOM Component";
        BOMComponent2: Record "BOM Component";
        AssemblyHeader: Record "Assembly Header";
        LocationCode: Code[10];
    begin
        // [FEATURE] [Component]
        // [SCENARIO 413] Components are available when assembling an Item with a Component with a Variant in inventory
        Initialize();

        LocationCode := '';
        // [GIVEN] Create the assembled Item "X" with 2 components:
        LibraryInventory.CreateItem(Item);
        // [GIVEN] 1st component with a Variant is in inventory
        AddComponent(Item, BOMComponent1);
        SetVariantOnComponent(BOMComponent1, CreateItemVariant(BOMComponent1."No."));
        AddInventory(BOMComponent1."No.", BOMComponent1."Variant Code", LocationCode, 1);
        // [GIVEN] 2nd component without a Variant is in inventory
        AddComponent(Item, BOMComponent2);
        AddInventory(BOMComponent2."No.", '', LocationCode, 1);

        // [WHEN] Create Assembly Order for assembling 1 pcs Item "X"
        CreateAssemblyOrder(AssemblyHeader, Item."No.", LocationCode, '', WorkDate2, 1);

        // [THEN] Components are available
        Assert.IsTrue(ComponentsAvailable(AssemblyHeader), StrSubstNo(ComponentIsNotAvailableErr, Item."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ComponentVariantNotAvailable()
    var
        Item: Record Item;
        BOMComponent1: Record "BOM Component";
        BOMComponent2: Record "BOM Component";
        AssemblyHeader: Record "Assembly Header";
        LocationCode: Code[10];
    begin
        // [FEATURE] [Component]
        // [SCENARIO 414] Components are NOT available when assembling an Item with a missing Component with a Variant in inventory
        Initialize();

        LocationCode := LocationBlue.Code;
        // [GIVEN] Create the assembled Item "X" with 2 components:
        LibraryInventory.CreateItem(Item);
        // [GIVEN] 1st component with a Variant is NOT in inventory
        AddComponent(Item, BOMComponent1);
        SetVariantOnComponent(BOMComponent1, CreateItemVariant(BOMComponent1."No."));
        // [GIVEN] 2nd component without a Variant is in inventory
        AddComponent(Item, BOMComponent2);
        AddInventory(BOMComponent2."No.", '', LocationCode, 1);

        // [WHEN] Create Assembly Order for assembling 1 pcs Item "X"
        CreateAssemblyOrder(AssemblyHeader, Item."No.", LocationCode, '', WorkDate2, 1);

        // [THEN] Components are NOT available
        Assert.IsFalse(ComponentsAvailable(AssemblyHeader), StrSubstNo(ComponentIsAvailableErr, Item."No."));
    end;

    [Test]
    [HandlerFunctions('ChangeLocationCodeConfirm')]
    [Scope('OnPrem')]
    procedure ChangeLocationComponentAvailable()
    var
        Item: Record Item;
        BOMComponent: Record "BOM Component";
        AssemblyHeader: Record "Assembly Header";
        LocationCodeFrom: Code[10];
        LocationCodeTo: Code[10];
    begin
        // [FEATURE] [Component]
        // [SCENARIO 416] Component is available when assembling an Item on Location with Component in inventory
        Initialize();

        LocationCodeFrom := '';
        LocationCodeTo := LocationBlue.Code;
        // [GIVEN] Create the assembled Item "X"
        LibraryInventory.CreateItem(Item);
        AddComponent(Item, BOMComponent);
        // [GIVEN] The Component is in inventory on Locations "L1" and "L2"
        AddInventory(BOMComponent."No.", '', LocationCodeFrom, 1);
        AddInventory(BOMComponent."No.", '', LocationCodeTo, 1);

        // [GIVEN] Create Assembly Order for assembling 1 pcs Item "X" on Location "L1"
        CreateAssemblyOrder(AssemblyHeader, Item."No.", LocationCodeFrom, '', WorkDate2, 1);

        // [WHEN] Change Location to "L2" on Assembly Order header
        AssemblyHeader.Validate("Location Code", LocationCodeTo);
        AssemblyHeader.Modify(true);

        // [THEN] Component is available
        Assert.IsTrue(ComponentsAvailable(AssemblyHeader), StrSubstNo(ComponentIsNotAvailableErr, Item."No."));
    end;

    [Test]
    [HandlerFunctions('ChangeLocationCodeConfirm')]
    [Scope('OnPrem')]
    procedure ChangeLocationComponentNotAvailable()
    var
        Item: Record Item;
        BOMComponent: Record "BOM Component";
        AssemblyHeader: Record "Assembly Header";
        LocationCodeFrom: Code[10];
        LocationCodeTo: Code[10];
    begin
        // [FEATURE] [Component]
        // [SCENARIO 417] Component is NOT available when assembling an Item on Location where no Component in inventory
        Initialize();

        LocationCodeFrom := LocationBlue.Code;
        LocationCodeTo := '';
        // [GIVEN] Create the assembled Item "X"
        LibraryInventory.CreateItem(Item);
        AddComponent(Item, BOMComponent);
        // [GIVEN] The Component is NOT in inventory on Location "L2"
        AddInventory(BOMComponent."No.", '', LocationCodeFrom, RandInt());

        // [GIVEN] Create Assembly Order for assembling 1 pcs Item "X" on Location "L1"
        CreateAssemblyOrder(AssemblyHeader, Item."No.", LocationCodeFrom, '', WorkDate2, 1);

        // [WHEN] Change Location to "L2" on Assembly Order header
        AssemblyHeader.Validate("Location Code", LocationCodeTo);
        AssemblyHeader.Modify(true);

        // [THEN] Component is NOT available
        Assert.IsFalse(ComponentsAvailable(AssemblyHeader), StrSubstNo(ComponentIsAvailableErr, Item."No."));
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ChangeLocationCodeConfirm(Question: Text[1024]; var Val: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, ChangeLocationQst) > 0, Question);

        Val := true;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckNotPostingNoSeries()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblySetup: Record "Assembly Setup";
    begin
        // [FEATURE] [Assembly Order] [UT]
        // [SCENARIO] Validating Posting No. Series the value should be getting from Posted Assembly Order No. field in Assembly Setup

        // [GIVEN] Create Item and Assembly Header for this item
        Initialize();
        AssemblySetup.Get();
        AssemblySetup."Posted Assembly Order Nos." := LibraryERM.CreateNoSeriesCode();
        AssemblySetup.Modify(true);
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), LibraryInventory.CreateItemNo(), '', 0, '');

        // [WHEN] Validate Posting No. Series field from Assembly Header
        AssemblyHeader.Validate("Posting No. Series", AssemblySetup."Posted Assembly Order Nos.");

        // [THEN] TestNoSeries function have to passed succesfully because of right Serial No. is transmitted into the trigger
        AssemblyHeader.TestField("Posting No. Series", AssemblySetup."Posted Assembly Order Nos.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPostedNoExist()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblySetup: Record "Assembly Setup";
    begin
        // [FEATURE] [Assembly Order] [UT]
        // [SCENARIO] Verify an error when insert Assembly Header Posted Assembly Order Nos. should not be empty

        // [GIVEN] Set Assembly Setup field to empty and create Item
        Initialize();
        AssemblySetup.Get();
        AssemblySetup."Posted Assembly Order Nos." := '';
        AssemblySetup.Modify(true);

        // [WHEN] Insert Assembly Header
        asserterror LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), LibraryInventory.CreateItemNo(), '', 0, '');

        // [THEN] Error in testing field Posting No. Series is expected
        Assert.ExpectedTestFieldError(AssemblySetup.FieldCaption("Posted Assembly Order Nos."), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartialPostingComponentAvailable()
    var
        Item: Record Item;
        BOMComponent: Record "BOM Component";
        AssemblyHeader: Record "Assembly Header";
        LocationCode: Code[10];
        QtyOnInventory: Integer;
    begin
        // [FEATURE] [Component]
        // [SCENARIO 418] Component is available after posting part of Assembly Order with Component in inventory
        Initialize();

        LocationCode := '';
        // [GIVEN] Create the assembled Item "X" with one component in inventory. Quantity = "Q"
        QtyOnInventory := CreateItemWithComponentInventory(Item, BOMComponent, LocationCode);
        // [GIVEN] Create Assembly Order for assembling 2 pcs Items "X"
        CreateAssemblyOrder(AssemblyHeader, Item."No.", LocationCode, '', WorkDate2, QtyOnInventory - 1);

        // [WHEN] Post Assembly Order with "Quantity To Assemble" = 1
        PostAssemblyOrderQty(AssemblyHeader, 1);

        // [THEN] Component is available
        Assert.IsTrue(ComponentsAvailable(AssemblyHeader), StrSubstNo(ComponentIsNotAvailableErr, Item."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartialPostingComponentNotAvailable()
    var
        Item: Record Item;
        BOMComponent: Record "BOM Component";
        AssemblyHeader: Record "Assembly Header";
        LocationCode: Code[10];
        QtyOnInventory: Integer;
    begin
        // [FEATURE] [Component]
        // [SCENARIO 419] Component is NOT available after posting part of Assembly Order with not enough Component in inventory
        Initialize();

        LocationCode := LocationBlue.Code;
        // [GIVEN] Create the assembled Item "X" with one component in inventory. Quantity = "Q"
        QtyOnInventory := CreateItemWithComponentInventory(Item, BOMComponent, LocationCode);
        // [GIVEN] Create Assembly Order for assembling "Q" + 1 pcs Items "X"
        CreateAssemblyOrder(AssemblyHeader, Item."No.", LocationCode, '', WorkDate2, QtyOnInventory + 1);

        // [WHEN] Post Assembly Order with "Quantity To Assemble" = 1
        PostAssemblyOrderQty(AssemblyHeader, 1);

        // [THEN] Component is NOT available
        Assert.IsFalse(ComponentsAvailable(AssemblyHeader), StrSubstNo(ComponentIsAvailableErr, Item."No."));
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,SendAssemblyAvailabilityNotificationHandler')]
    [Scope('OnPrem')]
    procedure AbleToAssembleMissingInventory()
    var
        Item: Record Item;
        BOMComponent: Record "BOM Component";
        AssemblyHeader: Record "Assembly Header";
        QtyOnInventory: Integer;
        QtyOnAssemble: Integer;
        QtyAssembled: Integer;
        LocationCode: Code[10];
    begin
        // [FEATURE] [Component]
        // [SCENARIO 421] "Able To Assemble" is equal to Component's quantity in inventory when "Quantity To Assemble" is bigger
        Initialize();

        LocationCode := LocationBlue.Code;
        // [GIVEN] Create the assembled Item "X" with one component in inventory. Quantity = "Q"
        QtyOnInventory := CreateItemWithComponentInventory(Item, BOMComponent, LocationCode);

        // [WHEN] Create Assembly Order for assembling "Q" + 1 pcs Items "X"
        QtyOnAssemble := QtyOnInventory + 1;
        CreateAssemblyOrder(AssemblyHeader, Item."No.", LocationCode, '', WorkDate2, QtyOnAssemble);

        // [THEN] Assembly Availability page is shown:
        // [THEN] "Able To Assemble" = "Q" on page header
        // [THEN] "Able To Assemble" = "Q" and "Expected Inventory" = "Q" in page line
        VerifyAsmAvailMissingInventory(AssemblyHeader, QtyOnInventory, 0);

        // [GIVEN] Post Assembly Order with "Quantity To Assemble" = 1 pcs
        QtyAssembled := 1;
        PostAssemblyOrderQty(AssemblyHeader, QtyAssembled);

        // [WHEN] Show Assembly Availability
        AssemblyHeader.ShowAvailability();

        // [THEN] Assembly Availability page shows:
        // [THEN] "Able To Assemble" = "Q" - 1, "Inventory" = 1 on page header
        // [THEN] "Able To Assemble" = "Q" - 1 and "Expected Inventory" = "Q" - 1 in page line
        VerifyAsmAvailMissingInventory(AssemblyHeader, QtyOnInventory - QtyAssembled, QtyAssembled);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure AbleToAssembleEnoughInventory()
    var
        Item: Record Item;
        BOMComponent: Record "BOM Component";
        AssemblyHeader: Record "Assembly Header";
        QtyOnInventory: Integer;
        QtyOnAssemble: Integer;
        QtyAssembled: Integer;
        LocationCode: Code[10];
    begin
        // [FEATURE] [Component]
        // [SCENARIO 421] "Able To Assemble" is equal to "Quantity To Assemble" when enough Component's quantity in inventory
        Initialize();

        LocationCode := LocationBlue.Code;
        // [GIVEN] Create the assembled Item "X" with one component in inventory. Quantity = "Q"
        QtyOnInventory := CreateItemWithComponentInventory(Item, BOMComponent, LocationCode);
        // [GIVEN] Create Assembly Order for assembling "Q" - 1 pcs of Item "X"
        QtyOnAssemble := QtyOnInventory - 1;
        CreateAssemblyOrder(AssemblyHeader, Item."No.", LocationCode, '', WorkDate2, QtyOnAssemble);

        // [WHEN] Show Assembly Availability
        AssemblyHeader.ShowAvailability();

        // [THEN] Assembly Availability page shows:
        // [THEN] "Able To Assemble" = "Q" - 1 on page header
        // [THEN] "Able To Assemble" = "Q" - 1 and "Expected Inventory" = "Q" in page line
        VerifyAsmAvailEnoughInventory(AssemblyHeader, QtyOnInventory, QtyOnAssemble, 0);

        // [GIVEN] Post Assembly Order with "Quantity To Assemble" = 1 pcs
        QtyAssembled := 1;
        PostAssemblyOrderQty(AssemblyHeader, QtyAssembled);

        // [WHEN] Show Assembly Availability
        AssemblyHeader.ShowAvailability();

        // [THEN] Assembly Availability page shows:
        // [THEN] "Able To Assemble" = "Q" - 2, "Inventory" = 1 on page header
        // [THEN] "Able To Assemble" = "Q" - 2, "Expected Inventory" = "Q" - 1 in page line
        VerifyAsmAvailEnoughInventory(AssemblyHeader, QtyOnInventory, QtyOnAssemble, QtyAssembled);
    end;

    local procedure VerifyAsmAvailMissingInventory(AssemblyHeader: Record "Assembly Header"; QtyOnInventory: Integer; QtyAssembled: Integer)
    var
        ExpAsmAvailTestBuf: Record "Asm. Availability Test Buffer";
    begin
        ExpAsmAvailTestBuf.Init();
        ExpAsmAvailTestBuf.Validate("Able To Assemble", QtyOnInventory);
        ExpAsmAvailTestBuf.Validate(Inventory, QtyAssembled);
        AssertAvailabilityHeader(AssemblyHeader, ExpAsmAvailTestBuf);

        ExpAsmAvailTestBuf.Init();
        ExpAsmAvailTestBuf."Document Line No." := 1;
        ExpAsmAvailTestBuf.Validate("Expected Inventory", QtyOnInventory);
        ExpAsmAvailTestBuf.Validate("Able To Assemble", QtyOnInventory);
        AssertAvailabilityLine(AssemblyHeader, ExpAsmAvailTestBuf);
    end;

    local procedure VerifyAsmAvailEnoughInventory(AssemblyHeader: Record "Assembly Header"; QtyOnInventory: Integer; QtyOnAssemble: Integer; QtyAssembled: Integer)
    var
        ExpAsmAvailTestBuf: Record "Asm. Availability Test Buffer";
    begin
        ExpAsmAvailTestBuf.Init();
        ExpAsmAvailTestBuf.Validate("Able To Assemble", QtyOnAssemble - QtyAssembled);
        ExpAsmAvailTestBuf.Validate(Inventory, QtyAssembled);
        AssertAvailabilityHeader(AssemblyHeader, ExpAsmAvailTestBuf);

        ExpAsmAvailTestBuf.Init();
        ExpAsmAvailTestBuf."Document Line No." := 1;
        ExpAsmAvailTestBuf.Validate("Expected Inventory", QtyOnInventory - QtyAssembled);
        ExpAsmAvailTestBuf.Validate("Able To Assemble", QtyOnAssemble - QtyAssembled);
        AssertAvailabilityLine(AssemblyHeader, ExpAsmAvailTestBuf);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,SendAssemblyAvailabilityNotificationHandler')]
    [Scope('OnPrem')]
    procedure InventoryOnHeaderOneLocation()
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        ExpAsmAvailTestBuf: Record "Asm. Availability Test Buffer";
        BOMComponent: Record "BOM Component";
        QtyInInventory: Integer;
        LocationCode: Code[10];
    begin
        // [FEATURE] [Assembled Item]
        // [SCENARIO 422] Assembly Availability page: Header's "Inventory" is equal to assembled Item's inventory
        Initialize();

        LocationCode := '';
        // [GIVEN] Create the assembled Item "X"
        LibraryInventory.CreateItem(Item);
        // [GIVEN] Component is NOT in inventory
        AddComponent(Item, BOMComponent);
        // [GIVEN] Item "X" is in inventory. Quantity = "Q"
        QtyInInventory := RandInt();
        AddInventory(Item."No.", '', LocationCode, QtyInInventory);

        // [WHEN] Create Assembly Order for assembling Item "X"
        CreateAssemblyOrder(AssemblyHeader, Item."No.", LocationCode, '', WorkDate2, 1);

        // [THEN] Assembly Availability page is shown: "Inventory" = "Q" on page header
        ExpAsmAvailTestBuf.Init();
        ExpAsmAvailTestBuf.Validate(Inventory, QtyInInventory);
        AssertAvailabilityHeader(AssemblyHeader, ExpAsmAvailTestBuf);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,SendAssemblyAvailabilityNotificationHandler')]
    [Scope('OnPrem')]
    procedure InventoryOnHeaderTwoLocations()
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        ExpAsmAvailTestBuf: Record "Asm. Availability Test Buffer";
        BOMComponent: Record "BOM Component";
        QtyOnInventory: Integer;
        LocationCode1: Code[10];
        LocationCode2: Code[10];
    begin
        // [FEATURE] [Assembled Item]
        // [SCENARIO 423] Assembly Availability page: Header's "Inventory" is equal to assembled Item's inventory on Assembly Orders' Location
        Initialize();

        LocationCode1 := LocationBlue.Code;
        LocationCode2 := '';
        // [GIVEN] Create the assembled Item "X"
        LibraryInventory.CreateItem(Item);
        // [GIVEN] Component is NOT in inventory
        AddComponent(Item, BOMComponent);
        QtyOnInventory := RandInt();
        // [GIVEN] Item "X" is in inventory on Location "L1". Quantity = "Q1"
        AddInventory(Item."No.", '', LocationCode1, QtyOnInventory);
        // [GIVEN] Item "X" is in inventory on Location "L2". Quantity = "Q2"
        AddInventory(Item."No.", '', LocationCode2, QtyOnInventory + 1);

        // [WHEN] Create Assembly Order for assembling Item "X" on Location "L1"
        CreateAssemblyOrder(AssemblyHeader, Item."No.", LocationCode1, '', WorkDate2, 1);

        // [THEN] Assembly Availability page is shown: "Inventory" = "Q1" on page header
        ExpAsmAvailTestBuf.Init();
        ExpAsmAvailTestBuf.Validate(Inventory, QtyOnInventory);
        AssertAvailabilityHeader(AssemblyHeader, ExpAsmAvailTestBuf);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,SendAssemblyAvailabilityNotificationHandler')]
    [Scope('OnPrem')]
    procedure InventoryOnHeaderItemVariant()
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        ExpAsmAvailTestBuf: Record "Asm. Availability Test Buffer";
        BOMComponent: Record "BOM Component";
        ItemVariantCode: Code[10];
        QtyOnInventory: Integer;
        LocationCode: Code[10];
    begin
        // [FEATURE] [Assembled Item]
        // [SCENARIO 424] Assembly Availability page: Header's "Inventory" is equal to assembled Item Variant's inventory
        Initialize();

        LocationCode := '';
        // [GIVEN] Create the assembled Item "X" with Variant
        LibraryInventory.CreateItem(Item);
        ItemVariantCode := CreateItemVariant(Item."No.");
        // [GIVEN] Component is NOT in inventory
        AddComponent(Item, BOMComponent);
        // [GIVEN] Item "X" is in inventory. Quantity = "Q1"
        QtyOnInventory := RandInt();
        AddInventory(Item."No.", '', LocationCode, QtyOnInventory + 1);
        // [GIVEN] Item "X" with Variant is in inventory. Quantity = "Q2"
        AddInventory(Item."No.", ItemVariantCode, LocationCode, QtyOnInventory);

        // [WHEN] Create Assembly Order for assembling Item "X" with Variant
        CreateAssemblyOrder(AssemblyHeader, Item."No.", LocationCode, ItemVariantCode, WorkDate2, 1);

        // [THEN] Assembly Availability page is shown: "Inventory" = "Q2" on page header
        ExpAsmAvailTestBuf.Init();
        ExpAsmAvailTestBuf.Validate(Inventory, QtyOnInventory);
        AssertAvailabilityHeader(AssemblyHeader, ExpAsmAvailTestBuf);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('AvailabilityWindowHandler')]
    procedure InventoryOnHeaderIncreasedByPost()
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        BOMComponent: Record "BOM Component";
        ItemInventory: Integer;
        CompInventory: Integer;
        QtyOnAssemble: Integer;
        QtyAssembled: Integer;
        LocationCode: Code[10];
    begin
        // [FEATURE] [Assembled Item]
        // [SCENARIO 425] Assembly Availability page: Header's "Inventory" is increased by Assembly Order's partial posting
        Initialize();

        LocationCode := LocationBlue.Code;
        // [GIVEN] Create the assembled Item "X"
        LibraryInventory.CreateItem(Item);
        AddComponent(Item, BOMComponent);
        // [GIVEN] Item "X" is in inventory. Quantity = "Q1"
        ItemInventory := RandInt();
        AddInventory(Item."No.", '', LocationCode, ItemInventory);
        // [GIVEN] Component is in inventory. Quantity = "Q2"
        CompInventory := RandInt();
        AddInventory(BOMComponent."No.", '', LocationCode, CompInventory);
        // [GIVEN] Create Assembly Order for assembling "Q3" pcs of Item "X" missing 1 pcs of Component
        QtyOnAssemble := CompInventory + 1;
        CreateAssemblyOrder(AssemblyHeader, Item."No.", LocationCode, '', WorkDate2, QtyOnAssemble);
        // [GIVEN] Post Assembly Order partially, "Quantity To Assemble" = "QA"
        QtyAssembled := 1;
        PostAssemblyOrderQty(AssemblyHeader, QtyAssembled);

        // [WHEN] Show Assembly Availability
        AssemblyHeader.ShowAvailability();

        // [THEN] Assembly Availability page shows:
        // [THEN] "Inventory" = "Q1" + "QA", "Able To Assemble" = "Q2" - "QA"
        VerifyAsmAvailMissingInventory(AssemblyHeader, CompInventory - QtyAssembled, ItemInventory + QtyAssembled);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,SendAssemblyAvailabilityNotificationHandler')]
    [Scope('OnPrem')]
    procedure EarliestAvailDateNoFutureDocs()
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        BOMComponent1: Record "BOM Component";
        BOMComponent2: Record "BOM Component";
        QtyOnAssemble: Integer;
        LocationCode: Code[10];
    begin
        // [FEATURE] [Assembled Item]
        // [SCENARIO 426] "Earliest Availability Date" is empty when no documents that add missing inventory in future
        Initialize();

        LocationCode := '';
        // [GIVEN] Create the assembled Item "X" with two components: "C1" and "C2"
        LibraryInventory.CreateItem(Item);
        AddComponent(Item, BOMComponent1);
        AddComponent(Item, BOMComponent2);

        // [GIVEN] Component "C1" is in inventory. Quantity = "Q"
        QtyOnAssemble := RandInt();
        AddInventory(BOMComponent1."No.", '', LocationCode, QtyOnAssemble);
        // [GIVEN] Component "C2" is in inventory. Quantity = "Q" - 1
        AddInventory(BOMComponent2."No.", '', LocationCode, QtyOnAssemble - 1);

        // [WHEN] Create Assembly Order for assembling "Q" pcs of Item "X"
        CreateAssemblyOrder(AssemblyHeader, Item."No.", LocationCode, '', WorkDate2, QtyOnAssemble);

        // [THEN] Asm. Avail. "Earliest Availability Date" is empty in header and lines
        VerifyEmptyEarliestAvailDate(AssemblyHeader);

        // [GIVEN] Add missing inventory for Component "C2"
        AddInventory(BOMComponent2."No.", '', LocationCode, 1);
        // [WHEN] Show Assembly Availability
        AssemblyHeader.ShowAvailability();

        // [THEN] Asm. Avail. "Earliest Availability Date" is empty in header and lines
        VerifyEmptyEarliestAvailDate(AssemblyHeader);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    local procedure VerifyEmptyEarliestAvailDate(AssemblyHeader: Record "Assembly Header")
    var
        ExpAsmAvailTestBuf: Record "Asm. Availability Test Buffer";
    begin
        ExpAsmAvailTestBuf.Init();
        ExpAsmAvailTestBuf.Validate("Earliest Availability Date", 0D);
        AssertAvailabilityHeader(AssemblyHeader, ExpAsmAvailTestBuf);
        ExpAsmAvailTestBuf."Document Line No." := 1;
        AssertAvailabilityLine(AssemblyHeader, ExpAsmAvailTestBuf);
        ExpAsmAvailTestBuf."Document Line No." := 2;
        AssertAvailabilityLine(AssemblyHeader, ExpAsmAvailTestBuf);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,SendAssemblyAvailabilityNotificationHandler')]
    [Scope('OnPrem')]
    procedure AbleToAssembleMissingComponent()
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        BOMComponent1: Record "BOM Component";
        BOMComponent2: Record "BOM Component";
        ItemVariant: Record "Item Variant";
        QtyOnAssemble: Integer;
        LocationCode1: Code[10];
        LocationCode2: Code[10];
    begin
        // [FEATURE] [Component]
        // [SCENARIO 427] "Able To Assemble" is increased when added missing inventory for one of components
        Initialize();

        LocationCode1 := '';
        LocationCode2 := LocationBlue.Code;
        // [GIVEN] Create the assembled Item "X" with two components: "C1" and "C2"
        LibraryInventory.CreateItem(Item);
        AddComponent(Item, BOMComponent1);
        AddComponent(Item, BOMComponent2);
        // [GIVEN] Component "C1" is in inventory on Location "L1". Quantity = "Q"
        QtyOnAssemble := RandInt();
        AddInventory(BOMComponent1."No.", '', LocationCode1, QtyOnAssemble);
        // [GIVEN] Component "C2" is NOT in inventory on Location "L1"
        AddInventory(BOMComponent2."No.", '', LocationCode2, RandInt());
        // [GIVEN] Component "C2" is in inventory for Variant and on Location "L2"
        LibraryInventory.CreateItemVariant(ItemVariant, BOMComponent2."No.");
        AddInventory(BOMComponent2."No.", ItemVariant.Code, LocationCode2, RandInt());
        AddInventory(BOMComponent2."No.", ItemVariant.Code, LocationCode1, RandInt());

        // [WHEN] Create Assembly Order for assembling "Q" pcs of Item "X" on Location "L1"
        CreateAssemblyOrder(AssemblyHeader, Item."No.", LocationCode1, '', WorkDate2, QtyOnAssemble);

        // [THEN] Assembly Availability page is shown: "Able To Assemble" = 0 due to missed Component "C2"
        // [THEN] "Able To Assemble" = 0 in line for Component "C2"
        VerifySecondComponentAvailability(AssemblyHeader, 0);

        // [GIVEN] Add missing inventory for Component "C2" on Location "L1"
        AddInventory(BOMComponent2."No.", '', LocationCode1, QtyOnAssemble);

        // [WHEN] Show Assembly Availability
        AssemblyHeader.ShowAvailability();

        // [THEN] Assembly Availability page shows: "Able To Assemble" = "Q"
        // [THEN] "Able To Assemble" = "Q" in line for Component "C2"
        VerifySecondComponentAvailability(AssemblyHeader, QtyOnAssemble);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    local procedure VerifySecondComponentAvailability(AssemblyHeader: Record "Assembly Header"; ExpectedQuantity: Decimal)
    var
        ExpAsmAvailTestBuf: Record "Asm. Availability Test Buffer";
    begin
        ExpAsmAvailTestBuf.Init();
        ExpAsmAvailTestBuf.Validate("Earliest Availability Date", 0D);
        ExpAsmAvailTestBuf.Validate("Able To Assemble", ExpectedQuantity);
        AssertAvailabilityHeader(AssemblyHeader, ExpAsmAvailTestBuf);
        ExpAsmAvailTestBuf."Document Line No." := 2;
        ExpAsmAvailTestBuf.Validate("Expected Inventory", ExpectedQuantity);
        ExpAsmAvailTestBuf.Validate("Able To Assemble", ExpectedQuantity);
        AssertAvailabilityLine(AssemblyHeader, ExpAsmAvailTestBuf);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,SendAssemblyAvailabilityNotificationHandler')]
    [Scope('OnPrem')]
    procedure EarliestAvailDateProductOrders()
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        BOMComponent: Record "BOM Component";
        CompQuantity: Integer;
        LocationCode1: Code[10];
        LocationCode2: Code[10];
    begin
        // [FEATURE] [Component]
        // [SCENARIO 428] "Earliest Availability Date" shows date of the first Production Order that adds missing inventory
        Initialize();

        LocationCode1 := LocationBlue.Code;
        LocationCode2 := '';
        // [GIVEN] Create the assembled Item "X" with one component in inventory on Location "L1"
        CompQuantity := CreateItemWithComponentInventory(Item, BOMComponent, LocationCode1);
        // [GIVEN] Create three future released Production Orders: +9D on "L2", +10D on "L1", +11D on "L1"
        CreateProdOrderAndRefresh(ProductionOrder, BOMComponent."No.", RandInt(), LocationCode2, WorkDate10D - 1);
        CreateProdOrderAndRefresh(ProductionOrder, BOMComponent."No.", RandInt(), LocationCode1, WorkDate10D);
        CreateProdOrderAndRefresh(ProductionOrder, BOMComponent."No.", RandInt(), LocationCode1, WorkDate10D + 1);

        // [WHEN] Create Assembly Order for assembling "Q" + 1 pcs of Item "X" on Location "L1"
        CreateAssemblyOrder(AssemblyHeader, Item."No.", LocationCode1, '', WorkDate2, CompQuantity + 1);

        // [THEN] Assembly Availability page shows in Header and Line: "Earliest Availability Date" = +10D, "Able To Assemble" = "Q"
        VerifyEarliestAvailDate(AssemblyHeader, CompQuantity, WorkDate10D);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,SendAssemblyAvailabilityNotificationHandler')]
    [Scope('OnPrem')]
    procedure EarliestAvailDatePurchOrders()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        AssemblyHeader: Record "Assembly Header";
        BOMComponent: Record "BOM Component";
        CompQuantity: Integer;
        LocationCode1: Code[10];
        LocationCode2: Code[10];
    begin
        // [FEATURE] [Component]
        // [SCENARIO 429] "Earliest Availability Date" shows date of the first Purchase Order that adds missing inventory
        Initialize();

        LocationCode1 := '';
        LocationCode2 := LocationBlue.Code;
        // [GIVEN] Create the assembled Item "X" with one component in inventory on Location "L1"
        CompQuantity := CreateItemWithComponentInventory(Item, BOMComponent, LocationCode1);
        // [GIVEN] Create three future Purchase Orders : +9D on "L2", +10D on "L1", +11D on "L1"
        CreatePurchaseOrder(PurchaseHeader, BOMComponent."No.", '', RandInt(), LocationCode2, WorkDate10D - 1);
        CreatePurchaseOrder(PurchaseHeader, BOMComponent."No.", '', RandInt(), LocationCode1, WorkDate10D);
        CreatePurchaseOrder(PurchaseHeader, BOMComponent."No.", '', RandInt(), LocationCode1, WorkDate10D + 1);

        // [WHEN] Create Assembly Order for assembling "Q" + 1 pcs of Item "X" on Location "L1"
        CreateAssemblyOrder(AssemblyHeader, Item."No.", LocationCode1, '', WorkDate2, CompQuantity + 1);

        // [THEN] Assembly Availability page shows in Header and Line: "Earliest Availability Date" = +10D, "Able To Assemble" = "Q"
        VerifyEarliestAvailDate(AssemblyHeader, CompQuantity, WorkDate10D);
    end;

    local procedure CreateItemWithComponentInventory(var Item: Record Item; var BOMComponent: Record "BOM Component"; LocationCode: Code[10]) CompQuantity: Decimal
    begin
        LibraryInventory.CreateItem(Item);
        AddComponent(Item, BOMComponent);
        CompQuantity := RandInt();
        AddInventory(BOMComponent."No.", '', LocationCode, CompQuantity);
    end;

    local procedure VerifyEarliestAvailDate(AssemblyHeader: Record "Assembly Header"; ExpectedQuantity: Decimal; EarliestDate: Date)
    var
        ExpAsmAvailTestBuf: Record "Asm. Availability Test Buffer";
    begin
        ExpAsmAvailTestBuf.Init();
        ExpAsmAvailTestBuf.Validate("Able To Assemble", ExpectedQuantity);
        ExpAsmAvailTestBuf.Validate("Earliest Availability Date", CalcSafeDate(EarliestDate));
        AssertAvailabilityHeader(AssemblyHeader, ExpAsmAvailTestBuf);

        ExpAsmAvailTestBuf."Document Line No." := 1;
        ExpAsmAvailTestBuf.Validate("Expected Inventory", ExpectedQuantity);
        ExpAsmAvailTestBuf.Validate("Earliest Availability Date", EarliestDate);
        AssertAvailabilityLine(AssemblyHeader, ExpAsmAvailTestBuf);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,SendAssemblyAvailabilityNotificationHandler')]
    [Scope('OnPrem')]
    procedure FutureReservationCausesAvailWarning()
    var
        AssemblyHeader: Record "Assembly Header";
        CompanyInfo: Record "Company Information";
        LateAssemblyHeader: Record "Assembly Header";
        LateAssemblyLine: Record "Assembly Line";
        ExpAsmAvailTestBuf: Record "Asm. Availability Test Buffer";
        BOMComponentNo: Code[20];
        AbleToAsmQty: Decimal;
        DateWithinCheckAvailPeriod: Date;
        ReservedQty: Decimal;
    begin
        // [FEATURE] [Check-Avail. period]
        // [SCENARIO 360419] Future Asm. Order with reservation causes Availability warning
        Initialize();

        // [GIVEN] Have a Component Item of an Assembly Item in inventory. Qty = Q
        // [GIVEN] Create an Assembly Order AO2 within Check-Avail. period with Qty = Q2, where (Q2 < Q)
        CompanyInfo.Get();
        DateWithinCheckAvailPeriod := CalcDate(CompanyInfo."Check-Avail. Period Calc.", WorkDate2);
        AbleToAsmQty :=
          -CreateAssemblyOrderMissingInventory(LateAssemblyHeader, BOMComponentNo, DateWithinCheckAvailPeriod, LocationBlue.Code, true);
        // [GIVEN] Reserve half of the Assembly Order AO2
        ReservedQty := AutoReserveHalfFirstAsmLine(LateAssemblyHeader, LateAssemblyLine);
        // [GIVEN] Create an Assembly Order AO1 on Working Date with Qty = 0
        CreateAssemblyOrder(AssemblyHeader, LateAssemblyHeader."Item No.", LateAssemblyHeader."Location Code", '', WorkDate2, 0);

        // [WHEN] Set Qty = Q1 on Assembly Order AO1, where (Q1 < Q) but bigger than remaining inventory (Q1 > Q - Q2)
        AssemblyHeader.Validate(Quantity, AbleToAsmQty * 3);
        AssemblyHeader.Modify();
        Commit();

        AssemblyHeader.ShowAvailability();

        // [THEN] Availability warning page shows: "Able To Assemble" = (Q - Q2) decreased by the Asm. Order AO2
        ExpAsmAvailTestBuf.Init();
        ExpAsmAvailTestBuf.Validate("Able To Assemble", AbleToAsmQty);
        AssertAvailabilityHeader(AssemblyHeader, ExpAsmAvailTestBuf);
        // [THEN] "Gross requirement" = not reserved Qty of the Asm. Order AO2
        // [THEN] "Expected Inventory" is not affected by the reservation on the Asm. Order AO2
        VerifyLineGrossReqExpInv(AssemblyHeader, LateAssemblyLine."Remaining Quantity (Base)" - ReservedQty, AbleToAsmQty);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('AvailabilityWindowHandler')]
    procedure AbleToAsmNotAffectedByReservation()
    var
        AssemblyHeader: Record "Assembly Header";
        CompanyInfo: Record "Company Information";
        LateAssemblyHeader: Record "Assembly Header";
        LateAssemblyLine: Record "Assembly Line";
        ExpAsmAvailTestBuf: Record "Asm. Availability Test Buffer";
        BOMComponentNo: Code[20];
        AbleToAsmQty: Decimal;
        DateWithinCheckAvailPeriod: Date;
    begin
        // [FEATURE] [Check-Avail. period]
        // [SCENARIO 360419] Reservation on Asm.Order does not affect "Able To Assemble"
        Initialize();

        // [GIVEN] Have a Component Item of an Assembly Item in inventory. Qty = Q
        // [GIVEN] Create an Assembly Order AO2 within Check-Avail. period with Qty = Q2, where (Q2 < Q)
        CompanyInfo.Get();
        DateWithinCheckAvailPeriod := GetEndDateOfCheckAvailPeriod(CalcDate(CompanyInfo."Check-Avail. Period Calc.", WorkDate2));
        AbleToAsmQty :=
          -CreateAssemblyOrderMissingInventory(LateAssemblyHeader, BOMComponentNo, DateWithinCheckAvailPeriod, LocationBlue.Code, true);
        // [GIVEN] Reserve half of the Assembly Order AO2
        AutoReserveHalfFirstAsmLine(LateAssemblyHeader, LateAssemblyLine);
        // [GIVEN] Create an Assembly Order AO1 on Working Date with Qty = Q1, where (Q1 < Q) but bigger than remaining inventory (Q1 > Q - Q2)
        CreateAssemblyOrder(
          AssemblyHeader, LateAssemblyHeader."Item No.", LateAssemblyHeader."Location Code", '', WorkDate2, AbleToAsmQty * 3);

        // [WHEN] Show Availability for reserved Assembly Order AO2
        LateAssemblyHeader.ShowAvailability();

        // [THEN] Availability page shows "Able To Assemble" = (Q - Q1) decreased by the Asm. Order AO1
        ExpAsmAvailTestBuf.Init();
        ExpAsmAvailTestBuf.Validate("Able To Assemble", LateAssemblyHeader.Quantity + AbleToAsmQty - AssemblyHeader.Quantity);
        ExpAsmAvailTestBuf.Validate("Scheduled Receipts", AssemblyHeader.Quantity);
        AssertAvailabilityHeader(LateAssemblyHeader, ExpAsmAvailTestBuf);
        // [THEN] "Gross requirement" = full Qty of the Asm. Order AO1 regardless of reservation
        // [THEN] "Expected Inventory" is not affected by the reservation on the Asm. Order AO2
        VerifyLineGrossReqExpInv(
          LateAssemblyHeader, AssemblyHeader.Quantity, LateAssemblyHeader.Quantity + AbleToAsmQty - AssemblyHeader.Quantity);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    local procedure AutoReserveHalfFirstAsmLine(AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line"): Decimal
    var
        ReservMgt: Codeunit "Reservation Management";
        FullAutoReservation: Boolean;
    begin
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.FindFirst();
        ReservMgt.SetReservSource(AssemblyLine);
        ReservMgt.AutoReserve(
          FullAutoReservation, '', AssemblyLine."Due Date",
          AssemblyLine."Remaining Quantity" div 2, AssemblyLine."Remaining Quantity (Base)" div 2);
        exit(AssemblyLine."Remaining Quantity (Base)" div 2);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('AvailabilityWindowHandler')]
    procedure EarliestAvailDateTransfers()
    var
        AssemblyHeader: Record "Assembly Header";
        BOMComponent: Record "BOM Component";
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        ExpAsmAvailTestBuf: Record "Asm. Availability Test Buffer";
        CompQuantity: Integer;
        MissedQty: Integer;
        QtyToTransfer: Decimal;
        RestoringTransferDate: Date;
    begin
        // [FEATURE] [Check-Avail. period]
        // [SCENARIO 360072] Assembly Availability page takes future requirements into account
        Initialize();

        // [GIVEN] Create the assembled Item "X" with one component in inventory
        CompQuantity := CreateItemWithComponentInventory(Item, BOMComponent, LocationBlue.Code);
        MissedQty := CompQuantity div 7;
        // [GIVEN] Create Assembly Order for assembling "Q" + 1 pcs of Item "X"
        CreateAssemblyOrder(AssemblyHeader, Item."No.", LocationBlue.Code, '', WorkDate2, CompQuantity + MissedQty);
        // [GIVEN] Decrease inventory on next day by Transfer to another location
        QtyToTransfer := (AssemblyHeader.Quantity - MissedQty) div 2;
        CreateTransferOrder(
          TransferHeader, BOMComponent."No.", '', LocationBlue.Code, LocationRed.Code, AssemblyHeader."Due Date" + 1, QtyToTransfer);
        // [GIVEN] Restore required inventory by transfering back in the next Check-Avail. period
        RestoringTransferDate := GetEndDateOfCheckAvailPeriod(AssemblyHeader."Due Date") + 1;
        CreateTransferOrder(
          TransferHeader, BOMComponent."No.", '', LocationRed.Code, LocationBlue.Code, RestoringTransferDate, QtyToTransfer + MissedQty);

        // [WHEN] Show Availability for Assembly Order
        AssemblyHeader.ShowAvailability();

        // [THEN] Verify Availability page:
        // [THEN] "Able To Assemble" decreased by the first transfer
        // [THEN] "Earliest Availability Date" is the receipt date of the second transfer
        ExpAsmAvailTestBuf.Init();
        ExpAsmAvailTestBuf.Validate("Able To Assemble", AssemblyHeader.Quantity - MissedQty - QtyToTransfer);
        ExpAsmAvailTestBuf.Validate("Earliest Availability Date", CalcSafeDate(RestoringTransferDate));
        AssertAvailabilityHeader(AssemblyHeader, ExpAsmAvailTestBuf);

        ExpAsmAvailTestBuf."Document Line No." := 1;
        ExpAsmAvailTestBuf.Validate("Gross Requirement", QtyToTransfer);
        ExpAsmAvailTestBuf.Validate("Expected Inventory", AssemblyHeader.Quantity - MissedQty - QtyToTransfer);
        ExpAsmAvailTestBuf.Validate("Able To Assemble", AssemblyHeader.Quantity - MissedQty - QtyToTransfer);
        ExpAsmAvailTestBuf.Validate("Earliest Availability Date", RestoringTransferDate);
        AssertAvailabilityLine(AssemblyHeader, ExpAsmAvailTestBuf);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    local procedure GetEndDateOfCheckAvailPeriod(Date: Date): Date
    var
        CompanyInfo: Record "Company Information";
        AvailableToPromise: Codeunit "Available to Promise";
    begin
        CompanyInfo.Get();
        exit(AvailableToPromise.GetPeriodEndingDate(Date + 1, CompanyInfo."Check-Avail. Time Bucket"));
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,SendAssemblyAvailabilityNotificationHandler')]
    [Scope('OnPrem')]
    procedure EarliestAvailDateSalesRetOrders()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        AssemblyHeader: Record "Assembly Header";
        BOMComponent: Record "BOM Component";
        CompQuantity: Integer;
        LocationCode1: Code[10];
        LocationCode2: Code[10];
    begin
        // [FEATURE] [Component]
        // [SCENARIO 4211] "Earliest Availability Date" shows date of the first Sales Returning Order that adds missing inventory
        Initialize();

        LocationCode1 := LocationBlue.Code;
        LocationCode2 := '';
        // [GIVEN] Create the assembled Item "X" with one component in inventory on Location "L1"
        CompQuantity := CreateItemWithComponentInventory(Item, BOMComponent, LocationCode1);
        // [GIVEN] Create three future Sales Return Orders: +9D on "L2", +10D on "L1", +11D on "L1"
        CreateSalesReturnOrder(SalesHeader, BOMComponent."No.", '', RandInt(), LocationCode2, WorkDate10D - 1);
        CreateSalesReturnOrder(SalesHeader, BOMComponent."No.", '', RandInt(), LocationCode1, WorkDate10D);
        CreateSalesReturnOrder(SalesHeader, BOMComponent."No.", '', RandInt(), LocationCode1, WorkDate10D + 1);

        // [WHEN] Create Assembly Order for assembling "Q" + 1 pcs of Item "X" on Location "L1"
        CreateAssemblyOrder(AssemblyHeader, Item."No.", LocationCode1, '', WorkDate2, CompQuantity + 1);

        // [THEN] Assembly Availability page shows in Header and Line: "Earliest Availability Date" = +10D, "Able To Assemble" = "Q"
        VerifyEarliestAvailDate(AssemblyHeader, CompQuantity, WorkDate10D);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,SendAssemblyAvailabilityNotificationHandler')]
    [Scope('OnPrem')]
    procedure AbleToAssembleExpectedInventory()
    var
        Item: Record Item;
        BOMComponent: Record "BOM Component";
        AssemblyHeader: Record "Assembly Header";
        ItemVariantCode: Code[10];
        CompQuantity: Integer;
        AddedQuantity: Integer;
        QtyToAssemble: Integer;
        LocationCode1: Code[10];
        LocationCode2: Code[10];
    begin
        // [FEATURE] [Component]
        // [SCENARIO 4212] "Able To Assemble" is not affected by inventory on different location or item variant
        Initialize();

        LocationCode1 := LocationBlue.Code;
        LocationCode2 := '';
        // [GIVEN] Create the assembled Item "X" with one component in inventory on Location "L1", Quantity = "Q"
        CompQuantity := CreateItemWithComponentInventory(Item, BOMComponent, LocationCode1);

        // [GIVEN] Create Item variant "V" and add inventory for combinations: "V" on "L1","V" on "L2","X" on "L2"
        ItemVariantCode := CreateItemVariant(BOMComponent."No.");
        AddInventory(BOMComponent."No.", ItemVariantCode, LocationCode1, RandInt());
        AddInventory(BOMComponent."No.", ItemVariantCode, LocationCode2, RandInt());
        AddInventory(BOMComponent."No.", '', LocationCode2, RandInt());

        // [WHEN] Create Assembly Order for assembling "Q" + 1 pcs of Item "X" on Location "L1"
        QtyToAssemble := CompQuantity + 1;
        CreateAssemblyOrder(AssemblyHeader, Item."No.", LocationCode1, '', WorkDate2, QtyToAssemble);

        // [THEN] Assembly Availability page is shown: "Able To Assemble" = "Q","Expected Inventory" = "Q"
        VerifyAbleToAssembleExpInventory(AssemblyHeader, CompQuantity, CompQuantity);

        // [GIVEN] Add 2 psc to inventory to Location "L1"
        AddedQuantity := QtyToAssemble - CompQuantity + 1;
        AddInventory(BOMComponent."No.", '', LocationCode1, 2);

        // [WHEN] Show Assembly Availability
        AssemblyHeader.ShowAvailability();

        // [THEN] Assembly Availability page shows: "Able To Assemble" = "Q" + 1,"Expected Inventory" = "Q" + 2
        VerifyAbleToAssembleExpInventory(AssemblyHeader, QtyToAssemble, CompQuantity + AddedQuantity);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    local procedure VerifyAbleToAssembleExpInventory(AssemblyHeader: Record "Assembly Header"; AbleToAssemble: Decimal; ExpInventory: Decimal)
    var
        ExpAsmAvailTestBuf: Record "Asm. Availability Test Buffer";
    begin
        ExpAsmAvailTestBuf.Init();
        ExpAsmAvailTestBuf.Validate("Able To Assemble", AbleToAssemble);
        AssertAvailabilityHeader(AssemblyHeader, ExpAsmAvailTestBuf);
        ExpAsmAvailTestBuf."Document Line No." := 1;
        ExpAsmAvailTestBuf.Validate("Expected Inventory", ExpInventory);
        AssertAvailabilityLine(AssemblyHeader, ExpAsmAvailTestBuf);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,SendAssemblyAvailabilityNotificationHandler')]
    [Scope('OnPrem')]
    procedure HdrScheduledReceiptsAssemblyOrders()
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        BOMComponent: Record "BOM Component";
        ItemVariantCode: Code[10];
        LocationCode1: Code[10];
        LocationCode2: Code[10];
        QtyToAssemble: Integer;
    begin
        // [FEATURE] [Assembled Item]
        // [SCENARIO 4213] "Scheduled Receipts" on the page header counts Assembly Orders
        Initialize();

        LocationCode1 := LocationBlue.Code;
        LocationCode2 := '';
        // [GIVEN] Create the assembled Item "X" with one component
        LibraryInventory.CreateItem(Item);
        AddComponent(Item, BOMComponent);
        // [GIVEN] Create Item variant "V"
        ItemVariantCode := CreateItemVariant(Item."No.");
        // [GIVEN] Create Assembly Orders for combinations: "V" on "L1","V" on "L2","X" on "L2"
        CreateAssemblyOrder(AssemblyHeader, Item."No.", LocationCode2, '', WorkDate2, RandInt());
        CreateAssemblyOrder(AssemblyHeader, Item."No.", LocationCode2, ItemVariantCode, WorkDate2, RandInt());
        CreateAssemblyOrder(AssemblyHeader, Item."No.", LocationCode1, ItemVariantCode, WorkDate2, RandInt());
        // [GIVEN] Create first Assembly Order for "X" on Location "L1". Quantity = "Q"
        QtyToAssemble := CreateAssemblyOrder(AssemblyHeader, Item."No.", LocationCode1, '', WorkDate2, RandInt());

        // [WHEN] Create second Assembly Order for "X" on Location "L1"
        CreateAssemblyOrder(AssemblyHeader, Item."No.", LocationCode1, '', WorkDate2, RandInt());

        // [THEN] Assembly Availability page is shown. Header's "Gross requirement" = 0
        VerifyHrdGrossReqSchedRcpts(AssemblyHeader, 0, QtyToAssemble);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,SendAssemblyAvailabilityNotificationHandler')]
    [Scope('OnPrem')]
    procedure HdrGrossRequirementSalesOrders()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        AssemblyHeader: Record "Assembly Header";
        BOMComponent: Record "BOM Component";
        ItemVariantCode: Code[10];
        Qty: Integer;
        LocationCode1: Code[10];
        LocationCode2: Code[10];
    begin
        // [FEATURE] [Assembled Item]
        // [SCENARIO 4215] "Gross requirement" on the page header counts Sales Orders
        Initialize();

        LocationCode1 := LocationBlue.Code;
        LocationCode2 := '';
        // [GIVEN] Create the assembled Item "X" with one component
        LibraryInventory.CreateItem(Item);
        AddComponent(Item, BOMComponent);
        // [GIVEN] Create Item variant "V"
        ItemVariantCode := CreateItemVariant(Item."No.");
        // [GIVEN] Create Sales Orders on +10D for combinations: "V" on "L1","V" on "L2","X" on "L2"
        CreateSalesOrder(SalesHeader, Item."No.", ItemVariantCode, RandInt(), WorkDate10D, LocationCode1);
        CreateSalesOrder(SalesHeader, Item."No.", '', RandInt(), WorkDate10D, LocationCode2);
        CreateSalesOrder(SalesHeader, Item."No.", ItemVariantCode, RandInt(), WorkDate10D, LocationCode2);
        // [GIVEN] Create Sales Order on +10D for "X" on "L1", Quantity = "Q"
        Qty := CreateSalesOrder(SalesHeader, Item."No.", '', RandInt(), WorkDate10D, LocationCode1);

        // [WHEN] Create Assembly Order on +10D for "X" on Location "L1"
        CreateAssemblyOrder(AssemblyHeader, Item."No.", LocationCode1, '', WorkDate10D, RandInt());

        // [THEN] Assembly Availability page is shown. Header's "Gross requirement" = "Q"
        VerifyHrdGrossReqSchedRcpts(AssemblyHeader, Qty, 0);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,SendAssemblyAvailabilityNotificationHandler')]
    [Scope('OnPrem')]
    procedure HdrGrossRequirementPurchRetOrders()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        AssemblyHeader: Record "Assembly Header";
        BOMComponent: Record "BOM Component";
        ItemVariantCode: Code[10];
        Qty: Integer;
        LocationCode1: Code[10];
        LocationCode2: Code[10];
    begin
        // [FEATURE] [Assembled Item]
        // [SCENARIO 4216] "Gross requirement" on the page header counts Purchase Return Orders
        Initialize();

        LocationCode1 := LocationBlue.Code;
        LocationCode2 := '';
        // [GIVEN] Create the assembled Item "X" with one component
        LibraryInventory.CreateItem(Item);
        AddComponent(Item, BOMComponent);
        // [GIVEN] Create Item variant "V"
        ItemVariantCode := CreateItemVariant(Item."No.");
        // [GIVEN] Create Purchase Return Orders on +10D for combinations: "V" on "L1","V" on "L2","X" on "L2"
        CreatePurchaseReturnOrder(PurchaseHeader, Item."No.", ItemVariantCode, RandInt(), LocationCode1, WorkDate10D);
        CreatePurchaseReturnOrder(PurchaseHeader, Item."No.", '', RandInt(), LocationCode2, WorkDate10D);
        CreatePurchaseReturnOrder(PurchaseHeader, Item."No.", ItemVariantCode, RandInt(), LocationCode2, WorkDate10D);
        // [GIVEN] Create Purchase Return Order on +10D for "X" on Location "L1", Quantity = "Q"
        Qty := CreatePurchaseReturnOrder(PurchaseHeader, Item."No.", '', RandInt(), LocationCode1, WorkDate10D);

        // [WHEN] Create Assembly Order for "X" on Location "L1"
        CreateAssemblyOrder(AssemblyHeader, Item."No.", LocationCode1, '', WorkDate2, RandInt());

        // [THEN] Assembly Availability page is shown. Header's "Gross requirement" = "Q"
        VerifyHrdGrossReqSchedRcpts(AssemblyHeader, Qty, 0);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,SendAssemblyAvailabilityNotificationHandler')]
    [Scope('OnPrem')]
    procedure HdrGrossRequirementTransferOrders()
    var
        TransferHeader: Record "Transfer Header";
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        BOMComponent: Record "BOM Component";
        ItemVariantCode: Code[10];
        Qty: Integer;
        LocationCode1: Code[10];
        LocationCode2: Code[10];
    begin
        // [FEATURE] [Assembled Item]
        // [SCENARIO 4217] "Gross requirement" on the page header counts Transfer Orders
        Initialize();

        LocationCode1 := LocationBlue.Code;
        LocationCode2 := LocationRed.Code;
        // [GIVEN] Create the assembled Item "X" with one component
        LibraryInventory.CreateItem(Item);
        AddComponent(Item, BOMComponent);
        SetRandComponentQuantityPer(BOMComponent);
        // [GIVEN] Create Item variant "V"
        ItemVariantCode := CreateItemVariant(Item."No.");
        // [GIVEN] Create Transfer Orders on +10D for combinations: "V" on "L1","V" on "L2","X" on "L2"
        CreateTransferOrder(TransferHeader, Item."No.", ItemVariantCode, LocationCode1, LocationCode2, WorkDate10D, RandInt());
        CreateTransferOrder(TransferHeader, Item."No.", ItemVariantCode, LocationCode2, LocationCode1, WorkDate10D, RandInt());
        CreateTransferOrder(TransferHeader, Item."No.", '', LocationCode2, LocationCode1, WorkDate10D, RandInt());
        // [GIVEN] Create Transfer Order for "X" on Location "L1", Quantity = "Q"
        Qty := CreateTransferOrder(TransferHeader, Item."No.", '', LocationCode1, LocationCode2, WorkDate2, RandInt());

        // [WHEN] Create Assembly Order for "X" on Location "L1"
        CreateAssemblyOrder(AssemblyHeader, Item."No.", LocationCode1, '', WorkDate2, RandInt());

        // [THEN] Assembly Availability page is shown. Header's "Gross requirement" = "Q"
        VerifyHrdGrossReqSchedRcpts(AssemblyHeader, Qty, 0);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,SendAssemblyAvailabilityNotificationHandler')]
    [Scope('OnPrem')]
    procedure HdrGrossRequirementProductionOrder()
    var
        AssembledItem: Record Item;
        ProducedItem: Record Item;
        AssemblyHeader: Record "Assembly Header";
        BOMComponent: Record "BOM Component";
        ProductionOrder: Record "Production Order";
        ItemVariantCode: Code[10];
        Qty: Integer;
        QtyPer: Integer;
        LocationCode1: Code[10];
        LocationCode2: Code[10];
    begin
        // [FEATURE] [Assembled Item]
        // [SCENARIO 4218] "Gross requirement" on the page header counts Production Orders
        Initialize();

        LocationCode1 := LocationBlue.Code;
        LocationCode2 := LocationRed.Code;
        // [GIVEN] Create the assembled Item "X" with one component
        LibraryInventory.CreateItem(AssembledItem);
        AddComponent(AssembledItem, BOMComponent);
        // [GIVEN] Create Item variant "V"
        ItemVariantCode := CreateItemVariant(AssembledItem."No.");
        // [GIVEN] Create Production Order on +10D for Item "P" on Location "L1", Quantity = "PQ"
        LibraryInventory.CreateItem(ProducedItem);
        Qty := CreateProdOrderAndRefresh(ProductionOrder, ProducedItem."No.", RandInt(), LocationCode1, WorkDate10D);
        // [GIVEN] Add Production Components for combinations: "V" on "L1","V" on "L2","X" on "L2"
        // [GIVEN] Add Production Components for "X" on "L1", Quantity = "Q"
        QtyPer := AddComponentsToProdOrder(ProductionOrder, AssembledItem."No.", ItemVariantCode, LocationCode1, LocationCode2);

        // [WHEN] Create Assembly Order for "X" on Location "L1"
        CreateAssemblyOrder(AssemblyHeader, AssembledItem."No.", LocationCode1, '', WorkDate2, RandInt());

        // [THEN] Assembly Availability page is shown. Header's "Gross requirement" = "Q" * "PQ"
        VerifyHrdGrossReqSchedRcpts(AssemblyHeader, Qty * QtyPer, 0);
    end;

    local procedure AddComponentsToProdOrder(ProductionOrder: Record "Production Order"; ItemNo: Code[20]; ItemVariantCode: Code[10]; LocationCode1: Code[10]; LocationCode2: Code[10]) QtyPer: Decimal
    begin
        AddComponentToProdOrder(ProductionOrder, ItemNo, ItemVariantCode, RandInt(), LocationCode1);
        AddComponentToProdOrder(ProductionOrder, ItemNo, ItemVariantCode, RandInt(), LocationCode2);
        AddComponentToProdOrder(ProductionOrder, ItemNo, '', RandInt(), LocationCode2);
        QtyPer := AddComponentToProdOrder(ProductionOrder, ItemNo, '', RandInt(), LocationCode1);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,SendAssemblyAvailabilityNotificationHandler')]
    [Scope('OnPrem')]
    procedure HdrScheduledReceiptsPurchaseOrders()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        AssemblyHeader: Record "Assembly Header";
        BOMComponent: Record "BOM Component";
        ItemVariantCode: Code[10];
        Qty: Integer;
        LocationCode1: Code[10];
        LocationCode2: Code[10];
    begin
        // [FEATURE] [Assembled Item]
        // [SCENARIO 4219] "Scheduled Receipts" on the page header counts Purchase Orders
        Initialize();

        LocationCode1 := '';
        LocationCode2 := LocationRed.Code;
        // [GIVEN] Create the assembled Item "X" with one component
        LibraryInventory.CreateItem(Item);
        AddComponent(Item, BOMComponent);
        // [GIVEN] Create Item variant "V"
        ItemVariantCode := CreateItemVariant(Item."No.");
        // [GIVEN] Create Purchase Orders on +10D for combinations: "V" on "L1","V" on "L2","X" on "L2","X" on "L1"
        CreatePurchaseOrders(Item."No.", ItemVariantCode, WorkDate10D, LocationCode1, LocationCode2);
        // [GIVEN] Create Purchase Order on WorkDate for "X" on "L1", Quantity = "Q"
        Qty := CreatePurchaseOrder(PurchaseHeader, Item."No.", '', RandInt(), LocationCode1, WorkDate2);

        // [WHEN] Create Assembly Order on WorkDate for "X" on Location "L1"
        CreateAssemblyOrder(AssemblyHeader, Item."No.", LocationCode1, '', WorkDate2, RandInt());

        // [THEN] Assembly Availability page is shown. Header's "Scheduled Receipts" = "Q"
        VerifyHrdGrossReqSchedRcpts(AssemblyHeader, 0, Qty);
    end;

    local procedure CreatePurchaseOrders(ItemNo: Code[20]; ItemVariantCode: Code[10]; ReceiptDate: Date; LocationCode1: Code[10]; LocationCode2: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseOrder(PurchaseHeader, ItemNo, ItemVariantCode, RandInt(), LocationCode1, ReceiptDate);
        CreatePurchaseOrder(PurchaseHeader, ItemNo, '', RandInt(), LocationCode2, ReceiptDate);
        CreatePurchaseOrder(PurchaseHeader, ItemNo, ItemVariantCode, RandInt(), LocationCode1, ReceiptDate);
        CreatePurchaseOrder(PurchaseHeader, ItemNo, '', RandInt(), LocationCode1, ReceiptDate);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,SendAssemblyAvailabilityNotificationHandler')]
    [Scope('OnPrem')]
    procedure HdrScheduledReceiptsProdOrderAsmOrder()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        AssemblyHeader: Record "Assembly Header";
        BOMComponent: Record "BOM Component";
        QtyOnAssemble: Integer;
        QtyToProduce: Integer;
        LocationCode: Code[10];
    begin
        // [FEATURE] [Assembled Item]
        // [SCENARIO 4220] "Scheduled Receipts" on the page header counts Production Orders
        Initialize();

        LocationCode := LocationBlue.Code;
        // [GIVEN] Create the assembled Item "X" with one component
        LibraryInventory.CreateItem(Item);
        AddComponent(Item, BOMComponent);
        // [GIVEN] Create Production Orders on +10D for "X" on "L1"
        CreateProdOrderAndRefresh(ProductionOrder, Item."No.", RandInt(), LocationCode, WorkDate10D);
        // [GIVEN] Create Production Order on WorkDate for "X" on "L1", Quantity = "PQ"
        QtyToProduce := CreateProdOrderAndRefresh(ProductionOrder, Item."No.", RandInt(), LocationCode, WorkDate2);
        // [GIVEN] Create Assembly Order on WorkDate for "X" on Location "L1", Quantity = "Q"
        QtyOnAssemble := CreateAssemblyOrder(AssemblyHeader, Item."No.", LocationCode, '', WorkDate2, RandInt());

        // [WHEN] Create Assembly Order on WorkDate for "X" on Location "L1"
        CreateAssemblyOrder(AssemblyHeader, Item."No.", LocationCode, '', WorkDate2, RandInt());

        // [THEN] Assembly Availability page is shown. Header's "Scheduled Receipts" = "Q" + "Qp"
        VerifyHrdGrossReqSchedRcpts(AssemblyHeader, 0, QtyOnAssemble + QtyToProduce);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,SendAssemblyAvailabilityNotificationHandler')]
    [Scope('OnPrem')]
    procedure HdrScheduledReceiptsSalesReturnOrders()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        AssemblyHeader: Record "Assembly Header";
        BOMComponent: Record "BOM Component";
        ItemVariantCode: Code[10];
        Qty: Integer;
        LocationCode1: Code[10];
        LocationCode2: Code[10];
    begin
        // [FEATURE] [Assembled Item]
        // [SCENARIO 4221] "Scheduled Receipts" on the page header counts Sales Return Orders
        Initialize();

        LocationCode1 := LocationBlue.Code;
        LocationCode2 := '';
        // [GIVEN] Create the assembled Item "X" with one component
        LibraryInventory.CreateItem(Item);
        AddComponent(Item, BOMComponent);
        // [GIVEN] Create Item variant "V"
        ItemVariantCode := CreateItemVariant(Item."No.");
        // [GIVEN] Create Sales Orders on +10D for combinations: "V" on "L1","V" on "L2","X" on "L2","X" on "L1"
        CreateSalesReturnOrders(Item."No.", ItemVariantCode, WorkDate10D, LocationCode1, LocationCode2);
        // [GIVEN] Create Sales Orders on WorkDate for "X" on "L1", Quantity = "Q"
        Qty := CreateSalesReturnOrder(SalesHeader, Item."No.", '', RandInt(), LocationCode1, WorkDate2);

        // [WHEN] Create Assembly Order on WorkDate for "X" on Location "L1"
        CreateAssemblyOrder(AssemblyHeader, Item."No.", LocationCode1, '', WorkDate2, RandInt());

        // [THEN] Assembly Availability page is shown. Header's "Scheduled Receipts" = "Q"
        VerifyHrdGrossReqSchedRcpts(AssemblyHeader, 0, Qty);
    end;

    local procedure CreateSalesReturnOrders(ItemNo: Code[20]; ItemVariantCode: Code[10]; ReceiptDate: Date; LocationCode1: Code[10]; LocationCode2: Code[10])
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesReturnOrder(SalesHeader, ItemNo, ItemVariantCode, RandInt(), LocationCode1, ReceiptDate);
        CreateSalesReturnOrder(SalesHeader, ItemNo, '', RandInt(), LocationCode2, ReceiptDate);
        CreateSalesReturnOrder(SalesHeader, ItemNo, ItemVariantCode, RandInt(), LocationCode1, ReceiptDate);
        CreateSalesReturnOrder(SalesHeader, ItemNo, '', RandInt(), LocationCode1, ReceiptDate);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,SendAssemblyAvailabilityNotificationHandler')]
    [Scope('OnPrem')]
    procedure HdrScheduledReceiptsTransferOrders()
    var
        TransferHeader: Record "Transfer Header";
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        BOMComponent: Record "BOM Component";
        ItemVariantCode: Code[10];
        Qty: Integer;
        LocationCode1: Code[10];
        LocationCode2: Code[10];
    begin
        // [FEATURE] [Assembled Item]
        // [SCENARIO 4222] "Scheduled Receipts" on the page header counts Transfer Orders
        Initialize();

        LocationCode1 := LocationRed.Code;
        LocationCode2 := LocationBlue.Code;
        // [GIVEN] Create the assembled Item "X" with one component
        LibraryInventory.CreateItem(Item);
        AddComponent(Item, BOMComponent);
        // [GIVEN] Create Item variant "V"
        ItemVariantCode := CreateItemVariant(Item."No.");
        // [GIVEN] Create Transfer Orders on +10D for combinations: "V" on "L1","V" on "L2","X" on "L2"
        CreateTransferOrder(TransferHeader, Item."No.", ItemVariantCode, LocationCode1, LocationCode2, WorkDate10D, RandInt());
        CreateTransferOrder(TransferHeader, Item."No.", ItemVariantCode, LocationCode2, LocationCode1, WorkDate10D, RandInt());
        CreateTransferOrder(TransferHeader, Item."No.", '', LocationCode2, LocationCode1, WorkDate10D, RandInt());
        // [GIVEN] Create Transfer Orders on WorkDate for "X" on "L2", Quantity = "Q"
        Qty := CreateTransferOrder(TransferHeader, Item."No.", '', LocationCode2, LocationCode1, WorkDate2, RandInt());

        // [WHEN] Create Assembly Order on WorkDate for "X" on Location "L1"
        CreateAssemblyOrder(AssemblyHeader, Item."No.", LocationCode1, '', WorkDate2, RandInt());

        // [THEN] Assembly Availability page is shown. Header's "Scheduled Receipts" = "Q"
        VerifyHrdGrossReqSchedRcpts(AssemblyHeader, 0, Qty);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,SendAssemblyAvailabilityNotificationHandler')]
    [Scope('OnPrem')]
    procedure HdrAbleToAssembleTwoCompWithQtyPer()
    var
        Item: Record Item;
        BOMComponent: array[2] of Record "BOM Component";
        AssemblyHeader: Record "Assembly Header";
        ExpAsmAvailTestBuf: Record "Asm. Availability Test Buffer";
        AbleToAssemble: array[2] of Decimal;
        QtyOnInventory: array[2] of Integer;
        QtyOnAssemble: Integer;
        i: Integer;
        LocationCode: Code[10];
    begin
        // [FEATURE] [Quantity Per]
        // [SCENARIO 4223] "Able To Assemble" is equal to the minimal quantity of two components in inventory, considering component's "Quantity per"
        Initialize();

        LocationCode := '';
        QtyOnAssemble := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create the assembled Item "X"
        LibraryInventory.CreateItem(Item);
        for i := 1 to 2 do begin
            // [GIVEN] Add two components with "Quantity per": "Qp1", "Qp2"
            AddComponent(Item, BOMComponent[i], i + 1);
            QtyOnInventory[i] := QtyOnAssemble * BOMComponent[i]."Quantity per" - i * 10;

            // [GIVEN] Add inventory for both components: "Q1", "Q2"
            AddInventory(BOMComponent[i]."No.", '', LocationCode, QtyOnInventory[i]);
            AbleToAssemble[i] := QtyOnInventory[i] / BOMComponent[i]."Quantity per";
        end;

        // [WHEN] Create Assembly Order for "X" missing both components
        CreateAssemblyOrder(AssemblyHeader, Item."No.", LocationCode, '', WorkDate2, QtyOnAssemble);
        Commit();
        AssemblyHeader.ShowAvailability();

        // [THEN] Header's "Able To Assemble" is minimal of "Able To Assemble" in lines
        ExpAsmAvailTestBuf.Init();
        ExpAsmAvailTestBuf.Validate("Able To Assemble", MinValue(AbleToAssemble[1], AbleToAssemble[2]));
        AssertAvailabilityHeader(AssemblyHeader, ExpAsmAvailTestBuf);
        // [THEN] Line's "Expected Inventory" shows components inventory (Q1, Q2)
        // [THEN] Line's "Able To Assemble" shows quantity of "X" considering "Quantity per" (Q1 / Qp1, Q2 / Qp2)
        for i := 1 to 2 do begin
            ExpAsmAvailTestBuf."Document Line No." := i;
            ExpAsmAvailTestBuf.Validate("Expected Inventory", QtyOnInventory[i]);
            ExpAsmAvailTestBuf.Validate("Able To Assemble", AbleToAssemble[i]);
            AssertAvailabilityLine(AssemblyHeader, ExpAsmAvailTestBuf);
        end;
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,SendAssemblyAvailabilityNotificationHandler')]
    [Scope('OnPrem')]
    procedure LineGrossRequirementAssemblyOrders()
    var
        Item: Record Item;
        BOMComponent: Record "BOM Component";
        AssemblyHeader: Record "Assembly Header";
        QtyOnAssemble1: Integer;
        LocationCode1: Code[10];
        LocationCode2: Code[10];
    begin
        // [FEATURE] [Quantity Per]
        // [SCENARIO 4224] "Gross requirement" on the page line counts Assembly Orders, considering "Quantity per"
        Initialize();

        LocationCode1 := LocationRed.Code;
        LocationCode2 := LocationBlue.Code;
        // [GIVEN] Create the assembled Item "X" with one component
        LibraryInventory.CreateItem(Item);
        AddComponent(Item, BOMComponent);
        // [GIVEN] Component's "Quantity per" = "Qp"
        SetRandComponentQuantityPer(BOMComponent);
        // [GIVEN] Create Component Variant "CV"
        SetVariantOnComponent(BOMComponent, CreateItemVariant(BOMComponent."No."));
        // [GIVEN] Create Assembly Order for item "X" for location "L2"
        CreateAssemblyOrder(AssemblyHeader, Item."No.", LocationCode2, '', WorkDate2, RandInt());
        // [GIVEN] Create first Assembly Order for item "X" for location "L1", Quantity = "Q"
        QtyOnAssemble1 := CreateAssemblyOrder(AssemblyHeader, Item."No.", LocationCode1, '', WorkDate2, RandInt());
        // [WHEN] Create second Assembly Order for item "X" for location "L1"
        CreateAssemblyOrder(AssemblyHeader, Item."No.", LocationCode1, '', WorkDate2, RandInt());

        // [THEN] Assembly Availability Line contains info only for the first order, not current one, same location and variant
        VerifyLineGrossReqExpInv(
          AssemblyHeader, QtyOnAssemble1 * BOMComponent."Quantity per", -QtyOnAssemble1 * BOMComponent."Quantity per");
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,SendAssemblyAvailabilityNotificationHandler')]
    [Scope('OnPrem')]
    procedure LineGrossRequirementSalesOrders()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        AssemblyHeader: Record "Assembly Header";
        BOMComponent: Record "BOM Component";
        ItemVariantCode: Code[10];
        QtyOnSO: Integer;
        LocationCode1: Code[10];
        LocationCode2: Code[10];
    begin
        // [FEATURE] [Component]
        // [SCENARIO 4225] "Gross requirement" on the page line counts Sales Orders
        Initialize();

        LocationCode1 := LocationRed.Code;
        LocationCode2 := '';
        // [GIVEN] Create the assembled Item "X" with a component "C"
        LibraryInventory.CreateItem(Item);
        AddComponent(Item, BOMComponent);
        // [GIVEN] Create Component variant "CV", not in assembly list
        ItemVariantCode := CreateItemVariant(BOMComponent."No.");
        // [GIVEN] Create Sales Orders for combinations: "CV" on "L1","CV" on "L2","C" on "L2"
        CreateSalesOrder(SalesHeader, BOMComponent."No.", ItemVariantCode, RandInt(), WorkDate2, LocationCode1);
        CreateSalesOrder(SalesHeader, BOMComponent."No.", '', RandInt(), WorkDate2, LocationCode2);
        CreateSalesOrder(SalesHeader, BOMComponent."No.", ItemVariantCode, RandInt(), WorkDate2, LocationCode1);
        // [GIVEN] Create Sales Order for "C" on "L1", Quantity = "Q"
        QtyOnSO := CreateSalesOrder(SalesHeader, BOMComponent."No.", '', RandInt(), WorkDate2, LocationCode1);

        // [WHEN] Create Assembly Order for item "X" for location "L1"
        CreateAssemblyOrderOnSafeDate(AssemblyHeader, Item."No.", LocationCode1, '', WorkDate2, RandInt());

        // [THEN] Assembly Availability Line: "Gross requirement" = "Q", "Expected Inventory" = -"Q"
        VerifyLineGrossReqExpInv(AssemblyHeader, QtyOnSO, -QtyOnSO);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,SendAssemblyAvailabilityNotificationHandler')]
    [Scope('OnPrem')]
    procedure LineGrossRequirementPurchReturnOrders()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        AssemblyHeader: Record "Assembly Header";
        BOMComponent: Record "BOM Component";
        ItemVariantCode: Code[10];
        QtyOnPRO: Integer;
        LocationCode1: Code[10];
        LocationCode2: Code[10];
    begin
        // [FEATURE] [Component]
        // [SCENARIO 4226] "Gross requirement" on the page line counts Purchase Return Orders
        Initialize();

        LocationCode1 := '';
        LocationCode2 := LocationBlue.Code;
        // [GIVEN] Create the assembled Item "X" with a component "C"
        LibraryInventory.CreateItem(Item);
        AddComponent(Item, BOMComponent);
        // [GIVEN] Create Component variant "CV", not in assembly list
        ItemVariantCode := CreateItemVariant(BOMComponent."No.");
        // [GIVEN] Create Purchase Return Orders for combinations: "CV" on "L1","CV" on "L2","C" on "L2"
        CreatePurchaseReturnOrder(PurchaseHeader, BOMComponent."No.", ItemVariantCode, RandInt(), LocationCode1, WorkDate2);
        CreatePurchaseReturnOrder(PurchaseHeader, BOMComponent."No.", '', RandInt(), LocationCode2, WorkDate2);
        CreatePurchaseReturnOrder(PurchaseHeader, BOMComponent."No.", ItemVariantCode, RandInt(), LocationCode2, WorkDate2);
        // [GIVEN] Create Purchase Return Order for "C" on "L1", Quantity = "Q"
        QtyOnPRO := CreatePurchaseReturnOrder(PurchaseHeader, BOMComponent."No.", '', RandInt(), LocationCode1, WorkDate2);

        // [WHEN] Create Assembly Order for item "X" for location "L1"
        CreateAssemblyOrderOnSafeDate(AssemblyHeader, Item."No.", LocationCode1, '', WorkDate2, RandInt());

        // [THEN] Assembly Availability Line: "Gross requirement" = "Q", "Expected Inventory" = -"Q"
        VerifyLineGrossReqExpInv(AssemblyHeader, QtyOnPRO, -QtyOnPRO);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,SendAssemblyAvailabilityNotificationHandler')]
    [Scope('OnPrem')]
    procedure LineGrossRequirementTransferOrders()
    var
        TransferHeader: Record "Transfer Header";
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        BOMComponent: Record "BOM Component";
        ItemVariantCode: Code[10];
        QtyOnTO: Integer;
        LocationCode1: Code[10];
        LocationCode2: Code[10];
    begin
        // [FEATURE] [Component]
        // [SCENARIO 4227] "Gross requirement" on the page line counts Transfer Orders
        Initialize();

        LocationCode1 := LocationRed.Code;
        LocationCode2 := LocationBlue.Code;
        // [GIVEN] Create the assembled Item "X" with a component "C"
        LibraryInventory.CreateItem(Item);
        AddComponent(Item, BOMComponent);
        // [GIVEN] Create Component variant "CV", not in assembly list
        ItemVariantCode := CreateItemVariant(BOMComponent."No.");
        // [GIVEN] Create Transfer Orders for combinations: "CV" on "L1","CV" on "L2"
        CreateTransferOrder(TransferHeader, BOMComponent."No.", ItemVariantCode, LocationCode1, LocationCode2, WorkDate2, RandInt());
        CreateTransferOrder(TransferHeader, BOMComponent."No.", ItemVariantCode, LocationCode2, LocationCode1, WorkDate2, RandInt());
        // [GIVEN] Create Transfer Order for "C" moving from "L1" to "L2"
        QtyOnTO := CreateTransferOrder(TransferHeader, BOMComponent."No.", '', LocationCode1, LocationCode2, WorkDate2, RandInt());

        // [WHEN] Create Assembly Order for item "X" for location "L1"
        CreateAssemblyOrderOnSafeDate(AssemblyHeader, Item."No.", LocationCode1, '', WorkDate2, RandInt());

        // [THEN] Assembly Availability Line: "Gross requirement" = "Q", "Expected Inventory" = -"Q"
        VerifyLineGrossReqExpInv(AssemblyHeader, QtyOnTO, -QtyOnTO);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,SendAssemblyAvailabilityNotificationHandler')]
    [Scope('OnPrem')]
    procedure LineGrossRequirementProductionOrders()
    var
        AssembledItem: Record Item;
        ProducedItem: Record Item;
        ProductionOrder: Record "Production Order";
        AssemblyHeader: Record "Assembly Header";
        BOMComponent: Record "BOM Component";
        ItemVariantCode: Code[10];
        QtyOnRPO: Integer;
        QtyPerProd: Integer;
        LocationCode1: Code[10];
        LocationCode2: Code[10];
    begin
        // [FEATURE] [Component] [Quantity Per]
        // [SCENARIO 4228] "Gross requirement" on the page line counts Production Orders
        Initialize();

        LocationCode1 := LocationRed.Code;
        LocationCode2 := LocationBlue.Code;
        // [GIVEN] Create the assembled Item "X" with a component "C"
        LibraryInventory.CreateItem(AssembledItem);
        AddComponent(AssembledItem, BOMComponent);
        // [GIVEN] Create Component variant "CV", not in assembly list
        ItemVariantCode := CreateItemVariant(BOMComponent."No.");
        // [GIVEN] Create Production Order for Item "P" on Location "L1", Quantity = "PQ"
        LibraryInventory.CreateItem(ProducedItem);
        QtyOnRPO := CreateProdOrderAndRefresh(ProductionOrder, ProducedItem."No.", RandInt(), LocationCode1, WorkDate2);
        // [GIVEN] Add Production Components for combinations: "CV" on "L1","CV" on "L2","C" on "L2"
        // [GIVEN] Add Production Component for "C" on "L1", Quantity = "Q"
        QtyPerProd := AddComponentsToProdOrder(ProductionOrder, BOMComponent."No.", ItemVariantCode, LocationCode1, LocationCode2);

        // [WHEN] Create Assembly Order for item "X" for location "L1"
        CreateAssemblyOrder(AssemblyHeader, AssembledItem."No.", LocationCode1, '', WorkDate2, RandInt());

        // [THEN] Assembly Availability Line: "Gross requirement" = ("Q" * "PQ"), "Expected Inventory" = -("Q" * "PQ")
        VerifyLineGrossReqExpInv(AssemblyHeader, QtyOnRPO * QtyPerProd, -QtyOnRPO * QtyPerProd);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,SendAssemblyAvailabilityNotificationHandler')]
    [Scope('OnPrem')]
    procedure LineScheduledReceiptsPurchaseOrders()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        AssemblyHeader: Record "Assembly Header";
        BOMComponent: Record "BOM Component";
        ExpAsmAvailTestBuf: Record "Asm. Availability Test Buffer";
        ItemVariantCode: Code[10];
        QtyOnPO: Integer;
        LocationCode1: Code[10];
        LocationCode2: Code[10];
    begin
        // [FEATURE] [Component] [Quantity Per]
        // [SCENARIO 4229] "Scheduled Receipts" on the page line counts Purchase Orders
        Initialize();

        LocationCode1 := LocationRed.Code;
        LocationCode2 := LocationBlue.Code;
        // [GIVEN] Create the assembled Item "X" with a component "C"
        LibraryInventory.CreateItem(Item);
        AddComponent(Item, BOMComponent);
        // [GIVEN] Component's "Quantity per" = "Qp"
        SetRandComponentQuantityPer(BOMComponent);
        // [GIVEN] Create Component variant "CV", not in assembly list
        ItemVariantCode := CreateItemVariant(BOMComponent."No.");
        // [GIVEN] Create Purchase Orders on +10D for combinations: "CV" on "L1","CV" on "L2","C" on "L2","C" on "L1"
        CreatePurchaseOrders(BOMComponent."No.", ItemVariantCode, WorkDate10D, LocationCode1, LocationCode2);
        // [GIVEN] Create Purchase Order on WorkDate for "C" on "L1", Quantity = "Q"
        QtyOnPO := CreatePurchaseOrder(PurchaseHeader, BOMComponent."No.", '', RandInt(), LocationCode1, WorkDate2);

        // [WHEN] Create Assembly Order for item "X" for location "L1"
        CreateAssemblyOrderOnSafeDate(AssemblyHeader, Item."No.", LocationCode1, '', WorkDate2, RandInt());

        // [THEN] Assembly Availability Line: "Scheduled Receipts" = "Q", "Expected Inventory" = "Q"
        ExpAsmAvailTestBuf.Init();
        ExpAsmAvailTestBuf."Document Line No." := 1;
        ExpAsmAvailTestBuf.Validate("Scheduled Receipts", QtyOnPO);
        ExpAsmAvailTestBuf.Validate("Expected Inventory", QtyOnPO);
        // [THEN] "Able To Assemble" = ("Q" / "Qp")
        ExpAsmAvailTestBuf.Validate("Able To Assemble", QtyOnPO / BOMComponent."Quantity per");
        AssertAvailabilityLine(AssemblyHeader, ExpAsmAvailTestBuf)
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,SendAssemblyAvailabilityNotificationHandler')]
    [Scope('OnPrem')]
    procedure LineScheduledReceiptsProductionOrders()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        AssemblyHeader: Record "Assembly Header";
        BOMComponent: Record "BOM Component";
        ExpAsmAvailTestBuf: Record "Asm. Availability Test Buffer";
        QtyOnRPO: Integer;
        LocationCode: Code[10];
    begin
        // [FEATURE] [Component] [Quantity Per]
        // [SCENARIO 4230] "Scheduled Receipts" on the page line counts Production Orders
        Initialize();

        LocationCode := LocationRed.Code;
        // [GIVEN] Create the assembled Item "X" with a component "C"
        LibraryInventory.CreateItem(Item);
        AddComponent(Item, BOMComponent);
        // [GIVEN] Component's "Quantity per" = "Qp"
        SetRandComponentQuantityPer(BOMComponent);
        // [GIVEN] Create Production Order on +10D for "C" on "L1"
        CreateProdOrderAndRefresh(ProductionOrder, BOMComponent."No.", RandInt(), LocationCode, WorkDate10D);
        // [GIVEN] Create Production Order for "C" on "L1", Quantity = "Q"
        QtyOnRPO := CreateProdOrderAndRefresh(ProductionOrder, BOMComponent."No.", RandInt(), LocationCode, WorkDate2);

        // [WHEN] Create Assembly Order for item "X" for location "L1"
        CreateAssemblyOrderOnSafeDate(AssemblyHeader, Item."No.", LocationCode, '', WorkDate2, RandInt());

        // [THEN] Assembly Availability Line: "Scheduled Receipts" = "Q", "Expected Inventory" = "Q"
        ExpAsmAvailTestBuf.Init();
        ExpAsmAvailTestBuf."Document Line No." := 1;
        ExpAsmAvailTestBuf.Validate("Scheduled Receipts", QtyOnRPO);
        ExpAsmAvailTestBuf.Validate("Expected Inventory", QtyOnRPO);
        // [THEN] "Able To Assemble" = ("Q" / "Qp")
        ExpAsmAvailTestBuf.Validate("Able To Assemble", QtyOnRPO / BOMComponent."Quantity per");
        AssertAvailabilityLine(AssemblyHeader, ExpAsmAvailTestBuf);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,SendAssemblyAvailabilityNotificationHandler')]
    [Scope('OnPrem')]
    procedure LineScheduledReceiptsSalesReturnOrders()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        AssemblyHeader: Record "Assembly Header";
        BOMComponent: Record "BOM Component";
        ExpAsmAvailTestBuf: Record "Asm. Availability Test Buffer";
        ItemVariantCode: Code[10];
        QtyOnSRO: Integer;
        LocationCode1: Code[10];
        LocationCode2: Code[10];
    begin
        // [FEATURE] [Component] [Quantity Per]
        // [SCENARIO 4231] "Scheduled Receipts" on the page line counts Sales Return Orders
        Initialize();

        LocationCode1 := LocationRed.Code;
        LocationCode2 := LocationBlue.Code;
        // [GIVEN] Create the assembled Item "X" with a component "C"
        LibraryInventory.CreateItem(Item);
        AddComponent(Item, BOMComponent);
        // [GIVEN] Component's "Quantity per" = "Qp"
        SetRandComponentQuantityPer(BOMComponent);
        // [GIVEN] Create Component variant "CV", not in assembly list
        ItemVariantCode := CreateItemVariant(BOMComponent."No.");
        // [GIVEN] Create Sales Return Orders on +10D for combinations: "CV" on "L1","CV" on "L2","C" on "L1","C" on "L2"
        CreateSalesReturnOrders(BOMComponent."No.", ItemVariantCode, WorkDate10D, LocationCode1, LocationCode2);
        // [GIVEN] Create Sales Return Order on WorkDate for "C" on "L1", Quantity = "Q"
        QtyOnSRO := CreateSalesReturnOrder(SalesHeader, BOMComponent."No.", '', QtyOnSRO, LocationCode1, WorkDate2);

        // [WHEN] Create Assembly Order for item "X" for location "L1"
        CreateAssemblyOrderOnSafeDate(AssemblyHeader, Item."No.", LocationCode1, '', WorkDate2, RandInt());

        // [THEN] Assembly Availability Line: "Scheduled Receipts" = "Q", "Expected Inventory" = "Q"
        ExpAsmAvailTestBuf.Init();
        ExpAsmAvailTestBuf."Document Line No." := 1;
        ExpAsmAvailTestBuf.Validate("Scheduled Receipts", QtyOnSRO);
        ExpAsmAvailTestBuf.Validate("Expected Inventory", QtyOnSRO);
        // [THEN] "Able To Assemble" = ("Q" / "Qp")
        ExpAsmAvailTestBuf.Validate("Able To Assemble", QtyOnSRO / BOMComponent."Quantity per");
        AssertAvailabilityLine(AssemblyHeader, ExpAsmAvailTestBuf);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,SendAssemblyAvailabilityNotificationHandler')]
    [Scope('OnPrem')]
    procedure LineScheduledReceiptsTransferOrders()
    var
        TransferHeader: Record "Transfer Header";
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        BOMComponent: Record "BOM Component";
        ExpAsmAvailTestBuf: Record "Asm. Availability Test Buffer";
        ItemVariantCode: Code[10];
        QtyOnTO: Integer;
        LocationCode1: Code[10];
        LocationCode2: Code[10];
    begin
        // [FEATURE] [Component] [Quantity Per]
        // [SCENARIO 4232] "Scheduled Receipts" on the page line counts Transfer Orders
        Initialize();

        LocationCode1 := LocationRed.Code;
        LocationCode2 := LocationBlue.Code;
        // [GIVEN] Create the assembled Item "X" with a component "C"
        LibraryInventory.CreateItem(Item);
        AddComponent(Item, BOMComponent);
        // [GIVEN] Component's "Quantity per" = "Qp"
        SetRandComponentQuantityPer(BOMComponent);
        // [GIVEN] Create Component variant "CV", not in assembly list
        ItemVariantCode := CreateItemVariant(BOMComponent."No.");
        // [GIVEN] Create Transfer Orders for combinations: "CV" on "L1","CV" on "L2","C" on "L2"
        CreateTransferOrder(TransferHeader, BOMComponent."No.", ItemVariantCode, LocationCode1, LocationCode2, WorkDate2, RandInt());
        CreateTransferOrder(TransferHeader, BOMComponent."No.", ItemVariantCode, LocationCode2, LocationCode1, WorkDate2, RandInt());
        CreateTransferOrder(TransferHeader, BOMComponent."No.", '', LocationCode2, LocationCode1, WorkDate10D, RandInt());
        // [GIVEN] Create Transfer Order for "C" on moving from "L2" to "L1"
        QtyOnTO := CreateTransferOrder(TransferHeader, BOMComponent."No.", '', LocationCode2, LocationCode1, WorkDate2, RandInt());

        // [WHEN] Create Assembly Order for item "X" for location "L1"
        CreateAssemblyOrderOnSafeDate(AssemblyHeader, Item."No.", LocationCode1, '', WorkDate2, RandInt());

        // [THEN] Assembly Availability Line: "Scheduled Receipts" = "Q", "Expected Inventory" = "Q"
        ExpAsmAvailTestBuf.Init();
        ExpAsmAvailTestBuf."Document Line No." := 1;
        ExpAsmAvailTestBuf.Validate("Scheduled Receipts", QtyOnTO);
        ExpAsmAvailTestBuf.Validate("Expected Inventory", QtyOnTO);
        // [THEN] "Able To Assemble" = ("Q" / "Qp")
        ExpAsmAvailTestBuf.Validate("Able To Assemble", QtyOnTO / BOMComponent."Quantity per");
        AssertAvailabilityLine(AssemblyHeader, ExpAsmAvailTestBuf);
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,SendAssemblyAvailabilityNotificationHandler')]
    [Scope('OnPrem')]
    procedure AbleToAssembleQtyPerUOMAsmItem()
    var
        Item: Record Item;
        BOMComponent: array[2] of Record "BOM Component";
        AssemblyHeader: Record "Assembly Header";
        UnitOfMeasure: Record "Unit of Measure";
        ExpAsmAvailTestBuf: Record "Asm. Availability Test Buffer";
        AbleToAssemble: array[2] of Decimal;
        QtyOnInventory: array[2] of Integer;
        QtyOnAssemble: Integer;
        QtyPerAsm: Integer;
        i: Integer;
        LocationCode: Code[10];
    begin
        // [FEATURE] [Quantity Per]
        // [SCENARIO 4233] "Able To Assemble" is calculated considering "Qty. Per Unit of Measure" of assembled Item
        Initialize();

        LocationCode := '';
        // [GIVEN] Create the assembled Item "X"
        LibraryInventory.CreateItem(Item);
        // [GIVEN] Add another UOM, "Quantity per" = "Qp"
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        QtyPerAsm := AddItemUOM(Item, UnitOfMeasure.Code);
        // [GIVEN] Add two components ("C1", "C2")
        for i := 1 to 2 do begin
            AddComponent(Item, BOMComponent[i]);
            // [GIVEN] Component's "Quantity per" = ("Qp1", "Qp2")
            SetRandComponentQuantityPer(BOMComponent[i]);
            // [GIVEN] Add Inventory ("Q1", "Q2")
            QtyOnInventory[i] := RandInt();
            AddInventory(BOMComponent[i]."No.", '', LocationCode, QtyOnInventory[i]);
            AbleToAssemble[i] := QtyOnInventory[i] / (BOMComponent[i]."Quantity per" * QtyPerAsm);
        end;
        // [GIVEN] Create Assembly Order for item "X"
        QtyOnAssemble := QtyOnInventory[1] + QtyOnInventory[2];
        CreateAssemblyOrder(AssemblyHeader, Item."No.", LocationCode, '', WorkDate2, QtyOnAssemble);

        // [WHEN] Change "Unit Of Measure Code" on Assembly Order header
        ChangeUOMOnAsmOrder(AssemblyHeader, UnitOfMeasure.Code);
        Commit();

        AssemblyHeader.ShowAvailability();

        // [THEN] Assembly Availability header: "Able To Assemble" is minimal of "Able To Assemble" in lines
        ExpAsmAvailTestBuf.Init();
        ExpAsmAvailTestBuf.Validate("Able To Assemble", MinValue(AbleToAssemble[1], AbleToAssemble[2]));
        AssertAvailabilityHeader(AssemblyHeader, ExpAsmAvailTestBuf);
        // [THEN] Assembly Availability line: "Able To Assemble" = "Q1" / ("Qp1" * "Qp")
        for i := 1 to 2 do begin
            Clear(ExpAsmAvailTestBuf);
            ExpAsmAvailTestBuf."Document Line No." := i;
            ExpAsmAvailTestBuf.Validate("Expected Inventory", QtyOnInventory[i]);
            ExpAsmAvailTestBuf.Validate("Able To Assemble", AbleToAssemble[i]);
            AssertAvailabilityLine(AssemblyHeader, ExpAsmAvailTestBuf);
        end;
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,SendAssemblyAvailabilityNotificationHandler')]
    [Scope('OnPrem')]
    procedure AbleToAssembleQtyPerUOMComponent()
    var
        Item: Record Item;
        BOMComponent: array[2] of Record "BOM Component";
        AssemblyHeader: Record "Assembly Header";
        UnitOfMeasure: Record "Unit of Measure";
        ExpAsmAvailTestBuf: Record "Asm. Availability Test Buffer";
        AbleToAssemble: array[2] of Decimal;
        QtyOnInventory: array[2] of Integer;
        QtyOnAssemble: Integer;
        QtyPerComp: array[2] of Integer;
        i: Integer;
        LocationCode: Code[10];
    begin
        // [FEATURE] [Quantity Per]
        // [SCENARIO 4234] "Able To Assemble" is calculated considering "Qty. Per Unit of Measure" of components
        Initialize();

        LocationCode := '';
        // [GIVEN] Create the assembled Item "X"
        LibraryInventory.CreateItem(Item);
        // [GIVEN] Add two components ("C1", "C2")
        for i := 1 to 2 do begin
            AddComponent(Item, BOMComponent[i]);
            // [GIVEN] Component's "Quantity per" = ("Qp1", "Qp2")
            SetRandComponentQuantityPer(BOMComponent[i]);
            // [GIVEN] Add another UOM for Component, "Quantity Per UOM" = ("QU1", "QU2")
            LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
            QtyPerComp[i] := RandInt();
            AddComponentUOM(BOMComponent[i], QtyPerComp[i], UnitOfMeasure.Code);
            // [GIVEN] Add Inventory ("Q1", "Q2")
            QtyOnInventory[i] := RandInt();
            AddInventory(BOMComponent[i]."No.", '', LocationCode, QtyOnInventory[i]);
            AbleToAssemble[i] := QtyOnInventory[i] / (BOMComponent[i]."Quantity per" * QtyPerComp[i]);
        end;

        // [WHEN] Create Assembly Order for item "X"
        QtyOnAssemble := QtyOnInventory[1] + QtyOnInventory[2];
        CreateAssemblyOrder(AssemblyHeader, Item."No.", LocationCode, '', WorkDate2, QtyOnAssemble);

        // [THEN] Assembly Availability header: "Able To Assemble" is minimal of "Able To Assemble" in lines
        ExpAsmAvailTestBuf.Init();
        ExpAsmAvailTestBuf.Validate("Able To Assemble", MinValue(AbleToAssemble[1], AbleToAssemble[2]));
        AssertAvailabilityHeader(AssemblyHeader, ExpAsmAvailTestBuf);
        // [THEN] Assembly Availability line: "Able To Assemble" = "Q1" / ("Qp1" * "QU1")
        for i := 1 to 2 do begin
            ExpAsmAvailTestBuf."Document Line No." := i;
            ExpAsmAvailTestBuf.Validate("Expected Inventory", QtyOnInventory[i] / QtyPerComp[i]);
            ExpAsmAvailTestBuf.Validate("Able To Assemble", AbleToAssemble[i]);
            AssertAvailabilityLine(AssemblyHeader, ExpAsmAvailTestBuf);
        end;
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,SendAssemblyAvailabilityNotificationHandler')]
    [Scope('OnPrem')]
    procedure AssemblyAvailabilityStaticData()
    var
        Item: Record Item;
        BOMComponent: Record "BOM Component";
        AssemblyHeader: Record "Assembly Header";
        LocationCode: Code[10];
    begin
        // [SCENARIO] Assembly Availability header and line contains static data form the source Assembly Order
        Initialize();

        LocationCode := '';
        // [GIVEN] Create the assembled Item "X"
        LibraryInventory.CreateItem(Item);
        // [GIVEN] Add first Component "C1"
        AddComponent(Item, BOMComponent);
        // [GIVEN] Add second Component "C2", "Quantity per" = "Qp"
        AddComponent(Item, BOMComponent);
        SetRandComponentQuantityPer(BOMComponent);
        // [GIVEN] Create Component Variant "C2V", include to assembly list asm list
        SetVariantOnComponent(BOMComponent, CreateItemVariant(BOMComponent."No."));

        // [WHEN] Create Assembly Order for Item "X"
        CreateAssemblyOrder(AssemblyHeader, Item."No.", LocationCode, '', WorkDate2, RandInt());

        // [THEN]  Assembly Availability page header and line contains correct values: Item No, Variant Code, Location Code, UOM, Quantity
        AssertAvailabilityHeaderStatic(AssemblyHeader);
        AssertAvailabilityLineStatic(AssemblyHeader, 1);
        AssertAvailabilityLineStatic(AssemblyHeader, 2);
        // [THEN] the Page contains two lines
        asserterror AssertAvailabilityLineStatic(AssemblyHeader, 3);
        Assert.ExpectedErrorCannotFind(Database::"Asm. Availability Test Buffer");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssemblyLineQtyWhenChangingUOMQuantityPer()
    var
        AssemblyLine: Record "Assembly Line";
        Item: Record Item;
        BOMComponent: Record "BOM Component";
        AssemblyHeader: Record "Assembly Header";
        UnitOfMeasure: Record "Unit of Measure";
        QtyOnAssemble: Integer;
        QtyPerAsm: Integer;
        ExpectedQtyPer: Decimal;
        LocationCode: Code[10];
    begin
        // [FEATURE] [Quantity Per]
        // [SCENARIO] Assembly Line quantities are calculated considering "Quantity per" on Component and on assembled Item
        Initialize();

        LocationCode := LocationRed.Code;
        // [GIVEN] Create the assembled Item "X"
        LibraryInventory.CreateItem(Item);
        // [GIVEN] Add UOM "U2" for Item "X", where "Qty Per UOM" = "Qp"
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        QtyPerAsm := AddItemUOM(Item, UnitOfMeasure.Code);
        // [GIVEN] Add Component "C" with UOM, where "Qty Per UOM" = "Qp1"
        AddComponent(Item, BOMComponent);
        SetRandComponentQuantityPer(BOMComponent);
        ExpectedQtyPer := BOMComponent."Quantity per" * QtyPerAsm;
        // [GIVEN] Create Assembly Order for Item "X", Quantity = "Q"
        QtyOnAssemble := CreateAssemblyOrder(AssemblyHeader, Item."No.", LocationCode, '', WorkDate2, RandInt());

        // [WHEN] Change Assembly Header's "Unit of Measure" to "U2"
        ChangeUOMOnAsmOrder(AssemblyHeader, UnitOfMeasure.Code);

        // [THEN] Assembly Line: "Quantity per" = ("Qp" * "Qp1")
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.FindFirst();
        Assert.AreEqual(
          ExpectedQtyPer, AssemblyLine."Quantity per", StrSubstNo(WrongValueInAsmLineErr, AssemblyLine.FieldName("Quantity per")));
        // [THEN] Assembly Line: "Quantity","Quantity to Consume","Remaining Quantity" = ("Quantity per" * "Q")
        Assert.AreEqual(
          ExpectedQtyPer * QtyOnAssemble, AssemblyLine.Quantity, StrSubstNo(WrongValueInAsmLineErr, AssemblyLine.FieldName(Quantity)));
        Assert.AreEqual(
          ExpectedQtyPer * QtyOnAssemble, AssemblyLine."Quantity to Consume",
          StrSubstNo(WrongValueInAsmLineErr, AssemblyLine.FieldName("Quantity to Consume")));
        Assert.AreEqual(
          ExpectedQtyPer * QtyOnAssemble, AssemblyLine."Remaining Quantity",
          StrSubstNo(WrongValueInAsmLineErr, AssemblyLine.FieldName("Remaining Quantity")));

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler,SendAssemblyAvailabilityNotificationHandler')]
    [Scope('OnPrem')]
    procedure LineAbleToAssembleAfterPostedOrderUndo()
    var
        Item: Record Item;
        BOMComponent: Record "BOM Component";
        AssemblyHeader: Record "Assembly Header";
        PostedAssemblyHeader: Record "Posted Assembly Header";
        ExpAsmAvailTestBuf: Record "Asm. Availability Test Buffer";
        QtyOnAssemble: Integer;
    begin
        // [FEATURE] [Undo Assembly Order]
        // [SCENARIO] "Able To Assemble" on page line is calculated correctly after Undo of posted Assembly Order
        Initialize();

        // [GIVEN] Create the assembled Item "X"
        LibraryInventory.CreateItem(Item);
        // [GIVEN] Add Component "C" , "Quantity per" = "Qp"
        AddComponent(Item, BOMComponent);
        SetRandComponentQuantityPer(BOMComponent);
        // [GIVEN] Add Component to inventory, enough to assemble "QA" psc, Quantity = ("QA" * "Qp")
        QtyOnAssemble := RandInt();
        AddInventory(BOMComponent."No.", '', '', BOMComponent."Quantity per" * QtyOnAssemble);
        // [GIVEN] Create Assembly Order for Item "X", Quantity = "QA"
        CreateAssemblyOrder(AssemblyHeader, Item."No.", '', '', WorkDate2, QtyOnAssemble);
        // [GIVEN] Post half Assembly Order
        PostAssemblyOrderQty(AssemblyHeader, QtyOnAssemble / 2);

        // [GIVEN] Undo Assembly Order and delete it
        FindPostedAssemblyHeaderNotReversed(PostedAssemblyHeader, AssemblyHeader."No.");
        LibraryAssembly.UndoPostedAssembly(PostedAssemblyHeader, true, '');
        AssemblyHeader.Get(AssemblyHeader."Document Type", AssemblyHeader."No.");
        AssemblyHeader.Delete(true);

        // [WHEN] Create new Assembly Order for Item "X", Quantity = ("QA" + 1) to cause Availability page
        CreateAssemblyOrder(AssemblyHeader, Item."No.", '', '', WorkDate2, QtyOnAssemble + 1);

        // [THEN] Assembly Availability page is shown: "Expected Inventory" = ("QA" * "Qp"), "Able To Assemble" = "QA"
        ExpAsmAvailTestBuf.Init();
        ExpAsmAvailTestBuf."Document Line No." := 1;
        ExpAsmAvailTestBuf.Validate("Expected Inventory", BOMComponent."Quantity per" * QtyOnAssemble);
        ExpAsmAvailTestBuf.Validate("Able To Assemble", QtyOnAssemble);
        AssertAvailabilityLine(AssemblyHeader, ExpAsmAvailTestBuf);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendAssemblyAvailabilityNotificationHandler(var Notification: Notification): Boolean
    var
        AssemblyLineManagement: Codeunit "Assembly Line Management";
    begin
        AssemblyLineManagement.ShowNotificationDetails(Notification);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailabilityWindowHandler(var AsmAvailabilityCheck: TestPage "Assembly Availability Check")
    begin
        ReadDataFromCheckPage(TempAsmAvailTestBuf, AsmAvailabilityCheck);
    end;

    local procedure ComponentsAvailable(AssemblyHeader: Record "Assembly Header"): Boolean
    begin
        exit(LibraryAssembly.ComponentsAvailable(AssemblyHeader));
    end;

    local procedure ReadDataFromCheckPage(var TempAsmAvailabilityTestBuf: Record "Asm. Availability Test Buffer" temporary; var AsmAvailabilityCheck: TestPage "Assembly Availability Check")
    begin
        TempAsmAvailabilityTestBuf.Reset();
        TempAsmAvailabilityTestBuf.DeleteAll();

        TempAsmAvailabilityTestBuf.Init();
        ReadHeaderFromPage(TempAsmAvailabilityTestBuf, AsmAvailabilityCheck);
        TempAsmAvailabilityTestBuf.Insert();

        if AsmAvailabilityCheck.AssemblyLineAvail.First() then
            repeat
                TempAsmAvailabilityTestBuf.Init();
                ReadLineFromPage(TempAsmAvailabilityTestBuf, AsmAvailabilityCheck);
                TempAsmAvailabilityTestBuf.Insert();
            until not AsmAvailabilityCheck.AssemblyLineAvail.Next();
    end;

    local procedure ReadHeaderFromPage(var TempAsmAvailabilityTestBuf: Record "Asm. Availability Test Buffer" temporary; var AsmAvailabilityCheck: TestPage "Assembly Availability Check")
    begin
        TempAsmAvailabilityTestBuf."Document No." := AsmAvailabilityCheck."No.".Value();
        TempAsmAvailabilityTestBuf."Document Line No." := 0;
        TempAsmAvailabilityTestBuf."Item No." := AsmAvailabilityCheck."Item No.".Value();
        TempAsmAvailabilityTestBuf."Variant Code" := AsmAvailabilityCheck."Variant Code".Value();
        TempAsmAvailabilityTestBuf."Location Code" := AsmAvailabilityCheck."Location Code".Value();
        TempAsmAvailabilityTestBuf."Unit of Measure Code" := AsmAvailabilityCheck."Unit of Measure Code".Value();
        TempAsmAvailabilityTestBuf.Description := AsmAvailabilityCheck.Description.Value();
        TempAsmAvailabilityTestBuf.Quantity := AsmAvailabilityCheck."Current Quantity".AsDecimal();
        TempAsmAvailabilityTestBuf.Inventory := AsmAvailabilityCheck.Inventory.AsDecimal();
        TempAsmAvailabilityTestBuf."Gross Requirement" := AsmAvailabilityCheck.GrossRequirement.AsDecimal();
        TempAsmAvailabilityTestBuf."Scheduled Receipts" := AsmAvailabilityCheck.ScheduledReceipts.AsDecimal();
        TempAsmAvailabilityTestBuf."Able To Assemble" := AsmAvailabilityCheck.AbleToAssemble.AsDecimal();
        Evaluate(TempAsmAvailabilityTestBuf."Earliest Availability Date", AsmAvailabilityCheck.EarliestAvailableDate.Value);
    end;

    local procedure ReadLineFromPage(var TempAsmAvailabilityTestBuf: Record "Asm. Availability Test Buffer" temporary; var AsmAvailabilityCheck: TestPage "Assembly Availability Check")
    begin
        TempAsmAvailabilityTestBuf."Document No." := AsmAvailabilityCheck."No.".Value();
        TempAsmAvailabilityTestBuf."Document Line No." += 1;
        TempAsmAvailabilityTestBuf."Item No." := AsmAvailabilityCheck.AssemblyLineAvail."No.".Value();
        TempAsmAvailabilityTestBuf."Variant Code" := AsmAvailabilityCheck.AssemblyLineAvail."Variant Code".Value();
        TempAsmAvailabilityTestBuf."Location Code" := AsmAvailabilityCheck.AssemblyLineAvail."Location Code".Value();
        TempAsmAvailabilityTestBuf."Unit of Measure Code" := AsmAvailabilityCheck.AssemblyLineAvail."Unit of Measure Code".Value();
        TempAsmAvailabilityTestBuf."Quantity Per" := AsmAvailabilityCheck.AssemblyLineAvail."Quantity per".AsDecimal();
        TempAsmAvailabilityTestBuf.Quantity := AsmAvailabilityCheck.AssemblyLineAvail.CurrentQuantity.AsDecimal();
        TempAsmAvailabilityTestBuf."Gross Requirement" := AsmAvailabilityCheck.AssemblyLineAvail.GrossRequirement.AsDecimal();
        TempAsmAvailabilityTestBuf."Scheduled Receipts" := AsmAvailabilityCheck.AssemblyLineAvail.ScheduledReceipt.AsDecimal();
        TempAsmAvailabilityTestBuf."Expected Inventory" := AsmAvailabilityCheck.AssemblyLineAvail.ExpectedAvailableInventory.AsDecimal();
        TempAsmAvailabilityTestBuf."Able To Assemble" := AsmAvailabilityCheck.AssemblyLineAvail.AbleToAssemble.AsDecimal();
        Evaluate(TempAsmAvailabilityTestBuf."Earliest Availability Date", AsmAvailabilityCheck.AssemblyLineAvail.EarliestAvailableDate.Value);
    end;

}

