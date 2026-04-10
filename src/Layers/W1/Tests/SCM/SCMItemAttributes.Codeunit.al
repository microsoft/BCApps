codeunit 137413 "SCM Item Attributes"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [SCM] [Item Attribute] [UI]
        IsInitialized := false;
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        AttributeValueAlreadySpecifiedErr: Label 'You have already specified a value for item attribute ''%1''.';
        AttributeBlockedErr: Label 'The item attribute ''%1'' is blocked.', Comment = '%1 - arbitrary name';
        AttributeValueBlockedErr: Label 'The item attribute value ''%1'' is blocked.', Comment = '%1 - arbitrary name';
        ReuseValuesAndTranslationsQst: Label 'There are values and translations for item attribute ''%1''.\\Do you want to reuse them after changing the item attribute name to ''%2''?', Comment = '%1 - arbitrary name,%2 - arbitrary name';
        ReuseValueTranslationsQst: Label 'There are translations for item attribute value ''%1''.\\Do you want to reuse these translations for the new value ''%2''?', Comment = '%1 - arbitrary name,%2 - arbitrary name';
        DeleteUsedAttributeQst: Label 'This item attribute has been assigned to at least one item.\\Are you sure you want to delete it?';
        RenameUsedAttributeQst: Label 'This item attribute has been assigned to at least one item.\\Are you sure you want to rename it?';
        DeleteUsedAttributeValueQst: Label 'This item attribute value has been assigned to at least one item.\\Are you sure you want to delete it?';
        RenameUsedAttributeValueQst: Label 'This item attribute value has been assigned to at least one item.\\Are you sure you want to rename it?';
        AttributeValueTypeMismatchErr: Label 'The value ''%1'' does not match the item attribute of type %2.';
        ChangingAttributeTypeErr: Label 'You cannot change the type of item attribute ''%1'', because it is either in use or it has predefined values.', Comment = '%1 - arbirtrary text';
        WrongAttrNameForUnknownLanguageErr: Label 'Default attribute name should be used when the selected system language is not set up';
        IsInitialized: Boolean;
        ItemAttributeValueNotFoundErr: Label 'Item Attribute Value of type %1 and value %2 was not found.';
        MissingAttributeNameErr: Label 'Name must have a value in Item Attribute: ID=0. It cannot be zero or empty.';
        NumericValueShouldNotBeZeroErr: Label 'Numeric Value should not be zero.';


    local procedure CreateItemAndSetOfItemsAttributes(var Item: Record Item)
    begin
        CreateTestOptionItemAttributes();
        LibraryInventory.CreateItem(Item);
    end;

    [Test]
    procedure PopulateItemAttributeValueSelectionWithoutParams()
    var
        ItemWithAttributes: Record Item;
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValueSelection: Record "Item Attribute Value Selection";
        ItemAttributeValue: Record "Item Attribute Value";
        TempItemAttributeValue: Record "Item Attribute Value" temporary;
    begin
        // [FEATURE] [UT]
        Initialize();
        ItemAttributeValueSelection.DeleteAll();

        // [GIVEN] Item 'X' with an attribute exist
        CreateItemAttributeValues(ItemAttributeValue, 1, ItemAttribute.Type::Text);
        LibraryInventory.CreateItem(ItemWithAttributes);
        SetItemAttributeValue(ItemWithAttributes, ItemAttributeValue);
        TempItemAttributeValue.TransferFields(ItemAttributeValue);
        TempItemAttributeValue.Insert();

        // [WHEN] Run PopulateItemAttributeValueSelection() without parameters DefinedOnTableID and DefinedOnKeyValue
        ItemAttributeValueSelection.PopulateItemAttributeValueSelection(TempItemAttributeValue);

        // [THEN] ItemAttributeValueSelection, where "Inherited-From Table ID" = 0, "Inherited-From Key Value" = ''
        ItemAttributeValueSelection.TestField("Inherited-From Table ID", 0);
        ItemAttributeValueSelection.TestField("Inherited-From Key Value", '');
    end;

    [Test]
    procedure PopulateItemAttributeValueSelectionWithParams()
    var
        ItemWithAttributes: Record Item;
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValueSelection: Record "Item Attribute Value Selection";
        ItemAttributeValue: Record "Item Attribute Value";
        TempItemAttributeValue: Record "Item Attribute Value" temporary;
        DefinedOnTableID: Integer;
        DefinedOnKeyValue: Code[20];
    begin
        // [FEATURE] [UT]
        Initialize();
        ItemAttributeValueSelection.DeleteAll();

        // [GIVEN] Item 'X' with an attribute exist
        CreateItemAttributeValues(ItemAttributeValue, 1, ItemAttribute.Type::Text);
        LibraryInventory.CreateItem(ItemWithAttributes);
        SetItemAttributeValue(ItemWithAttributes, ItemAttributeValue);
        DefinedOnTableID := Database::Item;
        DefinedOnKeyValue := ItemWithAttributes."No.";

        // [WHEN] Run PopulateItemAttributeValueSelection() passing DefinedOnTableID and DefinedOnKeyValue
        TempItemAttributeValue.TransferFields(ItemAttributeValue);
        TempItemAttributeValue.Insert();
        ItemAttributeValueSelection.PopulateItemAttributeValueSelection(TempItemAttributeValue, DefinedOnTableID, DefinedOnKeyValue);

        // [THEN] ItemAttributeValueSelection, where "Inherited-From Table ID" = 'Item', "Inherited-From Key Value" = 'X'
        ItemAttributeValueSelection.TestField("Inherited-From Table ID", DefinedOnTableID);
        ItemAttributeValueSelection.TestField("Inherited-From Key Value", DefinedOnKeyValue);
    end;

    [Test]
    [HandlerFunctions('ItemAttributeValueListHandler')]
    [Scope('OnPrem')]
    procedure TestAssignOptionAttributesToItemViaItemCard()
    var
        Item: Record Item;
        FirstItemAttribute: Record "Item Attribute";
        FirstItemAttributeValue: Record "Item Attribute Value";
        SecondItemAttribute: Record "Item Attribute";
        SecondItemAttributeValue: Record "Item Attribute Value";
        ItemCard: TestPage "Item Card";
    begin
        Initialize();

        // [GIVEN] An item and a set of item attributes
        CreateTestOptionItemAttributes();
        LibraryInventory.CreateItem(Item);

        // [WHEN] The user assigns some attribute values to the item
        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);

        FirstItemAttribute.FindFirst();
        AssignItemAttributeViaItemCard(FirstItemAttribute, FirstItemAttributeValue, ItemCard);

        SecondItemAttribute.FindLast();
        AssignItemAttributeViaItemCard(SecondItemAttribute, SecondItemAttributeValue, ItemCard);

        // [THEN] The factbox on the item card shows the names of the chosen attributes and values
        ItemCard.ItemAttributesFactbox.First();
        ItemCard.ItemAttributesFactbox.Attribute.AssertEquals(FirstItemAttribute.Name);
        ItemCard.ItemAttributesFactbox.Value.AssertEquals(FirstItemAttributeValue.Value);
        ItemCard.ItemAttributesFactbox.Last();
        ItemCard.ItemAttributesFactbox.Attribute.AssertEquals(SecondItemAttribute.Name);
        ItemCard.ItemAttributesFactbox.Value.AssertEquals(SecondItemAttributeValue.Value);
    end;

    local procedure TestAssignNonOptionAttributesToItemViaItemCard(ItemAttributeType: Option)
    var
        ItemAttribute: Record "Item Attribute";
        Item1: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        FirstItemAttribute: Record "Item Attribute";
        SecondItemAttribute: Record "Item Attribute";
        ItemCard: TestPage "Item Card";
        FirstItemAttributeValue: Text;
        SecondItemAttributeValue: Text;
    begin
        // [GIVEN] An item and a set of item attributes
        ItemAttribute.DeleteAll();
        LibraryInventory.CreateItemAttribute(FirstItemAttribute, ItemAttributeType, '');
        if ItemAttributeType <> ItemAttribute.Type::Text then
            LibraryInventory.CreateItemAttribute(SecondItemAttribute, ItemAttributeType, LibraryUtility.GenerateGUID())
        else
            LibraryInventory.CreateItemAttribute(SecondItemAttribute, ItemAttributeType, '');
        LibraryInventory.CreateItem(Item1);
        LibraryInventory.CreateItem(Item2);
        LibraryInventory.CreateItem(Item3);

        case ItemAttributeType of
            ItemAttribute.Type::Text:
                begin
                    FirstItemAttributeValue := LibraryUtility.GenerateGUID();
                    SecondItemAttributeValue := LibraryUtility.GenerateGUID();
                end;
            ItemAttribute.Type::Decimal:
                begin
                    FirstItemAttributeValue := Format(LibraryRandom.RandDec(10000, 2));
                    SecondItemAttributeValue := Format(LibraryRandom.RandDec(10000, 2));
                end;
            ItemAttribute.Type::Integer:
                begin
                    FirstItemAttributeValue := Format(LibraryRandom.RandInt(10000));
                    SecondItemAttributeValue := Format(LibraryRandom.RandInt(10000));
                end;
            ItemAttribute.Type::Date:
                begin
                    FirstItemAttributeValue := Format(LibraryUtility.GenerateRandomDate(CalcDate('<-CY>', Today), CalcDate('<CY>', Today)));
                    SecondItemAttributeValue := Format(LibraryUtility.GenerateRandomDate(CalcDate('<-CY>', Today), CalcDate('<CY>', Today)));
                end;
        end;

        // [WHEN] The user assigns some attribute values to the item
        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item1);
        SetItemAttributesViaItemCard(ItemCard, FirstItemAttribute, FirstItemAttributeValue);

        ItemCard.GotoRecord(Item2);
        SetItemAttributesViaItemCard(ItemCard, FirstItemAttribute, FirstItemAttributeValue);

        ItemCard.GotoRecord(Item3);
        SetItemAttributesViaItemCard(ItemCard, SecondItemAttribute, SecondItemAttributeValue);
        ItemCard.Close();

        // [THEN] The factbox on the item card shows the names of the chosen attributes and values
        ItemCard.OpenView();
        ItemCard.GotoRecord(Item1);
        ItemCard.ItemAttributesFactbox.Attribute.AssertEquals(FirstItemAttribute.Name);
        ItemCard.ItemAttributesFactbox.Value.AssertEquals(FirstItemAttributeValue);

        ItemCard.GotoRecord(Item2);
        ItemCard.ItemAttributesFactbox.Attribute.AssertEquals(FirstItemAttribute.Name);
        ItemCard.ItemAttributesFactbox.Value.AssertEquals(FirstItemAttributeValue);

        ItemCard.GotoRecord(Item3);
        ItemCard.ItemAttributesFactbox.Attribute.AssertEquals(SecondItemAttribute.Name);
        if (ItemAttributeType <> ItemAttribute.Type::Text) and (ItemAttributeType <> ItemAttribute.Type::Date) then
            ItemCard.ItemAttributesFactbox.Value.AssertEquals(
              StrSubstNo('%1 %2', SecondItemAttributeValue, SecondItemAttribute."Unit of Measure"))
        else
            ItemCard.ItemAttributesFactbox.Value.AssertEquals(SecondItemAttributeValue);
    end;

    [Test]
    [HandlerFunctions('ItemAttributeValueListHandler')]
    [Scope('OnPrem')]
    procedure TestAssignTextAttributesToItemViaItemCard()
    var
        DummyItemAttribute: Record "Item Attribute";
    begin
        Initialize();

        TestAssignNonOptionAttributesToItemViaItemCard(DummyItemAttribute.Type::Text);
    end;

    [Test]
    [HandlerFunctions('ItemAttributeValueListHandler')]
    [Scope('OnPrem')]
    procedure TestAssignIntegerAttributesToItemViaItemCard()
    var
        DummyItemAttribute: Record "Item Attribute";
    begin
        Initialize();

        TestAssignNonOptionAttributesToItemViaItemCard(DummyItemAttribute.Type::Integer);
    end;

    [Test]
    [HandlerFunctions('ItemAttributeValueListHandler')]
    [Scope('OnPrem')]
    procedure TestAssignDecimalAttributesToItemViaItemCard()
    var
        DummyItemAttribute: Record "Item Attribute";
    begin
        Initialize();

        TestAssignNonOptionAttributesToItemViaItemCard(DummyItemAttribute.Type::Decimal);
    end;

    [Test]
    [HandlerFunctions('ItemAttributeValueListHandler')]
    [Scope('OnPrem')]
    procedure TestAssignDateAttributesToItemViaItemCard()
    var
        DummyItemAttribute: Record "Item Attribute";
    begin
        Initialize();

        TestAssignNonOptionAttributesToItemViaItemCard(DummyItemAttribute.Type::Date);
    end;

    [Test]
    [HandlerFunctions('ItemAttributeValueListHandler')]
    [Scope('OnPrem')]
    procedure TestAssignOptionAttributesThatHaveSameValueNames()
    var
        Item: Record Item;
        FirstItemAttribute: Record "Item Attribute";
        FirstItemAttributeValue: Record "Item Attribute Value";
        SecondItemAttribute: Record "Item Attribute";
        SecondItemAttributeValue: Record "Item Attribute Value";
        ItemCard: TestPage "Item Card";
        FirstItemAttributeValueName: Text[250];
        SecondItemAttributeValueName: Text[250];
    begin
        Initialize();

        // [GIVEN] An item and a set of item attributes
        CreateTestOptionItemAttributes();
        LibraryInventory.CreateItem(Item);

        // [WHEN] The user assigns some attribute values that have same name in different attributes, to the item
        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);

        FirstItemAttribute.FindFirst();
        FirstItemAttributeValue.SetRange("Attribute ID", FirstItemAttribute.ID);
        FirstItemAttributeValue.FindFirst();
        FirstItemAttributeValueName := FirstItemAttributeValue.Value;
        SecondItemAttributeValue.FindLast();
        SecondItemAttributeValueName := SecondItemAttributeValue.Value;
        SetItemAttributesViaItemCard(ItemCard, FirstItemAttribute, FirstItemAttributeValue.Value);

        SecondItemAttribute.FindLast();
        SecondItemAttributeValue.SetRange("Attribute ID", SecondItemAttribute.ID);
        SecondItemAttributeValue.FindFirst();
        SecondItemAttributeValue.Value := FirstItemAttributeValueName;
        SecondItemAttributeValue.Modify();
        SecondItemAttributeValue.FindLast();
        SecondItemAttributeValue.Value := SecondItemAttributeValueName;
        SecondItemAttributeValue.Modify();
        SetItemAttributesViaItemCard(ItemCard, SecondItemAttribute, SecondItemAttributeValue.Value);

        // [THEN] The factbox on the item card shows the names of the chosen attributes and values
        ItemCard.ItemAttributesFactbox.First();
        ItemCard.ItemAttributesFactbox.Attribute.AssertEquals(FirstItemAttribute.Name);
        ItemCard.ItemAttributesFactbox.Value.AssertEquals(FirstItemAttributeValue.Value);
        ItemCard.ItemAttributesFactbox.Last();
        ItemCard.ItemAttributesFactbox.Attribute.AssertEquals(SecondItemAttribute.Name);
        ItemCard.ItemAttributesFactbox.Value.AssertEquals(SecondItemAttributeValue.Value);
    end;

    [Test]
    [HandlerFunctions('ItemAttributeValueListHandler')]
    [Scope('OnPrem')]
    procedure TestAssignOptionAttributesToItemViaItemList()
    var
        Item: Record Item;
        FirstItemAttribute: Record "Item Attribute";
        FirstItemAttributeValue: Record "Item Attribute Value";
        SecondItemAttribute: Record "Item Attribute";
        SecondItemAttributeValue: Record "Item Attribute Value";
        ItemList: TestPage "Item List";
    begin
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();
        // [GIVEN] An item and a set of item attributes
        CreateItemAndSetOfItemsAttributes(Item);
        // [WHEN] The user assigns some attribute values to the item
        ItemList.OpenEdit();
        ItemList.GotoRecord(Item);

        FirstItemAttribute.FindFirst();
        AssignItemAttributeViaItemList(FirstItemAttribute, FirstItemAttributeValue, ItemList);

        SecondItemAttribute.FindLast();
        AssignItemAttributeViaItemList(SecondItemAttribute, SecondItemAttributeValue, ItemList);

        // [THEN] The factbox on the item list shows the names of the chosen attributes and values
        ItemList.ItemAttributesFactBox.First();
        ItemList.ItemAttributesFactBox.Attribute.AssertEquals(FirstItemAttribute.Name);
        ItemList.ItemAttributesFactBox.Value.AssertEquals(FirstItemAttributeValue.Value);
        ItemList.ItemAttributesFactBox.Last();
        ItemList.ItemAttributesFactBox.Attribute.AssertEquals(SecondItemAttribute.Name);
        ItemList.ItemAttributesFactBox.Value.AssertEquals(SecondItemAttributeValue.Value);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOptionAttributeValuesShownOnItemAttributesListAndCard()
    var
        FirstItemAttribute: Record "Item Attribute";
        SecondItemAttribute: Record "Item Attribute";
    begin
        Initialize();

        // [WHEN] The user creates item attributes with some values
        CreateTestOptionItemAttributes();

        // [THEN] The Values field on the Item Attributes list shows the comma separated string with the item attribute values
        FirstItemAttribute.FindFirst();
        CheckOptionItemAttributeValues(FirstItemAttribute);
        SecondItemAttribute.FindLast();
        CheckOptionItemAttributeValues(SecondItemAttribute);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyOptionItemAttributeValuesViaValuesDrilldownOnList()
    var
        FirstItemAttribute: Record "Item Attribute";
        ItemAttributes: TestPage "Item Attributes";
        ItemAttributeCard: TestPage "Item Attribute";
        ItemAttributeValues: TestPage "Item Attribute Values";
    begin
        Initialize();

        // [WHEN] The user creates item attributes with some values
        CreateTestOptionItemAttributes();

        // [THEN] The Values field drilldown on Item Attriobutes window, launches the Item Attribute Values window, in which you can change the attribute values
        FirstItemAttribute.FindFirst();
        ItemAttributes.OpenEdit();
        ItemAttributes.GotoRecord(FirstItemAttribute);
        ItemAttributeCard.Trap();
        ItemAttributes.Edit().Invoke();
        ItemAttributeValues.Trap();
        ItemAttributeCard.Values.DrillDown();
        ItemAttributeValues.New();
        ItemAttributeValues.Value.SetValue(LibraryUtility.GenerateGUID());
        ItemAttributeValues.Close();
        ItemAttributeCard.Close();
        CheckOptionItemAttributeValues(FirstItemAttribute);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyOptionItemAttributeValuesViaValuesDrilldownOnCard()
    var
        FirstItemAttribute: Record "Item Attribute";
        ItemAttributes: TestPage "Item Attributes";
        ItemAttributeValues: TestPage "Item Attribute Values";
    begin
        Initialize();

        // [WHEN] The user creates item attributes with some values
        CreateTestOptionItemAttributes();

        // [THEN] The Values field drilldown on Item Attriobutes window, launches the Item Attribute Values window, in which you can change the attribute values
        FirstItemAttribute.FindFirst();
        ItemAttributes.OpenEdit();
        ItemAttributes.GotoRecord(FirstItemAttribute);
        ItemAttributeValues.Trap();
        ItemAttributes.Values.DrillDown();
        ItemAttributeValues.New();
        ItemAttributeValues.Value.SetValue(LibraryUtility.GenerateGUID());
        ItemAttributeValues.Close();
        CheckOptionItemAttributeValues(FirstItemAttribute);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestReuseTranslationsAfterRenamingOptionItemAttributeValue()
    var
        FirstItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttrValueTranslation: Record "Item Attr. Value Translation";
        Language: Record Language;
        TestLanguageID: Integer;
        TranslatedName: Text[250];
        NewName: Text[250];
    begin
        Initialize();

        // [GIVEN] A set of item attributes
        CreateTestOptionItemAttributes();
        FirstItemAttribute.FindFirst();
        ItemAttributeValue.SetRange("Attribute ID", FirstItemAttribute.ID);
        ItemAttributeValue.FindFirst();

        // [WHEN] The user translates attribute values
        TestLanguageID := 1030;
        Language.SetRange("Windows Language ID", TestLanguageID);
        if Language.FindFirst() then begin
            TranslatedName := InsertOptionItemAttributeValueTranslation(Language, FirstItemAttribute, ItemAttributeValue);

            // [WHEN] The user renames the attribute value
            // [WHEN] The user answers that he wants to reuse the attribute value translations
            NewName := LibraryUtility.GenerateGUID();
            LibraryVariableStorage.Enqueue(StrSubstNo(ReuseValueTranslationsQst, ItemAttributeValue.Value, NewName));
            LibraryVariableStorage.Enqueue(true);
            ItemAttributeValue.Validate(Value, NewName);
            ItemAttributeValue.Modify();

            // [THEN] The underlying attribute value translations are unchanged
            ItemAttrValueTranslation.Get(ItemAttributeValue."Attribute ID", ItemAttributeValue.ID, Language.Code);
            Assert.AreEqual(TranslatedName, ItemAttrValueTranslation.Name, '');
        end;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestDontReuseTranslationsAfterRenamingOptionItemAttributeValue()
    var
        FirstItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttrValueTranslation: Record "Item Attr. Value Translation";
        Language: Record Language;
        NewName: Text[250];
        TestLanguageID: Integer;
    begin
        Initialize();

        // [GIVEN] A set of item attributes
        CreateTestOptionItemAttributes();
        FirstItemAttribute.FindFirst();
        ItemAttributeValue.SetRange("Attribute ID", FirstItemAttribute.ID);
        ItemAttributeValue.FindFirst();

        // [WHEN] The user translates attribute values
        TestLanguageID := 1030;
        Language.SetRange("Windows Language ID", TestLanguageID);
        if Language.FindFirst() then begin
            InsertOptionItemAttributeValueTranslation(Language, FirstItemAttribute, ItemAttributeValue);

            // [WHEN] The user renames the attribute value
            // [WHEN] The user answers that he wants to reuse the attribute value translations
            NewName := LibraryUtility.GenerateGUID();
            LibraryVariableStorage.Enqueue(StrSubstNo(ReuseValueTranslationsQst, ItemAttributeValue.Value, NewName));
            LibraryVariableStorage.Enqueue(false);
            ItemAttributeValue.Validate(Value, NewName);
            ItemAttributeValue.Modify();

            // [THEN] The underlying attribute value translations are deleted
            Assert.IsFalse(ItemAttrValueTranslation.Get(ItemAttributeValue."Attribute ID", ItemAttributeValue.ID, Language.Code), '');
        end;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestReuseValuesAfterRenamingOptionItemAttribute()
    var
        FirstItemAttribute: Record "Item Attribute";
        Values: Text;
        NewName: Text[250];
    begin
        Initialize();

        // [GIVEN] A set of item attributes
        CreateTestOptionItemAttributes();
        FirstItemAttribute.FindFirst();
        Values := FirstItemAttribute.GetValues();

        // [WHEN] The user renames an attribute
        // [WHEN] The user answers that he wants to reuse the attribute values
        NewName := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(StrSubstNo(ReuseValuesAndTranslationsQst, FirstItemAttribute.Name, NewName));
        LibraryVariableStorage.Enqueue(true);
        FirstItemAttribute.Validate(Name, NewName);
        FirstItemAttribute.Modify();

        // [THEN] The underlying attribute values are unchanged
        Assert.AreEqual(Values, FirstItemAttribute.GetValues(), '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestDontReuseValuesAfterRenamingOptionItemAttribute()
    var
        FirstItemAttribute: Record "Item Attribute";
        Values: Text;
        NewName: Text[250];
    begin
        Initialize();

        // [GIVEN] A set of item attributes
        CreateTestOptionItemAttributes();
        FirstItemAttribute.FindFirst();
        Values := FirstItemAttribute.GetValues();
        Assert.AreNotEqual('', Values, '');

        // [WHEN] The user renames an attribute
        // [WHEN] The user answers that he doesn't want to reuse the attribute values
        NewName := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(StrSubstNo(ReuseValuesAndTranslationsQst, FirstItemAttribute.Name, NewName));
        LibraryVariableStorage.Enqueue(false);
        FirstItemAttribute.Validate(Name, NewName);
        FirstItemAttribute.Modify();

        // [THEN] The underlying attribute values are deleted
        Assert.AreEqual('', FirstItemAttribute.GetValues(), '');
    end;

    [Test]
    [HandlerFunctions('ItemAttributeValueListHandler')]
    [Scope('OnPrem')]
    procedure TestBlockedAttributesShownInItemAttributesFactbox()
    var
        Item: Record Item;
        FirstItemAttribute: Record "Item Attribute";
        FirstItemAttributeValue: Record "Item Attribute Value";
        ItemList: TestPage "Item List";
    begin
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();
        // [GIVEN] An item and a set of item attributes
        CreateItemAndSetOfItemsAttributes(Item);
        // [WHEN] The user assigns some attribute values to the item
        ItemList.OpenEdit();
        ItemList.GotoRecord(Item);
        FirstItemAttribute.FindFirst();
        AssignItemAttributeViaItemList(FirstItemAttribute, FirstItemAttributeValue, ItemList);
        ItemList.Close();

        // [WHEN] The user blocks the assigned attribute or value
        FirstItemAttribute.Blocked := true;
        FirstItemAttribute.Modify();
        FirstItemAttributeValue.Blocked := true;
        FirstItemAttributeValue.Modify();

        // [THEN] The factbox on the item list still shows the name of the blocked attribute and value
        ItemList.OpenView();
        ItemList.GotoRecord(Item);
        ItemList.ItemAttributesFactBox.First();
        ItemList.ItemAttributesFactBox.Attribute.AssertEquals(FirstItemAttribute.Name);
        ItemList.ItemAttributesFactBox.Value.AssertEquals(FirstItemAttributeValue.Value);
    end;

    [Test]
    [HandlerFunctions('ItemAttributeValueSetBlockedAttributeError')]
    [Scope('OnPrem')]
    procedure TestBlockedAttributesCannotBeNewlyAssigned()
    var
        Item: Record Item;
        FirstItemAttribute: Record "Item Attribute";
        FirstItemAttributeValue: Record "Item Attribute Value";
        ItemList: TestPage "Item List";
    begin
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();
        // [GIVEN] An item and a set of item attributes
        CreateItemAndSetOfItemsAttributes(Item);
        // [WHEN] The user assigns some attribute values to the item
        ItemList.OpenEdit();
        ItemList.GotoRecord(Item);
        FirstItemAttribute.FindLast();
        FirstItemAttributeValue.SetRange("Attribute ID", FirstItemAttribute.ID);
        FirstItemAttributeValue.FindLast();

        // [WHEN] The user blocks the assigned attribute
        FirstItemAttribute.Blocked := true;
        FirstItemAttribute.Modify();

        // [THEN] The user cannot set the blocked attributes on items (verified in the modal page handler methods)
        SetItemAttributesViaItemList(ItemList, FirstItemAttribute, FirstItemAttributeValue.Value);
    end;

    [Test]
    [HandlerFunctions('ItemAttributeValueSetBlockedAttributeValueError')]
    [Scope('OnPrem')]
    procedure TestBlockedAttributeValuesCannotBeNewlyAssigned()
    var
        Item: Record Item;
        FirstItemAttribute: Record "Item Attribute";
        FirstItemAttributeValue: Record "Item Attribute Value";
        ItemList: TestPage "Item List";
    begin
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();
        // [GIVEN] An item and a set of item attributes
        CreateItemAndSetOfItemsAttributes(Item);
        // [WHEN] The user assigns some attribute values to the item
        ItemList.OpenEdit();
        ItemList.GotoRecord(Item);
        FirstItemAttribute.FindFirst();
        FirstItemAttributeValue.SetRange("Attribute ID", FirstItemAttribute.ID);
        FirstItemAttributeValue.FindFirst();

        // [WHEN] The user blocks the assigned attribute value
        FirstItemAttributeValue.Blocked := true;
        FirstItemAttributeValue.Modify();

        // [THEN] The user cannot set the blocked attribute value on items (verified in the modal page handler methods)
        SetItemAttributesViaItemList(ItemList, FirstItemAttribute, FirstItemAttributeValue.Value);
    end;

    [Test]
    [HandlerFunctions('ItemAttributeValueListHandler')]
    [Scope('OnPrem')]
    procedure TestDeletedAttributesNotShownInItemAttributesFactbox()
    var
        Item: Record Item;
        FirstItemAttribute: Record "Item Attribute";
        DummyItemAttributeValue: Record "Item Attribute Value";
        ItemList: TestPage "Item List";
    begin
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();
        // [GIVEN] An item and a set of item attributes
        CreateItemAndSetOfItemsAttributes(Item);
        // [WHEN] The user assigns some attribute values to the item
        ItemList.OpenEdit();
        ItemList.GotoRecord(Item);
        FirstItemAttribute.FindFirst();
        AssignItemAttributeViaItemList(FirstItemAttribute, DummyItemAttributeValue, ItemList);
        ItemList.Close();

        // [WHEN] The user deletes the assigned attribute value
        DummyItemAttributeValue.DeleteAll();

        // [THEN] The factbox on the item list doesn't show the name of the deleted attribute and value
        ItemList.OpenView();
        ItemList.GotoRecord(Item);
        ItemList.ItemAttributesFactBox.First();
        ItemList.ItemAttributesFactBox.Attribute.AssertEquals('');
        ItemList.ItemAttributesFactBox.Value.AssertEquals('');
    end;

    [Test]
    [HandlerFunctions('ItemAttributeValueListHandler')]
    [Scope('OnPrem')]
    procedure TestRenamedAttributesShownInItemAttributesFactbox()
    var
        Item: Record Item;
        FirstItemAttribute: Record "Item Attribute";
        FirstItemAttributeValue: Record "Item Attribute Value";
        ItemList: TestPage "Item List";
        NewAttributeCode: Text;
        NewValueCode: Text;
    begin
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();
        // [GIVEN] An item and a set of item attributes
        CreateItemAndSetOfItemsAttributes(Item);
        // [WHEN] The user assigns some attribute values to the item
        ItemList.OpenEdit();
        ItemList.GotoRecord(Item);
        FirstItemAttribute.FindFirst();
        AssignItemAttributeViaItemList(FirstItemAttribute, FirstItemAttributeValue, ItemList);
        ItemList.Close();

        // [WHEN] The user renames the assigned attribute or value
        NewAttributeCode := LibraryUtility.GenerateGUID();
        FirstItemAttribute.Name := LowerCase(NewAttributeCode);
        FirstItemAttribute.Modify(true);
        NewValueCode := LibraryUtility.GenerateGUID();
        FirstItemAttributeValue.Value := LowerCase(NewValueCode);
        FirstItemAttributeValue.Modify();

        // [THEN] The factbox on the item list still shows the new name of the attribute and value
        ItemList.OpenView();
        ItemList.GotoRecord(Item);
        ItemList.ItemAttributesFactBox.First();
        ItemList.ItemAttributesFactBox.Attribute.AssertEquals(LowerCase(NewAttributeCode));
        ItemList.ItemAttributesFactBox.Value.AssertEquals(LowerCase(NewValueCode));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAttributesFactboxWithTranslatedAndNonTranslatedAttributes()
    var
        Item: Record Item;
        FirstItemAttribute: Record "Item Attribute";
        FirstItemAttributeValue: Record "Item Attribute Value";
        SecondItemAttribute: Record "Item Attribute";
        SecondItemAttributeValue: Record "Item Attribute Value";
        Language: Record Language;
        ItemList: TestPage "Item List";
        ItemAttributes: TestPage "Item Attributes";
        ItemAttributeTranslations: TestPage "Item Attribute Translations";
        ItemAttributeValues: TestPage "Item Attribute Values";
        ItemAttrValueTranslations: TestPage "Item Attr. Value Translations";
        TestLanguageID: Integer;
        TranslationPrefix: Text[250];
        OriginalLanguageID: Integer;
    begin
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();
        // [GIVEN] An item and a set of item attributes
        CreateItemAndSetOfItemsAttributes(Item);
        OriginalLanguageID := GlobalLanguage;
        TestLanguageID := 1030;
        TranslationPrefix := 'Danish';

        // [WHEN] The user assigns some attribute values to the item
        SecondItemAttribute.FindLast();
        SecondItemAttributeValue.SetRange("Attribute ID", SecondItemAttribute.ID);
        SecondItemAttributeValue.FindFirst();
        LibraryInventory.CreateItemAttributeValueMapping(DATABASE::Item, Item."No.", SecondItemAttribute.ID, SecondItemAttributeValue.ID);

        FirstItemAttribute.FindFirst();
        FirstItemAttributeValue.SetRange("Attribute ID", FirstItemAttribute.ID);
        FirstItemAttributeValue.FindFirst();
        LibraryInventory.CreateItemAttributeValueMapping(DATABASE::Item, Item."No.", FirstItemAttribute.ID, FirstItemAttributeValue.ID);

        // [WHEN] The user translates the assigned attribute or value, and switches the global language
        ItemAttributes.OpenEdit();
        ItemAttributes.GotoRecord(FirstItemAttribute);
        ItemAttributeTranslations.Trap();
        ItemAttributes.ItemAttributeTranslations.Invoke();
        ItemAttributeTranslations.New();

        Language.SetRange("Windows Language ID", TestLanguageID);
        if Language.FindFirst() then begin
            ItemAttributeTranslations."Language Code".SetValue(Language.Code);
            ItemAttributeTranslations.Name.SetValue(TranslationPrefix + FirstItemAttribute.Name);
            ItemAttributeTranslations.OK().Invoke();
            ItemAttributeValues.Trap();
            ItemAttributes.ItemAttributeValues.Invoke();
            ItemAttributeValues.FindFirstField(Value, FirstItemAttributeValue.Value);
            ItemAttrValueTranslations.Trap();
            ItemAttributeValues.ItemAttributeValueTranslations.Invoke();
            ItemAttrValueTranslations.New();
            ItemAttrValueTranslations."Language Code".SetValue(Language.Code);
            ItemAttrValueTranslations.Name.SetValue(TranslationPrefix + FirstItemAttributeValue.Value);
            ItemAttrValueTranslations.OK().Invoke();
            GlobalLanguage := TestLanguageID;

            // [THEN] The factbox on the item list shows the translated name of the attribute and value
            ItemList.OpenView();
            ItemList.GotoRecord(Item);
            ItemList.ItemAttributesFactBox.First();
            ItemList.ItemAttributesFactBox.Attribute.AssertEquals(TranslationPrefix + FirstItemAttribute.Name);
            ItemList.ItemAttributesFactBox.Value.AssertEquals(TranslationPrefix + FirstItemAttributeValue.Value);
            ItemList.ItemAttributesFactBox.Last();
            ItemList.ItemAttributesFactBox.Attribute.AssertEquals(SecondItemAttribute.Name);
            ItemList.ItemAttributesFactBox.Value.AssertEquals(SecondItemAttributeValue.Value);

            // cleanup
            GlobalLanguage := OriginalLanguageID;
        end;
    end;

    [Test]
    [HandlerFunctions('ItemAttributeValueListHandler')]
    [Scope('OnPrem')]
    procedure TestOnlyOneValueForTheAttributeCanBeAssignedToItem()
    var
        Item: Record Item;
        FirstItemAttribute: Record "Item Attribute";
        FirstItemAttributeValue: Record "Item Attribute Value";
        SecondItemAttributeValue: Record "Item Attribute Value";
        ItemCard: TestPage "Item Card";
    begin
        Initialize();

        // [GIVEN] An item and a set of item attributes
        LibraryInventory.CreateItem(Item);
        CreateTestOptionItemAttributes();

        // [WHEN] The user assigns some attribute values to the item
        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);

        FirstItemAttribute.FindFirst();
        AssignItemAttributeViaItemCard(FirstItemAttribute, FirstItemAttributeValue, ItemCard);

        // [WHEN] The user assigns the same attribute value to the item again
        SecondItemAttributeValue.SetRange("Attribute ID", FirstItemAttribute.ID);
        SecondItemAttributeValue.FindLast();

        // [THEN] The user gets an error message
        asserterror SetItemAttributesViaItemCard(ItemCard, FirstItemAttribute, SecondItemAttributeValue.Value);
        Assert.ExpectedError(StrSubstNo(AttributeValueAlreadySpecifiedErr, FirstItemAttribute.Name));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestValidationErrForIntegerAttribute()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValueSelection: Record "Item Attribute Value Selection";
        Item: Record Item;
        InvalidValue: Text[250];
    begin
        Initialize();

        CreateTestIntegerItemAttributes();
        ItemAttribute.FindFirst();
        LibraryInventory.CreateItem(Item);
        InvalidValue := Format(LibraryRandom.RandDec(1000, 2));

        ItemAttributeValueSelection.Validate("Attribute ID", ItemAttribute.ID);
        ItemAttributeValueSelection.Validate("Attribute Type", ItemAttributeValueSelection."Attribute Type"::Integer);
        asserterror ItemAttributeValueSelection.Validate(Value, InvalidValue);

        Assert.ExpectedError(StrSubstNo(AttributeValueTypeMismatchErr, InvalidValue, ItemAttribute.Type));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestValidationErrForDecimalAttribute()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValueSelection: Record "Item Attribute Value Selection";
        Item: Record Item;
        InvalidValue: Text[250];
    begin
        Initialize();

        CreateTestDecimalItemAttributes();
        ItemAttribute.FindFirst();
        LibraryInventory.CreateItem(Item);
        InvalidValue := LibraryUtility.GenerateGUID();

        ItemAttributeValueSelection.Validate("Attribute ID", ItemAttribute.ID);
        ItemAttributeValueSelection.Validate("Attribute Type", ItemAttributeValueSelection."Attribute Type"::Decimal);
        asserterror ItemAttributeValueSelection.Validate(Value, InvalidValue);

        Assert.ExpectedError(StrSubstNo(AttributeValueTypeMismatchErr, InvalidValue, ItemAttribute.Type));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestValidationErrForDateAttribute()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValueSelection: Record "Item Attribute Value Selection";
        Item: Record Item;
        InvalidValue: Text[250];
    begin
        Initialize();

        CreateTestDecimalItemAttributes();
        ItemAttribute.FindFirst();
        LibraryInventory.CreateItem(Item);
        InvalidValue := LibraryUtility.GenerateGUID();

        ItemAttributeValueSelection.Validate("Attribute ID", ItemAttribute.ID);
        ItemAttributeValueSelection.Validate("Attribute Type", ItemAttributeValueSelection."Attribute Type"::Date);
        asserterror ItemAttributeValueSelection.Validate(Value, InvalidValue);

        Assert.ExpectedError(StrSubstNo(AttributeValueTypeMismatchErr, InvalidValue, ItemAttribute.Type));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChangeTypeErrOptionAttributeWithValues()
    var
        DummyItemAttribute: Record "Item Attribute";
    begin
        Initialize();

        CreateTestOptionItemAttributes();
        DummyItemAttribute.FindFirst();
        asserterror DummyItemAttribute.Validate(Type, DummyItemAttribute.Type::Integer);
        Assert.ExpectedError(StrSubstNo(ChangingAttributeTypeErr, DummyItemAttribute.Name));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChangeTypeErrNonOptionAttributeWithValues()
    var
        ItemAttribute: Record "Item Attribute";
        DummyItemAttributeValue: Record "Item Attribute Value";
    begin
        Initialize();

        CreateTestIntegerItemAttributes();
        ItemAttribute.FindFirst();
        DummyItemAttributeValue."Attribute ID" := ItemAttribute.ID;
        DummyItemAttributeValue.Value := Format(LibraryRandom.RandInt(1000));
        DummyItemAttributeValue.Insert();
        asserterror ItemAttribute.Validate(Type, ItemAttribute.Type::Decimal);
        Assert.ExpectedError(StrSubstNo(ChangingAttributeTypeErr, ItemAttribute.Name));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestDeleteAttributeInUse()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
    begin
        // [SCENARIO] Item attribue assigned to an item should not be deleted after deletion is confirmed

        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();
        // [GIVEN] An item and a set of item attributes
        CreateItemWithIntegerAttribute(ItemAttributeValue);

        // [WHEN] User deletes the attribute assigned to item
        ItemAttribute.Get(ItemAttributeValue."Attribute ID");
        LibraryVariableStorage.Enqueue(DeleteUsedAttributeQst);
        LibraryVariableStorage.Enqueue(true);
        ItemAttribute.Delete(true);

        // [THEN] Attribute is not deleted
        Assert.IsFalse(ItemAttribute.Get(ItemAttributeValue."Attribute ID"), 'Item Attribute was not deleted!');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestDeleteAttributeValueInUse()
    var
        ItemAttributeValue: Record "Item Attribute Value";
    begin
        // [SCENARIO] Item attribue value assigned to an item should not be deleted after deletion is confirmed

        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();
        // [GIVEN] An item and a set of item attributes
        CreateItemWithIntegerAttribute(ItemAttributeValue);

        // [WHEN] User deletes the attribute value assigned to item
        LibraryVariableStorage.Enqueue(DeleteUsedAttributeValueQst);
        LibraryVariableStorage.Enqueue(true);
        ItemAttributeValue.Delete(true);

        // [THEN] Attribute value is not deleted
        Assert.IsFalse(ItemAttributeValue.Get(ItemAttributeValue.ID), 'Item Attribute was not deleted!');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestRenameAttributeInUse()
    var
        Item: Record Item;
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        NewName: Text[250];
    begin
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();
        // [GIVEN] An item and a set of item attributes
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Integer, '');
        LibraryInventory.CreateItemAttributeValue(ItemAttributeValue, ItemAttribute.ID, Format(LibraryRandom.RandInt(100)));

        // [WHEN] The user assigns some attribute values to the item
        LibraryInventory.CreateItemAttributeValueMapping(DATABASE::Item, Item."No.", ItemAttribute.ID, ItemAttributeValue.ID);

        NewName := LibraryUtility.GenerateGUID();

        LibraryVariableStorage.Enqueue(RenameUsedAttributeQst);
        LibraryVariableStorage.Enqueue(true);

        LibraryVariableStorage.Enqueue(StrSubstNo(ReuseValuesAndTranslationsQst, ItemAttribute.Name, NewName));
        LibraryVariableStorage.Enqueue(true);
        ItemAttribute.Validate(Name, NewName);
        ItemAttribute.Modify();

        ItemAttribute.Get(ItemAttribute.ID);
        Assert.AreEqual(NewName, ItemAttribute.Name, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestRenameAttributeValueInUse()
    var
        Item: Record Item;
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        NewValue: Text[250];
    begin
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();
        // [GIVEN] An item and a set of item attributes
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Text, '');
        LibraryInventory.CreateItemAttributeValue(ItemAttributeValue, ItemAttribute.ID, LibraryUtility.GenerateGUID());

        // [WHEN] The user assigns some attribute values to the item
        LibraryInventory.CreateItemAttributeValueMapping(DATABASE::Item, Item."No.", ItemAttribute.ID, ItemAttributeValue.ID);

        NewValue := LibraryUtility.GenerateGUID();

        LibraryVariableStorage.Enqueue(RenameUsedAttributeValueQst);
        LibraryVariableStorage.Enqueue(true);

        LibraryVariableStorage.Enqueue(StrSubstNo(ReuseValueTranslationsQst, ItemAttributeValue.Value, NewValue));
        LibraryVariableStorage.Enqueue(true);
        ItemAttributeValue.Validate(Value, NewValue);
        ItemAttributeValue.Modify();

        ItemAttributeValue.SetRange("Attribute ID", ItemAttribute.ID);
        ItemAttributeValue.FindFirst();
        Assert.AreEqual(NewValue, ItemAttributeValue.Value, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUoMNotShownForTextAndOptionAttributes()
    var
        DummyItemAttribute: Record "Item Attribute";
        ItemAttributeCard: TestPage "Item Attribute";
        AttributeName: Text;
    begin
        Initialize();

        ItemAttributeCard.OpenNew();
        AttributeName := LibraryUtility.GenerateGUID();
        ItemAttributeCard.Name.SetValue(LowerCase(AttributeName));
        ItemAttributeCard.Type.SetValue(DummyItemAttribute.Type::Text);
        Assert.IsFalse(ItemAttributeCard."Unit of Measure".Visible(), 'UoF Field is shown while it should be invisible');
        ItemAttributeCard.Type.SetValue(DummyItemAttribute.Type::Option);
        Assert.IsFalse(ItemAttributeCard."Unit of Measure".Visible(), 'UoF Field is shown while it should be invisible');
        ItemAttributeCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestValuesNotShownForNonOptionAttributes()
    var
        DummyItemAttribute: Record "Item Attribute";
        ItemAttributeCard: TestPage "Item Attribute";
        AttributeName: Text;
    begin
        Initialize();

        ItemAttributeCard.OpenNew();
        AttributeName := LibraryUtility.GenerateGUID();
        ItemAttributeCard.Name.SetValue(LowerCase(AttributeName));
        ItemAttributeCard.Type.SetValue(DummyItemAttribute.Type::Text);
        Assert.IsFalse(ItemAttributeCard.Values.Visible(), 'Values field is shown while it should be invisible');
        ItemAttributeCard.Type.SetValue(DummyItemAttribute.Type::Integer);
        Assert.IsFalse(ItemAttributeCard.Values.Visible(), 'Values field is shown while it should be invisible');
        ItemAttributeCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVisibilityInApplicationAreas()
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
    begin
        Initialize();

        VerifyVisibilityInApplicationArea(ExperienceTierSetup.FieldCaption(Basic));
        VerifyVisibilityInApplicationArea(ExperienceTierSetup.FieldCaption(Essential));
    end;

    [Test]
    [HandlerFunctions('ItemAttributeValueListHandler')]
    [Scope('OnPrem')]
    procedure TestChangeTextAttributesOnItem()
    var
        DummyItemAttribute: Record "Item Attribute";
    begin
        Initialize();

        TestChangeAttributesOnItem(DummyItemAttribute.Type::Text);
    end;

    [Test]
    [HandlerFunctions('ItemAttributeValueListHandler')]
    [Scope('OnPrem')]
    procedure TestChangeIntegerAttributesOnItem()
    var
        DummyItemAttribute: Record "Item Attribute";
    begin
        Initialize();

        TestChangeAttributesOnItem(DummyItemAttribute.Type::Integer);
    end;

    [Test]
    [HandlerFunctions('ItemAttributeValueListHandler')]
    [Scope('OnPrem')]
    procedure TestChangeDecimalAttributesOnItem()
    var
        DummyItemAttribute: Record "Item Attribute";
    begin
        Initialize();

        TestChangeAttributesOnItem(DummyItemAttribute.Type::Decimal);
    end;

    [Test]
    [HandlerFunctions('ItemAttributeValueListHandler')]
    [Scope('OnPrem')]
    procedure TestChangeOptionAttributesOnItem()
    var
        DummyItemAttribute: Record "Item Attribute";
    begin
        Initialize();

        TestChangeAttributesOnItem(DummyItemAttribute.Type::Option);
    end;

    [Test]
    [HandlerFunctions('ItemAttributeValueListHandler')]
    [Scope('OnPrem')]
    procedure TestChangeDateAttributesOnItem()
    var
        DummyItemAttribute: Record "Item Attribute";
    begin
        Initialize();

        TestChangeAttributesOnItem(DummyItemAttribute.Type::Date);
    end;

    local procedure TestChangeAttributesOnItem(ItemAttributeType: Option)
    var
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttribute: Record "Item Attribute";
        Item: Record Item;
        ItemCard: TestPage "Item Card";
        FirstItemAttributeValue: Text;
        SecondItemAttributeValue: Text;
        OriginalAttributeValueID: Integer;
    begin
        // [GIVEN] An item and a set of item attributes
        ItemAttribute.DeleteAll();
        LibraryVariableStorage.Clear();
        if ItemAttributeType = ItemAttribute.Type::Option then
            CreateTestOptionItemAttributes()
        else
            LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttributeType, '');
        LibraryInventory.CreateItem(Item);

        ItemAttribute.FindFirst();

        case ItemAttributeType of
            ItemAttribute.Type::Text:
                begin
                    FirstItemAttributeValue := LibraryUtility.GenerateGUID();
                    SecondItemAttributeValue := LibraryUtility.GenerateGUID();
                end;
            ItemAttribute.Type::Decimal:
                begin
                    FirstItemAttributeValue := Format(LibraryRandom.RandDec(10000, 2));
                    SecondItemAttributeValue := Format(LibraryRandom.RandDec(10000, 2));
                end;
            ItemAttribute.Type::Integer:
                begin
                    FirstItemAttributeValue := Format(LibraryRandom.RandInt(10000));
                    SecondItemAttributeValue := Format(LibraryRandom.RandInt(10000));
                end;
            ItemAttribute.Type::Option:
                begin
                    ItemAttributeValue.SetRange("Attribute ID", ItemAttribute.ID);
                    ItemAttributeValue.FindFirst();
                    FirstItemAttributeValue := ItemAttributeValue.Value;
                    ItemAttributeValue.FindLast();
                    SecondItemAttributeValue := ItemAttributeValue.Value;
                end;
            ItemAttribute.Type::Date:
                begin
                    FirstItemAttributeValue := Format(LibraryUtility.GenerateRandomDate(CalcDate('<-CY>', Today), CalcDate('<CY>', Today)));
                    SecondItemAttributeValue := Format(LibraryUtility.GenerateRandomDate(CalcDate('<-CY>', Today), CalcDate('<CY>', Today)));
                end;
        end;

        // [WHEN] The user assigns and then changes some attribute values to the item
        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);
        SetItemAttributesViaItemCard(ItemCard, ItemAttribute, FirstItemAttributeValue);
        ItemAttributeValueMapping.SetRange("Table ID", DATABASE::Item);
        ItemAttributeValueMapping.SetRange("No.", Item."No.");
        ItemAttributeValueMapping.SetRange("Item Attribute ID", ItemAttribute.ID);
        ItemAttributeValueMapping.FindFirst();
        OriginalAttributeValueID := ItemAttributeValueMapping."Item Attribute Value ID";
        ItemAttributeValueMapping.Delete(true);
        SetItemAttributesViaItemCard(ItemCard, ItemAttribute, SecondItemAttributeValue);
        ItemCard.Close();

        // [THEN] The factbox on the item card shows the names of the changed attributes and values
        ItemCard.OpenView();
        ItemCard.GotoRecord(Item);
        ItemCard.ItemAttributesFactbox.Attribute.AssertEquals(ItemAttribute.Name);
        ItemCard.ItemAttributesFactbox.Value.AssertEquals(SecondItemAttributeValue);

        // [THEN] The unused value is removed from Item Attribute Value table, if and only if the type of the attribute is not Option
        ItemAttributeValue.SetRange(ID, OriginalAttributeValueID);
        Assert.AreEqual(ItemAttribute.Type <> ItemAttribute.Type::Option, ItemAttributeValue.IsEmpty, '');
    end;

    [Test]
    [HandlerFunctions('FilterItemAttributesHandler')]
    [Scope('OnPrem')]
    procedure TestSpecifyingSingleFilter()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemWithAttributes: Record Item;
        ItemNoAttributes: Record Item;
        ItemList: TestPage "Item List";
    begin
        Initialize();

        // [GIVEN] An item with an single attribute
        CreateItemAttributeValues(ItemAttributeValue, 1, ItemAttribute.Type::Option);
        LibraryInventory.CreateItem(ItemWithAttributes);
        SetItemAttributeValue(ItemWithAttributes, ItemAttributeValue);
        LibraryInventory.CreateItem(ItemNoAttributes);

        // [WHEN] The user sets filters on the page
        InvokeFindByAttributes(ItemList, ItemAttributeValue);

        // [THEN] An single item is shown
        Assert.AreEqual(ItemWithAttributes."No.", ItemList.FILTER.GetFilter("No."), 'Wrong filter was set');
        ItemList.First();
        Assert.AreEqual(ItemWithAttributes."No.", ItemList."No.".Value, 'Wrong ItemAttribute was shown');
        Assert.IsFalse(ItemList.Next(), 'There should not be any records present in the list');
    end;

    [Test]
    [HandlerFunctions('FilterItemAttributesHandler')]
    [Scope('OnPrem')]
    procedure TestFindingMultipleItems()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttributeValue2: Record "Item Attribute Value";
        ItemWithAttributes: Record Item;
        ItemWithAttributes2: Record Item;
        ItemNoAttributes: Record Item;
        ItemList: TestPage "Item List";
    begin
        Initialize();

        // [GIVEN] Two items with the same attribute exist
        CreateItemAttributeValues(ItemAttributeValue, 1, ItemAttribute.Type::Text);
        CreateItemAttributeValues(ItemAttributeValue2, 10, ItemAttribute.Type::Text);

        LibraryInventory.CreateItem(ItemWithAttributes);
        SetItemAttributeValue(ItemWithAttributes, ItemAttributeValue);

        LibraryInventory.CreateItem(ItemWithAttributes2);
        SetItemAttributeValue(ItemWithAttributes2, ItemAttributeValue);

        LibraryInventory.CreateItem(ItemNoAttributes);

        // [WHEN] The user sets a filter on the page
        ItemAttributeValue.SetRange("Attribute ID", ItemAttributeValue."Attribute ID");
        InvokeFindByAttributes(ItemList, ItemAttributeValue);

        // [THEN] Both Items are shown
        ItemList.First();
        Assert.AreEqual(ItemWithAttributes."No.", ItemList."No.".Value, 'Wrong ItemAttribute was shown');
        ItemList.Next();
        Assert.AreEqual(ItemWithAttributes2."No.", ItemList."No.".Value, 'Wrong ItemAttribute was shown for the second item');
        Assert.IsFalse(ItemList.Next(), 'There should not be any records present in the list');
        Assert.AreEqual(
          StrSubstNo('%1..%2', ItemWithAttributes."No.", ItemWithAttributes2."No."), ItemList.FILTER.GetFilter("No."),
          'Wrong filter was set');
    end;

    [Test]
    [HandlerFunctions('FilterItemAttributesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestFinding2200ItemsCompressedFilter()
    var
        ItemAttributeValue: Record "Item Attribute Value";
        ItemList: TestPage "Item List";
        ItemNo: array[5] of Code[20];
    begin
        // [SCENARIO 277697] Filter 2200 sorted items by attribute in case of consecutive item numbers.
        Initialize();

        // [GIVEN] Items with sorted numbers "A00001" - "A02205".
        // [GIVEN] Items "A00001" and "A00003" don't have any attributes, all other items have attribute "A".
        CreateItemsWithConsecutiveNosAndAttributes(ItemNo, ItemAttributeValue);

        // [WHEN] Stan applies filter to items for Item Attribute "A".
        ItemAttributeValue.SetRange("Attribute ID", ItemAttributeValue."Attribute ID");
        InvokeFindByAttributes(ItemList, ItemAttributeValue);

        // [THEN] Only items with attribute "A" are shown.
        // [THEN] ".." are placed between "A00004" and "A02205", i.e the filter is "A00002|A00004..A02205".
        ItemList.First();
        Assert.AreEqual(ItemNo[2], ItemList."No.".Value, 'Wrong ItemAttribute was shown');
        ItemList.Last();
        Assert.AreEqual(ItemNo[5], ItemList."No.".Value, 'Wrong ItemAttribute was shown for the last item');
        Assert.AreEqual(
          StrSubstNo('%1|%2..%3', ItemNo[2], ItemNo[4], ItemNo[5]),
          ItemList.FILTER.GetFilter("No."), 'Wrong filter was set');
    end;

    [Test]
    [HandlerFunctions('FilterItemAttributesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestFinding2200ItemsUncompressedFilter()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttributeValue2: Record "Item Attribute Value";
        ItemWithAttributes: Record Item;
        ItemWithAttributes2: Record Item;
        ItemNoAttributes: Record Item;
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        TypeHelper: Codeunit "Type Helper";
        ItemList: TestPage "Item List";
        I: Integer;
        ItemNo: Code[10];
    begin
        // [SCENARIO 226323] Item List shows only items with attribute when no adjacent items with same attribute

        Initialize();

        // [GIVEN] Two attributes = "A" and "B"
        CreateItemAttributeValues(ItemAttributeValue, 1, ItemAttribute.Type::Text);
        CreateItemAttributeValues(ItemAttributeValue2, 10, ItemAttribute.Type::Text);

        ItemNo := Format(LibraryRandom.RandIntInRange(1000000, 2000000));

        CreateSimpleItem(ItemWithAttributes, ItemNo);
        SetItemAttributeValue(ItemWithAttributes, ItemAttributeValue);

        // [GIVEN] "N" items. N1 has attribute "A", N2 has attribute "B", N3 has attribute "A",...,NX has attribute "A"
        while I < TypeHelper.GetMaxNumberOfParametersInSQLQuery() + 100 do begin
            CreateSimpleItemWithNextNoAndSetItemAttributeValue(ItemWithAttributes2, ItemNo, ItemAttributeValue2);

            CreateSimpleItemWithNextNoAndSetItemAttributeValue(ItemWithAttributes2, ItemNo, ItemAttributeValue);
            I += 1;
        end;

        CreateSimpleItemWithNextNo(ItemNoAttributes, ItemNo);

        // [WHEN] The user sets an attribute filter "A" on the page "Item List"
        ItemAttributeValue.SetRange("Attribute ID", ItemAttributeValue."Attribute ID");
        InvokeFindByAttributes(ItemList, ItemAttributeValue);

        // [THEN] First item on page "Item List" is N1
        ItemList.First();
        Assert.AreEqual(ItemWithAttributes."No.", ItemList."No.".Value, 'Wrong ItemAttribute was shown');

        // [THEN] Second item on page "Item List" has attribute "A"
        ItemList.Next();
        ItemAttributeValueMapping.Get(DATABASE::Item, ItemList."No.".Value, ItemAttributeValue."Attribute ID");

        // [THEN] Last item on page "Item List" is NX
        ItemList.Last();
        Assert.AreEqual(ItemWithAttributes2."No.", ItemList."No.".Value, 'Wrong ItemAttribute was shown for the last item');
        Assert.AreEqual('', ItemList.FILTER.GetFilter("No."), 'No filter should be set - MARK should have been used.');

        // [THEN] After clearing attributes all filters on Item List is reseted
        ItemList.ClearAttributes.Invoke();
        ItemNoAttributes.Reset();
        ItemNoAttributes.FindLast();
        ItemList.Last();
        Assert.AreEqual(ItemNoAttributes."No.", ItemList."No.".Value, 'Wrong ItemAttribute was shown for the last item');
    end;

    [Test]
    [HandlerFunctions('FilterItemAttributesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SetFilterItemWithAttributeAfterUncompressedFilterApplied()
    var
        ItemAttributeValue: Record "Item Attribute Value";
        ItemList: TestPage "Item List";
        ItemNo: array[3] of Code[20];
    begin
        // [SCENARIO 277697] Stan sets filter for item with an attribute after he filters 2200 items by attribute in case of nonconsecutive item numbers.
        Initialize();

        // [GIVEN] Items with sorted numbers "A00001" - "A04402".
        // [GIVEN] Even items - "A00002", "A00004" and so on - have attribute "A", odd items don't have any attribute.
        CreateItemsWithNonConsecutiveNosAndAttributes(ItemNo, ItemAttributeValue);

        // [GIVEN] Filter by attribute "A" is applied to items list.
        ItemAttributeValue.SetRange("Attribute ID", ItemAttributeValue."Attribute ID");
        InvokeFindByAttributes(ItemList, ItemAttributeValue);

        // [WHEN] Stan sets filter "A00002" for Item."No.".
        ItemList.FILTER.SetFilter("No.", ItemNo[2]);

        // [THEN] Only item "A00002" is shown.
        ItemList.First();
        Assert.AreEqual(ItemNo[2], ItemList."No.".Value, 'Wrong first item');
        ItemList.Last();
        Assert.AreEqual(ItemNo[2], ItemList."No.".Value, 'Wrong last item');
    end;

    [Test]
    [HandlerFunctions('FilterItemAttributesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SetFilterItemWithoutAttributeAfterUncompressedFilterApplied()
    var
        ItemAttributeValue: Record "Item Attribute Value";
        ItemList: TestPage "Item List";
        ItemNo: array[3] of Code[20];
    begin
        // [SCENARIO 277697] Stan sets filter for item without an attribute after he filters 2200 items by attribute in case of nonconsecutive item numbers.
        Initialize();

        // [GIVEN] Items with sorted numbers "A00001" - "A04402".
        // [GIVEN] Even items - "A00002", "A00004" and so on - have attribute "A", odd items don't have any attribute.
        CreateItemsWithNonConsecutiveNosAndAttributes(ItemNo, ItemAttributeValue);

        // [GIVEN] Filter by attribute "A" is applied to items list.
        ItemAttributeValue.SetRange("Attribute ID", ItemAttributeValue."Attribute ID");
        InvokeFindByAttributes(ItemList, ItemAttributeValue);

        // [WHEN] Stan sets filter "A00001" for Item."No.".
        ItemList.FILTER.SetFilter("No.", ItemNo[1]);

        // [THEN] No items are shown.
        ItemList.First();
        Assert.AreEqual('', ItemList."No.".Value, 'First item exists');
    end;

    [Test]
    [HandlerFunctions('FilterItemAttributesHandler')]
    [Scope('OnPrem')]
    procedure TestSpecifyingMultipleAttributesInFilter()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttributeValue2: Record "Item Attribute Value";
        TempItemAttributeValue: Record "Item Attribute Value" temporary;
        ItemWithAttributes: Record Item;
        ItemNoAttributes: Record Item;
        ItemList: TestPage "Item List";
    begin
        Initialize();

        // [GIVEN] An item with an multiple attributes assigned
        CreateItemAttributeValues(ItemAttributeValue, 10, ItemAttribute.Type::Integer);
        CreateItemAttributeValues(ItemAttributeValue2, 11, ItemAttribute.Type::Integer);

        LibraryInventory.CreateItem(ItemWithAttributes);
        LibraryInventory.CreateItem(ItemNoAttributes);

        SetItemAttributeValue(ItemWithAttributes, ItemAttributeValue);
        SetItemAttributeValue(ItemWithAttributes, ItemAttributeValue2);
        TempItemAttributeValue.Copy(ItemAttributeValue2);
        TempItemAttributeValue.Insert();
        TempItemAttributeValue.Copy(ItemAttributeValue);
        TempItemAttributeValue.Insert();

        // [WHEN] The user sets two filters on the page
        InvokeFindByAttributes(ItemList, TempItemAttributeValue);

        // [THEN] An single item is shown
        ItemList.First();
        Assert.AreEqual(ItemWithAttributes."No.", ItemList."No.".Value, 'Wrong ItemAttribute was shown, single item should be shown');
        Assert.IsFalse(ItemList.Next(), 'There should not be any records present in the list');
        Assert.AreEqual(ItemWithAttributes."No.", ItemList.FILTER.GetFilter("No."), 'Wrong filter was set');
    end;

    [Test]
    [HandlerFunctions('FilterItemAttributesHandler')]
    [Scope('OnPrem')]
    procedure TestSpecifyingRangesInFilterByTyping()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttributeValue2: Record "Item Attribute Value";
        ItemAttributeValue3: Record "Item Attribute Value";
        ItemInsideRange1: Record Item;
        ItemInsideRange2: Record Item;
        ItemOutsideRange: Record Item;
        ItemList: TestPage "Item List";
        RangeText: Text;
    begin
        Initialize();

        // [GIVEN] An item with an multiple attributes assigned
        CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Integer);
        CreateItemAttributeValue(ItemAttribute, ItemAttributeValue, Format(LibraryRandom.RandInt(10000), 0, 9));
        LibraryInventory.CreateItem(ItemInsideRange1);
        SetItemAttributeValue(ItemInsideRange1, ItemAttributeValue);

        CreateItemAttributeValue(ItemAttribute, ItemAttributeValue2, Format(ItemAttributeValue."Numeric Value" + 1, 0, 9));
        LibraryInventory.CreateItem(ItemInsideRange2);
        SetItemAttributeValue(ItemInsideRange2, ItemAttributeValue2);

        CreateItemAttributeValue(ItemAttribute, ItemAttributeValue3, Format(ItemAttributeValue2."Numeric Value" + 1, 0, 9));
        LibraryInventory.CreateItem(ItemOutsideRange);
        SetItemAttributeValue(ItemOutsideRange, ItemAttributeValue3);

        RangeText := StrSubstNo('>=%1&<=%2', ItemAttributeValue."Numeric Value", ItemAttributeValue2."Numeric Value");

        // [WHEN] The user sets range filter on the filter page
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(ItemAttribute.Name);
        LibraryVariableStorage.Enqueue(RangeText);
        ItemList.OpenView();
        ItemList.FilterByAttributes.Invoke();

        // [THEN] Two items are found, item outside the range is not
        Assert.AreEqual(
          StrSubstNo('%1..%2', ItemInsideRange1."No.", ItemInsideRange2."No."), ItemList.FILTER.GetFilter("No."), 'Wrong filter was set');
        ItemList.First();
        Assert.AreEqual(ItemInsideRange1."No.", ItemList."No.".Value, 'Wrong ItemAttribute was shown');
        ItemList.Next();
        Assert.AreEqual(ItemInsideRange2."No.", ItemList."No.".Value, 'Wrong ItemAttribute was shown for the second item');
        Assert.IsFalse(ItemList.Next(), 'There should not be any records present in the list');
    end;

    [Test]
    [HandlerFunctions('VerifyAssistEditFilterItemAttributesHandler,AssistEditFilterItemAttributesHandler')]
    [Scope('OnPrem')]
    procedure TestSpecifyingRangeFilterWithAssistEditCard()
    var
        ItemAttribute: Record "Item Attribute";
        ItemList: TestPage "Item List";
        ExpectedRangeText: Text;
        Value1: Text;
        Value2: Text;
    begin
        Initialize();

        // [GIVEN] An attribute of type decimal
        CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Decimal);

        Value1 := '1000';
        Value2 := '2000';
        ExpectedRangeText := StrSubstNo('%1..%2', Value1, Value2);

        // [WHEN] The user sets range filter on the filter page
        LibraryVariableStorage.Enqueue(ItemAttribute.Name);
        LibraryVariableStorage.Enqueue(Value1);
        LibraryVariableStorage.Enqueue(Value2);
        LibraryVariableStorage.Enqueue(ExpectedRangeText);
        ItemList.OpenView();
        ItemList.FilterByAttributes.Invoke();

        // [THEN] Proper filter is filled out - verified in handler
    end;

    [Test]
    [HandlerFunctions('VerifyAssistEditFilterItemAttributesHandler,AssistEditFilterItemAttributesHandler')]
    [Scope('OnPrem')]
    procedure TestSpecifyingTextStartsWithAssistEditCard()
    var
        ItemAttribute: Record "Item Attribute";
        ItemList: TestPage "Item List";
        ExpectedFilterText: Text;
        TextValue: Text;
    begin
        Initialize();

        // [GIVEN] An attriubte of type text
        CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Text);

        TextValue := 'wood';
        ExpectedFilterText := StrSubstNo('@*%1', TextValue);

        // [WHEN] The user sets ends with filter on thext page
        LibraryVariableStorage.Enqueue(ItemAttribute.Name);
        LibraryVariableStorage.Enqueue(TextValue);
        LibraryVariableStorage.Enqueue(ExpectedFilterText);
        ItemList.OpenView();
        ItemList.FilterByAttributes.Invoke();

        // [THEN] Proper filter is filled out - verified in handler
    end;

    [Test]
    [HandlerFunctions('FilterItemAttributesHandler')]
    [Scope('OnPrem')]
    procedure TestSpecifyingTextOrConditions()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemWithAttributes: Record Item;
        ItemWithAttributes2: Record Item;
        ItemWithAttributes3: Record Item;
        ItemList: TestPage "Item List";
        FilterText: Text;
    begin
        Initialize();

        // [GIVEN] Three items with text attribute
        CreateItemAttributeValues(ItemAttributeValue, 10, ItemAttribute.Type::Text);

        LibraryInventory.CreateItem(ItemWithAttributes);
        SetItemAttributeValue(ItemWithAttributes, ItemAttributeValue);
        FilterText := ItemAttributeValue.Value;

        LibraryInventory.CreateItem(ItemWithAttributes2);
        ItemAttributeValue.Next();
        SetItemAttributeValue(ItemWithAttributes2, ItemAttributeValue);
        FilterText += '|' + ItemAttributeValue.Value;

        LibraryInventory.CreateItem(ItemWithAttributes3);
        ItemAttributeValue.Next();
        SetItemAttributeValue(ItemWithAttributes3, ItemAttributeValue);

        // [WHEN] The user sets a filter on the page searching for or condition
        ItemAttribute.Get(ItemAttributeValue."Attribute ID");
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(ItemAttribute.Name);
        LibraryVariableStorage.Enqueue(FilterText);

        ItemList.OpenView();
        ItemList.FilterByAttributes.Invoke();

        // [THEN] First and second items are shown, third is not
        Assert.AreEqual(
          StrSubstNo('%1..%2', ItemWithAttributes."No.", ItemWithAttributes2."No."), ItemList.FILTER.GetFilter("No."),
          'Wrong filter was set');
    end;

    [Test]
    [HandlerFunctions('VerifyAssistEditFilterItemAttributesHandler,SelectOptionValueFilterItemAttributesHandler')]
    [Scope('OnPrem')]
    procedure TestSpecifyingOptionFilterUserCancelsWithAssistEditCard()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemList: TestPage "Item List";
        ExpectedRangeText: Text;
    begin
        Initialize();

        // [GIVEN] An attribute of option type
        CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Option);
        CreateItemAttributeValues(ItemAttributeValue, 10, ItemAttribute.Type);

        // [WHEN] The user cancels the select page
        LibraryVariableStorage.Enqueue(ItemAttribute.Name);
        ExpectedRangeText := '';
        LibraryVariableStorage.Enqueue(ExpectedRangeText);

        ItemList.OpenView();
        ItemList.FilterByAttributes.Invoke();

        // [THEN] Proper filter is filled out - verified in handler
    end;

    [Test]
    [HandlerFunctions('FilterItemAttributesHandler')]
    [Scope('OnPrem')]
    procedure TestClearingTheFilter()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        TempItemAttributeValue: Record "Item Attribute Value" temporary;
        ItemWithAttributes: Record Item;
        ItemNoAttributes: Record Item;
        ItemList: TestPage "Item List";
    begin
        Initialize();

        // [GIVEN] Item list is already filtered with Attributes
        CreateItemAttributeValues(ItemAttributeValue, 10, ItemAttribute.Type::Integer);

        LibraryInventory.CreateItem(ItemWithAttributes);
        LibraryInventory.CreateItem(ItemNoAttributes);

        SetItemAttributeValue(ItemWithAttributes, ItemAttributeValue);

        ItemAttributeValue.SetRange(ID, ItemAttributeValue.ID);
        InvokeFindByAttributes(ItemList, TempItemAttributeValue);

        // [WHEN] The user clears the attribute filter
        ItemList.ClearAttributes.Invoke();

        // [THEN] Full item list is shown
        ItemList.GotoRecord(ItemNoAttributes);
        Assert.AreEqual('', ItemList.FILTER.GetFilter("No."), 'Filter should be removed from the page');
    end;

    [Test]
    [HandlerFunctions('CloseItemAttributeValueListHandler')]
    [Scope('OnPrem')]
    procedure TestItemAttributesSavedAfterPageClosed()
    var
        Item: Record Item;
        FirstItemAttribute: Record "Item Attribute";
        FirstItemAttributeValue: Record "Item Attribute Value";
        SecondItemAttribute: Record "Item Attribute";
        SecondItemAttributeValue: Record "Item Attribute Value";
        ItemCard: TestPage "Item Card";
    begin
        Initialize();

        // [GIVEN] An item and a set of item attributes
        CreateTestOptionItemAttributes();
        LibraryInventory.CreateItem(Item);

        // [WHEN] The user assigns some attribute values to the item and closes the Item Attribute Value Editor page
        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);

        FirstItemAttribute.FindFirst();
        SecondItemAttribute.FindLast();

        AssignItemAttributeViaItemCard(FirstItemAttribute, FirstItemAttributeValue, ItemCard);
        AssignItemAttributeViaItemCard(SecondItemAttribute, SecondItemAttributeValue, ItemCard);

        // [THEN] The attributes are saved
        ItemCard.ItemAttributesFactbox.First();
        ItemCard.ItemAttributesFactbox.Attribute.AssertEquals(FirstItemAttribute.Name);
        ItemCard.ItemAttributesFactbox.Value.AssertEquals(FirstItemAttributeValue.Value);
        ItemCard.ItemAttributesFactbox.Last();
        ItemCard.ItemAttributesFactbox.Attribute.AssertEquals(SecondItemAttribute.Name);
        ItemCard.ItemAttributesFactbox.Value.AssertEquals(SecondItemAttributeValue.Value);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItemAttributeValueExists()
    var
        ItemAttributeValue: Record "Item Attribute Value";
        SearchedItemAttributeValue: Record "Item Attribute Value";
        ItemAttribute: Record "Item Attribute";
        ItemAttributeManagement: Codeunit "Item Attribute Management";
        SearchResult: Boolean;
        NonExistingValue: Text[250];
    begin
        // [GIVEN] An item attribute value that does not exist
        NonExistingValue := 'Item attribute value that does not exist.';

        // [WHEN] We search for it
        SearchResult := ItemAttributeManagement.DoesValueExistInItemAttributeValues(NonExistingValue, SearchedItemAttributeValue);

        // [THEN]  We don not find it
        Assert.IsFalse(SearchResult, 'Expected the non existing item attribute value not to be found.');

        // [GIVEN] An item attribute value that exists
        CreateItemAttributeValues(ItemAttributeValue, 1, ItemAttribute.Type::Option);

        // [WHEN] We search for it
        SearchResult := ItemAttributeManagement.DoesValueExistInItemAttributeValues(ItemAttributeValue.Value, SearchedItemAttributeValue);

        // [THEN] We find it
        Assert.IsTrue(SearchResult, 'Expected the newly created item attribute value to be found.');

        // [WHEN] We search for it with different case (uppercase)
        Assert.AreEqual(
          ItemAttributeValue.Value, LowerCase(ItemAttributeValue.Value), 'Expected the item attribute value to be lowercase.');
        Assert.AreNotEqual(
          ItemAttributeValue.Value, UpperCase(ItemAttributeValue.Value),
          'Expected the uppercase item attribute value to be different from the item attribute value.');
        SearchResult :=
          ItemAttributeManagement.DoesValueExistInItemAttributeValues(UpperCase(ItemAttributeValue.Value), SearchedItemAttributeValue);

        // [THEN] We also find it because the search is not case-sensitive
        Assert.IsTrue(SearchResult, 'Expected the newly created item attribute value to be found, even when uppercase.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultItemAttributeNameUsedForUnknownLanguage()
    var
        ItemAttribute: Record "Item Attribute";
    begin
        // [SCENARIO 215293] Default item attribute name should be shown when the current system language is not found in the Language table
        Initialize();

        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Text, '');
        // Negative value to ensure that the parameter does not correspond to any Windows language ID
        Assert.AreEqual(ItemAttribute.Name, ItemAttribute.GetTranslatedName(-1), WrongAttrNameForUnknownLanguageErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultItemAttributeValueUsedForUnknownLanguage()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
    begin
        // [SCENARIO 215293] Default item attribute value should be shown when the current system language is not found in the Language table
        Initialize();

        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Text, '');
        LibraryInventory.CreateItemAttributeValue(ItemAttributeValue, ItemAttribute.ID, LibraryUtility.GenerateGUID());

        // Negative value to ensure that the parameter does not correspond to any Windows language ID
        Assert.AreEqual(ItemAttributeValue.Value, ItemAttributeValue.GetTranslatedName(-1), WrongAttrNameForUnknownLanguageErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SaveItemAttributesWhenRenameItem()
    var
        Item: Record Item;
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemNo: Code[20];
        PrevItemNo: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 211711] If Item is renamed, it's Attributes should not be lost
        Initialize();

        // [GIVEN] An item and a set of item attributes
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Two attribute values assigned to the Item "III"
        CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Decimal);
        CreateItemAttributeValueMapping(ItemAttribute.ID, Item."No.");
        CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Integer);
        CreateItemAttributeValueMapping(ItemAttribute.ID, Item."No.");
        CreateItemAttributeValue(ItemAttribute, ItemAttributeValue, Format(LibraryRandom.RandInt(100)));

        // [WHEN] Rename Item "III" to "III2"
        PrevItemNo := Item."No.";
        ItemNo := LibraryUtility.GenerateGUID();
        Item.Rename(ItemNo);

        // [THEN] There are two attributes for Item "III2"
        ItemAttributeValueMapping.SetRange("Table ID", DATABASE::Item);
        ItemAttributeValueMapping.SetRange("No.", ItemNo);
        Assert.RecordCount(ItemAttributeValueMapping, 2);

        // [THEN] There are no attributes for Item "III"
        ItemAttributeValueMapping.SetRange("No.", PrevItemNo);
        Assert.RecordIsEmpty(ItemAttributeValueMapping);

        // [THEN] Item Attribute Value is accessible
        ItemAttributeValue.SetRange("Attribute ID", ItemAttribute.ID);
        Assert.RecordCount(ItemAttributeValue, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FindingExistingAttributeValueByNumericValue()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttributeValueSelection: Record "Item Attribute Value Selection";
        AttrValueUSFormat: Text[250];
        AttrValue: Decimal;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 226997] FindAttributeValue function in Table 7504 "Item Attribute Value Selection" finds existing attribute of decimal type by its Numeric Value, as long as Value depends on regional settings.
        Initialize();

        // [GIVEN] Item Attribute "A".
        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Decimal, LibraryUtility.GenerateGUID());

        AttrValueUSFormat := '12,345.67';
        AttrValue := 12345.67;

        // [GIVEN] Item Attribute Value "V" of the attribute "A".
        // [GIVEN] "V".Value = '12,345.67' (in US format), "V"."Numeric Value" = 12345.67 (decimal)
        ItemAttributeValue.Init();
        ItemAttributeValue."Attribute ID" := ItemAttribute.ID;
        ItemAttributeValue.ID := LibraryRandom.RandInt(100);
        ItemAttributeValue.Value := AttrValueUSFormat;
        ItemAttributeValue."Numeric Value" := AttrValue;
        ItemAttributeValue.Insert();
        Clear(ItemAttributeValue);

        // [WHEN] Invoke FindAttributeValue function in Table 7504 in order to find Item Attribute Value record for item attribute "A" and value 12345.67.
        ItemAttributeValueSelection."Attribute ID" := ItemAttribute.ID;
        ItemAttributeValueSelection.Value := Format(AttrValue);
        ItemAttributeValueSelection.FindAttributeValue(ItemAttributeValue);

        // [THEN] Item Attribute Value "V" with Value = '12,345.67' is found.
        ItemAttributeValue.TestField(Value, AttrValueUSFormat);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemAttrValueTranslationsAreDeletedOnDeleteItemAttribute()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttrValueTranslation: Record "Item Attr. Value Translation";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 228474] Item Attribute Value Translation is deleted when Item Attribute is deleted.
        Initialize();

        // [GIVEN] Item Attribute with Item Attr. Value Translation.
        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Option, '');
        ItemAttrValueTranslation.Init();
        ItemAttrValueTranslation."Attribute ID" := ItemAttribute.ID;
        ItemAttrValueTranslation.Insert();

        // [WHEN] Delete the item attribute.
        ItemAttribute.Delete(true);

        // [THEN] Item attribute value translation is deleted.
        ItemAttrValueTranslation.SetRange("Attribute ID", ItemAttribute.ID);
        Assert.RecordIsEmpty(ItemAttrValueTranslation);
    end;

    [Test]
    [HandlerFunctions('ItemAttributeValueChangeValueEditor')]
    [Scope('OnPrem')]
    procedure ChangeItemAttribueValueWhenOtherMappedValuesExist()
    var
        Item: Record Item;
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        NewAttributeValue: Text;
        I: Integer;
        ItemCount: Integer;
    begin
        // [SCENARIO 235152] When changing a value of an item attribue, other values of the same attribute mapped to other items should not be affected

        Initialize();

        // [GIVEN] 5 items with the same attribute "A" and different values of that attribute - from "V1" to "V5"
        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Text, '');

        ItemCount := LibraryRandom.RandIntInRange(3, 6);
        for I := 1 to ItemCount do
            CreateItemWithTextAttributeValue(Item, ItemAttributeValue, ItemAttribute.ID);

        // [GIVEN] Select the first item and open the attribute value editor page
        // [WHEN] Change the value of the attribute from "V1" to "Z"
        NewAttributeValue := InvokeItemAttributesEditor(Item."No.");

        // [THEN] Attribute value "V1" is deleted
        VerifyAttributeMappingCount(ItemAttribute.ID, ItemAttributeValue.ID, 0);

        // [THEN] Attribute value "Z" is inserted
        FindItemAttributeValue(ItemAttributeValue, ItemAttribute.ID, NewAttributeValue);
        VerifyAttributeMappingCount(ItemAttribute.ID, ItemAttributeValue.ID, 1);
    end;

    [Test]
    [HandlerFunctions('ItemAttributeValueChangeValueEditor')]
    [Scope('OnPrem')]
    procedure ChangeItemAttribueValueWhenSameValueIsMapped()
    var
        Item: Record Item;
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        NewAttributeValue: Text;
        I: Integer;
        ItemCount: Integer;
    begin
        // [SCENARIO 235152] When changing a value of an item attribue, value should not be deleted if it is mapped to other items

        Initialize();

        // [GIVEN] 5 items with the same attribute "A", value "V"
        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Text, '');
        LibraryInventory.CreateItemAttributeValue(ItemAttributeValue, ItemAttribute.ID, LibraryUtility.GenerateGUID());

        ItemCount := LibraryRandom.RandIntInRange(3, 6);
        for I := 1 to ItemCount do
            CreateItemWithTextAttributeMapping(Item, ItemAttribute.ID, ItemAttributeValue.ID);

        // [GIVEN] Select the first item and open the attribute value editor page
        // [WHEN] Change the value of the attribute from "V" to "Z"
        NewAttributeValue := InvokeItemAttributesEditor(Item."No.");

        // [THEN] Attribute value "V" is not deleted, since it is mapped to the 4 remaining items
        VerifyAttributeMappingCount(ItemAttribute.ID, ItemAttributeValue.ID, ItemCount - 1);

        // [THEN] New attribute value "Z" is inserted
        FindItemAttributeValue(ItemAttributeValue, ItemAttribute.ID, NewAttributeValue);
        VerifyAttributeMappingCount(ItemAttribute.ID, ItemAttributeValue.ID, 1);
    end;

    [Test]
    [HandlerFunctions('ItemAttributeValueChangeValueEditor')]
    [Scope('OnPrem')]
    procedure ChangeItemAttribueValueWhenNoOtherMappingsExist()
    var
        Item: Record Item;
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        NewAttributeValue: Text;
    begin
        // [SCENARIO 235152] When changing a value of an item attribue, value should be deleted if it is not mapped to other items

        Initialize();

        // [GIVEN] One item with attribute "A", value "V"
        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Text, '');
        CreateItemWithTextAttributeValue(Item, ItemAttributeValue, ItemAttribute.ID);

        // [GIVEN] Select the item and open the attribute value editor page
        // [WHEN] Change the value of the attribute from "V" to "Z"
        NewAttributeValue := InvokeItemAttributesEditor(Item."No.");

        // [THEN] Attribute value "V" is deleted, since it is not mapped to any item anymore
        VerifyAttributeMappingCount(ItemAttribute.ID, ItemAttributeValue.ID, 0);

        // [THEN] New attribute value "Z" is inserted
        FindItemAttributeValue(ItemAttributeValue, ItemAttribute.ID, NewAttributeValue);
        VerifyAttributeMappingCount(ItemAttribute.ID, ItemAttributeValue.ID, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteCategoryAtributeUnusedValueDeleted()
    var
        ItemCategory: Record "Item Category";
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        TempItemAttributeValue: Record "Item Attribute Value" temporary;
        Item: Record Item;
        ItemAttributeManagement: Codeunit "Item Attribute Management";
        I: Integer;
    begin
        // [FEATURE] [Item Category]
        // [SCENARIO 252765] When attribute value mapping is deleted for all items in a category, attribute value that is not mapped to other items, should be deleted

        Initialize();

        // [GIVEN] Item attribute "A" with value "V"
        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Text, '');
        LibraryInventory.CreateItemAttributeValue(ItemAttributeValue, ItemAttribute.ID, LibraryUtility.GenerateGUID());

        // [GIVEN] Item category "C"
        LibraryInventory.CreateItemCategory(ItemCategory);

        // [GIVEN] 3 items in the category "C", all having the same attribute value (attribute "A", value "V")
        for I := 1 to 3 do
            CreateItemWithAttributeAndCategory(Item, ItemAttribute.ID, ItemAttributeValue.ID, ItemCategory.Code);

        // [WHEN] Delete attribute value mapping for the category "C"
        TempItemAttributeValue := ItemAttributeValue;
        TempItemAttributeValue.Insert();
        ItemAttributeManagement.DeleteCategoryItemsAttributeValueMapping(TempItemAttributeValue, ItemCategory.Code);

        // [THEN] Item attribute value "V" should be deleted
        ItemAttributeValue.SetRecFilter();
        Assert.RecordIsEmpty(ItemAttributeValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeCategoryAtributeValueUnusedValueDeleted()
    var
        ItemCategory: Record "Item Category";
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
    begin
        // [FEATURE] [Item Category]
        // [SCENARIO 252765] When category attribute value is changed, old attribute value that is not mapped to other items, should be deleted

        Initialize();

        // [GIVEN] Item category "C" with attribute "A" and attribute value "V1"
        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Text, '');
        CreateItemCategoryWithTextAttributeValue(ItemCategory, ItemAttributeValue, ItemAttribute.ID);

        // [WHEN] Change the attribute value from "V1" to "V2" for the category
        SetCategoryAttributeValue(ItemCategory.Code);

        // [THEN] Attribute value "V1" should be deleted
        ItemAttributeValue.SetRecFilter();
        Assert.RecordIsEmpty(ItemAttributeValue);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ChangeCategoryAtributeValueItemMappingExists()
    var
        ItemCategory: Record "Item Category";
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        Item: Record Item;
        I: Integer;
    begin
        // [FEATURE] [Item Category]
        // [SCENARIO 252765] When an attribute value is deleted for a category, but not its items, attribute value should not be deleted

        Initialize();

        // [GIVEN] Item category "C" with attribute "A" and attribute value "V1"
        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Text, '');
        CreateItemCategoryWithTextAttributeValue(ItemCategory, ItemAttributeValue, ItemAttribute.ID);

        // [GIVEN] 3 items in the category "C". Attribute value "V1" is automatically inherited from the category.
        for I := 1 to 3 do
            CreateItemWithCategory(Item, ItemCategory.Code);

        // [WHEN] Change the attribute value from "V1" to "V2" for the category
        SetCategoryAttributeValue(ItemCategory.Code);

        // [THEN] Attribute value "V1" should not be deleted
        ItemAttributeValue.SetRecFilter();
        Assert.RecordIsNotEmpty(ItemAttributeValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteCategoryAtributeValueMappingExists()
    var
        ItemCategory: Record "Item Category";
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        TempItemAttributeValue: Record "Item Attribute Value" temporary;
        Item: Record Item;
        ItemAttributeManagement: Codeunit "Item Attribute Management";
        I: Integer;
    begin
        // [FEATURE] [Item Category]
        // [SCENARIO 252765] When attribute value mapping is deleted for items in a category, but the value is mapped to items with no category code, attribute value should not be deleted

        Initialize();

        // [GIVEN] Item category "C" with attribute "A" and attribute value "V1"
        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Text, '');
        LibraryInventory.CreateItemCategory(ItemCategory);

        // [GIVEN] 2 items in the category "C". Attribute value "V1" is automatically inherited from the category.
        for I := 1 to 2 do
            CreateItemWithCategory(Item, ItemCategory.Code);

        // [GIVEN] Item that does not belong to any category
        CreateItemWithTextAttributeValue(Item, ItemAttributeValue, ItemAttribute.ID);

        // [WHEN] Delete attribute value mapping for all items in the category "C"
        TempItemAttributeValue := ItemAttributeValue;
        TempItemAttributeValue.Insert();
        ItemAttributeManagement.DeleteCategoryItemsAttributeValueMapping(TempItemAttributeValue, ItemCategory.Code);

        // [THEN] Attribute value "V1" should not be deleted
        ItemAttributeValue.SetRecFilter();
        Assert.RecordIsNotEmpty(ItemAttributeValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FindingExistingAttributeValueByDateValue()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttributeValueSelection: Record "Item Attribute Value Selection";
        AttrValueFullYear: Text[250];
        AttrValue: Date;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 317701] FindAttributeValue function in Table 7504 "Item Attribute Value Selection" finds existing attribute of date type by its Date Value.
        Initialize();

        // [GIVEN] Item Attribute "A".
        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Date, LibraryUtility.GenerateGUID());
        AttrValueFullYear := Format(WorkDate(), 0, '<Month,2>/<Day,2>/<Year4>');
        AttrValue := WorkDate();

        // [GIVEN] Item Attribute Value "V" of the attribute "A".
        // [GIVEN] "V"."Date Value" = '01\01\17'
        CreateItemAttributeValue(ItemAttribute, ItemAttributeValue, '');
        ItemAttributeValue.Validate("Date Value", AttrValue);
        ItemAttributeValue.Modify(true);
        Clear(ItemAttributeValue);

        // [WHEN] Invoke FindAttributeValue function in Table 7504 in order to find Item Attribute Value record for item attribute "A" and value '01\01\2017'
        ItemAttributeValueSelection."Attribute ID" := ItemAttribute.ID;
        ItemAttributeValueSelection.Value := Format(AttrValueFullYear);
        Assert.IsTrue(ItemAttributeValueSelection.FindAttributeValue(ItemAttributeValue),
          StrSubstNo(ItemAttributeValueNotFoundErr, 'Date', AttrValue));

        // [THEN] Item Attribute Value "V" is found with value '01\01\2017'
        ItemAttributeValue.TestField("Date Value", AttrValue);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('EditItemAttributeValueListHandler')]
    procedure ChangeItemAttributeValueMappingName()
    var
        Item: Record Item;
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        OldItemAttributeID: Integer;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 377465] The old "Item Attribute Value Mapping" must be deleted after change Name in page "Item Attribute Value List"
        Initialize();

        // [GIVEN] Item with attribute with name "IA1"
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Text, '');
        LibraryInventory.CreateItemAttributeValue(ItemAttributeValue, ItemAttribute.ID, '');
        OldItemAttributeID := ItemAttribute.ID;
        LibraryInventory.CreateItemAttributeValueMapping(
            Database::Item, Item."No.", ItemAttribute.ID, ItemAttributeValue.ID);

        // [GIVEN] Item Attribute with name "IA2"
        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Text, '');

        // [GIVEN] Open "Item Attribute Value List"
        LibraryVariableStorage.Enqueue(ItemAttribute.Name);
        Page.RunModal(Page::"Item Attribute Value Editor", Item);

        // [WHEN] Change "IA1" to "IA2"
        // In handler EditItemAttributeValueListHandler()

        // [THEN] Record "Item Attribute Value Mapping" with Name = "IA1" deleted
        ItemAttributeValueMapping.SetRange("Table ID", Database::Item);
        ItemAttributeValueMapping.SetRange("No.", Item."No.");
        ItemAttributeValueMapping.SetRange("Item Attribute ID", OldItemAttributeID);
        Assert.RecordIsEmpty(ItemAttributeValueMapping);

        // [THEN] Record "Item Attribute Value Mapping" with Name = "IA2" exists
        ItemAttributeValueMapping.SetRange("Item Attribute ID", ItemAttribute.ID);
        Assert.RecordIsNotEmpty(ItemAttributeValueMapping);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('FilterItemAttributesHandler')]
    procedure FilteringByItemAttributeWhenItemNoContainsSpecialChars()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        Item: Record Item;
        ItemList: TestPage "Item List";
    begin
        // [SCENARIO 394399] Filtering one item with special characters in No. by attributes.
        Initialize();

        // [GIVEN] Attribute "A".
        CreateItemAttributeValues(ItemAttributeValue, 1, ItemAttribute.Type::Option);

        // [GIVEN] Item with No. = 1000|*
        Item.Init();
        Item."No." := LibraryUtility.GenerateGUID() + '|*';
        Item.Insert();

        // [GIVEN] Assign attribute "A" to the item.
        SetItemAttributeValue(Item, ItemAttributeValue);

        // [WHEN] Filter items by attribute "A".
        InvokeFindByAttributes(ItemList, ItemAttributeValue);

        // [THEN] An single item '1000|*' is shown.
        Assert.AreEqual('''' + Item."No." + '''', ItemList.FILTER.GetFilter("No."), '');
        ItemList.First();
        Assert.AreEqual(Item."No.", ItemList."No.".Value, '');
        Assert.IsFalse(ItemList.Next(), '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('FilterItemAttributesHandler')]
    procedure FilteringByItemAttributeWhenTwoItemsContainSpecialChars()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        Item: array[2] of Record Item;
        ItemList: TestPage "Item List";
    begin
        // [SCENARIO 394399] Filtering two items with special characters in No. by attributes.
        Initialize();

        // [GIVEN] Attribute "A".
        CreateItemAttributeValues(ItemAttributeValue, 1, ItemAttribute.Type::Option);

        // [GIVEN] Item "I1" with No. = 1000|*
        Item[1].Init();
        Item[1]."No." := LibraryUtility.GenerateGUID() + '|*';
        Item[1].Insert();

        // [GIVEN] Item "I2" with No. = 1001|>
        Item[2].Init();
        Item[2]."No." := LibraryUtility.GenerateGUID() + '|>';
        Item[2].Insert();

        // [GIVEN] Assign attribute "A" to both items.
        SetItemAttributeValue(Item[1], ItemAttributeValue);
        SetItemAttributeValue(Item[2], ItemAttributeValue);

        // [WHEN] Filter items by attribute "A".
        InvokeFindByAttributes(ItemList, ItemAttributeValue);

        // [THEN] Only two items "I1".."I2" are shown.
        Assert.AreEqual(StrSubstNo('''%1''..''%2''', Item[1]."No.", Item[2]."No."), ItemList.FILTER.GetFilter("No."), '');
        ItemList.First();
        Assert.AreEqual(Item[1]."No.", ItemList."No.".Value, '');
        ItemList.Next();
        Assert.AreEqual(Item[2]."No.", ItemList."No.".Value, '');
        Assert.IsFalse(ItemList.Next(), '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure CannotInsertItemAttributeValueMappingForInexistingItem()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 394921] Cannot insert Item Attribute Value Mapping for inexisting item.
        Initialize();

        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Integer, '');
        LibraryInventory.CreateItemAttributeValue(ItemAttributeValue, ItemAttribute.ID, Format(LibraryRandom.RandInt(100)));

        ItemAttributeValueMapping.Init();
        ItemAttributeValueMapping."Table ID" := DATABASE::Item;
        ItemAttributeValueMapping."No." := LibraryUtility.GenerateGUID();
        ItemAttributeValueMapping."Item Attribute ID" := ItemAttributeValue."Attribute ID";
        ItemAttributeValueMapping."Item Attribute Value ID" := ItemAttributeValue.ID;
        asserterror ItemAttributeValueMapping.Insert(true);

        Assert.ExpectedError('There is no Item');
    end;

    [Test]
    procedure CannotInsertItemAttributeValueMappingForInexistingItemAttrValue()
    var
        Item: Record Item;
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 394921] Cannot insert Item Attribute Value Mapping for inexisting Item Attribute Value.
        Initialize();

        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Integer, '');
        LibraryInventory.CreateItemAttributeValue(ItemAttributeValue, ItemAttribute.ID, Format(LibraryRandom.RandInt(100)));

        ItemAttributeValueMapping.Init();
        ItemAttributeValueMapping."Table ID" := DATABASE::Item;
        ItemAttributeValueMapping."No." := Item."No.";
        ItemAttributeValueMapping."Item Attribute ID" := ItemAttributeValue."Attribute ID";
        ItemAttributeValueMapping."Item Attribute Value ID" := LibraryRandom.RandIntInRange(500, 1000);
        asserterror ItemAttributeValueMapping.Insert(true);

        Assert.ExpectedError('The Item Attribute Value does not exist');
    end;

    [Test]
    procedure TranslatedAttributeNameGetsMatchedToOriginalCorrectly()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemCategory: Record "Item Category";
        Language: Record Language;
        ItemCategoryCard: TestPage "Item Category Card";
        TranslatedValue: Text;
    begin
        // [SCENARIO 401848] When opening and closing Item Category card with Attributes which have translation for currently set global language: there is no message to delete any attribute values,
        // the original value is not deleted, the translated value is not added to Attribute Value table.
        Initialize();

        // [GIVEN] A Language was set in options with code "XXX"
        Language.SetRange("Windows Language ID", GlobalLanguage());
        Language.FindFirst();

        // [GIVEN] An Item Attribute was created
        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Option, '');

        // [GIVEN] An Item Attribute Value was created with value "VALUE"
        LibraryInventory.CreateItemAttributeValue(ItemAttributeValue, ItemAttribute.ID, LibraryUtility.GenerateGUID());

        // [GIVEN] An Item Attribute Value Translation was created with value "TRANSLATED VALUE"
        TranslatedValue := InsertOptionItemAttributeValueTranslation(Language, ItemAttribute, ItemAttributeValue);

        // [GIVEN] An Item Category was created and Item Attribute with default value assigned to the category
        LibraryInventory.CreateItemCategory(ItemCategory);
        AssignItemAttributeValueToCategory(ItemCategory, ItemAttribute, ItemAttributeValue.Value);

        // [WHEN] Open and close Item Category Card for this category
        ItemCategoryCard.OpenView();
        ItemCategoryCard.Filter.SetFilter(Code, ItemCategory.Code);
        ItemCategoryCard.OK().Invoke();

        // [THEN] No message for deletion of attribute values pops up

        // [THEN] Original Item Attribute Value "VALUE" still exists
        ItemAttributeValue.SetRange("Attribute ID", ItemAttribute.ID);
        ItemAttributeValue.SetRange(Value, ItemAttributeValue.Value);
        ItemAttributeValue.FindFirst();

        // [THEN] Translated value "TRANSLATED VALUE" was not added to the Item Attribute Value table
        ItemAttributeValue.SetRange(Value, TranslatedValue);
        Assert.RecordIsEmpty(ItemAttributeValue);
    end;

    [Test]
    procedure TestPopulateItemAttributeValueDecimal()
    var
        ItemAttributeValueSelection: Record "Item Attribute Value Selection";
        TempItemAttributeValue: Record "Item Attribute Value" temporary;
        TempNewItemAttributeValue: Record "Item Attribute Value" temporary;
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        Item: Record Item;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 423054] "Item Attribute Selection"."Populate Item Attribute Value" must correct handle the empty string for decimal value
        Initialize();
        ItemAttributeValueSelection.DeleteAll();

        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Decimal, '');
        LibraryInventory.CreateItemAttributeValue(ItemAttributeValue, ItemAttribute.ID, Format(LibraryRandom.RandDecInDecimalRange(1, 10, 1)));
        LibraryInventory.CreateItem(Item);
        SetItemAttributeValue(Item, ItemAttributeValue);

        ItemAttributeValue.Value := '';
        ItemAttributeValue.Modify(true);
        TempItemAttributeValue.TransferFields(ItemAttributeValue);
        TempItemAttributeValue.Insert();

        ItemAttributeValueSelection.PopulateItemAttributeValueSelection(TempItemAttributeValue);

        ItemAttributeValueSelection.PopulateItemAttributeValue(TempNewItemAttributeValue);

        TempNewItemAttributeValue.TestField(Value, '0');
    end;

    [Test]
    [HandlerFunctions('FilterItemAttributesHandler')]
    procedure FilteringByItemAttributeOfDateType()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        Item: Record Item;
        ItemList: TestPage "Item List";
    begin
        // [SCENARIO 428893] Filtering by item attribute of type = Date.
        Initialize();

        // [GIVEN] Item Attribute "A" of type = Date. Set value = '25/01/2024' (DD/MM/YYYY).
        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Date, '');
        LibraryInventory.CreateItemAttributeValue(ItemAttributeValue, ItemAttribute.ID, Format(WorkDate()));

        // [GIVEN] Create item "I" and assign item attribute "A" to it.
        LibraryInventory.CreateItem(Item);
        SetItemAttributeValue(Item, ItemAttributeValue);

        // [WHEN] Filter items by attributes - select attribute "A" and value '25'.
        ItemList.OpenView();
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(ItemAttribute.Name);
        LibraryVariableStorage.Enqueue(Format(Date2DMY(WorkDate(), 1)));
        ItemList.FilterByAttributes.Invoke();

        // [THEN] The item "I" is found.
        Assert.AreEqual(Item."No.", ItemList.FILTER.GetFilter("No."), '');
        ItemList.First();
        Assert.AreEqual(Item."No.", ItemList."No.".Value, '');

        ItemList.Close();
    end;

    [Test]
    procedure VerifyForbiddenInsertItemAttributeWithBlankName()
    var
        ItemAttribute: Record "Item Attribute";
    begin
        // [SCENARIO 464054] Verify that is not allowed to create new Item Attribute without Name value
        // [GIVEN] Init Item Attribute rec
        ItemAttribute.Init();

        // [GIVEN] Set Item Attribute type
        ItemAttribute.Validate(Type, ItemAttribute.Type::Date);

        // [WHEN] Try to insert new record
        asserterror ItemAttribute.Insert(true);

        // [THEN] Verify error for missing Name value
        Assert.AreEqual(GetLastErrorText(), MissingAttributeNameErr, 'Different error occur from expected.');
    end;

    [Test]
    procedure NumericValueShouldNotBeZeroWhenCreateIntegerItemAttributeFromItemCategoryCard()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemCategory: Record "Item Category";
        ItemCategoryCard: TestPage "Item Category Card";
    begin
        // [SCENARIO 492807] Integer attribute values not processed correctly if they are generated from the Item Category Card.
        Initialize();

        // [GIVEN] Create Item Category.
        LibraryInventory.CreateItemCategory(ItemCategory);

        // [GIVEN] Create Item Attribute.
        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Integer, '');

        // [GIVEN] Open Item Category Card page and enter Attribute Name and Value.
        ItemCategoryCard.OpenEdit();
        ItemCategoryCard.GoToRecord(ItemCategory);
        ItemCategoryCard.Attributes."Attribute Name".SetValue(ItemAttribute.Name);
        ItemCategoryCard.Attributes.Value.SetValue(Format(LibraryRandom.RandInt(4)));
        ItemCategoryCard.Close();

        // [WHEN] Find Item Attribute Value.
        ItemAttributeValue.SetRange("Attribute ID", ItemAttribute.ID);
        ItemAttributeValue.FindFirst();

        // [VERIFY] Verify Numeric Value is not zero in Item Attribute Value.
        Assert.AreNotEqual(0, ItemAttributeValue."Numeric Value", NumericValueShouldNotBeZeroErr);
    end;

    [Test]
    [HandlerFunctions('ItemAttributeValueListHandler')]
    procedure VerifyNoBlankEntryInsertedInItemAttributeValue()
    var
        Item: Record Item;
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemCard: TestPage "Item Card";
    begin
        // [SCENARIO 565898] An empty attribute value was not created through the item Card
        Initialize();

        // [GIVEN] An item and a set of item attributes
        CreateTestOptionItemAttributes();
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Open the Item Card
        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);

        // [WHEN] The user assigns some attribute values to the item 
        ItemAttribute.FindFirst();
        AssignItemAttributeViaItemCard(ItemAttribute, ItemAttributeValue, ItemCard);

        // [THEN] No blank Item attribute Value Inserted in the table
        ItemAttributeValue.SetRange("Attribute ID", ItemAttribute.ID);
        ItemAttributeValue.SetRange(Value, '');
        asserterror ItemAttributeValue.FindFirst();

        // [THEN] Verify there is nothing inside the filter
        Assert.AssertNothingInsideFilter();
    end;

    local procedure Initialize()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Item Attributes");
        LibraryApplicationArea.EnableFoundationSetup();
        ItemAttribute.DeleteAll();
        ItemAttributeValue.DeleteAll();
        ItemAttributeValueMapping.DeleteAll();
        LibraryVariableStorage.Clear();
        LibraryNotificationMgt.DisableAllNotifications();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Item Attributes");
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Item Attributes");
    end;

    local procedure VerifyVisibilityInApplicationArea(Experience: Text)
    var
        ItemAttribute: Record "Item Attribute";
        ApplicationAreaSetup: Record "Application Area Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        ItemAttributes: TestPage "Item Attributes";
        ItemAttributeValues: TestPage "Item Attribute Values";
        ItemAttributeTranslations: TestPage "Item Attribute Translations";
        ItemAttributeCard: TestPage "Item Attribute";
        ItemAttributeValueList: TestPage "Item Attribute Value List";
        ItemAttrValueTranslations: TestPage "Item Attr. Value Translations";
        ItemAttributesFactbox: TestPage "Item Attributes Factbox";
    begin
        ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(Experience);

        ItemAttributes.OpenNew();
        Assert.IsTrue(ItemAttributes.ItemAttributeValues.Visible(), '');
        Assert.IsTrue(ItemAttributes.ItemAttributeTranslations.Visible(), '');
        Assert.IsTrue(ItemAttributes.Name.Visible(), '');
        Assert.IsTrue(ItemAttributes.Values.Visible(), '');
        Assert.IsTrue(ItemAttributes.Blocked.Visible(), '');
        ItemAttributes.Close();

        ItemAttributeValues.OpenNew();
        Assert.IsTrue(ItemAttributeValues.ItemAttributeValueTranslations.Visible(), '');
        Assert.IsTrue(ItemAttributeValues.Value.Visible(), '');
        Assert.IsTrue(ItemAttributeValues.Blocked.Visible(), '');
        ItemAttributeValues.Close();

        ItemAttributeTranslations.OpenNew();
        Assert.IsTrue(ItemAttributeTranslations."Language Code".Visible(), '');
        Assert.IsTrue(ItemAttributeTranslations.Name.Visible(), '');
        ItemAttributeTranslations.Close();

        ItemAttributeCard.OpenNew();
        Assert.IsTrue(ItemAttributeCard.ItemAttributeValues.Visible(), '');
        Assert.IsTrue(ItemAttributeCard.ItemAttributeTranslations.Visible(), '');
        Assert.IsTrue(ItemAttributeCard.Name.Visible(), '');
        Assert.IsTrue(ItemAttributeCard.Type.Visible(), '');
        Assert.IsTrue(ItemAttributeCard.Blocked.Visible(), '');
        ItemAttributeCard.Type.SetValue(ItemAttribute.Type::Option);
        Assert.IsFalse(ItemAttributeCard."Unit of Measure".Visible(), '');
        Assert.IsTrue(ItemAttributeCard.Values.Visible(), '');
        ItemAttributeCard.Type.SetValue(ItemAttribute.Type::Integer);
        Assert.IsTrue(ItemAttributeCard."Unit of Measure".Visible(), '');
        Assert.IsFalse(ItemAttributeCard.Values.Visible(), '');
        ItemAttributeCard.Type.SetValue(ItemAttribute.Type::Decimal);
        Assert.IsTrue(ItemAttributeCard."Unit of Measure".Visible(), '');
        Assert.IsFalse(ItemAttributeCard.Values.Visible(), '');
        ItemAttributeCard.Type.SetValue(ItemAttribute.Type::Text);
        Assert.IsFalse(ItemAttributeCard."Unit of Measure".Visible(), '');
        Assert.IsFalse(ItemAttributeCard.Values.Visible(), '');
        ItemAttributeCard.Close();

        ItemAttributeValueList.OpenNew();
        Assert.IsTrue(ItemAttributeValueList."Attribute Name".Visible(), '');
        Assert.IsTrue(ItemAttributeValueList.Value.Visible(), '');
        ItemAttributeValueList.Close();

        ItemAttrValueTranslations.OpenNew();
        Assert.IsTrue(ItemAttrValueTranslations."Language Code".Visible(), '');
        Assert.IsTrue(ItemAttrValueTranslations.Name.Visible(), '');
        ItemAttrValueTranslations.Close();

        ItemAttributesFactbox.OpenView();
        Assert.IsTrue(ItemAttributesFactbox.Attribute.Visible(), '');
        Assert.IsTrue(ItemAttributesFactbox.Value.Visible(), '');
        ItemAttributesFactbox.Close();

        ApplicationAreaSetup.DeleteAll();
        ApplicationAreaMgmtFacade.SetupApplicationArea();
    end;

    local procedure AssignItemAttributeViaItemList(ItemAttribute: Record "Item Attribute"; var ItemAttributeValue: Record "Item Attribute Value"; var ItemList: TestPage "Item List")
    begin
        ItemAttributeValue.SetRange("Attribute ID", ItemAttribute.ID);
        ItemAttributeValue.FindFirst();
        SetItemAttributesViaItemList(ItemList, ItemAttribute, ItemAttributeValue.Value);
    end;

    local procedure AssignItemAttributeViaItemCard(ItemAttribute: Record "Item Attribute"; var ItemAttributeValue: Record "Item Attribute Value"; var ItemCard: TestPage "Item Card")
    begin
        ItemAttributeValue.SetRange("Attribute ID", ItemAttribute.ID);
        ItemAttributeValue.FindFirst();
        SetItemAttributesViaItemCard(ItemCard, ItemAttribute, ItemAttributeValue.Value);
    end;

    local procedure AssignItemAttributeValueToCategory(ItemCategory: Record "Item Category"; ItemAttribute: Record "Item Attribute"; ItemAttributeValue: Text)
    var
        ItemCategoryCard: TestPage "Item Category Card";
    begin
        ItemCategoryCard.OpenEdit();
        ItemCategoryCard.Filter.SetFilter(Code, ItemCategory.Code);
        ItemCategoryCard.Attributes."Attribute Name".SetValue(ItemAttribute.Name);
        ItemCategoryCard.Attributes.Value.SetValue(ItemAttributeValue);
        ItemCategoryCard.Close();
    end;

    local procedure CreateItemAttributeValues(var ItemAttributeValue: Record "Item Attribute Value"; NumerOfValuesPerAttribute: Integer; ItemAttributeType: Option)
    var
        ItemAttribute: Record "Item Attribute";
        I: Integer;
        ValueText: Text;
    begin
        CreateItemAttribute(ItemAttribute, ItemAttributeType);

        if NumerOfValuesPerAttribute = 0 then
            exit;

        for I := 1 to NumerOfValuesPerAttribute do begin
            Clear(ItemAttributeValue);

            case ItemAttributeType of
                ItemAttribute.Type::Decimal:
                    ValueText := Format(LibraryRandom.RandDecInDecimalRange(-1000000, 1000000, 3), 9);
                ItemAttribute.Type::Integer:
                    ValueText := Format(LibraryRandom.RandIntInRange(-1000000, 1000000), 9);
                ItemAttribute.Type::Option,
              ItemAttribute.Type::Text:
                    ValueText :=
                      Format(
                        LibraryUtility.GenerateRandomAlphabeticText(
                          Round(MaxStrLen(ItemAttributeValue.Value) / (NumerOfValuesPerAttribute * 2), 1), 1));
            end;

            CreateItemAttributeValue(ItemAttribute, ItemAttributeValue, ValueText);
        end;

        ItemAttributeValue.SetRange("Attribute ID", ItemAttributeValue."Attribute ID");
        ItemAttributeValue.FindFirst();
    end;

    local procedure CreateItemAttributeValue(var ItemAttribute: Record "Item Attribute"; var ItemAttributeValue: Record "Item Attribute Value"; ValueText: Text)
    begin
        ItemAttributeValue.Init();
        ItemAttributeValue."Attribute ID" := ItemAttribute.ID;
        ItemAttributeValue.Validate(Value, CopyStr(ValueText, 1, MaxStrLen(ItemAttributeValue.Value)));
        ItemAttributeValue.ID := LibraryRandom.RandInt(100);
        ItemAttributeValue.Insert(true);
    end;

    local procedure CreateItemAttributeValueMapping(ItemAttributeID: Integer; ItemNo: Code[20])
    var
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
    begin
        ItemAttributeValueMapping.Init();
        ItemAttributeValueMapping."Table ID" := DATABASE::Item;
        ItemAttributeValueMapping."No." := ItemNo;
        ItemAttributeValueMapping."Item Attribute ID" := ItemAttributeID;
        ItemAttributeValueMapping.Insert();
    end;

    local procedure CreateItemAttribute(var ItemAttribute: Record "Item Attribute"; ItemAttributeType: Option)
    var
        RecRef: RecordRef;
    begin
        ItemAttribute.Init();
        ItemAttribute.Name := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(ItemAttribute.Name)), 1, MaxStrLen(ItemAttribute.Name));
        ItemAttribute.Type := ItemAttributeType;
        RecRef.GetTable(ItemAttribute);
        ItemAttribute.ID := LibraryUtility.GetNewLineNo(RecRef, ItemAttribute.FieldNo(ID));
        ItemAttribute.Insert(true);
    end;

    local procedure CreateItemCategoryWithTextAttributeValue(var ItemCategory: Record "Item Category"; var ItemAttributeValue: Record "Item Attribute Value"; ItemAttributeID: Integer)
    begin
        LibraryInventory.CreateItemAttributeValue(ItemAttributeValue, ItemAttributeID, LibraryUtility.GenerateGUID());
        CreateItemCategoryWithTextAttributeMapping(ItemCategory, ItemAttributeID, ItemAttributeValue.ID);
    end;

    local procedure CreateItemCategoryWithTextAttributeMapping(var ItemCategory: Record "Item Category"; ItemAttributeID: Integer; ItemAttributeValueID: Integer)
    begin
        LibraryInventory.CreateItemCategory(ItemCategory);
        LibraryInventory.CreateItemAttributeValueMapping(
          DATABASE::"Item Category", ItemCategory.Code, ItemAttributeID, ItemAttributeValueID);
    end;

    local procedure CreateItemWithCategory(var Item: Record Item; CategoryCode: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Category Code", CategoryCode);
        Item.Modify(true);
    end;

    local procedure CreateItemWithAttributeAndCategory(var Item: Record Item; ItemAttributeID: Integer; ItemAttributeValueID: Integer; CategoryCode: Code[20])
    begin
        CreateItemWithCategory(Item, CategoryCode);
        LibraryInventory.CreateItemAttributeValueMapping(DATABASE::Item, Item."No.", ItemAttributeID, ItemAttributeValueID);
    end;

    local procedure CreateItemWithTextAttributeValue(var Item: Record Item; var ItemAttributeValue: Record "Item Attribute Value"; ItemAttributeID: Integer)
    begin
        LibraryInventory.CreateItemAttributeValue(ItemAttributeValue, ItemAttributeID, LibraryUtility.GenerateGUID());
        CreateItemWithTextAttributeMapping(Item, ItemAttributeID, ItemAttributeValue.ID);
    end;

    local procedure CreateItemWithTextAttributeMapping(var Item: Record Item; ItemAttributeID: Integer; ItemAttributeValueID: Integer)
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemAttributeValueMapping(DATABASE::Item, Item."No.", ItemAttributeID, ItemAttributeValueID);
    end;

    local procedure CreateSimpleItem(var Item: Record Item; ItemNo: Code[20])
    begin
        Item."No." := ItemNo;
        Item.Insert();
    end;

    local procedure CreateSimpleItemWithNextNo(var Item: Record Item; var ItemNo: Code[20])
    begin
        ItemNo := IncStr(ItemNo);
        CreateSimpleItem(Item, ItemNo);
    end;

    local procedure CreateSimpleItemWithNextNoAndSetItemAttributeValue(var Item: Record Item; var ItemNo: Code[20]; ItemAttributeValue: Record "Item Attribute Value")
    begin
        CreateSimpleItemWithNextNo(Item, ItemNo);
        LibraryInventory.CreateItemAttributeValueMapping(
          DATABASE::Item, Item."No.", ItemAttributeValue."Attribute ID", ItemAttributeValue.ID);
    end;

    local procedure CreateItemWithIntegerAttribute(var ItemAttributeValue: Record "Item Attribute Value")
    var
        Item: Record Item;
        ItemAttribute: Record "Item Attribute";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Integer, '');
        LibraryInventory.CreateItemAttributeValue(ItemAttributeValue, ItemAttribute.ID, Format(LibraryRandom.RandInt(100)));
        LibraryInventory.CreateItemAttributeValueMapping(DATABASE::Item, Item."No.", ItemAttribute.ID, ItemAttributeValue.ID);
    end;

    local procedure CreateTestOptionItemAttributes()
    var
        ItemAttribute: Record "Item Attribute";
    begin
        ItemAttribute.DeleteAll();
        CreateTestOptionItemAttribute();
        CreateTestOptionItemAttribute();
    end;

    local procedure CreateTestIntegerItemAttributes()
    var
        ItemAttribute: Record "Item Attribute";
    begin
        ItemAttribute.DeleteAll();
        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Integer, '');
        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Integer, LibraryUtility.GenerateGUID());
    end;

    local procedure CreateTestDecimalItemAttributes()
    var
        ItemAttribute: Record "Item Attribute";
    begin
        ItemAttribute.DeleteAll();
        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Decimal, '');
        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Decimal, LibraryUtility.GenerateGUID());
    end;

    local procedure CreateTestOptionItemAttribute()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
    begin
        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Option, '');

        LibraryInventory.CreateItemAttributeValue(ItemAttributeValue, ItemAttribute.ID, LowerCase(LibraryUtility.GenerateGUID()));
        LibraryInventory.CreateItemAttributeValue(ItemAttributeValue, ItemAttribute.ID, LowerCase(LibraryUtility.GenerateGUID()));
    end;

    local procedure CreateItemsWithConsecutiveNosAndAttributes(var ItemNo: array[5] of Code[20]; var ItemAttributeValue: Record "Item Attribute Value")
    var
        Item: Record Item;
        ItemAttribute: Record "Item Attribute";
        TypeHelper: Codeunit "Type Helper";
        i: Integer;
    begin
        for i := 1 to ArrayLen(ItemNo) do
            ItemNo[i] := 'A0000' + Format(i);

        CreateItemAttributeValues(ItemAttributeValue, 1, ItemAttribute.Type::Text);

        CreateSimpleItem(Item, ItemNo[1]);
        CreateSimpleItem(Item, ItemNo[2]);
        SetItemAttributeValue(Item, ItemAttributeValue);
        CreateSimpleItem(Item, ItemNo[3]);
        CreateSimpleItem(Item, ItemNo[4]);
        SetItemAttributeValue(Item, ItemAttributeValue);

        for i := 1 to TypeHelper.GetMaxNumberOfParametersInSQLQuery() + 100 do
            CreateSimpleItemWithNextNoAndSetItemAttributeValue(Item, ItemNo[5], ItemAttributeValue);

        CreateSimpleItem(Item, IncStr(ItemNo[5]));
    end;

    local procedure CreateItemsWithNonConsecutiveNosAndAttributes(var ItemNo: array[3] of Code[20]; var ItemAttributeValue: Record "Item Attribute Value")
    var
        Item: Record Item;
        ItemAttribute: Record "Item Attribute";
        TypeHelper: Codeunit "Type Helper";
        i: Integer;
    begin
        for i := 1 to ArrayLen(ItemNo) do
            ItemNo[i] := 'A0000' + Format(i - 1);

        CreateItemAttributeValues(ItemAttributeValue, 1, ItemAttribute.Type::Text);

        CreateSimpleItemWithNextNo(Item, ItemNo[1]);
        CreateSimpleItemWithNextNoAndSetItemAttributeValue(Item, ItemNo[2], ItemAttributeValue);

        for i := 1 to TypeHelper.GetMaxNumberOfParametersInSQLQuery() + 100 do begin
            CreateSimpleItemWithNextNo(Item, ItemNo[3]);
            CreateSimpleItemWithNextNoAndSetItemAttributeValue(Item, ItemNo[3], ItemAttributeValue);
        end;

        CreateSimpleItem(Item, IncStr(ItemNo[3]));
    end;

    local procedure CheckOptionItemAttributeValues(var ItemAttribute: Record "Item Attribute")
    var
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttributes: TestPage "Item Attributes";
        ItemAttributeCard: TestPage "Item Attribute";
        expectedValue: Text;
    begin
        ItemAttributeValue.SetRange("Attribute ID", ItemAttribute.ID);
        ItemAttributes.OpenView();
        ItemAttributes.GotoRecord(ItemAttribute);
        ItemAttributeCard.OpenView();
        ItemAttributeCard.GotoRecord(ItemAttribute);
        ItemAttributeValue.FindSet();
        repeat
            if expectedValue <> '' then
                expectedValue += ',';
            expectedValue += ItemAttributeValue.Value;
        until ItemAttributeValue.Next() = 0;
        ItemAttributes.Values.AssertEquals(expectedValue);
        ItemAttributeCard.Values.AssertEquals(expectedValue);
        ItemAttributes.Close();
        ItemAttributeCard.Close();
    end;

    local procedure FindItemAttributeValue(var ItemAttributeValue: Record "Item Attribute Value"; ItemAttributeID: Integer; AttributeValue: Text)
    begin
        ItemAttributeValue.SetRange("Attribute ID", ItemAttributeID);
        ItemAttributeValue.SetRange(Value, AttributeValue);
        ItemAttributeValue.FindFirst();
    end;

    local procedure InsertOptionItemAttributeValueTranslation(Language: Record Language; ItemAttribute: Record "Item Attribute"; ItemAttributeValue: Record "Item Attribute Value") TranslatedName: Text[250]
    var
        ItemAttrValueTranslation: Record "Item Attr. Value Translation";
    begin
        ItemAttrValueTranslation.Init();
        ItemAttrValueTranslation."Language Code" := Language.Code;
        ItemAttrValueTranslation."Attribute ID" := ItemAttribute.ID;
        ItemAttrValueTranslation.ID := ItemAttributeValue.ID;
        TranslatedName := LibraryUtility.GenerateGUID();
        ItemAttrValueTranslation.Name := TranslatedName;
        ItemAttrValueTranslation.Insert();
    end;

    local procedure SetCategoryAttributeValue(ItemCategoryCode: Code[20])
    var
        ItemCategoryCard: TestPage "Item Category Card";
    begin
        ItemCategoryCard.OpenEdit();
        ItemCategoryCard.GotoKey(ItemCategoryCode);
        ItemCategoryCard.Attributes.First();
        ItemCategoryCard.Attributes.Value.SetValue(LibraryUtility.GenerateGUID());
        ItemCategoryCard.OK().Invoke();
    end;

    local procedure SetItemAttributesViaItemCard(var ItemCard: TestPage "Item Card"; var ItemAttribute: Record "Item Attribute"; var ItemAttributeValue: Text)
    begin
        LibraryVariableStorage.Enqueue(ItemAttribute);
        LibraryVariableStorage.Enqueue(ItemAttributeValue);
        ItemCard.Attributes.Invoke();
    end;

    local procedure SetItemAttributesViaItemList(var ItemList: TestPage "Item List"; var ItemAttribute: Record "Item Attribute"; var ItemAttributeValue: Text)
    begin
        LibraryVariableStorage.Enqueue(ItemAttribute);
        LibraryVariableStorage.Enqueue(ItemAttributeValue);
        ItemList.Attributes.Invoke();
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

    local procedure InvokeFindByAttributes(var ItemList: TestPage "Item List"; var ItemAttributeValue: Record "Item Attribute Value")
    var
        ItemAttribute: Record "Item Attribute";
    begin
        ItemList.OpenView();
        LibraryVariableStorage.Enqueue(ItemAttributeValue.Count);
        if ItemAttributeValue.FindSet() then
            repeat
                ItemAttribute.Get(ItemAttributeValue."Attribute ID");
                LibraryVariableStorage.Enqueue(ItemAttribute.Name);
                LibraryVariableStorage.Enqueue(ItemAttributeValue.Value);
            until ItemAttributeValue.Next() = 0;

        ItemList.FilterByAttributes.Invoke();
    end;

    local procedure InvokeItemAttributesEditor(ItemNo: Code[20]): Text
    var
        ItemCard: TestPage "Item Card";
        NewAttributeValue: Text;
    begin
        ItemCard.OpenView();
        ItemCard.GotoKey(ItemNo);

        NewAttributeValue := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(NewAttributeValue);
        ItemCard.Attributes.Invoke();

        exit(NewAttributeValue);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VerifyAssistEditFilterItemAttributesHandler(var FilterItemsbyAttribute: TestPage "Filter Items by Attribute")
    begin
        FilterItemsbyAttribute.New();
        FilterItemsbyAttribute.Attribute.SetValue(LibraryVariableStorage.PeekText(1));
        FilterItemsbyAttribute.Value.AssistEdit();

        Assert.AreEqual(LibraryVariableStorage.DequeueText(), FilterItemsbyAttribute.Value.Value, 'Wrong filter was set');
    end;

    local procedure VerifyAttributeMappingCount(AttributeID: Integer; AttrValueID: Integer; ExpectedCount: Integer)
    var
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
    begin
        ItemAttributeValueMapping.SetRange("Item Attribute ID", AttributeID);
        ItemAttributeValueMapping.SetRange("Item Attribute Value ID", AttrValueID);
        Assert.AreEqual(ExpectedCount, ItemAttributeValueMapping.Count, '');
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

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemAttributeValueListHandler(var ItemAttributeValueEditor: TestPage "Item Attribute Value Editor")
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeVar: Variant;
        ItemAttributeValueVar: Variant;
        ItemAttributeValue: Text;
    begin
        LibraryVariableStorage.Dequeue(ItemAttributeVar);
        LibraryVariableStorage.Dequeue(ItemAttributeValueVar);
        ItemAttribute := ItemAttributeVar;
        ItemAttributeValue := ItemAttributeValueVar;
        ItemAttributeValueEditor.ItemAttributeValueList.New();
        ItemAttributeValueEditor.ItemAttributeValueList."Attribute Name".SetValue(ItemAttribute.Name);
        ItemAttributeValueEditor.ItemAttributeValueList.Value.SetValue(ItemAttributeValue);
        ItemAttributeValueEditor.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CloseItemAttributeValueListHandler(var ItemAttributeValueEditor: TestPage "Item Attribute Value Editor")
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeVar: Variant;
        ItemAttributeValueVar: Variant;
        ItemAttributeValue: Text;
    begin
        LibraryVariableStorage.Dequeue(ItemAttributeVar);
        LibraryVariableStorage.Dequeue(ItemAttributeValueVar);
        ItemAttribute := ItemAttributeVar;
        ItemAttributeValue := ItemAttributeValueVar;
        ItemAttributeValueEditor.ItemAttributeValueList.New();
        ItemAttributeValueEditor.ItemAttributeValueList."Attribute Name".SetValue(ItemAttribute.Name);
        ItemAttributeValueEditor.ItemAttributeValueList.Value.SetValue(ItemAttributeValue);
        ItemAttributeValueEditor.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemAttributeValueSetBlockedAttributeError(var ItemAttributeValueEditor: TestPage "Item Attribute Value Editor")
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeVar: Variant;
        ItemAttributeValueVar: Variant;
        ItemAttributeValue: Text;
    begin
        LibraryVariableStorage.Dequeue(ItemAttributeVar);
        LibraryVariableStorage.Dequeue(ItemAttributeValueVar);
        ItemAttribute := ItemAttributeVar;
        ItemAttributeValue := ItemAttributeValueVar;
        ItemAttributeValueEditor.ItemAttributeValueList.New();
        asserterror ItemAttributeValueEditor.ItemAttributeValueList."Attribute Name".SetValue(ItemAttribute.Name);
        Assert.ExpectedError(StrSubstNo(AttributeBlockedErr, ItemAttribute.Name));
        asserterror ItemAttributeValueEditor.ItemAttributeValueList.Value.SetValue(ItemAttributeValue);
        ItemAttributeValueEditor.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemAttributeValueSetBlockedAttributeValueError(var ItemAttributeValueEditor: TestPage "Item Attribute Value Editor")
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeVar: Variant;
        ItemAttributeValueVar: Variant;
        ItemAttributeValue: Text;
    begin
        LibraryVariableStorage.Dequeue(ItemAttributeVar);
        LibraryVariableStorage.Dequeue(ItemAttributeValueVar);
        ItemAttribute := ItemAttributeVar;
        ItemAttributeValue := ItemAttributeValueVar;
        ItemAttributeValueEditor.ItemAttributeValueList.New();
        ItemAttributeValueEditor.ItemAttributeValueList."Attribute Name".SetValue(ItemAttribute.Name);
        asserterror ItemAttributeValueEditor.ItemAttributeValueList.Value.SetValue(ItemAttributeValue);
        Assert.ExpectedError(StrSubstNo(AttributeValueBlockedErr, ItemAttributeValue));
        ItemAttributeValueEditor.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemAttributeValueChangeValueEditor(var ItemAttributeValueEditor: TestPage "Item Attribute Value Editor")
    begin
        ItemAttributeValueEditor.ItemAttributeValueList.Value.SetValue(LibraryVariableStorage.DequeueText());
        ItemAttributeValueEditor.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EditItemAttributeValueListHandler(var ItemAttributeValueEditor: TestPage "Item Attribute Value Editor")
    var
        ItemAttributeName: Text;
    begin
        ItemAttributeName := LibraryVariableStorage.DequeueText();
        ItemAttributeValueEditor.ItemAttributeValueList."Attribute Name".SetValue(ItemAttributeName);
        ItemAttributeValueEditor.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure FilterItemAttributesHandler(var FilterItemsbyAttribute: TestPage "Filter Items by Attribute")
    var
        NumberOfParameters: Integer;
        I: Integer;
    begin
        NumberOfParameters := LibraryVariableStorage.DequeueInteger();
        for I := 1 to NumberOfParameters do begin
            FilterItemsbyAttribute.New();
            FilterItemsbyAttribute.Attribute.SetValue(LibraryVariableStorage.DequeueText());
            FilterItemsbyAttribute.Value.SetValue(LibraryVariableStorage.DequeueText());
        end;

        FilterItemsbyAttribute.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AssistEditFilterItemAttributesHandler(var FilterItemsAssistEdit: TestPage "Filter Items - AssistEdit")
    var
        ItemAttribute: Record "Item Attribute";
        AttributeName: Text;
    begin
        AttributeName := LibraryVariableStorage.DequeueText();
        ItemAttribute.SetRange(Name, AttributeName);
        ItemAttribute.FindFirst();

        case ItemAttribute.Type of
            ItemAttribute.Type::Decimal, ItemAttribute.Type::Integer:
                begin
                    FilterItemsAssistEdit.NumericConditions.SetValue(1); // Range
                    FilterItemsAssistEdit.NumericValue.SetValue(LibraryVariableStorage.DequeueText());
                    FilterItemsAssistEdit.MaxNumericValue.SetValue(LibraryVariableStorage.DequeueText());
                end;
            ItemAttribute.Type::Text:
                begin
                    FilterItemsAssistEdit.TextConditions.SetValue(2); // Starts with
                    FilterItemsAssistEdit.TextValue.SetValue(LibraryVariableStorage.DequeueText());
                end;
        end;

        FilterItemsAssistEdit.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectOptionValueFilterItemAttributesHandler(var SelectItemAttributeValue: TestPage "Select Item Attribute Value")
    begin
        LibraryVariableStorage.DequeueText();
        SelectItemAttributeValue.Cancel().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

