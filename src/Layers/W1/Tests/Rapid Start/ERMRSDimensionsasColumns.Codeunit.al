codeunit 136611 "ERM RS Dimensions as Columns"
{
    Permissions = TableData "G/L Entry" = m,
                  TableData "Dimension Set Entry" = m;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Rapid Start] [Dimension]
    end;

    var
        Assert: Codeunit Assert;
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryRapidStart: Codeunit "Library - Rapid Start";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        APIMockEvents: Codeunit "API Mock Events";
        IncorrectNumberOfTablesErr: Label 'Incorrect number of tables in package.';
        CannotUseDimensionsAsColumnsErr: Label 'You cannot use the Dimensions as Columns function for table %1.';
        DimensionExpectedErr: Label 'The setup of Dimensions as Columns was canceled.';
        IncorrectDimPackageDataErr: Label 'Package Data were not updated when validate Dimension As Columns field.';
        DimensionNotAppliedErr: Label 'Default dimension was not applied.';
        IsInitialized: Boolean;
        DimValueDoesNotExistsInDimSetErr: Label 'Dimension value %1 %2 does not exist in Dimension Set ID %3.', Comment = '%1 = Dimension Code, %2 = Dimension Value Code';
        FieldIDProcessingOrderMustMatchErr: Label 'Field ID and Processing Order must match.';
        FieldIDProcessingOrderMustNotMatchErr: Label 'Field ID and Processing Order must not match.';

    [Test]
    [HandlerFunctions('ConfirmAddDimTablesHandlerYes')]
    [Scope('OnPrem')]
    procedure VerifyDimAsColumnsDimTablesAdded_ConfirmHandlerYes()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
    begin
        // [SCENARIO] Two dimension package tables added to the package if "Dimensions As Columns" set to 'Yes'
        Initialize();
        // [GIVEN] Package with table Customer
        CreateBasicPackage(ConfigPackage, ConfigPackageTable, DATABASE::Customer);
        // [WHEN] Set "Dimensions As Columns" to 'Yes' on Customer table and answer 'Yes' to confirmation
        SetDimensionAsColumns(ConfigPackageTable);
        // [THEN] Three tables in the package: Customer, Dimension Value, Default Dimension.
        ConfigPackageTable.SetRange("Package Code", ConfigPackage.Code);
        ConfigPackageTable.SetFilter("Table ID", '%1|%2|%3', DATABASE::Customer, DATABASE::"Dimension Value", DATABASE::"Default Dimension");
        Assert.RecordCount(ConfigPackageTable, 3);
    end;

    [Test]
    [HandlerFunctions('ConfirmAddDimTablesHandlerNo')]
    [Scope('OnPrem')]
    procedure VerifyDimAsColumnsDimTablesNotAdded_ConfirmHandlerNo()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
    begin
        // [SCENARIO] Addition of dimension tables on "Dimensions As Columns" set to 'Yes' can be cancelled
        Initialize();
        CreateBasicPackage(ConfigPackage, ConfigPackageTable, DATABASE::Customer);
        asserterror SetDimensionAsColumns(ConfigPackageTable);
        Assert.ExpectedError(DimensionExpectedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyDimAsColumnsIsNotAllowed()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
    begin
        Initialize();
        CreateBasicPackage(ConfigPackage, ConfigPackageTable, DATABASE::Location);
        asserterror SetDimensionAsColumns(ConfigPackageTable);
        Assert.ExpectedError(StrSubstNo(CannotUseDimensionsAsColumnsErr, ConfigPackageTable."Table ID"));
    end;

    [Test]
    [HandlerFunctions('ConfirmAddDimTablesHandlerYes')]
    [Scope('OnPrem')]
    procedure VerifyPackageDataUpdatedWithDimAsColumns()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
    begin
        Initialize();

        CreateBasicPackage(ConfigPackage, ConfigPackageTable, DATABASE::Customer);
        CreateCustomerPackageData(ConfigPackage, ConfigPackageTable);
        SetDimensionAsColumns(ConfigPackageTable);
        CheckCustomerPackageDataUpdated(ConfigPackage.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionSet_DimAsColumnsDimTablesAdded()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        SalesHeader: Record "Sales Header";
    begin
        // System do not suggests dimension tables while switch ON "Dimensions As Columns" for tables that have Dimension Set ID.
        Initialize();

        CreateBasicPackageForDimSet(ConfigPackage, ConfigPackageTable, SalesHeader, DATABASE::"Sales Header");
        SetDimensionAsColumns(ConfigPackageTable);

        Assert.AreEqual(1, ConfigPackageTable.Count, IncorrectNumberOfTablesErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmAddDimTablesHandlerYes')]
    [Scope('OnPrem')]
    procedure ApplyPackageWithDimensionsAsColumnsExistingCustomer()
    var
        ConfigPackage: Record "Config. Package";
        ConfigLine: Record "Config. Line";
        Customer: Record Customer;
        DimensionCode: Code[20];
    begin
        Initialize();
        CreateConfigLineAssignPackage(ConfigPackage, ConfigLine);
        LibrarySales.CreateCustomer(Customer);
        LibraryRapidStart.CreatePackageData(ConfigPackage.Code, DATABASE::Customer, 1, Customer.FieldNo("No."), Customer."No.");

        DimensionCode := SetDefaultDimensionInPackage(ConfigLine."Package Code", Customer."No.");
        ApplyConfigLineAndVerifyApplication(ConfigLine, Customer."No.", DimensionCode);
    end;

    [Test]
    [HandlerFunctions('ConfirmAddDimTablesHandlerYes')]
    [Scope('OnPrem')]
    procedure ApplyPackageWithDimensionsAsColumnsNewCustomer()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigLine: Record "Config. Line";
        Customer: Record Customer;
        DimVal: Record "Dimension Value";
        NewCustomerNo: Code[20];
    begin
        Initialize();

        NewCustomerNo := LibraryUtility.GenerateRandomCode(Customer.FieldNo("No."), DATABASE::Customer);
        FindDimensionWithValue(DimVal);

        CreateConfigPackageWithNewCustomer(ConfigPackage, ConfigPackageTable, ConfigLine, NewCustomerNo);
        ExportImportPackageSetNewCustAndDim(ConfigPackage, ConfigPackageTable, NewCustomerNo, DimVal."Dimension Code", DimVal.Code);

        ApplyConfigLineAndVerifyApplication(ConfigLine, NewCustomerNo, DimVal."Dimension Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyPackageWithDimAsColumnsWithoutSettingDimSetIDField()
    var
        DimVal: Record "Dimension Value";
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        SalesHeader: Record "Sales Header";
        OldManualNos: Boolean;
    begin
        // Verify that dimensions can be applied from package when field "Dimension Set ID" is not included.

        Initialize();
        CreatePackageExcludingDimSetIDField(ConfigPackage, ConfigPackageTable, SalesHeader);

        FindDimValueFromDefDim(DimVal, DATABASE::Customer, SalesHeader."Sell-to Customer No.");
        ExportImportPackageSetNewDimension(ConfigPackage, ConfigPackageTable, DimVal."Dimension Code", DimVal.Code);

        OldManualNos := SetupManualNos(SalesHeader."No. Series", true);

        LibraryRapidStart.ApplyPackage(ConfigPackage, true);
        SalesHeader.Find(); // get latest version after applying package
        VerifyDimValueExistsInSalesHeaderDimSetID(SalesHeader, DimVal);

        SetupManualNos(SalesHeader."No. Series", OldManualNos);
    end;

    [Test]
    [HandlerFunctions('PackageFieldsPageHandler')]
    [Scope('OnPrem')]
    procedure DimensionFieldsNotDeletedWhenReopenConfigPackageFieldsPage()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageField: Record "Config. Package Field";
        ConfigPackageField2: Record "Config. Package Field";
        ConfigManagement: Codeunit "Config. Management";
        ConfigPackageFields: TestPage "Config. Package Fields";
    begin
        // [SCENARIO 479333] [IcM] When the "Dimensions as columns" option is enabled, RapidStart doesn't always respect the defined order of fields
        Initialize();

        // [GIVEN] Create a Config Package with Gen Journal Line table.
        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, Database::"Gen. Journal Line");

        // [GIVEN] Validate Dimensions as Columns in Config Package Table.
        ConfigPackageTable.Validate("Dimensions as Columns", true);
        ConfigPackageTable.Modify();

        // [GIVEN] Open Config Package Fields page from Config Package Table.
        ConfigPackageTable.ShowPackageFields();

        // [GIVEN] Find Dimension Config Package Field.
        ConfigPackageField.SetRange("Package Code", ConfigPackageTable."Package Code");
        ConfigPackageField.SetRange("Table ID", ConfigPackageTable."Table ID");
        ConfigPackageField.SetRange("Field ID", ConfigManagement.DimensionFieldID(), ConfigManagement.DimensionFieldID() + 999);
        ConfigPackageField.FindFirst();

        // [VERIFY] Verify Field ID and Processing Order of Dimension Config Package Field are same.
        Assert.AreEqual(ConfigPackageField."Field ID", ConfigPackageField."Processing Order", FieldIDProcessingOrderMustMatchErr);

        // [GIVEN] Open Config Package Fields page and Move Up Dimension Config Package Field.
        ConfigPackageFields.OpenEdit();
        ConfigPackageFields.GoToRecord(ConfigPackageField);
        ConfigPackageFields."Move Up".Invoke();
        ConfigPackageFields.Close();

        // [GIVEN] Open Config Package Fields page from Config Package Table.
        ConfigPackageTable.ShowPackageFields();

        // [WHEN] Find Dimension Config Package Field.
        ConfigPackageField2.SetRange("Package Code", ConfigPackageTable."Package Code");
        ConfigPackageField2.SetRange("Table ID", ConfigPackageTable."Table ID");
        ConfigPackageField2.SetRange("Field ID", ConfigPackageField."Field ID");
        ConfigPackageField2.FindFirst();

        // [VERIFY] Verify Field ID and Processing Order of Dimension Config Package Field are not same.
        Assert.AreNotEqual(ConfigPackageField2."Field ID", ConfigPackageField2."Processing Order", FieldIDProcessingOrderMustNotMatchErr);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ERM RS Dimensions as Columns");

        LibraryApplicationArea.EnableFoundationSetup();

        LibraryRapidStart.CleanUp('');
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ERM RS Dimensions as Columns");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        APIMockEvents.SetAPIServicesEnabled(false);

        IsInitialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ERM RS Dimensions as Columns");
    end;

    local procedure CreateBasicPackage(var ConfigPackage: Record "Config. Package"; var ConfigPackageTable: Record "Config. Package Table"; TableId: Integer)
    begin
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, TableId);
        ConfigPackageTable.SetRange("Package Code", ConfigPackage.Code);
    end;

    local procedure SetDimensionAsColumns(var ConfigPackageTable: Record "Config. Package Table")
    begin
        ConfigPackageTable.Validate("Dimensions as Columns", true);
        ConfigPackageTable.Modify();
    end;

    local procedure CreatePackageExcludingDimSetIDField(var ConfigPackage: Record "Config. Package"; var ConfigPackageTable: Record "Config. Package Table"; var SalesHeader: Record "Sales Header")
    var
        Customer: Record Customer;
        ConfigPackageField: Record "Config. Package Field";
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        CreateNewCustomerAndNewLinkedDimension(Customer, DefaultDimension, DimensionValue);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Sales Header");
        SetDimensionAsColumns(ConfigPackageTable);
        ConfigPackageField.Get(ConfigPackageTable."Package Code", ConfigPackageTable."Table ID", DATABASE::"Dimension Set Entry");
        ConfigPackageField.Validate("Include Field", false);
        ConfigPackageField.Modify(true);

        ConfigPackageTable.SetRange("Package Code", ConfigPackage.Code);
        SetPackageFilterForTable(ConfigPackage.Code, DATABASE::"Sales Header", SalesHeader.FieldNo("No."), SalesHeader."No.");
    end;

    local procedure CreateBasicPackageForDimSet(var ConfigPackage: Record "Config. Package"; var ConfigPackageTable: Record "Config. Package Table"; var SalesHeader: Record "Sales Header"; TableID: Integer)
    var
        Customer: Record Customer;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        CreateNewCustomerAndNewLinkedDimension(Customer, DefaultDimension, DimensionValue);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        TableID := DATABASE::"Sales Header";
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, TableID);
        SetPackageFilterForTable(ConfigPackage.Code, TableID, SalesHeader.FieldNo("No."), SalesHeader."No.");
        ConfigPackageTable.SetRange("Package Code", ConfigPackage.Code);
    end;

    local procedure SetPackageFilterForTable(ConfigPackageCode: Code[20]; TableID: Integer; FieldID: Integer; FieldFilter: Text[250])
    var
        ConfigPackageFilter: Record "Config. Package Filter";
        ConfigPackageMgt: Codeunit "Config. Package Management";
    begin
        ConfigPackageMgt.InsertPackageFilter(ConfigPackageFilter, ConfigPackageCode, TableID, 0, FieldID, FieldFilter);
    end;

    local procedure VerifyDimValueExistsInSalesHeaderDimSetID(SalesHeader: Record "Sales Header"; DimVal: Record "Dimension Value")
    var
        DimSetEntry: Record "Dimension Set Entry";
    begin
        SalesHeader.TestField("Dimension Set ID");
        DimSetEntry.SetRange("Dimension Set ID", SalesHeader."Dimension Set ID");
        DimSetEntry.SetRange("Dimension Code", DimVal."Dimension Code");
        DimSetEntry.SetRange("Dimension Value Code", DimVal.Code);
        Assert.IsTrue(
          not DimSetEntry.IsEmpty,
          StrSubstNo(DimValueDoesNotExistsInDimSetErr, DimVal."Dimension Code", DimVal.Code, SalesHeader."Dimension Set ID"));
    end;

    local procedure CreateCustomerPackageData(var ConfigPackage: Record "Config. Package"; var ConfigPackageTable: Record "Config. Package Table")
    var
        Customer: Record Customer;
    begin
        LibraryRapidStart.CreatePackageDataForField(
          ConfigPackage,
          ConfigPackageTable,
          ConfigPackageTable."Table ID",
          Customer.FieldNo(Name),
          LibraryUtility.GenerateRandomCode(Customer.FieldNo(Name), DATABASE::Customer),
          Customer.FieldNo("No."));
    end;

    local procedure CheckCustomerPackageDataUpdated(PackageCode: Code[20])
    var
        ConfigPackageData: Record "Config. Package Data";
        ConfigPackageField: Record "Config. Package Field";
        Customer: Record Customer;
    begin
        ConfigPackageData.SetRange("Package Code", PackageCode);
        ConfigPackageData.SetRange("Table ID", DATABASE::Customer);
        ConfigPackageData.SetRange("No.", Customer.FieldNo("No."));

        ConfigPackageField.SetRange("Package Code", PackageCode);
        ConfigPackageField.SetRange("Table ID", DATABASE::Customer);
        ConfigPackageField.SetRange(Dimension, true);
        ConfigPackageField.FindSet();
        repeat
            ConfigPackageData.SetRange("Field ID", ConfigPackageField."Field ID");
            Assert.IsTrue(ConfigPackageData.FindFirst(), IncorrectDimPackageDataErr);
        until ConfigPackageField.Next() = 0;
    end;

    local procedure CreateNewCustomerAndNewLinkedDimension(var Customer: Record Customer; var DefaultDimension: Record "Default Dimension"; var DimensionValue: Record "Dimension Value")
    var
        Dimension: Record Dimension;
    begin
        Dimension.DeleteAll();
        DimensionValue.DeleteAll();
        DefaultDimension.DeleteAll();

        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);

        LibrarySales.CreateCustomer(Customer);

        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::Customer, Customer."No.", DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure CreateConfigLineAssignPackage(var ConfigPackage: Record "Config. Package"; var ConfigLine: Record "Config. Line")
    var
        ConfigPackageTable: Record "Config. Package Table";
    begin
        CreateBasicPackage(ConfigPackage, ConfigPackageTable, DATABASE::Customer);
        LibraryRapidStart.CreateConfigLine(ConfigLine, ConfigLine."Line Type"::Table, DATABASE::Customer, '', ConfigPackage.Code, true);
    end;

    local procedure SetDefaultDimensionInPackage(ConfigPackageCode: Code[20]; CustomerNo: Code[20]): Code[20]
    var
        Dimension: Record Dimension;
        DimVal: Record "Dimension Value";
        DefaultDim: Record "Default Dimension";
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimVal, Dimension.Code);

        LibraryRapidStart.CreatePackageData(
          ConfigPackageCode, DATABASE::"Default Dimension", 1, DefaultDim.FieldNo("Table ID"), Format(DATABASE::Customer));
        LibraryRapidStart.CreatePackageData(
          ConfigPackageCode, DATABASE::"Default Dimension", 1, DefaultDim.FieldNo("No."), CustomerNo);
        LibraryRapidStart.CreatePackageData(
          ConfigPackageCode, DATABASE::"Default Dimension", 1, DefaultDim.FieldNo("Dimension Code"), Dimension.Code);
        LibraryRapidStart.CreatePackageData(
          ConfigPackageCode, DATABASE::"Default Dimension", 1, DefaultDim.FieldNo("Dimension Value Code"), DimVal.Code);

        exit(Dimension.Code);
    end;

    local procedure ApplyConfigLineAndVerifyApplication(var ConfigLine: Record "Config. Line"; CustomerNo: Code[20]; DimensionCode: Code[20])
    var
        ConfigPackageMgt: Codeunit "Config. Package Management";
    begin
        ConfigLine.SetRange("Line No.", ConfigLine."Line No.");
        ConfigPackageMgt.SetHideDialog(true);
        ConfigPackageMgt.ApplyConfigLines(ConfigLine);

        VerifyDefaultDimApplied(CustomerNo, DimensionCode);
    end;

    local procedure VerifyDefaultDimApplied(CustomerNo: Code[20]; DimensionCode: Code[20])
    var
        DefaultDim: Record "Default Dimension";
    begin
        DefaultDim.SetRange("Table ID", DATABASE::Customer);
        DefaultDim.SetRange("No.", CustomerNo);
        DefaultDim.SetRange("Dimension Code", DimensionCode);
        Assert.IsFalse(DefaultDim.IsEmpty, DimensionNotAppliedErr);
    end;

    local procedure CreateConfigPackageWithNewCustomer(var ConfigPackage: Record "Config. Package"; var ConfigPackageTable: Record "Config. Package Table"; var ConfigLine: Record "Config. Line"; CustomerNo: Code[20])
    var
        ConfigPackageFilter: Record "Config. Package Filter";
        Customer: Record Customer;
        ConfigPackageMgt: Codeunit "Config. Package Management";
        ConfigMgt: Codeunit "Config. Management";
    begin
        CreateConfigLineAssignPackage(ConfigPackage, ConfigLine);

        LibraryRapidStart.CreatePackageData(ConfigPackage.Code, DATABASE::Customer, 1, Customer.FieldNo("No."), CustomerNo);
        ConfigPackageMgt.InsertPackageFilter(
          ConfigPackageFilter, ConfigPackage.Code, DATABASE::Customer, 0, Customer.FieldNo("No."), CustomerNo);

        ConfigPackageTable.SetRange("Package Code", ConfigPackage.Code);
        ConfigPackageTable.SetFilter("Table ID", ConfigMgt.MakeTableFilter(ConfigLine, true));
    end;

    local procedure ExportImportPackageSetNewCustAndDim(var ConfigPackage: Record "Config. Package"; var ConfigPackageTable: Record "Config. Package Table"; CustomerNo: Code[20]; DimCode: Code[20]; DimValCode: Code[20])
    begin
        ExportImportPackageSetNewValues(ConfigPackage, ConfigPackageTable, CustomerNo, DimCode, DimValCode);
    end;

    local procedure ExportImportPackageSetNewDimension(var ConfigPackage: Record "Config. Package"; var ConfigPackageTable: Record "Config. Package Table"; DimCode: Code[20]; DimValCode: Code[20])
    begin
        ExportImportPackageSetNewValues(ConfigPackage, ConfigPackageTable, '', DimCode, DimValCode);
    end;

    local procedure ExportImportPackageSetNewValues(var ConfigPackage: Record "Config. Package"; var ConfigPackageTable: Record "Config. Package Table"; CustomerNo: Code[20]; DimCode: Code[20]; DimValCode: Code[20])
    var
        Customer: Record Customer;
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
        PackageXML: DotNet XmlDocument;
    begin
        PackageXML := PackageXML.XmlDocument();
        ConfigXMLExchange.SetExcelMode(true);
        ConfigXMLExchange.ExportPackageXMLDocument(PackageXML, ConfigPackageTable, ConfigPackage, false);

        if CustomerNo <> '' then
            SetXMLNodeValue(PackageXML, ConfigXMLExchange.GetElementName(Customer.FieldName("No.")), CustomerNo);
        if DimCode <> '' then
            SetXMLNodeValue(PackageXML, ConfigXMLExchange.GetElementName(DimCode), DimValCode);

        ConfigXMLExchange.ImportPackageXMLDocument(PackageXML, '');
    end;

    local procedure SetXMLNodeValue(var PackageXML: DotNet XmlDocument; NodeName: Text[250]; NodeValue: Code[20])
    var
        XMLNode: DotNet XmlNode;
    begin
        XMLNode := PackageXML.SelectSingleNode('//' + NodeName);
        XMLNode.InnerText := NodeValue;
    end;

    local procedure FindDimensionWithValue(var DimVal: Record "Dimension Value")
    var
        Dimension: Record Dimension;
    begin
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.FindDimensionValue(DimVal, Dimension.Code);
    end;

    local procedure FindDimValueFromDefDim(var DimVal: Record "Dimension Value"; SourceTableID: Integer; SourceNo: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        DefaultDimension.SetRange("Table ID", SourceTableID);
        DefaultDimension.SetRange("No.", SourceNo);
        DefaultDimension.FindFirst();

        LibraryDimension.FindDimensionValue(DimVal, DefaultDimension."Dimension Code");
    end;

    local procedure SetupManualNos(NoSeriesCode: Code[20]; NewManualNos: Boolean) ManualNos: Boolean
    var
        NoSeries: Record "No. Series";
    begin
        NoSeries.Get(NoSeriesCode);
        ManualNos := NoSeries."Manual Nos.";
        NoSeries."Manual Nos." := NewManualNos;
        NoSeries.Modify();
    end;

    local procedure CreatePackageWithTable(var ConfigPackage: Record "Config. Package"; var ConfigPackageTable: Record "Config. Package Table"; TableNo: Integer)
    begin
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, TableNo);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmAddDimTablesHandlerYes(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmAddDimTablesHandlerNo(Question: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ImportPreviewModalPageHandler(var ConfigPackageImportPreview: TestPage "Config. Package Import Preview")
    begin
        ConfigPackageImportPreview.Import.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PackageFieldsPageHandler(var ConfigPackageFields: TestPage "Config. Package Fields")
    begin
        ConfigPackageFields.OK().Invoke();
    end;
}
