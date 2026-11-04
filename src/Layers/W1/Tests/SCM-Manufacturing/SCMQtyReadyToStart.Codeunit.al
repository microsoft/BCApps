// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Family;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.WorkCenter;

codeunit 137437 "SCM Qty. Ready to Start"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        FirstOperationNoTok: Label '10', Locked = true;
        SecondOperationNoTok: Label '20', Locked = true;
        ThirdOperationNoTok: Label '30', Locked = true;
        JoiningOperationNoTok: Label '40', Locked = true;
        QtyReadyToStartErr: Label 'Quantity Ready to Start of operation %1 is incorrect.', Comment = '%1 = Operation No.';
        RoutingStatusErr: Label 'Routing Status of operation %1 is incorrect.', Comment = '%1 = Operation No.';

    [Test]
    [Scope('OnPrem')]
    procedure FirstOperationEqualsInputQuantityAfterRefresh()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        // [SCENARIO] The first operation is ready to start with its own input quantity as soon as the production order is created and refreshed.
        Initialize();

        // [GIVEN] An item with a serial routing of two operations
        CreateItemWithSerialRouting(Item, LibraryRandom.RandIntInRange(2, 5));

        // [WHEN] A released production order is created and refreshed
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandIntInRange(20, 50));

        // [THEN] Quantity Ready to Start of the first operation equals its Input Quantity
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder, FirstOperationNoTok);
        Assert.AreNotEqual(0, ProdOrderRoutingLine."Input Quantity", 'Input Quantity of the first operation must not be zero.');
        Assert.AreEqual(
          ProdOrderRoutingLine."Input Quantity", ProdOrderRoutingLine."Quantity Ready to Start", StrSubstNo(QtyReadyToStartErr, FirstOperationNoTok));

        // [THEN] The second operation is not ready to start
        VerifyQtyReadyToStart(ProductionOrder, SecondOperationNoTok, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FirstOperationFollowsInputQuantityAfterQuantityChangeAndRefresh()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        Quantity: Decimal;
    begin
        // [SCENARIO] Refreshing a production order after a quantity change updates Quantity Ready to Start of the first operation.
        Initialize();

        // [GIVEN] A refreshed released production order with quantity "Q" for an item with a serial routing
        CreateItemWithSerialRouting(Item, LibraryRandom.RandIntInRange(2, 5));
        Quantity := LibraryRandom.RandIntInRange(20, 50);
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", Quantity);

        // [WHEN] The quantity is changed to "Q" + "X" and the production order is refreshed
        ProductionOrder.Find();
        ProductionOrder.Validate(Quantity, Quantity + LibraryRandom.RandIntInRange(5, 10));
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [THEN] Quantity Ready to Start of the first operation equals its new Input Quantity
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder, FirstOperationNoTok);
        Assert.AreEqual(ProductionOrder.Quantity, ProdOrderRoutingLine."Input Quantity", 'Input Quantity of the first operation is incorrect.');
        Assert.AreEqual(
          ProdOrderRoutingLine."Input Quantity", ProdOrderRoutingLine."Quantity Ready to Start", StrSubstNo(QtyReadyToStartErr, FirstOperationNoTok));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuccessorNotReadyBelowSendAheadQuantity()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        SendAheadQty: Decimal;
    begin
        // [SCENARIO] An operation stays not ready to start while its predecessor's posted output is below the predecessor's Send-Ahead Quantity.
        Initialize();

        // [GIVEN] A refreshed released production order for an item with a serial routing; the first operation has Send-Ahead Quantity "S"
        SendAheadQty := LibraryRandom.RandIntInRange(2, 5);
        CreateItemWithSerialRouting(Item, SendAheadQty);
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandIntInRange(20, 50));

        // [WHEN] Output "S" - 1 is posted on the first operation
        PostOutputForOperation(ProductionOrder, FirstOperationNoTok, SendAheadQty - 1);

        // [THEN] Quantity Ready to Start of the second operation is 0
        VerifyQtyReadyToStart(ProductionOrder, SecondOperationNoTok, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuccessorReadyAtSendAheadQuantity()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        SendAheadQty: Decimal;
        InputQty: Decimal;
    begin
        // [SCENARIO] An operation becomes ready to start when its predecessor's posted output reaches the predecessor's Send-Ahead Quantity.
        Initialize();

        // [GIVEN] A refreshed released production order for an item with a serial routing; the first operation has Send-Ahead Quantity "S"
        SendAheadQty := LibraryRandom.RandIntInRange(2, 5);
        CreateItemWithSerialRouting(Item, SendAheadQty);
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandIntInRange(20, 50));

        // [GIVEN] The second operation has Input Quantity "I"
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder, SecondOperationNoTok);
        InputQty := ProdOrderRoutingLine."Input Quantity";

        // [WHEN] Output "S" is posted on the first operation
        PostOutputForOperation(ProductionOrder, FirstOperationNoTok, SendAheadQty);

        // [THEN] Quantity Ready to Start of the second operation is "S" and its Input Quantity is still "I"
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder, SecondOperationNoTok);
        Assert.AreEqual(SendAheadQty, ProdOrderRoutingLine."Quantity Ready to Start", StrSubstNo(QtyReadyToStartErr, SecondOperationNoTok));
        Assert.AreEqual(InputQty, ProdOrderRoutingLine."Input Quantity", 'Input Quantity of the second operation must not change.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuccessorReadyAboveSendAheadQuantityEqualsPostedOutput()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        SendAheadQty: Decimal;
        FirstOutputQty: Decimal;
        SecondOutputQty: Decimal;
    begin
        // [SCENARIO] Above the predecessor's Send-Ahead Quantity, Quantity Ready to Start equals the predecessor's total posted output.
        Initialize();

        // [GIVEN] A refreshed released production order for an item with a serial routing; the first operation has Send-Ahead Quantity "S"
        SendAheadQty := LibraryRandom.RandIntInRange(2, 5);
        CreateItemWithSerialRouting(Item, SendAheadQty);
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandIntInRange(20, 50));

        // [GIVEN] Output "O1" below "S" is posted on the first operation
        FirstOutputQty := SendAheadQty - 1;
        PostOutputForOperation(ProductionOrder, FirstOperationNoTok, FirstOutputQty);

        // [WHEN] Output "O2" is posted on the first operation, so that "O1" + "O2" is above "S"
        SecondOutputQty := LibraryRandom.RandIntInRange(2, 5);
        PostOutputForOperation(ProductionOrder, FirstOperationNoTok, SecondOutputQty);

        // [THEN] Quantity Ready to Start of the second operation is "O1" + "O2"
        VerifyQtyReadyToStart(ProductionOrder, SecondOperationNoTok, FirstOutputQty + SecondOutputQty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuccessorNotReadyBelowFullLotWithoutSendAheadQuantity()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        // [SCENARIO] Without a send-ahead quantity, an operation stays not ready to start while its predecessor's posted output is below the full lot.
        Initialize();

        // [GIVEN] A refreshed released production order for an item with a serial routing; the first operation has Send-Ahead Quantity 0
        CreateItemWithSerialRouting(Item, 0);
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandIntInRange(20, 50));

        // [GIVEN] The second operation has Input Quantity "I"
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder, SecondOperationNoTok);

        // [WHEN] Output "I" - 1 is posted on the first operation
        PostOutputForOperation(ProductionOrder, FirstOperationNoTok, ProdOrderRoutingLine."Input Quantity" - 1);

        // [THEN] Quantity Ready to Start of the second operation is 0
        VerifyQtyReadyToStart(ProductionOrder, SecondOperationNoTok, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuccessorReadyAtFullLotWithoutSendAheadQuantity()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        InputQty: Decimal;
        FirstOutputQty: Decimal;
    begin
        // [SCENARIO] Without a send-ahead quantity, an operation becomes ready to start once its predecessor's posted output reaches the full lot, and then shows the posted output.
        Initialize();

        // [GIVEN] A refreshed released production order for an item with a serial routing; the first operation has Send-Ahead Quantity 0
        CreateItemWithSerialRouting(Item, 0);
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandIntInRange(20, 50));

        // [GIVEN] The second operation has Input Quantity "I"
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder, SecondOperationNoTok);
        InputQty := ProdOrderRoutingLine."Input Quantity";

        // [GIVEN] Output "O1" below "I" is posted on the first operation
        FirstOutputQty := LibraryRandom.RandIntInRange(1, 5);
        PostOutputForOperation(ProductionOrder, FirstOperationNoTok, FirstOutputQty);

        // [WHEN] Output "I" - "O1" is posted on the first operation
        PostOutputForOperation(ProductionOrder, FirstOperationNoTok, InputQty - FirstOutputQty);

        // [THEN] Quantity Ready to Start of the second operation is "I"
        VerifyQtyReadyToStart(ProductionOrder, SecondOperationNoTok, InputQty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendAheadQuantityAtLeastInputQuantityIsTreatedAsFullLot()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        Quantity: Decimal;
    begin
        // [SCENARIO] A Send-Ahead Quantity at or above the successor's Input Quantity is treated as the full lot.
        Initialize();

        // [GIVEN] A refreshed released production order with quantity "Q" for an item with a serial routing; the first operation has a Send-Ahead Quantity above "Q"
        Quantity := LibraryRandom.RandIntInRange(20, 50);
        CreateItemWithSerialRouting(Item, Quantity + LibraryRandom.RandIntInRange(1, 10));
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", Quantity);
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder, SecondOperationNoTok);
        Assert.AreEqual(Quantity, ProdOrderRoutingLine."Input Quantity", 'Input Quantity of the second operation is incorrect.');

        // [WHEN] Output "Q" is posted on the first operation
        PostOutputForOperation(ProductionOrder, FirstOperationNoTok, Quantity);

        // [THEN] Quantity Ready to Start of the second operation is "Q"
        VerifyQtyReadyToStart(ProductionOrder, SecondOperationNoTok, Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FullLotThresholdRoundedWithBaseUnitRoundingPrecision()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        Quantity: Decimal;
    begin
        // [SCENARIO] The full-lot threshold is rounded with the base-unit rounding precision, so that a scrap-calculation remainder does not block the successor.
        Initialize();

        // [GIVEN] An item with base-unit rounding precision 1 and a serial routing; the first operation has Send-Ahead Quantity 0 and the second operation a scrap factor of 0.001 %
        CreateItemWithSerialRoutingAndScrap(Item, 0, 0, 0.001);
        SetBaseUnitRoundingPrecision(Item, 1);

        // [GIVEN] A refreshed released production order with quantity "Q", so that the second operation has Input Quantity "Q" plus a fractional remainder
        Quantity := LibraryRandom.RandIntInRange(100, 200);
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", Quantity);
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder, SecondOperationNoTok);
        Assert.IsTrue(ProdOrderRoutingLine."Input Quantity" > Quantity, 'Input Quantity of the second operation must contain a scrap remainder.');
        Assert.AreEqual(Quantity, Round(ProdOrderRoutingLine."Input Quantity", 1), 'The scrap remainder of the second operation must round away.');

        // [WHEN] Output "Q" is posted on the first operation
        PostOutputForOperation(ProductionOrder, FirstOperationNoTok, Quantity);

        // [THEN] Quantity Ready to Start of the second operation is "Q"
        VerifyQtyReadyToStart(ProductionOrder, SecondOperationNoTok, Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FullLotReachableWithScrapOnPredecessor()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        PredecessorProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        Quantity: Decimal;
    begin
        // [SCENARIO] With scrap on the predecessor, posting the predecessor's expected output makes the successor ready to start.
        Initialize();

        // [GIVEN] An item with a serial routing; the first operation has Send-Ahead Quantity 0 and a scrap factor
        CreateItemWithSerialRoutingAndScrap(Item, 0, LibraryRandom.RandIntInRange(5, 20), 0);

        // [GIVEN] A refreshed released production order with quantity "Q"; the first operation's Input Quantity includes its scrap and is above "Q"
        Quantity := LibraryRandom.RandIntInRange(20, 50);
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", Quantity);
        FindProdOrderRoutingLine(PredecessorProdOrderRoutingLine, ProductionOrder, FirstOperationNoTok);
        Assert.IsTrue(PredecessorProdOrderRoutingLine."Input Quantity" > Quantity, 'Input Quantity of the first operation must include its scrap.');

        // [GIVEN] The second operation has Input Quantity "Q"
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder, SecondOperationNoTok);
        Assert.AreEqual(Quantity, ProdOrderRoutingLine."Input Quantity", 'Input Quantity of the second operation is incorrect.');

        // [WHEN] The expected output "Q" is posted on the first operation
        PostOutputForOperation(ProductionOrder, FirstOperationNoTok, Quantity);

        // [THEN] Quantity Ready to Start of the second operation is "Q"
        VerifyQtyReadyToStart(ProductionOrder, SecondOperationNoTok, Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FamilyReadyOnCombinedOutputOfAllFamilyItems()
    var
        Family: Record Family;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        Quantity: Decimal;
    begin
        // [SCENARIO] For a production family, the shared routing line becomes ready to start on the combined posted output of all family items.
        Initialize();

        // [GIVEN] A family of two items with quantity 1 each and a serial routing; the first operation has Send-Ahead Quantity 0
        CreateFamilyWithSerialRouting(Family, 0);

        // [GIVEN] A refreshed released production order with quantity "Q" for the family; the shared second operation has Input Quantity 2 * "Q"
        Quantity := LibraryRandom.RandIntInRange(20, 50);
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Family, Family."No.", Quantity);
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder, SecondOperationNoTok);
        Assert.AreEqual(2 * Quantity, ProdOrderRoutingLine."Input Quantity", 'Input Quantity of the shared second operation is incorrect.');

        // [WHEN] Output "Q" is posted on the first operation for each family item
        PostOutputForEachProdOrderLine(ProductionOrder, FirstOperationNoTok);

        // [THEN] Quantity Ready to Start of the shared second operation is 2 * "Q"
        VerifyQtyReadyToStart(ProductionOrder, SecondOperationNoTok, 2 * Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FamilyNotReadyOnOutputOfOneFamilyItem()
    var
        Family: Record Family;
        ProductionOrder: Record "Production Order";
    begin
        // [SCENARIO] For a production family, the output of a single family item does not reach the full lot of the shared routing line.
        Initialize();

        // [GIVEN] A family of two items with quantity 1 each and a serial routing; the first operation has Send-Ahead Quantity 0
        CreateFamilyWithSerialRouting(Family, 0);

        // [GIVEN] A refreshed released production order with quantity "Q" for the family; the shared second operation has Input Quantity 2 * "Q"
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Family, Family."No.", LibraryRandom.RandIntInRange(20, 50));

        // [WHEN] Output "Q" is posted on the first operation for the first family item only
        PostOutputForOperation(ProductionOrder, FirstOperationNoTok, ProductionOrder.Quantity);

        // [THEN] Quantity Ready to Start of the shared second operation is 0
        VerifyQtyReadyToStart(ProductionOrder, SecondOperationNoTok, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JoiningOperationNotReadyWhileOneBranchBelowThreshold()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        FirstBranchSendAheadQty: Decimal;
        SecondBranchSendAheadQty: Decimal;
    begin
        // [FEATURE] [Parallel Routing]
        // [SCENARIO] A joining operation stays not ready to start while one of its predecessor operations is below its own start threshold.
        Initialize();

        // [GIVEN] An item with a parallel routing 10 -> (20 | 30) -> 40; operation 20 has Send-Ahead Quantity "S1", operation 30 has Send-Ahead Quantity "S2"
        FirstBranchSendAheadQty := LibraryRandom.RandIntInRange(2, 5);
        SecondBranchSendAheadQty := LibraryRandom.RandIntInRange(2, 5);
        CreateItemWithParallelRouting(Item, FirstBranchSendAheadQty, SecondBranchSendAheadQty);

        // [GIVEN] A refreshed released production order; the joining operation 40 has predecessor operations 20 and 30
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandIntInRange(20, 50));
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder, JoiningOperationNoTok);
        Assert.AreEqual(
          StrSubstNo('%1|%2', SecondOperationNoTok, ThirdOperationNoTok), ProdOrderRoutingLine."Previous Operation No.",
          'Previous Operation No. of the joining operation is incorrect.');

        // [GIVEN] Output "S1" is posted on operation 20, so that this branch reaches its start threshold
        PostOutputForOperation(ProductionOrder, SecondOperationNoTok, FirstBranchSendAheadQty);

        // [WHEN] Output "S2" - 1 is posted on operation 30
        PostOutputForOperation(ProductionOrder, ThirdOperationNoTok, SecondBranchSendAheadQty - 1);

        // [THEN] Quantity Ready to Start of the joining operation 40 is 0
        VerifyQtyReadyToStart(ProductionOrder, JoiningOperationNoTok, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JoiningOperationReadyWithSmallestPostedOutputOfBranches()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        SendAheadQty: Decimal;
        FirstBranchOutputQty: Decimal;
        SecondBranchOutputQty: Decimal;
    begin
        // [FEATURE] [Parallel Routing]
        // [SCENARIO] Once all predecessor operations of a joining operation have reached their start thresholds, its Quantity Ready to Start is the smallest posted output among them.
        Initialize();

        // [GIVEN] An item with a parallel routing 10 -> (20 | 30) -> 40; operations 20 and 30 have Send-Ahead Quantity "S"
        SendAheadQty := LibraryRandom.RandIntInRange(2, 5);
        CreateItemWithParallelRouting(Item, SendAheadQty, SendAheadQty);
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandIntInRange(20, 50));

        // [GIVEN] Output "O1" above "S" is posted on operation 20
        FirstBranchOutputQty := SendAheadQty + LibraryRandom.RandIntInRange(1, 5);
        PostOutputForOperation(ProductionOrder, SecondOperationNoTok, FirstBranchOutputQty);

        // [GIVEN] The joining operation 40 is not ready to start while operation 30 has no output
        VerifyQtyReadyToStart(ProductionOrder, JoiningOperationNoTok, 0);

        // [WHEN] Output "O2" greater than "O1" is posted on operation 30
        SecondBranchOutputQty := FirstBranchOutputQty + LibraryRandom.RandIntInRange(1, 5);
        PostOutputForOperation(ProductionOrder, ThirdOperationNoTok, SecondBranchOutputQty);

        // [THEN] Quantity Ready to Start of the joining operation 40 is "O1", the smallest posted output of its predecessor operations
        VerifyQtyReadyToStart(ProductionOrder, JoiningOperationNoTok, FirstBranchOutputQty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JoiningOperationRecalculatedOnOutputOfSlowestBranch()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        SendAheadQty: Decimal;
        FirstBranchOutputQty: Decimal;
        SecondBranchOutputQty: Decimal;
    begin
        // [FEATURE] [Parallel Routing]
        // [SCENARIO] Posting output on the slowest branch recalculates the joining operation, so that the next slowest branch decides.
        Initialize();

        // [GIVEN] An item with a parallel routing 10 -> (20 | 30) -> 40; operations 20 and 30 have Send-Ahead Quantity "S"
        SendAheadQty := LibraryRandom.RandIntInRange(2, 5);
        CreateItemWithParallelRouting(Item, SendAheadQty, SendAheadQty);
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandIntInRange(20, 50));

        // [GIVEN] Output "O1" = "S" is posted on operation 20 and output "O2" above "O1" on operation 30, so that the joining operation 40 shows "O1"
        FirstBranchOutputQty := SendAheadQty;
        SecondBranchOutputQty := FirstBranchOutputQty + LibraryRandom.RandIntInRange(1, 5);
        PostOutputForOperation(ProductionOrder, SecondOperationNoTok, FirstBranchOutputQty);
        PostOutputForOperation(ProductionOrder, ThirdOperationNoTok, SecondBranchOutputQty);
        VerifyQtyReadyToStart(ProductionOrder, JoiningOperationNoTok, FirstBranchOutputQty);

        // [WHEN] Additional output "O2" is posted on operation 20, so that its total "O1" + "O2" is above "O2"
        PostOutputForOperation(ProductionOrder, SecondOperationNoTok, SecondBranchOutputQty);

        // [THEN] Quantity Ready to Start of the joining operation 40 is "O2", now the smallest posted output of its predecessor operations
        VerifyQtyReadyToStart(ProductionOrder, JoiningOperationNoTok, SecondBranchOutputQty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuccessorReadyWhenPredecessorPostedAsFinishedBelowThreshold()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        SendAheadQty: Decimal;
    begin
        // [FEATURE] [Finished Predecessor]
        // [SCENARIO] Posting output with Finished below the predecessor's start threshold makes the successor ready to start with the posted output.
        Initialize();

        // [GIVEN] A refreshed released production order for an item with a serial routing; the first operation has Send-Ahead Quantity "S"
        SendAheadQty := LibraryRandom.RandIntInRange(3, 6);
        CreateItemWithSerialRouting(Item, SendAheadQty);
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandIntInRange(20, 50));

        // [WHEN] Output "S" - 1 is posted on the first operation with Finished
        PostOutputForOperation(ProductionOrder, FirstOperationNoTok, SendAheadQty - 1, true);

        // [THEN] Quantity Ready to Start of the second operation is "S" - 1
        VerifyQtyReadyToStart(ProductionOrder, SecondOperationNoTok, SendAheadQty - 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure SuccessorReadyWhenPredecessorSetToFinishedBelowThreshold()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        SendAheadQty: Decimal;
    begin
        // [FEATURE] [Finished Predecessor]
        // [SCENARIO] Setting Routing Status to Finished by hand below the predecessor's start threshold makes the successor ready to start with the posted output.
        Initialize();

        // [GIVEN] A refreshed released production order for an item with a serial routing; the first operation has Send-Ahead Quantity "S"
        SendAheadQty := LibraryRandom.RandIntInRange(3, 6);
        CreateItemWithSerialRouting(Item, SendAheadQty);
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandIntInRange(20, 50));

        // [GIVEN] Output "S" - 1 is posted on the first operation, so that the second operation is not ready to start
        PostOutputForOperation(ProductionOrder, FirstOperationNoTok, SendAheadQty - 1);
        VerifyQtyReadyToStart(ProductionOrder, SecondOperationNoTok, 0);

        // [WHEN] Routing Status of the first operation is set to Finished on the production order routing line; ConfirmHandlerYes confirms that the allocated capacity of the operation is deleted
        SetRoutingStatusFinished(ProductionOrder, FirstOperationNoTok);

        // [THEN] Quantity Ready to Start of the second operation is "S" - 1
        VerifyQtyReadyToStart(ProductionOrder, SecondOperationNoTok, SendAheadQty - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuccessorNotReadyWhenPredecessorPostedAsFinishedWithoutOutput()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [Finished Predecessor]
        // [SCENARIO] A predecessor finished by posting without any output leaves its successor not ready to start.
        Initialize();

        // [GIVEN] A refreshed released production order for an item with a serial routing; the first operation has a Send-Ahead Quantity
        CreateItemWithSerialRouting(Item, LibraryRandom.RandIntInRange(2, 5));
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandIntInRange(20, 50));

        // [WHEN] Output 0 with a run time is posted on the first operation with Finished
        PostOutputForOperation(ProductionOrder, FirstOperationNoTok, 0, true, LibraryRandom.RandInt(5));

        // [THEN] The first operation is finished and Quantity Ready to Start of the second operation is 0
        VerifyRoutingStatus(ProductionOrder, FirstOperationNoTok, "Prod. Order Routing Status"::Finished);
        VerifyQtyReadyToStart(ProductionOrder, SecondOperationNoTok, 0);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure SuccessorNotReadyWhenPredecessorSetToFinishedWithoutOutput()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [Finished Predecessor]
        // [SCENARIO] A predecessor set to Finished by hand without any posted output leaves its successor not ready to start.
        Initialize();

        // [GIVEN] A refreshed released production order for an item with a serial routing; no output is posted
        CreateItemWithSerialRouting(Item, LibraryRandom.RandIntInRange(2, 5));
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandIntInRange(20, 50));

        // [WHEN] Routing Status of the first operation is set to Finished on the production order routing line; ConfirmHandlerYes confirms that the allocated capacity of the operation is deleted
        SetRoutingStatusFinished(ProductionOrder, FirstOperationNoTok);

        // [THEN] Quantity Ready to Start of the second operation is 0
        VerifyQtyReadyToStart(ProductionOrder, SecondOperationNoTok, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReversedOutputLowersQtyReadyToStart()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        SendAheadQty: Decimal;
        ReversedQty: Decimal;
    begin
        // [FEATURE] [Output Reversal]
        // [SCENARIO] Posting negative output on a predecessor that stays at or above its start threshold lowers the successor's Quantity Ready to Start to the new posted output.
        Initialize();

        // [GIVEN] A refreshed released production order for an item with a serial routing; the first operation has Send-Ahead Quantity "S"
        SendAheadQty := LibraryRandom.RandIntInRange(2, 5);
        CreateItemWithSerialRouting(Item, SendAheadQty);
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandIntInRange(20, 50));

        // [GIVEN] Output "S" + "R" is posted on the first operation, so that the second operation shows "S" + "R"
        ReversedQty := LibraryRandom.RandIntInRange(1, 5);
        PostOutputForOperation(ProductionOrder, FirstOperationNoTok, SendAheadQty + ReversedQty);
        VerifyQtyReadyToStart(ProductionOrder, SecondOperationNoTok, SendAheadQty + ReversedQty);

        // [WHEN] Output -"R" is posted on the first operation
        PostOutputForOperation(ProductionOrder, FirstOperationNoTok, -ReversedQty);

        // [THEN] Quantity Ready to Start of the second operation is "S"
        VerifyQtyReadyToStart(ProductionOrder, SecondOperationNoTok, SendAheadQty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReversedOutputBelowThresholdReturnsQtyReadyToStartToZero()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        SendAheadQty: Decimal;
    begin
        // [FEATURE] [Output Reversal]
        // [SCENARIO] Posting negative output that takes an unfinished predecessor below its start threshold returns the successor's Quantity Ready to Start to 0.
        Initialize();

        // [GIVEN] A refreshed released production order for an item with a serial routing; the first operation has Send-Ahead Quantity "S"
        SendAheadQty := LibraryRandom.RandIntInRange(2, 5);
        CreateItemWithSerialRouting(Item, SendAheadQty);
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandIntInRange(20, 50));

        // [GIVEN] Output "S" is posted on the first operation, so that the second operation is ready to start
        PostOutputForOperation(ProductionOrder, FirstOperationNoTok, SendAheadQty);
        VerifyQtyReadyToStart(ProductionOrder, SecondOperationNoTok, SendAheadQty);

        // [WHEN] Output -1 is posted on the first operation
        PostOutputForOperation(ProductionOrder, FirstOperationNoTok, -1);

        // [THEN] Quantity Ready to Start of the second operation is 0
        VerifyQtyReadyToStart(ProductionOrder, SecondOperationNoTok, 0);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ReversedOutputOnFinishedPredecessorLowersQtyReadyToStart()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        SendAheadQty: Decimal;
    begin
        // [FEATURE] [Finished Predecessor] [Output Reversal]
        // [SCENARIO] A correction posted with negative output and Finished on a finished predecessor keeps the successor ready to start and lowers its Quantity Ready to Start to the new posted output.
        Initialize();

        // [GIVEN] A refreshed released production order for an item with a serial routing; the first operation has Send-Ahead Quantity "S"
        SendAheadQty := LibraryRandom.RandIntInRange(3, 6);
        CreateItemWithSerialRouting(Item, SendAheadQty);
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandIntInRange(20, 50));

        // [GIVEN] Output "S" is posted on the first operation with Finished
        PostOutputForOperation(ProductionOrder, FirstOperationNoTok, SendAheadQty, true);

        // [WHEN] Output -1 is posted on the first operation with Finished; ConfirmHandlerYes confirms posting output on the finished operation
        PostOutputForOperation(ProductionOrder, FirstOperationNoTok, -1, true);

        // [THEN] The first operation stays finished and Quantity Ready to Start of the second operation is "S" - 1
        VerifyRoutingStatus(ProductionOrder, FirstOperationNoTok, "Prod. Order Routing Status"::Finished);
        VerifyQtyReadyToStart(ProductionOrder, SecondOperationNoTok, SendAheadQty - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplanRecalculatesQtyReadyToStart()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        Quantity: Decimal;
        Direction: Option Forward,Backward;
        CalcMethod: Option "No Levels","One level","All levels";
    begin
        // [FEATURE] [Replan]
        // [SCENARIO] Replanning a production order recalculates Quantity Ready to Start of every routing line whose Input Quantity it writes.
        Initialize();

        // [GIVEN] A refreshed released production order with quantity "Q" for an item with a serial routing; the first operation has Send-Ahead Quantity 0
        Quantity := LibraryRandom.RandIntInRange(20, 50);
        CreateItemWithSerialRouting(Item, 0);
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", Quantity);

        // [GIVEN] Output "Q" is posted on the first operation, so that the second operation is ready to start with "Q"
        PostOutputForOperation(ProductionOrder, FirstOperationNoTok, Quantity);
        VerifyQtyReadyToStart(ProductionOrder, SecondOperationNoTok, Quantity);

        // [GIVEN] The quantity of the production order line is raised to "Q" + "X" without recalculating the routing
        UpdateProdOrderLineQuantityWithoutRecalculation(ProductionOrder, Quantity + LibraryRandom.RandIntInRange(5, 10));
        VerifyQtyReadyToStart(ProductionOrder, SecondOperationNoTok, Quantity);

        // [WHEN] The production order is replanned
        LibraryManufacturing.RunReplanProductionOrder(ProductionOrder, Direction::Backward, CalcMethod::"No Levels");

        // [THEN] Quantity Ready to Start of the first operation equals its new Input Quantity
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder, FirstOperationNoTok);
        Assert.AreNotEqual(0, ProdOrderRoutingLine."Input Quantity", 'Input Quantity of the first operation must not be zero.');
        Assert.AreEqual(
          ProdOrderRoutingLine."Input Quantity", ProdOrderRoutingLine."Quantity Ready to Start", StrSubstNo(QtyReadyToStartErr, FirstOperationNoTok));

        // [THEN] The second operation's full lot is now "Q" + "X", so it is no longer ready to start
        VerifyQtyReadyToStart(ProductionOrder, SecondOperationNoTok, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdOrderFromPlanningWorksheetHasQtyReadyToStart()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        // [FEATURE] [Planning Worksheet]
        // [SCENARIO] A production order created from the planning worksheet has correct Quantity Ready to Start values right away.
        Initialize();

        // [GIVEN] An item with a serial routing and a fixed reorder quantity
        CreateItemWithSerialRouting(Item, LibraryRandom.RandIntInRange(2, 5));
        SetFixedReorderQtyPolicy(Item, LibraryRandom.RandIntInRange(5, 10), LibraryRandom.RandIntInRange(20, 50));

        // [GIVEN] A regenerative plan proposes a new production order for the item
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // [WHEN] The action message is carried out as a firm planned production order
        CarryOutActionMessageForItem(Item."No.");

        // [THEN] Quantity Ready to Start of the first operation equals its Input Quantity
        FindProdOrderForItem(ProductionOrder, Item."No.");
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder, FirstOperationNoTok);
        Assert.AreNotEqual(0, ProdOrderRoutingLine."Input Quantity", 'Input Quantity of the first operation must not be zero.');
        Assert.AreEqual(
          ProdOrderRoutingLine."Input Quantity", ProdOrderRoutingLine."Quantity Ready to Start", StrSubstNo(QtyReadyToStartErr, FirstOperationNoTok));

        // [THEN] The second operation is not ready to start
        VerifyQtyReadyToStart(ProductionOrder, SecondOperationNoTok, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuantityChangeOnProdOrderLineUpdatesQtyReadyToStart()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        ReleasedProductionOrder: TestPage "Released Production Order";
        Quantity: Decimal;
        NewQuantity: Decimal;
    begin
        // [FEATURE] [Quantity Change]
        // [SCENARIO] Changing the quantity of a production order line updates Quantity Ready to Start of the first operation and the full-lot threshold of the next operation.
        Initialize();

        // [GIVEN] The Premium experience, so that the production order lines part is shown
        LibraryApplicationArea.EnablePremiumSetup();

        // [GIVEN] A refreshed released production order with quantity "Q" for an item with a serial routing; the first operation has Send-Ahead Quantity 0
        Quantity := LibraryRandom.RandIntInRange(20, 50);
        CreateItemWithSerialRouting(Item, 0);
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", Quantity);

        // [GIVEN] Output "Q" is posted on the first operation, so that the second operation is ready to start with "Q"
        PostOutputForOperation(ProductionOrder, FirstOperationNoTok, Quantity);
        VerifyQtyReadyToStart(ProductionOrder, SecondOperationNoTok, Quantity);

        // [WHEN] The quantity of the production order line is changed to "Q" + "X" on the released production order
        NewQuantity := Quantity + LibraryRandom.RandIntInRange(5, 10);
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.Filter.SetFilter("No.", ProductionOrder."No.");
        ReleasedProductionOrder.ProdOrderLines.First();
        ReleasedProductionOrder.ProdOrderLines.Quantity.SetValue(NewQuantity);
        ReleasedProductionOrder.Close();

        // [THEN] Quantity Ready to Start of the first operation equals its new Input Quantity "Q" + "X"
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder, FirstOperationNoTok);
        Assert.AreEqual(NewQuantity, ProdOrderRoutingLine."Input Quantity", 'Input Quantity of the first operation is incorrect.');
        Assert.AreEqual(
          ProdOrderRoutingLine."Input Quantity", ProdOrderRoutingLine."Quantity Ready to Start", StrSubstNo(QtyReadyToStartErr, FirstOperationNoTok));

        // [THEN] The second operation's full lot is now "Q" + "X", so it is no longer ready to start
        VerifyQtyReadyToStart(ProductionOrder, SecondOperationNoTok, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StatusChangeKeepsQtyReadyToStart()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        FirstOperationQtyReadyToStart: Decimal;
        ProdOrderNo: Code[20];
    begin
        // [FEATURE] [Status Change]
        // [SCENARIO] Changing the status of a production order from Planned to Firm Planned to Released keeps Quantity Ready to Start of its routing lines.
        Initialize();

        // [GIVEN] A refreshed planned production order for an item with a serial routing; the first operation has Quantity Ready to Start "R"
        CreateItemWithSerialRouting(Item, LibraryRandom.RandIntInRange(2, 5));
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Planned, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandIntInRange(20, 50));
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder, FirstOperationNoTok);
        FirstOperationQtyReadyToStart := ProdOrderRoutingLine."Quantity Ready to Start";
        Assert.AreNotEqual(0, FirstOperationQtyReadyToStart, StrSubstNo(QtyReadyToStartErr, FirstOperationNoTok));

        // [WHEN] The production order is changed to Firm Planned
        ProdOrderNo :=
          LibraryManufacturing.ChangeProuctionOrderStatus(
            ProductionOrder."No.", ProductionOrder.Status::Planned, ProductionOrder.Status::"Firm Planned");

        // [THEN] The first operation keeps "R" and the second operation stays at 0
        ProductionOrder.SetLoadFields(Status, "No.");
        ProductionOrder.Get(ProductionOrder.Status::"Firm Planned", ProdOrderNo);
        VerifyQtyReadyToStart(ProductionOrder, FirstOperationNoTok, FirstOperationQtyReadyToStart);
        VerifyQtyReadyToStart(ProductionOrder, SecondOperationNoTok, 0);

        // [WHEN] The production order is changed to Released
        ProdOrderNo := LibraryManufacturing.ChangeStatusFirmPlanToReleased(ProdOrderNo);

        // [THEN] The first operation keeps "R" and the second operation stays at 0
        ProductionOrder.SetLoadFields(Status, "No.");
        ProductionOrder.Get(ProductionOrder.Status::Released, ProdOrderNo);
        VerifyQtyReadyToStart(ProductionOrder, FirstOperationNoTok, FirstOperationQtyReadyToStart);
        VerifyQtyReadyToStart(ProductionOrder, SecondOperationNoTok, 0);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ReopenRecalculatesQtyReadyToStart()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        SendAheadQty: Decimal;
        OutputQty: Decimal;
    begin
        // [FEATURE] [Reopen]
        // [SCENARIO] Reopening a finished production order recalculates Quantity Ready to Start of every reopened routing line.
        Initialize();

        // [GIVEN] A released production order for an item with a serial routing; the first operation has Send-Ahead Quantity "S"
        SendAheadQty := LibraryRandom.RandIntInRange(5, 10);
        CreateItemWithSerialRouting(Item, SendAheadQty);
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandIntInRange(20, 50));

        // [GIVEN] Output "X" below "S" posted as Finished on the first operation, so the second operation is ready to start with "X"
        OutputQty := SendAheadQty - 1;
        PostOutputForOperation(ProductionOrder, FirstOperationNoTok, OutputQty, true);
        VerifyQtyReadyToStart(ProductionOrder, SecondOperationNoTok, OutputQty);

        // [GIVEN] Output posted on the second operation and the production order finished
        PostOutputForOperation(ProductionOrder, SecondOperationNoTok, OutputQty);
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [WHEN] The finished production order is reopened; ConfirmHandlerYes has confirmed finishing the order although some output is still missing
        ReopenFinishedProdOrder(ProductionOrder."No.");

        // [THEN] The first operation is In Progress again and keeps its Input Quantity as Quantity Ready to Start
        VerifyRoutingStatus(ProductionOrder, FirstOperationNoTok, "Prod. Order Routing Status"::"In Progress");
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder, FirstOperationNoTok);
        Assert.AreEqual(
          ProdOrderRoutingLine."Input Quantity", ProdOrderRoutingLine."Quantity Ready to Start", StrSubstNo(QtyReadyToStartErr, FirstOperationNoTok));

        // [THEN] The second operation is not ready to start, because the reopened first operation is below "S" and no longer finished
        VerifyQtyReadyToStart(ProductionOrder, SecondOperationNoTok, 0);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ReopenFillsQtyReadyToStartOfOrderFinishedBeforeFeature()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        FinishedProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        SendAheadQty: Decimal;
        OutputQty: Decimal;
    begin
        // [FEATURE] [Reopen]
        // [SCENARIO] A production order finished before Quantity Ready to Start existed gets correct values when it is reopened.
        Initialize();

        // [GIVEN] A released production order for an item with a serial routing; the first operation has Send-Ahead Quantity "S"
        SendAheadQty := LibraryRandom.RandIntInRange(2, 5);
        CreateItemWithSerialRouting(Item, SendAheadQty);
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandIntInRange(20, 50));

        // [GIVEN] Output "X" at or above "S" posted on the first operation and output posted on the second operation
        OutputQty := SendAheadQty + LibraryRandom.RandInt(5);
        PostOutputForOperation(ProductionOrder, FirstOperationNoTok, OutputQty);
        PostOutputForOperation(ProductionOrder, SecondOperationNoTok, LibraryRandom.RandInt(OutputQty));

        // [GIVEN] The production order is finished and Quantity Ready to Start of its routing lines is 0, as for an order finished before the feature
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");
        FinishedProductionOrder.SetLoadFields(Status, "No.");
        FinishedProductionOrder.Get(FinishedProductionOrder.Status::Finished, ProductionOrder."No.");
        ClearQtyReadyToStartOnProdOrder(FinishedProductionOrder);

        // [WHEN] The finished production order is reopened; ConfirmHandlerYes has confirmed finishing the order although some output is still missing
        ReopenFinishedProdOrder(ProductionOrder."No.");

        // [THEN] Quantity Ready to Start of the first operation equals its Input Quantity
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder, FirstOperationNoTok);
        Assert.AreNotEqual(0, ProdOrderRoutingLine."Input Quantity", 'Input Quantity of the first operation must not be zero.');
        Assert.AreEqual(
          ProdOrderRoutingLine."Input Quantity", ProdOrderRoutingLine."Quantity Ready to Start", StrSubstNo(QtyReadyToStartErr, FirstOperationNoTok));

        // [THEN] Quantity Ready to Start of the second operation equals the posted output "X" of the first operation
        VerifyQtyReadyToStart(ProductionOrder, SecondOperationNoTok, OutputQty);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure UpgradeFillsQtyReadyToStartOfOpenProdOrdersOnly()
    var
        Item: Record Item;
        PlannedProductionOrder: Record "Production Order";
        ReleasedProductionOrder: Record "Production Order";
        FinishedProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QtyReadyToStartMgt: Codeunit "Qty. Ready to Start Mgt.";
        SendAheadQty: Decimal;
        OutputQty: Decimal;
    begin
        // [FEATURE] [Upgrade]
        // [SCENARIO] The upgrade recalculation fills in Quantity Ready to Start of every routing line of non-finished production orders and leaves finished production orders untouched.
        Initialize();

        // [GIVEN] An item with a serial routing; the first operation has Send-Ahead Quantity "S"
        SendAheadQty := LibraryRandom.RandIntInRange(2, 5);
        CreateItemWithSerialRouting(Item, SendAheadQty);
        OutputQty := SendAheadQty + LibraryRandom.RandInt(5);

        // [GIVEN] A refreshed planned production order
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          PlannedProductionOrder, PlannedProductionOrder.Status::Planned, PlannedProductionOrder."Source Type"::Item, Item."No.",
          LibraryRandom.RandIntInRange(20, 50));

        // [GIVEN] A released production order with output "X" at or above "S" posted on the first operation
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          ReleasedProductionOrder, ReleasedProductionOrder.Status::Released, ReleasedProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandIntInRange(20, 50));
        PostOutputForOperation(ReleasedProductionOrder, FirstOperationNoTok, OutputQty);

        // [GIVEN] A finished production order with output "X" posted on the first and the second operation
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          FinishedProductionOrder, FinishedProductionOrder.Status::Released, FinishedProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandIntInRange(20, 50));
        PostOutputForOperation(FinishedProductionOrder, FirstOperationNoTok, OutputQty);
        PostOutputForOperation(FinishedProductionOrder, SecondOperationNoTok, OutputQty);
        LibraryManufacturing.ChangeStatusReleasedToFinished(FinishedProductionOrder."No.");
        FinishedProductionOrder.SetLoadFields(Status, "No.");
        FinishedProductionOrder.Get(FinishedProductionOrder.Status::Finished, FinishedProductionOrder."No.");

        // [GIVEN] Quantity Ready to Start is 0 on all routing lines of the three production orders, as before the upgrade
        ClearQtyReadyToStartOnProdOrder(PlannedProductionOrder);
        ClearQtyReadyToStartOnProdOrder(ReleasedProductionOrder);
        ClearQtyReadyToStartOnProdOrder(FinishedProductionOrder);

        // [WHEN] The upgrade recalculation runs; ConfirmHandlerYes has confirmed finishing the finished production order although some output is still missing
        QtyReadyToStartMgt.UpdateQtyReadyToStartForOpenProdOrders();

        // [THEN] The planned production order's first operation equals its Input Quantity and its second operation is 0
        FindProdOrderRoutingLine(ProdOrderRoutingLine, PlannedProductionOrder, FirstOperationNoTok);
        Assert.AreNotEqual(0, ProdOrderRoutingLine."Input Quantity", 'Input Quantity of the first operation must not be zero.');
        Assert.AreEqual(
          ProdOrderRoutingLine."Input Quantity", ProdOrderRoutingLine."Quantity Ready to Start", StrSubstNo(QtyReadyToStartErr, FirstOperationNoTok));
        VerifyQtyReadyToStart(PlannedProductionOrder, SecondOperationNoTok, 0);

        // [THEN] The released production order's first operation equals its Input Quantity and its second operation equals "X"
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ReleasedProductionOrder, FirstOperationNoTok);
        Assert.AreEqual(
          ProdOrderRoutingLine."Input Quantity", ProdOrderRoutingLine."Quantity Ready to Start", StrSubstNo(QtyReadyToStartErr, FirstOperationNoTok));
        VerifyQtyReadyToStart(ReleasedProductionOrder, SecondOperationNoTok, OutputQty);

        // [THEN] The finished production order's routing lines are untouched and stay 0
        VerifyQtyReadyToStart(FinishedProductionOrder, FirstOperationNoTok, 0);
        VerifyQtyReadyToStart(FinishedProductionOrder, SecondOperationNoTok, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpgradeRecalculationTwiceGivesSameResult()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QtyReadyToStartMgt: Codeunit "Qty. Ready to Start Mgt.";
        SendAheadQty: Decimal;
        OutputQty: Decimal;
        FirstOperationQtyReadyToStart: Decimal;
    begin
        // [FEATURE] [Upgrade]
        // [SCENARIO] Running the upgrade recalculation twice gives the same Quantity Ready to Start as running it once.
        Initialize();

        // [GIVEN] A released production order for an item with a serial routing; the first operation has Send-Ahead Quantity "S"
        SendAheadQty := LibraryRandom.RandIntInRange(2, 5);
        CreateItemWithSerialRouting(Item, SendAheadQty);
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandIntInRange(20, 50));

        // [GIVEN] Output "X" at or above "S" posted on the first operation
        OutputQty := SendAheadQty + LibraryRandom.RandInt(5);
        PostOutputForOperation(ProductionOrder, FirstOperationNoTok, OutputQty);

        // [GIVEN] Quantity Ready to Start is 0 on all routing lines, as before the upgrade
        ClearQtyReadyToStartOnProdOrder(ProductionOrder);

        // [GIVEN] The upgrade recalculation has run once; the first operation has Quantity Ready to Start "R"
        QtyReadyToStartMgt.UpdateQtyReadyToStartForOpenProdOrders();
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder, FirstOperationNoTok);
        FirstOperationQtyReadyToStart := ProdOrderRoutingLine."Quantity Ready to Start";

        // [WHEN] The upgrade recalculation runs a second time
        QtyReadyToStartMgt.UpdateQtyReadyToStartForOpenProdOrders();

        // [THEN] The first operation still has "R", which equals its Input Quantity, and the second operation still has "X"
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder, FirstOperationNoTok);
        Assert.AreEqual(FirstOperationQtyReadyToStart, ProdOrderRoutingLine."Quantity Ready to Start", StrSubstNo(QtyReadyToStartErr, FirstOperationNoTok));
        Assert.AreEqual(
          ProdOrderRoutingLine."Input Quantity", ProdOrderRoutingLine."Quantity Ready to Start", StrSubstNo(QtyReadyToStartErr, FirstOperationNoTok));
        VerifyQtyReadyToStart(ProductionOrder, SecondOperationNoTok, OutputQty);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"SCM Qty. Ready to Start");
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"SCM Qty. Ready to Start");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();

        LibrarySetupStorage.SaveManufacturingSetup();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"SCM Qty. Ready to Start");
    end;

    local procedure CreateItemWithSerialRouting(var Item: Record Item; SendAheadQty: Decimal)
    begin
        CreateItemWithSerialRoutingAndScrap(Item, SendAheadQty, 0, 0);
    end;

    local procedure CreateItemWithSerialRoutingAndScrap(var Item: Record Item; SendAheadQty: Decimal; FirstOperationScrapFactorPct: Decimal; SecondOperationScrapFactorPct: Decimal)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Routing No.", CreateSerialRouting(SendAheadQty, FirstOperationScrapFactorPct, SecondOperationScrapFactorPct));
        Item.Modify(true);
    end;

    local procedure CreateSerialRouting(SendAheadQty: Decimal; FirstOperationScrapFactorPct: Decimal; SecondOperationScrapFactorPct: Decimal): Code[20]
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
    begin
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLineSetup(
          RoutingLine, RoutingHeader, WorkCenter."No.", FirstOperationNoTok, 0, LibraryRandom.RandInt(5));
        RoutingLine.Validate("Send-Ahead Quantity", SendAheadQty);
        RoutingLine.Validate("Scrap Factor %", FirstOperationScrapFactorPct);
        RoutingLine.Modify(true);
        LibraryManufacturing.CreateRoutingLineSetup(
          RoutingLine, RoutingHeader, WorkCenter."No.", SecondOperationNoTok, 0, LibraryRandom.RandInt(5));
        RoutingLine.Validate("Scrap Factor %", SecondOperationScrapFactorPct);
        RoutingLine.Modify(true);
        LibraryManufacturing.UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
        exit(RoutingHeader."No.");
    end;

    local procedure CreateItemWithParallelRouting(var Item: Record Item; FirstBranchSendAheadQty: Decimal; SecondBranchSendAheadQty: Decimal)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Routing No.", CreateParallelRoutingWithJoiningOperation(FirstBranchSendAheadQty, SecondBranchSendAheadQty));
        Item.Modify(true);
    end;

    local procedure CreateParallelRoutingWithJoiningOperation(FirstBranchSendAheadQty: Decimal; SecondBranchSendAheadQty: Decimal): Code[20]
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
    begin
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Parallel);
        CreateParallelRoutingLine(
          RoutingHeader, WorkCenter."No.", FirstOperationNoTok, StrSubstNo('%1|%2', SecondOperationNoTok, ThirdOperationNoTok), 0);
        CreateParallelRoutingLine(RoutingHeader, WorkCenter."No.", SecondOperationNoTok, JoiningOperationNoTok, FirstBranchSendAheadQty);
        CreateParallelRoutingLine(RoutingHeader, WorkCenter."No.", ThirdOperationNoTok, JoiningOperationNoTok, SecondBranchSendAheadQty);
        LibraryManufacturing.CreateRoutingLineSetup(
          RoutingLine, RoutingHeader, WorkCenter."No.", JoiningOperationNoTok, 0, LibraryRandom.RandInt(5));
        LibraryManufacturing.UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
        exit(RoutingHeader."No.");
    end;

    local procedure CreateParallelRoutingLine(RoutingHeader: Record "Routing Header"; WorkCenterNo: Code[20]; OperationNo: Code[10]; NextOperationNo: Code[30]; SendAheadQty: Decimal)
    var
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateRoutingLineSetup(RoutingLine, RoutingHeader, WorkCenterNo, OperationNo, 0, LibraryRandom.RandInt(5));
        RoutingLine.Validate("Next Operation No.", NextOperationNo);
        RoutingLine.Validate("Send-Ahead Quantity", SendAheadQty);
        RoutingLine.Modify(true);
    end;

    local procedure CreateFamilyWithSerialRouting(var Family: Record Family; SendAheadQty: Decimal)
    var
        FirstItem: Record Item;
        SecondItem: Record Item;
        FamilyLine: Record "Family Line";
    begin
        LibraryInventory.CreateItem(FirstItem);
        LibraryInventory.CreateItem(SecondItem);
        LibraryManufacturing.CreateFamily(Family);
        LibraryManufacturing.CreateFamilyLine(FamilyLine, Family."No.", FirstItem."No.", 1);
        LibraryManufacturing.CreateFamilyLine(FamilyLine, Family."No.", SecondItem."No.", 1);
        Family.Validate("Routing No.", CreateSerialRouting(SendAheadQty, 0, 0));
        Family.Modify(true);
    end;

    local procedure SetBaseUnitRoundingPrecision(Item: Record Item; QtyRoundingPrecision: Decimal)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        ItemUnitOfMeasure.SetLoadFields("Qty. Rounding Precision");
        ItemUnitOfMeasure.Get(Item."No.", Item."Base Unit of Measure");
        ItemUnitOfMeasure.Validate("Qty. Rounding Precision", QtyRoundingPrecision);
        ItemUnitOfMeasure.Modify(true);
    end;

    local procedure SetFixedReorderQtyPolicy(var Item: Record Item; ReorderPoint: Decimal; ReorderQuantity: Decimal)
    begin
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Fixed Reorder Qty.");
        Item.Validate("Reorder Point", ReorderPoint);
        Item.Validate("Reorder Quantity", ReorderQuantity);
        Item.Modify(true);
    end;

    local procedure CarryOutActionMessageForItem(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetCurrentKey(Type, "No.");
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", ItemNo);
        RequisitionLine.FindFirst();
        RequisitionLine.TestField("Ref. Order Type", RequisitionLine."Ref. Order Type"::"Prod. Order");
        RequisitionLine.Validate("Accept Action Message", true);
        RequisitionLine.Modify(true);
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);
    end;

    local procedure FindProdOrderForItem(var ProductionOrder: Record "Production Order"; ItemNo: Code[20])
    begin
        ProductionOrder.SetCurrentKey("Source Type", "Source No.");
        ProductionOrder.SetRange("Source Type", ProductionOrder."Source Type"::Item);
        ProductionOrder.SetRange("Source No.", ItemNo);
        ProductionOrder.SetLoadFields(Status, "No.");
        ProductionOrder.FindFirst();
    end;

    local procedure UpdateProdOrderLineQuantityWithoutRecalculation(ProductionOrder: Record "Production Order"; NewQuantity: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        ProdOrderLine.Validate(Quantity, NewQuantity);
        ProdOrderLine.Modify(true);
    end;

    local procedure PostOutputForOperation(ProductionOrder: Record "Production Order"; OperationNo: Code[10]; OutputQty: Decimal)
    begin
        PostOutputForOperation(ProductionOrder, OperationNo, OutputQty, false);
    end;

    local procedure PostOutputForOperation(ProductionOrder: Record "Production Order"; OperationNo: Code[10]; OutputQty: Decimal; IsFinished: Boolean)
    begin
        PostOutputForOperation(ProductionOrder, OperationNo, OutputQty, IsFinished, 0);
    end;

    local procedure PostOutputForOperation(ProductionOrder: Record "Production Order"; OperationNo: Code[10]; OutputQty: Decimal; IsFinished: Boolean; RunTime: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.SetLoadFields("Line No.", "Item No.");
        ProdOrderLine.FindFirst();

        PostOutputForProdOrderLine(ProdOrderLine, OperationNo, OutputQty, IsFinished, RunTime);
    end;

    local procedure PostOutputForEachProdOrderLine(ProductionOrder: Record "Production Order"; OperationNo: Code[10])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.SetLoadFields("Line No.", "Item No.", "Quantity (Base)");
        ProdOrderLine.FindSet();
        repeat
            PostOutputForProdOrderLine(ProdOrderLine, OperationNo, ProdOrderLine."Quantity (Base)", false, 0);
        until ProdOrderLine.Next() = 0;
    end;

    local procedure PostOutputForProdOrderLine(ProdOrderLine: Record "Prod. Order Line"; OperationNo: Code[10]; OutputQty: Decimal; IsFinished: Boolean; RunTime: Decimal)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalBatch."Template Type"::Output);
        ItemJournalTemplate.SetLoadFields(Type);
        ItemJournalTemplate.Get(ItemJournalBatch."Journal Template Name");
        LibraryManufacturing.CreateOutputJournal(
          ItemJournalLine, ItemJournalTemplate, ItemJournalBatch, ProdOrderLine."Item No.", ProdOrderLine."Prod. Order No.");
        ItemJournalLine.Validate("Order Line No.", ProdOrderLine."Line No.");
        ItemJournalLine.Validate("Operation No.", OperationNo);
        ItemJournalLine.Validate("Output Quantity", OutputQty);
        ItemJournalLine.Validate("Run Time", RunTime);
        ItemJournalLine.Validate(Finished, IsFinished);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
    end;

    local procedure ReopenFinishedProdOrder(ProdOrderNo: Code[20])
    var
        FinishedProductionOrder: Record "Production Order";
        ProdOrderStatusManagement: Codeunit "Prod. Order Status Management";
    begin
        FinishedProductionOrder.Get(FinishedProductionOrder.Status::Finished, ProdOrderNo);
        ProdOrderStatusManagement.ProcessProdOrderForReopen(FinishedProductionOrder);
    end;

    local procedure ClearQtyReadyToStartOnProdOrder(ProductionOrder: Record "Production Order")
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        Assert.RecordIsNotEmpty(ProdOrderRoutingLine);
        ProdOrderRoutingLine.ModifyAll("Quantity Ready to Start", 0, false);
    end;

    local procedure SetRoutingStatusFinished(ProductionOrder: Record "Production Order"; OperationNo: Code[10])
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Operation No.", OperationNo);
        ProdOrderRoutingLine.FindFirst();
        ProdOrderRoutingLine.Validate("Routing Status", ProdOrderRoutingLine."Routing Status"::Finished);
        ProdOrderRoutingLine.Modify(true);
    end;

    local procedure VerifyRoutingStatus(ProductionOrder: Record "Production Order"; OperationNo: Code[10]; ExpectedRoutingStatus: Enum "Prod. Order Routing Status")
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Operation No.", OperationNo);
        ProdOrderRoutingLine.SetLoadFields("Routing Status");
        ProdOrderRoutingLine.FindFirst();
        Assert.AreEqual(ExpectedRoutingStatus, ProdOrderRoutingLine."Routing Status", StrSubstNo(RoutingStatusErr, OperationNo));
    end;

    local procedure FindProdOrderRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProductionOrder: Record "Production Order"; OperationNo: Code[10])
    begin
        ProdOrderRoutingLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Operation No.", OperationNo);
        ProdOrderRoutingLine.SetLoadFields("Input Quantity", "Previous Operation No.", "Quantity Ready to Start");
        ProdOrderRoutingLine.FindFirst();
    end;

    local procedure VerifyQtyReadyToStart(ProductionOrder: Record "Production Order"; OperationNo: Code[10]; ExpectedQtyReadyToStart: Decimal)
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder, OperationNo);
        Assert.AreEqual(ExpectedQtyReadyToStart, ProdOrderRoutingLine."Quantity Ready to Start", StrSubstNo(QtyReadyToStartErr, OperationNo));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}