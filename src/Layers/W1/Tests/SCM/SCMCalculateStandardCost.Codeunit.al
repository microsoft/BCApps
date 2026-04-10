codeunit 137910 "SCM Calculate Standard Cost"
{
    // Target:
    //   CalcItem (BOM standard cost) and CalcAssemblySalesPrice (BOM unit price)
    //   of Codeunit 5812 Calculate Standard Cost
    // Approach:
    //   Syntesize test data (Item an BOM Component records) in each test method,
    //   end with a roll back leaving no trail in the DB.
    // Assumption:
    //   Test target does *NOT* call COMMIT
    // Demodata dependencies:
    //   a) UOM setup - 'PCS'
    //   b) Number Series 'ITEM1' and 'ITEM5'
    // Test data BOM structure:
    //   (0 x 0) parent
    //     + 1 * ( 300 x 400 )
    //     + 3 * ( 300 x 400 ) component
    //         + 2 * (   2 x   3 )
    //         + 4 * (  11 x  23 )
    //     + 2 * ( 200 x 360 )
    //   legend:
    //     BOM Component = '+ <quantity> '* Item
    //     Item          = '(<cost> 'x <price>') [<name of variable>]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Assembly] [BOM Component] [SCM]
    end;

    var
        LibraryKitting: Codeunit "Library - Kitting";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryResource: Codeunit "Library - Resource";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        CalcRecursionLevel: Integer;
        RecursionInstruction: Text[1024];
        TEXT_PART1: Label 'Part 1';
        TEXT_PART2: Label 'Part 2';
        TEXT_PART3: Label 'Part 3';
        TEXT_SUB1: Label 'Sub 1';
        TEXT_SUB2: Label 'Sub 2';
        ITEM_DESC: Label 'Test Calculate Cost/Price';
        Initialized: Boolean;

    [Normal]
    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Calculate Standard Cost");
        if Initialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Calculate Standard Cost");

        Initialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Calculate Standard Cost");
    end;

    [Test]
    [HandlerFunctions('PickCalcLevel,CalcProdBOM')]
    [Scope('OnPrem')]
    procedure AssemblyIncludesMfgItem()
    var
        asmTopItem: Record Item;
        asm1Item: Record Item;
        prod1Item: Record Item;
        BOMComponent: Record "BOM Component";
        childItem: Record Item;
    begin
        Initialize();
        asmTopItem.Get(CreateItem('ASM TOP', 0, 0));
        childItem.Get(CreateItem(TEXT_PART1, 1, 2));
        LibraryKitting.CreateBOMComponentLine(
          asmTopItem, BOMComponent.Type::Item, childItem."No.", 1, childItem."Base Unit of Measure", false);
        asm1Item.Get(CreateItem('ASM 1', 0, 0));
        childItem.Get(CreateItem(TEXT_PART2, 10, 20));
        LibraryKitting.CreateBOMComponentLine(
          asm1Item, BOMComponent.Type::Item, childItem."No.", 2, childItem."Base Unit of Measure", false);
        LibraryKitting.CreateBOMComponentLine(
          asmTopItem, BOMComponent.Type::Item, asm1Item."No.", 3, asm1Item."Base Unit of Measure", false);
        prod1Item.Get(CreateItem('PROD 1', 0, 0));

        LibraryManufacturing.AddProdBOMItem(prod1Item, CreateItem('PURCH 3', 100, 200), 4);
        LibraryManufacturing.AddProdBOMItem(prod1Item, TEXT_PART1, 5);
        LibraryKitting.CreateBOMComponentLine(
          asmTopItem, BOMComponent.Type::Item, prod1Item."No.", 6, prod1Item."Base Unit of Measure", false);

        TestCost('', asmTopItem, 0, 0, 0, 0, 0, 0, 0, 0);
        TestCost('', asmTopItem, 1 * 1 + 3 * 0 + 6 * 0, 1, 1 + 0 + 0, 0, 0, 1, 0, 0);
        TestCost('', asmTopItem, 1 * 1 + 3 * 2 * 10 + 6 * (4 * 100 + 5 * 1), 2, 1 + 60 + 2430, 0, 0, 2491, 0, 0);

        TestPrice('', asmTopItem, 0, 0);
        TestPrice('', asmTopItem, 1 * 2 + 3 * 0 + 6 * 0, 1);
        TestPrice('', asmTopItem, 1 * 2 + 3 * 2 * 20 + 6 * 0, 2); // Prod item price is not rolled up and stays 0

        asserterror Error('') // roll back
    end;

    [Test]
    [HandlerFunctions('PickCalcLevel')]
    [Scope('OnPrem')]
    procedure MfgBOMIncludesAssemblyItem()
    var
        prodTopItem: Record Item;
        asm1Item: Record Item;
        childItem: Record Item;
        BOMComponent: Record "BOM Component";
    begin
        Initialize();
        prodTopItem.Get(CreateItem('PROD TOP', 0, 0));
        childItem.Get(CreateItem(TEXT_PART1, 1, 2));
        LibraryManufacturing.AddProdBOMItem(prodTopItem, childItem."No.", 1);
        asm1Item.Get(CreateItem('ASM 1', 0, 0));
        LibraryKitting.CreateBOMComponentLine(
          asm1Item, BOMComponent.Type::Item, childItem."No.", 2, childItem."Base Unit of Measure", false);
        childItem.Get(CreateItem(TEXT_PART3, 10, 20));
        LibraryKitting.CreateBOMComponentLine(
          asm1Item, BOMComponent.Type::Item, childItem."No.", 3, childItem."Base Unit of Measure", false);
        LibraryManufacturing.AddProdBOMItem(prodTopItem, asm1Item."No.", 4);

        TestCost('', prodTopItem, 0, 0, 0, 0, 0, 0, 0, 0);
        TestCost('', prodTopItem, 1 * 1 + 4 * 0, 1, 1 + 0, 0, 0, 1, 0, 0);
        TestCost('', prodTopItem, 1 * 1 + 4 * (2 * 1 + 3 * 10), 2, 1 + 128, 0, 0, 129, 0, 0);

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NonBOMItem()
    var
        Item: Record Item;
    begin
        Initialize();
        Item.Get(CreateItem('NonBOM', 500, 700));
        asserterror TestCost('Cost', Item, 0, 0, 0, 0, 0, 0, 0, 0);
        asserterror TestPrice('Price', Item, 0, 0);
        // no roll back needed
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BOMItem()
    var
        ParentItem: Record Item;
        childItem: Record Item;
        BOMComponent: Record "BOM Component";
    begin
        Initialize();
        ParentItem.Get(CreateItem('Parent', 0, 0));
        childItem.Get(CreateItem(TEXT_PART1, 300, 400));
        LibraryKitting.CreateBOMComponentLine(
          ParentItem, BOMComponent.Type::Item, childItem."No.", 1, childItem."Base Unit of Measure", false);
        TestCost('One part', ParentItem, 1 * 300, 0, 300, 0, 0, 300, 0, 0);
        TestPrice('One part', ParentItem, 1 * 400, 0);

        childItem.Get(CreateItem(TEXT_PART2, 300, 400));
        LibraryKitting.CreateBOMComponentLine(
          ParentItem, BOMComponent.Type::Item, childItem."No.", 3, childItem."Base Unit of Measure", false);
        TestCost('Two parts', ParentItem, 300 + 3 * 300, 0, 1200, 0, 0, 1200, 0, 0);
        TestPrice('Two parts', ParentItem, 400 + 3 * 400, 0);

        childItem.Get(CreateItem(TEXT_PART3, 200, 360));
        LibraryKitting.CreateBOMComponentLine(
          ParentItem, BOMComponent.Type::Item, childItem."No.", 2, childItem."Base Unit of Measure", false);
        TestCost('Three parts', ParentItem, 1200 + 2 * 200, 0, 1600, 0, 0, 1600, 0, 0);
        TestPrice('Three parts', ParentItem, 1600 + 2 * 360, 0);

        asserterror Error('') // roll back
    end;

    [Test]
    [HandlerFunctions('PickCalcLevel')]
    [Scope('OnPrem')]
    procedure NestedBOMItem()
    var
        ParentItem: Record Item;
        childItem: Record Item;
        BOMComponentItem: Record Item;
        BOMComponent: Record "BOM Component";
    begin
        Initialize();
        ParentItem.Get(CreateItem('Parent', 0, 0));
        childItem.Get(CreateItem(TEXT_PART1, 300, 400));
        LibraryKitting.CreateBOMComponentLine(ParentItem, BOMComponent.Type::Item, childItem."No.", 1,
          childItem."Base Unit of Measure", false);
        BOMComponentItem.Get(CreateItem('Component', 300, 400));
        LibraryKitting.CreateBOMComponentLine(ParentItem, BOMComponent.Type::Item, BOMComponentItem."No.", 3,
          BOMComponentItem."Base Unit of Measure", false);

        childItem.Get(CreateItem(TEXT_PART2, 200, 360));
        LibraryKitting.CreateBOMComponentLine(ParentItem, BOMComponent.Type::Item, childItem."No.", 2,
          childItem."Base Unit of Measure", false);

        childItem.Get(CreateItem(TEXT_SUB1, 2, 3));
        LibraryKitting.CreateBOMComponentLine(BOMComponentItem, BOMComponent.Type::Item, childItem."No.", 3,
          childItem."Base Unit of Measure", false);
        TestCost('One Sub', ParentItem, 0, 0, 0, 0, 0, 0, 0, 0);
        ValidateCost('One Sub', BOMComponentItem, 300, 300, 0, 0, 300, 0, 0);
        TestCost('One Sub', ParentItem, 1600, 1, 1600, 0, 0, 1600, 0, 0); // 1*300 + 3*300 + 2*200
        ValidateCost('One Sub', BOMComponentItem, 300, 300, 0, 0, 300, 0, 0); // 300
        TestCost('One Sub', ParentItem, 718, 2, 718, 0, 0, 718, 0, 0); // 1*300 + 3 * 3 * 2 + 2*200
        ValidateCost('One Sub', BOMComponentItem, 6, 6, 0, 0, 6, 0, 0); // 3 * 2
        TestPrice('One Sub', ParentItem, 0, 0);
        ValidatePrice('One Sub', BOMComponentItem, 400);
        TestPrice('One Sub', ParentItem, 2320, 1);
        ValidatePrice('One Sub', BOMComponentItem, 400);
        TestPrice('One Sub', ParentItem, 1147, 2);
        ValidatePrice('One Sub', BOMComponentItem, 9);

        childItem.Get(CreateItem(TEXT_SUB2, 11, 23));
        LibraryKitting.CreateBOMComponentLine(BOMComponentItem, BOMComponent.Type::Item, childItem."No.", 4,
          childItem."Base Unit of Measure", false);
        TestCost('Two Subs', ParentItem, 718, 0, 718, 0, 0, 718, 0, 0);
        ValidateCost('Two Subs', BOMComponentItem, 6, 6, 0, 0, 6, 0, 0);
        TestCost('Two Subs', ParentItem, 718, 1, 718, 0, 0, 718, 0, 0);
        ValidateCost('Two Subs', BOMComponentItem, 6, 6, 0, 0, 6, 0, 0);
        TestCost('Two Subs', ParentItem, 850, 2, 850, 0, 0, 850, 0, 0);
        ValidateCost('Two Subs', BOMComponentItem, 50, 50, 0, 0, 50, 0, 0);
        TestPrice('Two Subs', ParentItem, 1147, 0);
        ValidatePrice('Two Subs', BOMComponentItem, 9);
        TestPrice('Two Subs', ParentItem, 1147, 1);
        ValidatePrice('Two Subs', BOMComponentItem, 9);
        TestPrice('Two Subs', ParentItem, 1423, 2);
        ValidatePrice('Two Subs', BOMComponentItem, 101);

        asserterror Error('') // roll back
    end;

    local procedure AssertContains(String: Text[1024]; SubString: Text[1024])
    begin
        Assert.IsFalse(StrPos(String, SubString) = 0,
          StrSubstNo('Text ''%1'' should contain ''%2''', String, SubString))
    end;

    local procedure AssertNotContains(String: Text[1024]; SubString: Text[1024])
    begin
        Assert.IsFalse(StrPos(String, SubString) <> 0,
          StrSubstNo('Text ''%1'' should not contain ''%2''', String, SubString))
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorTexts()
    var
        Item: Record Item;
    begin
        Initialize();
        Item.Get(CreateItem('NonAssemblyForCost', 500, 700));
        asserterror TestCost('', Item, 0, 0, 0, 0, 0, 0, 0, 0);
        AssertContains(GetLastErrorText, 'does not use replenishment system Assembly');
        AssertContains(GetLastErrorText, Format(Item."No."));
        AssertContains(GetLastErrorText, Item.Description);
        AssertContains(GetLastErrorText, 'Standard Cost');

        Item.Get(CreateItem('NonAssemblyForPrice', 500, 700));
        asserterror TestPrice('', Item, 0, 0);
        AssertContains(GetLastErrorText, 'does not use replenishment system Assembly');
        AssertContains(GetLastErrorText, Format(Item."No."));
        AssertContains(GetLastErrorText, Item.Description);
        AssertContains(GetLastErrorText, 'Unit Price');

        Item.Get(CreateItem('AssemblyForCost', 500, 700));
        Item."Replenishment System" := Item."Replenishment System"::Assembly;
        asserterror TestCost('', Item, 0, 0, 0, 0, 0, 0, 0, 0);
        AssertContains(GetLastErrorText, 'has no assembly list');
        AssertContains(GetLastErrorText, Format(Item."No."));
        AssertContains(GetLastErrorText, Item.Description);
        AssertContains(GetLastErrorText, 'Standard Cost');

        Item.Get(CreateItem('AssemblyForPrice', 500, 700));
        Item."Replenishment System" := Item."Replenishment System"::Assembly;
        asserterror TestPrice('', Item, 0, 0);
        AssertContains(GetLastErrorText, 'has no assembly list');
        AssertContains(GetLastErrorText, Format(Item."No."));
        AssertContains(GetLastErrorText, Item.Description);
        AssertContains(GetLastErrorText, 'Unit Price');
    end;

    [Test]
    [HandlerFunctions('CaptureInstruction')]
    [Scope('OnPrem')]
    procedure RecursionPrompt()
    var
        ParentItem: Record Item;
        childItem: Record Item;
        ComponentItem: Record Item;
        BOMComponent: Record "BOM Component";
    begin
        Initialize();
        ParentItem.Get(CreateItem('Parent', 0, 0));
        ComponentItem.Get(CreateItem('Component', 300, 400));
        LibraryKitting.CreateBOMComponentLine(ParentItem, BOMComponent.Type::Item, ComponentItem."No.", 3,
          ComponentItem."Base Unit of Measure", false);
        childItem.Get(CreateItem(TEXT_SUB1, 200, 360));
        LibraryKitting.CreateBOMComponentLine(ComponentItem, BOMComponent.Type::Item, childItem."No.", 2,
          childItem."Base Unit of Measure", false);

        RecursionInstruction := '';
        TestCost('', ParentItem, 0, 0, 0, 0, 0, 0, 0, 0);
        AssertContains(RecursionInstruction, 'Calculate');
        AssertContains(RecursionInstruction, 'rolling up the assembly list components');
        AssertContains(RecursionInstruction, Format(ParentItem."No."));
        AssertContains(RecursionInstruction, ParentItem.Description);
        AssertContains(RecursionInstruction, 'Standard Cost');
        AssertNotContains(RecursionInstruction, 'Are you sure that you want to continue?');

        RecursionInstruction := '';
        TestPrice('', ParentItem, 0, 0);
        AssertContains(RecursionInstruction, 'Calculate');
        AssertContains(RecursionInstruction, 'rolling up the assembly list components');
        AssertContains(RecursionInstruction, Format(ParentItem."No."));
        AssertContains(RecursionInstruction, ParentItem.Description);
        AssertContains(RecursionInstruction, 'Unit Price');
        AssertNotContains(RecursionInstruction, 'Are you sure that you want to continue?');

        asserterror Error('') // roll back
    end;

    [Test]
    [HandlerFunctions('CaptureInstruction')]
    [Scope('OnPrem')]
    procedure NonAssemblyWithListWarning()
    var
        ParentItem: Record Item;
        ComponentItem: Record Item;
        childItem: Record Item;
        BOMComponent: Record "BOM Component";
    begin
        Initialize();
        ParentItem.Get(CreateItem('Parent', 0, 0));
        ComponentItem.Get(CreateItem('Component1', 300, 400));
        LibraryKitting.CreateBOMComponentLine(ParentItem, BOMComponent.Type::Item, ComponentItem."No.", 3,
          ComponentItem."Base Unit of Measure", false);
        childItem.Get(CreateItem(TEXT_SUB1, 200, 360));
        LibraryKitting.CreateBOMComponentLine(ComponentItem, BOMComponent.Type::Item, childItem."No.", 2,
          childItem."Base Unit of Measure", false);
        ComponentItem.Get(CreateItem('Component2', 30, 40));
        LibraryKitting.CreateBOMComponentLine(ParentItem, BOMComponent.Type::Item, ComponentItem."No.", 7,
          ComponentItem."Base Unit of Measure", false);
        childItem.Get(CreateItem(TEXT_SUB2, 20, 36));
        LibraryKitting.CreateBOMComponentLine(ComponentItem, BOMComponent.Type::Item, childItem."No.", 2,
          childItem."Base Unit of Measure", false);
        ComponentItem."Replenishment System" := ComponentItem."Replenishment System"::Purchase;
        ComponentItem.Modify(false);

        RecursionInstruction := '';
        TestCost('', ParentItem, 0, 0, 0, 0, 0, 0, 0, 0);
        AssertContains(RecursionInstruction, 'Calculate');
        AssertContains(RecursionInstruction, 'rolling up the assembly list components');
        AssertContains(RecursionInstruction, Format(ParentItem."No."));
        AssertContains(RecursionInstruction, ParentItem.Description);
        AssertContains(RecursionInstruction, 'Standard Cost');
        AssertContains(RecursionInstruction, 'Are you sure that you want to continue?');

        RecursionInstruction := '';
        TestPrice('', ParentItem, 0, 0);
        AssertContains(RecursionInstruction, 'Calculate');
        AssertContains(RecursionInstruction, 'rolling up the assembly list components');
        AssertContains(RecursionInstruction, Format(ParentItem."No."));
        AssertContains(RecursionInstruction, ParentItem.Description);
        AssertContains(RecursionInstruction, 'Unit Price');
        AssertContains(RecursionInstruction, 'Are you sure that you want to continue?');

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseAndNonAssemblyWithList()
    var
        ParentItem: Record Item;
        ComponentItem: Record Item;
        BOMComponent: Record "BOM Component";
    begin
        Initialize();
        ParentItem.Get(CreateItem('Parent', 0, 0));
        ComponentItem.Get(CreateItem('Component1', 300, 400));
        LibraryKitting.CreateBOMComponentLine(ParentItem, BOMComponent.Type::Item, ComponentItem."No.", 3,
          ComponentItem."Base Unit of Measure", false);
        ComponentItem."Replenishment System" := ComponentItem."Replenishment System"::Purchase;
        ComponentItem.Modify(false);
        ComponentItem.Get(CreateItem('Component2', 30, 40));
        LibraryKitting.CreateBOMComponentLine(ParentItem, BOMComponent.Type::Item, ComponentItem."No.", 7,
          ComponentItem."Base Unit of Measure", false);
        ComponentItem."Replenishment System" := ComponentItem."Replenishment System"::Assembly;
        ComponentItem.Modify(false);

        TestCost('', ParentItem, 3 * 300 + 7 * 30, 0, 1110, 0, 0, 1110, 0, 0);
        TestPrice('', ParentItem, 3 * 400 + 7 * 40, 0);

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CostSharesDocSample()
    var
        ItemA: Record Item;
        ResourceA: Record Resource;
        ItemB: Record Item;
        ItemC: Record Item;
        BOMComponent: Record "BOM Component";
    begin
        Initialize();
        ItemA.Get(CreateItem('ItemA', 0, 0));
        LibraryResource.CreateResourceNew(ResourceA);
        ResourceA."Unit Cost" := 11;
        ResourceA."Direct Unit Cost" := 5;
        ResourceA.Modify();
        LibraryKitting.CreateBOMComponentLine(
          ItemA, BOMComponent.Type::Resource, ResourceA."No.", 1, ResourceA."Base Unit of Measure", false);
        ItemB.Get(CreateAsmItem('ItemB', 16, 10, 3, 3, 10, 3, 3));

        ItemC.Get(CreateAsmItem('ItemC', 8, 5, 2, 1, 5, 2, 1));
        LibraryKitting.CreateBOMComponentLine(ItemA, BOMComponent.Type::Item, ItemB."No.", 1,
          ItemB."Base Unit of Measure", false);
        LibraryKitting.CreateBOMComponentLine(ItemA, BOMComponent.Type::Item, ItemC."No.", 1,
          ItemC."Base Unit of Measure", false);

        TestCost('', ItemA, 16 + 8 + 5 + 6, 1, 16 + 8, 5, 6, 10 + 5, 3 + 2 + 5, 3 + 1 + 6);

        asserterror Error('') // roll back
    end;

    [Test]
    [HandlerFunctions('PickCalcLevel')]
    [Scope('OnPrem')]
    procedure RollupCalculationScenario()
    var
        ItemA: Record Item;
        ItemB: Record Item;
        ItemC: Record Item;
        ItemD: Record Item;
        ItemE: Record Item;
        ResourceA: Record Resource;
        ResourceB: Record Resource;
        ResourceC: Record Resource;
        BOMComponent: Record "BOM Component";
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
    begin
        Initialize();
        ItemA.Get(CreateItem('ITEM A', 0, 0));
        ItemA."Indirect Cost %" := 10;
        ItemA.Modify(true);
        ItemB.Get(CreateItem('ITEM B', 0, 0));
        ItemB."Indirect Cost %" := 10;
        ItemB.Modify(true);
        ItemC.Get(CreateItem('ITEM C', 0, 0));
        ItemC."Indirect Cost %" := 10;
        ItemC.Modify(true);
        ItemD.Get(CreateItem('ITEM D', 10, 0));
        ItemD."Indirect Cost %" := 10;
        ItemD.Modify(true);
        ItemE.Get(CreateItem('ITEM E', 10, 0));
        ItemE."Indirect Cost %" := 10;
        ItemE.Modify(true);
        LibraryResource.CreateResourceNew(ResourceA);
        ResourceA."Unit Cost" := 11;
        ResourceA."Direct Unit Cost" := 10;
        ResourceA.Modify(true);
        LibraryResource.CreateResourceNew(ResourceB);
        ResourceB."Unit Cost" := 11;
        ResourceB."Direct Unit Cost" := 10;
        ResourceB.Modify(true);
        LibraryResource.CreateResourceNew(ResourceC);
        ResourceC."Unit Cost" := 11;
        ResourceC."Direct Unit Cost" := 10;
        ResourceC.Modify(true);
        LibraryKitting.CreateBOMComponentLine(ItemA, BOMComponent.Type::Item, ItemB."No.", 1,
          ItemB."Base Unit of Measure", false);
        LibraryKitting.CreateBOMComponentLine(ItemA, BOMComponent.Type::Resource, ResourceA."No.", 1,
          ResourceA."Base Unit of Measure", false);
        LibraryKitting.CreateBOMComponentLine(ItemA, BOMComponent.Type::Item, ItemC."No.", 2,
          ItemC."Base Unit of Measure", false);
        LibraryKitting.CreateBOMComponentLine(ItemB, BOMComponent.Type::Item, ItemD."No.", 1,
          ItemD."Base Unit of Measure", false);
        LibraryKitting.CreateBOMComponentLine(ItemB, BOMComponent.Type::Resource, ResourceB."No.", 2,
          ResourceB."Base Unit of Measure", false);
        LibraryKitting.CreateBOMComponentLine(ItemC, BOMComponent.Type::Item, ItemE."No.", 2,
          ItemE."Base Unit of Measure", false);
        LibraryKitting.CreateBOMComponentLine(ItemC, BOMComponent.Type::Resource, ResourceC."No.", 3,
          ResourceC."Base Unit of Measure", false);

        CalcRecursionLevel := 2;
        CalculateStandardCost.CalcItem('ITEM A', true);
        ValidateCost('', ItemB, 35.2, 10, 20, 2, 10, 20, 2);
        ValidateCost('', ItemC, 58.3, 20, 30, 3, 20, 30, 3);
        ValidateCost('', ItemA, 179.08, 151.8, 10, 1, 50, 90, 9);

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PriceOfResourceBUG173923()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        grandChildItem: Record Item;
        Res: Record Resource;
        BOMComponent: Record "BOM Component";
    begin
        Initialize();
        ParentItem.Get(CreateItem(TEXT_PART1, 0, 0));
        ChildItem.Get(CreateItem(TEXT_PART2, 10, 15));
        grandChildItem.Get(CreateItem(TEXT_SUB1, 2, 3));
        LibraryKitting.CreateBOMComponentLine(ChildItem, BOMComponent.Type::Item, grandChildItem."No.", 4,
          grandChildItem."Base Unit of Measure", false);
        ChildItem."Replenishment System" := ChildItem."Replenishment System"::Purchase;
        ChildItem.Modify(true);
        LibraryKitting.CreateBOMComponentLine(ParentItem, BOMComponent.Type::Item, ChildItem."No.", 1,
          ChildItem."Base Unit of Measure", false);
        LibraryResource.CreateResourceNew(Res);
        Res."Direct Unit Cost" := 40;
        Res."Unit Cost" := 40;
        Res."Unit Price" := 50;
        Res.Modify();
        LibraryKitting.CreateBOMComponentLine(ParentItem, BOMComponent.Type::Resource, Res."No.", 1,
          Res."Base Unit of Measure", false);

        // This was the old test before changing the resource overhead into resource cost
        // TestCost('',ParentItem,1*10 + 1*40,0, 10,0,40, 10,0,40);
        TestCost('', ParentItem, 1 * 10 + 1 * 40, 0, 10, 40, 0, 10, 40, 0);

        TestPrice('', ParentItem, 1 * 65, 0);

        asserterror Error('') // roll back
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure PickCalcLevel(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := CalcRecursionLevel
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure CaptureInstruction(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        RecursionInstruction := Instruction;
        Choice := 0
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure CalcProdBOM(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.AreNotEqual(
          StrPos(Question, 'Do you want to calculate standard cost for those subassemblies?'), 0,
          'Unexpected CONFIRM');
        Reply := true
    end;

    local procedure ValidateCost(TestCase: Text[250]; var Item: Record Item; Cost: Decimal; SLMat: Decimal; SLRes: Decimal; SLResOvhd: Decimal; RUMat: Decimal; RURes: Decimal; RUResOvhd: Decimal)
    var
        errors: Text[1024];
    begin
        Item.Get(Item."No.");
        if Item."Standard Cost" <> Cost then
            errors += StrSubstNo('\Bad Standard Cost of %3. expected %1, got %2', Cost, Item."Standard Cost", Item."No.");
        if (Item."Single-Level Material Cost" <> SLMat) or
           (Item."Single-Level Capacity Cost" <> SLRes) or
           (Item."Single-Level Cap. Ovhd Cost" <> SLResOvhd)
        then
            errors += StrSubstNo(
                '\Bad single-level cost structure [Material x Resource x Res. Overhead)] of %7. ' +
                'expected: [%1 x %2 x %3]  got: [%4 x %5 x %6]',
                SLMat, SLRes, SLResOvhd,
                Item."Single-Level Material Cost", Item."Single-Level Capacity Cost", Item."Single-Level Cap. Ovhd Cost",
                Item."No.");
        if (Item."Rolled-up Material Cost" <> RUMat) or
           (Item."Rolled-up Capacity Cost" <> RURes) or
           (Item."Rolled-up Cap. Overhead Cost" <> RUResOvhd)
        then
            errors += StrSubstNo(
                '\Bad rolled-up cost structure [ (Material x Resource x Res. Overhead)]. of %7 ' +
                'expected: [%1 x %2 x %3]  got: [%4 x %5 x %6]',
                RUMat, RURes, RUResOvhd,
                Item."Rolled-up Material Cost", Item."Rolled-up Capacity Cost", Item."Rolled-up Cap. Overhead Cost",
                Item."No.");
        if Item."Standard Cost" <>
           Item."Single-Level Material Cost" +
           Item."Single-Level Capacity Cost" +
           Item."Single-Level Cap. Ovhd Cost" +
           Item."Single-Level Mfg. Ovhd Cost" +
           Item."Single-Level Subcontrd. Cost"
        then
            errors += StrSubstNo(
                '\Standard Cost, %1, does not equal sum of single-level cost shares, %2',
                Item."Standard Cost",
                Item."Single-Level Material Cost" +
                Item."Single-Level Capacity Cost" +
                Item."Single-Level Cap. Ovhd Cost" +
                Item."Single-Level Mfg. Ovhd Cost" +
                Item."Single-Level Subcontrd. Cost");
        if Item."Standard Cost" <>
           Item."Rolled-up Material Cost" +
           Item."Rolled-up Capacity Cost" +
           Item."Rolled-up Cap. Overhead Cost" +
           Item."Rolled-up Mfg. Ovhd Cost" +
           Item."Rolled-up Subcontracted Cost"
        then
            errors += StrSubstNo(
                '\Standard Cost, %1, does not equal sum of rolled-up cost shares, %2',
                Item."Standard Cost",
                Item."Rolled-up Material Cost" +
                Item."Rolled-up Capacity Cost" +
                Item."Rolled-up Cap. Overhead Cost" +
                Item."Rolled-up Mfg. Ovhd Cost" +
                Item."Rolled-up Subcontracted Cost");
        Assert.AreEqual(errors, '', TestCase + ':' + errors)
    end;

    local procedure TestCost(TestCase: Text[30]; var Item: Record Item; Cost: Decimal; Recursion: Integer; SLMat: Decimal; SLRes: Decimal; SLResOvhd: Decimal; RUMat: Decimal; RURes: Decimal; RUResOvhd: Decimal)
    var
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
    begin
        Item.Modify(true);
        CalcRecursionLevel := Recursion;
        CalculateStandardCost.CalcItem(Item."No.", not Item.IsMfgItem());
        ValidateCost(TestCase + ', recursion=' + Format(Recursion),
          Item, Cost, SLMat, SLRes, SLResOvhd, RUMat, RURes, RUResOvhd);
        CalculateStandardCost.CalcItem(Item."No.", not Item.IsMfgItem());
        ValidateCost('2nd ' + TestCase + ', recursion=' + Format(Recursion),
          Item, Cost, SLMat, SLRes, SLResOvhd, RUMat, RURes, RUResOvhd)
    end;

    local procedure ValidatePrice(TestCase: Text[250]; var Item: Record Item; Price: Decimal)
    begin
        Item.Get(Item."No.");
        Assert.AreEqual(Item."Unit Price", Price,
          StrSubstNo(TestCase + ': Bad Unit Price of %3. expected %1, got %2', Price, Item."Unit Price", Item."No."))
    end;

    local procedure TestPrice(TestCase: Text[30]; var Item: Record Item; Price: Decimal; Recursion: Integer)
    var
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
    begin
        Item.Modify(true);
        CalcRecursionLevel := Recursion;
        CalculateStandardCost.CalcAssemblyItemPrice(Item."No.");
        ValidatePrice(TestCase + ', recursion=' + Format(Recursion), Item, Price);
        CalculateStandardCost.CalcAssemblyItemPrice(Item."No.");
        ValidatePrice('2nd ' + TestCase + ', recursion=' + Format(Recursion), Item, Price)
    end;

    local procedure CreateItem(No: Code[20]; Cost: Decimal; Price: Decimal): Code[20]
    var
        UOM: Record "Unit of Measure";
    begin
        LibraryInventory.CreateUnitOfMeasureCode(UOM);
        exit(LibraryKitting.ItemCreate(No, ITEM_DESC, UOM.Code, Price, Cost))
    end;

    local procedure CreateAsmItem(No: Code[20]; Cost: Decimal; SLMat: Decimal; SLRes: Decimal; SLResOvhd: Decimal; RUMat: Decimal; RURes: Decimal; RUResOvhd: Decimal): Code[20]
    var
        item: Record Item;
        UOM: Record "Unit of Measure";
    begin
        LibraryInventory.CreateUnitOfMeasureCode(UOM);
        LibraryKitting.ItemCreate(No, ITEM_DESC, UOM.Code, 0, Cost);
        item.Get(No);
        item."Standard Cost" := Cost;
        item."Single-Level Material Cost" := SLMat;
        item."Single-Level Capacity Cost" := SLRes;
        item."Single-Level Cap. Ovhd Cost" := SLResOvhd;
        item."Single-Level Mfg. Ovhd Cost" := Cost - SLMat - SLRes - SLResOvhd;
        item."Rolled-up Material Cost" := RUMat;
        item."Rolled-up Capacity Cost" := RURes;
        item."Rolled-up Cap. Overhead Cost" := RUResOvhd;
        item."Rolled-up Mfg. Ovhd Cost" := Cost - RUMat - RURes - RUResOvhd;
        item."Replenishment System" := item."Replenishment System"::Assembly;
        item.Modify(true);
        ValidateCost('', item, Cost, SLMat, SLRes, SLResOvhd, RUMat, RURes, RUResOvhd);
        exit(No)
    end;
}

