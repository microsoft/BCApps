codeunit 136604 "ERM RS Package Dimensions"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Dimension] [Rapid Start]
        IsInitialized := false;
    end;

    var
        LibraryRapidStart: Codeunit "Library - Rapid Start";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryDim: Codeunit "Library - Dimension";
        LibrarySales: Codeunit "Library - Sales";
        ConfigPackageMgt: Codeunit "Config. Package Management";
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        DimSetLessThanExpectedError: Label 'Dimension Set ID should be more than %1 in Gen. Jnl Line 4. Current value is %2.';
        IncorrectDimSetError: Label 'Dimension Set ID is not correct.';
        LibraryRandom: Codeunit "Library - Random";
        APIMockEvents: Codeunit "API Mock Events";
        DimValueNotUpdatedErr: Label 'Dimension Set Entry was not updated on apply.';
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure ApplyJnlLineWithNewDimension()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        DimSetEntry: Record "Dimension Set Entry";
        GenJnlLine: Record "Gen. Journal Line";
        DimValue: Record "Dimension Value";
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        LastDimSetID: Integer;
        LineNo: Integer;
    begin
        Initialize();
        // Test apply of data with dimensions
        HideDialog();
        CreatePackageAndFields(ConfigPackage, ConfigPackageTable);

        // 1. Setup: Create dimension setup
        LibraryDim.CreateDimensionValue(DimValue, LibraryERM.GetShortcutDimensionCode(3));
        CreateDimSetEntryPackageData(1, LibraryERM.GetShortcutDimensionCode(3), DimValue.Code, 3, ConfigPackage.Code);

        // 2. Create Gen. Journal Lines
        LineNo := 10000;
        CreateGenJnlLines(ConfigPackage, ConfigPackageTable, LineNo, GenJnlTemplate, GenJnlBatch);

        // 3. Apply data
        LastDimSetID := 0;
        if DimSetEntry.FindLast() then
            LastDimSetID := DimSetEntry."Dimension Set ID";

        LibraryRapidStart.ApplyPackage(ConfigPackage, true);
        LibraryRapidStart.CleanUp(ConfigPackage.Code);

        // 4. Check encoded dimension set ID's
        GenJnlLine.Get(GenJnlTemplate.Name, GenJnlBatch.Name, LineNo);
        Assert.IsTrue(GenJnlLine."Dimension Set ID" >= LastDimSetID,
          StrSubstNo(DimSetLessThanExpectedError, LastDimSetID, GenJnlLine."Dimension Set ID"));

        // 5. Clean up test data
        LibraryERM.ClearGenJournalLines(GenJnlBatch);
        DimSetEntry.Reset();
        DimSetEntry.SetRange("Dimension Value Code", DimValue.Code);
        DimSetEntry.DeleteAll();
        DimValue.Delete(true);
        GenJnlBatch.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure ApplyJnlLineWithExistingDimension()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        DimSetEntry: Record "Dimension Set Entry";
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        ExistingDimSetID: Integer;
        DimNumber: Integer;
        LineNo: Integer;
    begin
        Initialize();
        // Test apply of data with dimensions
        HideDialog();

        // 1. Setup: Create dimension setup
        CreatePackageAndFields(ConfigPackage, ConfigPackageTable);

        DimNumber := 0;
        DimSetEntry.Next(LibraryRandom.RandInt(DimSetEntry.Count));
        ExistingDimSetID := DimSetEntry."Dimension Set ID";
        LibraryDim.FindDimensionSetEntry(DimSetEntry, DimSetEntry."Dimension Set ID");
        repeat
            DimNumber += 1;
            CreateDimSetEntryPackageData(1, DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code", DimNumber, ConfigPackage.Code);
        until DimSetEntry.Next() = 0;

        // 2. Create Gen. Journal Lines
        LineNo := 10000;
        CreateGenJnlLines(ConfigPackage, ConfigPackageTable, LineNo, GenJnlTemplate, GenJnlBatch);

        // 3. Apply data
        LibraryRapidStart.ApplyPackage(ConfigPackage, true);

        // 4. Check encoded dimension set ID's
        GenJnlLine.Get(GenJnlTemplate.Name, GenJnlBatch.Name, LineNo);
        Assert.AreEqual(ExistingDimSetID, GenJnlLine."Dimension Set ID", IncorrectDimSetError);

        // 5. Clean up test data
        LibraryERM.ClearGenJournalLines(GenJnlBatch);
        GenJnlBatch.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure ApplyDimSetId_ApplyWithDifferentValueCode_DataApplied()
    var
        DimensionSetEntry: Record "Dimension Set Entry";
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        NewDimSetID: Integer;
    begin
        Initialize();
        DimensionSetEntry.FindLast();
        NewDimSetID := DimensionSetEntry."Dimension Set ID" + 1;
        LibraryDim.FindDimension(Dimension);

        Clear(DimensionSetEntry);
        DimensionSetEntry."Dimension Set ID" := NewDimSetID;
        DimensionSetEntry."Dimension Code" := Dimension.Code;
        DimensionSetEntry.Insert();

        DimensionValue.SetRange("Dimension Code", Dimension.Code);
        DimensionValue.FindFirst();

        CreatePackageAndFields(ConfigPackage, ConfigPackageTable);
        CreateDimSetEntryPackageData(NewDimSetID, Dimension.Code, DimensionValue.Code, 0, ConfigPackage.Code);

        LibraryRapidStart.ApplyPackage(ConfigPackage, true);

        DimensionSetEntry.Get(NewDimSetID, Dimension.Code);
        Assert.AreEqual(DimensionValue.Code, DimensionSetEntry."Dimension Value Code", DimValueNotUpdatedErr);

        DimensionSetEntry.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyPackageToJnlLineWithoutDimension()
    var
        ConfigPackage: Record "Config. Package";
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        LineNo: Integer;
    begin
        Initialize();
        // Verify that there is no need to define "Dimension Set ID" field for package without dimensions

        HideDialog();
        LibraryRapidStart.CreatePackage(ConfigPackage);

        LineNo := 10000;
        CreateGenJnlLinePackageDataWithoutDimSetID(ConfigPackage, LineNo, GenJnlTemplate, GenJnlBatch);
        LibraryRapidStart.ApplyPackage(ConfigPackage, true);
        ExportImportPackage(ConfigPackage.Code);
        LibraryRapidStart.ApplyPackage(ConfigPackage, true);
        GenJnlLine.Get(GenJnlTemplate.Name, GenJnlBatch.Name, LineNo);
        Assert.AreEqual(0, GenJnlLine."Dimension Set ID", IncorrectDimSetError);

        LibraryERM.ClearGenJournalLines(GenJnlBatch);
        GenJnlBatch.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure ApplyBlankDimSetIDToJnlLineWithDefDimension()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        LineNo: Integer;
        DimSetID: Integer;
    begin
        Initialize();
        // Verify that default dimensions are inherited from the G/L Account if "Dimension Set ID" from package is zero.

        HideDialog();
        CreatePackageAndFields(ConfigPackage, ConfigPackageTable);

        LineNo := 10000;
        CreateGenJnlLineWithAccNoAndDefDimensions(ConfigPackage, ConfigPackageTable, LineNo, GenJnlTemplate, GenJnlBatch, DimSetID);
        LibraryRapidStart.ApplyPackage(ConfigPackage, true);
        ExportImportPackage(ConfigPackage.Code);
        LibraryRapidStart.ApplyPackage(ConfigPackage, true);
        GenJnlLine.Get(GenJnlTemplate.Name, GenJnlBatch.Name, LineNo);
        Assert.AreEqual(DimSetID, GenJnlLine."Dimension Set ID", IncorrectDimSetError);

        LibraryERM.ClearGenJournalLines(GenJnlBatch);
        GenJnlBatch.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyPackageWithDataTemplateWithDimensions()
    var
        Customer: Record Customer;
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        DimensionValue: Record "Dimension Value";
        DimensionsTemplate: Record "Dimensions Template";
        DefaultDimension: Record "Default Dimension";
        ConfigTemplateHeader: Record "Config. Template Header";
    begin
        // [FEATURE] [Data Template]
        // [SCENARIO 215383] Dimensions are assigned from Data Template when applying package

        Initialize();
        // [GIVEN] Customer
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Data Template "Y" has dimension "DEPARTMENT" - "PROD"
        LibraryDim.CreateDimWithDimValue(DimensionValue);
        LibraryRapidStart.CreateConfigTemplateHeader(ConfigTemplateHeader);
        LibraryDim.CreateDimensionsTemplate(
          DimensionsTemplate, ConfigTemplateHeader.Code, DATABASE::Customer, DimensionValue."Dimension Code", DimensionValue.Code);

        // [GIVEN] Package with 1 field included - "No." and Data Template "Y"
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::Customer);
        ConfigPackageTable."Data Template" := ConfigTemplateHeader.Code;
        ConfigPackageTable.Modify();
        LibraryRapidStart.CreatePackageData(ConfigPackage.Code, DATABASE::Customer, 1, Customer.FieldNo("No."), Customer."No.");

        // [WHEN] Apply package
        LibraryRapidStart.ApplyPackage(ConfigPackage, true);

        // [THEN] Default Dimension "DEPARTMENT" - "PROD" is created for Customer
        DefaultDimension.Get(DATABASE::Customer, Customer."No.", DimensionValue."Dimension Code");
        DefaultDimension.TestField("Dimension Value Code", DimensionValue.Code);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM RS Package Dimensions");
        LibraryRapidStart.CleanUp('');

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM RS Package Dimensions");
        APIMockEvents.SetAPIServicesEnabled(false);
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM RS Package Dimensions");
    end;

    local procedure CreatePackageAndFields(var ConfigPackage: Record "Config. Package"; var ConfigPackageTable: Record "Config. Package Table")
    begin
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Dimension Set Entry");
    end;

    local procedure CreateGenJnlLines(var ConfigPackage: Record "Config. Package"; var ConfigPackageTable: Record "Config. Package Table"; LineNo: Integer; var GenJnlTemplate: Record "Gen. Journal Template"; var GenJnlBatch: Record "Gen. Journal Batch")
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Gen. Journal Line");

        CreateGenJnlBatchPackageData(GenJnlTemplate, GenJnlBatch);
        CreateGenJnlLinePackageData(
          GenJnlTemplate.Name, GenJnlBatch.Name, LineNo, WorkDate(),
          CopyStr(
            LibraryUtility.GenerateRandomCode(GenJnlLine.FieldNo("Document No."), DATABASE::"Gen. Journal Line"),
            1, LibraryUtility.GetFieldLength(DATABASE::"Gen. Journal Line", GenJnlLine.FieldNo("Document No."))),
          0, 1, 1, ConfigPackage.Code);
    end;

    local procedure CreateGenJnlLinePackageDataWithoutDimSetID(var ConfigPackage: Record "Config. Package"; LineNo: Integer; var GenJnlTemplate: Record "Gen. Journal Template"; var GenJnlBatch: Record "Gen. Journal Batch")
    var
        GLAccount: Record "G/L Account";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageField: Record "Config. Package Field";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Gen. Journal Line");
        ConfigPackageField.Get(ConfigPackageTable."Package Code", ConfigPackageTable."Table ID", DATABASE::"Dimension Set Entry");
        ConfigPackageField.Validate("Include Field", false);
        ConfigPackageField.Modify(true);

        CreateGenJnlBatchPackageData(GenJnlTemplate, GenJnlBatch);
        LibraryERM.FindGLAccount(GLAccount);
        PrepareGenJnlLinePackageData(
          ConfigPackage.Code, 1, GenJnlTemplate.Name, GenJnlBatch.Name, LineNo, WorkDate(),
          CopyStr(
            LibraryUtility.GenerateRandomCode(GenJnlLine.FieldNo("Document No."), DATABASE::"Gen. Journal Line"),
            1, LibraryUtility.GetFieldLength(DATABASE::"Gen. Journal Line", GenJnlLine.FieldNo("Document No."))),
          GLAccount."No.", 0);
    end;

    local procedure CreateGenJnlLineWithAccNoAndDefDimensions(var ConfigPackage: Record "Config. Package"; var ConfigPackageTable: Record "Config. Package Table"; LineNo: Integer; var GenJnlTemplate: Record "Gen. Journal Template"; var GenJnlBatch: Record "Gen. Journal Batch"; var DimSetID: Integer)
    var
        GenJnlLine: Record "Gen. Journal Line";
        AccNo: Code[20];
    begin
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Gen. Journal Line");

        CreateGLAccountWithDefaultDimensions(AccNo, DimSetID);

        CreateGenJnlBatchPackageData(GenJnlTemplate, GenJnlBatch);
        PrepareGenJnlLinePackageData(
          ConfigPackage.Code, 1, GenJnlTemplate.Name, GenJnlBatch.Name, LineNo, WorkDate(),
          CopyStr(
            LibraryUtility.GenerateRandomCode(GenJnlLine.FieldNo("Document No."), DATABASE::"Gen. Journal Line"),
            1, LibraryUtility.GetFieldLength(DATABASE::"Gen. Journal Line", GenJnlLine.FieldNo("Document No."))),
          AccNo, 0);
    end;

    local procedure CreateGenJnlBatchPackageData(var GenJnlTemplate: Record "Gen. Journal Template"; var GenJnlBatch: Record "Gen. Journal Batch")
    begin
        GenJnlTemplate.SetRange(Type, GenJnlTemplate.Type::General);
        GenJnlTemplate.FindFirst();
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);
    end;

    local procedure CreateGenJnlLinePackageData(GenJnlTemplate: Code[20]; GenJnlBatch: Code[20]; LineNo: Integer; PostingDate: Date; DocumentNo: Code[20]; Amount: Decimal; DimSetID: Integer; RecordNo: Integer; PackageCode: Code[20])
    var
        GLAccount: Record "G/L Account";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        LibraryERM.FindGLAccount(GLAccount);
        PrepareGenJnlLinePackageData(
          PackageCode, RecordNo, GenJnlTemplate, GenJnlBatch, LineNo, PostingDate, DocumentNo, GLAccount."No.", Amount);
        LibraryRapidStart.CreatePackageData(
          PackageCode, DATABASE::"Gen. Journal Line", RecordNo, GenJnlLine.FieldNo("Dimension Set ID"), Format(DimSetID));
    end;

    local procedure PrepareGenJnlLinePackageData(PackageCode: Code[20]; RecordNo: Integer; GenJnlTemplate: Code[20]; GenJnlBatch: Code[20]; LineNo: Integer; PostingDate: Date; DocumentNo: Code[20]; AccNo: Code[20]; Amount: Decimal)
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        LibraryRapidStart.CreatePackageData(
          PackageCode, DATABASE::"Gen. Journal Line", RecordNo, GenJnlLine.FieldNo("Journal Template Name"), Format(GenJnlTemplate));
        LibraryRapidStart.CreatePackageData(
          PackageCode, DATABASE::"Gen. Journal Line", RecordNo, GenJnlLine.FieldNo("Journal Batch Name"), Format(GenJnlBatch));
        LibraryRapidStart.CreatePackageData(
          PackageCode, DATABASE::"Gen. Journal Line", RecordNo, GenJnlLine.FieldNo("Line No."), Format(LineNo));
        LibraryRapidStart.CreatePackageData(
          PackageCode, DATABASE::"Gen. Journal Line", RecordNo, GenJnlLine.FieldNo("Posting Date"), Format(PostingDate));
        LibraryRapidStart.CreatePackageData(
          PackageCode, DATABASE::"Gen. Journal Line", RecordNo, GenJnlLine.FieldNo("Document No."), Format(DocumentNo));
        LibraryRapidStart.CreatePackageData(
          PackageCode, DATABASE::"Gen. Journal Line", RecordNo,
          GenJnlLine.FieldNo("Account Type"), Format(GenJnlLine."Account Type"::"G/L Account"));
        LibraryRapidStart.CreatePackageData(
          PackageCode, DATABASE::"Gen. Journal Line", RecordNo, GenJnlLine.FieldNo("Account No."), Format(AccNo));
        LibraryRapidStart.CreatePackageData(
          PackageCode, DATABASE::"Gen. Journal Line", RecordNo, GenJnlLine.FieldNo(Amount), Format(Amount));
    end;

    local procedure CreateDimSetEntryPackageData(DimSetID: Integer; DimCode: Code[20]; DimValueCode: Code[20]; RecordNo: Integer; PackageCode: Code[20])
    var
        DimSetEntry: Record "Dimension Set Entry";
    begin
        LibraryRapidStart.CreatePackageData(
          PackageCode, DATABASE::"Dimension Set Entry", RecordNo, DimSetEntry.FieldNo("Dimension Set ID"), Format(DimSetID));
        LibraryRapidStart.CreatePackageData(
          PackageCode, DATABASE::"Dimension Set Entry", RecordNo, DimSetEntry.FieldNo("Dimension Code"), Format(DimCode));
        LibraryRapidStart.CreatePackageData(
          PackageCode, DATABASE::"Dimension Set Entry", RecordNo, DimSetEntry.FieldNo("Dimension Value Code"), Format(DimValueCode));
    end;

    local procedure CreateGLAccountWithDefaultDimensions(var AccNo: Code[20]; var DimSetID: Integer)
    var
        GLAccount: Record "G/L Account";
        DefaultDimension: Record "Default Dimension";
        DimSetEntry: Record "Dimension Set Entry";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        AccNo := GLAccount."No.";
        DimSetEntry.Next(LibraryRandom.RandInt(DimSetEntry.Count));
        DimSetID := DimSetEntry."Dimension Set ID";
        LibraryDim.FindDimensionSetEntry(DimSetEntry, DimSetEntry."Dimension Set ID");
        repeat
            LibraryDim.CreateDefaultDimension(
              DefaultDimension, DATABASE::"G/L Account", AccNo, DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code");
        until DimSetEntry.Next() = 0;
    end;

    local procedure ExportImportPackage(ConfigPackageCode: Code[20])
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
        PackageXML: DotNet XmlDocument;
    begin
        ConfigPackage.Get(ConfigPackageCode);
        ConfigPackageTable.SetRange("Package Code", ConfigPackage.Code);

        PackageXML := PackageXML.XmlDocument();
        ConfigXMLExchange.SetExcelMode(true);
        ConfigXMLExchange.ExportPackageXMLDocument(PackageXML, ConfigPackageTable, ConfigPackage, false);
        ConfigXMLExchange.ImportPackageXMLDocument(PackageXML, '');
    end;

    local procedure HideDialog()
    begin
        ConfigPackageMgt.SetHideDialog(true);
        ConfigXMLExchange.SetCalledFromCode(true);
        ConfigXMLExchange.SetHideDialog(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;


}

