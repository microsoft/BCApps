codeunit 137606 "SCM CETAF Costing Reval. WIP"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Revaluation] [SCM]
        isInitialized := false;
    end;

    var
        LibraryCosting: Codeunit "Library - Costing";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPatterns: Codeunit "Library - Patterns";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        TXTIncorrectRevalCost: Label 'Incorrect Cost Amount in inbound ILE No. %1 after revaluation.';
        AnyQst: Label 'Any?';
        AnyMsg: Label 'Any.';

    [Test]
    [Scope('OnPrem')]
    procedure TestFIFO_FIFO_SimpleProdOrder()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrder(Item."Costing Method"::FIFO, Item."Costing Method"::FIFO, WorkDate(), false, false, false, "Inventory Value Calc. Per"::"Item Ledger Entry", 1.5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFIFO_STD_SimpleProdOrder()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrder(Item."Costing Method"::FIFO, Item."Costing Method"::Standard, WorkDate(), false, false, false, "Inventory Value Calc. Per"::"Item Ledger Entry", 1.5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAVG_AVG_SimpleProdOrder()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrder(Item."Costing Method"::Average, Item."Costing Method"::Average, WorkDate(), false, false, false, "Inventory Value Calc. Per"::"Item Ledger Entry", 1.5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAVG_STD_SimpleProdOrder()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrder(Item."Costing Method"::Average, Item."Costing Method"::Standard, WorkDate(), false, false, false, "Inventory Value Calc. Per"::"Item Ledger Entry", 1.5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSTD_STD_SimpleProdOrder()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrder(Item."Costing Method"::Standard, Item."Costing Method"::Standard, WorkDate(), false, false, false, "Inventory Value Calc. Per"::"Item Ledger Entry", 1.5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFIFO_FIFO_ProdOrderRevalperItem_All()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrder(Item."Costing Method"::FIFO, Item."Costing Method"::FIFO, WorkDate(), true, false, false, "Inventory Value Calc. Per"::Item, 1.5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFIFO_STD_ProdOrderRevalperItem_All()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrder(Item."Costing Method"::FIFO, Item."Costing Method"::Standard, WorkDate(), true, false, false, "Inventory Value Calc. Per"::Item, 1.5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAVG_AVG_ProdOrderRevalperItem_All()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrder(Item."Costing Method"::Average, Item."Costing Method"::Average, WorkDate(), true, false, false, "Inventory Value Calc. Per"::Item, 1.5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAVG_STD_ProdOrderRevalperItem_All()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrder(Item."Costing Method"::Average, Item."Costing Method"::Standard, WorkDate(), true, false, false, "Inventory Value Calc. Per"::Item, 1.5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestLIFO_LIFO_ProdOrderRevalperItem_All()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrder(Item."Costing Method"::LIFO, Item."Costing Method"::LIFO, WorkDate(), true, false, false, "Inventory Value Calc. Per"::Item, 1.5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestLIFO_STD_ProdOrderRevalperItem_All()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrder(Item."Costing Method"::LIFO, Item."Costing Method"::Standard, WorkDate(), true, false, false, "Inventory Value Calc. Per"::Item, 1.5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSTD_STD_ProdOrderRevalperItem_All()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrder(Item."Costing Method"::Standard, Item."Costing Method"::Standard, WorkDate(), true, false, false, "Inventory Value Calc. Per"::Item, 1.5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFIFO_FIFO_ProdOrderRevalperItem_Partial()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrder(Item."Costing Method"::FIFO, Item."Costing Method"::FIFO, WorkDate(), false, true, false, "Inventory Value Calc. Per"::Item, 1.5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFIFO_STD_ProdOrderRevalperItem_Partial()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrder(Item."Costing Method"::FIFO, Item."Costing Method"::Standard, WorkDate(), false, true, false, "Inventory Value Calc. Per"::Item, 1.5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAVG_AVG_ProdOrderRevalperItem_Partial()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrder(Item."Costing Method"::Average, Item."Costing Method"::Average, WorkDate(), false, true, false, "Inventory Value Calc. Per"::Item, 1.5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAVG_STD_ProdOrderRevalperItem_Partial()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrder(Item."Costing Method"::Average, Item."Costing Method"::Standard, WorkDate(), false, true, false, "Inventory Value Calc. Per"::Item, 1.5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestLIFO_LIFO_ProdOrderRevalperItem_Partial()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrder(Item."Costing Method"::LIFO, Item."Costing Method"::LIFO, WorkDate(), false, true, false, "Inventory Value Calc. Per"::Item, 1.5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestLIFO_STD_ProdOrderRevalperItem_Partial()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrder(Item."Costing Method"::LIFO, Item."Costing Method"::Standard, WorkDate(), false, true, false, "Inventory Value Calc. Per"::Item, 1.5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSTD_STD_ProdOrderRevalperItem_Partial()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrder(Item."Costing Method"::Standard, Item."Costing Method"::Standard, WorkDate(), false, true, false, "Inventory Value Calc. Per"::Item, 1.5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFIFO_FIFO_ProdOrderRevalperItem_NonWIP()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrder(Item."Costing Method"::FIFO, Item."Costing Method"::FIFO, WorkDate(), false, false, true, "Inventory Value Calc. Per"::Item, 1.5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestLIFO_FIFO_ProdOrderRevalperItem_NonWIP()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrder(Item."Costing Method"::LIFO, Item."Costing Method"::FIFO, WorkDate(), false, false, true, "Inventory Value Calc. Per"::Item, 1.5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAVG_FIFO_ProdOrderRevalperItem_NonWIP()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrder(Item."Costing Method"::Average, Item."Costing Method"::FIFO, WorkDate(), false, false, true, "Inventory Value Calc. Per"::Item, 1.5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSTD_FIFO_ProdOrderRevalperItem_NonWIP()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrder(Item."Costing Method"::Standard, Item."Costing Method"::FIFO, WorkDate(), false, false, true, "Inventory Value Calc. Per"::Item, 1.5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFIFO_FIFO_ProdOrderRevalperItemtoZero()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrder_ZeroInv(Item."Costing Method"::FIFO, Item."Costing Method"::FIFO, WorkDate(), "Inventory Value Calc. Per"::Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFIFO_STD_ProdOrderRevalperItemtoZero()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrder_ZeroInv(Item."Costing Method"::FIFO, Item."Costing Method"::Standard, WorkDate(), "Inventory Value Calc. Per"::Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAVG_AVG_ProdOrderRevalperItemtoZero()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrder_ZeroInv(Item."Costing Method"::Average, Item."Costing Method"::Average, WorkDate(), "Inventory Value Calc. Per"::Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAVG_STD_ProdOrderRevalperItemtoZero()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrder_ZeroInv(Item."Costing Method"::Average, Item."Costing Method"::Standard, WorkDate(), "Inventory Value Calc. Per"::Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestLIFO_LIFO_ProdOrderRevalperItemtoZero()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrder_ZeroInv(Item."Costing Method"::LIFO, Item."Costing Method"::LIFO, WorkDate(), "Inventory Value Calc. Per"::Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestLIFO_STD_ProdOrderRevalperItemtoZero()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrder_ZeroInv(Item."Costing Method"::LIFO, Item."Costing Method"::Standard, WorkDate(), "Inventory Value Calc. Per"::Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSTD_STD_ProdOrderRevalperItemtoZero()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrder_ZeroInv(Item."Costing Method"::Standard, Item."Costing Method"::Standard, WorkDate(), "Inventory Value Calc. Per"::Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFIFO_FIFO_ProdOrderRevalperILE_All()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrder(
          Item."Costing Method"::FIFO, Item."Costing Method"::FIFO, WorkDate(), false, true, false, "Inventory Value Calc. Per"::"Item Ledger Entry", 1.5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFIFO_STD_ProdOrderRevalperILE_All()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrder(
          Item."Costing Method"::FIFO, Item."Costing Method"::Standard, WorkDate(), false, true, false, "Inventory Value Calc. Per"::"Item Ledger Entry", 1.5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFIFO_FIFO_ProdOrderRevalpartialILE()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrder_RevalPartialILEs(Item."Costing Method"::FIFO, Item."Costing Method"::FIFO, WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFIFO_AVG_ProdOrderRevalpartialILE()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrder_RevalPartialILEs(Item."Costing Method"::FIFO, Item."Costing Method"::Average, WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFIFO_STD_ProdOrderRevalpartialILE()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrder_RevalPartialILEs(Item."Costing Method"::FIFO, Item."Costing Method"::Standard, WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestLIFO_STD_ProdOrderRevalpartialILE()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrder_RevalPartialILEs(Item."Costing Method"::LIFO, Item."Costing Method"::Standard, WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSTD_STD_ProdOrderRevalpartialILE()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrder_RevalPartialILEs(Item."Costing Method"::Standard, Item."Costing Method"::Standard, WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFIFO_FIFO_ProdOrder_NegConsumption()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrder_NegConsumption(Item."Costing Method"::FIFO, Item."Costing Method"::FIFO, WorkDate(), "Inventory Value Calc. Per"::Item, 1.5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFIFO_STD_ProdOrder_NegConsumption()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrder_NegConsumption(Item."Costing Method"::FIFO, Item."Costing Method"::Standard, WorkDate(), "Inventory Value Calc. Per"::Item, 1.5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAVG_AVG_ProdOrder_NegConsumption()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrder_NegConsumption(Item."Costing Method"::Average, Item."Costing Method"::Average, WorkDate(), "Inventory Value Calc. Per"::Item, 1.5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAVG_STD_ProdOrder_NegConsumption()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrder_NegConsumption(Item."Costing Method"::Average, Item."Costing Method"::Standard, WorkDate(), "Inventory Value Calc. Per"::Item, 1.5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestLIFO_LIFO_ProdOrder_NegConsumption()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrder_NegConsumption(Item."Costing Method"::LIFO, Item."Costing Method"::LIFO, WorkDate(), "Inventory Value Calc. Per"::Item, 1.5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestLIFO_STD_ProdOrder_NegConsumption()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrder_NegConsumption(Item."Costing Method"::LIFO, Item."Costing Method"::Standard, WorkDate(), "Inventory Value Calc. Per"::Item, 1.5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSTD_STD_ProdOrder_NegConsumption()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrder_NegConsumption(Item."Costing Method"::Standard, Item."Costing Method"::Standard, WorkDate(), "Inventory Value Calc. Per"::Item, 1.5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFIFO_FIFO_TestProdOrder_RevalPartialConsmp()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrder_RevalPartialConsumption(Item."Costing Method"::FIFO, Item."Costing Method"::FIFO, WorkDate(), 1.5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFIFO_STD_TestProdOrder_RevalPartialConsmp()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrder_RevalPartialConsumption(Item."Costing Method"::FIFO, Item."Costing Method"::Standard, WorkDate(), 1.5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestLIFO_LIFO_TestProdOrder_RevalPartialConsmp()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrder_RevalPartialConsumption(Item."Costing Method"::LIFO, Item."Costing Method"::LIFO, WorkDate(), 1.5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestLIFO_STD_TestProdOrder_RevalPartialConsmp()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrder_RevalPartialConsumption(Item."Costing Method"::LIFO, Item."Costing Method"::Standard, WorkDate(), 1.5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSTD_STD_TestProdOrder_RevalPartialConsmp()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrder_RevalPartialConsumption(Item."Costing Method"::Standard, Item."Costing Method"::Standard, WorkDate(), 1.5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFIFO_ProdOrderAverageComponent()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrderAverageComponent(Item."Costing Method"::FIFO, WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAVG_ProdOrderAverageComponent()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrderAverageComponent(Item."Costing Method"::Average, WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestLIFO_ProdOrderAverageComponent()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrderAverageComponent(Item."Costing Method"::LIFO, WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSTD_ProdOrderAverageComponent()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrderAverageComponent(Item."Costing Method"::Standard, WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFIFO_ProdOrderAvgCompwithReval()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrderAvgCompwithReval(Item."Costing Method"::FIFO, WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestLIFO_ProdOrderAvgCompwithReval()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrderAvgCompwithReval(Item."Costing Method"::LIFO, WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAVG_ProdOrderAvgCompwithReval()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrderAvgCompwithReval(Item."Costing Method"::Standard, WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSTD_ProdOrderAvgCompwithReval()
    var
        Item: Record Item;
    begin
        Initialize();
        TestProdOrderAvgCompwithReval(Item."Costing Method"::Standard, WorkDate());
    end;

    local procedure TestProdOrder(ComponentCostingMethod: Enum "Costing Method"; ProducedItemCostingMethod: Enum "Costing Method"; StartDate: Date; RevalueBeforeProdOrder1: Boolean; RevalueBeforeProdOrder2: Boolean; RevalueAfterProdOrder2: Boolean; CalcPer: Enum "Inventory Value Calc. Per"; RevaluationFactor: Decimal)
    var
        ComponentItem: Record Item;
        ProducedItem1: Record Item;
        ProducedItem2: Record Item;
        EmptyItem: Record Item;
        ProductionOrder1: Record "Production Order";
        ProductionOrder2: Record "Production Order";
        EmptyProdOrder: Record "Production Order";
        ItemJnlBatch: Record "Item Journal Batch";
        QtyCompInProdItem1: Decimal;
        QtyCompInProdItem2: Decimal;
        QtyProdItem1InProdItem2: Decimal;
        ProdOrder1Qty: Decimal;
        ProdOrder2Qty: Decimal;
        QtyCompInProdOrder1: Decimal;
        QtyCompInProdOrder2: Decimal;
        QtyProdItem1InProdOrder2: Decimal;
        SaleProdItem2Qty: Decimal;
        VerifyVariance: Boolean;
    begin
        EmptyItem.Init();
        EmptyProdOrder.Init();
        VerifyVariance := ProducedItemCostingMethod = ProducedItem1."Costing Method"::Standard;
        InitializeQuantities(QtyCompInProdItem1, QtyCompInProdItem2, QtyProdItem1InProdItem2, ProdOrder1Qty, ProdOrder2Qty, SaleProdItem2Qty);
        SetupItems(
          ComponentItem, ProducedItem1, ProducedItem2, ComponentCostingMethod, ProducedItemCostingMethod, QtyCompInProdItem1,
          QtyCompInProdItem2, QtyProdItem1InProdItem2);
        SetupProdOrders(ProductionOrder1, ProductionOrder2, ProducedItem1, ProducedItem2, ProdOrder1Qty, ProdOrder2Qty, StartDate + 30);

        QtyCompInProdOrder1 := Round(QtyCompInProdItem1 * ProdOrder1Qty, ComponentItem."Rounding Precision", '>');
        QtyCompInProdOrder2 := Round(QtyCompInProdItem2 * ProdOrder2Qty, ComponentItem."Rounding Precision", '>');
        QtyProdItem1InProdOrder2 := Round(QtyProdItem1InProdItem2 * ProdOrder2Qty, ProducedItem1."Rounding Precision", '>');
        PurchaseItemSplitApplication(ComponentItem, QtyCompInProdOrder1, QtyCompInProdOrder2, ComponentItem."Unit Cost", StartDate);

        PostProdOrder1(ProductionOrder1, ComponentItem, ProducedItem1, StartDate + 4, QtyCompInProdOrder1, ProdOrder1Qty, 0);
        // Finish Order 1
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder1, ProductionOrder1.Status::Finished, StartDate + 10, false);

        // AdjustCost
        LibraryCosting.AdjustCostItemEntries(StrSubstNo('%1|%2', ComponentItem."No.", ProducedItem1."No."), '');
        // Verify
        VerifyCost(ComponentItem, EmptyItem, EmptyItem, ProductionOrder1, EmptyProdOrder, VerifyVariance);

        PostProdOrder2(
          ProductionOrder2, ComponentItem, ProducedItem1, ProducedItem2, StartDate + 20, QtyCompInProdOrder2, QtyProdItem1InProdOrder2,
          ProdOrder2Qty);
        // Finish Order 2
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder2, ProductionOrder2.Status::Finished, StartDate + 25, false);
        // Sell ProducedItem2
        LibraryInventory.PostItemJournalLine(
            "Item Journal Template Type"::Item, "Item Ledger Entry Type"::Sale,
            ProducedItem2, '', '', '', SaleProdItem2Qty, StartDate + 30, 0);
        // AdjustCost
        LibraryCosting.AdjustCostItemEntries(StrSubstNo('%1|%2|%3', ComponentItem."No.", ProducedItem1."No.", ProducedItem2."No."), '');

        // Verify
        VerifyCost(ComponentItem, ProducedItem1, ProducedItem2, EmptyProdOrder, ProductionOrder2, VerifyVariance);
        // Revalue
        if RevalueBeforeProdOrder1 then begin
            // Perform revaluation before consumption of order 1 was posted
            ExecuteRevalueExistingInventory(ComponentItem, ItemJnlBatch, StartDate + 1, CalcPer, false, false, false, "Inventory Value Calc. Base"::" ", '', '');
            LibraryPatterns.ModifyPostRevaluation(ItemJnlBatch, RevaluationFactor);
            LibraryCosting.AdjustCostItemEntries(StrSubstNo('%1|%2|%3', ComponentItem."No.", ProducedItem1."No.", ProducedItem2."No."), '');
            // Verify
            VerifyCost(ComponentItem, ProducedItem1, ProducedItem2, ProductionOrder1, ProductionOrder2, VerifyVariance);
        end;

        if RevalueBeforeProdOrder2 then begin
            // Perform revaluation after Order1 was finished, but before consumption of order 2 was posted
            ExecuteRevalueExistingInventory(
              ComponentItem, ItemJnlBatch, StartDate + 15, CalcPer, false, false, false, "Inventory Value Calc. Base"::" ", '', '');
            LibraryPatterns.ModifyPostRevaluation(ItemJnlBatch, RevaluationFactor);
            LibraryCosting.AdjustCostItemEntries(StrSubstNo('%1|%2|%3', ComponentItem."No.", ProducedItem1."No.", ProducedItem2."No."), '');
            // Verify
            VerifyCost(ComponentItem, ProducedItem1, ProducedItem2, ProductionOrder1, ProductionOrder2, VerifyVariance);
        end;

        if RevalueAfterProdOrder2 then begin
            // Perform revaluation after Order2 was finished
            ExecuteRevalueExistingInventory(
              ComponentItem, ItemJnlBatch, StartDate + 27, CalcPer, false, false, false, "Inventory Value Calc. Base"::" ", '', '');
            LibraryPatterns.ModifyPostRevaluation(ItemJnlBatch, RevaluationFactor);
            LibraryCosting.AdjustCostItemEntries(StrSubstNo('%1|%2|%3', ComponentItem."No.", ProducedItem1."No.", ProducedItem2."No."), '');
            // Verify
            VerifyCost(ComponentItem, ProducedItem1, ProducedItem2, ProductionOrder1, ProductionOrder2, VerifyVariance);
        end;
    end;

    local procedure TestProdOrder_ZeroInv(ComponentCostingMethod: Enum "Costing Method"; ProducedItemCostingMethod: Enum "Costing Method"; StartDate: Date; CalcPer: Enum "Inventory Value Calc. Per")
    var
        ComponentItem: Record Item;
        ProducedItem1: Record Item;
        ProducedItem2: Record Item;
        EmptyItem: Record Item;
        ProductionOrder1: Record "Production Order";
        ProductionOrder2: Record "Production Order";
        ItemJnlBatch: Record "Item Journal Batch";
        QtyCompInProdItem1: Decimal;
        QtyCompInProdItem2: Decimal;
        QtyProdItem1InProdItem2: Decimal;
        ProdOrder1Qty: Decimal;
        ProdOrder2Qty: Decimal;
        QtyCompInProdOrder1: Decimal;
        QtyCompInProdOrder2: Decimal;
        QtyProdItem1InProdOrder2: Decimal;
        SaleProdItem2Qty: Decimal;
        VerifyVariance: Boolean;
    begin
        EmptyItem.Init();
        VerifyVariance := ProducedItemCostingMethod = ProducedItem1."Costing Method"::Standard;
        InitializeQuantities(QtyCompInProdItem1, QtyCompInProdItem2, QtyProdItem1InProdItem2, ProdOrder1Qty, ProdOrder2Qty, SaleProdItem2Qty);
        SetupItems(
          ComponentItem, ProducedItem1, ProducedItem2, ComponentCostingMethod, ProducedItemCostingMethod, QtyCompInProdItem1,
          QtyCompInProdItem2, QtyProdItem1InProdItem2);
        SetupProdOrders(ProductionOrder1, ProductionOrder2, ProducedItem1, ProducedItem2, ProdOrder1Qty, ProdOrder2Qty, StartDate + 30);

        QtyCompInProdOrder1 := Round(QtyCompInProdItem1 * ProdOrder1Qty, ComponentItem."Rounding Precision", '>');
        QtyCompInProdOrder2 := Round(QtyCompInProdItem2 * ProdOrder2Qty, ComponentItem."Rounding Precision", '>');
        QtyProdItem1InProdOrder2 := Round(QtyProdItem1InProdItem2 * ProdOrder2Qty, ProducedItem1."Rounding Precision", '>');
        PurchaseItemSplitApplication(ComponentItem, QtyCompInProdOrder1, QtyCompInProdOrder2, ComponentItem."Unit Cost", StartDate);

        PostProdOrder1(ProductionOrder1, ComponentItem, ProducedItem1, StartDate + 4, QtyCompInProdOrder1, ProdOrder1Qty, 0);

        PostProdOrder2(
          ProductionOrder2, ComponentItem, ProducedItem1, ProducedItem2, StartDate + 20, QtyCompInProdOrder2, QtyProdItem1InProdOrder2,
          ProdOrder2Qty);

        // Finish Order 1
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder1, ProductionOrder1.Status::Finished, StartDate + 20, false);
        // Finish Order 2
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder2, ProductionOrder2.Status::Finished, StartDate + 20, false);

        // Sell ProducedItem2
        LibraryInventory.PostItemJournalLine(
             "Item Journal Template Type"::Item, "Item Ledger Entry Type"::Sale,
              ProducedItem2, '', '', '', SaleProdItem2Qty, StartDate + 30, 0);

        // AdjustCost
        LibraryCosting.AdjustCostItemEntries(StrSubstNo('%1|%2|%3', ComponentItem."No.", ProducedItem1."No.", ProducedItem2."No."), '');
        // Verify
        VerifyCost(ComponentItem, ProducedItem1, ProducedItem2, ProductionOrder1, ProductionOrder2, VerifyVariance);

        // Perform revaluation before consumption of order 1 was posted
        ExecuteRevalueExistingInventory(ComponentItem, ItemJnlBatch, StartDate + 1, CalcPer, false, false, false, "Inventory Value Calc. Base"::" ", '', '');
        LibraryPatterns.ModifyPostRevaluation(ItemJnlBatch, 0);
        LibraryCosting.AdjustCostItemEntries(StrSubstNo('%1|%2|%3', ComponentItem."No.", ProducedItem1."No.", ProducedItem2."No."), '');

        // Verify
        VerifyCost(ComponentItem, ProducedItem1, ProducedItem2, ProductionOrder1, ProductionOrder2, VerifyVariance);
    end;

    local procedure TestProdOrder_RevalPartialILEs(ComponentCostingMethod: Enum "Costing Method"; ProducedItemCostingMethod: Enum "Costing Method"; StartDate: Date)
    var
        ComponentItem: Record Item;
        ProducedItem1: Record Item;
        ProducedItem2: Record Item;
        EmptyItem: Record Item;
        ProductionOrder1: Record "Production Order";
        ProductionOrder2: Record "Production Order";
        EmptyProdOrder: Record "Production Order";
        ItemJnlBatch: Record "Item Journal Batch";
        QtyCompInProdItem1: Decimal;
        QtyCompInProdItem2: Decimal;
        QtyProdItem1InProdItem2: Decimal;
        ProdOrder1Qty: Decimal;
        ProdOrder2Qty: Decimal;
        QtyCompInProdOrder1: Decimal;
        QtyCompInProdOrder2: Decimal;
        QtyProdItem1InProdOrder2: Decimal;
        SaleProdItem2Qty: Decimal;
        VerifyVariance: Boolean;
    begin
        EmptyItem.Init();
        EmptyProdOrder.Init();
        VerifyVariance := ProducedItemCostingMethod = ProducedItem1."Costing Method"::Standard;
        InitializeQuantities(QtyCompInProdItem1, QtyCompInProdItem2, QtyProdItem1InProdItem2, ProdOrder1Qty, ProdOrder2Qty, SaleProdItem2Qty);
        SetupItems(
          ComponentItem, ProducedItem1, ProducedItem2, ComponentCostingMethod, ProducedItemCostingMethod, QtyCompInProdItem1,
          QtyCompInProdItem2, QtyProdItem1InProdItem2);
        SetupProdOrders(ProductionOrder1, ProductionOrder2, ProducedItem1, ProducedItem2, ProdOrder1Qty, ProdOrder2Qty, StartDate + 30);

        QtyCompInProdOrder1 := Round(QtyCompInProdItem1 * ProdOrder1Qty, ComponentItem."Rounding Precision", '>');
        QtyCompInProdOrder2 := Round(QtyCompInProdItem2 * ProdOrder2Qty, ComponentItem."Rounding Precision", '>');
        QtyProdItem1InProdOrder2 := Round(QtyProdItem1InProdItem2 * ProdOrder2Qty, ProducedItem1."Rounding Precision", '>');
        PurchaseItemSplitApplication(ComponentItem, QtyCompInProdOrder1, QtyCompInProdOrder2, ComponentItem."Unit Cost", StartDate);

        PostProdOrder1(ProductionOrder1, ComponentItem, ProducedItem1, StartDate + 4, QtyCompInProdOrder1, ProdOrder1Qty, 0);
        // Finish Order 1
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder1, ProductionOrder1.Status::Finished, StartDate + 10, false);

        // AdjustCost
        LibraryCosting.AdjustCostItemEntries(StrSubstNo('%1|%2', ComponentItem."No.", ProducedItem1."No."), '');
        // Verify
        VerifyCost(ComponentItem, EmptyItem, EmptyItem, ProductionOrder1, EmptyProdOrder, VerifyVariance);

        PostProdOrder2(
          ProductionOrder2, ComponentItem, ProducedItem1, ProducedItem2, StartDate + 20, QtyCompInProdOrder2, QtyProdItem1InProdOrder2,
          ProdOrder2Qty);
        // Finish Order 2
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder2, ProductionOrder2.Status::Finished, StartDate + 30, false);
        // Sell ProducedItem2
        LibraryInventory.PostItemJournalLine(
             "Item Journal Template Type"::Item, "Item Ledger Entry Type"::Sale,
              ProducedItem2, '', '', '', SaleProdItem2Qty, StartDate + 30, 0);
        // AdjustCost
        LibraryCosting.AdjustCostItemEntries(StrSubstNo('%1|%2|%3', ComponentItem."No.", ProducedItem1."No.", ProducedItem2."No."), '');

        // Verify
        VerifyCost(ComponentItem, ProducedItem1, ProducedItem2, EmptyProdOrder, ProductionOrder2, VerifyVariance);

        // Perform revaluation after Order1 was finished, but before consumption of order 2 was posted
        ExecuteRevalueExistingInventory(
          ComponentItem, ItemJnlBatch, StartDate + 15, "Inventory Value Calc. Per"::"Item Ledger Entry", false, false, false, "Inventory Value Calc. Base"::" ", '', '');
        ModifyRevaluationLine(ItemJnlBatch."Journal Template Name", ItemJnlBatch.Name, 10000, 0.66, LibraryERM.GetAmountRoundingPrecision());
        ModifyRevaluationLine(ItemJnlBatch."Journal Template Name", ItemJnlBatch.Name, 20000, 0.66, LibraryERM.GetAmountRoundingPrecision());
        ModifyRevaluationLine(ItemJnlBatch."Journal Template Name", ItemJnlBatch.Name, 40000, 0.66, LibraryERM.GetAmountRoundingPrecision());
        LibraryInventory.PostItemJournalBatch(ItemJnlBatch);

        LibraryCosting.AdjustCostItemEntries(StrSubstNo('%1|%2|%3', ComponentItem."No.", ProducedItem1."No.", ProducedItem2."No."), '');
        // Verify
        VerifyCost(ComponentItem, ProducedItem1, ProducedItem2, ProductionOrder1, ProductionOrder2, VerifyVariance);
    end;

    local procedure TestProdOrder_NegConsumption(ComponentCostingMethod: Enum "Costing Method"; ProducedItemCostingMethod: Enum "Costing Method"; StartDate: Date; CalcPer: Enum "Inventory Value Calc. Per"; RevaluationFactor: Decimal)
    var
        ComponentItem: Record Item;
        ProducedItem: Record Item;
        EmptyItem: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ProductionOrder: Record "Production Order";
        EmptyProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ConsumptionItemJournalLine: Record "Item Journal Line";
        ConsumptionItemJournalBatch: Record "Item Journal Batch";
        ItemJnlBatch: Record "Item Journal Batch";
        QtyCompInProdItem: Decimal;
        ProdOrderQty: Decimal;
        QtyCompInProdOrder: Decimal;
        TotalPurchQty: Decimal;
        ConsumptionQty: Decimal;
        NegConsmpCostbeforeReval: Decimal;
        NegConsmpCostafterReval: Decimal;
        RefNegConsmpCostafterReval: Decimal;
        VerifyVariance: Boolean;
    begin
        EmptyItem.Init();
        EmptyProdOrder.Init();
        VerifyVariance := ProducedItemCostingMethod = ProducedItem."Costing Method"::Standard;

        QtyCompInProdItem := LibraryRandom.RandDecInDecimalRange(0.1, 1, 2);
        ProdOrderQty := LibraryRandom.RandDecInDecimalRange(100, 200, 2);

        SetupItems1Comp1ProdItem(ComponentItem, ProducedItem, ComponentCostingMethod, ProducedItemCostingMethod, QtyCompInProdItem);
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProducedItem, '', '', ProdOrderQty, StartDate + 30);

        QtyCompInProdOrder := Round(QtyCompInProdItem * ProdOrderQty, ComponentItem."Rounding Precision", '>');
        TotalPurchQty := PurchaseItem1Comp1ProdPartialAppln(ComponentItem, QtyCompInProdOrder, ComponentItem."Unit Cost", StartDate);

        ConsumptionQty :=
          LibraryRandom.RandDecInDecimalRange(QtyCompInProdOrder + 1, TotalPurchQty - 1, ComponentItem."Rounding Precision");

        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        LibraryManufacturing.POSTConsumption(ProdOrderLine, ComponentItem, '', '', ConsumptionQty, StartDate + 4, ComponentItem."Unit Cost");

        LibraryManufacturing.POSTOutput(ProdOrderLine, ProdOrderQty, StartDate + 4, ProducedItem."Unit Cost");

        // Post negative consumption for the excess consumption posted previously
        ItemLedgerEntry.SetRange("Item No.", ComponentItem."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Consumption);
        ItemLedgerEntry.FindLast();
        LibraryManufacturing.CreateConsumptionJournalLine(
          ConsumptionItemJournalBatch, ProdOrderLine, ComponentItem, StartDate + 4, '', '', -(ConsumptionQty - QtyCompInProdOrder),
          ComponentItem."Unit Cost");
        ConsumptionItemJournalLine.SetRange("Journal Template Name", ConsumptionItemJournalBatch."Journal Template Name");
        ConsumptionItemJournalLine.SetRange("Journal Batch Name", ConsumptionItemJournalBatch.Name);
        ConsumptionItemJournalLine.SetRange("Item No.", ComponentItem."No.");
        ConsumptionItemJournalLine.FindFirst();
        ConsumptionItemJournalLine.Validate("Applies-from Entry", ItemLedgerEntry."Entry No.");
        ConsumptionItemJournalLine.Modify();
        LibraryInventory.PostItemJournalBatch(ConsumptionItemJournalBatch);

        // Finish Order
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, StartDate + 10, false);

        // AdjustCost
        LibraryCosting.AdjustCostItemEntries(StrSubstNo('%1|%2', ComponentItem."No.", ProducedItem."No."), '');
        // Verify
        VerifyCost(ComponentItem, EmptyItem, EmptyItem, ProductionOrder, EmptyProdOrder, VerifyVariance);

        ItemLedgerEntry.SetRange(Positive, true);
        ItemLedgerEntry.FindLast();
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        NegConsmpCostbeforeReval := ItemLedgerEntry."Cost Amount (Actual)";

        ExecuteRevalueExistingInventory(ComponentItem, ItemJnlBatch, StartDate + 1, CalcPer, false, false, false, "Inventory Value Calc. Base"::" ", '', '');
        LibraryPatterns.ModifyPostRevaluation(ItemJnlBatch, RevaluationFactor);
        LibraryCosting.AdjustCostItemEntries(StrSubstNo('%1|%2', ComponentItem."No.", ProducedItem."No."), '');

        // Verify
        VerifyCost(ComponentItem, EmptyItem, EmptyItem, ProductionOrder, EmptyProdOrder, VerifyVariance);

        // Test Revaluation Cost Flow to the negative consumption item
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        NegConsmpCostafterReval := ItemLedgerEntry."Cost Amount (Actual)";
        RefNegConsmpCostafterReval := Round(NegConsmpCostbeforeReval * RevaluationFactor, LibraryERM.GetAmountRoundingPrecision());
        Assert.AreEqual(
          RefNegConsmpCostafterReval, NegConsmpCostafterReval, StrSubstNo(TXTIncorrectRevalCost, ItemLedgerEntry."Entry No."));
    end;

    local procedure TestProdOrder_RevalPartialConsumption(ComponentCostingMethod: Enum "Costing Method"; ProducedItemCostingMethod: Enum "Costing Method"; StartDate: Date; RevaluationFactor: Decimal)
    var
        ComponentItem: Record Item;
        ProducedItem: Record Item;
        EmptyItem: Record Item;
        ProductionOrder: Record "Production Order";
        EmptyProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJnlBatch: Record "Item Journal Batch";
        QtyCompInProdItem: Decimal;
        ProdOrderQty: Decimal;
        QtyCompInProdOrder: Decimal;
        ConsumptionQty1: Decimal;
        ConsumptionQty2: Decimal;
        ConsumptionQty3: Decimal;
        VerifyVariance: Boolean;
    begin
        EmptyItem.Init();
        EmptyProdOrder.Init();
        VerifyVariance := ProducedItemCostingMethod = ProducedItem."Costing Method"::Standard;

        QtyCompInProdItem := LibraryRandom.RandDecInDecimalRange(0.1, 1, 2);
        ProdOrderQty := LibraryRandom.RandDecInDecimalRange(100, 200, 2);

        SetupItems1Comp1ProdItem(ComponentItem, ProducedItem, ComponentCostingMethod, ProducedItemCostingMethod, QtyCompInProdItem);
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProducedItem, '', '', ProdOrderQty, StartDate + 30);

        QtyCompInProdOrder := Round(QtyCompInProdItem * ProdOrderQty, ComponentItem."Rounding Precision", '>');
        PurchaseItem1Comp1ProdPartialAppln(ComponentItem, QtyCompInProdOrder, ComponentItem."Unit Cost", StartDate);

        // Consumption 1 should be applied from purchase 1
        ConsumptionQty1 := Round(QtyCompInProdOrder / 4, ComponentItem."Rounding Precision");
        // Consumption 1 should be applied partly from purchase 1, and partly from purchase 2
        ConsumptionQty2 := Round(QtyCompInProdOrder / 2, ComponentItem."Rounding Precision");
        // Consumption 1 should be applied from purchase 2
        ConsumptionQty3 := QtyCompInProdOrder - ConsumptionQty1 - ConsumptionQty2;

        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        LibraryManufacturing.POSTConsumption(ProdOrderLine, ComponentItem, '', '', ConsumptionQty1, StartDate + 4, ComponentItem."Unit Cost");
        LibraryManufacturing.POSTConsumption(ProdOrderLine, ComponentItem, '', '', ConsumptionQty2, StartDate + 6, ComponentItem."Unit Cost");
        LibraryManufacturing.POSTConsumption(ProdOrderLine, ComponentItem, '', '', ConsumptionQty3, StartDate + 8, ComponentItem."Unit Cost");

        LibraryManufacturing.POSTOutput(ProdOrderLine, ProdOrderQty, StartDate + 10, ProducedItem."Unit Cost");

        // Finish Order
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, StartDate + 11, false);

        // AdjustCost
        LibraryCosting.AdjustCostItemEntries(StrSubstNo('%1|%2', ComponentItem."No.", ProducedItem."No."), '');
        // Verify
        VerifyCost(ComponentItem, EmptyItem, EmptyItem, ProductionOrder, EmptyProdOrder, VerifyVariance);

        // Execute Revaluation after consumption 1, but before consumption 2
        ExecuteRevalueExistingInventory(
          ComponentItem, ItemJnlBatch, StartDate + 5, "Inventory Value Calc. Per"::"Item Ledger Entry", false, false, false, "Inventory Value Calc. Base"::" ", '', '');
        LibraryPatterns.ModifyPostRevaluation(ItemJnlBatch, RevaluationFactor);

        LibraryCosting.AdjustCostItemEntries(StrSubstNo('%1|%2', ComponentItem."No.", ProducedItem."No."), '');

        // Verify
        VerifyCost(ComponentItem, EmptyItem, EmptyItem, ProductionOrder, EmptyProdOrder, VerifyVariance);
    end;

    local procedure TestProdOrderAverageComponent(ProducedItemCostingMethod: Enum "Costing Method"; StartDate: Date)
    var
        ProdOrderLine: Record "Prod. Order Line";
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlLine: Record "Item Journal Line";
        ComponentItem: Record Item;
        ProducedItem: Record Item;
        ProductionOrder: Record "Production Order";
        QtyCompInProdItem: Decimal;
        ProdOrderQty: Decimal;
        QtyCompInProdOrder: Decimal;
        PurchaseQty1: Decimal;
        PurchaseQty2: Decimal;
        Cost1: Decimal;
        Cost2: Decimal;
        Cost3: Decimal;
        VerifyVariance: Boolean;
    begin
        QtyCompInProdItem := LibraryRandom.RandDecInDecimalRange(0.1, 1, 2);
        ProdOrderQty := LibraryRandom.RandDecInDecimalRange(100, 200, 2);

        SetupItems1Comp1ProdItem(
          ComponentItem, ProducedItem, ComponentItem."Costing Method"::Average, ProducedItemCostingMethod, QtyCompInProdItem);

        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProducedItem, '', '', ProdOrderQty, StartDate + 30);

        QtyCompInProdOrder := Round(QtyCompInProdItem * ProdOrderQty, ComponentItem."Rounding Precision", '>');

        PurchaseQty1 := Round(QtyCompInProdOrder / 2, ComponentItem."Rounding Precision");
        PurchaseQty2 := QtyCompInProdOrder - PurchaseQty1;

        Cost1 := LibraryPatterns.RandCost(ComponentItem);
        Cost2 := LibraryPatterns.RandCost(ComponentItem);
        Cost3 := LibraryPatterns.RandCost(ComponentItem);

        LibraryInventory.CreateItemJournalBatchByType(ItemJnlBatch, ItemJnlBatch."Template Type"::Item);
        LibraryInventory.CreateItemJournalLine(
          ItemJnlLine, ItemJnlBatch, ComponentItem, '', '', StartDate, ItemJnlLine."Entry Type"::Purchase, PurchaseQty1, Cost1);
        LibraryInventory.CreateItemJournalLine(
          ItemJnlLine, ItemJnlBatch, ComponentItem, '', '', StartDate + 1, ItemJnlLine."Entry Type"::Purchase, PurchaseQty2, Cost2);
        LibraryInventory.PostItemJournalBatch(ItemJnlBatch);

        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        LibraryManufacturing.POSTConsumption(ProdOrderLine, ComponentItem, '', '', QtyCompInProdOrder, StartDate + 2, ComponentItem."Unit Cost");

        LibraryInventory.CreateItemJournalBatchByType(ItemJnlBatch, ItemJnlBatch."Template Type"::Item);
        LibraryInventory.CreateItemJournalLine(
          ItemJnlLine, ItemJnlBatch, ComponentItem, '', '', StartDate + 2, ItemJnlLine."Entry Type"::Purchase, PurchaseQty2, Cost3);
        LibraryInventory.PostItemJournalBatch(ItemJnlBatch);

        LibraryManufacturing.POSTOutput(ProdOrderLine, ProdOrderQty, StartDate + 9, ProducedItem."Unit Cost");

        // Finish
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, StartDate + 10, false);

        LibraryCosting.AdjustCostItemEntries(StrSubstNo('%1|%2', ComponentItem."No.", ProducedItem."No."), '');

        // Verify
        VerifyVariance := ProducedItemCostingMethod = ProducedItem."Costing Method"::Standard;
        LibraryCosting.CheckAdjustment(ComponentItem);
        LibraryManufacturing.CheckProductionOrderCost(ProductionOrder, VerifyVariance);
    end;

    local procedure TestProdOrderAvgCompwithReval(ProducedItemCostingMethod: Enum "Costing Method"; StartDate: Date)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ParentItem: Record Item;
        CompItem: Record Item;
        Qty: Decimal;
        QtyPer: Decimal;
    begin
        Initialize();
        Qty := LibraryRandom.RandInt(20);
        QtyPer := LibraryRandom.RandInt(10);

        // Setup.
        SetupItems1Comp1ProdItem(CompItem, ParentItem, CompItem."Costing Method"::Average, ProducedItemCostingMethod, QtyPer);

        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ParentItem, '', '', Qty, StartDate);
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        // Purchase component item.
        LibraryInventory.PostPositiveAdjustment(CompItem, '', '', '', Qty * QtyPer / 2, StartDate, LibraryRandom.RandDec(100, 2));
        LibraryInventory.PostPositiveAdjustment(CompItem, '', '', '', (Qty * QtyPer) / 2 + 1,
          StartDate + 1, LibraryRandom.RandDec(100, 2));

        // Post consumption.
        LibraryManufacturing.CreateConsumptionJournalLine(ItemJournalBatch, ProdOrderLine, CompItem, StartDate + 5, '', '', Qty * QtyPer, 0);
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

        // Adjust.
        LibraryCosting.AdjustCostItemEntries(ParentItem."No." + '|' + CompItem."No.", '');

        // Revalue component.
        LibraryPatterns.CalculateInventoryValueRun(
          ItemJournalBatch, CompItem, StartDate + 7, "Inventory Value Calc. Per"::Item, false, false, false, "Inventory Value Calc. Base"::" ", false, '', '');
        LibraryPatterns.ModifyPostRevaluation(ItemJournalBatch, LibraryRandom.RandDecInRange(1, 3, 2));

        // Post output.
        LibraryManufacturing.CreateOutputJournalLine(ItemJournalBatch, ProdOrderLine, StartDate + 6, Qty, 0);
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

        // Adjust.
        LibraryCosting.AdjustCostItemEntries(ParentItem."No." + '|' + CompItem."No.", '');

        // Revalue component again.
        LibraryPatterns.CalculateInventoryValueRun(
          ItemJournalBatch, CompItem, StartDate + 7, "Inventory Value Calc. Per"::Item, false, false, false, "Inventory Value Calc. Base"::" ", false, '', '');
        LibraryPatterns.ModifyPostRevaluation(ItemJournalBatch, LibraryRandom.RandDecInRange(1, 3, 2));

        // Finish prod. order.
        ProductionOrder.Get(ProdOrderLine.Status, ProdOrderLine."Prod. Order No.");
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, StartDate, false);

        // Adjust.
        LibraryCosting.AdjustCostItemEntries(ParentItem."No." + '|' + CompItem."No.", '');

        // Verify adjustment.
        LibraryCosting.CheckAdjustment(ParentItem);
        LibraryCosting.CheckAdjustment(CompItem);
        LibraryManufacturing.CheckProductionOrderCost(ProductionOrder, true);
    end;

    [Test]
    [HandlerFunctions('ChangeAvgCostPeriodConfirmHndl,ChangeAvgCostPeriodMessageHndl')]
    [Scope('OnPrem')]
    procedure TestProdAverageItemConsNone()
    begin
        TestProdAverageItemCons(false, false);
    end;

    [Test]
    [HandlerFunctions('ChangeAvgCostPeriodConfirmHndl,ChangeAvgCostPeriodMessageHndl')]
    [Scope('OnPrem')]
    procedure TestProdAverageItemConsReserv()
    begin
        TestProdAverageItemCons(true, false);
    end;

    [Test]
    [HandlerFunctions('ChangeAvgCostPeriodConfirmHndl,ChangeAvgCostPeriodMessageHndl')]
    [Scope('OnPrem')]
    procedure TestProdAverageItemConsFixApp()
    begin
        TestProdAverageItemCons(false, true);
    end;

    [Test]
    [HandlerFunctions('ChangeAvgCostPeriodConfirmHndl,ChangeAvgCostPeriodMessageHndl')]
    [Scope('OnPrem')]
    procedure TestProdAverageItemConsReservNoAccPeriods()
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        // [FEATURE] [No Accounting Periods]
        // [SCENARIO 222561] Production, reservation and revaluation of item with average cost without accounting periods
        AccountingPeriod.DeleteAll();

        TestProdAverageItemCons(true, false);
    end;

    local procedure Initialize()
    var
        InventorySetup: Record "Inventory Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM CETAF Costing Reval. WIP");

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM CETAF Costing Reval. WIP");

        LibraryInventory.UpdateAverageCostSettings(
          InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Day);
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryPatterns.SetNoSeries();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM CETAF Costing Reval. WIP");
    end;

    local procedure InitializeQuantities(var QtyCompInProdItem1: Decimal; var QtyCompInProdItem2: Decimal; var QtyProdItem1InProdItem2: Decimal; var ProdOrder1Qty: Decimal; var ProdOrder2Qty: Decimal; var SaleProdItem2Qty: Decimal)
    begin
        QtyCompInProdItem1 := LibraryRandom.RandDecInDecimalRange(0.1, 1, 2);
        QtyCompInProdItem2 := LibraryRandom.RandDecInDecimalRange(1, 10, 2);
        QtyProdItem1InProdItem2 := LibraryRandom.RandDecInDecimalRange(1, 10, 2);
        ProdOrder1Qty := LibraryRandom.RandDecInDecimalRange(100, 200, 2);
        // Ensure that quantity of ProdItem1 consumed in ProdOrder2 should not be greater than what is produced in ProdItem1
        ProdOrder2Qty := LibraryRandom.RandDecInDecimalRange(10, ProdOrder1Qty / QtyProdItem1InProdItem2, 2);
        SaleProdItem2Qty := LibraryRandom.RandDecInDecimalRange(1, ProdOrder2Qty, 2);
    end;

    local procedure TestProdAverageItemCons(Reserve: Boolean; FixedAppl: Boolean)
    var
        InventorySetup: Record "Inventory Setup";
        CompItem: Record Item;
        ProdItem: Record Item;
        ProductionOrder: array[4] of Record "Production Order";
        ItemLedgEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        StartDate: Date;
        TotalQty: Decimal;
        ProdQty: Decimal;
        UnitAmount: Decimal;
        CompILEoutput: Integer;
        RevaluationFactor: Decimal;
        ExpectedCostAmount: Decimal;
        OldAvgCostPeriod: Enum "Average Cost Period Type";
        NewAvgCostPeriod: Enum "Average Cost Period Type";
        i: Integer;
    begin
        // VSTF 336187 Positive Cost Amount (Actual) figures while it should be negative in a specific Scenario including Production,
        // the use of reservation and a revaluation.

        // Setup
        Initialize();
        NewAvgCostPeriod := InventorySetup."Average Cost Period"::Month;
        SetupAvgCostPeriod(NewAvgCostPeriod, OldAvgCostPeriod);
        CreateItem(CompItem, CompItem."Costing Method"::Average);
        CreateItem(ProdItem, ProdItem."Costing Method"::FIFO);
        StartDate := WorkDate();
        TotalQty := 10000;
        ProdQty := 9990;
        UnitAmount := 0.2;

        // Repro steps
        LibraryInventory.PostPositiveAdjustment(CompItem, '', '', '', TotalQty, StartDate, UnitAmount);

        CreateAndPostProdOrder1Comp(ProductionOrder[1], CompItem, ProdItem, StartDate, ProdQty, 0, false);
        // ProdItem is consumed & CompItem is output - later date
        CreateAndPostProdOrder1Comp(ProductionOrder[2], ProdItem, CompItem, StartDate + 1, ProdQty, 0, false);
        // CompItem is consumed again
        if Reserve or FixedAppl then // Use the output entry from production of CompItem
            CompILEoutput := FindFirstILE(ItemLedgEntry, ProductionOrder[2]."No.", CompItem."No.", ItemLedgEntry."Entry Type"::Output)
        else
            CompILEoutput := 0; // Use entry found by system
        CreateAndPostProdOrder1Comp(ProductionOrder[3], CompItem, ProdItem, StartDate + 1, ProdQty, CompILEoutput, Reserve);
        // Use the remainder on inventory of CompItem - first date
        CreateAndPostProdOrder1Comp(ProductionOrder[4], CompItem, ProdItem, StartDate, TotalQty - ProdQty, 0, false);
        // Finish production orders
        for i := 1 to 4 do
            LibraryManufacturing.ChangeProdOrderStatus(
              ProductionOrder[i], ProductionOrder[i].Status::Finished, ProductionOrder[i]."Due Date", false);

        // Adjust and verify Cost per Unit
        LibraryCosting.AdjustCostItemEntries(CompItem."No." + '|' + ProdItem."No.", '');

        // Revaluate ProdItem - first output entry - and then adjust
        RevaluationFactor := 0.25;
        FindFirstILE(ItemLedgEntry, ProductionOrder[1]."No.", ProdItem."No.", ItemLedgEntry."Entry Type"::Output);
        LibraryPatterns.ExecutePostRevalueInboundILE(ProdItem, ItemLedgEntry, RevaluationFactor);
        LibraryCosting.AdjustCostItemEntries(CompItem."No." + '|' + ProdItem."No.", '');

        // Verification
        if FixedAppl then
            ExpectedCostAmount := ProdQty * UnitAmount * RevaluationFactor
        else begin
            ExpectedCostAmount := ProdQty * UnitAmount * RevaluationFactor + UnitAmount * (TotalQty - ProdQty);
            ExpectedCostAmount := ExpectedCostAmount / TotalQty * ProdQty;
        end;

        // ProdItem
        FindFirstILE(ItemLedgEntry, ProductionOrder[3]."No.", ProdItem."No.", ItemLedgEntry."Entry Type"::Output);
        Assert.AreNearlyEqual(ExpectedCostAmount, ItemLedgEntry."Cost Amount (Actual)", 0.01, 'Cost Amount in ProdItem is wrong.');
        // CompItem
        FindFirstILE(ItemLedgEntry, ProductionOrder[3]."No.", CompItem."No.", ItemLedgEntry."Entry Type"::Consumption);
        Assert.AreNearlyEqual(-ExpectedCostAmount, ItemLedgEntry."Cost Amount (Actual)", 0.01, 'Cost Amount in CompItem is wrong.');

        LibraryCosting.CheckAdjustment(ProdItem);
        CompItem.CalcFields(Inventory);
        Assert.IsTrue(CompItem.Inventory = 0, 'Inventory for component should be 0.');
        ValueEntry.SetRange("Item No.", CompItem."No.");
        ValueEntry.CalcSums("Cost Amount (Actual)", ValueEntry."Cost Amount (Expected)");
        Assert.IsTrue(ValueEntry."Cost Amount (Expected)" = 0, 'Cost amount expected for component should be 0.');
        Assert.IsTrue(ValueEntry."Cost Amount (Actual)" = 0, 'Cost amount actual for component should be 0.');

        // Tear down
        SetupAvgCostPeriod(OldAvgCostPeriod, NewAvgCostPeriod);
    end;

    local procedure SetupItems(var ComponentItem: Record Item; var ProducedItem1: Record Item; var ProducedItem2: Record Item; ComponentCostingMethod: Enum "Costing Method"; ProducedItemCostingMethod: Enum "Costing Method"; QtyCompInProd1: Decimal; QtyCompInProd2: Decimal; QtyProd1InProd2: Decimal)
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        Cost1: Decimal;
        Cost2: Decimal;
        Cost3: Decimal;
    begin
        // ProducedItem1 contains ComponentItem; ProducedItem2 contains ProducedItem1 and ComponentItem

        Cost1 := LibraryRandom.RandDecInDecimalRange(1, 10, 2);
        Cost2 := LibraryRandom.RandDecInDecimalRange(1, 10, 2);
        Cost3 := LibraryRandom.RandDecInDecimalRange(1, 10, 2);

        LibraryInventory.CreateItemSimple(ComponentItem, ComponentCostingMethod, Cost1);
        LibraryInventory.CreateItemSimple(ProducedItem1, ProducedItemCostingMethod, Cost2);
        LibraryInventory.CreateItemSimple(ProducedItem2, ProducedItemCostingMethod, Cost3);

        // Make Production BOM 1
        LibraryManufacturing.CreateProductionBOM(ProductionBOMHeader, ProducedItem1, ComponentItem, QtyCompInProd1, '');

        // Make Production BOM 2
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ProducedItem2."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ComponentItem."No.", QtyCompInProd2);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ProducedItem1."No.", QtyProd1InProd2);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify();
        ProducedItem2.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProducedItem2.Modify();
    end;

    local procedure SetupItems1Comp1ProdItem(var ComponentItem: Record Item; var ProducedItem: Record Item; ComponentCostingMethod: Enum "Costing Method"; ProducedItemCostingMethod: Enum "Costing Method"; QtyCompInProdItem: Decimal)
    var
        ProductionBOMHeader: Record "Production BOM Header";
        CostCompItem: Decimal;
        CostProdItem: Decimal;
    begin
        // ProducedItem1 contains ComponentItem; ProducedItem2 contains ProducedItem1 and ComponentItem
        CostCompItem := LibraryPatterns.RandCost(ComponentItem);
        CostProdItem := LibraryPatterns.RandCost(ProducedItem);

        LibraryInventory.CreateItemSimple(ComponentItem, ComponentCostingMethod, CostCompItem);
        LibraryInventory.CreateItemSimple(ProducedItem, ProducedItemCostingMethod, CostProdItem);

        // Make Production BOM
        LibraryManufacturing.CreateProductionBOM(ProductionBOMHeader, ProducedItem, ComponentItem, QtyCompInProdItem, '');
    end;

    local procedure CreateItem(var Item: Record Item; CostingMethod: Enum "Costing Method")
    begin
        LibraryInventory.CreateItemSimple(Item, CostingMethod, 0);
        Item.Description := Format(Item."Costing Method");
        Item.Modify();
    end;

    local procedure CreateAndPostProdOrder1Comp(var ProductionOrder: Record "Production Order"; ComponentItem: Record Item; ProducedItem: Record Item; PostingDate: Date; ProdQty: Decimal; ApplyToEntry: Integer; ReservComp: Boolean)
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ProducedItem, '', '', ProdQty, PostingDate);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, false, false, false);

        if ReservComp then begin
            MakeProdOrderCompReservation(ProductionOrder, ComponentItem."No.", ApplyToEntry, ProdQty);
            ApplyToEntry := 0; // Reservation replaces fixed application
        end;

        PostProdOrder1(ProductionOrder, ComponentItem, ProducedItem, PostingDate, ProdQty, ProdQty, ApplyToEntry);
    end;

    local procedure SetupProdOrders(var ProductionOrder1: Record "Production Order"; var ProductionOrder2: Record "Production Order"; ProducedItem1: Record Item; ProducedItem2: Record Item; ProdOrder1Qty: Decimal; ProdOrder2Qty: Decimal; DueDate: Date)
    begin
        // Create production order 1
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder1, ProductionOrder1.Status::Released, ProducedItem1, '', '', ProdOrder1Qty, DueDate);
        // Create production order 2
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder2, ProductionOrder1.Status::Released, ProducedItem2, '', '', ProdOrder2Qty, DueDate);
    end;

    local procedure PurchaseItemSplitApplication(ComponentItem: Record Item; QtyCompInProdOrder1: Decimal; QtyCompInProdOrder2: Decimal; UnitCost: Decimal; PostingDate: Date)
    var
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlLine: Record "Item Journal Line";
        PurchaseQty1: Decimal;
        PurchaseQty2: Decimal;
        PurchaseQty2_1: Decimal;
        PurchaseQty2_2: Decimal;
        PurchaseQty3: Decimal;
        PurchaseQty4: Decimal;
        PurchaseQty5: Decimal;
    begin
        // Components in first purchase will go entirely into ProdOrder1
        PurchaseQty1 := Round(QtyCompInProdOrder1 / 2, ComponentItem."Rounding Precision");
        // Components in second purchase will be split between ProdOrder1 and ProdOrder2
        PurchaseQty2_1 := QtyCompInProdOrder1 - PurchaseQty1;
        PurchaseQty2_2 := Round(QtyCompInProdOrder2 / 4, ComponentItem."Rounding Precision");
        PurchaseQty2 := PurchaseQty2_1 + PurchaseQty2_2;
        // Components in third purchase will go entirely into ProdOrder2
        PurchaseQty3 := Round(QtyCompInProdOrder2 / 4, ComponentItem."Rounding Precision");
        // Part of components in fourth purchase will go into ProdOrder2, and part will be unused
        PurchaseQty4 := QtyCompInProdOrder2 - PurchaseQty2_2 - PurchaseQty3 + LibraryRandom.RandDecInDecimalRange(1, 100, 2);
        // Components in fifth purchase will be unused
        PurchaseQty5 := LibraryRandom.RandDecInDecimalRange(1, 100, 2);

        LibraryInventory.CreateItemJournalBatchByType(ItemJnlBatch, ItemJnlBatch."Template Type"::Item);

        LibraryInventory.CreateItemJournalLine(
          ItemJnlLine, ItemJnlBatch, ComponentItem, '', '', PostingDate, ItemJnlLine."Entry Type"::Purchase, PurchaseQty1, UnitCost);
        LibraryInventory.CreateItemJournalLine(
          ItemJnlLine, ItemJnlBatch, ComponentItem, '', '', PostingDate, ItemJnlLine."Entry Type"::Purchase, PurchaseQty2, UnitCost);
        LibraryInventory.CreateItemJournalLine(
          ItemJnlLine, ItemJnlBatch, ComponentItem, '', '', PostingDate, ItemJnlLine."Entry Type"::Purchase, PurchaseQty3, UnitCost);
        LibraryInventory.CreateItemJournalLine(
          ItemJnlLine, ItemJnlBatch, ComponentItem, '', '', PostingDate, ItemJnlLine."Entry Type"::Purchase, PurchaseQty4, UnitCost);
        LibraryInventory.CreateItemJournalLine(
          ItemJnlLine, ItemJnlBatch, ComponentItem, '', '', PostingDate, ItemJnlLine."Entry Type"::Purchase, PurchaseQty5, UnitCost);
        LibraryInventory.PostItemJournalBatch(ItemJnlBatch);
    end;

    local procedure PurchaseItem1Comp1ProdPartialAppln(ComponentItem: Record Item; QtyCompInProdOrder: Decimal; UnitCost: Decimal; PostingDate: Date) TotalPurchQty: Decimal
    var
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlLine: Record "Item Journal Line";
        PurchaseQty1: Decimal;
        PurchaseQty2: Decimal;
    begin
        // Components in first purchase will go entirely into ProdOrder
        PurchaseQty1 := Round(QtyCompInProdOrder / 2, ComponentItem."Rounding Precision");
        // Part of Components in second purchase go into ProdOrder
        PurchaseQty2 := QtyCompInProdOrder - PurchaseQty1 + LibraryRandom.RandDecInDecimalRange(10, 100, 2);

        LibraryInventory.CreateItemJournalBatchByType(ItemJnlBatch, ItemJnlBatch."Template Type"::Item);

        LibraryInventory.CreateItemJournalLine(
          ItemJnlLine, ItemJnlBatch, ComponentItem, '', '', PostingDate, ItemJnlLine."Entry Type"::Purchase, PurchaseQty1, UnitCost);
        LibraryInventory.CreateItemJournalLine(
          ItemJnlLine, ItemJnlBatch, ComponentItem, '', '', PostingDate, ItemJnlLine."Entry Type"::Purchase, PurchaseQty2, UnitCost);
        LibraryInventory.PostItemJournalBatch(ItemJnlBatch);

        TotalPurchQty := PurchaseQty1 + PurchaseQty2;
        exit(TotalPurchQty);
    end;

    local procedure PostProdOrder1(ProductionOrder1: Record "Production Order"; ComponentItem: Record Item; ProducedItem1: Record Item; PostingDate: Date; QtyCompInProdOrder1: Decimal; ProdOrder1Qty: Decimal; ApplyToEntry: Integer)
    var
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJnlLine: Record "Item Journal Line";
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder1.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder1."No.");
        ProdOrderLine.FindFirst();

        if ApplyToEntry = 0 then
            LibraryManufacturing.POSTConsumption(ProdOrderLine, ComponentItem, '', '', QtyCompInProdOrder1, PostingDate, ComponentItem."Unit Cost")
        else begin // Make fixed application before posting consumption
            LibraryManufacturing.CreateConsumptionJournalLine(
              ItemJournalBatch, ProdOrderLine, ComponentItem, PostingDate, '', '', QtyCompInProdOrder1, ComponentItem."Unit Cost");
            ItemJnlLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
            ItemJnlLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
            ItemJnlLine.SetRange("Order Type", ItemJnlLine."Order Type"::Production);
            ItemJnlLine.SetRange("Order No.", ProductionOrder1."No.");
            ItemJnlLine.SetRange("Item No.", ComponentItem."No.");
            ItemJnlLine.FindFirst();
            ItemJnlLine."Applies-to Entry" := ApplyToEntry;
            ItemJnlLine.Modify();
            LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
        end;
        LibraryManufacturing.POSTOutput(ProdOrderLine, ProdOrder1Qty, PostingDate, ProducedItem1."Unit Cost");
    end;

    local procedure PostProdOrder2(ProductionOrder2: Record "Production Order"; ComponentItem: Record Item; ProducedItem1: Record Item; ProducedItem2: Record Item; PostingDate: Date; QtyCompInProdOrder2: Decimal; QtyProdItem1InProdOrder2: Decimal; ProdOrder2Qty: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder2.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder2."No.");
        ProdOrderLine.FindFirst();
        LibraryManufacturing.POSTConsumption(ProdOrderLine, ComponentItem, '', '', QtyCompInProdOrder2, PostingDate, ComponentItem."Unit Cost");
        LibraryManufacturing.POSTConsumption(
          ProdOrderLine, ProducedItem1, '', '', QtyProdItem1InProdOrder2, PostingDate, ProducedItem1."Unit Cost");
        LibraryManufacturing.POSTOutput(ProdOrderLine, ProdOrder2Qty, PostingDate, ProducedItem2."Unit Cost");
    end;

    local procedure ExecuteRevalueExistingInventory(var Item: Record Item; var ItemJnlBatch: Record "Item Journal Batch"; PostingDate: Date; CalculatePer: Enum "Inventory Value Calc. Per"; ByLocation: Boolean; ByVariant: Boolean; UpdStdCost: Boolean; CalcBase: Enum "Inventory Value Calc. Base"; LocationFilter: Code[20]; VariantFilter: Code[20])
    begin
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        LibraryCosting.CheckAdjustment(Item);

        LibraryPatterns.CalculateInventoryValueRun(
          ItemJnlBatch, Item, PostingDate, CalculatePer, ByLocation, ByVariant, UpdStdCost, CalcBase, false, LocationFilter, VariantFilter);

        LibraryPatterns.CHECKCalcInvPost(Item, ItemJnlBatch, PostingDate, CalculatePer, ByLocation, ByVariant, LocationFilter, VariantFilter);
    end;

    local procedure ModifyRevaluationLine(JournalTemplateName: Code[10]; JournalBatchName: Code[10]; LineNo: Integer; RevaluationFactor: Decimal; RoundingPrecision: Decimal)
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        ItemJnlLine.Get(JournalTemplateName, JournalBatchName, LineNo);
        ItemJnlLine.Validate(
          "Inventory Value (Revalued)", Round(ItemJnlLine."Inventory Value (Revalued)" * RevaluationFactor, RoundingPrecision));
        ItemJnlLine.Modify();
    end;

    local procedure FindFirstILE(var ItemLedgEntry: Record "Item Ledger Entry"; ProductionNo: Code[20]; ItemNo: Code[20]; EntryType: Enum "Item Ledger Document Type"): Integer
    begin
        ItemLedgEntry.Reset();
        ItemLedgEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.", "Entry Type");
        ItemLedgEntry.SetRange("Order Type", ItemLedgEntry."Order Type"::Production);
        ItemLedgEntry.SetRange("Order No.", ProductionNo);
        ItemLedgEntry.SetRange("Entry Type", EntryType);
        ItemLedgEntry.SetRange("Item No.", ItemNo);
        ItemLedgEntry.FindFirst();

        ItemLedgEntry.CalcFields("Cost Amount (Actual)");
        exit(ItemLedgEntry."Entry No.");
    end;

    local procedure MakeProdOrderCompReservation(ProductionOrder: Record "Production Order"; ComponentItemNo: Code[20]; ILENo: Integer; Qty: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComp: Record "Prod. Order Component";
        ReservEntry: Record "Reservation Entry";
        EntryNo: Integer;
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        ProdOrderComp.Init();
        ProdOrderComp.Status := ProductionOrder.Status;
        ProdOrderComp."Prod. Order No." := ProductionOrder."No.";
        ProdOrderComp."Prod. Order Line No." := ProdOrderLine."Line No.";
        ProdOrderComp."Line No." := 10000;
        ProdOrderComp.Validate("Due Date", ProductionOrder."Due Date");
        ProdOrderComp.Validate("Item No.", ComponentItemNo);
        ProdOrderComp.Validate("Quantity per", 1);
        ProdOrderComp.Insert();

        EntryNo := 1;
        ReservEntry.Reset();
        if ReservEntry.FindLast() then
            EntryNo := ReservEntry."Entry No." + 1;
        // Component
        ReservEntry.Init();
        ReservEntry."Entry No." := EntryNo;
        ReservEntry.Positive := false;
        ReservEntry."Item No." := ComponentItemNo;
        ReservEntry."Source Type" := DATABASE::"Prod. Order Component";
        ReservEntry."Source Subtype" := ProdOrderComp.Status.AsInteger();
        ReservEntry."Source ID" := ProdOrderComp."Prod. Order No.";
        ReservEntry."Source Prod. Order Line" := ProdOrderComp."Prod. Order Line No.";
        ReservEntry."Source Ref. No." := ProdOrderComp."Line No.";
        ReservEntry."Shipment Date" := ProdOrderComp."Due Date";
        ReservEntry."Quantity (Base)" := -Qty;
        ReservEntry.Quantity := ReservEntry."Quantity (Base)";
        ReservEntry."Qty. per Unit of Measure" := 1;
        ReservEntry.Insert();
        // Inventory
        ReservEntry.Init();
        ReservEntry."Entry No." := EntryNo;
        ReservEntry.Positive := true;
        ReservEntry."Item No." := ComponentItemNo;
        ReservEntry."Source Type" := DATABASE::"Item Ledger Entry";
        ReservEntry."Source Ref. No." := ILENo;
        ReservEntry."Quantity (Base)" := Qty;
        ReservEntry.Quantity := ReservEntry."Quantity (Base)";
        ReservEntry."Qty. per Unit of Measure" := 1;
        ReservEntry.Insert();
    end;

    local procedure SetupAvgCostPeriod(NewAvgCostPeriod: Enum "Average Cost Period Type"; var OldAvgCostPeriod: Enum "Average Cost Period Type")
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        OldAvgCostPeriod := InventorySetup."Average Cost Period";

        if InventorySetup."Average Cost Period" <> NewAvgCostPeriod then begin
            InventorySetup.Validate("Average Cost Period", NewAvgCostPeriod);
            InventorySetup.Modify();
        end else
            // For message handler if no change for Average Cost Period
            if Confirm(AnyQst) then
                Message(AnyMsg);
    end;

    local procedure VerifyCost(Item1: Record Item; Item2: Record Item; Item3: Record Item; ProdOrder1: Record "Production Order"; ProdOrder2: Record "Production Order"; VerifyVariance: Boolean)
    begin
        if Item1."No." <> '' then
            LibraryCosting.CheckAdjustment(Item1);
        if Item2."No." <> '' then
            LibraryCosting.CheckAdjustment(Item2);
        if Item3."No." <> '' then
            LibraryCosting.CheckAdjustment(Item3);
        if ProdOrder1."No." <> '' then
            LibraryManufacturing.CheckProductionOrderCost(ProdOrder1, VerifyVariance);
        if ProdOrder2."No." <> '' then
            LibraryManufacturing.CheckProductionOrderCost(ProdOrder2, VerifyVariance);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ChangeAvgCostPeriodMessageHndl(Message: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ChangeAvgCostPeriodConfirmHndl(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

