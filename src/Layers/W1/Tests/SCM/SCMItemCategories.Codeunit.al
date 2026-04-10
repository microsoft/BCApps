codeunit 137414 "SCM Item Categories"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [SCM] [Item Categories] [UI]
        IsInitialized := false;
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        CodeCoverageMgt: Codeunit "Code Coverage Mgt.";
        IncorrectParentErr: Label 'Category ''%1'' has an incorrect parent ''%2'', correct parent should be ''%3''   ';
        CyclicInheritanceErr: Label 'An item category cannot be a parent of itself or any of its children.';
        RenamingErr: Label 'Item Category ''%1'' should have been renamed to ''%2''';
        CategoryNotDeletedErr: Label 'Item Category ''%1'' should have been deleted.';
        CategoryWithChildrenDeleteErr: Label 'Item Category ''%1'' shouldn''t be deleted as it has children';
        DeleteQst: Label 'Delete %1?', Comment = '%1 - item category name';
        DeleteAttributesInheritedFromOldCategoryQst: Label 'Do you want to delete the attributes that are inherited from item category ''%1''?', Comment = '%1 - item category code';
        DeleteItemInheritedParentCategoryAttributesQst: Label 'One or more items belong to item category ''''%1'''', which is a child of item category ''''%2''''.\\Do you want to delete the inherited item attributes for the items in question?', Comment = '%1 - item category code';
        ChangingDefaultValueMsg: Label 'The new default value will not apply to items that use the current item category, ''''%1''''. It will only apply to new items.';
        CategoryStructureNotValidErr: Label 'The item category structure is not valid. The category %1 is a parent of itself or any of its children.', Comment = '%1 - Category Name';
        IsInitialized: Boolean;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Item Categories");
        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Item Categories");

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Item Categories");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChangingParent()
    var
        FirstItemCategory: Record "Item Category";
        LastItemCategory: Record "Item Category";
        ItemCategories: TestPage "Item Categories";
        ItemCategoryCard: TestPage "Item Category Card";
    begin
        Initialize();
        // [GIVEN] Category Hierarchy of 2 parent categories and 2 children for each
        CreateItemCategoryHierarchy(2);

        // [WHEN] The user
        ItemCategories.OpenEdit();
        ItemCategories.First();
        FirstItemCategory.Get(ItemCategories.Code.Value);
        ItemCategories.Last();
        LastItemCategory.Get(ItemCategories.Code.Value);
        ItemCategoryCard.Trap();
        ItemCategories.Edit().Invoke();
        ItemCategoryCard."Parent Category".SetValue(FirstItemCategory.Code);
        ItemCategoryCard.OK().Invoke();

        LastItemCategory.Find();
        FirstItemCategory.Find();
        // [THEN] The last item category parent and the tree view is updated
        Assert.AreEqual(
          FirstItemCategory.Code, LastItemCategory."Parent Category",
          StrSubstNo(IncorrectParentErr, LastItemCategory.Code, LastItemCategory."Parent Category", FirstItemCategory.Code));
        CheckItemCategoryTreePresentation();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChanginParentToEmpty()
    var
        SecondItemCategory: Record "Item Category";
        ItemCategories: TestPage "Item Categories";
        ItemCategoryCard: TestPage "Item Category Card";
    begin
        Initialize();
        // [GIVEN] Category Hierarchy of 2 parent categories and 2 children for each
        CreateItemCategoryHierarchy(2);

        // [WHEN] The user
        ItemCategories.OpenEdit();
        ExpandTreeStructure(ItemCategories);
        ItemCategories.First();
        ItemCategories.Next();
        SecondItemCategory.Get(ItemCategories.Code.Value);
        ItemCategoryCard.Trap();
        ItemCategories.Edit().Invoke();
        ItemCategoryCard."Parent Category".SetValue('');
        ItemCategoryCard.OK().Invoke();

        SecondItemCategory.Find();
        ItemCategories.GotoRecord(SecondItemCategory);
        // [THEN] The last item category parent and the tree view is updated
        Assert.AreEqual(
          SecondItemCategory.Code, ItemCategories.Code.Value,
          StrSubstNo(IncorrectParentErr, SecondItemCategory.Code, SecondItemCategory."Parent Category", ''));
        CheckItemCategoryTreePresentation();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAssignCategoryParentToItselfErr()
    var
        FirstItemCategory: Record "Item Category";
        ItemCategories: TestPage "Item Categories";
        ItemCategoryCard: TestPage "Item Category Card";
    begin
        Initialize();
        // [GIVEN] Category Hierarchy of 2 parent categories and 2 children for each
        CreateItemCategoryHierarchy(2);

        // [WHEN] The user try to set a parent category to be itself
        ItemCategories.OpenEdit();
        ItemCategories.First();
        FirstItemCategory.Get(ItemCategories.Code.Value);
        ItemCategoryCard.Trap();
        ItemCategories.Edit().Invoke();
        asserterror ItemCategoryCard."Parent Category".SetValue(FirstItemCategory.Code);
        Assert.ExpectedError(CyclicInheritanceErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAssignCategoryParentToChildErr()
    var
        FirstItemCategory: Record "Item Category";
        SecondItemCategory: Record "Item Category";
        ItemCategories: TestPage "Item Categories";
        ItemCategoryCard: TestPage "Item Category Card";
    begin
        Initialize();
        // [GIVEN] Category Hierarchy of 2 parent categories and 2 children for each
        CreateItemCategoryHierarchy(2);

        // [WHEN] The user try to set a parent category to one of its children
        ItemCategories.OpenEdit();
        ExpandTreeStructure(ItemCategories);
        ItemCategories.First();
        FirstItemCategory.Get(ItemCategories.Code.Value);
        ItemCategories.Next();
        SecondItemCategory.Get(ItemCategories.Code.Value);
        ItemCategories.First();
        ItemCategoryCard.Trap();
        ItemCategories.Edit().Invoke();
        asserterror ItemCategoryCard."Parent Category".SetValue(SecondItemCategory.Code);
        Assert.ExpectedError(CyclicInheritanceErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMultiLevelHierarchy()
    var
        FirstItemCategory: Record "Item Category";
        SecondItemCategory: Record "Item Category";
        ItemCategories: TestPage "Item Categories";
        ItemCategoryCard: TestPage "Item Category Card";
    begin
        Initialize();
        // [GIVEN] Category Hierarchy of 2 parent categories and 2 children for each
        CreateItemCategoryHierarchy(6);

        // [WHEN] The user
        ItemCategories.OpenEdit();
        ItemCategories.First();
        FirstItemCategory.Get(ItemCategories.Code.Value);
        ItemCategories.Last();
        SecondItemCategory.Get(ItemCategories.Code.Value);
        ItemCategoryCard.Trap();
        ItemCategories.Edit().Invoke();
        ItemCategoryCard."Parent Category".SetValue(FirstItemCategory.Code);
        ItemCategoryCard.OK().Invoke();

        SecondItemCategory.Find();
        FirstItemCategory.Find();
        // [THEN] The last item category parent and the tree view is updated
        Assert.AreEqual(
          FirstItemCategory.Code, SecondItemCategory."Parent Category",
          StrSubstNo(IncorrectParentErr, SecondItemCategory.Code, SecondItemCategory."Parent Category", FirstItemCategory.Code));
        CheckItemCategoryTreePresentation();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRenameItemCategory()
    var
        LastItemCategory: Record "Item Category";
        ItemCategories: TestPage "Item Categories";
        NewItemCategoryCode: Code[10];
    begin
        Initialize();
        // [GIVEN] Category Hierarchy of 2 parent categories and 2 children for each
        NewItemCategoryCode := LibraryUtility.GenerateGUID();
        CreateItemCategoryHierarchy(2);
        ItemCategories.OpenEdit();
        ItemCategories.Last();
        LastItemCategory.Get(ItemCategories.Code.Value);
        ItemCategories.Close();

        // [WHEN] The user try to set a parent category to one of its children
        LastItemCategory.Rename(NewItemCategoryCode);

        // [THEN] the last item should be shown at the beginning of the list and the tree structure should be reserved
        ItemCategories.OpenEdit();
        ItemCategories.First();
        Assert.AreEqual(
          NewItemCategoryCode, ItemCategories.Code.Value, StrSubstNo(RenamingErr, ItemCategories.Code.Value, NewItemCategoryCode));
        CheckItemCategoryTreePresentation();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestDeleteWithoutChildrenFromCard()
    var
        ItemCategory: Record "Item Category";
        ItemCategories: TestPage "Item Categories";
        ItemCategoryCard: TestPage "Item Category Card";
    begin
        Initialize();
        // [GIVEN] Category Hierarchy of 2 parent categories and 2 children for each
        CreateItemCategoryHierarchy(2);

        // [WHEN] The user delete an item category from the card
        ItemCategories.OpenEdit();
        ExpandTreeStructure(ItemCategories);
        ItemCategories.Last();
        ItemCategory.Get(ItemCategories.Code.Value);
        ItemCategoryCard.Trap();
        ItemCategories.Edit().Invoke();
        LibraryVariableStorage.Enqueue(StrSubstNo(DeleteQst, ItemCategories.Code));
        LibraryVariableStorage.Enqueue(true);
        ItemCategoryCard.Delete.Invoke();

        // [THEN] the item category should be deleted and the tree structure should be reserved
        Assert.IsFalse(ItemCategories.GotoRecord(ItemCategory), StrSubstNo(CategoryNotDeletedErr, ItemCategory.Code));
        CheckItemCategoryTreePresentation();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteWithChildrenErrFromCard()
    var
        ItemCategory: Record "Item Category";
        ItemCategories: TestPage "Item Categories";
        ItemCategoryCard: TestPage "Item Category Card";
    begin
        Initialize();
        // [GIVEN] Category Hierarchy of 2 parent categories and 2 children for each
        CreateItemCategoryHierarchy(2);

        // [WHEN] The user delete an item category from the card
        ItemCategories.OpenEdit();
        ItemCategories.First();
        ItemCategory.Get(ItemCategories.Code.Value);
        ItemCategoryCard.Trap();
        ItemCategories.Edit().Invoke();
        Assert.IsFalse(ItemCategoryCard.Delete.Enabled(), StrSubstNo(CategoryWithChildrenDeleteErr, ItemCategory.Code));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAssignAttributeToCategory()
    var
        FirstItemCategory: Record "Item Category";
        FirstItemAttribute: Record "Item Attribute";
        LastItemAttribute: Record "Item Attribute";
        FirstItemAttributeValue: Record "Item Attribute Value";
        ItemCategories: TestPage "Item Categories";
        ItemCategoryCard: TestPage "Item Category Card";
    begin
        Initialize();
        // [GIVEN] Category Hierarchy of 2 parent categories and 2 children for each
        CreateItemCategoryHierarchy(2);
        CreateTestItemAttributes();

        // [WHEN]  assign 2 item attributes (option and non option) to the the first category
        FirstItemCategory.FindFirst();
        FirstItemAttribute.FindFirst();
        LastItemAttribute.FindLast();

        FirstItemAttributeValue.SetRange("Attribute ID", FirstItemAttribute.ID);
        FirstItemAttributeValue.FindFirst();

        AssignItemAttributeValueToCategory(FirstItemCategory, FirstItemAttribute, FirstItemAttributeValue.Value);
        AssignItemAttributeValueToCategory(FirstItemCategory, LastItemAttribute, '');

        // [THEN] the item attribute should show in the card and in the factbox
        ItemCategories.OpenView();
        ItemCategories.ItemAttributesFactbox.First();
        ItemCategories.ItemAttributesFactbox.Attribute.AssertEquals(FirstItemAttribute.Name);
        ItemCategories.ItemAttributesFactbox.Value.AssertEquals(FirstItemAttributeValue.Value);
        ItemCategories.ItemAttributesFactbox.Last();
        ItemCategories.ItemAttributesFactbox.Attribute.AssertEquals(LastItemAttribute.Name);
        ItemCategories.ItemAttributesFactbox.Value.AssertEquals('');

        ItemCategories.First();
        ItemCategoryCard.Trap();
        ItemCategories.Edit().Invoke();
        ItemCategoryCard.Attributes.First();
        Assert.AreEqual(FirstItemAttribute.Name, ItemCategoryCard.Attributes."Attribute Name".Value, '');
        Assert.AreEqual(FirstItemAttributeValue.Value, ItemCategoryCard.Attributes.Value.Value, '');
        ItemCategoryCard.Attributes.Next();
        Assert.AreEqual(LastItemAttribute.Name, ItemCategoryCard.Attributes."Attribute Name".Value, '');
        Assert.AreEqual('', ItemCategoryCard.Attributes.Value.Value, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteAttributeFromCategory()
    var
        FirstItemCategory: Record "Item Category";
        FirstItemAttribute: Record "Item Attribute";
        LastItemAttribute: Record "Item Attribute";
        FirstItemAttributeValue: Record "Item Attribute Value";
        ItemCategories: TestPage "Item Categories";
        ItemCategoryCard: TestPage "Item Category Card";
    begin
        Initialize();
        // [GIVEN] Category Hierarchy of 2 parent categories and 2 children for each
        CreateItemCategoryHierarchy(2);
        CreateTestItemAttributes();

        // [WHEN]  assign 2 item attributes (option and non option) to the the first category and the user deletes first one
        FirstItemCategory.FindFirst();
        FirstItemAttribute.FindFirst();
        LastItemAttribute.FindLast();

        FirstItemAttributeValue.SetRange("Attribute ID", FirstItemAttribute.ID);
        FirstItemAttributeValue.FindFirst();

        AssignItemAttributeValueToCategory(FirstItemCategory, FirstItemAttribute, FirstItemAttributeValue.Value);
        AssignItemAttributeValueToCategory(FirstItemCategory, LastItemAttribute, '');
        FirstItemAttributeValue.Delete();

        // [THEN] the item attribute should show in the card and in the factbox
        ItemCategories.OpenView();
        ItemCategories.ItemAttributesFactbox.First();
        ItemCategories.ItemAttributesFactbox.Attribute.AssertEquals(LastItemAttribute.Name);
        ItemCategories.ItemAttributesFactbox.Value.AssertEquals('');

        ItemCategories.First();
        ItemCategoryCard.Trap();
        ItemCategories.Edit().Invoke();
        ItemCategoryCard.Attributes.First();
        Assert.AreEqual(LastItemAttribute.Name, ItemCategoryCard.Attributes."Attribute Name".Value, '');
        Assert.AreEqual('', ItemCategoryCard.Attributes.Value.Value, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteCategoryWithAttributes()
    var
        FirstItemCategory: Record "Item Category";
        FirstItemAttribute: Record "Item Attribute";
        LastItemAttribute: Record "Item Attribute";
        FirstItemAttributeValue: Record "Item Attribute Value";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
    begin
        Initialize();
        // [GIVEN] Category Hierarchy of 2 parent categories and 2 children for each
        CreateItemCategoryHierarchy(1);
        CreateTestItemAttributes();

        // [WHEN]  assign 2 item attributes (option and non option) to the the first category then delete the category
        FirstItemCategory.FindFirst();
        FirstItemAttribute.FindFirst();
        LastItemAttribute.FindLast();

        FirstItemAttributeValue.SetRange("Attribute ID", FirstItemAttribute.ID);
        FirstItemAttributeValue.FindFirst();

        AssignItemAttributeValueToCategory(FirstItemCategory, FirstItemAttribute, FirstItemAttributeValue.Value);
        AssignItemAttributeValueToCategory(FirstItemCategory, LastItemAttribute, '');

        FirstItemCategory.Delete(true);

        // [THEN] the item attribute value mapping should be cleared
        FilterItemAttributeValueMapping(ItemAttributeValueMapping, DATABASE::"Item Category", FirstItemCategory.Code, 0);
        Assert.RecordIsEmpty(ItemAttributeValueMapping);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInheritingAttributesFromParent()
    var
        FirstItemCategory: Record "Item Category";
        ChildItemCategory: Record "Item Category";
        FirstItemAttribute: Record "Item Attribute";
        LastItemAttribute: Record "Item Attribute";
        FirstItemAttributeValue: Record "Item Attribute Value";
        ItemCategories: TestPage "Item Categories";
        ItemCategoryCard: TestPage "Item Category Card";
    begin
        Initialize();
        // [GIVEN] Category Hierarchy of 2 parent categories and 2 children for each
        CreateItemCategoryHierarchy(2);
        CreateTestItemAttributes();

        // [WHEN]  assign 1 item attribute the first category and 1 attribute to the second one
        FirstItemCategory.FindFirst();
        ChildItemCategory.SetRange("Parent Category", FirstItemCategory.Code);
        ChildItemCategory.FindFirst();
        FirstItemAttribute.FindFirst();
        LastItemAttribute.FindLast();

        FirstItemAttributeValue.SetRange("Attribute ID", FirstItemAttribute.ID);
        FirstItemAttributeValue.FindFirst();

        AssignItemAttributeValueToCategory(FirstItemCategory, FirstItemAttribute, FirstItemAttributeValue.Value);
        AssignItemAttributeValueToCategory(ChildItemCategory, LastItemAttribute, '');

        // [THEN] the inherited attributes should show in the card and in the factbox
        ItemCategories.OpenView();
        ExpandTreeStructure(ItemCategories);
        ItemCategories.GotoRecord(ChildItemCategory);
        ItemCategories.ItemAttributesFactbox.First();
        ItemCategories.ItemAttributesFactbox.Attribute.AssertEquals(FirstItemAttribute.Name);
        ItemCategories.ItemAttributesFactbox.Value.AssertEquals(FirstItemAttributeValue.Value);

        ItemCategories.ItemAttributesFactbox.Last();
        ItemCategories.ItemAttributesFactbox.Attribute.AssertEquals(LastItemAttribute.Name);
        ItemCategories.ItemAttributesFactbox.Value.AssertEquals('');

        ItemCategoryCard.OpenView();
        ItemCategoryCard.GotoRecord(ChildItemCategory);
        ItemCategoryCard.Attributes.First();
        Assert.AreEqual(FirstItemAttribute.Name, ItemCategoryCard.Attributes."Attribute Name".Value, '');
        Assert.AreEqual(FirstItemAttributeValue.Value, ItemCategoryCard.Attributes.Value.Value, '');
        Assert.AreEqual(FirstItemCategory.Code, ItemCategoryCard.Attributes."Inherited-From Key Value".Value, '');
        ItemCategoryCard.Attributes.Last();
        Assert.AreEqual(LastItemAttribute.Name, ItemCategoryCard.Attributes."Attribute Name".Value, '');
        Assert.AreEqual('', ItemCategoryCard.Attributes.Value.Value, '');
        Assert.AreEqual('', ItemCategoryCard.Attributes."Inherited-From Key Value".Value, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestChangingParentWithAttributes()
    var
        FirstItemCategory: Record "Item Category";
        SecondItemCategory: Record "Item Category";
        ChildItemCategory: Record "Item Category";
        FirstItemAttribute: Record "Item Attribute";
        LastItemAttribute: Record "Item Attribute";
        FirstItemAttributeValue: Record "Item Attribute Value";
        ItemCategoryCard: TestPage "Item Category Card";
    begin
        Initialize();
        // [GIVEN] Category Hierarchy of 2 parent categories and 2 children for each
        CreateItemCategoryHierarchy(2);
        CreateTestItemAttributes();

        // [WHEN]  assign 1 item attribute the first category and 1 attribute to the second one
        FirstItemCategory.FindFirst();
        SecondItemCategory.Find('-');
        SecondItemCategory.Next();
        ChildItemCategory.SetRange("Parent Category", FirstItemCategory.Code);
        ChildItemCategory.FindFirst();
        FirstItemAttribute.FindFirst();
        LastItemAttribute.FindLast();

        FirstItemAttributeValue.SetRange("Attribute ID", FirstItemAttribute.ID);
        FirstItemAttributeValue.FindFirst();

        AssignItemAttributeValueToCategory(FirstItemCategory, FirstItemAttribute, FirstItemAttributeValue.Value);
        AssignItemAttributeValueToCategory(SecondItemCategory, LastItemAttribute, '');

        // [THEN] the inherited attributes should be updated in the card when you change the parent
        ItemCategoryCard.OpenEdit();
        ItemCategoryCard.GotoRecord(ChildItemCategory);
        ItemCategoryCard.Attributes.First();
        Assert.AreEqual(FirstItemAttribute.Name, ItemCategoryCard.Attributes."Attribute Name".Value, '');
        Assert.AreEqual(FirstItemCategory.Code, ItemCategoryCard.Attributes."Inherited-From Key Value".Value, '');

        LibraryVariableStorage.Enqueue(
          StrSubstNo(DeleteItemInheritedParentCategoryAttributesQst, ItemCategoryCard.Code.Value, ItemCategoryCard."Parent Category".Value));
        LibraryVariableStorage.Enqueue(true);
        ItemCategoryCard."Parent Category".SetValue(SecondItemCategory.Code);
        ItemCategoryCard.Attributes.First();
        Assert.AreEqual(LastItemAttribute.Name, ItemCategoryCard.Attributes."Attribute Name".Value, '');
        Assert.AreEqual(SecondItemCategory.Code, ItemCategoryCard.Attributes."Inherited-From Key Value".Value, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletingAttributeOnParentCategoryDeletesItemAttributes()
    var
        ParentItemCategory: Record "Item Category";
        ChildItemCategory: Record "Item Category";
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        Item: Record Item;
        ItemAttributeManagement: Codeunit "Item Attribute Management";
        IsItemWithAttrFound: Boolean;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 229088] When you delete item attribute on the parent category, the attribute on an item belonging to the child category is also deleted.

        // [GIVEN] Parent "PC" and child "CC" item categories.
        CreateItemCategoryHierarchy(2);
        ParentItemCategory.SetRange("Parent Category", '');
        ParentItemCategory.FindFirst();
        ChildItemCategory.SetRange("Parent Category", ParentItemCategory.Code);
        ChildItemCategory.FindFirst();

        // [GIVEN] Item attribute "A" is assigned to the parent category "PC".
        LibraryInventory.CreateItemAttributeWithValue(
          ItemAttribute, ItemAttributeValue, ItemAttribute.Type::Decimal, Format(LibraryRandom.RandDec(10, 2)));
        AssignItemAttributeValueToCategory(ParentItemCategory, ItemAttribute, ItemAttributeValue.Value);

        // [GIVEN] Item with the child category "CC".
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Category Code", ChildItemCategory.Code);
        Item.Modify(true);

        // [WHEN] Run "SearchCategoryItemsForAttribute" function in Codeunit 7500 with "PC" and "A" in parameters in order to find out if "A" is assigned to items with the child category.
        IsItemWithAttrFound :=
          ItemAttributeManagement.SearchCategoryItemsForAttribute(ParentItemCategory.Code, ItemAttribute.ID);

        // [THEN] Item with attribute "A" and child category is found.
        Assert.IsTrue(IsItemWithAttrFound, 'The attribute of item that belongs to the child category will not be deleted.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAssigningCategoryToItem()
    var
        FirstItemCategory: Record "Item Category";
        ChildItemCategory: Record "Item Category";
        FirstItemAttribute: Record "Item Attribute";
        LastItemAttribute: Record "Item Attribute";
        FirstItemAttributeValue: Record "Item Attribute Value";
        Item: Record Item;
        ItemCard: TestPage "Item Card";
        LastItemAttributeValue: Text;
    begin
        Initialize();
        // [GIVEN] Category Hierarchy of 2 parent categories and 2 children for each
        CreateItemCategoryHierarchy(2);
        CreateTestItemAttributes();
        LibraryInventory.CreateItem(Item);
        LastItemAttributeValue := LibraryUtility.GenerateGUID();
        LibraryNotificationMgt.DisableAllNotifications();

        // [WHEN]  assign 1 item attribute the first category and 1 attribute to the second one
        FirstItemCategory.FindFirst();
        ChildItemCategory.SetRange("Parent Category", FirstItemCategory.Code);
        ChildItemCategory.FindFirst();
        FirstItemAttribute.FindFirst();
        LastItemAttribute.FindLast();

        FirstItemAttributeValue.SetRange("Attribute ID", FirstItemAttribute.ID);
        FirstItemAttributeValue.FindFirst();

        AssignItemAttributeValueToCategory(FirstItemCategory, FirstItemAttribute, FirstItemAttributeValue.Value);
        AssignItemAttributeValueToCategory(ChildItemCategory, LastItemAttribute, LastItemAttributeValue);

        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);
        ItemCard."Item Category Code".SetValue(ChildItemCategory.Code);

        // [THEN] the inherited attributes should show in the card and in the factbox
        ItemCard.ItemAttributesFactbox.First();
        ItemCard.ItemAttributesFactbox.Attribute.AssertEquals(FirstItemAttribute.Name);
        ItemCard.ItemAttributesFactbox.Value.AssertEquals(FirstItemAttributeValue.Value);
        ItemCard.ItemAttributesFactbox.Next();
        ItemCard.ItemAttributesFactbox.Attribute.AssertEquals(LastItemAttribute.Name);
        ItemCard.ItemAttributesFactbox.Value.AssertEquals(LastItemAttributeValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAssigningCategoryToItemWithExistingAttributes()
    var
        FirstItemCategory: Record "Item Category";
        FirstItemAttribute: Record "Item Attribute";
        LastItemAttribute: Record "Item Attribute";
        FirstItemAttributeValue: Record "Item Attribute Value";
        LastItemAttributeValue: Record "Item Attribute Value";
        Item: Record Item;
        ItemCard: TestPage "Item Card";
    begin
        Initialize();
        // [GIVEN] Category Hierarchy of 2 parent categories and 2 children for each
        CreateItemCategoryHierarchy(2);
        CreateTestItemAttributes();
        LibraryInventory.CreateItem(Item);
        LibraryNotificationMgt.DisableAllNotifications();

        // [WHEN]  assign 1 item attribute the first category and 1 attribute to the second one
        FirstItemCategory.FindFirst();
        FirstItemAttribute.FindFirst();
        LastItemAttribute.FindLast();

        FirstItemAttributeValue.SetRange("Attribute ID", FirstItemAttribute.ID);
        FirstItemAttributeValue.FindFirst();

        LastItemAttributeValue.SetRange("Attribute ID", FirstItemAttribute.ID);
        LastItemAttributeValue.FindLast();

        AssignItemAttributeValueToCategory(FirstItemCategory, FirstItemAttribute, FirstItemAttributeValue.Value);
        AssignItemAttributeValueToCategory(FirstItemCategory, LastItemAttribute, '');

        SetItemAttributeValue(Item, LastItemAttributeValue);

        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);
        ItemCard."Item Category Code".SetValue(FirstItemCategory.Code);

        // [THEN] the inherited attributes should show in the card and in the factbox
        ItemCard.ItemAttributesFactbox.First();
        ItemCard.ItemAttributesFactbox.Attribute.AssertEquals(FirstItemAttribute.Name);
        ItemCard.ItemAttributesFactbox.Value.AssertEquals(LastItemAttributeValue.Value);
        ItemCard.ItemAttributesFactbox.Next();
        ItemCard.ItemAttributesFactbox.Attribute.AssertEquals(LastItemAttribute.Name);
        ItemCard.ItemAttributesFactbox.Value.AssertEquals('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAddingAttributeToCategoryWithItems()
    var
        FirstItemCategory: Record "Item Category";
        FirstItemAttribute: Record "Item Attribute";
        LastItemAttribute: Record "Item Attribute";
        FirstItemAttributeValue: Record "Item Attribute Value";
        Item: array[3] of Record Item;
        ItemCard: TestPage "Item Card";
        LastItemAttributeValue: Text;
        i: Integer;
    begin
        Initialize();
        // [FEATURE] [Item Attribute]
        // [SCENARIO 227028] Item attribute values assigned to item category is propagated to all items with this category.

        // [GIVEN] Category Hierarchy of 2 parent categories and 2 children for each
        CreateItemCategoryHierarchy(2);
        CreateTestItemAttributes();
        LastItemAttributeValue := LibraryUtility.GenerateGUID();
        LibraryNotificationMgt.DisableAllNotifications();

        // [GIVEN] 3 items "I1", "I2", "I3".
        for i := 1 to ArrayLen(Item) do
            LibraryInventory.CreateItem(Item[i]);

        // [GIVEN] Item category "C" with attribute "X1" and attribute value "Y1".
        FirstItemCategory.FindFirst();
        FirstItemAttribute.FindFirst();
        LastItemAttribute.FindLast();

        FirstItemAttributeValue.SetRange("Attribute ID", FirstItemAttribute.ID);
        FirstItemAttributeValue.FindFirst();

        AssignItemAttributeValueToCategory(FirstItemCategory, FirstItemAttribute, FirstItemAttributeValue.Value);

        // [GIVEN] Category "C" is assigned to all items.
        for i := 1 to ArrayLen(Item) do begin
            Item[i].Validate("Item Category Code", FirstItemCategory.Code);
            Item[i].Modify(true);
        end;

        // [WHEN] Assign attribute "X2" with value "Y2" to item category "C".
        AssignItemAttributeValueToCategory(FirstItemCategory, LastItemAttribute, LastItemAttributeValue);

        // [THEN] Both attributes "X1" and "X2" with their values "Y1" and "Y2" are assigned to items "I1", "I2", "I3".
        ItemCard.OpenView();
        for i := 1 to ArrayLen(Item) do begin
            ItemCard.GotoRecord(Item[i]);
            ItemCard.ItemAttributesFactbox.First();
            ItemCard.ItemAttributesFactbox.Attribute.AssertEquals(FirstItemAttribute.Name);
            ItemCard.ItemAttributesFactbox.Value.AssertEquals(FirstItemAttributeValue.Value);
            ItemCard.ItemAttributesFactbox.Next();
            ItemCard.ItemAttributesFactbox.Attribute.AssertEquals(LastItemAttribute.Name);
            ItemCard.ItemAttributesFactbox.Value.AssertEquals(LastItemAttributeValue);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletingAttributeFromCategoryWithItems()
    var
        FirstItemCategory: Record "Item Category";
        FirstItemAttribute: Record "Item Attribute";
        LastItemAttribute: Record "Item Attribute";
        FirstItemAttributeValue: Record "Item Attribute Value";
        Item: Record Item;
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemAttributeManagement: Codeunit "Item Attribute Management";
        ItemCard: TestPage "Item Card";
        LastItemAttributeValue: Text;
    begin
        Initialize();
        // [GIVEN] Category Hierarchy of 2 parent categories and 2 children for each
        CreateItemCategoryHierarchy(2);
        CreateTestItemAttributes();
        LastItemAttributeValue := LibraryUtility.GenerateGUID();
        LibraryInventory.CreateItem(Item);
        LibraryNotificationMgt.DisableAllNotifications();

        // [WHEN]  assign 1 item attribute the first category and 1 attribute to the second one
        FirstItemCategory.FindFirst();
        FirstItemAttribute.FindFirst();
        LastItemAttribute.FindLast();

        FirstItemAttributeValue.SetRange("Attribute ID", FirstItemAttribute.ID);
        FirstItemAttributeValue.FindFirst();

        AssignItemAttributeValueToCategory(FirstItemCategory, FirstItemAttribute, FirstItemAttributeValue.Value);
        AssignItemAttributeValueToCategory(FirstItemCategory, LastItemAttribute, LastItemAttributeValue);

        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);
        ItemCard."Item Category Code".SetValue(FirstItemCategory.Code);
        ItemCard.Close();

        FilterItemAttributeValueMapping(ItemAttributeValueMapping, DATABASE::"Item Category", FirstItemCategory.Code, 0);
        ItemAttributeValueMapping.DeleteAll();
        ItemAttributeManagement.DeleteCategoryItemsAttributeValueMapping(FirstItemAttributeValue, FirstItemCategory.Code);

        // [THEN] the inherited attributes should show in the card and in the factbox
        ItemCard.OpenView();
        ItemCard.GotoRecord(Item);
        ItemCard.ItemAttributesFactbox.First();
        ItemCard.ItemAttributesFactbox.Attribute.AssertEquals(LastItemAttribute.Name);
        ItemCard.ItemAttributesFactbox.Value.AssertEquals(LastItemAttributeValue);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestChangingCategoryAttributeDefaultValue()
    var
        FirstItemCategory: Record "Item Category";
        FirstItemAttribute: Record "Item Attribute";
        LastItemAttribute: Record "Item Attribute";
        FirstItemAttributeValue: Record "Item Attribute Value";
        FirstItem: Record Item;
        SecondItem: Record Item;
        ItemCard: TestPage "Item Card";
        ItemCategoryCard: TestPage "Item Category Card";
        LastItemAttributeValue: Text;
    begin
        Initialize();
        // [GIVEN] Category Hierarchy of 2 parent categories and 2 children for each
        CreateItemCategoryHierarchy(2);
        CreateTestItemAttributes();
        LibraryInventory.CreateItem(FirstItem);
        LibraryInventory.CreateItem(SecondItem);
        LastItemAttributeValue := LibraryUtility.GenerateGUID();
        LibraryNotificationMgt.DisableAllNotifications();

        // [WHEN]  assign 1 item attribute the first category and 1 attribute to the second one
        FirstItemCategory.FindFirst();
        FirstItemAttribute.FindFirst();
        LastItemAttribute.FindLast();

        FirstItemAttributeValue.SetRange("Attribute ID", FirstItemAttribute.ID);
        FirstItemAttributeValue.FindFirst();

        AssignItemAttributeValueToCategory(FirstItemCategory, FirstItemAttribute, FirstItemAttributeValue.Value);
        AssignItemAttributeValueToCategory(FirstItemCategory, LastItemAttribute, '');

        ItemCard.OpenEdit();
        ItemCard.GotoRecord(FirstItem);
        ItemCard."Item Category Code".SetValue(FirstItemCategory.Code);
        ItemCard.Close();

        ItemCategoryCard.OpenEdit();
        ItemCategoryCard.GotoRecord(FirstItemCategory);
        ItemCategoryCard.Attributes.Last();
        LibraryVariableStorage.Enqueue(StrSubstNo(ChangingDefaultValueMsg, FirstItemCategory.Code));
        ItemCategoryCard.Attributes.Value.SetValue(LastItemAttributeValue);
        ItemCategoryCard.Close();

        ItemCard.OpenEdit();
        ItemCard.GotoRecord(SecondItem);
        ItemCard."Item Category Code".SetValue(FirstItemCategory.Code);
        ItemCard.Close();

        // [THEN] the inherited attributes should show in the card and in the factbox
        ItemCard.OpenView();
        ItemCard.GotoRecord(FirstItem);
        ItemCard.ItemAttributesFactbox.First();
        ItemCard.ItemAttributesFactbox.Attribute.AssertEquals(FirstItemAttribute.Name);
        ItemCard.ItemAttributesFactbox.Value.AssertEquals(FirstItemAttributeValue.Value);
        ItemCard.ItemAttributesFactbox.Next();
        ItemCard.ItemAttributesFactbox.Attribute.AssertEquals(LastItemAttribute.Name);
        ItemCard.ItemAttributesFactbox.Value.AssertEquals('');

        ItemCard.GotoRecord(SecondItem);
        ItemCard.ItemAttributesFactbox.First();
        ItemCard.ItemAttributesFactbox.Attribute.AssertEquals(FirstItemAttribute.Name);
        ItemCard.ItemAttributesFactbox.Value.AssertEquals(FirstItemAttributeValue.Value);
        ItemCard.ItemAttributesFactbox.Next();
        ItemCard.ItemAttributesFactbox.Attribute.AssertEquals(LastItemAttribute.Name);
        ItemCard.ItemAttributesFactbox.Value.AssertEquals(LastItemAttributeValue);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestChangingCategoryParentWithItems()
    var
        ChildItemCategory: Record "Item Category";
        FirstParentItemCategory: Record "Item Category";
        SecondParentItemCategory: Record "Item Category";
        FirstItemAttribute: Record "Item Attribute";
        LastItemAttribute: Record "Item Attribute";
        FirstItemAttributeValue: Record "Item Attribute Value";
        Item: Record Item;
        ItemCard: TestPage "Item Card";
        ItemCategoryCard: TestPage "Item Category Card";
        LastItemAttributeValue: Text;
    begin
        Initialize();
        // [GIVEN] Category Hierarchy of 2 parent categories and 2 children for each
        CreateItemCategoryHierarchy(2);
        CreateTestItemAttributes();
        LibraryInventory.CreateItem(Item);
        LastItemAttributeValue := LibraryUtility.GenerateGUID();
        LibraryNotificationMgt.DisableAllNotifications();

        // [WHEN]  assign 1 item attribute the first category and 1 attribute to the second one
        FirstParentItemCategory.FindFirst();
        SecondParentItemCategory.Find('-');
        SecondParentItemCategory.Next();
        ChildItemCategory.SetRange("Parent Category", FirstParentItemCategory.Code);
        ChildItemCategory.FindFirst();
        FirstItemAttribute.FindFirst();
        LastItemAttribute.FindLast();

        FirstItemAttributeValue.SetRange("Attribute ID", FirstItemAttribute.ID);
        FirstItemAttributeValue.FindFirst();

        AssignItemAttributeValueToCategory(FirstParentItemCategory, FirstItemAttribute, FirstItemAttributeValue.Value);
        AssignItemAttributeValueToCategory(SecondParentItemCategory, LastItemAttribute, LastItemAttributeValue);

        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);
        ItemCard."Item Category Code".SetValue(ChildItemCategory.Code);
        ItemCard.Close();

        ItemCategoryCard.OpenEdit();
        ItemCategoryCard.GotoRecord(ChildItemCategory);
        LibraryVariableStorage.Enqueue(
          StrSubstNo(DeleteItemInheritedParentCategoryAttributesQst, ChildItemCategory.Code, FirstParentItemCategory.Code));
        LibraryVariableStorage.Enqueue(true);
        ItemCategoryCard."Parent Category".SetValue(SecondParentItemCategory.Code);
        ItemCategoryCard.Close();

        // [THEN] the inherited attributes should show in the card and in the factbox
        ItemCard.OpenView();
        ItemCard.GotoRecord(Item);
        ItemCard.ItemAttributesFactbox.First();
        ItemCard.ItemAttributesFactbox.Attribute.AssertEquals(LastItemAttribute.Name);
        ItemCard.ItemAttributesFactbox.Value.AssertEquals(LastItemAttributeValue);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestChangingItemCategory()
    var
        FirstItemCategory: Record "Item Category";
        SecondItemCategory: Record "Item Category";
        FirstItemAttribute: Record "Item Attribute";
        LastItemAttribute: Record "Item Attribute";
        FirstItemAttributeValue: Record "Item Attribute Value";
        FirstItem: Record Item;
        SecondItem: Record Item;
        ItemCard: TestPage "Item Card";
        LastItemAttributeValue: Text;
    begin
        Initialize();
        // [GIVEN] Category Hierarchy of 2 parent categories and 2 children for each
        CreateItemCategoryHierarchy(2);
        CreateTestItemAttributes();
        LibraryInventory.CreateItem(FirstItem);
        LibraryInventory.CreateItem(SecondItem);
        LastItemAttributeValue := LibraryUtility.GenerateGUID();
        LibraryNotificationMgt.DisableAllNotifications();

        // [WHEN]  assign 1 item attribute the first category and 1 attribute to the second one
        FirstItemCategory.FindFirst();
        SecondItemCategory.Find('-');
        SecondItemCategory.Next();
        FirstItemAttribute.FindFirst();
        LastItemAttribute.FindLast();

        FirstItemAttributeValue.SetRange("Attribute ID", FirstItemAttribute.ID);
        FirstItemAttributeValue.FindFirst();

        AssignItemAttributeValueToCategory(FirstItemCategory, FirstItemAttribute, FirstItemAttributeValue.Value);
        AssignItemAttributeValueToCategory(SecondItemCategory, LastItemAttribute, LastItemAttributeValue);

        ItemCard.OpenEdit();
        ItemCard.GotoRecord(FirstItem);
        ItemCard."Item Category Code".SetValue(FirstItemCategory.Code);
        ItemCard.Close();

        ItemCard.OpenEdit();
        ItemCard.GotoRecord(FirstItem);
        LibraryVariableStorage.Enqueue(StrSubstNo(DeleteAttributesInheritedFromOldCategoryQst, FirstItemCategory.Code));
        LibraryVariableStorage.Enqueue(true);
        ItemCard."Item Category Code".SetValue(SecondItemCategory.Code);
        ItemCard.ItemAttributesFactbox.Attribute.AssertEquals(LastItemAttribute.Name);
        ItemCard.ItemAttributesFactbox.Value.AssertEquals(LastItemAttributeValue);
        ItemCard.Close();

        // [THEN] the inherited attributes should show in the card and in the factbox
        ItemCard.OpenView();
        ItemCard.GotoRecord(FirstItem);
        ItemCard.ItemAttributesFactbox.First();
        ItemCard.ItemAttributesFactbox.Attribute.AssertEquals(LastItemAttribute.Name);
        ItemCard.ItemAttributesFactbox.Value.AssertEquals(LastItemAttributeValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAssignAttributesToItemAfterValidationItemCategory()
    var
        Item: Record Item;
        TempItemAttributeValue: Record "Item Attribute Value" temporary;
        ItemCategoryCode: Code[20];
        ItemAttributeID: array[2] of Integer;
    begin
        Initialize();
        // [SCENARIO 212490] Item Attributes must be coppied from Item Category to Item after validation of "Item Category Code"

        // [GIVEN] "Item Category" - "IC" with attributes "ATT1" and "ATT2"
        ItemCategoryCode := CreateItemCategoryWithItemAttributes(ItemAttributeID);

        // [GIVEN] Item without Item Category
        LibraryInventory.CreateItem(Item);

        // [WHEN] Validate Item."Item Category Code" = "IC"
        Item.Validate("Item Category Code", ItemCategoryCode);

        // [THEN] Item have Item Category "ATT1"
        TempItemAttributeValue.LoadItemAttributesFactBoxData(Item."No.");
        TempItemAttributeValue.SetRange("Attribute ID", ItemAttributeID[1]);
        Assert.RecordIsNotEmpty(TempItemAttributeValue);

        // [THEN] Item have Item Category "ATT2"
        TempItemAttributeValue.SetRange("Attribute ID", ItemAttributeID[2]);
        Assert.RecordIsNotEmpty(TempItemAttributeValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCategoryExists()
    var
        ItemCategory: Record "Item Category";
        ItemCategoryManagement: Codeunit "Item Category Management";
        ItemCategoryCode: Code[20];
        NonExistingCode: Code[20];
        SearchResult: Boolean;
    begin
        Initialize();
        // [GIVEN] A guid that does not exist as a category
        NonExistingCode := LibraryUtility.GenerateGUID();

        // [WHEN] We search for it
        SearchResult := ItemCategoryManagement.DoesValueExistInItemCategories(NonExistingCode, ItemCategory);

        // [THEN] We don't find it
        Assert.IsFalse(SearchResult, 'Expected the non existing category not to be found.');

        // [GIVEN] A category that exists
        ItemCategoryCode := CreateItemCategory('');

        // [WHEN] We search for it
        SearchResult := ItemCategoryManagement.DoesValueExistInItemCategories(ItemCategoryCode, ItemCategory);

        // [THEN] We find it
        Assert.IsTrue(SearchResult, 'Expected the newly created category to be found.');

        // [WHEN] We search for it, with a different case (lowercase)
        Assert.AreEqual(
          ItemCategoryCode, UpperCase(ItemCategoryCode), 'Expected the uppercase category code to be equal to the category code.');
        Assert.AreNotEqual(
          ItemCategoryCode, LowerCase(ItemCategoryCode), 'Expected the lowercase category code to be different from the category code.');
        SearchResult := ItemCategoryManagement.DoesValueExistInItemCategories(LowerCase(ItemCategoryCode), ItemCategory);

        // [THEN] We find it because the search is not case-sensitive
        Assert.IsTrue(SearchResult, 'Expected the newly created category to be found, even when lowercase.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteItemAttributeValueMappingWhenDeleteItem()
    var
        Item: Record Item;
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
    begin
        Initialize();
        // [SCENARIO 223256] Delete Item Attribute Value Mapping when user deletes Item

        // [GIVEN] Item with an attribute
        LibraryInventory.CreateItem(Item);
        CreateItemAttributeWithValueAndMappingForItem(Item."No.");

        // [WHEN] Delete Item
        Item.Delete(true);

        // [THEN] Item Attribute Value Mapping is deleted
        FilterItemAttributeValueMapping(ItemAttributeValueMapping, DATABASE::Item, Item."No.", 0);
        Assert.RecordIsEmpty(ItemAttributeValueMapping);
    end;

    [Test]
    [HandlerFunctions('ItemAttributeValueEditorHandler')]
    [Scope('OnPrem')]
    procedure AssignBlankDecimalAttribute()
    var
        Item: Record Item;
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemList: TestPage "Item List";
    begin
        Initialize();
        // [SCENARIO 223453] Assign blank decimal attribute to Item when blank and zero values exist

        // [GIVEN] "Item Attribute" with Type = Decimal
        // [GIVEN] "Item Attribute Value" with "Value" = '0', "ID" = 1
        LibraryInventory.CreateItemAttributeWithValue(ItemAttribute, ItemAttributeValue, ItemAttribute.Type::Decimal, '0');

        // [GIVEN] "Item Attribute Value" with "Value" = '', "ID" = 2
        LibraryInventory.CreateItemAttributeValue(ItemAttributeValue, ItemAttribute.ID, '');

        // [GIVEN] Item
        LibraryInventory.CreateItem(Item);

        // [WHEN] Assign blank decimal attribute '' to Item
        LibraryVariableStorage.Enqueue(ItemAttribute.Name);
        ItemList.OpenEdit();
        ItemList.GotoRecord(Item);
        ItemList.Attributes.Invoke();

        // [THEN] Item is mapped with blank "Item Attribute Value" with "ID" = 2
        FilterItemAttributeValueMapping(ItemAttributeValueMapping, DATABASE::Item, Item."No.", ItemAttribute.ID);
        ItemAttributeValueMapping.FindFirst();
        Assert.AreEqual(ItemAttributeValue.ID, ItemAttributeValueMapping."Item Attribute Value ID", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItemCategoriesPageWithDecimalValueFromItemCategory()
    var
        Item: Record Item;
        ItemCategory: Record "Item Category";
        ItemCategories: TestPage "Item Categories";
        AttributeTextValue: Text[10];
        ItemAttributeName: Text[250];
        TextUoM: Text[1];
    begin
        Initialize();
        // [SCENARIO 223061] ItemAttributesFactbox shows decimal values assigned by default from Item Category page.

        // [GIVEN] Item Attribute "AAA" of Decimal Type with Text Unit of Measure.
        // [GIVEN] Item Category "CAT" where "parent category" = ''.
        // [GIVEN] An "Item" with "CAT" assigned.
        CreareParentCategoryWithItemAndAttribute(Item, ItemCategory, TextUoM, ItemAttributeName);

        // [GIVEN] "AAA" is added to "CAT" with default value = 11222,33 (or 11,222.33 for other cultures).
        AttributeTextValue := Format(LibraryRandom.RandDecInRange(10000, 20000, 2));
        SetItemCategoryAttributeValue(ItemCategory, ItemAttributeName, AttributeTextValue);

        // [WHEN] "CAT" is selected on "Item Categories Page".
        ItemCategories.OpenView();
        ItemCategories.GotoRecord(ItemCategory);

        // [THEN] ItemAttributesFactbox shows "AAA" with Name and Value with Unit of Measure.
        ItemCategories.ItemAttributesFactbox.Attribute.AssertEquals(ItemAttributeName);
        ItemCategories.ItemAttributesFactbox.Value.AssertEquals(AttributeTextValue + ' ' + TextUoM);
        ItemCategories.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItemAttributesFactBoxFromItemListWithDecimalValueFromItemCategory()
    var
        Item: Record Item;
        ItemCategory: Record "Item Category";
        ItemList: TestPage "Item List";
        AttributeTextValue: Text[10];
        TextUoM: Text[1];
        ItemAttributeName: Text[250];
    begin
        Initialize();
        // [SCENARIO 223061] ItemAttributesFactbox shows decimal values assigned as default from Item Category page.

        // [GIVEN] Item Attribute "AAA" of Decimal Type with Text Unit of Measure.
        // [GIVEN] Item Category "CAT" where "parent category" = ''.
        // [GIVEN] An "Item" with "CAT" assigned.
        CreareParentCategoryWithItemAndAttribute(Item, ItemCategory, TextUoM, ItemAttributeName);

        AttributeTextValue := Format(LibraryRandom.RandDecInRange(10000, 20000, 2));
        // [GIVEN] "AAA" is added to "CAT" with default value = 11222,33 (or 11,222.33 for other cultures).
        SetItemCategoryAttributeValue(ItemCategory, ItemAttributeName, AttributeTextValue);

        // [WHEN] When "Item" is selected on "Item List" Page.
        ItemList.OpenView();
        ItemList.GotoRecord(Item);

        // [THEN] ItemAttributesFactbox displays "AAA" with Name and Value with Unit of Measure.
        ItemList.ItemAttributesFactBox.Attribute.AssertEquals(ItemAttributeName);
        ItemList.ItemAttributesFactBox.Value.AssertEquals(AttributeTextValue + ' ' + TextUoM);
        ItemList.Close();
    end;

    [Test]
    [HandlerFunctions('ItemAttributeValueEditorWithVerificationHandler')]
    [Scope('OnPrem')]
    procedure TestItemAttributeValuesPageFromItemListWithDecimalValueFromItemCategory()
    var
        Item: Record Item;
        ItemCategory: Record "Item Category";
        ItemList: TestPage "Item List";
        AttributeTextValue: Text[10];
        TextUoM: Text[1];
        ItemAttributeName: Text[250];
    begin
        Initialize();
        // [SCENARIO 223061] "Item Attribute Values" page shows decimal values assigned as default from Item Category page.

        // [GIVEN] Item Attribute "AAA" of Decimal Type with Text Unit of Measure.
        // [GIVEN] Item Category "CAT" where "parent category" = ''.
        // [GIVEN] An "Item" with "CAT" assigned.
        CreareParentCategoryWithItemAndAttribute(Item, ItemCategory, TextUoM, ItemAttributeName);

        AttributeTextValue := Format(LibraryRandom.RandDecInRange(10000, 20000, 2));
        // [GIVEN] "AAA" is added to "CAT" with default value = 11222,33 (or 11,222.33 for other cultures).
        SetItemCategoryAttributeValue(ItemCategory, ItemAttributeName, AttributeTextValue);

        // [WHEN] "Item Attribute Values" page is opened from "Item List" page.
        ItemList.OpenView();
        ItemList.GotoRecord(Item);
        ItemList.Attributes.Invoke();
        ItemList.Close();

        // [THEN] "Item Attribute Values" page is populated with "AAA" Name and Value via the ItemAttributeValueEditorWithVerificationHandler.
        Assert.AreEqual(ItemAttributeName, LibraryVariableStorage.DequeueText(), 'Attribute Name is expected');
        Assert.AreEqual(AttributeTextValue, LibraryVariableStorage.DequeueText(), 'Attribute Value is expected');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetAttributeValueID_ExistingValueDecimalWithLocalCulture()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttributeValueSelection: Record "Item Attribute Value Selection";
        TempItemAttributeValue: Record "Item Attribute Value" temporary;
        Result: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 223061] Test GetAttributeValueID procedure with Decimal value with local culture.

        LibraryInventory.CreateItemAttributeWithValue(
          ItemAttribute, ItemAttributeValue, ItemAttribute.Type::Decimal,
          Format(LibraryRandom.RandDecInRange(10000, 20000, 2)));

        CreateItemAttributeValueSelection(ItemAttributeValue, ItemAttributeValueSelection);

        Result := ItemAttributeValueSelection.GetAttributeValueID(TempItemAttributeValue);

        Assert.AreEqual(ItemAttributeValue.ID, Result, 'Item Attribute Value ID mismatch');
        Assert.AreEqual(TempItemAttributeValue.Value, ItemAttributeValue.Value, 'Item Attribute Values mismatch');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetAttributeValueID_ExistingValueDecimalWithXMLCulture()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttributeValueSelection: Record "Item Attribute Value Selection";
        TempItemAttributeValue: Record "Item Attribute Value" temporary;
        Result: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 223061] Test GetAttributeValueID procedure for Decimal value with XML culture.

        LibraryInventory.CreateItemAttributeWithValue(
          ItemAttribute, ItemAttributeValue, ItemAttribute.Type::Decimal,
          Format(LibraryRandom.RandDecInRange(10000, 20000, 2), 0, 9));

        CreateItemAttributeValueSelection(ItemAttributeValue, ItemAttributeValueSelection);

        Result := ItemAttributeValueSelection.GetAttributeValueID(TempItemAttributeValue);

        Assert.AreEqual(ItemAttributeValue.ID, Result, 'Item Attribute Value ID mismatch');
        Assert.AreEqual(TempItemAttributeValue.Value, ItemAttributeValue.Value, 'Item Attribute Values mismatch');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetAttributeValueID_ExistingValueNonDecimal()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttributeValueSelection: Record "Item Attribute Value Selection";
        TempItemAttributeValue: Record "Item Attribute Value" temporary;
        Result: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 223061] Test GetAttributeValueID procedure for existing Text value.

        LibraryInventory.CreateItemAttributeWithValue(
          ItemAttribute, ItemAttributeValue, ItemAttribute.Type::Text,
          LibraryUtility.GenerateGUID());

        CreateItemAttributeValueSelection(ItemAttributeValue, ItemAttributeValueSelection);

        Result := ItemAttributeValueSelection.GetAttributeValueID(TempItemAttributeValue);

        Assert.AreEqual(ItemAttributeValue.ID, Result, 'Item Attribute Value ID mismatch');
        Assert.AreEqual(TempItemAttributeValue.Value, ItemAttributeValue.Value, 'Item Attribute Values mismatch');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetAttributeValueID_NotExistingValueNonDecimal()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttributeValueSelection: Record "Item Attribute Value Selection";
        TempItemAttributeValue: Record "Item Attribute Value" temporary;
        Result: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 223061] Test GetAttributeValueID procedure for non existing Text value.

        LibraryInventory.CreateItemAttributeWithValue(
          ItemAttribute, ItemAttributeValue, ItemAttribute.Type::Text,
          '');

        CreateItemAttributeValueSelectionWithValue(
          ItemAttributeValue, ItemAttributeValueSelection, LibraryUtility.GenerateGUID());

        Result := ItemAttributeValueSelection.GetAttributeValueID(TempItemAttributeValue);

        ItemAttributeValue.SetRange("Attribute ID", ItemAttributeValueSelection."Attribute ID");
        ItemAttributeValue.FindLast();

        Assert.AreEqual(ItemAttributeValue.ID, Result, 'Item Attribute Value ID mismatch');
        Assert.AreEqual(TempItemAttributeValue.Value, ItemAttributeValue.Value, 'Item Attribute Values mismatch');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetAttributeValueID_NotExistingValueDecimalWithLocalCulture()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttributeValueSelection: Record "Item Attribute Value Selection";
        TempItemAttributeValue: Record "Item Attribute Value" temporary;
        Result: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 223061] Test GetAttributeValueID procedure for non existing Decimal value with local culture.

        LibraryInventory.CreateItemAttributeWithValue(
          ItemAttribute, ItemAttributeValue, ItemAttribute.Type::Decimal, '');

        CreateItemAttributeValueSelectionWithValue(
          ItemAttributeValue, ItemAttributeValueSelection, Format(LibraryRandom.RandDecInDecimalRange(10000, 20000, 2)));

        Result := ItemAttributeValueSelection.GetAttributeValueID(TempItemAttributeValue);

        ItemAttributeValue.SetRange("Attribute ID", ItemAttributeValueSelection."Attribute ID");
        ItemAttributeValue.FindLast();

        Assert.AreEqual(ItemAttributeValue.ID, Result, 'Item Attribute Value ID mismatch');
        Assert.AreEqual(TempItemAttributeValue.Value, ItemAttributeValue.Value, 'Item Attribute Values mismatch');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetAttributeValueID_NotExistingValueDecimalWithXMLCulture()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttributeValueSelection: Record "Item Attribute Value Selection";
        TempItemAttributeValue: Record "Item Attribute Value" temporary;
        Result: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 223061] Test GetAttributeValueID procedure for non existing Decimal value with XML culture.

        LibraryInventory.CreateItemAttributeWithValue(
          ItemAttribute, ItemAttributeValue, ItemAttribute.Type::Decimal, '');

        CreateItemAttributeValueSelectionWithValue(
          ItemAttributeValue, ItemAttributeValueSelection, Format(LibraryRandom.RandDecInDecimalRange(10000, 20000, 2), 0, 9));

        Result := ItemAttributeValueSelection.GetAttributeValueID(TempItemAttributeValue);

        ItemAttributeValue.SetRange("Attribute ID", ItemAttributeValueSelection."Attribute ID");
        ItemAttributeValue.FindLast();

        Assert.AreEqual(ItemAttributeValue.ID, Result, 'Item Attribute Value ID mismatch');
        Assert.AreEqual(TempItemAttributeValue.Value, ItemAttributeValue.Value, 'Item Attribute Values mismatch');
    end;

    local procedure CreareParentCategoryWithItemAndAttribute(var Item: Record Item; var ItemCategory: Record "Item Category"; var TextUoM: Text[1]; var ItemAttributeName: Text[250])
    var
        ItemAttribute: Record "Item Attribute";
    begin
        TextUoM := CopyStr(LibraryUtility.GenerateRandomText(1), 1, 1);
        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Decimal, TextUoM);
        ItemAttributeName := ItemAttribute.Name;
        LibraryInventory.CreateItemCategory(ItemCategory);

        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Category Code", ItemCategory.Code);
        Item.Modify(true);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure FilterByAttribForSortedItemsWhereItemWithAttribHasSuffix()
    var
        Item: Record Item;
        ItemAttributeValue: Record "Item Attribute Value";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 223204] Filter sorted items by attribute when items with attributes have suffix

        // [GIVEN] Three Items with sorted numbers
        // [GIVEN] 'TEST80102-T' with attribute "A",'80103' no attrutes,'TEST80103-T' with attribute "A"
        CreateItemsAndAttribsForScenarioWithSortedItems(ItemAttributeValue, 'TEST80102-T', 'TEST80103', 'TEST80103-T');

        // [WHEN] Apply GetItemNoFilterText to Items for Item Attribute "A"
        Item.SetFilter("No.", RunGetItemNoFilterText(ItemAttributeValue));

        // [THEN] Two Items selected: 'TEST80102-T' and 'TEST80103-T'
        Assert.RecordCount(Item, 2);
        Item.FindSet();
        Assert.AreEqual('TEST80102-T', Item."No.", '');
        Item.Next();
        Assert.AreEqual('TEST80103-T', Item."No.", '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure FilterByAttribForSortedItemsWhereItemWithoutAttribHasSuffix()
    var
        Item: Record Item;
        ItemAttributeValue: Record "Item Attribute Value";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 223204] Filter sorted items by attribute when items without attributes have suffix

        // [GIVEN] Three Items with sorted numbers
        // [GIVEN] 'T80102' with attribute "A",'T80102-T' no attrutes,'T80103' with attribute "A"
        CreateItemsAndAttribsForScenarioWithSortedItems(ItemAttributeValue, 'T80102', 'T80102-T', 'T80103');

        // [WHEN] Apply GetItemNoFilterText to Items for Item Attribute "A"
        Item.SetFilter("No.", RunGetItemNoFilterText(ItemAttributeValue));

        // [THEN] Two Items selected: 'T80102' and 'T80103'
        Assert.RecordCount(Item, 2);
        Item.FindSet();
        Assert.AreEqual('T80102', Item."No.", '');
        Item.Next();
        Assert.AreEqual('T80103', Item."No.", '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UT_GetItemNoFilterTextForItemsWithSequentialNumbers()
    var
        ItemAttributeValue: Record "Item Attribute Value";
        ItemNo: array[5] of Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 277697] Filter sorted items by attribute in case of consecutive item numbers.

        // [GIVEN] Six items with sorted numbers "A001" - "A005".
        // [GIVEN] Item "A002" doesn't have any attributes, all other items have attribute "A".
        CreateItemsAndAttribsForFilterTest(ItemNo, ItemAttributeValue);

        // [WHEN] Apply GetItemNoFilterText to items for Item Attribute "A".
        // [THEN] ".." are placed between "A003" and "A005", i.e the filter is "A001|A003..A005".
        Assert.AreEqual(
          StrSubstNo('%1|%2..%3', ItemNo[1], ItemNo[3], ItemNo[5]),
          RunGetItemNoFilterText(ItemAttributeValue), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_FindItemsByAttributesReturnsTempItemIsEqualToItem()
    var
        Item: Record Item;
        TempFilteredItem: Record Item temporary;
        ItemAttributeValue: Record "Item Attribute Value";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 277697] Filter sorted items by attribute: FindItemsByAttributes returns temporary Item records, that are equal to correspondning Item records.

        // [GIVEN] Item with Attribute "A".
        CreateItemWithAttribute(Item, ItemAttributeValue);

        // [WHEN] Run FindItemsByAttributes for Attribute "A".
        RunFindItemsByAttributes(ItemAttributeValue, TempFilteredItem);

        // [THEN] Returned temporary Item record is equal to Item record with the same "No.".
        TempFilteredItem.FindFirst();
        TempFilteredItem.TestField(Description, Item.Description);
        TempFilteredItem.TestField("Base Unit of Measure", Item."Base Unit of Measure");
        TempFilteredItem.TestField("Unit Price", Item."Unit Price");
        TempFilteredItem.TestField("Unit Cost", Item."Unit Cost");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ThreeAttributesLastItemDoesNotMatchOneOfAttribute()
    var
        TempFilteredItem: Record Item temporary;
        Item: array[3] of Record Item;
        ItemAttribute: array[3] of Record "Item Attribute";
        ItemAttributeValue: array[3] of Record "Item Attribute Value";
        i: Integer;
        j: Integer;
    begin
        // [SCENARIO 227778] All items selected by using "Filter By Attributes" except the last one which does not match one of the attributes

        // [GIVEN] Three attributes: Length, Width, Depth
        for i := 1 to ArrayLen(ItemAttributeValue) do
            LibraryInventory.CreateItemAttributeWithValue(
              ItemAttribute[i], ItemAttributeValue[i], ItemAttribute[i].Type::Decimal, Format(LibraryRandom.RandDec(100, 2)));

        // [GIVEN] Item "X" has Length 9, Width 12, Depth 5
        // [GIVEN] Item "Y" has Length 9, Width 12, Depth 5
        for i := 1 to ArrayLen(Item) - 1 do begin
            LibraryInventory.CreateItem(Item[i]);
            for j := 1 to ArrayLen(ItemAttributeValue) do
                LibraryInventory.CreateItemAttributeValueMapping(
                  DATABASE::Item, Item[i]."No.", ItemAttribute[j].ID, ItemAttributeValue[j].ID);
        end;

        // [GIVEN] Item "Z" has Length 9, Width and Depth is not defined
        LibraryInventory.CreateItem(Item[i + 1]);
        LibraryInventory.CreateItemAttributeValueMapping(
          DATABASE::Item, Item[i + 1]."No.", ItemAttribute[1].ID, ItemAttributeValue[1].ID);

        // [WHEN] Set the following filters by attributes: Length = 9, Width = 12, Depth = 5
        FindItemsByMultipleAttributes(TempFilteredItem, ItemAttributeValue);

        // [THEN] Two item selected by filters
        Assert.RecordCount(TempFilteredItem, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoItemCategoryWithEmptyCodeAllowed()
    var
        ItemCategory: Record "Item Category";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 273705] Item Category with empty Code cannot be inserted.
        Initialize();

        ItemCategory.Init();
        asserterror ItemCategory.Insert(true);
        Assert.ExpectedTestFieldError(ItemCategory.FieldCaption(Code), '');
    end;

    [Test]
    [HandlerFunctions('ItemAttributeValueEditorSetNameAndValueHandler')]
    [Scope('OnPrem')]
    procedure SetNewValueOfItemAttributeWithTypeOption()
    var
        Item: Record Item;
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: array[2] of Record "Item Attribute Value";
    begin
        // [SCENARIO 277700] Item attribute value of attribute with type option is not deleted from the database when it is not has been used

        // [GIVEN] Item attribute of type option and its two value "V1" and "V2","V1" is mapped to the item "I"
        CreatePairOfItemAttributeValues(Item, ItemAttributeValue, ItemAttribute.Type::Option);

        // [WHEN] Open item attribute value editor and change "V1" to "V2"
        SetNewItemAttributeValue(Item, ItemAttributeValue[2]);

        // [THEN] "V1" still exists in the database
        ItemAttributeValue[1].Find();
    end;

    [Test]
    [HandlerFunctions('ItemAttributeValueEditorSetNameAndValueHandler')]
    [Scope('OnPrem')]
    procedure SetNewValueOfItemAttributeWithTypeText()
    var
        Item: Record Item;
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: array[2] of Record "Item Attribute Value";
    begin
        // [SCENARIO 277700] Item attribute value of attribute with type text is deleted from the database when it is not has been used

        // [GIVEN] Item attribute of type text and its two value "V1" and "V2", "V1" is mapped to the item "I"
        CreatePairOfItemAttributeValues(Item, ItemAttributeValue, ItemAttribute.Type::Text);

        // [WHEN] Open item attribute value editor and change "V1" to "V2"
        SetNewItemAttributeValue(Item, ItemAttributeValue[2]);

        // [THEN] now "V1" is deleted from the database
        ItemAttributeValue[1].SetRange("Attribute ID", ItemAttributeValue[1]."Attribute ID");
        ItemAttributeValue[1].SetRange(ID, ItemAttributeValue[1].ID);
        Assert.RecordIsEmpty(ItemAttributeValue[1]);
    end;

    [Test]
    [HandlerFunctions('ItemListModalPageHandler,FilterItemsByAttributeModalPageHandler')]
    [Scope('OnPrem')]
    procedure SetUnsetAttributesWhenItemListInLookupMode()
    var
        Item: Record Item;
        NameValueBuffer: Record "Name/Value Buffer";
        CodeCoverage: Record "Code Coverage";
        LookupItemsQty: Integer;
        FilteredItemsQty: Integer;
        RestoredItemsQty: Integer;
        SubString: Text[3];
        DummyReturnValue: Text;
        NoOfHits: Integer;
    begin
        // [FEATURE] [Item] [UT] [Performance]
        // [SCENARIO 283579] When the ItemList page is opened from TAB27.PickItem function in Lookup mode, and then filtered by Item attributes, then clearing attributes filter restores the original list of records.
        Initialize();

        // [GIVEN] 3 Items with sorted numbers in Description field
        // [GIVEN] Items 'TESTFFF1' and 'TESTFFF2' with attribute "A", 'TESTFFF3' with no attributes.
        // [GIVEN] SubString 'FFF' created as a partial description containing in all 3 Items Description
        CreateItemsAndAttributesForLookupAndFilterTest(SubString);

        // [WHEN] SubString is validated on any Purchase / Sales document in the Line."No." field where Item.TryGetItemNoOpenCard is invoked
        CodeCoverageMgt.StartApplicationCoverage();
        Item.TryGetItemNoOpenCard(DummyReturnValue, SubString, true, true, true);
        CodeCoverageMgt.StopApplicationCoverage();

        // [THEN] ItemList.SetTempFilteredItemRec procedure must be called
        NoOfHits :=
          GetCodeCoverageForObject(
            CodeCoverage."Object Type"::Table, DATABASE::Item, 'SetTempFilteredItemRec');
        Assert.AreEqual(1, NoOfHits, 'ItemList.SetTempFilteredItemRec must be called');

        // [THEN] ItemList lookup page is opened by ItemListModalPageHandler, total number of found records = 3
        LookupItemsQty := LibraryVariableStorage.DequeueInteger();
        Assert.AreEqual(3, LookupItemsQty, 'Expected items in ItemList lookup = 3');

        // [WHEN] "Filter by Attributes" ActionButton invoked and attribute "A" selected (at ItemListModalPageHandler)
        // [THEN] Total number of filtered records = 2
        FilteredItemsQty := LibraryVariableStorage.DequeueInteger();
        Assert.AreEqual(2, FilteredItemsQty, 'Expected items in ItemList lookup page (when filtered by attributes) = 2');

        // [WHEN] "Clear Attributes Filter" ActionButton invoked (at ItemListModalPageHandler)
        // [THEN] Total number of restored record in the page = 3
        RestoredItemsQty := LibraryVariableStorage.DequeueInteger();
        Assert.AreEqual(3, RestoredItemsQty, 'Expected items in ItemList lookup page (when the attribute filter is cleared) = 3');

        LibraryVariableStorage.AssertEmpty();
        NameValueBuffer.DeleteAll();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoItemAttributeValueMappingOnTempRecord()
    var
        TempItem: Record Item temporary;
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemCategoryCode: Code[20];
    begin
        // [FEATURE] [Item]
        // [SCENARIO 314081] Item Attribute Value Mapping is not created for temporary items
        Initialize();
        ItemAttributeValueMapping.DeleteAll();

        // [GIVEN] Item Category 'CAT01' with Item Attribute Value Mapping
        ItemCategoryCode := CreateItemCategory('');
        CreateItemAttributeWithValueAndMapping(ItemCategoryCode);

        // [GIVEN] Temporary Item "TEMP"
        TempItem.Init();

        // [WHEN] Set "Item Category Code" = "CAT01" on "TEMP" Item
        TempItem.Validate("Item Category Code", ItemCategoryCode);

        // [THEN] Item Attribute Value Mapping doesn't exist for the "TEMP" Item
        ItemAttributeValueMapping.SetRange("Table ID", DATABASE::Item);
        ItemAttributeValueMapping.SetRange("No.", TempItem."No.");
        Assert.RecordIsEmpty(ItemAttributeValueMapping);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CategoryDescriptionDoesNotChangeWhenValidateParentCategory()
    var
        ItemCategory: Record "Item Category";
        ItemCategories: TestPage "Item Categories";
        ItemCategoryCard: TestPage "Item Category Card";
        Description: Text;
    begin
        // [SCENARIO 337513] Category description remains unchanged when validate parent category
        Initialize();

        // [GIVEN] Created Category Hierarchy of two Categories "C1" and "C2"
        CreateItemCategoryHierarchy(2);

        // [GIVEN] The user opened Category Card for Category "C2"
        ItemCategory.FindLast();
        ItemCategories.OpenEdit();
        ItemCategories.FILTER.SetFilter(Code, ItemCategory.Code);
        ItemCategoryCard.Trap();
        ItemCategories.Edit().Invoke();

        // [GIVEN] The user set new Description for "C2"
        Description := LibraryUtility.GenerateGUID();
        ItemCategoryCard.Description.SetValue(Description);

        // [WHEN] Set "C1" as a Parent Category for "C2"
        ItemCategory.FindFirst();
        ItemCategoryCard."Parent Category".SetValue(ItemCategory.Code);

        // [THEN] The description for "C2" remains as set by the user
        ItemCategoryCard.Description.AssertEquals(Description);
        ItemCategories.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewCategoryDescriptionDoesNotChangeWhenValidateParentCategory()
    var
        ItemCategory: Record "Item Category";
        ItemCategoryParent: Record "Item Category";
        ItemCategoryCard: TestPage "Item Category Card";
        Description: Text;
    begin
        // [SCENARIO 340871] Category description remains unchanged when validate parent category for newly created item category
        Initialize();

        // [GIVEN] Created Category Hierarchy of Parent Category "C1"
        CreateItemCategoryHierarchy(1);
        ItemCategoryParent.FindLast();

        // [GIVEN] The user opened Category Card for new Category "C2"
        ItemCategoryCard.OpenNew();
        ItemCategoryCard.Code.SetValue(LibraryUtility.GenerateGUID());

        // [GIVEN] The user set new Description for "C2"
        Description := LibraryUtility.GenerateGUID();
        ItemCategoryCard.Description.SetValue(Description);

        // [WHEN] Set "C1" as a Parent Category for "C2"
        ItemCategoryCard."Parent Category".SetValue(ItemCategoryParent.Code);
        ItemCategoryCard.Close();

        // [THEN] Description and "Parent Category" fields fo "C2" are saved to DB as expected
        ItemCategory.FindLast();
        ItemCategory.TestField(Description, Description);
        ItemCategory.TestField("Parent Category", ItemCategoryParent.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertingItemCategoryUpdatesIndentation()
    var
        ItemCategory: array[2] of Record "Item Category";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 341347] Update indentation on inserting item category.
        Initialize();

        CreateItemCategoryRec(ItemCategory[1], '');

        ItemCategory[2].Init();
        ItemCategory[2].Code := LibraryUtility.GenerateGUID();
        ItemCategory[2]."Parent Category" := ItemCategory[1].Code;
        ItemCategory[2].Insert(true);

        ItemCategory[2].TestField(Indentation, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdatingItemCategoryUpdatesIndentation()
    var
        ItemCategory: array[3] of Record "Item Category";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 341347] Update indentation on updating parent item category.
        Initialize();

        CreateItemCategoryRec(ItemCategory[1], '');
        CreateItemCategoryRec(ItemCategory[2], '');
        CreateItemCategoryRec(ItemCategory[3], ItemCategory[2].Code);

        ItemCategory[2]."Parent Category" := ItemCategory[1].Code;
        ItemCategory[2].Modify(true);

        ItemCategory[2].TestField(Indentation, 1);

        ItemCategory[3].Find();
        ItemCategory[3].TestField(Indentation, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PresentationOrderOnInsertFirstItemCategory()
    var
        ItemCategory: Record "Item Category";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 341347] Presentation order on inserting very first item category.
        Initialize();
        ItemCategory.DeleteAll();

        ItemCategory.Init();
        ItemCategory.Code := LibraryUtility.GenerateGUID();

        ItemCategory.Insert(true);

        ItemCategory.Find();
        ItemCategory.TestField("Presentation Order", 10000);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PresentationOrderOnInsertItemCatToTop()
    var
        ItemCategory: Record "Item Category";
        NewCode: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 341347] Presentation order on inserting item category to the top of the list.
        Initialize();
        ItemCategory.DeleteAll();

        NewCode := LibraryUtility.GenerateGUID();
        CreateItemCategoryRec(ItemCategory, '');

        ItemCategory.Init();
        ItemCategory.Code := NewCode;
        ItemCategory.Insert(true);

        ItemCategory.Find();
        ItemCategory.TestField("Presentation Order", 5000);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PresentationOrderOnInsertItemCatToBottom()
    var
        ItemCategory: Record "Item Category";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 341347] Presentation order on inserting item category to the bottom of the list.
        Initialize();
        ItemCategory.DeleteAll();

        CreateItemCategoryRec(ItemCategory, '');
        CreateItemCategoryRec(ItemCategory, '');

        ItemCategory.Find();
        ItemCategory.TestField("Presentation Order", 20000);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PresentationOrderOnInsertItemCatToMiddle()
    var
        ItemCategory: Record "Item Category";
        NewCode: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 341347] Presentation order on inserting item category to the middle of the list.
        Initialize();
        ItemCategory.DeleteAll();

        CreateItemCategoryRec(ItemCategory, '');
        NewCode := LibraryUtility.GenerateGUID();
        CreateItemCategoryRec(ItemCategory, '');

        ItemCategory.Init();
        ItemCategory.Code := NewCode;
        ItemCategory.Insert(true);

        ItemCategory.Find();
        ItemCategory.TestField("Presentation Order", 15000);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PresentationOrderOnInsertFirstItemCatInGroup()
    var
        ItemCategoryParent: Record "Item Category";
        ItemCategory: Record "Item Category";
        NewCode: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 341347] Presentation order on inserting first item category in a child group.
        Initialize();
        ItemCategory.DeleteAll();

        CreateItemCategoryRec(ItemCategoryParent, '');
        CreateItemCategoryRec(ItemCategory, '');

        NewCode := LibraryUtility.GenerateGUID();
        CreateItemCategoryRec(ItemCategory, ItemCategoryParent.Code);

        ItemCategory.Init();
        ItemCategory.Code := NewCode;
        ItemCategory."Parent Category" := ItemCategoryParent.Code;
        ItemCategory.Insert(true);

        ItemCategory.Find();
        ItemCategory.TestField("Presentation Order", 12500);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PresentationOrderOnInsertLastItemCatInGroup()
    var
        ItemCategoryParent: Record "Item Category";
        ItemCategory: Record "Item Category";
        NewCode: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 341347] Presentation order on inserting last item category in a child group.
        Initialize();
        ItemCategory.DeleteAll();

        CreateItemCategoryRec(ItemCategoryParent, '');
        CreateItemCategoryRec(ItemCategory, ItemCategoryParent.Code);
        NewCode := LibraryUtility.GenerateGUID();
        CreateItemCategoryRec(ItemCategory, '');

        ItemCategory.Init();
        ItemCategory.Code := NewCode;
        ItemCategory."Parent Category" := ItemCategoryParent.Code;
        ItemCategory.Insert(true);

        ItemCategory.Find();
        ItemCategory.TestField("Presentation Order", 25000);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PresentationOrderOnInsertItemCatAfterTree()
    var
        ItemCategory: Record "Item Category";
        NewCode: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 341347] Presentation order on inserting last item category in a child group.
        Initialize();
        ItemCategory.DeleteAll();

        CreateItemCategoryRec(ItemCategory, '');
        CreateItemCategoryRec(ItemCategory, ItemCategory.Code);
        CreateItemCategoryRec(ItemCategory, ItemCategory.Code);
        NewCode := LibraryUtility.GenerateGUID();
        CreateItemCategoryRec(ItemCategory, '');

        ItemCategory.Init();
        ItemCategory.Code := NewCode;
        ItemCategory.Insert(true);

        ItemCategory.Find();
        ItemCategory.TestField("Presentation Order", 35000);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PresentationOrderOnModifyingParentCategory()
    var
        ItemCategoryParent: Record "Item Category";
        ItemCategory: Record "Item Category";
        NewCode: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 341347] Presentation order after modifying parent category.
        Initialize();
        ItemCategory.DeleteAll();

        CreateItemCategoryRec(ItemCategoryParent, '');
        NewCode := LibraryUtility.GenerateGUID();
        CreateItemCategoryRec(ItemCategory, ItemCategoryParent.Code);

        ItemCategory.Init();
        ItemCategory.Code := NewCode;
        ItemCategory.Insert(true);

        ItemCategory."Parent Category" := ItemCategoryParent.Code;
        ItemCategory.Modify(true);

        ItemCategory.Find();
        ItemCategory.TestField("Presentation Order", 15000);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PresentationOrderRecalculatedWhenNoRoomForNewNo()
    var
        ItemCategory: Record "Item Category";
        ItemCategories: TestPage "Item Categories";
        NewCode: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 341347] Presentation order recalculated on trying to assign existing presentation order no. to a new category.
        Initialize();
        ItemCategory.DeleteAll();

        NewCode := LibraryUtility.GenerateGUID();

        CreateItemCategoryRec(ItemCategory, '');
        ItemCategory."Presentation Order" := 1;
        ItemCategory.Modify();

        ItemCategory.Init();
        ItemCategory.Code := NewCode;
        ItemCategory.Insert(true);

        ItemCategories.OpenView();
        ItemCategories.First();
        ItemCategories.Code.AssertEquals(NewCode);

        ItemCategory.Find();
        ItemCategory.TestField("Presentation Order", 10000);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ChangeDefaultValueOnChangeItemCategoryDeleteConfirmed()
    var
        ItemAttribute: Record "Item Attribute";
        Item: Record Item;
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemAttributeValueID: Integer;
    begin
        // [FEATURE] [Item Attribute]
        // [SCENARIO 344524] Item's Attribute Values inherited from Item Categories are changed on Item Category change when attribute deletion confirmed
        Initialize();

        // [GIVEN] Created Item Attribute "A"
        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Option, '');

        // [GIVEN] Item Category "C1" with Default Value "V1" for the Item Attribute
        // [GIVEN] Created Item with Item Category "C1"
        LibraryInventory.CreateItem(Item);
        SetItemCategoryWithAttributeDefaultValueOnItem(Item, ItemAttribute.ID);

        // [GIVEN] Item Category "C2" with Default Value "V2" for the Item Attribute
        // [WHEN] Set Item's Category to "C2" and confirm Yes on "Do you want to delete the attributes that are inherited from item category 'C1'?"
        LibraryVariableStorage.Enqueue(
          StrSubstNo(DeleteAttributesInheritedFromOldCategoryQst, Item."Item Category Code"));
        LibraryVariableStorage.Enqueue(true);
        ItemAttributeValueID := SetItemCategoryWithAttributeDefaultValueOnItem(Item, ItemAttribute.ID);

        // [THEN] Item's Attribute "A" Value = "V2"
        FilterItemAttributeValueMapping(ItemAttributeValueMapping, DATABASE::Item, Item."No.", ItemAttribute.ID);
        ItemAttributeValueMapping.SetRange("Item Attribute Value ID", ItemAttributeValueID);
        Assert.RecordIsNotEmpty(ItemAttributeValueMapping);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ChangeDefaultValueOnChangeItemCategoryDeleteNotConfirmed()
    var
        ItemAttribute: Record "Item Attribute";
        Item: Record Item;
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemAttributeValueID: Integer;
    begin
        // [FEATURE] [Item Attribute]
        // [SCENARIO 344524] Item's Attribute Values inherited from Item Categories are not changed on Item Category change when attribute deletion not confirmed
        Initialize();

        // [GIVEN] Created Item Attribute "A"
        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Option, '');

        // [GIVEN] Item Category "C1" with Default Value "V1" for the Item Attribute
        // [GIVEN] Created Item with Item Category "C1"
        LibraryInventory.CreateItem(Item);
        ItemAttributeValueID := SetItemCategoryWithAttributeDefaultValueOnItem(Item, ItemAttribute.ID);

        // [GIVEN] Item Category "C2" with Default Value "V2" for the Item Attribute
        // [WHEN] Set Item's Category to "C2" and don't confirm "Do you want to delete the attributes that are inherited from item category 'C1'?"
        LibraryVariableStorage.Enqueue(
          StrSubstNo(DeleteAttributesInheritedFromOldCategoryQst, Item."Item Category Code"));
        LibraryVariableStorage.Enqueue(false);
        SetItemCategoryWithAttributeDefaultValueOnItem(Item, ItemAttribute.ID);

        // [THEN] Item's Attribute "A" Value = "V1"
        FilterItemAttributeValueMapping(ItemAttributeValueMapping, DATABASE::Item, Item."No.", ItemAttribute.ID);
        ItemAttributeValueMapping.SetRange("Item Attribute Value ID", ItemAttributeValueID);
        Assert.RecordIsNotEmpty(ItemAttributeValueMapping);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ChangeDefaultValueOnChangeParentItemCategoryDeleteConfirmed()
    var
        ItemAttribute: Record "Item Attribute";
        Item: Record Item;
        ItemCategory: Record "Item Category";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemAttributeValueID: Integer;
    begin
        // [FEATURE] [Item Attribute]
        // [SCENARIO 344524] Item's Attribute Values inherited from Parent Item Categories are changed on Item Category parent change when attribute deletion confirmed
        Initialize();

        // [GIVEN] Created Item Attribute "A"
        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Option, '');

        // [GIVEN] Item Category "P1" with Default Value "V1" for the Item Attribute
        // [GIVEN] Item Category "CHILD" with "Parent Category" = "P1"
        // [GIVEN] Created Item with Item Category "CHILD"
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemCategory(ItemCategory);
        Item.Validate("Item Category Code", ItemCategory.Code);
        Item.Modify(true);
        SetParentItemCategoryWithAttributeDefaultValue(ItemCategory, ItemAttribute.ID);

        // [GIVEN] Item Category "P2" with Default Value "V2" for the Item Attribute
        // [WHEN] Set "Parent Category" to "C2" on "CHILD" and confirm Yes on "Do you want to delete the inherited attributes...?"
        LibraryVariableStorage.Enqueue(
          StrSubstNo(DeleteItemInheritedParentCategoryAttributesQst, Item."Item Category Code", ItemCategory."Parent Category"));
        LibraryVariableStorage.Enqueue(true);
        ItemAttributeValueID := SetParentItemCategoryWithAttributeDefaultValue(ItemCategory, ItemAttribute.ID);

        // [THEN] Item's Attribute "A" Value = "V2"
        FilterItemAttributeValueMapping(ItemAttributeValueMapping, DATABASE::Item, Item."No.", ItemAttribute.ID);
        ItemAttributeValueMapping.SetRange("Item Attribute Value ID", ItemAttributeValueID);
        Assert.RecordIsNotEmpty(ItemAttributeValueMapping);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ChangeDefaultValueOnChangeParentItemCategoryDeleteNotConfirmed()
    var
        ItemAttribute: Record "Item Attribute";
        Item: Record Item;
        ItemCategory: Record "Item Category";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemAttributeValueID: Integer;
    begin
        // [FEATURE] [Item Attribute]
        // [SCENARIO 344524] Item's Attribute Values inherited from Parent Item Categories are not changed on Item Category parent change when attribute deletion not confirmed
        Initialize();

        // [GIVEN] Created Item Attribute "A"
        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Option, '');

        // [GIVEN] Item Category "P1" with Default Value "V1" for the Item Attribute
        // [GIVEN] Item Category "CHILD" with "Parent Category" = "P1"
        // [GIVEN] Created Item with Item Category "CHILD"
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemCategory(ItemCategory);
        Item.Validate("Item Category Code", ItemCategory.Code);
        Item.Modify(true);
        ItemAttributeValueID := SetParentItemCategoryWithAttributeDefaultValue(ItemCategory, ItemAttribute.ID);

        // [GIVEN] Item Category "P2" with Default Value "V2" for the Item Attribute
        // [WHEN] Set "Parent Category" to "C2" on "CHILD" and don't confirm on "Do you want to delete the inherited attributes...?"
        LibraryVariableStorage.Enqueue(
          StrSubstNo(DeleteItemInheritedParentCategoryAttributesQst, Item."Item Category Code", ItemCategory."Parent Category"));
        LibraryVariableStorage.Enqueue(false);
        SetParentItemCategoryWithAttributeDefaultValue(ItemCategory, ItemAttribute.ID);

        // [THEN] Item's Attribute "A" Value = "V1"
        FilterItemAttributeValueMapping(ItemAttributeValueMapping, DATABASE::Item, Item."No.", ItemAttribute.ID);
        ItemAttributeValueMapping.SetRange("Item Attribute Value ID", ItemAttributeValueID);
        Assert.RecordIsNotEmpty(ItemAttributeValueMapping);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AttributeWithDateTypeConservesValue()
    var
        ItemAttribute: Record "Item Attribute";
        ItemCategory: Record "Item Category";
        ItemCategories: TestPage "Item Categories";
        ItemCategoryCard: TestPage "Item Category Card";
        Date: Date;
    begin
        // [FEATURE] [Item Attribute]
        // [SCENARIO 356977] When user enters a new value in attribute of type date in Item Category card, closes page and reopens - the value is there.

        // [GIVEN] Item attribute of type date
        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Date, '');

        // [GIVEN] Item category
        LibraryInventory.CreateItemCategory(ItemCategory);

        // [GIVEN] Item category card page was open
        ItemCategoryCard.OpenEdit();
        ItemCategoryCard.FILTER.SetFilter(Code, ItemCategory.Code);

        // [GIVEN] Attribute was added to the category with value = 10-01-2021
        Date := LibraryRandom.RandDate(20);
        ItemCategoryCard.Attributes."Attribute Name".SetValue(ItemAttribute.Name);
        ItemCategoryCard.Attributes.Value.SetValue(Date);

        // [GIVEN] Page was closed
        ItemCategoryCard.Close();

        // [WHEN] Page was open again
        ItemCategories.OpenView();
        ItemCategories.Filter.SetFilter(Code, ItemCategory.Code);
        ItemCategories.First();

        ItemCategoryCard.Trap();
        ItemCategories.View().Invoke();

        // [THEN] Attribute still has value 10-01-2021
        ItemCategoryCard.Attributes.Value.AssertEquals(Date);

        // Cleanup
        ItemCategoryCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemCategoryCodeIsNotEditableOnItemCategoriesPage()
    var
        ItemCategory: Record "Item Category";
        ItemCategories: TestPage "Item Categories";
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 410682] The field Code in page Item Categories must be readonly
        LibraryInventory.CreateItemCategory(ItemCategory);
        ItemCategories.OpenEdit();
        ItemCategories.Filter.SetFilter(Code, ItemCategory.Code);
        ItemCategories.Code.AssertEquals(ItemCategory.Code);

        Assert.IsFalse(ItemCategories.Code.Editable(), 'Wrong');
    end;

    [Test]
    procedure ErrorOnCollectingItemAttributesWhenItemCategoryStructureIsNotValid()
    var
        ItemCategory: Record "Item Category";
        ChildItemCategory: Record "Item Category";
        TempItemAttributeValue: Record "Item Attribute Value" temporary;
    begin
        // [SCENARIO 492883] Error on collecting item attributes when item category structure is not valid.
        Initialize();

        ItemCategory.Init();
        ItemCategory.Code := LibraryUtility.GenerateGUID();
        ItemCategory."Parent Category" := ItemCategory.Code;
        ItemCategory.Insert();

        asserterror TempItemAttributeValue.LoadCategoryAttributesFactBoxData(ItemCategory.Code);
        Assert.ExpectedError(StrSubstNo(CategoryStructureNotValidErr, ItemCategory.Code));

        ItemCategory.Init();
        ItemCategory.Code := LibraryUtility.GenerateGUID();
        ItemCategory.Insert();
        ChildItemCategory.Init();
        ChildItemCategory.Code := LibraryUtility.GenerateGUID();
        ChildItemCategory."Parent Category" := ItemCategory.Code;
        ChildItemCategory.Insert();

        ItemCategory."Parent Category" := ChildItemCategory.Code;
        ItemCategory.Modify();

        asserterror TempItemAttributeValue.LoadCategoryAttributesFactBoxData(ItemCategory.Code);
        Assert.ExpectedError(StrSubstNo(CategoryStructureNotValidErr, ItemCategory.Code));
    end;

    local procedure CreatePairOfItemAttributeValues(var Item: Record Item; var ItemAttributeValue: array[2] of Record "Item Attribute Value"; Type: Option)
    var
        ItemAttribute: Record "Item Attribute";
    begin
        LibraryInventory.CreateItemAttributeWithValue(
          ItemAttribute, ItemAttributeValue[1], Type,
          CopyStr(
            LibraryUtility.GenerateRandomText(MaxStrLen(ItemAttributeValue[1].Value)), 1, MaxStrLen(ItemAttributeValue[1].Value)));

        LibraryInventory.CreateItemAttributeValue(
          ItemAttributeValue[2], ItemAttribute.ID,
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(ItemAttributeValue[2].Value)), 1, MaxStrLen(ItemAttributeValue[2].Value)));

        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemAttributeValueMapping(
          DATABASE::Item, Item."No.", ItemAttribute.ID, ItemAttributeValue[1].ID);
    end;

    local procedure SetNewItemAttributeValue(Item: Record Item; ItemAttributeValue: Record "Item Attribute Value")
    var
        ItemCard: TestPage "Item Card";
    begin
        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);
        ItemAttributeValue.CalcFields("Attribute Name");
        LibraryVariableStorage.Enqueue(ItemAttributeValue."Attribute Name");
        LibraryVariableStorage.Enqueue(ItemAttributeValue.Value);
        ItemCard.Attributes.Invoke();
    end;

    local procedure SetItemCategoryWithAttributeDefaultValueOnItem(var Item: Record Item; ItemAttributeID: Integer): Integer
    var
        ItemCategory: Record "Item Category";
        ItemAttributeValueID: Integer;
    begin
        ItemAttributeValueID := CreateItemCategoryWithItemAttributeValue(ItemCategory, ItemAttributeID);
        Item.Validate("Item Category Code", ItemCategory.Code);
        Item.Modify(true);
        exit(ItemAttributeValueID);
    end;

    local procedure SetParentItemCategoryWithAttributeDefaultValue(var ItemCategory: Record "Item Category"; ItemAttributeID: Integer): Integer
    var
        ParentItemCategory: Record "Item Category";
        ItemAttributeValueID: Integer;
    begin
        ItemAttributeValueID := CreateItemCategoryWithItemAttributeValue(ParentItemCategory, ItemAttributeID);
        ItemCategory.Validate("Parent Category", CreateItemCategory(ParentItemCategory.Code));
        ItemCategory.Modify(true);
        exit(ItemAttributeValueID);
    end;

    local procedure CreateItemCategoryHierarchy(LevelsNumber: Integer)
    var
        ItemCategory: Record "Item Category";
        CurrentLevel: Integer;
    begin
        // creating simple hierarchy of 2 parent categories and 2 children for each
        ItemCategory.DeleteAll();

        if LevelsNumber <= 0 then
            exit;
        CreateItemCategory('');
        CreateItemCategory('');
        for CurrentLevel := 1 to (LevelsNumber - 1) do begin
            ItemCategory.SetRange(Indentation, CurrentLevel - 1);
            if ItemCategory.FindSet() then
                repeat
                    CreateItemCategory(ItemCategory.Code);
                    CreateItemCategory(ItemCategory.Code);
                until ItemCategory.Next() = 0;
        end;
    end;

    local procedure CreateItemCategory(ParentCategory: Code[20]) ItemCategoryCode: Code[20]
    var
        ItemCategoryCard: TestPage "Item Category Card";
    begin
        ItemCategoryCard.OpenNew();
        ItemCategoryCode := LibraryUtility.GenerateGUID();
        ItemCategoryCard.Code.SetValue(ItemCategoryCode);
        ItemCategoryCard.Description.SetValue(Format(ItemCategoryCode + ItemCategoryCode));
        ItemCategoryCard."Parent Category".SetValue(ParentCategory);
        ItemCategoryCard.OK().Invoke();
    end;

    local procedure CreateItemCategoryRec(var ItemCategory: Record "Item Category"; ParentCategoryCode: Code[20])
    begin
        ItemCategory.Init();
        ItemCategory.Code := LibraryUtility.GenerateGUID();
        ItemCategory."Parent Category" := ParentCategoryCode;
        ItemCategory.Insert(true);
    end;

    local procedure CreateItemCategoryWithItemAttributes(var ItemAttributeID: array[2] of Integer): Code[20]
    var
        ItemCategory: Record "Item Category";
    begin
        LibraryInventory.CreateItemCategory(ItemCategory);
        ItemAttributeID[1] := CreateItemAttributeWithValueAndMapping(ItemCategory.Code);
        ItemAttributeID[2] := CreateItemAttributeWithValueAndMapping(ItemCategory.Code);
        exit(ItemCategory.Code);
    end;

    local procedure CreateItemCategoryWithItemAttributeValue(var ItemCategory: Record "Item Category"; ItemAttributeID: Integer): Integer
    var
        ItemAttributeValue: Record "Item Attribute Value";
    begin
        LibraryInventory.CreateItemCategory(ItemCategory);
        LibraryInventory.CreateItemAttributeValue(ItemAttributeValue, ItemAttributeID, LibraryUtility.GenerateGUID());
        LibraryInventory.CreateItemAttributeValueMapping(
          DATABASE::"Item Category", ItemCategory.Code, ItemAttributeID, ItemAttributeValue.ID);
        exit(ItemAttributeValue.ID);
    end;

    local procedure CreateItemAttributeWithValueAndMapping(ItemCategoryCode: Code[20]): Integer
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
    begin
        CreateItemAttributeWithValue(ItemAttribute, ItemAttributeValue);
        LibraryInventory.CreateItemAttributeValueMapping(
          DATABASE::"Item Category", ItemCategoryCode, ItemAttribute.ID, ItemAttributeValue.ID);
        exit(ItemAttribute.ID);
    end;

    local procedure CreateItemAttributeWithValueAndMappingForItem(ItemNo: Code[20]): Integer
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
    begin
        CreateItemAttributeWithValue(ItemAttribute, ItemAttributeValue);
        LibraryInventory.CreateItemAttributeValueMapping(
          DATABASE::Item, ItemNo, ItemAttribute.ID, ItemAttributeValue.ID);
        exit(ItemAttribute.ID);
    end;

    local procedure CreateItemAttributeWithValue(var ItemAttribute: Record "Item Attribute"; var ItemAttributeValue: Record "Item Attribute Value")
    begin
        LibraryInventory.CreateItemAttributeWithValue(
          ItemAttribute, ItemAttributeValue, ItemAttribute.Type::Text, LibraryUtility.GenerateGUID());
    end;

    local procedure CreateItemAttributeValueSelection(var ItemAttributeValue: Record "Item Attribute Value"; var ItemAttributeValueSelection: Record "Item Attribute Value Selection")
    begin
        ItemAttributeValueSelection.InsertRecord(ItemAttributeValue, 0, '');
    end;

    local procedure CreateItemAttributeValueSelectionWithValue(var ItemAttributeValue: Record "Item Attribute Value"; var ItemAttributeValueSelection: Record "Item Attribute Value Selection"; ValueVariant: Variant)
    begin
        ItemAttributeValue.Value := ValueVariant;
        ItemAttributeValueSelection.InsertRecord(ItemAttributeValue, 0, '');
    end;

    local procedure CreateItemsAndAttribsForScenarioWithSortedItems(var ItemAttributeValue: Record "Item Attribute Value"; ItemNoWithAttrib1: Code[20]; ItemNo: Code[20]; ItemNoWithAttrib2: Code[20])
    var
        Item: Record Item;
        ItemAttribute: Record "Item Attribute";
    begin
        CreateItemAttributeWithValue(ItemAttribute, ItemAttributeValue);
        MockItemWithAttribute(ItemNoWithAttrib1, ItemAttributeValue);
        Item."No." := ItemNo;
        Item.Insert();
        MockItemWithAttribute(ItemNoWithAttrib2, ItemAttributeValue);
    end;

    local procedure CreateItemsAndAttribsForFilterTest(var ItemNo: array[5] of Code[20]; var ItemAttributeValue: Record "Item Attribute Value")
    var
        Item: Record Item;
        ItemAttribute: Record "Item Attribute";
        i: Integer;
    begin
        for i := 1 to ArrayLen(ItemNo) do
            ItemNo[i] := 'A00' + Format(i);
        CreateItemAttributeWithValue(ItemAttribute, ItemAttributeValue);
        MockItemWithAttribute(ItemNo[1], ItemAttributeValue);
        Item."No." := ItemNo[2];
        Item.Insert();
        MockItemWithAttribute(ItemNo[3], ItemAttributeValue);
        MockItemWithAttribute(ItemNo[4], ItemAttributeValue);
        MockItemWithAttribute(ItemNo[5], ItemAttributeValue);
    end;

    local procedure CreateItemsAndAttributesForLookupAndFilterTest(var SubString: Text[3])
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        Item: array[3] of Record Item;
        NameValueBuffer: Record "Name/Value Buffer";
        i: Integer;
    begin
        SubString := CopyStr(LibraryUtility.GenerateRandomText(3), 1, MaxStrLen(SubString));
        for i := 1 to ArrayLen(Item) do begin
            LibraryInventory.CreateItem(Item[i]);
            Item[i].Description := 'TEST' + SubString + Format(i);
            Item[i].Modify();
        end;

        LibraryInventory.CreateItemAttributeWithValue(
          ItemAttribute, ItemAttributeValue, ItemAttribute.Type::Text, LibraryUtility.GenerateGUID());

        for i := 1 to ArrayLen(Item) - 1 do
            LibraryInventory.CreateItemAttributeValueMapping(DATABASE::Item, Item[i]."No.", ItemAttribute.ID, ItemAttributeValue.ID);

        NameValueBuffer.DeleteAll();
        NameValueBuffer.Init();
        NameValueBuffer.Name := ItemAttribute.Name;
        NameValueBuffer.Value := ItemAttributeValue.Value;
        NameValueBuffer.Insert();
    end;

    local procedure CreateTestItemAttributes()
    var
        ItemAttribute: Record "Item Attribute";
    begin
        ItemAttribute.DeleteAll();
        CreateTestOptionItemAttribute();
        CreateNonOptionTestItemAttribute(ItemAttribute.Type::Text, '');
    end;

    local procedure CreateTestOptionItemAttribute()
    var
        DummyItemAttribute: Record "Item Attribute";
        ItemAttributes: TestPage "Item Attributes";
        AttributeName: Text;
    begin
        ItemAttributes.OpenNew();
        AttributeName := LibraryUtility.GenerateGUID();
        ItemAttributes.Name.SetValue(LowerCase(AttributeName));
        ItemAttributes.Type.SetValue(DummyItemAttribute.Type::Option);
        CreateTestOptionItemAttributeValues(ItemAttributes);
        ItemAttributes.Close();
    end;

    local procedure CreateNonOptionTestItemAttribute(Type: Option; UoM: Text)
    var
        ItemAttributeCard: TestPage "Item Attribute";
        AttributeName: Text;
    begin
        ItemAttributeCard.OpenNew();
        AttributeName := LibraryUtility.GenerateGUID();
        ItemAttributeCard.Name.SetValue(LowerCase(AttributeName));
        ItemAttributeCard.Type.SetValue(Type);
        ItemAttributeCard."Unit of Measure".SetValue(UoM);
        ItemAttributeCard.Close();
    end;

    local procedure CreateTestOptionItemAttributeValues(var ItemAttributes: TestPage "Item Attributes")
    var
        ItemAttributeValues: TestPage "Item Attribute Values";
        FirstAttributeValueName: Text;
        SecondAttributeValueName: Text;
    begin
        ItemAttributeValues.Trap();
        ItemAttributes.ItemAttributeValues.Invoke();
        ItemAttributeValues.First();
        FirstAttributeValueName := LibraryUtility.GenerateGUID();
        ItemAttributeValues.Value.SetValue(FirstAttributeValueName);
        ItemAttributeValues.Next();
        SecondAttributeValueName := LibraryUtility.GenerateGUID();
        ItemAttributeValues.Value.SetValue(SecondAttributeValueName);
        ItemAttributeValues.Close();
    end;

    local procedure CreateItemWithAttribute(var Item: Record Item; var ItemAttributeValue: Record "Item Attribute Value")
    var
        ItemAttribute: Record "Item Attribute";
    begin
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
          Item, LibraryRandom.RandDecInRange(100, 200, 2), LibraryRandom.RandDecInRange(100, 200, 2));
        CreateItemAttributeWithValue(ItemAttribute, ItemAttributeValue);
        SetItemAttributeValue(Item, ItemAttributeValue);
    end;

    local procedure CountItemsFilteredOnPage(var ItemList: TestPage "Item List") "Count": Integer
    begin
        if ItemList.First() then
            repeat
                Count += 1;
            until ItemList.Next() = false;
        exit(Count);
    end;

    local procedure GetCodeCoverageForObject(ObjectType: Option; ObjectID: Integer; CodeLine: Text) NoOfHits: Integer
    var
        CodeCoverage: Record "Code Coverage";
    begin
        CodeCoverageMgt.Refresh();
        CodeCoverage.SetRange("Line Type", CodeCoverage."Line Type"::Code);
        CodeCoverage.SetRange("Object Type", ObjectType);
        CodeCoverage.SetRange("Object ID", ObjectID);
        CodeCoverage.SetFilter("No. of Hits", '>%1', 0);
        CodeCoverage.SetFilter(Line, '@*' + CodeLine + '*');
        if CodeCoverage.FindSet() then
            repeat
                NoOfHits += CodeCoverage."No. of Hits";
            until CodeCoverage.Next() = 0;
    end;

    local procedure MockItemWithAttribute(ItemNo: Code[20]; ItemAttributeValue: Record "Item Attribute Value")
    var
        Item: Record Item;
    begin
        Item."No." := ItemNo;
        Item.Insert();
        SetItemAttributeValue(Item, ItemAttributeValue);
    end;

    local procedure AssignItemAttributeValueToCategory(ItemCategory: Record "Item Category"; ItemAttribute: Record "Item Attribute"; ItemAttributeValue: Text)
    var
        ItemCategoryCard: TestPage "Item Category Card";
    begin
        ItemCategoryCard.OpenEdit();
        ItemCategoryCard.GotoRecord(ItemCategory);
        ItemCategoryCard.Attributes.New();
        ItemCategoryCard.Attributes."Attribute Name".SetValue(ItemAttribute.Name);
        ItemCategoryCard.Attributes.Value.SetValue(ItemAttributeValue);
        ItemCategoryCard.Close();
    end;

    local procedure SetItemAttributeValue(Item: Record Item; ItemAttributeValue: Record "Item Attribute Value")
    var
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
    begin
        ItemAttributeValueMapping.Init();
        ItemAttributeValueMapping.Validate("No.", Item."No.");
        ItemAttributeValueMapping.Validate("Table ID", DATABASE::Item);
        ItemAttributeValueMapping.Validate("Item Attribute ID", ItemAttributeValue."Attribute ID");
        ItemAttributeValueMapping.Validate("Item Attribute Value ID", ItemAttributeValue.ID);
        ItemAttributeValueMapping.Insert(true);
    end;

    local procedure SetItemCategoryAttributeValue(ItemCategory: Record "Item Category"; ItemAttributeName: Text[250]; AttributeTextValue: Text[10])
    var
        ItemCategoryCard: TestPage "Item Category Card";
    begin
        ItemCategoryCard.OpenEdit();
        ItemCategoryCard.GotoRecord(ItemCategory);
        ItemCategoryCard.Attributes.New();
        ItemCategoryCard.Attributes."Attribute Name".SetValue(ItemAttributeName);
        ItemCategoryCard.Attributes.Value.SetValue(AttributeTextValue);
        ItemCategoryCard.Attributes.Last();
        ItemCategoryCard.Attributes.New();
        ItemCategoryCard.Close();
    end;

    local procedure CheckItemCategoryTreePresentation()
    var
        ItemCategory: Record "Item Category";
        PreviousItemCategory: Record "Item Category";
        ItemCategories: TestPage "Item Categories";
    begin
        ItemCategories.OpenView();
        ExpandTreeStructure(ItemCategories);
        ItemCategories.First();
        repeat
            ItemCategory.Get(ItemCategories.Code.Value);
            if ItemCategory.Indentation = PreviousItemCategory.Indentation then
                Assert.AreEqual(
                  ItemCategory."Parent Category", PreviousItemCategory."Parent Category",
                  StrSubstNo(IncorrectParentErr, ItemCategory.Code, PreviousItemCategory."Parent Category", ItemCategory."Parent Category"))
            else
                if ItemCategory.Indentation > PreviousItemCategory.Indentation then
                    Assert.AreEqual(
                      ItemCategory."Parent Category", PreviousItemCategory.Code,
                      StrSubstNo(IncorrectParentErr, ItemCategory.Code, PreviousItemCategory.Code, ItemCategory."Parent Category"))
                else begin
                    repeat
                        PreviousItemCategory.Get(PreviousItemCategory."Parent Category");
                    until ItemCategory.Indentation = PreviousItemCategory.Indentation;
                    Assert.AreEqual(
                      ItemCategory."Parent Category", PreviousItemCategory."Parent Category",
                      StrSubstNo(IncorrectParentErr, ItemCategory.Code, PreviousItemCategory."Parent Category", ItemCategory."Parent Category"));
                end;
            PreviousItemCategory.Get(ItemCategories.Code.Value);
        until not ItemCategories.Next();
    end;

    local procedure ExpandTreeStructure(var ItemCategories: TestPage "Item Categories")
    begin
        if ItemCategories.First() then
            repeat
                ItemCategories.Expand(true);
            until not ItemCategories.Next();
    end;

    local procedure FilterItemAttributeValueMapping(var ItemAttributeValueMapping: Record "Item Attribute Value Mapping"; TableID: Integer; No: Code[20]; AttributeID: Integer)
    begin
        if TableID <> 0 then
            ItemAttributeValueMapping.SetRange("Table ID", TableID);
        if No <> '' then
            ItemAttributeValueMapping.SetRange("No.", No);
        if AttributeID <> 0 then
            ItemAttributeValueMapping.SetRange("Item Attribute ID", AttributeID);
    end;

    local procedure RunGetItemNoFilterText(ItemAttributeValue: Record "Item Attribute Value"): Text
    var
        TempFilterItemAttributesBuffer: Record "Filter Item Attributes Buffer" temporary;
        TempFilteredItem: Record Item temporary;
        ItemAttributeManagement: Codeunit "Item Attribute Management";
        ParameterCount: Integer;
    begin
        LibraryInventory.CopyItemAttributeToFilterItemAttributesBuffer(TempFilterItemAttributesBuffer, ItemAttributeValue);
        ItemAttributeManagement.FindItemsByAttributes(TempFilterItemAttributesBuffer, TempFilteredItem);
        exit(ItemAttributeManagement.GetItemNoFilterText(TempFilteredItem, ParameterCount));
    end;

    local procedure RunFindItemsByAttributes(ItemAttributeValue: Record "Item Attribute Value"; var TempFilteredItem: Record Item temporary)
    var
        TempFilterItemAttributesBuffer: Record "Filter Item Attributes Buffer" temporary;
        ItemAttributeManagement: Codeunit "Item Attribute Management";
    begin
        LibraryInventory.CopyItemAttributeToFilterItemAttributesBuffer(TempFilterItemAttributesBuffer, ItemAttributeValue);
        ItemAttributeManagement.FindItemsByAttributes(TempFilterItemAttributesBuffer, TempFilteredItem);
    end;

    local procedure FindItemsByMultipleAttributes(var TempFilteredItem: Record Item temporary; ItemAttributeValue: array[3] of Record "Item Attribute Value")
    var
        TempFilterItemAttributesBuffer: Record "Filter Item Attributes Buffer" temporary;
        ItemAttributeManagement: Codeunit "Item Attribute Management";
        i: Integer;
    begin
        for i := 1 to ArrayLen(ItemAttributeValue) do
            LibraryInventory.CopyItemAttributeToFilterItemAttributesBuffer(TempFilterItemAttributesBuffer, ItemAttributeValue[i]);
        ItemAttributeManagement.FindItemsByAttributes(TempFilterItemAttributesBuffer, TempFilteredItem);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    var
        ExpectedQuestion: Text;
    begin
        ExpectedQuestion := LibraryVariableStorage.DequeueText();
        Assert.AreEqual(ExpectedQuestion, Question, '');
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        ExpectedQuestion: Text;
    begin
        ExpectedQuestion := LibraryVariableStorage.DequeueText();
        Assert.AreEqual(ExpectedQuestion, Message, '');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemAttributeValueEditorHandler(var ItemAttributeValueEditor: TestPage "Item Attribute Value Editor")
    begin
        ItemAttributeValueEditor.ItemAttributeValueList."Attribute Name".SetValue(LibraryVariableStorage.DequeueText());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemAttributeValueEditorWithVerificationHandler(var ItemAttributeValueEditor: TestPage "Item Attribute Value Editor")
    begin
        LibraryVariableStorage.Enqueue(ItemAttributeValueEditor.ItemAttributeValueList."Attribute Name".Value);
        LibraryVariableStorage.Enqueue(ItemAttributeValueEditor.ItemAttributeValueList.Value.Value);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemAttributeValueEditorSetNameAndValueHandler(var ItemAttributeValueEditor: TestPage "Item Attribute Value Editor")
    begin
        ItemAttributeValueEditor.ItemAttributeValueList."Attribute Name".SetValue(LibraryVariableStorage.DequeueText());
        ItemAttributeValueEditor.ItemAttributeValueList.Value.SetValue(LibraryVariableStorage.DequeueText());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemListModalPageHandler(var ItemList: TestPage "Item List")
    begin
        LibraryVariableStorage.Enqueue(CountItemsFilteredOnPage(ItemList));

        ItemList.FilterByAttributes.Invoke();
        LibraryVariableStorage.Enqueue(CountItemsFilteredOnPage(ItemList));

        ItemList.ClearAttributes.Invoke();
        LibraryVariableStorage.Enqueue(CountItemsFilteredOnPage(ItemList));

        ItemList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure FilterItemsByAttributeModalPageHandler(var FilterItemsbyAttribute: TestPage "Filter Items by Attribute")
    var
        NameValueBuffer: Record "Name/Value Buffer";
    begin
        FilterItemsbyAttribute.First();
        NameValueBuffer.FindFirst();
        FilterItemsbyAttribute.Attribute.SetValue := NameValueBuffer.Name;
        FilterItemsbyAttribute.Value.SetValue := NameValueBuffer.Value;
        FilterItemsbyAttribute.OK().Invoke();
    end;
}

