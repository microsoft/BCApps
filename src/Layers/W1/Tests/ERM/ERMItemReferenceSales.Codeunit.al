codeunit 134463 "ERM Item Reference Sales"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Item Reference] [Reference No] [Sales]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemReference: Codeunit "Library - Item Reference";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        ItemRefNotExistsErr: Label 'There are no items with reference %1.';
        DialogCodeErr: Label 'Dialog';
        ItemReferenceMgt: Codeunit "Item Reference Management";
        DescriptionMustBeSameErr: Label 'Description must be same.';
        isInitialized: Boolean;

    [Test]
    [HandlerFunctions('ItemReferenceListModalPageHandler')]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenSameCustomersForSameItemsAndBarCodeShowDialogTrue()
    var
        ItemReference: array[2] of Record "Item Reference";
        SalesLine: Record "Sales Line";
        CustNo: array[2] of Code[20];
        ItemRefNo: Code[50];
        Index: Integer;
        ItemIndex: Integer;
        ItemNo: array[2] of Code[20];
    begin
        // [FEATURE] [UI] [Bar Code]
        // [SCENARIO 289240] Customers: A,B, Items: X,Y,Z, Customer References: AX, AY, BX, BY and Bar Code Reference PZ
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is Yes
        // [SCENARIO 289240] Page Item Reference List shows only References for Customer A and Bar Code (AX, AY and PZ)
        Initialize();
        for ItemIndex := 1 to ArrayLen(ItemNo) do begin
            ItemNo[ItemIndex] := LibraryInventory.CreateItemNo();
            CustNo[ItemIndex] := LibrarySales.CreateCustomerNo();
        end;
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");
        LibraryVariableStorage.Enqueue(ItemRefNo);

        // [GIVEN] Two Item References for Item 1000 with No = 1234, Type = Customer and Type No = 10000 and 20000
        // [GIVEN] Two similar Item References for Item 1001
        for ItemIndex := 1 to ArrayLen(ItemNo) do begin
            for Index := 1 to ArrayLen(ItemReference) do
                LibraryItemReference.CreateItemReferenceWithNo(ItemReference[Index], ItemRefNo, ItemNo[ItemIndex],
                  ItemReference[Index]."Reference Type"::Customer, CustNo[Index]);
            EnqueueItemReferenceFields(ItemReference[1]);
        end;

        // [GIVEN] Item Reference for Item 1100 with No = 1234, Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[2], ItemRefNo, LibraryInventory.CreateItemNo(),
          ItemReference[2]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID());
        EnqueueItemReferenceFields(ItemReference[2]);

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, CustNo[1], ItemRefNo);

        // [GIVEN] Ran ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = TRUE
        ItemReferenceMgt.ReferenceLookupSalesItem(SalesLine, ItemReference[1], true);

        // [GIVEN] Page Item Reference List opened showing three Item References:
        // [GIVEN] Two with Type Customer and Type No = 10000 and last one with Type Bar Code, Stan selected the last one
        // Done in ItemReferenceListModalPageHandler

        // [WHEN] Push OK on page Item Reference List
        // Done in ItemReferenceListModalPageHandler

        // [THEN] ICRLookupSalesItem returns Item Reference with Item No = 1100
        ItemReference[1].TestField("Item No.", ItemReference[2]."Item No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemReferenceListModalPageHandler')]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenSameCustomersForSameItemsShowDialogTrue()
    var
        ItemReference: array[2] of Record "Item Reference";
        SalesLine: Record "Sales Line";
        CustNo: array[2] of Code[20];
        ItemRefNo: Code[50];
        Index: Integer;
        ItemIndex: Integer;
        ItemNo: array[2] of Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 289240] Customers: A,B, Items: X,Y, Item References: AX, AY, BX, BY
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is Yes
        // [SCENARIO 289240] Page Item Reference List shows only Item References for Customer A (AX and AY)
        Initialize();
        for ItemIndex := 1 to ArrayLen(ItemNo) do begin
            ItemNo[ItemIndex] := LibraryInventory.CreateItemNo();
            CustNo[ItemIndex] := LibrarySales.CreateCustomerNo();
        end;
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");
        LibraryVariableStorage.Enqueue(ItemRefNo);

        // [GIVEN] Two Item References for Item 1000 with No = 1234, Type = Customer and Type No = 10000 and 20000
        // [GIVEN] Two similar Item References for Item 1001
        for ItemIndex := 1 to ArrayLen(ItemNo) do begin
            for Index := 1 to ArrayLen(ItemReference) do
                LibraryItemReference.CreateItemReferenceWithNo(ItemReference[Index], ItemRefNo, ItemNo[ItemIndex],
                  ItemReference[Index]."Reference Type"::Customer, CustNo[Index]);
            EnqueueItemReferenceFields(ItemReference[1]);
        end;

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, CustNo[1], ItemRefNo);

        // [GIVEN] Ran ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = TRUE
        ItemReferenceMgt.ReferenceLookupSalesItem(SalesLine, ItemReference[1], true);

        // [GIVEN] Page Item Reference List opened showing two Item References with Type No = 10000: first for Item 1000, second for Item 1001
        // [GIVEN] Stan selected the second one
        // Done in ItemReferenceListModalPageHandler

        // [WHEN] Push OK on page Item Reference List
        // Done in ItemReferenceListModalPageHandler

        // [THEN] ICRLookupSalesItem returns Item Reference with Item No = 1001
        ItemReference[1].TestField("Item No.", ItemReference[2]."Item No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemReferenceListModalPageHandler')]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenCustomerAndBarCodeDifferentItemsShowDialogTrue()
    var
        ItemReference: array[2] of Record "Item Reference";
        SalesLine: Record "Sales Line";
        CustNo: Code[20];
        ItemRefNo: Code[50];
    begin
        // [FEATURE] [UI] [Bar Code]
        // [SCENARIO 289240] Customer A, Items: X,Y Customer Reference AX and Bar Code Reference PY
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is Yes
        // [SCENARIO 289240] Page Item Reference List shows both Item References (AX and PY)
        Initialize();
        CustNo := LibrarySales.CreateCustomerNo();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");
        LibraryVariableStorage.Enqueue(ItemRefNo);

        // [GIVEN] Item References for Item 1000 with No = 1234, Type = Customer and Type No = 10000
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[1], ItemRefNo, LibraryInventory.CreateItemNo(),
          ItemReference[1]."Reference Type"::Customer, CustNo);
        EnqueueItemReferenceFields(ItemReference[1]);

        // [GIVEN] Item References for Item 1001 with same No and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[2], ItemRefNo, LibraryInventory.CreateItemNo(),
          ItemReference[2]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID());
        EnqueueItemReferenceFields(ItemReference[2]);

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, CustNo, ItemRefNo);

        // [GIVEN] Ran ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = TRUE
        ItemReferenceMgt.ReferenceLookupSalesItem(SalesLine, ItemReference[1], true);

        // [GIVEN] Page Item Reference List opened showing both Item References: first for Item 1000, second for Item 1001
        // [GIVEN] Stan selected the second one
        // Done in ItemReferenceListModalPageHandler

        // [WHEN] Push OK on page Item Reference List
        // Done in ItemReferenceListModalPageHandler

        // [THEN] ICRLookupSalesItem returns Item Reference with Item No = 1001
        ItemReference[1].TestField("Item No.", ItemReference[2]."Item No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemReferenceListModalPageHandler')]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenCustomerAndBlankTypeDifferentItemsShowDialogTrue()
    var
        ItemReference: array[2] of Record "Item Reference";
        SalesLine: Record "Sales Line";
        CustNo: Code[20];
        ItemRefNo: Code[50];
    begin
        // [FEATURE] [UI] [Bar Code]
        // [SCENARIO 289240] Customer A, Items: X,Y Customer Reference AX and <blank> Type Reference TY
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is Yes
        // [SCENARIO 289240] Page Item Reference List shows both Item References (AX and TY)
        Initialize();
        CustNo := LibrarySales.CreateCustomerNo();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");
        LibraryVariableStorage.Enqueue(ItemRefNo);

        // [GIVEN] Item References for Item 1000 with No = 1234, Type = Customer and Type No = 10000
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[1], ItemRefNo, LibraryInventory.CreateItemNo(),
          ItemReference[1]."Reference Type"::Customer, CustNo);

        // [GIVEN] Item References for Item 1001 with No = 1234 and Type = <blank>
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[2], ItemRefNo, LibraryInventory.CreateItemNo(),
          ItemReference[2]."Reference Type"::" ", '');
        EnqueueItemReferenceFields(ItemReference[2]); // <blank> type record is to be displayed first
        EnqueueItemReferenceFields(ItemReference[1]);

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, CustNo, ItemRefNo);

        // [GIVEN] Ran ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = TRUE
        ItemReferenceMgt.ReferenceLookupSalesItem(SalesLine, ItemReference[2], true);

        // [GIVEN] Page Item Reference List opened showing both Item References: first with <blank> Type, second with Type Customer
        // [GIVEN] Stan selected the second one
        // Done in ItemReferenceListModalPageHandler

        // [WHEN] Push OK on page Item Reference List
        // Done in ItemReferenceListModalPageHandler

        // [THEN] ICRLookupSalesItem returns Item Reference with Item No = 1000
        ItemReference[2].TestField("Item No.", ItemReference[1]."Item No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemReferenceListModalPageHandler')]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenSameCustomerDifferentItemsShowDialogTrue()
    var
        ItemReference: array[2] of Record "Item Reference";
        SalesLine: Record "Sales Line";
        CustNo: Code[20];
        ItemRefNo: Code[50];
        Index: Integer;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 289240] Customer A, Items: X,Y Item References AX and AY
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is Yes
        // [SCENARIO 289240] Page Item Reference List shows both Item References (AX and AY)
        Initialize();
        CustNo := LibrarySales.CreateCustomerNo();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");
        LibraryVariableStorage.Enqueue(ItemRefNo);

        // [GIVEN] Item References for Items 1000 and 1001 with same No = 1234, Type = Customer and Type No = 10000
        for Index := 1 to ArrayLen(ItemReference) do begin
            LibraryItemReference.CreateItemReferenceWithNo(ItemReference[Index], ItemRefNo, LibraryInventory.CreateItemNo(),
              ItemReference[Index]."Reference Type"::Customer, CustNo);
            EnqueueItemReferenceFields(ItemReference[Index]);
        end;

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, CustNo, ItemRefNo);

        // [GIVEN] Ran ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = TRUE
        ItemReferenceMgt.ReferenceLookupSalesItem(SalesLine, ItemReference[1], true);

        // [GIVEN] Page Item Reference List opened showing both Item References, first for Item 1000, second for Item 1001
        // [GIVEN] Stan selected the second one
        // Done in ItemReferenceListModalPageHandler

        // [WHEN] Push OK on page Item Reference List
        // Done in ItemReferenceListModalPageHandler

        // [THEN] ICRLookupSalesItem returns Item Reference with Item No = 1001
        ItemReference[1].TestField("Item No.", ItemReference[2]."Item No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemReferenceListModalPageHandler')]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenBarCodesDifferentItemsShowDialogTrue()
    var
        ItemReference: array[2] of Record "Item Reference";
        SalesLine: Record "Sales Line";
        ItemRefNo: Code[50];
        Index: Integer;
    begin
        // [FEATURE] [UI] [Bar Code]
        // [SCENARIO 289240] Items: X,Y, Bar Code References: PX,PY
        // [SCENARIO 289240] ICRLookupSalesItem for Customer and ShowDialog is Yes
        // [SCENARIO 289240] Page Item Reference List shows both Item References (PX and PY)
        Initialize();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");
        LibraryVariableStorage.Enqueue(ItemRefNo);

        // [GIVEN] Item References for Items 1000 and 1001, both with No = 1234 and Type = Bar Code
        for Index := 1 to ArrayLen(ItemReference) do begin
            LibraryItemReference.CreateItemReferenceWithNo(ItemReference[Index], ItemRefNo, LibraryInventory.CreateItemNo(),
              ItemReference[Index]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID());
            EnqueueItemReferenceFields(ItemReference[Index]);
        end;

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, LibrarySales.CreateCustomerNo(), ItemRefNo);

        // [GIVEN] Ran ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = TRUE
        ItemReferenceMgt.ReferenceLookupSalesItem(SalesLine, ItemReference[1], true);

        // [GIVEN] Page Item Reference List opened showing both Item References, first for Item 1000, second for Item 1001
        // [GIVEN] Stan selected the second one
        // Done in ItemReferenceListModalPageHandler

        // [WHEN] Push OK on page Item Reference List
        // Done in ItemReferenceListModalPageHandler

        // [THEN] ICRLookupSalesItem returns Item Reference with Item No = 1001
        ItemReference[1].TestField("Item No.", ItemReference[2]."Item No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenCustomerAndBarCodeSameItemShowDialogTrue()
    var
        ItemReference: array[2] of Record "Item Reference";
        SalesLine: Record "Sales Line";
        CustNo: Code[20];
        ItemRefNo: Code[50];
    begin
        // [FEATURE] [Bar Code]
        // [SCENARIO 289240] Customer A, Item X, Customer Reference AX, Bar Code Reference PX
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is Yes
        // [SCENARIO 289240] Page Item Reference List is not shown, ICRLookupSalesItem returns Item Reference for Customer A (AX)
        Initialize();
        CustNo := LibrarySales.CreateCustomerNo();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Item References for Item 1000 with No = 1234, Type = Customer and Type No = 10000
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[1], ItemRefNo, LibraryInventory.CreateItemNo(),
          ItemReference[1]."Reference Type"::Customer, CustNo);

        // [GIVEN] Item References for same Item with same No and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[2], ItemRefNo, ItemReference[1]."Item No.",
          ItemReference[2]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID());

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, CustNo, ItemRefNo);

        // [WHEN] Ran ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = TRUE
        ItemReferenceMgt.ReferenceLookupSalesItem(SalesLine, ItemReference[2], true);

        // [THEN] ICRLookupSalesItem returns Item Reference with Item No = 1000
        ItemReference[2].TestField("Item No.", ItemReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenCustomerAndBlankTypeSameItemShowDialogTrue()
    var
        ItemReference: array[2] of Record "Item Reference";
        SalesLine: Record "Sales Line";
        CustNo: Code[20];
        ItemRefNo: Code[50];
    begin
        // [FEATURE] [Bar Code]
        // [SCENARIO 289240] Customer A, Item X, Customer Reference AX, <blank> Type Reference TX
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is Yes
        // [SCENARIO 289240] Page Item Reference List is not shown, ICRLookupSalesItem returns Item Reference for Customer A (AX)
        Initialize();
        CustNo := LibrarySales.CreateCustomerNo();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Item References for Item 1000 with No = 1234, Type = Customer and Type No = 10000
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[1], ItemRefNo, LibraryInventory.CreateItemNo(),
          ItemReference[1]."Reference Type"::Customer, CustNo);

        // [GIVEN] Item References for same Item with same No and Type = <blank>
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[2], ItemRefNo, ItemReference[1]."Item No.",
          ItemReference[2]."Reference Type"::" ", '');

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, CustNo, ItemRefNo);

        // [WHEN] Ran ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = TRUE
        ItemReferenceMgt.ReferenceLookupSalesItem(SalesLine, ItemReference[2], true);

        // [THEN] ICRLookupSalesItem returns Item Reference with Item No = 1000
        ItemReference[2].TestField("Item No.", ItemReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenBarCodesSameItemShowDialogTrue()
    var
        ItemReference: array[2] of Record "Item Reference";
        SalesLine: Record "Sales Line";
        ItemRefNo: Code[50];
        ItemNo: Code[20];
        Index: Integer;
    begin
        // [FEATURE] [Bar Code]
        // [SCENARIO 289240] Item X, Bar Code References: PX,TX
        // [SCENARIO 289240] ICRLookupSalesItem for Customer and ShowDialog is Yes
        // [SCENARIO 289240] Page Item Reference List is not shown, ICRLookupSalesItem returns Item Reference PX
        Initialize();
        ItemNo := LibraryInventory.CreateItemNo();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Item References both for same Item, No = 1234 and Type = Bar Code, Type No are "P" and "T"
        for Index := 1 to ArrayLen(ItemReference) do
            LibraryItemReference.CreateItemReferenceWithNo(ItemReference[Index], ItemRefNo, ItemNo,
              ItemReference[Index]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID());

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, LibrarySales.CreateCustomerNo(), ItemRefNo);

        // [WHEN] Run ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = TRUE
        ItemReferenceMgt.ReferenceLookupSalesItem(SalesLine, ItemReference[2], true);

        // [THEN] ICRLookupSalesItem returns Item Reference with Type No = "P"
        ItemReference[2].TestField("Reference Type No.", ItemReference[1]."Reference Type No.");
        ItemReference[2].TestField("Item No.", ItemReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenDifferentCustomersSameItemShowDialogTrue()
    var
        ItemReference: array[2] of Record "Item Reference";
        SalesLine: Record "Sales Line";
        ItemRefNo: Code[50];
        ItemNo: Code[20];
        Index: Integer;
    begin
        // [SCENARIO 289240] Customers: A,B, Item X, Item References AX and BX
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is Yes
        // [SCENARIO 289240] Page Item Reference List is not shown, ICRLookupSalesItem returns Item Reference for Customer A (AX)
        Initialize();
        ItemNo := LibraryInventory.CreateItemNo();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Two Item References for Item 1000 with same No = 1234, Type = Customer, first has Type No = 10000, second has Type No = 20000
        for Index := 1 to ArrayLen(ItemReference) do
            LibraryItemReference.CreateItemReferenceWithNo(ItemReference[Index], ItemRefNo, ItemNo,
              ItemReference[Index]."Reference Type"::Customer, LibrarySales.CreateCustomerNo());

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(
          SalesLine, CopyStr(ItemReference[1]."Reference Type No.", 1, MaxStrLen(SalesLine."Sell-to Customer No.")), ItemRefNo);

        // [WHEN] Run ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = TRUE
        ItemReferenceMgt.ReferenceLookupSalesItem(SalesLine, ItemReference[2], true);

        // [THEN] ICRLookupSalesItem returns Item Reference with Item No = 1000
        ItemReference[2].TestField("Item No.", ItemReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenDifferentCustomersDifferentItemsShowDialogTrue()
    var
        ItemReference: array[2] of Record "Item Reference";
        SalesLine: Record "Sales Line";
        ItemRefNo: Code[50];
        Index: Integer;
    begin
        // [SCENARIO 289240] Customers: A,B, Items X,Y, Item References AX and BY
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is Yes
        // [SCENARIO 289240] Page Item Reference List is not shown, ICRLookupSalesItem returns Item Reference for Customer A (AX)
        Initialize();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Item Reference for Item 1000 with No = 1234, Type = Customer, Type No = 10000
        // [GIVEN] Item Reference for Item 1001 with No = 1234, Type = Customer, Type No = 20000
        for Index := 1 to ArrayLen(ItemReference) do
            LibraryItemReference.CreateItemReferenceWithNo(ItemReference[Index], ItemRefNo, LibraryInventory.CreateItemNo(),
              ItemReference[Index]."Reference Type"::Customer, LibrarySales.CreateCustomerNo());

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(
          SalesLine, CopyStr(ItemReference[1]."Reference Type No.", 1, MaxStrLen(SalesLine."Sell-to Customer No.")), ItemRefNo);

        // [WHEN] Run ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = TRUE
        ItemReferenceMgt.ReferenceLookupSalesItem(SalesLine, ItemReference[2], true);

        // [THEN] ICRLookupSalesItem returns Item Reference with Item No = 1000
        ItemReference[2].TestField("Item No.", ItemReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenOtherCustomerAndBarCodeShowDialogTrue()
    var
        ItemReference: array[2] of Record "Item Reference";
        SalesLine: Record "Sales Line";
        ItemRefNo: Code[50];
    begin
        // [FEATURE] [Bar Code]
        // [SCENARIO 289240] Customer B, Items X,Y Customer Reference BX, Bar Code Reference PY
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is Yes
        // [SCENARIO 289240] Page Item Reference List is not shown, ICRLookupSalesItem returns Item Reference PY
        Initialize();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Item Reference for Item 1000 with No = 1234, Type = Customer and Type No = 20000
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[1], ItemRefNo, LibraryInventory.CreateItemNo(),
          ItemReference[1]."Reference Type"::Customer, LibrarySales.CreateCustomerNo());

        // [GIVEN] Item References for Item 1001 with same No and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[2], ItemRefNo, ItemReference[1]."Item No.",
          ItemReference[2]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID());

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, LibrarySales.CreateCustomerNo(), ItemRefNo);

        // [WHEN] Ran ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = TRUE
        ItemReferenceMgt.ReferenceLookupSalesItem(SalesLine, ItemReference[1], true);

        // [THEN] ICRLookupSalesItem returns Item Reference with Item No = 1001
        ItemReference[1].TestField("Item No.", ItemReference[2]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenOtherCustomerShowDialogTrue()
    var
        ItemReference: Record "Item Reference";
        SalesLine: Record "Sales Line";
        ItemRefNo: Code[50];
    begin
        // [SCENARIO 289240] Customer B, Item Reference BX
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is Yes
        // [SCENARIO 289240] ICRLookupSalesItem throws error
        Initialize();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference.FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Item Reference for Item with No = 1234, Type = Customer and Type No = 20000
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference, ItemRefNo, LibraryInventory.CreateItemNo(),
          ItemReference."Reference Type"::Customer, LibrarySales.CreateCustomerNo());

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, LibrarySales.CreateCustomerNo(), ItemRefNo);

        // [WHEN] Run ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = TRUE
        asserterror ItemReferenceMgt.ReferenceLookupSalesItem(SalesLine, ItemReference, true);

        // [THEN] Error "There are no items with cross reference: 1234"
        Assert.ExpectedError(StrSubstNo(ItemRefNotExistsErr, ItemRefNo));
        Assert.ExpectedErrorCode(DialogCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenOtherMultipleCustomersShowDialogTrue()
    var
        ItemReference: Record "Item Reference";
        SalesLine: Record "Sales Line";
        ItemRefNo: Code[50];
    begin
        // [SCENARIO 289240] Customers: B,C Item References BX,CY
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is Yes
        // [SCENARIO 289240] ICRLookupSalesItem throws error
        Initialize();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference.FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Two Item References with same No = 1234, same Type = Customer and Type No 20000 and 30000
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference, ItemRefNo, LibraryInventory.CreateItemNo(),
          ItemReference."Reference Type"::Customer, LibrarySales.CreateCustomerNo());
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference, ItemRefNo, LibraryInventory.CreateItemNo(),
          ItemReference."Reference Type"::Customer, LibrarySales.CreateCustomerNo());

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, LibrarySales.CreateCustomerNo(), ItemRefNo);

        // [WHEN] Run ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = TRUE
        asserterror ItemReferenceMgt.ReferenceLookupSalesItem(SalesLine, ItemReference, true);

        // [THEN] Error "There are no items with cross reference: 1234"
        Assert.ExpectedError(StrSubstNo(ItemRefNotExistsErr, ItemRefNo));
        Assert.ExpectedErrorCode(DialogCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenOneCustomerShowDialogTrue()
    var
        ItemReference: Record "Item Reference";
        SalesLine: Record "Sales Line";
        ItemRefNo: Code[50];
        ItemNo: Code[20];
    begin
        // [SCENARIO 289240] Customer A, Item Reference AX
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is Yes
        // [SCENARIO 289240] ICRLookupSalesItem Returns Item Reference AX
        Initialize();
        ItemNo := LibraryInventory.CreateItemNo();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference.FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Item Reference for Item 1000 with No = 1234, Type = Customer and Type No = 10000
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference, ItemRefNo, ItemNo,
          ItemReference."Reference Type"::Customer, LibrarySales.CreateCustomerNo());

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(
          SalesLine, CopyStr(ItemReference."Reference Type No.", 1, MaxStrLen(SalesLine."Sell-to Customer No.")), ItemRefNo);

        // [WHEN] Run ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = TRUE
        ItemReferenceMgt.ReferenceLookupSalesItem(SalesLine, ItemReference, true);

        // [THEN] ICRLookupSalesItem returns Item Reference with Item No = 1000
        ItemReference.TestField("Item No.", ItemNo)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenNoItemRefShowDialogTrue()
    var
        DummyItemReference: Record "Item Reference";
        SalesLine: Record "Sales Line";
        ItemRefNo: Code[50];
    begin
        // [SCENARIO 289240] No Item References with No = 1234
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A with Item Reference No = 1234 and ShowDialog is Yes
        // [SCENARIO 289240] ICRLookupSalesItem Returns Item Reference AX
        Initialize();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(DummyItemReference.FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, LibrarySales.CreateCustomerNo(), ItemRefNo);

        // [WHEN] Run ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = TRUE
        asserterror ItemReferenceMgt.ReferenceLookupSalesItem(SalesLine, DummyItemReference, true);

        // [THEN] Error "There are no items with cross reference: 1234"
        Assert.ExpectedError(StrSubstNo(ItemRefNotExistsErr, ItemRefNo));
        Assert.ExpectedErrorCode(DialogCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenSameCustomersForSameItemsAndBarCodeShowDialogFalse()
    var
        ItemReference: array[2] of Record "Item Reference";
        SalesLine: Record "Sales Line";
        CustNo: array[2] of Code[20];
        ItemRefNo: Code[50];
        Index: Integer;
        ItemIndex: Integer;
        ItemNo: array[2] of Code[20];
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO 289240] Customers: A,B, Items: X,Y,Z, Customer References: AX, AY, BX, BY and Bar Code Reference PZ
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is No
        // [SCENARIO 289240] ICRLookupSalesItem returns Item Reference for Customer A and Item X (AX)
        Initialize();
        for ItemIndex := 1 to ArrayLen(ItemNo) do begin
            ItemNo[ItemIndex] := LibraryInventory.CreateItemNo();
            CustNo[ItemIndex] := LibrarySales.CreateCustomerNo();
        end;
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Two Item References for Item 1000 with No = 1234, Type = Customer and Type No = 10000 and 20000
        // [GIVEN] Two similar Item References for Item 1001
        for ItemIndex := 1 to ArrayLen(ItemNo) do
            for Index := 1 to ArrayLen(ItemReference) do
                LibraryItemReference.CreateItemReferenceWithNo(ItemReference[Index], ItemRefNo, ItemNo[ItemIndex],
                  ItemReference[Index]."Reference Type"::Customer, CustNo[Index]);

        // [GIVEN] Item Reference for Item 1100 with No = 1234, Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNo(
          ItemReference[2], ItemRefNo, LibraryInventory.CreateItemNo(), ItemReference[2]."Reference Type"::"Bar Code",
          LibraryUtility.GenerateGUID());

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, CustNo[1], ItemRefNo);

        // [WHEN] Run ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = FALSE
        ItemReferenceMgt.ReferenceLookupSalesItem(SalesLine, ItemReference[2], false);

        // [THEN] ICRLookupSalesItem returns Item Reference with Item No = 1000 and Type No = 10000
        ItemReference[2].TestField("Item No.", ItemNo[1]);
        ItemReference[2].TestField("Reference Type No.", CustNo[1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenSameCustomersForSameItemsShowDialogFalse()
    var
        ItemReference: array[2] of Record "Item Reference";
        SalesLine: Record "Sales Line";
        CustNo: array[2] of Code[20];
        ItemRefNo: Code[50];
        Index: Integer;
        ItemIndex: Integer;
        ItemNo: array[2] of Code[20];
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO 289240] Customers: A,B, Items: X,Y, Item References: AX, AY, BX, BY
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is No
        // [SCENARIO 289240] ICRLookupSalesItem returns Item Reference for Customer A and Item X (AX)
        Initialize();
        for ItemIndex := 1 to ArrayLen(ItemNo) do begin
            ItemNo[ItemIndex] := LibraryInventory.CreateItemNo();
            CustNo[ItemIndex] := LibrarySales.CreateCustomerNo();
        end;
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Two Item References for Item 1000 with No = 1234, Type = Customer and Type No = 10000 and 20000
        // [GIVEN] Two similar Item References for Item 1001
        for ItemIndex := 1 to ArrayLen(ItemNo) do
            for Index := 1 to ArrayLen(ItemReference) do
                LibraryItemReference.CreateItemReferenceWithNo(ItemReference[Index], ItemRefNo, ItemNo[ItemIndex],
                  ItemReference[Index]."Reference Type"::Customer, CustNo[Index]);

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, CustNo[1], ItemRefNo);

        // [When] Run ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = FALSE
        ItemReferenceMgt.ReferenceLookupSalesItem(SalesLine, ItemReference[2], false);

        // [THEN] ICRLookupSalesItem returns Item Reference with Item No = 1000 and Type No = 10000
        ItemReference[2].TestField("Item No.", ItemNo[1]);
        ItemReference[2].TestField("Reference Type No.", CustNo[1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenCustomerAndBarCodeDifferentItemsShowDialogFalse()
    var
        ItemReference: array[2] of Record "Item Reference";
        SalesLine: Record "Sales Line";
        CustNo: Code[20];
        ItemRefNo: Code[50];
    begin
        // [FEATURE] [Intercompany] [Bar Code]
        // [SCENARIO 289240] Customer A, Items: X,Y Customer Reference AX and Bar Code Reference PY
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is No
        // [SCENARIO 289240] ICRLookupSalesItem returns Item Reference for Customer A and Item X (AX)
        Initialize();
        CustNo := LibrarySales.CreateCustomerNo();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Item References for Item 1000 with No = 1234, Type = Customer and Type No = 10000
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[1], ItemRefNo, LibraryInventory.CreateItemNo(),
          ItemReference[1]."Reference Type"::Customer, CustNo);

        // [GIVEN] Item References for Item 1001 with same No and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[2], ItemRefNo, LibraryInventory.CreateItemNo(),
          ItemReference[2]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID());

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, CustNo, ItemRefNo);

        // [WHEN] Ran ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = FALSE
        ItemReferenceMgt.ReferenceLookupSalesItem(SalesLine, ItemReference[2], false);

        // [THEN] ICRLookupSalesItem returns Item Reference with Item No = 1000
        ItemReference[2].TestField("Item No.", ItemReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenCustomerAndBlankTypeDifferentItemsShowDialogFalse()
    var
        ItemReference: array[2] of Record "Item Reference";
        SalesLine: Record "Sales Line";
        CustNo: Code[20];
        ItemRefNo: Code[50];
    begin
        // [FEATURE] [Intercompany] [Bar Code]
        // [SCENARIO 289240] Customer A, Items: X,Y Customer Reference AX and <blank> Type Item Reference TY
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is No
        // [SCENARIO 289240] ICRLookupSalesItem returns Item Reference for Customer A and Item X (AX)
        Initialize();
        CustNo := LibrarySales.CreateCustomerNo();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Item References for Item 1000 with No = 1234, Type = Customer and Type No = 10000
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[1], ItemRefNo, LibraryInventory.CreateItemNo(),
          ItemReference[1]."Reference Type"::Customer, CustNo);

        // [GIVEN] Item References for Item 1001 with No = 1234 and Type = <blank>
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[2], ItemRefNo, LibraryInventory.CreateItemNo(),
          ItemReference[2]."Reference Type"::" ", '');

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, CustNo, ItemRefNo);

        // [WHEN] Run ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = FALSE
        ItemReferenceMgt.ReferenceLookupSalesItem(SalesLine, ItemReference[2], false);

        // [THEN] ICRLookupSalesItem returns Item Reference with Item No = 1000
        ItemReference[2].TestField("Item No.", ItemReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenSameCustomerDifferentItemsShowDialogFalse()
    var
        ItemReference: array[2] of Record "Item Reference";
        SalesLine: Record "Sales Line";
        CustNo: Code[20];
        ItemRefNo: Code[50];
        Index: Integer;
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO 289240] Customer A, Items: X,Y Item References AX and AY
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is No
        // [SCENARIO 289240] ICRLookupSalesItem returns Item Reference for Customer A and Item X (AX)
        Initialize();
        CustNo := LibrarySales.CreateCustomerNo();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Item References for Items 1000 and 1001 with same No = 1234, Type = Customer and Type No = 10000
        for Index := 1 to ArrayLen(ItemReference) do
            LibraryItemReference.CreateItemReferenceWithNo(ItemReference[Index], ItemRefNo, LibraryInventory.CreateItemNo(),
              ItemReference[Index]."Reference Type"::Customer, CustNo);

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, CustNo, ItemRefNo);

        // [WHEN] Run ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = FALSE
        ItemReferenceMgt.ReferenceLookupSalesItem(SalesLine, ItemReference[2], false);

        // [THEN] ICRLookupSalesItem returns Item Reference with Item No = 1000
        ItemReference[2].TestField("Item No.", ItemReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenBarCodesDifferentItemsShowDialogFalse()
    var
        ItemReference: array[2] of Record "Item Reference";
        SalesLine: Record "Sales Line";
        ItemRefNo: Code[50];
        Index: Integer;
    begin
        // [FEATURE] [Intercompany] [Bar Code]
        // [SCENARIO 289240] Items: X,Y, Bar Code References: PX,PY
        // [SCENARIO 289240] ICRLookupSalesItem for Customer and ShowDialog is No
        // [SCENARIO 289240] ICRLookupSalesItem returns Item Reference PX
        Initialize();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Item References for Items 1000 and 1001, both with No = 1234 and Type = Bar Code
        for Index := 1 to ArrayLen(ItemReference) do
            LibraryItemReference.CreateItemReferenceWithNo(ItemReference[Index], ItemRefNo, LibraryInventory.CreateItemNo(),
              ItemReference[Index]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID());

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, LibrarySales.CreateCustomerNo(), ItemRefNo);

        // [WHEN] Run ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = FALSE
        ItemReferenceMgt.ReferenceLookupSalesItem(SalesLine, ItemReference[2], false);

        // [THEN] ICRLookupSalesItem returns Item Reference with Item No = 1001
        ItemReference[2].TestField("Item No.", ItemReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenCustomerAndBarCodeSameItemShowDialogFalse()
    var
        ItemReference: array[2] of Record "Item Reference";
        SalesLine: Record "Sales Line";
        CustNo: Code[20];
        ItemRefNo: Code[50];
    begin
        // [FEATURE] [Intercompany] [Bar Code]
        // [SCENARIO 289240] Customer A, Item X, Customer Reference AX, Bar Code Reference PX
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is No
        // [SCENARIO 289240] ICRLookupSalesItem returns Item Reference for Customer A (AX)
        Initialize();
        CustNo := LibrarySales.CreateCustomerNo();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Item References for Item 1000 with No = 1234, Type = Customer and Type No = 10000
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[1], ItemRefNo, LibraryInventory.CreateItemNo(),
          ItemReference[1]."Reference Type"::Customer, CustNo);

        // [GIVEN] Item References for same Item with same No and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[2], ItemRefNo, ItemReference[1]."Item No.",
          ItemReference[2]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID());

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, CustNo, ItemRefNo);

        // [WHEN] Ran ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = FALSE
        ItemReferenceMgt.ReferenceLookupSalesItem(SalesLine, ItemReference[2], false);

        // [THEN] ICRLookupSalesItem returns Item Reference with Item No = 1000
        ItemReference[2].TestField("Item No.", ItemReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenCustomerAndBlankTypeSameItemShowDialogFalse()
    var
        ItemReference: array[2] of Record "Item Reference";
        SalesLine: Record "Sales Line";
        CustNo: Code[20];
        ItemRefNo: Code[50];
    begin
        // [FEATURE] [Intercompany] [Bar Code]
        // [SCENARIO 289240] Customer A, Item X, Customer Reference AX, <blank> Type Item Reference TX
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is No
        // [SCENARIO 289240] Page Item Reference List is not shown, ICRLookupSalesItem returns Item Reference for Customer A (AX)
        Initialize();
        CustNo := LibrarySales.CreateCustomerNo();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Item References for Item 1000 with No = 1234, Type = Customer and Type No = 10000
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[1], ItemRefNo, LibraryInventory.CreateItemNo(),
          ItemReference[1]."Reference Type"::Customer, CustNo);

        // [GIVEN] Item References for same Item with same No and Type = <blank>
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[2], ItemRefNo, ItemReference[1]."Item No.",
          ItemReference[2]."Reference Type"::" ", '');

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, CustNo, ItemRefNo);

        // [WHEN] Ran ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = FALSE
        ItemReferenceMgt.ReferenceLookupSalesItem(SalesLine, ItemReference[2], false);

        // [THEN] ICRLookupSalesItem returns Item Reference with Item No = 1000
        ItemReference[2].TestField("Item No.", ItemReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenBarCodesSameItemShowDialogFalse()
    var
        ItemReference: array[2] of Record "Item Reference";
        SalesLine: Record "Sales Line";
        ItemRefNo: Code[50];
        ItemNo: Code[20];
        Index: Integer;
    begin
        // [FEATURE] [Intercompany] [Bar Code]
        // [SCENARIO 289240] Item X, Bar Code References: PX,TX
        // [SCENARIO 289240] ICRLookupSalesItem for Customer and ShowDialog is No
        // [SCENARIO 289240] ICRLookupSalesItem returns Item Reference PX
        Initialize();
        ItemNo := LibraryInventory.CreateItemNo();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Item References both for same Item, No = 1234 and Type = Bar Code, Type No are "P" and "T"
        for Index := 1 to ArrayLen(ItemReference) do
            LibraryItemReference.CreateItemReferenceWithNo(ItemReference[Index], ItemRefNo, ItemNo,
              ItemReference[Index]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID());

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, LibrarySales.CreateCustomerNo(), ItemRefNo);

        // [WHEN] Run ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = FALSE
        ItemReferenceMgt.ReferenceLookupSalesItem(SalesLine, ItemReference[2], false);

        // [THEN] ICRLookupSalesItem returns Item Reference with Type No = "P"
        ItemReference[2].TestField("Reference Type No.", ItemReference[1]."Reference Type No.");
        ItemReference[2].TestField("Item No.", ItemReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenDifferentCustomersSameItemShowDialogFalse()
    var
        ItemReference: array[2] of Record "Item Reference";
        SalesLine: Record "Sales Line";
        ItemRefNo: Code[50];
        ItemNo: Code[20];
        Index: Integer;
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO 289240] Customers: A,B, Item X, Item References AX and BX
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is No
        // [SCENARIO 289240] ICRLookupSalesItem returns Item Reference for Customer A (AX)
        Initialize();
        ItemNo := LibraryInventory.CreateItemNo();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Two Item References for Item 1000 with same No = 1234, Type = Customer, first has Type No = 10000, second has Type No = 20000
        for Index := 1 to ArrayLen(ItemReference) do
            LibraryItemReference.CreateItemReferenceWithNo(ItemReference[Index], ItemRefNo, ItemNo,
              ItemReference[Index]."Reference Type"::Customer, LibrarySales.CreateCustomerNo());

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(
          SalesLine, CopyStr(ItemReference[1]."Reference Type No.", 1, MaxStrLen(SalesLine."Sell-to Customer No.")), ItemRefNo);

        // [WHEN] Run ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = FALSE
        ItemReferenceMgt.ReferenceLookupSalesItem(SalesLine, ItemReference[2], false);

        // [THEN] ICRLookupSalesItem returns Item Reference with Item No = 1000
        ItemReference[2].TestField("Item No.", ItemReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenDifferentCustomersSameItemShowDialogFalseSecond()
    var
        ItemReference: array[2] of Record "Item Reference";
        SalesLine: Record "Sales Line";
        ItemRefNo: Code[50];
        ItemNo: Code[20];
        Index: Integer;
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO 315787] Customers: A,B, Item X, Item References AX and BX
        // [SCENARIO 315787] ICRLookupSalesItem for Customer B and ShowDialog is No
        // [SCENARIO 315787] ICRLookupSalesItem returns Item Reference for Customer B (BX)
        Initialize();
        ItemNo := LibraryInventory.CreateItemNo();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Two Item References for Item 1000 with same No = 1234, Type = Customer, first has Type No = 10000, second has Type No = 20000
        for Index := 1 to ArrayLen(ItemReference) do
            LibraryItemReference.CreateItemReferenceWithNo(ItemReference[Index], ItemRefNo, ItemNo,
              ItemReference[Index]."Reference Type"::Customer, LibrarySales.CreateCustomerNo());

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 20000 and Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(
          SalesLine, CopyStr(ItemReference[2]."Reference Type No.", 1, MaxStrLen(SalesLine."Sell-to Customer No.")), ItemRefNo);

        // [WHEN] Run ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = FALSE
        ItemReferenceMgt.ReferenceLookupSalesItem(SalesLine, ItemReference[1], false);

        // [THEN] ICRLookupSalesItem returns Item Reference with Item No = 2000
        ItemReference[1].TestField("Item No.", ItemReference[2]."Item No.");
        ItemReference[1].TestField("Reference Type No.", ItemReference[2]."Reference Type No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenDifferentCustomersDifferentItemsShowDialogFalse()
    var
        ItemReference: array[2] of Record "Item Reference";
        SalesLine: Record "Sales Line";
        ItemRefNo: Code[50];
        Index: Integer;
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO 289240] Customers: A,B, Items X,Y, Item References AX and BY
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is No
        // [SCENARIO 289240] ICRLookupSalesItem returns Item Reference for Customer A (AX)
        Initialize();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Item Reference for Item 1000 with No = 1234, Type = Customer, Type No = 10000
        // [GIVEN] Item Reference for Item 1001 with No = 1234, Type = Customer, Type No = 20000
        for Index := 1 to ArrayLen(ItemReference) do
            LibraryItemReference.CreateItemReferenceWithNo(ItemReference[Index], ItemRefNo, LibraryInventory.CreateItemNo(),
              ItemReference[Index]."Reference Type"::Customer, LibrarySales.CreateCustomerNo());

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(
          SalesLine, CopyStr(ItemReference[1]."Reference Type No.", 1, MaxStrLen(SalesLine."Sell-to Customer No.")), ItemRefNo);

        // [WHEN] Run ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = FALSE
        ItemReferenceMgt.ReferenceLookupSalesItem(SalesLine, ItemReference[2], false);

        // [THEN] ICRLookupSalesItem returns Item Reference with Item No = 1000
        ItemReference[2].TestField("Item No.", ItemReference[1]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenOtherCustomerAndBarCodeShowDialogFalse()
    var
        ItemReference: array[2] of Record "Item Reference";
        SalesLine: Record "Sales Line";
        ItemRefNo: Code[50];
    begin
        // [FEATURE] [Intercompany] [Bar Code]
        // [SCENARIO 289240] Customer B, Items X,Y Customer Reference BX, Bar Code Reference PY
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is No
        // [SCENARIO 289240] ICRLookupSalesItem returns Item Reference PY
        Initialize();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Item Reference for Item 1000 with No = 1234, Type = Customer and Type No = 20000
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[1], ItemRefNo, LibraryInventory.CreateItemNo(),
          ItemReference[1]."Reference Type"::Customer, LibrarySales.CreateCustomerNo());

        // [GIVEN] Item References for Item 1001 with same No and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[2], ItemRefNo, ItemReference[1]."Item No.",
          ItemReference[2]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID());

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, LibrarySales.CreateCustomerNo(), ItemRefNo);

        // [WHEN] Ran ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = FALSE
        ItemReferenceMgt.ReferenceLookupSalesItem(SalesLine, ItemReference[1], false);

        // [THEN] ICRLookupSalesItem returns Item Reference with Item No = 1001
        ItemReference[1].TestField("Item No.", ItemReference[2]."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenOtherCustomerShowDialogFalse()
    var
        ItemReference: Record "Item Reference";
        SalesLine: Record "Sales Line";
        ItemRefNo: Code[50];
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO 289240] Customer B, Item Reference BX
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is No
        // [SCENARIO 289240] ICRLookupSalesItem throws error
        Initialize();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference.FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Item Reference for Item with No = 1234, Type = Customer and Type No = 20000
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference, ItemRefNo, LibraryInventory.CreateItemNo(),
          ItemReference."Reference Type"::Customer, LibrarySales.CreateCustomerNo());

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, LibrarySales.CreateCustomerNo(), ItemRefNo);

        // [WHEN] Run ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = FALSE
        asserterror ItemReferenceMgt.ReferenceLookupSalesItem(SalesLine, ItemReference, false);

        // [THEN] Error "There are no items with cross reference: 1234"
        Assert.ExpectedError(StrSubstNo(ItemRefNotExistsErr, ItemRefNo));
        Assert.ExpectedErrorCode(DialogCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenOtherMultipleCustomersShowDialogFalse()
    var
        ItemReference: Record "Item Reference";
        SalesLine: Record "Sales Line";
        ItemRefNo: Code[50];
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO 289240] Customers: B,C Item References BX,CY
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is No
        // [SCENARIO 289240] ICRLookupSalesItem throws error
        Initialize();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference.FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Two Item References with same No = 1234, same Type = Customer and Type No 20000 and 30000
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference, ItemRefNo, LibraryInventory.CreateItemNo(),
          ItemReference."Reference Type"::Customer, LibrarySales.CreateCustomerNo());
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference, ItemRefNo, LibraryInventory.CreateItemNo(),
          ItemReference."Reference Type"::Customer, LibrarySales.CreateCustomerNo());

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, LibrarySales.CreateCustomerNo(), ItemRefNo);

        // [WHEN] Run ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = FALSE
        asserterror ItemReferenceMgt.ReferenceLookupSalesItem(SalesLine, ItemReference, false);

        // [THEN] Error "There are no items with cross reference: 1234"
        Assert.ExpectedError(StrSubstNo(ItemRefNotExistsErr, ItemRefNo));
        Assert.ExpectedErrorCode(DialogCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenOneCustomerShowDialogFalse()
    var
        ItemReference: Record "Item Reference";
        SalesLine: Record "Sales Line";
        ItemRefNo: Code[50];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO 289240] Customer A, Item Reference AX
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is No
        // [SCENARIO 289240] ICRLookupSalesItem Returns Item Reference AX
        Initialize();
        ItemNo := LibraryInventory.CreateItemNo();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference.FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Item Reference for Item 1000 with No = 1234, Type = Customer and Type No = 10000
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference, ItemRefNo, ItemNo,
          ItemReference."Reference Type"::Customer, LibrarySales.CreateCustomerNo());

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(
          SalesLine, CopyStr(ItemReference."Reference Type No.", 1, MaxStrLen(SalesLine."Sell-to Customer No.")), ItemRefNo);

        // [WHEN] Run ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = FALSE
        ItemReferenceMgt.ReferenceLookupSalesItem(SalesLine, ItemReference, false);

        // [THEN] ICRLookupSalesItem returns Item Reference with Item No = 1000
        ItemReference.TestField("Item No.", ItemNo)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenNoItemRefShowDialogFalse()
    var
        DummyItemReference: Record "Item Reference";
        SalesLine: Record "Sales Line";
        ItemRefNo: Code[50];
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO 289240] No Item References with No = 1234
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A with Item Reference No = 1234 and ShowDialog is No
        // [SCENARIO 289240] ICRLookupSalesItem Returns Item Reference AX
        Initialize();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(DummyItemReference.FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(
          SalesLine, LibrarySales.CreateCustomerNo(), ItemRefNo);

        // [WHEN] Run ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = FALSE
        asserterror ItemReferenceMgt.ReferenceLookupSalesItem(SalesLine, DummyItemReference, false);

        // [THEN] Error "There are no items with cross reference: 1234"
        Assert.ExpectedError(StrSubstNo(ItemRefNotExistsErr, ItemRefNo));
        Assert.ExpectedErrorCode(DialogCodeErr);
    end;

    [Test]
    [HandlerFunctions('ItemReferenceListCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenStanCancelsItemReferenceList()
    var
        ItemReference: array[2] of Record "Item Reference";
        SalesLine: Record "Sales Line";
        CustNo: array[2] of Code[20];
        ItemRefNo: Code[50];
        Index: Integer;
        ItemIndex: Integer;
        ItemNo: array[2] of Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 289240] ICRLookupSalesItem for Customer A and ShowDialog is Yes
        // [SCENARIO 289240] Page Item Reference List opened with Item References
        // [SCENARIO 289240] When Stan pushes cancel on page, then error
        Initialize();
        for ItemIndex := 1 to ArrayLen(ItemNo) do begin
            ItemNo[ItemIndex] := LibraryInventory.CreateItemNo();
            CustNo[ItemIndex] := LibrarySales.CreateCustomerNo();
        end;
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");

        // [GIVEN] Two Item References for Item 1000 with No = 1234, Type = Customer and Type No = 10000 and 20000
        // [GIVEN] Two similar Item References for Item 1001
        for ItemIndex := 1 to ArrayLen(ItemNo) do
            for Index := 1 to ArrayLen(ItemReference) do
                LibraryItemReference.CreateItemReferenceWithNo(ItemReference[Index], ItemRefNo, ItemNo[ItemIndex],
                  ItemReference[Index]."Reference Type"::Customer, CustNo[Index]);

        // [GIVEN] Item Reference for Item 1100 with No = 1234, Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNo(
          ItemReference[2], ItemRefNo, LibraryInventory.CreateItemNo(), ItemReference[2]."Reference Type"::"Bar Code",
          LibraryUtility.GenerateGUID());

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, CustNo[1], ItemRefNo);

        // [GIVEN] Ran ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = TRUE
        asserterror ItemReferenceMgt.ReferenceLookupSalesItem(SalesLine, ItemReference[1], true);

        // [GIVEN] Page Item Reference List opened

        // [WHEN] Stan pushes Cancel on page Item Reference List
        // Done in ItemReferenceListCancelModalPageHandler

        // [THEN] Error "There are no items with cross reference: 1234"
        Assert.ExpectedError(StrSubstNo(ItemRefNotExistsErr, ItemRefNo));
        Assert.ExpectedErrorCode(DialogCodeErr);
    end;

    [Test]
    [HandlerFunctions('ItemReferenceListModalPageHandler')]
    [Scope('OnPrem')]
    procedure SalesLineLookupItemRefNoWhenSameCustomerDifferentItems()
    var
        ItemReference: array[2] of Record "Item Reference";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustNo: Code[20];
        ItemRefNo: Code[50];
        Index: Integer;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 289240] Customer A, Items: X,Y Item References AX and AY
        // [SCENARIO 289240] Stan looks up Reference No in Sales Line and selects Item Reference AY
        // [SCENARIO 289240] Sales Line has Item Y
        Initialize();
        CustNo := LibrarySales.CreateCustomerNo();
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");
        LibraryVariableStorage.Enqueue(ItemRefNo);

        // [GIVEN] Item References for Items 1000 and 1001 with same No = 1234, Type = Customer and Type No = 10000
        for Index := 1 to ArrayLen(ItemReference) do begin
            LibraryItemReference.CreateItemReferenceWithNo(ItemReference[Index], ItemRefNo, LibraryInventory.CreateItemNo(),
              ItemReference[Index]."Reference Type"::Customer, CustNo);
            EnqueueItemReferenceFields(ItemReference[Index]);
        end;

        // [GIVEN] Sales Invoice with "Sell-to Customer No." = 10000 and Sales Line had Type = Item
        CreateSalesInvoiceOneLineWithLineTypeItem(SalesLine, CustNo);

        // [GIVEN] Stan Looked up Item Reference No in Sales Line
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        ItemReferenceMgt.SalesReferenceNoLookup(SalesLine, SalesHeader);

        // [GIVEN] Page Item Reference List opened showing both Item References, first for Item 1000, second for Item 1001
        // [GIVEN] Stan selected the second one
        // Done in ItemReferenceListModalPageHandler

        // [WHEN] Push OK on page Item Reference List
        // Done in ItemReferenceListModalPageHandler

        // [THEN] Sales Line has No = 1001
        SalesLine.TestField("No.", ItemReference[2]."Item No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemReferenceListModalPageHandler')]
    [Scope('OnPrem')]
    procedure ICRLookupSalesItemWhenSameCustomerForSameItemDifferentVariants()
    var
        ItemReference: array[2] of Record "Item Reference";
        SalesLine: Record "Sales Line";
        ItemVariant: Record "Item Variant";
        CustNo: Code[20];
        ItemRefNo: Code[50];
        Index: Integer;
        ItemNo: Code[20];
        VariantCode: array[2] of Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 289240] Customers: C Item: I, Variants: A,B Item References: IA, IB
        // [SCENARIO 289240] Page Item Reference List allow to select variant B
        Initialize();
        ItemNo := LibraryInventory.CreateItemNo();
        CustNo := LibrarySales.CreateCustomerNo();
        VariantCode[1] := LibraryInventory.CreateItemVariant(ItemVariant, ItemNo);
        VariantCode[2] := LibraryInventory.CreateItemVariant(ItemVariant, ItemNo);
        ItemRefNo :=
          LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), DATABASE::"Item Reference");
        LibraryVariableStorage.Enqueue(ItemRefNo);

        // [GIVEN] Three Item References for Item 1000 with No = 1234, Variant = A,B
        for Index := 1 to ArrayLen(VariantCode) do begin
            LibraryItemReference.CreateItemReference(
              ItemReference[Index], ItemNo, VariantCode[Index], '', "Item Reference Type"::Customer, CustNo, ItemRefNo);
            EnqueueItemReferenceFields(ItemReference[Index]);
        end;

        // [GIVEN] Sales Line had Type = Item, "Sell-to Customer No." = 10000 and Reference No. = 1234
        MockSalesLineForICRLookupSalesItem(SalesLine, CustNo, ItemRefNo);

        // [GIVEN] Ran ICRLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = TRUE
        ItemReferenceMgt.ReferenceLookupSalesItem(SalesLine, ItemReference[1], true);

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
    procedure ICRLookupSalesItemWhenBarCodeAndExpiredBarCodeShowDialogTrue()
    var
        ItemReference: array[2] of Record "Item Reference";
        ReturnedItemReference: Record "Item Reference";
        SalesLine: Record "Sales Line";
        ItemReferenceNo: Code[50];
    begin
        Initialize();

        // [GIVEN] Barcode for multiple item references
        ItemReferenceNo := LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), Database::"Item Reference");

        // [GIVEN] Sales Order with empty Line with Type = Item and with the item reference
        CreateSalesInvoiceOneLineWithLineTypeItem(SalesLine, LibrarySales.CreateCustomerNo());
        SalesLine."Item Reference No." := ItemReferenceNo;
        SalesLine.Modify();

        // [GIVEN] Item References for Item X and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNoAndDates(ItemReference[1], ItemReferenceNo, LibraryInventory.CreateItemNo(),
          ItemReference[1]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID(),
           CalcDate('<-1M>', SalesLine.GetDateForCalculations()), CalcDate('<-1D>', SalesLine.GetDateForCalculations()));

        // [GIVEN] Item References for Item Y and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[2], ItemReferenceNo, LibraryInventory.CreateItemNo(),
          ItemReference[2]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID());

        // [WHEN] Ran ReferenceLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = TRUE
        ItemReferenceMgt.ReferenceLookupSalesItem(SalesLine, ReturnedItemReference, true);

        // [THEN] Item Reference with Item No = X is ignored
        // [THEN] ReferenceLookupSalesItem returns Item Reference with Item No = Y
        ReturnedItemReference.TestField("Item No.", ItemReference[2]."Item No.");
    end;

    [Test]
    [HandlerFunctions('ItemReferenceListModalPageHandler')]
    procedure ICRLookupSalesItemWhenBarCodeAndBarCodeDateLimitedShowDialogTrue()
    var
        ItemReference: array[2] of Record "Item Reference";
        ReturnedItemReference: Record "Item Reference";
        SalesLine: Record "Sales Line";
        ItemReferenceNo: Code[50];
    begin
        Initialize();

        // [GIVEN] Barcode for multiple item references
        ItemReferenceNo := LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), Database::"Item Reference");
        LibraryVariableStorage.Enqueue(ItemReferenceNo);

        // [GIVEN] Sales Order with empty Line with Type = Item and with the item reference
        CreateSalesInvoiceOneLineWithLineTypeItem(SalesLine, LibrarySales.CreateCustomerNo());
        SalesLine."Item Reference No." := ItemReferenceNo;
        SalesLine.Modify();

        // [GIVEN] Item References for Item X and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNoAndDates(ItemReference[1], ItemReferenceNo, LibraryInventory.CreateItemNo(),
          ItemReference[1]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID(),
           CalcDate('<-1M>', SalesLine.GetDateForCalculations()), CalcDate('<+1M>', SalesLine.GetDateForCalculations()));
        EnqueueItemReferenceFields(ItemReference[1]);

        // [GIVEN] Item References for Item Y and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNo(ItemReference[2], ItemReferenceNo, LibraryInventory.CreateItemNo(),
          ItemReference[2]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID());
        EnqueueItemReferenceFields(ItemReference[2]);

        // [WHEN] Ran ReferenceLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = TRUE
        ItemReferenceMgt.ReferenceLookupSalesItem(SalesLine, ReturnedItemReference, true);

        // [GIVEN] Page Item Reference List opened showing both Item References
        // [GIVEN] User selected the second one
        // Done in ItemReferenceListModalPageHandler

        // [THEN] ReferenceLookupSalesItem returns Item Reference with Item No = Y
        ReturnedItemReference.TestField("Item No.", ItemReference[2]."Item No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure ICRLookupSalesItemWhenTwoExpiredBarCodesShowDialogTrue()
    var
        ItemReference: array[2] of Record "Item Reference";
        ReturnedItemReference: Record "Item Reference";
        SalesLine: Record "Sales Line";
        ItemReferenceNo: Code[50];
    begin
        Initialize();

        // [GIVEN] Barcode for multiple item references
        ItemReferenceNo := LibraryUtility.GenerateRandomCode(ItemReference[1].FieldNo("Reference No."), Database::"Item Reference");

        // [GIVEN] Sales Order with empty Line with Type = Item and with the item reference
        CreateSalesInvoiceOneLineWithLineTypeItem(SalesLine, LibrarySales.CreateCustomerNo());
        SalesLine."Item Reference No." := ItemReferenceNo;
        SalesLine.Modify();

        // [GIVEN] Item References for Item X and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNoAndDates(ItemReference[1], ItemReferenceNo, LibraryInventory.CreateItemNo(),
          ItemReference[1]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID(),
           CalcDate('<-1M>', SalesLine.GetDateForCalculations()), CalcDate('<-1D>', SalesLine.GetDateForCalculations()));

        // [GIVEN] Item References for Item Y and Type = Bar Code
        LibraryItemReference.CreateItemReferenceWithNoAndDates(ItemReference[2], ItemReferenceNo, LibraryInventory.CreateItemNo(),
          ItemReference[2]."Reference Type"::"Bar Code", LibraryUtility.GenerateGUID(),
           CalcDate('<+1D>', SalesLine.GetDateForCalculations()), CalcDate('<+1M>', SalesLine.GetDateForCalculations()));

        // [WHEN] Ran ReferenceLookupSalesItem from codeunit Dist. Integration for the Sales Line with ShowDialog = TRUE
        asserterror ItemReferenceMgt.ReferenceLookupSalesItem(SalesLine, ReturnedItemReference, true);

        // [THEN] Error "There are no items with reference %1."
        Assert.ExpectedError(StrSubstNo(ItemRefNotExistsErr, ItemReferenceNo));
    end;

    [Test]
    procedure VerifyDescriptionInSalesLineWhenBothItemReferenceAndItemVariantAreUsed()
    var
        Item: array[2] of Record Item;
        ItemReference: array[2] of Record "Item Reference";
        ItemVariant: array[2] of Record "Item Variant";
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        CustomerNo: Code[20];
    begin
        // [SCENARIO 574832] Verify that the item description in the sales line is prioritized correctly when both Item Reference and Item Variant are used. 
        Initialize();

        // [GIVEN] Create a new customer.
        CustomerNo := LibrarySales.CreateCustomerNo();

        // [GIVEN] Create first Item with Item Variant and Item Reference.
        CreateItemWithItemVariantAndItemReference(Item[1], ItemVariant[1], ItemReference[1], CustomerNo);

        // [GIVEN] Set description value in first Item Reference.
        if ItemReference[1].Description = '' then begin
            ItemReference[1].Validate(Description, ItemReference[1]."Reference No.");
            ItemReference[1].Modify(true);
        end;

        // [GIVEN] Create second Item with Item Variant and Item Reference.
        CreateItemWithItemVariantAndItemReference(Item[2], ItemVariant[2], ItemReference[2], CustomerNo);

        // [GIVEN] Create Sales Header with document type Invoice.
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);

        // [GIVEN] Create Two Sales Lines.
        CreateSalesLine(SalesLine[1], SalesHeader, Item[1]."No.");
        CreateSalesLine(SalesLine[2], SalesHeader, Item[2]."No.");

        // [WHEN] Both Item Variant and Item Reference have description values and their values are set in the sales line.
        ModifySalesLine(SalesLine[1], ItemVariant[1].Code, ItemReference[1]."Reference No.");

        // [THEN] Ensure that the Sales Line description is the same as the Item Reference description.
        Assert.AreEqual(SalesLine[1].Description, ItemReference[1].Description, DescriptionMustBeSameErr);

        // [WHEN] Both Item Variant and Item Reference have description values, but only the Item Variant value is set in the sales line.
        ModifySalesLine(SalesLine[1], ItemVariant[1].Code, '');

        // [THEN] Ensure that the Sales Line description is the same as the Item Variant description.
        Assert.AreEqual(SalesLine[1].Description, ItemVariant[1].Description, DescriptionMustBeSameErr);

        // [WHEN] Both Item Variant and Item Reference have description values, but both values are set blank in the sales line.
        ModifySalesLine(SalesLine[1], '', '');

        // [THEN] Ensure that the Sales Line description is the same as the Item description.
        Assert.AreEqual(SalesLine[1].Description, Item[1].Description, DescriptionMustBeSameErr);

        // [WHEN] Item Variant has a description value, but Item Reference has a blank description. However, both values are set in the sales line.
        ModifySalesLine(SalesLine[2], ItemVariant[2].Code, ItemReference[2]."Reference No.");

        // [THEN] Ensure that the Sales Line description is the same as the Item Variant description.
        Assert.AreEqual(SalesLine[2].Description, ItemVariant[2].Description, DescriptionMustBeSameErr);

        // [WHEN] Item Variant and Item Reference values are set blank in the sales line.
        ModifySalesLine(SalesLine[2], '', '');

        // [THEN] Ensure that the Sales Line description is the same as the Item description.
        Assert.AreEqual(SalesLine[2].Description, Item[2].Description, DescriptionMustBeSameErr);
    end;

    [Test]
    procedure VerifyDescriptionInSalesLineWhenItemReferenceAndItemVariantAndItemTranslationUsed()
    var
        Customer: Record Customer;
        Item: array[2] of Record Item;
        ItemReference: array[2] of Record "Item Reference";
        ItemTranslation: array[2] of Record "Item Translation";
        ItemVariant: array[2] of Record "Item Variant";
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        LanguageCode: Code[10];
    begin
        // [SCENARIO 574832] Verify that the Item description in the Sales line is prioritized correctly when Item Reference,Item Variant and Item Translation are used. 
        Initialize();

        // [GIVEN] Create a new Customer ansd set Languague code.
        LanguageCode := LibraryERM.GetAnyLanguageDifferentFromCurrent();
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Language Code", LanguageCode);
        Customer.Modify(true);

        // [GIVEN] Create first Item with Item Variant and Item Reference.
        CreateItemWithItemVariantAndItemReference(Item[1], ItemVariant[1], ItemReference[1], Customer."No.");

        // [GIVEN] Set description value in first Item Reference.
        if ItemReference[1].Description = '' then begin
            ItemReference[1].Validate(Description, ItemReference[1]."Reference No.");
            ItemReference[1].Modify(true);
        end;

        // [GIVEN] Create second Item with Item Variant and Item Reference.
        CreateItemWithItemVariantAndItemReference(Item[2], ItemVariant[2], ItemReference[2], Customer."No.");

        // [GIVEN] Create Multiple Item Translation.
        CreateItemTranslation(ItemTranslation[1], Item[1]."No.", LanguageCode, ItemVariant[1].Code);
        CreateItemTranslation(ItemTranslation[2], Item[2]."No.", LanguageCode, ItemVariant[2].Code);

        // [GIVEN] Create Sales Header with document type Invoice.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        // [GIVEN] Create Two Sales Lines.
        CreateSalesLine(SalesLine[1], SalesHeader, Item[1]."No.");
        CreateSalesLine(SalesLine[2], SalesHeader, Item[2]."No.");

        // [WHEN] Both Item Variant and Item Reference have description values and their values are set in the Sales line.
        ModifySalesLine(SalesLine[1], ItemVariant[1].Code, ItemReference[1]."Reference No.");

        // [THEN] Ensure that the Sales Line description is the same as the Item Reference description.
        Assert.AreEqual(SalesLine[1].Description, ItemReference[1].Description, DescriptionMustBeSameErr);

        // [WHEN] Both Item Variant and Item Reference have description values, but only the Item Variant value is set in the Sales line.
        ModifySalesLine(SalesLine[1], ItemVariant[1].Code, '');

        // [THEN] Ensure that the Sales Line description is the same as the Item Translation description.
        Assert.AreEqual(SalesLine[1].Description, ItemTranslation[1].Description, DescriptionMustBeSameErr);

        // [WHEN] Both Item Variant and Item Reference have description values, but both values are set blank in the Sales line.
        ModifySalesLine(SalesLine[1], '', '');

        // [THEN] Ensure that the Sales Line description is the same as the Item description.
        Assert.AreEqual(SalesLine[1].Description, Item[1].Description, DescriptionMustBeSameErr);

        // [WHEN] Item Variant has a description value, but Item Reference has a blank description. However, both values are set in the Sales line.
        ModifySalesLine(SalesLine[2], ItemVariant[2].Code, ItemReference[2]."Reference No.");

        // [THEN] Ensure that the Sales Line description is the same as the Item Translation description.
        Assert.AreEqual(SalesLine[2].Description, ItemTranslation[2].Description, DescriptionMustBeSameErr);

        // [WHEN] Item Variant and Item Reference values are set blank in the Sales line.
        ModifySalesLine(SalesLine[2], '', '');

        // [THEN] Ensure that the Sales Line description is the same as the Item description.
        Assert.AreEqual(SalesLine[2].Description, Item[2].Description, DescriptionMustBeSameErr);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ERM Item Reference Sales");

        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ERM Item Reference Sales");
        Commit();
        IsInitialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ERM Item Reference Sales");
    end;

    local procedure MockSalesLineForICRLookupSalesItem(var SalesLine: Record "Sales Line"; CustNo: Code[20]; ItemRefNo: Code[50])
    begin
        SalesLine.Init();
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."Sell-to Customer No." := CustNo;
        SalesLine."Item Reference No." := ItemRefNo;
    end;

    local procedure CreateSalesInvoiceOneLineWithLineTypeItem(var SalesLine: Record "Sales Line"; CustNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustNo);
        LibrarySales.CreateSalesLineSimple(SalesLine, SalesHeader);
        SalesLine.Validate(Type, SalesLine.Type::Item);
        SalesLine.Modify(true);
    end;

    local procedure EnqueueItemReferenceFields(ItemReference: Record "Item Reference")
    begin
        LibraryVariableStorage.Enqueue(ItemReference."Reference Type");
        LibraryVariableStorage.Enqueue(ItemReference."Reference Type No.");
        LibraryVariableStorage.Enqueue(ItemReference."Item No.");
    end;

    local procedure CreateItemWithItemVariantAndItemReference(var Item: Record Item; var ItemVariant: Record "Item Variant"; var ItemReference: Record "Item Reference"; CustomerNo: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate(Description, Item."No.");
        Item.Modify(true);

        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        LibraryItemReference.CreateItemReference(ItemReference, Item."No.", ItemVariant.Code, '', "Item Reference Type"::Customer, CustomerNo, LibraryUtility.GenerateRandomCode(ItemReference.FieldNo("Reference No."), Database::"Item Reference"));
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ItemNo: Code[20])
    begin
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandIntInRange(1, 10));
    end;

    local procedure ModifySalesLine(var SalesLine: Record "Sales Line"; VariantCode: Code[20]; ItemReferenceNo: Code[50])
    begin
        SalesLine.Validate("Variant Code", VariantCode);
        SalesLine.Validate("Item Reference No.", ItemReferenceNo);
        SalesLine.Modify(true);
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

