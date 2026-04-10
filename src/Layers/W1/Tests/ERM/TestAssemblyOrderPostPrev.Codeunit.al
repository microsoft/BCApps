codeunit 134785 "Test Assembly Order Post Prev."
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Post Preview] [Assembly Order]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryERM: Codeunit "Library - ERM";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryDimension: Codeunit "Library - Dimension";
        IsInitialized: Boolean;
        WrongPostPreviewErr: Label 'Expected empty error from Preview. Actual error: ';
        DimensionSetIdHasChangedOnHeader: Label 'Dimension Set ID has changed on Posted Assembly Header';
        DimensionSetIdHasChangedOnLine: Label 'Dimension Set ID has changed on Posted Assembly Line';

    [Test]
    [Scope('OnPrem')]
    procedure PreviewAssemblyOrderPosting()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        AssembledItem: Record Item;
        CompItem: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        AsemblyPostYesNo: Codeunit "Assembly-Post (Yes/No)";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [FEATURE] [Assembly] [Assembly Order] [Preview Posting]
        // [SCENARIO] Preview Assembly Order posting shows the ledger entries that will be generated when the assembly order is posted.
        Initialize();

        // [GIVEN] An Assembly Order with line
        CreateItem(CompItem);
        LibraryInventory.CreateItem(AssembledItem);
        CreateAssemblyOrder(AssemblyHeader, AssembledItem."No.", 10);
        CreateAssemblyOrderLine(AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, CompItem."No.", 20, CompItem."Base Unit of Measure");
        Commit();

        // [WHEN] Preview is invoked
        GLPostingPreview.Trap();
        asserterror AsemblyPostYesNo.Preview(AssemblyHeader);
        Assert.AreEqual('', GetLastErrorText, WrongPostPreviewErr + GetLastErrorText);

        // [THEN] Preview creates the entries that will be created when the asembly order is posted
        GLPostingPreview.First();
        VerifyGLPostingPreviewLine(GLPostingPreview, ItemLedgerEntry.TableCaption(), 2);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, ValueEntry.TableCaption(), 2);
        GLPostingPreview.OK().Invoke();
    end;

    [Test]
    procedure DimensionSetIDShouldFlowToPostedAssemblyOrder()
    var
        DefaultDimension: Record "Default Dimension";
        DefaultDimension2: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        Location: Record Location;
        ItemJournalLine: Record "Item Journal Line";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        AssembledItem: Record Item;
        CompItem: Record Item;
        InventoryPostingSetup: Record "Inventory Posting Setup";
        DimensionSetIDHeader: Integer;
        PostedAssemblyHeader: Record "Posted Assembly Header";
        PostedAssemblyLine: Record "Posted Assembly Line";
    begin
        // [SCENARIO 474052] Unexpected dimension value missing error when trying to post assembly order.
        Initialize();

        // [GIVEN] Create Comp Item
        CreateItem(CompItem);

        // [GIVEN] Create Assembled Item
        LibraryInventory.CreateItem(AssembledItem);

        // [GIVEN] Create two Dimensions with its Dimension Values.
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDimWithDimValue(DimensionValue2);

        // [GIVEN] Create a Default Dimension with Value Posting as Code Mandatory for GL Account.
        CreateDefaultDimensionForInventAdjAcc(DefaultDimension, DimensionValue, CompItem);

        // [GIVEN] Create a Location.
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Create a Default Dimension for Location.
        LibraryDimension.CreateDefaultDimension(
            DefaultDimension2,
            Database::Location,
            Location.Code,
            DimensionValue2."Dimension Code",
            DimensionValue2.Code);

        // [GIVEN] Create an Item Jnl Line to purchase inventory for assembly Item
        LibraryInventory.CreateItemJnlLine(
            ItemJournalLine,
            "Item Ledger Entry Type"::Purchase,
            WorkDate(),
            CompItem."No.",
            LibraryRandom.RandInt(10),
            Location.Code);

        // [GIVEN] Create Inventory Posting Setup for assembly Item  Inventory Posting Group & Location.
        LibraryInventory.CreateInventoryPostingSetup(InventoryPostingSetup, Location.Code, CompItem."Inventory Posting Group");
        InventoryPostingSetup."Inventory Account" := LibraryERM.CreateGLAccountNo();
        InventoryPostingSetup.Modify();

        // [GIVEN] Post Item Jnl Line.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create & Save Dimension Set ID in a variable.
        DimensionSetIDHeader := LibraryDimension.CreateDimSet(LibraryRandom.RandInt(20), DimensionValue."Dimension Code", DimensionValue.Code);

        // [GIVEN] Create an Assembly Order & Validate Dimension Set ID.
        CreateAssemblyOrderWithLocation(AssemblyHeader, AssemblyLine, AssembledItem, CompItem, DimensionSetIDHeader, Location);

        // [THEN] Post the created Assembly Order.
        Codeunit.Run(Codeunit::"Assembly-Post", AssemblyHeader);

        // [THEN] Find Posted Assembly Header.
        PostedAssemblyHeader.SetRange("Order No.", AssemblyHeader."No.");
        PostedAssemblyHeader.FindFirst();

        // [VERIFY] Verify Dimension Set ID is same in Posted Assembly Header & in the created Assembly Header.
        Assert.AreEqual(PostedAssemblyHeader."Dimension Set ID", DimensionSetIDHeader, DimensionSetIdHasChangedOnHeader);

        // [THEN] Find Posted Assembly Line.
        PostedAssemblyLine.Get(PostedAssemblyHeader."No.", AssemblyLine."Line No.");

        // [VERIFY] Verify Dimension Set ID is same in Posted Assembly Line & in the created Assembly Line.
        Assert.AreEqual(PostedAssemblyLine."Dimension Set ID", AssemblyLine."Dimension Set ID", DimensionSetIdHasChangedOnLine);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Test Assembly Order Post Prev.");
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Test Assembly Order Post Prev.");

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Test Assembly Order Post Prev.");
    end;

    local procedure CreateAssemblyOrder(var AssemblyHeader: Record "Assembly Header"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        if ItemNo <> '' then begin
            LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), ItemNo, '', Quantity, '');
            exit;
        end;
        Clear(AssemblyHeader);
        AssemblyHeader."Document Type" := AssemblyHeader."Document Type"::Order;
        AssemblyHeader.Insert(true);
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

    local procedure CreateItem(var Item: Record Item)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, Item."No.", '', '', LibraryRandom.RandIntInRange(10, 20));
        LibraryInventory.PostItemJournalLine(
          ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure VerifyGLPostingPreviewLine(GLPostingPreview: TestPage "G/L Posting Preview"; TableName: Text; ExpectedEntryCount: Integer)
    begin
        Assert.AreEqual(TableName, GLPostingPreview."Table Name".Value, StrSubstNo('A record for Table Name %1 was not found.', TableName));
        Assert.AreEqual(ExpectedEntryCount, GLPostingPreview."No. of Records".AsInteger(),
          StrSubstNo('Table Name %1 Unexpected number of records.', TableName));
    end;

    local procedure CreateAssemblyOrderWithLocation(
        var AssemblyHeader: Record "Assembly Header";
        var AssemblyLine: Record "Assembly Line";
        MainItem: Record Item;
        Item: Record Item;
        DimensionSetIDHeader: Integer;
        Location: Record Location)
    begin
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), MainItem."No.", '', LibraryRandom.RandInt(0), '');
        AssemblyHeader.Validate("Dimension Set ID", DimensionSetIDHeader);
        AssemblyHeader.Modify(true);

        LibraryAssembly.CreateAssemblyLine(
            AssemblyHeader,
            AssemblyLine,
            "BOM Component Type"::Item,
            Item."No.",
            Item."Base Unit of Measure",
            LibraryRandom.RandInt(0),
            LibraryRandom.RandInt(0), Item.Description);
        AssemblyLine.Validate("Gen. Prod. Posting Group", Item."Gen. Prod. Posting Group");
        AssemblyLine.Validate("Location Code", Location.Code);
        AssemblyLine.Modify(true);
    end;

    local procedure CreateDefaultDimensionForInventAdjAcc(
        var DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        Item: Record Item)
    var
        GenPostingSetup: Record "General Posting Setup";
    begin
        GenPostingSetup.SetRange("Gen. Bus. Posting Group", '');
        GenPostingSetup.SetRange("Gen. Prod. Posting Group", Item."Gen. Prod. Posting Group");
        GenPostingSetup.SetFilter("Inventory Adjmt. Account", '<>%1', '');
        GenPostingSetup.FindFirst();

        GenPostingSetup."Direct Cost Applied Account" := LibraryERM.CreateGLAccountNo();
        GenPostingSetup.Modify();

        CreateDefaultDimensionWithCodeMandatory(DefaultDimension, DimensionValue, GenPostingSetup."Inventory Adjmt. Account");
    end;

    local procedure CreateDefaultDimensionWithCodeMandatory(
        var DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        GLAccountNo: Code[20])
    begin
        LibraryDimension.CreateDefaultDimensionGLAcc(DefaultDimension, GLAccountNo, DimensionValue."Dimension Code", '');
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
        DefaultDimension.Modify();
    end;
}