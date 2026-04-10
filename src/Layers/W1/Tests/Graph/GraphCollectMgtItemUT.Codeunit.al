codeunit 134627 "Graph Collect Mgt Item UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [Item]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        BaseUnitOfMeasureCannotHaveConversionsErr: Label 'Base Unit Of Measure must be specified on the item first.';

    [Test]
    [Scope('OnPrem')]
    procedure TestBaseUOMToJSON()
    var
        Item: Record Item;
        GraphCollectionMgtItem: Codeunit "Graph Collection Mgt - Item";
        ItemUOMJSON: Text;
    begin
        // [FEATURE] [Unit of Measure]
        // Setup
        CreateTestItem(Item);

        // Execute
        ItemUOMJSON := GraphCollectionMgtItem.ItemUnitOfMeasureToJSON(Item, Item."Base Unit of Measure");

        // Verify
        VerifyUOMJSON(ItemUOMJSON, Item."Base Unit of Measure");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNonExistiongUOMToJSON()
    var
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        GraphCollectionMgtItem: Codeunit "Graph Collection Mgt - Item";
        ItemUOMJSON: Text;
    begin
        // [FEATURE] [Unit of Measure]
        // Setup
        CreateTestItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        UnitOfMeasure.Delete();

        // Execute
        ItemUOMJSON := GraphCollectionMgtItem.ItemUnitOfMeasureToJSON(Item, UnitOfMeasure.Code);

        // Verify
        Assert.AreEqual('', ItemUOMJSON, 'Blank JSON should be generated for non existing UOM');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNoAssignedUOMToJSONGeneratesBlankJSON()
    var
        Item: Record Item;
        GraphCollectionMgtItem: Codeunit "Graph Collection Mgt - Item";
        ItemUOMJSON: Text;
    begin
        // [FEATURE] [Unit of Measure]
        // Setup
        CreateTestItem(Item);
        Item."Base Unit of Measure" := '';
        Item.Modify();

        // Execute
        ItemUOMJSON := GraphCollectionMgtItem.ItemUnitOfMeasureToJSON(Item, Item."Base Unit of Measure");

        // Verify
        Assert.AreEqual('', ItemUOMJSON, 'Blank string should be returned');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestConversionUOMToJSON()
    var
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        GraphCollectionMgtItem: Codeunit "Graph Collection Mgt - Item";
        ItemUOMJSON: Text;
    begin
        // [FEATURE] [Unit of Measure]
        // Setup
        CreateTestItem(Item);
        SetSaleUnitOfMeasureDifferentThanBase(Item, UnitOfMeasure);
        Item.Modify(true);

        // Execute
        ItemUOMJSON := GraphCollectionMgtItem.ItemUnitOfMeasureToJSON(Item, Item."Sales Unit of Measure");

        // Verify
        VerifyUnitOfMeasureConversionJSON(ItemUOMJSON, Item, Item."Sales Unit of Measure");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBlankUOMCodeGeneratesBlankJSON()
    var
        Item: Record Item;
        GraphCollectionMgtItem: Codeunit "Graph Collection Mgt - Item";
        ItemUOMJSON: Text;
        BlankUOMCode: Code[10];
    begin
        // [FEATURE] [Unit of Measure]
        // Setup
        CreateTestItem(Item);
        BlankUOMCode := '';

        // Execute
        ItemUOMJSON := GraphCollectionMgtItem.ItemUnitOfMeasureToJSON(Item, BlankUOMCode);

        // Verify
        Assert.AreEqual('', ItemUOMJSON, 'For blank UOM blank string should be returned');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateBaseUOMValues()
    var
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        TempUnitOfMeasure: Record "Unit of Measure" temporary;
        ItemUOMJSON: Text;
    begin
        // [FEATURE] [Unit of Measure]
        // Setup
        CreateTestItem(Item);
        UnitOfMeasure.Get(Item."Base Unit of Measure");
        TempUnitOfMeasure.TransferFields(UnitOfMeasure);
        TempUnitOfMeasure.Insert(true);
        ModifyNonKeyFieldsOnUnitOfMeasure(TempUnitOfMeasure);
        ItemUOMJSON := ConvertUnitOfMeasureToJSON(TempUnitOfMeasure);

        // Execute
        UpdateBaseUnitOfMeasure(Item, ItemUOMJSON);

        // Verify
        UnitOfMeasure.Get(TempUnitOfMeasure.Code);
        UnitOfMeasure.TestField(Description, TempUnitOfMeasure.Description);
        UnitOfMeasure.TestField(Symbol, TempUnitOfMeasure.Symbol);
        VerifyUOMJSON(ItemUOMJSON, Item."Base Unit of Measure");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSettingBaseUOMToBlank()
    var
        Item: Record Item;
        DummyUnitOfMeasure: Record "Unit of Measure";
    begin
        // [FEATURE] [Unit of Measure]
        // Setup
        CreateTestItem(Item);

        // Execute
        UpdateBaseUnitOfMeasure(Item, GenerateNoUOMJSONString());

        // Verify
        Assert.IsFalse(DummyUnitOfMeasure.Get(''), 'No blank units of measure should have been created');
        Assert.AreEqual('', Item."Base Unit of Measure", 'Base unit of measure for item should be set to blank');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBlankBaseUOMJSONDoesNotModifyTheItem()
    var
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        GraphCollectionMgtItem: Codeunit "Graph Collection Mgt - Item";
        ItemUOMJSON: Text;
    begin
        // [FEATURE] [Unit of Measure]
        // Setup
        CreateTestItem(Item);
        UnitOfMeasure.Get(Item."Base Unit of Measure");
        ItemUOMJSON := GraphCollectionMgtItem.ItemUnitOfMeasureToJSON(Item, Item."Base Unit of Measure");

        // Execute
        UpdateBaseUnitOfMeasure(Item, '');

        // Verify
        UnitOfMeasure.Find();
        Assert.AreEqual(Item."Base Unit of Measure", UnitOfMeasure.Code, 'Base unit of measure should not have been changed');
        VerifyUOMJSON(ItemUOMJSON, Item."Base Unit of Measure");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestReplaceBOMWithExistingUOM()
    var
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        UnitOfMeasureNew: Record "Unit of Measure";
        ItemUOMJSON: Text;
    begin
        // [FEATURE] [Unit of Measure]
        // Setup
        CreateTestItem(Item);
        UnitOfMeasure.Get(Item."Base Unit of Measure");
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasureNew);

        ItemUOMJSON := ConvertUnitOfMeasureToJSON(UnitOfMeasureNew);

        // Execute
        UpdateBaseUnitOfMeasure(Item, ItemUOMJSON);

        // Verify
        Assert.IsTrue(UnitOfMeasure.Find(), 'Old unit of measure should not have been removed');
        Assert.AreEqual(Item."Base Unit of Measure", UnitOfMeasureNew.Code, 'Base UOM was not updated');
        VerifyUOMJSON(ItemUOMJSON, Item."Base Unit of Measure");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestReplaceBOMWithNewUOMCreatesNewUOMOnTheFly()
    var
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        UnitOfMeasureNew: Record "Unit of Measure";
        ItemUOMJSON: Text;
    begin
        // [FEATURE] [Unit of Measure]
        // Setup
        CreateTestItem(Item);
        UnitOfMeasure.Get(Item."Base Unit of Measure");
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasureNew);
        ItemUOMJSON := ConvertUnitOfMeasureToJSON(UnitOfMeasureNew);
        UnitOfMeasureNew.Delete(true);

        // Execute
        UpdateBaseUnitOfMeasure(Item, ItemUOMJSON);

        // Verify
        Assert.IsTrue(UnitOfMeasure.Find(), 'Old unit of measure should not have been removed');
        Assert.AreNotEqual(Item."Base Unit of Measure", UnitOfMeasure.Code, 'Base UOM was not updated');
        Assert.IsTrue(UnitOfMeasureNew.Get(Item."Base Unit of Measure"), 'New unit of measure was not inserted');
        VerifyUOMJSON(ItemUOMJSON, Item."Base Unit of Measure");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestReplaceBOMWithConversionsExisting()
    var
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        SalesUnitOfMeasure: Record "Unit of Measure";
        UnitOfMeasureNew: Record "Unit of Measure";
        ItemBaseUOMJSON: Text;
    begin
        // [FEATURE] [Unit of Measure]
        // Setup
        CreateTestItem(Item);
        UnitOfMeasure.Get(Item."Base Unit of Measure");
        SetSaleUnitOfMeasureDifferentThanBase(Item, SalesUnitOfMeasure);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasureNew);
        ItemBaseUOMJSON := ConvertUnitOfMeasureToJSON(UnitOfMeasureNew);

        // Execute
        UpdateBaseUnitOfMeasure(Item, ItemBaseUOMJSON);

        // Verify
        Assert.IsTrue(UnitOfMeasure.Find(), 'Old unit of measure should not have been removed');
        Assert.AreEqual(Item."Base Unit of Measure", UnitOfMeasureNew.Code, 'Base UOM was not updated');
        Assert.AreEqual(UnitOfMeasureNew.Code, Item."Sales Unit of Measure", 'Sales UOM should be set to base');
        Assert.IsTrue(SalesUnitOfMeasure.Find(), 'Sales UOM should not have been removed');
        VerifyUOMJSON(ItemBaseUOMJSON, Item."Base Unit of Measure");

        // Test blank Base UOM with Sales UOM Existing - error

        // test blank Base UOM and Sales UOM
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSettingBaseUOMToBlankWithUOMWithConversions()
    var
        Item: Record Item;
        BaseUnitOfMeasure: Record "Unit of Measure";
        SalesUnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        TempUnitOfMeasure: Record "Unit of Measure" temporary;
        ItemUOMJSON: Text;
    begin
        // [FEATURE] [Unit of Measure]
        // Setup
        CreateTestItem(Item);
        BaseUnitOfMeasure.Get(Item."Base Unit of Measure");
        SetSaleUnitOfMeasureDifferentThanBase(Item, SalesUnitOfMeasure);

        ItemUOMJSON := ConvertUnitOfMeasureToJSON(TempUnitOfMeasure);

        // Execute
        UpdateBaseUnitOfMeasure(Item, ItemUOMJSON);

        // Verify
        SalesUnitOfMeasure.Find();
        Assert.AreEqual('', Item."Sales Unit of Measure", 'Sales unit of measure was not updated');
        Assert.IsTrue(ItemUnitOfMeasure.Get(Item."No.", SalesUnitOfMeasure.Code), 'Old Item unit of measure was deleted');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSettingUOMWithCoversionsToADifferentValueRaisesAnError()
    var
        Item: Record Item;
        SalesUnitOfMeasure: Record "Unit of Measure";
        NewSalesUnitOfMeasure: Record "Unit of Measure";
        ItemUOMJSON: Text;
        FromToConversionRate: Decimal;
    begin
        // [FEATURE] [Unit of Measure]
        // Setup
        CreateTestItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(SalesUnitOfMeasure);
        LibraryInventory.CreateUnitOfMeasureCode(NewSalesUnitOfMeasure);
        FromToConversionRate := LibraryRandom.RandDecInDecimalRange(1, 10000, 2);

        ItemUOMJSON := ConvertUnitOfMeasureWithConversionsToJSON(SalesUnitOfMeasure, NewSalesUnitOfMeasure, FromToConversionRate);

        // Execute
        asserterror UpdateBaseUnitOfMeasure(Item, ItemUOMJSON);

        // Verify
        Assert.ExpectedError(BaseUnitOfMeasureCannotHaveConversionsErr);
    end;

    local procedure GenerateNoUOMJSONString(): Text
    var
        JSONManagement: Codeunit "JSON Management";
        GraphCollectionMgtItem: Codeunit "Graph Collection Mgt - Item";
        JsonObject: DotNet JObject;
    begin
        JSONManagement.InitializeEmptyObject();
        JSONManagement.GetJSONObject(JsonObject);
        JSONManagement.AddJPropertyToJObject(JsonObject, GraphCollectionMgtItem.UOMComplexTypeUnitCode(), '');
        exit(JSONManagement.WriteObjectToString());
    end;

    local procedure CreateTestItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Assert.AreNotEqual(Item."Base Unit of Measure", '', 'Base Unit of measure must be set');
        Assert.AreNotEqual(Item."Sales Unit of Measure", '', 'Sales Unit of measure must be set');
        Assert.AreNotEqual(Item."Purch. Unit of Measure", '', 'Purch. Unit of measure must be set');
    end;

    local procedure SetSaleUnitOfMeasureDifferentThanBase(var Item: Record Item; var UnitOfMeasure: Record "Unit of Measure")
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(
          ItemUnitOfMeasure, Item."No.", UnitOfMeasure.Code, LibraryRandom.RandDecInDecimalRange(1, 10000, 2));
        Item.Validate("Sales Unit of Measure", ItemUnitOfMeasure.Code);
    end;

    local procedure UpdateBaseUnitOfMeasure(var Item: Record Item; BaseUOMJSon: Text)
    var
        GraphCollectionMgtItem: Codeunit "Graph Collection Mgt - Item";
    begin
        GraphCollectionMgtItem.ProcessComplexTypes(
          Item,
          BaseUOMJSon
          );
    end;

    local procedure ModifyNonKeyFieldsOnUnitOfMeasure(var UnitOfMeasure: Record "Unit of Measure")
    begin
        UnitOfMeasure.Validate(Description, LibraryUtility.GenerateGUID());
        UnitOfMeasure.Validate(Symbol, LibraryUtility.GenerateGUID());
        UnitOfMeasure.Modify(true);
    end;

    local procedure ConvertUnitOfMeasureToJSON(UnitOfMeasure: Record "Unit of Measure"): Text
    var
        JSONManagement: Codeunit "JSON Management";
        GraphCollectionMgtItem: Codeunit "Graph Collection Mgt - Item";
        JsonObject: DotNet JObject;
    begin
        JSONManagement.InitializeEmptyObject();
        JSONManagement.GetJSONObject(JsonObject);
        JSONManagement.AddJPropertyToJObject(JsonObject, GraphCollectionMgtItem.UOMComplexTypeUnitCode(), UnitOfMeasure.Code);
        JSONManagement.AddJPropertyToJObject(JsonObject, GraphCollectionMgtItem.UOMComplexTypeUnitName(), UnitOfMeasure.Description);
        JSONManagement.AddJPropertyToJObject(JsonObject, GraphCollectionMgtItem.UOMComplexTypeSymbol(), UnitOfMeasure.Symbol);
        exit(JSONManagement.WriteObjectToString());
    end;

    local procedure ConvertUnitOfMeasureWithConversionsToJSON(var UnitOfMeasure: Record "Unit of Measure"; var BaseUnitOfMeasure: Record "Unit of Measure"; ConversionRate: Decimal): Text
    var
        JSONManagement: Codeunit "JSON Management";
        GraphCollectionMgtItem: Codeunit "Graph Collection Mgt - Item";
        JsonObject: DotNet JObject;
        ComplexTypeJSONObject: DotNet JObject;
    begin
        JSONManagement.InitializeObject(ConvertUnitOfMeasureToJSON(UnitOfMeasure));
        JSONManagement.GetJSONObject(JsonObject);

        ComplexTypeJSONObject := ComplexTypeJSONObject.JObject();
        JSONManagement.AddJPropertyToJObject(
          ComplexTypeJSONObject, GraphCollectionMgtItem.UOMConversionComplexTypeToUnitOfMeasure(), BaseUnitOfMeasure.Code);
        JSONManagement.AddJPropertyToJObject(
          ComplexTypeJSONObject, GraphCollectionMgtItem.UOMConversionComplexTypeFromToConversionRate(), ConversionRate);
        JSONManagement.AddJObjectToJObject(JsonObject, GraphCollectionMgtItem.UOMConversionComplexTypeName(), ComplexTypeJSONObject);

        exit(JSONManagement.WriteObjectToString());
    end;

    local procedure VerifyUOMJSON(BaseUOMJSON: Text; ExpectedUOMCode: Code[20])
    var
        UnitOfMeasure: Record "Unit of Measure";
        JSONManagement: Codeunit "JSON Management";
        GraphCollectionMgtItem: Codeunit "Graph Collection Mgt - Item";
        JsonObject: DotNet JObject;
        UnitCode: Text;
        UnitSymbol: Text;
        UnitName: Text;
    begin
        JSONManagement.InitializeObject(BaseUOMJSON);
        JSONManagement.GetJSONObject(JsonObject);
        JSONManagement.GetStringPropertyValueFromJObjectByName(JsonObject, GraphCollectionMgtItem.UOMComplexTypeUnitCode(), UnitCode);
        JSONManagement.GetStringPropertyValueFromJObjectByName(JsonObject, GraphCollectionMgtItem.UOMComplexTypeSymbol(), UnitSymbol);
        JSONManagement.GetStringPropertyValueFromJObjectByName(JsonObject, GraphCollectionMgtItem.UOMComplexTypeUnitName(), UnitName);

        UnitOfMeasure.Init();
        if ExpectedUOMCode <> '' then
            UnitOfMeasure.Get(ExpectedUOMCode);

        Assert.AreEqual(UnitOfMeasure.Code, UnitCode, 'UnitCode is not as expected');
        Assert.AreEqual(UnitOfMeasure.Description, UnitName, 'UnitName is not as expected');
        Assert.AreEqual(UnitOfMeasure.Symbol, UnitSymbol, 'UnitSymbol is not as expected');
    end;

    local procedure VerifyUnitOfMeasureConversionJSON(UOMWithConversionJSON: Text; var Item: Record Item; UOMCode: Code[20])
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        JSONManagement: Codeunit "JSON Management";
        GraphCollectionMgtItem: Codeunit "Graph Collection Mgt - Item";
        JsonObject: DotNet JObject;
        ConversionJObject: DotNet JObject;
        ConversionJObjectVariant: Variant;
        ConversionRateTxt: Text;
        ConversionRate: Decimal;
        ToUnitOfMeasure: Text;
    begin
        VerifyUOMJSON(UOMWithConversionJSON, UOMCode);

        JSONManagement.InitializeObject(UOMWithConversionJSON);
        JSONManagement.GetJSONObject(JsonObject);
        JSONManagement.GetPropertyValueFromJObjectByName(
          JsonObject, GraphCollectionMgtItem.UOMConversionComplexTypeName(), ConversionJObjectVariant);
        ConversionJObject := ConversionJObjectVariant;

        JSONManagement.GetStringPropertyValueFromJObjectByName(
          ConversionJObject, GraphCollectionMgtItem.UOMConversionComplexTypeFromToConversionRate(), ConversionRateTxt);
        Evaluate(ConversionRate, ConversionRateTxt, 9);

        JSONManagement.GetStringPropertyValueFromJObjectByName(
          ConversionJObject, GraphCollectionMgtItem.UOMConversionComplexTypeToUnitOfMeasure(), ToUnitOfMeasure);

        ItemUnitOfMeasure.Get(Item."No.", UOMCode);
        Assert.AreEqual(Item."Base Unit of Measure", ToUnitOfMeasure, 'ToUnitOfMeasure is not as expected');
        Assert.AreEqual(ItemUnitOfMeasure."Qty. per Unit of Measure", ConversionRate, 'ConversionRate is not as expected');
    end;
}

