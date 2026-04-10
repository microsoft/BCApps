codeunit 134464 "ERM Item Reference Purchase"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Item Reference] [Reference No] [Purchase]
    end;

    var
        Assert: Codeunit Assert;
        ItemReferenceMgt: Codeunit "Item Reference Management";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemReference: Codeunit "Library - Item Reference";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        ItemRefNotExistsErr: Label 'There are no items with reference %1.';
        DialogCodeErr: Label 'Dialog';
        DescriptionMustBeSameErr: Label 'Description must be same.';
        isInitialized: Boolean;

    [Test]
    [HandlerFunctions('ItemReferenceListModalPageHandler')]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenSameVendorsForSameItemsAndBarCodeShowDialogTrue()
    var
        ItemReference: array[2] of Record "Item Reference";
        PurchaseLine: Record "Purchase Line";
        VendorNo: array[2] of Code[20];
        ItemRefNo: Code[50];
        Index: Integer;
        ItemIndex: Integer;
        ItemNo: array[2] of Code[20];
    begin
        // [FEATURE] [UI] [Bar Code]
        // [SCENARIO 289240] Vendors: A,B, Items: X,Y,Z, Vendor Item References: AX, AY, BX, BY and Bar Code Reference PZ
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is Yes
        // [SCENARIO 289240] Page Item Reference List shows only Item References for Vendor A and Bar Code (AX, AY and PZ)
        Initialize();
        for ItemIndex := 1 to ArrayLen(ItemNo) do begin
            ItemNo[ItemIndex] := LibraryInventory.CreateItemNo();
            VendorNo[ItemIndex] := LibraryPurchase.CreateVendorNo();
        end;
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");
        LibraryVariableStorage.Enqueue(ItemRefNo);

        // [GIVEN] Two Item Item References for Item 1000 with No = 1234, Type = Vendor and Type No = 10000 and 20000
        // [GIVEN] Two similar Item Item References for Item 1001
        for ItemIndex := 1 to ArrayLen(ItemNo) do begin
            for Index := 1 to ArrayLen(ItemReference) do
                LibraryItemReference.CreateItemReferenceWithNo(ItemReference[Index], ItemRefNo, ItemNo[ItemIndex],
                  ItemReference[Index]."Reference Type"::Vendor, VendorNo[Index]);
            EnqueueItemReferenceFields(ItemReference[1]);
        end;

        // [GIVEN] Item Reference for Item 1100 with No = 1234, Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNo(
          ItemReference[2], ItemRefNo, LibraryInventory.CreateItemNo(), ItemReference[2]."Reference Type"::"Bar Code",
          LibraryUtility.GenerateGUID());
        EnqueueItemReferenceFields(ItemReference[2]);

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, VendorNo[1], ItemRefNo);

        // [GIVEN] Ran ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = TRUE
        ItemReferenceMgt.ReferenceLookupPurchaseItem(PurchaseLine, ItemReference[1], true);

        // [GIVEN] Page Item Reference List opened showing three Item References:
        // [GIVEN] Two with Type Vendor and Type No = 10000 and last one with Type Bar Code, Stan selected the last one
        // Done in ItemReferenceListModalPageHandler

        // [WHEN] Push OK on page Item Reference List
        // Done in ItemReferenceListModalPageHandler

        // [THEN] ICRLookupPurchaseItem returns Item Reference with Item No = 1100
        ItemReference[1].TestField("Item No.", ItemReference[2]."Item No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemReferenceListModalPageHandler')]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenSameVendorsForSameItemsShowDialogTrue()
    var
        ItemReference: array[2] of Record "Item Reference";
        PurchaseLine: Record "Purchase Line";
        VendorNo: array[2] of Code[20];
        ItemRefNo: Code[50];
        Index: Integer;
        ItemIndex: Integer;
        ItemNo: array[2] of Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 289240] Vendors: A,B, Items: X,Y, Item References: AX, AY, BX, BY
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is Yes
        // [SCENARIO 289240] Page Item Reference List shows only Item References for Vendor A (AX and AY)
        Initialize();
        for ItemIndex := 1 to ArrayLen(ItemNo) do begin
            ItemNo[ItemIndex] := LibraryInventory.CreateItemNo();
            VendorNo[ItemIndex] := LibraryPurchase.CreateVendorNo();
        end;
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");
        LibraryVariableStorage.Enqueue(ItemRefNo);

        // [GIVEN] Two Item Item References for Item 1000 with No = 1234, Type = Vendor and Type No = 10000 and 20000
        // [GIVEN] Two similar Item Item References for Item 1001
        for ItemIndex := 1 to ArrayLen(ItemNo) do begin
            for Index := 1 to ArrayLen(ItemReference) do
                LibraryItemReference.CreateItemReferenceWithNo(ItemReference[Index], ItemRefNo, ItemNo[ItemIndex],
                  ItemReference[Index]."Reference Type"::Vendor, VendorNo[Index]);
            EnqueueItemReferenceFields(ItemReference[1]);
        end;

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, VendorNo[1], ItemRefNo);

        // [GIVEN] Ran ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = TRUE
        ItemReferenceMgt.ReferenceLookupPurchaseItem(PurchaseLine, ItemReference[1], true);

        // [GIVEN] Page Item Reference List opened showing two Item References with Type No = 10000, first for Item 1000, second for Item 1001
        // [GIVEN] Stan selected the second one
        // Done in ItemReferenceListModalPageHandler

        // [WHEN] Push OK on page Item Reference List
        // Done in ItemReferenceListModalPageHandler

        // [THEN] ICRLookupPurchaseItem returns Item Reference with Item No = 1001
        ItemReference[1].TestField("Item No.", ItemReference[2]."Item No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemReferenceListModalPageHandler')]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenVendorAndBarCodeDifferentItemsShowDialogTrue()
    var
        ItemReference: array[2] of Record "Item Reference";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
        ItemRefNo: Code[50];
    begin
        // [FEATURE] [UI] [Bar Code]
        // [SCENARIO 289240] Vendor A, Items: X,Y Vendor Reference AX and Bar Code Reference PY
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is Yes
        // [SCENARIO 289240] Page Item Reference List shows both Item References (AX and PY)
        Initialize();
        VendorNo := LibraryPurchase.CreateVendorNo();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");
        LibraryVariableStorage.Enqueue(ItemRefNo);

        // [GIVEN] Item Item References for Item 1000 with No = 1234, Type = Vendor and Type No = 10000
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[1], ItemRefNo, LibraryInventory.CreateItemNo(),
          ItemReference[1]."Reference Type"::Vendor, VendorNo);
        EnqueueItemReferenceFields(ItemReference[1]);

        // [GIVEN] Item Item References for Item 1001 with same No and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[2], ItemRefNo, LibraryInventory.CreateItemNo(),
          ItemReference[2]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID());
        EnqueueItemReferenceFields(ItemReference[2]);

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, VendorNo, ItemRefNo);

        // [GIVEN] Ran ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = TRUE
        ItemReferenceMgt.ReferenceLookupPurchaseItem(PurchaseLine, ItemReference[1], true);

        // [GIVEN] Page Item Reference List opened showing both Item References, first for Item 1000, second for Item 1001
        // [GIVEN] Stan selected the second one
        // Done in ItemReferenceListModalPageHandler

        // [WHEN] Push OK on page Item Reference List
        // Done in ItemReferenceListModalPageHandler

        // [THEN] ICRLookupPurchaseItem returns Item Reference with Item No = 1001
        ItemReference[1].TestField("Item No.", ItemReference[2]."Item No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemReferenceListModalPageHandler')]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenVendorAndBlankTypeDifferentItemsShowDialogTrue()
    var
        ItemReference: array[2] of Record "Item Reference";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
        ItemRefNo: Code[50];
    begin
        // [FEATURE] [UI] [Bar Code]
        // [SCENARIO 289240] Vendor A, Items: X,Y Vendor Reference AX and <blank> Type Reference TY
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is Yes
        // [SCENARIO 289240] Page Item Reference List shows both Item References (AX and TY)
        Initialize();
        VendorNo := LibraryPurchase.CreateVendorNo();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");
        LibraryVariableStorage.Enqueue(ItemRefNo);

        // [GIVEN] Item Item References for Item 1000 with No = 1234, Type = Vendor and Type No = 10000
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[1], ItemRefNo, LibraryInventory.CreateItemNo(),
          ItemReference[1]."Reference Type"::Vendor, VendorNo);

        // [GIVEN] Item Item References for Item 1001 with No = 1234 and Type = <blank>
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[2], ItemRefNo, LibraryInventory.CreateItemNo(),
          ItemReference[2]."Reference Type"::" ", '');
        EnqueueItemReferenceFields(ItemReference[2]); // <blank> type record is to be displayed first
        EnqueueItemReferenceFields(ItemReference[1]);

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, VendorNo, ItemRefNo);

        // [GIVEN] Ran ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = TRUE
        ItemReferenceMgt.ReferenceLookupPurchaseItem(PurchaseLine, ItemReference[2], true);

        // [GIVEN] Page Item Reference List opened showing both Item References, first with <blank> Type, second with Type Vendor
        // [GIVEN] Stan selected the second one
        // Done in ItemReferenceListModalPageHandler

        // [WHEN] Push OK on page Item Reference List
        // Done in ItemReferenceListModalPageHandler

        // [THEN] ICRLookupPurchaseItem returns Item Reference with Item No = 1000
        ItemReference[2].TestField("Item No.", ItemReference[1]."Item No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemReferenceListModalPageHandler')]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenSameVendorDifferentItemsShowDialogTrue()
    var
        ItemReference: array[2] of Record "Item Reference";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
        ItemRefNo: Code[50];
        Index: Integer;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 289240] Vendor A, Items: X,Y Item References AX and AY
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is Yes
        // [SCENARIO 289240] Page Item Reference List shows both Item References (AX and AY)
        Initialize();
        VendorNo := LibraryPurchase.CreateVendorNo();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");
        LibraryVariableStorage.Enqueue(ItemRefNo);

        // [GIVEN] Item Item References for Items 1000 and 1001 with same No = 1234, Type = Vendor and Type No = 10000
        for Index := 1 to ArrayLen(ItemReference) do begin
            LibraryItemReference.CreateItemReferenceWithNo(ItemReference[Index], ItemRefNo, LibraryInventory.CreateItemNo(),
              ItemReference[Index]."Reference Type"::Vendor, VendorNo);
            EnqueueItemReferenceFields(ItemReference[Index]);
        end;

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, VendorNo, ItemRefNo);

        // [GIVEN] Ran ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = TRUE
        ItemReferenceMgt.ReferenceLookupPurchaseItem(PurchaseLine, ItemReference[1], true);

        // [GIVEN] Page Item Reference List opened showing both Item References: first for Item 1000, second for Item 1001
        // [GIVEN] Stan selected the second one
        // Done in ItemReferenceListModalPageHandler

        // [WHEN] Push OK on page Item Reference List
        // Done in ItemReferenceListModalPageHandler

        // [THEN] ICRLookupPurchaseItem returns Item Reference with Item No = 1001
        ItemReference[1].TestField("Item No.", ItemReference[2]."Item No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemReferenceListModalPageHandler')]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenBarCodesDifferentItemsShowDialogTrue()
    var
        ItemReference: array[2] of Record "Item Reference";
        PurchaseLine: Record "Purchase Line";
        ItemRefNo: Code[50];
        Index: Integer;
    begin
        // [FEATURE] [UI] [Bar Code]
        // [SCENARIO 289240] Items: X,Y, Bar Code Item References: PX,PY
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor and ShowDialog is Yes
        // [SCENARIO 289240] Page Item Reference List shows both Item References (PX and PY)
        Initialize();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");
        LibraryVariableStorage.Enqueue(ItemRefNo);

        // [GIVEN] Item Item References for Items 1000 and 1001, both with No = 1234 and Type = Bar Code
        for Index := 1 to ArrayLen(ItemReference) do begin
            LibraryItemReference.CreateItemReferenceWithNo(ItemReference[Index], ItemRefNo, LibraryInventory.CreateItemNo(),
              ItemReference[Index]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID());
            EnqueueItemReferenceFields(ItemReference[Index]);
        end;

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, LibraryPurchase.CreateVendorNo(), ItemRefNo);

        // [GIVEN] Ran ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = TRUE
        ItemReferenceMgt.ReferenceLookupPurchaseItem(PurchaseLine, ItemReference[1], true);

        // [GIVEN] Page Item Reference List opened showing both Item References: first for Item 1000, second for Item 1001
        // [GIVEN] Stan selected the second one
        // Done in ItemReferenceListModalPageHandler

        // [WHEN] Push OK on page Item Reference List
        // Done in ItemReferenceListModalPageHandler

        // [THEN] ICRLookupPurchaseItem returns Item Reference with Item No = 1001
        ItemReference[1].TestField("Item No.", ItemReference[2]."Item No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenVendorAndBarCodeSameItemShowDialogTrue()
    var
        ItemReference: array[2] of Record "Item Reference";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
        ItemRefNo: Code[50];
    begin
        // [FEATURE] [Bar Code]
        // [SCENARIO 289240] Vendor A, Item X, Vendor Reference AX, Bar Code Reference PX
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is Yes
        // [SCENARIO 289240] Page Item Reference List is not shown, ICRLookupPurchaseItem returns Reference for Vendor A (AX)
        Initialize();
        VendorNo := LibraryPurchase.CreateVendorNo();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Item Item References for Item 1000 with No = 1234, Type = Vendor and Type No = 10000
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[1], ItemRefNo, LibraryInventory.CreateItemNo(),
          ItemReference[1]."Reference Type"::Vendor, VendorNo);

        // [GIVEN] Item Item References for same Item with same No and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[2], ItemRefNo, ItemReference[1]."Item No.",
          ItemReference[2]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID());

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, VendorNo, ItemRefNo);

        // [WHEN] Ran ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = TRUE
        ItemReferenceMgt.ReferenceLookupPurchaseItem(PurchaseLine, ItemReference[2], true);

        // [THEN] ICRLookupPurchaseItem returns Item Reference with Item No = 1000
        ItemReference[2].TestField("Item No.", ItemReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenVendorAndBlankTypeSameItemShowDialogTrue()
    var
        ItemReference: array[2] of Record "Item Reference";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
        ItemRefNo: Code[50];
    begin
        // [FEATURE] [Bar Code]
        // [SCENARIO 289240] Vendor A, Item X, Vendor Reference AX, <blank> Type Reference TX
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is Yes
        // [SCENARIO 289240] Page Item Reference List is not shown, ICRLookupPurchaseItem returns Reference for Vendor A (AX)
        Initialize();
        VendorNo := LibraryPurchase.CreateVendorNo();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Item Item References for Item 1000 with No = 1234, Type = Vendor and Type No = 10000
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[1], ItemRefNo, LibraryInventory.CreateItemNo(),
          ItemReference[1]."Reference Type"::Vendor, VendorNo);

        // [GIVEN] Item Item References for same Item with same No and Type = <blank>
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[2], ItemRefNo, ItemReference[1]."Item No.",
          ItemReference[2]."Reference Type"::" ", '');

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, VendorNo, ItemRefNo);

        // [WHEN] Ran ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = TRUE
        ItemReferenceMgt.ReferenceLookupPurchaseItem(PurchaseLine, ItemReference[2], true);

        // [THEN] ICRLookupPurchaseItem returns Item Reference with Item No = 1000
        ItemReference[2].TestField("Item No.", ItemReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenBarCodesSameItemShowDialogTrue()
    var
        ItemReference: array[2] of Record "Item Reference";
        PurchaseLine: Record "Purchase Line";
        ItemRefNo: Code[50];
        ItemNo: Code[20];
        Index: Integer;
    begin
        // [FEATURE] [Bar Code]
        // [SCENARIO 289240] Item X, Bar Code Item References: PX,TX
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor and ShowDialog is Yes
        // [SCENARIO 289240] Page Item Reference List is not shown, ICRLookupPurchaseItem returns Reference PX
        Initialize();
        ItemNo := LibraryInventory.CreateItemNo();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Item Item References both for same Item, No = 1234 and Type = Bar Code, Type No are "P" and "T"
        for Index := 1 to ArrayLen(ItemReference) do
            LibraryItemReference.CreateItemReferenceWithNo(ItemReference[Index], ItemRefNo, ItemNo,
              ItemReference[Index]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID());

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, LibraryPurchase.CreateVendorNo(), ItemRefNo);

        // [WHEN] Run ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = TRUE
        ItemReferenceMgt.ReferenceLookupPurchaseItem(PurchaseLine, ItemReference[2], true);

        // [THEN] ICRLookupPurchaseItem returns Item Reference with Type No = "P"
        ItemReference[2].TestField("Reference Type No.", ItemReference[1]."Reference Type No.");
        ItemReference[2].TestField("Item No.", ItemReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenDifferentVendorsSameItemShowDialogTrue()
    var
        ItemReference: array[2] of Record "Item Reference";
        PurchaseLine: Record "Purchase Line";
        ItemRefNo: Code[50];
        ItemNo: Code[20];
        Index: Integer;
    begin
        // [SCENARIO 289240] Vendors: A,B, Item X, Item References AX and BX
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is Yes
        // [SCENARIO 289240] Page Item Reference List is not shown, ICRLookupPurchaseItem returns Reference for Vendor A (AX)
        Initialize();
        ItemNo := LibraryInventory.CreateItemNo();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Two Item Item References for Item 1000 with same No = 1234, Type = Vendor, first has Type No = 10000, second has Type No = 20000
        for Index := 1 to ArrayLen(ItemReference) do
            LibraryItemReference.CreateItemReferenceWithNo(ItemReference[Index], ItemRefNo, ItemNo,
              ItemReference[Index]."Reference Type"::Vendor, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(
          PurchaseLine, CopyStr(ItemReference[1]."Reference Type No.", 1, MaxStrLen(PurchaseLine."Buy-from Vendor No.")),
          ItemRefNo);

        // [WHEN] Run ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = TRUE
        ItemReferenceMgt.ReferenceLookupPurchaseItem(PurchaseLine, ItemReference[2], true);

        // [THEN] ICRLookupPurchaseItem returns Item Reference with Item No = 1000
        ItemReference[2].TestField("Item No.", ItemReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenDifferentVendorsDifferentItemsShowDialogTrue()
    var
        ItemReference: array[2] of Record "Item Reference";
        PurchaseLine: Record "Purchase Line";
        ItemRefNo: Code[50];
        Index: Integer;
    begin
        // [SCENARIO 289240] Vendors: A,B, Items X,Y, Item References AX and BY
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is Yes
        // [SCENARIO 289240] Page Item Reference List is not shown, ICRLookupPurchaseItem returns Reference for Vendor A (AX)
        Initialize();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Item Reference for Item 1000 with No = 1234, Type = Vendor, Type No = 10000
        // [GIVEN] Item Reference for Item 1001 with No = 1234, Type = Vendor, Type No = 20000
        for Index := 1 to ArrayLen(ItemReference) do
            LibraryItemReference.CreateItemReferenceWithNo(ItemReference[Index], ItemRefNo, LibraryInventory.CreateItemNo(),
              ItemReference[Index]."Reference Type"::Vendor, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(
          PurchaseLine, CopyStr(ItemReference[1]."Reference Type No.", 1, MaxStrLen(PurchaseLine."Buy-from Vendor No.")),
          ItemRefNo);

        // [WHEN] Run ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = TRUE
        ItemReferenceMgt.ReferenceLookupPurchaseItem(PurchaseLine, ItemReference[2], true);

        // [THEN] ICRLookupPurchaseItem returns Item Reference with Item No = 1000
        ItemReference[2].TestField("Item No.", ItemReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenOtherVendorAndBarCodeShowDialogTrue()
    var
        ItemReference: array[2] of Record "Item Reference";
        PurchaseLine: Record "Purchase Line";
        ItemRefNo: Code[50];
    begin
        // [FEATURE] [Bar Code]
        // [SCENARIO 289240] Vendor B, Items X,Y Vendor Reference BX, Bar Code Reference PY
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is Yes
        // [SCENARIO 289240] Page Item Reference List is not shown, ICRLookupPurchaseItem returns Reference PY
        Initialize();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Item Reference for Item 1000 with No = 1234, Type = Vendor and Type No = 20000
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[1], ItemRefNo, LibraryInventory.CreateItemNo(),
          ItemReference[1]."Reference Type"::Vendor, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Item Item References for Item 1001 with same No and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[2], ItemRefNo, ItemReference[1]."Item No.",
          ItemReference[2]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID());

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, LibraryPurchase.CreateVendorNo(), ItemRefNo);

        // [WHEN] Ran ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = TRUE
        ItemReferenceMgt.ReferenceLookupPurchaseItem(PurchaseLine, ItemReference[1], true);

        // [THEN] ICRLookupPurchaseItem returns Item Reference with Item No = 1001
        ItemReference[1].TestField("Item No.", ItemReference[2]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenOtherVendorShowDialogTrue()
    var
        ItemReference: Record "Item Reference";
        PurchaseLine: Record "Purchase Line";
        ItemRefNo: Code[50];
    begin
        // [SCENARIO 289240] Vendor B, Reference BX
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is Yes
        // [SCENARIO 289240] ICRLookupPurchaseItem throws error
        Initialize();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference.FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Item Reference for Item with No = 1234, Type = Vendor and Type No = 20000
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference, ItemRefNo, LibraryInventory.CreateItemNo(),
          ItemReference."Reference Type"::Vendor, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, LibraryPurchase.CreateVendorNo(), ItemRefNo);

        // [WHEN] Run ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = TRUE
        asserterror ItemReferenceMgt.ReferenceLookupPurchaseItem(PurchaseLine, ItemReference, true);

        // [THEN] Error "There are no items with cross reference: 1234"
        Assert.ExpectedError(StrSubstNo(ItemRefNotExistsErr, ItemRefNo));
        Assert.ExpectedErrorCode(DialogCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenOtherMultipleVendorsShowDialogTrue()
    var
        ItemReference: Record "Item Reference";
        PurchaseLine: Record "Purchase Line";
        ItemRefNo: Code[50];
    begin
        // [SCENARIO 289240] Vendors: B,C Item References BX,CY
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is Yes
        // [SCENARIO 289240] ICRLookupPurchaseItem throws error
        Initialize();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference.FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Two Item Item References with same No = 1234, same Type = Vendor and Type No 20000 and 30000
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference, ItemRefNo, LibraryInventory.CreateItemNo(),
          ItemReference."Reference Type"::Vendor, LibraryPurchase.CreateVendorNo());
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference, ItemRefNo, LibraryInventory.CreateItemNo(),
          ItemReference."Reference Type"::Vendor, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, LibraryPurchase.CreateVendorNo(), ItemRefNo);

        // [WHEN] Run ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = TRUE
        asserterror ItemReferenceMgt.ReferenceLookupPurchaseItem(PurchaseLine, ItemReference, true);

        // [THEN] Error "There are no items with cross reference: 1234"
        Assert.ExpectedError(StrSubstNo(ItemRefNotExistsErr, ItemRefNo));
        Assert.ExpectedErrorCode(DialogCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenOneVendorShowDialogTrue()
    var
        ItemReference: Record "Item Reference";
        PurchaseLine: Record "Purchase Line";
        ItemRefNo: Code[50];
        ItemNo: Code[20];
    begin
        // [SCENARIO 289240] Vendor A, Reference AX
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is Yes
        // [SCENARIO 289240] ICRLookupPurchaseItem Returns Reference AX
        Initialize();
        ItemNo := LibraryInventory.CreateItemNo();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference.FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Item Reference for Item 1000 with No = 1234, Type = Vendor and Type No = 10000
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference, ItemRefNo, ItemNo,
          ItemReference."Reference Type"::Vendor, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(
          PurchaseLine, CopyStr(ItemReference."Reference Type No.", 1, MaxStrLen(PurchaseLine."Buy-from Vendor No.")),
          ItemRefNo);

        // [WHEN] Run ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = TRUE
        ItemReferenceMgt.ReferenceLookupPurchaseItem(PurchaseLine, ItemReference, true);

        // [THEN] ICRLookupPurchaseItem returns Item Reference with Item No = 1000
        ItemReference.TestField("Item No.", ItemNo)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenNoItemRefShowDialogTrue()
    var
        DummyItemReference: Record "Item Reference";
        PurchaseLine: Record "Purchase Line";
        ItemRefNo: Code[50];
    begin
        // [SCENARIO 289240] No Item References with No = 1234
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A with Reference No = 1234 and ShowDialog is Yes
        // [SCENARIO 289240] ICRLookupPurchaseItem Returns Reference AX
        Initialize();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(DummyItemReference.FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, LibraryPurchase.CreateVendorNo(), ItemRefNo);

        // [WHEN] Run ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = TRUE
        asserterror ItemReferenceMgt.ReferenceLookupPurchaseItem(PurchaseLine, DummyItemReference, true);

        // [THEN] Error "There are no items with cross reference: 1234"
        Assert.ExpectedError(StrSubstNo(ItemRefNotExistsErr, ItemRefNo));
        Assert.ExpectedErrorCode(DialogCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenSameVendorsForSameItemsAndBarCodeShowDialogFalse()
    var
        ItemReference: array[2] of Record "Item Reference";
        PurchaseLine: Record "Purchase Line";
        VendorNo: array[2] of Code[20];
        ItemRefNo: Code[50];
        Index: Integer;
        ItemIndex: Integer;
        ItemNo: array[2] of Code[20];
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO 289240] Vendors: A,B, Items: X,Y,Z, Vendor Item References: AX, AY, BX, BY and Bar Code Reference PZ
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is No
        // [SCENARIO 289240] ICRLookupPurchaseItem returns Reference for Vendor A and Item X (AX)
        Initialize();
        for ItemIndex := 1 to ArrayLen(ItemNo) do begin
            ItemNo[ItemIndex] := LibraryInventory.CreateItemNo();
            VendorNo[ItemIndex] := LibraryPurchase.CreateVendorNo();
        end;
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Two Item Item References for Item 1000 with No = 1234, Type = Vendor and Type No = 10000 and 20000
        // [GIVEN] Two similar Item Item References for Item 1001
        for ItemIndex := 1 to ArrayLen(ItemNo) do
            for Index := 1 to ArrayLen(ItemReference) do
                LibraryItemReference.CreateItemReferenceWithNo(ItemReference[Index], ItemRefNo, ItemNo[ItemIndex],
                  ItemReference[Index]."Reference Type"::Vendor, VendorNo[Index]);

        // [GIVEN] Item Reference for Item 1100 with No = 1234, Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNo(
          ItemReference[2], ItemRefNo, LibraryInventory.CreateItemNo(), ItemReference[2]."Reference Type"::"Bar Code",
          LibraryUtility.GenerateGUID());

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, VendorNo[1], ItemRefNo);

        // [WHEN] Run ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = FALSE
        ItemReferenceMgt.ReferenceLookupPurchaseItem(PurchaseLine, ItemReference[2], false);

        // [THEN] ICRLookupPurchaseItem returns Item Reference with Item No = 1000 and Type No = 10000
        ItemReference[2].TestField("Item No.", ItemNo[1]);
        ItemReference[2].TestField("Reference Type No.", VendorNo[1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenSameVendorsForSameItemsShowDialogFalse()
    var
        ItemReference: array[2] of Record "Item Reference";
        PurchaseLine: Record "Purchase Line";
        VendorNo: array[2] of Code[20];
        ItemRefNo: Code[50];
        Index: Integer;
        ItemIndex: Integer;
        ItemNo: array[2] of Code[20];
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO 289240] Vendors: A,B, Items: X,Y, Item References: AX, AY, BX, BY
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is No
        // [SCENARIO 289240] ICRLookupPurchaseItem returns Reference for Vendor A and Item X (AX)
        Initialize();
        for ItemIndex := 1 to ArrayLen(ItemNo) do begin
            ItemNo[ItemIndex] := LibraryInventory.CreateItemNo();
            VendorNo[ItemIndex] := LibraryPurchase.CreateVendorNo();
        end;
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Two Item Item References for Item 1000 with No = 1234, Type = Vendor and Type No = 10000 and 20000
        // [GIVEN] Two similar Item Item References for Item 1001
        for ItemIndex := 1 to ArrayLen(ItemNo) do
            for Index := 1 to ArrayLen(ItemReference) do
                LibraryItemReference.CreateItemReferenceWithNo(ItemReference[Index], ItemRefNo, ItemNo[ItemIndex],
                  ItemReference[Index]."Reference Type"::Vendor, VendorNo[Index]);

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, VendorNo[1], ItemRefNo);

        // [When] Run ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = FALSE
        ItemReferenceMgt.ReferenceLookupPurchaseItem(PurchaseLine, ItemReference[2], false);

        // [THEN] ICRLookupPurchaseItem returns Item Reference with Item No = 1000 and Type No = 10000
        ItemReference[2].TestField("Item No.", ItemNo[1]);
        ItemReference[2].TestField("Reference Type No.", VendorNo[1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenVendorAndBarCodeDifferentItemsShowDialogFalse()
    var
        ItemReference: array[2] of Record "Item Reference";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
        ItemRefNo: Code[50];
    begin
        // [FEATURE] [Intercompany] [Bar Code]
        // [SCENARIO 289240] Vendor A, Items: X,Y Vendor Reference AX and Bar Code Reference PY
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is No
        // [SCENARIO 289240] ICRLookupPurchaseItem returns Reference for Vendor A and Item X (AX)
        Initialize();
        VendorNo := LibraryPurchase.CreateVendorNo();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Item Item References for Item 1000 with No = 1234, Type = Vendor and Type No = 10000
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[1], ItemRefNo, LibraryInventory.CreateItemNo(),
          ItemReference[1]."Reference Type"::Vendor, VendorNo);

        // [GIVEN] Item Item References for Item 1001 with same No and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[2], ItemRefNo, LibraryInventory.CreateItemNo(),
          ItemReference[2]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID());

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, VendorNo, ItemRefNo);

        // [WHEN] Ran ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = FALSE
        ItemReferenceMgt.ReferenceLookupPurchaseItem(PurchaseLine, ItemReference[2], false);

        // [THEN] ICRLookupPurchaseItem returns Item Reference with Item No = 1000
        ItemReference[2].TestField("Item No.", ItemReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenVendorAndBlankTypeDifferentItemsShowDialogFalse()
    var
        ItemReference: array[2] of Record "Item Reference";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
        ItemRefNo: Code[50];
    begin
        // [FEATURE] [Intercompany] [Bar Code]
        // [SCENARIO 289240] Vendor A, Items: X,Y Vendor Reference AX and <blank> Type Reference TY
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is No
        // [SCENARIO 289240] ICRLookupPurchaseItem returns Reference for Vendor A and Item X (AX)
        Initialize();
        VendorNo := LibraryPurchase.CreateVendorNo();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Item Item References for Item 1000 with No = 1234, Type = Vendor and Type No = 10000
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[1], ItemRefNo, LibraryInventory.CreateItemNo(),
          ItemReference[1]."Reference Type"::Vendor, VendorNo);

        // [GIVEN] Item Item References for Item 1001 with No = 1234 and Type = <blank>
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[2], ItemRefNo, LibraryInventory.CreateItemNo(),
          ItemReference[2]."Reference Type"::" ", '');

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, VendorNo, ItemRefNo);

        // [WHEN] Run ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = FALSE
        ItemReferenceMgt.ReferenceLookupPurchaseItem(PurchaseLine, ItemReference[2], false);

        // [THEN] ICRLookupPurchaseItem returns Item Reference with Item No = 1000
        ItemReference[2].TestField("Item No.", ItemReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenSameVendorDifferentItemsShowDialogFalse()
    var
        ItemReference: array[2] of Record "Item Reference";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
        ItemRefNo: Code[50];
        Index: Integer;
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO 289240] Vendor A, Items: X,Y Item References AX and AY
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is No
        // [SCENARIO 289240] ICRLookupPurchaseItem returns Reference for Vendor A and Item X (AX)
        Initialize();
        VendorNo := LibraryPurchase.CreateVendorNo();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Item Item References for Items 1000 and 1001 with same No = 1234, Type = Vendor and Type No = 10000
        for Index := 1 to ArrayLen(ItemReference) do
            LibraryItemReference.CreateItemReferenceWithNo(ItemReference[Index], ItemRefNo, LibraryInventory.CreateItemNo(),
              ItemReference[Index]."Reference Type"::Vendor, VendorNo);

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, VendorNo, ItemRefNo);

        // [WHEN] Run ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = FALSE
        ItemReferenceMgt.ReferenceLookupPurchaseItem(PurchaseLine, ItemReference[2], false);

        // [THEN] ICRLookupPurchaseItem returns Item Reference with Item No = 1000
        ItemReference[2].TestField("Item No.", ItemReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenBarCodesDifferentItemsShowDialogFalse()
    var
        ItemReference: array[2] of Record "Item Reference";
        PurchaseLine: Record "Purchase Line";
        ItemRefNo: Code[50];
        Index: Integer;
    begin
        // [FEATURE] [Intercompany] [Bar Code]
        // [SCENARIO 289240] Items: X,Y, Bar Code Item References: PX,PY
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor and ShowDialog is No
        // [SCENARIO 289240] ICRLookupPurchaseItem returns Reference PX
        Initialize();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Item Item References for Items 1000 and 1001, both with No = 1234 and Type = Bar Code
        for Index := 1 to ArrayLen(ItemReference) do
            LibraryItemReference.CreateItemReferenceWithNo(ItemReference[Index], ItemRefNo, LibraryInventory.CreateItemNo(),
              ItemReference[Index]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID());

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, LibraryPurchase.CreateVendorNo(), ItemRefNo);

        // [WHEN] Run ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = FALSE
        ItemReferenceMgt.ReferenceLookupPurchaseItem(PurchaseLine, ItemReference[2], false);

        // [THEN] ICRLookupPurchaseItem returns Item Reference with Item No = 1001
        ItemReference[2].TestField("Item No.", ItemReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenVendorAndBarCodeSameItemShowDialogFalse()
    var
        ItemReference: array[2] of Record "Item Reference";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
        ItemRefNo: Code[50];
    begin
        // [FEATURE] [Intercompany] [Bar Code]
        // [SCENARIO 289240] Vendor A, Item X, Vendor Reference AX, Bar Code Reference PX
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is No
        // [SCENARIO 289240] ICRLookupPurchaseItem returns Reference for Vendor A (AX)
        Initialize();
        VendorNo := LibraryPurchase.CreateVendorNo();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Item Item References for Item 1000 with No = 1234, Type = Vendor and Type No = 10000
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[1], ItemRefNo, LibraryInventory.CreateItemNo(),
          ItemReference[1]."Reference Type"::Vendor, VendorNo);

        // [GIVEN] Item Item References for same Item with same No and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[2], ItemRefNo, ItemReference[1]."Item No.",
          ItemReference[2]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID());

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, VendorNo, ItemRefNo);

        // [WHEN] Ran ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = FALSE
        ItemReferenceMgt.ReferenceLookupPurchaseItem(PurchaseLine, ItemReference[2], false);

        // [THEN] ICRLookupPurchaseItem returns Item Reference with Item No = 1000
        ItemReference[2].TestField("Item No.", ItemReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenVendorAndBlankTypeSameItemShowDialogFalse()
    var
        ItemReference: array[2] of Record "Item Reference";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
        ItemRefNo: Code[50];
    begin
        // [FEATURE] [Intercompany] [Bar Code]
        // [SCENARIO 289240] Vendor A, Item X, Vendor Reference AX, <blank> Type Reference TX
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is No
        // [SCENARIO 289240] Page Item Reference List is not shown, ICRLookupPurchaseItem returns Reference for Vendor A (AX)
        Initialize();
        VendorNo := LibraryPurchase.CreateVendorNo();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Item Item References for Item 1000 with No = 1234, Type = Vendor and Type No = 10000
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[1], ItemRefNo, LibraryInventory.CreateItemNo(),
          ItemReference[1]."Reference Type"::Vendor, VendorNo);

        // [GIVEN] Item Item References for same Item with same No and Type = <blank>
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[2], ItemRefNo, ItemReference[1]."Item No.",
          ItemReference[2]."Reference Type"::" ", '');

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, VendorNo, ItemRefNo);

        // [WHEN] Ran ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = FALSE
        ItemReferenceMgt.ReferenceLookupPurchaseItem(PurchaseLine, ItemReference[2], false);

        // [THEN] ICRLookupPurchaseItem returns Item Reference with Item No = 1000
        ItemReference[2].TestField("Item No.", ItemReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenBarCodesSameItemShowDialogFalse()
    var
        ItemReference: array[2] of Record "Item Reference";
        PurchaseLine: Record "Purchase Line";
        ItemRefNo: Code[50];
        ItemNo: Code[20];
        Index: Integer;
    begin
        // [FEATURE] [Intercompany] [Bar Code]
        // [SCENARIO 289240] Item X, Bar Code Item References: PX,TX
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor and ShowDialog is No
        // [SCENARIO 289240] ICRLookupPurchaseItem returns Reference PX
        Initialize();
        ItemNo := LibraryInventory.CreateItemNo();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Item Item References both for same Item, No = 1234 and Type = Bar Code, Type No are "P" and "T"
        for Index := 1 to ArrayLen(ItemReference) do
            LibraryItemReference.CreateItemReferenceWithNo(ItemReference[Index], ItemRefNo, ItemNo,
              ItemReference[Index]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID());

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, LibraryPurchase.CreateVendorNo(), ItemRefNo);

        // [WHEN] Run ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = FALSE
        ItemReferenceMgt.ReferenceLookupPurchaseItem(PurchaseLine, ItemReference[2], false);

        // [THEN] ICRLookupPurchaseItem returns Item Reference with Type No = "P"
        ItemReference[2].TestField("Reference Type No.", ItemReference[1]."Reference Type No.");
        ItemReference[2].TestField("Item No.", ItemReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenDifferentVendorsSameItemShowDialogFalse()
    var
        ItemReference: array[2] of Record "Item Reference";
        PurchaseLine: Record "Purchase Line";
        ItemRefNo: Code[50];
        ItemNo: Code[20];
        Index: Integer;
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO 289240] Vendors: A,B, Item X, Item References AX and BX
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is No
        // [SCENARIO 289240] ICRLookupPurchaseItem returns Reference for Vendor A (AX)
        Initialize();
        ItemNo := LibraryInventory.CreateItemNo();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Two Item Item References for Item 1000 with same No = 1234, Type = Vendor, first has Type No = 10000, second has Type No = 20000
        for Index := 1 to ArrayLen(ItemReference) do
            LibraryItemReference.CreateItemReferenceWithNo(ItemReference[Index], ItemRefNo, ItemNo,
              ItemReference[Index]."Reference Type"::Vendor, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(
          PurchaseLine, CopyStr(ItemReference[1]."Reference Type No.", 1, MaxStrLen(PurchaseLine."Buy-from Vendor No.")),
          ItemRefNo);

        // [WHEN] Run ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = FALSE
        ItemReferenceMgt.ReferenceLookupPurchaseItem(PurchaseLine, ItemReference[2], false);

        // [THEN] ICRLookupPurchaseItem returns Item Reference with Item No = 1000
        ItemReference[2].TestField("Item No.", ItemReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenDifferentVendorsDifferentItemsShowDialogFalse()
    var
        ItemReference: array[2] of Record "Item Reference";
        PurchaseLine: Record "Purchase Line";
        ItemRefNo: Code[50];
        Index: Integer;
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO 289240] Vendors: A,B, Items X,Y, Item References AX and BY
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is No
        // [SCENARIO 289240] ICRLookupPurchaseItem returns Reference for Vendor A (AX)
        Initialize();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Item Reference for Item 1000 with No = 1234, Type = Vendor, Type No = 10000
        // [GIVEN] Item Reference for Item 1001 with No = 1234, Type = Vendor, Type No = 20000
        for Index := 1 to ArrayLen(ItemReference) do
            LibraryItemReference.CreateItemReferenceWithNo(ItemReference[Index], ItemRefNo, LibraryInventory.CreateItemNo(),
              ItemReference[Index]."Reference Type"::Vendor, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(
          PurchaseLine, CopyStr(ItemReference[1]."Reference Type No.", 1, MaxStrLen(PurchaseLine."Buy-from Vendor No.")),
          ItemRefNo);

        // [WHEN] Run ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = FALSE
        ItemReferenceMgt.ReferenceLookupPurchaseItem(PurchaseLine, ItemReference[2], false);

        // [THEN] ICRLookupPurchaseItem returns Item Reference with Item No = 1000
        ItemReference[2].TestField("Item No.", ItemReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenOtherVendorAndBarCodeShowDialogFalse()
    var
        ItemReference: array[2] of Record "Item Reference";
        PurchaseLine: Record "Purchase Line";
        ItemRefNo: Code[50];
    begin
        // [FEATURE] [Intercompany] [Bar Code]
        // [SCENARIO 289240] Vendor B, Items X,Y Vendor Reference BX, Bar Code Reference PY
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is No
        // [SCENARIO 289240] ICRLookupPurchaseItem returns Reference PY
        Initialize();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Item Reference for Item 1000 with No = 1234, Type = Vendor and Type No = 20000
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[1], ItemRefNo, LibraryInventory.CreateItemNo(),
          ItemReference[1]."Reference Type"::Vendor, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Item Item References for Item 1001 with same No and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[2], ItemRefNo, ItemReference[1]."Item No.",
          ItemReference[2]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID());

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, LibraryPurchase.CreateVendorNo(), ItemRefNo);

        // [WHEN] Ran ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = FALSE
        ItemReferenceMgt.ReferenceLookupPurchaseItem(PurchaseLine, ItemReference[1], false);

        // [THEN] ICRLookupPurchaseItem returns Item Reference with Item No = 1001
        ItemReference[1].TestField("Item No.", ItemReference[2]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenOtherVendorShowDialogFalse()
    var
        ItemReference: Record "Item Reference";
        PurchaseLine: Record "Purchase Line";
        ItemRefNo: Code[50];
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO 289240] Vendor B, Reference BX
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is No
        // [SCENARIO 289240] ICRLookupPurchaseItem throws error
        Initialize();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference.FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Item Reference for Item with No = 1234, Type = Vendor and Type No = 20000
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference, ItemRefNo, LibraryInventory.CreateItemNo(),
          ItemReference."Reference Type"::Vendor, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, LibraryPurchase.CreateVendorNo(), ItemRefNo);

        // [WHEN] Run ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = FALSE
        asserterror ItemReferenceMgt.ReferenceLookupPurchaseItem(PurchaseLine, ItemReference, false);

        // [THEN] Error "There are no items with cross reference: 1234"
        Assert.ExpectedError(StrSubstNo(ItemRefNotExistsErr, ItemRefNo));
        Assert.ExpectedErrorCode(DialogCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenOtherMultipleVendorsShowDialogFalse()
    var
        ItemReference: Record "Item Reference";
        PurchaseLine: Record "Purchase Line";
        ItemRefNo: Code[50];
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO 289240] Vendors: B,C Item References BX,CY
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is No
        // [SCENARIO 289240] ICRLookupPurchaseItem throws error
        Initialize();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference.FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Two Item Item References with same No = 1234, same Type = Vendor and Type No 20000 and 30000
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference, ItemRefNo, LibraryInventory.CreateItemNo(),
          ItemReference."Reference Type"::Vendor, LibraryPurchase.CreateVendorNo());
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference, ItemRefNo, LibraryInventory.CreateItemNo(),
          ItemReference."Reference Type"::Vendor, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, LibraryPurchase.CreateVendorNo(), ItemRefNo);

        // [WHEN] Run ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = FALSE
        asserterror ItemReferenceMgt.ReferenceLookupPurchaseItem(PurchaseLine, ItemReference, false);

        // [THEN] Error "There are no items with cross reference: 1234"
        Assert.ExpectedError(StrSubstNo(ItemRefNotExistsErr, ItemRefNo));
        Assert.ExpectedErrorCode(DialogCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenOneVendorShowDialogFalse()
    var
        ItemReference: Record "Item Reference";
        PurchaseLine: Record "Purchase Line";
        ItemRefNo: Code[50];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO 289240] Vendor A, Reference AX
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is No
        // [SCENARIO 289240] ICRLookupPurchaseItem Returns Reference AX
        Initialize();
        ItemNo := LibraryInventory.CreateItemNo();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference.FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Item Reference for Item 1000 with No = 1234, Type = Vendor and Type No = 10000
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference, ItemRefNo, ItemNo,
          ItemReference."Reference Type"::Vendor, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(
          PurchaseLine, CopyStr(ItemReference."Reference Type No.", 1, MaxStrLen(PurchaseLine."Buy-from Vendor No.")),
          ItemRefNo);

        // [WHEN] Run ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = FALSE
        ItemReferenceMgt.ReferenceLookupPurchaseItem(PurchaseLine, ItemReference, false);

        // [THEN] ICRLookupPurchaseItem returns Item Reference with Item No = 1000
        ItemReference.TestField("Item No.", ItemNo)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenNoItemRefShowDialogFalse()
    var
        DummyItemReference: Record "Item Reference";
        PurchaseLine: Record "Purchase Line";
        ItemRefNo: Code[50];
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO 289240] No Item References with No = 1234
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A with Item Reference No = 1234 and ShowDialog is No
        // [SCENARIO 289240] ICRLookupPurchaseItem Returns Reference AX
        Initialize();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(DummyItemReference.FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(
          PurchaseLine, LibraryPurchase.CreateVendorNo(), ItemRefNo);

        // [WHEN] Run ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = FALSE
        asserterror ItemReferenceMgt.ReferenceLookupPurchaseItem(PurchaseLine, DummyItemReference, false);

        // [THEN] Error "There are no items with cross reference: 1234"
        Assert.ExpectedError(StrSubstNo(ItemRefNotExistsErr, ItemRefNo));
        Assert.ExpectedErrorCode(DialogCodeErr);
    end;

    [Test]
    [HandlerFunctions('ItemReferenceListCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenStanCancelsItemReferenceList()
    var
        ItemReference: array[2] of Record "Item Reference";
        PurchaseLine: Record "Purchase Line";
        VendorNo: array[2] of Code[20];
        ItemRefNo: Code[50];
        Index: Integer;
        ItemIndex: Integer;
        ItemNo: array[2] of Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 289240] ICRLookupPurchaseItem for Vendor A and ShowDialog is Yes
        // [SCENARIO 289240] Page Item Reference List opened with Item References
        // [SCENARIO 289240] When Stan pushes cancel on page, then error
        Initialize();
        for ItemIndex := 1 to ArrayLen(ItemNo) do begin
            ItemNo[ItemIndex] := LibraryInventory.CreateItemNo();
            VendorNo[ItemIndex] := LibraryPurchase.CreateVendorNo();
        end;
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Two Item Item References for Item 1000 with No = 1234, Type = Vendor and Type No = 10000 and 20000
        // [GIVEN] Two similar Item Item References for Item 1001
        for ItemIndex := 1 to ArrayLen(ItemNo) do
            for Index := 1 to ArrayLen(ItemReference) do
                LibraryItemReference.CreateItemReferenceWithNo(ItemReference[Index], ItemRefNo, ItemNo[ItemIndex],
                  ItemReference[Index]."Reference Type"::Vendor, VendorNo[Index]);

        // [GIVEN] Item Reference for Item 1100 with No = 1234, Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNo(
          ItemReference[2], ItemRefNo, LibraryInventory.CreateItemNo(), ItemReference[2]."Reference Type"::"Bar Code",
          LibraryUtility.GenerateGUID());

        // [GIVEN] Purchase Line had Type = Item, "Buy-from Vendor No." = 10000 and Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, VendorNo[1], ItemRefNo);

        // [GIVEN] Ran ICRLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = TRUE
        asserterror ItemReferenceMgt.ReferenceLookupPurchaseItem(PurchaseLine, ItemReference[1], true);

        // [GIVEN] Page Item Reference List opened

        // [WHEN] Stan pushes Cancel on page Item Reference List
        // Done in ItemReferenceListCancelModalPageHandler

        // [THEN] Error "There are no items with cross reference: 1234"
        Assert.ExpectedError(StrSubstNo(ItemRefNotExistsErr, ItemRefNo));
        Assert.ExpectedErrorCode(DialogCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeItemVendorLeadCalcTime()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemVendor: Record "Item Vendor";
        ItemReference: Record "Item Reference";
        SavedItemReferenceDescription: Text[100];
    begin
        // [SCENARIO 292774] Description should not be cleared in item cross refference when updating Lead Time Calculation of related Item Vendor record
        Initialize();

        // [GIVEN] Item Reference of "Vendor" type with Item No. "ITEM", Vendor No. "VEND", Variant Code "VARIANT" and description "DESCR"
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        CreateItemReference(
          ItemReference, Item."No.", ItemVariant.Code,
          ItemReference."Reference Type"::Vendor, LibraryPurchase.CreateVendorNo());
        SavedItemReferenceDescription := ItemReference.Description;

        // [WHEN] "Lead Time Calculation" field of Item Vendor record "VEND", "ITEM", "VARIANT" is being updated
        ItemVendor.Get(ItemReference."Reference Type No.", Item."No.", ItemVariant.Code);
        Evaluate(ItemVendor."Lead Time Calculation", '<1D>');
        ItemVendor.Modify(true);

        // [THEN] Item Reference description is not changed
        ItemReference.Find();
        ItemReference.TestField(Description, SavedItemReferenceDescription);
    end;

    [Test]
    [HandlerFunctions('ItemReferenceListModalPageHandler')]
    [Scope('OnPrem')]
    procedure PurchLineLookupItemRefNoWhenSameVendorDifferentItems()
    var
        ItemReference: array[2] of Record "Item Reference";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
        ItemRefNo: Code[50];
        Index: Integer;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 289240] Vendor A, Items: X,Y Item References AX and AY
        // [SCENARIO 289240] Stan looks up Reference No in Purchase Line and selects Reference AY
        // [SCENARIO 289240] Purchase Line has Item Y
        Initialize();
        VendorNo := LibraryPurchase.CreateVendorNo();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");
        LibraryVariableStorage.Enqueue(ItemRefNo);

        // [GIVEN] Item Item References for Items 1000 and 1001 with same No = 1234, Type = Vendor and Type No = 10000
        for Index := 1 to ArrayLen(ItemReference) do begin
            LibraryItemReference.CreateItemReferenceWithNo(ItemReference[Index], ItemRefNo, LibraryInventory.CreateItemNo(),
              ItemReference[Index]."Reference Type"::Vendor, VendorNo);
            EnqueueItemReferenceFields(ItemReference[Index]);
        end;

        // [GIVEN] Purchase Invoice with "Buy-from Vendor No." = 10000 and Purchase Line had Type = Item
        CreatePurchaseInvoiceOneLineWithLineTypeItem(PurchaseLine, VendorNo);

        // [GIVEN] Stan Looked up Item Reference No in Purchase Line
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        ItemReferenceMgt.PurchaseReferenceNoLookup(PurchaseLine, PurchaseHeader);

        // [GIVEN] Page Item Reference List opened showing both Item References, first for Item 1000, second for Item 1001
        // [GIVEN] Stan selected the second one
        // Done in ItemReferenceListModalPageHandler

        // [WHEN] Push OK on page Item Reference List
        // Done in ItemReferenceListModalPageHandler

        // [THEN] Purchase Line has No = 1001
        PurchaseLine.TestField("No.", ItemReference[2]."Item No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectCreatingItemReferenceFromItemVendorCatalog()
    var
        ItemReference: Record "Item Reference";
        ItemVariant: Record "Item Variant";
        ItemVendorCatalog: TestPage "Item Vendor Catalog";
        ItemNo: Code[20];
        VendorNo: Code[20];
        ItemVendorNo: Code[10];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 402797] Only one "Item Reference" must be created by "Item Vendor Catalog" when user set "Variant Code" after "Item Vendor"
        Initialize();

        // [GIVEN] Item, Vendor, "Item Variant"
        ItemNo := LibraryInventory.CreateItemNo();
        VendorNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Create new "Item Vendor" by "Item Vendor Catalog"
        ItemVendorCatalog.OpenNew();
        ItemVendorCatalog.Filter.SetFilter("Item No.", ItemNo);
        ItemVendorCatalog."Vendor No.".SetValue(VendorNo);
        ItemVendorNo := LibraryUtility.GenerateGUID();
        ItemVendorCatalog."Vendor Item No.".SetValue(ItemVendorNo);

        // [WHEN] Set "Variant Code" after "Vendor Item No."
        ItemVendorCatalog."Variant Code".SetValue(LibraryInventory.CreateItemVariant(ItemVariant, ItemNo));
        ItemVendorCatalog.Next();

        // [THEN] "Item Reference" for Item and Vendor is only one
        ItemReference.SetRange("Item No.", ItemNo);
        ItemReference.SetRange("Reference Type", ItemReference."Reference Type"::Vendor);
        ItemReference.SetRange("Reference Type No.", VendorNo);
        ItemReference.FindFirst();
        ItemReference.TestField("Reference No.", ItemVendorNo);
        Assert.RecordCount(ItemReference, 1);
    end;

    [Test]
    [HandlerFunctions('ItemReferenceListModalPageHandler')]
    [Scope('OnPrem')]
    procedure ICRLookupPurchaseItemWhenSameVendorForSameItemDifferentVariants()
    var
        ItemReference: array[2] of Record "Item Reference";
        PurchaseLine: Record "Purchase Line";
        ItemVariant: Record "Item Variant";
        VendNo: Code[20];
        ItemRefNo: Code[50];
        Index: Integer;
        ItemNo: Code[20];
        VariantCode: array[2] of Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 289240] Vendor: V Item: I, Variants: A,B Item References: IA, IB
        // [SCENARIO 289240] Page Item Reference List allow to select variant B
        Initialize();
        ItemNo := LibraryInventory.CreateItemNo();
        VendNo := LibraryPurchase.CreateVendorNo();
        VariantCode[1] := LibraryInventory.CreateItemVariant(ItemVariant, ItemNo);
        VariantCode[2] := LibraryInventory.CreateItemVariant(ItemVariant, ItemNo);
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");
        LibraryVariableStorage.Enqueue(ItemRefNo);

        // [GIVEN] Two Item References for Item 1000 with No = 1234, Variant = A,B
        for Index := 1 to ArrayLen(VariantCode) do begin
            LibraryItemReference.CreateItemReference(
              ItemReference[Index], ItemNo, VariantCode[Index], '', "Item Reference Type"::Vendor, VendNo, ItemRefNo);
            EnqueueItemReferenceFields(ItemReference[Index]);
        end;

        // [GIVEN] Purchase Line had Type = Item, "Bill-to Customer No." = 10000 and Reference No. = 1234
        MockPurchaseLineForICRLookupPurchaseItem(PurchaseLine, VendNo, ItemRefNo);

        // [GIVEN] Ran ICRLookupPurchaseItem for the Purchase Line with ShowDialog = TRUE
        ItemReferenceMgt.ReferenceLookupPurchaseItem(PurchaseLine, ItemReference[1], true);

        // [GIVEN] Stan selected the second one
        // Done in ItemReferenceListModalPageHandler

        // [WHEN] Push OK on page Item Reference List
        // Done in ItemReferenceListModalPageHandler

        // [THEN] ICRLookupSalesItem returns Item Reference with Variant Code = B
        ItemReference[1].TestField("Item No.", ItemReference[2]."Item No.");
        ItemReference[1].TestField("Variant Code", ItemReference[2]."Variant Code");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateVendorItemNoFromItemVendorCatalog()
    var
        ItemReference: Record "Item Reference";
        ItemVendorCatalog: TestPage "Item Vendor Catalog";
        ItemNo: Code[20];
        VendorNo: Code[20];
        ItemVendorNo: Code[10];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 428994] User can update "Vendor Item No." from Item Vendor Catalog page
        Initialize();

        // [GIVEN] Item, Vendor, "Item Variant"
        ItemNo := LibraryInventory.CreateItemNo();
        VendorNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Create new "Item Vendor" by "Item Vendor Catalog"
        ItemVendorCatalog.OpenNew();
        ItemVendorCatalog.Filter.SetFilter("Item No.", ItemNo);
        ItemVendorCatalog."Vendor No.".SetValue(VendorNo);
        ItemVendorNo := LibraryUtility.GenerateGUID();
        // [GIVEN] Specify "Vendor Item No."
        ItemVendorCatalog."Vendor Item No.".SetValue(ItemVendorNo);

        // [WHEN] Move to the next record
        ItemVendorCatalog.Next();

        // [THEN] "Item Reference" for Item and Vendor is only one
        ItemReference.SetRange("Item No.", ItemNo);
        ItemReference.SetRange("Reference Type", ItemReference."Reference Type"::Vendor);
        ItemReference.SetRange("Reference Type No.", VendorNo);
        ItemReference.FindFirst();
        ItemReference.TestField("Reference No.", ItemVendorNo);
        Assert.RecordCount(ItemReference, 1);
    end;

    [Test]
    [HandlerFunctions('ItemReferenceListModalPageHandler')]
    procedure VerifyLocationCodeOnPurchaseLineOnLookupItemReferenceAfterLocationCodeIsUpdatedOnPurchHeader()
    var
        Item: Record Item;
        ItemReference: Record "Item Reference";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: array[2] of Record Location;
        ItemRefNo: Code[50];
    begin
        // [SCENARIO 474114] Verify Location Code on Purchase Line on Lookup Item Reference after Location Code is updated on Purch. Header
        Initialize();

        // [GIVEN] Create Item
        LibraryInventory.CreateItem(Item);

        ItemRefNo := LibraryUtility.GenerateRandomCode(ItemReference.FieldNo("Reference No."), Database::"Item Reference");
        LibraryVariableStorage.Enqueue(ItemRefNo);

        // [GIVEN] Create Locations
        LibraryWarehouse.CreateLocation(Location[1]);
        LibraryWarehouse.CreateLocation(Location[2]);

        // [GIVEN] Create Vendor with Location Code
        LibraryPurchase.CreateVendorWithLocationCode(Vendor, Location[1].Code);

        // [GIVEN] Add Item Reference to Vendor
        LibraryItemReference.CreateItemReference(ItemReference, Item."No.", '', Item."Base Unit of Measure", "Item Reference Type"::Vendor, Vendor."No.", ItemRefNo);
        EnqueueItemReferenceFields(ItemReference);

        // [GIVEN] Create Purchase Header
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");

        // [GIVEN] Update Location Code on Purchase Header
        PurchaseHeader.Validate("Location Code", Location[2].Code);
        PurchaseHeader.Modify();

        // [GIVEN] Create Purchase Line
        LibraryPurchase.CreatePurchaseLineSimple(PurchaseLine, PurchaseHeader);
        PurchaseLine.Validate(Type, PurchaseLine.Type::Item);
        PurchaseLine.Modify(true);

        // [WHEN] Stan Looked up Item Reference No in Purchase Line
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        ItemReferenceMgt.PurchaseReferenceNoLookup(PurchaseLine, PurchaseHeader);

        // [THEN] Verify Location Code on Purchase Line
        Assert.AreEqual(PurchaseLine."Location Code", Location[2].Code, '');
    end;

    [Test]
    procedure ICRLookupPurchaseItemWhenBarCodeAndExpiredBarCodeShowDialogTrue()
    var
        ItemReference: array[2] of Record "Item Reference";
        ReturnedItemReference: Record "Item Reference";
        PurchaseLine: Record "Purchase Line";
        ItemReferenceNo: Code[50];
    begin
        Initialize();

        // [GIVEN] Barcode for multiple item references
        ItemReferenceNo := LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), Database::"Item Reference");

        // [GIVEN] Purchase Order with empty Line with Type = Item and with the item reference
        CreatePurchaseInvoiceOneLineWithLineTypeItem(PurchaseLine, LibraryPurchase.CreateVendorNo());
        PurchaseLine."Item Reference No." := ItemReferenceNo;
        PurchaseLine.Modify();

        // [GIVEN] Item References for Item X and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNoAndDates(ItemReference[1], ItemReferenceNo, LibraryInventory.CreateItemNo(),
          ItemReference[1]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID(),
           CalcDate('<-1M>', PurchaseLine.GetDateForCalculations()), CalcDate('<-1D>', PurchaseLine.GetDateForCalculations()));

        // [GIVEN] Item References for Item Y and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[2], ItemReferenceNo, LibraryInventory.CreateItemNo(),
          ItemReference[2]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID());

        // [WHEN] Ran ReferenceLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = TRUE
        ItemReferenceMgt.ReferenceLookupPurchaseItem(PurchaseLine, ReturnedItemReference, true);

        // [THEN] Item Reference with Item No = X is ignored
        // [THEN] ReferenceLookupPurchaseItem returns Item Reference with Item No = Y
        ReturnedItemReference.TestField("Item No.", ItemReference[2]."Item No.");
    end;

    [Test]
    [HandlerFunctions('ItemReferenceListModalPageHandler')]
    procedure ICRLookupPurchaseItemWhenBarCodeAndBarCodeDateLimitedShowDialogTrue()
    var
        ItemReference: array[2] of Record "Item Reference";
        ReturnedItemReference: Record "Item Reference";
        PurchaseLine: Record "Purchase Line";
        ItemReferenceNo: Code[50];
    begin
        Initialize();

        // [GIVEN] Barcode for multiple item references
        ItemReferenceNo := LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), Database::"Item Reference");
        LibraryVariableStorage.Enqueue(ItemReferenceNo);

        // [GIVEN] Purchase Order with empty Line with Type = Item and with the item reference
        CreatePurchaseInvoiceOneLineWithLineTypeItem(PurchaseLine, LibraryPurchase.CreateVendorNo());
        PurchaseLine."Item Reference No." := ItemReferenceNo;
        PurchaseLine.Modify();

        // [GIVEN] Item References for Item X and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNoAndDates(ItemReference[1], ItemReferenceNo, LibraryInventory.CreateItemNo(),
          ItemReference[1]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID(),
           CalcDate('<-1M>', PurchaseLine.GetDateForCalculations()), CalcDate('<+1M>', PurchaseLine.GetDateForCalculations()));
        EnqueueItemReferenceFields(ItemReference[1]);

        // [GIVEN] Item References for Item Y and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[2], ItemReferenceNo, LibraryInventory.CreateItemNo(),
          ItemReference[2]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID());
        EnqueueItemReferenceFields(ItemReference[2]);

        // [WHEN] Ran ReferenceLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = TRUE
        ItemReferenceMgt.ReferenceLookupPurchaseItem(PurchaseLine, ReturnedItemReference, true);

        // [GIVEN] Page Item Reference List opened showing both Item References
        // [GIVEN] User selected the second one
        // Done in ItemReferenceListModalPageHandler

        // [THEN] ReferenceLookupPurchaseItem returns Item Reference with Item No = Y
        ReturnedItemReference.TestField("Item No.", ItemReference[2]."Item No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure ICRLookupPurchaseItemWhenTwoExpiredBarCodesShowDialogTrue()
    var
        ItemReference: array[2] of Record "Item Reference";
        ReturnedItemReference: Record "Item Reference";
        PurchaseLine: Record "Purchase Line";
        ItemReferenceNo: Code[50];
    begin
        Initialize();

        // [GIVEN] Barcode for multiple item references
        ItemReferenceNo := LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), Database::"Item Reference");

        // [GIVEN] Purchase Order with empty Line with Type = Item and with the item reference
        CreatePurchaseInvoiceOneLineWithLineTypeItem(PurchaseLine, LibraryPurchase.CreateVendorNo());
        PurchaseLine."Item Reference No." := ItemReferenceNo;
        PurchaseLine.Modify();

        // [GIVEN] Item References for Item X and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNoAndDates(ItemReference[1], ItemReferenceNo, LibraryInventory.CreateItemNo(),
          ItemReference[1]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID(),
           CalcDate('<-1M>', PurchaseLine.GetDateForCalculations()), CalcDate('<-1D>', PurchaseLine.GetDateForCalculations()));

        // [GIVEN] Item References for Item Y and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNoAndDates(ItemReference[2], ItemReferenceNo, LibraryInventory.CreateItemNo(),
          ItemReference[2]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID(),
           CalcDate('<+1D>', PurchaseLine.GetDateForCalculations()), CalcDate('<+1M>', PurchaseLine.GetDateForCalculations()));

        // [WHEN] Ran ReferenceLookupPurchaseItem from codeunit Dist. Integration for the Purchase Line with ShowDialog = TRUE
        asserterror ItemReferenceMgt.ReferenceLookupPurchaseItem(PurchaseLine, ReturnedItemReference, true);

        // [THEN] Error "There are no items with reference %1."
        Assert.ExpectedError(StrSubstNo(ItemRefNotExistsErr, ItemReferenceNo));
    end;

    [Test]
    procedure VerifyDescriptionInPurchaseLineWhenBothItemReferenceAndItemVariantAreUsed()
    var
        Item: array[2] of Record Item;
        ItemReference: array[2] of Record "Item Reference";
        ItemVariant: array[2] of Record "Item Variant";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        VendorNo: Code[20];
    begin
        // [SCENARIO 574832] Verify that the item description in the purchase line is prioritized correctly when both Item Reference and Item Variant are used. 
        Initialize();

        // [GIVEN] Create a new Vendor.
        VendorNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Create first Item with Item Variant and Item Reference.
        CreateItemWithItemVariantAndItemReference(Item[1], ItemVariant[1], ItemReference[1], VendorNo);

        // [GIVEN] Set description value in first Item Reference.
        if ItemReference[1].Description = '' then begin
            ItemReference[1].Validate(Description, ItemReference[1]."Reference No.");
            ItemReference[1].Modify(true);
        end;

        // [GIVEN] Create second Item with Item Variant and Item Reference.
        CreateItemWithItemVariantAndItemReference(Item[2], ItemVariant[2], ItemReference[2], VendorNo);

        // [GIVEN] Create Purchase Header with document type Invoice.
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);

        // [GIVEN] Create Two Purchase Lines.
        CreatePurchaseLine(PurchaseLine[1], PurchaseHeader, Item[1]."No.");
        CreatePurchaseLine(PurchaseLine[2], PurchaseHeader, Item[2]."No.");

        // [WHEN] Both Item Variant and Item Reference have description values and their values are set in the Purchase line.
        ModifyPurchaseLine(PurchaseLine[1], ItemVariant[1].Code, ItemReference[1]."Reference No.");

        // [THEN] Ensure that the Purchase Line description is the same as the Item Reference description.
        Assert.AreEqual(PurchaseLine[1].Description, ItemReference[1].Description, DescriptionMustBeSameErr);

        // [WHEN] Both Item Variant and Item Reference have description values, but only the Item Variant value is set in the Purchase line.
        ModifyPurchaseLine(PurchaseLine[1], ItemVariant[1].Code, '');

        // [THEN] Ensure that the Purchase Line description is the same as the Item Variant description.
        Assert.AreEqual(PurchaseLine[1].Description, ItemVariant[1].Description, DescriptionMustBeSameErr);

        // [WHEN] Both Item Variant and Item Reference have description values, but both values are set blank in the Purchase line.
        ModifyPurchaseLine(PurchaseLine[1], '', '');

        // [THEN] Ensure that the Purchase Line description is the same as the Item description.
        Assert.AreEqual(PurchaseLine[1].Description, Item[1].Description, DescriptionMustBeSameErr);

        // [WHEN] Item Variant has a description value, but Item Reference has a blank description. However, both values are set in the Purchase line.
        ModifyPurchaseLine(PurchaseLine[2], ItemVariant[2].Code, ItemReference[2]."Reference No.");

        // [THEN] Ensure that the Purchase Line description is the same as the Item Variant description.
        Assert.AreEqual(PurchaseLine[2].Description, ItemVariant[2].Description, DescriptionMustBeSameErr);

        // [WHEN] Item Variant and Item Reference values are set blank in the Purchase line.
        ModifyPurchaseLine(PurchaseLine[2], '', '');

        // [THEN] Ensure that the Purchase Line description is the same as the Item description.
        Assert.AreEqual(PurchaseLine[2].Description, Item[2].Description, DescriptionMustBeSameErr);
    end;

    [Test]
    procedure VerifyDescriptionInPurchaseLineWhenItemReferenceAndItemVariantAndItemTranslationUsed()
    var
        Item: array[2] of Record Item;
        ItemReference: array[2] of Record "Item Reference";
        ItemTranslation: array[2] of Record "Item Translation";
        ItemVariant: array[2] of Record "Item Variant";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        Vendor: Record Vendor;
        LanguageCode: Code[10];
    begin
        // [SCENARIO 574832] Verify that the Item description in the purchase line is prioritized correctly when Item Reference,Item Variant and Item Translation are used. 
        Initialize();

        // [GIVEN] Create a new Vendor ansd set Languague code.
        LanguageCode := LibraryERM.GetAnyLanguageDifferentFromCurrent();
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Language Code", LanguageCode);
        Vendor.Modify(true);

        // [GIVEN] Create first Item with Item Variant and Item Reference.
        CreateItemWithItemVariantAndItemReference(Item[1], ItemVariant[1], ItemReference[1], Vendor."No.");

        // [GIVEN] Set description value in first Item Reference.
        if ItemReference[1].Description = '' then begin
            ItemReference[1].Validate(Description, ItemReference[1]."Reference No.");
            ItemReference[1].Modify(true);
        end;

        // [GIVEN] Create second Item with Item Variant and Item Reference.
        CreateItemWithItemVariantAndItemReference(Item[2], ItemVariant[2], ItemReference[2], Vendor."No.");

        // [GIVEN] Create Multiple Item Translation.
        CreateItemTranslation(ItemTranslation[1], Item[1]."No.", LanguageCode, ItemVariant[1].Code);
        CreateItemTranslation(ItemTranslation[2], Item[2]."No.", LanguageCode, ItemVariant[2].Code);

        // [GIVEN] Create Purchase Header with document type Invoice.
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");

        // [GIVEN] Create Two Purchase Lines.
        CreatePurchaseLine(PurchaseLine[1], PurchaseHeader, Item[1]."No.");
        CreatePurchaseLine(PurchaseLine[2], PurchaseHeader, Item[2]."No.");

        // [WHEN] Both Item Variant and Item Reference have description values and their values are set in the Purchase line.
        ModifyPurchaseLine(PurchaseLine[1], ItemVariant[1].Code, ItemReference[1]."Reference No.");

        // [THEN] Ensure that the Purchase Line description is the same as the Item Reference description.
        Assert.AreEqual(PurchaseLine[1].Description, ItemReference[1].Description, DescriptionMustBeSameErr);

        // [WHEN] Both Item Variant and Item Reference have description values, but only the Item Variant value is set in the Purchase line.
        ModifyPurchaseLine(PurchaseLine[1], ItemVariant[1].Code, '');

        // [THEN] Ensure that the Purchase Line description is the same as the Item Translation description.
        Assert.AreEqual(PurchaseLine[1].Description, ItemTranslation[1].Description, DescriptionMustBeSameErr);

        // [WHEN] Both Item Variant and Item Reference have description values, but both values are set blank in the Purchase line.
        ModifyPurchaseLine(PurchaseLine[1], '', '');

        // [THEN] Ensure that the Purchase Line description is the same as the Item description.
        Assert.AreEqual(PurchaseLine[1].Description, Item[1].Description, DescriptionMustBeSameErr);

        // [WHEN] Item Variant has a description value, but Item Reference has a blank description. However, both values are set in the Purchase line.
        ModifyPurchaseLine(PurchaseLine[2], ItemVariant[2].Code, ItemReference[2]."Reference No.");

        // [THEN] Ensure that the Purchase Line description is the same as the Item Translation description.
        Assert.AreEqual(PurchaseLine[2].Description, ItemTranslation[2].Description, DescriptionMustBeSameErr);

        // [WHEN] Item Variant and Item Reference values are set blank in the Purchase line.
        ModifyPurchaseLine(PurchaseLine[2], '', '');

        // [THEN] Ensure that the Purchase Line description is the same as the Item description.
        Assert.AreEqual(PurchaseLine[2].Description, Item[2].Description, DescriptionMustBeSameErr);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ERM Item Reference Purchase");

        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ERM Item Reference Purchase");
        Commit();
        IsInitialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ERM Item Reference Purchase");
    end;

    local procedure CreateItemReference(var ItemReference: Record "Item Reference"; ItemNo: Code[20]; ItemVariantNo: Code[10]; ReferenceType: Enum "Item Reference Type"; ReferenceTypeNo: Code[30])
    begin
        ItemReference.Init();
        ItemReference.Validate("Item No.", ItemNo);
        ItemReference.Validate("Variant Code", ItemVariantNo);
        ItemReference.Validate("Reference Type", ReferenceType);
        ItemReference.Validate("Reference Type No.", ReferenceTypeNo);
        ItemReference.Validate(
          "Reference No.",
          LibraryUtility.GenerateRandomCode(ItemReference.FieldNo("Reference No."), DATABASE::"Item Reference"));
        ItemReference.Validate(Description, ReferenceTypeNo);
        ItemReference.Insert(true);
    end;

    local procedure MockPurchaseLineForICRLookupPurchaseItem(var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20]; ItemRefNo: Code[50])
    begin
        PurchaseLine.Init();
        PurchaseLine.Type := PurchaseLine.Type::Item;
        PurchaseLine."Buy-from Vendor No." := VendorNo;
        PurchaseLine."Item Reference No." := ItemRefNo;
    end;

    local procedure CreatePurchaseInvoiceOneLineWithLineTypeItem(var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        LibraryPurchase.CreatePurchaseLineSimple(PurchaseLine, PurchaseHeader);
        PurchaseLine.Validate(Type, PurchaseLine.Type::Item);
        PurchaseLine.Modify(true);
    end;

    local procedure EnqueueItemReferenceFields(ItemReference: Record "Item Reference")
    begin
        LibraryVariableStorage.Enqueue(ItemReference."Reference Type");
        LibraryVariableStorage.Enqueue(ItemReference."Reference Type No.");
        LibraryVariableStorage.Enqueue(ItemReference."Item No.");
    end;

    local procedure CreateItemWithItemVariantAndItemReference(var Item: Record Item; var ItemVariant: Record "Item Variant"; var ItemReference: Record "Item Reference"; VendorNo: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate(Description, Item."No.");
        Item.Modify(true);

        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        LibraryItemReference.CreateItemReference(ItemReference, Item."No.", ItemVariant.Code, '', "Item Reference Type"::Vendor, VendorNo, LibraryUtility.GenerateRandomCode(ItemReference.FieldNo("Reference No."), Database::"Item Reference"));
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20])
    begin
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandIntInRange(1, 10));
    end;

    local procedure ModifyPurchaseLine(var PurchaseLine: Record "Purchase Line"; VariantCode: Code[20]; ItemReferenceNo: Code[50])
    begin
        PurchaseLine.Validate("Variant Code", VariantCode);
        PurchaseLine.Validate("Item Reference No.", ItemReferenceNo);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateItemTranslation(var ItemTranslation: Record "Item Translation"; ItemNo: Code[20]; LanguageCode: Code[10]; VariantCode: Code[10])
    begin
        ItemTranslation.Init();
        ItemTranslation.Validate("Item No.", ItemNo);
        ItemTranslation.Validate("Language Code", LanguageCode);
        ItemTranslation.Validate("Variant Code", VariantCode);
        ItemTranslation.Validate(Description, LibraryUtility.GenerateGUID());
        ItemTranslation.Validate("Description 2", LibraryUtility.GenerateGUID());
        ItemTranslation.Insert(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
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

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemReferenceListCancelModalPageHandler(var ItemReferenceList: TestPage "Item Reference List")
    begin
        ItemReferenceList.Cancel().Invoke();
    end;

}

