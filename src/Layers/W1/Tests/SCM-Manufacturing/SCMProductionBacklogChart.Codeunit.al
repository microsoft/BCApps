// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using Microsoft.Manufacturing.Document;
using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Setup;

codeunit 137111 "SCM Production Backlog Chart"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Manufacturing] [Production Order] [SCM]
        isInitialized := false;
    end;

    var
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;

    [Normal]
    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Production Backlog Chart");
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Production Backlog Chart");

        isInitialized := true;
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Production Backlog Chart");
    end;

    [Normal]
    local procedure SetupDelayedProdOrders(ProdItems: Integer; Simulated: Integer; Planned: Integer; FirmPlanned: Integer; Released: Integer)
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        TempItem: Record Item temporary;
        DelayedProdOrdersByCost: Query "Delayed Prod. Orders - by Cost";
        Qty: Decimal;
        CostAmount: Decimal;
        TotalCostAmount: Decimal;
        PrevTotalCostAmount: Decimal;
        "count": Decimal;
    begin
        // Setup.
        Initialize();
        for count := 1 to ProdItems do begin
            LibraryAssembly.CreateItem(Item, Item."Costing Method"::Standard, Item."Replenishment System"::"Prod. Order", '', '');
            LibraryManufacturing.CreateProductionBOM(Item, 1);
            CreateProdOrders(Item."No.", ProductionOrder.Status::Simulated, Simulated);
            CreateProdOrders(Item."No.", ProductionOrder.Status::Planned, Planned);
            CreateProdOrders(Item."No.", ProductionOrder.Status::"Firm Planned", FirmPlanned);
            CreateProdOrders(Item."No.", ProductionOrder.Status::Released, Released);
            TempItem := Item;
            TempItem.Insert();
        end;

        // Verify query: Query - database consistency.
        DelayedProdOrdersByCost.Open();
        count := 0;
        while DelayedProdOrdersByCost.Read() do begin
            count += 1;
            GetExpectedProdOrderBacklog(
              Qty, CostAmount, TotalCostAmount, '<=', false, DelayedProdOrdersByCost.Status, DelayedProdOrdersByCost.Item_No);
            if count > 1 then
                Assert.IsTrue(
                  PrevTotalCostAmount >= TotalCostAmount,
                  'Query is not sorted by ' + DelayedProdOrdersByCost.ColumnCaption(Cost_of_Open_Production_Orders));
            Assert.AreEqual(Qty, DelayedProdOrdersByCost.Sum_Remaining_Quantity, 'Item: ' + DelayedProdOrdersByCost.Item_No + '; field: ' + DelayedProdOrdersByCost.ColumnCaption(Sum_Remaining_Quantity));
            Assert.AreEqual(
              TotalCostAmount, DelayedProdOrdersByCost.Cost_of_Open_Production_Orders, 'Item: ' + DelayedProdOrdersByCost.Item_No + '; field: ' + DelayedProdOrdersByCost.ColumnCaption(Cost_of_Open_Production_Orders));
            Assert.AreNotEqual(
              ProductionOrder.Status::Simulated, DelayedProdOrdersByCost.Status, 'Item: ' + DelayedProdOrdersByCost.Item_No + '; field: ' + DelayedProdOrdersByCost.ColumnCaption(Status));
            Assert.AreNotEqual(
              ProductionOrder.Status::Finished, DelayedProdOrdersByCost.Status, 'Item: ' + DelayedProdOrdersByCost.Item_No + '; field: ' + DelayedProdOrdersByCost.ColumnCaption(Status));
            PrevTotalCostAmount := TotalCostAmount;
        end;
        DelayedProdOrdersByCost.Close();

        // Verify query: Database - query consistency.
        TempItem.FindSet();
        repeat
            VerifyDelayedBacklogRecords(TempItem."No.", ProductionOrder.Status::Planned);
            VerifyDelayedBacklogRecords(TempItem."No.", ProductionOrder.Status::"Firm Planned");
            VerifyDelayedBacklogRecords(TempItem."No.", ProductionOrder.Status::Released);
        until TempItem.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DelayedProdOrdersByCost()
    begin
        SetupDelayedProdOrders(2, 2, 2, 2, 2);
    end;

    [Normal]
    local procedure SetupTop10ProdOrders(ProdItems: Integer; Simulated: Integer; Planned: Integer; FirmPlanned: Integer; Released: Integer)
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        Top10ProdOrdersByCost: Query "Top-10 Prod. Orders - by Cost";
        Qty: Decimal;
        CostAmount: Decimal;
        TotalCostAmount: Decimal;
        PrevTotalCostAmount: Decimal;
        "count": Decimal;
    begin
        // Setup.
        Initialize();
        for count := 1 to ProdItems do begin
            LibraryAssembly.CreateItem(Item, Item."Costing Method"::Standard, Item."Replenishment System"::"Prod. Order", '', '');
            LibraryManufacturing.CreateProductionBOM(Item, 1);
            CreateProdOrders(Item."No.", ProductionOrder.Status::Simulated, Simulated);
            CreateProdOrders(Item."No.", ProductionOrder.Status::Planned, Planned);
            CreateProdOrders(Item."No.", ProductionOrder.Status::"Firm Planned", FirmPlanned);
            CreateProdOrders(Item."No.", ProductionOrder.Status::Released, Released);
        end;

        // Verify query: Query - database consistency.
        count := 0;
        Top10ProdOrdersByCost.Open();
        while Top10ProdOrdersByCost.Read() do begin
            GetExpectedProdOrderBacklog(
              Qty, CostAmount, TotalCostAmount, '', false, Top10ProdOrdersByCost.Status, Top10ProdOrdersByCost.Item_No);
            count += 1;
            if count > 1 then
                Assert.IsTrue(
                  PrevTotalCostAmount >= TotalCostAmount,
                  'Query is not sorted by ' + Top10ProdOrdersByCost.ColumnCaption(Cost_of_Open_Production_Orders));
            Assert.AreEqual(Qty, Top10ProdOrdersByCost.Sum_Remaining_Quantity, 'Item: ' + Top10ProdOrdersByCost.Item_No + '; field: ' + Top10ProdOrdersByCost.ColumnCaption(Sum_Remaining_Quantity));
            Assert.AreEqual(
              TotalCostAmount, Top10ProdOrdersByCost.Cost_of_Open_Production_Orders, 'Item: ' + Top10ProdOrdersByCost.Item_No + '; field: ' + Top10ProdOrdersByCost.ColumnCaption(Cost_of_Open_Production_Orders));
            Assert.AreNotEqual(ProductionOrder.Status::Simulated, Top10ProdOrdersByCost.Status, 'Item: ' + Top10ProdOrdersByCost.Item_No + '; field: ' + Top10ProdOrdersByCost.ColumnCaption(Status));
            Assert.AreNotEqual(ProductionOrder.Status::Finished, Top10ProdOrdersByCost.Status, 'Item: ' + Top10ProdOrdersByCost.Item_No + '; field: ' + Top10ProdOrdersByCost.ColumnCaption(Status));
            PrevTotalCostAmount := TotalCostAmount;
        end;
        Top10ProdOrdersByCost.Close();
        Assert.IsTrue(Top10ProdOrdersByCost.TopNumberOfRows = 10, 'More than 10 records returned by query.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Top10ProdOrdersByCost()
    begin
        SetupTop10ProdOrders(1, 2, 2, 2, 2);
    end;

    [Normal]
    local procedure SetupPendingProdOrders(ProdItems: Integer; Simulated: Integer; Planned: Integer; FirmPlanned: Integer; Released: Integer)
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        TempItem: Record Item temporary;
        PendingProdOrdersByCost: Query "Pending Prod. Orders - by Cost";
        Qty: Decimal;
        CostAmount: Decimal;
        TotalCostAmount: Decimal;
        PrevTotalCostAmount: Decimal;
        "count": Decimal;
    begin
        // Setup.
        Initialize();
        for count := 1 to ProdItems do begin
            LibraryAssembly.CreateItem(Item, Item."Costing Method"::Standard, Item."Replenishment System"::"Prod. Order", '', '');
            LibraryManufacturing.CreateProductionBOM(Item, 1);
            CreateProdOrders(Item."No.", ProductionOrder.Status::Simulated, Simulated);
            CreateProdOrders(Item."No.", ProductionOrder.Status::Planned, Planned);
            CreateProdOrders(Item."No.", ProductionOrder.Status::"Firm Planned", FirmPlanned);
            CreateProdOrders(Item."No.", ProductionOrder.Status::Released, Released);
            TempItem := Item;
            TempItem.Insert();
        end;

        // Verify query: Query - database consistency.
        PendingProdOrdersByCost.Open();
        count := 0;
        while PendingProdOrdersByCost.Read() do begin
            count += 1;
            GetExpectedProdOrderBacklog(
              Qty, CostAmount, TotalCostAmount, '>=', false, PendingProdOrdersByCost.Status, PendingProdOrdersByCost.Item_No);
            if count > 1 then
                Assert.IsTrue(
                  PrevTotalCostAmount >= TotalCostAmount,
                  'Query is not sorted by ' + PendingProdOrdersByCost.ColumnCaption(Cost_of_Open_Production_Orders));
            Assert.AreEqual(Qty, PendingProdOrdersByCost.Sum_Remaining_Quantity, 'Item: ' + PendingProdOrdersByCost.Item_No + '; field: ' + PendingProdOrdersByCost.ColumnCaption(Sum_Remaining_Quantity));
            Assert.AreEqual(
              TotalCostAmount, PendingProdOrdersByCost.Cost_of_Open_Production_Orders, 'Item: ' + PendingProdOrdersByCost.Item_No + '; field: ' + PendingProdOrdersByCost.ColumnCaption(Cost_of_Open_Production_Orders));
            Assert.AreNotEqual(
              ProductionOrder.Status::Simulated, PendingProdOrdersByCost.Status, 'Item: ' + PendingProdOrdersByCost.Item_No + '; field: ' + PendingProdOrdersByCost.ColumnCaption(Status));
            Assert.AreNotEqual(
              ProductionOrder.Status::Finished, PendingProdOrdersByCost.Status, 'Item: ' + PendingProdOrdersByCost.Item_No + '; field: ' + PendingProdOrdersByCost.ColumnCaption(Status));
            PrevTotalCostAmount := TotalCostAmount;
        end;
        PendingProdOrdersByCost.Close();

        // Verify query: Database - query consistency.
        TempItem.FindSet();
        repeat
            VerifyPendingBacklogRecords(TempItem."No.", ProductionOrder.Status::Planned);
            VerifyPendingBacklogRecords(TempItem."No.", ProductionOrder.Status::"Firm Planned");
            VerifyPendingBacklogRecords(TempItem."No.", ProductionOrder.Status::Released);
        until TempItem.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PendingProdOrdersByCost()
    begin
        SetupPendingProdOrders(2, 2, 2, 2, 2);
    end;

    [Normal]
    local procedure SetupMyDelayedProdOrders(ProdItems: Integer; Simulated: Integer; Planned: Integer; FirmPlanned: Integer; Released: Integer)
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        TempItem: Record Item temporary;
        MyItem: Record "My Item";
        MyDelayedProdOrders: Query "My Delayed Prod. Orders";
        Qty: Decimal;
        CostAmount: Decimal;
        TotalCostAmount: Decimal;
        "count": Decimal;
    begin
        // Setup.
        Initialize();
        for count := 1 to ProdItems do begin
            LibraryAssembly.CreateItem(Item, Item."Costing Method"::Standard, Item."Replenishment System"::"Prod. Order", '', '');
            LibraryManufacturing.CreateProductionBOM(Item, 1);
            CreateProdOrders(Item."No.", ProductionOrder.Status::Simulated, Simulated);
            CreateProdOrders(Item."No.", ProductionOrder.Status::Planned, Planned);
            CreateProdOrders(Item."No.", ProductionOrder.Status::"Firm Planned", FirmPlanned);
            CreateProdOrders(Item."No.", ProductionOrder.Status::Released, Released);
            if count mod 2 = 0 then begin
                MyItem.Init();
                MyItem.Validate("User ID", UserId);
                MyItem.Validate("Item No.", Item."No.");
                MyItem.Insert();
            end;
            TempItem := Item;
            TempItem.Insert();
        end;

        // Verify query: Query - database consistency.
        MyDelayedProdOrders.SetFilter(User_ID, UserId);
        MyDelayedProdOrders.Open();
        while MyDelayedProdOrders.Read() do begin
            GetExpectedProdOrderBacklog(Qty, CostAmount, TotalCostAmount, '<=', true, MyDelayedProdOrders.Status, MyDelayedProdOrders.Item_No);
            Assert.AreEqual(Qty, MyDelayedProdOrders.Sum_Remaining_Quantity, 'Item: ' + MyDelayedProdOrders.Item_No + '; field: ' + MyDelayedProdOrders.ColumnCaption(Sum_Remaining_Quantity));
            Assert.AreNotEqual(ProductionOrder.Status::Simulated, MyDelayedProdOrders.Status, 'Item: ' + MyDelayedProdOrders.Item_No + '; field: ' + MyDelayedProdOrders.ColumnCaption(Status));
            Assert.AreNotEqual(ProductionOrder.Status::Finished, MyDelayedProdOrders.Status, 'Item: ' + MyDelayedProdOrders.Item_No + '; field: ' + MyDelayedProdOrders.ColumnCaption(Status));
        end;
        MyDelayedProdOrders.Close();

        // Verify query: Database - query consistency.
        TempItem.FindSet();
        repeat
            VerifyMyDelayedBacklogRecords(TempItem."No.", ProductionOrder.Status::Planned);
            VerifyMyDelayedBacklogRecords(TempItem."No.", ProductionOrder.Status::"Firm Planned");
            VerifyMyDelayedBacklogRecords(TempItem."No.", ProductionOrder.Status::Released);
        until TempItem.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MyDelayedProdOrders()
    begin
        SetupMyDelayedProdOrders(3, 2, 2, 2, 2);
    end;

    [Normal]
    local procedure SetupMyProdOrders(ProdItems: Integer; Simulated: Integer; Planned: Integer; FirmPlanned: Integer; Released: Integer)
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        TempItem: Record Item temporary;
        MyItem: Record "My Item";
        MyProdOrdersByCost: Query "My Prod. Orders - By Cost";
        Qty: Decimal;
        CostAmount: Decimal;
        TotalCostAmount: Decimal;
        PrevTotalCostAmount: Decimal;
        "count": Decimal;
    begin
        // Setup.
        Initialize();
        for count := 1 to ProdItems do begin
            LibraryAssembly.CreateItem(Item, Item."Costing Method"::Standard, Item."Replenishment System"::"Prod. Order", '', '');
            LibraryManufacturing.CreateProductionBOM(Item, 1);
            CreateProdOrders(Item."No.", ProductionOrder.Status::Simulated, Simulated);
            CreateProdOrders(Item."No.", ProductionOrder.Status::Planned, Planned);
            CreateProdOrders(Item."No.", ProductionOrder.Status::"Firm Planned", FirmPlanned);
            CreateProdOrders(Item."No.", ProductionOrder.Status::Released, Released);
            if count mod 2 = 0 then begin
                MyItem.Init();
                MyItem.Validate("User ID", UserId);
                MyItem.Validate("Item No.", Item."No.");
                MyItem.Insert();
            end;
            TempItem := Item;
            TempItem.Insert();
        end;

        // Verify query: Query - database consistency.
        MyProdOrdersByCost.SetFilter(User_ID, UserId);
        MyProdOrdersByCost.Open();
        count := 0;
        while MyProdOrdersByCost.Read() do begin
            count += 1;
            GetExpectedProdOrderBacklog(Qty, CostAmount, TotalCostAmount, '', true, MyProdOrdersByCost.Status, MyProdOrdersByCost.Item_No);
            if count > 1 then
                Assert.IsTrue(
                  PrevTotalCostAmount >= TotalCostAmount,
                  'Query is not sorted by ' + MyProdOrdersByCost.ColumnCaption(Cost_of_Open_Production_Orders));
            Assert.AreEqual(Qty, MyProdOrdersByCost.Sum_Remaining_Quantity, 'Item: ' + MyProdOrdersByCost.Item_No + '; field: ' + MyProdOrdersByCost.ColumnCaption(Sum_Remaining_Quantity));
            Assert.AreEqual(TotalCostAmount, MyProdOrdersByCost.Cost_of_Open_Production_Orders, 'Item: ' + MyProdOrdersByCost.Item_No + '; field: ' + MyProdOrdersByCost.ColumnCaption(Cost_of_Open_Production_Orders));
            Assert.AreNotEqual(ProductionOrder.Status::Simulated, MyProdOrdersByCost.Status, 'Item: ' + MyProdOrdersByCost.Item_No + '; field: ' + MyProdOrdersByCost.ColumnCaption(Status));
            Assert.AreNotEqual(ProductionOrder.Status::Finished, MyProdOrdersByCost.Status, 'Item: ' + MyProdOrdersByCost.Item_No + '; field: ' + MyProdOrdersByCost.ColumnCaption(Status));
            PrevTotalCostAmount := TotalCostAmount;
        end;
        MyProdOrdersByCost.Close();

        // Verify query: Database - query consistency.
        TempItem.FindSet();
        repeat
            VerifyMyBacklogRecords(TempItem."No.", ProductionOrder.Status::Planned);
            VerifyMyBacklogRecords(TempItem."No.", ProductionOrder.Status::"Firm Planned");
            VerifyMyBacklogRecords(TempItem."No.", ProductionOrder.Status::Released);
        until TempItem.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MyProdOrdersByCost()
    begin
        SetupMyProdOrders(3, 2, 2, 2, 2);
    end;

    [Normal]
    local procedure CreateProdOrders(ItemNo: Code[20]; Status: Enum "Production Order Status"; NoOfOrders: Integer)
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ProductionOrder: Record "Production Order";
        "count": Integer;
    begin
        ManufacturingSetup.Get();
        for count := 1 to NoOfOrders do begin
            LibraryManufacturing.CreateProductionOrder(
              ProductionOrder, Status, ProductionOrder."Source Type"::Item, ItemNo, LibraryRandom.RandDec(10, 2));
            ProductionOrder.Validate("Ending Date", Today + 10 * Power(-1, count) * count);
            ProductionOrder.Validate("Due Date", ProductionOrder."Ending Date");
            ProductionOrder.Modify(true);
            LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        end;
    end;

    [Normal]
    local procedure GetExpectedProdOrderBacklog(var Qty: Decimal; var CostAmount: Decimal; var TotalCostAmount: Decimal; DateFilter: Text; UseMyItem: Boolean; Status: Enum "Production Order Status"; ItemNo: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
        MyItem: Record "My Item";
        Item: Record Item;
    begin
        Qty := 0;
        CostAmount := 0;
        TotalCostAmount := 0;

        ProdOrderLine.SetRange(Status, Status);
        ProdOrderLine.SetRange("Item No.", ItemNo);
        if DateFilter <> '' then
            ProdOrderLine.SetFilter("Due Date", DateFilter + '%1', Today)
        else
            ProdOrderLine.SetRange("Due Date");

        if UseMyItem and (not MyItem.Get(UserId, ItemNo)) then
            exit;

        if ProdOrderLine.FindSet() then
            repeat
                Qty += ProdOrderLine."Remaining Quantity";
                CostAmount += ProdOrderLine."Cost Amount";
            until ProdOrderLine.Next() = 0;

        Item.Get(ItemNo);
        Item.CalcFields("Cost of Open Production Orders");
        TotalCostAmount := Item."Cost of Open Production Orders";
    end;

    [Normal]
    local procedure VerifyDelayedBacklogRecords(ItemNo: Code[20]; Status: Enum "Production Order Status")
    var
        DelayedProdOrdersByCost: Query "Delayed Prod. Orders - by Cost";
        Qty: Decimal;
        CostAmount: Decimal;
        TotalCostAmount: Decimal;
        ExpQueryRecords: Integer;
        ActQueryRecords: Integer;
    begin
        GetExpectedProdOrderBacklog(Qty, CostAmount, TotalCostAmount, '<=', false, Status, ItemNo);
        ExpQueryRecords := 0;
        if Qty > 0 then
            ExpQueryRecords := 1;

        DelayedProdOrdersByCost.Open();
        while DelayedProdOrdersByCost.Read() do
            if (DelayedProdOrdersByCost.Item_No = ItemNo) and (DelayedProdOrdersByCost.Status = Status) then begin
                Assert.AreEqual(Qty, DelayedProdOrdersByCost.Sum_Remaining_Quantity, 'Item: ' + DelayedProdOrdersByCost.Item_No + '; field: ' + DelayedProdOrdersByCost.ColumnCaption(Sum_Remaining_Quantity));
                Assert.AreEqual(
                  TotalCostAmount, DelayedProdOrdersByCost.Cost_of_Open_Production_Orders, 'Item: ' + DelayedProdOrdersByCost.Item_No + '; field: ' + DelayedProdOrdersByCost.ColumnCaption(Cost_of_Open_Production_Orders));
                ActQueryRecords += 1;
            end;
        Assert.AreEqual(
          ExpQueryRecords, ActQueryRecords, 'Unexpected no. of query records for item ' + ItemNo + ' and status ' + Format(Status));
    end;

    [Normal]
    local procedure VerifyPendingBacklogRecords(ItemNo: Code[20]; Status: Enum "Production Order Status")
    var
        PendingProdOrdersByCost: Query "Pending Prod. Orders - by Cost";
        Qty: Decimal;
        CostAmount: Decimal;
        TotalCostAmount: Decimal;
        ExpQueryRecords: Integer;
        ActQueryRecords: Integer;
    begin
        GetExpectedProdOrderBacklog(Qty, CostAmount, TotalCostAmount, '>=', false, Status, ItemNo);
        ExpQueryRecords := 0;
        if Qty > 0 then
            ExpQueryRecords := 1;

        PendingProdOrdersByCost.Open();
        while PendingProdOrdersByCost.Read() do
            if (PendingProdOrdersByCost.Item_No = ItemNo) and (PendingProdOrdersByCost.Status = Status) then begin
                Assert.AreEqual(Qty, PendingProdOrdersByCost.Sum_Remaining_Quantity, 'Item: ' + PendingProdOrdersByCost.Item_No + '; field: ' + PendingProdOrdersByCost.ColumnCaption(Sum_Remaining_Quantity));
                Assert.AreEqual(
                  TotalCostAmount, PendingProdOrdersByCost.Cost_of_Open_Production_Orders, 'Item: ' + PendingProdOrdersByCost.Item_No + '; field: ' + PendingProdOrdersByCost.ColumnCaption(Cost_of_Open_Production_Orders));
                ActQueryRecords += 1;
            end;
        Assert.AreEqual(
          ExpQueryRecords, ActQueryRecords, 'Unexpected no. of query records for item ' + ItemNo + ' and status ' + Format(Status));
    end;

    [Normal]
    local procedure VerifyMyDelayedBacklogRecords(ItemNo: Code[20]; Status: Enum "Production Order Status")
    var
        MyDelayedProdOrders: Query "My Delayed Prod. Orders";
        Qty: Decimal;
        CostAmount: Decimal;
        TotalCostAmount: Decimal;
        ExpQueryRecords: Integer;
        ActQueryRecords: Integer;
    begin
        GetExpectedProdOrderBacklog(Qty, CostAmount, TotalCostAmount, '<=', true, Status, ItemNo);
        ExpQueryRecords := 0;
        if Qty > 0 then
            ExpQueryRecords := 1;

        MyDelayedProdOrders.SetFilter(User_ID, UserId);
        MyDelayedProdOrders.Open();
        while MyDelayedProdOrders.Read() do
            if (MyDelayedProdOrders.Item_No = ItemNo) and (MyDelayedProdOrders.Status = Status) then begin
                Assert.AreEqual(Qty, MyDelayedProdOrders.Sum_Remaining_Quantity, 'Item: ' + MyDelayedProdOrders.Item_No + '; field: ' + MyDelayedProdOrders.ColumnCaption(Sum_Remaining_Quantity));
                ActQueryRecords += 1;
            end;
        Assert.AreEqual(
          ExpQueryRecords, ActQueryRecords, 'Unexpected no. of query records for item ' + ItemNo + ' and status ' + Format(Status));
    end;

    [Normal]
    local procedure VerifyMyBacklogRecords(ItemNo: Code[20]; Status: Enum "Production Order Status")
    var
        MyProdOrdersByCost: Query "My Prod. Orders - By Cost";
        Qty: Decimal;
        CostAmount: Decimal;
        TotalCostAmount: Decimal;
        ExpQueryRecords: Integer;
        ActQueryRecords: Integer;
    begin
        GetExpectedProdOrderBacklog(Qty, CostAmount, TotalCostAmount, '', true, Status, ItemNo);
        ExpQueryRecords := 0;
        if Qty > 0 then
            ExpQueryRecords := 1;

        MyProdOrdersByCost.SetFilter(User_ID, UserId);
        MyProdOrdersByCost.Open();
        while MyProdOrdersByCost.Read() do
            if (MyProdOrdersByCost.Item_No = ItemNo) and (MyProdOrdersByCost.Status = Status) then begin
                Assert.AreEqual(Qty, MyProdOrdersByCost.Sum_Remaining_Quantity, 'Item: ' + MyProdOrdersByCost.Item_No + '; field: ' + MyProdOrdersByCost.ColumnCaption(Sum_Remaining_Quantity));
                Assert.AreEqual(TotalCostAmount, MyProdOrdersByCost.Cost_of_Open_Production_Orders, 'Item: ' + MyProdOrdersByCost.Item_No + '; field: ' + MyProdOrdersByCost.ColumnCaption(Cost_of_Open_Production_Orders));
                ActQueryRecords += 1;
            end;
        Assert.AreEqual(
          ExpQueryRecords, ActQueryRecords, 'Unexcepted no. of query records for item ' + ItemNo + ' and status ' + Format(Status));
    end;
}

