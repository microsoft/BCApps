codeunit 136612 "ERM RS Process Data"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Rapid Start] [Process Data]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        ImplementProcessingLogicMsg: Label 'Implement processing logic for Table %1 in Report 8621';
        ConfigPackageMgt: Codeunit "Config. Package Management";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRapidStart: Codeunit "Library - Rapid Start";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        APIMockEvents: Codeunit "API Mock Events";
        FilterInfoOneFieldMsg: Label '%1=%2', Locked = true;
        FilterInfoTwoFieldsMsg: Label '%1=%2, %3=%4';
        ActionMustBeCustomErr: Label 'Action must be equal to ''Custom''';
        CustomProcCodIDMustHaveValueErr: Label 'Custom Processing Codeunit ID must have a value';
        CustomProcCodIDMustBeZeroErr: Label 'Custom Processing Codeunit ID must be equal to ''0''';

    [Test]
    [Scope('OnPrem')]
    procedure CustomProcCodIDShouldBeAnExistingCodID()
    var
        AllObjWithCaption: Record AllObjWithCaption;
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
    begin
        // [FEATURE] [Config. Table Processing Rule] [Custom] [UT]
        // [SCENARIO] "Custom Processing Codeunit ID" field should be validated as an id of an existing codeunits
        Initialize();

        ConfigTableProcessingRule.Init();
        ConfigTableProcessingRule.Validate("Table ID", DATABASE::"Invt. Posting Buffer");
        ConfigTableProcessingRule.Validate(Action, ConfigTableProcessingRule.Action::Custom);

        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Codeunit);
        AllObjWithCaption.FindLast();
        asserterror ConfigTableProcessingRule.Validate("Custom Processing Codeunit ID", AllObjWithCaption."Object ID" + 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomProcCodIDShouldBeEmptyForNonCustomAction()
    var
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
    begin
        // [FEATURE] [Config. Table Processing Rule] [Custom] [UT]
        // [SCENARIO] "Custom Processing Codeunit ID" field should be empty if action is NOT "Custom"
        Initialize();

        ConfigTableProcessingRule.Init();
        ConfigTableProcessingRule.Validate("Table ID", DATABASE::"Gen. Journal Line");
        ConfigTableProcessingRule.Validate(Action, ConfigTableProcessingRule.Action::Post);
        asserterror ConfigTableProcessingRule.Validate("Custom Processing Codeunit ID", 136612);
        Assert.ExpectedError(ActionMustBeCustomErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomProcCodIDShouldBeEmptyForNonCustomActionOnInsert()
    var
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
    begin
        // [FEATURE] [Config. Table Processing Rule] [Custom] [UT]
        // [SCENARIO] On INSERT: "Custom Processing Codeunit ID" field should be empty if action is NOT "Custom"
        Initialize();

        ConfigTableProcessingRule.Init();
        ConfigTableProcessingRule.Validate("Table ID", DATABASE::"Gen. Journal Line");
        ConfigTableProcessingRule.Validate(Action, ConfigTableProcessingRule.Action::Post);
        ConfigTableProcessingRule."Custom Processing Codeunit ID" := 1;
        asserterror ConfigTableProcessingRule.Insert(true);
        Assert.ExpectedError(CustomProcCodIDMustBeZeroErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomProcCodIDShouldBeEmptyForNonCustomActionOnModify()
    var
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
    begin
        // [FEATURE] [Config. Table Processing Rule] [Custom] [UT]
        // [SCENARIO] On MODIFY: "Custom Processing Codeunit ID" field should be empty if action is NOT "Custom"
        Initialize();

        ConfigTableProcessingRule.Init();
        ConfigTableProcessingRule.Validate("Table ID", DATABASE::"Gen. Journal Line");
        ConfigTableProcessingRule.Validate(Action, ConfigTableProcessingRule.Action::Post);
        ConfigTableProcessingRule."Custom Processing Codeunit ID" := 0;
        ConfigTableProcessingRule.Insert(true);

        ConfigTableProcessingRule."Custom Processing Codeunit ID" := 1;
        asserterror ConfigTableProcessingRule.Modify(true);
        Assert.ExpectedError(CustomProcCodIDMustBeZeroErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomProcCodIDShouldBeFilledForCustomAction()
    var
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
    begin
        // [FEATURE] [Config. Table Processing Rule] [Custom] [UT]
        // [SCENARIO] "Custom Processing Codeunit ID" field should be filled if action is "Custom"
        Initialize();

        ConfigTableProcessingRule.Init();
        ConfigTableProcessingRule.Validate("Table ID", DATABASE::"Gen. Journal Line");
        ConfigTableProcessingRule.Validate(Action, ConfigTableProcessingRule.Action::Custom);
        asserterror ConfigTableProcessingRule.Validate("Custom Processing Codeunit ID", 0);
        Assert.ExpectedError(CustomProcCodIDMustHaveValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomProcCodIDShouldBeFilledForCustomActionOnInsert()
    var
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
    begin
        // [FEATURE] [Config. Table Processing Rule] [Custom] [UT]
        // [SCENARIO] On INSERT: "Custom Processing Codeunit ID" field should be filled if action is "Custom"
        Initialize();

        ConfigTableProcessingRule.Init();
        ConfigTableProcessingRule.Validate("Table ID", DATABASE::"Gen. Journal Line");
        ConfigTableProcessingRule.Validate(Action, ConfigTableProcessingRule.Action::Custom);
        ConfigTableProcessingRule."Custom Processing Codeunit ID" := 0;
        asserterror ConfigTableProcessingRule.Insert(true);
        Assert.ExpectedError(CustomProcCodIDMustHaveValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomProcCodIDShouldBeFilledForCustomActionOnModify()
    var
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
    begin
        // [FEATURE] [Config. Table Processing Rule] [Custom] [UT]
        // [SCENARIO] On MODIFY: "Custom Processing Codeunit ID" field should be filled if action is "Custom"
        Initialize();

        ConfigTableProcessingRule.Init();
        ConfigTableProcessingRule.Validate("Table ID", DATABASE::"Gen. Journal Line");
        ConfigTableProcessingRule.Validate(Action, ConfigTableProcessingRule.Action::Custom);
        ConfigTableProcessingRule."Custom Processing Codeunit ID" := 1;
        ConfigTableProcessingRule.Insert(true);

        ConfigTableProcessingRule."Custom Processing Codeunit ID" := 0;
        asserterror ConfigTableProcessingRule.Modify(true);
        Assert.ExpectedError(CustomProcCodIDMustHaveValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomProcCodShouldBeRanForReleasePurchDoc()
    var
        ConfigPackage: Record "Config. Package";
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
        PurchHeader: Record "Purchase Header";
        ERMRSProcessData: Codeunit "ERM RS Process Data";
    begin
        // [FEATURE] [Config. Table Processing Rule] [Custom] [Purchase]
        // [SCENARIO] The "Apply" package process runs a codeunit which id is set in "Custom Processing Codeunit ID" for a Custom rule
        Initialize();
        BindSubscription(ERMRSProcessData);

        // [GIVEN] Created a Purchase Order with one line
        CreatePurchOrder(PurchHeader);
        // [GIVEN] A Package with tables (38,39) and a Processing Rule 'Custom' running COD415 defined for Table 38
        ExportImportPackageWithRuleForPurchHeader(
          ConfigPackage, PurchHeader, ConfigTableProcessingRule.Action::Custom, CODEUNIT::"Release Purchase Document");

        // [WHEN] Apply the package
        LibraryRapidStart.ApplyPackage(ConfigPackage, true);

        // [THEN] Sales Order is shipped
        PurchHeader.Find();
        Assert.AreEqual(PurchHeader.Status::Released, PurchHeader.Status, PurchHeader.FieldCaption(Status));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomProcCodShouldBeRanForReleaseSalesDoc()
    var
        ConfigPackage: Record "Config. Package";
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
        SalesHeader: Record "Sales Header";
        ERMRSProcessData: Codeunit "ERM RS Process Data";
    begin
        // [FEATURE] [Config. Table Processing Rule] [Custom] [Sales]
        // [SCENARIO] The "Apply" package process runs a codeunit which id is set in "Custom Processing Codeunit ID" for a Custom rule
        Initialize();
        BindSubscription(ERMRSProcessData);

        // [GIVEN] Created a Sales Order with one line
        CreateSalesOrder(SalesHeader);
        // [GIVEN] A Package with tables (36,37) and a Processing Rule 'Custom' running COD414 defined for Table 36
        ExportImportPackageWithRuleForSalesHeader(
          ConfigPackage, SalesHeader, ConfigTableProcessingRule.Action::Custom, CODEUNIT::"Release Sales Document");

        // [WHEN] Apply the package
        LibraryRapidStart.ApplyPackage(ConfigPackage, true);

        // [THEN] Sales Order is shipped
        SalesHeader.Find();
        Assert.AreEqual(SalesHeader.Status::Released, SalesHeader.Status, SalesHeader.FieldCaption(Status));
    end;

    [Test]
    [HandlerFunctions('CustomCodIdEditableModalHandler')]
    [Scope('OnPrem')]
    procedure CustomProcCodIDShouldBeEditableForCustomAction()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageCard: TestPage "Config. Package Card";
        SalesActions: array[2] of Integer;
    begin
        // [FEATURE] [Config. Table Processing Rule] [Custom] [UI]
        // [SCENARIO] "Custom Processing Codeunit ID" field should be editable only if action is "Custom"
        Initialize();

        LibraryRapidStart.CreatePackage(ConfigPackage);
        GetSalesActions(SalesActions);
        CreatePackageTableWithTwoRules(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Sales Header", SalesActions);
        ConfigPackageCard.OpenEdit();
        ConfigPackageCard.Control10.ProcessingRules.Invoke(); // calls CustomCodIdEditableModalHandler

        // [THEN] "Custom Processing Codeunit ID" changes editability while moving focus from "Custom" line to "Post" and back
        // Verification by CustomCodIdEditableModalHandler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecordDoesNotFitFilterOnNotIncludedField()
    var
        ConfigPackageFilter: Record "Config. Package Filter";
        ConfigPackageRecord: Record "Config. Package Record";
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
        GenJnlLine: Record "Gen. Journal Line";
        Result: Boolean;
    begin
        // [FEATURE] [Config. Table Processing Rule] [Filter] [UT]
        // [SCENARIO] FitsProcessingFilter() returns FALSE if the record does not include filtered field
        Initialize();

        // [GIVEN] A Rule 'Post' for table 81
        CreatePackageWithRuleForGenJnlLine(ConfigTableProcessingRule);

        // [GIVEN] A Journal Line in Config Data, that does not include field "Amount"
        CreateGenJnlLines(GenJnlLine, 1);
        PutGenJnlLineToConfigPackageData(ConfigTableProcessingRule."Package Code", ConfigPackageRecord, GenJnlLine);

        // [GIVEN] A Processing Rule Filter is set: "Amount" = '>0'
        LibraryRapidStart.CreatePackageTableRuleFilter(
          ConfigPackageFilter, ConfigTableProcessingRule, GenJnlLine.FieldNo(Amount), '>0');

        // [WHEN] Run Record.FitsProcessingFilter()
        Result := ConfigPackageRecord.FitsProcessingFilter(ConfigTableProcessingRule."Rule No.");

        // [THEN] FitsProcessingFilter() returns FALSE
        Assert.IsFalse(Result, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecordFitsProcessingFilter()
    var
        ConfigPackageFilter: Record "Config. Package Filter";
        ConfigPackageRecord: array[2] of Record "Config. Package Record";
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
        GenJnlLine: Record "Gen. Journal Line";
        Result: array[2] of Boolean;
        LineNo: Integer;
    begin
        // [FEATURE] [Config. Table Processing Rule] [Filter] [UT]
        // [SCENARIO] FitsProcessingFilter() returns TRUE if the record matches one field filter
        Initialize();

        // [GIVEN] A Rule 'Post' for table 81
        CreatePackageWithRuleForGenJnlLine(ConfigTableProcessingRule);

        // [GIVEN] Two Journal Lines in Config Data, where "Line No." = (10000, 20000)
        CreateGenJnlLines(GenJnlLine, 2);
        PutGenJnlLineToConfigPackageData(ConfigTableProcessingRule."Package Code", ConfigPackageRecord[1], GenJnlLine);
        GenJnlLine.Next();
        ConfigPackageRecord[2]."No." := ConfigPackageRecord[1]."No.";
        PutGenJnlLineToConfigPackageData(ConfigTableProcessingRule."Package Code", ConfigPackageRecord[2], GenJnlLine);
        LineNo := GenJnlLine."Line No.";

        // [GIVEN] A Processing Rule Filter is set: 'Line No.' = 20000
        LibraryRapidStart.CreatePackageTableRuleFilter(
          ConfigPackageFilter, ConfigTableProcessingRule, GenJnlLine.FieldNo("Line No."), Format(LineNo));

        // [WHEN] Run Record.FitsProcessingFilter() on two records
        Result[1] := ConfigPackageRecord[1].FitsProcessingFilter(ConfigTableProcessingRule."Rule No.");
        Result[2] := ConfigPackageRecord[2].FitsProcessingFilter(ConfigTableProcessingRule."Rule No.");

        // [THEN] FALSE for record, where 'Line No.' = 10000
        Assert.IsFalse(Result[1], '1');
        // [THEN] TRUE for record, where 'Line No.' = 20000
        Assert.IsTrue(Result[2], '2');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecordFitsProcessingFilters()
    var
        ConfigPackageFilter: Record "Config. Package Filter";
        ConfigPackageRecord: array[3] of Record "Config. Package Record";
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
        GenJnlLine: Record "Gen. Journal Line";
        Result: array[3] of Boolean;
        I: Integer;
        LineNo: Integer;
    begin
        // [FEATURE] [Config. Table Processing Rule] [Filter] [UT]
        // [SCENARIO] FitsProcessingFilter() returns TRUE if the record matches multiple fields filters
        Initialize();

        // [GIVEN] A Rule 'Post' for table 81
        CreatePackageWithRuleForGenJnlLine(ConfigTableProcessingRule);

        // [GIVEN] Three Journal Lines in Config Data, where "Line No." = (10000, 20000, 30000)
        CreateGenJnlLines(GenJnlLine, 3);
        PutGenJnlLineToConfigPackageData(ConfigTableProcessingRule."Package Code", ConfigPackageRecord[1], GenJnlLine);
        GenJnlLine.Next();
        ConfigPackageRecord[2]."No." := ConfigPackageRecord[1]."No.";
        // [GIVEN] The Journal Line, where "Line No." = 20000, has "Posting Date" = WorkDate() + 1
        GenJnlLine."Posting Date" += 1;
        PutGenJnlLineToConfigPackageData(ConfigTableProcessingRule."Package Code", ConfigPackageRecord[2], GenJnlLine);
        GenJnlLine.Next();
        ConfigPackageRecord[3]."No." := ConfigPackageRecord[2]."No.";
        PutGenJnlLineToConfigPackageData(ConfigTableProcessingRule."Package Code", ConfigPackageRecord[3], GenJnlLine);
        LineNo := GenJnlLine."Line No.";

        // [GIVEN] A Processing Rule Filter: "Posting Date" = '>WORKDATE'
        LibraryRapidStart.CreatePackageTableRuleFilter(
          ConfigPackageFilter, ConfigTableProcessingRule, GenJnlLine.FieldNo("Posting Date"), '>' + Format(WorkDate()));
        // [GIVEN] A Processing Rule Filter: "Line No." = '<30000'
        LibraryRapidStart.CreatePackageTableRuleFilter(
          ConfigPackageFilter, ConfigTableProcessingRule, GenJnlLine.FieldNo("Line No."), '<' + Format(LineNo));

        // [WHEN] Run Record.FitsProcessingFilter() on three records
        for I := 1 to 3 do
            Result[I] := ConfigPackageRecord[I].FitsProcessingFilter(ConfigTableProcessingRule."Rule No.");

        // [THEN] FALSE for record, where 'Line No.' = 10000, "Posting Date" = WORKDATE
        Assert.IsFalse(Result[1], '1');
        // [THEN] TRUE for record, where 'Line No.' = 20000, "Posting Date" = WorkDate() + 1
        Assert.IsTrue(Result[2], '2');
        // [THEN] FALSE for record, where 'Line No.' = 30000, "Posting Date" = WORKDATE
        Assert.IsFalse(Result[3], '3');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FindInsertedRec()
    var
        ConfigPackageRecord: Record "Config. Package Record";
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
        ConfigRecordForProcessing: Record "Config. Record For Processing";
        ExpectedGenJnlLine: Record "Gen. Journal Line";
        GenJnlLine: Record "Gen. Journal Line";
        RecRef: RecordRef;
    begin
        // [FEATURE] [Config. Table Processing Rule] [UT]
        // [SCENARIO] FindInsertedRecord() returns a RecordRef for a Config. Record.
        Initialize();

        // [GIVEN] A Rule 'Post' for table 81
        CreatePackageWithRuleForGenJnlLine(ConfigTableProcessingRule);

        // [GIVEN] Three Journal Lines in the DB, where "Line No." = (10000, 20000, 30000)
        CreateGenJnlLines(GenJnlLine, 3);
        // [GIVEN] Two Config Records for Journal lines in the Package Data: where "Line No." = (10000, 20000)
        PutGenJnlLineToConfigPackageData(ConfigTableProcessingRule."Package Code", ConfigPackageRecord, GenJnlLine);
        ConfigRecordForProcessing.AddRecord(ConfigPackageRecord, ConfigTableProcessingRule."Rule No.");
        GenJnlLine.Next();
        ExpectedGenJnlLine := GenJnlLine;
        PutGenJnlLineToConfigPackageData(ConfigTableProcessingRule."Package Code", ConfigPackageRecord, GenJnlLine);
        ConfigRecordForProcessing.AddRecord(ConfigPackageRecord, ConfigTableProcessingRule."Rule No.");

        // [WHEN] Run ConfigRecordForProcessing.FindInsertedRecord() on record, where "Line No." = 20000
        ConfigRecordForProcessing.FindInsertedRecord(RecRef);

        // [THEN] returned the Journal line record, where "Line No." = 20000
        RecRef.SetTable(GenJnlLine);
        Assert.AreEqual(
          ExpectedGenJnlLine."Journal Template Name", GenJnlLine."Journal Template Name",
          GenJnlLine.FieldCaption("Journal Template Name"));
        Assert.AreEqual(
          ExpectedGenJnlLine."Journal Batch Name", GenJnlLine."Journal Batch Name",
          GenJnlLine.FieldCaption("Journal Batch Name"));
        Assert.AreEqual(
          ExpectedGenJnlLine."Line No.", GenJnlLine."Line No.", GenJnlLine.FieldCaption("Line No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FindInsertedRecBlankPrimaryKey()
    var
        ConfigPackageRecord: Record "Config. Package Record";
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
        ConfigRecordForProcessing: Record "Config. Record For Processing";
        CompanyInformation: Record "Company Information";
        ExpectedCompanyInformation: Record "Company Information";
        CompanyInformationPage: TestPage "Company Information";
        RecRef: RecordRef;
    begin
        // [FEATURE] [Config. Table Processing Rule] [UT]
        // [SCENARIO] FindInsertedRecord() returns a RecordRef for a Config. Record. when the primary key is blank
        Initialize();

        // [GIVEN] A Custom Rule for table 79
        CreatePackageWithRuleForCompanyInformation(ConfigTableProcessingRule);

        // [GIVEN] A Company Information record exists (created when the page is opened)
        CompanyInformationPage.OpenView();
        CompanyInformationPage.Close();
        ExpectedCompanyInformation.Get();

        // [GIVEN] A Config Record for the company information record in the Package Data
        PutCompanyInformationToConfigPackageData(ConfigTableProcessingRule."Package Code", ConfigPackageRecord, CompanyInformation);
        ConfigRecordForProcessing.AddRecord(ConfigPackageRecord, ConfigTableProcessingRule."Rule No.");

        // [WHEN] Run ConfigRecordForProcessing.FindInsertedRecord() on record
        Assert.IsTrue(ConfigRecordForProcessing.FindInsertedRecord(RecRef), 'FindInsertedRecord did not find the record');

        // [THEN] returned the one and only company information record
        RecRef.SetTable(CompanyInformation);
        Assert.AreEqual(
          Format(ExpectedCompanyInformation), Format(CompanyInformation), 'FindInsertedRecord did not retrieve the correct record');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostGenJournalLine()
    var
        ConfigPackage: Record "Config. Package";
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
        GenJournalLine: Record "Gen. Journal Line";
        LastGLEntryNo: Integer;
        NoOfLines: Integer;
    begin
        // [FEATURE] [Config. Table Processing Rule]
        // [SCENARIO] Journal lines stored in the package should be posted if 'Post' action defined
        Initialize();

        // [GIVEN] A Package with tables (15,80,81,232) and Processing Rule 'Post' defined for Table 81
        CreateRuleForGenJnlPackage(ConfigTableProcessingRule);

        // [GIVEN] 3 Gen. Journal Lines are in the Package
        NoOfLines := 3;
        CreateGenJnlLines(GenJournalLine, NoOfLines);
        ExportImportPackage(ConfigTableProcessingRule."Package Code", false);

        // [WHEN] Apply the package
        LastGLEntryNo := GetLastGLEntryNo();
        GenJournalLine.DeleteAll();
        ConfigPackage.Get(ConfigTableProcessingRule."Package Code");
        LibraryRapidStart.ApplyPackage(ConfigPackage, false);

        // [THEN] 3 Journal Lines will be posted
        VerifyGLEntryCount('', LastGLEntryNo, 2 * NoOfLines);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostGenJournalLineFiltered()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageFilter: Record "Config. Package Filter";
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
        GenJournalLine: Record "Gen. Journal Line";
        LastGLEntryNo: Integer;
        NoOfLines: Integer;
    begin
        // [FEATURE] [Config. Table Processing Rule][Filter]
        // [SCENARIO] Filtered Journal line stored in the package should be posted if 'Post' action defined
        Initialize();

        // [GIVEN] A Package with tables (15,80,81,232) and Processing Rule 'Post' defined for Table 81
        CreateRuleForGenJnlPackage(ConfigTableProcessingRule);

        // [GIVEN] A Processing Rule Filter is set: 'Line No.' = <30000
        LibraryRapidStart.CreatePackageTableRuleFilter(
          ConfigPackageFilter, ConfigTableProcessingRule, GenJournalLine.FieldNo("Line No."), '<30000');

        // [GIVEN] 3 Gen. Journal Lines are in the Package
        NoOfLines := 3;
        CreateGenJnlLines(GenJournalLine, NoOfLines);
        GenJournalLine.FindLast();
        ExportImportPackage(ConfigTableProcessingRule."Package Code", false);

        // [WHEN] Apply the package
        LastGLEntryNo := GetLastGLEntryNo();
        GenJournalLine.DeleteAll();
        ConfigPackage.Get(ConfigTableProcessingRule."Package Code");
        LibraryRapidStart.ApplyPackage(ConfigPackage, false);

        // [THEN] 2 Journal Lines will be posted
        VerifyGLEntryCount('', LastGLEntryNo, 2 * (NoOfLines - 1));
        // [THEN] The last Journal Line is not posted
        Assert.IsTrue(GenJournalLine.Find(), 'Last Journal Line should not be posted');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipSalesOrder()
    var
        ConfigPackage: Record "Config. Package";
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
        SalesHeader: Record "Sales Header";
        LastCLEntryNo: Integer;
    begin
        // [FEATURE] [Config. Table Processing Rule] [Sales]
        // [SCENARIO] Filtered Sales Order stored in the package should be shipped if 'Ship' action defined
        Initialize();

        // [GIVEN] Created a Sales Order with one line
        CreateSalesOrder(SalesHeader);

        // [GIVEN] A Package with tables (36,37) and Processing Rule 'Ship' defined for Table 36
        ExportImportPackageWithRuleForSalesHeader(ConfigPackage, SalesHeader, ConfigTableProcessingRule.Action::Ship, 0);

        // [WHEN] Apply the package
        LastCLEntryNo := GetLastCLEntryNo();
        LibraryRapidStart.ApplyPackage(ConfigPackage, true);

        // [THEN] Sales Order is shipped
        VerifySalesOrderIsShipped(SalesHeader, LastCLEntryNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceSalesOrder()
    var
        ConfigPackage: Record "Config. Package";
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
        SalesHeader: Record "Sales Header";
        LastCLEntryNo: Integer;
    begin
        // [FEATURE] [Config. Table Processing Rule] [Sales]
        // [SCENARIO] Filtered Sales Order stored in the package should be invoiced if 'Invoice' action defined
        Initialize();

        // [GIVEN] Created a Sales Order with one line
        CreateSalesOrder(SalesHeader);

        // [GIVEN] A Package with tables (36,37) and Processing Rule 'Invoice' defined for Table 36
        ExportImportPackageWithRuleForSalesHeader(ConfigPackage, SalesHeader, ConfigTableProcessingRule.Action::Invoice, 0);

        // [WHEN] Apply the package
        LastCLEntryNo := GetLastCLEntryNo();
        LibraryRapidStart.ApplyPackage(ConfigPackage, true);

        // [THEN] Sales Order is shipped
        VerifySalesOrderIsInvoiced(SalesHeader, LastCLEntryNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReceivePurchaseOrder()
    var
        ConfigPackage: Record "Config. Package";
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
        PurchHeader: Record "Purchase Header";
        LastVLEntryNo: Integer;
    begin
        // [FEATURE] [Config. Table Processing Rule] [Purchase]
        // [SCENARIO] Filtered Purchase Invoice stored in the package should be received if 'Receive' action defined
        Initialize();

        // [GIVEN] Created a Purchase Order with one line
        CreatePurchOrder(PurchHeader);

        // [GIVEN] A Package with tables (38,39) and Processing Rule 'Receive' defined for Table 38
        ExportImportPackageWithRuleForPurchHeader(ConfigPackage, PurchHeader, ConfigTableProcessingRule.Action::Receive, 0);

        // [WHEN] Apply the package
        LastVLEntryNo := GetLastCLEntryNo();
        LibraryRapidStart.ApplyPackage(ConfigPackage, true);

        // [THEN] Purch Order is received
        VerifyPurchOrderIsReceived(PurchHeader, LastVLEntryNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoicePurchaseOrder()
    var
        ConfigPackage: Record "Config. Package";
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
        PurchHeader: Record "Purchase Header";
        LastVLEntryNo: Integer;
    begin
        // [FEATURE] [Config. Table Processing Rule] [Purchase]
        // [SCENARIO] Filtered Purchase Invoice stored in the package should be invoiced if 'Invoice' action defined
        Initialize();

        // [GIVEN] Created a Purchase Order with one line
        CreatePurchOrder(PurchHeader);

        // [GIVEN] A Package with tables (38,39) and Processing Rule 'Invoice' defined for Table 38
        ExportImportPackageWithRuleForPurchHeader(ConfigPackage, PurchHeader, ConfigTableProcessingRule.Action::Invoice, 0);

        // [WHEN] Apply the package
        LastVLEntryNo := GetLastVLEntryNo();
        LibraryRapidStart.ApplyPackage(ConfigPackage, true);

        // [THEN] Purch Order is received
        VerifyPurchOrderIsInvoiced(PurchHeader, LastVLEntryNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FieldFilterCanBeSetPerRule()
    var
        ConfigPackageFilter: Record "Config. Package Filter";
    begin
        // [FEATURE] [Config. Table Processing Rule] [Filter]
        // [SCENARIO] One field filter can be set per rule
        Initialize();

        // [GIVEN] A filter line defined for a table rule 'A'
        ConfigPackageFilter.Init();
        ConfigPackageFilter."Table ID" := DATABASE::"Gen. Journal Line";
        ConfigPackageFilter."Processing Rule No." := 1;
        ConfigPackageFilter.Insert(true);

        // [WHEN] Add a filter line for a table rule 'B'
        ConfigPackageFilter."Processing Rule No." := 2;
        ConfigPackageFilter.Insert(true);

        // [THEN] 2 Filter lines inserted for a table
        ConfigPackageFilter.SetRange("Table ID", ConfigPackageFilter."Table ID");
        Assert.AreEqual(2, ConfigPackageFilter.Count, ConfigPackageFilter.TableCaption());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TwoFieldFiltersCanBeSetPerRule()
    var
        ConfigPackageFilter: Record "Config. Package Filter";
    begin
        // [FEATURE] [Config. Table Processing Rule] [Filter]
        // [SCENARIO] Two field filters can be set per rule
        Initialize();

        // [GIVEN] A filter line for Field 1 defined for a table rule
        ConfigPackageFilter.Init();
        ConfigPackageFilter."Table ID" := DATABASE::"Gen. Journal Line";
        ConfigPackageFilter."Processing Rule No." := 1;
        ConfigPackageFilter."Field ID" := 1;
        ConfigPackageFilter.Insert(true);

        // [WHEN] Add a filter line for Field 1 for a table rule
        ConfigPackageFilter."Field ID" := 2;
        ConfigPackageFilter.Insert(true);

        // [THEN] 2 Filter lines inserted for a table
        ConfigPackageFilter.SetRange("Table ID", ConfigPackageFilter."Table ID");
        ConfigPackageFilter.SetRange("Processing Rule No.", ConfigPackageFilter."Processing Rule No.");
        Assert.AreEqual(2, ConfigPackageFilter.Count, ConfigPackageFilter.TableCaption());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FilterCannotBeDefinedTwiceForOneField()
    var
        ConfigPackageFilter: Record "Config. Package Filter";
    begin
        // [FEATURE] [Config. Table Processing Rule] [Filter]
        // [SCENARIO] Filter cannot be defined twice for one field per rule
        Initialize();

        // [GIVEN] A filter line for Field 1 defined for a table rule
        ConfigPackageFilter.Init();
        ConfigPackageFilter."Table ID" := DATABASE::"Sales Header";
        ConfigPackageFilter."Processing Rule No." := 1;
        ConfigPackageFilter."Field ID" := 1;
        ConfigPackageFilter."Field Filter" := '>0';
        ConfigPackageFilter.Insert(true);

        // [WHEN] Add second filter line for Field 1 for a table rule
        ConfigPackageFilter."Field Filter" := '<0';

        // [THEN] Error: 'Filter already exists'
        Assert.IsFalse(ConfigPackageFilter.Insert(true), 'INSERT');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FiltersDeletedWhenRuleDeleted()
    var
        ConfigPackageFilter: Record "Config. Package Filter";
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
        FilterValue: array[4] of Integer;
    begin
        // [FEATURE] [Config. Table Processing Rule] [Filter]
        // [SCENARIO] Processing Filters should be removed while a parent rule is removed
        Initialize();

        // [GIVEN] 2 processing rules 'A' and 'B' with filters
        CreateTwoPackageTableRulesWithFilters(FilterValue);

        // [WHEN] Delete the Rule 'A'
        ConfigTableProcessingRule.FindSet();
        ConfigTableProcessingRule.Delete(true);

        // [THEN] Filters for Rule 'A' will be deleted
        ConfigPackageFilter.SetRange("Package Code", ConfigTableProcessingRule."Package Code");
        ConfigPackageFilter.SetRange("Table ID", ConfigTableProcessingRule."Table ID");
        ConfigPackageFilter.SetRange("Processing Rule No.", ConfigTableProcessingRule."Rule No.");
        Assert.AreEqual(0, ConfigPackageFilter.Count, ConfigPackageFilter.GetFilters);
        // [THEN] Filters for Rule 'B' will NOT be deleted
        ConfigTableProcessingRule.Next();
        ConfigPackageFilter.SetRange("Processing Rule No.", ConfigTableProcessingRule."Rule No.");
        Assert.AreEqual(2, ConfigPackageFilter.Count, ConfigPackageFilter.GetFilters);
    end;

    [Test]
    [HandlerFunctions('ShowProcessingFiltersFromRulesModalHandler,ProcessingFiltersModalHandler')]
    [Scope('OnPrem')]
    procedure FiltersListPageShowsFiltersRelevantForParentRule()
    var
        ConfigPackageCard: TestPage "Config. Package Card";
        FilterValue: array[4] of Integer;
    begin
        // [FEATURE] [Config. Table Processing Rule] [Filter] [UI]
        // [SCENARIO] Config. Package Filters list page should show filters relevant for parent Rule
        Initialize();

        // [GIVEN] 2 processing rules 'A' and 'B' with filters
        CreateTwoPackageTableRulesWithFilters(FilterValue);
        // Passing expected filters to ProcessingFiltersModalHandler
        LibraryVariableStorage.Enqueue(FilterValue[3]);
        LibraryVariableStorage.Enqueue(FilterValue[4]);

        // [GIVEN] Open rules list
        ConfigPackageCard.OpenEdit();
        ConfigPackageCard.Control10.ProcessingRules.Invoke(); // calls ShowProcessingFiltersFromRulesModalHandler

        // [WHEN] Run 'Processing Filters' action on Rules list for Rule 'B'
        // Done by RulesForFiltersModalHandler

        // [THEN] Two filter lines for rule 'B' will be on the Filters page
        // verified by ProcessingFiltersModalHandler
    end;

    [Test]
    [HandlerFunctions('VerifyFilterInfoForRulesModalHandler')]
    [Scope('OnPrem')]
    procedure ProcessingFiltersJoinedAreShownOnRulesList()
    var
        ConfigPackageFilter: Record "Config. Package Filter";
        SalesHeader: Record "Sales Header";
        ConfigPackageCard: TestPage "Config. Package Card";
        FilterValue: array[4] of Integer;
    begin
        // [FEATURE] [Config. Table Processing Rule] [Filter] [UI]
        // [SCENARIO] Config. Package Filters should be shown on Rules list as joined string
        Initialize();

        // [GIVEN] A rule 'R1' with 2 filter lines: Filter 'X' for Field 'A', Filter 'Y' for Field 'B'
        CreateTwoPackageTableRulesWithFilters(FilterValue);
        // [GIVEN] A rule 'R2' with Filter 'Z' for Field 'A'
        ConfigPackageFilter.FindLast();
        ConfigPackageFilter.Delete(true);
        // Passing expected filters to VerifyFilterInfoForRulesModalHandler
        LibraryVariableStorage.Enqueue(
          StrSubstNo(
            FilterInfoTwoFieldsMsg, SalesHeader.FieldCaption("Document Type"), FilterValue[1],
            SalesHeader.FieldCaption("Sell-to Customer No."), FilterValue[2]));
        LibraryVariableStorage.Enqueue(
          StrSubstNo(
            FilterInfoOneFieldMsg, SalesHeader.FieldCaption("Document Type"), FilterValue[3]));

        // [WHEN] Open Processing Rules list
        ConfigPackageCard.OpenEdit();
        ConfigPackageCard.Control10.ProcessingRules.Invoke(); // calls VerifyFilterInfoForRulesModalHandler

        // [THEN] 'Filter' column contains 'A=X, B=Y' for Rule 'R1'
        // [THEN] 'Filter' column contains 'A=Z' for Rule 'R2'
        // verified by VerifyFilterInfoForRulesModalHandler
    end;

    [Test]
    [HandlerFunctions('TableFiltersModalHandler')]
    [Scope('OnPrem')]
    procedure ProcessingFiltersAreNotShownAsTableFilters()
    var
        ConfigPackageCard: TestPage "Config. Package Card";
        FilterValue: array[4] of Integer;
    begin
        // [FEATURE] [Config. Table Processing Rule] [Filter] [UI]
        // [SCENARIO] Config. Package Filters list page called for Config. Table should not show processing filters
        Initialize();

        // [GIVEN] 2 processing rules 'A' and 'B' with filters
        CreateTwoPackageTableRulesWithFilters(FilterValue);

        // [WHEN] Open Filters list for Config. Table
        ConfigPackageCard.OpenEdit();
        ConfigPackageCard.Control10.PackageFilters.Invoke(); // calls TableFiltersModalHandler

        // [THEN] No filters shown on the page
        // verified by TableFiltersModalHandler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProcessingFilterInfoIsBlankForNotDefinedRuleNo()
    var
        ConfigPackageFilter: Record "Config. Package Filter";
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
    begin
        // [FEATURE] [Config. Table Processing Rule] [Filter] [UT]
        // [SCENARIO] GetFilterInfo() should return '' while Rule No is zero
        Initialize();

        ConfigPackageFilter.Init();
        ConfigPackageFilter."Table ID" := DATABASE::"Gen. Journal Line";
        ConfigPackageFilter."Processing Rule No." := 0;
        ConfigPackageFilter."Field ID" := 1;
        ConfigPackageFilter."Field Filter" := '*';
        ConfigPackageFilter.Insert();

        ConfigTableProcessingRule.Init();
        ConfigTableProcessingRule."Table ID" := ConfigPackageFilter."Table ID";
        ConfigTableProcessingRule."Rule No." := 0;

        Assert.AreEqual('', ConfigTableProcessingRule.GetFilterInfo(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RuleActionMustBeFilledOnInsert()
    var
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
    begin
        // [FEATURE] [Config. Table Processing Rule] [Action]
        // [SCENARIO] "Action" must be filled
        Initialize();

        ConfigTableProcessingRule.Init();
        ConfigTableProcessingRule."Table ID" := DATABASE::"Gen. Journal Line";
        ConfigTableProcessingRule.Action := 0;
        // [WHEN] Insert a rule, where "Action" is 0
        asserterror ConfigTableProcessingRule.Insert(true);
        // [THEN] An error message
        Assert.ExpectedError(ConfigTableProcessingRule.FieldCaption(Action));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RuleActionMustBeFilledOnModify()
    var
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
    begin
        // [FEATURE] [Config. Table Processing Rule] [Action]
        // [SCENARIO] "Action" cannot be modified to 0
        Initialize();

        // [GIVEN] A rule, where Action is Post
        ConfigTableProcessingRule.Init();
        ConfigTableProcessingRule."Table ID" := DATABASE::"Gen. Journal Line";
        ConfigTableProcessingRule.Action := ConfigTableProcessingRule.Action::Post;
        ConfigTableProcessingRule.Insert(true);
        // [WHEN] Modify "Action" to 0
        ConfigTableProcessingRule.Action := 0;
        asserterror ConfigTableProcessingRule.Modify(true);
        // [THEN] An error message
        Assert.ExpectedError(ConfigTableProcessingRule.FieldCaption(Action));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ActionsShipInvoiceAvailableForSalesHeader()
    var
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
    begin
        // [FEATURE] [Config. Table Processing Rule] [Action]
        // [SCENARIO] 'Ship,Invoice' should be available for Table 36
        Initialize();

        ConfigTableProcessingRule."Table ID" := DATABASE::"Sales Header";
        asserterror ConfigTableProcessingRule.Validate(Action, ConfigTableProcessingRule.Action::Post);
        ConfigTableProcessingRule.Validate(Action, ConfigTableProcessingRule.Action::Invoice);
        ConfigTableProcessingRule.Validate(Action, ConfigTableProcessingRule.Action::Ship);
        asserterror ConfigTableProcessingRule.Validate(Action, ConfigTableProcessingRule.Action::Receive);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ActionsReceiveInvoiceAvailableForPurchHeader()
    var
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
    begin
        // [FEATURE] [Config. Table Processing Rule] [Action]
        // [SCENARIO] 'Receive,Invoice' should be available for Table 38
        Initialize();

        ConfigTableProcessingRule."Table ID" := DATABASE::"Purchase Header";
        asserterror ConfigTableProcessingRule.Validate(Action, ConfigTableProcessingRule.Action::Post);
        asserterror ConfigTableProcessingRule.Validate(Action, ConfigTableProcessingRule.Action::Ship);
        ConfigTableProcessingRule.Validate(Action, ConfigTableProcessingRule.Action::Receive);
        ConfigTableProcessingRule.Validate(Action, ConfigTableProcessingRule.Action::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ActionPostAvailableForGenJournalLine()
    var
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
    begin
        // [FEATURE] [Config. Table Processing Rule] [Action]
        // [SCENARIO] 'Post' should be available for Table 81
        Initialize();
        ConfigTableProcessingRule."Table ID" := DATABASE::"Gen. Journal Line";
        ConfigTableProcessingRule.Validate(Action, ConfigTableProcessingRule.Action::Post);
        asserterror ConfigTableProcessingRule.Validate(Action, ConfigTableProcessingRule.Action::Invoice);
        asserterror ConfigTableProcessingRule.Validate(Action, ConfigTableProcessingRule.Action::Ship);
        asserterror ConfigTableProcessingRule.Validate(Action, ConfigTableProcessingRule.Action::Receive);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RuleDeletedWhenConfigTableDeleted()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: array[2] of Record "Config. Package Table";
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
        SalesActions: array[2] of Integer;
        PurchActions: array[2] of Integer;
    begin
        // [FEATURE] [Config. Table Processing Rule]
        // [SCENARIO] Rule should be deleted while related Config. Table is deleted

        // [GIVEN] 2 Config. Package Tables (36,38) each with 3 rules
        LibraryRapidStart.CreatePackage(ConfigPackage);
        GetSalesActions(SalesActions);
        CreatePackageTableWithTwoRules(ConfigPackageTable[1], ConfigPackage.Code, DATABASE::"Sales Header", SalesActions);
        GetPurchActions(PurchActions);
        CreatePackageTableWithTwoRules(ConfigPackageTable[2], ConfigPackage.Code, DATABASE::"Purchase Header", PurchActions);

        // [WHEN] Delete the Config. Package Table 36
        ConfigPackageTable[1].Find();
        ConfigPackageTable[1].Delete(true);

        // [THEN] The rules for table 36 will be deleted
        ConfigTableProcessingRule.SetRange("Package Code", ConfigPackageTable[1]."Package Code");
        ConfigTableProcessingRule.SetRange("Table ID", ConfigPackageTable[1]."Table ID");
        Assert.IsTrue(ConfigTableProcessingRule.IsEmpty, Format(ConfigPackageTable[1]."Table ID"));
        // [THEN] The rules for table 38 will NOT be deleted
        ConfigTableProcessingRule.SetRange("Table ID", ConfigPackageTable[2]."Table ID");
        Assert.IsFalse(ConfigTableProcessingRule.IsEmpty, Format(ConfigPackageTable[2]."Table ID"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RuleIsSetPerPackagePerTable()
    var
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
        PackageCode: Code[20];
    begin
        // [FEATURE] [Config. Table Processing Rule]
        // [SCENARIO] Rule should be set per package per table
        Initialize();

        // [GIVEN] A rule for Package 'X', Table '1'
        PackageCode := 'X';
        ConfigTableProcessingRule.Init();
        ConfigTableProcessingRule."Package Code" := PackageCode;
        ConfigTableProcessingRule."Table ID" := 1;
        ConfigTableProcessingRule.Insert();

        // [WHEN] Insert a rule for Package 'X', Table '2'
        ConfigTableProcessingRule."Table ID" += 1;
        ConfigTableProcessingRule.Insert();

        // [THEN] There are 2 rules for Package 'X'
        ConfigTableProcessingRule.SetRange("Package Code", PackageCode);
        Assert.AreEqual(2, ConfigTableProcessingRule.Count, ConfigTableProcessingRule.TableName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TwoRulesCanBeSetForOneTableInPackage()
    var
        ConfigPackageTable: Record "Config. Package Table";
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
    begin
        // [FEATURE] [Config. Table Processing Rule]
        // [SCENARIO] Two rules can be set for same table in a package
        Initialize();
        // [GIVEN] A rule is set for Table 36
        ConfigPackageTable.Init();
        ConfigPackageTable."Table ID" := DATABASE::"Sales Header";
        LibraryRapidStart.CreatePackageTableRule(
          ConfigTableProcessingRule, ConfigPackageTable, ConfigTableProcessingRule.Action::Invoice, 0);
        // [GIVEN] A rule is set for Table 81
        ConfigPackageTable."Table ID" := DATABASE::"Gen. Journal Line";
        LibraryRapidStart.CreatePackageTableRule(ConfigTableProcessingRule, ConfigPackageTable, ConfigTableProcessingRule.Action::Post, 0);

        // [WHEN] Add a second rule for Table 81
        LibraryRapidStart.CreatePackageTableRule(ConfigTableProcessingRule, ConfigPackageTable, ConfigTableProcessingRule.Action::Post, 0);

        // [THEN] There will be 2 rules for Table 81
        ConfigTableProcessingRule.SetRange("Package Code", ConfigPackageTable."Package Code");
        ConfigTableProcessingRule.SetRange("Table ID", ConfigPackageTable."Table ID");
        Assert.AreEqual(2, ConfigTableProcessingRule.Count, ConfigTableProcessingRule.TableName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RulesOrderDefinesExecutionOrder()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageFilter: Record "Config. Package Filter";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        LastGLEntryNo: Integer;
        NoOfLines: Integer;
    begin
        // [FEATURE] [Config. Table Processing Rule]
        // [SCENARIO] The order of the rules should define order of their execution
        Initialize();

        // [GIVEN] A Package with tables (15,80,81,232)
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"G/L Account");
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Gen. Journal Template");
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Gen. Journal Batch");
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Gen. Journal Line");

        // [GIVEN] 2 Gen. Journal Lines, where Amount = (1.10, 2.20), are in the Package
        NoOfLines := 2;
        CreateGenJnlLines(GenJournalLine, NoOfLines);
        GenJournalLine.FindLast();

        // [GIVEN] Added first Processing Rule 'Post' with filter "Amount" = 2.20
        LibraryRapidStart.CreatePackageTableRule(
          ConfigTableProcessingRule, ConfigPackageTable, ConfigTableProcessingRule.Action::Post, 0);
        LibraryRapidStart.CreatePackageTableRuleFilter(
          ConfigPackageFilter, ConfigTableProcessingRule, GenJournalLine.FieldNo(Amount), Format(GenJournalLine.Amount));
        // [GIVEN] Added second Processing Rule 'Post' without filters
        LibraryRapidStart.CreatePackageTableRule(
          ConfigTableProcessingRule, ConfigPackageTable, ConfigTableProcessingRule.Action::Post, 0);

        ExportImportPackage(ConfigPackage.Code, false);

        // [WHEN] Apply the package
        LastGLEntryNo := GetLastGLEntryNo();
        GenJournalLine.DeleteAll();
        LibraryRapidStart.ApplyPackage(ConfigPackage, false);

        // [THEN] 2 Journal Lines will be posted
        VerifyGLEntryCount('', LastGLEntryNo, 2 * NoOfLines);
        // [THEN] The first GLEntry will have Amount = 2.20
        GLEntry.SetFilter("Entry No.", '>%1', LastGLEntryNo);
        GLEntry.FindFirst();
        Assert.AreEqual(2.2, Abs(GLEntry.Amount), 'First entry');
        // [THEN] The last GLEntry will have Amount = 1.10
        GLEntry.FindLast();
        Assert.AreEqual(1.1, Abs(GLEntry.Amount), 'Last entry');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ActionFieldEditableOnRulesList()
    var
        ConfigTableProcessingRules: TestPage "Config. Table Processing Rules";
    begin
        // [FEATURE] [Config. Table Processing Rule] [UI]
        // [SCENARIO] Action field in Rule List should be editable
        Initialize();

        ConfigTableProcessingRules.OpenNew();
        Assert.IsTrue(ConfigTableProcessingRules.Action.Visible(), ConfigTableProcessingRules.Action.Caption);
        Assert.IsTrue(ConfigTableProcessingRules.Action.Editable(), ConfigTableProcessingRules.Action.Caption);
        ConfigTableProcessingRules.Close();
    end;

    [Test]
    [HandlerFunctions('RulesModalHandler')]
    [Scope('OnPrem')]
    procedure RuleNoDefinedAutomatically()
    var
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageCard: TestPage "Config. Package Card";
        RuleNo: Integer;
    begin
        // [FEATURE] [Config. Table Processing Rule] [UI]
        // [SCENARIO] "Rule No." should be defined automatically
        Initialize();

        // [GIVEN] A Package with one Table
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Sales Header");

        // [GIVEN] Run "Processing Rules" action from Package card
        ConfigPackageCard.OpenEdit();
        ConfigPackageCard.Control10.ProcessingRules.Invoke(); // calls RulesModalHandler

        // [WHEN] Add two rule lines
        // done by RulesModalHandler
        RuleNo := LibraryVariableStorage.DequeueInteger();

        // [THEN] "Rule No." will be incremented
        Assert.AreEqual(2, ConfigTableProcessingRule.Count, ConfigTableProcessingRule.TableName);
        ConfigTableProcessingRule.FindLast();
        Assert.AreEqual(RuleNo + 10000, ConfigTableProcessingRule."Rule No.", ConfigTableProcessingRule.FieldCaption("Rule No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FindRuleForRecordReturnsFalse()
    var
        ConfigRecordForProcessing: Record "Config. Record For Processing";
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
    begin
        // [FEATURE] [Config. Table Processing Rule] [UT]
        // [SCENARIO] FindRuleForRecord() method returns FALSE and an empty Rule record
        Initialize();

        ConfigTableProcessingRule.Init();
        ConfigTableProcessingRule."Package Code" := 'X';
        ConfigTableProcessingRule."Table ID" := 36;
        ConfigTableProcessingRule."Rule No." := 10000;
        CreateRuleVariations(ConfigTableProcessingRule);

        ConfigRecordForProcessing.Init();
        ConfigRecordForProcessing."Package Code" := ConfigTableProcessingRule."Package Code";
        ConfigRecordForProcessing."Table ID" := ConfigTableProcessingRule."Table ID";
        ConfigRecordForProcessing."Rule No." := ConfigTableProcessingRule."Rule No." + 1;
        ConfigRecordForProcessing.Insert();

        ConfigTableProcessingRule.FindLast();
        Assert.IsFalse(ConfigRecordForProcessing.FindConfigRule(ConfigTableProcessingRule), 'FindConfigRule');

        Assert.AreEqual('', ConfigTableProcessingRule."Package Code", ConfigTableProcessingRule.FieldCaption("Package Code"));
        Assert.AreEqual(0, ConfigTableProcessingRule."Table ID", ConfigTableProcessingRule.FieldCaption("Table ID"));
        Assert.AreEqual(0, ConfigTableProcessingRule."Rule No.", ConfigTableProcessingRule.FieldCaption("Rule No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FindRuleForRecordReturnsTrue()
    var
        ConfigRecordForProcessing: Record "Config. Record For Processing";
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
    begin
        // [FEATURE] [Config. Table Processing Rule] [UT]
        // [SCENARIO] FindRuleForRecord() method returns TRUE and an found Rule record
        Initialize();

        ConfigTableProcessingRule.Init();
        ConfigTableProcessingRule."Package Code" := 'X';
        ConfigTableProcessingRule."Table ID" := 36;
        ConfigTableProcessingRule."Rule No." := 10000;
        CreateRuleVariations(ConfigTableProcessingRule);

        ConfigRecordForProcessing.Init();
        ConfigRecordForProcessing."Package Code" := ConfigTableProcessingRule."Package Code";
        ConfigRecordForProcessing."Table ID" := ConfigTableProcessingRule."Table ID";
        ConfigRecordForProcessing."Rule No." := ConfigTableProcessingRule."Rule No.";

        ConfigTableProcessingRule.FindLast();
        Assert.IsTrue(ConfigRecordForProcessing.FindConfigRule(ConfigTableProcessingRule), 'FindConfigRule');

        Assert.AreEqual(
          ConfigRecordForProcessing."Package Code", ConfigTableProcessingRule."Package Code",
          ConfigTableProcessingRule.FieldCaption("Package Code"));
        Assert.AreEqual(
          ConfigRecordForProcessing."Table ID", ConfigTableProcessingRule."Table ID",
          ConfigTableProcessingRule.FieldCaption("Table ID"));
        Assert.AreEqual(
          ConfigRecordForProcessing."Rule No.", ConfigTableProcessingRule."Rule No.",
          ConfigTableProcessingRule.FieldCaption("Rule No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FindRulesForTableReturnsFalse()
    var
        ConfigPackageTable: Record "Config. Package Table";
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
    begin
        // [FEATURE] [Config. Table Processing Rule] [UT]
        // [SCENARIO] FindRulesForTable() method returns FALSE and an empty set if none rules defined for a table
        Initialize();
        // [GIVEN] There are 3 Rules, one per Table 37,38
        ConfigTableProcessingRule.Init();
        ConfigTableProcessingRule."Package Code" := 'X';
        ConfigTableProcessingRule."Table ID" := 37;
        CreateRuleVariations(ConfigTableProcessingRule);

        // [WHEN] FindRulesForTable() for Table 36
        ConfigPackageTable.Init();
        ConfigPackageTable."Package Code" := ConfigTableProcessingRule."Package Code";
        ConfigPackageTable."Table ID" := ConfigTableProcessingRule."Table ID" - 1;
        Assert.IsFalse(ConfigTableProcessingRule.FindTableRules(ConfigPackageTable), 'FindRulesForTable');

        // [THEN] Returns FALSE and an empty set
        Assert.AreEqual(0, ConfigTableProcessingRule.Count, 'Wrong COUNT of Rules')
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FindRulesForTableReturnsTrue()
    var
        ConfigPackageTable: Record "Config. Package Table";
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
    begin
        // [FEATURE] [Config. Table Processing Rule] [UT]
        // [SCENARIO] FindRulesForTable() method returns TRUE and a set of rules defined for a table
        Initialize();
        // [GIVEN] There are 3 Rules for Package 'X': 2 for Table 36 and 1 for Table 37
        ConfigTableProcessingRule.Init();
        ConfigTableProcessingRule."Package Code" := 'X';
        ConfigTableProcessingRule."Table ID" := 36;
        CreateRuleVariations(ConfigTableProcessingRule);

        // [WHEN] FindRulesForTable() for Package 'X' and Table 36
        ConfigPackageTable.Init();
        ConfigPackageTable."Package Code" := ConfigTableProcessingRule."Package Code";
        ConfigPackageTable."Table ID" := ConfigTableProcessingRule."Table ID";
        Assert.IsTrue(ConfigTableProcessingRule.FindTableRules(ConfigPackageTable), 'FindRulesForTable');

        // [THEN] Returns TRUE and a set of 2 records
        Assert.AreEqual(2, ConfigTableProcessingRule.Count, 'Wrong COUNT of Rules')
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RunPostActionOnJournalLine()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
        GenJournalLine: Record "Gen. Journal Line";
        RecRef: RecordRef;
        DocumentNo: Code[20];
        LastGLEntryNo: Integer;
        NoOfLines: Integer;
    begin
        // [FEATURE] [Config. Table Processing Rule] [Action Post] [UT]
        // [SCENARIO] RunActionOnInsertedRecord() method posts a Gen. Journal Line
        Initialize();

        // [GIVEN] A Rule "Post" for Table 81
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Gen. Journal Line");
        LibraryRapidStart.CreatePackageTableRule(
          ConfigTableProcessingRule, ConfigPackageTable, ConfigTableProcessingRule.Action::Post, 0);

        // [GIVEN] Created 3 Gen. Journal Lines
        NoOfLines := 3;
        CreateGenJnlLines(GenJournalLine, NoOfLines);
        LastGLEntryNo := GetLastGLEntryNo();

        // [WHEN] Rule.RunActionOnInsertedRecord() on the last Gen. Journal Line
        GenJournalLine.FindLast();
        DocumentNo := GenJournalLine."Document No.";
        RecRef.GetTable(GenJournalLine);
        Commit();
        Assert.IsTrue(ConfigTableProcessingRule.RunActionOnInsertedRecord(RecRef), 'RunActionOnInsertedRecord');

        // [THEN] The last Journal Line will be posted
        Assert.IsFalse(GenJournalLine.Find(), 'Posted line should be deleted');
        Assert.AreEqual(NoOfLines - 1, GenJournalLine.Count, GenJournalLine.TableCaption());
        VerifyGLEntryCount(DocumentNo, LastGLEntryNo, 2);
        VerifyGLEntryCount('', LastGLEntryNo, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RunShipActionOnSalesHeader()
    var
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
        SalesHeader: Record "Sales Header";
        RecRef: RecordRef;
        LastCLEntryNo: Integer;
    begin
        // [FEATURE] [Config. Table Processing Rule] [Action Ship] [Sales] [UT]
        // [SCENARIO] RunActionOnInsertedRecord() method ships a Sales Order
        Initialize();
        // [GIVEN] A Rule "Ship" for Table 36
        CreatePackageWithRuleForSalesHeader(ConfigTableProcessingRule, ConfigTableProcessingRule.Action::Ship);

        // [GIVEN] Create a Sales Order with one line
        CreateSalesOrder(SalesHeader);
        LastCLEntryNo := GetLastCLEntryNo();

        // [WHEN] Rule.RunActionOnInsertedRecord() on Sales Header
        RecRef.GetTable(SalesHeader);
        Commit();
        Assert.IsTrue(ConfigTableProcessingRule.RunActionOnInsertedRecord(RecRef), 'RunActionOnInsertedRecord');

        // [THEN] Sales Order will be shipped: no Cust. Ledger Entries posted, Sales Order is not deleted, Sales Shipment is posted.
        VerifySalesOrderIsShipped(SalesHeader, LastCLEntryNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RunReceiveActionOnPurchaseHeader()
    var
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
        PurchHeader: Record "Purchase Header";
        RecRef: RecordRef;
        LastVLEntryNo: Integer;
    begin
        // [FEATURE] [Config. Table Processing Rule] [Action Receive] [Purchase] [UT]
        // [SCENARIO] RunActionOnInsertedRecord() method receives a Purhase Order
        Initialize();
        // [GIVEN] A Rule "Receive" for Table 38
        CreatePackageWithRuleForPurchHeader(ConfigTableProcessingRule, ConfigTableProcessingRule.Action::Receive);

        // [GIVEN] Create a Purchase Order with one line
        CreatePurchOrder(PurchHeader);
        LastVLEntryNo := GetLastVLEntryNo();

        // [WHEN] Rule.RunActionOnInsertedRecord() on Purchase Header
        RecRef.GetTable(PurchHeader);
        Commit();
        Assert.IsTrue(ConfigTableProcessingRule.RunActionOnInsertedRecord(RecRef), 'RunActionOnInsertedRecord');

        // [THEN] Purchase Order will be received: no Vend. Ledger Entry posted, Purchase Order is not deleted, Purchase Receipt is posted.
        VerifyPurchOrderIsReceived(PurchHeader, LastVLEntryNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RunInvoiceActionOnSalesHeader()
    var
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
        SalesHeader: Record "Sales Header";
        RecRef: RecordRef;
        LastCLEntryNo: Integer;
    begin
        // [FEATURE] [Config. Table Processing Rule] [Action Invoice] [Sales] [UT]
        // [SCENARIO] RunActionOnInsertedRecord() method invoices a Sales Order
        Initialize();
        // [GIVEN] A Rule "Invoice" for Table 36
        CreatePackageWithRuleForSalesHeader(ConfigTableProcessingRule, ConfigTableProcessingRule.Action::Invoice);

        // [GIVEN] Create a Sales Order with one line
        CreateSalesOrder(SalesHeader);
        LastCLEntryNo := GetLastCLEntryNo();

        // [WHEN] Rule.RunActionOnInsertedRecord() on Sales Header
        RecRef.GetTable(SalesHeader);
        Commit();
        Assert.IsTrue(ConfigTableProcessingRule.RunActionOnInsertedRecord(RecRef), 'RunActionOnInsertedRecord');

        // [THEN] Sales Order will be invoiced: Cust. Ledger Entry is posted, Sales Order is deleted, Sales Invoice is posted.
        VerifySalesOrderIsInvoiced(SalesHeader, LastCLEntryNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RunInvoiceActionOnPurchaseHeader()
    var
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
        PurchHeader: Record "Purchase Header";
        RecRef: RecordRef;
        LastVLEntryNo: Integer;
    begin
        // [FEATURE] [Config. Table Processing Rule] [Action Invoice] [Purchase] [UT]
        // [SCENARIO] RunActionOnInsertedRecord() method invoices a Purhase Order
        Initialize();
        // [GIVEN] A Rule "Invoice" for Table 38
        CreatePackageWithRuleForPurchHeader(ConfigTableProcessingRule, ConfigTableProcessingRule.Action::Invoice);

        // [GIVEN] Create a Purchase Order with one line
        CreatePurchOrder(PurchHeader);
        LastVLEntryNo := GetLastVLEntryNo();

        // [WHEN] Rule.RunActionOnInsertedRecord() on Purchase Header
        RecRef.GetTable(PurchHeader);
        Commit();
        Assert.IsTrue(ConfigTableProcessingRule.RunActionOnInsertedRecord(RecRef), 'RunActionOnInsertedRecord');

        // [THEN] Purchase Order will be invoiced: Vend. Ledger Entry is posted, Purchase Order is deleted, Purchase Invoice is posted.
        VerifyPurchOrderIsInvoiced(PurchHeader, LastVLEntryNo);
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure ProcessDataFromPackageRunsDefaultProcessingReportPerTable()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ERMRSProcessData: Codeunit "ERM RS Process Data";
        ConfigPackageCard: TestPage "Config. Package Card";
    begin
        // [FEATURE] [Config. Package - Process]
        // [SCENARIO] "Config. Package - Process" should be called from Package card if "Processing Object ID" is not set
        Initialize();

        // [GIVEN] created a Config. Package with tables Customer,Vendor
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::Customer);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::Vendor);

        // [GIVEN] Open Config. Package card
        ConfigPackageCard.OpenEdit();
        ConfigPackageCard.GotoRecord(ConfigPackage);

        // [GIVEN] Subscribe with the rule for Vendor
        BindSubscription(ERMRSProcessData);
        LibraryVariableStorage.Enqueue(DATABASE::Customer);

        // [WHEN] Run "Process Data" action
        ConfigPackageCard.ProcessData.Invoke();

        // [THEN] 1 message shown: 'Implement processing logic for Table Customer in Report 8621'
        // handled by MsgHandler
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure ProcessDataFromPackageRecordRunsDefaultProcessingReport()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ERMRSProcessData: Codeunit "ERM RS Process Data";
        ConfigPackageRecords: TestPage "Config. Package Records";
    begin
        // [FEATURE] [Config. Package - Process]
        // [SCENARIO] "Config. Package - Process" should be called from Package Record line if "Processing Object ID" is not set
        Initialize();

        // [GIVEN] created a Config. Package with one record per tables Customer, Vendor
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::Customer);
        LibraryRapidStart.CreatePackageData(ConfigPackage.Code, DATABASE::Customer, 0, 0, '');
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::Vendor);
        LibraryRapidStart.CreatePackageData(ConfigPackage.Code, DATABASE::Vendor, 0, 0, '');

        // [GIVEN] Open Config. Package Records page on a Customer record
        ConfigPackageRecords.OpenEdit();
        ConfigPackageRecords.First();

        // [GIVEN] Subscribe with the rule for Vendor
        BindSubscription(ERMRSProcessData);
        LibraryVariableStorage.Enqueue(DATABASE::Customer);

        // [WHEN] Run "Process Data" action
        ConfigPackageRecords.ProcessData.Invoke();

        // [THEN] a message shown: 'Implement processing logic Table Customer in Report 8621'
        // handled by MsgHandler
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecordsAreNotDeletedIfDeleteRecsBeforeProcessingIsUnChecked()
    var
        ConfigPackage: Record "Config. Package";
        Customer: Record Customer;
        CustomerCount: Integer;
    begin
        // [FEATURE] [Delete Recs Before Processing]
        // [SCENARIO] Records should not be deleted from table before data migration, if "Delete Recs Before Processing" is set to false
        Initialize();

        // [GIVEN] A Customer table with more than one record in it
        CustomerCount := Customer.Count();
        Assert.IsTrue(CustomerCount > 1, 'The start condition is not satified. There is not more than one Customer in the table.');

        // [GIVEN] A Config. Package with one record in the Customer table, where "Delete Data Before Processing" is disabled
        CreatePackageWithCustomer(ConfigPackage, false);

        // [WHEN] Data is applied
        LibraryRapidStart.ApplyPackage(ConfigPackage, false);

        // [THEN] there is one more record than there was before in the customer table
        Assert.AreEqual(CustomerCount + 1, Customer.Count, 'There is not one Customer more in the Customer table.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecordsAreDeletedIfDeleteRecsBeforeProcessingIsChecked()
    var
        ConfigPackage: Record "Config. Package";
        Customer: Record Customer;
    begin
        // [FEATURE] [Delete Recs Before Processing]
        // [SCENARIO] Records should be deleted from table before data migration, if "Delete Recs Before Processing" is set to true
        Initialize();

        // [GIVEN] A Customer table with more than one record in it
        Assert.IsTrue(Customer.Count > 1, 'The start condition is not satified. There is not more than one Customer in the table.');

        // [GIVEN] A Config. Package with one record in the Customer table, where "Delete Data Before Processing" is enabled
        CreatePackageWithCustomer(ConfigPackage, true);

        // [WHEN] Data is applied
        LibraryRapidStart.ApplyPackage(ConfigPackage, false);

        // [THEN] Only the one record from the package exists in the customer table, since all others have been deleted.
        Assert.AreEqual(1, Customer.Count, 'There is not one Customer in the Customer table. Deletion failed.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RunPostActionOnCustomReportLayout()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageFilter: Record "Config. Package Filter";
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
        CustomReportLayout: Record "Custom Report Layout";
        ReportLayoutSelection: Record "Report Layout Selection";
        RecRef: RecordRef;
        CustomLayoutCode: Code[20];
        ReportID: Integer;
    begin
        // [FEATURE] [Config. Table Processing Rule] [Action Post] [UT]
        // [SCENARIO] RunActionOnInsertedRecord() method updates a report layout selection for a custom report layout
        Initialize();

        // [GIVEN] A Rule "Post" for Table 9650
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Custom Report Layout");
        LibraryRapidStart.CreatePackageTableRule(
          ConfigTableProcessingRule, ConfigPackageTable, ConfigTableProcessingRule.Action::Post, 0);

        // [GIVEN] Created Custom Report Layouts
        ReportID := 1306;
        CreateCustomReportLayouts(3, ReportID);

        // [GIVEN] A filter that describes one of the report layouts
        CustomReportLayout.SetRange("Report ID", ReportID);
        CustomReportLayout.FindLast();
        CustomLayoutCode := CustomReportLayout.Code;
        LibraryRapidStart.CreatePackageTableRuleFilter(
          ConfigPackageFilter, ConfigTableProcessingRule, 1, StrSubstNo('=%1', CustomLayoutCode));

        // [WHEN] Rule.RunActionOnInsertedRecord() on the Custom Report Layout table
        RecRef.GetTable(CustomReportLayout);
        Commit();
        Assert.IsTrue(ConfigTableProcessingRule.RunActionOnInsertedRecord(RecRef), 'RunActionOnInsertedRecord');

        // [THEN] The layout in the filter is set up as the default.
        Assert.IsTrue(
          ReportLayoutSelection.Get(CustomReportLayout."Report ID", CompanyName), 'Report Layout Selection is empty, expected items in the table.');
        Assert.IsTrue(
          ReportLayoutSelection."Custom Report Layout Code" = CustomLayoutCode, StrSubstNo('Expected report layout %1.', CustomLayoutCode));
    end;

    local procedure Initialize()
    var
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageFilter: Record "Config. Package Filter";
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
        CustomReportLayout: Record "Custom Report Layout";
        ReportLayoutSelection: Record "Report Layout Selection";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM RS Process Data");
        LibraryRapidStart.CleanUp('');
        APIMockEvents.SetAPIServicesEnabled(false);
        ConfigPackageTable.DeleteAll(true);
        ConfigPackageFilter.DeleteAll(true);
        ConfigTableProcessingRule.DeleteAll(true);
        CustomReportLayout.DeleteAll();
        ReportLayoutSelection.DeleteAll(true);
    end;

    local procedure CreateGenJnlLines(var GenJournalLine: Record "Gen. Journal Line"; NoOfLines: Integer)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccountNo: Code[20];
        I: Integer;
    begin
        GenJournalTemplate.DeleteAll();
        GenJournalBatch.DeleteAll();
        GenJournalLine.DeleteAll();
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GLAccountNo := LibraryERM.CreateGLAccountNoWithDirectPosting();

        for I := 1 to NoOfLines do
            LibraryERM.CreateGeneralJnlLineWithBalAcc(
              GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
              GenJournalLine."Account Type"::"G/L Account", GLAccountNo,
              GenJournalLine."Account Type"::"G/L Account", GLAccountNo, I * 1.1);

        GenJournalLine.FindSet();
    end;

    local procedure CreatePackageTableWithTwoRules(var ConfigPackageTable: Record "Config. Package Table"; ConfigPackageCode: Code[20]; TableID: Integer; "Actions": array[2] of Integer)
    var
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
    begin
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackageCode, TableID);
        LibraryRapidStart.CreatePackageTableRule(ConfigTableProcessingRule, ConfigPackageTable, Actions[1], 0);
        LibraryRapidStart.CreatePackageTableRule(ConfigTableProcessingRule, ConfigPackageTable, Actions[2], 0);
    end;

    local procedure CreateTwoPackageTableRulesWithFilters(var FilterValue: array[4] of Integer)
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageFilter: Record "Config. Package Filter";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
        SalesActions: array[2] of Integer;
        Counter: Integer;
        FieldNo: Integer;
    begin
        LibraryRapidStart.CreatePackage(ConfigPackage);
        GetSalesActions(SalesActions);
        CreatePackageTableWithTwoRules(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Sales Header", SalesActions);
        ConfigTableProcessingRule.FindSet();
        repeat
            for FieldNo := 1 to 2 do begin
                Counter += 1;
                FilterValue[Counter] := Counter;
                LibraryRapidStart.CreatePackageTableRuleFilter(
                  ConfigPackageFilter, ConfigTableProcessingRule, FieldNo, Format(FilterValue[Counter]));
            end;
        until ConfigTableProcessingRule.Next() = 0;
    end;

    local procedure CreatePackageWithRuleForGenJnlLine(var ConfigTableProcessingRule: Record "Config. Table Processing Rule")
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
    begin
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Gen. Journal Line");
        LibraryRapidStart.CreatePackageTableRule(
          ConfigTableProcessingRule, ConfigPackageTable, ConfigTableProcessingRule.Action::Post, 0);
    end;

    local procedure CreatePackageWithRuleForPurchHeader(var ConfigTableProcessingRule: Record "Config. Table Processing Rule"; "Action": Option)
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
    begin
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Purchase Header");
        LibraryRapidStart.CreatePackageTableRule(ConfigTableProcessingRule, ConfigPackageTable, Action, 0);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Purchase Line");
        ConfigPackageTable.Validate("Parent Table ID", DATABASE::"Purchase Header");
        ConfigPackageTable.Modify(true);
    end;

    local procedure CreatePackageWithRuleForSalesHeader(var ConfigTableProcessingRule: Record "Config. Table Processing Rule"; "Action": Option)
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
    begin
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Sales Header");
        LibraryRapidStart.CreatePackageTableRule(ConfigTableProcessingRule, ConfigPackageTable, Action, 0);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Sales Line");
        ConfigPackageTable.Validate("Parent Table ID", DATABASE::"Sales Header");
        ConfigPackageTable.Modify(true);
    end;

    local procedure CreatePackageWithRuleForCompanyInformation(var ConfigTableProcessingRule: Record "Config. Table Processing Rule")
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
    begin
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Company Information");
        LibraryRapidStart.CreatePackageTableRule(
          ConfigTableProcessingRule, ConfigPackageTable, ConfigTableProcessingRule.Action::Custom, CODEUNIT::"Setup Company Name");
    end;

    local procedure CreatePackageWithCustomer(var ConfigPackage: Record "Config. Package"; DeleteRecords: Boolean)
    var
        ConfigPackageTable: Record "Config. Package Table";
    begin
        LibraryRapidStart.CreatePackage(ConfigPackage);

        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::Customer);
        ConfigPackageTable."Delete Recs Before Processing" := DeleteRecords;
        ConfigPackageTable."Skip Table Triggers" := true;
        ConfigPackageTable.Modify();

        LibraryRapidStart.CreatePackageData(ConfigPackage.Code, DATABASE::Customer, 1, 1,
          LibraryUtility.GenerateRandomCode(1, DATABASE::Customer));
    end;

    local procedure CreateRuleForGenJnlPackage(var ConfigTableProcessingRule: Record "Config. Table Processing Rule")
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
    begin
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"G/L Account");
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Gen. Journal Template");
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Gen. Journal Batch");
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Gen. Journal Line");
        LibraryRapidStart.CreatePackageTableRule(
          ConfigTableProcessingRule, ConfigPackageTable, ConfigTableProcessingRule.Action::Post, 0);
    end;

    local procedure CreatePurchOrder(var PurchHeader: Record "Purchase Header")
    var
        GLAccount: Record "G/L Account";
        PurchLine: Record "Purchase Line";
        VendorNo: Code[20];
    begin
        GLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());
        VendorNo :=
          LibraryPurchase.CreateVendorWithBusPostingGroups(
            GLAccount."Gen. Bus. Posting Group", GLAccount."VAT Bus. Posting Group");
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, VendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::"G/L Account", GLAccount."No.", 1);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header")
    var
        GLAccount: Record "G/L Account";
        SalesLine: Record "Sales Line";
        CustomerNo: Code[20];
    begin
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        CustomerNo :=
          LibrarySales.CreateCustomerWithBusPostingGroups(
            GLAccount."Gen. Bus. Posting Group", GLAccount."VAT Bus. Posting Group");
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", 1);
    end;

    local procedure CreateRuleVariations(ExpectedConfigTableProcessingRule: Record "Config. Table Processing Rule")
    var
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
    begin
        ConfigTableProcessingRule := ExpectedConfigTableProcessingRule;
        ConfigTableProcessingRule.Insert();
        ConfigTableProcessingRule := ExpectedConfigTableProcessingRule;
        ConfigTableProcessingRule."Table ID" += 1;
        ConfigTableProcessingRule.Insert();
        ConfigTableProcessingRule := ExpectedConfigTableProcessingRule;
        ConfigTableProcessingRule."Package Code" += 'X';
        ConfigTableProcessingRule.Insert();
        ConfigTableProcessingRule := ExpectedConfigTableProcessingRule;
        ConfigTableProcessingRule."Rule No." += 10000;
        ConfigTableProcessingRule.Insert();
    end;

    local procedure ExportImportPackage(ConfigPackageCode: Code[20]; Overwrite: Boolean)
    var
        ConfigPackageTable: Record "Config. Package Table";
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
        FileMgt: Codeunit "File Management";
        FilePath: Text;
    begin
        ConfigXMLExchange.SetCalledFromCode(true);
        ConfigXMLExchange.SetHideDialog(true);

        FilePath := FileMgt.ServerTempFileName('xml');
        ConfigPackageTable.SetRange("Package Code", ConfigPackageCode);
        ConfigXMLExchange.ExportPackageXML(ConfigPackageTable, FilePath);
        if not Overwrite then
            LibraryRapidStart.CleanUp(ConfigPackageCode);
        ConfigXMLExchange.ImportPackageXML(FilePath);
    end;

    local procedure ExportImportPackageWithRuleForPurchHeader(var ConfigPackage: Record "Config. Package"; var PurchHeader: Record "Purchase Header"; "Action": Option; CodeunitID: Integer)
    var
        ConfigPackageField: Record "Config. Package Field";
        ConfigPackageFilter: Record "Config. Package Filter";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
        PurchLine: Record "Purchase Line";
    begin
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Purchase Header");
        ConfigPackageField.Get(ConfigPackage.Code, ConfigPackageTable."Table ID", PurchHeader.FieldNo("No."));
        LibraryRapidStart.CreatePackageTableRule(ConfigTableProcessingRule, ConfigPackageTable, Action, CodeunitID);
        ConfigPackageMgt.InsertPackageFilter(
          ConfigPackageFilter, ConfigPackage.Code, ConfigPackageTable."Table ID", 0, PurchHeader.FieldNo("No."), PurchHeader."No.");

        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Purchase Line");
        ConfigPackageTable.Validate("Parent Table ID", DATABASE::"Purchase Header");
        ConfigPackageTable.Modify(true);
        ConfigPackageMgt.InsertPackageFilter(
          ConfigPackageFilter, ConfigPackage.Code, ConfigPackageTable."Table ID", 0, PurchLine.FieldNo("Document No."), PurchHeader."No.");

        ExportImportPackage(ConfigPackage.Code, false);
        PurchHeader.Delete(true);
    end;

    local procedure ExportImportPackageWithRuleForSalesHeader(var ConfigPackage: Record "Config. Package"; var SalesHeader: Record "Sales Header"; "Action": Option; CodeunitID: Integer)
    var
        ConfigPackageField: Record "Config. Package Field";
        ConfigPackageFilter: Record "Config. Package Filter";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
        SalesLine: Record "Sales Line";
    begin
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Sales Header");
        ConfigPackageField.Get(ConfigPackage.Code, ConfigPackageTable."Table ID", SalesHeader.FieldNo("No."));
        LibraryRapidStart.CreatePackageTableRule(ConfigTableProcessingRule, ConfigPackageTable, Action, CodeunitID);
        ConfigPackageMgt.InsertPackageFilter(
          ConfigPackageFilter, ConfigPackage.Code, ConfigPackageTable."Table ID", 0, SalesHeader.FieldNo("No."), SalesHeader."No.");

        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Sales Line");
        ConfigPackageTable.Validate("Parent Table ID", DATABASE::"Sales Header");
        ConfigPackageTable.Modify(true);
        ConfigPackageMgt.InsertPackageFilter(
          ConfigPackageFilter, ConfigPackage.Code, ConfigPackageTable."Table ID", 0, SalesLine.FieldNo("Document No."), SalesHeader."No.");

        ExportImportPackage(ConfigPackage.Code, false);
        SalesHeader.Delete(true);
    end;

    local procedure GetLastGLEntryNo(): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        if GLEntry.FindLast() then
            exit(GLEntry."Entry No.");
        exit(0);
    end;

    local procedure GetLastCLEntryNo(): Integer
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        if CustLedgEntry.FindLast() then
            exit(CustLedgEntry."Entry No.");
        exit(0);
    end;

    local procedure GetLastVLEntryNo(): Integer
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        if VendLedgEntry.FindLast() then
            exit(VendLedgEntry."Entry No.");
        exit(0);
    end;

    local procedure GetPurchActions(var PurchAction: array[2] of Integer)
    var
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
    begin
        PurchAction[1] := ConfigTableProcessingRule.Action::Receive;
        PurchAction[2] := ConfigTableProcessingRule.Action::Invoice;
    end;

    local procedure GetSalesActions(var SalesAction: array[2] of Integer)
    var
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
    begin
        SalesAction[1] := ConfigTableProcessingRule.Action::Ship;
        SalesAction[2] := ConfigTableProcessingRule.Action::Invoice;
    end;

    local procedure PutGenJnlLineToConfigPackageData(ConfigPackageCode: Code[20]; var ConfigPackageRecord: Record "Config. Package Record"; GenJnlLine: Record "Gen. Journal Line")
    var
        ConfigPackageData: Record "Config. Package Data";
    begin
        ConfigPackageRecord."Package Code" := ConfigPackageCode;
        ConfigPackageRecord."Table ID" := DATABASE::"Gen. Journal Line";
        ConfigPackageRecord."No." += 1;
        ConfigPackageRecord.Insert();

        ConfigPackageData.Init();
        ConfigPackageData."Package Code" := ConfigPackageCode;
        ConfigPackageData."Table ID" := ConfigPackageRecord."Table ID";
        ConfigPackageData."No." := ConfigPackageRecord."No.";
        ConfigPackageData."Field ID" := GenJnlLine.FieldNo("Journal Template Name");
        ConfigPackageData.Value := GenJnlLine."Journal Template Name";
        ConfigPackageData.Insert();
        ConfigPackageData."Field ID" := GenJnlLine.FieldNo("Journal Batch Name");
        ConfigPackageData.Value := GenJnlLine."Journal Batch Name";
        ConfigPackageData.Insert();
        ConfigPackageData."Field ID" := GenJnlLine.FieldNo("Line No.");
        ConfigPackageData.Value := Format(GenJnlLine."Line No.");
        ConfigPackageData.Insert();
        ConfigPackageData."Field ID" := GenJnlLine.FieldNo("Posting Date");
        ConfigPackageData.Value := Format(GenJnlLine."Posting Date");
        ConfigPackageData.Insert();
    end;

    local procedure PutCompanyInformationToConfigPackageData(ConfigPackageCode: Code[20]; var ConfigPackageRecord: Record "Config. Package Record"; CompanyInformation: Record "Company Information")
    var
        ConfigPackageData: Record "Config. Package Data";
    begin
        ConfigPackageRecord."Package Code" := ConfigPackageCode;
        ConfigPackageRecord."Table ID" := DATABASE::"Company Information";
        ConfigPackageRecord."No." += 1;
        ConfigPackageRecord.Insert();

        ConfigPackageData.Init();
        ConfigPackageData."Package Code" := ConfigPackageCode;
        ConfigPackageData."Table ID" := ConfigPackageRecord."Table ID";
        ConfigPackageData."No." := ConfigPackageRecord."No.";
        ConfigPackageData."Field ID" := CompanyInformation.FieldNo("Primary Key");
        ConfigPackageData.Value := CompanyInformation."Primary Key";
        ConfigPackageData.Insert();
    end;

    local procedure VerifyCLEntryCount(DocumentNo: Code[20]; LastCLEntryNo: Integer; ExpectedCount: Integer)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        if DocumentNo <> '' then
            CustLedgEntry.SetRange("Document No.", DocumentNo);
        CustLedgEntry.SetFilter("Entry No.", '>%1', LastCLEntryNo);
        Assert.AreEqual(
          ExpectedCount, CustLedgEntry.Count,
          StrSubstNo('%1 %2:<%3>', CustLedgEntry.TableCaption(), CustLedgEntry.FieldCaption("Document No."), DocumentNo));
    end;

    local procedure VerifyGLEntryCount(DocumentNo: Code[20]; LastGLEntryNo: Integer; ExpectedCount: Integer)
    var
        GLEntry: Record "G/L Entry";
    begin
        if DocumentNo <> '' then
            GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetFilter("Entry No.", '>%1', LastGLEntryNo);
        Assert.AreEqual(
          ExpectedCount, GLEntry.Count,
          StrSubstNo('%1 %2:<%3>', GLEntry.TableCaption(), GLEntry.FieldCaption("Document No."), DocumentNo));
    end;

    local procedure VerifyVLEntryCount(DocumentNo: Code[20]; LastVLEntryNo: Integer; ExpectedCount: Integer)
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        if DocumentNo <> '' then
            VendLedgEntry.SetRange("Document No.", DocumentNo);
        VendLedgEntry.SetFilter("Entry No.", '>%1', LastVLEntryNo);
        Assert.AreEqual(
          ExpectedCount, VendLedgEntry.Count,
          StrSubstNo('%1 %2:<%3>', VendLedgEntry.TableCaption(), VendLedgEntry.FieldCaption("Document No."), DocumentNo));
    end;

    local procedure VerifyPurchOrderIsInvoiced(PurchHeader: Record "Purchase Header"; LastVLEntryNo: Integer)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        VerifyVLEntryCount('', LastVLEntryNo, 1);
        Assert.IsFalse(PurchHeader.Find(), PurchHeader.TableCaption());
        PurchInvHeader.Reset();
        PurchInvHeader.SetRange("Order No.", PurchHeader."No.");
        Assert.IsTrue(PurchInvHeader.FindFirst(), PurchInvHeader.TableCaption());
    end;

    local procedure VerifyPurchOrderIsReceived(PurchHeader: Record "Purchase Header"; LastVLEntryNo: Integer)
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
    begin
        VerifyVLEntryCount('', LastVLEntryNo, 0);
        Assert.IsTrue(PurchHeader.Find(), PurchHeader.TableCaption());
        PurchRcptHeader.Reset();
        PurchRcptHeader.SetRange("Order No.", PurchHeader."No.");
        Assert.IsTrue(PurchRcptHeader.FindFirst(), PurchRcptHeader.TableCaption());
    end;

    local procedure VerifySalesOrderIsInvoiced(SalesHeader: Record "Sales Header"; LastCLEntryNo: Integer)
    var
        SalesInvHeader: Record "Sales Invoice Header";
    begin
        VerifyCLEntryCount('', LastCLEntryNo, 1);
        Assert.IsFalse(SalesHeader.Find(), SalesHeader.TableCaption());
        SalesInvHeader.Reset();
        SalesInvHeader.SetRange("Order No.", SalesHeader."No.");
        Assert.IsTrue(SalesInvHeader.FindFirst(), SalesInvHeader.TableCaption());
    end;

    local procedure VerifySalesOrderIsShipped(SalesHeader: Record "Sales Header"; LastCLEntryNo: Integer)
    var
        SalesShptHeader: Record "Sales Shipment Header";
    begin
        VerifyCLEntryCount('', LastCLEntryNo, 0);
        Assert.IsTrue(SalesHeader.Find(), SalesHeader.TableCaption());
        SalesShptHeader.Reset();
        SalesShptHeader.SetRange("Order No.", SalesHeader."No.");
        Assert.IsTrue(SalesShptHeader.FindFirst(), SalesShptHeader.TableCaption());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomCodIdEditableModalHandler(var ConfigTableProcessingRules: TestPage "Config. Table Processing Rules")
    var
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
    begin
        ConfigTableProcessingRules.First();
        ConfigTableProcessingRules.Action.SetValue(ConfigTableProcessingRule.Action::Custom);
        ConfigTableProcessingRules."Custom Processing Codeunit ID".Activate();
        Assert.IsTrue(
          ConfigTableProcessingRules."Custom Processing Codeunit ID".Editable(),
          ConfigTableProcessingRules."Custom Processing Codeunit ID".Caption);
        ConfigTableProcessingRules."Custom Processing Codeunit ID".SetValue(CODEUNIT::"Sales-Post");

        ConfigTableProcessingRules.Next();
        Assert.IsFalse(
          ConfigTableProcessingRules."Custom Processing Codeunit ID".Editable(),
          ConfigTableProcessingRules.Action.Value);

        ConfigTableProcessingRules.Previous();
        Assert.IsTrue(
          ConfigTableProcessingRules."Custom Processing Codeunit ID".Editable(),
          ConfigTableProcessingRules."Custom Processing Codeunit ID".Caption);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MsgHandler(Message: Text)
    var
        TableID: Integer;
    begin
        TableID := LibraryVariableStorage.DequeueInteger();
        Assert.ExpectedMessage(StrSubstNo(ImplementProcessingLogicMsg, TableID), Message);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TableFiltersModalHandler(var ConfigPackageFilters: TestPage "Config. Package Filters")
    begin
        Assert.IsFalse(ConfigPackageFilters.First(), 'Should be no filters shown');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure RulesModalHandler(var ConfigTableProcessingRules: TestPage "Config. Table Processing Rules")
    var
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
    begin
        ConfigTableProcessingRules.Action.SetValue(ConfigTableProcessingRule.Action::Ship);
        ConfigTableProcessingRules.New();

        ConfigTableProcessingRule.FindLast();
        LibraryVariableStorage.Enqueue(ConfigTableProcessingRule."Rule No."); // return to the test RuleNoDefinedAutomatically

        ConfigTableProcessingRules.Action.SetValue(ConfigTableProcessingRule.Action::Invoice);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ShowProcessingFiltersFromRulesModalHandler(var ConfigTableProcessingRules: TestPage "Config. Table Processing Rules")
    begin
        ConfigTableProcessingRules.Last();
        ConfigTableProcessingRules.ProcessingFilters.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProcessingFiltersModalHandler(var ConfigPackageFilters: TestPage "Config. Package Filters")
    begin
        ConfigPackageFilters.First();
        ConfigPackageFilters."Field Filter".AssertEquals(LibraryVariableStorage.DequeueInteger());
        ConfigPackageFilters.Last();
        ConfigPackageFilters."Field Filter".AssertEquals(LibraryVariableStorage.DequeueInteger());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VerifyFilterInfoForRulesModalHandler(var ConfigTableProcessingRules: TestPage "Config. Table Processing Rules")
    begin
        ConfigTableProcessingRules.First();
        ConfigTableProcessingRules.FilterInfo.AssertEquals(LibraryVariableStorage.DequeueText());
        ConfigTableProcessingRules.Next();
        ConfigTableProcessingRules.FilterInfo.AssertEquals(LibraryVariableStorage.DequeueText());
        Assert.IsFalse(ConfigTableProcessingRules.FilterInfo.Editable(), 'Filter info should not be editable');
    end;

    local procedure CreateCustomReportLayouts(ReportQty: Integer; ReportID: Integer)
    var
        CustomReportLayout: Record "Custom Report Layout";
        i: Integer;
    begin
        for i := 1 to ReportQty do begin
            CustomReportLayout.InitBuiltInLayout(ReportID, CustomReportLayout.Type::Word.AsInteger());
            CustomReportLayout.Description := StrSubstNo('Layout %1', i);
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Config. Table Processing Rule", 'OnDoesTableHaveCustomRuleInRapidStart', '', false, false)]
    local procedure OnDoesTableHaveCustomHandler(TableID: Integer; var Result: Boolean)
    begin
        if TableID in [DATABASE::"Purchase Header", DATABASE::"Sales Header"] then
            Result := true;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Config. Package - Process", 'OnBeforeTextTransformation', '', false, false)]
    local procedure OnBeforeTextTransformationHandler(ConfigPackageTable: Record "Config. Package Table"; var TempField: Record "Field" temporary; var TempTransformationRule: Record "Transformation Rule" temporary)
    var
        Vendor: Record Vendor;
        ConfigPackageProcess: Report "Config. Package - Process";
    begin
        case ConfigPackageTable."Table ID" of
            DATABASE::Vendor:
                ConfigPackageProcess.AddRuleForField(
                  DATABASE::Vendor, Vendor.FieldNo(Name),
                  TempTransformationRule."Transformation Type"::Uppercase.AsInteger(), TempField, TempTransformationRule);
        end
    end;
}

