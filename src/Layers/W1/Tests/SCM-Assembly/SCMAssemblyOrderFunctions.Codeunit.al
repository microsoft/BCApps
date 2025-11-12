// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Test;

using System.Environment.Configuration;
using System.TestLibraries.Utilities;
using Microsoft.Assembly.Document;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Item;
using Microsoft.Finance.Dimension;
using Microsoft.Assembly.Setup;
using Microsoft.Inventory.Item.Substitution;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Finance.GeneralLedger.Setup;

codeunit 137907 "SCM Assembly Order Functions"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Assembly] [SCM]
        WorkDate2 := LibraryPlanning.SetSafetyWorkDate(); // to avoid Due Date Before Work Date message.
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        MSGAssertLineCount: Label 'Bad Line count of Order: %1 expected %2, got %3';
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryKitting: Codeunit "Library - Kitting";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryDimension: Codeunit "Library - Dimension";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPlanning: Codeunit "Library - Planning";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        WorkDate2: Date;
        RefreshingBomCnfm: Label 'This assembly order may have customized lines. Are you sure that you want to reset the lines according to the assembly BOM?';
        UpdateDimCnfm: Label 'Do you want to update the Dimensions on the lines?';
        Initialized: Boolean;
        MSGDueDateBeforeWorkDate: Label 'is before work date';
        DimErr: Label 'Incorrect Dimension Set ID';
        ShortcutDimErr: Label 'Incorrect Shortcut Dimension';
        Description2AssemblyLineResourceNotBlankErr: Label 'Description 2 field of Assembly Line table must be blank for Type Resource.';
        Description2AssemblyLineItemDoesntMatchErr: Label 'Description 2 field of Assembly Line table must match to related component item Description 2 for Type Item.';
        UpdateDimOnSalesLinesMsg: Label 'You may have changed a dimension.\\Do you want to update the lines?';

    [Test]
    [Scope('OnPrem')]
    procedure ExplodeBomOneItem()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        BOMComp: Record "BOM Component";
        parentItem: Record Item;
        childItem: Record Item;
        childItem2: Record Item;
    begin
        Initialize();
        parentItem.Get(LibraryKitting.CreateItemWithLotAndNewUOM(500, 700, 1));
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parentItem."No.", 1));
        childItem.Get(LibraryKitting.CreateItemWithNewUOM(500, 700));
        LibraryInventory.CreateBOMComponent(
          BOMComp, parentItem."No.", BOMComp.Type::Item, childItem."No.", 1, childItem."Base Unit of Measure");

        AssemblyHeader.RefreshBOM();
        ValidateCount(AssemblyHeader."No.", 1);
        childItem2.Get(LibraryKitting.CreateItemWithNewUOM(500, 700));
        LibraryInventory.CreateBOMComponent(
          BOMComp, childItem."No.", BOMComp.Type::Item, childItem2."No.", 1, childItem2."Base Unit of Measure");

        FindAssemblyLine(AssemblyLine, AssemblyHeader);

        AssemblyLine.ExplodeAssemblyList();
        ValidateCount(AssemblyHeader."No.", 2);
        NotificationLifecycleMgt.RecallAllNotifications();
        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExplodeBomTwoItem()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        BOMComp: Record "BOM Component";
        parentItem: Record Item;
        childItem: Record Item;
        childItem2: Record Item;
    begin
        Initialize();
        parentItem.Get(LibraryKitting.CreateItemWithLotAndNewUOM(500, 700, 1));
        parentItem.Validate("Costing Method", parentItem."Costing Method"::Average);
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parentItem."No.", 1));
        childItem.Get(LibraryKitting.CreateItemWithNewUOM(500, 700));
        LibraryInventory.CreateBOMComponent(
          BOMComp, parentItem."No.", BOMComp.Type::Item, childItem."No.", 1, childItem."Base Unit of Measure");

        AssemblyHeader.RefreshBOM();
        ValidateCount(AssemblyHeader."No.", 1);
        childItem2.Get(LibraryKitting.CreateItemWithNewUOM(500, 700));
        LibraryInventory.CreateBOMComponent(
          BOMComp, childItem."No.", BOMComp.Type::Item, childItem2."No.", 1, childItem2."Base Unit of Measure");
        childItem2.Get(LibraryKitting.CreateItemWithNewUOM(100, 200));
        LibraryInventory.CreateBOMComponent(
          BOMComp, childItem."No.", BOMComp.Type::Item, childItem2."No.", 2, childItem2."Base Unit of Measure");

        FindAssemblyLine(AssemblyLine, AssemblyHeader);

        AssemblyLine.ExplodeAssemblyList();
        ValidateCount(AssemblyHeader."No.", 3);
        ValidateQuantityonLines(AssemblyHeader."No.", 3);
        AssemblyHeader.UpdateUnitCost();
        ValidateOrderUnitCost(AssemblyHeader, 1 * (1 * 500 + 2 * 100));
        NotificationLifecycleMgt.RecallAllNotifications();
        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExplodeBomSkip()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        BOMComp: Record "BOM Component";
        parentItem: Record Item;
        childItem: Record Item;
        childItem2: Record Item;
    begin
        Initialize();
        parentItem.Get(LibraryKitting.CreateItemWithLotAndNewUOM(500, 700, 1));
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parentItem."No.", 1));
        childItem.Get(LibraryKitting.CreateItemWithNewUOM(500, 700));
        LibraryInventory.CreateBOMComponent(
          BOMComp, parentItem."No.", BOMComp.Type::Item, childItem."No.", 1, childItem."Base Unit of Measure");

        AssemblyHeader.RefreshBOM();
        ValidateCount(AssemblyHeader."No.", 1);
        childItem2.Get(LibraryKitting.CreateItemWithNewUOM(500, 700));
        LibraryInventory.CreateBOMComponent(
          BOMComp, childItem."No.", BOMComp.Type::Item, childItem2."No.", 1, childItem2."Base Unit of Measure");

        FindAssemblyLine(AssemblyLine, AssemblyHeader);

        AssemblyLine.ExplodeAssemblyList();  // Can't be esscaped anymore as dimension is not asked anymore
        ValidateCount(AssemblyHeader."No.", 2); // was 1 before we removed the question
        NotificationLifecycleMgt.RecallAllNotifications();
        asserterror Error('') // roll back
    end;

    [Test]
    [HandlerFunctions('DimensionSetupRefreshConfirmHandler')]
    [Scope('OnPrem')]
    procedure DimensionSetup()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        BOMComp: Record "BOM Component";
        ParentItem: Record Item;
        ChildItem: Record Item;
        Dimension1: Record Dimension;
        Dimension2: Record Dimension;
        Dimension3: Record Dimension;
        DimValue1: Record "Dimension Value";
        DimValue2: Record "Dimension Value";
        DimValue21: Record "Dimension Value";
        DimValue22: Record "Dimension Value";
        DimValue3: Record "Dimension Value";
        AsmSetup: Record "Assembly Setup";
        DefaultDim: Record "Default Dimension";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        TempDimSetEntryLinePost: Record "Dimension Set Entry" temporary;
        DimMgt: Codeunit DimensionManagement;
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryAssembly: Codeunit "Library - Assembly";
        DimSetID1: Integer;
        DimSetID2: Integer;
        parent: Code[20];
        child: Code[20];
    begin
        Initialize();
        LibraryKitting.SetCopyFrom(0); // Header

        // Setup dimensions
        LibraryDimension.CreateDimension(Dimension1);
        LibraryDimension.CreateDimensionValue(DimValue1, Dimension1.Code);
        LibraryDimension.CreateDimensionValue(DimValue2, Dimension1.Code);

        LibraryDimension.CreateDimension(Dimension2);
        LibraryDimension.CreateDimensionValue(DimValue21, Dimension2.Code);
        LibraryDimension.CreateDimensionValue(DimValue22, Dimension2.Code);
        LibraryDimension.CreateDimension(Dimension3);
        LibraryDimension.CreateDimensionValue(DimValue3, Dimension3.Code);

        // Add dimension to Dim Set
        TempDimSetEntry."Dimension Code" := Dimension1.Code;
        TempDimSetEntry."Dimension Value Code" := DimValue1.Code;
        TempDimSetEntry."Dimension Value ID" := DimValue1."Dimension Value ID";
        TempDimSetEntry.Insert();
        TempDimSetEntry."Dimension Code" := Dimension2.Code;
        TempDimSetEntry."Dimension Value Code" := DimValue21.Code;
        TempDimSetEntry."Dimension Value ID" := DimValue21."Dimension Value ID";
        TempDimSetEntry.Insert();

        DimSetID1 := DimMgt.GetDimensionSetID(TempDimSetEntry);

        TempDimSetEntry.DeleteAll();
        TempDimSetEntry."Dimension Code" := Dimension1.Code;
        TempDimSetEntry."Dimension Value Code" := DimValue2.Code;
        TempDimSetEntry."Dimension Value ID" := DimValue2."Dimension Value ID";
        TempDimSetEntry.Insert();
        TempDimSetEntry."Dimension Code" := Dimension2.Code;
        TempDimSetEntry."Dimension Value Code" := DimValue22.Code;
        TempDimSetEntry."Dimension Value ID" := DimValue22."Dimension Value ID";
        TempDimSetEntry.Insert();
        TempDimSetEntry."Dimension Code" := Dimension3.Code;
        TempDimSetEntry."Dimension Value Code" := DimValue3.Code;
        TempDimSetEntry."Dimension Value ID" := DimValue3."Dimension Value ID";
        TempDimSetEntry.Insert();

        DimSetID2 := DimMgt.GetDimensionSetID(TempDimSetEntry);
        parent := LibraryKitting.CreateItemWithLotAndNewUOM(500, 700, 1);
        child := LibraryKitting.CreateItemWithNewUOM(500, 700);
        ParentItem.Get(parent);
        ChildItem.Get(child);

        DefaultDim.Init();
        DefaultDim.Validate("Table ID", DATABASE::Item);
        DefaultDim.Validate("No.", ParentItem."No.");
        DefaultDim.Validate("Dimension Code", Dimension1.Code);
        DefaultDim.Validate("Dimension Value Code", DimValue1.Code);
        DefaultDim.Insert();
        DefaultDim.Validate("Table ID", DATABASE::Item);
        DefaultDim.Validate("No.", ParentItem."No.");
        DefaultDim.Validate("Dimension Code", Dimension2.Code);
        DefaultDim.Validate("Dimension Value Code", DimValue21.Code);
        DefaultDim.Insert();

        DefaultDim.Init();
        DefaultDim.Validate("Table ID", DATABASE::Item);
        DefaultDim.Validate("No.", ChildItem."No.");
        DefaultDim.Validate("Dimension Code", Dimension1.Code);
        DefaultDim.Validate("Dimension Value Code", DimValue2.Code);
        DefaultDim.Insert();
        DefaultDim.Validate("Table ID", DATABASE::Item);
        DefaultDim.Validate("No.", ChildItem."No.");
        DefaultDim.Validate("Dimension Code", Dimension2.Code);
        DefaultDim.Validate("Dimension Value Code", DimValue22.Code);
        DefaultDim.Insert();
        DefaultDim.Validate("Table ID", DATABASE::Item);
        DefaultDim.Validate("No.", ChildItem."No.");
        DefaultDim.Validate("Dimension Code", Dimension3.Code);
        DefaultDim.Validate("Dimension Value Code", DimValue3.Code);
        DefaultDim.Insert();

        LibraryInventory.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Item, child, 1, ChildItem."Base Unit of Measure");
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parent, 1));

        // Set the refreshBom Method
        // TEST WITH THE ASM setup option Copy Component Dimensions from := Order Header
        AsmSetup.FindFirst();
        AsmSetup.Validate("Copy Component Dimensions from", AsmSetup."Copy Component Dimensions from"::"Order Header");
        AsmSetup.Modify();

        AssemblyHeader.Validate("Dimension Set ID", DimSetID1);
        AssemblyHeader.Modify(true);

        LibraryAssembly.SetLinkToLines(AssemblyHeader, AssemblyLine);

        AssemblyLine.FindFirst();
        AssemblyLine.Validate("Dimension Set ID", DimSetID2);
        AssemblyHeader.RefreshBOM();
        // find children lines and verify dimensions
        LibraryAssembly.SetLinkToLines(AssemblyHeader, AssemblyLine);
        AssemblyLine.FindFirst();
        Assert.AreNotEqual(AssemblyLine."Dimension Set ID", 0, 'AssemblyLine.Dimension Set ID must not be Zero');

        // Test the refreshBOM using AsmSetup."Copy Component Dimensions from"::"Order Header"
        DimMgt.GetDimensionSet(TempDimSetEntryLinePost, AssemblyLine."Dimension Set ID");

        // VERIFY
        Assert.AreEqual(AssemblyHeader."Dimension Set ID", DimSetID1, 'Asm Header.Dimension Set ID changed');
        Assert.AreNotEqual(AssemblyLine."Dimension Set ID", DimSetID2,
          StrSubstNo(
            'AssemblyLine.Dimension Set ID did NOT change, which it is expected to Initital %1 after update %2', DimSetID2,
            AssemblyLine."Dimension Set ID"));

        TempDimSetEntryLinePost.SetFilter("Dimension Code", Dimension1.Code);
        TempDimSetEntryLinePost.FindFirst();
        Assert.AreEqual(TempDimSetEntryLinePost."Dimension Value Code", DimValue1.Code,
          StrSubstNo('Wrong Dimension Value in Line, expected %1, got %2', DimValue1.Code, TempDimSetEntryLinePost."Dimension Value Code"));

        // TEST WITH THE OTHER ASM setup option Copy Component Dimensions from := Item/Resource Card
        AsmSetup.Validate("Copy Component Dimensions from", AsmSetup."Copy Component Dimensions from"::"Item/Resource Card");
        AsmSetup.Modify();

        DimSetID2 := AssemblyLine."Dimension Set ID";
        AssemblyHeader.RefreshBOM();
        LibraryAssembly.SetLinkToLines(AssemblyHeader, AssemblyLine);
        AssemblyLine.FindFirst();
        // VERIFY
        Assert.AreEqual(AssemblyHeader."Dimension Set ID", DimSetID1, 'Asm Header.Dimension Set ID changed');
        Assert.AreNotEqual(AssemblyLine."Dimension Set ID", DimSetID2,
          StrSubstNo(
            'AssemblyLine.Dimension Set ID did NOT change, which it is expected to Initital %1 after update %2', DimSetID2,
            AssemblyLine."Dimension Set ID"));

        DimMgt.GetDimensionSet(TempDimSetEntryLinePost, AssemblyLine."Dimension Set ID");
        TempDimSetEntryLinePost.SetFilter("Dimension Code", Dimension1.Code);
        TempDimSetEntryLinePost.FindFirst();
        Assert.AreEqual(TempDimSetEntryLinePost."Dimension Value Code", DimValue2.Code,
          StrSubstNo('Wrong Dimension Value in Line, expected %1, got %2', DimValue2.Code, TempDimSetEntryLinePost."Dimension Value Code"));
        NotificationLifecycleMgt.RecallAllNotifications();
        asserterror Error('') // roll back
    end;

    [Test]
    [HandlerFunctions('ItemSubstitutionPageHandler')]
    [Scope('OnPrem')]
    procedure Substitude()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        BOMComp: Record "BOM Component";
        ItemSubstitution: Record "Item Substitution";
        childItem: Record Item;
        subst: Code[20];
        parent: Code[20];
    begin
        Initialize();
        parent := LibraryKitting.CreateItemWithLotAndNewUOM(500, 700, 1);
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parent, 1));
        childItem.Get(LibraryKitting.CreateItemWithNewUOM(500, 700));

        LibraryInventory.CreateBOMComponent(
          BOMComp, parent, BOMComp.Type::Item, childItem."No.", 1, childItem."Base Unit of Measure");

        AssemblyHeader.RefreshBOM();
        ValidateCount(AssemblyHeader."No.", 1);

        FindAssemblyLine(AssemblyLine, AssemblyHeader);

        subst := LibraryKitting.CreateItem(500, 700, childItem."Base Unit of Measure");
        ItemSubstitution.CreateSubstitutionItem2Item(childItem."No.", '', subst, '', false);
        AssemblyLine.ShowItemSub();
        ValidateNo(AssemblyLine, subst);

        asserterror Error(''); // roll back

        LibraryNotificationMgt.RecallNotificationsForRecord(AssemblyLine);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSTF295357()
    var
        DueDate: Date;
    begin
        DueDate := CalcDate('<1Y>', WorkDate());
        TestAsmOrderExplodeBOM(false, DueDate);
    end;

    [Test]
    [HandlerFunctions('DueDateBeforeWorkDateMsgHandler')]
    [Scope('OnPrem')]
    procedure VSTF295357DueDateBeforeWorkDate()
    var
        DueDate: Date;
    begin
        DueDate := CalcDate('<-1Y>', WorkDate());
        TestAsmOrderExplodeBOM(false, DueDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSTF333588()
    var
        DueDate: Date;
    begin
        DueDate := CalcDate('<1Y>', WorkDate());
        TestAsmOrderExplodeBOM(true, DueDate);
    end;

    [Test]
    [HandlerFunctions('DueDateBeforeWorkDateMsgHandler')]
    [Scope('OnPrem')]
    procedure VSTF333588DueDateBeforeWorkDate()
    var
        DueDate: Date;
    begin
        DueDate := CalcDate('<-1Y>', WorkDate());
        TestAsmOrderExplodeBOM(true, DueDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimOnPlanningCompWithAssembly()
    var
        PlanningComponent: Record "Planning Component";
        Item: array[2] of Record Item;
        DimSetID: array[2] of Integer;
        DimValueCode: Code[20];
    begin
        // [FEATURE] [Dimension] [Planning Worksheet]
        // [SCENARIO 377510] Planning Components should inherit Dimension from Requisition Line while planning through Planning Worksheet
        Initialize();

        // [GIVEN] Component Item with Default Dimension = "X"
        // [GIVEN] Parent Item with Default Dimension = "Y"
        // [GIVEN] Sales Order for Parent Item with "Shortcut Dimension Code 1" = "Z"
        DimValueCode := CreateSalesOrderForAssemblyItemWithDim(DimSetID, Item);

        // [WHEN] Calculate Regenerative Plan
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item[1], WorkDate(), WorkDate());

        // [THEN] Planning Component is created with Dimension = "Y" and "Shortcut Dimension Code 1" = "Z"
        PlanningComponent.SetRange("Item No.", Item[2]."No.");
        PlanningComponent.FindFirst();
        Assert.AreEqual(DimSetID[1], PlanningComponent."Dimension Set ID", DimErr);
        Assert.AreEqual(DimValueCode, PlanningComponent."Shortcut Dimension 1 Code", ShortcutDimErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimOnAssemblyLineCopiedFromHeader()
    var
        RequisitionLine: Record "Requisition Line";
        AssemblySetup: Record "Assembly Setup";
        Item: array[2] of Record Item;
        DimSetID: array[2] of Integer;
    begin
        // [FEATURE] [Dimension] [Planning Worksheet] [Copy Components Dimensions from]
        // [SCENARIO 377510] Default Dimension of Component should be taken from Assembly Header when "Copy Components Dimensions from" is "Order Header" in Assembly Setup
        Initialize();

        // [GIVEN] Assembly Setup where "Copy Components Dimensions from" is "Order Header"
        SetCopyCompDimOnAsmSetup(AssemblySetup."Copy Component Dimensions from"::"Order Header");

        // [GIVEN] Component Item with Default Dimension = "X"
        // [GIVEN] Parent Item with Default Dimension = "Y"
        // [GIVEN] Sales Order for Parent Item
        CreateSalesOrderForAssemblyItemWithDim(DimSetID, Item);

        // [GIVEN] Calculate Regenerative Plan for Parent Item
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item[1], WorkDate(), WorkDate());
        AcceptActionMessageOnReqLines(RequisitionLine, Item[1]."No.");

        // [WHEN] Carry Out Action Message
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);

        // [THEN] Assembly Line has Dimension equal to "Y"
        VerifyDimOnAssemblyLine(Item[1]."No.", DimSetID[1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimOnAssemblyLineCopiedFromItem()
    var
        RequisitionLine: Record "Requisition Line";
        AssemblySetup: Record "Assembly Setup";
        Item: array[2] of Record Item;
        DimSetID: array[2] of Integer;
    begin
        // [FEATURE] [Dimension] [Planning Worksheet] [Copy Components Dimensions from]
        // [SCENARIO 377510] Default Dimension of Component should be taken from Component Item when "Copy Components Dimensions from" is "Item/Resource Card" in Assembly Setup
        Initialize();

        // [GIVEN] Assembly Setup where "Copy Components Dimensions from" is "Item/Resource Card"
        SetCopyCompDimOnAsmSetup(AssemblySetup."Copy Component Dimensions from"::"Item/Resource Card");

        // [GIVEN] Component Item with Default Dimension = "X"
        // [GIVEN] Parent Item with Default Dimension = "Y"
        // [GIVEN] Sales Order for Parent Item
        CreateSalesOrderForAssemblyItemWithDim(DimSetID, Item);

        // [GIVEN] Calculate Regenerative Plan for Parent Item
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item[1], WorkDate(), WorkDate());
        AcceptActionMessageOnReqLines(RequisitionLine, Item[1]."No.");

        // [WHEN] Carry Out Action Message
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);

        // [THEN] Assembly Line has Dimension equal to "X"
        VerifyDimOnAssemblyLine(Item[1]."No.", DimSetID[2]);
    end;

    [Test]
    [HandlerFunctions('StubMessageHandler')]
    [Scope('OnPrem')]
    procedure Description2InAssemblyLineMatching()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        BOMComponent: Record "BOM Component";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        Resource: Record Resource;
    begin
        // [FEATURE] [Assembly BOM]
        // [SCENARIO 381865] Field "Description 2" should not be populated in assembly line with Type = "Resource". For a line with Type = "Item", it should be copied from the component item.
        Initialize();

        // [GIVEN] Parent Assembly Item PAI with populated Description 2.
        LibraryInventory.CreateItem(ParentItem);
        ParentItem.Validate("Replenishment System", ParentItem."Replenishment System"::Assembly);
        ParentItem.Validate("Description 2", LibraryUtility.GenerateRandomCode(ParentItem.FieldNo("Description 2"), DATABASE::Item));
        ParentItem.Modify(true);

        // [GIVEN] Child Item CI with populated Description 2 as a BOM Component of type Item for PAI.
        LibraryInventory.CreateItem(ChildItem);
        ChildItem.Validate("Description 2", LibraryUtility.GenerateRandomCode(ChildItem.FieldNo("Description 2"), DATABASE::Item));
        ChildItem.Modify(true);
        LibraryInventory.CreateBOMComponent(
          BOMComponent, ParentItem."No.", BOMComponent.Type::Item, ChildItem."No.", 1, '');

        // [GIVEN] A BOM Component of type Resource for PAI.
        LibraryInventory.CreateBOMComponent(
          BOMComponent, ParentItem."No.", BOMComponent.Type::Resource, LibraryAssembly.CreateResource(Resource, true, ''), 1, '');

        // [WHEN] Create Assembly Header for PAI and populate Quantity
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), ParentItem."No.", '', LibraryRandom.RandInt(10), '');

        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.SetRange(Type, AssemblyLine.Type::Resource);
        AssemblyLine.FindFirst();
        // [THEN] the field "Description 2" of related Assembly Line of Type Resource is blank.
        Assert.AreEqual('', AssemblyLine."Description 2", Description2AssemblyLineResourceNotBlankErr);

        AssemblyLine.SetRange(Type, AssemblyLine.Type::Item);
        AssemblyLine.FindFirst();
        // [THEN] The field "Description 2" of related Assembly Line of Type Item is equal to CI."Description 2".
        Assert.AreEqual(ChildItem."Description 2", AssemblyLine."Description 2", Description2AssemblyLineItemDoesntMatchErr);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExplodeBOMDiffUnitOfMeasure()
    var
        Item: array[3] of Record Item;
        ItemUnitOfMeasure: array[3] of Record "Item Unit of Measure";
        BOMComponent: Record "BOM Component";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        ExpectedQty: Decimal;
        ExpectedQtyBase: Decimal;
    begin
        // [FEATURE] [Explode BOM] [Item Unit of Measure]
        // [SCENARIO 211722] Function "Explode BOM" of the assembly order should consider the order unit of measure when calculating the quantity of a component item
        Initialize();

        // [GIVEN] Item "A" with an additional unit of measure "UoM1", "Qty. per Unit of Measure" = 2
        LibraryInventory.CreateItem(Item[1]);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure[1], Item[1]."No.", LibraryRandom.RandIntInRange(2, 10));

        // [GIVEN] Item "B" with an additional unit of measure "UoM2", "Qty. per Unit of Measure" = 3
        // [GIVEN] Item "B" is an assembly component of "A", unit of measure of the component is "UoM2"
        LibraryInventory.CreateItem(Item[2]);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure[2], Item[2]."No.", LibraryRandom.RandIntInRange(2, 10));
        LibraryInventory.CreateBOMComponent(
          BOMComponent, Item[1]."No.", BOMComponent.Type::Item, Item[2]."No.", 1, ItemUnitOfMeasure[2].Code);

        // [GIVEN] Item "C" with an additional unit of measure "UoM3", "Qty. per Unit of Measure" = 4
        // [GIVEN] Item "C" is an assembly component of "B", unit of measure of the component is "UoM3"
        LibraryInventory.CreateItem(Item[3]);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure[3], Item[3]."No.", LibraryRandom.RandIntInRange(2, 10));
        LibraryInventory.CreateBOMComponent(
          BOMComponent, Item[2]."No.", BOMComponent.Type::Item, Item[3]."No.", 1, ItemUnitOfMeasure[3].Code);

        // [GIVEN] Create an assembly order for te top-level item "A", unit of measure = "UOM1"
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, Item[1]."No.", 1));
        AssemblyHeader.Validate("Unit of Measure Code", ItemUnitOfMeasure[1].Code);
        AssemblyHeader.Modify(true);

        FindAssemblyLine(AssemblyLine, AssemblyHeader);

        // [WHEN] Run "Explode BOM" function on the item "B"
        AssemblyLine.ExplodeAssemblyList();

        // [THEN] Quantity of the low-level item "C" in the order line is 2 * 3 = 6
        // [THEN] "Quantity (Base)" of the item "C" in the order line is 2 * 3 * 4 = 24
        ExpectedQty := ItemUnitOfMeasure[1]."Qty. per Unit of Measure" * ItemUnitOfMeasure[2]."Qty. per Unit of Measure";
        ExpectedQtyBase := ExpectedQty * ItemUnitOfMeasure[3]."Qty. per Unit of Measure";
        VerifyAssemblyLineQty(Item[3]."No.", ExpectedQty, ExpectedQtyBase);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExplodeBOMQuantityPerLine()
    var
        Item: array[3] of Record Item;
        BOMComponent: Record "BOM Component";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        QtyPerLine: array[2] of Decimal;
    begin
        // [FEATURE] [Explode BOM]
        // [SCENARIO 211722] Function "Explode BOM" of the assembly order should calculate the quantity of a component item based on "Quantity per" in the order line

        Initialize();

        // [GIVEN] 3 items "A", "B" and "C"
        QtyPerLine[1] := LibraryRandom.RandIntInRange(2, 10);
        QtyPerLine[2] := LibraryRandom.RandIntInRange(2, 10);

        // [GIVEN] Item "B" is an assembly component of "A", "Quantity per" = 2
        LibraryInventory.CreateItem(Item[1]);
        LibraryInventory.CreateItem(Item[2]);
        LibraryInventory.CreateBOMComponent(
          BOMComponent, Item[1]."No.", BOMComponent.Type::Item, Item[2]."No.", QtyPerLine[1], Item[2]."Base Unit of Measure");

        // [GIVEN] Item "C" is a component of "B", "Quantity per" = 3
        LibraryInventory.CreateItem(Item[3]);
        LibraryInventory.CreateBOMComponent(
          BOMComponent, Item[2]."No.", BOMComponent.Type::Item, Item[3]."No.", QtyPerLine[2], Item[3]."Base Unit of Measure");

        // [GIVEN] Create an assembly order for te top-level item "A"
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, Item[1]."No.", 1));
        FindAssemblyLine(AssemblyLine, AssemblyHeader);

        // [WHEN] Run "Explode BOM" function on the item "B"
        AssemblyLine.ExplodeAssemblyList();

        // [THEN] Quantity of the low-level item "C" in the order line is 2 * 3 = 6
        VerifyAssemblyLineQty(Item[3]."No.", QtyPerLine[1] * QtyPerLine[2], QtyPerLine[1] * QtyPerLine[2]);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('StubMessageHandler')]
    [Scope('OnPrem')]
    procedure DescriptionInAssemblyLineMatchingBOMComponent()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        BOMComponent: Record "BOM Component";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
    begin
        // [FEATURE] [Assembly BOM] [Description]
        // [SCENARIO 351774] Field "Description" in Assembly Line is copied from the BOM Component
        Initialize();

        // [GIVEN] Parent Assembly Item "A"
        LibraryInventory.CreateItem(ParentItem);
        ParentItem.Validate("Replenishment System", ParentItem."Replenishment System"::Assembly);
        ParentItem.Modify(true);

        // [GIVEN] Item "B" with Description = "Initial"
        LibraryInventory.CreateItem(ChildItem);
        ChildItem.Validate(Description, LibraryUtility.GenerateRandomCode(ChildItem.FieldNo(Description), DATABASE::Item));
        ChildItem.Modify(true);

        // [GIVEN] Item "B" is an assembly component of "A", with Description = "Modified" on a BOM Component
        LibraryInventory.CreateBOMComponent(
          BOMComponent, ParentItem."No.", BOMComponent.Type::Item, ChildItem."No.", 1, '');
        BOMComponent.Validate(Description, LibraryUtility.GenerateRandomCode(ChildItem.FieldNo(Description), DATABASE::"BOM Component"));
        BOMComponent.Modify(true);

        // [WHEN] Create Assembly Header for "A" and populate Quantity
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), ParentItem."No.", '', LibraryRandom.RandInt(10), '');

        // [THEN] "Description" = "Modified" on the Assembly Line
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.FindFirst();
        AssemblyLine.TestField(Description, BOMComponent.Description);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure DoNotShowConfirmForATOLineAfterUserConfirmsSalesLineChange()
    var
        Dimension: Record Dimension;
        DimensionValue: array[2] of Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        Customer: Record Customer;
        CompItem: Record Item;
        AsmItem: Record Item;
        BOMComponent: Record "BOM Component";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Assemble-to-Order] [Dimension]
        // [SCENARIO 437447] Do not ask for dimension change confirmation for assemble-to-order line after the user confirms changes for the sales line.
        Initialize();
        LibraryAssembly.SetStockoutWarning(false);

        // [GIVEN] Dimension "D" with two values - "D1" and "D2".
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue[1], Dimension.Code);
        LibraryDimension.CreateDimensionValue(DimensionValue[2], Dimension.Code);

        // [GIVEN] Customer with default dimension value "D1".
        LibrarySales.CreateCustomer(Customer);
        LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension, Customer."No.", Dimension.Code, DimensionValue[1].Code);

        // [GIVEN] Assemble-to-order item "A" with component "C".
        LibraryInventory.CreateItem(CompItem);
        LibraryInventory.CreateItem(AsmItem);
        AsmItem.Validate("Replenishment System", AsmItem."Replenishment System"::Assembly);
        AsmItem.Validate("Assembly Policy", AsmItem."Assembly Policy"::"Assemble-to-Order");
        AsmItem.Modify(true);
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, CompItem."No.", AsmItem."No.", '', BOMComponent."Resource Usage Type", 1, true);

        // [GIVEN] Sales order for the customer.
        // [GIVEN] Add two sales lines, each for item "A". The assembly order is created in the background.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("Shipment Date", LibraryRandom.RandDate(30));
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, AsmItem."No.", 1);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, AsmItem."No.", 1);

        // [WHEN] Update dimension value from "D1" to "D2" on the sales header.
        LibraryVariableStorage.Enqueue(UpdateDimOnSalesLinesMsg);
        SalesHeader.UpdateAllLineDim(
          LibraryDimension.EditDimSet(SalesHeader."Dimension Set ID", Dimension.Code, DimensionValue[2].Code),
          SalesHeader."Dimension Set ID");

        // [THEN] Ensure that only one confirmation message for sales lines is raised.

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ExplodeBomHandler')]
    procedure ExplodeBOMDeletesLinkedAssemblyToOrder()
    var
        AsmItem: Record Item;
        CompItem: Record Item;
        BOMComponent: Record "BOM Component";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
    begin
        // [FEATURE] [Explode BOM] [Assemble-to-Order]
        // [SCENARIO 442268] Linked assembly to order must be deleted for the exploded line.
        Initialize();

        // [GIVEN] Assemble-to-order item.
        LibraryInventory.CreateItem(AsmItem);
        AsmItem.Validate("Replenishment System", AsmItem."Replenishment System"::Assembly);
        AsmItem.Validate("Assembly Policy", AsmItem."Assembly Policy"::"Assemble-to-Order");
        AsmItem.Modify(true);

        // [GIVEN] Create BOM component.
        LibraryInventory.CreateItem(CompItem);
        LibraryInventory.CreateBOMComponent(
          BOMComponent, AsmItem."No.", BOMComponent.Type::Item, CompItem."No.", 1, '');

        // [GIVEN] Sales quote for the assembled item.
        // [GIVEN] Ensure that the linked assembly quote is created too.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, '');
        SalesHeader.Validate("Shipment Date", WorkDate2);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, AsmItem."No.", LibraryRandom.RandInt(10));
        LibraryAssembly.FindLinkedAssemblyOrder(
          AssemblyHeader, SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");

        // [WHEN] Explode BOM for the sales line.
        LibrarySales.ExplodeBOM(SalesLine);

        // [THEN] The linked assembly quote has been deleted.
        asserterror LibraryAssembly.FindLinkedAssemblyOrder(
            AssemblyHeader, SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Assembly Order Functions");
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();

        if Initialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Assembly Order Functions");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        LibrarySetupStorage.Save(DATABASE::"Assembly Setup");

        Initialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Assembly Order Functions");
    end;

    local procedure SetCopyCompDimOnAsmSetup(CopyComponentDimensionsFrom: Option)
    var
        AssemblySetup: Record "Assembly Setup";
    begin
        AssemblySetup.Get();
        AssemblySetup.Validate("Copy Component Dimensions from", CopyComponentDimensionsFrom);
        AssemblySetup.Modify(true);
    end;

    local procedure CreateItemWithDefaultDimension(var Item: Record Item; DimensionValue: Record "Dimension Value"): Integer
    var
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::Assembly);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::Order);
        Item.Modify(true);
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, Item."No.", DimensionValue."Dimension Code", DimensionValue.Code);
        exit(MockDimSetEntry(DimensionValue));
    end;

    local procedure MockDimSetEntry(DimensionValue: Record "Dimension Value"): Integer
    var
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimMgt: Codeunit DimensionManagement;
    begin
        TempDimSetEntry.Init();
        TempDimSetEntry."Dimension Code" := DimensionValue."Dimension Code";
        TempDimSetEntry."Dimension Value Code" := DimensionValue.Code;
        TempDimSetEntry."Dimension Value ID" := DimensionValue."Dimension Value ID";
        TempDimSetEntry.Insert();
        exit(DimMgt.GetDimensionSetID(TempDimSetEntry));
    end;

    local procedure AcceptActionMessageOnReqLines(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20])
    begin
        RequisitionLine.SetRange("No.", ItemNo);
        RequisitionLine.FindSet();
        RequisitionLine.ModifyAll("Accept Action Message", true, true);
    end;

    local procedure CreateSalesOrderForAssemblyItemWithDim(var DimSetID: array[2] of Integer; var Item: array[2] of Record Item): Code[20]
    var
        BOMComponent: Record "BOM Component";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DimensionValue: Record "Dimension Value";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue, GeneralLedgerSetup."Shortcut Dimension 1 Code");
        DimSetID[1] := CreateItemWithDefaultDimension(Item[1], DimensionValue);
        DimSetID[2] := CreateItemWithDefaultDimension(Item[2], DimensionValue);
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, Item[2]."No.", Item[1]."No.", '', BOMComponent."Resource Usage Type", LibraryRandom.RandInt(10), true);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, Item[1]."No.", LibraryRandom.RandInt(10));

        exit(DimensionValue.Code);
    end;

    local procedure FindAssemblyLine(var AssemblyLine: Record "Assembly Line"; AssemblyHeader: Record "Assembly Header")
    begin
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.FindFirst();
    end;

    local procedure TestAsmOrderExplodeBOM(ExplodeBOMFromPage: Boolean; DueDate: Date)
    var
        ChildChildItem: Record Item;
        ChildItem: Record Item;
        ParentItem: Record Item;
        BOMComponent: Record "BOM Component";
        AsmHeader: Record "Assembly Header";
        AsmLine: Record "Assembly Line";
        AsmLineMgt: Codeunit "Assembly Line Management";
        AsmOrderTestPage: TestPage "Assembly Order";
        ChildItemDesc1: Code[20];
        ChildItemDesc2: Code[20];
        ParentItemDesc1: Code[20];
        ParentItemDesc2: Code[20];
        ResourceNo: Code[20];
        LineCount: Integer;
        ExpectedNoLines: Integer;
    begin
        // SETUP
        // Make the BOM tree
        Initialize();
        LibraryInventory.CreateItem(ChildChildItem);

        // Create child assembly item
        LibraryInventory.CreateItem(ChildItem);
        ChildItem."Replenishment System" := ChildItem."Replenishment System"::Assembly;
        ChildItem.Modify();
        LibraryInventory.CreateBOMComponent(BOMComponent, ChildItem."No.", BOMComponent.Type::" ", '', 1, '');
        ChildItemDesc1 := LibraryUtility.GenerateRandomCode(BOMComponent.FieldNo(Description), DATABASE::"BOM Component");
        BOMComponent.Validate(Description, ChildItemDesc1);
        BOMComponent.Modify();
        LibraryInventory.CreateBOMComponent(BOMComponent, ChildItem."No.", BOMComponent.Type::Item, ChildChildItem."No.", 1, '');
        ResourceNo := LibraryKitting.CreateResourceWithNewUOM(1, 1); // Any resource price/cost
        LibraryInventory.CreateBOMComponent(BOMComponent, ChildItem."No.", BOMComponent.Type::Resource, ResourceNo, 1, '');
        LibraryInventory.CreateBOMComponent(BOMComponent, ChildItem."No.", BOMComponent.Type::" ", '', 1, '');
        ChildItemDesc2 := LibraryUtility.GenerateRandomCode(BOMComponent.FieldNo(Description), DATABASE::"BOM Component");
        BOMComponent.Validate(Description, ChildItemDesc2);
        BOMComponent.Modify();

        // Create parent assembly item
        LibraryInventory.CreateItem(ParentItem);
        ParentItem."Replenishment System" := ParentItem."Replenishment System"::Assembly;
        ParentItem.Modify();
        LibraryInventory.CreateBOMComponent(BOMComponent, ParentItem."No.", BOMComponent.Type::" ", '', 1, '');
        ParentItemDesc1 := LibraryUtility.GenerateRandomCode(BOMComponent.FieldNo(Description), DATABASE::"BOM Component");
        BOMComponent.Validate(Description, ParentItemDesc1);
        BOMComponent.Modify();
        LibraryInventory.CreateBOMComponent(BOMComponent, ParentItem."No.", BOMComponent.Type::Item, ChildItem."No.", 1, '');
        LibraryInventory.CreateBOMComponent(BOMComponent, ParentItem."No.", BOMComponent.Type::" ", '', 1, '');
        ParentItemDesc2 := LibraryUtility.GenerateRandomCode(BOMComponent.FieldNo(Description), DATABASE::"BOM Component");
        BOMComponent.Validate(Description, ParentItemDesc2);
        BOMComponent.Modify();

        // Make Asm header and lines
        LibraryAssembly.CreateAssemblyHeader(AsmHeader, DueDate, ParentItem."No.", '', LibraryRandom.RandInt(10), '');

        // EXERCISE
        // Call the explode BOM function
        if ExplodeBOMFromPage then begin
            AsmOrderTestPage.OpenEdit();
            AsmOrderTestPage.FILTER.SetFilter("Document Type", Format(AsmHeader."Document Type"::Order));
            AsmOrderTestPage.FILTER.SetFilter("No.", AsmHeader."No.");
            AsmOrderTestPage.Lines.FILTER.SetFilter(Type, Format(AsmLine.Type::Item));
            AsmOrderTestPage.Lines.FILTER.SetFilter("No.", ChildItem."No.");
            AsmOrderTestPage.First();
            AsmOrderTestPage.Lines.ExplodeBOM.Invoke();
        end else begin
            AsmLine.SetRange("Document Type", AsmHeader."Document Type");
            AsmLine.SetRange("Document No.", AsmHeader."No.");
            AsmLine.SetRange(Type, AsmLine.Type::Item);
            AsmLine.SetRange("No.", ChildItem."No.");
            AsmLine.FindSet();
            AsmLineMgt.ExplodeAsmList(AsmLine);
        end;

        // VERIFY
        AsmLine.Reset();
        FindAssemblyLine(AsmLine, AsmHeader);
        LineCount := 0;
        ExpectedNoLines := 7;
        repeat
            LineCount += 1;
            case LineCount of
                1: // line 1
                    begin
                        AsmLine.TestField(Type, AsmLine.Type::" ");
                        AsmLine.TestField("No.", '');
                        AsmLine.TestField(Description, ParentItemDesc1);
                    end;
                2: // line 2
                    begin
                        AsmLine.TestField(Type, AsmLine.Type::" ");
                        AsmLine.TestField("No.", ChildItem."No.");
                    end;
                3: // line 3
                    begin
                        AsmLine.TestField(Type, AsmLine.Type::" ");
                        AsmLine.TestField("No.", '');
                        AsmLine.TestField(Description, ChildItemDesc1);
                    end;
                4: // line 4
                    begin
                        AsmLine.TestField(Type, AsmLine.Type::Item);
                        AsmLine.TestField("No.", ChildChildItem."No.");
                    end;
                5: // line 5 - VSTF333535
                    begin
                        AsmLine.TestField(Type, AsmLine.Type::Resource);
                        AsmLine.TestField("No.", ResourceNo);
                    end;
                6: // line 6
                    begin
                        AsmLine.TestField(Type, AsmLine.Type::" ");
                        AsmLine.TestField("No.", '');
                        AsmLine.TestField(Description, ChildItemDesc2);
                    end;
                7: // line 7
                    begin
                        AsmLine.TestField(Type, AsmLine.Type::" ");
                        AsmLine.TestField("No.", '');
                        AsmLine.TestField(Description, ParentItemDesc2);
                    end;
            end;
        until AsmLine.Next() = 0;

        Assert.AreEqual(
          ExpectedNoLines,
          LineCount,
          StrSubstNo(MSGAssertLineCount, AsmHeader."No.", ExpectedNoLines, LineCount));

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    local procedure ValidateOrderUnitCost(AssemblyHeader: Record "Assembly Header"; ExpectedCost: Decimal)
    begin
        Assert.AreEqual(AssemblyHeader."Unit Cost", ExpectedCost,
          StrSubstNo('Bad Unit Cost of Assembly Order %1 Expected %2, got %3',
            AssemblyHeader."No.",
            ExpectedCost,
            AssemblyHeader."Unit Cost"));
    end;

    local procedure ValidateCount(OrderNo: Code[20]; "Count": Integer)
    var
        AssemblyHeader: Record "Assembly Header";
        LibraryAssembly: Codeunit "Library - Assembly";
    begin
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, OrderNo);
        Assert.AreEqual(Count, LibraryAssembly.LineCount(AssemblyHeader),
          StrSubstNo(MSGAssertLineCount, OrderNo, Count, LibraryAssembly.LineCount(AssemblyHeader)));
    end;

    local procedure ValidateQuantityonLines(OrderNo: Code[20]; "Count": Integer)
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, OrderNo);
        Assert.AreEqual(Count, LibraryKitting.TotalQuantity(AssemblyHeader),
          StrSubstNo('Bad Line Quantity of Order: %1 expected %2, got %3', OrderNo, Count, LibraryKitting.TotalQuantity(AssemblyHeader)));
    end;

    local procedure ValidateNo(AsmLine: Record "Assembly Line"; Number: Code[20])
    begin
        Assert.IsFalse((AsmLine.Type <> AsmLine.Type::Item) or (AsmLine."No." <> Number),
          StrSubstNo('Bad Item substitution in Line %1 Expected %2 got %3',
            AsmLine."Document No.",
            Number,
            AsmLine."No."));
    end;

    local procedure VerifyAssemblyLineQty(ItemNo: Code[20]; ExpectedQty: Decimal; ExpectedQtyBase: Decimal)
    var
        AssemblyLine: Record "Assembly Line";
    begin
        AssemblyLine.SetRange(Type, AssemblyLine.Type::Item);
        AssemblyLine.SetRange("No.", ItemNo);
        AssemblyLine.FindFirst();

        AssemblyLine.TestField(Quantity, ExpectedQty);
        AssemblyLine.TestField("Quantity (Base)", ExpectedQtyBase);
        AssemblyLine.TestField("Quantity per", ExpectedQty);
        AssemblyLine.TestField("Remaining Quantity", ExpectedQty);
        AssemblyLine.TestField("Remaining Quantity (Base)", ExpectedQtyBase);
        AssemblyLine.TestField("Quantity to Consume", ExpectedQty);
        AssemblyLine.TestField("Quantity to Consume (Base)", ExpectedQtyBase);
    end;

    local procedure VerifyDimOnAssemblyLine(ItemNo: Code[20]; DimSetID: Integer)
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
    begin
        AssemblyHeader.SetRange("Item No.", ItemNo);
        AssemblyHeader.FindFirst();
        AssemblyLine.SetRange("Document Type", AssemblyLine."Document Type"::Order);
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.FindFirst();
        Assert.AreEqual(DimSetID, AssemblyLine."Dimension Set ID", DimErr);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure StubMessageHandler(MessageText: Text)
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemSubstitutionPageHandler(var ItemSubstitutionEntries: Page "Item Substitution Entries"; var Response: Action)
    begin
        Response := ACTION::LookupOK;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure DueDateBeforeWorkDateMsgHandler(Message: Text)
    begin
        Assert.IsTrue(StrPos(Message, MSGDueDateBeforeWorkDate) > 0, MSGDueDateBeforeWorkDate);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure DimensionSetupRefreshConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue((StrPos(Question, RefreshingBomCnfm) > 0) or (StrPos(Question, UpdateDimCnfm) > 0),
          StrSubstNo('Wrong question: %1', Question));
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedConfirm(LibraryVariableStorage.DequeueText(), Question);
        Reply := true;
    end;

    [StrMenuHandler]
    procedure ExplodeBomHandler(Options: Text[1024]; var Choice: Integer; Instructions: Text[1024])
    begin
        Choice := 1;
    end;
}

