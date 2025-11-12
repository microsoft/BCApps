codeunit 137463 "Phys. Invt. Item Journal"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Physical Inventory]
    end;

    var
        LibraryItemReference: Codeunit "Library - Item Reference";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        Assert: Codeunit Assert;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure RenumberDocNoOneLine()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        EntryType: Enum "Item Ledger Entry Type";
        OldDocNo: Code[20];
    begin
        // [FEATURE] [Item Journal] [Renumber documents]
        // [SCENARIO 257226] Generate one line in the Item Journal and renumber the document number.
        Initialize();

        // [GIVEN] Create random item
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create one Item Journal lines with the created item
        ItemJournalLine.DeleteAll();
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, EntryType::"Positive Adjmt.", WorkDate(), Item."No.", LibraryRandom.RandDec(20, 0), '');

        OldDocNo := ItemJournalLine."Document No.";
        SetNewDocNo(ItemJournalLine);

        // [WHEN] Enable the functionality renumber document no. on Item journal
        Commit();
        ItemJournalLine.RenumberDocumentNo();

        // [THEN] The lines must have the first value from the No. Series
        VerifyItemJnlLineDocNo(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name",
          ItemJournalLine."Line No.", OldDocNo);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure RenumberDocNoMultipleLines()
    var
        Item: Record Item;
        Item2: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        EntryType: Enum "Item Ledger Entry Type";
        NoSeries: Codeunit "No. Series";
        NoSeriesCode: Code[20];
        NewDocNo: Code[20];
        ItemJnlBatch: Record "Item Journal Batch";
    begin
        // [FEATURE] [Item Journal] [Renumber documents]
        // [SCENARIO 257227] Generate multiple lines in the Item Journal and renumber the "Document No.".
        Initialize();

        // [GIVEN] Create two random items
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item2);

        // [GIVEN] Create multiple Item Journal lines with the created items and a random "Document No.""
        ItemJournalLine.DeleteAll();
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, EntryType::"Positive Adjmt.", WorkDate(), Item."No.", LibraryRandom.RandDec(20, 0), '');
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, EntryType::"Positive Adjmt.", WorkDate(), Item2."No.", LibraryRandom.RandDec(20, 0), '');
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, EntryType::"Positive Adjmt.", WorkDate(), Item2."No.", LibraryRandom.RandDec(20, 0), '');

        // [WHEN] Enable the functionality renumber "Document No." on Item journal
        Commit();
        ItemJournalLine.RenumberDocumentNo();

        // [THEN] All the lines must have the same "Document No."
        if ItemJnlBatch.Get(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name") then
            NoSeriesCode := ItemJnlBatch."No. Series";

        NewDocNo := NoSeries.PeekNextNo(NoSeriesCode);
        VerifyItemJnlLineDocNo(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name",
          10000, NewDocNo);
        VerifyItemJnlLineDocNo(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name",
          20000, NewDocNo);
        VerifyItemJnlLineDocNo(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name",
          30000, NewDocNo);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure RenumberDocNoMultipleLinesAndDifferentWorkDate()
    var
        Item: Record Item;
        Item2: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        EntryType: Enum "Item Ledger Entry Type";
        NoSeries: Codeunit "No. Series";
        NoSeriesCode: Code[20];
        NewDocNo: Code[20];
        ItemJnlBatch: Record "Item Journal Batch";
    begin
        // [FEATURE] [Item Journal] [Renumber documents]
        // [SCENARIO 257228] Generate multiple lines in the Item Journal with different dates and renumber the document number.
        Initialize();

        // [GIVEN] Create two random items
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item2);

        // [GIVEN] Create multiple Item Journal lines with the created items
        ItemJournalLine.DeleteAll();
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, EntryType::"Positive Adjmt.", WorkDate(), Item."No.", LibraryRandom.RandDec(20, 0), '');
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, EntryType::"Positive Adjmt.", WorkDate() + 1, Item."No.", LibraryRandom.RandDec(20, 0), '');
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, EntryType::"Positive Adjmt.", WorkDate() + 1, Item2."No.", LibraryRandom.RandDec(20, 0), '');

        // [WHEN] Enable the functionality renumber document no. on Item journal
        Commit();
        ItemJournalLine.RenumberDocumentNo();

        // [THEN] Line 10000 must have a different value then line 20000 and 30000
        if ItemJnlBatch.Get(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name") then
            NoSeriesCode := ItemJnlBatch."No. Series";

        NewDocNo := NoSeries.PeekNextNo(NoSeriesCode);
        VerifyItemJnlLineDocNo(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name",
          10000, NewDocNo);
        VerifyItemJnlLineDocNo(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name",
          20000, IncStr(NewDocNo));
        VerifyItemJnlLineDocNo(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name",
          30000, IncStr(NewDocNo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemReferenceOnValidatePhysInvtJournalItemJournal()
    var
        ItemReference: Record "Item Reference";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [GIVEN] Empty Physical Journal Line (Item Journal Line) exists
        CreatePhysInvtJournalLineWithNoItem(ItemJournalLine);

        // [GIVEN] Different item references exist
        CreateDifferentItemReferencesWithSameReferenceNo(ItemReference);

        // [WHEN] Validate item reference no using existing refernce no
        ItemJournalLine.Validate("Item Reference No.", ItemReference."Reference No.");
        ItemJournalLine.Modify(true);

        // [THEN] Info from item reference is copied
        TestItemJournalLineReferenceFields(ItemJournalLine, ItemReference);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ItemJournalTemplateListModalPageHandler,ItemReferenceList1ItemReferenceModalPageHandler')]
    procedure ItemReferenceOnLookupPhysInvtJournalItemJournal()
    var
        ItemReference: Record "Item Reference";
        ItemJournalLine: Record "Item Journal Line";
        PhysInventoryJournal: TestPage "Phys. Inventory Journal";
    begin
        // [GIVEN] Empty Physical Journal Line (Item Journal Line) exists
        CreatePhysInvtJournalLineWithNoItem(ItemJournalLine);

        // [GIVEN] Different item references exist
        CreateDifferentItemReferencesWithSameReferenceNo(ItemReference);

        // [WHEN] Lookup references
        PhysInventoryJournal.OpenEdit();
        PhysInventoryJournal.GoToRecord(ItemJournalLine);
        PhysInventoryJournal."Item Reference No.".Lookup();
        PhysInventoryJournal.Close();

        // [THEN] Info from item reference is copied
        TestItemJournalLineReferenceFields(ItemJournalLine, ItemReference);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemReferenceBarCodeOnValidatePhysInvtJournalItemJournalNonBaseUoM()
    var
        Item: Record Item;
        ItemReference: Record "Item Reference";
        ItemJournalLine: Record "Item Journal Line";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        // [GIVEN] Empty Physical Journal Line (Item Journal Line) exists
        CreatePhysInvtJournalLineWithNoItem(ItemJournalLine);

        // [GIVEN] Item Reference for Item exists with non-base UoM code
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 2);
        LibraryItemReference.CreateItemReference(ItemReference, Item."No.", '', ItemUnitOfMeasure.Code, "Item Reference Type"::"Bar Code", '', LibraryUtility.GenerateRandomCode(ItemReference.FieldNo("Reference No."), Database::"Item Reference"));

        ItemReference.Validate("Unit of Measure", ItemUnitOfMeasure.Code);
        ItemReference.Modify(true);

        // [WHEN] Validate item reference no using existing refernce no that has non-base unit of measure
        ItemJournalLine.Validate("Item Reference No.", ItemReference."Reference No.");

        // [THEN] Unit of measure is applied in the line
        Assert.AreEqual(ItemReference."Unit of Measure", ItemJournalLine."Unit of Measure Code", ItemJournalLine.FieldCaption("Unit of Measure Code"));
        Assert.AreEqual(ItemUnitOfMeasure."Qty. per Unit of Measure", ItemJournalLine."Qty. per Unit of Measure", ItemJournalLine.FieldCaption("Qty. per Unit of Measure"));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure YesConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure SetNewDocNo(var ItemJournalLine: Record "Item Journal Line"): Code[20]
    var
        i: Integer;
    begin
        for i := 1 to LibraryRandom.RandIntInRange(2, 10) do
            ItemJournalLine."Document No." := IncStr(ItemJournalLine."Document No.");
        ItemJournalLine.Modify();
        exit(ItemJournalLine."Document No.")
    end;

    local procedure VerifyItemJnlLineDocNo(TemplateName: Code[20]; BatchName: Code[20]; LineNo: Integer; DocNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.Get(TemplateName, BatchName, LineNo);
        ItemJournalLine.TestField("Document No.", DocNo)
    end;

    local procedure CreatePhysInvtJournalLineWithNoItem(var ItemJournalLine: Record "Item Journal Line")
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        EntryType: Enum "Item Ledger Entry Type";
    begin
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryVariableStorage.Enqueue(ItemJournalTemplate.Name);
        ItemJournalTemplate.Validate(Type, ItemJournalTemplate.Type::"Phys. Inventory");
        ItemJournalTemplate.Modify();
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJnlLineWithNoItem(ItemJournalLine, ItemJournalBatch, ItemJournalTemplate.Name, ItemJournalBatch.Name, EntryType::"Positive Adjmt.");
    end;

    local procedure TestItemJournalLineReferenceFields(var ItemJournalLine: Record "Item Journal Line"; ItemReference: Record "Item Reference")
    begin
        ItemJournalLine.SetRecFilter();
        ItemJournalLine.FindFirst();
        ItemJournalLine.TestField("Item No.", ItemReference."Item No.");
        ItemJournalLine.TestField("Unit of Measure Code", ItemReference."Unit of Measure");
        ItemJournalLine.TestField("Variant Code", ItemReference."Variant Code");
        ItemJournalLine.TestField("Description", ItemReference."Description");
        ItemJournalLine.TestField("Item Reference Type", ItemReference."Reference Type");
        ItemJournalLine.TestField("Item Reference Type No.", ItemReference."Reference Type No.");
        ItemJournalLine.TestField("Item Reference Unit of Measure", ItemReference."Unit of Measure");
    end;

    local procedure CreateDifferentItemReferencesWithSameReferenceNo(var FirstItemReference: Record "Item Reference")
    var
        Item: Record Item;
        AdditionalItemReference: Record "Item Reference";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemVariant: Record "Item Variant";
    begin
        FirstItemReference.DeleteAll();
        LibraryInventory.CreateItem(Item);
        LibraryVariableStorage.Enqueue(Item."No.");
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 10);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        LibraryItemReference.CreateItemReference(FirstItemReference, Item."No.", "Item Reference Type"::" ", '');
        FirstItemReference.Rename(FirstItemReference."Item No.", ItemVariant.Code, ItemUnitOfMeasure.Code, FirstItemReference."Reference Type", FirstItemReference."Reference Type No.", FirstItemReference."Reference No.");
        FirstItemReference.Validate(Description, LibraryUtility.GenerateRandomText(MaxStrLen(FirstItemReference.Description)));
        FirstItemReference.Validate("Description 2", LibraryUtility.GenerateRandomText(MaxStrLen(FirstItemReference."Description 2")));
        FirstItemReference.Modify(true);

        LibraryInventory.CreateItem(Item);
        LibraryVariableStorage.Enqueue(Item."No.");
        LibraryItemReference.CreateItemReferenceWithNo(AdditionalItemReference, FirstItemReference."Reference No.", Item."No.", FirstItemReference."Reference Type"::"Bar Code", '');
        LibraryInventory.CreateItem(Item);
        LibraryVariableStorage.Enqueue(Item."No.");
        LibraryItemReference.CreateItemReferenceWithNo(AdditionalItemReference, FirstItemReference."Reference No.", Item."No.", FirstItemReference."Reference Type"::Customer, LibrarySales.CreateCustomerNo());
        LibraryInventory.CreateItem(Item);
        LibraryVariableStorage.Enqueue(Item."No.");
        LibraryItemReference.CreateItemReferenceWithNo(AdditionalItemReference, FirstItemReference."Reference No.", Item."No.", FirstItemReference."Reference Type"::Vendor, LibraryPurchase.CreateVendorNo());
    end;

    [ModalPageHandler]
    procedure ItemJournalTemplateListModalPageHandler(var ItemJournalTemplate: TestPage "Item Journal Template List");
    begin
        ItemJournalTemplate.GoToKey(LibraryVariableStorage.DequeueText());
        ItemJournalTemplate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemReferenceList1ItemReferenceModalPageHandler(var ItemReferenceList: TestPage "Item Reference List")
    var
        ItemNo: Code[20];
    begin
        ItemNo := LibraryVariableStorage.DequeueText();
        ItemReferenceListContains(ItemReferenceList, ItemNo);
        ItemReferenceListNotContains(ItemReferenceList, LibraryVariableStorage.DequeueText());
        ItemReferenceListNotContains(ItemReferenceList, LibraryVariableStorage.DequeueText());
        ItemReferenceListNotContains(ItemReferenceList, LibraryVariableStorage.DequeueText());

        ItemReferenceList.Filter.SetFilter("Item No.", ItemNo);
        ItemReferenceList.First(); // Return the item reference for the first item
        ItemReferenceList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemReferenceList2ItemReferencesModalPageHandler(var ItemReferenceList: TestPage "Item Reference List")
    var
        ItemNo: Code[20];
    begin
        ItemNo := LibraryVariableStorage.DequeueText();
        ItemReferenceListContains(ItemReferenceList, ItemNo);
        ItemReferenceListContains(ItemReferenceList, LibraryVariableStorage.DequeueText());
        ItemReferenceListNotContains(ItemReferenceList, LibraryVariableStorage.DequeueText());
        ItemReferenceListNotContains(ItemReferenceList, LibraryVariableStorage.DequeueText());

        ItemReferenceList.Filter.SetFilter("Item No.", ItemNo);
        ItemReferenceList.First(); // Return the item reference for the first item
        ItemReferenceList.OK().Invoke();
    end;

    local procedure ItemReferenceListContains(var ItemReferenceList: TestPage "Item Reference List"; ItemNo: Code[20])
    begin
        ItemReferenceList.Filter.SetFilter("Item No.", ItemNo);
        Assert.IsTrue(ItemReferenceList.First(), 'Item Reference List does not contain entry that should be visible');
    end;

    local procedure ItemReferenceListNotContains(var ItemReferenceList: TestPage "Item Reference List"; ItemNo: Code[20])
    begin
        ItemReferenceList.Filter.SetFilter("Item No.", ItemNo);
        Assert.IsFalse(ItemReferenceList.First(), 'Item Reference List contains entry that should not be visible');
    end;
}
