// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Test;

using Microsoft.Assembly.History;
using Microsoft.Warehouse.Ledger;
using System.Environment.Configuration;
using Microsoft.Assembly.Document;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.BOM;
using Microsoft.Foundation.UOM;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Assembly.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Location;
using Microsoft.Sales.Document;
using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Warehouse.Structure;
using Microsoft.Inventory;

codeunit 137908 "SCM Assembly Order"
{
    Permissions = TableData "Posted Assembly Header" = rimd,
                  TableData "Warehouse Entry" = rimd;
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
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPlanning: Codeunit "Library - Planning";
        WorkDate2: Date;
        Initialized: Boolean;
        CnfmRefreshLinesQst: Label 'This assembly order may have customized lines. Are you sure that you want to reset the lines according to the assembly BOM?';
        AssertLineCountErr: Label 'Bad Line count of Order: %1 expected %2, got %3', Comment = '%1: Order No.; %2: Expected line count; %3: Actual line count';
        UpdateDimensionOnLineQst: Label 'You may have changed a dimension.\\Do you want to update the lines?';
        NotMatchingDimensionsMsg: Label 'Dimensions are not matching on header and line.';
        QtyPerNoChangeErr: Label 'You cannot change Quantity per when Type is '' ''.';
        RoundingTo0Err: Label 'Rounding of the field';
        RoundingErr: Label 'is of lower precision than expected';
        ValueMustBeEqualErr: Label '%1 must be equal to %2 in the %3.', Comment = '%1 = Field Caption , %2 = Expected Value, %3 = Table Caption';
        QtyToConsumeMustBeUpdatedErr: Label 'Quantity to Consume in assembly line must be updated.';

    [Normal]
    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Assembly Order");
        if Initialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Assembly Order");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        Initialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Assembly Order");
    end;

    local procedure CreateAssemblyOrderWithoutLines(var AssemblyHeader: Record "Assembly Header"; DueDate: Date; ItemNo: Code[20])
    begin
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(DueDate, ItemNo, 0)); // no lines
    end;

    local procedure FindAssemblyLine(AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line")
    begin
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.FindFirst();
    end;

    local procedure FindItemUnitOfMeasure(Item: Record Item; var ItemUOM: Record "Item Unit of Measure")
    begin
        ItemUOM.Get(Item."No.", Item."Base Unit of Measure");
    end;

    local procedure CalculateAssemblyLineQty(AssemblyHeader: Record "Assembly Header"; BOMComponent: Record "BOM Component"; ItemUOM: Record "Item Unit of Measure"): Decimal;
    var
        UOMMgt: Codeunit "Unit of Measure Management";
    begin
        exit(UOMMgt.RoundToItemRndPrecision(AssemblyHeader.Quantity * BOMComponent."Quantity per", ItemUOM."Qty. Rounding Precision"));
    end;

    local procedure MatchTxt(AssemblyLine: Record "Assembly Line"; ExpectedQuantity: Decimal): Text
    begin
        exit(
            StrSubstNo(
                ValueMustBeEqualErr,
                AssemblyLine.FieldCaption(Quantity),
                ExpectedQuantity,
                AssemblyLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BUG232108TwoUOM()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        BOMComp: Record "BOM Component";
        Item: Record Item;
        childItem: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        parent: Code[20];
        BOMQtyPer: Decimal;
        HeaderQty: Decimal;
        ParentQtyPerUOM: Decimal;
    begin
        Initialize();
        BOMQtyPer := 3;
        HeaderQty := 2;
        ParentQtyPerUOM := 15;

        parent := MakeItemWithLot();
        Item.Get(parent);
        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, ParentQtyPerUOM);
        childItem.Get(MakeItem());
        LibraryInventory.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Item, childItem."No.", BOMQtyPer, childItem."Base Unit of Measure");

        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parent, HeaderQty));
        AssemblyHeader.Validate("Unit of Measure Code", NonBaseUOM.Code);

        validateQuantityonLines(AssemblyHeader."No.", HeaderQty * ParentQtyPerUOM * BOMQtyPer);
        ValidateTotalQuantityToConsume(AssemblyHeader, HeaderQty * ParentQtyPerUOM * BOMQtyPer);

        AsmLineFindFirst(AssemblyHeader, AssemblyLine);
        ValidateQuantityPer(AssemblyLine, ParentQtyPerUOM * BOMQtyPer);
        NotificationLifecycleMgt.RecallAllNotifications();

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BUG232108TwoUOMUOMbeforeQty()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        BOMComp: Record "BOM Component";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        childItem: Record Item;
        parent: Code[20];
        BOMQtyPer: Decimal;
        HeaderQty: Decimal;
        ParentQtyPerUOM: Decimal;
    begin
        Initialize();
        BOMQtyPer := 3;
        HeaderQty := 2;
        ParentQtyPerUOM := 15;

        parent := MakeItemWithLot();
        Item.Get(parent);
        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, ParentQtyPerUOM);
        childItem.Get(MakeItem());
        LibraryInventory.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Item, childItem."No.", BOMQtyPer, childItem."Base Unit of Measure");

        CreateAssemblyOrderWithoutLines(AssemblyHeader, WorkDate2, parent);
        AssemblyHeader.Validate("Unit of Measure Code", NonBaseUOM.Code);
        AssemblyHeader.Validate(Quantity, HeaderQty);

        validateQuantityonLines(AssemblyHeader."No.", HeaderQty * ParentQtyPerUOM * BOMQtyPer);
        ValidateTotalQuantityToConsume(AssemblyHeader, HeaderQty * ParentQtyPerUOM * BOMQtyPer);

        AsmLineFindFirst(AssemblyHeader, AssemblyLine);
        ValidateQuantityPer(AssemblyLine, ParentQtyPerUOM * BOMQtyPer);
        NotificationLifecycleMgt.RecallAllNotifications();

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OneOrderNoLine()
    var
        AssemblyHeader: Record "Assembly Header";
        Parent: Code[20];
    begin
        Initialize();
        Parent := MakeItemWithLot();
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, Parent, 1));

        AssemblyHeader.RefreshBOM();
        validateCount(AssemblyHeader."No.", 0);

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OneOrderAddOneLine()
    var
        AssemblyHeader: Record "Assembly Header";
        BOMComp: Record "BOM Component";
        childItem: Record Item;
        parent: Code[20];
    begin
        Initialize();
        parent := MakeItemWithLot();
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parent, 1));
        childItem.Get(MakeItem());
        LibraryInventory.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Item, childItem."No.", 1, childItem."Base Unit of Measure");

        AssemblyHeader.RefreshBOM();
        validateCount(AssemblyHeader."No.", 1);
        NotificationLifecycleMgt.RecallAllNotifications();

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OneOrderOneLine()
    var
        AssemblyHeader: Record "Assembly Header";
        BOMComp: Record "BOM Component";
        childItem: Record Item;
        parent: Code[20];
    begin
        Initialize();
        parent := MakeItemWithLot();
        childItem.Get(MakeItem());
        LibraryInventory.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Item, childItem."No.", 1, childItem."Base Unit of Measure");

        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parent, 1));
        validateCount(AssemblyHeader."No.", 1);
        NotificationLifecycleMgt.RecallAllNotifications();

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OneOrderTwoLine()
    var
        AssemblyHeader: Record "Assembly Header";
        BOMComp: Record "BOM Component";
        childItem: Record Item;
        parent: Code[20];
    begin
        Initialize();
        parent := MakeItemWithLot();
        childItem.Get(MakeItem());
        LibraryInventory.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Item, childItem."No.", 1, childItem."Base Unit of Measure");
        childItem.Get(MakeItem());
        LibraryInventory.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Item, childItem."No.", 1, childItem."Base Unit of Measure");

        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parent, 1));
        validateCount(AssemblyHeader."No.", 2);
        NotificationLifecycleMgt.RecallAllNotifications();

        asserterror Error('') // roll back
    end;

    [Test]
    [HandlerFunctions('ConfirmItemChange')]
    [Scope('OnPrem')]
    procedure OneOrderTwoLineChangeItem()
    var
        AssemblyHeader: Record "Assembly Header";
        BOMComp: Record "BOM Component";
        childItem: Record Item;
        parent: Code[20];
        SecondParent: Code[20];
    begin
        Initialize();
        parent := MakeItemWithLot();
        childItem.Get(MakeItem());
        LibraryInventory.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Item, childItem."No.", 1, childItem."Base Unit of Measure");
        childItem.Get(MakeItem());
        LibraryInventory.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Item, childItem."No.", 1, childItem."Base Unit of Measure");

        SecondParent := MakeItemWithLot();
        childItem.Get(MakeItem());
        LibraryInventory.CreateBOMComponent(
          BOMComp, SecondParent, BOMComp.Type::Item, childItem."No.", 1, childItem."Base Unit of Measure");
        childItem.Get(MakeItem());
        LibraryInventory.CreateBOMComponent(
          BOMComp, SecondParent, BOMComp.Type::Item, childItem."No.", 1, childItem."Base Unit of Measure");
        childItem.Get(MakeItem());
        LibraryInventory.CreateBOMComponent(
          BOMComp, SecondParent, BOMComp.Type::Item, childItem."No.", 1, childItem."Base Unit of Measure");
        childItem.Get(MakeItem());
        LibraryInventory.CreateBOMComponent(
          BOMComp, SecondParent, BOMComp.Type::Item, childItem."No.", 1, childItem."Base Unit of Measure");

        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parent, 1));
        validateCount(AssemblyHeader."No.", 2);

        AssemblyHeader.Validate("Item No.", SecondParent);
        validateCount(AssemblyHeader."No.", 4);
        NotificationLifecycleMgt.RecallAllNotifications();

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OneOrderOneItemOneResource()
    var
        AssemblyHeader: Record "Assembly Header";
        BOMComp: Record "BOM Component";
        childItem: Record Item;
        resource: Record Resource;
        parent: Code[20];
    begin
        Initialize();
        parent := MakeItemWithLot();
        childItem.Get(MakeItem());
        LibraryInventory.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Item, childItem."No.", 1, childItem."Base Unit of Measure");
        resource.Get(LibraryKitting.CreateResourceWithNewUOM(500, 700));
        LibraryInventory.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Resource, resource."No.", 1, resource."Base Unit of Measure");

        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parent, 1));
        validateCount(AssemblyHeader."No.", 2);
        NotificationLifecycleMgt.RecallAllNotifications();

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OneOrderOneItemandResourceandT()
    var
        AssemblyHeader: Record "Assembly Header";
        BOMComp: Record "BOM Component";
        childItem: Record Item;
        resource: Record Resource;
        parent: Code[20];
    begin
        Initialize();
        parent := MakeItemWithLot();
        childItem.Get(MakeItem());
        LibraryInventory.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Item, childItem."No.", 1, childItem."Base Unit of Measure");
        resource.Get(LibraryKitting.CreateResourceWithNewUOM(500, 700));
        LibraryInventory.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Resource, resource."No.", 1, resource."Base Unit of Measure");
        LibraryInventory.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::" ", '', 0, '');
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parent, 1));
        validateCount(AssemblyHeader."No.", 3);
        NotificationLifecycleMgt.RecallAllNotifications();

        asserterror Error('') // roll back
    end;

    [Test]
    [HandlerFunctions('ConfirmRefreshLines')]
    [Scope('OnPrem')]
    procedure OneOrderTwoLineRefreshOneLine()
    var
        AssemblyHeader: Record "Assembly Header";
        BOMComp: Record "BOM Component";
        childItem: Record Item;
        resource: Record Resource;
        parent: Code[20];
    begin
        Initialize();
        parent := MakeItemWithLot();
        childItem.Get(MakeItem());
        LibraryInventory.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Item, childItem."No.", 1, childItem."Base Unit of Measure");
        resource.Get(LibraryKitting.CreateResourceWithNewUOM(500, 700));
        LibraryInventory.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Resource, resource."No.", 1, resource."Base Unit of Measure");
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parent, 1));
        validateCount(AssemblyHeader."No.", 2);
        childItem.Get(MakeItem());
        LibraryInventory.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Item, childItem."No.", 1, childItem."Base Unit of Measure");
        AssemblyHeader.RefreshBOM();
        validateCount(AssemblyHeader."No.", 3);
        NotificationLifecycleMgt.RecallAllNotifications();

        asserterror Error('') // roll back
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmRefreshLines(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, CnfmRefreshLinesQst) > 0, Question);
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmUpdateDimensionOnLines(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, UpdateDimensionOnLineQst) > 0, Question);
        Reply := true;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OneOrderTwoLineDelete()
    var
        AssemblyHeader: Record "Assembly Header";
        BOMComp: Record "BOM Component";
        childItem: Record Item;
        parent: Code[20];
    begin
        Initialize();
        parent := MakeItemWithLot();
        childItem.Get(MakeItem());
        LibraryInventory.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Item, childItem."No.", 1, childItem."Base Unit of Measure");
        childItem.Get(MakeItem());
        LibraryInventory.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Item, childItem."No.", 1, childItem."Base Unit of Measure");

        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parent, 1));
        validateCount(AssemblyHeader."No.", 2);
        AssemblyHeader.Delete(true);
        validateDeleted(AssemblyHeader, 0);
        NotificationLifecycleMgt.RecallAllNotifications();

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OneCompAverage()
    var
        AssemblyHeader: Record "Assembly Header";
        BOMComp: Record "BOM Component";
        Item: Record Item;
        childItem: Record Item;
        parent: Code[20];
    begin
        Initialize();
        parent := MakeItemWithLot();
        Item.Get(parent);
        Item.Validate("Costing Method", Item."Costing Method"::Average);
        childItem.Get(LibraryKitting.CreateItemWithNewUOM(10, 700));
        LibraryInventory.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Item, childItem."No.", 10, childItem."Base Unit of Measure");
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parent, 1));
        AssemblyHeader.UpdateUnitCost();
        ValidateOrderUnitCost(AssemblyHeader, 100);
        NotificationLifecycleMgt.RecallAllNotifications();

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BomWithResourceUsageType()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        BOMComp: Record "BOM Component";
        resource: Record Resource;
        parent: Code[20];
    begin
        Initialize();
        parent := MakeItemWithLot();
        resource.Get(LibraryKitting.CreateResourceWithNewUOM(500, 700));
        LibraryInventory.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Resource, resource."No.", 1, resource."Base Unit of Measure");
        resource.Get(LibraryKitting.CreateResourceWithNewUOM(500, 700));
        LibraryInventory.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Resource, resource."No.", 1, resource."Base Unit of Measure");
        BOMComp.Validate("Resource Usage Type", BOMComp."Resource Usage Type"::Fixed);
        BOMComp.Modify(true);

        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parent, 1));
        validateCount(AssemblyHeader."No.", 2);
        AsmLineFindFirst(AssemblyHeader, AssemblyLine);
        ValidateLineResourceTypeUsage(AssemblyLine, AssemblyLine."Resource Usage Type"::Direct);
        AssemblyLine.Next();
        ValidateLineResourceTypeUsage(AssemblyLine, AssemblyLine."Resource Usage Type"::Fixed);

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BomWithResourceUsageTypeFixed()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        BOMComp: Record "BOM Component";
        resource: Record Resource;
        parent: Code[20];
        ParentQty: Decimal;
        BomQty: Decimal;
    begin
        Initialize();
        ParentQty := 5;
        BomQty := 2;

        parent := MakeItemWithLot();
        resource.Get(LibraryKitting.CreateResourceWithNewUOM(500, 700));
        LibraryInventory.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Resource, resource."No.", BomQty, resource."Base Unit of Measure");
        resource.Get(LibraryKitting.CreateResourceWithNewUOM(500, 700));
        LibraryInventory.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Resource, resource."No.", BomQty, resource."Base Unit of Measure");
        BOMComp.Validate("Resource Usage Type", BOMComp."Resource Usage Type"::Fixed);
        BOMComp.Modify(true);

        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parent, ParentQty));
        validateCount(AssemblyHeader."No.", 2);
        AsmLineFindFirst(AssemblyHeader, AssemblyLine);
        ValidateLineResourceTypeUsage(AssemblyLine, AssemblyLine."Resource Usage Type"::Direct);
        ValidateQuantity(AssemblyLine, BomQty * ParentQty);
        AssemblyLine.Validate("Resource Usage Type", AssemblyLine."Resource Usage Type"::Fixed);
        ValidateQuantity(AssemblyLine, BomQty);

        AssemblyLine.Next();
        ValidateLineResourceTypeUsage(AssemblyLine, AssemblyLine."Resource Usage Type"::Fixed);
        ValidateQuantity(AssemblyLine, BomQty);
        AssemblyLine.Validate("Resource Usage Type", AssemblyLine."Resource Usage Type"::Direct);
        ValidateQuantity(AssemblyLine, BomQty * ParentQty);

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OneResourceFixedChange()
    var
        BOMComp: Record "BOM Component";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        resource: Record Resource;
        Parent: Code[20];
        ParentQty: Decimal;
        BomQty: Decimal;
    begin
        Initialize();
        Parent := LibraryKitting.CreateItemWithLotAndNewUOM(500, 700, 10);
        resource.Get(LibraryKitting.CreateResourceWithNewUOM(100, 0));
        LibraryInventory.CreateBOMComponent(
          BOMComp, Parent, BOMComp.Type::Resource, resource."No.", 5, resource."Base Unit of Measure");
        BOMComp.Validate("Resource Usage Type", BOMComp."Resource Usage Type"::Fixed);
        BOMComp.Modify(true);

        ParentQty := 5;
        BomQty := 5;

        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, Parent, ParentQty));
        AsmLineFindFirst(AssemblyHeader, AssemblyLine);
        ValidateQuantity(AssemblyLine, BomQty);

        AssemblyHeader.Validate(Quantity, 10);
        AssemblyLine.FindFirst();
        ValidateQuantity(AssemblyLine, BomQty);

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeUnitCost()
    var
        AssemblyHeader: Record "Assembly Header";
        BOMComp: Record "BOM Component";
        childItem: Record Item;
        AssemblyLine: Record "Assembly Line";
        parent: Code[20];
        Costprice: Decimal;
    begin
        Initialize();
        parent := LibraryKitting.CreateStdCostItemWithNewUOM(500, 700, 1);
        Costprice := 500;
        childItem.Get(LibraryKitting.CreateItemWithNewUOM(Costprice, 700));
        LibraryInventory.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Item, childItem."No.", 1, childItem."Base Unit of Measure");
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parent, 1));
        validateCount(AssemblyHeader."No.", 1);
        AsmLineFindFirst(AssemblyHeader, AssemblyLine);
        ValidateLineUnitCost(AssemblyLine, Costprice);

        asserterror AssemblyLine.Validate("Unit Cost", 100);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuantityPerline()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        item: Record Item;
        parent: Code[20];
    begin
        Initialize();
        parent := LibraryKitting.CreateStdCostItemWithNewUOM(500, 700, 1);
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parent, 10));
        item.Get(LibraryKitting.CreateItemWithNewUOM(100, 700));
        LibraryAssembly.CreateAssemblyLine(
          AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, item."No.", item."Base Unit of Measure", 20, 1, 'Test QuantityPer ');

        AsmLineFindFirst(AssemblyHeader, AssemblyLine);
        ValidateQuantityPer(AssemblyLine, 1);

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuantityPerlineChange()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        item: Record Item;
        parent: Code[20];
    begin
        Initialize();
        parent := LibraryKitting.CreateStdCostItemWithNewUOM(500, 700, 1);
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parent, 5));
        item.Get(LibraryKitting.CreateItemWithNewUOM(100, 700));
        LibraryKitting.AddLine(AssemblyHeader, "BOM Component Type"::Item, item."No.", item."Base Unit of Measure", 20, 0, 'Test QuantityPer');

        AsmLineFindFirst(AssemblyHeader, AssemblyLine);
        AssemblyLine.Validate("Quantity per", 0);
        ValidateQuantityPer(AssemblyLine, 0); // BUG252757 Change to 0 allowed
        AssemblyLine.Validate("Quantity per", 10);
        ValidateQuantityPer(AssemblyLine, 10);
        ValidateQuantity(AssemblyLine, 5 * 10);

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BUG252757QtyPerInitValue()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        ItemNo: Code[20];
    begin
        Initialize();
        // BUG252757 Qty per on the Assembly Line cannot be set to 0
        ItemNo := LibraryKitting.CreateItemWithNewUOM(100, 700);
        AssemblyHeader.Init();
        AssemblyHeader.Insert(true);
        AssemblyLine.Init();
        AssemblyLine."Document Type" := AssemblyHeader."Document Type";
        AssemblyLine."Document No." := AssemblyHeader."No.";
        AssemblyLine.Type := AssemblyLine.Type::Item;
        AssemblyLine.Validate("No.", ItemNo);

        ValidateQuantityPer(AssemblyLine, 0);

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeUOMHeader()
    var
        AssemblyHeader: Record "Assembly Header";
        Item: Record Item;
        childItem: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        Costprice: Decimal;
        parent: Code[20];
    begin
        Initialize();
        Costprice := 400;
        parent := LibraryKitting.CreateStdCostItemWithNewUOM(Costprice, 700, 1);
        Item.Get(parent);
        Item.Validate("Costing Method", Item."Costing Method"::Average);

        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parent, 5));
        childItem.Get(LibraryKitting.CreateItemWithNewUOM(100, 700));
        LibraryKitting.AddLine(
          AssemblyHeader, "BOM Component Type"::Item, childItem."No.", childItem."Base Unit of Measure", 20, 4, 'Test UOM Header');

        AssemblyHeader.UpdateUnitCost();
        ValidateOrderUnitCost(AssemblyHeader, 400);
        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, 6);
        AssemblyHeader.Validate("Unit of Measure Code", NonBaseUOM.Code);
        AssemblyHeader.UpdateUnitCost();
        ValidateOrderUnitCost(AssemblyHeader, 2400);
        NotificationLifecycleMgt.RecallAllNotifications();

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Bug233632ChangeUOMConsume()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        Costprice: Decimal;
        parent: Code[20];
    begin
        Initialize();
        Costprice := 400;
        parent := LibraryKitting.CreateStdCostItemWithNewUOM(Costprice, 700, 1);
        Item.Get(parent);
        Item.Validate("Costing Method", Item."Costing Method"::Average);
        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, 2);

        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parent, 10));
        Item.Get(LibraryKitting.CreateItemWithNewUOM(100, 700));

        AssemblyHeader.Validate("Quantity to Assemble", 3);
        AssemblyHeader.Validate("Unit of Measure Code", NonBaseUOM.Code);

        LibraryKitting.AddLine(AssemblyHeader, "BOM Component Type"::Item, Item."No.", Item."Base Unit of Measure", 10, 1, 'Test UOM consume');

        LibraryAssembly.SetLinkToLines(AssemblyHeader, AssemblyLine);
        AssemblyLine.FindFirst();
        ValidateQuantityPer(AssemblyLine, 1);
        ValidateQuantityToConsume(AssemblyLine, 10);

        AssemblyHeader.Validate("Quantity to Assemble", 3);

        LibraryAssembly.SetLinkToLines(AssemblyHeader, AssemblyLine);
        AssemblyLine.FindFirst();
        ValidateQuantityPer(AssemblyLine, 1);
        ValidateQuantity(AssemblyLine, 10);
        ValidateQuantityToConsume(AssemblyLine, 3);

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateQuantityPerOrder()
    var
        BOMComp: Record "BOM Component";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        childItem: Record Item;
        parent: Code[20];
        OrderQuantity: Decimal;
        BomQuantity: Decimal;
    begin
        Initialize();
        OrderQuantity := 5;
        BomQuantity := 1;

        parent := LibraryKitting.CreateStdCostItemWithNewUOM(500, 700, 1);
        childItem.Get(LibraryKitting.CreateItemWithNewUOM(100, 700));
        LibraryInventory.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Item, childItem."No.", BomQuantity, childItem."Base Unit of Measure");
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parent, OrderQuantity));

        validateCount(AssemblyHeader."No.", 1);
        AsmLineFindFirst(AssemblyHeader, AssemblyLine);
        ValidateQuantityPer(AssemblyLine, BomQuantity);
        validateQuantityonLines(AssemblyHeader."No.", OrderQuantity * BomQuantity);
        NotificationLifecycleMgt.RecallAllNotifications();

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartiallypostedRefresh()
    var
        AssemblyHeader: Record "Assembly Header";
        BOMComp: Record "BOM Component";
        childItem: Record Item;
        parent: Code[20];
    begin
        Initialize();
        parent := LibraryKitting.CreateStdCostItemWithNewUOM(500, 700, 1);
        childItem.Get(MakeItem());
        LibraryInventory.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Item, childItem."No.", 1, childItem."Base Unit of Measure");
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parent, 4));
        validateCount(AssemblyHeader."No.", 1);
        AssemblyHeader."Remaining Quantity (Base)" := 3;
        AssemblyHeader.Validate(Quantity, 2);
        NotificationLifecycleMgt.RecallAllNotifications();

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuantityToAssemble()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        Initialize();
        AssemblyHeader.Init();
        AssemblyHeader.Quantity := 10;
        AssemblyHeader."Remaining Quantity" := 2;
        AssemblyHeader."Qty. per Unit of Measure" := 1;
        AssemblyHeader.Validate("Quantity to Assemble", 2);

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuantityToAssembleFail()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        Initialize();
        AssemblyHeader.Init();
        AssemblyHeader.Quantity := 10;
        AssemblyHeader."Remaining Quantity" := 2;
        asserterror AssemblyHeader.Validate("Quantity to Assemble", 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateQuantityToConsumeSuccess()
    var
        AssemblyLine: Record "Assembly Line";
    begin
        Initialize();
        AssemblyLine.Init();
        AssemblyLine."Remaining Quantity" := 2;
        AssemblyLine."Qty. per Unit of Measure" := 1;
        AssemblyLine.Validate("Quantity to Consume", 2);

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateQuantityToConsumeFail()
    var
        AssemblyLine: Record "Assembly Line";
    begin
        Initialize();
        AssemblyLine.Init();
        AssemblyLine."Remaining Quantity" := 2;
        asserterror AssemblyLine.Validate("Quantity to Consume", 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorThrownWhenBaseQtyIsRoundedTo0OnAssemblyHeader()
    var
        AssemblyHeader: Record "Assembly Header";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        Initialize();
        NonBaseQtyPerUOM := 3;
        BaseQtyPerUOM := 1;
        QtyRoundingPrecision := 0.1;

        Item.Get(MakeItemWithLot());
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, BaseQtyPerUOM);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();

        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        CreateAssemblyOrderWithoutLines(AssemblyHeader, WorkDate2, Item."No.");
        AssemblyHeader.Validate("Unit of Measure Code", NonBaseUOM.Code);
        asserterror AssemblyHeader.Validate(Quantity, 0.01);
        Assert.ExpectedError(RoundingTo0Err);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorThrownWhenQtyIsRoundedTo0OnAssemblyHeader()
    var
        AssemblyHeader: Record "Assembly Header";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        Initialize();
        NonBaseQtyPerUOM := 3;
        BaseQtyPerUOM := 1;
        QtyRoundingPrecision := 0.1;

        Item.Get(MakeItemWithLot());
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, BaseQtyPerUOM);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();

        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        CreateAssemblyOrderWithoutLines(AssemblyHeader, WorkDate2, Item."No.");
        AssemblyHeader.Validate("Unit of Measure Code", BaseUOM.Code);
        asserterror AssemblyHeader.Validate(Quantity, 0.01);
        Assert.ExpectedError(RoundingErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BaseQtyIsRoundedWithRoundingPrecisionSpecifiedOnAssemblyHeader()
    var
        AssemblyHeader: Record "Assembly Header";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        Initialize();
        NonBaseQtyPerUOM := 3;
        BaseQtyPerUOM := 1;
        QtyRoundingPrecision := 0.1;

        Item.Get(MakeItemWithLot());
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, BaseQtyPerUOM);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();

        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        CreateAssemblyOrderWithoutLines(AssemblyHeader, WorkDate2, Item."No.");
        AssemblyHeader.Validate("Unit of Measure Code", NonBaseUOM.Code);
        AssemblyHeader.Validate(Quantity, 5.67);
        Assert.AreEqual(17.0, AssemblyHeader."Quantity (Base)", 'Base quantity is not rounded correctly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BaseQtyIsRoundedWithRoundingPrecisionUnspecifiedOnAssemblyHeader()
    var
        AssemblyHeader: Record "Assembly Header";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
    begin
        Initialize();
        NonBaseQtyPerUOM := 3;
        BaseQtyPerUOM := 1;

        Item.Get(MakeItemWithLot());
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, BaseQtyPerUOM);
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();

        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        CreateAssemblyOrderWithoutLines(AssemblyHeader, WorkDate2, Item."No.");
        AssemblyHeader.Validate("Unit of Measure Code", NonBaseUOM.Code);
        AssemblyHeader.Validate(Quantity, 5.6666666);
        Assert.AreEqual(17.00001, AssemblyHeader."Quantity (Base)", 'Base qty. is not rounded correctly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BaseQtyIsRoundedWithRoundingPrecisionOnAssemblyHeader()
    var
        AssemblyHeader: Record "Assembly Header";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        Initialize();
        NonBaseQtyPerUOM := 6;
        BaseQtyPerUOM := 1;
        QtyRoundingPrecision := 0.1;

        Item.Get(MakeItemWithLot());
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, BaseQtyPerUOM);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();

        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        CreateAssemblyOrderWithoutLines(AssemblyHeader, WorkDate2, Item."No.");
        AssemblyHeader.Validate("Unit of Measure Code", NonBaseUOM.Code);
        AssemblyHeader.Validate(Quantity, 5 / 6);
        Assert.AreEqual(5, AssemblyHeader."Quantity (Base)", 'Base quantity is not rounded correctly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorThrownWhenBaseQtyToAssembleIsRoundedTo0OnAssemblyHeader()
    var
        AssemblyHeader: Record "Assembly Header";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        Initialize();
        NonBaseQtyPerUOM := 3;
        BaseQtyPerUOM := 1;
        QtyRoundingPrecision := 0.1;

        Item.Get(MakeItemWithLot());
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, BaseQtyPerUOM);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();

        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        CreateAssemblyOrderWithoutLines(AssemblyHeader, WorkDate2, Item."No.");
        AssemblyHeader.Validate("Unit of Measure Code", NonBaseUOM.Code);
        AssemblyHeader.Validate(Quantity, 5);
        asserterror AssemblyHeader.Validate("Quantity to Assemble", 0.01);
        Assert.ExpectedError(RoundingTo0Err);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorThrownWhenQtyToAssembleIsRoundedTo0OnAssemblyHeader()
    var
        AssemblyHeader: Record "Assembly Header";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        Initialize();
        NonBaseQtyPerUOM := 3;
        BaseQtyPerUOM := 1;
        QtyRoundingPrecision := 0.1;

        Item.Get(MakeItemWithLot());
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, BaseQtyPerUOM);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();

        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        CreateAssemblyOrderWithoutLines(AssemblyHeader, WorkDate2, Item."No.");
        AssemblyHeader.Validate("Unit of Measure Code", BaseUOM.Code);
        AssemblyHeader.Validate(Quantity, 5);
        asserterror AssemblyHeader.Validate("Quantity to Assemble", 0.01);
        Assert.ExpectedError(RoundingErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BaseQtyToAssembleIsRoundedWithRoundingPrecisionSpecifiedOnAssemblyHeader()
    var
        AssemblyHeader: Record "Assembly Header";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        Initialize();
        NonBaseQtyPerUOM := 3;
        BaseQtyPerUOM := 1;
        QtyRoundingPrecision := 0.1;

        Item.Get(MakeItemWithLot());
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, BaseQtyPerUOM);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();

        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        CreateAssemblyOrderWithoutLines(AssemblyHeader, WorkDate2, Item."No.");
        AssemblyHeader.Validate("Unit of Measure Code", NonBaseUOM.Code);
        AssemblyHeader.Validate(Quantity, 10);
        AssemblyHeader.Validate("Quantity to Assemble", 5.67);
        Assert.AreEqual(17.0, AssemblyHeader."Quantity to Assemble (Base)", 'Base quantity is not rounded correctly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BaseQtyToAssembleIsRoundedWithRoundingPrecisionOnAssemblyHeader()
    var
        AssemblyHeader: Record "Assembly Header";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        Initialize();
        NonBaseQtyPerUOM := 6;
        BaseQtyPerUOM := 1;
        QtyRoundingPrecision := 0.1;

        Item.Get(MakeItemWithLot());
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, BaseQtyPerUOM);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();

        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        CreateAssemblyOrderWithoutLines(AssemblyHeader, WorkDate2, Item."No.");
        AssemblyHeader.Validate("Unit of Measure Code", NonBaseUOM.Code);
        AssemblyHeader.Validate(Quantity, 1);
        AssemblyHeader.Validate("Quantity to Assemble", 5 / 6);
        Assert.AreEqual(5, AssemblyHeader."Quantity to Assemble (Base)", 'Base quantity is not rounded correctly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorThrownWhenBaseQtyIsRoundedTo0OnAssemblyLine()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        ParentItem: Record Item;
        ChildItem: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        Initialize();
        NonBaseQtyPerUOM := 3;
        BaseQtyPerUOM := 1;
        QtyRoundingPrecision := 0.1;

        ParentItem.Get(MakeItemWithLot());
        ChildItem.Get(MakeItemWithLot());
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, ChildItem."No.", BaseUOM.Code, BaseQtyPerUOM);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        ChildItem.Validate("Base Unit of Measure", ItemUOM.Code);
        ChildItem.Modify();

        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, ChildItem."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, ParentItem."No.", 1));
        LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, ChildItem."No.", NonBaseUOM.Code, 0, 0, '');
        asserterror AssemblyLine.Validate(Quantity, 0.01);
        Assert.ExpectedError(RoundingTo0Err);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorThrownWhenQtyIsRoundedTo0OnAssemblyLine()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        ParentItem: Record Item;
        ChildItem: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        Initialize();
        NonBaseQtyPerUOM := 3;
        BaseQtyPerUOM := 1;
        QtyRoundingPrecision := 0.1;

        ParentItem.Get(MakeItemWithLot());
        ChildItem.Get(MakeItemWithLot());
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, ChildItem."No.", BaseUOM.Code, BaseQtyPerUOM);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        ChildItem.Validate("Base Unit of Measure", ItemUOM.Code);
        ChildItem.Modify();

        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, ChildItem."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, ParentItem."No.", 1));
        LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, ChildItem."No.", BaseUOM.Code, 0, 0, '');
        asserterror AssemblyLine.Validate(Quantity, 0.01);
        Assert.ExpectedError(RoundingErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BaseQtyIsRoundedWithRoundingPrecisionSpecifiedOnAssemblyLine()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        ParentItem: Record Item;
        ChildItem: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        Initialize();
        NonBaseQtyPerUOM := 3;
        BaseQtyPerUOM := 1;
        QtyRoundingPrecision := 0.1;

        ParentItem.Get(MakeItemWithLot());
        ChildItem.Get(MakeItemWithLot());
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, ChildItem."No.", BaseUOM.Code, BaseQtyPerUOM);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        ChildItem.Validate("Base Unit of Measure", ItemUOM.Code);
        ChildItem.Modify();

        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, ChildItem."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, ParentItem."No.", 1));
        LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, ChildItem."No.", NonBaseUOM.Code, 0, 0, '');
        AssemblyLine.Validate("Unit of Measure Code", NonBaseUOM.Code);
        AssemblyLine.Validate(Quantity, 5.67);
        Assert.AreEqual(17.0, AssemblyLine."Quantity (Base)", 'Base quantity is not rounded correctly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BaseQtyIsRoundedWithRoundingPrecisionUnspecifiedOnAssemblyLine()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        ParentItem: Record Item;
        ChildItem: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
    begin
        Initialize();
        NonBaseQtyPerUOM := 3;
        BaseQtyPerUOM := 1;

        ParentItem.Get(MakeItemWithLot());
        ChildItem.Get(MakeItemWithLot());
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, ChildItem."No.", BaseUOM.Code, BaseQtyPerUOM);
        ChildItem.Validate("Base Unit of Measure", ItemUOM.Code);
        ChildItem.Modify();

        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, ChildItem."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, ParentItem."No.", 1));
        LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, ChildItem."No.", NonBaseUOM.Code, 0, 0, '');
        AssemblyLine.Validate("Unit of Measure Code", NonBaseUOM.Code);
        AssemblyLine.Validate(Quantity, 5.6666666);
        Assert.AreEqual(17.00001, AssemblyLine."Quantity (Base)", 'Base qty. is not rounded correctly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BaseQtyIsRoundedWithRoundingPrecisionOnAssemblyLine()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        ParentItem: Record Item;
        ChildItem: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        Initialize();
        NonBaseQtyPerUOM := 6;
        BaseQtyPerUOM := 1;
        QtyRoundingPrecision := 0.1;

        ParentItem.Get(MakeItemWithLot());
        ChildItem.Get(MakeItemWithLot());
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, ChildItem."No.", BaseUOM.Code, BaseQtyPerUOM);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        ChildItem.Validate("Base Unit of Measure", ItemUOM.Code);
        ChildItem.Modify();

        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, ChildItem."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, ParentItem."No.", 1));
        LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, ChildItem."No.", NonBaseUOM.Code, 0, 0, '');
        AssemblyLine.Validate("Unit of Measure Code", NonBaseUOM.Code);
        AssemblyLine.Validate(Quantity, 5 / 6);
        Assert.AreEqual(5, AssemblyLine."Quantity (Base)", 'Base quantity is not rounded correctly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorThrownWhenBaseQtyToConsumeIsRoundedTo0OnAssemblyLine()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        ParentItem: Record Item;
        ChildItem: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        Initialize();
        NonBaseQtyPerUOM := 3;
        BaseQtyPerUOM := 1;
        QtyRoundingPrecision := 0.1;

        ParentItem.Get(MakeItemWithLot());
        ChildItem.Get(MakeItemWithLot());
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, ChildItem."No.", BaseUOM.Code, BaseQtyPerUOM);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        ChildItem.Validate("Base Unit of Measure", ItemUOM.Code);
        ChildItem.Modify();

        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, ChildItem."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, ParentItem."No.", 1));
        LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, ChildItem."No.", NonBaseUOM.Code, 0, 0, '');
        AssemblyLine.Validate("Unit of Measure Code", NonBaseUOM.Code);
        AssemblyLine.Validate(Quantity, 5);
        asserterror AssemblyLine.Validate("Quantity to Consume", 0.01);
        Assert.ExpectedError(RoundingTo0Err);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorThrownWhenQtyToConsumeIsRoundedTo0OnAssemblyLine()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        ParentItem: Record Item;
        ChildItem: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        Initialize();
        NonBaseQtyPerUOM := 3;
        BaseQtyPerUOM := 1;
        QtyRoundingPrecision := 0.1;

        ParentItem.Get(MakeItemWithLot());
        ChildItem.Get(MakeItemWithLot());
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, ChildItem."No.", BaseUOM.Code, BaseQtyPerUOM);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        ChildItem.Validate("Base Unit of Measure", ItemUOM.Code);
        ChildItem.Modify();

        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, ChildItem."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, ParentItem."No.", 1));
        LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, ChildItem."No.", BaseUOM.Code, 0, 0, '');
        AssemblyLine.Validate("Unit of Measure Code", BaseUOM.Code);
        AssemblyLine.Validate(Quantity, 5);
        asserterror AssemblyLine.Validate("Quantity to Consume", 0.01);
        Assert.ExpectedError(RoundingErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BaseQtyToConsumeIsRoundedWithRoundingPrecisionSpecifiedOnAssemblyLine()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        ParentItem: Record Item;
        ChildItem: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        Initialize();
        NonBaseQtyPerUOM := 3;
        BaseQtyPerUOM := 1;
        QtyRoundingPrecision := 0.1;

        ParentItem.Get(MakeItemWithLot());
        ChildItem.Get(MakeItemWithLot());
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, ChildItem."No.", BaseUOM.Code, BaseQtyPerUOM);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        ChildItem.Validate("Base Unit of Measure", ItemUOM.Code);
        ChildItem.Modify();

        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, ChildItem."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, ParentItem."No.", 1));
        LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, ChildItem."No.", NonBaseUOM.Code, 0, 0, '');
        AssemblyLine.Validate("Unit of Measure Code", NonBaseUOM.Code);
        AssemblyLine.Validate(Quantity, 10);
        AssemblyLine.Validate("Quantity to Consume", 5.67);
        Assert.AreEqual(17.0, AssemblyLine."Quantity to Consume (Base)", 'Base quantity is not rounded correctly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BaseQtyToConsumeIsRoundedWithRoundingPrecisionOnAssemblyLine()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        ParentItem: Record Item;
        ChildItem: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        Initialize();
        NonBaseQtyPerUOM := 6;
        BaseQtyPerUOM := 1;
        QtyRoundingPrecision := 0.1;

        ParentItem.Get(MakeItemWithLot());
        ChildItem.Get(MakeItemWithLot());
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, ChildItem."No.", BaseUOM.Code, BaseQtyPerUOM);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        ChildItem.Validate("Base Unit of Measure", ItemUOM.Code);
        ChildItem.Modify();

        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, ChildItem."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, ParentItem."No.", 1));
        LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, ChildItem."No.", NonBaseUOM.Code, 0, 0, '');
        AssemblyLine.Validate("Unit of Measure Code", NonBaseUOM.Code);
        AssemblyLine.Validate(Quantity, 1);
        AssemblyLine.Validate("Quantity to Consume", 5 / 6);
        Assert.AreEqual(5, AssemblyLine."Quantity to Consume (Base)", 'Base quantity is not rounded correctly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssemblyLineQtyToConsumeIsCorrectlyCalculatedWithDifferentUoMforItems()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        ParentItem: Record Item;
        ChildItem: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        Initialize();
        NonBaseQtyPerUOM := 0.001;
        BaseQtyPerUOM := 1;
        QtyRoundingPrecision := 0.00001;

        ParentItem.Get(MakeItemWithLot());
        ChildItem.Get(MakeItemWithLot());
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, ChildItem."No.", BaseUOM.Code, BaseQtyPerUOM);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        ChildItem.Validate("Base Unit of Measure", ItemUOM.Code);
        ChildItem.Modify();

        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, ChildItem."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, ParentItem."No.", 100));
        LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, ChildItem."No.", NonBaseUOM.Code, 0.5, 0.005, '');
        Assert.AreEqual(0.5, AssemblyLine.Quantity, 'Quantity is not calculated correctly.');
        Assert.AreEqual(0.5, AssemblyLine."Quantity to Consume", 'Quantity to Consume is not calculated correctly from Quantity.');
        Assert.AreEqual(0.0005, AssemblyLine."Quantity to Consume (Base)", 'Quantity to Consume (Base) is not calculated correctly from Quantity to Consume.');

        AssemblyHeader.Validate(Quantity, 90);
        AssemblyHeader.Modify();

        AssemblyLine.Get(AssemblyLine.RecordId);
        Assert.AreEqual(0.45, AssemblyLine.Quantity, 'Quantity is not calculated correctly.');
        Assert.AreEqual(0.45, AssemblyLine."Quantity to Consume", 'Quantity to Consume is not calculated correctly from Quantity.');
        Assert.AreEqual(0.00045, AssemblyLine."Quantity to Consume (Base)", 'Quantity to Consume (Base) is not calculated correctly from Quantity to Consume.');
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    local procedure CreatePostedAssemblyHeader(var PostedAsmHeader: Record "Posted Assembly Header"; AssemblyHeader: Record "Assembly Header")
    var
        AssemblySetup: Record "Assembly Setup";
        NoSeries: Codeunit "No. Series";
        PostedAssemblyNos: Code[20];
    begin
        PostedAssemblyNos := LibraryUtility.GetGlobalNoSeriesCode();
        AssemblySetup.Get();
        if AssemblySetup."Posted Assembly Order Nos." <> PostedAssemblyNos then begin
            AssemblySetup."Posted Assembly Order Nos." := PostedAssemblyNos;
            AssemblySetup.Modify();
        end;

        Clear(PostedAsmHeader);
        PostedAsmHeader."No." := NoSeries.GetNextNo(PostedAssemblyNos);
        PostedAsmHeader.TransferFields(AssemblyHeader);
        PostedAsmHeader."Order No." := AssemblyHeader."No.";
        PostedAsmHeader.Insert();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeQuantity()
    var
        AssemblyHeader: Record "Assembly Header";
        BOMComp: Record "BOM Component";
        childItem: Record Item;
        parent: Code[20];
    begin
        Initialize();
        parent := LibraryKitting.CreateStdCostItemWithNewUOM(500, 700, 1);
        childItem.Get(MakeItem());
        LibraryInventory.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Item, childItem."No.", 1, childItem."Base Unit of Measure");
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parent, 1));
        validateCount(AssemblyHeader."No.", 1);
        AssemblyHeader.Validate(Quantity, 2);
        validateCount(AssemblyHeader."No.", 1);
        validateQuantityonLines(AssemblyHeader."No.", 2);
        NotificationLifecycleMgt.RecallAllNotifications();

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ZeroQuantity()
    var
        AssemblyHeader: Record "Assembly Header";
        BOMComp: Record "BOM Component";
        childItem: Record Item;
        parent: Code[20];
    begin
        Initialize();
        parent := LibraryKitting.CreateStdCostItemWithNewUOM(500, 700, 1);
        childItem.Get(MakeItem());
        LibraryInventory.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Item, childItem."No.", 1, childItem."Base Unit of Measure");
        CreateAssemblyOrderWithoutLines(AssemblyHeader, WorkDate2, parent);
        validateCount(AssemblyHeader."No.", 0);

        asserterror Error('') // roll back
    end;

    [Test]
    procedure AssembleToOrderSetsLocationForNonInventoryItem()
    var
        AssemblyItem: Record Item;
        NonInventoryItem: Record Item;
        Location: Record Location;
        BOMComponent: Record "BOM Component";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ATOLink: Record "Assemble-to-Order Link";
        AssemblyLine: Record "Assembly Line";
    begin
        // [SCENARIO] When using assemble-to-order for an assembly item containing non-inventory items in its BOM,
        // the location code is set for the generated assembly lines.
        Initialize();

        // [GIVEN] an assemble-to-order item with an assembly BOM containing a non-inventory item.
        LibraryInventory.CreateItem(AssemblyItem);
        AssemblyItem.Validate("Replenishment System", AssemblyItem."Replenishment System"::Assembly);
        AssemblyItem.Validate("Assembly Policy", AssemblyItem."Assembly Policy"::"Assemble-to-Order");
        AssemblyItem.Modify(true);

        LibraryInventory.CreateNonInventoryTypeItem(NonInventoryItem);

        LibraryAssembly.CreateAssemblyListComponent(
            "BOM Component Type"::Item, NonInventoryItem."No.", AssemblyItem."No.", '',
            BOMComponent."Resource Usage Type", 1, true);

        // [GIVEN] A location requiring pick & shipment.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, true);

        // [WHEN] Creating a sales order containing the assembly item.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Shipment Date", CalcDate('<+1W>', WorkDate()));
        SalesHeader.Validate("Location Code", Location.Code);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, AssemblyItem."No.", 1);

        // [THEN] An assembly order is automatically created.
        Assert.IsTrue(ATOLink.AsmExistsForSalesLine(SalesLine), 'Expected Assemble-to-Order link to be created');

        // [THEN] The location code is set for the non-inventory item.
        AssemblyLine.SetRange("Document Type", ATOLink."Assembly Document Type");
        AssemblyLine.SetRange("Document No.", ATOLink."Assembly Document No.");
        AssemblyLine.SetRange("No.", NonInventoryItem."No.");
        AssemblyLine.FindFirst();
        Assert.AreEqual(AssemblyLine."Location Code", Location.Code, 'Expected location to be set.');
        Assert.AreEqual(AssemblyLine.Quantity, 1, 'Expected quantity to be 1.');
    end;

    [Test]
    procedure DoNotRefreshLinesWhenAssemblyOrderIsReleased()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyOrder: TestPage "Assembly Order";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 445426] Do not allow to refresh lines when the assembly order is released.
        Initialize();

        AssemblyHeader.Init();
        AssemblyHeader."Document Type" := "Assembly Document Type"::Order;
        AssemblyHeader."No." := LibraryUtility.GenerateGUID();
        AssemblyHeader.Status := AssemblyHeader.Status::Released;
        AssemblyHeader.Insert();

        AssemblyOrder.OpenEdit();
        AssemblyOrder.Filter.SetFilter("No.", AssemblyHeader."No.");
        asserterror AssemblyOrder."Refresh Lines".Invoke();

        Assert.ExpectedTestFieldError(AssemblyHeader.FieldCaption(Status), Format(AssemblyHeader.Status::Open));
    end;

    [Test]
    [HandlerFunctions('ConfirmUpdateDimensionOnLines')]
    procedure VerifyDimensionsAreUpdatedOnAssemblyLinesOnChangeDimensionOnHeader()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLineItem: Record "Assembly Line";
        CompItem: Record Item;
        AsmItem: Record Item;
        AssemblyOrder: TestPage "Assembly Order";
        GlobalDim1Value: Code[20];
    begin
        // [SCENARIO 454705] Verify Dimensions are update on assembly lines when we change dimension on assembly header
        // [GIVEN]
        Initialize();

        // [GIVEN] Create Assembly and Component Item
        LibraryInventory.CreateItem(CompItem);
        LibraryInventory.CreateItem(AsmItem);

        // [GIVEN] New Dimension Value for Global Dimension 1
        CreateGlobalDimValues(GlobalDim1Value);

        // [GIVEN] Create Assembly Order 
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate2, AsmItem."No.", '', 1, '');
        CreateAssemblyOrderLine(
          AssemblyHeader, AssemblyLineItem, "BOM Component Type"::Item, CompItem."No.", 1, CompItem."Base Unit of Measure");

        // [WHEN] Open create Assembly Order and Update Dimension
        OpenAssemblyOrderAndUpdateDimension(AssemblyOrder, AssemblyHeader, GlobalDim1Value);

        // [THEN] Verify dimension is updated on Line
        VerifyDimensionOnLine(AssemblyHeader);
    end;

    [Test]
    [HandlerFunctions('ConfirmLocationChange')]
    procedure VerifyDimensionsAreNotReInitializedIfDefaultDimensionDoesntExist()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLineItem: Record "Assembly Line";
        CompItem: Record Item;
        AsmItem: Record Item;
        Location: Record Location;
        DimensionValue: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        AssemblyOrder: TestPage "Assembly Order";
    begin
        // [SCENARIO 455039] Verify dimensions are not re-initialized on validate field if default dimensions does not exist
        // [GIVEN]
        Initialize();

        // [GIVEN] Create Assembly and Component Item        
        LibraryInventory.CreateItem(CompItem);
        LibraryInventory.CreateItem(AsmItem);

        // [GIVEN] Add Default Dimension on Assembly Item
        AddDefaultDimensionToAssemblyItem(AsmItem, DimensionValue);

        // [GIVEN] Create Location without Default Dimension
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Create Assembly Order 
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate2, AsmItem."No.", '', 1, '');
        CreateAssemblyOrderLine(
          AssemblyHeader, AssemblyLineItem, "BOM Component Type"::Item, CompItem."No.", 1, CompItem."Base Unit of Measure");

        // [GIVEN] Update global dimension 1 on Assembly Line
        UpdateGlobalDimensionOnAssemblyLine(AssemblyLineItem, DimensionValue2);

        // [WHEN] Change Location on Assembly Line
        // [HANDLERS] ConfirmLocationChange
        UpdateLocationOnAssemblyOrderLine(AssemblyOrder, AssemblyHeader, Location.Code);

        // [THEN] Verify dimension is not changed on Line
        VerifyDimensionIsNotReInitializedOnLine(AssemblyLineItem, DimensionValue2);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    procedure VerifyPostAssemblyOrderForComponentItemWithAdditionalUoM()
    var
        CompItem: Record Item;
        AsmItem: Record Item;
        NonBaseUOM: Record "Unit of Measure";
        ItemUOM: Record "Item Unit of Measure";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
    begin
        // [SCENARIO 463373] Verify Post Assembly Order for Component Item with Additional Unit of Measure 
        Initialize();

        // [GIVEN] Create Assembly and Component Item
        LibraryInventory.CreateItem(CompItem);
        LibraryInventory.CreateItem(AsmItem);

        // [GIVEN] Create additional UoM for Component Item
        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, CompItem."No.", NonBaseUOM.Code, 0.001);

        // [GIVEN] Value required for Inventory
        CreateAndPostItemJournalLine(CompItem."No.", 1000, '');

        // [GIVEN] Create Assembly Order 
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate2, AsmItem."No.", '', 570, '');
        LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, CompItem."No.", NonBaseUOM.Code, 197900.0043, 0, '');

        // [WHEN] Update Quantity to Consume on Assembly Line
        OpenAssemblyOrderAndUpdateQuantityToConsume(AssemblyHeader, 197900);

        // [THEN] Post Assembly Order
        AssemblyHeader.Get(AssemblyHeader."Document Type", AssemblyHeader."No.");
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');
    end;

    [Test]
    procedure VerifyDefaultDimensionsOnlyHasItemsDefaultDimensions()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLineItem: Record "Assembly Line";
        CompItem: Record Item;
        AsmItem: Record Item;
        Location: Record Location;
        DimensionValue: array[2] of Record "Dimension Value";
    begin
        // [SCENARIO 491902] Dimension Value Code in Location Dimensions Overrides the Product Specific Dimension in the Assembly Order.
        Initialize();

        // [GIVEN] Create Assembly and Component Item
        LibraryInventory.CreateItem(AsmItem);
        LibraryInventory.CreateItem(CompItem);

        // [GIVEN] Add Default Dimension on Assembly and Component Item 
        AddDefaultDimensionToAssemblyItem(AsmItem, DimensionValue[1]);
        AddDefaultDimensionToAssemblyItem(CompItem, DimensionValue[2]);

        // // [GIVEN] Create Location without Default Dimension
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Create Assembly Order 
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate2, AsmItem."No.", '', 1, '');
        CreateAssemblyOrderLine(AssemblyHeader, AssemblyLineItem, "BOM Component Type"::Item, CompItem."No.", 1, CompItem."Base Unit of Measure");

        // [VERIFY] Verify: Default Dimension of Assembly Header should not filled on Assembly Line Default Dimension
        VerifyAssemblyHeaderDimensionNotExistsOnAssemblyLine(AssemblyLineItem."Dimension Set ID", DimensionValue[1]);

        // [THEN] Verify: Default Dimension on Assembly Line is filled with Component Item Default Dimension
        VerifyDimensionIsNotReInitializedOnLine(AssemblyLineItem, DimensionValue[2]);
        VerifyDimensionValue(AssemblyLineItem."Dimension Set ID", DimensionValue[2]);
    end;

    [Test]
    procedure VerifyDefaultDimensionsOnlyHasItemAndLocationDimensions()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLineItem: Record "Assembly Line";
        CompItem: Record Item;
        AsmItem: Record Item;
        Location: Record Location;
        DefaultDimension: Record "Default Dimension";
        DimensionValue: array[3] of Record "Dimension Value";
    begin
        // [SCENARIO 491902] Dimension Value Code in Location Dimensions Overrides the Product Specific Dimension in the Assembly Order.
        Initialize();

        // [GIVEN] Create Assembly and Component Item        
        LibraryInventory.CreateItem(AsmItem);
        LibraryInventory.CreateItem(CompItem);

        // [GIVEN] Add Default Dimension on Assembly Item
        AddDefaultDimensionToAssemblyItem(AsmItem, DimensionValue[1]);
        AddDefaultDimensionToAssemblyItem(CompItem, DimensionValue[2]);

        // [GIVEN] Create Dimension Value for Global Dimension 2
        LibraryDimension.CreateDimensionValue(DimensionValue[3], LibraryERM.GetGlobalDimensionCode(2));

        // [GIVEN] Create Location with default dimension
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryDimension.CreateDefaultDimension(
            DefaultDimension, Database::Location, Location.Code, DimensionValue[3]."Dimension Code", DimensionValue[3].Code);
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
        DefaultDimension.Modify(true);

        // [GIVEN] Create Assembly Order 
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate2, AsmItem."No.", '', 1, '');
        CreateAssemblyOrderLine(AssemblyHeader, AssemblyLineItem, "BOM Component Type"::Item, CompItem."No.", 1, CompItem."Base Unit of Measure");

        // [WHEN] Change Location on Assembly Line
        AssemblyLineItem.Validate("Location Code", Location.Code);

        // [VERIFY] Verify: Default Dimension of Assembly Header should not filled on Assembly Line Default Dimension
        VerifyAssemblyHeaderDimensionNotExistsOnAssemblyLine(AssemblyLineItem."Dimension Set ID", DimensionValue[1]);

        // [THEN] Verify: Default Dimension on Assembly Line is filled with Component Item and Location Default Dimension
        VerifyDimensionValue(AssemblyLineItem."Dimension Set ID", DimensionValue[2]);
        VerifyDimensionValue(AssemblyLineItem."Dimension Set ID", DimensionValue[3]);
    end;

    [Test]
    procedure QtyToConsumeUpdatedAfterPartialPostingWithRounding()
    var
        ComponentItem: Record Item;
        AssemblyItem: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        QtyPerParentItem: Decimal;
        OrderQty: Decimal;
        QtyToAssemble: Decimal;
    begin
        // [SCENARIO] "Qty. to Consume" in assembly order is updated after partial posting when its value exceeds the remaining quantity due to rounding error

        Initialize();

        QtyPerParentItem := 38.19715;
        OrderQty := 3.08;
        QtyToAssemble := 0.77;

        // [GIVEN] Component item "COMPONENT" and an assembly item "ASM"
        LibraryInventory.CreateItem(ComponentItem);
        LibraryInventory.CreateItem(AssemblyItem);

        // [GIVEN] Create an assembly BOM for the item "ASM", including the "COMPONENT", set "Qty. per" = 38.19715
        LibraryAssembly.CreateAssemblyListComponent(Enum::"BOM Component Type"::Item, ComponentItem."No.", AssemblyItem."No.", '', 0, QtyPerParentItem, true);

        // [GIVEN] Post positive adjustment of 120 pcs of the "COMPONENT" item (quantity sufficient to cover the assembly demand) 
        CreateAndPostItemJournalLine(ComponentItem."No.", Round(QtyPerParentItem * OrderQty, 1, '>'), '');

        // [GIVEN] Create an assembly order for the "ASM" item, set Quantity = 3.08 and "Qty. to Assemble" = 0.77
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, CalcDate('<1M>', WorkDate()), AssemblyItem."No.", '', OrderQty, '');
        AssemblyHeader.Validate("Quantity to Assemble", QtyToAssemble);
        AssemblyHeader.Modify(true);

        // [WHEN] Post the assembly order
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        // [THEN] "Qty. to Consume" in the assembly line is updated to 88.23541, which is equal to the remaining quantity
        FindAssemblyLine(AssemblyLine, AssemblyHeader."No.");
        Assert.AreEqual(AssemblyLine."Remaining Quantity", AssemblyLine."Quantity to Consume", QtyToConsumeMustBeUpdatedErr);
    end;

    local procedure FindAssemblyLine(var AssemblyLine: Record "Assembly Line"; AssemblyOrderNo: Code[20])
    begin
        AssemblyLine.SetRange("Document Type", Enum::"Assembly Document Type"::Order);
        AssemblyLine.SetRange("Document No.", AssemblyOrderNo);
        AssemblyLine.FindFirst();
    end;

    local procedure VerifyAssemblyHeaderDimensionNotExistsOnAssemblyLine(DimensionSetID: Integer; DimensionValue: Record "Dimension Value")
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        DimensionSetEntry.SetRange("Dimension Set ID", DimensionSetID);
        DimensionSetEntry.SetRange("Dimension Code", DimensionValue."Dimension Code");
        Assert.RecordIsNotEmpty(DimensionSetEntry);
    end;

    local procedure VerifyDimensionValue(DimensionSetID: Integer; DimensionValue: Record "Dimension Value")
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        DimensionSetEntry.SetRange("Dimension Set ID", DimensionSetID);
        DimensionSetEntry.SetRange("Dimension Code", DimensionValue."Dimension Code");
        DimensionSetEntry.FindFirst();
        Assert.AreEqual(DimensionValue.Code, DimensionSetEntry."Dimension Value Code", NotMatchingDimensionsMsg);
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; Quantity: Decimal; VariantCode: Code[10])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryAssembly.SetupItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        ItemJournalLine.Validate("Variant Code", VariantCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure OpenAssemblyOrderAndUpdateQuantityToConsume(AssemblyHeader: Record "Assembly Header"; QuantityToConsume: Decimal)
    var
        AssemblyOrder: TestPage "Assembly Order";
    begin
        AssemblyOrder.OpenEdit();
        AssemblyOrder.GoToKey(AssemblyHeader."Document Type"::Order, AssemblyHeader."No.");
        AssemblyOrder.Lines."Quantity to Consume".SetValue(QuantityToConsume);
        AssemblyOrder.Close();
    end;

    local procedure VerifyDimensionIsNotReInitializedOnLine(var AssemblyLine: Record "Assembly Line"; var DimensionValue: Record "Dimension Value")
    begin
        AssemblyLine.Get(AssemblyLine."Document Type", AssemblyLine."Document No.", AssemblyLine."Line No.");
        Assert.IsTrue(AssemblyLine."Shortcut Dimension 1 Code" = DimensionValue.Code, NotMatchingDimensionsMsg);
    end;

    local procedure AddDefaultDimensionToAssemblyItem(var AsmItem: Record Item; var DimensionValue: Record "Dimension Value")
    var
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.CreateDimensionValue(DimensionValue, LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDefaultDimensionItem(
          DefaultDimension, AsmItem."No.", DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure UpdateGlobalDimensionOnAssemblyLine(var AssemblyLineItem: Record "Assembly Line"; var DimensionValue: Record "Dimension Value")
    begin
        LibraryDimension.CreateDimensionValue(DimensionValue, LibraryERM.GetGlobalDimensionCode(1));
        AssemblyLineItem.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);
        AssemblyLineItem.Modify(true);
    end;

    local procedure UpdateLocationOnAssemblyOrderLine(var AssemblyOrder: TestPage "Assembly Order"; var AssemblyHeader: Record "Assembly Header"; LocationCode: Code[10])
    begin
        AssemblyOrder.OpenEdit();
        AssemblyOrder.GoToRecord(AssemblyHeader);
        AssemblyOrder."Location Code".SetValue(LocationCode);
        AssemblyOrder.Close();
    end;

    local procedure VerifyDimensionOnLine(var AssemblyHeader: Record "Assembly Header")
    var
        AssemblyLine: Record "Assembly Line";
    begin
        AssemblyHeader.Get(AssemblyHeader."Document Type", AssemblyHeader."No.");
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.FindFirst();
        Assert.IsTrue(AssemblyLine."Shortcut Dimension 1 Code" = AssemblyHeader."Shortcut Dimension 1 Code", NotMatchingDimensionsMsg);
    end;

    local procedure CreateGlobalDimValues(var GlobalDim1Value: Code[20])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionValue: Record "Dimension Value";
    begin
        GeneralLedgerSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 1 Code");
        GlobalDim1Value := DimensionValue.Code;
    end;

    local procedure OpenAssemblyOrderAndUpdateDimension(var AssemblyOrder: TestPage "Assembly Order"; var AssemblyHeader: Record "Assembly Header"; GlobalDim1Value: Code[20])
    begin
        AssemblyOrder.OpenEdit();
        AssemblyOrder.GoToRecord(AssemblyHeader);
        AssemblyOrder."Shortcut Dimension 1 Code".SetValue(GlobalDim1Value);
        AssemblyOrder.Close();
    end;

    local procedure CreateAssemblyOrderLine(AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line"; Type: Enum "BOM Component Type"; No: Code[20]; Quantity: Decimal; UoM: Code[10])
    var
        RecRef: RecordRef;
    begin
        if No <> '' then begin
            LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine, Type, No, UoM, Quantity, 1, '');
            exit;
        end;
        Clear(AssemblyLine);
        AssemblyLine."Document Type" := AssemblyHeader."Document Type";
        AssemblyLine."Document No." := AssemblyHeader."No.";
        RecRef.GetTable(AssemblyLine);
        AssemblyLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, AssemblyLine.FieldNo("Line No.")));
        AssemblyLine.Insert(true);
        AssemblyLine.Validate(Type, Type);
        AssemblyLine.Modify(true);
    end;

    local procedure ValidateLineUnitCost(AssemblyLine: Record "Assembly Line"; ExpectedCost: Decimal)
    begin
        Assert.AreEqual(AssemblyLine."Unit Cost", ExpectedCost,
          StrSubstNo('Bad Unit Cost of Assembly Line %1 Expected %2, got %3',
            AssemblyLine."Document No.",
            ExpectedCost,
            AssemblyLine."Unit Cost"));
    end;

    local procedure ValidateOrderUnitCost(AssemblyHeader: Record "Assembly Header"; ExpectedCost: Decimal)
    begin
        Assert.AreEqual(AssemblyHeader."Unit Cost", ExpectedCost,
          StrSubstNo('Bad Unit Cost of Assembly Order %1 Expected %2, got %3',
            AssemblyHeader."No.",
            ExpectedCost,
            AssemblyHeader."Unit Cost"));
    end;

    local procedure ValidateLineResourceTypeUsage(AssemblyLine: Record "Assembly Line"; ExpectedUsageType: Integer)
    var
        Value: Integer;
    begin
        Value := AssemblyLine."Resource Usage Type";
        Assert.AreEqual(Value, ExpectedUsageType,
          StrSubstNo('Bad Resource Usage Type in Assembly line %1 Expected %2 got %3',
            AssemblyLine."Document No.",
            ExpectedUsageType,
            Value));
    end;

    [Normal]
    local procedure validateCount(OrderNo: Code[20]; "Count": Integer)
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, OrderNo);
        Assert.AreEqual(Count, LibraryAssembly.LineCount(AssemblyHeader),
          StrSubstNo(AssertLineCountErr, OrderNo, Count, LibraryAssembly.LineCount(AssemblyHeader)));
    end;

    [Normal]
    local procedure validateDeleted(AsmHeader: Record "Assembly Header"; "Count": Integer)
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        Assert.IsFalse(AssemblyHeader.Get(AsmHeader."Document Type"::Order, AsmHeader."No."),
          StrSubstNo('Order %1 Existed', AsmHeader."No."));

        Assert.AreEqual(LibraryAssembly.LineCount(AssemblyHeader), Count,
          StrSubstNo(AssertLineCountErr, AsmHeader."No.", Count, LibraryAssembly.LineCount(AssemblyHeader)))
    end;

    [Normal]
    local procedure validateQuantityonLines(OrderNo: Code[20]; "Count": Integer)
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, OrderNo);
        Assert.AreEqual(Count, LibraryKitting.TotalQuantity(AssemblyHeader),
          StrSubstNo('Bad Line Quantity of Order: %1 expected %2, got %3', OrderNo, Count, LibraryKitting.TotalQuantity(AssemblyHeader)));
    end;

    local procedure ValidateQuantityPer(AsmLine: Record "Assembly Line"; ValidQuantity: Decimal)
    begin
        Assert.AreEqual(ValidQuantity, AsmLine."Quantity per", 'Bad Quantity Per');
    end;

    local procedure ValidateQuantity(AsmLine: Record "Assembly Line"; ValidQuantity: Decimal)
    begin
        Assert.AreEqual(AsmLine.Quantity, ValidQuantity,
          StrSubstNo('Bad Quantity : expected %1 got %2', ValidQuantity, AsmLine.Quantity))
    end;

    local procedure ValidateQuantityToConsume(AsmLine: Record "Assembly Line"; Expected: Decimal)
    begin
        Assert.AreEqual(AsmLine."Quantity to Consume", Expected,
          StrSubstNo('Bad Quantity to Consume: expected %1 got %2', Expected, AsmLine."Quantity to Consume"))
    end;

    local procedure ValidateTotalQuantityToConsume(AsmHeader: Record "Assembly Header"; Expected: Decimal)
    var
        Actual: Decimal;
    begin
        Actual := TotalToConsume(AsmHeader);
        Assert.AreEqual(Expected, Actual,
          StrSubstNo('Bad Total Quantity to Consume: expected %1 got %2', Expected, Actual))
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmItemChange(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmLocationChange(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    local procedure TotalToConsume(AsmHeader: Record "Assembly Header"): Decimal
    var
        AsmLine: Record "Assembly Line";
        TempCount: Decimal;
    begin
        LibraryAssembly.SetLinkToLines(AsmHeader, AsmLine);
        TempCount := 0;
        if AsmLine.FindSet() then
            repeat
                TempCount += AsmLine."Quantity to Consume";
            until AsmLine.Next() <= 0;
        exit(TempCount);
    end;

    local procedure MakeItem(): Code[20]
    begin
        exit(LibraryKitting.CreateItemWithLotAndNewUOM(500, 700, 1));
    end;

    local procedure MakeItemWithLot(): Code[20]
    begin
        exit(LibraryKitting.CreateItemWithLotAndNewUOM(500, 700, 1));
    end;

    local procedure AsmLineFindFirst(AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line")
    begin
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.FindFirst();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSTF289825()
    var
        Item: Record Item;
        AsmLine: Record "Assembly Line";
    begin
        // SETUP
        Initialize();
        LibraryInventory.CreateItem(Item);

        // Create a blank asm line with Type blank to trigger the code
        AsmLine.Init();
        AsmLine.Type := AsmLine.Type::" ";

        // EXERCISE
        asserterror AsmLine.Validate("Quantity per", 1);

        // VERIFY
        Assert.IsTrue(StrPos(GetLastErrorText, QtyPerNoChangeErr) > 0, GetLastErrorText);
        ClearLastError();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSTF294294()
    var
        Item: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        AsmHeader: Record "Assembly Header";
        WhseEntry: Record "Warehouse Entry";
        WhseEntry2: Record "Warehouse Entry";
        PostedAsmHeader: Record "Posted Assembly Header";
        UndoPostingManagement: Codeunit "Undo Posting Management";
    begin
        // SETUP
        Initialize();
        LibraryInventory.CreateItem(Item);

        LibraryWarehouse.CreateLocation(Location);
        Location."Bin Mandatory" := true;
        Location.Modify();

        LibraryWarehouse.CreateBin(Bin, Location.Code, '', '', '');
        Bin.Validate(Dedicated, true);
        Bin.Modify();

        LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', Bin.Code, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Dedicated := Bin.Dedicated;
        BinContent.Modify();

        // Simulate posting
        LibraryAssembly.CreateAssemblyHeader(AsmHeader, WorkDate(), Item."No.", Location.Code, LibraryRandom.RandInt(10), '');
        AsmHeader."Bin Code" := Bin.Code;

        WhseEntry2.FindLast();
        WhseEntry.Init();
        WhseEntry."Entry No." := WhseEntry2."Entry No." + 1;
        WhseEntry."Source Type" := DATABASE::"Assembly Header";
        WhseEntry."Source Subtype" := AsmHeader."Document Type".AsInteger();
        WhseEntry."Source No." := AsmHeader."No.";
        WhseEntry."Source Line No." := 0;
        WhseEntry."Location Code" := AsmHeader."Location Code";
        WhseEntry."Item No." := AsmHeader."Item No.";
        WhseEntry."Unit of Measure Code" := AsmHeader."Unit of Measure Code";
        WhseEntry."Bin Code" := AsmHeader."Bin Code";
        WhseEntry."Qty. (Base)" := AsmHeader."Quantity (Base)";
        WhseEntry.Insert();

        CreatePostedAssemblyHeader(PostedAsmHeader, AsmHeader);

        // EXERCISE
        UndoPostingManagement.TestAsmHeader(PostedAsmHeader);

        // VERIFY
        // no error has occured

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('MessageHandler')]
    procedure RoundingPrecisioninItemQuantityOnAssembelyOrder()
    var
        NonBaseUOM: Record "Unit of Measure";
        Item: Record Item;
        Item2: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        BOMComponent: Record "BOM Component";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        ExpectedQuantity: Decimal;
        MustMatchTxt: Text;
    begin
        // [SCENARIO 487935] Issue in rounding precision in the item quantity when creating Assembly orders. 
        Initialize();

        // [GIVEN] Create an UOM.
        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);

        // [GIVEN] Create a Item and assign Qty Rounding Precision 1.
        LibraryInventory.CreateItem(Item);
        ItemUOM.Get(Item."No.", Item."Base Unit of Measure");
        ItemUOM.Validate("Qty. Rounding Precision", 1);
        ItemUOM.Modify();

        // [GIVEN] Create another Item.
        LibraryInventory.CreateItem(Item2);

        // [GIVEN] Create Bom Component.
        LibraryInventory.CreateBOMComponent(
            BOMComponent,
            Item2."No.",
            BOMComponent.Type::Item,
            Item."No.",
            LibraryRandom.RandDec(0, 1),
            Item."Base Unit of Measure");

        //[GIVEN] Create an Assembly Header Without Line.
        CreateAssemblyOrderWithoutLines(AssemblyHeader, WorkDate(), Item2."No.");

        // [GIVEN] Validate the quantity on Assembly Order
        AssemblyHeader.Validate(Quantity, LibraryRandom.RandDec(100, 2));
        AssemblyHeader.Modify(true);

        FindAssemblyLine(AssemblyHeader, AssemblyLine);
        FindItemUnitOfMeasure(Item, ItemUOM);

        // [THEN] Calculate Expected Assembly Order Quantity.
        ExpectedQuantity := CalculateAssemblyLineQty(AssemblyHeader, BOMComponent, ItemUOM);

        // [THEN]  Calculate Expected Text.
        MustMatchTxt := MatchTxt(AssemblyLine, ExpectedQuantity);

        // [VERIFY] Assembly Line Quantity when Rounding Precision was not 0.
        Assert.AreEqual(ExpectedQuantity, AssemblyLine.Quantity, MustMatchTxt);

        // [GIVEN] Change the quantity on Assembly Header.
        AssemblyHeader.Validate(Quantity, LibraryRandom.RandDec(500, 4));
        AssemblyHeader.Modify(true);

        FindAssemblyLine(AssemblyHeader, AssemblyLine);
        FindItemUnitOfMeasure(Item, ItemUOM);

        // [THEN] Calculate Expected Assembly Order Quantity.
        ExpectedQuantity := CalculateAssemblyLineQty(AssemblyHeader, BOMComponent, ItemUOM);

        // [THEN]  Calculate Expected Text.
        MustMatchTxt := MatchTxt(AssemblyLine, ExpectedQuantity);

        // [VERIFY] Assembly Line Quantity when Rounding Precision was not 0.
        Assert.AreEqual(ExpectedQuantity, AssemblyLine.Quantity, MustMatchTxt);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure GrossRequirementIsCorrectlyCalculatedWithDifferentUoMRForItems()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        ParentItem: Record Item;
        ChildItem: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        BaseQtyPerUOM: Decimal;
        NonBaseQtyPerUOM: Decimal;
    begin
        // [SCENARIO 547904] Gross Component quantity showing correct value when Assembly component item has Item UOM other than Base UOM
        Initialize();

        // [GIVEN] Assign Non Base Qty and Base Qty Per UOM
        NonBaseQtyPerUOM := 0.4329;
        BaseQtyPerUOM := 1;

        // [GIVEN] Create Assembly order Parent item and child item
        ParentItem.Get(MakeItemWithLot());
        ChildItem.Get(MakeItemWithLot());

        // [GIVEN] Create  Unit of Measure code
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);

        // [GIVEN] Create Item UOM for Child Item
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, ChildItem."No.", BaseUOM.Code, BaseQtyPerUOM);
        ChildItem.Validate("Base Unit of Measure", ItemUOM.Code);
        ChildItem.Modify();

        // [GIVEN] Create Non BAse UOM and Item UOM
        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, ChildItem."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        // [WHEN] Create Assembly order
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, ParentItem."No.", 1));
        LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, ChildItem."No.", NonBaseUOM.Code, 1, 1, '');

        // [THEN] Open Show Availability page and verify Gross requirement on page
        OpenAssemblyAvailabilityPage(AssemblyHeader."No.");
    end;

    [Test]
    procedure ChangeComponentItemToNonInventoryClearBinCode()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        Location: Record Location;
        Bin: Record Bin;
        ChildItemInventoriable, ChildItemNonInventoriable : Record Item;
        Parent: Code[20];
    begin
        // [SCENARIO 1022] Changing the Component Item to Non-Inventory Item should clear Bin Code 
        Initialize();

        // [GIVEN] Parent Item
        Parent := MakeItemWithLot();

        // [GIVEN] Inventoriable Child Item
        ChildItemInventoriable.Get(MakeItem());

        // [GIVEN] Non-Inventoriable Child Item
        ChildItemNonInventoriable.Get(MakeItem());
        ChildItemNonInventoriable.Validate("Inventory Posting Group", '');
        ChildItemNonInventoriable.Validate(Type, ChildItemNonInventoriable.Type::"Non-Inventory");
        ChildItemNonInventoriable.Modify(false);

        // [GIVEN] Location with Bin Codes and default Assembly To-Bin Code
        LibraryWarehouse.CreateLocationWMS(Location, true, false, true, false, false);
        LibraryWarehouse.CreateBin(Bin, Location.Code, '', '', '');
        Location.Validate("To-Assembly Bin Code", Bin.Code);
        Location.Modify(false);

        // [GIVEN] Assembly Order with one inventoriable Item line on a Location with Bins 
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, Parent, 1));
        AssemblyHeader.Validate("Location Code", Location.Code);
        AssemblyHeader.Modify(true);

        // [WHEN] Create an Assembly Line for an inventoriable Item
        CreateAssemblyOrderLine(AssemblyHeader, AssemblyLine, Enum::"BOM Component Type"::Item, ChildItemInventoriable."No.", 1, ChildItemInventoriable."Base Unit of Measure");

        // [THEN] Location + Bin Code is filled
        Assert.Equal(Location.Code, AssemblyLine."Location Code");
        Assert.Equal(Location."To-Assembly Bin Code", AssemblyLine."Bin Code");

        // [WHEN] Changing the Item No. to Non-Inventoriable Item
        AssemblyLine.Validate("No.", ChildItemNonInventoriable."No.");
        AssemblyLine.Modify(false);

        // [THEN] Location and Bin Code should be empty
        Assert.Equal('', AssemblyLine."Location Code");
        Assert.Equal('', AssemblyLine."Bin Code");
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('MessageHandler')]
    procedure RoundingBaseUOMItemQuantityOnAssemblyOrder()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        BOMComponent: Record "BOM Component";
        CompItem: array[2] of Record Item;
        Item2: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        UOMMgt: Codeunit "Unit of Measure Management";
        CompItemQtyPer: array[2] of Decimal;
        ExpectedQuantity: Decimal;
        MustMatchTxt: Text;
    begin
        // [SCENARIO 563279] Rounding of Base UOM correct in Assembly order 
        Initialize();

        // [GIVEN] Create an UOM.
        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);

        // [GIVEN] Create two QtyPer with decimal quantity per, one is less than 0.5 and another is more than 0.5
        CompItemQtyPer[1] := LibraryRandom.RandDecInDecimalRange(0.1, 0.5, 2);
        CompItemQtyPer[2] := LibraryRandom.RandDecInDecimalRange(0.5, 0.9, 2);

        // [GIVEN] Create two Component Items with Replenishment System Purchase and rounding precision 1
        CreateItemWithRoundingPrecision(CompItem[1], CompItem[1]."Replenishment System"::Purchase, 1, 0.01);
        CreateItemWithRoundingPrecision(CompItem[2], CompItem[2]."Replenishment System"::Purchase, 0.01, 1);

        // [GIVEN] Create another Item.
        LibraryInventory.CreateItem(Item2);

        // [GIVEN] Create 2 Bom Components.
        LibraryInventory.CreateBOMComponent(
            BOMComponent,
            Item2."No.",
            BOMComponent.Type::Item,
            CompItem[1]."No.",
            CompItemQtyPer[1],
            CompItem[1]."Base Unit of Measure");
        LibraryInventory.CreateBOMComponent(
            BOMComponent,
            Item2."No.",
            BOMComponent.Type::Item,
            CompItem[2]."No.",
            CompItemQtyPer[2],
            CompItem[2]."Base Unit of Measure");

        //[GIVEN] Create an Assembly Header Without Line.
        CreateAssemblyOrderWithoutLines(AssemblyHeader, WorkDate(), Item2."No.");

        // [GIVEN] Validate the quantity on Assembly Order
        AssemblyHeader.Validate(Quantity, LibraryRandom.RandDec(100, 2));
        AssemblyHeader.Modify(true);

        // [GIVEN] Find Assembly Line for first Component Item
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.FindSet();

        ItemUOM.Get(CompItem[1]."No.", CompItem[1]."Base Unit of Measure");
        FindItemUnitOfMeasure(CompItem[1], ItemUOM);

        // [THEN] Calculate Expected Assembly Order Quantity.
        ExpectedQuantity := UOMMgt.RoundToItemRndPrecision(
            AssemblyHeader.Quantity * CompItemQtyPer[1], CompItem[1]."Rounding Precision");

        // [THEN]  Calculate Expected Text.
        MustMatchTxt := MatchTxt(AssemblyLine, ExpectedQuantity);

        // [VERIFY] Assembly Line Quantity when Rounding Precision was not 0.
        Assert.AreEqual(ExpectedQuantity, AssemblyLine.Quantity, MustMatchTxt);

        // [GIVEN] Get next Assembly Line for second Component Item
        AssemblyLine.Next();
        FindItemUnitOfMeasure(CompItem[2], ItemUOM);

        // [THEN] Calculate Expected Assembly Order Quantity.
        ExpectedQuantity := UOMMgt.RoundToItemRndPrecision(
            AssemblyHeader.Quantity * CompItemQtyPer[2], CompItem[2]."Rounding Precision");

        // [THEN]  Calculate Expected Text.
        MustMatchTxt := MatchTxt(AssemblyLine, ExpectedQuantity);

        // [VERIFY] Assembly Line Quantity when Rounding Precision was not 0.
        Assert.AreEqual(ExpectedQuantity, AssemblyLine.Quantity, MustMatchTxt);

        // Cleanup
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    local procedure OpenAssemblyAvailabilityPage(DocumentNo: Code[20])
    var
        AssemblyOrder: TestPage "Assembly Order";
    begin
        AssemblyOrder.OpenView();
        AssemblyOrder.FILTER.SetFilter("No.", DocumentNo);
        AssemblyOrder.ShowAvailability.Invoke();
        AssemblyOrder.OK().Invoke();
    end;

    local procedure CreateItemWithRoundingPrecision(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System"; ItemRoundingPrecision: Decimal; UOMRoundingPrecision: Decimal)
    var
        ItemUOM: Record "Item Unit of Measure";
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate(Critical, true);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Rounding Precision", ItemRoundingPrecision);
        Item.Modify(true);

        ItemUOM.Get(Item."No.", Item."Base Unit of Measure");
        ItemUOM.Validate("Qty. Rounding Precision", UOMRoundingPrecision);
        ItemUOM.Modify();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailabilityWindowHandler(var AsmAvailability: TestPage "Assembly Availability Check")
    begin
        AsmAvailability.AssemblyLineAvail.First();
        AsmAvailability.AssemblyLineAvail.GrossRequirement.AssertEquals(0);
        AsmAvailability.AssemblyLineAvail.ExpectedAvailableInventory.AssertEquals(0);
    end;
}

