codeunit 134466 "ERM Item Reference Other"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Item Reference] [Reference No]
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemReference: Codeunit "Library - Item Reference";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        ItemRefNotExistsErr: Label 'There are no items with reference %1.';
        ItemReferenceMgt: Codeunit "Item Reference Management";
        DescriptionMustBeSameErr: Label 'Description must be same.';
        IsInitialized: Boolean;

    [Test]
    procedure IRLookupItemJournalWhenBarCodeAndExpiredBarCodeShowDialogTrue()
    var
        ItemReference: array[2] of Record "Item Reference";
        ReturnedItemReference: Record "Item Reference";
        ItemJournalLine: Record "Item Journal Line";
        ItemReferenceNo: Code[50];
    begin
        Initialize();

        // [GIVEN] Barcode for multiple item references
        ItemReferenceNo := LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), Database::"Item Reference");

        // [GIVEN] Item Journal with the item reference
        CreateItemJournalLine(ItemJournalLine);
        ItemJournalLine."Item Reference No." := ItemReferenceNo;
        ItemJournalLine.Modify();

        // [GIVEN] Item References for Item X and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNoAndDates(ItemReference[1], ItemReferenceNo, LibraryInventory.CreateItemNo(),
          ItemReference[1]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID(),
           CalcDate('<-1M>', ItemJournalLine.GetDateForCalculations()), CalcDate('<-1D>', ItemJournalLine.GetDateForCalculations()));

        // [GIVEN] Item References for Item Y and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[2], ItemReferenceNo, LibraryInventory.CreateItemNo(),
          ItemReference[2]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID());

        // [WHEN] Ran ReferenceLookupItemJournalItem from codeunit Dist. Integration for the Item Journal Line with ShowDialog = TRUE
        ItemReferenceMgt.ReferenceLookupItemJournalItem(ItemJournalLine, ReturnedItemReference, true);

        // [THEN] Item Reference with Item No = X is ignored
        // [THEN] ReferenceLookupItemJournalItem returns Item Reference with Item No = Y
        ReturnedItemReference.TestField("Item No.", ItemReference[2]."Item No.");
    end;

    [Test]
    [HandlerFunctions('ItemReferenceListModalPageHandler')]
    procedure IRLookupItemJournalWhenBarCodeAndBarCodeDateLimitedShowDialogTrue()
    var
        ItemReference: array[2] of Record "Item Reference";
        ReturnedItemReference: Record "Item Reference";
        ItemJournalLine: Record "Item Journal Line";
        ItemReferenceNo: Code[50];
    begin
        Initialize();

        // [GIVEN] Barcode for multiple item references
        ItemReferenceNo := LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), Database::"Item Reference");
        LibraryVariableStorage.Enqueue(ItemReferenceNo);

        // [GIVEN] Item Journal with the item reference
        CreateItemJournalLine(ItemJournalLine);
        ItemJournalLine."Item Reference No." := ItemReferenceNo;
        ItemJournalLine.Modify();

        // [GIVEN] Item References for Item X and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNoAndDates(ItemReference[1], ItemReferenceNo, LibraryInventory.CreateItemNo(),
          ItemReference[1]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID(),
           CalcDate('<-1M>', ItemJournalLine.GetDateForCalculations()), CalcDate('<+1M>', ItemJournalLine.GetDateForCalculations()));
        EnqueueItemReferenceFields(ItemReference[1]);

        // [GIVEN] Item References for Item Y and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[2], ItemReferenceNo, LibraryInventory.CreateItemNo(),
          ItemReference[2]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID());
        EnqueueItemReferenceFields(ItemReference[2]);

        // [WHEN] Ran ReferenceLookupItemJournalItem from codeunit Dist. Integration for the Item Journal Line with ShowDialog = TRUE
        ItemReferenceMgt.ReferenceLookupItemJournalItem(ItemJournalLine, ReturnedItemReference, true);

        // [GIVEN] Page Item Reference List opened showing both Item References
        // [GIVEN] User selected the second one
        // Done in ItemReferenceListModalPageHandler

        // [THEN] ReferenceLookupItemJournalItem returns Item Reference with Item No = Y
        ReturnedItemReference.TestField("Item No.", ItemReference[2]."Item No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure IRLookupItemJournalWhenTwoExpiredBarCodesShowDialogTrue()
    var
        ItemReference: array[2] of Record "Item Reference";
        ReturnedItemReference: Record "Item Reference";
        ItemJournalLine: Record "Item Journal Line";
        ItemReferenceNo: Code[50];
    begin
        Initialize();

        // [GIVEN] Barcode for multiple item references
        ItemReferenceNo := LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), Database::"Item Reference");

        // [GIVEN] Item Journal with the item reference
        CreateItemJournalLine(ItemJournalLine);
        ItemJournalLine."Item Reference No." := ItemReferenceNo;
        ItemJournalLine.Modify();

        // [GIVEN] Item References for Item X and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNoAndDates(ItemReference[1], ItemReferenceNo, LibraryInventory.CreateItemNo(),
          ItemReference[1]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID(),
           CalcDate('<-1M>', ItemJournalLine.GetDateForCalculations()), CalcDate('<-1D>', ItemJournalLine.GetDateForCalculations()));

        // [GIVEN] Item References for Item Y and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNoAndDates(ItemReference[2], ItemReferenceNo, LibraryInventory.CreateItemNo(),
          ItemReference[2]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID(),
           CalcDate('<+1D>', ItemJournalLine.GetDateForCalculations()), CalcDate('<+1M>', ItemJournalLine.GetDateForCalculations()));

        // [WHEN] Ran ReferenceLookupItemJournalItem from codeunit Dist. Integration for the Item Journal Line with ShowDialog = TRUE
        asserterror ItemReferenceMgt.ReferenceLookupItemJournalItem(ItemJournalLine, ReturnedItemReference, true);

        // [THEN] Error "There are no items with reference %1."
        Assert.ExpectedError(StrSubstNo(ItemRefNotExistsErr, ItemReferenceNo));
    end;

    [Test]
    procedure IRLookupPhysInvOrderWhenBarCodeAndExpiredBarCodeShowDialogTrue()
    var
        ItemReference: array[2] of Record "Item Reference";
        ReturnedItemReference: Record "Item Reference";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        ItemReferenceNo: Code[50];
    begin
        Initialize();

        // [GIVEN] Barcode for multiple item references
        ItemReferenceNo := LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), Database::"Item Reference");

        // [GIVEN] Phys. Invt. Order with the item reference
        CreatePhysInvtOrderLine(PhysInvtOrderLine);
        PhysInvtOrderLine."Item Reference No." := ItemReferenceNo;
        PhysInvtOrderLine.Modify();

        // [GIVEN] Item References for Item X and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNoAndDates(ItemReference[1], ItemReferenceNo, LibraryInventory.CreateItemNo(),
          ItemReference[1]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID(),
           CalcDate('<-1M>', PhysInvtOrderLine.GetDateForCalculations()), CalcDate('<-1D>', PhysInvtOrderLine.GetDateForCalculations()));

        // [GIVEN] Item References for Item Y and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[2], ItemReferenceNo, LibraryInventory.CreateItemNo(),
          ItemReference[2]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID());

        // [WHEN] Ran ReferenceLookupPhysicalInventoryOrderItem from codeunit Dist. Integration for the Phys. Invt. Order Line with ShowDialog = TRUE
        ItemReferenceMgt.ReferenceLookupPhysicalInventoryOrderItem(PhysInvtOrderLine, ReturnedItemReference, true);

        // [THEN] Item Reference with Item No = X is ignored
        // [THEN] ReferenceLookupPhysicalInventoryOrderItem returns Item Reference with Item No = Y
        ReturnedItemReference.TestField("Item No.", ItemReference[2]."Item No.");
    end;

    [Test]
    [HandlerFunctions('ItemReferenceListModalPageHandler')]
    procedure IRLookupPhysInvOrderWhenBarCodeAndBarCodeDateLimitedShowDialogTrue()
    var
        ItemReference: array[2] of Record "Item Reference";
        ReturnedItemReference: Record "Item Reference";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        ItemReferenceNo: Code[50];
    begin
        Initialize();

        // [GIVEN] Barcode for multiple item references
        ItemReferenceNo := LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), Database::"Item Reference");
        LibraryVariableStorage.Enqueue(ItemReferenceNo);

        // [GIVEN] Phys. Invt. Order with the item reference
        CreatePhysInvtOrderLine(PhysInvtOrderLine);
        PhysInvtOrderLine."Item Reference No." := ItemReferenceNo;
        PhysInvtOrderLine.Modify();

        // [GIVEN] Item References for Item X and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNoAndDates(ItemReference[1], ItemReferenceNo, LibraryInventory.CreateItemNo(),
          ItemReference[1]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID(),
           CalcDate('<-1M>', PhysInvtOrderLine.GetDateForCalculations()), CalcDate('<+1M>', PhysInvtOrderLine.GetDateForCalculations()));
        EnqueueItemReferenceFields(ItemReference[1]);

        // [GIVEN] Item References for Item Y and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[2], ItemReferenceNo, LibraryInventory.CreateItemNo(),
          ItemReference[2]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID());
        EnqueueItemReferenceFields(ItemReference[2]);

        // [WHEN] Ran ReferenceLookupPhysicalInventoryOrderItem from codeunit Dist. Integration for the Phys. Invt. Order Line with ShowDialog = TRUE
        ItemReferenceMgt.ReferenceLookupPhysicalInventoryOrderItem(PhysInvtOrderLine, ReturnedItemReference, true);

        // [GIVEN] Page Item Reference List opened showing both Item References
        // [GIVEN] User selected the second one
        // Done in ItemReferenceListModalPageHandler

        // [THEN] ReferenceLookupPhysicalInventoryOrderItem returns Item Reference with Item No = Y
        ReturnedItemReference.TestField("Item No.", ItemReference[2]."Item No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure IRLookupPhysInvOrderWhenTwoExpiredBarCodesShowDialogTrue()
    var
        ItemReference: array[2] of Record "Item Reference";
        ReturnedItemReference: Record "Item Reference";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        ItemReferenceNo: Code[50];
    begin
        Initialize();

        // [GIVEN] Barcode for multiple item references
        ItemReferenceNo := LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), Database::"Item Reference");

        // [GIVEN] Phys. Invt. Order with the item reference
        CreatePhysInvtOrderLine(PhysInvtOrderLine);
        PhysInvtOrderLine."Item Reference No." := ItemReferenceNo;
        PhysInvtOrderLine.Modify();

        // [GIVEN] Item References for Item X and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNoAndDates(ItemReference[1], ItemReferenceNo, LibraryInventory.CreateItemNo(),
          ItemReference[1]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID(),
           CalcDate('<-1M>', PhysInvtOrderLine.GetDateForCalculations()), CalcDate('<-1D>', PhysInvtOrderLine.GetDateForCalculations()));

        // [GIVEN] Item References for Item Y and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNoAndDates(ItemReference[2], ItemReferenceNo, LibraryInventory.CreateItemNo(),
          ItemReference[2]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID(),
           CalcDate('<+1D>', PhysInvtOrderLine.GetDateForCalculations()), CalcDate('<+1M>', PhysInvtOrderLine.GetDateForCalculations()));

        // [WHEN] Ran ReferenceLookupPhysicalInventoryOrderItem from codeunit Dist. Integration for the Phys. Invt. Order Line with ShowDialog = TRUE
        asserterror ItemReferenceMgt.ReferenceLookupPhysicalInventoryOrderItem(PhysInvtOrderLine, ReturnedItemReference, true);

        // [THEN] Error "There are no items with reference %1."
        Assert.ExpectedError(StrSubstNo(ItemRefNotExistsErr, ItemReferenceNo));
    end;

    [Test]
    procedure IRLookupPhysInvRecordWhenBarCodeAndExpiredBarCodeShowDialogTrue()
    var
        ItemReference: array[2] of Record "Item Reference";
        ReturnedItemReference: Record "Item Reference";
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
        ItemReferenceNo: Code[50];
    begin
        Initialize();

        // [GIVEN] Barcode for multiple item references
        ItemReferenceNo := LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), Database::"Item Reference");

        // [GIVEN] Phys. Invt. Record with the item reference
        CreatePhysInvtRecordLine(PhysInvtRecordLine);
        PhysInvtRecordLine."Item Reference No." := ItemReferenceNo;
        PhysInvtRecordLine.Modify();

        // [GIVEN] Item References for Item X and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNoAndDates(ItemReference[1], ItemReferenceNo, LibraryInventory.CreateItemNo(),
          ItemReference[1]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID(),
           CalcDate('<-1M>', PhysInvtRecordLine.GetDateForCalculations()), CalcDate('<-1D>', PhysInvtRecordLine.GetDateForCalculations()));

        // [GIVEN] Item References for Item Y and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[2], ItemReferenceNo, LibraryInventory.CreateItemNo(),
          ItemReference[2]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID());

        // [WHEN] Ran ReferenceLookupPhysicalInventoryRecordItem from codeunit Dist. Integration for the Phys. Invt. Record Line with ShowDialog = TRUE
        ItemReferenceMgt.ReferenceLookupPhysicalInventoryRecordItem(PhysInvtRecordLine, ReturnedItemReference, true);

        // [THEN] Item Reference with Item No = X is ignored
        // [THEN] ReferenceLookupPhysicalInventoryRecordItem returns Item Reference with Item No = Y
        ReturnedItemReference.TestField("Item No.", ItemReference[2]."Item No.");
    end;

    [Test]
    [HandlerFunctions('ItemReferenceListModalPageHandler')]
    procedure IRLookupPhysInvRecordWhenBarCodeAndBarCodeDateLimitedShowDialogTrue()
    var
        ItemReference: array[2] of Record "Item Reference";
        ReturnedItemReference: Record "Item Reference";
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
        ItemReferenceNo: Code[50];
    begin
        Initialize();

        // [GIVEN] Barcode for multiple item references
        ItemReferenceNo := LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), Database::"Item Reference");
        LibraryVariableStorage.Enqueue(ItemReferenceNo);

        // [GIVEN] Phys. Invt. Record with the item reference
        CreatePhysInvtRecordLine(PhysInvtRecordLine);
        PhysInvtRecordLine."Item Reference No." := ItemReferenceNo;
        PhysInvtRecordLine.Modify();

        // [GIVEN] Item References for Item X and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNoAndDates(ItemReference[1], ItemReferenceNo, LibraryInventory.CreateItemNo(),
          ItemReference[1]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID(),
           CalcDate('<-1M>', PhysInvtRecordLine.GetDateForCalculations()), CalcDate('<+1M>', PhysInvtRecordLine.GetDateForCalculations()));
        EnqueueItemReferenceFields(ItemReference[1]);

        // [GIVEN] Item References for Item Y and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[2], ItemReferenceNo, LibraryInventory.CreateItemNo(),
          ItemReference[2]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID());
        EnqueueItemReferenceFields(ItemReference[2]);

        // [WHEN] Ran ReferenceLookupPhysicalInventoryRecordItem from codeunit Dist. Integration for the Phys. Invt. Record Line with ShowDialog = TRUE
        ItemReferenceMgt.ReferenceLookupPhysicalInventoryRecordItem(PhysInvtRecordLine, ReturnedItemReference, true);

        // [GIVEN] Page Item Reference List opened showing both Item References
        // [GIVEN] User selected the second one
        // Done in ItemReferenceListModalPageHandler

        // [THEN] ReferenceLookupPhysicalInventoryRecordItem returns Item Reference with Item No = Y
        ReturnedItemReference.TestField("Item No.", ItemReference[2]."Item No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure IRLookupPhysInvRecordWhenTwoExpiredBarCodesShowDialogTrue()
    var
        ItemReference: array[2] of Record "Item Reference";
        ReturnedItemReference: Record "Item Reference";
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
        ItemReferenceNo: Code[50];
    begin
        Initialize();

        // [GIVEN] Barcode for multiple item references
        ItemReferenceNo := LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), Database::"Item Reference");

        // [GIVEN] Phys. Invt. Record with the item reference
        CreatePhysInvtRecordLine(PhysInvtRecordLine);
        PhysInvtRecordLine."Item Reference No." := ItemReferenceNo;
        PhysInvtRecordLine.Modify();

        // [GIVEN] Item References for Item X and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNoAndDates(ItemReference[1], ItemReferenceNo, LibraryInventory.CreateItemNo(),
          ItemReference[1]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID(),
           CalcDate('<-1M>', PhysInvtRecordLine.GetDateForCalculations()), CalcDate('<-1D>', PhysInvtRecordLine.GetDateForCalculations()));

        // [GIVEN] Item References for Item Y and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNoAndDates(ItemReference[2], ItemReferenceNo, LibraryInventory.CreateItemNo(),
          ItemReference[2]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID(),
           CalcDate('<+1D>', PhysInvtRecordLine.GetDateForCalculations()), CalcDate('<+1M>', PhysInvtRecordLine.GetDateForCalculations()));

        // [WHEN] Ran ReferenceLookupPhysicalInventoryRecordItem from codeunit Dist. Integration for the Phys. Invt. Record Line with ShowDialog = TRUE
        asserterror ItemReferenceMgt.ReferenceLookupPhysicalInventoryRecordItem(PhysInvtRecordLine, ReturnedItemReference, true);

        // [THEN] Error "There are no items with reference %1."
        Assert.ExpectedError(StrSubstNo(ItemRefNotExistsErr, ItemReferenceNo));
    end;

    [Test]
    procedure VerifyDescriptionInPhysInvtOrderLineWhenBothItemReferenceAndItemVariantAreUsed()
    var
        Item: array[2] of Record Item;
        ItemReference: array[2] of Record "Item Reference";
        ItemVariant: array[2] of Record "Item Variant";
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: array[2] of Record "Phys. Invt. Order Line";
    begin
        // [SCENARIO 574832] Verify that the item description in the phys. invt. order line is prioritized correctly when both Item Reference and Item Variant are used. 
        Initialize();

        // [GIVEN] Create first Item with Item Variant and Item Reference.
        CreateItemWithItemVariantAndItemReference(Item[1], ItemVariant[1], ItemReference[1]);

        // [GIVEN] Set description value in first Item Reference.
        if ItemReference[1].Description = '' then begin
            ItemReference[1].Validate(Description, ItemReference[1]."Reference No.");
            ItemReference[1].Modify(true);
        end;

        // [GIVEN] Create second Item with Item Variant and Item Reference.
        CreateItemWithItemVariantAndItemReference(Item[2], ItemVariant[2], ItemReference[2]);

        // [GIVEN] Create Phys Inventory Order Header.
        CreatePhysInventoryOrderHeader(PhysInvtOrderHeader);

        // [GIVEN] Create Two Phys Invt Order Lines.
        CreatePhysInventoryOrderLine(PhysInvtOrderLine[1], PhysInvtOrderHeader, Item[1]."No.");
        CreatePhysInventoryOrderLine(PhysInvtOrderLine[2], PhysInvtOrderHeader, Item[2]."No.");

        // [WHEN] Both Item Variant and Item Reference have description values and their values are set in the Phys Invt Order Line.
        ModifyPhysInvtOrderLine(PhysInvtOrderLine[1], ItemVariant[1].Code, ItemReference[1]."Reference No.");

        // [THEN] Ensure that the Phys Invt Order Line description is the same as the Item Reference description.
        Assert.AreEqual(PhysInvtOrderLine[1].Description, ItemReference[1].Description, DescriptionMustBeSameErr);

        // [WHEN] Both Item Variant and Item Reference have description values, but only the Item Variant value is set in the Phys Invt Order Line.
        ModifyPhysInvtOrderLine(PhysInvtOrderLine[1], ItemVariant[1].Code, '');

        // [THEN] Ensure that the Phys Invt Order Line description is the same as the Item Variant description.
        Assert.AreEqual(PhysInvtOrderLine[1].Description, ItemVariant[1].Description, DescriptionMustBeSameErr);

        // [WHEN] Both Item Variant and Item Reference have description values, but both values are set blank in the Phys Invt Order Line.
        ModifyPhysInvtOrderLine(PhysInvtOrderLine[1], '', '');

        // [THEN] Ensure that the Phys Invt Order Line description is the same as the Item description.
        Assert.AreEqual(PhysInvtOrderLine[1].Description, Item[1].Description, DescriptionMustBeSameErr);

        // [WHEN] Item Variant has a description value, but Item Reference has a blank description. However, both values are set in the Phys Invt Order Line.
        ModifyPhysInvtOrderLine(PhysInvtOrderLine[2], ItemVariant[2].Code, ItemReference[2]."Reference No.");

        // [THEN] Ensure that the Phys Invt Order Line description is the same as the Item Variant description.
        Assert.AreEqual(PhysInvtOrderLine[2].Description, ItemVariant[2].Description, DescriptionMustBeSameErr);

        // [WHEN] Item Variant and Item Reference values are set blank in the Phys Invt Order Line.
        ModifyPhysInvtOrderLine(PhysInvtOrderLine[2], '', '');

        // [THEN] Ensure that the Phys Invt Order Line description is the same as the Item description.
        Assert.AreEqual(PhysInvtOrderLine[2].Description, Item[2].Description, DescriptionMustBeSameErr);
    end;

    [Test]
    procedure VerifyDescriptionInPhysInvtRecordLineWhenBothItemReferenceAndItemVariantAreUsed()
    var
        Item: array[2] of Record Item;
        ItemReference: array[2] of Record "Item Reference";
        ItemVariant: array[2] of Record "Item Variant";
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: array[2] of Record "Phys. Invt. Order Line";
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
        PhysInvtRecordLine: array[2] of Record "Phys. Invt. Record Line";
    begin
        // [SCENARIO 574832] Verify that the item description in the phys. invt. order line is prioritized correctly when both Item Reference and Item Variant are used. 
        Initialize();

        // [GIVEN] Create first Item with Item Variant and Item Reference.
        CreateItemWithItemVariantAndItemReference(Item[1], ItemVariant[1], ItemReference[1]);

        // [GIVEN] Set description value in first Item Reference.
        if ItemReference[1].Description = '' then begin
            ItemReference[1].Validate(Description, ItemReference[1]."Reference No.");
            ItemReference[1].Modify(true);
        end;

        // [GIVEN] Create second Item with Item Variant and Item Reference.
        CreateItemWithItemVariantAndItemReference(Item[2], ItemVariant[2], ItemReference[2]);

        // [GIVEN] Create Phys Inventory Order Header.
        CreatePhysInventoryOrderHeader(PhysInvtOrderHeader);

        // [GIVEN] Create Two Phys. Invt. Order Lines.
        CreatePhysInventoryOrderLine(PhysInvtOrderLine[1], PhysInvtOrderHeader, Item[1]."No.");
        CreatePhysInventoryOrderLine(PhysInvtOrderLine[2], PhysInvtOrderHeader, Item[2]."No.");

        // [GIVEN] Create Phys. Invt. Record Header.
        CreatePhysInvtRecordHeader(PhysInvtRecordHeader, PhysInvtOrderHeader."No.");

        // [GIVEN] Create Two Phys. Invt. Record Lines.
        CreatePhysInvtRecordLine(PhysInvtRecordLine[1], PhysInvtRecordHeader, PhysInvtOrderLine[1]);
        CreatePhysInvtRecordLine(PhysInvtRecordLine[2], PhysInvtRecordHeader, PhysInvtOrderLine[2]);

        // [WHEN] Both Item Variant and Item Reference have description values and their values are set in the Phys. Invt. Record Line.
        ModifyPhysInvtRecordLine(PhysInvtRecordLine[1], ItemVariant[1].Code, ItemReference[1]."Reference No.");

        // [THEN] Ensure that the Phys. Invt. Record Lines description is the same as the Item Reference description.
        Assert.AreEqual(PhysInvtRecordLine[1].Description, ItemReference[1].Description, DescriptionMustBeSameErr);

        // [WHEN] Both Item Variant and Item Reference have description values, but only the Item Variant value is set in the Phys. Invt. Record Lines.
        ModifyPhysInvtRecordLine(PhysInvtRecordLine[1], ItemVariant[1].Code, '');

        // [THEN] Ensure that the Phys. Invt. Record Lines description is the same as the Item Variant description.
        Assert.AreEqual(PhysInvtRecordLine[1].Description, ItemVariant[1].Description, DescriptionMustBeSameErr);

        // [WHEN] Both Item Variant and Item Reference have description values, but both values are set blank in the Phys. Invt. Record Lines.
        ModifyPhysInvtRecordLine(PhysInvtRecordLine[1], '', '');

        // [THEN] Ensure that the Phys. Invt. Record Lines description is the same as the Item description.
        Assert.AreEqual(PhysInvtRecordLine[1].Description, Item[1].Description, DescriptionMustBeSameErr);

        // [WHEN] Item Variant has a description value, but Item Reference has a blank description. However, both values are set in the Phys. Invt. Record Lines.
        ModifyPhysInvtRecordLine(PhysInvtRecordLine[2], ItemVariant[2].Code, ItemReference[2]."Reference No.");

        // [THEN] Ensure that the Phys Invt Order Line description is the same as the Item Variant description.
        Assert.AreEqual(PhysInvtRecordLine[2].Description, ItemVariant[2].Description, DescriptionMustBeSameErr);

        // [WHEN] Item Variant and Item Reference values are set blank in the Phys. Invt. Record Lines.
        ModifyPhysInvtRecordLine(PhysInvtRecordLine[2], '', '');

        // [THEN] Ensure that the Phys. Invt. Record Lines description is the same as the Item description.
        Assert.AreEqual(PhysInvtRecordLine[2].Description, Item[2].Description, DescriptionMustBeSameErr);
    end;

    [Test]
    procedure VerifyDescriptionInInvtDocumentLineWhenBothItemReferenceAndItemVariantAreUsed()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: array[2] of Record "Invt. Document Line";
        Item: array[2] of Record Item;
        ItemReference: array[2] of Record "Item Reference";
        ItemVariant: array[2] of Record "Item Variant";
    begin
        // [SCENARIO 574832] Verify that the item description in the Invt. Document Line is prioritized correctly when both Item Reference and Item Variant are used. 
        Initialize();

        // [GIVEN] Create first Item with Item Variant and Item Reference.
        CreateItemWithItemVariantAndItemReference(Item[1], ItemVariant[1], ItemReference[1]);

        // [GIVEN] Set description value in first Item Reference.
        if ItemReference[1].Description = '' then begin
            ItemReference[1].Validate(Description, ItemReference[1]."Reference No.");
            ItemReference[1].Modify(true);
        end;

        // [GIVEN] Create second Item with Item Variant and Item Reference.
        CreateItemWithItemVariantAndItemReference(Item[2], ItemVariant[2], ItemReference[2]);

        // [GIVEN] Create Invt. Document Header.
        CreateInvtDocumentHeader(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Receipt);

        // [GIVEN] Create Two Invt. Document Lines.
        CreateInvtDocumentLine(InvtDocumentLine[1], InvtDocumentHeader, Item[1]);
        CreateInvtDocumentLine(InvtDocumentLine[2], InvtDocumentHeader, Item[2]);

        // [WHEN] Both Item Variant and Item Reference have description values and their values are set in the Invt. Document Line.
        ModifyInvtDocumentLine(InvtDocumentLine[1], ItemVariant[1].Code, ItemReference[1]."Reference No.");

        // [THEN] Ensure that the Invt. Document Line description is the same as the Item Reference description.
        Assert.AreEqual(InvtDocumentLine[1].Description, ItemReference[1].Description, DescriptionMustBeSameErr);

        // [WHEN] Both Item Variant and Item Reference have description values, but only the Item Variant value is set in the Invt. Document Line.
        ModifyInvtDocumentLine(InvtDocumentLine[1], ItemVariant[1].Code, '');

        // [THEN] Ensure that the Invt. Document Line description is the same as the Item Variant description.
        Assert.AreEqual(InvtDocumentLine[1].Description, ItemVariant[1].Description, DescriptionMustBeSameErr);

        // [WHEN] Both Item Variant and Item Reference have description values, but both values are set blank in the Invt. Document Line.
        ModifyInvtDocumentLine(InvtDocumentLine[1], '', '');

        // [THEN] Ensure that the Invt. Document Line description is the same as the Item description.
        Assert.AreEqual(InvtDocumentLine[1].Description, Item[1].Description, DescriptionMustBeSameErr);

        // [WHEN] Item Variant has a description value, but Item Reference has a blank description. However, both values are set in the Invt. Document Line.
        ModifyInvtDocumentLine(InvtDocumentLine[2], ItemVariant[2].Code, ItemReference[2]."Reference No.");

        // [THEN] Ensure that the Invt. Document Line description is the same as the Item Variant description.
        Assert.AreEqual(InvtDocumentLine[2].Description, ItemVariant[2].Description, DescriptionMustBeSameErr);

        // [WHEN] Item Variant and Item Reference values are set blank in the Invt. Document Line.
        ModifyInvtDocumentLine(InvtDocumentLine[2], '', '');

        // [THEN] Ensure that the Invt. Document Line description is the same as the Item description.
        Assert.AreEqual(InvtDocumentLine[2].Description, Item[2].Description, DescriptionMustBeSameErr);
    end;

    [Test]
    procedure VerifyDescriptionInItemJournalLineWhenBothItemReferenceAndItemVariantAreUsed()
    var
        Item: array[2] of Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: array[2] of Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemReference: array[2] of Record "Item Reference";
        ItemVariant: array[2] of Record "Item Variant";
    begin
        // [SCENARIO 574832] Verify that the item description in the Item Journal Line is prioritized correctly when both Item Reference and Item Variant are used. 
        Initialize();

        // [GIVEN] Create first Item with Item Variant and Item Reference.
        CreateItemWithItemVariantAndItemReference(Item[1], ItemVariant[1], ItemReference[1]);

        // [GIVEN] Set description value in first Item Reference.
        if ItemReference[1].Description = '' then begin
            ItemReference[1].Validate(Description, ItemReference[1]."Reference No.");
            ItemReference[1].Modify(true);
        end;

        // [GIVEN] Create second Item with Item Variant and Item Reference.
        CreateItemWithItemVariantAndItemReference(Item[2], ItemVariant[2], ItemReference[2]);

        // [GIVEN] Item Journal Template and Item journal Batch.
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);

        // [GIVEN] Create Two Item Journal Lines.
        CreateItemJournalLine(ItemJournalLine[1], ItemJournalBatch, Item[1]."No.");
        CreateItemJournalLine(ItemJournalLine[2], ItemJournalBatch, Item[2]."No.");

        // [WHEN] Both Item Variant and Item Reference have description values and their values are set in the Item Journal Line.
        ModifyItemJournalLine(ItemJournalLine[1], ItemVariant[1].Code, ItemReference[1]."Reference No.");

        // [THEN] Ensure that the Item Journal Line description is the same as the Item Reference description.
        Assert.AreEqual(ItemJournalLine[1].Description, ItemReference[1].Description, DescriptionMustBeSameErr);

        // [WHEN] Both Item Variant and Item Reference have description values, but only the Item Variant value is set in the Item Journal Line.
        ModifyItemJournalLine(ItemJournalLine[1], ItemVariant[1].Code, '');

        // [THEN] Ensure that the Item Journal Line description is the same as the Item Variant description.
        Assert.AreEqual(ItemJournalLine[1].Description, ItemVariant[1].Description, DescriptionMustBeSameErr);

        // [WHEN] Both Item Variant and Item Reference have description values, but both values are set blank in the Item Journal Line.
        ModifyItemJournalLine(ItemJournalLine[1], '', '');

        // [THEN] Ensure that the Item Journal Line description is the same as the Item description.
        Assert.AreEqual(ItemJournalLine[1].Description, Item[1].Description, DescriptionMustBeSameErr);

        // [WHEN] Item Variant has a description value, but Item Reference has a blank description. However, both values are set in the Item Journal Line.
        ModifyItemJournalLine(ItemJournalLine[2], ItemVariant[2].Code, ItemReference[2]."Reference No.");

        // [THEN] Ensure that the Item Journal Line description is the same as the Item Variant description.
        Assert.AreEqual(ItemJournalLine[2].Description, ItemVariant[2].Description, DescriptionMustBeSameErr);

        // [WHEN] Item Variant and Item Reference values are set blank in the Item Journal Line.
        ModifyItemJournalLine(ItemJournalLine[2], '', '');

        // [THEN] Ensure that the Item Journal Line description is the same as the Item description.
        Assert.AreEqual(ItemJournalLine[2].Description, Item[2].Description, DescriptionMustBeSameErr);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ERM Item Reference Other");

        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ERM Item Reference Other");
        Commit();
        IsInitialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ERM Item Reference Other");
    end;

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line")
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJnlLineWithNoItem(ItemJournalLine, ItemJournalBatch, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, Enum::"Item Ledger Entry Type"::"Positive Adjmt.");
    end;

    local procedure CreatePhysInvtOrderLine(var PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
    begin
        PhysInvtOrderHeader."No." := LibraryRandom.RandText(MaxStrLen(PhysInvtOrderHeader."No."));
        PhysInvtOrderHeader."Posting Date" := WorkDate();
        PhysInvtOrderHeader.Insert();

        PhysInvtOrderLine."Document No." := PhysInvtOrderHeader."No.";
        PhysInvtOrderLine."Line No." := 1;
        PhysInvtOrderLine.Insert();
    end;

    local procedure CreatePhysInvtRecordLine(var PhysInvtRecordLine: Record "Phys. Invt. Record Line")
    var
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
    begin
        CreatePhysInvtOrderLine(PhysInvtOrderLine);

        PhysInvtRecordHeader."Order No." := PhysInvtOrderLine."Document No.";
        PhysInvtRecordHeader."Recording No." := 1;
        PhysInvtRecordHeader.Insert();

        PhysInvtRecordLine."Order No." := PhysInvtOrderLine."Document No.";
        PhysInvtRecordLine.Insert();
    end;

    local procedure EnqueueItemReferenceFields(ItemReference: Record "Item Reference")
    begin
        LibraryVariableStorage.Enqueue(ItemReference."Reference Type");
        LibraryVariableStorage.Enqueue(ItemReference."Reference Type No.");
        LibraryVariableStorage.Enqueue(ItemReference."Item No.");
    end;

    local procedure CreateItemWithItemVariantAndItemReference(var Item: Record Item; var ItemVariant: Record "Item Variant"; var ItemReference: Record "Item Reference")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate(Description, Item."No.");
        Item.Modify(true);

        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        LibraryItemReference.CreateItemReference(ItemReference, Item."No.", ItemVariant.Code, '', "Item Reference Type"::" ", '', LibraryUtility.GenerateRandomCode(ItemReference.FieldNo("Reference No."), Database::"Item Reference"));
    end;

    local procedure CreatePhysInventoryOrderHeader(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header")
    begin
        PhysInvtOrderHeader."No." := '';
        PhysInvtOrderHeader.Insert(true);
    end;

    local procedure CreatePhysInventoryOrderLine(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; ItemNo: Code[20])
    begin
        PhysInvtOrderLine."Document No." := PhysInvtOrderHeader."No.";
        PhysInvtOrderLine."Line No." := GetLineNo(PhysInvtOrderHeader);
        PhysInvtOrderLine.Validate("Item No.", ItemNo);
        PhysInvtOrderLine.Validate("Quantity (Base)", LibraryRandom.RandIntInRange(1, 10));
        PhysInvtOrderLine.Insert(true);
    end;

    local procedure GetLineNo(PhysInvtOrderHeader: Record "Phys. Invt. Order Header"): Integer
    var
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
    begin
        PhysInvtOrderLine.SetRange("Document No.", PhysInvtOrderHeader."No.");
        if PhysInvtOrderLine.FindLast() then
            exit(PhysInvtOrderLine."Line No." + 10000)
        else
            exit(10000);
    end;

    local procedure CreatePhysInvtRecordHeader(var PhysInvtRecordHeader: Record "Phys. Invt. Record Header"; OrderNo: Code[20])
    begin
        PhysInvtRecordHeader.Validate("Order No.", OrderNo);
        PhysInvtRecordHeader.Validate("Recording No.", 1);
        PhysInvtRecordHeader.Insert(true);
    end;

    local procedure CreatePhysInvtRecordLine(var PhysInvtRecordLine: Record "Phys. Invt. Record Line"; PhysInvtRecordHeader: Record "Phys. Invt. Record Header"; PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    begin
        PhysInvtRecordLine.Validate("Order No.", PhysInvtRecordHeader."Order No.");
        PhysInvtRecordLine.Validate("Recording No.", PhysInvtRecordHeader."Recording No.");
        PhysInvtRecordLine.Validate("Line No.", PhysInvtOrderLine."Line No.");
        PhysInvtRecordLine.Validate("Item No.", PhysInvtOrderLine."Item No.");
        PhysInvtRecordLine.Validate("Quantity (Base)", PhysInvtOrderLine."Quantity (Base)");
        PhysInvtRecordLine.Insert(true);
    end;

    local procedure CreateInvtDocumentHeader(var InvtDocumentHeader: Record "Invt. Document Header"; DocumentType: Enum "Invt. Doc. Document Type")
    var
        Location: Record Location;
    begin
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, DocumentType, LibraryWarehouse.CreateLocation(Location));
    end;

    local procedure CreateInvtDocumentLine(var InvtDocumentLine: Record "Invt. Document Line"; InvtDocumentHeader: Record "Invt. Document Header"; Item: Record Item)
    begin
        LibraryInventory.CreateInvtDocumentLine(
          InvtDocumentHeader, InvtDocumentLine, Item."No.", Item."Unit Cost", LibraryRandom.RandIntInRange(1, 10));
    end;

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemJournalBatch: Record "Item Journal Batch"; ItemNo: Code[20])
    begin
        LibraryInventory.CreateItemJnlLineWithNoItem(ItemJournalLine, ItemJournalBatch, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, Enum::"Item Ledger Entry Type"::"Positive Adjmt.");
        ItemJournalLine.Validate("Item No.", ItemNo);
        ItemJournalLine.Modify(true);
    end;

    local procedure ModifyPhysInvtOrderLine(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; VariantCode: Code[20]; ItemReferenceNo: Code[50])
    begin
        PhysInvtOrderLine.Validate("Variant Code", VariantCode);
        PhysInvtOrderLine.Validate("Item Reference No.", ItemReferenceNo);
        PhysInvtOrderLine.Modify(true);
    end;

    local procedure ModifyPhysInvtRecordLine(var PhysInvtRecordLine: Record "Phys. Invt. Record Line"; VariantCode: Code[20]; ItemReferenceNo: Code[50])
    begin
        PhysInvtRecordLine.Validate("Variant Code", VariantCode);
        PhysInvtRecordLine.Validate("Item Reference No.", ItemReferenceNo);
        PhysInvtRecordLine.Modify(true); //PhysInvtOrderLine
    end;

    local procedure ModifyInvtDocumentLine(var InvtDocumentLine: Record "Invt. Document Line"; VariantCode: Code[20]; ItemReferenceNo: Code[50])
    begin
        InvtDocumentLine.Validate("Variant Code", VariantCode);
        InvtDocumentLine.Validate("Item Reference No.", ItemReferenceNo);
        InvtDocumentLine.Modify(true);
    end;

    local procedure ModifyItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; VariantCode: Code[20]; ItemReferenceNo: Code[50])
    begin
        ItemJournalLine.Validate("Variant Code", VariantCode);
        ItemJournalLine.Validate("Item Reference No.", ItemReferenceNo);
        ItemJournalLine.Modify(true);
    end;

    [ModalPageHandler]
    procedure ItemReferenceListModalPageHandler(var ItemReferenceList: TestPage "Item Reference List")
    begin
        ItemReferenceList.FILTER.SetFilter("Reference No.", LibraryVariableStorage.DequeueText());
        repeat
            ItemReferenceList."Reference Type".AssertEquals(LibraryVariableStorage.DequeueInteger());
            ItemReferenceList."Reference Type No.".AssertEquals(LibraryVariableStorage.DequeueText());
            ItemReferenceList."Item No.".AssertEquals(LibraryVariableStorage.DequeueText());
        until ItemReferenceList.Next() = false;
        ItemReferenceList.OK().Invoke();
    end;
}

