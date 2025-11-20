codeunit 134084 "Item Avail. by Lot No Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibrarySales: Codeunit "Library - Sales";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        DayDateFormulaTxt: Label '<%1D>', Locked = false, Comment = '%1 = no. of days';

    [Test]
    [Scope('OnPrem')]
    procedure ShouldClearVariantFilterWhenItemChanges()
    var
        ItemA: Record Item;
        ItemB: Record Item;
        ItemVariant: Record "Item Variant";
        AvailabilityTestPage: TestPage "Item Availability by Lot No.";
    begin
        // [SCENARIO] The variant filter should be cleared on item change as it is dependent on the current item.
        Initialize();

        // [GIVEN] Item A & B. Item A has a variant.
        CreateItem(ItemA);
        CreateVariant(ItemA, ItemVariant);
        CreateItem(ItemB);

        // [GIVEN] Item A as current item and variant filter set.
        AvailabilityTestPage.OpenView();
        AvailabilityTestPage.GoToRecord(ItemA);
        AvailabilityTestPage.VariantFilter.SetValue(ItemVariant.Code);
        Assert.AreEqual(ItemVariant.Code, AvailabilityTestPage.VariantFilter.Value, 'Expected variant filter to be set.');

        // [WHEN] Changing current item to item B.
        AvailabilityTestPage.GoToRecord(ItemB);

        // [THEN] The variant filter is cleared.
        Assert.AreEqual('', AvailabilityTestPage.VariantFilter.Value, 'Expected variant filter to be cleared.');

        AvailabilityTestPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShouldOnlyIncludeEntriesWithALotNo()
    var
        Item: Record Item;
        AvailabilityTestPage: TestPage "Item Availability by Lot No.";
    begin
        // [SCENARIO] We are only interested in displaying information about lots. 
        // Therefore we should only get data from ILE and Reservation entries having a lot assigned.
        Initialize();

        CreateItem(Item);

        // [GIVEN] Two posted purchase orders. One with lot no. (qty = 3) and one without lot no (qty = 1).
        CreatePurchaseOrder(Item, 'LOT1', '', '', 3, true);
        CreatePurchaseOrder(Item, '', '', '', 1, true);

        // [GIVEN] Two unposted purchase orders. One with lot no. (qty = 4) and one without lot no (qty = 1).
        CreatePurchaseOrder(Item, 'LOT1', '', '', 4, false);
        CreatePurchaseOrder(Item, '', '', '', 1, false);

        // [GIVEN] Two unposted sales orders. One with lot no. (qty = 2) and one without lot no (qty = 1).
        CreateSalesOrder(Item, 'LOT1', '', '', 2, false);
        CreateSalesOrder(Item, '', '', '', 1, false);

        // [GIVEN] Two planned production orders. One with lot no. (qty = 6) and one without lot no (qty = 5).
        CreatePlannedProductionOrder(Item, 'LOT1', '', '', 6);
        CreatePlannedProductionOrder(Item, '', '', '', 5);

        // [WHEN] Opening page for item with amount type of balance at date and current date set one week ahead.
        AvailabilityTestPage.OpenView();
        AvailabilityTestPage.GoToRecord(Item);
        AvailabilityTestPage.PeriodType.SetValue("Analysis Period Type"::Week);
        AvailabilityTestPage.AmountType.SetValue("Analysis Amount Type"::"Balance at Date");
        AvailabilityTestPage.NextPeriod.Invoke();

        // [THEN] Only one entry is shown containing the specified lot and correct quantities.
        Assert.AreEqual(Format(AvailabilityTestPage.ItemAvailLoTNoLines.LotNo), 'LOT1', 'Expected lot to be shown.');
        Assert.AreEqual(3, AvailabilityTestPage.ItemAvailLoTNoLines.Inventory.AsInteger(), 'Expected inventory of 3.');
        Assert.AreEqual(4, AvailabilityTestPage.ItemAvailLoTNoLines.ScheduledRcpt.AsInteger(), 'Expected scheduled receipt of 4.');
        Assert.AreEqual(2, AvailabilityTestPage.ItemAvailLoTNoLines.GrossRequirement.AsInteger(), 'Expected gross requirement of 2.');
        Assert.AreEqual(6, AvailabilityTestPage.ItemAvailLoTNoLines.PlannedOrderRcpt.AsInteger(), 'Expected planned order receipt of 6.');
        Assert.AreEqual(11, AvailabilityTestPage.ItemAvailLoTNoLines.QtyAvailable.AsInteger(), 'Expected available inventory of 11.');
        Assert.IsFalse(AvailabilityTestPage.ItemAvailLoTNoLines.Next(), 'Expected only one entry.');

        AvailabilityTestPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocationFilterOnEntries()
    var
        Item: Record Item;
        LocationA: Record Location;
        LocationB: Record Location;
        AvailabilityTestPage: TestPage "Item Availability by Lot No.";
    begin
        // [SCENARIO] Item ledger entries should be filtered by location when location filter is applied.
        Initialize();

        CreateItem(Item);

        // [GIVEN] Two locations A and B.
        CreateLocation(LocationA);
        CreateLocation(LocationB);

        // [GIVEN] Two posted purchase orders. One with location A (qty = 1) and one with location B (qty = 3).
        CreatePurchaseOrder(Item, 'LOT1', LocationA.Code, '', 1, true);
        CreatePurchaseOrder(Item, 'LOT1', LocationB.Code, '', 3, true);

        // [GIVEN] Two unposted purchase orders. One with location A (qty = 4) and one with location B (qty = 2).
        CreatePurchaseOrder(Item, 'LOT1', LocationA.Code, '', 4, false);
        CreatePurchaseOrder(Item, 'LOT1', LocationB.Code, '', 2, false);

        // [GIVEN] Two unposted sales orders. One with location A (qty = 2) and one with location B (qty = 1).
        CreateSalesOrder(Item, 'LOT1', LocationA.Code, '', 2, false);
        CreateSalesOrder(Item, 'LOT1', LocationB.Code, '', 1, false);

        // [GIVEN] Two planned production orders. One with location A (qty = 6) and one with location B (qty = 5).
        CreatePlannedProductionOrder(Item, 'LOT1', LocationA.Code, '', 6);
        CreatePlannedProductionOrder(Item, 'LOT1', LocationB.Code, '', 5);

        // [WHEN] Opening page for item with amount type of balance at date and current date set one week ahead.
        AvailabilityTestPage.OpenView();
        AvailabilityTestPage.GoToRecord(Item);
        AvailabilityTestPage.PeriodType.SetValue("Analysis Period Type"::Week);
        AvailabilityTestPage.AmountType.SetValue("Analysis Amount Type"::"Balance at Date");
        AvailabilityTestPage.NextPeriod.Invoke();

        // [THEN] Quantities should show for both location A and B.
        Assert.AreEqual(4, AvailabilityTestPage.ItemAvailLoTNoLines.Inventory.AsInteger(), 'Expected inventory of 4.');
        Assert.AreEqual(6, AvailabilityTestPage.ItemAvailLoTNoLines.ScheduledRcpt.AsInteger(), 'Expected scheduled receipt of 6.');
        Assert.AreEqual(3, AvailabilityTestPage.ItemAvailLoTNoLines.GrossRequirement.AsInteger(), 'Expected gross requirement of 3.');
        Assert.AreEqual(11, AvailabilityTestPage.ItemAvailLoTNoLines.PlannedOrderRcpt.AsInteger(), 'Expected planned order receipt of 11.');
        Assert.AreEqual(18, AvailabilityTestPage.ItemAvailLoTNoLines.QtyAvailable.AsInteger(), 'Expected available inventory of 18.');

        // [WHEN] Setting location filter for location A.
        AvailabilityTestPage.LocationFilter.SetValue(LocationA.Code);

        // [THEN] Quantities should show only for location A.
        Assert.AreEqual(1, AvailabilityTestPage.ItemAvailLoTNoLines.Inventory.AsInteger(), 'Expected inventory of 1.');
        Assert.AreEqual(4, AvailabilityTestPage.ItemAvailLoTNoLines.ScheduledRcpt.AsInteger(), 'Expected scheduled receipt of 4.');
        Assert.AreEqual(2, AvailabilityTestPage.ItemAvailLoTNoLines.GrossRequirement.AsInteger(), 'Expected gross requirement of 2.');
        Assert.AreEqual(6, AvailabilityTestPage.ItemAvailLoTNoLines.PlannedOrderRcpt.AsInteger(), 'Expected planned order receipt of 6.');
        Assert.AreEqual(9, AvailabilityTestPage.ItemAvailLoTNoLines.QtyAvailable.AsInteger(), 'Expected available inventory of 9.');

        // [WHEN] Setting location filter for location B.
        AvailabilityTestPage.LocationFilter.SetValue(LocationB.Code);

        // [THEN] Quantities should show only for location B.
        Assert.AreEqual(3, AvailabilityTestPage.ItemAvailLoTNoLines.Inventory.AsInteger(), 'Expected inventory of 3.');
        Assert.AreEqual(2, AvailabilityTestPage.ItemAvailLoTNoLines.ScheduledRcpt.AsInteger(), 'Expected scheduled receipt of 2.');
        Assert.AreEqual(1, AvailabilityTestPage.ItemAvailLoTNoLines.GrossRequirement.AsInteger(), 'Expected gross requirement of 1.');
        Assert.AreEqual(5, AvailabilityTestPage.ItemAvailLoTNoLines.PlannedOrderRcpt.AsInteger(), 'Expected planned order receipt of 5.');
        Assert.AreEqual(9, AvailabilityTestPage.ItemAvailLoTNoLines.QtyAvailable.AsInteger(), 'Expected available inventory of 9.');

        // [WHEN] Clearing location filter.
        AvailabilityTestPage.LocationFilter.SetValue('');

        // [THEN] Quantities should show for both location A and B.
        Assert.AreEqual(4, AvailabilityTestPage.ItemAvailLoTNoLines.Inventory.AsInteger(), 'Expected inventory of 4.');
        Assert.AreEqual(6, AvailabilityTestPage.ItemAvailLoTNoLines.ScheduledRcpt.AsInteger(), 'Expected scheduled receipt of 6.');
        Assert.AreEqual(3, AvailabilityTestPage.ItemAvailLoTNoLines.GrossRequirement.AsInteger(), 'Expected gross requirement of 3.');
        Assert.AreEqual(11, AvailabilityTestPage.ItemAvailLoTNoLines.PlannedOrderRcpt.AsInteger(), 'Expected planned order receipt of 11.');
        Assert.AreEqual(18, AvailabilityTestPage.ItemAvailLoTNoLines.QtyAvailable.AsInteger(), 'Expected available inventory of 18.');

        AvailabilityTestPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VariantFilterOnEntries()
    var
        Item: Record Item;
        ItemVariantA: Record "Item Variant";
        ItemVariantB: Record "Item Variant";
        AvailabilityTestPage: TestPage "Item Availability by Lot No.";
    begin
        // [SCENARIO] Item ledger entries should be filtered by variant when variant filter is applied.
        Initialize();

        CreateItem(Item);

        // [GIVEN] Two variants A and B.
        CreateVariant(Item, ItemVariantA);
        CreateVariant(Item, ItemVariantB);

        // [GIVEN] Two posted purchase orders. One with variant A (qty = 1) and one with variant B (qty = 3).
        CreatePurchaseOrder(Item, 'LOT1', '', ItemVariantA.Code, 1, true);
        CreatePurchaseOrder(Item, 'LOT1', '', ItemVariantB.Code, 3, true);

        // [GIVEN] Two unposted purchase orders. One with variant A (qty = 4) and one with variant B (qty = 2).
        CreatePurchaseOrder(Item, 'LOT1', '', ItemVariantA.Code, 4, false);
        CreatePurchaseOrder(Item, 'LOT1', '', ItemVariantB.Code, 2, false);

        // [GIVEN] Two unposted sales orders. One with variant A (qty = 2) and one with variant B (qty = 1).
        CreateSalesOrder(Item, 'LOT1', '', ItemVariantA.Code, 2, false);
        CreateSalesOrder(Item, 'LOT1', '', ItemVariantB.Code, 1, false);

        // [GIVEN] Two planned production orders. One with variant A (qty = 6) and one with variant B (qty = 5).
        CreatePlannedProductionOrder(Item, 'LOT1', '', ItemVariantA.Code, 6);
        CreatePlannedProductionOrder(Item, 'LOT1', '', ItemVariantB.Code, 5);

        // [WHEN] Opening page for item with amount type of balance at date and current date set one week ahead.
        AvailabilityTestPage.OpenView();
        AvailabilityTestPage.GoToRecord(Item);
        AvailabilityTestPage.PeriodType.SetValue("Analysis Period Type"::Week);
        AvailabilityTestPage.AmountType.SetValue("Analysis Amount Type"::"Balance at Date");
        AvailabilityTestPage.NextPeriod.Invoke();

        // [THEN] Quantities should show for both variant A and B.
        Assert.AreEqual(4, AvailabilityTestPage.ItemAvailLoTNoLines.Inventory.AsInteger(), 'Expected inventory of 4.');
        Assert.AreEqual(6, AvailabilityTestPage.ItemAvailLoTNoLines.ScheduledRcpt.AsInteger(), 'Expected scheduled receipt of 6.');
        Assert.AreEqual(3, AvailabilityTestPage.ItemAvailLoTNoLines.GrossRequirement.AsInteger(), 'Expected gross requirement of 3.');
        Assert.AreEqual(11, AvailabilityTestPage.ItemAvailLoTNoLines.PlannedOrderRcpt.AsInteger(), 'Expected planned order receipt of 11.');
        Assert.AreEqual(18, AvailabilityTestPage.ItemAvailLoTNoLines.QtyAvailable.AsInteger(), 'Expected available inventory of 18.');

        // [WHEN] Setting variant filter for variant A.
        AvailabilityTestPage.VariantFilter.SetValue(ItemVariantA.Code);

        // [THEN] Quantities should show only for variant A.
        Assert.AreEqual(1, AvailabilityTestPage.ItemAvailLoTNoLines.Inventory.AsInteger(), 'Expected inventory of 1.');
        Assert.AreEqual(4, AvailabilityTestPage.ItemAvailLoTNoLines.ScheduledRcpt.AsInteger(), 'Expected scheduled receipt of 4.');
        Assert.AreEqual(2, AvailabilityTestPage.ItemAvailLoTNoLines.GrossRequirement.AsInteger(), 'Expected gross requirement of 2.');
        Assert.AreEqual(6, AvailabilityTestPage.ItemAvailLoTNoLines.PlannedOrderRcpt.AsInteger(), 'Expected planned order receipt of 6.');
        Assert.AreEqual(9, AvailabilityTestPage.ItemAvailLoTNoLines.QtyAvailable.AsInteger(), 'Expected available inventory of 9.');

        // [WHEN] Setting variant filter for variant B.
        AvailabilityTestPage.VariantFilter.SetValue(ItemVariantB.Code);

        // [THEN] Quantities should show only for variant B.
        Assert.AreEqual(3, AvailabilityTestPage.ItemAvailLoTNoLines.Inventory.AsInteger(), 'Expected inventory of 3.');
        Assert.AreEqual(2, AvailabilityTestPage.ItemAvailLoTNoLines.ScheduledRcpt.AsInteger(), 'Expected scheduled receipt of 2.');
        Assert.AreEqual(1, AvailabilityTestPage.ItemAvailLoTNoLines.GrossRequirement.AsInteger(), 'Expected gross requirement of 1.');
        Assert.AreEqual(5, AvailabilityTestPage.ItemAvailLoTNoLines.PlannedOrderRcpt.AsInteger(), 'Expected planned order receipt of 5.');
        Assert.AreEqual(9, AvailabilityTestPage.ItemAvailLoTNoLines.QtyAvailable.AsInteger(), 'Expected available inventory of 9.');

        // [WHEN] Clearing variant filter.
        AvailabilityTestPage.VariantFilter.SetValue('');

        // [THEN] Quantities should show for both variant A and B.
        Assert.AreEqual(4, AvailabilityTestPage.ItemAvailLoTNoLines.Inventory.AsInteger(), 'Expected inventory of 4.');
        Assert.AreEqual(6, AvailabilityTestPage.ItemAvailLoTNoLines.ScheduledRcpt.AsInteger(), 'Expected scheduled receipt of 6.');
        Assert.AreEqual(3, AvailabilityTestPage.ItemAvailLoTNoLines.GrossRequirement.AsInteger(), 'Expected gross requirement of 3.');
        Assert.AreEqual(11, AvailabilityTestPage.ItemAvailLoTNoLines.PlannedOrderRcpt.AsInteger(), 'Expected planned order receipt of 11.');
        Assert.AreEqual(18, AvailabilityTestPage.ItemAvailLoTNoLines.QtyAvailable.AsInteger(), 'Expected available inventory of 18.');

        AvailabilityTestPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DateFilterOnEntries()
    var
        Item: Record Item;
        AvailabilityTestPage: TestPage "Item Availability by Lot No.";
        PeriodPageManagement: Codeunit PeriodPageManagement;
        CalendarDate: Record Date;
        OriginalWorkDate: Date;
    begin
        // [SCENARIO] Item ledger entries should be filtered by variant when variant filter is applied.
        Initialize();

        // Set work date to start of week to easen the setup of weekly data.
        PeriodPageManagement.FindDate('', CalendarDate, "Analysis Period Type"::Week);
        WorkDate(CalendarDate."Period Start");

        CreateItem(Item);
        OriginalWorkDate := WorkDate();

        // [GIVEN] Posted purchase order (qty = 1, WorkDate()).
        CreatePurchaseOrder(Item, 'LOT1', '', '', 1, true);

        // [GIVEN] Unposted purchase order (qty = 1, WorkDate()).
        CreatePurchaseOrder(Item, 'LOT1', '', '', 1, false);

        // [GIVEN] Unposted sales order (qty = 1, WorkDate()).
        CreateSalesOrder(Item, 'LOT1', '', '', 1, false);

        // [GIVEN] Planned production order (qty = 1, WorkDate()).
        CreatePlannedProductionOrder(Item, 'LOT1', '', '', 1);

        WorkDate(AddDays(OriginalWorkDate, -7));

        // [GIVEN] Posted purchase order (qty = 2, -7 days from workdate).
        CreatePurchaseOrder(Item, 'LOT1', '', '', 2, true);

        // [GIVEN] Unposted purchase order (qty = 2, -7 days from workdate).
        CreatePurchaseOrder(Item, 'LOT1', '', '', 2, false);

        // [GIVEN] Unposted sales order (qty = 2, -7 days from workdate).
        CreateSalesOrder(Item, 'LOT1', '', '', 2, false);

        // [GIVEN] Planned production order (qty = 2, -7 days from workdate).
        CreatePlannedProductionOrder(Item, 'LOT1', '', '', 2);

        WorkDate(AddDays(OriginalWorkDate, 7));

        // [GIVEN] Posted purchase order (qty = 4, +7 days from workdate).
        CreatePurchaseOrder(Item, 'LOT1', '', '', 4, true);

        // [GIVEN] Unposted purchase order (qty = 4, +7 days from workdate).
        CreatePurchaseOrder(Item, 'LOT1', '', '', 4, false);

        // [GIVEN] Unposted sales order (qty = 4, +7 days from workdate).
        CreateSalesOrder(Item, 'LOT1', '', '', 4, false);

        // [GIVEN] Planned production order (qty = 4, +7 days from workdate).
        CreatePlannedProductionOrder(Item, 'LOT1', '', '', 4);
        WorkDate(OriginalWorkDate);

        // [WHEN] Opening page for item with amount type of net change and current date set to current week.
        AvailabilityTestPage.OpenView();
        AvailabilityTestPage.GoToRecord(Item);
        AvailabilityTestPage.PeriodType.SetValue("Analysis Period Type"::Day);
        AvailabilityTestPage.DateFilter.SetValue(WorkDate());
        AvailabilityTestPage.PeriodType.SetValue("Analysis Period Type"::Week);
        AvailabilityTestPage.AmountType.SetValue("Analysis Amount Type"::"Net Change");

        // [THEN] Quantities should only show for current week (except for posted PO as ILE are not filtered).
        Assert.AreEqual(7, AvailabilityTestPage.ItemAvailLoTNoLines.Inventory.AsInteger(), 'Expected inventory of 7.');
        Assert.AreEqual(1, AvailabilityTestPage.ItemAvailLoTNoLines.ScheduledRcpt.AsInteger(), 'Expected scheduled receipt of 1.');
        Assert.AreEqual(1, AvailabilityTestPage.ItemAvailLoTNoLines.GrossRequirement.AsInteger(), 'Expected gross requirement of 1.');
        Assert.AreEqual(1, AvailabilityTestPage.ItemAvailLoTNoLines.PlannedOrderRcpt.AsInteger(), 'Expected planned order receipt of 1.');
        Assert.AreEqual(8, AvailabilityTestPage.ItemAvailLoTNoLines.QtyAvailable.AsInteger(), 'Expected available inventory of 8.');

        // [WHEN] Showing week period net change from last week.
        AvailabilityTestPage.PreviousPeriod.Invoke();

        // [THEN] Quantities should only show for last week (except for posted PO as ILE are not filtered).
        Assert.AreEqual(7, AvailabilityTestPage.ItemAvailLoTNoLines.Inventory.AsInteger(), 'Expected inventory of 7.');
        Assert.AreEqual(2, AvailabilityTestPage.ItemAvailLoTNoLines.ScheduledRcpt.AsInteger(), 'Expected scheduled receipt of 2.');
        Assert.AreEqual(2, AvailabilityTestPage.ItemAvailLoTNoLines.GrossRequirement.AsInteger(), 'Expected gross requirement of 2.');
        Assert.AreEqual(2, AvailabilityTestPage.ItemAvailLoTNoLines.PlannedOrderRcpt.AsInteger(), 'Expected planned order receipt of 2.');
        Assert.AreEqual(9, AvailabilityTestPage.ItemAvailLoTNoLines.QtyAvailable.AsInteger(), 'Expected available inventory of 9.');

        // [WHEN] Showing week period net change for next week.
        AvailabilityTestPage.NextPeriod.Invoke();
        AvailabilityTestPage.NextPeriod.Invoke();

        // [THEN] Quantities should only show for next week (except for posted PO as ILE are not filtered).
        Assert.AreEqual(7, AvailabilityTestPage.ItemAvailLoTNoLines.Inventory.AsInteger(), 'Expected inventory of 7.');
        Assert.AreEqual(4, AvailabilityTestPage.ItemAvailLoTNoLines.ScheduledRcpt.AsInteger(), 'Expected scheduled receipt of 4.');
        Assert.AreEqual(4, AvailabilityTestPage.ItemAvailLoTNoLines.GrossRequirement.AsInteger(), 'Expected gross requirement of 4.');
        Assert.AreEqual(4, AvailabilityTestPage.ItemAvailLoTNoLines.PlannedOrderRcpt.AsInteger(), 'Expected planned order receipt of 4.');
        Assert.AreEqual(11, AvailabilityTestPage.ItemAvailLoTNoLines.QtyAvailable.AsInteger(), 'Expected available inventory of 11.');

        // [WHEN] Showing balance at date for this week.
        AvailabilityTestPage.PreviousPeriod.Invoke();
        AvailabilityTestPage.AmountType.SetValue("Analysis Amount Type"::"Balance at Date");

        // [THEN] Quantities should only show for up to and including current week (except for posted PO as ILE are not filtered).
        Assert.AreEqual(7, AvailabilityTestPage.ItemAvailLoTNoLines.Inventory.AsInteger(), 'Expected inventory of 7.');
        Assert.AreEqual(3, AvailabilityTestPage.ItemAvailLoTNoLines.ScheduledRcpt.AsInteger(), 'Expected scheduled receipt of 3.');
        Assert.AreEqual(3, AvailabilityTestPage.ItemAvailLoTNoLines.GrossRequirement.AsInteger(), 'Expected gross requirement of 3.');
        Assert.AreEqual(3, AvailabilityTestPage.ItemAvailLoTNoLines.PlannedOrderRcpt.AsInteger(), 'Expected planned order receipt of 3.');
        Assert.AreEqual(10, AvailabilityTestPage.ItemAvailLoTNoLines.QtyAvailable.AsInteger(), 'Expected available inventory of 10.');

        AvailabilityTestPage.Close();
    end;

    [Test]
    procedure ExpirationDateOnItemAvailByLotPage()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemAvailabilityByLotNo: TestPage "Item Availability by Lot No.";
        LotNo: Code[50];
    begin
        // [SCENARIO 426457] Expiration Date is displayed for lot no. that is present in item tracking for sales line.
        Initialize();
        LotNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Lot-tracked item with expiration date.
        LibraryItemTracking.CreateItemTrackingCodeWithExpirationDate(ItemTrackingCode, false, true);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);

        // [GIVEN] Post item journal line, assign lot no. "L", expiration date = WorkDate.
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', LibraryRandom.RandIntInRange(11, 20));
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJournalLine, '', LotNo, ItemJournalLine."Quantity (Base)");
        ReservationEntry.Validate("Expiration Date", WorkDate());
        ReservationEntry.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create sales order for item "L", select lot no. "L".
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", LibraryRandom.RandInt(10), '', WorkDate());
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine, '', LotNo, Salesline."Quantity (Base)");

        // [WHEN] Open "Item Availability by Lot No." page.
        ItemAvailabilityByLotNo.OpenView();
        ItemAvailabilityByLotNo.GoToRecord(Item);

        // [THEN] Expiration date = WorkDate.
        ItemAvailabilityByLotNo.ItemAvailLoTNoLines.ExpirationDate.AssertEquals(WorkDate());
    end;

    [Test]
    [HandlerFunctions('ItemAvailabilitybyLotNoPageHandler')]
    procedure InItemReclassJnlItemAvailabilityByLotDisplaySelectedLineItem()
    var
        Item: array[5] of Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemReclassJournal: TestPage "Item Reclass. Journal";
        i: Integer;
    begin
        // [SCENARIO 560479] The item that is populated in Item Availability By Lot No. should be the one selected from the Item Reclassification Journal.
        Initialize();

        // [GIVEN] Create Item Journal Template and Item Journal Batch.
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Transfer);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);

        // [GIVEN] Create Item Reclass Journal with multiple item lines.
        for i := 1 to LibraryRandom.RandIntInRange(3, 5) do begin
            CreateItem(Item[i]);
            LibraryInventory.CreateItemJnlLineWithNoItem(
              ItemJournalLine, ItemJournalBatch, ItemJournalTemplate.Name, ItemJournalBatch.Name, "Item Ledger Entry Type"::Transfer);
            ItemJournalline.Validate("Item No.", Item[i]."No.");
            ItemJournalLine.Modify(true);
        end;

        // [WHEN] In Item Reclass Jnl Select the Second created Item Line.
        ItemReclassJournal.OpenEdit();
        ItemReclassJournal.Filter.SetFilter("Journal Template Name", ItemJournalTemplate.Name);
        ItemReclassJournal.Filter.SetFilter("Journal Batch Name", ItemJournalBatch.Name);
        ItemReclassJournal.Next();
        LibraryVariableStorage.Enqueue(Item[2]."No.");

        // [THEN] Verify that the 'Item Availability by Lot No.' page has a filter for the selected Item Journal Line's Item No.
        ItemReclassJournal.Lot.Invoke();
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
    end;

    local procedure CreatePurchaseOrder(
        Item: Record Item;
        LotNo: Code[10];
        Location: Code[10];
        VariantCode: Code[10];
        Qty: Decimal;
        Post: Boolean
    )
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        if Location <> '' then
            LibraryPurchase.CreatePurchaseOrderWithLocation(PurchaseHeader, '', Location)
        else
            LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);

        LibraryPurchase.CreatePurchaseLineWithUnitCost(
            PurchaseLine,
            PurchaseHeader,
            Item."No.",
            1,
            Qty
        );
        if VariantCode <> '' then begin
            PurchaseLine.Validate("Variant Code", VariantCode);
            PurchaseLine.Modify();
        end;

        if LotNo <> '' then
            LibraryItemTracking.CreatePurchOrderItemTracking(
                ReservationEntry,
                PurchaseLine,
                '',
                LotNo,
                PurchaseLine."Quantity (Base)"
            );

        if Post then
            LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure CreateSalesOrder(
        Item: Record Item;
        LotNo: Code[10];
        Location: Code[10];
        VariantCode: Code[10];
        Qty: Decimal;
        Post: Boolean
    )
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        if Location <> '' then
            LibrarySales.CreateSalesOrderWithLocation(SalesHeader, '', Location)
        else
            LibrarySales.CreateSalesOrder(SalesHeader);

        LibrarySales.CreateSalesLineWithUnitPrice(
            SalesLine,
            SalesHeader,
            Item."No.",
            1,
            Qty
        );

        if VariantCode <> '' then begin
            SalesLine.Validate("Variant Code", VariantCode);
            SalesLine.Modify();
        end;

        if LotNo <> '' then
            LibraryItemTracking.CreateSalesOrderItemTracking(
                ReservationEntry,
                SalesLine,
                '',
                LotNo,
                SalesLine."Quantity (Base)"
            );

        if Post then
            LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure CreatePlannedProductionOrder(
        Item: Record Item;
        LotNo: Code[10];
        Location: Code[10];
        VariantCode: Code[10];
        Qty: Decimal
    )
    var
        ProductionItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        LibraryInventory.CreateItem(ProductionItem);
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder,
            ProductionOrder.Status::Planned,
            ProductionOrder."Source Type"::Item,
            ProductionItem."No.",
            1
        );
        LibraryManufacturing.CreateProdOrderLine(
            ProdOrderLine,
            ProdOrderLine.Status::Planned,
            ProductionOrder."No.",
            Item."No.",
            VariantCode,
            Location,
            Qty
        );

        if LotNo <> '' then
            LibraryManufacturing.CreateProdOrderItemTracking(
                ReservationEntry,
                ProdOrderLine,
                '',
                LotNo,
                ProdOrderLine."Quantity (Base)"
            );
    end;

    local procedure CreateLocation(var Location: Record Location)
    begin
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);
    end;

    local procedure CreateVariant(var Item: Record Item; var ItemVariant: Record "Item Variant")
    begin
        LibraryInventory.CreateVariant(ItemVariant, Item);
    end;

    local procedure AddDays(ToDate: Date; NumberOfDays: Integer): Date
    begin
        exit(CalcDate(StrSubstNo(DayDateFormulaTxt, NumberOfDays), ToDate));
    end;

    local procedure Initialize()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Item Avail. by Lot No Tests");

        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
    end;

    [PageHandler]
    procedure ItemAvailabilitybyLotNoPageHandler(var ItemAvailabilitybyLotNoTestPage: TestPage "Item Availability by Lot No.")
    var
        ItemNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ItemNo);
        ItemAvailabilitybyLotNoTestPage.ItemFilter.AssertEquals(ItemNo);
    end;
}