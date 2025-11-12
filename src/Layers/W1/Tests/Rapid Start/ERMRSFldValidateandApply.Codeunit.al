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
        LibrarySales: Codeunit "Library - Sales";
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

}
