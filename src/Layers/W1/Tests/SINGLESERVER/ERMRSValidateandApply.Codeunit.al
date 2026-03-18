codeunit 136608 "ERM RS Validate and Apply"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Config Package] [Rapid Start]
    end;

    var
        LibraryRapidStart: Codeunit "Library - Rapid Start";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERM: Codeunit "Library - ERM";
        LibraryJournals: Codeunit "Library - Journals";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        APIMockEvents: Codeunit "API Mock Events";
        isInitialized: Boolean;
        MigrationError: Label 'There are errors in Migration Data Error.';
        NoMigrationError: Label 'There must be errors in Migration Data Error.';
        NoDataInTableAferApply: Label 'There is no data in table after apply procedure.';
        MoreThanOneRecordInserted: Label 'More than one record inserted after apply.';
        NonPKDataWasNotInserted: Label 'Non PK Data was not inserted.';
        SeriesNoNotAssigned: Label 'Series No not assigned to PK field.';
        DataWasNotOverwritten: Label 'Data was not overwritten after apply on existing data.';
        TableFilterApplyErr: Label 'Application must not change error state outside selection. ';
        TableMustNotBeAppliedErr: Label 'Table %1 must not be applied.';
        TableMustBeAppliedErr: Label 'Table %1 must be applied.';
        RecordInsertErr: Label 'Record must not be inserted if it have error in primary key, error must be in migration data error. ';
        BadModelTableErr: Label 'Table must allow to insert records without errors.';
        TestCustomerNameTxt: Label 'Mister James';
        TransformedTestCustomerNameTxt: Label 'Mr. James';
        TestBankAccountIBANCodeTxt: Label '00321 33213 32131';
        TransformedTestBankAccountIBANCodeTxt: Label '003213321332131';

    [Test]
    [Scope('OnPrem')]
    procedure PackageDataValidation_ValidateRecordWithWrongRelation_PackageErrorGenerated()
    var
        ConfigPackageError: Record "Config. Package Error";
        ConfigPackage: Record "Config. Package";
    begin
        Initialize();

        CreateRelatedPackageData(
          ConfigPackage,
          false,// CreatePrimaryPackageData
          true,// CreateRelatedPackageData
          true,// Delete primary record
          true,// Delete related record
          0,// Primary priority
          0); // Related table priority

        ValidatePackageAndSkipProcessingOrder(ConfigPackage);

        Assert.IsTrue(not ConfigPackageError.IsEmpty, NoMigrationError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PackageDataValidation_ValidateRecordWithCorrectRelation_NoPackageError()
    var
        ConfigPackageError: Record "Config. Package Error";
        ConfigPackage: Record "Config. Package";
    begin
        Initialize();

        CreateRelatedPackageData(
          ConfigPackage,
          false,// CreatePrimaryPackageData
          true,// CreateRelatedPackageData
          false,// Delete primary record
          true,// Delete related record
          0,// Primary priority
          0); // Related table priority

        ValidatePackageAndSkipProcessingOrder(ConfigPackage);

        Assert.IsTrue(ConfigPackageError.IsEmpty, MigrationError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PackageDataApplying_ApplyRecordWithWrongRelation_PackageErrorGenerated()
    var
        ConfigPackageError: Record "Config. Package Error";
        ConfigPackage: Record "Config. Package";
    begin
        Initialize();

        CreateRelatedPackageData(
          ConfigPackage,
          false,// CreatePrimaryPackageData
          true,// CreateRelatedPackageData
          true,// Delete primary record
          true,// Delete related record
          0,// Primary priority
          0); // Related table priority

        ApplyPackageAndSkipProcessingOrder(ConfigPackage);

        Assert.IsTrue(not ConfigPackageError.IsEmpty, NoMigrationError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PackageDataApplying_ApplyRecordWithCorrectRelation_DataInTable()
    var
        ConfigPackage: Record "Config. Package";
        PrimaryConfigPackageTable: Record "Config. Package Table";
        RelatedConfigPackageTable: Record "Config. Package Table";
        GenJournalBatch: Record "Gen. Journal Batch";
        KeyValueWithRelation: Code[10];
        KeyValueWithoutRelation: Code[10];
    begin
        Initialize();

        CreatePackageDataPairWithPKRelation(
          ConfigPackage,
          PrimaryConfigPackageTable,
          RelatedConfigPackageTable,
          false,// CreatePrimaryPackageData
          true,// CreateRelatedPackageData
          false,// Delete primary record
          true,// Delete related record
          0,// Primary priority
          0); // Related table priority

        GetKeyValuesWithRelation(RelatedConfigPackageTable, KeyValueWithRelation, KeyValueWithoutRelation);

        ApplyPackageAndSkipProcessingOrder(ConfigPackage);

        Assert.IsTrue(GenJournalBatch.Get(KeyValueWithRelation, KeyValueWithoutRelation), NoDataInTableAferApply);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PackageDataApplying_RecordWithWrongRelationInPK_RecordNotInserted()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageError: Record "Config. Package Error";
        NoSeriesLine: Record "No. Series Line";
        KeyValueWithRelation: Code[10];
    begin
        // To check that record not inserted if it has error in PK
        Initialize();

        // Prerequisite: Test requires that table do not generates error on insert
        KeyValueWithRelation := CreateAndApplyPackageDataForTableWithoutPKCheckOnInsert(ConfigPackage, false);
        Assert.IsTrue(ConfigPackageError.IsEmpty() and NoSeriesLine.Get(KeyValueWithRelation, 0), BadModelTableErr);
        LibraryRapidStart.CleanUp(ConfigPackage.Code);
        Clear(ConfigPackage);

        // Verification
        KeyValueWithRelation := CreateAndApplyPackageDataForTableWithoutPKCheckOnInsert(ConfigPackage, true);
        Assert.IsFalse(ConfigPackageError.IsEmpty() or NoSeriesLine.Get(KeyValueWithRelation, 0), RecordInsertErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PackageDataValidation_ValidateMultipleRecordsWithWrongRecordProcessingOrder_PackageErrorGenerated()
    var
        ConfigPackageError: Record "Config. Package Error";
        ConfigPackage: Record "Config. Package";
    begin
        Initialize();

        CreateRelatedPackageData(
          ConfigPackage,
          true,// CreatePrimaryPackageData
          true,// CreateRelatedPackageData
          true,// Delete primary record
          true,// Delete related record
          1,// Primary priority
          0); // Related table priority

        ValidatePackageAndSetupProcessingOrder(ConfigPackage);

        Assert.IsTrue(ConfigPackageError.IsEmpty, MigrationError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PackageDataValidation_ValidateMultipleRecordsWithWrongRecordProcessingOrderWithSetProcessingOrder_NoPackageError()
    var
        ConfigPackageError: Record "Config. Package Error";
        ConfigPackage: Record "Config. Package";
    begin
        Initialize();

        CreateRelatedPackageData(
          ConfigPackage,
          true,// CreatePrimaryPackageData
          true,// CreateRelatedPackageData
          true,// Delete primary record
          true,// Delete related record
          1,// Primary priority
          0); // Related table priority

        ValidatePackageAndSkipProcessingOrder(ConfigPackage);

        Assert.IsTrue(not ConfigPackageError.IsEmpty, NoMigrationError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PackageDataValidation_ValidateMultipleRecordsWithCorrectRecordProcessingOrder_NoPackageError()
    var
        ConfigPackageError: Record "Config. Package Error";
        ConfigPackage: Record "Config. Package";
    begin
        Initialize();

        CreateRelatedPackageData(
          ConfigPackage,
          true,// CreatePrimaryPackageData
          true,// CreateRelatedPackageData
          true,// Delete primary record
          true,// Delete related record
          0,// Primary priority
          1); // Related table priority

        ValidatePackageAndSkipProcessingOrder(ConfigPackage);

        Assert.IsTrue(ConfigPackageError.IsEmpty, MigrationError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PackageDataApplying_ApplyMultipleRecordsWithWrongRecordProcessingOrder_PackageErrorGenerated()
    var
        ConfigPackageError: Record "Config. Package Error";
        ConfigPackage: Record "Config. Package";
    begin
        Initialize();

        CreateRelatedPackageData(
          ConfigPackage,
          true,// CreatePrimaryPackageData
          true,// CreateRelatedPackageData
          true,// Delete primary record
          true,// Delete related record
          1,// Primary priority
          0); // Related table priority

        ApplyPackageAndSkipProcessingOrder(ConfigPackage);

        Assert.IsTrue(not ConfigPackageError.IsEmpty, NoMigrationError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PackageDataApplying_ApplyMultipleRecordsWithWrongRecordProcessingOrderWithSetProcessingOrder_DataInTables()
    var
        ConfigPackage: Record "Config. Package";
        PrimaryConfigPackageTable: Record "Config. Package Table";
        RelatedConfigPackageTable: Record "Config. Package Table";
        GenJournalBatch: Record "Gen. Journal Batch";
        KeyValueWithRelation: Code[10];
        KeyValueWithoutRelation: Code[10];
    begin
        Initialize();

        CreatePackageDataPairWithPKRelation(
          ConfigPackage,
          PrimaryConfigPackageTable,
          RelatedConfigPackageTable,
          true,// CreatePrimaryPackageData
          true,// CreateRelatedPackageData
          true,// Delete primary record
          true,// Delete related record
          1,// Primary priority
          0); // Related table priority

        GetKeyValuesWithRelation(RelatedConfigPackageTable, KeyValueWithRelation, KeyValueWithoutRelation);

        ApplyPackageAndSetupProcessingOrder(ConfigPackage);

        Assert.IsTrue(GenJournalBatch.Get(KeyValueWithRelation, KeyValueWithoutRelation), NoDataInTableAferApply);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PackageDataApplying_ApplyMultipleRecordsWithCorrectRecordProcessingOrder_DataInTable()
    var
        ConfigPackage: Record "Config. Package";
        PrimaryConfigPackageTable: Record "Config. Package Table";
        RelatedConfigPackageTable: Record "Config. Package Table";
        GenJournalBatch: Record "Gen. Journal Batch";
        KeyValueWithRelation: Code[10];
        KeyValueWithoutRelation: Code[10];
    begin
        Initialize();

        CreatePackageDataPairWithPKRelation(
          ConfigPackage,
          PrimaryConfigPackageTable,
          RelatedConfigPackageTable,
          true,// CreatePrimaryPackageData
          true,// CreateRelatedPackageData
          true,// Delete primary record
          true,// Delete related record
          0,// Primary priority
          1); // Related table priority

        GetKeyValuesWithRelation(RelatedConfigPackageTable, KeyValueWithRelation, KeyValueWithoutRelation);

        ApplyPackageAndSkipProcessingOrder(ConfigPackage);

        Assert.IsTrue(GenJournalBatch.Get(KeyValueWithRelation, KeyValueWithoutRelation), NoDataInTableAferApply);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PackageDataValidation_ValidateRecordsWithoutRelations_NoPackageError()
    var
        ConfigPackageError: Record "Config. Package Error";
        ConfigPackage: Record "Config. Package";
        GenJournalTemplateName: Code[10];
        ItemJournalTemplateName: Code[10];
    begin
        Initialize();

        CreatePackageDataPairWithoutRelation(ConfigPackage, GenJournalTemplateName, ItemJournalTemplateName);

        ValidatePackageAndSkipProcessingOrder(ConfigPackage);

        Assert.IsTrue(ConfigPackageError.IsEmpty, MigrationError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PackageDataValidation_ValidateRecordsWithRelationsInNonPKFieldsAndWrongProcessingOrder_NoPackageError()
    var
        ConfigPackageError: Record "Config. Package Error";
        ConfigPackage: Record "Config. Package";
        GenJournalTemplateName: Code[10];
        ReasonCodeCode: Code[10];
    begin
        Initialize();

        CreatePackageDataPairWithNonPKRelation(ConfigPackage, 1, 0, GenJournalTemplateName, ReasonCodeCode);

        ValidatePackageAndSkipProcessingOrder(ConfigPackage);

        Assert.IsTrue(ConfigPackageError.IsEmpty, MigrationError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PackageDataValidation_ValidateRecordsWithRelationsInNonPKFieldsAndCorrectProcessingOrder_NoPackageError()
    var
        ConfigPackageError: Record "Config. Package Error";
        ConfigPackage: Record "Config. Package";
        GenJournalTemplateName: Code[10];
        ReasonCodeCode: Code[10];
    begin
        Initialize();

        CreatePackageDataPairWithNonPKRelation(ConfigPackage, 0, 1, GenJournalTemplateName, ReasonCodeCode);

        ValidatePackageAndSkipProcessingOrder(ConfigPackage);

        Assert.IsTrue(ConfigPackageError.IsEmpty, MigrationError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PackageDataApplying_ApplyRecordsWithoutRelations_DataInTables()
    var
        ConfigPackage: Record "Config. Package";
        ItemJournalTemplate: Record "Item Journal Template";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalTemplateName: Code[10];
        ItemJournalTemplateName: Code[10];
    begin
        Initialize();

        CreatePackageDataPairWithoutRelation(ConfigPackage, GenJournalTemplateName, ItemJournalTemplateName);

        ApplyPackageAndSkipProcessingOrder(ConfigPackage);

        Assert.IsTrue(
          ItemJournalTemplate.Get(ItemJournalTemplateName) and GenJournalTemplate.Get(GenJournalTemplateName), NoDataInTableAferApply);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PackageDataApplying_ApplyRecordsWithRelationsInNonPKFieldsAndWrongProcessingOrder_DataInTables()
    var
        ConfigPackage: Record "Config. Package";
        ReasonCode: Record "Reason Code";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalTemplateName: Code[10];
        ReasonCodeCode: Code[10];
    begin
        Initialize();

        CreatePackageDataPairWithNonPKRelation(ConfigPackage, 1, 0, GenJournalTemplateName, ReasonCodeCode);

        ApplyPackageAndSkipProcessingOrder(ConfigPackage);

        Assert.IsTrue(
          GenJournalTemplate.Get(GenJournalTemplateName) and ReasonCode.Get(ReasonCodeCode), NoDataInTableAferApply);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PackageDataApplying_ApplyRecordsWithRelationsInNonPKFieldsAndCorrectProcessingOrder_DataInTables()
    var
        ConfigPackage: Record "Config. Package";
        ReasonCode: Record "Reason Code";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalTemplateName: Code[10];
        ReasonCodeCode: Code[10];
    begin
        Initialize();

        CreatePackageDataPairWithNonPKRelation(ConfigPackage, 0, 1, GenJournalTemplateName, ReasonCodeCode);

        ApplyPackageAndSkipProcessingOrder(ConfigPackage);

        Assert.IsTrue(
          GenJournalTemplate.Get(GenJournalTemplateName) and ReasonCode.Get(ReasonCodeCode), NoDataInTableAferApply);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyTableWithSeriesNo_ApplyRecordWithFilledPK_OneRecordInserted()
    begin
        GeneralTestcaseForApplyingRecordWithSeries(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyTableWithSeriesNo_ApplyRecordWithBlankPK_OneRecordInserted()
    begin
        GeneralTestcaseForApplyingRecordWithSeries(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyTableWithSeriesNo_ApplyRecordWithBlankPK_NonPKDataInsertedAswell()
    var
        ConfigPackage: Record "Config. Package";
        Customer: Record Customer;
        CustomerName: Text[50];
    begin
        Initialize();

        GeneratePackageForTableWithSeriesNo(ConfigPackage, CustomerName, true);

        ApplyPackageAndSetupProcessingOrder(ConfigPackage);

        Customer.SetRange(Name, CustomerName); // Customer name is equal to PK, so no falsepositive here
        Assert.IsTrue(Customer.FindFirst(), NonPKDataWasNotInserted);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyTableWithSeriesNo_ApplyRecordWithBlankPK_SeriesNoAssignedForPK()
    var
        ConfigPackage: Record "Config. Package";
        Customer: Record Customer;
        SalesSetup: Record "Sales & Receivables Setup";
        NoSeriesLine: Record "No. Series Line";
        NoSeries: Codeunit "No. Series";
        CustomerName: Text[50];
    begin
        Initialize();

        GeneratePackageForTableWithSeriesNo(ConfigPackage, CustomerName, true);

        ApplyPackageAndSetupProcessingOrder(ConfigPackage);

        Customer.SetRange(Name, CustomerName);
        Customer.FindFirst();

        SalesSetup.Get();

        NoSeries.GetNoSeriesLine(NoSeriesLine, SalesSetup."Customer Nos.", 0D, true);

        Assert.IsTrue(Customer."No." = NoSeriesLine."Last No. Used", SeriesNoNotAssigned);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PackageDataApplying_ApplyOverExistingData_DataOverwritten()
    var
        ConfigPackage: Record "Config. Package";
        PrimaryConfigPackageTable: Record "Config. Package Table";
        RelatedConfigPackageTable: Record "Config. Package Table";
        GenJournalBatch: Record "Gen. Journal Batch";
        KeyValueWithRelation: Code[10];
        KeyValueWithoutRelation: Code[10];
        TableDescription: Text[20];
    begin
        Initialize();

        CreatePackageDataPairWithPKRelation(
          ConfigPackage,
          PrimaryConfigPackageTable,
          RelatedConfigPackageTable,
          false,// CreatePrimaryPackageData
          true,// CreateRelatedPackageData
          false,// Delete primary record
          false,// Delete related record
          0,// Primary priority
          0); // Related table priority

        GetKeyValuesWithRelation(RelatedConfigPackageTable, KeyValueWithRelation, KeyValueWithoutRelation);
        GenJournalBatch.Get(KeyValueWithRelation, KeyValueWithoutRelation);
        GenJournalBatch.Description :=
          LibraryUtility.GenerateRandomCode(GenJournalBatch.FieldNo(Description), DATABASE::"Gen. Journal Batch");
        GenJournalBatch.Modify();

        TableDescription := LibraryUtility.GenerateRandomCode(GenJournalBatch.FieldNo(Description), DATABASE::"Gen. Journal Batch");
        LibraryRapidStart.CreatePackageDataForField(
          ConfigPackage,
          RelatedConfigPackageTable,
          DATABASE::"Gen. Journal Batch",
          GenJournalBatch.FieldNo(Description),
          TableDescription,
          1);

        ApplyPackageAndSetupProcessingOrder(ConfigPackage);

        GenJournalBatch.Get(KeyValueWithRelation, KeyValueWithoutRelation);
        Assert.AreEqual(TableDescription, GenJournalBatch.Description, DataWasNotOverwritten);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PackageDataApplying_ApplyPackageWithConfigQuestions()
    var
        Customer: Record Customer;
        ConfigQuestion: Record "Config. Question";
        ConfigPackage: Record "Config. Package";
    begin
        // Test to verify that answers are applied correctly to option fields

        Initialize();

        // Create a new package with a question on Customer.Blocked field. The answer value is Blocked::Invoice
        CreatePackageWithQuestion(ConfigPackage, ConfigQuestion, Format(Customer.Blocked::Invoice));
        // Answer value in the questionnaire is Blocked::All
        SetAnswerValue(
          ConfigQuestion."Questionnaire Code", ConfigQuestion."Question Area Code", DATABASE::Customer, Customer.FieldNo(Blocked),
          Format(Customer.Blocked::All));

        LibraryRapidStart.ApplyPackage(ConfigPackage, true);

        ConfigQuestion.Get(
          ConfigQuestion."Questionnaire Code",
          ConfigQuestion."Question Area Code",
          GetConfigQuestionNo(
            ConfigQuestion."Questionnaire Code", ConfigQuestion."Question Area Code", DATABASE::Customer, Customer.FieldNo(Blocked)));

        // Make sure that the answer in the questionnaire is replaced with the value from the package
        Assert.AreEqual(Format(Customer.Blocked::Invoice), ConfigQuestion.Answer, NoDataInTableAferApply);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PackageDataApplying_ApplyPackageWithCodeFieldMapping()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        CurrencyTotalBuffer: Record "Currency Total Buffer";
        Currency: Record Currency;
        MasterCode: Code[10];
        MasterTableID: Integer;
        RelatedTableID: Integer;
    begin
        // Mapping for table 332 Currency Total Buffer field 1 Currency Code (type Code)
        Initialize();

        LibraryERM.CreateCurrency(Currency);

        // create new package with table 332
        LibraryRapidStart.CreatePackage(ConfigPackage);
        MasterTableID := DATABASE::Currency;
        RelatedTableID := DATABASE::"Currency Total Buffer";
        MasterCode := LibraryUtility.GenerateRandomCode(1, MasterTableID);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, RelatedTableID);
        LibraryRapidStart.CreatePackageData(ConfigPackage.Code, RelatedTableID, 1, 1, MasterCode);
        CreateFieldMapping(ConfigPackage.Code, RelatedTableID, 1, MasterCode, Currency.Code);

        // apply package with mapping
        LibraryRapidStart.ApplyPackage(ConfigPackage, false);

        // validate
        Assert.IsTrue(CurrencyTotalBuffer.Get(Currency.Code), 'Missing currency code');

        // clean up
        CurrencyTotalBuffer.Delete();
        Currency.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PackageDataApplying_ApplyPackageWithRelatedCodeFieldMapping()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        CurrencyTotalBuffer: Record "Currency Total Buffer";
        Currency: Record Currency;
        MasterCode: Code[10];
        MasterTableID: Integer;
        RelatedTableID: Integer;
    begin
        // Mapping for the Currency Code in table 332 Currency Total Buffer
        // is defined in the Currency table
        Initialize();

        LibraryERM.CreateCurrency(Currency);

        // create new package with table 332
        LibraryRapidStart.CreatePackage(ConfigPackage);
        MasterTableID := DATABASE::"Currency Total Buffer";
        RelatedTableID := DATABASE::Currency;
        MasterCode := LibraryUtility.GenerateRandomCode(1, MasterTableID);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, RelatedTableID);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, MasterTableID);
        LibraryRapidStart.CreatePackageData(ConfigPackage.Code, MasterTableID, 1, 1, MasterCode);
        CreateFieldMapping(ConfigPackage.Code, RelatedTableID, 1, MasterCode, Currency.Code);

        // apply package with mapping
        LibraryRapidStart.ApplyPackage(ConfigPackage, false);

        // validate
        Assert.IsTrue(CurrencyTotalBuffer.Get(Currency.Code), 'Missing currency code');

        // clean up
        CurrencyTotalBuffer.Delete();
        Currency.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PackageDataApplying_ApplyPackageWithCodeAndRelatedCodeFieldMapping()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        CurrencyTotalBuffer: Record "Currency Total Buffer";
        Currency: Record Currency;
        Currency2: Record Currency;
        MasterCode: Code[10];
        RelatedCode: Code[10];
        MasterTableID: Integer;
        RelatedTableID: Integer;
    begin
        // For table 332 Currency Total Buffer:
        // Mapping for the Currency Code '1' is defined in the Currency table
        // Mapping for the Currency Code '2' is defined for the Currency Code field
        Initialize();

        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateCurrency(Currency2);

        // create new package with table 332
        LibraryRapidStart.CreatePackage(ConfigPackage);
        MasterTableID := DATABASE::"Currency Total Buffer";
        RelatedTableID := DATABASE::Currency;
        MasterCode := LibraryUtility.GenerateRandomCode(1, MasterTableID);
        RelatedCode := LibraryUtility.GenerateRandomCode(1, RelatedTableID);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, MasterTableID);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, RelatedTableID);
        LibraryRapidStart.CreatePackageData(ConfigPackage.Code, MasterTableID, 1, 1, MasterCode);
        LibraryRapidStart.CreatePackageData(ConfigPackage.Code, MasterTableID, 2, 1, RelatedCode);
        CreateFieldMapping(ConfigPackage.Code, RelatedTableID, 1, MasterCode, Currency.Code);
        CreateFieldMapping(ConfigPackage.Code, MasterTableID, 1, RelatedCode, Currency2.Code);

        // apply package with mapping
        LibraryRapidStart.ApplyPackage(ConfigPackage, false);

        // validate
        Assert.IsTrue(CurrencyTotalBuffer.Get(Currency.Code), 'Missing currency code');
        CurrencyTotalBuffer.Delete();
        Currency.Delete();
        Assert.IsTrue(CurrencyTotalBuffer.Get(Currency2.Code), 'Missing currency code');
        CurrencyTotalBuffer.Delete();
        Currency2.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PackageDataApplying_ApplyPackageWithOptionFieldMapping()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        BOMBuffer: Record "BOM Buffer";
        OptionText: Text[250];
        TableID: Integer;
    begin
        Initialize();

        // create new package with table 5870
        LibraryRapidStart.CreatePackage(ConfigPackage);
        TableID := DATABASE::"BOM Buffer";
        OptionText := 'ItemOption';
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, TableID);
        LibraryRapidStart.CreatePackageData(ConfigPackage.Code, TableID, 1, 1, '1');
        LibraryRapidStart.CreatePackageData(ConfigPackage.Code, TableID, 1, 2, OptionText);
        CreateFieldMapping(ConfigPackage.Code, TableID, 2, OptionText, 'Item');

        // apply package with mapping
        LibraryRapidStart.ApplyPackage(ConfigPackage, false);

        // validate
        BOMBuffer.Get(1);
        Assert.AreEqual('Item', Format(BOMBuffer.Type), 'Missing option value Item.');

        BOMBuffer.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PackageDataApplying_ApplyPackageWithCreateMissingCodes()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageField: Record "Config. Package Field";
        Currency: Record Currency;
        MasterCode: Code[10];
        MasterTableID: Integer;
        RelatedTableID: Integer;
    begin
        Initialize();

        // create new package with table 332
        LibraryRapidStart.CreatePackage(ConfigPackage);
        MasterTableID := DATABASE::Currency;
        RelatedTableID := DATABASE::"Currency Total Buffer";
        MasterCode := LibraryUtility.GenerateRandomCode(1, MasterTableID);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, RelatedTableID);
        LibraryRapidStart.CreatePackageData(ConfigPackage.Code, RelatedTableID, 1, 1, MasterCode);
        ConfigPackageField.Get(ConfigPackageTable."Package Code", RelatedTableID, 1);
        ConfigPackageField."Create Missing Codes" := true;
        ConfigPackageField.Modify();

        // apply package with mapping
        LibraryRapidStart.ApplyPackage(ConfigPackage, false);

        // validate
        Assert.IsTrue(Currency.Get(MasterCode), 'value not found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PackageDataProcessing_RunTransformOnSingleDataRecord()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageData: Record "Config. Package Data";
        Customer: Record Customer;
        ERMRSValidateAndApply: Codeunit "ERM RS Validate and Apply";
        TextValue: Text;
        ExpectedTextValue: Text;
        TableID: Integer;
    begin
        // [FEATURE] [Config. Package - Process]
        Initialize();

        // [GIVEN] create new package with table Customer, where Name is 'Mister James'
        LibraryRapidStart.CreatePackage(ConfigPackage);
        TableID := DATABASE::Customer;
        TextValue := TestCustomerNameTxt;
        Clear(Customer);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, TableID);
        LibraryRapidStart.CreatePackageData(ConfigPackage.Code, TableID, 1, Customer.FieldNo(Name), CopyStr(TextValue, 1, 250));
        // [GIVEN] Subscribe to "Config. Package - Process" with rule for table Customer
        BindSubscription(ERMRSValidateAndApply);

        // [WHEN] Run report "Config. Package - Process"
        REPORT.RunModal(REPORT::"Config. Package - Process", false, false, ConfigPackageTable);

        // [THEN] Customer's Name is 'Mr. James'
        ConfigPackageData.SetRange("Package Code", ConfigPackage.Code);
        ConfigPackageData.SetRange("Table ID", TableID);
        ConfigPackageData.SetRange("Field ID", Customer.FieldNo(Name));
        ConfigPackageData.FindFirst();

        ExpectedTextValue := TransformedTestCustomerNameTxt;
        Assert.AreEqual(ExpectedTextValue, ConfigPackageData.Value, 'incorrect value');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PackageDataProcessing_RunTransformOnMultipleDataRecord()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageData: Record "Config. Package Data";
        BankAccount: Record "Bank Account";
        ERMRSValidateAndApply: Codeunit "ERM RS Validate and Apply";
        TextValue: Text;
        TableID: Integer;
    begin
        // [FEATURE] [Config. Package - Process]
        Initialize();

        // [GIVEN] create new package with table Bank Account
        LibraryRapidStart.CreatePackage(ConfigPackage);
        TableID := DATABASE::"Bank Account";
        Clear(BankAccount);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, TableID);

        // [GIVEN] Two bank records, where IBAN and "SWIFT Code" is '00321 33213 32131'
        TextValue := TestBankAccountIBANCodeTxt;
        LibraryRapidStart.CreatePackageData(ConfigPackage.Code, TableID, 1, BankAccount.FieldNo(IBAN), CopyStr(TextValue, 1, 250));
        LibraryRapidStart.CreatePackageData(ConfigPackage.Code, TableID, 1, BankAccount.FieldNo("SWIFT Code"), CopyStr(TextValue, 1, 250));

        TextValue := TestBankAccountIBANCodeTxt;
        LibraryRapidStart.CreatePackageData(ConfigPackage.Code, TableID, 2, BankAccount.FieldNo(IBAN), CopyStr(TextValue, 1, 250));
        LibraryRapidStart.CreatePackageData(ConfigPackage.Code, TableID, 2, BankAccount.FieldNo("SWIFT Code"), CopyStr(TextValue, 1, 250));
        // [GIVEN] Subscribe to "Config. Package - Process" with rule for "Bank Account" fields IBAN and "SWIFT Code"
        BindSubscription(ERMRSValidateAndApply);

        // [WHEN] Run report "Config. Package - Process"
        REPORT.RunModal(REPORT::"Config. Package - Process", false, false, ConfigPackageTable);

        // [THEN] Two bank records, where IBAN and "SWIFT Code" is '003213321332131'
        ConfigPackageData.SetRange("Package Code", ConfigPackage.Code);
        ConfigPackageData.SetRange("Table ID", TableID);
        ConfigPackageData.SetFilter("Field ID", '%1|%2', BankAccount.FieldNo(IBAN), BankAccount.FieldNo("SWIFT Code"));
        ConfigPackageData.FindSet();
        repeat
            Assert.AreEqual(
              TransformedTestBankAccountIBANCodeTxt, ConfigPackageData.Value,
              StrSubstNo('Wrong value in field no. %1 in record %2', ConfigPackageData."Field ID", ConfigPackageData."No."));
        until ConfigPackageData.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('ConfigPackageErrorRecordHandler')]
    [Scope('OnPrem')]
    procedure PackageErrors_RecordIDDrilldownOpensFailedRecordField()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageError: Record "Config. Package Error";
        ConfigPackageRecord: Record "Config. Package Record";
        ConfigPackageTable: Record "Config. Package Table";
        SalesHeader: Record "Sales Header";
        ConfigPackageErrors: TestPage "Config. Package Errors";
    begin
        // [FEATURE] [Error] [UI]
        // [SCENARIO] Drilldown on "Record ID" opens the record page with columns for: fields of PK and the failing field.
        Initialize();
        LibraryVariableStorage.Clear();
        LibraryApplicationArea.EnableFoundationSetup();
        // [GIVEN] Package 'A', where is 1 error for table 'Sales Header'.
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Sales Header");
        LibraryRapidStart.CreatePackageRecord(ConfigPackageRecord, ConfigPackage.Code, DATABASE::"Sales Header", 1);
        ConfigPackageRecord.Invalid := true;
        ConfigPackageRecord.Modify();
        ConfigPackageError."Field ID" := SalesHeader.FieldNo("Bill-to Customer No.");
        CreatePackageErrors(ConfigPackageError, ConfigPackageTable, 1);
        // [GIVEN] Record Data, where "Document Type" is 'Credit Memo', "No." is 'X', "Bill-to Customer No." is 'Z'
        SalesHeader."Document Type" := SalesHeader."Document Type"::"Credit Memo";
        LibraryRapidStart.CreatePackageFieldData(
          ConfigPackageRecord, SalesHeader.FieldNo("Document Type"), Format(SalesHeader."Document Type"));
        SalesHeader."No." := LibraryUtility.GenerateGUID();
        LibraryRapidStart.CreatePackageFieldData(ConfigPackageRecord, SalesHeader.FieldNo("No."), SalesHeader."No.");
        SalesHeader."Bill-to Customer No." := LibraryUtility.GenerateGUID();
        LibraryRapidStart.CreatePackageFieldData(
          ConfigPackageRecord, SalesHeader.FieldNo("Bill-to Customer No."), SalesHeader."Bill-to Customer No.");
        // [GIVEN] Open "Package Errors" page
        ConfigPackageErrors.OpenView();

        // [WHEN] Drill down on "Record ID"
        ConfigPackageErrors.RecordIDValue.DrillDown(); // handled by ConfigPackageErrorRecordHandler

        // [THEN] Page 'Record' opened, where is 1 record with 3 editable columns:
        Assert.AreEqual('', LibraryVariableStorage.DequeueText(), 'Field4 caption');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'Field4 visible');
        // [THEN] Columnn #1: "Document Type" is 'Credit Memo' (part of the primary key)
        Assert.AreEqual(SalesHeader.FieldCaption("Document Type"), LibraryVariableStorage.DequeueText(), 'Field1 caption');
        Assert.AreEqual(Format(SalesHeader."Document Type"), LibraryVariableStorage.DequeueText(), 'Field1 value');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Field1 editable');
        // [THEN] Columnn #2: "No." is 'X' (part of the primary key)
        Assert.AreEqual(SalesHeader.FieldCaption("No."), LibraryVariableStorage.DequeueText(), 'Field2 caption');
        Assert.AreEqual(SalesHeader."No.", LibraryVariableStorage.DequeueText(), 'Field2 value');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Field2 editable');
        // [THEN] Columnn #3: "Bill-to Customer No." is 'Z' (the failing field)
        Assert.AreEqual(SalesHeader.FieldCaption("Bill-to Customer No."), LibraryVariableStorage.DequeueText(), 'Field3 caption');
        Assert.AreEqual(SalesHeader."Bill-to Customer No.", LibraryVariableStorage.DequeueText(), 'Field3 value');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Field3 editable');

        ConfigPackageErrors.Close();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PackageCard_NoOfErrorsInvisibleIfNoErrors()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageError: Record "Config. Package Error";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageCard: TestPage "Config. Package Card";
    begin
        // [FEATURE] [Error] [UI]
        // [SCENARIO] "No. of Errors" and action "Show Error" are invisible if there are no errors for the package.
        Initialize();

        // [GIVEN] Package 'A'
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::Currency);
        // [GIVEN] There are no errors for Package 'A'
        CreatePackageErrors(ConfigPackageError, ConfigPackageTable, 0);

        // [WHEN] Open Package card page
        ConfigPackageCard.OpenView();
        // [THEN] Action "Show Error" and "No. of Errors" are invisible
        Assert.IsFalse(ConfigPackageCard."No. of Errors".Visible(), 'No. of Errors.VISIBLE');
        Assert.IsFalse(ConfigPackageCard.ShowError.Visible(), 'ShowError.VISIBLE');
        ConfigPackageCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PackageCard_NoOfErrorsVisibleIfErrorsExist()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageError: Record "Config. Package Error";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageCard: TestPage "Config. Package Card";
    begin
        // [FEATURE] [Error] [UI]
        // [SCENARIO] "No. of Errors" and action "Show Error" are visible if there are errors for the package.
        Initialize();
        LibraryApplicationArea.EnableFoundationSetup();
        // [GIVEN] Package 'A'
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::Currency);
        // [GIVEN] There is 1 error for Package 'A'
        CreatePackageErrors(ConfigPackageError, ConfigPackageTable, 1);

        // [WHEN] Open Package card page
        ConfigPackageCard.OpenView();
        // [THEN] Action "Show Error" is visible
        Assert.IsTrue(ConfigPackageCard.ShowError.Visible(), 'ShowError.VISIBLE');
        // [THEN] "No. of Errors" is visible and equals '1'
        Assert.IsTrue(ConfigPackageCard."No. of Errors".Visible(), 'No. of Errors.VISIBLE');
        Assert.AreEqual(1, ConfigPackageCard."No. of Errors".AsInteger(), 'wrong No. of Errors');
        ConfigPackageCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PackageCard_ActionShowErrorOpensErrorList()
    var
        Currency: Record Currency;
        CountryRegion: Record "Country/Region";
        ConfigPackage: Record "Config. Package";
        ConfigPackageError: Record "Config. Package Error";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageCard: TestPage "Config. Package Card";
        ConfigPackageErrors: TestPage "Config. Package Errors";
    begin
        // [FEATURE] [Error] [UI]
        // [SCENARIO] Action "Show Error" opens the list of all errors for the package.
        Initialize();
        LibraryApplicationArea.EnableFoundationSetup();
        // [GIVEN] Package 'A', where are 1 error for table 4 and 2 errors for table 9.
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::Currency);
        ConfigPackageError."Field ID" := Currency.FieldNo("Residual Gains Account");
        CreatePackageErrors(ConfigPackageError, ConfigPackageTable, 1);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Country/Region");
        ConfigPackageError."Field ID" := CountryRegion.FieldNo("EU Country/Region Code");
        CreatePackageErrors(ConfigPackageError, ConfigPackageTable, 2);
        // [GIVEN] Open Package card page
        ConfigPackageCard.OpenView();
        // [WHEN] Run Action "Show Error"
        ConfigPackageErrors.Trap();
        ConfigPackageCard.ShowError.Invoke();

        // [THEN] Page 'Errors' opened where are 1 record: with "Table ID"
        Assert.IsTrue(ConfigPackageErrors.First(), 'Line #1 is not found');
        // [THEN] 1 record, where "Table ID" is '4', "Field Caption" is 'Residual Gains Account'
        ConfigPackageErrors."Field Caption".AssertEquals(Currency.FieldCaption("Residual Gains Account"));
        Assert.AreEqual(DATABASE::Currency, ConfigPackageErrors."Table ID".AsInteger(), 'Table ID for line #1');
        // [THEN] 2 records, where "Table ID" is '9', "Field Caption" is 'EU Country/Region Code'
        Assert.IsTrue(ConfigPackageErrors.Next(), 'Line #2 is not found');
        ConfigPackageErrors."Field Caption".AssertEquals(CountryRegion.FieldCaption("EU Country/Region Code"));
        Assert.AreEqual(DATABASE::"Country/Region", ConfigPackageErrors."Table ID".AsInteger(), 'Table ID for line #2');
        Assert.IsTrue(ConfigPackageErrors.Next(), 'Line #3 is not found');
        Assert.AreEqual(DATABASE::"Country/Region", ConfigPackageErrors."Table ID".AsInteger(), 'Table ID for line #3');
        Assert.IsFalse(ConfigPackageErrors.Next(), 'Line #4 must not exist');
        // [THEN] "Field Caption" control does not support drilldown action
        asserterror ConfigPackageErrors."Field Caption".DrillDown();
        Assert.ExpectedError('The NavDrilldownAction method is not supported.');
        ConfigPackageErrors.Close();
        ConfigPackageCard.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PackageCardPageTestability_ValidateRelations()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageError: Record "Config. Package Error";
        ConfigPackageCard: TestPage "Config. Package Card";
    begin
        Initialize();

        CreateRelatedPackageData(
          ConfigPackage,
          false,// Do not createPrimaryPackageData
          true,// CreateRelatedPackageData
          true,// Delete primary record
          true,// Delete related record
          0,// Primary priority
          0); // Related table priority

        ConfigPackageCard.OpenView();
        ConfigPackageCard.GotoRecord(ConfigPackage);
        ConfigPackageCard.Control10.ValidateRelations.Invoke();

        ConfigPackageError.SetRange("Package Code", ConfigPackage.Code);
        Assert.IsFalse(ConfigPackageError.IsEmpty, NoMigrationError);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PackageCardPageTestability_ApplyData()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageError: Record "Config. Package Error";
        ConfigPackageCard: TestPage "Config. Package Card";
    begin
        Initialize();

        CreateRelatedPackageData(
          ConfigPackage,
          false,// Do not createPrimaryPackageData
          true,// CreateRelatedPackageData
          true,// Delete primary record
          true,// Delete related record
          0,// Primary priority
          0); // Related table priority

        ConfigPackageCard.OpenView();
        ConfigPackageCard.GotoRecord(ConfigPackage);
        ConfigPackageCard.Control10.ApplyData.Invoke();

        ConfigPackageError.SetRange("Package Code", ConfigPackage.Code);
        Assert.IsFalse(ConfigPackageError.IsEmpty, NoMigrationError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PackageDataApplying_MasterThenRelatedThenMasterAgain_NoPackageErrorsAfterLastApply()
    var
        MasterConfigPackage: Record "Config. Package";
        RelatedConfigPackage: Record "Config. Package";
        ConfigPackageError: Record "Config. Package Error";
    begin
        Initialize();

        CreateTwoPackagesWithRelationBetweenTables(MasterConfigPackage, RelatedConfigPackage);

        ApplyPackageAndSetupProcessingOrder(RelatedConfigPackage);
        ApplyPackageAndSetupProcessingOrder(MasterConfigPackage);
        ApplyPackageAndSetupProcessingOrder(RelatedConfigPackage);

        Assert.IsTrue(ConfigPackageError.IsEmpty, MigrationError);
    end;

    [Test]
    [HandlerFunctions('ConfigPackageRecordsHandler')]
    [Scope('OnPrem')]
    procedure PackageDataApplying_ApplyFromPackageErrorsNonErroneous_ErrorDeleted()
    var
        MasterConfigPackage: Record "Config. Package";
        RelatedConfigPackage: Record "Config. Package";
        ConfigPackageError: Record "Config. Package Error";
    begin
        Initialize();
        CreateTwoPackagesWithRelationBetweenTables(MasterConfigPackage, RelatedConfigPackage);
        ApplyPackageAndSetupProcessingOrder(RelatedConfigPackage);
        ApplyPackageAndSetupProcessingOrder(MasterConfigPackage);

        RunApplyFromPackageRecords(RelatedConfigPackage);

        Assert.IsTrue(ConfigPackageError.IsEmpty, MigrationError);
    end;

    [Test]
    [HandlerFunctions('ConfigPackageRecordsHandler')]
    [Scope('OnPrem')]
    procedure PackageDataApplying_ApplyFromPackageErrorsErroneous_ErrorPresent()
    var
        MasterConfigPackage: Record "Config. Package";
        RelatedConfigPackage: Record "Config. Package";
        ConfigPackageError: Record "Config. Package Error";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        Initialize();
        CreateTwoPackagesWithRelationBetweenTables(MasterConfigPackage, RelatedConfigPackage);
        ApplyPackageAndSetupProcessingOrder(RelatedConfigPackage);

        RunApplyFromPackageRecords(RelatedConfigPackage);

        ConfigPackageError.SetRange("Package Code", RelatedConfigPackage.Code);
        ConfigPackageError.FindFirst();
        ConfigPackageError.TestField("Field ID", GenJournalTemplate.FieldNo(Name));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PackageDataApplying_RunApplyWithTableFilter_PackageErrorsForOtherTablesSaved()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageError: Record "Config. Package Error";
        ConfigPackageMgt: Codeunit "Config. Package Management";
        ErrorText: Text[250];
    begin
        Initialize();

        CreateRelatedPackageData(
          ConfigPackage,
          true,// CreatePrimaryPackageData
          true,// CreateRelatedPackageData
          true,// Delete primary record
          true,// Delete related record
          0,// Primary priority
          0); // Related table priority

        ConfigPackageMgt.SetHideDialog(true);
        ConfigPackageTable.SetRange("Package Code", ConfigPackage.Code);
        ConfigPackageTable.SetRange("Table ID", DATABASE::"Gen. Journal Batch");
        ConfigPackageMgt.ApplyPackage(ConfigPackage, ConfigPackageTable, true);

        ConfigPackageError.FindFirst();
        ErrorText := ConfigPackageError."Error Text";

        ConfigPackageTable.SetRange("Table ID", DATABASE::"Gen. Journal Template");
        ConfigPackageMgt.ApplyPackage(ConfigPackage, ConfigPackageTable, true);

        ConfigPackageError.FindFirst();
        Assert.AreEqual(ErrorText, ConfigPackageError."Error Text", TableFilterApplyErr);
    end;

    [Test]
    [HandlerFunctions('ConfigPackageRecordsHandler')]
    [Scope('OnPrem')]
    procedure PackageDataApplying_ApplyFromPackageErrors_ErrorDeletedForSelectedLineOnly()
    var
        MasterConfigPackage: Record "Config. Package";
        RelatedConfigPackage: Record "Config. Package";
        ConfigPackageError: Record "Config. Package Error";
        RecNo: Integer;
    begin
        Initialize();
        CreateTwoPackagesWithRelationBetweenTables(MasterConfigPackage, RelatedConfigPackage);

        RecNo := 2;
        CreateAdditionalGenJnlBatchInPackageData(MasterConfigPackage, RelatedConfigPackage, RecNo);

        ApplyPackageAndSetupProcessingOrder(RelatedConfigPackage);
        ApplyPackageAndSetupProcessingOrder(MasterConfigPackage);

        RunApplyFromPackageRecords(RelatedConfigPackage);

        ConfigPackageError.SetRange("Record No.", RecNo);
        Assert.IsFalse(ConfigPackageError.IsEmpty, NoMigrationError);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure VerifyDimensionsTableIsNotAppliedWhenAnotherTableIsSelected()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
    begin
        // Create a package and include data without Dimension Set ID
        CreatePackageWithCustomerAndDimension(ConfigPackage, ConfigPackageTable);

        // Exercise: Select 1 table from the package and apply it
        SelectOneTableAndApplyPackage(ConfigPackage, ConfigPackageTable, DATABASE::Customer);

        // Verify that the package record for the dimension table has not been applied
        CalcPackageTableFields(ConfigPackageTable, ConfigPackage.Code, DATABASE::Dimension);
        Assert.AreEqual(1, ConfigPackageTable."No. of Package Records",
          StrSubstNo(TableMustNotBeAppliedErr, ConfigPackageTable."Table Name"));
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure VerifyDimensionsTableIsAppliedWhenTableWithDimSetIDIsSelected()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
    begin
        // Create a package and include data with Dimension Set ID
        CreatePackageWithSalesHeaderAndDimension(ConfigPackage, ConfigPackageTable);
        InsertDimSetEntryIfEmpty();

        // Exercise: Select 1 table from the package and apply it
        SelectOneTableAndApplyPackage(ConfigPackage, ConfigPackageTable, DATABASE::"Sales Header");

        // Verify that the table with Dim Set ID tables has been applied
        CalcPackageTableFields(ConfigPackageTable, ConfigPackage.Code, DATABASE::Dimension);
        Assert.AreEqual(0, ConfigPackageTable."No. of Package Records",
          StrSubstNo(TableMustBeAppliedErr, ConfigPackageTable."Table Name"));
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure VerifyDimensionsTableIsNotAppliedWhenTableWithDimSetIDIsSelectedAndDimSetEntryIsEmpty()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        DimSetEntry: Record "Dimension Set Entry";
    begin
        // Create a package and include data with Dimension Set ID
        CreatePackageWithSalesHeaderAndDimension(ConfigPackage, ConfigPackageTable);
        DimSetEntry.DeleteAll();

        // Exercise: Select 1 table from the package and apply it
        SelectOneTableAndApplyPackage(ConfigPackage, ConfigPackageTable, DATABASE::"Sales Header");

        // Verify that the table with Dim Set ID tables has not been applied when dimension set entries exist
        CalcPackageTableFields(ConfigPackageTable, ConfigPackage.Code, DATABASE::Dimension);
        Assert.AreEqual(1, ConfigPackageTable."No. of Package Records",
          StrSubstNo(TableMustBeAppliedErr, ConfigPackageTable."Table Name"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatePackageNoRecordsCreatedCustomerContact()
    var
        ConfigPackage: Record "Config. Package";
        Customer: Record Customer;
        Contact: Record Contact;
        ContactNo: Code[20];
    begin
        // [SCENARIO 376810] Validate Package for Customer Table with Contact does not create new Contact
        Initialize();

        // [GIVEN] Customer "X"
        LibrarySales.CreateCustomer(Customer);
        ContactNo := LibraryUtility.GenerateRandomCode(Customer.FieldNo(Contact), DATABASE::Customer);

        // [GIVEN] Rapid Start Package with Customer Table
        // [GIVEN] Package Data has Customer "No." = "X", "Contact" = "Z"
        LibraryRapidStart.CreatePackage(ConfigPackage);
        CreatePackageTableWithTableData(
          ConfigPackage.Code, DATABASE::Customer, Customer.FieldNo("No."), Customer.FieldNo(Contact),
          Customer."No.", ContactNo);

        // [WHEN] Run Validate Package
        LibraryRapidStart.ValidatePackage(ConfigPackage, false);

        // [THEN] Contact with Name = "Z" does not exists
        Contact.Init();
        Contact.SetRange(Name, ContactNo);
        Assert.RecordIsEmpty(Contact);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatePackageNoRecordsCreatedVendorContact()
    var
        ConfigPackage: Record "Config. Package";
        Vendor: Record Vendor;
        Contact: Record Contact;
        ContactNo: Code[20];
    begin
        // [SCENARIO 376810] Validate Package for Vendor Table with Contact does not create new Contact
        Initialize();

        // [GIVEN] Vendor "X"
        LibraryPurchase.CreateVendor(Vendor);
        ContactNo := LibraryUtility.GenerateRandomCode(Vendor.FieldNo(Contact), DATABASE::Vendor);

        // [GIVEN] Rapid Start Package with Vendor Table
        // [GIVEN] Package Data has Vendor "No." = "X", "Contact" = "Z"
        LibraryRapidStart.CreatePackage(ConfigPackage);
        CreatePackageTableWithTableData(
          ConfigPackage.Code, DATABASE::Vendor, Vendor.FieldNo("No."), Vendor.FieldNo(Contact),
          Vendor."No.", ContactNo);

        // [WHEN] Run Validate Package
        LibraryRapidStart.ValidatePackage(ConfigPackage, false);

        // [THEN] Contact with Name = "Z" does not exists
        Contact.Init();
        Contact.SetRange(Name, ContactNo);
        Assert.RecordIsEmpty(Contact);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatePackageNoRecordsCreatedItemBaseUnitOfMeasure()
    var
        ConfigPackage: Record "Config. Package";
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        // [SCENARIO 376810] Validate Package for Item Table with Base Unit of Measure does not create new Item Unit of Measure
        Initialize();

        // [GIVEN] Item "X", Unit of Measure "Y"
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);

        // [GIVEN] Rapid Start Package with Customer Table
        // [GIVEN] Package Data has Vendor "No." = "X", "Base Unit of Measure" = "Z"
        LibraryRapidStart.CreatePackage(ConfigPackage);
        CreatePackageTableWithTableData(
          ConfigPackage.Code, DATABASE::Item, Item.FieldNo("No."), Item.FieldNo("Base Unit of Measure"),
          Item."No.", UnitOfMeasure.Code);

        // [WHEN] Run Validate Package
        LibraryRapidStart.ValidatePackage(ConfigPackage, false);

        // [THEN] Item Unit of Measure with Name = "Z" does not exists
        ItemUnitOfMeasure.Init();
        ItemUnitOfMeasure.SetRange(Code, UnitOfMeasure.Code);
        Assert.RecordIsEmpty(ItemUnitOfMeasure);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTValidateExceptionCheckFields()
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ConfigPackageManagement: Codeunit "Config. Package Management";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 376810] Validate Package for Item Table with Base Unit of Measure does not create new Item Unit of Measure
        Initialize();

        // [WHEN] Run function "ValidateException" from of "Config Package Management" codeunit for fields Customer/Vendor "Contact", Item "Base Unit of Measure"
        // [THEN] "ValidateException" returns TRUE to show that fields are exceptions and should not be validated
        Assert.IsTrue(
          ConfigPackageManagement.ValidateException(DATABASE::Customer, Customer.FieldNo(Contact)),
          Customer.FieldCaption(Contact));
        Assert.IsTrue(
          ConfigPackageManagement.ValidateException(DATABASE::Vendor, Vendor.FieldNo(Contact)),
          Vendor.FieldCaption(Contact));
        Assert.IsTrue(
          ConfigPackageManagement.ValidateException(DATABASE::Item, Item.FieldNo("Base Unit of Measure")),
          Item.FieldCaption("Base Unit of Measure"));
        Assert.IsTrue(
          ConfigPackageManagement.ValidateException(DATABASE::"Sales Header", SalesHeader.FieldNo("No.")),
          SalesHeader.FieldCaption("No."));
        Assert.IsTrue(
          ConfigPackageManagement.ValidateException(DATABASE::"Sales Line", SalesLine.FieldNo("Document No.")),
          SalesLine.FieldCaption("Document No."));
        Assert.IsTrue(
          ConfigPackageManagement.ValidateException(DATABASE::"Purchase Header", PurchaseHeader.FieldNo("No.")),
          PurchaseHeader.FieldCaption("No."));
        Assert.IsTrue(
          ConfigPackageManagement.ValidateException(DATABASE::"Purchase Line", PurchaseLine.FieldNo("Document No.")),
          PurchaseLine.FieldCaption("Document No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DelayedInsertOnApplyProductionForecastEntryWhenConfigTableHasMandatoryFieldsFilled()
    var
        ProductionForecastEntry: Record "Production Forecast Entry";
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageError: Record "Config. Package Error";
        ProdForecastName: Code[10];
        TableID: Integer;
    begin
        // [SCENARIO 381053] Delayed insert with not-"Skip Table Triggers" option for the table where OnInsert trigger fails while non-PK fields are not filled yet
        Initialize();

        // [GIVEN] Config Package for new Production Forecast Entry with "Skip Table Triggers" = No
        ProdForecastName := CreateProductionForecastName();

        TableID := DATABASE::"Production Forecast Entry";
        LibraryRapidStart.CreatePackage(ConfigPackage);

        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, TableID);
        ConfigPackageTable.Validate("Skip Table Triggers", false);
        ConfigPackageTable.Modify(true);

        // [GIVEN] Mandatory fields are filled in: "Production Forecast Name" = "N", "Forecast Date" = WORKDATE
        if not ProductionForecastEntry.FindLast() then
            ProductionForecastEntry.Init();
        LibraryRapidStart.CreatePackageData(
          ConfigPackage.Code, TableID, 1, ProductionForecastEntry.FieldNo("Entry No."), Format(ProductionForecastEntry."Entry No." + 1));
        LibraryRapidStart.CreatePackageData(
          ConfigPackage.Code, TableID, 1, ProductionForecastEntry.FieldNo("Forecast Date"), Format(WorkDate()));
        LibraryRapidStart.CreatePackageData(
          ConfigPackage.Code, TableID, 1, ProductionForecastEntry.FieldNo("Production Forecast Name"), ProdForecastName);

        // [WHEN] Apply Package
        LibraryRapidStart.ApplyPackage(ConfigPackage, false);

        // [THEN] No error for Config. Package created
        ConfigPackageError.Init();
        ConfigPackageError.SetRange("Package Code", ConfigPackage.Code);
        Assert.RecordIsEmpty(ConfigPackageError);
        // [THEN] Production Forecast Entry is created with "Production Forecast Name" = "N", "Forecast Date" = WORKDATE
        ProductionForecastEntry.FindLast();
        ProductionForecastEntry.TestField("Production Forecast Name", ProdForecastName);
        ProductionForecastEntry.TestField("Forecast Date", WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DelayedInsertOnApplyProductionForecastEntryWhenConfigTableHasMandatoryFieldNotFilled()
    var
        ProductionForecastEntry: Record "Production Forecast Entry";
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageError: Record "Config. Package Error";
        TableID: Integer;
    begin
        // [SCENARIO 381053] Delayed insert with not-"Skip Table Triggers" option gives an error when not all mandatory non-PK field are filled in.
        Initialize();

        // [GIVEN] Config Package for new Production Forecast Entry with "Skip Table Triggers" = No
        TableID := DATABASE::"Production Forecast Entry";
        LibraryRapidStart.CreatePackage(ConfigPackage);

        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, TableID);
        ConfigPackageTable.Validate("Skip Table Triggers", false);
        ConfigPackageTable.Modify(true);

        // [GIVEN] Only one mandatory field is filled in: "Forecast Date" = WORKDATE
        if not ProductionForecastEntry.FindLast() then
            ProductionForecastEntry.Init();
        LibraryRapidStart.CreatePackageData(
          ConfigPackage.Code, TableID, 1, ProductionForecastEntry.FieldNo("Entry No."), Format(ProductionForecastEntry."Entry No." + 1));

        LibraryRapidStart.CreatePackageData(
          ConfigPackage.Code, TableID, 1, ProductionForecastEntry.FieldNo("Forecast Date"), Format(WorkDate()));

        // [WHEN] Apply Package
        LibraryRapidStart.ApplyPackage(ConfigPackage, false);

        // [THEN] Error for Config. Package is created for "Production Forecast Name" field
        ConfigPackageError.SetRange("Package Code", ConfigPackage.Code);
        ConfigPackageError.FindFirst();
        Assert.ExpectedMessage(ProductionForecastEntry.FieldCaption("Production Forecast Name"), ConfigPackageError."Error Text");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NonKeyFieldsValidatedOnDelayedInsert()
    var
        ProductionForecastEntry: Record "Production Forecast Entry";
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        Item: Record Item;
        ProdForecastName: Code[10];
        TableID: Integer;
        ForecastQty: Decimal;
    begin
        // [SCENARIO 220748] Fields that are not part of the primary key should be validated with delayed insert
        Initialize();

        // [GIVEN] Item "I" with the base unit of measure "M"
        LibraryInventory.CreateItem(Item);
        ForecastQty := LibraryRandom.RandInt(100);

        // [GIVEN] Config Package for a new production forecast with one entry
        ProdForecastName := CreateProductionForecastName();

        TableID := DATABASE::"Production Forecast Entry";
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, TableID);

        // [GIVEN] Forecast entry refers to the item "I", "Forecast Quantity (Base)" = "X"
        // [GIVEN] Config package record includes the field "Forecast Quantity (Base)", but "Forecast Quantity" and "Unit of Measure Code" are blank
        if not ProductionForecastEntry.FindLast() then
            ProductionForecastEntry.Init();
        LibraryRapidStart.CreatePackageData(
          ConfigPackage.Code, TableID, 1, ProductionForecastEntry.FieldNo("Entry No."), Format(ProductionForecastEntry."Entry No." + 1));
        LibraryRapidStart.CreatePackageData(
          ConfigPackage.Code, TableID, 1, ProductionForecastEntry.FieldNo("Forecast Date"), Format(WorkDate()));
        LibraryRapidStart.CreatePackageData(
          ConfigPackage.Code, TableID, 1, ProductionForecastEntry.FieldNo("Production Forecast Name"), ProdForecastName);
        LibraryRapidStart.CreatePackageData(
          ConfigPackage.Code, TableID, 1, ProductionForecastEntry.FieldNo("Item No."), Item."No.");
        LibraryRapidStart.CreatePackageData(
          ConfigPackage.Code, TableID, 1, ProductionForecastEntry.FieldNo("Forecast Quantity (Base)"), Format(ForecastQty));

        // [WHEN] Apply Package
        LibraryRapidStart.ApplyPackage(ConfigPackage, false);

        // [THEN] New forecast entry is inserted. "Forecast Quantity" = "X", "Unit of Measure Code" = "M"
        ProductionForecastEntry.SetRange("Production Forecast Name", ProdForecastName);
        ProductionForecastEntry.FindLast();
        ProductionForecastEntry.TestField("Unit of Measure Code", Item."Base Unit of Measure");
        ProductionForecastEntry.TestField("Forecast Quantity", ForecastQty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DelayedInsertFalseOnApplyConfigPackageTableWhenWrongRelation()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        Customer: Record Customer;
        CustomerNo: Code[20];
    begin
        // [SCENARIO 286354] Record has been inserted during an Applying package if the record has wrong relation and "Delayed Insert" = FALSE.
        Initialize();

        // [GIVEN] Config. package with customer
        LibrarySales.CreateCustomer(Customer);
        CustomerNo := Customer."No.";
        LibraryRapidStart.CreatePackageDataForField(ConfigPackage, ConfigPackageTable, DATABASE::Customer,
          Customer.FieldNo("No."), Customer."No.", 1);

        // [GIVEN] Customer has wrong relation (Customer Code = <random value>)
        LibraryRapidStart.CreatePackageDataForField(ConfigPackage, ConfigPackageTable, DATABASE::Customer,
          Customer.FieldNo("Currency Code"), LibraryUtility.GenerateGUID(), 1);
        Customer.Delete();

        // [GIVEN] "Config. Package Table"."Delayed Insert" = FALSE
        ConfigPackageTable.Get(ConfigPackageTable."Package Code", ConfigPackageTable."Table ID");
        ConfigPackageTable.Validate("Delayed Insert", false);
        ConfigPackageTable.Modify(true);

        // [WHEN] Apply package
        ApplyPackageAndSetupProcessingOrder(ConfigPackage);

        // [THEN] Customer has been inserted without Non key fields data
        Customer.Get(CustomerNo);
        Customer.TestField("Currency Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DelayedInsertTrueOnApplyConfigPackageTableWhenWrongRelation()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        Customer: Record Customer;
        CustomerNo: Code[20];
    begin
        // [SCENARIO 286354] Record has not been inserted during an Applying package if the record has wrong relation and "Delayed Insert" = TRUE.
        Initialize();

        // [GIVEN] Config. package with customer
        LibrarySales.CreateCustomer(Customer);
        CustomerNo := Customer."No.";
        LibraryRapidStart.CreatePackageDataForField(ConfigPackage, ConfigPackageTable, DATABASE::Customer,
          Customer.FieldNo("No."), Customer."No.", 1);

        // [GIVEN] Customer has wrong relation (Customer Code = <random value>)
        LibraryRapidStart.CreatePackageDataForField(ConfigPackage, ConfigPackageTable, DATABASE::Customer,
          Customer.FieldNo("Currency Code"), LibraryUtility.GenerateGUID(), 1);
        Customer.Delete();

        // [GIVEN] "Config. Package Table"."Delayed Insert" = TRUE
        ConfigPackageTable.Get(ConfigPackageTable."Package Code", ConfigPackageTable."Table ID");
        ConfigPackageTable.Validate("Delayed Insert", true);
        ConfigPackageTable.Modify(true);

        // [WHEN] Apply package
        ApplyPackageAndSetupProcessingOrder(ConfigPackage);

        // [THEN] Customer has not been inserted
        Assert.IsFalse(Customer.Get(CustomerNo), 'Record has been inserted.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DelayedInsertFieldVisible()
    var
        ConfigPackageSubform: TestPage "Config. Package Subform";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 286354] Config. Package Table has visible field: "Delayed Insert"
        LibraryApplicationArea.EnableFoundationSetup();
        ConfigPackageSubform.OpenNew();
        Assert.IsTrue(ConfigPackageSubform."Delayed Insert".Visible(), 'The field "Delayed Insert" should be visible');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateMissingCodesWithCompositeKeyMultipleFieldsToInsert()
    var
        Customer: Record Customer;
        PostCode: Record "Post Code";
        ConfigLine: Record "Config. Line";
        ConfigPackage: Record "Config. Package";
        ConfigPackageError: Record "Config. Package Error";
        ConfigPackageMgt: Codeunit "Config. Package Management";
        TableID: Integer;
        CustomerNo: Code[20];
        City: Code[30];
        NewPostCode: Code[20];
    begin
        // [FEATURE] [Config Package] [Relation Table]
        // [SCENARIO 317356] Config package can create missing codes for related table with composite primary key from multiple config package fields
        Initialize();

        // [GIVEN] Config line contains a record with fields of the table Customer:
        // [GIVEN] "No." = "CU01", "City" = "TESTCITY", "Post Code" = "TS-77777"
        TableID := DATABASE::Customer;
        CustomerNo := LibraryUtility.GenerateRandomCode(Customer.FieldNo("No."), DATABASE::Customer);
        NewPostCode := LibraryUtility.GenerateRandomCode(PostCode.FieldNo(Code), DATABASE::"Post Code");
        City := LibraryUtility.GenerateRandomCode(PostCode.FieldNo(City), DATABASE::"Post Code");

        // [GIVEN] Config package field relation table Id is set as the table "Post Code" on both fields
        CreatePackageDataCustWithCreateMissingCodesForCityAndPostCode(ConfigPackage, CustomerNo, City, NewPostCode);
        SetConfigPackageFieldRelationTableID(
          ConfigPackage.Code, DATABASE::Customer, Customer.FieldNo(City), DATABASE::"Post Code");
        SetConfigPackageFieldRelationTableID(
          ConfigPackage.Code, DATABASE::Customer, Customer.FieldNo("Post Code"), DATABASE::"Post Code");

        LibraryRapidStart.CreateConfigLine(ConfigLine, ConfigLine."Line Type"::Table, TableID, '', ConfigPackage.Code, false);

        // [WHEN] Apply package data
        ConfigLine.SetRange("Line No.", ConfigLine."Line No.");
        ConfigPackageMgt.ApplyConfigLines(ConfigLine);

        // [THEN] No errors occur, error list is blank, database contains the Customer record "CU01" with fields:"City" = "TESTCITY" and "Post City" = "TS-77777"
        // [THEN] Database contains the "Post Code" record ["TS-77777","TESTCITY"]
        ConfigPackageError.SetRange("Package Code", ConfigPackage.Code);
        ConfigPackageError.SetRange("Table ID", TableID);
        Assert.RecordIsEmpty(ConfigPackageError);

        Customer.Get(CustomerNo);
        PostCode.Get(NewPostCode, City);
        Customer.TestField(City, PostCode.City);
        Customer.TestField("Post Code", PostCode.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyValidatePackageCodeunit()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Validate the "Config. Validate Package" sets the validation state when validatin is done
        Initialize();

        // [GIVEN] A ConfigPackageTable
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::Item);

        // [WHEN] Validating the package
        ConfigPackageTable.SetRange("Package Code", ConfigPackage.Code);
        CODEUNIT.Run(CODEUNIT::"Config. Validate Package", ConfigPackageTable);

        // [THEN] Validation is set
        ConfigPackageTable.SetRange(Validated, true);
        Assert.RecordCount(ConfigPackageTable, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyValidatePackageCodeunitFailed()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ObjectMetadata: Record "Object Metadata";
        NonExistingTableId: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Validate the "Config. Validate Package" sets the validation state on the tables that passed validation
        Initialize();

        // [GIVEN] Two Config. Package Tables in the Package, where the first Table is inconsistent
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::Item);
        ObjectMetadata.SetRange("Object Type", ObjectMetadata."Object Type"::Table);
        ObjectMetadata.FindLast();
        NonExistingTableId := ObjectMetadata."Object ID" + 1000;
        ConfigPackageTable.Init();
        ConfigPackageTable.Validate("Package Code", ConfigPackage.Code);
        ConfigPackageTable."Table ID" := NonExistingTableId;
        ConfigPackageTable.Insert(true);
        Commit();

        // [WHEN] Validating the package
        ConfigPackageTable.SetRange("Package Code", ConfigPackage.Code);
        asserterror CODEUNIT.Run(CODEUNIT::"Config. Validate Package", ConfigPackageTable);

        // [THEN] The first Table sould NOT be marked validated
        ConfigPackageTable.Get(ConfigPackage.Code, DATABASE::Item);
        ConfigPackageTable.TestField(Validated, false);

        // [THEN] The second Table sould NOT be marked validated
        ConfigPackageTable.Get(ConfigPackage.Code, NonExistingTableId);
        ConfigPackageTable.TestField(Validated, false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ValidateRelatedField()
    var
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        TempConfigPackageTable: Record "Config. Package Table" temporary;
        ConfigPackageError: Record "Config. Package Error";
        ConfigPackageMgt: Codeunit "Config. Package Management";
        TableID: Integer;
    begin
        // [FEATURE] [Config Package] [Relation Table]
        // [SCENARIO 358118] Stan can validate "Configuration Package" reflecting "Gen. Journal Line" with specified "Account Type" = "Bank Account" and "Account No.".
        Initialize();

        TableID := DATABASE::"Gen. Journal Line";

        // [GIVEN] Bank Account with "No." = "XXX"
        // [GIVEN] Configuration package for "Gen. Journal Line" table
        // [GIVEN] Configuration package data reflecting "Gen. Journal Line" with "Account Type" = "Bank Account" and "Account No." = "XXX"
        // [GIVEN] There is no G/L Account with "No." = "XXX" in database.
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::"Bank Account", LibraryERM.CreateBankAccountNo(), LibraryRandom.RandIntInRange(10, 20));

        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, TableID);

        LibraryRapidStart.CreatePackageData(
          ConfigPackage.Code, TableID, 1, GenJournalLine.FieldNo("Journal Template Name"), GenJournalLine."Journal Template Name");
        LibraryRapidStart.CreatePackageData(
          ConfigPackage.Code, TableID, 1, GenJournalLine.FieldNo("Journal Batch Name"), GenJournalLine."Journal Batch Name");
        LibraryRapidStart.CreatePackageData(
          ConfigPackage.Code, TableID, 1, GenJournalLine.FieldNo("Line No."), Format(GenJournalLine."Line No."));
        LibraryRapidStart.CreatePackageData(
          ConfigPackage.Code, TableID, 1, GenJournalLine.FieldNo("Account Type"), Format(GenJournalLine."Account Type"));
        LibraryRapidStart.CreatePackageData(
          ConfigPackage.Code, TableID, 1, GenJournalLine.FieldNo("Account No."), GenJournalLine."Account No.");

        GLAccount.SetRange("No.", GenJournalLine."Account No.");
        GLAccount.DeleteAll();

        GenJournalLine.Delete();
        Commit();

        // [WHEN] Validate package.
        ConfigPackageMgt.ValidatePackageRelations(ConfigPackageTable, TempConfigPackageTable, false);

        // [THEN] Package validation has not produced any error
        Assert.RecordCount(TempConfigPackageTable, 1);
        TempConfigPackageTable.SetRange("Table ID", TableID);
        Assert.RecordCount(TempConfigPackageTable, 1);

        ConfigPackageError.SetRange("Package Code", ConfigPackage.Code);
        ConfigPackageError.SetRange("Table ID", TableID);
        Assert.RecordIsEmpty(ConfigPackageError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatePackageNoModifyItemOnValidatePackage();
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    BEGIN
        // [SCENARIO 419198] Validate Package for Item Table does not update Item record fields
        Initialize();

        // [GIVEN] Item "X" with "VAT Prod. Posting Group" = VPPG
        LibraryInventory.CreateItem(Item);
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, Item."No.", 1);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        Item."VAT Prod. Posting Group" := VATProductPostingGroup.Code;
        Item.Modify(false);

        // [GIVEN] Rapid Start Package with Item Table
        // [GIVEN] Package Data has Customer "No." = "X", "Production BOM No." = "X"
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, Database::Item);

        LibraryRapidStart.CreatePackageData(
            ConfigPackage.Code, Database::Item, 1, Item.FIELDNO("No."), Item."No.");
        LibraryRapidStart.CreatePackageData(
            ConfigPackage.Code, Database::Item, 1, Item.FIELDNO("Production BOM No."), ProductionBOMHeader."No.");

        // [WHEN] Run Validate Package
        LibraryRapidStart.ValidatePackage(ConfigPackage, false);

        // [THEN] Item "X" field "VAT Prod. Posting Group" = VPPG
        Item.Get(Item."No.");
        Item.TESTFIELD("VAT Prod. Posting Group", VATProductPostingGroup.Code);
    END;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM RS Validate and Apply");
        LibraryRapidStart.CleanUp('');
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM RS Validate and Apply");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        APIMockEvents.SetAPIServicesEnabled(false);
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM RS Validate and Apply");
    end;

    local procedure CreatePackageDataPairWithPKRelation(var ConfigPackage: Record "Config. Package"; var PrimaryConfigPackageTable: Record "Config. Package Table"; var RelatedConfigPackageTable: Record "Config. Package Table"; CreatePrimaryPackageData: Boolean; CreateRelatedPackageData: Boolean; DeletePrimaryRecord: Boolean; DeleteRelatedRecord: Boolean; PrimaryDataPriority: Integer; RelatedDataPriority: Integer)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        KeyValueWithRelation: Code[10];
        KeyValueWithoutRelation: Code[10];
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate); // Master
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name); // Related

        KeyValueWithRelation := GenJournalTemplate.Name;
        KeyValueWithoutRelation := GenJournalBatch.Name;

        if DeletePrimaryRecord then
            GenJournalTemplate.Delete();
        if DeleteRelatedRecord then
            GenJournalBatch.Delete();

        // Master data
        if CreatePrimaryPackageData then begin
            LibraryRapidStart.CreatePackageDataForField(
              ConfigPackage,
              PrimaryConfigPackageTable,
              DATABASE::"Gen. Journal Template",
              GenJournalTemplate.FieldNo(Name),
              KeyValueWithRelation,
              1);
            LibraryRapidStart.SetProcessingOrderForRecord(ConfigPackage.Code, PrimaryConfigPackageTable."Table ID", PrimaryDataPriority);
        end;

        // Related Table field with relation
        if CreateRelatedPackageData then begin
            // PK Field with relation
            LibraryRapidStart.CreatePackageDataForField(
              ConfigPackage,
              RelatedConfigPackageTable,
              DATABASE::"Gen. Journal Batch",
              GenJournalBatch.FieldNo("Journal Template Name"),
              KeyValueWithRelation,
              1);

            // Field without relation
            LibraryRapidStart.CreatePackageDataForField(
              ConfigPackage,
              RelatedConfigPackageTable,
              DATABASE::"Gen. Journal Batch",
              GenJournalBatch.FieldNo(Name),
              KeyValueWithoutRelation,
              1);
            LibraryRapidStart.SetProcessingOrderForRecord(ConfigPackage.Code, RelatedConfigPackageTable."Table ID", RelatedDataPriority);
        end;
    end;

    local procedure CreateRelatedPackageData(var ConfigPackage: Record "Config. Package"; CreatePrimaryPackageData: Boolean; CreateRelatedPackageData: Boolean; DeletePrimaryRecord: Boolean; DeleteRelatedRecord: Boolean; PrimaryDataPriority: Integer; RelatedDataPriority: Integer)
    var
        PrimaryConfigPackageTable: Record "Config. Package Table";
        RelatedConfigPackageTable: Record "Config. Package Table";
    begin
        CreatePackageDataPairWithPKRelation(
          ConfigPackage,
          PrimaryConfigPackageTable,
          RelatedConfigPackageTable,
          CreatePrimaryPackageData,
          CreateRelatedPackageData,
          DeletePrimaryRecord,
          DeleteRelatedRecord,
          PrimaryDataPriority,
          RelatedDataPriority);
    end;

    local procedure CreatePackageDataPairWithNonPKRelation(var ConfigPackage: Record "Config. Package"; TableWithoutRelationPriority: Integer; TableWithRelationPriority: Integer; var GenJournalTemplateName: Code[10]; var ReasonCodeCode: Code[10])
    var
        ReasonCodeConfigPackageTable: Record "Config. Package Table";
        GenJnlTemplateConfigPackageTable: Record "Config. Package Table";
        ReasonCode: Record "Reason Code";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateReasonCode(ReasonCode);

        GenJournalTemplateName := GenJournalTemplate.Name;
        ReasonCodeCode := ReasonCode.Code;

        GenJournalTemplate.Delete();
        ReasonCode.Delete();

        LibraryRapidStart.CreatePackageDataForField(
          ConfigPackage,
          GenJnlTemplateConfigPackageTable,
          DATABASE::"Gen. Journal Template",
          GenJournalTemplate.FieldNo(Name),
          GenJournalTemplateName,
          1);
        LibraryRapidStart.SetProcessingOrderForRecord(
          ConfigPackage.Code, GenJnlTemplateConfigPackageTable."Table ID", TableWithoutRelationPriority);

        LibraryRapidStart.CreatePackageDataForField(
          ConfigPackage,
          ReasonCodeConfigPackageTable,
          DATABASE::"Reason Code",
          ReasonCode.FieldNo(Code),
          ReasonCodeCode,
          1);

        LibraryRapidStart.SetProcessingOrderForRecord(
          ConfigPackage.Code, ReasonCodeConfigPackageTable."Table ID", TableWithRelationPriority);
    end;

    local procedure CreatePackageDataPairWithoutRelation(var ConfigPackage: Record "Config. Package"; var GenJournalTemplateName: Code[10]; var ItemJournalTemplateName: Code[10])
    var
        ItemJnlTemplateConfigPackageTable: Record "Config. Package Table";
        GenJnlTemplateConfigPackageTable: Record "Config. Package Table";
        ItemJournalTemplate: Record "Item Journal Template";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);

        GenJournalTemplateName := GenJournalTemplate.Name;
        ItemJournalTemplateName := ItemJournalTemplate.Name;

        GenJournalTemplate.Delete();
        ItemJournalTemplate.Delete();

        LibraryRapidStart.CreatePackageDataForField(
          ConfigPackage,
          GenJnlTemplateConfigPackageTable,
          DATABASE::"Gen. Journal Template",
          GenJournalTemplate.FieldNo(Name),
          GenJournalTemplateName,
          1);

        LibraryRapidStart.CreatePackageDataForField(
          ConfigPackage,
          ItemJnlTemplateConfigPackageTable,
          DATABASE::"Item Journal Template",
          ItemJournalTemplate.FieldNo(Name),
          ItemJournalTemplateName,
          1);
    end;

    local procedure CreatePackageDataCustWithCreateMissingCodesForCityAndPostCode(var ConfigPackage: Record "Config. Package"; CustomerNo: Code[20]; City: Code[30]; NewPostCode: Code[20])
    var
        Customer: Record Customer;
        ConfigPackageTable: Record "Config. Package Table";
    begin
        LibraryRapidStart.CreatePackageDataForField(
          ConfigPackage, ConfigPackageTable, DATABASE::Customer, Customer.FieldNo("No."), CustomerNo, 1);

        LibraryRapidStart.CreatePackageDataForField(
          ConfigPackage, ConfigPackageTable, DATABASE::Customer, Customer.FieldNo(City), City, 1);
        LibraryRapidStart.CreatePackageDataForField(
          ConfigPackage, ConfigPackageTable, DATABASE::Customer, Customer.FieldNo("Post Code"), NewPostCode, 1);

        LibraryRapidStart.SetCreateMissingCodesForField(ConfigPackage.Code, DATABASE::Customer, Customer.FieldNo(City), true);
        LibraryRapidStart.SetCreateMissingCodesForField(ConfigPackage.Code, DATABASE::Customer, Customer.FieldNo("Post Code"), true);
    end;

    local procedure CreatePackageErrors(var ConfigPackageError: Record "Config. Package Error"; ConfigPackageTable: Record "Config. Package Table"; NoOfErrors: Integer)
    var
        FieldNo: Integer;
        i: Integer;
    begin
        FieldNo := ConfigPackageError."Field ID";
        ConfigPackageError."Package Code" := ConfigPackageTable."Package Code";
        ConfigPackageError."Table ID" := ConfigPackageTable."Table ID";
        for i := 1 to NoOfErrors do begin
            ConfigPackageError."Record No." := i;
            ConfigPackageError."Field ID" := FieldNo;
            ConfigPackageError.Insert(true);
        end;
        // adding an error for another package
        ConfigPackageError."Package Code" := LibraryUtility.GenerateGUID();
        ConfigPackageError.Insert(true);
    end;

    local procedure CreatePackageTableWithTableData(ConfigPackageCode: Code[20]; TableID: Integer; FieldNo: Integer; FieldNoChecked: Integer; FieldValue: Text[250]; FieldCheckedValue: Text[250])
    var
        ConfigPackageTable: Record "Config. Package Table";
    begin
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackageCode, TableID);
        LibraryRapidStart.CreatePackageData(ConfigPackageCode, TableID, 1, FieldNo, FieldValue);
        LibraryRapidStart.CreatePackageData(ConfigPackageCode, TableID, 1, FieldNoChecked, FieldCheckedValue);
    end;

    local procedure CreateProductionForecastName(): Code[10]
    var
        ProductionForecastName: Record "Production Forecast Name";
    begin
        ProductionForecastName.Name :=
          LibraryUtility.GenerateRandomCode(ProductionForecastName.FieldNo(Name), DATABASE::"Production Forecast Name");
        ProductionForecastName.Insert();

        exit(ProductionForecastName.Name);
    end;

    local procedure CreateAndApplyPackageDataForTableWithoutPKCheckOnInsert(var ConfigPackage: Record "Config. Package"; ValidatePK: Boolean) KeyValueWithRelation: Code[10]
    var
        ConfigPackageTable: Record "Config. Package Table";
        NoSeriesLine: Record "No. Series Line";
        ConfigPackageField: Record "Config. Package Field";
    begin
        KeyValueWithRelation :=
          LibraryUtility.GenerateRandomCode(
            NoSeriesLine.FieldNo("Series Code"), DATABASE::"No. Series Line");
        LibraryRapidStart.CreatePackageDataForField(
          ConfigPackage,
          ConfigPackageTable,
          DATABASE::"No. Series Line",
          NoSeriesLine.FieldNo("Series Code"),
          KeyValueWithRelation,
          1);
        LibraryRapidStart.CreatePackageDataForField(
          ConfigPackage,
          ConfigPackageTable,
          DATABASE::"No. Series Line",
          NoSeriesLine.FieldNo("Line No."),
          Format(0),
          1);

        ConfigPackageField.Get(ConfigPackage.Code, DATABASE::"No. Series Line", NoSeriesLine.FieldNo("Series Code"));
        ConfigPackageField."Validate Field" := ValidatePK;
        ConfigPackageField.Modify();

        ApplyPackageAndSkipProcessingOrder(ConfigPackage);
    end;

    local procedure GetKeyValuesWithRelation(ConfigPackageTable: Record "Config. Package Table"; var KeyWithRelation: Code[250]; var KeyWithoutRelation: Code[250])
    var
        ConfigPackageData: Record "Config. Package Data";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        ConfigPackageData.Get(
          ConfigPackageTable."Package Code",
          ConfigPackageTable."Table ID",
          1,
          GenJournalBatch.FieldNo("Journal Template Name"));

        KeyWithRelation := ConfigPackageData.Value;

        ConfigPackageData.Get(
          ConfigPackageTable."Package Code",
          ConfigPackageTable."Table ID",
          1,
          GenJournalBatch.FieldNo(Name));

        KeyWithoutRelation := ConfigPackageData.Value;
    end;

    local procedure GetConfigQuestionNo(ConfigQuestionnaireCode: Code[10]; ConfigQuestionAreaCode: Code[10]; TableID: Integer; FieldID: Integer): Integer
    var
        ConfigQuestion: Record "Config. Question";
    begin
        ConfigQuestion.SetRange("Questionnaire Code", ConfigQuestionnaireCode);
        ConfigQuestion.SetRange("Question Area Code", ConfigQuestionAreaCode);
        ConfigQuestion.SetRange("Table ID", TableID);
        ConfigQuestion.SetRange("Field ID", FieldID);
        ConfigQuestion.FindFirst();

        exit(ConfigQuestion."No.");
    end;

    local procedure CreatePackageWithQuestion(var ConfigPackage: Record "Config. Package"; var ConfigQuestion: Record "Config. Question"; AnswerValue: Text[250])
    var
        ConfigQuestionnaire: Record "Config. Questionnaire";
        ConfigQuestionArea: Record "Config. Question Area";
        ConfigPackageTable: Record "Config. Package Table";
        Customer: Record Customer;
        QuestionnaireManagement: Codeunit "Questionnaire Management";
    begin
        LibraryRapidStart.CreateQuestionnaire(ConfigQuestionnaire);
        LibraryRapidStart.CreateQuestionArea(ConfigQuestionArea, ConfigQuestionnaire.Code);
        ConfigQuestionArea.Validate("Table ID", DATABASE::Customer);
        ConfigQuestionArea.Modify(true);
        QuestionnaireManagement.UpdateQuestions(ConfigQuestionArea);

        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Config. Question");

        InsertQuestionPackageData(ConfigPackage.Code, ConfigQuestion.FieldNo("Questionnaire Code"), ConfigQuestionnaire.Code);
        InsertQuestionPackageData(ConfigPackage.Code, ConfigQuestion.FieldNo("Question Area Code"), ConfigQuestionArea.Code);

        InsertQuestionPackageData(
          ConfigPackage.Code,
          ConfigQuestion.FieldNo("No."),
          Format(GetConfigQuestionNo(ConfigQuestionnaire.Code, ConfigQuestionArea.Code, DATABASE::Customer, Customer.FieldNo(Blocked))));

        ConfigQuestion.Get(
          ConfigQuestionnaire.Code, ConfigQuestionArea.Code,
          GetConfigQuestionNo(ConfigQuestionnaire.Code, ConfigQuestionArea.Code, DATABASE::Customer, Customer.FieldNo(Blocked)));
        InsertQuestionPackageData(ConfigPackage.Code, ConfigQuestion.FieldNo(Question), ConfigQuestion.Question);
        InsertQuestionPackageData(ConfigPackage.Code, ConfigQuestion.FieldNo("Answer Option"), ConfigQuestion."Answer Option");
        // New answer to be applied
        InsertQuestionPackageData(ConfigPackage.Code, ConfigQuestion.FieldNo(Answer), AnswerValue);
        InsertQuestionPackageData(ConfigPackage.Code, ConfigQuestion.FieldNo("Table ID"), Format(DATABASE::Customer));
        InsertQuestionPackageData(ConfigPackage.Code, ConfigQuestion.FieldNo("Field ID"), Format(Customer.FieldNo(Blocked)));
    end;

    local procedure InsertDimSetEntryIfEmpty()
    var
        DimSetEntry: Record "Dimension Set Entry";
    begin
        if DimSetEntry.IsEmpty() then begin
            DimSetEntry.Init();
            DimSetEntry."Dimension Set ID" := 1;
            DimSetEntry.Insert();
        end;
    end;

    local procedure InsertQuestionPackageData(ConfigPackageCode: Code[20]; FieldID: Integer; Value: Text[250])
    begin
        LibraryRapidStart.CreatePackageData(ConfigPackageCode, DATABASE::"Config. Question", 1, FieldID, Value);
    end;

    local procedure SetAnswerValue(ConfigQuestionnaireCode: Code[10]; ConfigQuestionAreaCode: Code[10]; TableID: Integer; FieldID: Integer; AnswerValue: Text[250])
    var
        ConfigQuestion: Record "Config. Question";
    begin
        ConfigQuestion.Get(
          ConfigQuestionnaireCode, ConfigQuestionAreaCode,
          GetConfigQuestionNo(ConfigQuestionnaireCode, ConfigQuestionAreaCode, TableID, FieldID));
        ConfigQuestion.Validate(Answer, AnswerValue);
        ConfigQuestion.Modify();
    end;

    local procedure SetConfigPackageFieldRelationTableID(ConfigPackageCode: Code[20]; TableID: Integer; FieldID: Integer; RelationTableID: Integer)
    var
        ConfigPackageField: Record "Config. Package Field";
    begin
        ConfigPackageField.Get(ConfigPackageCode, TableID, FieldID);
        ConfigPackageField.Validate("Relation Table ID", RelationTableID);
        ConfigPackageField.Modify(true);
    end;

    local procedure GeneratePackageForTableWithSeriesNo(var ConfigPackage: Record "Config. Package"; var CustomerName: Text[50]; BlankPK: Boolean)
    var
        ConfigPackageTable: Record "Config. Package Table";
        Customer: Record Customer;
        CustomerNo: Code[20];
    begin
        LibrarySales.CreateCustomer(Customer);

        if not BlankPK then
            CustomerNo := Customer."No."
        else
            CustomerNo := '';

        CustomerName := Customer."No.";

        LibraryRapidStart.CreatePackageDataForField(
          ConfigPackage,
          ConfigPackageTable,
          DATABASE::Customer,
          Customer.FieldNo("No."),
          CustomerNo,
          1);

        LibraryRapidStart.CreatePackageDataForField(
          ConfigPackage,
          ConfigPackageTable,
          DATABASE::Customer,
          Customer.FieldNo(Name),
          CustomerName,
          1);

        Customer.Delete();
    end;

    local procedure GeneralTestcaseForApplyingRecordWithSeries(BlankPK: Boolean)
    var
        ConfigPackage: Record "Config. Package";
        Customer: Record Customer;
        CustomerName: Text[50];
        CustomersCount: Integer;
    begin
        Initialize();

        GeneratePackageForTableWithSeriesNo(ConfigPackage, CustomerName, BlankPK);

        CustomersCount := Customer.Count();
        ApplyPackageAndSetupProcessingOrder(ConfigPackage);

        Assert.IsTrue(Customer.Count <= CustomersCount + 1, MoreThanOneRecordInserted);
    end;

    local procedure ApplyPackageAndSetupProcessingOrder(var ConfigPackage: Record "Config. Package")
    begin
        LibraryRapidStart.ApplyPackage(ConfigPackage, true);
    end;

    local procedure ApplyPackageAndSkipProcessingOrder(var ConfigPackage: Record "Config. Package")
    begin
        LibraryRapidStart.ApplyPackage(ConfigPackage, false);
    end;

    local procedure ValidatePackageAndSetupProcessingOrder(var ConfigPackage: Record "Config. Package")
    begin
        LibraryRapidStart.ValidatePackage(ConfigPackage, true);
    end;

    local procedure ValidatePackageAndSkipProcessingOrder(var ConfigPackage: Record "Config. Package")
    begin
        LibraryRapidStart.ValidatePackage(ConfigPackage, false);
    end;

    local procedure CreateTwoPackagesWithRelationBetweenTables(var MasterConfigPackage: Record "Config. Package"; var RelatedConfigPackage: Record "Config. Package")
    var
        MasterConfigPackageData: Record "Config. Package Data";
        RelatedConfigPackageData: Record "Config. Package Data";
    begin
        CreateRelatedPackageData(
          MasterConfigPackage,
          true,// CreatePrimaryPackageData
          false,// CreateRelatedPackageData
          true,// Delete primary record
          true,// Delete related record
          0,// Primary priority
          0); // Related table priority

        CreateRelatedPackageData(
          RelatedConfigPackage,
          false,// CreatePrimaryPackageData
          true,// CreateRelatedPackageData
          true,// Delete primary record
          true,// Delete related record
          0,// Primary priority
          0); // Related table priority

        MasterConfigPackageData.SetRange("Package Code", MasterConfigPackage.Code);
        MasterConfigPackageData.FindFirst();
        RelatedConfigPackageData.SetRange("Package Code", RelatedConfigPackage.Code);
        RelatedConfigPackageData.FindFirst();
        RelatedConfigPackageData.Value := MasterConfigPackageData.Value;
        RelatedConfigPackageData.Modify();
    end;

    local procedure RunApplyFromPackageRecords(ConfigPackage: Record "Config. Package")
    var
        ConfigPackageCard: TestPage "Config. Package Card";
    begin
        ConfigPackageCard.OpenView();
        ConfigPackageCard.GotoRecord(ConfigPackage);
        ConfigPackageCard.Control10.GotoKey(ConfigPackage.Code, DATABASE::"Gen. Journal Batch");
        ConfigPackageCard.Control10.PackageErrors.Invoke();
    end;

    local procedure CreateAdditionalPackageData(RecRef: RecordRef; ConfigPackageCode: Code[20]; FromRecordNo: Integer; NewRecordNo: Integer)
    var
        ConfigPackageData: Record "Config. Package Data";
        FieldRef: FieldRef;
    begin
        ConfigPackageData.SetRange("Package Code", ConfigPackageCode);
        ConfigPackageData.SetRange("No.", FromRecordNo);
        ConfigPackageData.FindSet();
        repeat
            FieldRef := RecRef.Field(ConfigPackageData."Field ID");
            LibraryRapidStart.CreatePackageData(ConfigPackageData."Package Code", ConfigPackageData."Table ID", NewRecordNo, ConfigPackageData."Field ID", Format(FieldRef.Value));
        until ConfigPackageData.Next() = 0;
    end;

    local procedure CreateAdditionalGenJnlBatchInPackageData(MasterConfigPackage: Record "Config. Package"; RelatedConfigPackage: Record "Config. Package"; RecNo: Integer)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        MasterConfigPackageData: Record "Config. Package Data";
        GenJournalTemplate: Record "Gen. Journal Template";
        RecRef: RecordRef;
    begin
        MasterConfigPackageData.SetRange("Package Code", MasterConfigPackage.Code);
        MasterConfigPackageData.FindFirst();

        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch."Journal Template Name" := CopyStr(MasterConfigPackageData.Value, 1, 10);

        RecRef.GetTable(GenJournalBatch);

        CreateAdditionalPackageData(RecRef, RelatedConfigPackage.Code, 1, RecNo);

        GenJournalBatch."Journal Template Name" := GenJournalTemplate.Name;
        GenJournalBatch.Delete();
        GenJournalTemplate.Delete();
    end;

    local procedure CreatePackageWithCustomerAndDimension(var ConfigPackage: Record "Config. Package"; var ConfigPackageTable: Record "Config. Package Table")
    var
        Customer: Record Customer;
        Dimension: Record Dimension;
    begin
        LibraryRapidStart.CreatePackage(ConfigPackage);
        CreatePackageTableWithData(ConfigPackage, ConfigPackageTable, DATABASE::Customer, Customer.FieldNo("No."));
        CreatePackageTableWithData(ConfigPackage, ConfigPackageTable, DATABASE::Dimension, Dimension.FieldNo(Code));
    end;

    local procedure CreatePackageWithSalesHeaderAndDimension(var ConfigPackage: Record "Config. Package"; var ConfigPackageTable: Record "Config. Package Table")
    var
        SalesHeader: Record "Sales Header";
        Dimension: Record Dimension;
    begin
        LibraryRapidStart.CreatePackage(ConfigPackage);
        CreatePackageTableWithData(ConfigPackage, ConfigPackageTable, DATABASE::"Sales Header", SalesHeader.FieldNo("No."));
        CreatePackageTableWithData(ConfigPackage, ConfigPackageTable, DATABASE::Dimension, Dimension.FieldNo(Code));
    end;

    local procedure CreatePackageTableWithData(var ConfigPackage: Record "Config. Package"; var ConfigPackageTable: Record "Config. Package Table"; TableID: Integer; FieldID: Integer)
    begin
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, TableID);
        LibraryRapidStart.CreatePackageData(ConfigPackage.Code, TableID, 1, FieldID,
          LibraryUtility.GenerateRandomCode(FieldID, TableID));
    end;

    local procedure CreateFieldMapping(PackageCode: Code[20]; TableID: Integer; FieldID: Integer; OldValue: Text[250]; NewValue: Text[250])
    var
        ConfigFieldMapping: Record "Config. Field Map";
    begin
        ConfigFieldMapping.Init();
        ConfigFieldMapping.Validate("Package Code", PackageCode);
        ConfigFieldMapping.Validate("Table ID", TableID);
        ConfigFieldMapping.Validate("Field ID", FieldID);
        ConfigFieldMapping."Old Value" := OldValue;
        ConfigFieldMapping."New Value" := NewValue;
        ConfigFieldMapping.Insert();
    end;

    local procedure SelectOneTableAndApplyPackage(var ConfigPackage: Record "Config. Package"; var ConfigPackageTable: Record "Config. Package Table"; TableID: Integer)
    var
        ConfigPackageMgt: Codeunit "Config. Package Management";
    begin
        ConfigPackageTable.SetRange("Package Code", ConfigPackage.Code);
        ConfigPackageTable.SetRange("Table ID", TableID);
        ConfigPackageMgt.ApplyPackage(ConfigPackage, ConfigPackageTable, true);

        ConfigPackageTable.Reset();
    end;

    local procedure CalcPackageTableFields(var ConfigPackageTable: Record "Config. Package Table"; ConfigPackageCode: Code[20]; TableID: Integer)
    begin
        ConfigPackageTable.Get(ConfigPackageCode, TableID);
        ConfigPackageTable.CalcFields("No. of Package Records", "Table Name");
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmYesHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ConfigPackageRecordsHandler(var ConfigPackageRecords: TestPage "Config. Package Records")
    begin
        ConfigPackageRecords.ApplyData.Invoke();
        ConfigPackageRecords.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ConfigPackageErrorRecordHandler(var ConfigPackageRecords: TestPage "Config. Package Records")
    begin
        // 4th column is not visible
        LibraryVariableStorage.Enqueue(ConfigPackageRecords.Field4.Caption);
        LibraryVariableStorage.Enqueue(ConfigPackageRecords.Field4.Visible());
        // Expecting 3 visible fields with values
        LibraryVariableStorage.Enqueue(ConfigPackageRecords.Field1.Caption);
        LibraryVariableStorage.Enqueue(ConfigPackageRecords.Field1.Value);
        LibraryVariableStorage.Enqueue(ConfigPackageRecords.Field1.Editable());
        LibraryVariableStorage.Enqueue(ConfigPackageRecords.Field2.Caption);
        LibraryVariableStorage.Enqueue(ConfigPackageRecords.Field2.Value);
        LibraryVariableStorage.Enqueue(ConfigPackageRecords.Field2.Editable());
        LibraryVariableStorage.Enqueue(ConfigPackageRecords.Field3.Caption);
        LibraryVariableStorage.Enqueue(ConfigPackageRecords.Field3.Value);
        LibraryVariableStorage.Enqueue(ConfigPackageRecords.Field3.Editable());
    end;

    [EventSubscriber(ObjectType::Report, Report::"Config. Package - Process", 'OnBeforeTextTransformation', '', false, false)]
    local procedure OnBeforeTextTransformationHandler(ConfigPackageTable: Record "Config. Package Table"; var TempField: Record "Field" temporary; var TempTransformationRule: Record "Transformation Rule" temporary)
    var
        Customer: Record Customer;
        BankAccount: Record "Bank Account";
        ConfigPackageProcess: Report "Config. Package - Process";
    begin
        case ConfigPackageTable."Table ID" of
            DATABASE::"Bank Account":
                begin
                    ConfigPackageProcess.AddRuleForField(
                      DATABASE::"Bank Account", BankAccount.FieldNo("SWIFT Code"),
                      TempTransformationRule."Transformation Type"::"Remove Non-Alphanumeric Characters".AsInteger(), TempField, TempTransformationRule);
                    ConfigPackageProcess.AddRuleForField(
                      DATABASE::"Bank Account", BankAccount.FieldNo(IBAN),
                      TempTransformationRule."Transformation Type"::"Remove Non-Alphanumeric Characters".AsInteger(), TempField, TempTransformationRule);
                end;
            DATABASE::Customer:
                begin
                    ConfigPackageProcess.AddRuleForField(
                      DATABASE::Customer, Customer.FieldNo(Name),
                      TempTransformationRule."Transformation Type"::Replace.AsInteger(), TempField, TempTransformationRule);
                    TempTransformationRule."Find Value" := 'Mister';
                    TempTransformationRule."Replace Value" := 'Mr.';
                    TempTransformationRule.Modify();
                end;
        end;
    end;
}

