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
        GraphCollectionMgtItem: Codeunit "Graph Collection Mgt - Item";
        JsonObject: JsonObject;
        JsonText: Text;
    begin
        JsonObject.Add(GraphCollectionMgtItem.UOMComplexTypeUnitCode(), '');
        JsonObject.WriteTo(JsonText);
        exit(JsonText);
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
        GraphCollectionMgtItem: Codeunit "Graph Collection Mgt - Item";
        JsonObject: JsonObject;
        JsonText: Text;
    begin
        JsonObject.Add(GraphCollectionMgtItem.UOMComplexTypeUnitCode(), UnitOfMeasure.Code);
        JsonObject.Add(GraphCollectionMgtItem.UOMComplexTypeUnitName(), UnitOfMeasure.Description);
        JsonObject.Add(GraphCollectionMgtItem.UOMComplexTypeSymbol(), UnitOfMeasure.Symbol);
        JsonObject.WriteTo(JsonText);
        exit(JsonText);
    end;

    local procedure ConvertUnitOfMeasureWithConversionsToJSON(var UnitOfMeasure: Record "Unit of Measure"; var BaseUnitOfMeasure: Record "Unit of Measure"; ConversionRate: Decimal): Text
    var
        GraphCollectionMgtItem: Codeunit "Graph Collection Mgt - Item";
        JsonObject: JsonObject;
        ComplexTypeJSONObject: JsonObject;
        JsonText: Text;
    begin
        JsonObject.ReadFrom(ConvertUnitOfMeasureToJSON(UnitOfMeasure));

        ComplexTypeJSONObject.Add(GraphCollectionMgtItem.UOMConversionComplexTypeToUnitOfMeasure(), BaseUnitOfMeasure.Code);
        ComplexTypeJSONObject.Add(GraphCollectionMgtItem.UOMConversionComplexTypeFromToConversionRate(), ConversionRate);
        JsonObject.Add(GraphCollectionMgtItem.UOMConversionComplexTypeName(), ComplexTypeJSONObject);

        JsonObject.WriteTo(JsonText);
        exit(JsonText);
    end;

    local procedure VerifyUOMJSON(BaseUOMJSON: Text; ExpectedUOMCode: Code[20])
    var
        UnitOfMeasure: Record "Unit of Measure";
        GraphCollectionMgtItem: Codeunit "Graph Collection Mgt - Item";
        JsonObject: JsonObject;
        UnitCode: Text;
        UnitSymbol: Text;
        UnitName: Text;
    begin
        JsonObject.ReadFrom(BaseUOMJSON);
        UnitCode := JsonObject.GetText(GraphCollectionMgtItem.UOMComplexTypeUnitCode(), true);
        UnitSymbol := JsonObject.GetText(GraphCollectionMgtItem.UOMComplexTypeSymbol(), true);
        UnitName := JsonObject.GetText(GraphCollectionMgtItem.UOMComplexTypeUnitName(), true);

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
        GraphCollectionMgtItem: Codeunit "Graph Collection Mgt - Item";
        JsonObject: JsonObject;
        ConversionJObject: JsonObject;
        ConversionJsonToken: JsonToken;
        ConversionRateTxt: Text;
        ConversionRate: Decimal;
        ToUnitOfMeasure: Text;
    begin
        VerifyUOMJSON(UOMWithConversionJSON, UOMCode);

        JsonObject.ReadFrom(UOMWithConversionJSON);
        JsonObject.Get(GraphCollectionMgtItem.UOMConversionComplexTypeName(), ConversionJsonToken);
        ConversionJObject := ConversionJsonToken.AsObject();

        ConversionRateTxt := ConversionJObject.GetText(GraphCollectionMgtItem.UOMConversionComplexTypeFromToConversionRate());
        Evaluate(ConversionRate, ConversionRateTxt, 9);

        ToUnitOfMeasure := ConversionJObject.GetText(GraphCollectionMgtItem.UOMConversionComplexTypeToUnitOfMeasure());

        ItemUnitOfMeasure.Get(Item."No.", UOMCode);
        Assert.AreEqual(Item."Base Unit of Measure", ToUnitOfMeasure, 'ToUnitOfMeasure is not as expected');
        Assert.AreEqual(ItemUnitOfMeasure."Qty. per Unit of Measure", ConversionRate, 'ConversionRate is not as expected');
    end;
}
