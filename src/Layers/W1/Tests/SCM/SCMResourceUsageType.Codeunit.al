codeunit 137909 "SCM Resource Usage Type"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [BOM Component] [Resource] [SCM]
    end;

    var
        LibraryKitting: Codeunit "Library - Kitting";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        CalcRecursionLevel: Integer;
        Initialized: Boolean;

    [Normal]
    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Resource Usage Type");
        if Initialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Resource Usage Type");

        Initialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Resource Usage Type");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OneResource()
    var
        ParentItem: Record Item;
        BOMComp: Record "BOM Component";
        resource: Record Resource;
    begin
        Initialize();
        ParentItem.Get(LibraryKitting.CreateItemWithLotAndNewUOM(500, 700, 1));
        resource.Get(LibraryKitting.CreateResourceWithNewUOM(100, 0));
        LibraryKitting.CreateBOMComponentLine(
          ParentItem, BOMComp.Type::Resource, resource."No.", 1, resource."Base Unit of Measure", false);
        calcThenValidateCost(ParentItem."No.", 100, 2);
        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OneResource10()
    var
        ParentItem: Record Item;
        resource: Record Resource;
    begin
        Initialize();
        ParentItem.Get(LibraryKitting.CreateItemWithLotAndNewUOM(500, 700, 10));
        resource.Get(LibraryKitting.CreateResourceWithNewUOM(100, 0));
        LibraryKitting.CreateBOMComponentLine(
          ParentItem, "BOM Component Type"::Resource, resource."No.", 10, resource."Base Unit of Measure", false);
        calcThenValidateCost(ParentItem."No.", 1000, 1);
        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OneResource10Fixed()
    var
        ParentItem: Record Item;
        resource: Record Resource;
    begin
        Initialize();
        ParentItem.Get(LibraryKitting.CreateItemWithLotAndNewUOM(500, 700, 10));
        resource.Get(LibraryKitting.CreateResourceWithNewUOM(100, 0));
        LibraryKitting.CreateBOMComponentLine(ParentItem, "BOM Component Type"::Resource, resource."No.", 5, resource."Base Unit of Measure", true);
        calcThenValidateCost(ParentItem."No.", 50, 1);
        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TwoResources()
    var
        ParentItem: Record Item;
        resource: Record Resource;
    begin
        Initialize();
        ParentItem.Get(LibraryKitting.CreateItemWithLotAndNewUOM(500, 700, 10));
        resource.Get(LibraryKitting.CreateResourceWithNewUOM(100, 0));
        LibraryKitting.CreateBOMComponentLine(ParentItem, "BOM Component Type"::Resource, resource."No.", 5, resource."Base Unit of Measure", true);
        resource.Get(LibraryKitting.CreateResourceWithNewUOM(100, 0));
        LibraryKitting.CreateBOMComponentLine(
          ParentItem, "BOM Component Type"::Resource, resource."No.", 10, resource."Base Unit of Measure", false);
        calcThenValidateCost(ParentItem."No.", 1050, 1);
        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OneResourceOneItem()
    var
        ParentItem: Record Item;
        BOMComp: Record "BOM Component";
        childItem: Record Item;
        resource: Record Resource;
    begin
        Initialize();
        ParentItem.Get(LibraryKitting.CreateItemWithLotAndNewUOM(500, 700, 1));
        resource.Get(LibraryKitting.CreateResourceWithNewUOM(100, 0));
        LibraryKitting.CreateBOMComponentLine(
          ParentItem, BOMComp.Type::Resource, resource."No.", 1, resource."Base Unit of Measure", false);
        childItem.Get(LibraryKitting.CreateItemWithNewUOM(300, 400));
        LibraryKitting.CreateBOMComponentLine(ParentItem, BOMComp.Type::Item, childItem."No.", 1, childItem."Base Unit of Measure", false);
        calcThenValidateCost(ParentItem."No.", 400, 1);
        asserterror Error('') // roll back
    end;

    [Test]
    [HandlerFunctions('pickCalcLevel')]
    [Scope('OnPrem')]
    procedure NestedBOMItem()
    var
        ParentItem: Record Item;
        ComponentItem: Record Item;
        subComponentItem: Record Item;
        BOMComp: Record "BOM Component";
        resource: Record Resource;
        auxId: Code[20];
    begin
        Initialize();
        ParentItem.Get(LibraryKitting.CreateItemWithLotAndNewUOM(0, 0, 10));
        ComponentItem.Get(LibraryKitting.CreateItemWithNewUOM(300, 400));
        LibraryKitting.CreateBOMComponentLine(
          ParentItem, BOMComp.Type::Item, ComponentItem."No.", 1, ComponentItem."Base Unit of Measure", false);
        calcThenValidatePrice(ParentItem."No.", 400, 0);
        ComponentItem.Get(LibraryKitting.CreateItemWithNewUOM(300, 400));

        LibraryKitting.CreateBOMComponentLine(
          ParentItem, BOMComp.Type::Item, ComponentItem."No.", 3, ComponentItem."Base Unit of Measure", false);
        calcThenValidatePrice(ParentItem."No.", 1600, 0);
        auxId := ComponentItem."No.";
        ComponentItem.Get(LibraryKitting.CreateItemWithNewUOM(200, 360));
        LibraryKitting.CreateBOMComponentLine(
          ParentItem, BOMComp.Type::Item, ComponentItem."No.", 2, ComponentItem."Base Unit of Measure", false);
        ComponentItem.Get(auxId);
        calcThenValidatePrice(ParentItem."No.", 2320, 0);
        resource.Get(LibraryKitting.CreateResourceWithNewUOM(100, 0));
        LibraryKitting.CreateBOMComponentLine(
          ParentItem, BOMComp.Type::Resource, resource."No.", 5, resource."Base Unit of Measure", false);

        subComponentItem.Get(LibraryKitting.CreateItemWithNewUOM(2, 3));
        LibraryKitting.CreateBOMComponentLine(
          ComponentItem, BOMComp.Type::Item, subComponentItem."No.", 3, subComponentItem."Base Unit of Measure", false);
        calcThenValidatePrice(ParentItem."No.", -999, 0);
        validatePrice(ComponentItem."No.", 400);
        calcThenValidatePrice(ParentItem."No.", 2320, 1);
        validatePrice(ComponentItem."No.", 400);
        calcThenValidatePrice(ParentItem."No.", 1147, 2);
        validatePrice(ComponentItem."No.", 9);
        subComponentItem.Get(LibraryKitting.CreateItemWithNewUOM(11, 23));
        LibraryKitting.CreateBOMComponentLine(
          ComponentItem, BOMComp.Type::Item, subComponentItem."No.", 4, subComponentItem."Base Unit of Measure", false);
        calcThenValidatePrice(ParentItem."No.", -999, 0);
        validatePrice(ComponentItem."No.", 400);
        calcThenValidatePrice(ParentItem."No.", 2320, 1);
        validatePrice(ComponentItem."No.", 400);
        calcThenValidatePrice(ParentItem."No.", 1423, 2);
        validatePrice(ComponentItem."No.", 101);
        resource.Get(LibraryKitting.CreateResourceWithNewUOM(100, 0));
        LibraryKitting.CreateBOMComponentLine(
          ComponentItem, BOMComp.Type::Resource, resource."No.", 5, resource."Base Unit of Measure", false);
        calcThenValidatePrice(ParentItem."No.", -999, 0);
        validatePrice(ComponentItem."No.", 400);
        calcThenValidatePrice(ParentItem."No.", 2320, 1);
        validatePrice(ComponentItem."No.", 400);
        calcThenValidatePrice(ParentItem."No.", 1423, 2);
        validatePrice(ComponentItem."No.", 101);

        validateCost(ComponentItem."No.", 300); // initial cost
        calcThenValidateCost(ParentItem."No.", 2850, 2);
        validateCost(ComponentItem."No.", 2 * 3 + 11 * 4 + 100 * 5); // calculated cost
        asserterror Error('') // roll back
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure pickCalcLevel(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := CalcRecursionLevel
    end;

    local procedure validateCost(itemNo: Code[20]; cost: Decimal)
    var
        item: Record Item;
    begin
        item.Get(itemNo);
        Assert.AreEqual(item."Unit Cost", cost,
          StrSubstNo('Bad Unit Cost of %3. expected %1, got %2', cost, item."Unit Cost", itemNo));
    end;

    local procedure calcThenValidateCost(itemNo: Code[20]; cost: Decimal; recursion: Integer)
    var
        item: Record Item;
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
    begin
        item.Get(itemNo);
        item."Unit Cost" := -999;
        item.Modify();
        CalcRecursionLevel := recursion;
        CalculateStandardCost.CalcItem(itemNo, true);
        validateCost(itemNo, cost);
    end;

    local procedure validatePrice(itemNo: Code[20]; price: Decimal)
    var
        item: Record Item;
    begin
        item.Get(itemNo);
        Assert.AreEqual(item."Unit Price", price,
          StrSubstNo('Bad Unit Price of %3. expected %1, got %2', price, item."Unit Price", itemNo));
    end;

    local procedure calcThenValidatePrice(itemNo: Code[20]; price: Decimal; recursion: Integer)
    var
        item: Record Item;
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
    begin
        item.Get(itemNo);
        item."Unit Price" := -999;
        item.Modify();
        CalcRecursionLevel := recursion;
        CalculateStandardCost.CalcAssemblyItemPrice(itemNo);
        validatePrice(itemNo, price);
    end;
}

