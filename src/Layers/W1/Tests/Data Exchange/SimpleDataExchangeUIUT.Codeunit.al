codeunit 134280 "Simple Data Exchange UI UT"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Data Exchange]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        Initialized: Boolean;
        CurrencyCodeXMLElementTxt: Label '\exchangerates\dailyrates\@code';
        StartingDateXMLElementTxt: Label '\exchangerates\@id';
        ExchRateAmountXMLElementTxt: Label '\exchangerates\dailyrates\rate';
        RelationalExchRateAmountXMLElementTxt: Label '\exchangerates\dailyrates\@amount';
        NewDefinitionLineSourceTxt: Label '\exchangerates\dailyrates\';

    local procedure Initialize()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        InventorySetup: Record "Inventory Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Simple Data Exchange UI UT");
        DataExch.DeleteAll(true);
        DataExchDef.DeleteAll(true);

        if Initialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Simple Data Exchange UI UT");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryInventory.NoSeriesSetup(InventorySetup);
        Initialized := true;

        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Simple Data Exchange UI UT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGeneratingSetupWithSuggestedFieldsOnly()
    var
        DataExchDef: Record "Data Exch. Def";
        TempSuggestedField: Record "Field" temporary;
        DataExchFieldMappingBuf: Record "Data Exch. Field Mapping Buf.";
        TempDataExchFieldMappingBuf: Record "Data Exch. Field Mapping Buf." temporary;
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchMapping: Record "Data Exch. Mapping";
        Depth: Integer;
    begin
        // Setup
        Initialize();
        CreateDataExchangeDefinition(DataExchDef, DataExchLineDef, DataExchMapping);
        GetSuggestedFields(TempSuggestedField);

        // Execute
        DataExchFieldMappingBuf.InsertFromDataExchDefinition(TempDataExchFieldMappingBuf, DataExchDef, TempSuggestedField);

        // Verify
        Assert.IsTrue(DataExchFieldMappingBuf.IsEmpty, 'No permanent records should have been inserted');
        Assert.IsTrue(TempSuggestedField.Count > 0, 'Temp suggested fields must have a value');
        TempDataExchFieldMappingBuf.FindFirst();

        Depth := 0;
        VerifyDataExchangeDefLineField(TempDataExchFieldMappingBuf, DataExchLineDef, DataExchMapping, Depth);

        Depth := 1;
        Assert.AreEqual(
          TempSuggestedField.Count, TempDataExchFieldMappingBuf.Count - 1, 'Wrong number of TempSimpleDataExchangeSetup records found');
        VerifySuggestedFields(TempDataExchFieldMappingBuf, DataExchLineDef, TempSuggestedField, Depth);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGeneratingSetupWithMappedFieldsOnly()
    var
        DataExchDef: Record "Data Exch. Def";
        TempSuggestedField: Record "Field" temporary;
        DataExchFieldMappingBuf: Record "Data Exch. Field Mapping Buf.";
        TempDataExchFieldMappingBuf: Record "Data Exch. Field Mapping Buf." temporary;
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        Depth: Integer;
    begin
        // Setup
        Initialize();
        CreateDataExchangeDefinition(DataExchDef, DataExchLineDef, DataExchMapping);
        CreateFieldMappings(DataExchMapping);

        // Execute
        DataExchFieldMappingBuf.InsertFromDataExchDefinition(TempDataExchFieldMappingBuf, DataExchDef, TempSuggestedField);

        // Verify
        Assert.IsTrue(DataExchFieldMappingBuf.IsEmpty, 'No permanent records should have been inserted');
        TempDataExchFieldMappingBuf.FindFirst();

        Depth := 0;
        VerifyDataExchangeDefLineField(TempDataExchFieldMappingBuf, DataExchLineDef, DataExchMapping, Depth);

        Depth := 1;
        Assert.AreEqual(
          DataExchFieldMapping.Count, TempDataExchFieldMappingBuf.Count - 1,
          'Wrong number of TempSimpleDataExchangeSetup records found');
        VerifyMappedFields(TempDataExchFieldMappingBuf, DataExchMapping);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGeneratingSetupWithMixedFields()
    var
        DataExchDef: Record "Data Exch. Def";
        TempSuggestedField: Record "Field" temporary;
        DataExchFieldMappingBuf: Record "Data Exch. Field Mapping Buf.";
        TempDataExchFieldMappingBuf: Record "Data Exch. Field Mapping Buf." temporary;
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        Depth: Integer;
    begin
        // Setup
        Initialize();
        CreateDataExchangeDefinition(DataExchDef, DataExchLineDef, DataExchMapping);
        CreateFieldMappings(DataExchMapping);
        GetSuggestedFields(TempSuggestedField);

        TempSuggestedField.FindFirst();
        DataExchFieldMapping.SetFilter("Field ID", '<>%1', TempSuggestedField."No.");
        DataExchFieldMapping.DeleteAll(true);
        TempSuggestedField.Delete();
        TempSuggestedField.Reset();

        // Execute
        DataExchFieldMappingBuf.InsertFromDataExchDefinition(TempDataExchFieldMappingBuf, DataExchDef, TempSuggestedField);

        // Verify
        Assert.IsTrue(DataExchFieldMappingBuf.IsEmpty, 'No permanent records should have been inserted');
        TempDataExchFieldMappingBuf.FindFirst();

        Depth := 0;
        VerifyDataExchangeDefLineField(TempDataExchFieldMappingBuf, DataExchLineDef, DataExchMapping, Depth);

        Clear(DataExchFieldMapping);
        Depth := 1;
        Assert.AreEqual(
          DataExchFieldMapping.Count, TempDataExchFieldMappingBuf.Count - 1,
          'Wrong number of TempSimpleDataExchangeSetup records found');
        VerifyMappedFields(TempDataExchFieldMappingBuf, DataExchMapping);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGeneratingSetupWithDefinitionLineOnly()
    var
        DataExchDef: Record "Data Exch. Def";
        TempSuggestedField: Record "Field" temporary;
        DataExchFieldMappingBuf: Record "Data Exch. Field Mapping Buf.";
        TempDataExchFieldMappingBuf: Record "Data Exch. Field Mapping Buf." temporary;
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchMapping: Record "Data Exch. Mapping";
        Depth: Integer;
    begin
        // Setup
        Initialize();
        CreateDataExchangeDefinition(DataExchDef, DataExchLineDef, DataExchMapping);

        // Execute
        DataExchFieldMappingBuf.InsertFromDataExchDefinition(TempDataExchFieldMappingBuf, DataExchDef, TempSuggestedField);

        // Verify
        Assert.IsTrue(DataExchFieldMappingBuf.IsEmpty, 'No permanent records should have been inserted');

        Depth := 0;
        Assert.AreEqual(1, TempDataExchFieldMappingBuf.Count, 'Wrong number of TempSimpleDataExchangeSetup records found');
        VerifyDataExchangeDefLineField(TempDataExchFieldMappingBuf, DataExchLineDef, DataExchMapping, Depth);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGeneratingSetupWithParentChildLinesDefinition()
    var
        DataExchDef: Record "Data Exch. Def";
        TempChildSuggestedField: Record "Field" temporary;
        DataExchFieldMappingBuf: Record "Data Exch. Field Mapping Buf.";
        TempDataExchFieldMappingBuf: Record "Data Exch. Field Mapping Buf." temporary;
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchMapping: Record "Data Exch. Mapping";
        ChildDataExchLineDef: Record "Data Exch. Line Def";
        ChildDataExchMapping: Record "Data Exch. Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        Depth: Integer;
    begin
        // Setup
        Initialize();
        CreateDataExchangeDefinition(DataExchDef, DataExchLineDef, DataExchMapping);
        CreateFieldMappings(DataExchMapping);
        CreateChildLineDefinition(DataExchLineDef, ChildDataExchLineDef, ChildDataExchMapping);
        GetSuggestedFieldsChildTable(TempChildSuggestedField);

        // Execute
        DataExchFieldMappingBuf.InsertFromDataExchDefinition(TempDataExchFieldMappingBuf, DataExchDef, TempChildSuggestedField);

        // Verify Header
        Assert.IsTrue(DataExchFieldMappingBuf.IsEmpty, 'No permanent records should have been inserted');
        TempDataExchFieldMappingBuf.FindFirst();
        Assert.AreEqual(
          DataExchFieldMapping.Count, TempDataExchFieldMappingBuf.Count - 2,
          'Wrong number of TempSimpleDataExchangeSetup records found');

        Depth := 0;
        VerifyDataExchangeDefLineField(TempDataExchFieldMappingBuf, DataExchLineDef, DataExchMapping, Depth);

        Clear(DataExchFieldMapping);
        Depth := 1;
        VerifyMappedFields(TempDataExchFieldMappingBuf, DataExchMapping);

        // Verify child lines
        TempDataExchFieldMappingBuf.Reset();
        TempDataExchFieldMappingBuf.SetRange("Data Exchange Line Def Code", ChildDataExchLineDef.Code);
        TempDataExchFieldMappingBuf.FindSet();
        VerifyDataExchangeDefLineField(TempDataExchFieldMappingBuf, ChildDataExchLineDef, ChildDataExchMapping, Depth);

        Depth := 2;
        VerifySuggestedFields(TempDataExchFieldMappingBuf, ChildDataExchLineDef, TempChildSuggestedField, Depth);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInsertingLineManually()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchFieldMappingBuf: Record "Data Exch. Field Mapping Buf.";
        TempDataExchFieldMappingBuf: Record "Data Exch. Field Mapping Buf." temporary;
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        // Setup
        Initialize();
        CreateDataExchangeDefinition(DataExchDef, DataExchLineDef, DataExchMapping);

        // Execute
        CreateSetupRecordManually(TempDataExchFieldMappingBuf, DataExchMapping);

        // Verify
        Assert.IsTrue(DataExchFieldMappingBuf.IsEmpty, 'No permanent records should have been inserted');

        Assert.AreEqual(1, DataExchFieldMapping.Count, 'Data Exchange Field Mapping should have been created');
        Assert.AreEqual(1, DataExchColumnDef.Count, 'Data Exchange Column Def should have been created');
        VerifyMappedFields(TempDataExchFieldMappingBuf, DataExchMapping);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSettingDefaultValue()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchFieldMappingBuf: Record "Data Exch. Field Mapping Buf.";
        TempDataExchFieldMappingBuf: Record "Data Exch. Field Mapping Buf." temporary;
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        DataExchColumnDef: Record "Data Exch. Column Def";
        ExpectedText: Text;
    begin
        // Setup
        Initialize();
        CreateDataExchangeDefinition(DataExchDef, DataExchLineDef, DataExchMapping);
        CreateSetupRecordManually(TempDataExchFieldMappingBuf, DataExchMapping);

        // Execute
        ExpectedText := LibraryUtility.GenerateRandomText(MaxStrLen(TempDataExchFieldMappingBuf."Default Value"));
        TempDataExchFieldMappingBuf.SetRange(Type, TempDataExchFieldMappingBuf.Type::Field);
        TempDataExchFieldMappingBuf.FindFirst();
        TempDataExchFieldMappingBuf.Validate(
          "Default Value", CopyStr(ExpectedText, 1, MaxStrLen(TempDataExchFieldMappingBuf."Default Value")));
        TempDataExchFieldMappingBuf.Modify(true);

        // Verify
        Assert.IsTrue(DataExchFieldMappingBuf.IsEmpty, 'No permanent records should have been inserted');

        Assert.AreEqual(1, DataExchFieldMapping.Count, 'Data Exchange Field Mapping should have been created');
        Assert.AreEqual(1, DataExchColumnDef.Count, 'Data Exchange Column Def should have been created');

        DataExchFieldMapping.SetRange("Field ID", TempDataExchFieldMappingBuf."Field ID");
        DataExchFieldMapping.FindFirst();

        Assert.AreEqual(ExpectedText, DataExchFieldMapping."Default Value", 'Expected value was not set');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletingALine()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchFieldMappingBuf: Record "Data Exch. Field Mapping Buf.";
        TempDataExchFieldMappingBuf: Record "Data Exch. Field Mapping Buf." temporary;
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        // Setup
        Initialize();
        CreateDataExchangeDefinition(DataExchDef, DataExchLineDef, DataExchMapping);
        CreateSetupRecordManually(TempDataExchFieldMappingBuf, DataExchMapping);

        // Execute
        TempDataExchFieldMappingBuf.Delete(true);

        // Verify
        Assert.IsTrue(DataExchFieldMappingBuf.IsEmpty, 'No permanent records should have been inserted');

        Assert.AreEqual(0, DataExchFieldMapping.Count, 'Data Exchange Field Mapping should have been deleted');
        Assert.AreEqual(0, DataExchColumnDef.Count, 'Data Exchange Column Def should have been deleted');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdatingSourceUpdatesColumnMapping()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchFieldMappingBuf: Record "Data Exch. Field Mapping Buf.";
        TempDataExchFieldMappingBuf: Record "Data Exch. Field Mapping Buf." temporary;
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        DataExchColumnDef: Record "Data Exch. Column Def";
        ExpectedText: Text;
    begin
        // Setup
        Initialize();
        CreateDataExchangeDefinition(DataExchDef, DataExchLineDef, DataExchMapping);
        CreateSetupRecordManually(TempDataExchFieldMappingBuf, DataExchMapping);
        ExpectedText := RelationalExchRateAmountXMLElementTxt;
        Assert.AreNotEqual(TempDataExchFieldMappingBuf.Source, ExpectedText, 'Setup data is wrong');

        // Execute
        TempDataExchFieldMappingBuf.Validate(Source, RelationalExchRateAmountXMLElementTxt);

        // Verify
        Assert.IsTrue(DataExchFieldMappingBuf.IsEmpty, 'No permanent records should have been inserted');

        Assert.AreEqual(1, DataExchFieldMapping.Count, 'Data Exchange Field Mapping should have been deleted');
        Assert.AreEqual(1, DataExchColumnDef.Count, 'Data Exchange Column Def should have been deleted');

        DataExchColumnDef.FindFirst();
        Assert.AreEqual(ExpectedText, DataExchColumnDef.Path, 'Path should be updated');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdatingSourceUpdatesLineDefinition()
    var
        DataExchDef: Record "Data Exch. Def";
        TempSuggestedField: Record "Field" temporary;
        DataExchFieldMappingBuf: Record "Data Exch. Field Mapping Buf.";
        TempDataExchFieldMappingBuf: Record "Data Exch. Field Mapping Buf." temporary;
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        DataExchColumnDef: Record "Data Exch. Column Def";
        ExpectedText: Text;
    begin
        // Setup
        Initialize();
        CreateDataExchangeDefinition(DataExchDef, DataExchLineDef, DataExchMapping);
        DataExchFieldMappingBuf.InsertFromDataExchDefinition(TempDataExchFieldMappingBuf, DataExchDef, TempSuggestedField);
        TempDataExchFieldMappingBuf.SetRange(Type, TempDataExchFieldMappingBuf.Type::Table);
        TempDataExchFieldMappingBuf.FindFirst();
        ExpectedText := NewDefinitionLineSourceTxt;
        Assert.AreNotEqual(TempDataExchFieldMappingBuf.Source, ExpectedText, 'Setup data is wrong');

        // Execute
        TempDataExchFieldMappingBuf.Validate(Source, NewDefinitionLineSourceTxt);

        // Verify
        Assert.IsTrue(DataExchFieldMappingBuf.IsEmpty, 'No permanent records should have been inserted');
        TempDataExchFieldMappingBuf.FindFirst();

        Assert.AreEqual(0, DataExchFieldMapping.Count, 'Data Exchange Field Mapping should not be created');
        Assert.AreEqual(0, DataExchColumnDef.Count, 'Data Exchange Column Def should not be created');

        DataExchLineDef.FindFirst();
        Assert.AreEqual(ExpectedText, DataExchLineDef."Data Line Tag", 'Path should be updated');
    end;

    local procedure CreateDataExchangeDefinition(var DataExchDef: Record "Data Exch. Def"; var DataExchLineDef: Record "Data Exch. Line Def"; var DataExchMapping: Record "Data Exch. Mapping")
    begin
        DataExchDef.Init();
        DataExchDef.Code := LibraryUtility.GenerateRandomCode(DataExchDef.FieldNo(Code), DATABASE::"Data Exch. Def");
        DataExchDef.Name := LibraryUtility.GenerateRandomCode(DataExchDef.FieldNo(Name), DATABASE::"Data Exch. Def");
        DataExchDef.Type := DataExchDef.Type::"Generic Import";
        DataExchDef."Reading/Writing Codeunit" := CODEUNIT::"Import XML File to Data Exch.";
        DataExchDef.Insert(true);

        // TODO: test with namespace
        DataExchLineDef.Init();
        DataExchLineDef."Data Exch. Def Code" := DataExchDef.Code;
        DataExchLineDef.Code :=
          LibraryUtility.GenerateRandomCode(DataExchLineDef.FieldNo(Code), DATABASE::"Data Exch. Line Def");
        DataExchLineDef.Name :=
          LibraryUtility.GenerateRandomCode(DataExchLineDef.FieldNo(Name), DATABASE::"Data Exch. Line Def");
        DataExchLineDef.Insert();

        DataExchMapping.Init();
        DataExchMapping."Data Exch. Def Code" := DataExchDef.Code;
        DataExchMapping."Data Exch. Line Def Code" := DataExchLineDef.Code;
        DataExchMapping."Table ID" := DATABASE::"Currency Exchange Rate";
        DataExchMapping."Mapping Codeunit" := CODEUNIT::"Map Currency Exchange Rate";
        DataExchMapping.Insert(true);
    end;

    local procedure CreateChildLineDefinition(ParentDataExchLineDef: Record "Data Exch. Line Def"; var DataExchLineDef: Record "Data Exch. Line Def"; var DataExchMapping: Record "Data Exch. Mapping")
    begin
        DataExchLineDef.Init();
        DataExchLineDef."Data Exch. Def Code" := ParentDataExchLineDef."Data Exch. Def Code";
        DataExchLineDef.Code :=
          LibraryUtility.GenerateRandomCode(DataExchLineDef.FieldNo(Code), DATABASE::"Data Exch. Line Def");
        DataExchLineDef.Name :=
          LibraryUtility.GenerateRandomCode(DataExchLineDef.FieldNo(Name), DATABASE::"Data Exch. Line Def");
        DataExchLineDef."Parent Code" := ParentDataExchLineDef.Code;
        DataExchLineDef.Insert();

        DataExchMapping.Init();
        DataExchMapping."Data Exch. Def Code" := DataExchLineDef."Data Exch. Def Code";
        DataExchMapping."Data Exch. Line Def Code" := DataExchLineDef.Code;
        DataExchMapping."Table ID" := DATABASE::Dimension;
        DataExchMapping."Mapping Codeunit" := CODEUNIT::"Map Currency Exchange Rate";
        DataExchMapping.Insert(true);
    end;

    local procedure CreateFieldMappings(DataExchMapping: Record "Data Exch. Mapping")
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        CreateExchMappingLine(DataExchMapping, CurrencyCodeXMLElementTxt, CurrencyExchangeRate.FieldNo("Currency Code"));
        CreateExchMappingLine(DataExchMapping, StartingDateXMLElementTxt, CurrencyExchangeRate.FieldNo("Starting Date"));
        CreateExchMappingLine(DataExchMapping, ExchRateAmountXMLElementTxt, CurrencyExchangeRate.FieldNo("Exchange Rate Amount"));
        CreateExchMappingLine(
          DataExchMapping, RelationalExchRateAmountXMLElementTxt, CurrencyExchangeRate.FieldNo("Relational Exch. Rate Amount"));
    end;

    local procedure CreateExchMappingLine(DataExchMapping: Record "Data Exch. Mapping"; FromColumnName: Text[50]; ToFieldNo: Integer)
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        LastColumnNoUsed: Integer;
    begin
        DataExchColumnDef.SetRange("Data Exch. Def Code", DataExchMapping."Data Exch. Def Code");
        DataExchColumnDef.SetRange("Data Exch. Line Def Code", DataExchMapping."Data Exch. Line Def Code");
        if DataExchColumnDef.FindLast() then
            LastColumnNoUsed := DataExchColumnDef."Column No.";

        DataExchColumnDef."Data Exch. Def Code" := DataExchMapping."Data Exch. Def Code";
        DataExchColumnDef."Data Exch. Line Def Code" := DataExchMapping."Data Exch. Line Def Code";
        DataExchColumnDef."Column No." := LastColumnNoUsed + 10000;
        DataExchColumnDef.Name := FromColumnName;
        DataExchColumnDef.Path := FromColumnName;
        DataExchColumnDef.Insert(true);

        DataExchFieldMapping.Init();
        DataExchFieldMapping.Validate("Data Exch. Def Code", DataExchMapping."Data Exch. Def Code");
        DataExchFieldMapping.Validate("Data Exch. Line Def Code", DataExchMapping."Data Exch. Line Def Code");
        DataExchFieldMapping.Validate("Table ID", DataExchMapping."Table ID");
        DataExchFieldMapping.Validate("Column No.", DataExchColumnDef."Column No.");
        DataExchFieldMapping.Validate("Field ID", ToFieldNo);
        DataExchFieldMapping.Insert(true);
    end;

    local procedure CreateSetupRecordManually(var TempDataExchFieldMappingBuf: Record "Data Exch. Field Mapping Buf." temporary; DataExchMapping: Record "Data Exch. Mapping")
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        TempDataExchFieldMappingBuf.Init();
        TempDataExchFieldMappingBuf.Validate("Data Exchange Def Code", DataExchMapping."Data Exch. Def Code");
        TempDataExchFieldMappingBuf.Validate("Data Exchange Line Def Code", DataExchMapping."Data Exch. Line Def Code");
        TempDataExchFieldMappingBuf.Validate("Field ID", CurrencyExchangeRate.FieldNo("Currency Code"));
        TempDataExchFieldMappingBuf.Validate("Table ID", DataExchMapping."Table ID");
        TempDataExchFieldMappingBuf.Validate(Caption, CurrencyExchangeRate.FieldCaption("Currency Code"));
        TempDataExchFieldMappingBuf.Validate(Source, CurrencyCodeXMLElementTxt);
        TempDataExchFieldMappingBuf.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure GetSuggestedFields(var TempField: Record "Field" temporary)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        InsertMandatoryField(TempField, CurrencyExchangeRate.FieldNo("Currency Code"), DATABASE::"Currency Exchange Rate");
        InsertMandatoryField(TempField, CurrencyExchangeRate.FieldNo("Relational Exch. Rate Amount"), DATABASE::"Currency Exchange Rate");
        InsertMandatoryField(TempField, CurrencyExchangeRate.FieldNo("Starting Date"), DATABASE::"Currency Exchange Rate");
        InsertMandatoryField(TempField, CurrencyExchangeRate.FieldNo("Exchange Rate Amount"), DATABASE::"Currency Exchange Rate");
    end;

    [Scope('OnPrem')]
    procedure GetSuggestedFieldsChildTable(var TempField: Record "Field" temporary)
    var
        Dimension: Record Dimension;
    begin
        InsertMandatoryField(TempField, Dimension.FieldNo(Code), DATABASE::Dimension);
        InsertMandatoryField(TempField, Dimension.FieldNo(Name), DATABASE::Dimension);
        InsertMandatoryField(TempField, Dimension.FieldNo("Code Caption"), DATABASE::Dimension);
    end;

    local procedure InsertMandatoryField(var TempField: Record "Field" temporary; FieldID: Integer; TableID: Integer)
    var
        "Field": Record "Field";
    begin
        Field.Get(TableID, FieldID);
        TempField.Copy(Field);
        TempField.Insert();
    end;

    local procedure VerifyDataExchangeDefLineField(var TempDataExchFieldMappingBuf: Record "Data Exch. Field Mapping Buf." temporary; DataExchLineDef: Record "Data Exch. Line Def"; DataExchMapping: Record "Data Exch. Mapping"; Depth: Integer)
    var
        DataExchDef: Record "Data Exch. Def";
    begin
        DataExchDef.Get(DataExchLineDef."Data Exch. Def Code");
        Assert.AreEqual(TempDataExchFieldMappingBuf.Type::Table, TempDataExchFieldMappingBuf.Type, 'Wrong value for Type Field');
        Assert.AreEqual(
          TempDataExchFieldMappingBuf."Data Exchange Def Code", DataExchLineDef."Data Exch. Def Code",
          'Wrong value for Data Exchange Def Code Field');
        Assert.AreEqual(
          TempDataExchFieldMappingBuf."Data Exchange Line Def Code", DataExchLineDef.Code,
          'Wrong value for Data Exchange Line Def Code Field');
        Assert.AreEqual(TempDataExchFieldMappingBuf."Field ID", 0, 'Wrong value for Field ID Field');
        Assert.AreEqual(TempDataExchFieldMappingBuf."Table ID", DataExchMapping."Table ID", 'Wrong value for Table ID Field');
        Assert.AreEqual(TempDataExchFieldMappingBuf."Column No.", 0, 'Wrong value for Column No Field');
        Assert.AreEqual(TempDataExchFieldMappingBuf."Default Value", '', 'Wrong value for Default Value Field');
        Assert.AreEqual(TempDataExchFieldMappingBuf.Source, DataExchLineDef."Data Line Tag", 'Wrong value for Source Field');
        Assert.AreEqual(TempDataExchFieldMappingBuf.Caption, DataExchLineDef.Name, 'Wrong value for Caption Field');
        Assert.AreEqual(TempDataExchFieldMappingBuf.Depth, Depth, 'Wrong value for Depth Field');
    end;

    local procedure VerifySuggestedFields(var TempDataExchFieldMappingBuf: Record "Data Exch. Field Mapping Buf." temporary; DataExchLineDef: Record "Data Exch. Line Def"; var TempSuggestedField: Record "Field" temporary; Depth: Integer)
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        TempDataExchFieldMappingBuf.SetRange(Type, TempDataExchFieldMappingBuf.Type::Field);

        if TempDataExchFieldMappingBuf.IsEmpty() then
            exit;

        DataExchDef.Get(DataExchLineDef."Data Exch. Def Code");

        repeat
            TempDataExchFieldMappingBuf.SetRange("Field ID", TempSuggestedField."No.");
            Assert.AreEqual(1, TempDataExchFieldMappingBuf.Count, 'There should only be one suggestion field record present');
            TempDataExchFieldMappingBuf.FindFirst();
            Assert.AreEqual(TempDataExchFieldMappingBuf.Type::Field, TempDataExchFieldMappingBuf.Type, 'Wrong value for Type Field');
            Assert.AreEqual(
              TempDataExchFieldMappingBuf."Data Exchange Def Code", DataExchLineDef."Data Exch. Def Code",
              'Wrong value for Data Exchange Def Code Field');
            Assert.AreEqual(
              TempDataExchFieldMappingBuf."Data Exchange Line Def Code", DataExchLineDef.Code,
              'Wrong value for Data Exchange Line Def Code Field');
            Assert.AreEqual(TempDataExchFieldMappingBuf."Field ID", TempSuggestedField."No.", 'Wrong value for Field ID Field');
            Assert.AreEqual(TempDataExchFieldMappingBuf."Table ID", TempSuggestedField.TableNo, 'Wrong value for Table ID Field');
            Assert.IsTrue(TempDataExchFieldMappingBuf."Column No." > 0, 'Wrong value for Column No Field');
            Assert.IsTrue(
              DataExchColumnDef.Get(
                TempDataExchFieldMappingBuf."Data Exchange Def Code", TempDataExchFieldMappingBuf."Data Exchange Line Def Code",
                TempDataExchFieldMappingBuf."Column No."), 'Data Exch Column Def should have been created');
            Assert.AreEqual(TempDataExchFieldMappingBuf."Default Value", '', 'Wrong value for Default Value Field');
            Assert.AreEqual(TempDataExchFieldMappingBuf.Source, '', 'Wrong value for Source Field');
            Assert.AreEqual(TempDataExchFieldMappingBuf.Caption, TempSuggestedField."Field Caption", 'Wrong value for Caption Field');
            Assert.AreEqual(TempDataExchFieldMappingBuf.Depth, Depth, 'Wrong value for Depth Field');
        until TempSuggestedField.Next() = 0;
    end;

    local procedure VerifyMappedFields(var TempDataExchFieldMappingBuf: Record "Data Exch. Field Mapping Buf." temporary; DataExchMapping: Record "Data Exch. Mapping")
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        TempDataExchFieldMappingBuf.SetRange(Type, TempDataExchFieldMappingBuf.Type::Field);
        DataExchFieldMapping.SetRange("Data Exch. Def Code", DataExchMapping."Data Exch. Def Code");
        DataExchFieldMapping.SetRange("Data Exch. Line Def Code", DataExchMapping."Data Exch. Line Def Code");
        DataExchFieldMapping.SetRange("Table ID", DataExchMapping."Table ID");

        if TempDataExchFieldMappingBuf.IsEmpty() then
            exit;

        DataExchDef.Get(DataExchMapping."Data Exch. Def Code");

        DataExchFieldMapping.FindSet();
        repeat
            TempDataExchFieldMappingBuf.SetRange("Field ID", DataExchFieldMapping."Field ID");
            TempDataExchFieldMappingBuf.SetRange("Table ID", DataExchFieldMapping."Table ID");
            Assert.AreEqual(1, TempDataExchFieldMappingBuf.Count, 'There should only be one suggestion field record present');
            TempDataExchFieldMappingBuf.FindFirst();
            Assert.AreEqual(TempDataExchFieldMappingBuf.Type::Field, TempDataExchFieldMappingBuf.Type, 'Wrong value for Type Field');
            Assert.AreEqual(
              TempDataExchFieldMappingBuf."Data Exchange Def Code", DataExchFieldMapping."Data Exch. Def Code",
              'Wrong value for Data Exchange Def Code Field');
            Assert.AreEqual(
              TempDataExchFieldMappingBuf."Data Exchange Line Def Code", DataExchFieldMapping."Data Exch. Line Def Code",
              'Wrong value for Data Exchange Line Def Code Field');
            Assert.AreEqual(TempDataExchFieldMappingBuf."Table ID", DataExchFieldMapping."Table ID", 'Wrong value for Table ID Field');
            Assert.IsTrue(TempDataExchFieldMappingBuf."Column No." > 0, 'Wrong value for Column No Field');
            Assert.IsTrue(
              DataExchColumnDef.Get(
                TempDataExchFieldMappingBuf."Data Exchange Def Code", TempDataExchFieldMappingBuf."Data Exchange Line Def Code",
                TempDataExchFieldMappingBuf."Column No."), 'Data Exch Column Def should have been created');
            Assert.AreEqual(TempDataExchFieldMappingBuf."Default Value", '', 'Wrong value for Default Value Field');
            Assert.AreEqual(TempDataExchFieldMappingBuf.Source, DataExchColumnDef.Path, 'Wrong value for Source Field');
            Assert.AreEqual(TempDataExchFieldMappingBuf.Caption, DataExchFieldMapping.GetFieldCaption(), 'Wrong value for Caption Field');
        until DataExchFieldMapping.Next() = 0;
    end;
}

