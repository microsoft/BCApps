codeunit 136609 "ERM RS Fld. Validate and Apply"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Config Package] [Rapid Start]
    end;

    var
        LibraryRapidStart: Codeunit "Library - Rapid Start";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        ConfigValidateManagement: Codeunit "Config. Validate Management";
        LibraryRandom: Codeunit "Library - Random";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        APIMockEvents: Codeunit "API Mock Events";
        isInitialized: Boolean;
        SingleEntryRecNo: Integer;
        MigrationError: Label 'There are errors in Migration Data Error.';
        NoMigrationError: Label 'There must be errors in Migration Data Error.';
        NoDataInTableAfterApply: Label 'There is no data in table after apply procedure.';
        DataIsInvalidAfterApply: Label 'Invalid data in field %1.';
        PackageValidationError: Label 'Package validation errors.';
        InvalidDataExpected: Label 'Config. package record is expected to be invalid.';
        ListMustBeEmpty: Label '%1 must be empty.';
        OptionNoExistsErr: Label 'OptionNoExists function returns wrong result.';
        GetOptionNoErr: Label 'GetOptionNo function returns wrong result.';
        ConfigPackContErr: Label 'Config Package contains errors';
        ItemUOMWeightErr: Label 'Item unit of measure weight is incorrect';
        UnsupportedCommentParentTypeErr: Label 'Unsupported comment parent type %1.', Comment = '%1 - comment table name';

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM RS Fld. Validate and Apply");
        LibraryRapidStart.CleanUp('');
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM RS Fld. Validate and Apply");

        SingleEntryRecNo := 1;

        APIMockEvents.SetAPIServicesEnabled(false);
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM RS Fld. Validate and Apply");
    end;

    local procedure CreateResource(var Resource: Record Resource; var ResourcePrice: Record "Resource Price")
    var
        LibraryResource: Codeunit "Library - Resource";
    begin
        Resource.Init();
        Resource.Validate("No.", LibraryUtility.GenerateRandomCode(Resource.FieldNo("No."), DATABASE::Resource));
        Resource.Insert(true);

        LibraryResource.CreateResourcePrice(ResourcePrice, ResourcePrice.Type::Resource, Resource."No.", '', '');
    end;

    local procedure GeneratePackageWithFieldFillingDependency(var ConfigPackage: Record "Config. Package"; FieldPriorityWithDependency: Integer; FieldPriorityWithoutDependency: Integer; var ResourcePriceCode: Code[20]; SavePackageRecord: Boolean)
    var
        ConfigPackageTable: Record "Config. Package Table";
        Resource: Record Resource;
        ResourcePrice: Record "Resource Price";
    begin
        CreateResource(Resource, ResourcePrice);

        ResourcePriceCode := ResourcePrice.Code;

        LibraryRapidStart.CreatePackageDataForField(
          ConfigPackage,
          ConfigPackageTable,
          DATABASE::"Resource Price",
          ResourcePrice.FieldNo(Type),
          Format(ResourcePrice.Type::All),
          SingleEntryRecNo);

        LibraryRapidStart.CreatePackageDataForField(
          ConfigPackage,
          ConfigPackageTable,
          DATABASE::"Resource Price",
          ResourcePrice.FieldNo(Code),
          ResourcePrice.Code,
          SingleEntryRecNo);

        LibraryRapidStart.CreatePackageDataForField(
          ConfigPackage,
          ConfigPackageTable,
          DATABASE::"Resource Price",
          ResourcePrice.FieldNo("Work Type Code"),
          ResourcePrice."Work Type Code",
          SingleEntryRecNo);

        LibraryRapidStart.CreatePackageDataForField(
          ConfigPackage,
          ConfigPackageTable,
          DATABASE::"Resource Price",
          ResourcePrice.FieldNo("Currency Code"),
          ResourcePrice."Currency Code",
          SingleEntryRecNo);

        LibraryRapidStart.SetProcessingOrderForField(
          ConfigPackage.Code, ConfigPackageTable."Table ID", ResourcePrice.FieldNo(Type), FieldPriorityWithoutDependency);
        LibraryRapidStart.SetProcessingOrderForField(
          ConfigPackage.Code, ConfigPackageTable."Table ID", ResourcePrice.FieldNo(Code), FieldPriorityWithDependency);

        if not SavePackageRecord then
            ResourcePrice.Delete();
    end;

    local procedure GenerateSimplePackage(UseInvalidGLAccountCode: Boolean; SavePackageRecord: Boolean; ValidateFields: Boolean; var ConfigPackage: Record "Config. Package"; var CustPostingGroupCode: Code[20]; var GLAccountNo: Code[20])
    var
        GLAccount: Record "G/L Account";
        CustPostingGroup: Record "Customer Posting Group";
        ConfigPackageTable: Record "Config. Package Table";
    begin
        CustPostingGroup.Code := LibraryUtility.GenerateRandomCode(CustPostingGroup.FieldNo(Code), DATABASE::"Customer Posting Group");

        if UseInvalidGLAccountCode then
            CustPostingGroup."Receivables Account" :=
              LibraryUtility.GenerateRandomCode(CustPostingGroup.FieldNo("Receivables Account"), DATABASE::"Customer Posting Group")
        else begin
            LibraryERM.FindGLAccount(GLAccount);
            CustPostingGroup."Receivables Account" := GLAccount."No.";
        end;

        if SavePackageRecord then
            CustPostingGroup.Insert();

        CustPostingGroupCode := CustPostingGroup.Code;
        GLAccountNo := CustPostingGroup."Receivables Account";

        LibraryRapidStart.CreatePackageDataForField(
          ConfigPackage,
          ConfigPackageTable,
          DATABASE::"Customer Posting Group",
          CustPostingGroup.FieldNo(Code),
          CustPostingGroup.Code,
          SingleEntryRecNo);

        LibraryRapidStart.CreatePackageDataForField(
          ConfigPackage,
          ConfigPackageTable,
          DATABASE::"Customer Posting Group",
          CustPostingGroup.FieldNo("Receivables Account"),
          CustPostingGroup."Receivables Account",
          SingleEntryRecNo);

        LibraryRapidStart.CreatePackageDataForField(
          ConfigPackage,
          ConfigPackageTable,
          DATABASE::"Customer Posting Group",
          CustPostingGroup.FieldNo("Service Charge Acc."),
          '',
          SingleEntryRecNo);

        SetPackageFieldsValidation(ConfigPackage.Code, ValidateFields);
    end;

    local procedure SetPackageFieldsValidation(PackageCode: Code[20]; ValidateFields: Boolean)
    var
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageField: Record "Config. Package Field";
    begin
        ConfigPackageTable.SetRange("Package Code", PackageCode);
        if ConfigPackageTable.FindSet() then
            repeat
                ConfigPackageField.SetRange("Package Code", PackageCode);
                ConfigPackageField.SetRange("Table ID", ConfigPackageTable."Table ID");
                if ConfigPackageField.FindSet() then
                    repeat
                        if not ConfigPackageField."Primary Key" then begin
                            ConfigPackageField.Validate("Validate Field", ValidateFields);
                            ConfigPackageField.Modify(true);
                        end;
                    until ConfigPackageField.Next() = 0;
            until ConfigPackageTable.Next() = 0;
    end;

    local procedure SetPackageFieldValue(ConfigPackageCode: Code[20]; TableID: Integer; RecordNo: Integer; FieldNo: Integer; NewValue: Text[250])
    var
        ConfigPackageData: Record "Config. Package Data";
    begin
        ConfigPackageData.Get(ConfigPackageCode, TableID, RecordNo, FieldNo);
        ConfigPackageData.Validate(Value, NewValue);
        ConfigPackageData.Modify(true);
    end;

    local procedure CheckOptionNoExists(Value: Text; ExpectedResult: Boolean)
    var
        SalesLine: Record "Sales Line";
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.Open(DATABASE::"Sales Line");
        FieldRef := RecRef.Field(SalesLine.FieldNo(Type));
        Assert.AreEqual(ExpectedResult, ConfigValidateManagement.OptionNoExists(FieldRef, CopyStr(Value, 1, 250)), OptionNoExistsErr);
    end;

    local procedure CheckGetOptionNo(Value: Text; ExpectedResult: Integer)
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.Open(DATABASE::"Sales Cr.Memo Line");
        FieldRef := RecRef.Field(SalesCrMemoLine.FieldNo("IC Partner Ref. Type"));
        Assert.AreEqual(ExpectedResult, ConfigValidateManagement.GetOptionNo(CopyStr(Value, 1, 250), FieldRef), GetOptionNoErr);
    end;

    local procedure VerifyOption(OptionNo: Enum "IC Partner Reference Type")
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        SalesCrMemoLine.Init();
        SalesCrMemoLine."IC Partner Ref. Type" := OptionNo;
        CheckGetOptionNo(Format(SalesCrMemoLine."IC Partner Ref. Type"), OptionNo.AsInteger());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TableValidation_ValidateTableWithWrongOrderInPK_PackageErrorGenerated()
    var
        ConfigPackageError: Record "Config. Package Error";
        ConfigPackage: Record "Config. Package";
        ResourcePriceCode: Code[20];
    begin
        Initialize();

        GeneratePackageWithFieldFillingDependency(ConfigPackage, 1, 0, ResourcePriceCode, false);

        LibraryRapidStart.ValidatePackage(ConfigPackage, false);

        Assert.IsTrue(not ConfigPackageError.IsEmpty, NoMigrationError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TableValidation_ValidateTableWithCorrectOrderInPK_NoPackageErrors()
    var
        ConfigPackageError: Record "Config. Package Error";
        ConfigPackage: Record "Config. Package";
        ResourcePriceCode: Code[20];
    begin
        Initialize();

        GeneratePackageWithFieldFillingDependency(ConfigPackage, 0, 1, ResourcePriceCode, false);

        LibraryRapidStart.ValidatePackage(ConfigPackage, false);

        Assert.IsTrue(ConfigPackageError.IsEmpty, MigrationError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TableApplying_ApplyTableWithWrongOrderInPK_PackageErrorGenerated()
    var
        ConfigPackageError: Record "Config. Package Error";
        ConfigPackage: Record "Config. Package";
        ResourcePriceCode: Code[20];
    begin
        Initialize();

        GeneratePackageWithFieldFillingDependency(ConfigPackage, 1, 0, ResourcePriceCode, false);

        LibraryRapidStart.ApplyPackage(ConfigPackage, false);

        Assert.IsTrue(not ConfigPackageError.IsEmpty, NoMigrationError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TableApplying_ApplyTableWithCorrectOrderInPK_DataInTable()
    var
        ConfigPackage: Record "Config. Package";
        ResourcePrice: Record "Resource Price";
        ResourcePriceCode: Code[20];
    begin
        Initialize();

        GeneratePackageWithFieldFillingDependency(ConfigPackage, 0, 1, ResourcePriceCode, false);

        LibraryRapidStart.ApplyPackage(ConfigPackage, false);

        Assert.IsTrue(ResourcePrice.Get(ResourcePrice.Type::All, ResourcePriceCode, '', ''), NoDataInTableAfterApply);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TableApplying_ApplyValidTableDataWithoutFieldValidation()
    var
        ConfigPackage: Record "Config. Package";
        CustPostingGroup: Record "Customer Posting Group";
        CustPostingGroupCode: Code[20];
        GLAccountNo: Code[20];
    begin
        Initialize();

        GenerateSimplePackage(false, false, false, ConfigPackage, CustPostingGroupCode, GLAccountNo);

        LibraryRapidStart.ApplyPackage(ConfigPackage, false);

        Assert.IsTrue(CustPostingGroup.Get(CustPostingGroupCode), NoDataInTableAfterApply);
        Assert.AreEqual(
          GLAccountNo, CustPostingGroup."Receivables Account",
          StrSubstNo(DataIsInvalidAfterApply, CustPostingGroup.FieldCaption("Receivables Account")));

        CustPostingGroup.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TableApplying_ApplyInvalidTableDataWithoutFieldValidation()
    var
        ConfigPackage: Record "Config. Package";
        CustPostingGroup: Record "Customer Posting Group";
        CustPostingGroupCode: Code[20];
        GLAccountNo: Code[20];
    begin
        Initialize();

        GenerateSimplePackage(true, false, false, ConfigPackage, CustPostingGroupCode, GLAccountNo);

        LibraryRapidStart.ApplyPackage(ConfigPackage, false);

        Assert.IsTrue(CustPostingGroup.Get(CustPostingGroupCode), NoDataInTableAfterApply);
        Assert.AreEqual(
          GLAccountNo, CustPostingGroup."Receivables Account",
          StrSubstNo(DataIsInvalidAfterApply, CustPostingGroup.FieldCaption("Receivables Account")));

        CustPostingGroup.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TableApplying_ApplyTableWhenAppliedRecordExists()
    var
        ConfigPackage: Record "Config. Package";
        CustPostingGroup: Record "Customer Posting Group";
        CustPostingGroupCode: Code[20];
        GLAccountNo: Code[20];
    begin
        Initialize();

        GenerateSimplePackage(false, true, false, ConfigPackage, CustPostingGroupCode, GLAccountNo);

        CustPostingGroup.Get(CustPostingGroupCode);
        CustPostingGroup."Receivables Account" := '';
        CustPostingGroup.Modify();

        LibraryRapidStart.ApplyPackage(ConfigPackage, false);

        Assert.IsTrue(CustPostingGroup.Get(CustPostingGroupCode), NoDataInTableAfterApply);
        Assert.AreEqual(
          GLAccountNo, CustPostingGroup."Receivables Account",
          StrSubstNo(DataIsInvalidAfterApply, CustPostingGroup.FieldCaption("Receivables Account")));

        CustPostingGroup.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TableValidation_ValidateValidTableDataWithoutFieldValidation()
    var
        ConfigPackageError: Record "Config. Package Error";
        ConfigPackage: Record "Config. Package";
        CustPostingGroupCode: Code[20];
        GLAccountNo: Code[20];
    begin
        Initialize();

        GenerateSimplePackage(false, false, false, ConfigPackage, CustPostingGroupCode, GLAccountNo);

        LibraryRapidStart.ValidatePackage(ConfigPackage, false);

        ConfigPackageError.SetRange("Package Code", ConfigPackage.Code);
        Assert.IsTrue(ConfigPackageError.IsEmpty, PackageValidationError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TableValidation_ValidateInvalidTableDataWithoutFieldValidation()
    var
        ConfigPackageError: Record "Config. Package Error";
        ConfigPackage: Record "Config. Package";
        CustPostingGroupCode: Code[20];
        GLAccountNo: Code[20];
    begin
        Initialize();

        GenerateSimplePackage(true, false, false, ConfigPackage, CustPostingGroupCode, GLAccountNo);

        LibraryRapidStart.ValidatePackage(ConfigPackage, false);

        ConfigPackageError.SetRange("Package Code", ConfigPackage.Code);
        Assert.IsTrue(ConfigPackageError.IsEmpty, PackageValidationError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TableValidation_ValidateTableWhenValidatedRecordExists()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageError: Record "Config. Package Error";
        ResourcePriceCode: Code[20];
    begin
        // Verify that ValidatePackage works correctly when a record being validated exists in DB

        Initialize();

        GeneratePackageWithFieldFillingDependency(ConfigPackage, 0, 1, ResourcePriceCode, true);

        LibraryRapidStart.ValidatePackage(ConfigPackage, false);

        ConfigPackageError.SetRange("Package Code", ConfigPackage.Code);
        Assert.IsTrue(ConfigPackageError.IsEmpty, PackageValidationError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TableValidation_ValidateMultipleErrorsCreated()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageData: Record "Config. Package Data";
        ConfigPackageError: Record "Config. Package Error";
        CustPostingGroup: Record "Customer Posting Group";
        CustPostingGroupCode: Code[20];
        GLAccountNo: Code[20];
    begin
        // Verify that a package error is created for every invalid fata entry when a single package line contains more than one error

        Initialize();

        // The package is created with one error in data
        GenerateSimplePackage(
          true,// Generate package with invalid G/L Account code
          false,// Do not save package record
          true,// Validate package fields
          ConfigPackage,// Resulting package
          CustPostingGroupCode,// Code of customer posting group loaded to package
          GLAccountNo); // G/L Account No. used in package

        // Invalidate one more field
        SetPackageFieldValue(
          ConfigPackage.Code, DATABASE::"Customer Posting Group", 1, CustPostingGroup.FieldNo("Service Charge Acc."), GLAccountNo);

        LibraryRapidStart.ValidatePackage(ConfigPackage, false);

        // Make sure that two errors have been created
        ConfigPackageError.SetRange("Package Code", ConfigPackage.Code);
        Assert.AreEqual(2, ConfigPackageError.Count, PackageValidationError);

        ConfigPackageData.Get(ConfigPackage.Code, DATABASE::"Customer Posting Group", 1, CustPostingGroup.FieldNo("Receivables Account"));
        Assert.IsTrue(ConfigPackageData.Invalid, InvalidDataExpected);

        ConfigPackageData.Get(ConfigPackage.Code, DATABASE::"Customer Posting Group", 1, CustPostingGroup.FieldNo("Service Charge Acc."));
        Assert.IsTrue(ConfigPackageData.Invalid, InvalidDataExpected);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TableValidation_CorrectPackageErrorAfterValidation()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageData: Record "Config. Package Data";
        ConfigPackageError: Record "Config. Package Error";
        CustPostingGroup: Record "Customer Posting Group";
        GLAccount: Record "G/L Account";
        CustPostingGroupCode: Code[20];
        GLAccountNo: Code[20];
    begin
        // Verify that a package error is deleted when the invalid record is corrected

        Initialize();

        GenerateSimplePackage(
          true,// Generate package with invalid G/L Account code
          false,// Do not save package record
          true,// Validate package fields
          ConfigPackage,// Resulting package
          CustPostingGroupCode,// Code of customer posting group loaded to package
          GLAccountNo); // G/L Account No. used in package

        LibraryRapidStart.ValidatePackage(ConfigPackage, false);

        // Make sure that the error is created
        ConfigPackageError.SetRange("Package Code", ConfigPackage.Code);
        Assert.AreEqual(1, ConfigPackageError.Count, PackageValidationError);

        ConfigPackageData.Get(ConfigPackage.Code, DATABASE::"Customer Posting Group", 1, CustPostingGroup.FieldNo("Receivables Account"));
        Assert.IsTrue(ConfigPackageData.Invalid, InvalidDataExpected);

        // Now, fix it
        LibraryERM.FindGLAccount(GLAccount);
        SetPackageFieldValue(
          ConfigPackage.Code, DATABASE::"Customer Posting Group", 1, CustPostingGroup.FieldNo("Receivables Account"), GLAccount."No.");
        LibraryRapidStart.ValidatePackage(ConfigPackage, false);

        ConfigPackageError.SetRange("Package Code", ConfigPackage.Code);
        Assert.IsTrue(ConfigPackageError.IsEmpty, PackageValidationError);

        ConfigPackageData.Get(ConfigPackage.Code, DATABASE::"Customer Posting Group", 1, CustPostingGroup.FieldNo("Receivables Account"));
        Assert.IsFalse(ConfigPackageData.Invalid, PackageValidationError);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ConfigPackageRecordsHandler(var ConfigPackageRecords: TestPage "Config. Package Records")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.FindGLAccount(GLAccount);

        ConfigPackageRecords.First();
        ConfigPackageRecords.Field2.SetValue(GLAccount."No.");

        Assert.IsFalse(ConfigPackageRecords.First(), StrSubstNo(ListMustBeEmpty, ConfigPackageRecords.Caption));
    end;

    [Test]
    [HandlerFunctions('ConfigPackageRecordsHandler')]
    [Scope('OnPrem')]
    procedure PageValidation_CorrectPackageErrorFromPage()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageData: Record "Config. Package Data";
        CustomerPostingGroup: Record "Customer Posting Group";
        ConfigPackageCard: TestPage "Config. Package Card";
        CustPostingGroupCode: Code[20];
        GLAccountNo: Code[20];
    begin
        // Verify that a package error can be corrected from "Config. Package Records" page

        Initialize();

        GenerateSimplePackage(
          true,// Generate package with invalid G/L Account code
          false,// Do not save package record
          true,// Validate package fields
          ConfigPackage,// Resulting package
          CustPostingGroupCode,// Code of customer posting group loaded to package
          GLAccountNo); // G/L Account No. used in package

        LibraryRapidStart.ValidatePackage(ConfigPackage, false);

        ConfigPackageData.SetRange("Package Code", ConfigPackage.Code);
        ConfigPackageData.SetRange("Field ID", CustomerPostingGroup.FieldNo("Receivables Account"));
        ConfigPackageData.SetRange(Invalid, false);
        Assert.IsTrue(ConfigPackageData.IsEmpty, InvalidDataExpected);

        ConfigPackageCard.OpenView();
        ConfigPackageCard.GotoRecord(ConfigPackage);
        ConfigPackageCard.Control10.GotoKey(ConfigPackage.Code, DATABASE::"Customer Posting Group");

        ConfigPackageCard.Control10.PackageErrors.Invoke();

        ConfigPackageData.Get(
          ConfigPackage.Code, DATABASE::"Customer Posting Group", 1, CustomerPostingGroup.FieldNo("Receivables Account"));
        Assert.IsFalse(ConfigPackageData.Invalid, PackageValidationError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OptionNoExistsUT_NonIntegerValue_False()
    begin
        CheckOptionNoExists('A', false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OptionNoExistsUT_NegativeValue_False()
    begin
        CheckOptionNoExists('-1', false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OptionNoExistsUT_ZeroValue_True()
    begin
        CheckOptionNoExists('0', true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OptionNoExistsUT_BetweenZeroAndMaxOptionNo_True()
    begin
        CheckOptionNoExists('2', true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OptionNoExistsUT_MaxOptionNo_True()
    begin
        CheckOptionNoExists('5', true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OptionNoExistsUT_MoreThanMax_False()
    begin
        CheckOptionNoExists('333', false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetOptionNoUT_NonOptionSubstring_NoOption()
    begin
        CheckGetOptionNo(Format(CreateGuid()), -1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetOptionNoUT_OptionSubstringNotEqualToOption_NoOption()
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        SalesCrMemoLine."IC Partner Ref. Type" := SalesCrMemoLine."IC Partner Ref. Type"::Item;
        CheckGetOptionNo(
          CopyStr(
            Format(SalesCrMemoLine."IC Partner Ref. Type"), 1,
            StrLen(Format(SalesCrMemoLine."IC Partner Ref. Type")) / 2), -1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetOptionNoUT_EmptySubstringAndEmptyOptionExists_NoFound()
    begin
        CheckGetOptionNo('', 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetOptionNoUT_FirstOption_OptionFound()
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        VerifyOption(SalesCrMemoLine."IC Partner Ref. Type"::" ");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetOptionNoUT_MiddleOption_OptionFound()
    begin
        VerifyOption("IC Partner Reference Type"::"Charge (Item)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetOptionNoUT_LastOption_OptionFound()
    begin
        VerifyOption("IC Partner Reference Type"::"Common Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TableApplying_ApplyTableDataWithCurrency()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        GenJnlLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        RecRef: RecordRef;
        CurrencyCode: Code[10];
    begin
        // Create Config. Package Record (Gen. Jnl Line with Currency)
        // Check no package errors exist after Package Application
        Initialize();

        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(
            WorkDate() - LibraryRandom.RandInt(365),
            LibraryRandom.RandDec(2, 2),
            LibraryRandom.RandDec(2, 2));
        LibrarySales.CreateCustomer(Customer);
        Customer."Currency Code" := CurrencyCode;
        Customer.Modify(true);
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        LibraryRapidStart.CreatePackageDataForField(
          ConfigPackage,
          ConfigPackageTable,
          DATABASE::"Gen. Journal Line",
          GenJnlLine.FieldNo("Journal Template Name"),
          GenJournalTemplate.Name,
          SingleEntryRecNo);

        RecRef.GetTable(GenJnlLine);
        LibraryRapidStart.CreatePackageDataForField(
          ConfigPackage,
          ConfigPackageTable,
          DATABASE::"Gen. Journal Line",
          GenJnlLine.FieldNo("Line No."),
          Format(LibraryUtility.GetNewLineNo(RecRef, GenJnlLine.FieldNo("Line No."))),
          SingleEntryRecNo);

        LibraryRapidStart.CreatePackageDataForField(
          ConfigPackage,
          ConfigPackageTable,
          DATABASE::"Gen. Journal Line",
          GenJnlLine.FieldNo("Account Type"),
          Format(GenJnlLine."Account Type"::Customer),
          SingleEntryRecNo);

        LibraryRapidStart.CreatePackageDataForField(
          ConfigPackage,
          ConfigPackageTable,
          DATABASE::"Gen. Journal Line",
          GenJnlLine.FieldNo("Account No."),
          Customer."No.",
          SingleEntryRecNo);

        LibraryRapidStart.CreatePackageDataForField(
          ConfigPackage,
          ConfigPackageTable,
          DATABASE::"Gen. Journal Line",
          GenJnlLine.FieldNo("Posting Date"),
          Format(WorkDate()),
          SingleEntryRecNo);

        LibraryRapidStart.CreatePackageDataForField(
          ConfigPackage,
          ConfigPackageTable,
          DATABASE::"Gen. Journal Line",
          GenJnlLine.FieldNo("Currency Code"),
          CurrencyCode,
          SingleEntryRecNo);

        LibraryRapidStart.CreatePackageDataForField(
          ConfigPackage,
          ConfigPackageTable,
          DATABASE::"Gen. Journal Line",
          GenJnlLine.FieldNo(Amount),
          Format(LibraryRandom.RandDecInRange(1, 1000, 2)),
          SingleEntryRecNo);

        LibraryRapidStart.CreatePackageDataForField(
          ConfigPackage,
          ConfigPackageTable,
          DATABASE::"Gen. Journal Line",
          GenJnlLine.FieldNo("Journal Batch Name"),
          GenJournalBatch.Name,
          SingleEntryRecNo);

        LibraryRapidStart.ApplyPackage(ConfigPackage, false);

        ConfigPackageTable.Get(ConfigPackage.Code, DATABASE::"Gen. Journal Line");
        ConfigPackageTable.CalcFields("No. of Package Errors");

        // Validate
        Assert.AreEqual(0, ConfigPackageTable."No. of Package Errors", ConfigPackContErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_SalesPriceTableProcessingOrder()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
    begin
        // [FEATURE] [Sales Price] [UT]
        // [SCENARIO 375680] Field included in primary key should have higher Processing Order in configuration package

        // [GIVEN] Configuration package
        Initialize();
        LibraryRapidStart.CreatePackage(ConfigPackage);

        // [WHEN] Add table "Sales Price" in configuration package
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Sales Price");

        // [THEN] Key field "Sales Type" with ID = "13" has "Processing Order" = 2
        VerifyProcessingOrder(ConfigPackage.Code, ConfigPackageTable."Table ID", 13, 2);
    end;

    local procedure VerifyProcessingOrder(PackageCode: Code[20]; TableID: Integer; FieldID: Integer; ProcessingOrder: Integer)
    var
        ConfigPackageField: Record "Config. Package Field";
    begin
        ConfigPackageField.Get(PackageCode, TableID, FieldID);
        ConfigPackageField.TestField("Processing Order", ProcessingOrder);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyPackageValidationEnumField()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        StockkeepingUnit: Record "Stockkeeping Unit";
        Location: Record Location;
        ReorderingPolicy: Enum "Reordering Policy";
        ItemNo: Code[20];
    begin
        // [SCENARIO 371872] Validation of Enum field when applying package
        Initialize();

        ItemNo := LibraryInventory.CreateItemNo();
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Config. Package with Stockkeeping Unit record
        LibraryRapidStart.CreatePackageDataForField(
          ConfigPackage,
          ConfigPackageTable,
          DATABASE::"Stockkeeping Unit",
          StockkeepingUnit.FieldNo("Location Code"),
          Location.Code,
          SingleEntryRecNo);

        LibraryRapidStart.CreatePackageDataForField(
          ConfigPackage,
          ConfigPackageTable,
          DATABASE::"Stockkeeping Unit",
          StockkeepingUnit.FieldNo("Item No."),
          ItemNo,
          SingleEntryRecNo);

        LibraryRapidStart.CreatePackageDataForField(
          ConfigPackage,
          ConfigPackageTable,
          DATABASE::"Stockkeeping Unit",
          StockkeepingUnit.FieldNo("Variant Code"),
          '',
          SingleEntryRecNo);

        // [GIVEN] Config. Package record "Reordering Policy" = "Maximum Qty."
        LibraryRapidStart.CreatePackageDataForField(
          ConfigPackage,
          ConfigPackageTable,
          DATABASE::"Stockkeeping Unit",
          StockkeepingUnit.FieldNo("Reordering Policy"),
          FORMAT(ReorderingPolicy::"Maximum Qty."),
          SingleEntryRecNo);

        // [WHEN] Package is applied
        LibraryRapidStart.ApplyPackage(ConfigPackage, false);

        // [THEN] Created Stockkeeping unit has "Include Inventory" = True;
        // "Reordering Policy" was validated
        ConfigPackageTable.Get(ConfigPackage.Code, DATABASE::"Stockkeeping Unit");
        StockkeepingUnit.GET(Location.Code, ItemNo, '');
        Assert.IsTrue(StockkeepingUnit."Include Inventory", 'Wrong field value');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_ConfigValidateManagement_GetOptionNo_NoFieldRefModification()
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        OptionNo: Integer;
    begin
        // [SCENARIO 371872] UT checks codeunit ConfigValidateManagement method does not modify FieldRef

        // [GIVEN] FieldRef points to enum field with value " "
        RecordRef.Open(Database::"Stockkeeping Unit");
        FieldRef := RecordRef.Field(StockkeepingUnit.FieldNo("Reordering Policy"));
        Assert.AreEqual(' ', Format(FieldRef.Value), 'Wrong FieldRef value');

        // [WHEN] GetOptionNo is invoked for FieldRef with value 'Maximum Qty.'
        OptionNo := ConfigValidateManagement.GetOptionNo('Maximum Qty.', FieldRef);

        // [THEN] Returned value is 2 and is equal to number in sequence
        Assert.AreEqual(2, OptionNo, 'Wrong value returned');

        // [THEN] FieldRef value is not changed and is equal to ' '
        Assert.AreEqual(' ', Format(FieldRef.Value), 'Wrong FieldRef value');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyConfigPackagePostCodeRecord()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        PostCode: Record "Post Code";
        CountryRegionCode: Code[10];
    begin
        // [SCENARIO 411676] Configuration Package should correctly apply Post Code record
        Initialize();

        // [GIVEN] Post Code record with "Country/Region Code" = ''
        LibraryERM.CreatePostCode(PostCode);
        CountryRegionCode := PostCode."Country/Region Code";
        PostCode."Country/Region Code" := '';
        PostCode.Modify();

        // [GIVEN] Config. Package with Post Code record, "Country/Region Code" = 'BE'
        LibraryRapidStart.CreatePackageDataForField(
          ConfigPackage,
          ConfigPackageTable,
          DATABASE::"Post Code",
          PostCode.FieldNo(Code),
          PostCode.Code,
          SingleEntryRecNo);

        LibraryRapidStart.CreatePackageDataForField(
          ConfigPackage,
          ConfigPackageTable,
          DATABASE::"Post Code",
          PostCode.FieldNo(City),
          PostCode.City,
          SingleEntryRecNo);

        LibraryRapidStart.CreatePackageDataForField(
          ConfigPackage,
          ConfigPackageTable,
          DATABASE::"Post Code",
          PostCode.FieldNo("Country/Region Code"),
          CountryRegionCode,
          SingleEntryRecNo);

        // [WHEN] Package is applied
        LibraryRapidStart.ApplyPackage(ConfigPackage, false);

        // [THEN] Configuration Package "No. of Package Errors" = 0
        ConfigPackageTable.Get(ConfigPackage.Code, DATABASE::"Post Code");
        ConfigPackageTable.CalcFields("No. of Package Errors");
        ConfigPackageTable.TestField("No. of Package Errors", 0);

        // [THEN] Post Code record is updated, "Country/Region Code" = 'BE'
        PostCode.GET(PostCode.Code, PostCode.City);
        PostCode.TestField("Country/Region Code", CountryRegionCode);
    end;

    [Test]
    procedure ItemUnitOfMeasureWeightUpdatedViaConfigPackage()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageRecord: Record "Config. Package Record";
        ConfigPackageTable: Record "Config. Package Table";
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        UnitOfMeasure: Record "Unit of Measure";
        ItemNo: Code[20];
        NetWeight: Decimal;
    begin
        // [SCENARIO 616529] Item Unit of Measure weight is updated when Net Weight is set via Configuration Package after Base Unit of Measure.
        Initialize();

        // [GIVEN] A new item number and unit of measure.
        ItemNo := LibraryInventory.CreateItemNo();
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        NetWeight := LibraryRandom.RandDecInRange(1, 100, 2);

        // [GIVEN] A configuration package for Item table with fields in specific order.
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::Item);

        // [GIVEN] Configure fields to be included: No., Base Unit of Measure (applied first), Net Weight (applied second).
        SetupItemConfigPackageFields(ConfigPackage.Code, ConfigPackageTable."Table ID");

        // [GIVEN] Package data: No. = ItemNo, Base Unit of Measure = UOM Code, Net Weight = 10.
        LibraryRapidStart.CreatePackageRecord(ConfigPackageRecord, ConfigPackageTable."Package Code", ConfigPackageTable."Table ID", 1);
        LibraryRapidStart.CreatePackageFieldData(ConfigPackageRecord, Item.FieldNo("No."), ItemNo);
        LibraryRapidStart.CreatePackageFieldData(ConfigPackageRecord, Item.FieldNo("Base Unit of Measure"), UnitOfMeasure.Code);
        LibraryRapidStart.CreatePackageFieldData(ConfigPackageRecord, Item.FieldNo("Net Weight"), Format(NetWeight));

        // [WHEN] Apply the configuration package.
        LibraryRapidStart.ApplyPackage(ConfigPackage, false);

        // [THEN] Verify Item Unit of Measure is created with the correct weight.
        ItemUnitOfMeasure.Get(ItemNo, UnitOfMeasure.Code);
        Assert.AreEqual(ItemUnitOfMeasure.Weight, NetWeight, ItemUOMWeightErr);
    end;

    [Test]
    procedure ValidateAndApplyGLAccountCommentPackage()
    begin
        // [SCENARIO 651132] G/L account comments require an existing G/L account.
        VerifyCommentParentRelation("Comment Line Table Name"::"G/L Account", Database::"G/L Account");
    end;

    [Test]
    procedure ValidateAndApplyCustomerCommentPackage()
    begin
        // [SCENARIO 651132] Customer comments require an existing customer.
        VerifyCommentParentRelation("Comment Line Table Name"::Customer, Database::Customer);
    end;

    [Test]
    procedure ValidateAndApplyVendorCommentPackage()
    begin
        // [SCENARIO 651132] Vendor comments require an existing vendor.
        VerifyCommentParentRelation("Comment Line Table Name"::Vendor, Database::Vendor);
    end;

    [Test]
    procedure ValidateAndApplyItemCommentPackage()
    begin
        // [SCENARIO 651132] Item comments require an existing item.
        VerifyCommentParentRelation("Comment Line Table Name"::Item, Database::Item);
    end;

    [Test]
    procedure ValidateAndApplyResourceCommentPackage()
    begin
        // [SCENARIO 651132] Resource comments require an existing resource.
        VerifyCommentParentRelation("Comment Line Table Name"::Resource, Database::Resource);
    end;

    [Test]
    procedure ValidateAndApplyJobCommentPackage()
    begin
        // [SCENARIO 651132] Project comments require an existing project.
        VerifyCommentParentRelation("Comment Line Table Name"::Job, Database::Job);
    end;

    [Test]
    procedure ValidateAndApplyResourceGroupCommentPackage()
    begin
        // [SCENARIO 651132] Resource group comments require an existing resource group.
        VerifyCommentParentRelation("Comment Line Table Name"::"Resource Group", Database::"Resource Group");
    end;

    [Test]
    procedure ValidateAndApplyBankAccountCommentPackage()
    begin
        // [SCENARIO 651132] Bank account comments require an existing bank account.
        VerifyCommentParentRelation("Comment Line Table Name"::"Bank Account", Database::"Bank Account");
    end;

    [Test]
    procedure ValidateAndApplyCampaignCommentPackage()
    begin
        // [SCENARIO 651132] Campaign comments require an existing campaign.
        VerifyCommentParentRelation("Comment Line Table Name"::Campaign, Database::Campaign);
    end;

    [Test]
    procedure ValidateAndApplyFixedAssetCommentPackage()
    begin
        // [SCENARIO 651132] Fixed asset comments require an existing fixed asset.
        VerifyCommentParentRelation("Comment Line Table Name"::"Fixed Asset", Database::"Fixed Asset");
    end;

    [Test]
    procedure ValidateAndApplyInsuranceCommentPackage()
    begin
        // [SCENARIO 651132] Insurance comments require an existing insurance record.
        VerifyCommentParentRelation("Comment Line Table Name"::Insurance, Database::Insurance);
    end;

    [Test]
    procedure ValidateAndApplyICPartnerCommentPackage()
    begin
        // [SCENARIO 651132] Intercompany partner comments require an existing intercompany partner.
        VerifyCommentParentRelation("Comment Line Table Name"::"IC Partner", Database::"IC Partner");
    end;

    [Test]
    procedure CustomerCommentRequiresCustomerNotItem()
    var
        CommentLine: Record "Comment Line";
        ConfigPackage: Record "Config. Package";
        Customer: Record Customer;
        Item: Record Item;
    begin
        // [SCENARIO 651132] An existing item does not satisfy the parent relation of a customer comment.
        Initialize();
        LibraryInventory.CreateItem(Item);
        Assert.IsFalse(Customer.Get(Item."No."), 'The item number must not identify a customer.');
        CreateCommentPackage(ConfigPackage, CommentLine."Table Name"::Customer, Item."No.", true);

        LibraryRapidStart.ValidatePackage(ConfigPackage, true);

        VerifyCommentPackageError(ConfigPackage.Code, Item."No.", Customer.TableCaption());
        Assert.IsFalse(CommentLine.Get(CommentLine."Table Name"::Customer, Item."No.", 10000), 'An item must not validate a customer comment.');
    end;

    [Test]
    procedure ApplyCommentPackageWithoutNoValidation()
    var
        CommentLine: Record "Comment Line";
        ConfigPackage: Record "Config. Package";
        Item: Record Item;
        ItemNo: Code[20];
    begin
        // [SCENARIO 651132] Disabling No. validation retains the existing import behavior.
        Initialize();
        ItemNo := LibraryUtility.GenerateRandomCode20(Item.FieldNo("No."), Database::Item);
        CreateCommentPackage(ConfigPackage, CommentLine."Table Name"::Item, ItemNo, false);

        LibraryRapidStart.ValidatePackage(ConfigPackage, true);
        VerifyCommentPackageHasNoErrors(ConfigPackage.Code);
        LibraryRapidStart.ApplyPackage(ConfigPackage, true);

        VerifyCommentPackageHasNoErrors(ConfigPackage.Code);
        CommentLine.Get(CommentLine."Table Name"::Item, ItemNo, 10000);
        CommentLine.TestField(Comment, ConfigPackage.Code);
    end;

    [Test]
    procedure ApplyCommentPackageWithBlankItemNo()
    var
        CommentLine: Record "Comment Line";
        ConfigPackage: Record "Config. Package";
    begin
        // [SCENARIO 651132] The item relation does not introduce a mandatory No. requirement.
        Initialize();
        CreateCommentPackage(ConfigPackage, CommentLine."Table Name"::Item, '', true);

        LibraryRapidStart.ValidatePackage(ConfigPackage, true);
        VerifyCommentPackageHasNoErrors(ConfigPackage.Code);
        LibraryRapidStart.ApplyPackage(ConfigPackage, true);

        VerifyCommentPackageHasNoErrors(ConfigPackage.Code);
        CommentLine.Get(CommentLine."Table Name"::Item, '', 10000);
        CommentLine.TestField(Comment, ConfigPackage.Code);
    end;

    [Test]
    procedure ApplyCommentPackageForTypesWithoutHistoricalRelation()
    var
        CommentLine: Record "Comment Line";
        ConfigPackage: Record "Config. Package";
        Item: Record Item;
        ParentNo: Code[20];
    begin
        // [SCENARIO 651132] Types absent from the original relation do not acquire a new parent check.
        Initialize();
        ParentNo := LibraryUtility.GenerateRandomCode20(Item.FieldNo("No."), Database::Item);
        CreateCommentPackage(ConfigPackage, CommentLine."Table Name"::"Nonstock Item", ParentNo, true);
        AddCommentPackageRecord(ConfigPackage.Code, 2, CommentLine."Table Name"::"Vendor Agreement", ParentNo);
        AddCommentPackageRecord(ConfigPackage.Code, 3, CommentLine."Table Name"::"Customer Agreement", ParentNo);

        LibraryRapidStart.ValidatePackage(ConfigPackage, true);
        VerifyCommentPackageHasNoErrors(ConfigPackage.Code);
        LibraryRapidStart.ApplyPackage(ConfigPackage, true);

        VerifyCommentPackageHasNoErrors(ConfigPackage.Code);
        CommentLine.Get(CommentLine."Table Name"::"Nonstock Item", ParentNo, 10000);
        CommentLine.TestField(Comment, ConfigPackage.Code);
        CommentLine.Get(CommentLine."Table Name"::"Vendor Agreement", ParentNo, 10000);
        CommentLine.TestField(Comment, ConfigPackage.Code);
        CommentLine.Get(CommentLine."Table Name"::"Customer Agreement", ParentNo, 10000);
        CommentLine.TestField(Comment, ConfigPackage.Code);
    end;

    [Test]
    procedure ApplyItemAndMixedCommentsInSamePackage()
    var
        CommentLine: Record "Comment Line";
        ConfigPackage: Record "Config. Package";
        Customer: Record Customer;
        Item: Record Item;
        ItemNo: Code[20];
    begin
        // [SCENARIO 651132] An item can be imported with item and customer comments sharing its number.
        Initialize();
        LibraryInventory.CreateItem(Item);
        ItemNo := Item."No.";
        Item.Delete(true);
        LibrarySales.CreateCustomer(Customer);
        Customer.Rename(ItemNo);
        CreateCommentPackage(ConfigPackage, CommentLine."Table Name"::Item, ItemNo, true);
        AddCommentPackageRecord(ConfigPackage.Code, 2, CommentLine."Table Name"::Customer, ItemNo);
        AddCommentParentPackageRecord(ConfigPackage.Code, Database::Item, ItemNo);

        LibraryRapidStart.ValidatePackage(ConfigPackage, true);
        VerifyCommentPackageHasNoErrors(ConfigPackage.Code);
        LibraryRapidStart.ApplyPackage(ConfigPackage, true);

        VerifyCommentPackageHasNoErrors(ConfigPackage.Code);
        Item.Get(ItemNo);
        CommentLine.Get(CommentLine."Table Name"::Item, ItemNo, 10000);
        CommentLine.TestField(Comment, ConfigPackage.Code);
        CommentLine.Get(CommentLine."Table Name"::Customer, ItemNo, 10000);
        CommentLine.TestField(Comment, ConfigPackage.Code);
    end;

    [Test]
    procedure ApplyBankAccountAndCommentInSamePackage()
    begin
        // [SCENARIO 651132] A conditional parent with a higher table ID is imported before its comments.
        VerifyParentAndCommentInSamePackage("Comment Line Table Name"::"Bank Account", Database::"Bank Account");
    end;

    [Test]
    procedure ApplyJobAndCommentInSamePackage()
    begin
        // [SCENARIO 651132] Comments follow the final, adjusted processing order of their project.
        VerifyParentAndCommentInSamePackage("Comment Line Table Name"::Job, Database::Job);
    end;

    [Test]
    procedure PendingItemDoesNotValidateCustomerComment()
    var
        CommentLine: Record "Comment Line";
        ConfigPackage: Record "Config. Package";
        Customer: Record Customer;
        Item: Record Item;
        ItemNo: Code[20];
    begin
        // [SCENARIO 651132] A same-number parent in the package must match the comment's table type.
        Initialize();
        LibraryInventory.CreateItem(Item);
        ItemNo := Item."No.";
        Item.Delete(true);
        Assert.IsFalse(Customer.Get(ItemNo), 'The item number must not identify a customer.');
        CreateCommentPackage(ConfigPackage, CommentLine."Table Name"::Customer, ItemNo, true);
        AddCommentParentPackageRecord(ConfigPackage.Code, Database::Item, ItemNo);

        LibraryRapidStart.ValidatePackage(ConfigPackage, true);

        VerifyCommentPackageError(ConfigPackage.Code, ItemNo, Customer.TableCaption());
    end;

    [Test]
    procedure CommentBeforePendingParentFailsValidation()
    var
        BankAccount: Record "Bank Account";
        CommentLine: Record "Comment Line";
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ParentNo: Code[20];
    begin
        // [SCENARIO 651132] Package data must not bypass an explicitly incorrect parent/child processing order.
        Initialize();
        ParentNo := CreatePendingCommentParentPackage(ConfigPackage, CommentLine."Table Name"::"Bank Account", Database::"Bank Account");
        ConfigPackageTable.Get(ConfigPackage.Code, Database::"Comment Line");
        ConfigPackageTable."Processing Order" := 1;
        ConfigPackageTable.Modify();
        ConfigPackageTable.Get(ConfigPackage.Code, Database::"Bank Account");
        ConfigPackageTable."Processing Order" := 2;
        ConfigPackageTable.Modify();

        LibraryRapidStart.ValidatePackage(ConfigPackage, false);
        VerifyCommentPackageError(ConfigPackage.Code, ParentNo, BankAccount.TableCaption());

        LibraryRapidStart.ValidatePackage(ConfigPackage, true);
        VerifyCommentPackageHasNoErrors(ConfigPackage.Code);
    end;

    [Test]
    procedure RenameItemWithImportedComment()
    var
        CommentLine: Record "Comment Line";
        ConfigPackage: Record "Config. Package";
        Customer: Record Customer;
        Item: Record Item;
        OldItemNo: Code[20];
        NewItemNo: Code[20];
    begin
        // [SCENARIO 651132] Renaming an item preserves its comments without renaming customer comments.
        Initialize();
        LibraryInventory.CreateItem(Item);
        OldItemNo := Item."No.";
        NewItemNo := LibraryUtility.GenerateRandomCode20(Item.FieldNo("No."), Database::Item);
        LibrarySales.CreateCustomer(Customer);
        Customer.Rename(OldItemNo);
        CreateCommentPackage(ConfigPackage, CommentLine."Table Name"::Item, OldItemNo, true);
        AddCommentPackageRecord(ConfigPackage.Code, 2, CommentLine."Table Name"::Customer, OldItemNo);
        LibraryRapidStart.ApplyPackage(ConfigPackage, true);
        VerifyCommentPackageHasNoErrors(ConfigPackage.Code);

        Item.Get(OldItemNo);
        Item.Rename(NewItemNo);

        Assert.IsFalse(CommentLine.Get(CommentLine."Table Name"::Item, OldItemNo, 10000), 'The old item comment key must not remain.');
        CommentLine.Get(CommentLine."Table Name"::Item, NewItemNo, 10000);
        CommentLine.TestField(Comment, ConfigPackage.Code);
        CommentLine.Get(CommentLine."Table Name"::Customer, OldItemNo, 10000);
        CommentLine.TestField(Comment, ConfigPackage.Code);
        Assert.IsFalse(CommentLine.Get(CommentLine."Table Name"::Customer, NewItemNo, 10000), 'A customer comment must not follow an item rename.');
    end;

    local procedure VerifyCommentParentRelation(TableName: Enum "Comment Line Table Name"; ParentTableID: Integer)
    var
        CommentLine: Record "Comment Line";
        ConfigPackage: Record "Config. Package";
        ParentRecRef: RecordRef;
        ParentFieldRef: FieldRef;
        ParentNo: Code[20];
    begin
        Initialize();
        ParentRecRef.Open(ParentTableID);
        ParentFieldRef := ParentRecRef.Field(1);
        ParentNo := LibraryUtility.GenerateRandomCode20(ParentFieldRef.Number, ParentTableID);

        CreateCommentPackage(ConfigPackage, TableName, ParentNo, true);
        LibraryRapidStart.ValidatePackage(ConfigPackage, true);
        VerifyCommentPackageError(ConfigPackage.Code, ParentNo, ParentRecRef.Caption);
        Assert.IsFalse(CommentLine.Get(TableName, ParentNo, 10000), 'Validation must not insert a comment.');

        CreateCommentPackage(ConfigPackage, TableName, ParentNo, true);
        LibraryRapidStart.ApplyPackage(ConfigPackage, true);
        VerifyCommentPackageError(ConfigPackage.Code, ParentNo, ParentRecRef.Caption);
        Assert.IsFalse(CommentLine.Get(TableName, ParentNo, 10000), 'An orphan comment must not be inserted.');

        ParentRecRef.Close();
        ParentNo := CreateCommentParent(TableName);

        CreateCommentPackage(ConfigPackage, TableName, ParentNo, true);
        LibraryRapidStart.ValidatePackage(ConfigPackage, true);
        VerifyCommentPackageHasNoErrors(ConfigPackage.Code);
        LibraryRapidStart.ApplyPackage(ConfigPackage, true);

        VerifyCommentPackageHasNoErrors(ConfigPackage.Code);
        CommentLine.Get(TableName, ParentNo, 10000);
        CommentLine.TestField(Comment, ConfigPackage.Code);
    end;

    local procedure CreateCommentParent(TableName: Enum "Comment Line Table Name"): Code[20]
    var
        GLAccount: Record "G/L Account";
        Customer: Record Customer;
        Vendor: Record Vendor;
        Item: Record Item;
        Resource: Record Resource;
        Job: Record Job;
        ResourceGroup: Record "Resource Group";
        BankAccount: Record "Bank Account";
        Campaign: Record Campaign;
        FixedAsset: Record "Fixed Asset";
        Insurance: Record Insurance;
        ICPartner: Record "IC Partner";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryResource: Codeunit "Library - Resource";
        LibraryJob: Codeunit "Library - Job";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
    begin
        case TableName of
            TableName::"G/L Account":
                begin
                    LibraryERM.CreateGLAccount(GLAccount);
                    exit(GLAccount."No.");
                end;
            TableName::Customer:
                begin
                    LibrarySales.CreateCustomer(Customer);
                    exit(Customer."No.");
                end;
            TableName::Vendor:
                begin
                    LibraryPurchase.CreateVendor(Vendor);
                    exit(Vendor."No.");
                end;
            TableName::Item:
                begin
                    LibraryInventory.CreateItem(Item);
                    exit(Item."No.");
                end;
            TableName::Resource:
                begin
                    LibraryResource.CreateResourceNew(Resource);
                    exit(Resource."No.");
                end;
            TableName::Job:
                begin
                    LibraryJob.CreateJob(Job);
                    exit(Job."No.");
                end;
            TableName::"Resource Group":
                begin
                    LibraryResource.CreateResourceGroup(ResourceGroup);
                    exit(ResourceGroup."No.");
                end;
            TableName::"Bank Account":
                begin
                    LibraryERM.CreateBankAccount(BankAccount);
                    exit(BankAccount."No.");
                end;
            TableName::Campaign:
                begin
                    LibraryMarketing.CreateCampaign(Campaign);
                    exit(Campaign."No.");
                end;
            TableName::"Fixed Asset":
                begin
                    LibraryFixedAsset.CreateFixedAsset(FixedAsset);
                    exit(FixedAsset."No.");
                end;
            TableName::Insurance:
                begin
                    LibraryFixedAsset.CreateInsurance(Insurance);
                    exit(Insurance."No.");
                end;
            TableName::"IC Partner":
                begin
                    LibraryERM.CreateICPartner(ICPartner);
                    exit(ICPartner.Code);
                end;
            else
                Assert.Fail(StrSubstNo(UnsupportedCommentParentTypeErr, TableName));
        end;
    end;

    local procedure VerifyParentAndCommentInSamePackage(TableName: Enum "Comment Line Table Name"; ParentTableID: Integer)
    var
        CommentLine: Record "Comment Line";
        ConfigPackage: Record "Config. Package";
        ParentPackageTable: Record "Config. Package Table";
        CommentPackageTable: Record "Config. Package Table";
        ParentRecRef: RecordRef;
        ParentFieldRef: FieldRef;
        ParentNo: Code[20];
    begin
        Initialize();
        ParentNo := CreatePendingCommentParentPackage(ConfigPackage, TableName, ParentTableID);

        LibraryRapidStart.ValidatePackage(ConfigPackage, true);
        VerifyCommentPackageHasNoErrors(ConfigPackage.Code);
        ParentPackageTable.Get(ConfigPackage.Code, ParentTableID);
        CommentPackageTable.Get(ConfigPackage.Code, Database::"Comment Line");
        Assert.IsTrue(
            CommentPackageTable."Processing Order" > ParentPackageTable."Processing Order",
            'Comments must follow their parent, including any table-specific processing-order adjustment.');
        LibraryRapidStart.ApplyPackage(ConfigPackage, true);

        VerifyCommentPackageHasNoErrors(ConfigPackage.Code);
        ParentRecRef.Open(ParentTableID);
        ParentFieldRef := ParentRecRef.Field(1);
        ParentFieldRef.Value := ParentNo;
        Assert.IsTrue(ParentRecRef.Find(), 'The parent must be imported from the same package.');
        ParentRecRef.Close();
        CommentLine.Get(TableName, ParentNo, 10000);
        CommentLine.TestField(Comment, ConfigPackage.Code);
    end;

    local procedure CreatePendingCommentParentPackage(var ConfigPackage: Record "Config. Package"; TableName: Enum "Comment Line Table Name"; ParentTableID: Integer) ParentNo: Code[20]
    var
        ParentRecRef: RecordRef;
        ParentFieldRef: FieldRef;
    begin
        ParentNo := CreateCommentParent(TableName);
        ParentRecRef.Open(ParentTableID);
        ParentFieldRef := ParentRecRef.Field(1);
        ParentFieldRef.Value := ParentNo;
        ParentRecRef.Find();
        ParentRecRef.Delete(true);
        ParentRecRef.Close();
        CreateCommentPackage(ConfigPackage, TableName, ParentNo, true);
        AddCommentParentPackageRecord(ConfigPackage.Code, ParentTableID, ParentNo);
    end;

    local procedure AddCommentParentPackageRecord(PackageCode: Code[20]; ParentTableID: Integer; ParentNo: Code[20])
    var
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageRecord: Record "Config. Package Record";
    begin
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, PackageCode, ParentTableID);
        LibraryRapidStart.SetIncludeAllFields(PackageCode, ParentTableID, false);
        LibraryRapidStart.CreatePackageRecord(ConfigPackageRecord, PackageCode, ParentTableID, 1);
        LibraryRapidStart.CreatePackageFieldData(ConfigPackageRecord, 1, ParentNo);
    end;

    local procedure CreateCommentPackage(var ConfigPackage: Record "Config. Package"; TableName: Enum "Comment Line Table Name"; ParentNo: Code[20]; ValidateNo: Boolean)
    var
        CommentLine: Record "Comment Line";
        ConfigPackageTable: Record "Config. Package Table";
    begin
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, Database::"Comment Line");
        ConfigPackageTable.TestField("Skip Table Triggers", false);
        LibraryRapidStart.SetIncludeAllFields(ConfigPackage.Code, Database::"Comment Line", false);
        LibraryRapidStart.SetIncludeOneField(ConfigPackage.Code, Database::"Comment Line", CommentLine.FieldNo(Comment), true);
        LibraryRapidStart.SetValidateOneField(ConfigPackage.Code, Database::"Comment Line", CommentLine.FieldNo("No."), ValidateNo);
        AddCommentPackageRecord(ConfigPackage.Code, 1, TableName, ParentNo);
    end;

    local procedure AddCommentPackageRecord(PackageCode: Code[20]; RecordNo: Integer; TableName: Enum "Comment Line Table Name"; ParentNo: Code[20])
    var
        CommentLine: Record "Comment Line";
        ConfigPackageRecord: Record "Config. Package Record";
    begin
        LibraryRapidStart.CreatePackageRecord(ConfigPackageRecord, PackageCode, Database::"Comment Line", RecordNo);
        LibraryRapidStart.CreatePackageFieldData(ConfigPackageRecord, CommentLine.FieldNo("Table Name"), Format(TableName));
        LibraryRapidStart.CreatePackageFieldData(ConfigPackageRecord, CommentLine.FieldNo("No."), ParentNo);
        LibraryRapidStart.CreatePackageFieldData(ConfigPackageRecord, CommentLine.FieldNo("Line No."), Format(10000));
        LibraryRapidStart.CreatePackageFieldData(ConfigPackageRecord, CommentLine.FieldNo(Comment), PackageCode);
    end;

    local procedure VerifyCommentPackageError(PackageCode: Code[20]; ParentNo: Code[20]; ParentTableCaption: Text)
    var
        CommentLine: Record "Comment Line";
        ConfigPackageError: Record "Config. Package Error";
    begin
        ConfigPackageError.SetRange("Package Code", PackageCode);
        Assert.RecordCount(ConfigPackageError, 1);
        ConfigPackageError.FindFirst();
        ConfigPackageError.TestField("Table ID", Database::"Comment Line");
        ConfigPackageError.TestField("Field ID", CommentLine.FieldNo("No."));
        Assert.ExpectedMessage(ParentNo, ConfigPackageError."Error Text");
        Assert.ExpectedMessage(ParentTableCaption, ConfigPackageError."Error Text");
    end;

    local procedure VerifyCommentPackageHasNoErrors(PackageCode: Code[20])
    var
        ConfigPackageError: Record "Config. Package Error";
    begin
        ConfigPackageError.SetRange("Package Code", PackageCode);
        Assert.RecordCount(ConfigPackageError, 0);
    end;

    local procedure SetupItemConfigPackageFields(PackageCode: Code[20]; TableID: Integer)
    var
        ConfigPackageField: Record "Config. Package Field";
        Item: Record Item;
    begin
        ConfigPackageField.SetRange("Package Code", PackageCode);
        ConfigPackageField.SetRange("Table ID", TableID);
        ConfigPackageField.ModifyAll("Include Field", false);

        LibraryRapidStart.SetIncludeOneField(PackageCode, TableID, Item.FieldNo("No."), true);
        LibraryRapidStart.SetIncludeOneField(PackageCode, TableID, Item.FieldNo("Base Unit of Measure"), true);
        LibraryRapidStart.SetIncludeOneField(PackageCode, TableID, Item.FieldNo("Net Weight"), true);
    end;

}
