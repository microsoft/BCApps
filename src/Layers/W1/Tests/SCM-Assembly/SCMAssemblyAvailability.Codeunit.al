// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Test;

using Microsoft.Inventory.Ledger;
using System.Environment.Configuration;
using Microsoft.Assembly.Document;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Availability;
using Microsoft.Sales.Document;
using Microsoft.Purchases.Document;
using Microsoft.Inventory.Setup;
using Microsoft.Foundation.NoSeries;

codeunit 137906 "SCM Assembly Availability"
{
    Permissions = TableData "Item Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Assembly] [SCM]
        WorkDate2 := LibraryPlanning.SetSafetyWorkDate();
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryKitting: Codeunit "Library - Kitting";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        DummyAssemblyOrderTestPage: TestPage "Assembly Order";
        LastEntryNo: Integer;
        WorkDate2: Date;
        MSG_IS_BEFORE_WORKDATE: Label 'is before work date';
        Initialized: Boolean;

    [Normal]
    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Assembly Availability");
        if Initialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Assembly Availability");

        Initialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Assembly Availability");
    end;

    [Test]
    [HandlerFunctions('IsBeforeWorkDateMsgHandler')]
    [Scope('OnPrem')]
    procedure BUG231289Availabilitydateblank()
    var
        AssemblyHeader: Record "Assembly Header";
        BOMComp: Record "BOM Component";
        parentItem: Record Item;
        childItem: Record Item;
        childItem2: Record Item;
        QTYParent: Decimal;
        QTYChild: Decimal;
        ExpectedDate: Date;
    begin
        Initialize();
        LibraryKitting.SetLookahead('<1Y>');
        QTYParent := 2;
        QTYChild := 1;
        parentItem.Get(LibraryKitting.CreateItemWithLotAndNewUOMUsingItemNo('Parent', 500, 700, 1));
        childItem.Get(LibraryKitting.CreateItemWithNewUOMUsingItemNo('Child1', 500, 700));
        childItem2.Get(LibraryKitting.CreateItemWithNewUOMUsingItemNo('Child2', 500, 700));

        LibraryInventory.CreateBOMComponent(
          BOMComp, parentItem."No.", BOMComp.Type::Item, childItem."No.", QTYChild, childItem."Base Unit of Measure");
        LibraryInventory.CreateBOMComponent(
          BOMComp, parentItem."No.", BOMComp.Type::Item, childItem2."No.", QTYChild, childItem2."Base Unit of Measure");

        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order,
          LibraryKitting.CreateOrderNo(DMY2Date(1, 2, 2010), 'testAvailField', parentItem."No.", QTYParent));
        AssemblyHeader.Validate("Due Date", DMY2Date(1, 2, 2010));

        MockItemLedgerEntry(childItem."No.", 2, AssemblyHeader."Location Code", DMY2Date(1, 1, 2008));
        MockItemLedgerEntry(childItem2."No.", 1, AssemblyHeader."Location Code", DMY2Date(1, 1, 2008));

        ExpectedDate := 0D; // Anydate with a year of due date of line=due date of header
        MockPurchaseOrder(childItem."No.", 1, AssemblyHeader."Location Code", DMY2Date(1, 1, 2010)); // any date before due date

        ValidateQtyAvailableToMake(AssemblyHeader, 1);
        ValidateEarliestDate(AssemblyHeader, ExpectedDate);
        ValidateOrderRatio(AssemblyHeader, 1);
        NotificationLifecycleMgt.RecallAllNotifications();
        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMockfunctions()
    var
        ChildItem: Record Item;
        Location: Record Location;
    begin
        Initialize();
        ChildItem.Get(LibraryKitting.CreateItemWithNewUOM(500, 700));
        MockItemLedgerEntry(ChildItem."No.", 10, LibraryWarehouse.CreateLocation(Location), DMY2Date(1, 1, 2010));
        ChildItem.CalcFields(Inventory);
        Assert.AreEqual(10, ChildItem.Inventory, 'Wrong Inventory');

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestLocation()
    var
        AssemblyHeader: Record "Assembly Header";
        ParentItemNo: Code[20];
    begin
        Initialize();
        ParentItemNo := LibraryKitting.CreateItemWithLotAndNewUOM(500, 700, 1);

        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate2, ParentItemNo, '', 1, '');
        AssemblyHeader.Validate("Location Code", '');
        AssemblyHeader.Validate("Due Date", WorkDate2);
        AssemblyHeader.Validate("Item No.");

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRemainingOnLineforOne()
    var
        AssemblyHeader: Record "Assembly Header";
        BOMComp: Record "BOM Component";
        AssemblyLine: Record "Assembly Line";
        parentItem: Record Item;
        childItem: Record Item;
    begin
        Initialize();
        parentItem.Get(LibraryKitting.CreateItemWithLotAndNewUOM(500, 700, 1));
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parentItem."No.", 1));
        childItem.Get(LibraryKitting.CreateItemWithNewUOM(500, 700));
        LibraryInventory.CreateBOMComponent(
          BOMComp, parentItem."No.", BOMComp.Type::Item, childItem."No.", 1, childItem."Base Unit of Measure");

        AssemblyHeader.RefreshBOM();
        AssemblyLine.SetRange("Document Type", AssemblyLine."Document Type"::Order);
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.FindFirst();
        ValidateremainingQty(AssemblyLine, 1);
        ValidateremainingQtyBase(AssemblyLine, 1);
        NotificationLifecycleMgt.RecallAllNotifications();
        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCalcFieldsForOrderAndLine()
    var
        AssemblyHeader: Record "Assembly Header";
        BOMComp: Record "BOM Component";
        parentItem: Record Item;
        childItem: Record Item;
        QTYParent: Decimal;
        QTYChild: Decimal;
    begin
        Initialize();
        QTYParent := 2;
        QTYChild := 4;

        parentItem.Get(LibraryKitting.CreateItemWithLotAndNewUOM(500, 700, 1));
        childItem.Get(LibraryKitting.CreateItemWithNewUOM(500, 700));
        LibraryInventory.CreateBOMComponent(
          BOMComp, parentItem."No.", BOMComp.Type::Item, childItem."No.", QTYChild, childItem."Base Unit of Measure");
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parentItem."No.", QTYParent));

        ValidateInItemOnOrder(parentItem."No.", QTYParent);
        ValidateInItemOnComponents(childItem."No.", QTYParent * QTYChild);
        NotificationLifecycleMgt.RecallAllNotifications();
        asserterror Error('') // roll back
    end;

    [Test]
    [HandlerFunctions('UpdateLocationHandler')]
    [Scope('OnPrem')]
    procedure TestCalcFieldsForOrderLocation()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        BOMComponent: Record "BOM Component";
        Location: Record Location;
        otherLocation: Record Location;
        parentItem: Record Item;
        childItem: Record Item;
        QTYParent: Decimal;
        QTYChild: Decimal;
    begin
        Initialize();
        QTYParent := 2;
        QTYChild := 4;

        parentItem.Get(LibraryKitting.CreateItemWithLotAndNewUOMUsingItemNo('Parent', 500, 700, 1));
        childItem.Get(LibraryKitting.CreateItemWithNewUOMUsingItemNo('Child', 500, 700));
        LibraryInventory.CreateBOMComponent(
          BOMComponent, parentItem."No.", BOMComponent.Type::Item, childItem."No.", QTYChild, childItem."Base Unit of Measure");
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parentItem."No.", QTYParent));
        LibraryWarehouse.CreateLocation(Location);
        LibraryWarehouse.CreateLocation(otherLocation);

        AssemblyHeader.Validate("Location Code", Location.Code);
        AssemblyHeader.Modify();
        ValidateInItemOnOrderLocation(parentItem."No.", QTYParent, Location.Code);
        ValidateInItemOnCompLocation(childItem."No.", QTYParent * QTYChild, Location.Code);
        ValidateInItemOnCompLocation(childItem."No.", 0, otherLocation.Code);

        AssemblyLine.SetRange("Document Type", AssemblyLine."Document Type"::Order);
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.FindFirst();
        AssemblyLine.Validate("Location Code", Location.Code);
        ValidateInItemOnCompLocation(childItem."No.", QTYParent * QTYChild, Location.Code);
        ValidateInItemOnCompLocation(childItem."No.", 0, otherLocation.Code);
        NotificationLifecycleMgt.RecallAllNotifications();
        asserterror Error('') // roll back
    end;

    [Test]
    [HandlerFunctions('IsBeforeWorkDateMsgHandler')]
    [Scope('OnPrem')]
    procedure TestAvailablilty()
    var
        AssemblyHeader: Record "Assembly Header";
        BOMComp: Record "BOM Component";
        parentItem: Record Item;
        childItem: Record Item;
        QTYParent: Decimal;
        QTYChild: Decimal;
    begin
        Initialize();
        LibraryKitting.SetLookahead('<1M>');
        LibraryPlanning.SetDefaultSafetyLeadTime('');

        QTYParent := 1;
        QTYChild := 5;
        parentItem.Get(LibraryKitting.CreateItemWithLotAndNewUOMUsingItemNo('Parent', 500, 700, 1));
        childItem.Get(LibraryKitting.CreateItemWithNewUOMUsingItemNo('Child', 500, 700));
        LibraryInventory.CreateBOMComponent(
          BOMComp, parentItem."No.", BOMComp.Type::Item, childItem."No.", QTYChild, childItem."Base Unit of Measure");

        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parentItem."No.", QTYParent));
        AssemblyHeader.Validate("Due Date", DMY2Date(1, 1, 2010));
        ValidateOrderAvailability(AssemblyHeader, false);
        MockItemLedgerEntry(childItem."No.", 10, AssemblyHeader."Location Code", DMY2Date(1, 1, 2010));
        ValidateInventoryMock(childItem."No.", 10);
        ValidateOrderAvailability(AssemblyHeader, true);
        MockSalesOrder(childItem."No.", 7, AssemblyHeader."Location Code", DMY2Date(1, 1, 2010));
        ValidateOrderAvailability(AssemblyHeader, false);
        NotificationLifecycleMgt.RecallAllNotifications();
        asserterror Error('') // roll back
    end;

    [Test]
    [HandlerFunctions('IsBeforeWorkDateMsgHandler,SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestAvailabilityWarning()
    var
        TempNotificationContext: Record "Notification Context" temporary;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        BOMComp: Record "BOM Component";
        parentItem: Record Item;
        childItem: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        LibraryInventory: Codeunit "Library - Inventory";
        QTYParent: Decimal;
        QTYChild: Decimal;
        NbNotifs: Integer;
    begin
        Initialize();
        QTYParent := 2;
        QTYChild := 1;

        parentItem.Get(LibraryKitting.CreateItemWithLotAndNewUOMUsingItemNo('Parent', 500, 700, 1));
        childItem.Get(LibraryKitting.CreateItemWithNewUOMUsingItemNo('Child', 500, 700));

        LibraryInventory.CreateBOMComponent(
          BOMComp, parentItem."No.", BOMComp.Type::Item, childItem."No.", QTYChild, childItem."Base Unit of Measure");

        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parentItem."No.", QTYParent));
        AssemblyHeader.Validate("Due Date", DMY2Date(1, 1, 2010));
        ValidateOrderAvailability(AssemblyHeader, false);

        AssemblyLine.SetRange("Document Type", AssemblyLine."Document Type"::Order);
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.FindFirst();
        AssemblyLine.ShowAvailabilityWarning();

        // WHEN we decrease the quantity so the item is available (0 items ordered)
        NotificationLifecycleMgt.GetTmpNotificationContext(TempNotificationContext);
        NbNotifs := TempNotificationContext.Count();
        EditAssemblyOrderQuantityPer(AssemblyHeader."No.", 0);

        // THEN the item availability notification is recalled
        Assert.AreEqual(NbNotifs - 1, TempNotificationContext.Count, 'Unexpected number of notifications after decreasing Quantity.');

        // WHEN we change the line type from item to resource
        EditAssemblyOrderQuantityPer(AssemblyHeader."No.", QTYChild);
        Assert.AreEqual(NbNotifs, TempNotificationContext.Count, 'Unexpected number of notifications after increasing Quantity back.');
        EditAssemblyOrderLineType(AssemblyHeader."No.", Format(AssemblyLine.Type::Resource));

        // THEN the item availability notification is recalled
        Assert.AreEqual(
          NbNotifs - 1, TempNotificationContext.Count, 'Unexpected number of notifications after changing line type to Resource.');

        // WHEN we change the line unit of measure
        // First, setup everything so we have a notification
        EditAssemblyOrderLineType(AssemblyHeader."No.", Format(AssemblyLine.Type::Item));
        EditAssemblyOrderLineNo(AssemblyHeader."No.", childItem."No.");

        SetItemInventory(childItem."No.", 10); // we buy 10 items
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, childItem."No.", UnitOfMeasure.Code, 5); // 1 box contains 5 items
        EditAssemblyOrderLineUnitOfMeasure(AssemblyHeader."No.", UnitOfMeasure.Code);
        EditAssemblyOrderQuantityPer(AssemblyHeader."No.", 3); // we try to sell 3 boxes of 5 items => notif
        Assert.AreEqual(
          NbNotifs, TempNotificationContext.Count, 'Unexpected number of notifications after changing line type back to Item.');
        // set back to the base unit of measure => 3 items instead of 3 boxes
        EditAssemblyOrderLineUnitOfMeasure(AssemblyHeader."No.", childItem."Base Unit of Measure");

        // THEN the item availability notification is recalled
        Assert.AreEqual(NbNotifs - 1, TempNotificationContext.Count, 'Unexpected number of notifications after changing unit of measure.');

        asserterror Error(''); // roll back
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('IsBeforeWorkDateMsgHandler,SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestAvailabilityWarningFields()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        BOMComp: Record "BOM Component";
        parentItem: Record Item;
        childItem: Record Item;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        QTYParent: Decimal;
        QTYChild: Decimal;
        QTYInventory: Decimal;
        QTYPurchase: Decimal;
        QTYNewPurchase: Decimal;
    begin
        Initialize();
        LibraryKitting.SetLookahead('<1Y>');
        LibraryPlanning.SetDefaultSafetyLeadTime('');

        QTYParent := 1;
        QTYChild := 16;     // must be 16
        QTYInventory := 10;
        QTYPurchase := 5;
        QTYNewPurchase := 1;

        parentItem.Get(LibraryKitting.CreateItemWithLotAndNewUOMUsingItemNo('Parent', 500, 700, 1));
        childItem.Get(LibraryKitting.CreateItemWithNewUOMUsingItemNo('Child', 500, 700));

        LibraryInventory.CreateBOMComponent(
          BOMComp, parentItem."No.", BOMComp.Type::Item, childItem."No.", QTYChild, childItem."Base Unit of Measure");

        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parentItem."No.", QTYParent));
        AssemblyHeader.Validate("Due Date", DMY2Date(15, 2, 2010));
        ValidateOrderAvailability(AssemblyHeader, false);

        MockItemLedgerEntry(childItem."No.", QTYInventory, AssemblyHeader."Location Code", DMY2Date(1, 1, 2008));
        MockPurchaseOrder(childItem."No.", QTYPurchase, AssemblyHeader."Location Code", DMY2Date(1, 2, 2010));

        LibraryAssembly.SetLinkToLines(AssemblyHeader, AssemblyLine);
        AssemblyLine.FindFirst();
        ValidateAvailabilityFields(AssemblyLine, QTYChild, QTYInventory, 0, QTYPurchase, false);

        MockPurchaseOrder(childItem."No.", QTYNewPurchase, AssemblyHeader."Location Code", DMY2Date(15, 2, 2010));
        ValidateAvailabilityFields(AssemblyLine, QTYChild, QTYInventory, 0, QTYPurchase + QTYNewPurchase, true);

        ValidateEarliestDate(AssemblyHeader, 0D);
        asserterror Error(''); // roll back
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('IsBeforeWorkDateMsgHandler')]
    [Scope('OnPrem')]
    procedure TestAvailabilityFields()
    var
        AssemblyHeader: Record "Assembly Header";
        BOMComp: Record "BOM Component";
        InventorySetup: Record "Inventory Setup";
        parentItem: Record Item;
        childItem: Record Item;
        childItem2: Record Item;
        QTYParent: Decimal;
        QTYChild: Decimal;
        ExpectedDate: Date;
    begin
        Initialize();
        LibraryPlanning.SetDefaultSafetyLeadTime('<1D>');

        LibraryKitting.SetLookahead('<1M>');
        QTYParent := 8;
        QTYChild := 1;
        parentItem.Get(LibraryKitting.CreateItemWithLotAndNewUOMUsingItemNo('Parent', 500, 700, 1));
        childItem.Get(LibraryKitting.CreateItemWithNewUOMUsingItemNo('Child1', 500, 700));
        childItem2.Get(LibraryKitting.CreateItemWithNewUOMUsingItemNo('Child2', 500, 700));

        LibraryInventory.CreateBOMComponent(
          BOMComp, parentItem."No.", BOMComp.Type::Item, childItem."No.", QTYChild, childItem."Base Unit of Measure");
        LibraryInventory.CreateBOMComponent(
          BOMComp, parentItem."No.", BOMComp.Type::Item, childItem2."No.", QTYChild, childItem2."Base Unit of Measure");

        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrderNo(WorkDate2, 'testAvailField',
            parentItem."No.", QTYParent));
        AssemblyHeader.Validate("Due Date", DMY2Date(1, 2, 2010));

        MockItemLedgerEntry(childItem."No.", 3, AssemblyHeader."Location Code", DMY2Date(1, 1, 2008));
        MockItemLedgerEntry(childItem2."No.", 7, AssemblyHeader."Location Code", DMY2Date(1, 1, 2008));
        ExpectedDate := DMY2Date(17, 2, 2010); // Anydate with a year of due date of line=due date of header
        MockPurchaseOrder(childItem."No.", 1, AssemblyHeader."Location Code", DMY2Date(1, 1, 2010)); // any date before due date
        MockPurchaseOrder(childItem."No.", 4, AssemblyHeader."Location Code", 20100210D); // any date between due date and expected date
        MockPurchaseOrder(childItem2."No.", 1, AssemblyHeader."Location Code", ExpectedDate);

        ValidateQtyAvailableToMake(AssemblyHeader, 4);
        InventorySetup.Get();
        ValidateEarliestDate(AssemblyHeader, CalcDate(InventorySetup."Default Safety Lead Time", ExpectedDate));
        ValidateOrderRatio(AssemblyHeader, 4);
        NotificationLifecycleMgt.RecallAllNotifications();
        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRatioUOM()
    var
        AssemblyHeader: Record "Assembly Header";
        BOMComp: Record "BOM Component";
        ParentItem: Record Item;
        ChildItem: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
    begin
        Initialize();
        LibraryKitting.SetLookahead('<1M>');

        ParentItem.Get(LibraryKitting.CreateItemWithLotAndNewUOMUsingItemNo('Parent', 500, 700, 1));
        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, ParentItem."No.", NonBaseUOM.Code, 10);

        ChildItem.Get(LibraryKitting.CreateItemWithNewUOMUsingItemNo('Child1', 500, 700));
        LibraryInventory.CreateBOMComponent(
          BOMComp, ParentItem."No.", BOMComp.Type::Item, ChildItem."No.", 2, ChildItem."Base Unit of Measure");

        AssemblyHeader.Get(
          AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrderNo(WorkDate2, 'testAvailField', ParentItem."No.", 3));
        AssemblyHeader.Validate("Unit of Measure Code", NonBaseUOM.Code);
        AssemblyHeader.Modify();
        MockItemLedgerEntry(ChildItem."No.", 5, AssemblyHeader."Location Code", DMY2Date(1, 1, 2008));

        ValidateOrderRatio(AssemblyHeader, 0.25);
        NotificationLifecycleMgt.RecallAllNotifications();

        asserterror Error('') // roll back
    end;

    [Test]
    procedure AvailabilityOfAssemblyComponentWithFutureDemands()
    var
        AsmItem: Record Item;
        CompItem: Record Item;
        BOMComponent: Record "BOM Component";
        ItemJournalLine: Record "Item Journal Line";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: array[2] of Record "Assembly Line";
        AssemblyInfoPaneManagement: Codeunit "Assembly Info-Pane Management";
    begin
        // [FEATURE] [Availability] [UT]
        // [SCENARIO 396510] Availability of assembly component with future demands.
        Initialize();

        // [GIVEN] Assembly item.
        LibraryInventory.CreateItem(AsmItem);
        AsmItem.Validate("Replenishment System", AsmItem."Replenishment System"::Assembly);
        AsmItem.Modify(true);

        // [GIVEN] Component item.
        LibraryInventory.CreateItem(CompItem);
        LibraryInventory.CreateBOMComponent(
          BOMComponent, AsmItem."No.", BOMComponent.Type::Item, CompItem."No.", 1, CompItem."Base Unit of Measure");

        // [GIVEN] Post 2 pcs of the component to inventory.
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, CompItem."No.", '', '', 2);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Assembly order for 1 pc on WorkDate() + 1. Assembly line = "A1".
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate() + 1, AsmItem."No.", '', 1, '');
        FindAssemblyLine(AssemblyLine[1], AssemblyHeader, CompItem."No.");

        // [GIVEN] Assembly order for 1 pc on WorkDate() + 2. Assembly line = "A2".
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate() + 2, AsmItem."No.", '', 1, '');
        FindAssemblyLine(AssemblyLine[2], AssemblyHeader, CompItem."No.");

        // [WHEN] Invoke "CalcAvailability" function that shows item availability in the factbox for assembly line.
        // [THEN] Available quantity for the assembly line "A1" = 1.
        // [THEN] Available quantity for the assembly line "A2" = 0.
        Assert.AreEqual(
          1, AssemblyInfoPaneManagement.CalcAvailability(AssemblyLine[1]), 'Wrong available quantity for the assembly line.');
        Assert.AreEqual(
          0, AssemblyInfoPaneManagement.CalcAvailability(AssemblyLine[2]), 'Wrong available quantity for the assembly line.');
    end;

    [Normal]
    local procedure EditAssemblyOrderLineNo(AssemblyOrderNo: Code[20]; AssemblyLineNo: Code[20])
    begin
        // Method Edits Assembly Order's line No (item number for example).
        OpenAssemblyOrderPageByNo(AssemblyOrderNo, DummyAssemblyOrderTestPage);

        // EXECUTE: Change Line "No" on Assembly Order Through UI.
        DummyAssemblyOrderTestPage.Lines."No.".Value(AssemblyLineNo);
        DummyAssemblyOrderTestPage.Close();
    end;

    [Normal]
    local procedure EditAssemblyOrderLineUnitOfMeasure(AssemblyOrderNo: Code[20]; AssemblyLineUnitOfMeasureCode: Code[20])
    begin
        // Method Edits Assembly Order's "unit of measure".
        OpenAssemblyOrderPageByNo(AssemblyOrderNo, DummyAssemblyOrderTestPage);

        // EXECUTE: Change Line unit of measure on Assembly Order Through UI.
        DummyAssemblyOrderTestPage.Lines."Unit of Measure Code".Value(AssemblyLineUnitOfMeasureCode);
        DummyAssemblyOrderTestPage.Close();
    end;

    [Normal]
    local procedure EditAssemblyOrderLineType(AssemblyOrderNo: Code[20]; AssemblyLineType: Text)
    begin
        // Method Edits Assembly Order's line Type.
        OpenAssemblyOrderPageByNo(AssemblyOrderNo, DummyAssemblyOrderTestPage);

        // EXECUTE: Change Line type on Assembly Order Through UI.
        DummyAssemblyOrderTestPage.Lines.Type.Value(AssemblyLineType);
        DummyAssemblyOrderTestPage.Close();
    end;

    [Normal]
    local procedure EditAssemblyOrderQuantityPer(AssemblyOrderNo: Code[20]; AssemblyQuantityPer: Integer)
    begin
        // Method Edits Assembly Order's line "Quantity per".
        OpenAssemblyOrderPageByNo(AssemblyOrderNo, DummyAssemblyOrderTestPage);

        // EXECUTE: Change Demand "Quantity per" on Assembly Order Through UI.
        DummyAssemblyOrderTestPage.Lines."Quantity per".Value(Format(AssemblyQuantityPer));
        DummyAssemblyOrderTestPage.Close();
    end;

    local procedure FindAssemblyLine(var AssemblyLine: Record "Assembly Line"; AssemblyHeader: Record "Assembly Header"; ItemNo: Code[20])
    begin
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.SetRange("No.", ItemNo);
        AssemblyLine.FindFirst();
    end;

    [Normal]
    local procedure OpenAssemblyOrderPageByNo(AssemblyOrderNoToFind: Code[20]; AssemblyOrderToReturn: TestPage "Assembly Order")
    var
        DummyAssemblyHeader: Record "Assembly Header";
    begin
        // Method Opens assembly order page for the assembly order no.
        AssemblyOrderToReturn.OpenEdit();
        Assert.IsTrue(
          AssemblyOrderToReturn.GotoKey(DummyAssemblyHeader."Document Type"::Order, AssemblyOrderNoToFind),
          'Unable to locate assembly order with order no');
    end;

    local procedure SetItemInventory(ItemNo: Code[20]; Quantity: Integer)
    var
        Item: Record Item;
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        Item.SetRange("No.", ItemNo);
        Item.FindFirst();
        Item.Validate(Inventory, Quantity);
        Item.Modify();
        SequenceNoMgt.ClearState();
    end;

    local procedure ValidateOrderRatio(AsmHeader: Record "Assembly Header"; ExpectedAvailable: Decimal)
    var
        AssemblyLine: Record "Assembly Line";
        Result: Decimal;
        AvailableDate: Date;
    begin
        LibraryAssembly.SetLinkToLines(AsmHeader, AssemblyLine);
        LibraryAssembly.EarliestAvailableDate(AsmHeader, AssemblyLine, Result, AvailableDate);
        Assert.AreEqual(Result, ExpectedAvailable,
          StrSubstNo('Bad Able to make for Assembly order %1 Expected %2, got %3',
            AsmHeader."No.",
            ExpectedAvailable,
            Result));
    end;

    local procedure ValidateAvailabilityFields(AsmLine: Record "Assembly Line"; ExpectedQuantity: Decimal; ExpectedInventory: Decimal; ExpectedCrossRequirement: Decimal; ExpectedScheduledReceipts: Decimal; ExpectedAvailable: Boolean)
    var
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        getItemNo: Code[20];
        getInventory: Decimal;
        getGrossRequirement: Decimal;
        getReservedRequirement: Decimal;
        getScheduledReceipts: Decimal;
        getReservedReceipts: Decimal;
        getCurrentQty: Decimal;
        getCurrentResQty: Decimal;
        getTotalQty: Decimal;
        getEarliestAvilabilityDate: Date;
        getUnitOfMeasure: Code[10];
    begin
        ItemCheckAvail.AssemblyLineCheck(AsmLine);
        ItemCheckAvail.FetchCalculation(getItemNo, getUnitOfMeasure, getInventory,
          getGrossRequirement, getReservedRequirement, getScheduledReceipts, getReservedReceipts,
          getCurrentQty, getCurrentResQty, getTotalQty, getEarliestAvilabilityDate);
        Assert.AreEqual(ExpectedQuantity, AsmLine."Remaining Quantity",
          StrSubstNo('Wrong Expected Quantity in %1, expected %2 - got %3', AsmLine."Document No.", ExpectedQuantity,
            AsmLine."Remaining Quantity"));
        Assert.AreEqual(ExpectedInventory, getInventory,
          StrSubstNo('Wrong Inventory in %1, expected %2 - got %3', AsmLine."Document No.", ExpectedInventory, getInventory));
        Assert.AreEqual(ExpectedCrossRequirement, getGrossRequirement,
          StrSubstNo('Wrong GrossReq. in %1, expected %2 - got %3', AsmLine."Document No.", ExpectedCrossRequirement,
            getGrossRequirement));
        Assert.AreEqual(ExpectedScheduledReceipts, getScheduledReceipts,
          StrSubstNo('Wrong ScheduledReceipts in %1, expected %2 - got %3', AsmLine."Document No.", ExpectedScheduledReceipts,
            getScheduledReceipts));
        Assert.AreEqual(ExpectedAvailable, getTotalQty >= 0,
          StrSubstNo('Wrong Availability in %1, expected %2 - got %3', AsmLine."Document No.", ExpectedAvailable, getTotalQty >= 0));
    end;

    local procedure ValidateQtyAvailableToMake(AsmHeader: Record "Assembly Header"; ExpectedQty: Decimal)
    var
        AssemblyLine: Record "Assembly Line";
        QtyAvailable: Decimal;
        EarliestDate: Date;
    begin
        LibraryAssembly.SetLinkToLines(AsmHeader, AssemblyLine);
        LibraryAssembly.EarliestAvailableDate(AsmHeader, AssemblyLine, QtyAvailable, EarliestDate);
        Assert.AreEqual(QtyAvailable, ExpectedQty,
          StrSubstNo('Wrong Availability Qty in %1, expected %2 - got %3', AsmHeader."No.", ExpectedQty, QtyAvailable));
    end;

    local procedure ValidateEarliestDate(AsmHeader: Record "Assembly Header"; ExpectedDate: Date)
    var
        AssemblyLine: Record "Assembly Line";
        QtyAvailable: Decimal;
        EarliestDate: Date;
    begin
        LibraryAssembly.SetLinkToLines(AsmHeader, AssemblyLine);
        LibraryAssembly.EarliestAvailableDate(AsmHeader, AssemblyLine, QtyAvailable, EarliestDate);
        Assert.AreEqual(EarliestDate, ExpectedDate,
          StrSubstNo('Wrong EarliestDate in %1, expected %2 - got %3', AsmHeader."No.", ExpectedDate, EarliestDate));
    end;

    local procedure ValidateInventoryMock(Itemno: Code[20]; ExpectedInventory: Decimal)
    var
        Item: Record Item;
        result: Decimal;
    begin
        Item.Get(Itemno);
        Item.CalcFields(Inventory);
        result := Item.Inventory;
        Assert.AreEqual(result, ExpectedInventory,
          StrSubstNo('Bad inventory for %1 expected %2 but got %3',
            Item."No.", ExpectedInventory, result));
    end;

    local procedure ValidateOrderAvailability(AsmHeader: Record "Assembly Header"; ExpectedAvailable: Boolean)
    var
        Result: Boolean;
    begin
        Result := LibraryAssembly.ComponentsAvailable(AsmHeader);
        Assert.AreEqual(Result, ExpectedAvailable,
          StrSubstNo('Bad Availability for components in Assembly order %1 Expected %2, got %3',
            AsmHeader."No.",
            ExpectedAvailable,
            Result));
    end;

    local procedure ValidateremainingQty(AssemblyLine: Record "Assembly Line"; ExpectedRemQty: Decimal)
    begin
        Assert.AreEqual(AssemblyLine."Quantity (Base)", ExpectedRemQty,
          StrSubstNo('Bad Remaining Qty in Assembly Line %1 Expected %2, got %3',
            AssemblyLine."Document No.",
            ExpectedRemQty,
            AssemblyLine."Quantity (Base)"));
    end;

    local procedure ValidateremainingQtyBase(AssemblyLine: Record "Assembly Line"; ExpectedRemQty: Decimal)
    begin
        Assert.AreEqual(AssemblyLine."Remaining Quantity", ExpectedRemQty,
          StrSubstNo('Bad Remaining Qty(Base) in Assembly Line %1 Expected %2, got %3',
            AssemblyLine."Document No.",
            ExpectedRemQty,
            AssemblyLine."Remaining Quantity"));
    end;

    local procedure ValidateInItemOnOrder(ItemNo: Code[20]; ExpectedQuantity: Decimal)
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Item.CalcFields("Qty. on Assembly Order");
        Assert.AreEqual(Item."Qty. on Assembly Order", ExpectedQuantity,
          StrSubstNo('Bad "Qty. on Assembly Order" for Item %1 Expected %2, got %3',
            Item."No.",
            ExpectedQuantity,
            Item."Qty. on Assembly Order"));
    end;

    local procedure ValidateInItemOnComponents(ItemNo: Code[20]; ExpectedQuantity: Decimal)
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Item.SetRange("Location Filter");
        Item.CalcFields("Qty. on Asm. Component");
        Assert.AreEqual(Item."Qty. on Asm. Component", ExpectedQuantity,
          StrSubstNo('Bad "Qty. on Assembly Order" for Item %1 Expected %2, got %3',
            Item."No.",
            ExpectedQuantity,
            Item."Qty. on Asm. Component"));
    end;

    local procedure ValidateInItemOnOrderLocation(ItemNo: Code[20]; ExpectedQuantity: Decimal; LocationCode: Code[20])
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Item.SetRange("Location Filter", LocationCode);
        Item.CalcFields("Qty. on Assembly Order");
        Assert.AreEqual(Item."Qty. on Assembly Order", ExpectedQuantity,
          StrSubstNo('Bad "Qty. on Assembly Order" for Item %1 Expected %2, got %3',
            Item."No.",
            ExpectedQuantity,
            Item."Qty. on Assembly Order"));
    end;

    local procedure ValidateInItemOnCompLocation(ItemNo: Code[20]; ExpectedQuantity: Decimal; LocationCode: Code[20])
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Item.SetRange("Location Filter", LocationCode);
        Item.CalcFields("Qty. on Asm. Component");
        Assert.AreEqual(Item."Qty. on Asm. Component", ExpectedQuantity,
          StrSubstNo('Bad "Qty. on Assembly Comp" for Item %1 Expected %2 at %4, got %3',
            Item."No.",
            ExpectedQuantity,
            Item."Qty. on Asm. Component", LocationCode));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure UpdateLocationHandler(Question: Text[1024]; var Choice: Boolean)
    begin
        Choice := true;
    end;

    local procedure MockItemLedgerEntry(ItemNo: Code[20]; Qty: Decimal; LocationCode: Code[10]; Date: Date)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.Reset();
        if LastEntryNo = 0 then begin
            if ItemLedgEntry.FindLast() then;
            ItemLedgEntry."Entry No." += 1;
            LastEntryNo := ItemLedgEntry."Entry No."
        end else begin
            LastEntryNo += 1;
            ItemLedgEntry."Entry No." := LastEntryNo;
        end;
        ItemLedgEntry."Item No." := ItemNo;
        ItemLedgEntry.Quantity := Qty;
        ItemLedgEntry."Location Code" := LocationCode;
        ItemLedgEntry."Posting Date" := Date;
        ItemLedgEntry.Insert();
    end;

    local procedure MockSalesOrder(ItemNo: Code[20]; Qty: Decimal; LocationCode: Code[10]; Date: Date)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Reset();
        SalesLine."Document Type" := SalesLine."Document Type"::Order;
        if LastEntryNo = 0 then begin
            if SalesLine.FindLast() then;
            SalesLine."Line No." := SalesLine."Line No." + 10000;
            LastEntryNo := SalesLine."Line No.";
        end else begin
            LastEntryNo += 10000;
            SalesLine."Line No." := LastEntryNo;
        end;
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := ItemNo;
        SalesLine."Outstanding Qty. (Base)" := Qty;
        SalesLine."Location Code" := LocationCode;
        SalesLine."Shipment Date" := Date;
        SalesLine.Insert();
    end;

    local procedure MockPurchaseOrder(ItemNo: Code[20]; Qty: Decimal; LocationCode: Code[10]; Date: Date)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.Reset();
        PurchaseLine."Document Type" := PurchaseLine."Document Type"::Order;
        if LastEntryNo = 0 then begin
            if PurchaseLine.FindLast() then;
            PurchaseLine."Line No." := PurchaseLine."Line No." + 10000;
            LastEntryNo := PurchaseLine."Line No.";
        end else begin
            LastEntryNo += 10000;
            PurchaseLine."Line No." := LastEntryNo;
        end;
        PurchaseLine.Type := PurchaseLine.Type::Item;
        PurchaseLine."No." := ItemNo;
        PurchaseLine."Outstanding Qty. (Base)" := Qty;
        PurchaseLine."Outstanding Quantity" := Qty;
        PurchaseLine."Location Code" := LocationCode;
        PurchaseLine."Expected Receipt Date" := Date;
        PurchaseLine.Insert();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure IsBeforeWorkDateMsgHandler(Msg: Text[1024])
    begin
        Assert.IsTrue(StrPos(Msg, MSG_IS_BEFORE_WORKDATE) > 0, '');
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    begin
    end;
}

