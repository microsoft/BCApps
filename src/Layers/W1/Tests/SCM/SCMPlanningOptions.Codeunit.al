codeunit 137008 "SCM Planning Options"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Planning] [SCM]
        Initialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
        Initialized: Boolean;
        WrongFieldValueErr: Label '%1 is incorrect in %2', Comment = '%1: Field name; %2: Table name. Example: "Direct Unit Cost is incorrect in Requisition Line"';

    [Test]
    [Scope('OnPrem')]
    procedure RecheduleOutCase1()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
    begin
        Initialize();

        LibraryInventory.CreateItem(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Evaluate(Item."Rescheduling Period", '<5D>');
        Evaluate(Item."Safety Lead Time", '<0D>');
        Item.Modify(true);

        CreatePurchaseOrder(PurchaseLine, Item."No.", 7, CalcDate('<+5D>', WorkDate()));

        CreateSalesOrder(SalesLine, Item."No.", 7, CalcDate('<+11D>', WorkDate()));

        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate('<+2D>', WorkDate()), CalcDate('<+16D>', WorkDate()));

        // verify planning worksheet lines
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", Item."No.");
        AssertPlanningLine(RequisitionLine, RequisitionLine."Action Message"::Cancel, 0D,
          PurchaseLine."Expected Receipt Date", PurchaseLine.Quantity, 0, 1, false);
        AssertPlanningLine(RequisitionLine, RequisitionLine."Action Message"::New, 0D,
          SalesLine."Shipment Date", 0, PurchaseLine.Quantity, 1, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecheduleOutCase2()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
    begin
        Initialize();

        LibraryInventory.CreateItem(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Evaluate(Item."Rescheduling Period", '<6D>');
        Evaluate(Item."Safety Lead Time", '<0D>');
        Item.Modify(true);

        CreatePurchaseOrder(PurchaseLine, Item."No.", 7, CalcDate('<+5D>', WorkDate()));

        CreateSalesOrder(SalesLine, Item."No.", 7, CalcDate('<+11D>', WorkDate()));

        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate('<+2D>', WorkDate()), CalcDate('<+16D>', WorkDate()));

        // verify planning worksheet lines
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", Item."No.");
        AssertPlanningLine(RequisitionLine, RequisitionLine."Action Message"::Reschedule,
          PurchaseLine."Expected Receipt Date", SalesLine."Shipment Date",
          0, PurchaseLine.Quantity, 1, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecheduleInCase1()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
    begin
        Initialize();

        LibraryInventory.CreateItem(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Evaluate(Item."Rescheduling Period", '<5D>');
        Evaluate(Item."Safety Lead Time", '<0D>');
        Item.Modify(true);

        CreatePurchaseOrder(PurchaseLine, Item."No.", 7, CalcDate('<+11D>', WorkDate()));

        CreateSalesOrder(SalesLine, Item."No.", 7, CalcDate('<+5D>', WorkDate()));

        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate('<+2D>', WorkDate()), CalcDate('<+16D>', WorkDate()));

        // verify planning worksheet lines
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", Item."No.");
        AssertPlanningLine(RequisitionLine, RequisitionLine."Action Message"::Cancel, 0D,
          PurchaseLine."Expected Receipt Date", PurchaseLine.Quantity, 0, 1, false);
        AssertPlanningLine(RequisitionLine, RequisitionLine."Action Message"::New, 0D,
          SalesLine."Shipment Date", 0, PurchaseLine.Quantity, 1, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecheduleInCase2()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
    begin
        Initialize();

        LibraryInventory.CreateItem(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Evaluate(Item."Rescheduling Period", '<6D>');
        Evaluate(Item."Safety Lead Time", '<0D>');
        Item.Modify(true);

        CreatePurchaseOrder(PurchaseLine, Item."No.", 7, CalcDate('<+11D>', WorkDate()));

        CreateSalesOrder(SalesLine, Item."No.", 7, CalcDate('<+5D>', WorkDate()));

        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate('<+2D>', WorkDate()), CalcDate('<+16D>', WorkDate()));
        // verify planning worksheet lines
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", Item."No.");
        AssertPlanningLine(RequisitionLine, RequisitionLine."Action Message"::Reschedule,
          PurchaseLine."Expected Receipt Date", SalesLine."Shipment Date",
          0, PurchaseLine.Quantity, 1, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DampenerPeriodCase1()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
    begin
        Initialize();

        LibraryPlanning.SetDefaultDampenerPeriod('<5D>');

        LibraryInventory.CreateItem(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        // Ensure that Dampener Period is taken from Mfg.Setup due to the defaulting rules
        Evaluate(Item."Dampener Period", '');
        Evaluate(Item."Safety Lead Time", '<0D>');
        Evaluate(Item."Lot Accumulation Period", '<10D>');
        Item.Modify(true);

        CreatePurchaseOrder(PurchaseLine, Item."No.", 7, CalcDate('<+5D>', WorkDate()));

        CreateSalesOrder(SalesLine, Item."No.", 7, CalcDate('<+11D>', WorkDate()));

        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate('<+2D>', WorkDate()), CalcDate('<+16D>', WorkDate()));

        // verify planning worksheet lines
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", Item."No.");
        AssertPlanningLine(RequisitionLine, RequisitionLine."Action Message"::Cancel, 0D,
          PurchaseLine."Expected Receipt Date", PurchaseLine.Quantity, 0, 1, false);
        AssertPlanningLine(RequisitionLine, RequisitionLine."Action Message"::New, 0D,
          SalesLine."Shipment Date", 0, SalesLine.Quantity, 1, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DampenerPeriodCase2()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
    begin
        Initialize();

        LibraryInventory.CreateItem(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Evaluate(Item."Dampener Period", '<6D>');
        Evaluate(Item."Safety Lead Time", '<0D>');
        Evaluate(Item."Lot Accumulation Period", '<10D>');
        Item.Modify(true);

        CreatePurchaseOrder(PurchaseLine, Item."No.", 7, CalcDate('<+5D>', WorkDate()));

        CreateSalesOrder(SalesLine, Item."No.", 7, CalcDate('<+11D>', WorkDate()));

        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate('<+2D>', WorkDate()), CalcDate('<+16D>', WorkDate()));
        // verify planning worksheet lines
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", Item."No.");
        AssertPlanningLine(RequisitionLine, RequisitionLine."Action Message"::" ",
          0D, 0D,
          0, 0, 0, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LotAccumulationCase1()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
    begin
        Initialize();

        LibraryInventory.CreateItem(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Evaluate(Item."Lot Accumulation Period", '<5D>');
        Evaluate(Item."Safety Lead Time", '<0D>');
        Item.Modify(true);

        CreatePurchaseOrder(PurchaseLine, Item."No.", 4, CalcDate('<+5D>', WorkDate()));

        CreateSalesOrder(SalesLine, Item."No.", 3, CalcDate('<+5D>', WorkDate()));
        CreateSalesOrder(SalesLine, Item."No.", 7, CalcDate('<+11D>', WorkDate()));

        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate('<+2D>', WorkDate()), CalcDate('<+16D>', WorkDate()));
        // verify planning worksheet lines
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", Item."No.");
        AssertPlanningLine(RequisitionLine, RequisitionLine."Action Message"::"Change Qty.",
          0D, PurchaseLine."Expected Receipt Date",
          4, 3, 1, false);
        AssertPlanningLine(RequisitionLine, RequisitionLine."Action Message"::New,
          0D, SalesLine."Shipment Date",
          0, 7, 1, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LotAccumulationCase2()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
    begin
        Initialize();

        LibraryInventory.CreateItem(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Evaluate(Item."Lot Accumulation Period", '<6D>');
        Evaluate(Item."Safety Lead Time", '<0D>');
        Item.Modify(true);

        CreatePurchaseOrder(PurchaseLine, Item."No.", 4, CalcDate('<+5D>', WorkDate()));

        CreateSalesOrder(SalesLine, Item."No.", 3, CalcDate('<+5D>', WorkDate()));
        CreateSalesOrder(SalesLine, Item."No.", 7, CalcDate('<+11D>', WorkDate()));

        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate('<+2D>', WorkDate()), CalcDate('<+16D>', WorkDate()));
        // verify planning worksheet lines
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", Item."No.");
        AssertPlanningLine(RequisitionLine, RequisitionLine."Action Message"::"Change Qty.",
          0D, PurchaseLine."Expected Receipt Date",
          4, 10, 1, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimeBucket()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
    begin
        Initialize();

        LibraryInventory.CreateItem(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Fixed Reorder Qty.");
        Item."Reorder Point" := 4;
        Item."Reorder Quantity" := 7;
        Evaluate(Item."Lead Time Calculation", '<2D>');
        Evaluate(Item."Time Bucket", '<8D>');
        Evaluate(Item."Safety Lead Time", '<0D>');
        Item.Modify(true);

        CreatePurchaseOrder(PurchaseLine, Item."No.", 7, CalcDate('<+0D>', WorkDate()));

        CreateSalesOrder(SalesLine, Item."No.", 3, CalcDate('<+4D>', WorkDate()));

        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate('<+2D>', WorkDate()), CalcDate('<+16D>', WorkDate()));

        // verify planning worksheet line
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", Item."No.");
        AssertPlanningLine(RequisitionLine, RequisitionLine."Action Message"::New,
          0D, CalcDate('<12D>', WorkDate()),
          0, 7, 1, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OverflowCase1()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
    begin
        Initialize();

        LibraryInventory.CreateItem(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Fixed Reorder Qty.");
        Item."Reorder Point" := 4;
        Item."Reorder Quantity" := 7;
        Item."Overflow Level" := 12;
        Evaluate(Item."Lead Time Calculation", '<2D>');
        Evaluate(Item."Time Bucket", '<8D>');
        Evaluate(Item."Safety Lead Time", '<0D>');
        Item.Modify(true);

        CreatePurchaseOrder(PurchaseLine, Item."No.", 7, CalcDate('<+0D>', WorkDate()));
        CreatePurchaseOrder(PurchaseLine, Item."No.", 3, CalcDate('<+17D>', WorkDate()));

        CreateSalesOrder(SalesLine, Item."No.", 3, CalcDate('<+4D>', WorkDate()));

        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate('<+2D>', WorkDate()), CalcDate('<+18D>', WorkDate()));

        // verify planning worksheet line
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", Item."No.");
        AssertPlanningLine(RequisitionLine, RequisitionLine."Action Message"::New,
          0D, CalcDate('<12D>', WorkDate()),
          0, 7, 1, false);
        AssertPlanningLine(RequisitionLine, RequisitionLine."Action Message"::"Change Qty.",
          0D, PurchaseLine."Expected Receipt Date",
          3, 1, 1, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OverflowCase2()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
    begin
        Initialize();

        LibraryInventory.CreateItem(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Fixed Reorder Qty.");
        Item."Reorder Point" := 4;
        Item."Reorder Quantity" := 7;
        Item."Overflow Level" := 0;
        Evaluate(Item."Lead Time Calculation", '<2D>');
        Evaluate(Item."Time Bucket", '<8D>');
        Evaluate(Item."Safety Lead Time", '<0D>');
        Item.Modify(true);

        CreatePurchaseOrder(PurchaseLine, Item."No.", 7, CalcDate('<+0D>', WorkDate()));
        CreatePurchaseOrder(PurchaseLine, Item."No.", 3, CalcDate('<+17D>', WorkDate()));

        CreateSalesOrder(SalesLine, Item."No.", 3, CalcDate('<+4D>', WorkDate()));

        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate('<+2D>', WorkDate()), CalcDate('<+18D>', WorkDate()));

        // verify planning worksheet line
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", Item."No.");
        AssertPlanningLine(RequisitionLine, RequisitionLine."Action Message"::New,
          0D, CalcDate('<12D>', WorkDate()),
          0, 7, 1, false);
        AssertPlanningLine(RequisitionLine, RequisitionLine."Action Message"::Cancel,
          0D, PurchaseLine."Expected Receipt Date",
          3, 0, 1, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DampenerQtyCase1()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
    begin
        Initialize();

        LibraryInventory.CreateItem(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item."Dampener Quantity" := 4;
        Item.Modify(true);

        CreatePurchaseOrder(PurchaseLine, Item."No.", 7, CalcDate('<+5D>', WorkDate()));

        CreateSalesOrder(SalesLine, Item."No.", 3, CalcDate('<+5D>', WorkDate()));

        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate('<+2D>', WorkDate()), CalcDate('<+16D>', WorkDate()));
        // verify planning worksheet lines
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", Item."No.");
        AssertPlanningLine(RequisitionLine, RequisitionLine."Action Message"::" ",
          0D, 0D,
          0, 0, 0, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DampenerQtyCase2()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
    begin
        Initialize();

        LibraryPlanning.SetDefaultDampenerPercent(10);

        LibraryInventory.CreateItem(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item."Dampener Quantity" := 0;
        Item."Lot Size" := 40;
        Item.Modify(true);

        CreatePurchaseOrder(PurchaseLine, Item."No.", 7, CalcDate('<+5D>', WorkDate()));

        CreateSalesOrder(SalesLine, Item."No.", 3, CalcDate('<+5D>', WorkDate()));

        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate('<+2D>', WorkDate()), CalcDate('<+16D>', WorkDate()));
        // verify planning worksheet lines
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", Item."No.");
        AssertPlanningLine(
          RequisitionLine, RequisitionLine."Action Message"::" ",
          0D, 0D,
          0, 0, 0, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B298909()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        ReschedulingPeriod: DateFormula;
        LotAccumulationPeriod: DateFormula;
        SupplyQuantityValue: array[5] of Decimal;
        SupplyDateValue: array[5] of Date;
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
    begin
        Initialize();
        Evaluate(LotAccumulationPeriod, '<1W>');
        Evaluate(ReschedulingPeriod, '<1M>');

        LibraryInventory.CreateItem(Item);
        Item."Replenishment System" := Item."Replenishment System"::Purchase;
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Validate("Rescheduling Period", ReschedulingPeriod);
        Item.Validate("Lot Accumulation Period", LotAccumulationPeriod);
        Item.Modify(true);

        DemandQuantityValue[1] := 100;
        DemandDateValue[1] := CalcDate(ReschedulingPeriod, WorkDate());
        CreateSalesOrder(SalesLine, Item."No.", DemandQuantityValue[1], DemandDateValue[1]);

        DemandQuantityValue[2] := 100;
        DemandDateValue[2] := CalcDate(ReschedulingPeriod, DemandDateValue[1]);
        CreateSalesOrder(SalesLine, Item."No.", DemandQuantityValue[2], DemandDateValue[2]);

        SupplyQuantityValue[1] := DemandQuantityValue[1] + DemandQuantityValue[2];
        SupplyDateValue[1] := DemandDateValue[1];
        CreatePurchaseOrder(PurchaseLine, Item."No.", SupplyQuantityValue[1], SupplyDateValue[1]);

        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), CalcDate('<365D>', WorkDate()));

        // verify planning worksheet line
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", Item."No.");
        AssertPlanningLine(
          RequisitionLine, RequisitionLine."Action Message"::"Change Qty.",
          0D, SupplyDateValue[1],
          SupplyQuantityValue[1], DemandQuantityValue[1], 1, false);
        AssertPlanningLine(
          RequisitionLine, RequisitionLine."Action Message"::New,
          0D, CalcDate(ReschedulingPeriod, SupplyDateValue[1]),
          0, DemandQuantityValue[2], 1, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoSeriesSetup()
    var
        PurchPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Modify(true);

        PurchPayablesSetup.Get();
        PurchPayablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchPayablesSetup.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RequisitionLineValidateDueDateUpdatesUnitCost()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        RequisitionLine: Record "Requisition Line";
        PriceListLine: Record "Price List Line";
        PurchasePrice: Record "Purchase Price";
        UnitCost: Decimal;
    begin
        // [FEATURE] [Requisition Plan] [Item Purchase Price]
        // [SCENARIO 364400] Chainging "Due Date" in the Requisition Line updates Unit Cost

        // [GIVEN] Item replenished via purchase order
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);

        Item.Validate("Vendor No.", Vendor."No.");
        Item.Validate("Replenishment System", Item."Replenishment System"::Purchase);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Fixed Reorder Qty.");
        Item.Validate("Reorder Quantity", 100);
        Item.Modify(true);

        // [GIVEN] Item Purchase Price: Starting Date = WorkDate() - 1, Ending Date = WorkDate(), Unit Cost = "X"
        UnitCost := LibraryRandom.RandDec(100, 2);
        CreateItemPurchasePrice(Item."No.", Vendor."No.", CalcDate('<-1D>', WorkDate()), WorkDate(), UnitCost);
        // [GIVEN] Item Purchase Price: Starting Date = WorkDate() + 1, Ending Date = WorkDate() + 2, Unit Cost = 2 * "X"
        UnitCost := UnitCost * LibraryRandom.RandIntInRange(2, 5);
        CreateItemPurchasePrice(Item."No.", Vendor."No.", CalcDate('<1D>', WorkDate()), CalcDate('<2D>', WorkDate()), UnitCost);
        CopyFromToPriceListLine.CopyFrom(PurchasePrice, PriceListLine);

        // [GIVEN] Calculate regenerative plan on WORKDATE
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // [WHEN] Update "Due Date" on requisiton line, set new value = WorkDate() + 2
        FindRequisitionLine(RequisitionLine, Item."No.");
        RequisitionLine.SetCurrFieldNo(RequisitionLine.FieldNo("Due Date"));
        RequisitionLine.Validate("Due Date", CalcDate('<2D>', WorkDate()));

        // [THEN] "Direct Unit Cost" on requisition line = 2 * "X"
        Assert.AreEqual(UnitCost, RequisitionLine."Direct Unit Cost", StrSubstNo(WrongFieldValueErr, RequisitionLine.FieldCaption("Direct Unit Cost"), RequisitionLine.TableCaption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NetChangePlanForSKUItemHasNoPlanningParameters()
    var
        Item: Record Item;
        Location: Record Location;
        SKU: Record "Stockkeeping Unit";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Net Change Plan] [Stockkeeping Unit]
        // [SCENARIO 220546] Net change planning should plan a stockkeping unit that has planning parameters configured, and the item is not set up for planning
        Initialize();

        // [GIVEN] Item "I" without planning parameters (Reordering Policy is blank)
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Stockkeeping unit for item "I", "Reordering Policy" = "Lot-for-Lot"
        CreateSKU(SKU, Location.Code, Item."No.", SKU."Reordering Policy"::"Lot-for-Lot");

        // [GIVEN] Calculate net change plan
        // This step is required to deactivate the planning assignment entry. It is created with Inactive = FALSE when a new stockkeping unit is inserted.
        // Planning worksheet will not plan anything, since there is no demand, but it will update "Inactive" to TRUE.
        CalcNetChangePlanForPlanWksh(Item."No.");

        // [GIVEN] Create sales order for "X" pcs item "I" as demand for planning
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(), Item."No.",
          LibraryRandom.RandInt(10), Location.Code, WorkDate());

        // [WHEN] Calculate net change plan
        CalcNetChangePlanForPlanWksh(Item."No.");

        // [THEN] Replenishment of "X" pcs of item "I" is suggested
        FindRequisitionLine(RequisitionLine, Item."No.");
        RequisitionLine.TestField(Quantity, SalesLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NetChangeDoesNotPlanForSKUWithoutPlanningParameters()
    var
        Item: Record Item;
        Location: Record Location;
        SKU: Record "Stockkeeping Unit";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Net Change Plan] [Stockkeeping Unit]
        // [SCENARIO 220546] Net change planning should not plan a stockkeping unit that has no planning parameters configured when the item is set up for planning
        Initialize();

        // [GIVEN] Item "I" with planning parameters ("Reordering Policy" = "Lot-for-Lot")
        LibraryInventory.CreateItem(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Modify(true);

        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Stockkeeping unit for item "I" with blank reordering policy
        CreateSKU(SKU, Location.Code, Item."No.", SKU."Reordering Policy"::" ");

        // [GIVEN] Calculate net change plan
        // This step is required to deactivate the planning assignment entry. It is created with Inactive = FALSE when a new stockkeping unit is inserted.
        // Planning worksheet will not plan anything, since there is no demand, but it will update "Inactive" to TRUE.
        CalcNetChangePlanForPlanWksh(Item."No.");

        // [GIVEN] Create a sales order for "X" pcs of item "I"
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(), Item."No.",
          LibraryRandom.RandInt(10), Location.Code, WorkDate());

        // [WHEN] Calculate net change plan
        CalcNetChangePlanForPlanWksh(Item."No.");

        // [THEN] No replenishment is suggested
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", Item."No.");
        Assert.RecordIsEmpty(RequisitionLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NetChangePlanReplansSalesOrderForSKUUpdatedAfterFirstPlanning()
    var
        Item: Record Item;
        Location: Record Location;
        SKU: Record "Stockkeeping Unit";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Net Change Plan] [Stockkeeping Unit]
        // [SCENARIO 220546] Net change planning should suggest replenishment when demand for the stockkeeping unit is changed after planning

        Initialize();

        // [GIVEN] Item "I" without planning parameters (Reordering Policy is blank)
        LibraryInventory.CreateItem(Item);

        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Stockkeeping unit for item "I", "Reordering Policy" = "Lot-for-Lot"
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(SKU, Location.Code, Item."No.", '');
        SKU.Validate("Reordering Policy", SKU."Reordering Policy"::"Lot-for-Lot");
        SKU.Modify(true);

        // [GIVEN] Create a sales order for "X" pcs item "I" as demand for planning
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        CreateSalesLineOnLocation(SalesLine, SalesHeader, Item."No.", LibraryRandom.RandInt(10), Location.Code);

        // [GIVEN] Calculate net change plan
        CalcNetChangePlanForPlanWksh(Item."No.");

        // [GIVEN] Create another line in the sales order with "Y" pcs of item "I"
        CreateSalesLineOnLocation(SalesLine, SalesHeader, Item."No.", LibraryRandom.RandInt(10), Location.Code);

        // [WHEN] Calculate net change plan
        CalcNetChangePlanForPlanWksh(Item."No.");

        // [THEN] Suggested quantity for replenishment is "X" + "Y"
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", Item."No.");
        RequisitionLine.FindFirst();

        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetRange("No.", Item."No.");
        SalesLine.CalcSums(Quantity);
        RequisitionLine.TestField(Quantity, SalesLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultVendorCopiedFromSKUInRequisitionLine()
    var
        Item: Record Item;
        Location: Record Location;
        StockkeepingUnit: Record "Stockkeeping Unit";
        RequisitionLine: Record "Requisition Line";
        ReqWorksheet: TestPage "Req. Worksheet";
    begin
        // [FEATURE] [Stockkeeping Unit]
        // [SCENARIO] Default vendor no. and vendor item no. should be copied to the requisition line from the stockkeeping unit card if the SKU exists for item and location

        Initialize();

        // [GIVEN] Item "I" with a stockkeeping unit on location "L"
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, Location.Code, Item."No.", '');

        // [GIVEN] "Vendor No." is "X" and "Vendor Item No." is "Y" in the SKU card
        StockkeepingUnit.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        StockkeepingUnit.Validate("Vendor Item No.", LibraryUtility.GenerateGUID());
        StockkeepingUnit.Modify(true);

        // [GIVEN] Manually create a requisition line in the planning worksheet and set "Item No." = "I"
        ReqWorksheet.OpenEdit();
        ReqWorksheet.Type.SetValue(RequisitionLine.Type::Item);
        ReqWorksheet."No.".SetValue(Item."No.");

        // [WHEN] Set "Location Code" = "L" in the requisition line
        ReqWorksheet."Location Code".SetValue(Location.Code);

        // [THEN] "Vendor No." =  "X", "Vendor Item No." = "Y"
        ReqWorksheet."Vendor No.".AssertEquals(StockkeepingUnit."Vendor No.");
        ReqWorksheet."Vendor Item No.".AssertEquals(StockkeepingUnit."Vendor Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorNotResetOnRequisitionLineIfVendorBlankOnSKU()
    var
        Vendor: Record Vendor;
        ItemVendor: Record "Item Vendor";
        Item: Record Item;
        Location: Record Location;
        StockkeepingUnit: Record "Stockkeeping Unit";
        RequisitionLine: Record "Requisition Line";
        ReqWorksheet: TestPage "Req. Worksheet";
    begin
        // [FEATURE] [Stockkeeping Unit]
        // [SCENARIO 232937] Manually set Vendor No. on requisition line is not cleared but validated with its current value, if Vendor No. is blank on stockkeeping unit.
        Initialize();

        // [GIVEN] Item "I" with a stockkeeping unit on location "L". "Vendor No." and "Vendor Item No." are blank on the SKU.
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, Location.Code, Item."No.", '');

        // [GIVEN] Vendor "V".
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Manually create a requisition line in the planning worksheet and set "Item No." = "I", "Vendor No." = "V".
        ReqWorksheet.OpenEdit();
        ReqWorksheet.Type.SetValue(RequisitionLine.Type::Item);
        ReqWorksheet."No.".SetValue(Item."No.");
        ReqWorksheet."Vendor No.".SetValue(Vendor."No.");

        // [GIVEN] Item Vendor for "V" and "I". "Vendor Item No." = "VI".
        LibraryInventory.CreateItemVendor(ItemVendor, Vendor."No.", Item."No.");
        ItemVendor.Validate("Vendor Item No.", LibraryUtility.GenerateGUID());
        ItemVendor.Modify(true);

        // [WHEN] Set "Location Code" = "L" on the requisition line.
        ReqWorksheet."Location Code".SetValue(Location.Code);

        // [THEN] "Vendor No." remains "V" on the requisition line.
        ReqWorksheet."Vendor No.".AssertEquals(Vendor."No.");

        // [THEN] "Vendor Item No." is populated with "VI" on the requisition line.
        ReqWorksheet."Vendor Item No.".AssertEquals(ItemVendor."Vendor Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RequisitionLineStartingEndingDateTimeUpdatedFromRouting()
    var
        RequisitionLine: Record "Requisition Line";
        PlanningRoutingLine: Record "Planning Routing Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        PlanningRoutingManagement: Codeunit PlanningRoutingManagement;
    begin
        // [FEATURE] [UT] [Planning Worksheet]
        // [SCENARIO 257194] Function CalculatePlanningLineDates in codeunit 99000809 "Planning Line Management" updates fields "Starting Date-Time" and "Ending Date-Time" of the requisition line

        LibraryPlanning.SelectRequisitionWkshName(RequisitionWkshName, RequisitionWkshName."Template Type"::Planning);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);

        MockPlanningRoutingLine(PlanningRoutingLine, RequisitionLine);

        PlanningRoutingManagement.CalculatePlanningLineDates(RequisitionLine);

        Assert.AreEqual(
            CreateDateTime(PlanningRoutingLine."Starting Date", PlanningRoutingLine."Starting Time"), RequisitionLine."Starting Date-Time",
            StrSubstNo(WrongFieldValueErr, RequisitionLine.FieldName("Starting Date-Time"), RequisitionLine.TableName()));
        Assert.AreEqual(
            CreateDateTime(PlanningRoutingLine."Ending Date", PlanningRoutingLine."Ending Time"), RequisitionLine."Ending Date-Time",
            StrSubstNo(WrongFieldValueErr, RequisitionLine.FieldName("Starting Date-Time"), RequisitionLine.TableName()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RespectPlanningParamRequisitionPlanWithTransfer()
    var
        Item: Record Item;
        Location: array[2] of Record Location;
        SKU: Record "Stockkeeping Unit";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TransferRoute: Record "Transfer Route";
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Requisition Worksheet]
        // [SCENARIO 259107] Replenishment via transfer should be planned for item on a location with inbound handling time and "Respect Planning Parameters for Supply Triggered Safety Stock"

        Initialize();

        // [GIVEN] Location "A"
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[1]);
        // [GIVEN] Location "B" with 1 day inbound handling time
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[2]);
        Evaluate(Location[2]."Inbound Whse. Handling Time", '<1D>');
        Location[2].Modify(true);
        LibraryInventory.CreateTransferRoute(TransferRoute, Location[1].Code, Location[2].Code);

        // [GIVEN] Item "I" with a stockkeeping unit on the location "B"
        // [GIVEN] Item is configured to be replenished by a transfer from location "A". Reordering policy is "Maximum Qty.", "Maximum Inventory" is "X"
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(SKU, Location[2].Code, Item."No.", '');
        SKU.Validate("Reordering Policy", SKU."Reordering Policy"::"Maximum Qty.");
        SKU.Validate("Reorder Point", LibraryRandom.RandIntInRange(10, 20));
        SKU.Validate("Maximum Inventory", SKU."Reorder Point" * 2);
        SKU.Validate("Replenishment System", SKU."Replenishment System"::Transfer);
        SKU.Validate("Transfer-from Code", Location[1].Code);
        SKU.Modify(true);

        // [GIVEN] Sales order for item "I" on location "B", "Quantity" = "Y"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        CreateSalesLineOnLocation(SalesLine, SalesHeader, Item."No.", LibraryRandom.RandInt(20), Location[2].Code);

        // [WHEN] Calculate requisition plan for item "I" and location "B" with the option "Respect Planning Parameters for Supply Triggered Safety Stock"
        CalculatePlanInRequisitionWorksheet(Item, Location[2].Code, WorkDate(), WorkDate() + 1);

        // [THEN] Quantity planned for replenishment "X" + "Y", transfer is planned on work date
        FindRequisitionLine(RequisitionLine, Item."No.");
        RequisitionLine.TestField(Quantity, SKU."Maximum Inventory" + SalesLine.Quantity);
        RequisitionLine.TestField("Due Date", WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocationCodeNotOverwrittenIfBlankOnVendorWhenValidateVendorNo()
    var
        Item: Record Item;
        Location: Record Location;
        Vendor: Record Vendor;
        RequisitionLine: Record "Requisition Line";
        ReqWorksheet: TestPage "Req. Worksheet";
    begin
        // [FEATURE] [Requisition Worksheet]
        // [SCENARIO 290080] When a Vendor with no default location code is entered on the Requisition Line the Location Code previously entered is not overwritten to blank
        Initialize();

        // [GIVEN] Item
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Location
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Vendor with Location Code empty
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Manually create a requisition line in the planning worksheet and set "Item No." and Location Code
        ReqWorksheet.OpenEdit();
        ReqWorksheet.Type.SetValue(RequisitionLine.Type::Item);
        ReqWorksheet."No.".SetValue(Item."No.");
        ReqWorksheet."Location Code".SetValue(Location.Code);

        // [WHEN] Requisition Line "Vendor No." is validated with Vendor."No."
        ReqWorksheet."Vendor No.".SetValue(Vendor."No.");

        // [THEN] Location Code is not overwritten
        ReqWorksheet."Location Code".AssertEquals(Location.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocationCodeOverwrittenIfNotBlankOnVendorWhenValidateVendorNo()
    var
        Item: Record Item;
        Location: array[2] of Record Location;
        Vendor: Record Vendor;
        RequisitionLine: Record "Requisition Line";
        ReqWorksheet: TestPage "Req. Worksheet";
    begin
        // [FEATURE] [Requisition Worksheet]
        // [SCENARIO 290080] When a Vendor with a default location code is entered on the Requisition Line the Location Code previously entered is overwritten
        Initialize();

        // [GIVEN] Item
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Location "1"
        LibraryWarehouse.CreateLocation(Location[1]);

        // [GIVEN] Vendor with Location Code for Location "2"
        LibraryPurchase.CreateVendor(Vendor);
        LibraryWarehouse.CreateLocation(Location[2]);
        LibraryPurchase.CreateVendorWithLocationCode(Vendor, Location[2].Code);

        // [GIVEN] Manually create a requisition line in the planning worksheet and set "Item No." and Location Code
        ReqWorksheet.OpenEdit();
        ReqWorksheet.Type.SetValue(RequisitionLine.Type::Item);
        ReqWorksheet."No.".SetValue(Item."No.");
        ReqWorksheet."Location Code".SetValue(Location[1].Code);

        // [WHEN] Requisition Line "Vendor No." is validated with Vendor."No."
        ReqWorksheet."Vendor No.".SetValue(Vendor."No.");

        // [THEN] Location Code is set to Vendor Location Code
        ReqWorksheet."Location Code".AssertEquals(Vendor."Location Code");
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Planning Options");

        LibraryApplicationArea.EnableEssentialSetup();

        if Initialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Planning Options");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        NoSeriesSetup();

        Commit();

        Initialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Planning Options");
    end;

    local procedure CalcNetChangePlanForPlanWksh(ItemNo: Code[20])
    var
        Item: Record Item;
    begin
        Item.SetRange("No.", ItemNo);
        LibraryPlanning.CalcNetChangePlanForPlanWksh(Item, WorkDate(), WorkDate(), true);
    end;

    local procedure CalculatePlanInRequisitionWorksheet(var Item: Record Item; LocationCode: Code[10]; PlanningStartDate: Date; PlanningEndDate: Date)
    var
        ReqWkshName: Record "Requisition Wksh. Name";
        InvtProfileOffsetting: Codeunit "Inventory Profile Offsetting";
    begin
        Item.SetRecFilter();
        Item.SetRange("Location Filter", LocationCode);

        LibraryPlanning.SelectRequisitionWkshName(ReqWkshName, ReqWkshName."Template Type"::"Req.");
        InvtProfileOffsetting.SetParm('', 0D, 0);
        InvtProfileOffsetting.CalculatePlanFromWorksheet(
          Item, ReqWkshName."Worksheet Template Name", ReqWkshName.Name, PlanningStartDate, PlanningEndDate, true, true);
    end;

    local procedure CreateSKU(var SKU: Record "Stockkeeping Unit"; LocationCode: Code[10]; ItemNo: Code[20]; ReorderingPolicy: Enum "Reordering Policy")
    begin
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(SKU, LocationCode, ItemNo, '');
        SKU.Validate("Reordering Policy", ReorderingPolicy);
        SKU.Modify(true);
    end;

    local procedure CreateItemPurchasePrice(ItemNo: Code[20]; VendorNo: Code[20]; StartingDate: Date; EndingDate: Date; UnitCost: Decimal)
    var
        PurchPrice: Record "Purchase Price";
    begin
        PurchPrice.Init();
        PurchPrice.Validate("Item No.", ItemNo);
        PurchPrice.Validate("Vendor No.", VendorNo);
        PurchPrice.Validate("Starting Date", StartingDate);
        PurchPrice.Validate("Ending Date", EndingDate);
        PurchPrice.Validate("Direct Unit Cost", UnitCost);
        PurchPrice.Insert(true);
    end;

    local procedure CreatePurchaseOrder(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; Quantity: Decimal; AvailableDate: Date)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Expected Receipt Date", AvailableDate);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesLineOnLocation(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Qty: Decimal; LocationCode: Code[10])
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Qty);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesLine: Record "Sales Line"; ItemNo: Code[20]; Quantity: Decimal; AvailableDate: Date)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Shipment Date", AvailableDate);
        SalesLine.Modify(true);
    end;

    local procedure FindRequisitionLine(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20])
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", ItemNo);
        RequisitionLine.FindFirst();
    end;

    local procedure AssertPlanningLine(var RequisitionLineFiltered: Record "Requisition Line"; ActionMsg: Enum "Action Message Type"; OrigDueDate: Date; DueDate: Date; OrigQty: Decimal; Quantity: Decimal; NoOfLines: Integer; NoLinesExpected: Boolean)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.CopyFilters(RequisitionLineFiltered);
        if not NoLinesExpected then begin
            RequisitionLine.SetRange("Action Message", ActionMsg);
            RequisitionLine.SetRange("Original Due Date", OrigDueDate);
            RequisitionLine.SetRange("Due Date", DueDate);
            RequisitionLine.SetRange("Original Quantity", OrigQty);
            RequisitionLine.SetRange(Quantity, Quantity);
        end;
        Assert.AreEqual(NoOfLines, RequisitionLine.Count, 'Asserting that the no. of lines match');
    end;

    local procedure MockPlanningRoutingLine(var PlanningRoutingLine: Record "Planning Routing Line"; RequisitionLine: Record "Requisition Line")
    begin
        PlanningRoutingLine.Init();
        PlanningRoutingLine."Worksheet Template Name" := RequisitionLine."Worksheet Template Name";
        PlanningRoutingLine."Worksheet Batch Name" := RequisitionLine."Journal Batch Name";
        PlanningRoutingLine."Worksheet Line No." := RequisitionLine."Line No.";
        PlanningRoutingLine."Operation No." := LibraryUtility.GenerateRandomCode(PlanningRoutingLine.FieldNo("Operation No."), DATABASE::"Planning Routing Line");
        PlanningRoutingLine."Starting Date" := LibraryRandom.RandDateFromInRange(WorkDate(), 1, 10);
        PlanningRoutingLine."Starting Time" := 100000T + LibraryRandom.RandInt(100000);
        PlanningRoutingLine."Ending Date" := LibraryRandom.RandDateFromInRange(WorkDate(), 15, 20);
        PlanningRoutingLine."Ending Time" := 110000T + LibraryRandom.RandInt(100000);
        PlanningRoutingLine.Insert();
    end;
}

