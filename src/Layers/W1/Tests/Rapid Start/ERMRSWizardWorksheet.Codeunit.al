codeunit 136606 "ERM RS Wizard & Worksheet"
{
    Permissions = TableData "G/L Entry" = m;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Rapid Start]
    end;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRapidStart: Codeunit "Library - Rapid Start";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        ConfigPackageMgt: Codeunit "Config. Package Management";
        APIMockEvents: Codeunit "API Mock Events";
        IncorrectNumOfTablesWithDataErr: Label 'Incorrect number of tables for Get Config. Tables report with IncludeWithDataOnly option.';
        IncorrectNumOfRelatedTablesErr: Label 'Incorrect number of tables for Get Config. Tables report with IncludeRelatedTables option.';
        ConfigPackageTblNotFoundErr: Label 'Config Package Table is not found.';
        SameTblReferenceErr: Label 'Some lines refer to the same table. You cannot assign a table to a package more than one time.';
        IncorrectRelatedTableIDErr: Label 'Incorrect Related Table ID value.';
        IncorrectNumOfTblRecsErr: Label 'Incorrect number of %1 table records.', Comment = '%1 - Table caption;';
        IncorrectPageIdForTableIDErr: Label 'Incorrect Page ID value for Table ID %1.', Comment = '%1 - Table ID.';
        IncorrectNumOfTablesInclDimErr: Label 'Incorrect number of tables for Get Config. Tables report with IncludeDimensionTables option.';
        IncorrectValueErr: Label 'Incorrect value of %1 in %2.', Comment = '%1 - Field Caption; %2 - Table caption;';
        PackageCodeNotAssignedErr: Label 'You must assign a package code before you can carry out this action.';
        LineBlockedErr: Label 'You cannot process line for table %1 and package code %2 because it is blocked.', Comment = '%1 - Table caption; %2 - Package code;';
        IncorrecrTableIDErr: Label 'Incorrect Table ID.';
        NotTblLineTypeErr: Label 'Line Type must be equal to ''Table''';
        FielValueNotUpdatedErr: Label 'The value of the field %1 was not updated.', Comment = '%1 - Field caption.';
        IncorrectQtyOfLinesErr: Label 'Incorrect quantity of lines, there is an unexpected result of Promoted Tables Only button work.';
        ConfigPackageNotAssignedErr: Label 'The Config. Package was not assigned.';
        LineNotExclFromConfigPackageErr: Label 'The line was not excluded from the Config. Package.';
        AnswerNotUpdatedErr: Label 'The Answer for value %1 was not updated.', Comment = '%1 - Question value.';
        LineNotMovedDownErr: Label 'The line was not moved down.';
        LineNotMovedUpErr: Label 'The line was not moved up.';
        RecNotAddedToTblErr: Label 'The record was not added to table %1.', Comment = '%1 - Table caption.';
        RecordAppliedErr: Label 'Record must not be applied.';
        RecordNotAppliedErr: Label 'Record must be applied.';
        TestPageNotOpenedErr: Label 'The TestPage is already open.';
        ConfigMgt: Codeunit "Config. Management";
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
        WrongConfigCreatedErr: Label 'No Config. Line or more than one line created.';
        ConfigLineCreatedErr: Label 'Config. Line created for package without config lines.';
        AssignmentErr: Label 'Config. Line was assigned to package.';
        PackageCodeReserErr: Label 'Package Code was not erased for config. package line.';
        RelatedTablesMustBeDeletedErr: Label 'Related tables must be deleted.';
        RelatedTablesMustNotBeDeletedErr: Label 'Related tables must not be deleted.';
        TableMustNotBeIncludedErr: Label 'Table %1 must not be added to the worksheet.', Comment = '%1 - Table caption';
        AreaLineTestFieldTableErr: Label 'Line Type must be equal to ''Table''  in Config. Line: Line No.=0. Current value is ''Area''.';
        GroupLineTestFieldTableErr: Label 'Line Type must be equal to ''Table''  in Config. Line: Line No.=0. Current value is ''Group''.';
        NoTableIdErr: Label 'There is no Config. Question Area within the filter.';
        NoExpectedErr: Label 'No expected error for config line with Table Line Type.';
        WrongQuestionAreaErr: Label 'Wrong question area opened.';
        DimAsColTestFieldExpectedErr: Label 'Dimensions as Columns must be equal to ''No''  in Config. Line';
        CodeCannotBeEmptyErr: Label '%1 must have a value in %2', Comment = '%1 - Field caption; %2 - Table caption.';
        LibraryERM: Codeunit "Library - ERM";
        FieldShouldBeDisabledErr: Label 'Field should be disabled when user does not have write access to table.';
        FieldShouldBeEnabledErr: Label 'Field should be enabled when user has write access to table.';
        LibraryInventory: Codeunit "Library - Inventory";

    [Test]
    [Scope('OnPrem')]
    procedure VerifyCompanyInfoUpdatedFromConfigSetup()
    var
        ConfigSetup: Record "Config. Setup";
        CompanyInfo: Record "Company Information";
    begin
        // Tests if Company Information table is updated from Rapid Start Wizard
        Initialize();

        CreateConfigSetup(ConfigSetup);
        ConfigSetup.CopyCompInfo();
        CompanyInfo.Get();
        CompanyInfo.TestField(Name, ConfigSetup.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyPackageUploadedToWizard()
    var
        ConfigSetup: Record "Config. Setup";
        ConfigPackage: Record "Config. Package";
    begin
        Initialize();
        PreparePackageFileNameForWizard(ConfigSetup, ConfigPackage);

        ConfigSetup.TestField("Package Name", ConfigPackage."Package Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyReport_GetConfigTables_IncludeWithDataOnlyOption()
    var
        ConfigLine: Record "Config. Line";
    begin
        Initialize();
        CreateLineNumberBuffer();
        GenerateReport_GetConfigTables(DATABASE::"Line Number Buffer", true, false, false, false);

        ConfigLine.SetRange("Package Code", '');
        Assert.IsTrue(ConfigLine.Count = 1, IncorrectNumOfTablesWithDataErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyReport_GetConfigTables_IncludeRelatedTablesOption()
    var
        ConfigLine: Record "Config. Line";
        TableID: Integer;
    begin
        Initialize();
        CreateLineNumberBuffer();
        TableID := DATABASE::"Sales & Receivables Setup";
        GenerateReport_GetConfigTables(TableID, false, true, false, false);

        // Verify related records count with source table are equal to count of config.lines
        ConfigLine.SetRange("Package Code", '');
        Assert.AreEqual(GetRelatedTableCount(TableID) + 1, ConfigLine.Count, IncorrectNumOfRelatedTablesErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyReport_GetConfigTables_IncludeDimensionTablesOption()
    var
        ConfigLine: Record "Config. Line";
    begin
        Initialize();
        CreateLineNumberBuffer();
        GenerateReport_GetConfigTables(DATABASE::Customer, false, false, true, false);
        ConfigLine.SetRange("Package Code", '');
        Assert.IsTrue(ConfigLine.Count = 9, IncorrectNumOfTablesInclDimErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyAssignConfigLineToConfigPackage()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigLine: Record "Config. Line";
        TableID: Integer;
    begin
        // Sunshine scenario for assign package.
        // SETUP
        Initialize();
        LibraryRapidStart.CreatePackage(ConfigPackage);
        TableID := FindTableID();
        AddConfigLine(ConfigLine."Line Type"::Table, TableID, '');
        FindFirstConfigLine(ConfigLine);

        // EXECUTE
        ConfigPackageMgt.AssignPackage(ConfigLine, ConfigPackage.Code);

        // VALIDATE
        ConfigLine.TestField("Package Code", ConfigPackage.Code);
        Assert.IsTrue(ConfigPackageTable.Get(ConfigPackage.Code, TableID), ConfigPackageTblNotFoundErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyRemoveTableFromPackage_Sunshine()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigLine: Record "Config. Line";
        TableID: Integer;
    begin
        // If table is removed from package then package code of appropriate config line must be cleaned.
        // Sunshine scenario.
        // SETUP
        Initialize();
        LibraryRapidStart.CreatePackage(ConfigPackage);
        TableID := FindTableID();
        AddConfigLine(ConfigLine."Line Type"::Table, TableID, '');
        ConfigLine.SetRange("Package Code", '');
        ConfigPackageMgt.AssignPackage(ConfigLine, ConfigPackage.Code);
        ConfigPackageTable.Get(ConfigPackage.Code, TableID);

        // EXECUTE
        ConfigPackageTable.Delete(true);

        // VALIDATE
        FindFirstConfigLine(ConfigLine);
        ConfigLine.TestField("Package Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyRemoveTableFromPackage_SameWorksheetTables()
    var
        ConfigPackage: array[2] of Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigLine: Record "Config. Line";
        TableID: Integer;
        FirstTetLineNo: Integer;
    begin
        // If table is removed from package then package code of appropriate config line must be cleaned.
        // If worksheet has 2 same tables removing table from package must cleanup Package Code for proper config line
        // SETUP
        Initialize();
        FirstTetLineNo := InitRemoveTableFromPackage_SameWorksheetTables(ConfigPackage, TableID);

        // EXECUTE delete table from second package
        ConfigPackageTable.Get(ConfigPackage[2].Code, TableID);
        ConfigPackageTable.Delete(true);

        // VALIDATE Package code has to be cleared for second line, but not cleared for the first one
        ConfigLine.Get(FirstTetLineNo);
        ConfigLine.TestField("Package Code", ConfigPackage[1].Code);

        ConfigLine.Next();
        ConfigLine.TestField("Package Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyAssignPackage_SameTablesAtOnce()
    var
        ConfigPackage: Record "Config. Package";
        ConfigLine: Record "Config. Line";
        TableID: Integer;
    begin
        // it should not be possible assigne same tables to one package at once
        // SETUP
        Initialize();
        TableID := FindTableID();
        LibraryRapidStart.CreatePackage(ConfigPackage);

        // add 2 tables with same Table ID
        AddConfigLine(ConfigLine."Line Type"::Table, TableID, '');
        AddConfigLine(ConfigLine."Line Type"::Table, TableID, '');

        // EXECUTE
        asserterror ConfigPackageMgt.AssignPackage(ConfigLine, ConfigPackage.Code);
        Assert.ExpectedError(SameTblReferenceErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyAssignPackage_SameTablesOneByOne()
    var
        ConfigPackage: Record "Config. Package";
        ConfigLine: Record "Config. Line";
        TableID: Integer;
    begin
        // it should not be possible assigne same tables to one package one by one
        // SETUP
        Initialize();
        TableID := FindTableID();
        LibraryRapidStart.CreatePackage(ConfigPackage);

        // add 2 tables with same Table ID
        AddConfigLine(ConfigLine."Line Type"::Table, TableID, '');
        AddConfigLine(ConfigLine."Line Type"::Table, TableID, '');

        // assign first table to the package
        ConfigLine.FindFirst();
        ConfigLine.SetRecFilter();

        ConfigPackageMgt.AssignPackage(ConfigLine, ConfigPackage.Code);

        // EXECUTE
        // try to assign second table to the package
        ConfigLine.Reset();
        ConfigLine.FindLast();
        ConfigLine.SetRecFilter();
        asserterror ConfigPackageMgt.AssignPackage(ConfigLine, ConfigPackage.Code);
        Assert.ExpectedError(SameTblReferenceErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure VerifyChangeConfigLineTableIDLinkedToPackage_Yes()
    var
        ConfigLine: Record "Config. Line";
        TableID: Integer;
    begin
        // change work sheet's Table ID if it is linked to package and confirm update
        Initialize();
        ChangeConfigLineTableIDLinkedToPackage(ConfigLine, TableID);

        // VERIFY package code must be cleared
        ConfigLine.TestField("Package Code", '');
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    [Scope('OnPrem')]
    procedure VerifyChangeConfigLineTableIDLinkedToPackage_No()
    var
        ConfigLine: Record "Config. Line";
        TableID: Integer;
    begin
        // change work sheet's Table ID if it is linked to package and do not confirm update
        Initialize();
        ChangeConfigLineTableIDLinkedToPackage(ConfigLine, TableID);

        // VERIFY table id is not changed
        ConfigLine.TestField("Table ID", TableID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReassignPackage()
    var
        ConfigLine: Record "Config. Line";
        NewPackageCode: Code[20];
        TableID: Integer;
        FieldsQty: Integer;
        FiltersQty: Integer;
        ErrorsQty: Integer;
    begin
        // check that after package is reassigned linked fields, filters and errors are renamed
        // SETUP
        Initialize();
        InitReassignPackageScenario(ConfigLine, TableID, NewPackageCode, FieldsQty, FiltersQty, ErrorsQty);

        // EXECUTE assign config line to another package
        ConfigLine.SetRange("Package Code", NewPackageCode);
        ConfigPackageMgt.AssignPackage(ConfigLine, NewPackageCode);

        // VERIFY fields and filters have to be in the new package
        VerifyRelatedRecords(NewPackageCode, TableID, FieldsQty, FiltersQty, ErrorsQty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckFindPage()
    begin
        CheckPage(DATABASE::"Company Information", PAGE::"Company Information");
        CheckPage(DATABASE::"Responsibility Center", PAGE::"Responsibility Center List");
        CheckPage(DATABASE::"Accounting Period", PAGE::"Accounting Periods");
        CheckPage(DATABASE::"General Ledger Setup", PAGE::"General Ledger Setup");
        CheckPage(DATABASE::"No. Series", PAGE::"No. Series");
        CheckPage(DATABASE::"No. Series Line", PAGE::"No. Series Lines");
        CheckPage(DATABASE::"G/L Account", PAGE::"Chart of Accounts");
        CheckPage(DATABASE::"Gen. Business Posting Group", PAGE::"Gen. Business Posting Groups");
        CheckPage(DATABASE::"Gen. Product Posting Group", PAGE::"Gen. Product Posting Groups");
        CheckPage(DATABASE::"General Posting Setup", PAGE::"General Posting Setup");
        CheckPage(DATABASE::"VAT Business Posting Group", PAGE::"VAT Business Posting Groups");
        CheckPage(DATABASE::"VAT Product Posting Group", PAGE::"VAT Product Posting Groups");
        CheckPage(DATABASE::"VAT Posting Setup", PAGE::"VAT Posting Setup");
        CheckPage(DATABASE::"Acc. Schedule Name", PAGE::"Account Schedule Names");
        CheckPage(DATABASE::"Column Layout Name", PAGE::"Column Layout Names");
        CheckPage(DATABASE::"G/L Budget Name", PAGE::"G/L Budget Names");
        CheckPage(DATABASE::"VAT Statement Template", PAGE::"VAT Statement Templates");
        CheckPage(DATABASE::"Tariff Number", PAGE::"Tariff Numbers");
        CheckPage(DATABASE::"Transaction Type", PAGE::"Transaction Types");
        CheckPage(DATABASE::"Transaction Specification", PAGE::"Transaction Specifications");
        CheckPage(DATABASE::"Transport Method", PAGE::"Transport Methods");
        CheckPage(DATABASE::"Entry/Exit Point", PAGE::"Entry/Exit Points");
        CheckPage(DATABASE::Area, PAGE::Areas);
        CheckPage(DATABASE::Territory, PAGE::Territories);
        CheckPage(DATABASE::"Tax Jurisdiction", PAGE::"Tax Jurisdictions");
        CheckPage(DATABASE::"Tax Group", PAGE::"Tax Groups");
        CheckPage(DATABASE::"Tax Detail", PAGE::"Tax Details");
        CheckPage(DATABASE::"Tax Area", PAGE::"Tax Area");
        CheckPage(DATABASE::"Tax Area Line", PAGE::"Tax Area Line");
        CheckPage(DATABASE::"Source Code", PAGE::"Source Codes");
        CheckPage(DATABASE::"Reason Code", PAGE::"Reason Codes");
        CheckPage(DATABASE::"Standard Text", PAGE::"Standard Text Codes");
        CheckPage(DATABASE::"Business Unit", PAGE::"Business Unit List");
        CheckPage(DATABASE::Dimension, PAGE::Dimensions);
        CheckPage(DATABASE::"Default Dimension Priority", PAGE::"Default Dimension Priorities");
        CheckPage(DATABASE::"Dimension Combination", PAGE::"Dimension Combinations");
        CheckPage(DATABASE::"Analysis View", PAGE::"Analysis View List");
        CheckPage(DATABASE::"Post Code", PAGE::"Post Codes");
        CheckPage(DATABASE::"Country/Region", PAGE::"Countries/Regions");
        CheckPage(DATABASE::Language, PAGE::Languages);
        CheckPage(DATABASE::Currency, PAGE::Currencies);
        CheckPage(DATABASE::"Bank Account", PAGE::"Bank Account List");
        CheckPage(DATABASE::"Bank Account Posting Group", PAGE::"Bank Account Posting Groups");
        CheckPage(DATABASE::"Change Log Setup (Table)", PAGE::"Change Log Setup (Table) List");
        CheckPage(DATABASE::"Change Log Setup (Field)", PAGE::"Change Log Setup (Field) List");
        CheckPage(DATABASE::"Sales & Receivables Setup", PAGE::"Sales & Receivables Setup");
        CheckPage(DATABASE::Customer, PAGE::"Customer List");
        CheckPage(DATABASE::"Customer Posting Group", PAGE::"Customer Posting Groups");
        CheckPage(DATABASE::"Payment Terms", PAGE::"Payment Terms");
        CheckPage(DATABASE::"Payment Method", PAGE::"Payment Methods");
        CheckPage(DATABASE::"Reminder Terms", PAGE::"Reminder Terms");
        CheckPage(DATABASE::"Reminder Level", PAGE::"Reminder Levels");
        CheckPage(DATABASE::"Reminder Text", PAGE::"Reminder Text");
        CheckPage(DATABASE::"Finance Charge Terms", PAGE::"Finance Charge Terms");
        CheckPage(DATABASE::"Shipment Method", PAGE::"Shipment Methods");
        CheckPage(DATABASE::"Shipping Agent", PAGE::"Shipping Agents");
        CheckPage(DATABASE::"Shipping Agent Services", PAGE::"Shipping Agent Services");
        CheckPage(DATABASE::"Customer Discount Group", PAGE::"Customer Disc. Groups");
        CheckPage(DATABASE::"Salesperson/Purchaser", PAGE::"Salespersons/Purchasers");
        CheckPage(DATABASE::"Marketing Setup", PAGE::"Marketing Setup");
        CheckPage(DATABASE::"Duplicate Search String Setup", PAGE::"Duplicate Search String Setup");
        CheckPage(DATABASE::Contact, PAGE::"Contact List");
        CheckPage(DATABASE::"Business Relation", PAGE::"Business Relations");
        CheckPage(DATABASE::"Mailing Group", PAGE::"Mailing Groups");
        CheckPage(DATABASE::"Industry Group", PAGE::"Industry Groups");
        CheckPage(DATABASE::"Web Source", PAGE::"Web Sources");
        CheckPage(DATABASE::"Interaction Group", PAGE::"Interaction Groups");
        CheckPage(DATABASE::"Interaction Template", PAGE::"Interaction Templates");
        CheckPage(DATABASE::"Job Responsibility", PAGE::"Job Responsibilities");
        CheckPage(DATABASE::"Organizational Level", PAGE::"Organizational Levels");
        CheckPage(DATABASE::"Campaign Status", PAGE::"Campaign Status");
        CheckPage(DATABASE::Activity, PAGE::Activity);
        CheckPage(DATABASE::Team, PAGE::Teams);
        CheckPage(DATABASE::"Profile Questionnaire Header", PAGE::"Profile Questionnaires");
        CheckPage(DATABASE::"Sales Cycle", PAGE::"Sales Cycles");
        CheckPage(DATABASE::"Close Opportunity Code", PAGE::"Close Opportunity Codes");
        CheckPage(DATABASE::"Service Mgt. Setup", PAGE::"Service Mgt. Setup");
        CheckPage(DATABASE::"Service Item", PAGE::"Service Item List");
        CheckPage(DATABASE::"Service Hour", PAGE::"Default Service Hours");
        CheckPage(DATABASE::"Work-Hour Template", PAGE::"Work-Hour Templates");
        CheckPage(DATABASE::"Resource Service Zone", PAGE::"Resource Service Zones");
        CheckPage(DATABASE::Loaner, PAGE::"Loaner List");
        CheckPage(DATABASE::"Skill Code", PAGE::"Skill Codes");
        CheckPage(DATABASE::"Fault Reason Code", PAGE::"Fault Reason Codes");
        CheckPage(DATABASE::"Service Cost", PAGE::"Service Costs");
        CheckPage(DATABASE::"Service Zone", PAGE::"Service Zones");
        CheckPage(DATABASE::"Service Order Type", PAGE::"Service Order Types");
        CheckPage(DATABASE::"Service Item Group", PAGE::"Service Item Groups");
        CheckPage(DATABASE::"Service Shelf", PAGE::"Service Shelves");
        CheckPage(DATABASE::"Service Status Priority Setup", PAGE::"Service Order Status Setup");
        CheckPage(DATABASE::"Repair Status", PAGE::"Repair Status Setup");
        CheckPage(DATABASE::"Service Price Group", PAGE::"Service Price Groups");
        CheckPage(DATABASE::"Serv. Price Group Setup", PAGE::"Serv. Price Group Setup");
        CheckPage(DATABASE::"Service Price Adjustment Group", PAGE::"Serv. Price Adjmt. Group");
        CheckPage(DATABASE::"Serv. Price Adjustment Detail", PAGE::"Serv. Price Adjmt. Detail");
        CheckPage(DATABASE::"Resolution Code", PAGE::"Resolution Codes");
        CheckPage(DATABASE::"Fault Area", PAGE::"Fault Areas");
        CheckPage(DATABASE::"Symptom Code", PAGE::"Symptom Codes");
        CheckPage(DATABASE::"Fault Code", PAGE::"Fault Codes");
        CheckPage(DATABASE::"Fault/Resol. Cod. Relationship", PAGE::"Fault/Resol. Cod. Relationship");
        CheckPage(DATABASE::"Contract Group", PAGE::"Service Contract Groups");
        CheckPage(DATABASE::"Service Contract Template", PAGE::"Service Contract Template");
        CheckPage(DATABASE::"Service Contract Account Group", PAGE::"Serv. Contract Account Groups");
        CheckPage(DATABASE::"Troubleshooting Header", PAGE::Troubleshooting);
        CheckPage(DATABASE::"Purchases & Payables Setup", PAGE::"Purchases & Payables Setup");
        CheckPage(DATABASE::Vendor, PAGE::"Vendor List");
        CheckPage(DATABASE::"Vendor Posting Group", PAGE::"Vendor Posting Groups");
        CheckPage(DATABASE::Purchasing, PAGE::"Purchasing Codes");
        CheckPage(DATABASE::"Inventory Setup", PAGE::"Inventory Setup");
        CheckPage(DATABASE::"Nonstock Item Setup", PAGE::"Catalog Item Setup");
        CheckPage(DATABASE::"Item Tracking Code", PAGE::"Item Tracking Codes");
        CheckPage(DATABASE::Item, PAGE::"Item List");
        CheckPage(DATABASE::"Nonstock Item", PAGE::"Catalog Item List");
        CheckPage(DATABASE::"Inventory Posting Group", PAGE::"Inventory Posting Groups");
        CheckPage(DATABASE::"Inventory Posting Setup", PAGE::"Inventory Posting Setup");
        CheckPage(DATABASE::"Unit of Measure", PAGE::"Units of Measure");
        CheckPage(DATABASE::"Customer Price Group", PAGE::"Customer Price Groups");
        CheckPage(DATABASE::"Item Discount Group", PAGE::"Item Disc. Groups");
        CheckPage(DATABASE::Manufacturer, PAGE::Manufacturers);
        CheckPage(DATABASE::"Item Category", PAGE::"Item Categories");
        CheckPage(DATABASE::"Rounding Method", PAGE::"Rounding Methods");
        CheckPage(DATABASE::Location, PAGE::"Location List");
        CheckPage(DATABASE::"Transfer Route", PAGE::"Transfer Routes");
        CheckPage(DATABASE::"Stockkeeping Unit", PAGE::"Stockkeeping Unit List");
        CheckPage(DATABASE::"Warehouse Setup", PAGE::"Warehouse Setup");
        CheckPage(DATABASE::"Resources Setup", PAGE::"Resources Setup");
        CheckPage(DATABASE::Resource, PAGE::"Resource List");
        CheckPage(DATABASE::"Resource Group", PAGE::"Resource Groups");
        CheckPage(DATABASE::"Work Type", PAGE::"Work Types");
        CheckPage(DATABASE::"Jobs Setup", PAGE::"Jobs Setup");
        CheckPage(DATABASE::"Job Posting Group", PAGE::"Job Posting Groups");
        CheckPage(DATABASE::"FA Setup", PAGE::"Fixed Asset Setup");
        CheckPage(DATABASE::"Fixed Asset", PAGE::"Fixed Asset List");
        CheckPage(DATABASE::Insurance, PAGE::"Insurance List");
        CheckPage(DATABASE::"FA Posting Group", PAGE::"FA Posting Groups");
        CheckPage(DATABASE::"FA Journal Template", PAGE::"FA Journal Templates");
        CheckPage(DATABASE::"FA Reclass. Journal Template", PAGE::"FA Reclass. Journal Templates");
        CheckPage(DATABASE::"Insurance Journal Template", PAGE::"Insurance Journal Templates");
        CheckPage(DATABASE::"Depreciation Book", PAGE::"Depreciation Book List");
        CheckPage(DATABASE::"FA Class", PAGE::"FA Classes");
        CheckPage(DATABASE::"FA Subclass", PAGE::"FA Subclasses");
        CheckPage(DATABASE::"FA Location", PAGE::"FA Locations");
        CheckPage(DATABASE::"Insurance Type", PAGE::"Insurance Types");
        CheckPage(DATABASE::Maintenance, PAGE::Maintenance);
        CheckPage(DATABASE::"Human Resources Setup", PAGE::"Human Resources Setup");
        CheckPage(DATABASE::Employee, PAGE::"Employee List");
        CheckPage(DATABASE::"Cause of Absence", PAGE::"Causes of Absence");
        CheckPage(DATABASE::"Cause of Inactivity", PAGE::"Causes of Inactivity");
        CheckPage(DATABASE::"Grounds for Termination", PAGE::"Grounds for Termination");
        CheckPage(DATABASE::"Employment Contract", PAGE::"Employment Contracts");
        CheckPage(DATABASE::Qualification, PAGE::Qualifications);
        CheckPage(DATABASE::Relative, PAGE::Relatives);
        CheckPage(DATABASE::"Misc. Article", PAGE::"Misc. Article Information");
        CheckPage(DATABASE::Confidential, PAGE::Confidential);
        CheckPage(DATABASE::"Employee Statistics Group", PAGE::"Employee Statistics Groups");
        CheckPage(DATABASE::Union, PAGE::Unions);
        CheckPage(DATABASE::"Manufacturing Setup", PAGE::"Manufacturing Setup");
        CheckPage(DATABASE::Family, PAGE::Family);
        CheckPage(DATABASE::"Production BOM Header", PAGE::"Production BOM");
        CheckPage(DATABASE::"Capacity Unit of Measure", PAGE::"Capacity Units of Measure");
        CheckPage(DATABASE::"Work Shift", PAGE::"Work Shifts");
        CheckPage(DATABASE::"Shop Calendar", PAGE::"Shop Calendars");
        CheckPage(DATABASE::"Work Center Group", PAGE::"Work Center Groups");
        CheckPage(DATABASE::"Standard Task", PAGE::"Standard Tasks");
        CheckPage(DATABASE::"Routing Link", PAGE::"Routing Links");
        CheckPage(DATABASE::Stop, PAGE::"Stop Codes");
        CheckPage(DATABASE::Scrap, PAGE::"Scrap Codes");
        CheckPage(DATABASE::"Machine Center", PAGE::"Machine Center List");
        CheckPage(DATABASE::"Work Center", PAGE::"Work Center List");
        CheckPage(DATABASE::"Routing Header", PAGE::Routing);
        CheckPage(DATABASE::"Cost Type", PAGE::"Cost Type List");
        CheckPage(DATABASE::"Cost Journal Template", PAGE::"Cost Journal Templates");
        CheckPage(DATABASE::"Cost Allocation Source", PAGE::"Cost Allocation");
        CheckPage(DATABASE::"Cost Allocation Target", PAGE::"Cost Allocation Target List");
        CheckPage(DATABASE::"Cost Accounting Setup", PAGE::"Cost Accounting Setup");
        CheckPage(DATABASE::"Cost Budget Name", PAGE::"Cost Budget Names");
        CheckPage(DATABASE::"Cost Center", PAGE::"Chart of Cost Centers");
        CheckPage(DATABASE::"Cost Object", PAGE::"Chart of Cost Objects");
        CheckPage(DATABASE::"Cash Flow Setup", PAGE::"Cash Flow Setup");
        CheckPage(DATABASE::"Cash Flow Forecast", PAGE::"Cash Flow Forecast List");
        CheckPage(DATABASE::"Cash Flow Account", PAGE::"Chart of Cash Flow Accounts");
        CheckPage(DATABASE::"Cash Flow Manual Expense", PAGE::"Cash Flow Manual Expenses");
        CheckPage(DATABASE::"Cash Flow Manual Revenue", PAGE::"Cash Flow Manual Revenues");
        CheckPage(DATABASE::"IC Partner", PAGE::"IC Partner List");
        CheckPage(DATABASE::"Base Calendar", PAGE::"Base Calendar List");
        CheckPage(DATABASE::"Finance Charge Text", PAGE::"Reminder Text");
        CheckPage(DATABASE::"Currency for Fin. Charge Terms", PAGE::"Currencies for Fin. Chrg Terms");
        CheckPage(DATABASE::"Currency for Reminder Level", PAGE::"Currencies for Reminder Level");
        CheckPage(DATABASE::"Currency Exchange Rate", PAGE::"Currency Exchange Rates");
        CheckPage(DATABASE::"VAT Statement Name", PAGE::"VAT Statement Names");
        CheckPage(DATABASE::"VAT Statement Line", PAGE::"VAT Statement");
        CheckPage(DATABASE::"No. Series Relationship", PAGE::"No. Series Relationships");
        CheckPage(DATABASE::"User Setup", PAGE::"User Setup");
        CheckPage(DATABASE::"Gen. Journal Template", PAGE::"General Journal Template List");
        CheckPage(DATABASE::"Gen. Journal Batch", PAGE::"General Journal Batches");
        CheckPage(DATABASE::"Gen. Journal Line", PAGE::"General Journal");
        CheckPage(DATABASE::"Item Journal Template", PAGE::"Item Journal Template List");
        CheckPage(DATABASE::"Item Journal Batch", PAGE::"Item Journal Batches");
        CheckPage(DATABASE::"Customer Bank Account", PAGE::"Customer Bank Account List");
        CheckPage(DATABASE::"Vendor Bank Account", PAGE::"Vendor Bank Account List");
        CheckPage(DATABASE::"Cust. Invoice Disc.", PAGE::"Cust. Invoice Discounts");
        CheckPage(DATABASE::"Vendor Invoice Disc.", PAGE::"Vend. Invoice Discounts");
        CheckPage(DATABASE::"Dimension Value", PAGE::"Dimension Value List");
        CheckPage(DATABASE::"Dimension Value Combination", PAGE::"Dimension Combinations");
        CheckPage(DATABASE::"Default Dimension", PAGE::"Default Dimensions");
        CheckPage(DATABASE::"Dimension Translation", PAGE::"Dimension Translations");
        CheckPage(DATABASE::"Dimension Set Entry", PAGE::"Dimension Set Entries");
        CheckPage(DATABASE::"VAT Report Setup", PAGE::"VAT Report Setup");
        CheckPage(DATABASE::"VAT Registration No. Format", PAGE::"VAT Registration No. Formats");
        CheckPage(DATABASE::"G/L Entry", PAGE::"General Ledger Entries");
        CheckPage(DATABASE::"Cust. Ledger Entry", PAGE::"Customer Ledger Entries");
        CheckPage(DATABASE::"Vendor Ledger Entry", PAGE::"Vendor Ledger Entries");
        CheckPage(DATABASE::"Item Ledger Entry", PAGE::"Item Ledger Entries");
        CheckPage(DATABASE::"Sales Header", PAGE::"Sales List");
        CheckPage(DATABASE::"Purchase Header", PAGE::"Purchase List");
        CheckPage(DATABASE::"G/L Register", PAGE::"G/L Registers");
        CheckPage(DATABASE::"Item Register", PAGE::"Item Registers");
        CheckPage(DATABASE::"Item Journal Line", PAGE::"Item Journal Lines");
        CheckPage(DATABASE::"Sales Shipment Header", PAGE::"Posted Sales Shipments");
        CheckPage(DATABASE::"Sales Invoice Header", PAGE::"Posted Sales Invoices");
        CheckPage(DATABASE::"Sales Cr.Memo Header", PAGE::"Posted Sales Credit Memos");
        CheckPage(DATABASE::"Purch. Rcpt. Header", PAGE::"Posted Purchase Receipts");
        CheckPage(DATABASE::"Purch. Inv. Header", PAGE::"Posted Purchase Invoices");
        CheckPage(DATABASE::"Purch. Cr. Memo Hdr.", PAGE::"Posted Purchase Credit Memos");
        CheckPage(DATABASE::"Sales Price", PAGE::"Sales Prices");
        CheckPage(DATABASE::"Purchase Price", PAGE::"Purchase Prices");
        CheckPage(DATABASE::"VAT Entry", PAGE::"VAT Entries");
        CheckPage(DATABASE::"FA Ledger Entry", PAGE::"FA Ledger Entries");
        CheckPage(DATABASE::"Value Entry", PAGE::"Value Entries");
        CheckPage(DATABASE::"Source Code Setup", PAGE::"Source Code Setup");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyImportPackage()
    var
        ConfigSetup: Record "Config. Setup";
        ConfigPackage: Record "Config. Package";
    begin
        // Unit Test to Verify ImportPackage function
        Initialize();

        // 1. Excersize: prepare and import package
        PreparePackageFileNameForWizard(ConfigSetup, ConfigPackage);

        ConfigSetup.SetHideDialog(true);
        ConfigSetup.ImportPackage(ConfigSetup.DecompressPackage(false));

        // 2. Verify Package imported: Config. Package with related tables created
        VerifyPackageWithRelatedRecord(ConfigPackage.Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure VerifyApplyData()
    var
        ConfigLine: Record "Config. Line";
        ConfigPackage: Record "Config. Package";
        ConfigPackageError: Record "Config. Package Error";
        ConfigLinePage: TestPage "Config. Worksheet";
        TableID: Integer;
    begin
        // Verify Apply Data on WS lines with page.
        Initialize();

        // 1. Setup.
        ConfigLine.DeleteAll(true);

        // 2. Excersise: create Config. Package and Line
        TableID := DATABASE::"Gen. Journal Batch";
        CreatePackageDataWithRelation(ConfigPackage, false);
        LibraryRapidStart.CreateConfigLine(ConfigLine, ConfigLine."Line Type"::Table, TableID, '', ConfigPackage.Code, false);

        // 3. Apply Data from created config.line.
        ConfigLinePage.OpenView();
        ConfigLinePage.GotoRecord(ConfigLine);
        ConfigLinePage.ApplyData.Invoke();

        // 4. Verify Errors created on Gen. Journal Batch table
        ConfigPackageError.SetRange("Package Code", ConfigPackage.Code);
        ConfigPackageError.SetRange("Table ID", TableID);
        Assert.IsFalse(ConfigPackageError.IsEmpty, StrSubstNo(IncorrectNumOfTblRecsErr, ConfigPackageError.TableName));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyAccessToPackageCard_EmptyPackageCode()
    var
        ConfigLine: Record "Config. Line";
        ConfigWorksheet: TestPage "Config. Worksheet";
    begin
        Initialize();
        AddConfigLine(ConfigLine."Line Type"::Table, FindTableID(), '');

        ConfigWorksheet.OpenView();
        ConfigWorksheet.First();
        asserterror ConfigWorksheet.PackageCard.Invoke();
    end;

    [Test]
    [HandlerFunctions('ConfigPackageCardHandler')]
    [Scope('OnPrem')]
    procedure VerifyAccessToPackageCard_FilledPackageCode()
    var
        ConfigPackage: Record "Config. Package";
        ConfigWorksheet: TestPage "Config. Worksheet";
        ConfigPackageCard: TestPage "Config. Package Card";
        PackageCode: Variant;
    begin
        Initialize();
        FindTableAndCreatePackageWithWshtLines(ConfigPackage);

        ConfigWorksheet.OpenView();
        ConfigWorksheet.First();

        ConfigPackageCard.Trap();
        ConfigWorksheet.PackageCard.Invoke();
        LibraryVariableStorage.Dequeue(PackageCode);

        Assert.AreEqual(
          ConfigPackage.Code, PackageCode, StrSubstNo(IncorrectValueErr, ConfigPackage.FieldName(Code), 'Config. Package Card'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyAccessToQuestionCard_AreaLine()
    var
        ConfigLine: Record "Config. Line";
        ConfigWorksheet: TestPage "Config. Worksheet";
        ConfigQuestionAreaCard: TestPage "Config. Question Area";
    begin
        Initialize();
        AddConfigLine(ConfigLine."Line Type"::Area, 0, '');

        asserterror PrepareQuestionAreaCard(ConfigWorksheet, ConfigQuestionAreaCard, ConfigLine."Line No.");
        Assert.ExpectedError(AreaLineTestFieldTableErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyAccessToQuestionCard_GroupLine()
    var
        ConfigLine: Record "Config. Line";
        ConfigWorksheet: TestPage "Config. Worksheet";
        ConfigQuestionAreaCard: TestPage "Config. Question Area";
    begin
        Initialize();
        AddConfigLine(ConfigLine."Line Type"::Group, 0, '');

        asserterror PrepareQuestionAreaCard(ConfigWorksheet, ConfigQuestionAreaCard, ConfigLine."Line No.");
        Assert.ExpectedError(GroupLineTestFieldTableErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyAccessToQuestionCard_TableLine()
    var
        ConfigLine: Record "Config. Line";
        ConfigWorksheet: TestPage "Config. Worksheet";
        ConfigQuestionAreaCard: TestPage "Config. Question Area";
        TableID: Integer;
    begin
        Initialize();
        TableID := FindTableID();
        AddConfigLine(ConfigLine."Line Type"::Table, TableID, '');

        asserterror PrepareQuestionAreaCard(ConfigWorksheet, ConfigQuestionAreaCard, ConfigLine."Line No.");
        Assert.IsTrue(StrPos(GetLastErrorText, NoTableIdErr) > 0, NoExpectedErr);
    end;

    [Test]
    [HandlerFunctions('ConfigQuestionAreaHandler')]
    [Scope('OnPrem')]
    procedure AccessToQuestionCard_FromTableLineAndExistingQuestion_RecordOpened()
    var
        ConfigLine: Record "Config. Line";
        ConfigWorksheet: TestPage "Config. Worksheet";
        ConfigQuestionAreaCard: TestPage "Config. Question Area";
        QuestionAreaTableId: Variant;
        TableID: Integer;
    begin
        Initialize();
        TableID := FindTableID();
        AddConfigLine(ConfigLine."Line Type"::Table, TableID, '');
        CreateQuestionArea(TableID);

        PrepareQuestionAreaCard(ConfigWorksheet, ConfigQuestionAreaCard, ConfigLine."Line No.");
        LibraryVariableStorage.Dequeue(QuestionAreaTableId);

        Assert.AreEqual(QuestionAreaTableId, Format(TableID), WrongQuestionAreaErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyAccessToUsersListFromWorksheet()
    var
        ConfigLine: Record "Config. Line";
        ConfigWorksheet: TestPage "Config. Worksheet";
        UsersList: TestPage Users;
    begin
        Initialize();
        AddConfigLine(ConfigLine."Line Type"::Group, 0, '');
        ConfigWorksheet.OpenView();

        UsersList.Trap();
        ConfigWorksheet.Users.Invoke();
        UsersList.Close();
    end;

    [Test]
    [HandlerFunctions('ConfigPackageRecordsHandler')]
    [Scope('OnPrem')]
    procedure PackageDataAvailablePositive()
    var
        ConfigPackage: Record "Config. Package";
        StandardText: Record "Standard Text";
        ConfigWorksheet: TestPage "Config. Worksheet";
    begin
        Initialize();
        CreateAndAssignPackage(ConfigPackage, DATABASE::"Standard Text");
        LibraryRapidStart.CreatePackageData(
          ConfigPackage.Code,
          DATABASE::"Standard Text",
          1,
          StandardText.FieldNo(Code),
          LibraryUtility.GenerateRandomCode(StandardText.FieldNo(Code), DATABASE::"Standard Text"));

        ConfigWorksheet.OpenView();
        ConfigWorksheet.First();

        ConfigWorksheet.PackageData.Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PackageDataAvailableNegative()
    var
        ConfigLine: Record "Config. Line";
        ConfigWorksheet: TestPage "Config. Worksheet";
    begin
        Initialize();
        AddConfigLine(ConfigLine."Line Type"::Table, FindTableID(), '');

        ConfigWorksheet.OpenView();
        ConfigWorksheet.First();
        asserterror ConfigWorksheet.PackageData.Invoke();
        Assert.ExpectedError(PackageCodeNotAssignedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DatabaseDataAvailable()
    var
        StandardText: Record "Standard Text";
        ConfigLine: Record "Config. Line";
        ConfigWorksheet: TestPage "Config. Worksheet";
        StandardTextCodes: TestPage "Standard Text Codes";
    begin
        Initialize();
        StandardText.DeleteAll();
        StandardText.Init();
        StandardText.Code := LibraryUtility.GenerateRandomCode(StandardText.FieldNo(Code), DATABASE::"Standard Text");
        StandardText.Insert(true);

        AddConfigLine(ConfigLine."Line Type"::Table, DATABASE::"Standard Text", '');

        ConfigWorksheet.OpenView();
        ConfigWorksheet.First();

        StandardTextCodes.Trap();
        ConfigWorksheet."Database Data".Invoke();
        Assert.AreEqual(StandardText.Code, Format(StandardTextCodes.Code.Value),
          StrSubstNo(IncorrectValueErr, StandardTextCodes.Code.Caption, StandardTextCodes.Caption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PackageTableFactbox()
    var
        ConfigWorksheet: TestPage "Config. Worksheet";
        ConfigPackageCode: Code[20];
        ConfigPackageName: Text[50];
        ValidRecordsCount: Integer;
        InvalidRecordsCount: Integer;
    begin
        Initialize();
        InitFactBoxTestScenario(ConfigPackageCode, ConfigPackageName, ValidRecordsCount, InvalidRecordsCount);

        ConfigWorksheet.OpenView();
        ConfigWorksheet.First();

        // Validate package code in the factbox
        VerifyEqual(
          ConfigPackageCode,
          ConfigWorksheet."Package Table"."Package Code".Value,
          ConfigWorksheet."Package Table"."Package Code".Caption);

        // Validate package name in the factbox
        VerifyEqual(
          ConfigPackageName,
          ConfigWorksheet."Package Table"."Package Caption".Value,
          ConfigWorksheet."Package Table"."Package Caption".Caption);

        // Validate number of correct package records
        VerifyEqual(
          ValidRecordsCount,
          ConfigWorksheet."Package Table"."No. of Package Records".Value,
          ConfigWorksheet."Package Table"."No. of Package Records".Caption);

        // Validate number of package errors
        VerifyEqual(
          InvalidRecordsCount,
          ConfigWorksheet."Package Table"."No. of Package Errors".Value,
          ConfigWorksheet."Package Table"."No. of Package Errors".Caption);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure VerifyLineApplicationPositive()
    var
        ConfigPackage: Record "Config. Package";
        GLAccount: Record "G/L Account";
        ConfigWorksheet: TestPage "Config. Worksheet";
        GLAccountCode: Code[10];
    begin
        Initialize();
        CreatePackageWithGLAccountTable(ConfigPackage, GLAccountCode);

        ConfigWorksheet.OpenView();
        ConfigWorksheet.FindFirstField("Package Code", ConfigPackage.Code);
        ConfigWorksheet.ApplyData.Invoke();

        Assert.IsTrue(GLAccount.Get(GLAccountCode), RecordNotAppliedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyBlockedLineApplicationNegative()
    var
        ConfigLine: Record "Config. Line";
        ConfigPackage: Record "Config. Package";
        GLAccount: Record "G/L Account";
        ConfigWorksheet: TestPage "Config. Worksheet";
        GLAccountCode: Code[20];
    begin
        Initialize();
        CreatePackageWithGLAccountTable(ConfigPackage, GLAccountCode);

        ChangeLastLineStatus(ConfigLine.Status::Blocked);

        ConfigWorksheet.OpenView();
        ConfigWorksheet.FindFirstField("Package Code", ConfigPackage.Code);
        asserterror ConfigWorksheet.ApplyData.Invoke();

        Assert.ExpectedError(StrSubstNo(LineBlockedErr, ConfigWorksheet."Table ID".Value, ConfigPackage.Code));
        Assert.IsFalse(GLAccount.Get(GLAccountCode), RecordAppliedErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure VerifyIgnoredLineApplicationNegative()
    var
        ConfigPackage: Record "Config. Package";
        ConfigLine: Record "Config. Line";
        GLAccount: Record "G/L Account";
        ConfigWorksheet: TestPage "Config. Worksheet";
        GLAccountCode: Code[20];
    begin
        Initialize();
        CreatePackageWithGLAccountTable(ConfigPackage, GLAccountCode);

        ChangeLastLineStatus(ConfigLine.Status::Ignored);

        ConfigWorksheet.OpenView();
        ConfigWorksheet.ApplyData.Invoke();

        Assert.IsFalse(GLAccount.Get(GLAccountCode), RecordAppliedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyAccessToUsersListFromWizard()
    var
        ConfigWizard: TestPage "Config. Wizard";
        UsersList: TestPage Users;
    begin
        Initialize();
        ConfigWizard.OpenView();

        UsersList.Trap();
        ConfigWizard.Users.Invoke();

        asserterror UsersList.OpenView();
        Assert.ExpectedError(TestPageNotOpenedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyAssignmentToBlockedLine()
    var
        ConfigLine: Record "Config. Line";
        ConfigPackage: Record "Config. Package";
        FirstTestLineNo: Integer;
    begin
        Initialize();
        FirstTestLineNo := InitAssignmentScenario(ConfigPackage);
        ConfigLine.SetFilter("Line No.", '>=%1', FirstTestLineNo);
        ChangeLastLineStatus(ConfigLine.Status::Blocked);

        Commit();

        asserterror ConfigPackageMgt.AssignPackage(ConfigLine, ConfigPackage.Code);

        // This error message should contain table ID and package code.
        // Related code defect 331948 was rejected due to low priority.
        // Assert.ExpectedError(STRSUBSTNO(Text013,ConfigLine."Table ID",ConfigPackage.Code));
        Assert.ExpectedError(StrSubstNo(LineBlockedErr, ConfigLine."Table ID", ''));

        ConfigLine.FindSet();
        repeat
            Assert.AreEqual('', ConfigLine."Package Code",
              StrSubstNo(IncorrectValueErr, ConfigLine.FieldCaption("Package Code"), ConfigLine.TableCaption()));
        until ConfigLine.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyAssignmentToIgnoredLine()
    var
        ConfigPackage: Record "Config. Package";
        ConfigLine: Record "Config. Line";
        FirstTestLineNo: Integer;
    begin
        Initialize();
        FirstTestLineNo := InitAssignmentScenario(ConfigPackage);
        ConfigLine.SetFilter("Line No.", '>=%1', FirstTestLineNo);
        ChangeLastLineStatus(ConfigLine.Status::Ignored);

        ConfigPackageMgt.AssignPackage(ConfigLine, ConfigPackage.Code);

        ConfigLine.FindSet();
        Assert.AreEqual(ConfigPackage.Code, ConfigLine."Package Code",
          StrSubstNo(IncorrectValueErr, ConfigLine.FieldCaption("Package Code"), ConfigLine.TableCaption()));

        ConfigLine.Next();
        Assert.AreEqual('', ConfigLine."Package Code",
          StrSubstNo(IncorrectValueErr, ConfigLine.FieldCaption("Package Code"), ConfigLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfigPackagesListHandler')]
    [Scope('OnPrem')]
    procedure VerifyPackageAssignment()
    var
        ConfigPackage: Record "Config. Package";
        ConfigLine: Record "Config. Line";
        ConfigWorksheet: TestPage "Config. Worksheet";
        FirstTestLineNo: Integer;
    begin
        Initialize();
        FirstTestLineNo := InitAssignmentScenario(ConfigPackage);
        ConfigLine.SetFilter("Line No.", '>=%1', FirstTestLineNo);
        ConfigLine.FindFirst();

        ConfigWorksheet.OpenEdit();

        ConfigWorksheet.GotoRecord(ConfigLine);
        LibraryVariableStorage.Enqueue(ConfigPackage.Code);
        ConfigWorksheet.AssignPackage.Invoke();

        Assert.AreEqual(ConfigPackage.Code, ConfigWorksheet."Package Code".Value,
          StrSubstNo(IncorrectValueErr, ConfigWorksheet."Package Code".Caption, ConfigWorksheet.Caption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyGetRelatedTablesAction()
    var
        ConfigLine: Record "Config. Line";
        ConfigWorksheet: TestPage "Config. Worksheet";
    begin
        // SETUP
        Initialize();
        AddConfigLine(ConfigLine."Line Type"::Table, DATABASE::"Item Unit of Measure", '');
        ConfigLine.SetRange("Package Code", '');
        ConfigLine.FindFirst();

        ConfigWorksheet.OpenEdit();
        ConfigWorksheet.GotoRecord(ConfigLine);

        // EXECUTE the Get Related Tables action
        ConfigWorksheet.GetRelatedTables.Invoke();

        // VERIFY that Worksheet was updated with source table information + related tables information
        ConfigWorksheet.Next();
        Assert.AreEqual(Format(DATABASE::Item), Format(ConfigWorksheet."Table ID"), IncorrecrTableIDErr);
        ConfigWorksheet.Next();
        Assert.AreEqual(Format(DATABASE::"Unit of Measure"), Format(ConfigWorksheet."Table ID"), IncorrecrTableIDErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure VerifyDeleteDuplicateLinesAction()
    var
        ConfigLine: Record "Config. Line";
        ConfigPackage: Record "Config. Package";
        ConfigWorksheet: TestPage "Config. Worksheet";
        NoOfConfigLineRecordsBefore: Integer;
    begin
        // SETUP
        // Config Line with a different Package Code is not considered as duplicate
        Initialize();
        NoOfConfigLineRecordsBefore := ConfigLine.Count();

        LibraryRapidStart.CreatePackage(ConfigPackage);

        AddConfigLine(ConfigLine."Line Type"::Table, DATABASE::"Item Unit of Measure", '');
        FindFirstConfigLine(ConfigLine);
        ConfigPackageMgt.AssignPackage(ConfigLine, ConfigPackage.Code);

        AddConfigLine(ConfigLine."Line Type"::Table, DATABASE::Item, '');
        AddConfigLine(ConfigLine."Line Type"::Table, DATABASE::"Item Unit of Measure", '');
        AddConfigLine(ConfigLine."Line Type"::Table, DATABASE::Item, '');   // Duplicate
        AddConfigLine(ConfigLine."Line Type"::Table, DATABASE::"Item Unit of Measure", ''); // Duplicate
        AddConfigLine(ConfigLine."Line Type"::Table, DATABASE::Vendor, '');

        ConfigWorksheet.OpenEdit();

        // EXECUTE the Delete Duplicated Lines action
        ConfigWorksheet.DeleteDuplicateLines.Invoke();

        // VERIFY that duplicated lines were removed from the Worksheet, and the other lines are still there
        ConfigWorksheet.First();
        Assert.AreEqual(Format(DATABASE::"Item Unit of Measure"), Format(ConfigWorksheet."Table ID"), IncorrecrTableIDErr);
        ConfigWorksheet.Next();
        Assert.AreEqual(Format(DATABASE::Item), Format(ConfigWorksheet."Table ID"), IncorrecrTableIDErr);
        ConfigWorksheet.Next();
        Assert.AreEqual(Format(DATABASE::"Item Unit of Measure"), Format(ConfigWorksheet."Table ID"), IncorrecrTableIDErr);
        ConfigWorksheet.Next();
        Assert.AreEqual(Format(DATABASE::Vendor), Format(ConfigWorksheet."Table ID"), IncorrecrTableIDErr);
        Assert.AreEqual(NoOfConfigLineRecordsBefore, ConfigLine.Count - 4, StrSubstNo(IncorrectNumOfTblRecsErr, ConfigLine.TableName));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyInWorksheetPropertyIsNotSetForRelatedTables()
    var
        ConfigLine: Record "Config. Line";
        ConfigWorksheet: TestPage "Config. Worksheet";
    begin
        // check that Related Table FactBox is accessible and shows related table list and related table can be added
        // SETUP
        Initialize();
        ConfigWorksheet.OpenNew();
        ConfigWorksheet."Line Type".SetValue(ConfigLine."Line Type"::Table);

        // EXECUTE: Validate TableID
        ConfigWorksheet."Table ID".SetValue(DATABASE::"Item Unit of Measure");

        // VERIFY that "In Worksheet" field is empty for all tables that have not been transferred to workshet
        ConfigWorksheet."Related Tables".First();
        Assert.AreEqual('', Format(ConfigWorksheet."Related Tables"."In Worksheet"), IncorrectRelatedTableIDErr);

        ConfigWorksheet."Related Tables".Next();
        Assert.AreEqual('', Format(ConfigWorksheet."Related Tables"."In Worksheet"), IncorrectRelatedTableIDErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyGetRelatedTablesSetsInWorksheetProperty()
    var
        ConfigLine: Record "Config. Line";
        ConfigWorksheet: TestPage "Config. Worksheet";
    begin
        // SETUP
        Initialize();
        AddConfigLine(ConfigLine."Line Type"::Table, DATABASE::"Item Unit of Measure", '');
        ConfigWorksheet.OpenEdit();
        ConfigWorksheet.First();

        // EXECUTE the Get Related Tables action
        ConfigWorksheet.GetRelatedTables.Invoke();

        // VERIFY that "In Worksheet" field is set for all tables transferred to worksheet
        ConfigWorksheet."Related Tables".First();
        Assert.AreEqual(Format(true), Format(ConfigWorksheet."Related Tables"."In Worksheet"), IncorrectRelatedTableIDErr);

        ConfigWorksheet."Related Tables".Next();
        Assert.AreEqual(Format(true), Format(ConfigWorksheet."Related Tables"."In Worksheet"), IncorrectRelatedTableIDErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyRelatedTableFactbox_View()
    var
        ConfigLine: Record "Config. Line";
        ConfigWorksheet: TestPage "Config. Worksheet";
    begin
        // check that Related Table FactBox is accessible and shows related table list and related table can be added
        // SETUP
        Initialize();
        ConfigWorksheet.OpenNew();
        ConfigWorksheet."Line Type".SetValue(ConfigLine."Line Type"::Table);

        // EXECUTE: Validate TableID
        ConfigWorksheet."Table ID".SetValue(DATABASE::"Item Unit of Measure");

        // VERIFY that Related Table FactBox contains correct data
        ConfigWorksheet."Related Tables".First();
        Assert.AreEqual(
          Format(DATABASE::Item), Format(ConfigWorksheet."Related Tables"."Relation Table ID"),
          IncorrectRelatedTableIDErr);
        ConfigWorksheet."Related Tables".Next();
        Assert.AreEqual(Format(DATABASE::"Unit of Measure"),
          Format(ConfigWorksheet."Related Tables"."Relation Table ID"), IncorrectRelatedTableIDErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure VerifyQuestionsFactbox_ViewAndActions()
    var
        Currency: Record Currency;
        ConfigQuestionAreaPage: TestPage "Config. Question Area";
        ConfigWorksheet: TestPage "Config. Worksheet";
        Answers: array[4] of Text[250];
    begin
        // test verifies that Answers can be applied and Questions FactBox has correct value and it is not editable
        // SETUP creates values to apply as Answers, Questions and Question Area
        Initialize();

        InitCurrencyQuestionsAnswersScenario(Answers, ConfigQuestionAreaPage);

        // EXECUTE applying the Answers
        ConfigQuestionAreaPage.ApplyAnswers.Invoke();

        // VERIFY that table data was changed (Code, Last Date Adjusted, Description, Invoice Rounding Precision)
        if Currency.Get(Answers[1]) then begin
            Assert.AreEqual(Answers[2], Format(Currency."Last Date Adjusted"), StrSubstNo(FielValueNotUpdatedErr, 'Last Date Adjusted'));
            Assert.AreEqual(Answers[3], Currency.Description, StrSubstNo(FielValueNotUpdatedErr, 'Description'));
            Assert.AreEqual(
              Answers[4], Format(Currency."Invoice Rounding Precision"), StrSubstNo(FielValueNotUpdatedErr, 'Invoice Rounding Precision'));
        end else
            Error(RecNotAddedToTblErr, Currency.TableCaption());

        ConfigWorksheet.OpenEdit();
        // VERIFY that the Questions FactBox has correct values (Code, Due Date Calculation, Discount %, Description)
        ConfigWorksheet.Control22.First();
        repeat
            case Format(ConfigWorksheet.Control22.Question.Value) of
                'Code?':
                    Assert.AreEqual(
                      Answers[1], ConfigWorksheet.Control22.Answer.Value, StrSubstNo(AnswerNotUpdatedErr, 'Code?'));
                'Last Date Adjusted?':
                    Assert.AreEqual(Answers[2], ConfigWorksheet.Control22.Answer.Value,
                      StrSubstNo(AnswerNotUpdatedErr, 'Last Date Adjusted?'));
                'Description?':
                    Assert.AreEqual(
                      Answers[3], ConfigWorksheet.Control22.Answer.Value, StrSubstNo(AnswerNotUpdatedErr, 'Description?'));
                'Invoice Rounding Precision?':
                    Assert.AreEqual(Answers[4], ConfigWorksheet.Control22.Answer.Value,
                      StrSubstNo(AnswerNotUpdatedErr, 'Invoice Rounding Precision?'));
            end;
        until not ConfigWorksheet.Control22.Next();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyPromotedTables_Area()
    var
        ConfigWorksheet: TestPage "Config. Worksheet";
    begin
        // negative test; this test verifies that lines with type 'Area' cannot have the property Promoted Table = TRUE
        // SETUP creates a line with the 'Area' type
        Initialize();

        AddConfigLine(0, 0, LibraryUtility.GenerateGUID());
        ConfigWorksheet.OpenEdit();
        ConfigWorksheet.First();

        asserterror ConfigWorksheet."Promoted Table".SetValue(Format(true));
        Assert.ExpectedError(NotTblLineTypeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyPromotedTables_Group()
    var
        ConfigWorksheet: TestPage "Config. Worksheet";
    begin
        // negative test; this test verifies that lines with type 'Group' cannot have the property Promoted Table = TRUE
        // SETUP creates a line with the 'Group' type
        Initialize();

        AddConfigLine(1, 0, LibraryUtility.GenerateGUID());
        ConfigWorksheet.OpenEdit();
        ConfigWorksheet.First();

        asserterror ConfigWorksheet."Promoted Table".SetValue(Format(true));
        Assert.ExpectedError(NotTblLineTypeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyPromotedTablesFiltering()
    var
        ConfigLine: Record "Config. Line";
        ConfigWorksheet: TestPage "Config. Worksheet";
        TableID: Integer;
        Counter: Integer;
        MaxLines: Integer;
    begin
        // test verifies that the Promoted Tables Only button works: 1) only Promoted tables are shown at the first click; 2) all the tables are shown at the second click.
        // SETUP creates lines of tables at the Worksheet
        Initialize();
        MaxLines := LibraryRandom.RandInt(5);
        for Counter := 1 to MaxLines do begin
            TableID := FindNextTableID(LibraryRandom.RandIntInRange(3, 9));
            AddConfigLine(2, TableID, '');
        end;

        FindFirstConfigLine(ConfigLine);
        ConfigWorksheet.OpenEdit();
        ConfigWorksheet.GotoRecord(ConfigLine);
        ConfigWorksheet."Promoted Table".SetValue(Format(true));

        // EXECUTE click on the Promoted Tables Only button
        ConfigWorksheet.PromotedOnly.Invoke();
        // VERIFY that only Promoted tables are shown
        Assert.AreEqual(1, CountConfigWorksheetPageLines(ConfigWorksheet), IncorrectQtyOfLinesErr);

        // EXECUTE click on the Promoted Tables Only button
        ConfigWorksheet.PromotedOnly.Invoke();
        // VERIFY that all the tables are shown
        Assert.AreEqual(MaxLines, CountConfigWorksheetPageLines(ConfigWorksheet), IncorrectQtyOfLinesErr);
    end;

    [Test]
    [HandlerFunctions('ConfigPackagesPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyAssignPackagePageAction()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigLine: Record "Config. Line";
        ConfigWorksheet: TestPage "Config. Worksheet";
        ConfigPackageCode: Code[20];
        TableID: Integer;
        LineNo: Integer;
    begin
        // test verifies that the package can be assigned to tables one by one, then a table can be excluded from the package
        // SETUP creates lines in the Worksheet and package
        Initialize();
        TableID := FindTableID();
        AddConfigLine(2, TableID, '');
        TableID := FindNextTableID(TableID);
        AddConfigLine(2, TableID, '');
        LibraryRapidStart.CreatePackage(ConfigPackage);
        ConfigPackageCode := ConfigPackage.Code;
        LibraryVariableStorage.Enqueue(ConfigPackageCode);

        FindFirstConfigLine(ConfigLine);
        LineNo := ConfigLine."Line No.";
        ConfigWorksheet.OpenEdit();
        // EXECUTE the assigning package to table by the page button Assign Package
        ConfigWorksheet.GotoRecord(ConfigLine);
        repeat
            ConfigWorksheet.AssignPackage.Invoke();
            // VERIFY that package was assigned
            Assert.AreEqual(ConfigPackageCode, ConfigWorksheet."Package Code".Value, ConfigPackageNotAssignedErr);
        until ConfigWorksheet.Next();

        // EXECUTE the deleting table from package (not from the Worksheet!)
        ConfigPackageTable.SetRange("Package Code", ConfigPackageCode);
        ConfigPackageTable.FindFirst();
        ConfigPackageTable.Delete(true);

        // VERIFY that the package is not assigned to excluded table (refreshing of page is needed)
        ConfigWorksheet.Close();
        ConfigWorksheet.OpenView();
        ConfigWorksheet.GotoKey(LineNo);
        Assert.AreEqual('', ConfigWorksheet."Package Code".Value, LineNotExclFromConfigPackageErr);
    end;

    [Test]
    [HandlerFunctions('ConfigPackagesPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyAssignPackagePage_SameTablesOneByOne()
    var
        ConfigPackage: Record "Config. Package";
        ConfigLine: Record "Config. Line";
        ConfigWorksheet: TestPage "Config. Worksheet";
        ConfigPackageCode: Code[20];
        TableID: Integer;
    begin
        // test verifies that the package cannot be assigned to the same tables
        // SETUP creates lines in the Worksheet and package; the tables in lines are the same
        Initialize();
        TableID := FindTableID();
        AddConfigLine(2, TableID, '');
        AddConfigLine(2, TableID, '');
        LibraryRapidStart.CreatePackage(ConfigPackage);
        ConfigPackageCode := ConfigPackage.Code;
        LibraryVariableStorage.Enqueue(ConfigPackageCode);

        FindFirstConfigLine(ConfigLine);
        ConfigLine.Reset();
        ConfigWorksheet.OpenEdit();
        // EXECUTE the assigning package to table by the page button Assign Package
        ConfigWorksheet.GotoRecord(ConfigLine);
        LibraryVariableStorage.Enqueue(ConfigPackageCode);
        ConfigWorksheet.AssignPackage.Invoke();

        ConfigWorksheet.Next();
        // VERIFY that the package cannot be assigned to the tables with the same ID as a previos table
        LibraryVariableStorage.Enqueue(ConfigPackageCode);
        asserterror ConfigWorksheet.AssignPackage.Invoke();
        Assert.ExpectedError(SameTblReferenceErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyLineMovingBetweenGroups()
    var
        ConfigLine: Record "Config. Line";
        ConfigWorksheet: TestPage "Config. Worksheet";
        TableID: Integer;
        TableID1: Integer;
        TableID2: Integer;
    begin
        // test verifies that lines in the Worksheet can be moved up and down
        // SETUP creates several lines in the Worksheet
        Initialize();
        AddConfigLine(ConfigLine."Line Type"::Area, 0, LibraryUtility.GenerateGUID());
        AddConfigLine(ConfigLine."Line Type"::Group, 0, LibraryUtility.GenerateGUID());
        TableID := FindTableID();
        AddConfigLine(ConfigLine."Line Type"::Table, TableID, '');
        TableID1 := TableID;

        AddConfigLine(ConfigLine."Line Type"::Group, 0, LibraryUtility.GenerateGUID());
        TableID := FindNextTableID(TableID);
        AddConfigLine(ConfigLine."Line Type"::Table, TableID, '');
        TableID2 := TableID;

        SetVerticalSorting(ConfigLine);
        ConfigLine.SetRange("Table ID", TableID1);
        ConfigLine.FindFirst();

        ConfigWorksheet.OpenEdit();

        // EXECUTE moving down action
        ConfigWorksheet.GotoRecord(ConfigLine);
        ConfigWorksheet.MoveDown.Invoke();
        ConfigWorksheet.MoveDown.Invoke();
        // VERIFY that the line was moved down
        ConfigLine.FindFirst();
        Assert.AreEqual(ConfigLine."Vertical Sorting", FindNumberOfLineAtWorksheetPage(ConfigLine, ConfigWorksheet), LineNotMovedDownErr);

        ConfigLine.SetRange("Table ID", TableID2);
        ConfigLine.FindFirst();

        // EXECUTE moving up action
        ConfigWorksheet.GotoRecord(ConfigLine);
        ConfigWorksheet.MoveUp.Invoke();
        // VERIFY that the line was moved up
        ConfigLine.FindFirst();
        Assert.AreEqual(ConfigLine."Vertical Sorting", FindNumberOfLineAtWorksheetPage(ConfigLine, ConfigWorksheet), LineNotMovedUpErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure VerifyApplyDataForSelection()
    var
        ConfigLine: Record "Config. Line";
        ConfigPackage: Record "Config. Package";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        JournalTemplateName: Code[10];
        JournalBatchName: Code[10];
    begin
        // Verify Apply Data can be applied on some WS lines: unit test for 2 lines.
        Initialize();

        // 1. Excersise: create Config. Package and Line
        CreateConfigPackageAndLine(ConfigPackage, ConfigLine, JournalTemplateName, JournalBatchName);

        // 2. Apply Data from created config.line.
        ConfigLine.SetRange("Package Code", ConfigPackage.Code);
        ConfigPackageMgt.ApplyConfigLines(ConfigLine);

        // 3. Verify that records created in database.
        Assert.IsTrue(GenJournalTemplate.Get(JournalTemplateName), StrSubstNo(RecNotAddedToTblErr, GenJournalTemplate.TableName));
        Assert.IsTrue(
          GenJournalBatch.Get(JournalTemplateName, JournalBatchName), StrSubstNo(RecNotAddedToTblErr, GenJournalBatch.TableName));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyAssignParentLineNos()
    var
        ConfigLine: Record "Config. Line";
        TableID: Integer;
        GroupLineNo: Integer;
    begin
        // Unit test to verify ConfigMgt.AssignParentLineNos
        Initialize();

        // 1. Excersize: create WS Lines and AssignParentLineNos
        TableID := FindTableID();
        AddConfigLine(ConfigLine."Line Type"::Group, 0, '');
        GroupLineNo := ConfigLine."Line No.";
        AddConfigLine(ConfigLine."Line Type"::Table, TableID, '');
        ConfigMgt.AssignParentLineNos();

        // 2. Verify  Parent Line No. for table
        ConfigLine.FindLast();
        Assert.AreEqual(GroupLineNo, ConfigLine."Parent Line No.",
          StrSubstNo(IncorrectValueErr, ConfigLine.FieldName("Parent Line No."), ConfigLine.TableName));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyLastTableDeletionDeletesRelatedTables()
    var
        ConfigLine: Record "Config. Line";
        ConfigRelatedTable: Record "Config. Related Table";
        TableID: Integer;
    begin
        // Verify that related tables are cleaned up when the config. line is deleted if there are no more lines with the same table id in the worksheet
        Initialize();

        // Setup: Create config. line with related tables
        TableID := FindTableWithRelatedTables();
        LibraryRapidStart.CreateConfigLine(ConfigLine, ConfigLine."Line Type"::Table, TableID, '', '', false);

        // Excercise: Delete config. line
        ConfigLine.Delete(true);

        // Verify: Related tables have been deleted
        ConfigRelatedTable.SetRange("Table ID", TableID);
        Assert.IsTrue(ConfigRelatedTable.IsEmpty, RelatedTablesMustBeDeletedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyWorksheetLineDeletionSkipsRelatedTables()
    var
        ConfigLine: Record "Config. Line";
        ConfigRelatedTable: Record "Config. Related Table";
        TableID: Integer;
    begin
        // Verify that related tables are not deleted when the config. line is deleted if there are lines with the same table id in the worksheet
        Initialize();

        // Setup: Create several config. lines with the same table ID having related tables
        TableID := FindTableWithRelatedTables();
        LibraryRapidStart.CreateConfigLine(ConfigLine, ConfigLine."Line Type"::Table, TableID, '', '', false);
        LibraryRapidStart.CreateConfigLine(ConfigLine, ConfigLine."Line Type"::Table, TableID, '', '', false);

        // Excercise: Delete one of the config. lines
        ConfigLine.Delete(true);

        // Verify: Related tables have not been deleted
        ConfigRelatedTable.SetRange("Table ID", TableID);
        Assert.IsFalse(ConfigRelatedTable.IsEmpty, RelatedTablesMustNotBeDeletedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyGetRelatedTablesSkipsReferringTable()
    var
        AllObj: Record AllObj;
        ConfigLine: Record "Config. Line";
        ConfigMgt: Codeunit "Config. Management";
        TableID: Integer;
    begin
        // Verify that a table from a worksheet is not added to the worksheet for the second time after getting related tables
        Initialize();

        TableID := FindTableWithRelatedTables();
        LibraryRapidStart.CreateConfigLine(ConfigLine, ConfigLine."Line Type"::Table, TableID, '', '', false);

        AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
        AllObj.SetRange("Object ID", TableID);
        ConfigMgt.GetConfigTables(AllObj, false, true, false, false, false);

        ConfigLine.SetRange("Table ID", TableID);
        Assert.AreEqual(1, ConfigLine.Count, StrSubstNo(TableMustNotBeIncludedErr, TableID));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyDimAsColumnsCannotBeSetWithoutPackage()
    var
        ConfigLine: Record "Config. Line";
    begin
        // [FEATURE] [Dimension]
        Initialize();
        // [GIVEN] Create worksheet line with <blank> package code
        LibraryRapidStart.CreateConfigLine(ConfigLine, ConfigLine."Line Type"::Table, DATABASE::Customer, '', '', false);

        // [WHEN] Attempt to set "Dimensions as Columns" as 'Yes'
        asserterror ConfigLine.Validate("Dimensions as Columns", true);

        // [THEN] Error: "Code cannot be empty"
        Assert.ExpectedError(StrSubstNo(CodeCannotBeEmptyErr, ConfigLine.FieldCaption("Package Code"), ConfigLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfigPackageCardHandler')]
    [Scope('OnPrem')]
    procedure VerifyPackageCardAssignedToGroupLineCanBeOpened()
    var
        ConfigLine: Record "Config. Line";
    begin
        Initialize();
        VerifyPackageCardAssignedToGroupOrAreaLineCanBeOpened_Helper(ConfigLine."Line Type"::Group);
    end;

    [Test]
    [HandlerFunctions('ConfigPackageCardHandler')]
    [Scope('OnPrem')]
    procedure VerifyPackageCardAssignedToAreaLineCanBeOpened()
    var
        ConfigLine: Record "Config. Line";
    begin
        Initialize();
        VerifyPackageCardAssignedToGroupOrAreaLineCanBeOpened_Helper(ConfigLine."Line Type"::Area);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyPackageCardIsNotOpenedIfPackageNotAssigned_GroupLine()
    var
        ConfigLine: Record "Config. Line";
    begin
        Initialize();
        VerifyPackageCardIsNotOpenedIfPackageNotAssigned_Helper(ConfigLine."Line Type"::Group);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyPackageCardIsNotOpenedIfPackageNotAssigned_AreaLine()
    var
        ConfigLine: Record "Config. Line";
    begin
        Initialize();
        VerifyPackageCardIsNotOpenedIfPackageNotAssigned_Helper(ConfigLine."Line Type"::Area);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyImportExportDisabledWithoutWriteAccessOnConfigPackageCard()
    var
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        ConfigPackageCard: TestPage "Config. Package Card";
    begin
        // [SCENARIO 262975] Import\Export functions disabled if user doesn't have write access to config package table
        Initialize();

        // [GIVEN] User doesn't have access to the config package table
        LibraryLowerPermissions.SetTeamMember();

        // [WHEN] Config. Package Card is opened
        ConfigPackageCard.OpenView();

        // [THEN] Import\Export fields should be disabled
        Assert.IsFalse(ConfigPackageCard.ImportFromExcel.Enabled(), FieldShouldBeDisabledErr);
        Assert.IsFalse(ConfigPackageCard.ExportToExcel.Enabled(), FieldShouldBeDisabledErr);
        Assert.IsFalse(ConfigPackageCard.ImportPackage.Enabled(), FieldShouldBeDisabledErr);
        Assert.IsFalse(ConfigPackageCard.ExportPackage.Enabled(), FieldShouldBeDisabledErr);

        // [THEN] Import\Export fields should be disabled on subform
        Assert.IsFalse(ConfigPackageCard.Control10.ImportFromExcel.Enabled(), FieldShouldBeDisabledErr);
        Assert.IsFalse(ConfigPackageCard.Control10.ExportToExcel.Enabled(), FieldShouldBeDisabledErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyImportExportDisabledWithoutWriteAccessOnConfigPackages()
    var
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        ConfigPackages: TestPage "Config. Packages";
    begin
        // [SCENARIO 262975] Import\Export functions disabled if user doesn't have write access to config package table
        Initialize();

        // [GIVEN] User doesn't have access to the config package table
        LibraryLowerPermissions.SetTeamMember();

        // [WHEN] Config. Packages form is opened
        ConfigPackages.OpenView();

        // [THEN] Import\Export fields should be disabled
        Assert.IsFalse(ConfigPackages.ExportToExcel.Enabled(), FieldShouldBeDisabledErr);
        Assert.IsFalse(ConfigPackages.ImportPackage.Enabled(), FieldShouldBeDisabledErr);
        Assert.IsFalse(ConfigPackages.ImportFromExcel.Enabled(), FieldShouldBeDisabledErr);
        Assert.IsFalse(ConfigPackages.ExportPackage.Enabled(), FieldShouldBeDisabledErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyImportExportEnabledWithWriteAccessOnConfigPackageCard()
    var
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        ConfigPackageCard: TestPage "Config. Package Card";
    begin
        // [SCENARIO 262975] Import\Export functions enabled if user has write access to config package table
        Initialize();

        // [GIVEN] User has access to the config package table
        LibraryLowerPermissions.SetO365Full();

        // [WHEN] Config. Package Card is opened
        ConfigPackageCard.OpenView();

        // [THEN] Import\Export fields should be enabled
        Assert.IsTrue(ConfigPackageCard.ImportFromExcel.Enabled(), FieldShouldBeEnabledErr);
        Assert.IsTrue(ConfigPackageCard.ExportToExcel.Enabled(), FieldShouldBeEnabledErr);
        Assert.IsTrue(ConfigPackageCard.ImportPackage.Enabled(), FieldShouldBeEnabledErr);
        Assert.IsTrue(ConfigPackageCard.ExportPackage.Enabled(), FieldShouldBeEnabledErr);

        // [THEN] Import\Export fields should be enabled on subform
        Assert.IsTrue(ConfigPackageCard.Control10.ImportFromExcel.Enabled(), FieldShouldBeDisabledErr);
        Assert.IsTrue(ConfigPackageCard.Control10.ExportToExcel.Enabled(), FieldShouldBeDisabledErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyImportExportEnabledWithWriteAccessOnConfigPackages()
    var
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        ConfigPackages: TestPage "Config. Packages";
    begin
        // [SCENARIO 262975] Import\Export functions enabled if user has write access to config package table
        Initialize();

        // [GIVEN] User has access to the config package table
        LibraryLowerPermissions.SetO365Full();

        // [WHEN] Config. Packages form is opened
        ConfigPackages.OpenView();

        // [THEN] Import\Export fields should be enabled
        Assert.IsTrue(ConfigPackages.ExportToExcel.Enabled(), FieldShouldBeEnabledErr);
        Assert.IsTrue(ConfigPackages.ImportPackage.Enabled(), FieldShouldBeEnabledErr);
        Assert.IsTrue(ConfigPackages.ImportFromExcel.Enabled(), FieldShouldBeEnabledErr);
        Assert.IsTrue(ConfigPackages.ExportPackage.Enabled(), FieldShouldBeEnabledErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportImport_PackageWithWorksheetLine_WorksheetLineCreated()
    var
        ConfigPackage: Record "Config. Package";
        ConfigLine: Record "Config. Line";
    begin
        Initialize();
        FindTableAndCreatePackageWithWshtLines(ConfigPackage);

        ExportImportPackageWithCleanup(ConfigPackage, true);

        ConfigLine.SetRange("Package Code", ConfigPackage.Code);
        Assert.IsTrue(ConfigLine.Count = 1, WrongConfigCreatedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportImport_PackageWithoutWorksheetLine_NoWorksheetLines()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigLine: Record "Config. Line";
        TableId: Integer;
    begin
        Initialize();
        TableId := FindTableID();
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, TableId);

        ExportImportPackageWithCleanup(ConfigPackage, true);

        ConfigLine.SetFilter("Package Code", '%1|%2', ConfigPackage.Code, '');
        Assert.IsTrue(ConfigLine.IsEmpty, ConfigLineCreatedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportImport_PackageWithWorksheetLineWithoutPackageAssignment_NoWorksheetLines()
    var
        ConfigPackage: Record "Config. Package";
        ConfigLine: Record "Config. Line";
    begin
        Initialize();
        ExportImportPackageAndWshtLineWithoutAssignment(ConfigPackage, true);

        ConfigLine.SetFilter("Package Code", '%1|%2', ConfigPackage.Code, '');
        Assert.IsTrue(ConfigLine.IsEmpty, ConfigLineCreatedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportImport_PackageWithoutWshtLineToExistingWshtLine_NoAssignments()
    var
        ConfigPackage: Record "Config. Package";
        ConfigLine: Record "Config. Line";
        AllConfigLines: Integer;
    begin
        Initialize();
        ExportImportPackageAndWshtLineWithoutAssignment(ConfigPackage, false);

        AllConfigLines := ConfigLine.Count();
        ConfigLine.SetRange("Package Code", ConfigPackage.Code);
        Assert.IsTrue(ConfigLine.IsEmpty() and (AllConfigLines > 0), AssignmentErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportImport_PackageWithWshtLineToExistingWshtLine_NoAssignmentsForExisting()
    var
        ConfigPackage: Record "Config. Package";
        ConfigLine: Record "Config. Line";
    begin
        Initialize();
        FindTableAndCreatePackageWithWshtLines(ConfigPackage);

        ExportImportPackageWithCleanup(ConfigPackage, false);

        ConfigLine.SetRange("Package Code", '');
        Assert.IsTrue(not ConfigLine.IsEmpty, AssignmentErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportImport_PackageWithWshtLineToExistingWshtLine_OnlyOneNewWshtLineAdded()
    var
        ConfigPackage: Record "Config. Package";
        ConfigLine: Record "Config. Line";
        AllConfigLines: Integer;
    begin
        Initialize();
        FindTableAndCreatePackageWithWshtLines(ConfigPackage);

        ExportImportPackageWithCleanup(ConfigPackage, false);

        AllConfigLines := ConfigLine.Count();
        ConfigLine.SetRange("Package Code", ConfigPackage.Code);
        Assert.IsTrue((ConfigLine.Count = 1) and (AllConfigLines > 1), WrongConfigCreatedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportImport_OverwritePackage_OnlyOneNewWshtLineAdded()
    var
        ConfigPackage: Record "Config. Package";
        ConfigLine: Record "Config. Line";
    begin
        Initialize();
        FindTableAndCreatePackageWithWshtLines(ConfigPackage);

        ExportImportPackageWithoutCleanup(ConfigPackage);

        ConfigLine.SetRange("Package Code", ConfigPackage.Code);
        Assert.IsTrue(ConfigLine.Count = 1, WrongConfigCreatedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportImport_OverwritePackage_NoAssignmentsForExisting()
    var
        ConfigPackage: Record "Config. Package";
        ConfigLine: Record "Config. Line";
    begin
        Initialize();
        FindTableAndCreatePackageWithWshtLines(ConfigPackage);

        ExportImportPackageWithoutCleanup(ConfigPackage);

        ConfigLine.SetRange("Package Code", '');
        Assert.IsTrue(ConfigLine.Count > 0, AssignmentErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportImport_OverwritePackageWithoutWshtLine_WshtPackageCodeClear()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigLine: Record "Config. Line";
        FileMgt: Codeunit "File Management";
        TableId: Integer;
        FilePath: Text;
    begin
        Initialize();
        TableId := FindTableID();
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, TableId);

        ConfigXMLExchange.SetCalledFromCode(true);
        ConfigXMLExchange.SetHideDialog(true);
        FilePath := FileMgt.ServerTempFileName('xml');
        ConfigPackageTable.SetRange("Package Code", ConfigPackage.Code);
        ConfigXMLExchange.ExportPackageXML(ConfigPackageTable, FilePath);

        AddConfigLine(ConfigLine."Line Type"::Table, TableId, '');
        FindFirstConfigLine(ConfigLine);
        ConfigPackageMgt.AssignPackage(ConfigLine, ConfigPackage.Code);

        ConfigXMLExchange.ImportPackageXML(FilePath);

        ConfigLine.SetRange("Package Code", '');
        Assert.IsTrue(ConfigLine.Count > 0, PackageCodeReserErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletePackage_PackageWithWshtLine_WshtPackageCodeClear()
    var
        ConfigPackage: Record "Config. Package";
        ConfigLine: Record "Config. Line";
    begin
        Initialize();
        FindTableAndCreatePackageWithWshtLines(ConfigPackage);

        CleanupData(ConfigPackage.Code, false);

        ConfigLine.SetRange("Package Code", '');
        Assert.IsTrue(ConfigLine.Count > 0, PackageCodeReserErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure VerifyModifyTableIDNotAvailableDimAsColumnsTrue()
    var
        ConfigLine: Record "Config. Line";
        ConfigPackage: Record "Config. Package";
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO] Table ID cannot be changed in config. line with Dimension As Columns = TRUE
        Initialize();

        // [GIVEN] Config. Line for Customer, where "Dimensions as Columns" is 'Yes'
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreateConfigLine(ConfigLine, ConfigLine."Line Type"::Table, DATABASE::Customer, '', ConfigPackage.Code, true);

        // [WHEN] Modify "Table ID" in Config. Line
        asserterror ConfigLine.Validate("Table ID", FindTableID());

        // [THEN] Error message: 'Dimensions as Columns must be equal to No'
        Assert.ExpectedError(DimAsColTestFieldExpectedErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure VerifyDimAsColumnsClearsWhenDeletePackageTable()
    var
        ConfigLine: Record "Config. Line";
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO] Dimension As Columns in config. line cleared after Package Table was deleted from package
        Initialize();

        // [GIVEN] Config. Line for Customer table, where "Dimensions as Columns" is 'Yes'
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreateConfigLine(ConfigLine, ConfigLine."Line Type"::Table, DATABASE::Customer, '', ConfigPackage.Code, true);

        // [WHEN] Remove package table Customer
        ConfigPackageTable.Get(ConfigPackage.Code, DATABASE::Customer);
        ConfigPackageTable.Delete(true);

        // [THEN] Config. Line, where "Dimensions as Columns" is 'No'
        ConfigLine.FindFirst();
        Assert.IsFalse(ConfigLine."Dimensions as Columns", StrSubstNo(ConfigLine.FieldName("Dimensions as Columns")));
    end;

    [Test]
    [HandlerFunctions('ConfigPackageRecordsPageHandler')]
    [Scope('OnPrem')]
    procedure PackageDataWithDimensionSetID()
    var
        DummyGLEntry: Record "G/L Entry";
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageCard: TestPage "Config. Package Card";
        ProdOrder: Code[20];
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO 380668] Verify field with FIELDNO more then 480 (Dimension Set ID) is shown as package data

        ProdOrder := LibraryUtility.GenerateRandomCode(DummyGLEntry.FieldNo("Prod. Order No."), DATABASE::"G/L Entry");
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"G/L Entry");

        // [GIVEN] Package with 3 fields included, second field is "Dimension Set ID" (480)
        UpdatePackageFields(ConfigPackage);

        // [GIVEN] A third field (FIELDNO 5400) is "Prod. Order No." = "X"
        InsertGLEntryPackageDataWithProdOrderNo(ConfigPackage, ProdOrder);

        // [WHEN] Open "Config. Package Records" page
        LibraryVariableStorage.Enqueue(ProdOrder);
        ConfigPackageCard.OpenView();
        ConfigPackageCard.GotoRecord(ConfigPackage);
        ConfigPackageCard.Control10.GotoRecord(ConfigPackageTable);
        ConfigPackageCard.Control10."No. of Package Records".DrillDown();

        // [THEN] "Prod. Order No." (FIELDNO 5400) = "X" is shown as third colomn
        // Verification is done in ConfigPackageRecordsPageHandler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PackageDataUpdatedWithBlank()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        PaymentTerms: Record "Payment Terms";
    begin
        // [SCENARIO 382545] RapidStart import data with blank value

        Initialize();
        // [GIVEN] PaymentTerms with Description field filled in.
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        LibraryUtility.FillFieldMaxText(PaymentTerms, PaymentTerms.FieldNo(Description));

        // [GIVEN] Package with 2 fields included - No. and Description
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Payment Terms");

        LibraryRapidStart.CreatePackageData(ConfigPackage.Code, DATABASE::"Payment Terms", 1, PaymentTerms.FieldNo(Code), PaymentTerms.Code);
        // [GIVEN] "Description" value is blank
        LibraryRapidStart.CreatePackageData(ConfigPackage.Code, DATABASE::"Payment Terms", 1, PaymentTerms.FieldNo(Description), '');

        // [WHEN] Apply RapidStart package data
        LibraryRapidStart.ApplyPackage(ConfigPackage, true);

        // [THEN] Description field is blank in Payment Terms
        PaymentTerms.Find();
        PaymentTerms.TestField(Description, '');

        // Tear Down
        PaymentTerms.Delete();
        ConfigPackage.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PackageDataUpdatedWithBlankTemplate()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        PaymentTerms: Record "Payment Terms";
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplateLine: Record "Config. Template Line";
    begin
        // [SCENARIO] RapidStart import data with blank value which benongs to Template

        Initialize();
        // [GIVEN] PaymentTerms with Description field filled in.
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        LibraryUtility.FillFieldMaxText(PaymentTerms, PaymentTerms.FieldNo(Description));

        // [GIVEN] Package with 2 fields included - No. and Description
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Payment Terms");

        // [GIVEN] Template has default value for Description
        LibraryRapidStart.CreateConfigTemplateHeader(ConfigTemplateHeader);
        LibraryRapidStart.CreateConfigTemplateLine(ConfigTemplateLine, ConfigTemplateHeader.Code);
        ConfigTemplateLine."Field ID" := PaymentTerms.FieldNo(Description);
        ConfigTemplateLine."Table ID" := DATABASE::"Payment Terms";
        ConfigTemplateLine."Default Value" := CopyStr(
            LibraryUtility.GenerateRandomText(MaxStrLen(PaymentTerms.Description)), 1, MaxStrLen(PaymentTerms.Description));
        ConfigTemplateLine.Modify();
        ConfigPackageTable."Data Template" := ConfigTemplateHeader.Code;
        ConfigPackageTable.Modify();

        LibraryRapidStart.CreatePackageData(ConfigPackage.Code, DATABASE::"Payment Terms", 1, PaymentTerms.FieldNo(Code), PaymentTerms.Code);
        // [GIVEN] "Description" value is blank
        LibraryRapidStart.CreatePackageData(ConfigPackage.Code, DATABASE::"Payment Terms", 1, PaymentTerms.FieldNo(Description), '');

        // [WHEN] Apply RapidStart package data
        LibraryRapidStart.ApplyPackage(ConfigPackage, true);

        // [THEN] Description field contains default value
        PaymentTerms.Find();
        PaymentTerms.TestField(Description, ConfigTemplateLine."Default Value");

        // Tear Down
        PaymentTerms.Delete();
        ConfigPackage.Delete(true);
        ConfigTemplateHeader.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PackageDataUpdatedWithBlankTemplateInherits()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        PaymentTerms: Record "Payment Terms";
        ConfigTemplateHeader: array[2] of Record "Config. Template Header";
        ConfigTemplateLine: array[2] of Record "Config. Template Line";
    begin
        // [SCENARIO] RapidStart import data with blank value which belongs to Template that inherits another one.

        Initialize();
        // [GIVEN] PaymentTerms with Description field filled in.
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        LibraryUtility.FillFieldMaxText(PaymentTerms, PaymentTerms.FieldNo(Description));

        // [GIVEN] Package with 2 fields included - No. and Description
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Payment Terms");

        // [GIVEN] Template has default value for Description
        LibraryRapidStart.CreateConfigTemplateHeader(ConfigTemplateHeader[1]);
        LibraryRapidStart.CreateConfigTemplateLine(ConfigTemplateLine[1], ConfigTemplateHeader[1].Code);
        ConfigTemplateLine[1]."Field ID" := PaymentTerms.FieldNo(Description);
        ConfigTemplateLine[1]."Table ID" := DATABASE::"Payment Terms";
        ConfigTemplateLine[1]."Default Value" := CopyStr(
            LibraryUtility.GenerateRandomText(MaxStrLen(PaymentTerms.Description)), 1, MaxStrLen(PaymentTerms.Description));
        ConfigTemplateLine[1].Modify();

        // [GIVEN] Second Template inherits first one.
        LibraryRapidStart.CreateConfigTemplateHeader(ConfigTemplateHeader[2]);
        LibraryRapidStart.CreateConfigTemplateLine(ConfigTemplateLine[2], ConfigTemplateHeader[2].Code);
        ConfigTemplateLine[2].Type := ConfigTemplateLine[2].Type::Template;
        ConfigTemplateLine[2]."Template Code" := ConfigTemplateHeader[1].Code;
        ConfigTemplateLine[2].Modify();

        ConfigPackageTable."Data Template" := ConfigTemplateHeader[2].Code;
        ConfigPackageTable.Modify();

        LibraryRapidStart.CreatePackageData(ConfigPackage.Code, DATABASE::"Payment Terms", 1, PaymentTerms.FieldNo(Code), PaymentTerms.Code);

        // [GIVEN] "Description" value is blank
        LibraryRapidStart.CreatePackageData(ConfigPackage.Code, DATABASE::"Payment Terms", 1, PaymentTerms.FieldNo(Description), '');

        // [WHEN] Apply RapidStart package data
        LibraryRapidStart.ApplyPackage(ConfigPackage, true);

        // [THEN] Description field contains default value from inherited Template
        PaymentTerms.Find();
        PaymentTerms.TestField(Description, ConfigTemplateLine[1]."Default Value");

        // Tear Down
        PaymentTerms.Delete();
        ConfigPackage.Delete(true);
        ConfigTemplateHeader[1].Delete(true);
        ConfigTemplateHeader[2].Delete(true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ConfigPackageFieldsHandler,SelectRelatedTableHandler')]
    [Scope('OnPrem')]
    procedure UserCanChangeRelatedTableForFieldInConfigPackageWhenAddingTable()
    var
        ConfigPackage: Record "Config. Package";
        TableRelationsMetadata: Record "Table Relations Metadata";
        ConfigValidateManagement: Codeunit "Config. Validate Management";
        ConfigPackageCard: TestPage "Config. Package Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 217835] User can change the related table ID of the field if the one has some related tables at the time of adding table to Config. Package
        Initialize();

        // [GIVEN] Empty Config. Package
        LibraryRapidStart.CreatePackage(ConfigPackage);

        // [GIVEN] Open card of Config. Package and add table with field with 2 or more related tables
        // [GIVEN] Example table Item (27) with field "Sales Unit of Measure" (5425) with related tables "Unit of Measure" (204) and "Item Unit of Measure" (5404)
        FindFieldWithMultiRelation(TableRelationsMetadata);
        ConfigPackageCard.Trap();
        ConfigPackageCard.OpenEdit();
        ConfigPackageCard.GotoRecord(ConfigPackage);

        // [GIVEN] Add table Item (27) to config package
        // [GIVEN] User get message 'Some fields have 2 or more related tables.\Do you want check them?' - TRUE
        // [GIVEN] "Config. Package Field"."Relation Table ID" <> 204
        // Verifying in ConfirmHandler
        LibraryVariableStorage.Enqueue('Some fields have 2 or more related tables.\Do you want check them?');
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(
          ConfigValidateManagement.GetRelationTableID(TableRelationsMetadata."Table ID", TableRelationsMetadata."Field No."));
        ConfigPackageCard.Control10."Table ID".SetValue(TableRelationsMetadata."Table ID");

        // [WHEN] User change related table ID for field "Sales Unit of Measure" (5425) from 204 to 5404
        // Processing in ConfigPackageFieldsHandler and SelectRelatedTableHandler

        // [THEN] "Config. Package Field"."Related Table ID" = 5404
        // Verification in ConfigPackageFieldsHandler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnableDisableActionChangeRelationTableOnPageConfigPackageFields()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        TableRelationsMetadata: Record "Table Relations Metadata";
        ConfigPackageFields: TestPage "Config. Package Fields";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 217835] Action "Change Relation Table" on the page "Config. Package Fields" is enabled for a field with multirelated table and the action is disabled for the field with 1 relation or without relations
        Initialize();

        // [GIVEN] Config. Package with table is containing field with 2 or more related tables
        // [GIVEN] Example table Item (27) with field "Sales Unit of Measure" (5425) with related tables "Unit of Measure" (204) and "Item Unit of Measure" (5404)
        LibraryRapidStart.CreatePackage(ConfigPackage);
        FindFieldWithMultiRelation(TableRelationsMetadata);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, TableRelationsMetadata."Table ID");

        // [GIVEN] Open page "Config. Package Fields"
        ConfigPackageFields.Trap();
        ConfigPackageFields.OpenEdit();
        ConfigPackageFields.FILTER.SetFilter("Package Code", ConfigPackage.Code);
        ConfigPackageFields.FILTER.SetFilter("Table ID", Format(TableRelationsMetadata."Table ID"));

        // [WHEN] Go to record with multirelated table
        ConfigPackageFields.GotoKey(ConfigPackage.Code, TableRelationsMetadata."Table ID", TableRelationsMetadata."Field No.");

        // [THEN] Action "Change Relation Table" is enabled
        Assert.IsTrue(ConfigPackageFields."Change Related Table".Enabled(), 'The action "Change Relation Table" should be enabled.');

        // [WHEN] Go to record without multirelated table (for example field "No." (1))
        ConfigPackageFields.GotoKey(ConfigPackage.Code, TableRelationsMetadata."Table ID", 1);

        // [THEN] Action "Change Relation Table" is disabled
        Assert.IsFalse(ConfigPackageFields."Change Related Table".Enabled(), 'The action "Change Relation Table" should be disabled.');
    end;

    [Test]
    [HandlerFunctions('ConfigPackFieldsHandler')]
    [Scope('OnPrem')]
    procedure OpenPageConfigPackageFieldWithoutFilters()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        "Field": Record "Field";
        TableID: Integer;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 217835] "Config. Package Table"."ShowFilteredPackageFields" with FilterValue = '' opens page "Config. Package Fields" with all fields of table
        Initialize();

        // [GIVEN] Config. package with table
        TableID := DATABASE::"Config. Package Field";
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, TableID);

        // [WHEN] Invoke "Config. Package Table"."ShowFilteredPackageFields" with FilterValue = ''
        ConfigPackageTable.ShowFilteredPackageFields('');

        // [THEN] Page "Config. Package Fields" shows all fields of table
        Field.SetRange(TableNo, TableID);
        Field.SetFilter(Class, '<>%1', Field.Class::FlowField);
        Assert.AreEqual(Field.Count, LibraryVariableStorage.DequeueInteger(), 'Wrong count of record on the page "Config. Package Fields"');
    end;

    [Test]
    [HandlerFunctions('ConfigPackFieldsHandler')]
    [Scope('OnPrem')]
    procedure OpenPageConfigPackageFieldWithFilters()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageField: Record "Config. Package Field";
        TableID: Integer;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 217835] "Config. Package Table"."ShowFilteredPackageFields" with FilterValue = '1' opens page "Config. Package Fields" with only filtered record
        Initialize();

        // [GIVEN] Config. package with table
        TableID := DATABASE::"Config. Package Field";
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, TableID);

        // [WHEN] Invoke "Config. Package Table"."ShowFilteredPackageFields" with FilterValue = '1'
        ConfigPackageTable.ShowFilteredPackageFields(Format(ConfigPackageField.FieldNo("Package Code")));

        // [THEN] Page "Config. Package Fields" shows only one record
        Assert.AreEqual(1, LibraryVariableStorage.DequeueInteger(), 'Wrong count of record on the page "Config. Package Fields"');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TablesOutOfSpecifiedRangeMustNotBeIncludedInConfigUT()
    var
        AllObj: Record AllObj;
        ConfigLine: Record "Config. Line";
        ConfigMgt: Codeunit "Config. Management";
        TableID: Integer;
    begin
        // [FEATURE] [Config. Line] [UT]
        // [SCENARIO 217870] Tables out of ..99000999|2000000004|2000000005 range must not be included in Configuration Worksheet and no error must appear
        Initialize();

        TableID := 99008535; // TempBlob

        AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
        AllObj.SetRange("Object ID", TableID);
        ConfigMgt.GetConfigTables(AllObj, false, true, false, false, false);

        ConfigLine.SetRange("Table ID", TableID);
        Assert.RecordIsEmpty(ConfigLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TablesOfCRMTypeMustNotBeIncludedInConfigUT()
    var
        AllObj: Record AllObj;
        ConfigLine: Record "Config. Line";
        ConfigMgt: Codeunit "Config. Management";
        TableID: Integer;
    begin
        // [FEATURE] [Config. Line] [UT]
        // [SCENARIO 217870] Tables of CRM Type must not be included in Configuration Worksheet
        Initialize();

        TableID := DATABASE::"CRM NAV Connection";

        AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
        AllObj.SetRange("Object ID", TableID);
        ConfigMgt.GetConfigTables(AllObj, false, true, false, false, false);

        ConfigLine.SetRange("Table ID", TableID);
        Assert.RecordIsEmpty(ConfigLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TablesOfExchangeTypeMustNotBeIncludedInConfigUT()
    var
        AllObj: Record AllObj;
        ConfigLine: Record "Config. Line";
        ConfigMgt: Codeunit "Config. Management";
        TableID: Integer;
    begin
        // [FEATURE] [Config. Line] [UT]
        // [SCENARIO 217870] Tables of Exchange Type must not be included in Configuration Worksheet
        Initialize();

        TableID := DATABASE::"Booking Item";

        AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
        AllObj.SetRange("Object ID", TableID);
        ConfigMgt.GetConfigTables(AllObj, false, true, false, false, false);

        ConfigLine.SetRange("Table ID", TableID);
        Assert.RecordIsEmpty(ConfigLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TablesOfNormalTypeCanBeIncludedInConfigUT()
    var
        AllObj: Record AllObj;
        ConfigLine: Record "Config. Line";
        ConfigMgt: Codeunit "Config. Management";
        TableID: Integer;
    begin
        // [FEATURE] [Config. Line] [UT]
        // [SCENARIO 217870] Tables of Normal Type can be included in Configuration Worksheet
        Initialize();

        TableID := DATABASE::Item;

        AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
        AllObj.SetRange("Object ID", TableID);
        ConfigMgt.GetConfigTables(AllObj, false, false, false, false, true);

        ConfigLine.SetRange("Table ID", TableID);
        Assert.RecordCount(ConfigLine, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExtensionTablesCanBeIncludedInConfigUT()
    var
        AllObj: Record AllObj;
        ConfigLine: Record "Config. Line";
        TableID: Integer;
    begin
        // [FEATURE] [Config. Line] [UT]
        // [SCENARIO 217870] Extension tables can be included in Configuration Worksheet
        Initialize();

        TableID := 1070; // "MS - PayPal Standard Account" extension table

        AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
        AllObj.SetRange("Object ID", TableID);
        ConfigMgt.GetConfigTables(AllObj, false, false, false, false, true);

        ConfigLine.SetRange("Table ID", TableID);
        Assert.RecordIsNotEmpty(ConfigLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResultMakeTableFilteConfigManagement()
    var
        TempConfigLine: Record "Config. Line" temporary;
        "Filter": Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 222724] Function "Config. Management"."MakeTableFilter" returns a filter string for Config. Lines with Status " ", "In Progress", "Completed"
        Initialize();

        // [GIVEN] Config. Line with "Table ID" = 1 and Status = " "
        InsertConfigLineWithStatusAndTableID(TempConfigLine, TempConfigLine.Status::" ", 1);

        // [GIVEN] Config. Line with "Table ID" = 2 and Status = "Completed"
        InsertConfigLineWithStatusAndTableID(TempConfigLine, TempConfigLine.Status::Completed, 2);

        // [GIVEN] Config. Line with "Table ID" = 3 and Status = "In Progress"
        InsertConfigLineWithStatusAndTableID(TempConfigLine, TempConfigLine.Status::"In Progress", 3);

        // [WHEN] Invoke "Config. Management"."MakeTableFilter"
        Filter := ConfigMgt.MakeTableFilter(TempConfigLine, false);

        // [THEN] Filter = "1|2|3"
        Assert.AreEqual('1|2|3', Filter, 'Wrong value of Filter');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateMissingCodesWhenKeyStartsFromFieldGreaterThanOne()
    var
        ConfigLine: Record "Config. Line";
        ConfigPackage: Record "Config. Package";
        ConfigPackageError: Record "Config. Package Error";
        TableID: Integer;
    begin
        // [FEATURE] [Config Package]
        // [SCENARIO 231155] Apply data for related table when create missing codes and the primary key starts with field number greater than 1
        Initialize();

        // [GIVEN] Config Line contains one record with fields of the table Item - "No." and "Manufacturer Code"
        TableID := DATABASE::Item;

        // [GIVEN] For "Manufacturer Code" "Create Missing Codes" is on
        CreatePackageDataWithRelationAndCreateMissingCodes(ConfigPackage);
        LibraryRapidStart.CreateConfigLine(ConfigLine, ConfigLine."Line Type"::Table, TableID, '', ConfigPackage.Code, false);

        // [WHEN] Apply package data
        ConfigLine.SetRange("Line No.", ConfigLine."Line No.");
        ConfigPackageMgt.ApplyConfigLines(ConfigLine);

        // [THEN] No errors occur, error list is blank
        ConfigPackageError.SetRange("Package Code", ConfigPackage.Code);
        ConfigPackageError.SetRange("Table ID", TableID);
        Assert.RecordIsEmpty(ConfigPackageError);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateMissingCodesWithCompositeKey()
    var
        UnitOfMeasure: Record "Unit of Measure";
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ConfigLine: Record "Config. Line";
        ConfigPackage: Record "Config. Package";
        ConfigPackageError: Record "Config. Package Error";
        TableID: Integer;
        ItemNo: Code[20];
    begin
        // [FEATURE] [Config Package] [Relation Table]
        // [SCENARIO 274364] Config package can contain composite key when missing code is creating
        Initialize();

        // [GIVEN] Config line contains one record with fields of the table Item - "No." = "N" and "Sales Unit of Measure" = "SUOM"
        // [GIVEN] Database contains "Unit Of Measure" = "SUOM" but does not contain item "N" and "Item Unit of Measure" ["N","SUOM"]
        TableID := DATABASE::Item;
        ItemNo := LibraryUtility.GenerateRandomCode(Item.FieldNo("No."), DATABASE::Item);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);

        // [GIVEN] Config package field relation table Id is set as the table "Item Unit of Measure"
        CreatePackageDataWithItemNoSalesUnitOfMeasure(ConfigPackage, ItemNo, UnitOfMeasure.Code);
        SetConfigPackageFieldRelationTableID(
          ConfigPackage.Code, DATABASE::Item, Item.FieldNo("Sales Unit of Measure"), DATABASE::"Item Unit of Measure");

        LibraryRapidStart.CreateConfigLine(ConfigLine, ConfigLine."Line Type"::Table, TableID, '', ConfigPackage.Code, false);

        // [WHEN] Apply package data
        ConfigLine.SetRange("Line No.", ConfigLine."Line No.");
        ConfigPackageMgt.ApplyConfigLines(ConfigLine);

        // [THEN] No errors occur, error list is blank, database contains the item "N" with "Sales Unit of Measure" = "SUOM" and "Item Unit of Measure" ["N","SUOM"]
        ConfigPackageError.SetRange("Package Code", ConfigPackage.Code);
        ConfigPackageError.SetRange("Table ID", TableID);
        Assert.RecordIsEmpty(ConfigPackageError);

        Item.Get(ItemNo);
        ItemUnitOfMeasure.Get(ItemNo, UnitOfMeasure.Code);
        Item.TestField("Sales Unit of Measure", UnitOfMeasure.Code);
    end;

    [Test]
    [HandlerFunctions('ConfigFieldMappingModalPageHandler')]
    [Scope('OnPrem')]
    procedure AddNewFieldMapping()
    var
        ConfigPackageField: Record "Config. Package Field";
        ConfigFieldMap: Record "Config. Field Map";
        ConfigPackageManagement: Codeunit "Config. Package Management";
    begin
        // [GIVEN] There a config package field
        ConfigPackageField."Package Code" := 'CODE';
        ConfigPackageField."Table ID" := DATABASE::"Config. Package Field";
        ConfigPackageField."Field ID" := ConfigPackageField.FieldNo(Dimension);

        // [WHEN] The Config. Field Mapping page is opened
        // [THEN] It is possible to add new values on the page (verified in the handler) 
        ConfigPackageManagement.ShowFieldMapping(ConfigPackageField);

        // [THEN] Config. Field Map has a record with the fields that correspond to the ones from Config. Package Field table
        ConfigFieldMap.SetRange("Old Value", 'Old value');
        ConfigFieldMap.SetRange("New Value", 'New value');

        Assert.IsTrue(ConfigFieldMap.FindFirst(), 'The record should have been added to the Config. Field Map table');
        Assert.AreEqual(ConfigFieldMap."Package Code", ConfigPackageField."Package Code", 'Package Code should be the same in Config. Package Field and Config. Field Map tables');
        Assert.AreEqual(ConfigFieldMap."Table ID", ConfigPackageField."Table ID", 'Table ID should be the same in Config. Package Field and Config. Field Map tables');
        Assert.AreEqual(ConfigFieldMap."Field ID", ConfigPackageField."Field ID", 'Field ID should be the same in Config. Package Field and Config. Field Map tables');

        ConfigFieldMap.Delete();
    end;

    [ModalPageHandler]
    procedure ConfigFieldMappingModalPageHandler(var ConfigFieldMapping: TestPage "Config. Field Mapping");
    begin
        ConfigFieldMapping."Old Value".SetValue('Old value');
        ConfigFieldMapping."New Value".SetValue('New value');
        ConfigFieldMapping.Next();
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        LibraryRapidStart.CleanUp('');
        APIMockEvents.SetAPIServicesEnabled(false);
    end;

    local procedure CleanupData(PackageCode: Code[20]; DeleteConfigLines: Boolean)
    var
        ConfigPackage: Record "Config. Package";
        ConfigLine: Record "Config. Line";
    begin
        if DeleteConfigLines then begin
            ConfigLine.SetFilter("Package Code", '%1|%2', PackageCode, '');
            ConfigLine.DeleteAll(true);
        end;

        ConfigPackage.SetFilter(Code, '%1|%2', PackageCode, '');
        ConfigPackage.DeleteAll(true);
        ClearLastError();
    end;

    local procedure CreateConfigSetup(var ConfigSetup: Record "Config. Setup")
    begin
        if not ConfigSetup.Get() then begin
            ConfigSetup.Init();
            ConfigSetup.Insert();
        end;
        ConfigSetup.Name := LibraryUtility.GenerateGUID();
        ConfigSetup.Modify();
    end;

    local procedure CheckPage(TableID: Integer; PageID: Integer)
    var
        ConfigMgt: Codeunit "Config. Management";
    begin
        Assert.AreEqual(PageID, ConfigMgt.FindPage(TableID), StrSubstNo(IncorrectPageIdForTableIDErr, TableID));
    end;

    local procedure AddConfigLine(LineType: Option "Area",Group,"Table"; TableID: Integer; LineName: Text[50])
    var
        ConfigLine: Record "Config. Line";
    begin
        LibraryRapidStart.CreateConfigLine(ConfigLine, LineType, TableID, LineName, '', false);
    end;

    local procedure FindTableID(): Integer
    var
        AllObj: Record AllObj;
    begin
        AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
        AllObj.FindFirst();

        exit(AllObj."Object ID");
    end;

    local procedure FindNextTableID(TableID: Integer): Integer
    var
        AllObj: Record AllObj;
    begin
        AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
        AllObj.SetFilter("Object ID", '>%1', TableID);
        AllObj.FindFirst();

        exit(AllObj."Object ID");
    end;

    local procedure FindTableWithRelatedTables(): Integer
    var
        "Field": Record "Field";
    begin
        Field.SetFilter(RelationTableNo, '>0');
        Field.FindFirst();

        exit(Field.TableNo);
    end;

    local procedure FindFieldWithMultiRelation(var TableRelationsMetadata: Record "Table Relations Metadata")
    begin
        TableRelationsMetadata.SetRange("Related Field No.", 2);
        TableRelationsMetadata.SetRange("Condition Field No.", 1);
        TableRelationsMetadata.FindFirst();
    end;

    local procedure InitRemoveTableFromPackage_SameWorksheetTables(var ConfigPackage: array[2] of Record "Config. Package"; var TableID: Integer): Integer
    var
        ConfigLine: array[2] of Record "Config. Line";
        i: Integer;
    begin
        // 2 same tables in worksheet.
        // 2 packages, firts config line is assigned to first package,
        // second one to second package
        TableID := FindTableID();

        for i := 1 to 2 do begin
            LibraryRapidStart.CreatePackage(ConfigPackage[i]);

            AddConfigLine(ConfigLine[i]."Line Type"::Table, TableID, '');
            ConfigLine[i].FindLast();
            ConfigLine[i].SetRecFilter();

            ConfigPackageMgt.AssignPackage(ConfigLine[i], ConfigPackage[i].Code);
        end;

        exit(ConfigLine[1]."Line No.");
    end;

    [HandlerFunctions('MessageHandler')]
    local procedure InitCurrencyQuestionsAnswersScenario(var Answers: array[4] of Text[250]; var ConfigQuestionAreaPage: TestPage "Config. Question Area")
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigQuestionnaire: Record "Config. Questionnaire";
        ConfigQuestionArea: Record "Config. Question Area";
        ConfigQuestion: Record "Config. Question";
        TableID: Integer;
    begin
        Answers[1] := '1';
        Answers[2] := Format(20010101D);
        Answers[3] := 'test';
        Answers[4] := Format(0.01);

        TableID := DATABASE::Currency;
        AddConfigLine(2, TableID, '');
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, TableID);
        LibraryRapidStart.ApplyPackage(ConfigPackage, false);

        LibraryRapidStart.CreateQuestionnaire(ConfigQuestionnaire);
        LibraryRapidStart.CreateQuestionArea(ConfigQuestionArea, ConfigQuestionnaire.Code);
        LibraryRapidStart.CreateQuestion(ConfigQuestion, ConfigQuestionArea);

        ConfigQuestionAreaPage.OpenEdit();
        ConfigQuestionAreaPage.GotoRecord(ConfigQuestionArea);
        ConfigQuestionAreaPage."Table ID".Value := Format(TableID);
        ConfigQuestionAreaPage.UpdateQuestions.Invoke();

        ConfigQuestionAreaPage.ConfigQuestionSubform.First();
        repeat
            case Format(ConfigQuestionAreaPage.ConfigQuestionSubform.Question.Value) of
                'Code?':
                    ConfigQuestionAreaPage.ConfigQuestionSubform.Answer.SetValue(Answers[1]);
                'Last Date Adjusted?':
                    ConfigQuestionAreaPage.ConfigQuestionSubform.Answer.SetValue(Answers[2]);
                'Description?':
                    ConfigQuestionAreaPage.ConfigQuestionSubform.Answer.SetValue(Answers[3]);
                'Invoice Rounding Precision?':
                    ConfigQuestionAreaPage.ConfigQuestionSubform.Answer.SetValue(Answers[4]);
            end;
        until not ConfigQuestionAreaPage.ConfigQuestionSubform.Next();
    end;

    local procedure ChangeConfigLineTableIDLinkedToPackage(var ConfigLine: Record "Config. Line"; var TableID: Integer): Code[20]
    var
        ConfigPackage: Record "Config. Package";
    begin
        // try to change work sheet's Table ID if it is linked to package
        // SETUP
        TableID := FindTableID();
        LibraryRapidStart.CreatePackage(ConfigPackage);
        AddConfigLine(ConfigLine."Line Type"::Table, TableID, '');

        FindFirstConfigLine(ConfigLine);
        ConfigPackageMgt.AssignPackage(ConfigLine, ConfigPackage.Code);

        // EXECUTE
        ConfigLine.Validate("Table ID", FindNextTableID(TableID));

        exit(ConfigPackage.Code);
    end;

    local procedure CreateLineNumberBuffer()
    var
        LineNumberBuffer: Record "Line Number Buffer";
    begin
        LineNumberBuffer.Reset();
        LineNumberBuffer.DeleteAll();

        LineNumberBuffer.Init();
        LineNumberBuffer."Old Line Number" := LibraryRandom.RandInt(1);
        LineNumberBuffer.Insert(true);
        Commit();
    end;

    local procedure GenerateReport_GetConfigTables(TableID: Integer; IncludeWithDataOnly: Boolean; IncludeRelatedTables: Boolean; IncludeDimensionTables: Boolean; IncludeLicensedTablesOnly: Boolean)
    var
        AllObj: Record AllObj;
        GetConfigTables: Report "Get Config. Tables";
    begin
        AllObj.Reset();
        AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
        AllObj.SetRange("Object ID", TableID);

        Clear(GetConfigTables);
        GetConfigTables.SetTableView(AllObj);
        GetConfigTables.InitializeRequest(
          IncludeWithDataOnly, IncludeRelatedTables, IncludeDimensionTables, IncludeLicensedTablesOnly);
        GetConfigTables.UseRequestPage(false);
        GetConfigTables.Run();
    end;

    local procedure InitReassignPackageScenario(var ConfigLine: Record "Config. Line"; var TableID: Integer; var NewPackageCode: Code[20]; var FieldsQty: Integer; var FiltersQty: Integer; var ErrorsQty: Integer)
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageField: Record "Config. Package Field";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageFilter: Record "Config. Package Filter";
        ConfigPackageError: Record "Config. Package Error";
        ConfigPackageCode: Code[20];
    begin
        // check that after package is reassigned linked fields, filters and errors are renamed
        // SETUP
        TableID := FindTableID();
        AddConfigLine(ConfigLine."Line Type"::Table, TableID, '');
        LibraryRapidStart.CreatePackage(ConfigPackage);
        ConfigPackageCode := ConfigPackage.Code;
        LibraryRapidStart.CreatePackage(ConfigPackage);

        ConfigLine.SetRange("Package Code", '');
        ConfigLine.FindFirst();
        ConfigPackageMgt.AssignPackage(ConfigLine, ConfigPackageCode);

        // add filters and errors for each field
        ConfigPackageTable.Get(ConfigPackageCode, TableID);
        AddRelatedRecords(ConfigPackageTable);

        ConfigPackageField.SetRange("Package Code", ConfigPackageCode);
        FieldsQty := ConfigPackageField.Count();
        ConfigPackageFilter.SetRange("Package Code", ConfigPackageCode);
        FiltersQty := ConfigPackageFilter.Count();
        ConfigPackageError.SetRange("Package Code", ConfigPackageCode);
        ErrorsQty := ConfigPackageError.Count();

        NewPackageCode := ConfigPackage.Code;
    end;

    local procedure AddRelatedRecords(ConfigPackageTable: Record "Config. Package Table")
    var
        ConfigPackageFilter: Record "Config. Package Filter";
        ConfigPackageError: Record "Config. Package Error";
        "Field": Record "Field";
    begin
        Field.SetRange(TableNo, ConfigPackageTable."Table ID");
        if Field.FindSet() then
            repeat
                ConfigPackageFilter.Init();
                ConfigPackageFilter."Package Code" := ConfigPackageTable."Package Code";
                ConfigPackageFilter."Table ID" := ConfigPackageTable."Table ID";
                ConfigPackageFilter.Validate("Field ID", Field."No.");
                ConfigPackageFilter.Insert();

                ConfigPackageError.Init();
                ConfigPackageError."Package Code" := ConfigPackageTable."Package Code";
                ConfigPackageError."Table ID" := ConfigPackageTable."Table ID";
                ConfigPackageError.Validate("Field ID", Field."No.");
                ConfigPackageError.Insert();
            until Field.Next() = 0;
    end;

    local procedure VerifyRelatedRecords(PackageCode: Code[20]; TableID: Integer; FieldsQty: Integer; FiltersQty: Integer; ErrorsQty: Integer)
    var
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageField: Record "Config. Package Field";
        ConfigPackageFilter: Record "Config. Package Filter";
        ConfigPackageError: Record "Config. Package Error";
    begin
        ConfigPackageTable.Get(PackageCode, TableID);

        ConfigPackageField.SetRange("Package Code", PackageCode);
        Assert.AreEqual(FieldsQty, ConfigPackageField.Count, StrSubstNo(IncorrectNumOfTblRecsErr, ConfigPackageField.TableCaption()));

        ConfigPackageFilter.SetRange("Package Code", PackageCode);
        Assert.AreEqual(FiltersQty, ConfigPackageFilter.Count, StrSubstNo(IncorrectNumOfTblRecsErr, ConfigPackageFilter.TableCaption()));

        ConfigPackageError.SetRange("Package Code", PackageCode);
        Assert.AreEqual(ErrorsQty, ConfigPackageError.Count, StrSubstNo(IncorrectNumOfTblRecsErr, ConfigPackageError.TableCaption()));
    end;

    local procedure VerifyPackageWithRelatedRecord(PackageCode: Code[20])
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageField: Record "Config. Package Field";
        ConfigPackageFilter: Record "Config. Package Filter";
        ConfigPackageRecord: Record "Config. Package Record";
        ConfigPackageData: Record "Config. Package Data";
        ConfigPackageError: Record "Config. Package Error";
    begin
        ConfigPackageTable.SetRange("Package Code", PackageCode);
        ConfigPackageRecord.SetRange("Package Code", PackageCode);
        ConfigPackageData.SetRange("Package Code", PackageCode);
        ConfigPackageField.SetRange("Package Code", PackageCode);
        ConfigPackageError.SetRange("Package Code", PackageCode);
        ConfigPackageFilter.SetRange("Package Code", PackageCode);

        Assert.IsTrue(ConfigPackage.Get(PackageCode), StrSubstNo(IncorrectNumOfTblRecsErr, ConfigPackage.TableName));
        Assert.IsFalse(ConfigPackageTable.IsEmpty, StrSubstNo(IncorrectNumOfTblRecsErr, ConfigPackageTable.TableName));
        Assert.IsFalse(ConfigPackageRecord.IsEmpty, StrSubstNo(IncorrectNumOfTblRecsErr, ConfigPackageRecord.TableName));
        Assert.IsFalse(ConfigPackageData.IsEmpty, StrSubstNo(IncorrectNumOfTblRecsErr, ConfigPackageData.TableName));
        Assert.IsFalse(ConfigPackageField.IsEmpty, StrSubstNo(IncorrectNumOfTblRecsErr, ConfigPackageField.TableName));
        Assert.IsFalse(ConfigPackageFilter.IsEmpty, StrSubstNo(IncorrectNumOfTblRecsErr, ConfigPackageFilter.TableName));
        Assert.IsTrue(ConfigPackageError.IsEmpty, StrSubstNo(IncorrectNumOfTblRecsErr, ConfigPackageError.TableName));
    end;

    local procedure CreateAndAssignPackage(var ConfigPackage: Record "Config. Package"; TableID: Integer)
    var
        ConfigPackageTable: Record "Config. Package Table";
        ConfigLine: Record "Config. Line";
    begin
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, TableID);
        AddConfigLine(ConfigLine."Line Type"::Table, TableID, '');
        FindFirstConfigLine(ConfigLine);
        ConfigLine.SetRange("Line No.", ConfigLine."Line No.");
        ConfigPackageMgt.AssignPackage(ConfigLine, ConfigPackage.Code);
    end;

    local procedure PrepareQuestionAreaCard(var ConfigWorksheet: TestPage "Config. Worksheet"; var ConfigQuestionAreaCard: TestPage "Config. Question Area"; ConfigLineNo: Integer)
    begin
        ConfigWorksheet.OpenView();
        ConfigWorksheet.GotoKey(ConfigLineNo);

        ConfigQuestionAreaCard.Trap();
        ConfigWorksheet.Questions.Invoke();
    end;

    local procedure CreateCurrencyRecordInPackage(ConfigPackageCode: Code[20]; RecNo: Integer; GLAccountNo: Code[20])
    var
        Currency: Record Currency;
    begin
        LibraryRapidStart.CreatePackageData(ConfigPackageCode, DATABASE::Currency, RecNo,
          Currency.FieldNo(Code), LibraryUtility.GenerateRandomCode(Currency.FieldNo(Code), DATABASE::Currency));
        LibraryRapidStart.CreatePackageData(ConfigPackageCode, DATABASE::Currency, RecNo,
          Currency.FieldNo("Unrealized Gains Acc."), GLAccountNo);
    end;

    local procedure InitFactBoxTestScenario(var ConfigPackageCode: Code[20]; var ConfigPackageName: Text[50]; var ValidRecordsCount: Integer; var InvalidRecordsCount: Integer)
    var
        GLAccount: Record "G/L Account";
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigLine: Record "Config. Line";
        ValidGLAccountNo: Code[20];
        InvalidGLAccountNo: Code[20];
    begin
        // Creating config. package with 2 tables
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::Currency);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"G/L Account");

        // Display these 2 tables in the config. worksheet
        AddConfigLine(ConfigLine."Line Type"::Table, DATABASE::Currency, '');
        AddConfigLine(ConfigLine."Line Type"::Table, DATABASE::"G/L Account", '');

        ValidGLAccountNo := GenerateGLAccountNoFromGUID();
        InvalidGLAccountNo := GenerateGLAccountNoFromGUID();

        // To make "ValidGLAccountNo" actually valid we must create a corresponding package record
        LibraryRapidStart.CreatePackageData(ConfigPackage.Code, DATABASE::"G/L Account", 1, GLAccount.FieldNo("No."), ValidGLAccountNo);

        // The package will contain 4 records: 2 valid and 2 invalid
        CreateCurrencyRecordInPackage(ConfigPackage.Code, 1, ValidGLAccountNo);
        CreateCurrencyRecordInPackage(ConfigPackage.Code, 2, ValidGLAccountNo);
        CreateCurrencyRecordInPackage(ConfigPackage.Code, 3, InvalidGLAccountNo);
        CreateCurrencyRecordInPackage(ConfigPackage.Code, 4, InvalidGLAccountNo);

        ConfigPackageMgt.AssignPackage(ConfigLine, ConfigPackage.Code);

        // ApplyPackage function contains code structure "IF CODEUNIT.RUN THEN". So, without this COMMIT, the test will fail.
        Commit();
        LibraryRapidStart.ApplyPackage(ConfigPackage, false);

        ConfigPackageCode := ConfigPackage.Code;
        ConfigPackageName := ConfigPackage."Package Name";
        ValidRecordsCount := 2;
        InvalidRecordsCount := 2;
    end;

    local procedure VerifyEqual(Expected: Variant; Actual: Variant; FieldCaption: Text[250])
    var
        ConfigPackageTableFactBox: Page "Config. Package Table FactBox";
    begin
        Assert.AreEqual(
          Format(Expected),
          Format(Actual),
          StrSubstNo(IncorrectValueErr, FieldCaption, ConfigPackageTableFactBox.Caption));
    end;

    local procedure GetFileName(FileNameTo: Code[10]): Text[1024]
    begin
        exit(TemporaryPath + FileNameTo + '.xls');
    end;

    local procedure FindFirstConfigLine(var ConfigLine: Record "Config. Line")
    begin
        ConfigLine.Reset();
        ConfigLine.SetRange("Package Code", '');
        ConfigLine.FindFirst();
    end;

    local procedure InitAssignmentScenario(var ConfigPackage: Record "Config. Package"): Integer
    var
        ConfigPackageTable: Record "Config. Package Table";
        ConfigLine: Record "Config. Line";
        TableID: Integer;
    begin
        LibraryRapidStart.CreatePackage(ConfigPackage);

        TableID := FindTableID();
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, TableID);
        AddConfigLine(2, TableID, '');

        TableID := FindNextTableID(TableID);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, TableID);
        AddConfigLine(2, TableID, '');

        ConfigLine.SetRange("Package Code", '');
        ConfigLine.FindFirst();
        exit(ConfigLine."Line No.");
    end;

    local procedure InsertGLEntryPackageDataWithProdOrderNo(ConfigPackage: Record "Config. Package"; ProdOrder: Code[20])
    var
        DummyGLEntry: Record "G/L Entry";
    begin
        LibraryRapidStart.CreatePackageData(ConfigPackage.Code,
          DATABASE::"G/L Entry", 1, DummyGLEntry.FieldNo("Entry No."), '1');
        LibraryRapidStart.CreatePackageData(ConfigPackage.Code,
          DATABASE::"G/L Entry", 1, DummyGLEntry.FieldNo("Prod. Order No."), ProdOrder);
    end;

    local procedure ChangeLastLineStatus(LineStatus: Option " ","In Progress",Completed,Ignored,Blocked)
    var
        ConfigLine: Record "Config. Line";
    begin
        ConfigLine.FindLast();
        ConfigLine.Status := LineStatus;
        ConfigLine.Modify();
    end;

    local procedure CreatePackageDataWithRelation(var ConfigPackage: Record "Config. Package"; CreatePrimaryRecord: Boolean)
    var
        PrimaryConfigPackageTable: Record "Config. Package Table";
        RelatedConfigPackageTable: Record "Config. Package Table";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        ConfigPackageFilter: Record "Config. Package Filter";
        LibraryERM: Codeunit "Library - ERM";
        ConfigPackageMgt: Codeunit "Config. Package Management";
        KeyValueWithRelation: Code[10];
        KeyValueWithoutRelation: Code[10];
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate); // Master
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name); // Related

        KeyValueWithRelation := GenJournalTemplate.Name;
        KeyValueWithoutRelation := GenJournalBatch.Name;

        GenJournalTemplate.Delete();
        GenJournalBatch.Delete();

        // Related Table field with relation

        // Master data
        if CreatePrimaryRecord then
            LibraryRapidStart.CreatePackageDataForField(
              ConfigPackage,
              PrimaryConfigPackageTable,
              DATABASE::"Gen. Journal Template",
              GenJournalTemplate.FieldNo(Name),
              KeyValueWithRelation,
              1);

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

        ConfigPackageMgt.InsertPackageFilter(
          ConfigPackageFilter, ConfigPackage.Code, DATABASE::"Gen. Journal Batch", 0, GenJournalBatch.FieldNo(Name), GenJournalBatch.Name);
    end;

    local procedure CreatePackageDataWithRelationAndCreateMissingCodes(var ConfigPackage: Record "Config. Package")
    var
        Item: Record Item;
        Manufacturer: Record Manufacturer;
        PrimaryConfigPackageTable: Record "Config. Package Table";
        RelatedConfigPackageTable: Record "Config. Package Table";
        ConfigPackageFilter: Record "Config. Package Filter";
        ConfigPackageMgt: Codeunit "Config. Package Management";
        ItemNo: Code[20];
        ManufacturerCode: Code[10];
    begin
        ItemNo := LibraryUtility.GenerateRandomCode(Item.FieldNo("No."), DATABASE::Item);
        ManufacturerCode := LibraryUtility.GenerateRandomCode(Manufacturer.FieldNo(Code), DATABASE::Manufacturer);

        LibraryRapidStart.CreatePackageDataForField(
          ConfigPackage, PrimaryConfigPackageTable, DATABASE::Item, Item.FieldNo("No."), ItemNo, 1);

        LibraryRapidStart.CreatePackageDataForField(
          ConfigPackage, RelatedConfigPackageTable, DATABASE::Manufacturer, Manufacturer.FieldNo(Code), ManufacturerCode, 1);

        LibraryRapidStart.CreatePackageDataForField(
          ConfigPackage, PrimaryConfigPackageTable, DATABASE::Item, Item.FieldNo("Manufacturer Code"), ManufacturerCode, 1);

        ConfigPackageMgt.InsertPackageFilter(
          ConfigPackageFilter, ConfigPackage.Code, DATABASE::Item, 0, Item.FieldNo("No."), Item."No.");

        LibraryRapidStart.SetCreateMissingCodesForField(ConfigPackage.Code, DATABASE::Item, Item.FieldNo("Manufacturer Code"), true);
    end;

    local procedure CreatePackageDataWithItemNoSalesUnitOfMeasure(var ConfigPackage: Record "Config. Package"; ItemNo: Code[20]; SalesUnitOfMeasureCode: Code[10])
    var
        Item: Record Item;
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageFilter: Record "Config. Package Filter";
    begin
        LibraryRapidStart.CreatePackageDataForField(
          ConfigPackage, ConfigPackageTable, DATABASE::Item, Item.FieldNo("No."), ItemNo, 1);

        LibraryRapidStart.CreatePackageDataForField(
          ConfigPackage, ConfigPackageTable, DATABASE::Item, Item.FieldNo("Sales Unit of Measure"), SalesUnitOfMeasureCode, 1);

        ConfigPackageMgt.InsertPackageFilter(
          ConfigPackageFilter, ConfigPackage.Code, DATABASE::Item, 0, Item.FieldNo("No."), Item."No.");

        LibraryRapidStart.SetCreateMissingCodesForField(ConfigPackage.Code, DATABASE::Item, Item.FieldNo("Sales Unit of Measure"), true);
    end;

    local procedure SetConfigPackageFieldRelationTableID(ConfigPackageCode: Code[20]; TableID: Integer; FieldID: Integer; RelationTableID: Integer)
    var
        ConfigPackageField: Record "Config. Package Field";
    begin
        ConfigPackageField.Get(ConfigPackageCode, TableID, FieldID);
        ConfigPackageField.Validate("Relation Table ID", RelationTableID);
        ConfigPackageField.Modify(true);
    end;

    local procedure PreparePackageFileNameForWizard(var ConfigSetup: Record "Config. Setup"; var ConfigPackage: Record "Config. Package")
    var
        ConfigPackageTable: Record "Config. Package Table";
        ConfigXMLExch: Codeunit "Config. XML Exchange";
        ConfigPckgCompressionMgt: Codeunit "Config. Pckg. Compression Mgt.";
        FileMgt: Codeunit "File Management";
        FileName: Text;
        CompressedFileName: Text;
    begin
        FileName := GetFileName(LibraryUtility.GenerateGUID());
        CreateConfigSetup(ConfigSetup);
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::Location);
        ConfigPackageTable.SetRange("Package Code", ConfigPackage.Code);
        ConfigXMLExch.SetCalledFromCode(true);
        ConfigXMLExch.ExportPackageXML(ConfigPackageTable, FileName);

        CompressedFileName := FileMgt.ServerTempFileName('');
        ConfigPckgCompressionMgt.ServersideCompress(FileName, CompressedFileName);

        ConfigSetup.Validate("Package File Name", CopyStr(CompressedFileName, 1, MaxStrLen(ConfigSetup."Package File Name")));
    end;

    local procedure CountConfigWorksheetPageLines(ConfigWorksheet: TestPage "Config. Worksheet") Counter: Integer
    begin
        ConfigWorksheet.First();
        repeat
            if (ConfigWorksheet."Package Code".Value = '') and (ConfigWorksheet."Table ID".Value <> '') then
                Counter := Counter + 1;
        until not ConfigWorksheet.Next();
    end;

    local procedure FindNumberOfLineAtWorksheetPage(ConfigLine: Record "Config. Line"; var ConfigWorksheet: TestPage "Config. Worksheet") Counter: Integer
    begin
        ConfigWorksheet.First();
        repeat
            Counter := Counter + 1;
            if (Format(ConfigLine."Line Type") = ConfigWorksheet."Line Type".Value) and
               (Format(ConfigLine.Name) = ConfigWorksheet.Name.Value) and
               (Format(ConfigLine."Table ID") = ConfigWorksheet."Table ID".Value)
            then
                exit(Counter);
        until not ConfigWorksheet.Next();
    end;

    local procedure SetVerticalSorting(var ConfigLine: Record "Config. Line")
    var
        Counter: Integer;
    begin
        ConfigLine.FindSet();
        repeat
            Counter := Counter + 1;
            ConfigLine.Validate("Vertical Sorting", Counter);
            ConfigLine.Modify(true);
        until ConfigLine.Next() = 0;
    end;

    local procedure GenerateGLAccountNoFromGUID() GeneratedCode: Code[20]
    var
        DummyGLAccount: Record "G/L Account";
    begin
        // Some localized versions require G/L Account to start with a digit other than 0
        GeneratedCode := LibraryUtility.GenerateGUID();
        while StrLen(GeneratedCode) < MaxStrLen(DummyGLAccount."No.") do
            GeneratedCode := '1' + GeneratedCode;
    end;

    local procedure GetRelatedTableCount(TableID: Integer): Integer
    var
        "Field": Record "Field";
        "Integer": Record "Integer" temporary;
    begin
        Field.SetRange(TableNo, TableID);
        Field.SetFilter(RelationTableNo, '<>%1&<>%2&..%3', 0, TableID, 99000999);
        if Field.FindSet() then
            repeat
                Integer.Number := Field.RelationTableNo;
                if Integer.Insert() then;
            until Field.Next() = 0;
        exit(Integer.Count);
    end;

    local procedure CreatePackageWithGLAccountTable(var ConfigPackage: Record "Config. Package"; var GLAccountCode: Code[20])
    var
        GLAccount: Record "G/L Account";
    begin
        CreateAndAssignPackage(ConfigPackage, DATABASE::"G/L Account");
        GLAccountCode := LibraryUtility.GenerateRandomCode(GLAccount.FieldNo("No."), DATABASE::"G/L Account");
        LibraryRapidStart.CreatePackageData(ConfigPackage.Code, DATABASE::"G/L Account", 1, GLAccount.FieldNo("No."), GLAccountCode);
    end;

    local procedure CreateConfigPackageAndLine(var ConfigPackage: Record "Config. Package"; var ConfigLine: Record "Config. Line"; var JournalTemplateName: Code[10]; var JournalBatchName: Code[10])
    var
        ConfigPackageData: Record "Config. Package Data";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreatePackageDataWithRelation(ConfigPackage, true);
        LibraryRapidStart.CreateConfigLine(ConfigLine, ConfigLine."Line Type"::Table, DATABASE::"Gen. Journal Template", '',
          ConfigPackage.Code, false);
        LibraryRapidStart.CreateConfigLine(ConfigLine, ConfigLine."Line Type"::Table, DATABASE::"Gen. Journal Batch", '',
          ConfigPackage.Code, false);

        ConfigPackageData.Get(ConfigPackage.Code, DATABASE::"Gen. Journal Batch", 1, GenJournalBatch.FieldNo("Journal Template Name"));
        JournalTemplateName := CopyStr(ConfigPackageData.Value, 1, StrLen(ConfigPackageData.Value));
        ConfigPackageData.Get(ConfigPackage.Code, DATABASE::"Gen. Journal Batch", 1, GenJournalBatch.FieldNo(Name));
        JournalBatchName := CopyStr(ConfigPackageData.Value, 1, StrLen(ConfigPackageData.Value));
    end;

    local procedure OpenPackageCardFromWorksheet(LineNo: Integer)
    var
        ConfigWorksheet: TestPage "Config. Worksheet";
    begin
        ConfigWorksheet.OpenView();
        ConfigWorksheet.GotoKey(LineNo);
        ConfigWorksheet.PackageCard.Invoke();
    end;

    local procedure UpdatePackageFields(ConfigPackage: Record "Config. Package")
    var
        DummyGLEntry: Record "G/L Entry";
        ConfigPackageField: Record "Config. Package Field";
    begin
        ConfigPackageField.Reset();
        ConfigPackageField.SetRange("Package Code", ConfigPackage.Code);
        ConfigPackageField.SetRange("Table ID", DATABASE::"G/L Entry");
        ConfigPackageField.ModifyAll("Include Field", false, true);

        LibraryRapidStart.SetIncludeOneField(ConfigPackage.Code, DATABASE::"G/L Entry", DummyGLEntry.FieldNo("Entry No."), true);
        LibraryRapidStart.SetIncludeOneField(ConfigPackage.Code, DATABASE::"G/L Entry", DummyGLEntry.FieldNo("Dimension Set ID"), true);
        LibraryRapidStart.SetIncludeOneField(ConfigPackage.Code, DATABASE::"G/L Entry", DummyGLEntry.FieldNo("Prod. Order No."), true);
    end;

    local procedure InsertConfigLineWithStatusAndTableID(var TempConfigLine: Record "Config. Line" temporary; Status: Option; TableID: Integer)
    begin
        TempConfigLine.Init();
        TempConfigLine."Line No." := TableID;
        TempConfigLine.Status := Status;
        TempConfigLine."Table ID" := TableID;
        TempConfigLine.Insert();
    end;

    local procedure VerifyPackageCardAssignedToGroupOrAreaLineCanBeOpened_Helper(LineType: Option "Area",Group,"Table"): Code[20]
    var
        ConfigPackage: Record "Config. Package";
        ConfigLine: Record "Config. Line";
        PackageCode: Variant;
    begin
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreateConfigLine(ConfigLine, LineType, 0, '', ConfigPackage.Code, false);

        OpenPackageCardFromWorksheet(ConfigLine."Line No.");

        LibraryVariableStorage.Dequeue(PackageCode);
        Assert.AreEqual(
          ConfigPackage.Code, PackageCode, StrSubstNo(IncorrectValueErr, ConfigPackage.FieldCaption(Code), ConfigPackage.TableCaption()));

        exit(PackageCode);
    end;

    local procedure VerifyPackageCardIsNotOpenedIfPackageNotAssigned_Helper(LineType: Option "Area",Group,"Table")
    var
        ConfigLine: Record "Config. Line";
    begin
        LibraryRapidStart.CreateConfigLine(ConfigLine, LineType, 0, '', '', false);

        asserterror OpenPackageCardFromWorksheet(ConfigLine."Line No.");

        Assert.ExpectedError(StrSubstNo(CodeCannotBeEmptyErr, ConfigLine.FieldCaption("Package Code"), ConfigLine.TableCaption()));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmYesHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmNoHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), Question, 'Wrong confirm.');
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(MessageStr: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ConfigPackageFieldsHandler(var ConfigPackageFields: TestPage "Config. Package Fields")
    begin
        ConfigPackageFields.First();
        ConfigPackageFields."Relation Table ID".AssertEquals(LibraryVariableStorage.DequeueInteger());
        LibraryVariableStorage.Enqueue(ConfigPackageFields."Relation Table ID".Value); // Enqueue current value of "Relation Table ID" for excluding in SelectRelatedTableHandler
        ConfigPackageFields."Change Related Table".Invoke();
        ConfigPackageFields."Relation Table ID".AssertEquals(LibraryVariableStorage.DequeueInteger());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ConfigPackFieldsHandler(var ConfigPackageFields: TestPage "Config. Package Fields")
    var
        I: Integer;
    begin
        I := 0;
        ConfigPackageFields.First();
        repeat
            I += 1;
        until ConfigPackageFields.Next() = false;
        LibraryVariableStorage.Enqueue(I);
        ConfigPackageFields.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectRelatedTableHandler(var Objects: TestPage Objects)
    begin
        Objects.FILTER.SetFilter("Object ID", '<>' + LibraryVariableStorage.DequeueText()); // Dequeue current value of "Relation Table ID" (it has been enqueued in ConfigPackageFiledsHandler)
        Objects.First();
        LibraryVariableStorage.Enqueue(Objects."Object ID".Value); // Enqueue new value for verification in test
        Objects.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ConfigPackageRecordsHandler(var ConfigPackageRecords: TestPage "Config. Package Records")
    var
        ConfigPackageData: Record "Config. Package Data";
        StandardText: Record "Standard Text";
    begin
        ConfigPackageData.SetRange("Table ID", DATABASE::"Standard Text");
        ConfigPackageData.SetRange("No.", 1);
        ConfigPackageData.SetRange("Field ID", StandardText.FieldNo(Code));
        ConfigPackageData.FindFirst();

        Assert.AreEqual(ConfigPackageData.Value, Format(ConfigPackageRecords.Field1),
          StrSubstNo(IncorrectValueErr, ConfigPackageRecords.Field1.Caption, ConfigPackageRecords.Caption));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ConfigPackagesListHandler(var ConfigPackages: TestPage "Config. Packages")
    var
        PackageCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(PackageCode);
        ConfigPackages.GotoKey(PackageCode);
        ConfigPackages.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ConfigPackageCardHandler(var ConfigPackageCard: TestPage "Config. Package Card")
    begin
        ConfigPackageCard.First();
        LibraryVariableStorage.Enqueue(ConfigPackageCard.Code.Value);
        ConfigPackageCard.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ConfigPackagesPageHandler(var ConfigPackages: TestPage "Config. Packages")
    var
        ConfigPackageCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(ConfigPackageCode);
        ConfigPackages.FILTER.SetFilter(Code, ConfigPackageCode);
        ConfigPackages.First();
        ConfigPackages.OK().Invoke();
    end;

    local procedure ExportImportPackage(ConfigPackage: Record "Config. Package"; DeleteConfigLines: Boolean; Overwrite: Boolean)
    var
        ConfigPackageTable: Record "Config. Package Table";
        FileMgt: Codeunit "File Management";
        FilePath: Text;
    begin
        ConfigXMLExchange.SetCalledFromCode(true);
        ConfigXMLExchange.SetHideDialog(true);

        FilePath := FileMgt.ServerTempFileName('xml');
        ConfigPackageTable.SetRange("Package Code", ConfigPackage.Code);
        ConfigXMLExchange.ExportPackageXML(ConfigPackageTable, FilePath);
        if not Overwrite then
            CleanupData(ConfigPackage.Code, DeleteConfigLines);
        ConfigXMLExchange.ImportPackageXML(FilePath);
    end;

    local procedure ExportImportPackageWithCleanup(ConfigPackage: Record "Config. Package"; DeleteConfigLines: Boolean)
    begin
        ExportImportPackage(ConfigPackage, DeleteConfigLines, false);
    end;

    local procedure ExportImportPackageWithoutCleanup(ConfigPackage: Record "Config. Package")
    begin
        ExportImportPackage(ConfigPackage, false, true);
    end;

    local procedure ExportImportPackageAndWshtLineWithoutAssignment(var ConfigPackage: Record "Config. Package"; CleanupConfigLine: Boolean)
    var
        ConfigPackageTable: Record "Config. Package Table";
        ConfigLine: Record "Config. Line";
        TableId: Integer;
    begin
        TableId := FindTableID();
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, TableId);
        AddConfigLine(ConfigLine."Line Type"::Table, TableId, '');

        ExportImportPackageWithCleanup(ConfigPackage, CleanupConfigLine);
    end;

    local procedure FindTableAndCreatePackageWithWshtLines(var ConfigPackage: Record "Config. Package")
    var
        TableId: Integer;
    begin
        TableId := FindTableID();
        CreateAndAssignPackage(ConfigPackage, TableId);
    end;

    local procedure CreateQuestionArea(TableId: Integer)
    var
        ConfigQuestionArea: Record "Config. Question Area";
        ConfigQuestionnaire: Record "Config. Questionnaire";
    begin
        LibraryRapidStart.CreateQuestionnaire(ConfigQuestionnaire);
        LibraryRapidStart.CreateQuestionArea(ConfigQuestionArea, ConfigQuestionnaire.Code);

        ConfigQuestionArea."Table ID" := TableId;
        ConfigQuestionArea.Modify();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ConfigQuestionAreaHandler(var ConfigQuestionArea: TestPage "Config. Question Area")
    begin
        LibraryVariableStorage.Enqueue(ConfigQuestionArea."Table ID".Value);
        ConfigQuestionArea.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ConfigPackageRecordsPageHandler(var ConfigPackageRecords: TestPage "Config. Package Records")
    begin
        ConfigPackageRecords.Field3.AssertEquals(LibraryVariableStorage.DequeueText());
    end;
}

