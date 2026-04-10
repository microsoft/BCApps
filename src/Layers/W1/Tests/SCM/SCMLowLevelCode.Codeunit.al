codeunit 137053 "SCM Low-Level Code"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        CloseBOMQst: Label 'All versions attached to the BOM will be closed. Close BOM?';
        ConfirmQst: Label 'Calculate low-level code?';
        RecursiveLoopDetected: Label 'A recursive loop was found in the following chain of nodes: %1.';

    trigger OnRun()
    begin
        // [FEATURE] [Planning] [SCM]        
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('BOMConfirmHandler')]
    procedure TestLowLevelCode()
    var
        ItemA: Record Item;
        ItemB: Record Item;
        ItemC: Record Item;
        ItemD: Record Item;
        ItemE: Record Item;
        LowLevelCodeCalculator: Codeunit "Low-Level Code Calculator";
    begin
        DeleteDemoDataEntities();
        Create5ItemHierarchy(ItemA, ItemB, ItemC, ItemD, ItemE);

        ClearAllLowLevelCodes();
        LowLevelCodeCalculator.Calculate();

        VerifyItemLowLevelCode(ItemA."No.", 0);
        VerifyItemLowLevelCode(ItemB."No.", 1);
        VerifyItemLowLevelCode(ItemC."No.", 2);
        VerifyItemLowLevelCode(ItemD."No.", 4);
        VerifyItemLowLevelCode(ItemE."No.", 3);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('BOMConfirmHandler')]
    procedure TestLowLevelCodeWithoutResettingLowLevelCodes()
    var
        ItemA: Record Item;
        ItemB: Record Item;
        ItemC: Record Item;
        ItemD: Record Item;
        ItemE: Record Item;
        LowLevelCodeCalculator: Codeunit "Low-Level Code Calculator";
    begin
        DeleteDemoDataEntities();
        Create5ItemHierarchy(ItemA, ItemB, ItemC, ItemD, ItemE);

        LowLevelCodeCalculator.Calculate();

        VerifyItemLowLevelCode(ItemA."No.", 0);
        VerifyItemLowLevelCode(ItemB."No.", 1);
        VerifyItemLowLevelCode(ItemC."No.", 2);
        VerifyItemLowLevelCode(ItemD."No.", 4);
        VerifyItemLowLevelCode(ItemE."No.", 3);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('BOMConfirmHandler')]
    procedure TestSameItemReAddedToBOMs()
    var
        ItemA: Record Item;
        ItemB: Record Item;
        ItemC: Record Item;
        ItemD: Record Item;
        ItemE: Record Item;
        LowLevelCodeCalculator: Codeunit "Low-Level Code Calculator";
    begin
        DeleteDemoDataEntities();
        Create5ItemHierarchy(ItemA, ItemB, ItemC, ItemD, ItemE);

        AddChildItemToParentBOM(ItemA, ItemB);
        AddChildItemToParentBOM(ItemC, ItemE);

        ClearAllLowLevelCodes();
        LowLevelCodeCalculator.Calculate();

        VerifyItemLowLevelCode(ItemA."No.", 0);
        VerifyItemLowLevelCode(ItemB."No.", 1);
        VerifyItemLowLevelCode(ItemC."No.", 2);
        VerifyItemLowLevelCode(ItemD."No.", 4);
        VerifyItemLowLevelCode(ItemE."No.", 3);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('BOMConfirmHandler')]
    procedure TestLowLevelCodeClearsLLCForNonTreeNodes()
    var
        ItemA: Record Item;
        ItemB: Record Item;
        ItemC: Record Item;
        ItemD: Record Item;
        ItemE: Record Item;
        ItemX: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        UnitOfMeasure: Record "Unit of Measure";
        LowLevelCodeCalculator: Codeunit "Low-Level Code Calculator";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        DeleteDemoDataEntities();
        Create5ItemHierarchy(ItemA, ItemB, ItemC, ItemD, ItemE);

        CreateItem(ItemX);
        ItemX."Low-Level Code" := 100;
        ItemX.Modify();

        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, UnitOfMeasure.Code);
        ProductionBOMHeader.Status := "BOM Status"::Certified;
        ProductionBOMHeader."Low-Level Code" := 14;
        ProductionBOMHeader.Modify();

        LowLevelCodeCalculator.Calculate();

        ItemX.Find('=');
        Assert.AreEqual(0, ItemX."Low-Level Code", 'Non tree item node should have 0 low level code');

        ProductionBOMHeader.Find('=');
        Assert.AreEqual(0, ProductionBOMHeader."Low-Level Code", 'Non tree BOM node should have 0 low level code');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('BOMConfirmHandler')]
    procedure TestLowLevelCodeWithAClosed()
    var
        ItemA: Record Item;
        ItemB: Record Item;
        ItemC: Record Item;
        ItemD: Record Item;
        ItemE: Record Item;
        LowLevelCodeCalculator: Codeunit "Low-Level Code Calculator";
    begin
        DeleteDemoDataEntities();
        Create5ItemHierarchy(ItemA, ItemB, ItemC, ItemD, ItemE);

        ChangeBOMStatus(ItemA."No.", "BOM Status"::Closed);

        ClearAllLowLevelCodes();
        LowLevelCodeCalculator.Calculate();
        VerifyItemLowLevelCode(ItemA."No.", 0);
        VerifyItemLowLevelCode(ItemB."No.", 0);
        VerifyItemLowLevelCode(ItemC."No.", 1);
        VerifyItemLowLevelCode(ItemD."No.", 3);
        VerifyItemLowLevelCode(ItemE."No.", 2);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('BOMConfirmHandler')]
    procedure TestLowLevelCodeWithAClosedButBomVersionForACertified()
    var
        ItemA: Record Item;
        ItemB: Record Item;
        ItemC: Record Item;
        ItemD: Record Item;
        ItemE: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionBOMVersion: Record "Production BOM Version";
        LowLevelCodeCalculator: Codeunit "Low-Level Code Calculator";
    begin
        DeleteDemoDataEntities();
        Create5ItemHierarchy(ItemA, ItemB, ItemC, ItemD, ItemE);

        ChangeBOMStatus(ItemA."No.", "BOM Status"::Closed);

        // certify a version instead
        ProductionBOMHeader.Get(ItemA."Production BOM No.");
        LibraryManufacturing.CreateProductionBOMVersion(ProductionBOMVersion, ProductionBOMHeader."No.", '1.0', ProductionBOMHeader."Unit of Measure Code");
        ProductionBOMVersion.Status := "BOM Status"::Certified;
        ProductionBOMVersion."Starting Date" := WorkDate();
        ProductionBOMVersion.Modify();
        // add that version into the bom lines
        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMHeader."No.");
        if ProductionBOMLine.FindSet() then
            repeat
                ProductionBOMLine.Rename(ProductionBOMLine."Production BOM No.", ProductionBOMVersion."Version Code", ProductionBOMLine."Line No.");
            until ProductionBOMLine.Next() = 0;

        ClearAllLowLevelCodes();
        LowLevelCodeCalculator.Calculate();
        VerifyItemLowLevelCode(ItemA."No.", 0);
        VerifyItemLowLevelCode(ItemB."No.", 0);
        VerifyItemLowLevelCode(ItemC."No.", 1);
        VerifyItemLowLevelCode(ItemD."No.", 3);
        VerifyItemLowLevelCode(ItemE."No.", 2);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('BOMConfirmHandler')]
    procedure TestLowLevelCodeWithAClosedBUnderDevelopment()
    var
        ItemA: Record Item;
        ItemB: Record Item;
        ItemC: Record Item;
        ItemD: Record Item;
        ItemE: Record Item;
        LowLevelCodeCalculator: Codeunit "Low-Level Code Calculator";
    begin
        DeleteDemoDataEntities();
        Create5ItemHierarchy(ItemA, ItemB, ItemC, ItemD, ItemE);

        ChangeBOMStatus(ItemA."No.", "BOM Status"::Closed);
        ChangeBOMStatus(ItemB."No.", "BOM Status"::"Under Development");

        ClearAllLowLevelCodes();
        LowLevelCodeCalculator.Calculate();

        VerifyItemLowLevelCode(ItemA."No.", 0);
        VerifyItemLowLevelCode(ItemB."No.", 0);
        VerifyItemLowLevelCode(ItemC."No.", 0);
        VerifyItemLowLevelCode(ItemD."No.", 2);
        VerifyItemLowLevelCode(ItemE."No.", 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('BOMConfirmHandler')]
    procedure TestLowLevelCodeWithBClosed()
    var
        ItemA: Record Item;
        ItemB: Record Item;
        ItemC: Record Item;
        ItemD: Record Item;
        ItemE: Record Item;
        LowLevelCodeCalculator: Codeunit "Low-Level Code Calculator";
    begin
        DeleteDemoDataEntities();
        Create5ItemHierarchy(ItemA, ItemB, ItemC, ItemD, ItemE);

        ChangeBOMStatus(ItemB."No.", "BOM Status"::Closed);

        ClearAllLowLevelCodes();
        LowLevelCodeCalculator.Calculate();

        VerifyItemLowLevelCode(ItemA."No.", 0);
        VerifyItemLowLevelCode(ItemB."No.", 1);
        VerifyItemLowLevelCode(ItemC."No.", 0);
        VerifyItemLowLevelCode(ItemD."No.", 2);
        VerifyItemLowLevelCode(ItemE."No.", 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('BOMConfirmHandler')]
    procedure TestLowLevelCodeWithBUnderDevelopment()
    var
        ItemA: Record Item;
        ItemB: Record Item;
        ItemC: Record Item;
        ItemD: Record Item;
        ItemE: Record Item;
        LowLevelCodeCalculator: Codeunit "Low-Level Code Calculator";
    begin
        DeleteDemoDataEntities();
        Create5ItemHierarchy(ItemA, ItemB, ItemC, ItemD, ItemE);

        ChangeBOMStatus(ItemB."No.", "BOM Status"::"Under Development");

        ClearAllLowLevelCodes();
        LowLevelCodeCalculator.Calculate();

        VerifyItemLowLevelCode(ItemA."No.", 0);
        VerifyItemLowLevelCode(ItemB."No.", 1);
        VerifyItemLowLevelCode(ItemC."No.", 0);
        VerifyItemLowLevelCode(ItemD."No.", 2);
        VerifyItemLowLevelCode(ItemE."No.", 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('BOMConfirmHandler')]
    procedure TestLowLevelCodeWithAUnderDevelopmentBClosed()
    var
        ItemA: Record Item;
        ItemB: Record Item;
        ItemC: Record Item;
        ItemD: Record Item;
        ItemE: Record Item;
        LowLevelCodeCalculator: Codeunit "Low-Level Code Calculator";
    begin
        DeleteDemoDataEntities();
        Create5ItemHierarchy(ItemA, ItemB, ItemC, ItemD, ItemE);

        ChangeBOMStatus(ItemA."No.", "BOM Status"::"Under Development");
        ChangeBOMStatus(ItemB."No.", "BOM Status"::Closed);

        ClearAllLowLevelCodes();
        LowLevelCodeCalculator.Calculate();

        VerifyItemLowLevelCode(ItemA."No.", 0);
        VerifyItemLowLevelCode(ItemB."No.", 0);
        VerifyItemLowLevelCode(ItemC."No.", 0);
        VerifyItemLowLevelCode(ItemD."No.", 2);
        VerifyItemLowLevelCode(ItemE."No.", 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('BOMConfirmHandler')]
    procedure TestLowLevelCodeWithAUnderDevelopment()
    var
        ItemA: Record Item;
        ItemB: Record Item;
        ItemC: Record Item;
        ItemD: Record Item;
        ItemE: Record Item;
        LowLevelCodeCalculator: Codeunit "Low-Level Code Calculator";
    begin
        DeleteDemoDataEntities();
        Create5ItemHierarchy(ItemA, ItemB, ItemC, ItemD, ItemE);

        ChangeBOMStatus(ItemA."No.", "BOM Status"::"Under Development");

        ClearAllLowLevelCodes();
        LowLevelCodeCalculator.Calculate();

        VerifyItemLowLevelCode(ItemA."No.", 0);
        VerifyItemLowLevelCode(ItemB."No.", 0);
        VerifyItemLowLevelCode(ItemC."No.", 1);
        VerifyItemLowLevelCode(ItemD."No.", 3);
        VerifyItemLowLevelCode(ItemE."No.", 2);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('BOMConfirmHandler')]
    procedure TestRecursionWithinBOMs()
    var
        ProdBOMA: Record "Production BOM Header";
        ProdBOMB: Record "Production BOM Header";
        ProdBOMC: Record "Production BOM Header";
        UnitOfMeasure: Record "Unit of Measure";
        ProdBOMLine: Record "Production BOM Line";
        LowLevelCodeCalculator: Codeunit "Low-Level Code Calculator";
    begin
        DeleteDemoDataEntities();

        UnitOfMeasure.FindFirst();
        LibraryManufacturing.CreateProductionBOMHeader(ProdBOMA, UnitOfMeasure.Code);
        LibraryManufacturing.CreateProductionBOMHeader(ProdBOMB, UnitOfMeasure.Code);
        LibraryManufacturing.CreateProductionBOMHeader(ProdBOMC, UnitOfMeasure.Code);

        LibraryManufacturing.CreateProductionBOMLine(ProdBOMA, ProdBOMLine, '', "Production BOM Line Type"::"Production BOM", ProdBOMB."No.", 1);
        LibraryManufacturing.CreateProductionBOMLine(ProdBOMB, ProdBOMLine, '', "Production BOM Line Type"::"Production BOM", ProdBOMC."No.", 1);
        LibraryManufacturing.CreateProductionBOMLine(ProdBOMC, ProdBOMLine, '', "Production BOM Line Type"::"Production BOM", ProdBOMB."No.", 1);

        ProdBOMA.Status := "BOM Status"::Certified;
        ProdBOMA.Modify();
        ProdBOMB.Status := "BOM Status"::Certified;
        ProdBOMB.Modify();
        ProdBOMC.Status := "BOM Status"::Certified;
        ProdBOMC.Modify();

        asserterror LowLevelCodeCalculator.Calculate();
        Assert.ExpectedError(StrSubstNo(RecursiveLoopDetected, StrSubstNo('%1, %2, %3, %4', GetKey(ProdBOMA), GetKey(ProdBOMB), GetKey(ProdBOMC), GetKey(ProdBOMB))));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('BOMConfirmHandler')]
    procedure TestRecursionWithinItemBOMsMix()
    var
        ItemA: Record Item;
        ItemB: Record Item;
        ItemC: Record Item;
        ProdBOMA: Record "Production BOM Header";
        ProdBOMB: Record "Production BOM Header";
        ProdBOMC: Record "Production BOM Header";
        LowLevelCodeCalculator: Codeunit "Low-Level Code Calculator";
    begin
        DeleteDemoDataEntities();

        CreateItem(ItemA);
        CreateItem(ItemB);
        CreateItem(ItemC);

        ProdBOMA.Get(CreateBOM(ItemA, ItemB));
        ProdBOMB.Get(CreateBOM(ItemB, ItemC));
        ProdBOMC.Get(CreateBOM(ItemC, ItemB));

        asserterror LowLevelCodeCalculator.Calculate();

        Assert.ExpectedError(StrSubstNo(RecursiveLoopDetected, StrSubstNo('%1, %2, %3, %4, %5, %6, %7', GetKey(ItemA), GetKey(ProdBOMA), GetKey(ItemB), GetKey(ProdBOMB), GetKey(ItemC), GetKey(ProdBOMC), GetKey(ItemB))));
    end;

    local procedure DeleteDemoDataEntities()
    var
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        BOMComponent: Record "BOM Component";
    begin
        Item.DeleteAll();
        ProductionBOMHeader.DeleteAll();
        ProductionBOMLine.DeleteAll();
        BOMComponent.DeleteAll();
    end;

    local procedure Create5ItemHierarchy(var ItemA: Record Item; var ItemB: Record Item; var ItemC: Record Item; var ItemD: Record Item; var ItemE: Record Item)
    begin
        CreateItem(ItemA);
        CreateItem(ItemB);
        CreateItem(ItemC);
        CreateItem(ItemD);
        CreateItem(ItemE);

        CreateBOM(ItemA, ItemE);
        CreateBOM(ItemA, ItemB);
        CreateBOM(ItemB, ItemC);
        CreateBOM(ItemC, ItemE);
        CreateBOM(ItemB, ItemD);
        CreateBOM(ItemE, ItemD);
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        LibraryManufacturing.CreateItemManufacturing(Item, "Costing Method"::Standard, 0, "Reordering Policy"::" ", "Flushing Method"::"Pick + Manual", '', '');
    end;

    local procedure CreateBOM(var ParentItem: Record Item; var ChildItem: Record Item): Code[20]
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProdBOMLine: Record "Production BOM Line";
    begin
        if ParentItem."Production BOM No." = '' then
            LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ParentItem."Base Unit of Measure")
        else begin
            ProductionBOMHeader.Get(ParentItem."Production BOM No.");
            ProductionBOMHeader.Validate(Status, "BOM Status"::"Under Development");
            ProductionBOMHeader.Modify(true);
        end;

        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProdBOMLine, '', "Production BOM Line Type"::Item, ChildItem."No.", 1);
        ProductionBOMHeader.Validate(Status, "BOM Status"::Certified);
        ProductionBOMHeader.Modify(true);
        ParentItem."Production BOM No." := ProductionBOMHeader."No.";
        ParentItem.Modify();
        exit(ProductionBOMHeader."No.");
    end;

    local procedure AddChildItemToParentBOM(var ParentItem: Record Item; var ChildItem: Record Item)
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProdBOMLine: Record "Production BOM Line";
        OriginalStatus: Enum "BOM Status";
    begin
        ProductionBOMHeader.Get(ParentItem."Production BOM No.");
        OriginalStatus := ProductionBOMHeader.Status;
        ProductionBOMHeader.Status := "BOM Status"::"Under Development";
        ProductionBOMHeader.Modify();

        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProdBOMLine, '', "Production BOM Line Type"::Item, ChildItem."No.", 1);

        ProductionBOMHeader.Status := OriginalStatus;
        ProductionBOMHeader.Modify();
    end;

    local procedure VerifyItemLowLevelCode(ItemNo: Code[20]; ExpectedLowLevelCode: Integer)
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Assert.AreEqual(ExpectedLowLevelCode, Item."Low-Level Code", StrSubstNo('Mismatch in item low level code for %1', ItemNo));
        if Item."Production BOM No." <> '' then
            VerifyBOMLowLevelCode(Item."Production BOM No.", Item."Low-Level Code" + 1);
    end;

    local procedure VerifyBOMLowLevelCode(BOMNo: Code[20]; ExpectedLowLevelCode: Integer)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        ProductionBOMHeader.Get(BOMNo);
        if ProductionBOMHeader.Status = "BOM Status"::Certified then
            Assert.AreEqual(ExpectedLowLevelCode, ProductionBOMHeader."Low-Level Code", StrSubstNo('Mismatch in BOM low level code for %1', BOMNo))
        else
            Assert.AreEqual(0, ProductionBOMHeader."Low-Level Code", 'Uncertified BOMs must have 0 low level code');
    end;

    local procedure ChangeBOMStatus(ItemNo: Code[20]; NewStatus: Enum "BOM Status")
    var
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        Item.Get(ItemNo);
        ProductionBOMHeader.Get(Item."Production BOM No.");
        ProductionBOMHeader.Validate(Status, NewStatus);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure ClearAllLowLevelCodes()
    var
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        Item.ModifyAll("Low-Level Code", 0);
        ProductionBOMHeader.ModifyAll("Low-Level Code", 0);
    end;

    local procedure GetKey(Item: Record Item): Text
    var
        BOMNode: Codeunit "BOM Node";
        LowLevelCodeParameter: Codeunit "Low-Level Code Parameter";
    begin
        BOMNode.CreateForItem(Item."No.", 0, LowLevelCodeParameter);
        exit(BOMNode.GetKey());
    end;

    local procedure GetKey(ProdBOMHeader: Record "Production BOM Header"): Text
    var
        BOMNode: Codeunit "BOM Node";
        LowLevelCodeParameter: Codeunit "Low-Level Code Parameter";
    begin
        BOMNode.CreateForProdBOM(ProdBOMHeader."No.", 0, LowLevelCodeParameter);
        exit(BOMNode.GetKey());
    end;

    [ConfirmHandler]
    procedure BOMConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        case Question of
            CloseBOMQst,
            ConfirmQst:
                Reply := true;
            else
                Assert.Fail(StrSubstNo('Unhandled confirm dialog: %1', Question));
        end;
    end;
}