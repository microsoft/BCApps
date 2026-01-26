codeunit 142006 "Export Business Data"
{
    // // [FEATURE] [Export Business Data]
    // -----------------------------------------------
    // Test Function Name
    // -----------------------------------------------
    // 2.  TestExportedFilesExistence
    // 3.  TestTableExcludedIfNoRecordsInPeriodFilter
    // 4.  TestEntriesExcludedIfNotInPeriodFilter
    // 5.  TestDTDFileNameInIndexXML
    // 6.  TestMediaNameTagInIndexXML
    // 7.  TestFieldCountInIndexXML
    // 8.  TestCorrectTableNameUsedInIndexXML
    // 9.  TestCorrectPKFieldNameUsedInIndexXML
    // 10. TestCorrectFieldNameUsedInIndexXML
    // 11. TestKeyNoUsage
    // 12. TestTableFilter
    // 13. TestIgnoredFilterOnPeriodFieldByTableFilter
    // 14. TestSettingTableFilterWithoutPeriodField
    // 15. TestExportOneTableFlowFilterApplied
    // 16. TestExportDateFilterHandlingEndDate
    // 17. TestExportDateFilterHandlingStartDate
    // 18. TestExportRelatedTablesFlowFilterApplied
    // 19. TestLogExportedRecords
    // 20. TestExportPeriodInLog
    // 21. TestTablesNumberInLog
    // 22. TestsExportLogIfNothingToExport
    // 24. TestNoFieldsInRecordSource
    // 25. TestRecFieldsDeletion
    // 26. TestRelatedTableDeletion
    // 27. TestFlowFieldsCalcAccordingAppliedFilters
    // 28. TestExportTwoEqualFlowFields
    // 29. TestDateFilterFieldNoIsFilled
    // 30. TestExportWithDateFilterFieldNo
    // 31. TestExportLongRecord

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        DataCompression: Codeunit "Data Compression";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryDimension: Codeunit "Library - Dimension";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryXMLRead: Codeunit "Library - XML Read";
        LogFileTxt: Label 'Log.txt';
        DurationTxt: Label 'Duration:';
        DurationErr: Label 'Duration is not found.';
        IndexFileTxt: Label 'index.xml';
        DefaultDTDFileTxt: Label 'empty.dtd';
        FlowFilterRecExportErr: Label 'Records with flow filter applied exported incorrectly.';
        LogFileErr: Label 'Substring <%1> does not exist in log file.';
        LogFileLineTxt: Label 'For table %1, %2 data records were exported';
        IncorrectNoOfRelatedRecsErr: Label 'Incorrect number of related records after applying flowfilter.';
        NoFieldsDefinedErr: Label 'Data cannot be exported because no fields have been defined for one or more tables in the %1 data export.';
        CannotFindFileErr: Label 'Cannot find exported file: %1';
        WrongNoOfLinesExportedErr: Label 'Wrong number of lines exported. Expected lines : %1.';
        WrongEntryNoExportedErr: Label 'Wrong "Entry No." exported.';
        WrongCountOfElementsErr: Label 'Wrong count of elements <%1>';
        DTDMissedInDocTypeSectionErr: Label 'DOCTYPE section should contain short DTD file name: %1';
        WrongElementValueErr: Label 'Wrong Element value <%2> in Node <%1>';
        PeriodFieldFilterErr: Label 'You cannot use the period field Posting Date in the table filter';
        WrongTableFilterTextErr: Label 'Wrong Table Filter text';
        NotAllRecFieldsDeletedErr: Label 'Not all the related Fields were deleted';
        NotAllReleatedTablesDeletedErr: Label 'Not all the related Tables were deleted';
        WrongPeriodErr: Label 'Wrong Period: <%1> does not exist in <%2>';
        WrongTablesNumberErr: Label 'Wrong number of Tables was exported';
        WrongDateFilterFieldNoErr: Label 'Wrong Date Filter Field in table %1.';
        ValueErr: Label 'Line Length should be greater than or equal to 1024.';
        EmptyFileErr: Label 'File %1 is not empty.';
        WrongValueErr: Label 'Incorrect exported line value.';
        CannotModifyTableNoErr: Label 'You cannot modify the Table No. field.';
        WrongNoOfLinesErr: Label 'Wrong number of %1 in setup';
        WrongIndentErr: Label 'Indentation is not correct.';
        OptionValueErr: Label 'Wrong option value in file.';
        GLAccTxt: Label 'GLAcc 2022';
        FAAccTxt: Label 'FAAcc 2022';
        ItemAccTxt: Label 'Item 2022';
        CVLedgerEntryLineFormatTxt: Label '%1;"%2";%3';
        DtldCVLedgEntryLineFormatTxt: Label '%1;%2;"%3";%4';
        CVLedgerEntryFileNameTxt: Label 'CVLedgerEntryBuffer.txt';
        DtldCVLedgEntryFileNameTxt: Label 'DetailedCVLedgEntryBuffer.txt';

    [Test]
    [Scope('OnPrem')]
    procedure BlankFileCreated()
    var
        CVLedgEntryBuffer: Record "CV Ledger Entry Buffer";
        DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer";
        DataExportRecord: Record "Data Export Record Definition";
        ExpectedFileNames: array[5] of Text;
        FolderName: Text;
    begin
        // [FEATURE] Digital Audit
        // [SCENARIO 080] 352285 - Export blank file.
        // [GIVEN] Both Parent Table and Child Table have no records to export.
        SetupParentChildTablesForExport(DataExportRecord, ExpectedFileNames);

        // [WHEN] Export data
        FolderName := ExportBusinessData(DataExportRecord);

        // [THEN] Parent and Child Files are empty
        VerifyFileIsEmpty(FolderName, ExpectedFileNames[1]);
        VerifyFileIsEmpty(FolderName, ExpectedFileNames[2]);
        // [THEN] Log.txt reports: 0 data records exported, 1 file(s) created
        ValidateLogFile(FolderName, 1, CVLedgEntryBuffer.TableName, 0);
        ValidateLogFile(FolderName, 2, DetailedCVLedgEntryBuffer.TableName, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DurationInLogTxt()
    var
        DataExportRecord: Record "Data Export Record Definition";
        ExpectedFileNames: array[5] of Text;
        FolderName: Text;
    begin
        // [FEATURE] Digital Audit
        // [SCENARIO 089] Duration reported per table in Log.txt
        // [GIVEN] Table contains N records to export.
        SetupParentChildTablesForExport(DataExportRecord, ExpectedFileNames);
        InsertChildEntries(1);

        // [WHEN] Exporting the file.
        FolderName := ExportBusinessData(DataExportRecord);

        // [THEN] Log.txt reports: ...1 file(s) created, Duration: X Seconds Y Miliseconds
        VerifyDurationInLogFile(FolderName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestExportedFilesExistence()
    var
        DataExportRecord: Record "Data Export Record Definition";
        ExpectedFileNames: array[6] of Text;
        FolderName: Text;
    begin
        SetupParentChildTablesForExport(DataExportRecord, ExpectedFileNames);
        InsertChildEntries(1);

        FolderName := ExportBusinessData(DataExportRecord);
        ExpectedFileNames[3] := LogFileTxt;
        ExpectedFileNames[4] := IndexFileTxt;
        ExpectedFileNames[5] := DefaultDTDFileTxt;
        VerifyFileNames(FolderName, ExpectedFileNames);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTableExcludedIfNoRecordsInPeriodFilter()
    var
        DataExportRecord: Record "Data Export Record Definition";
        ExpectedFileNames: array[5] of Text;
        FolderName: Text;
    begin
        // [FEATURE] Digital Audit
        // [SCENARIO 080] Export blank file when shift a period
        // [GIVEN] Parent Table contains 1 record
        SetupParentChildTablesForExport(DataExportRecord, ExpectedFileNames);
        // [GIVEN] Child Table has 1 record, but out of reporting period
        InsertChildEntries(1);
        ShiftPostingDateInFirstChildEntry();

        // [WHEN] Export data
        FolderName := ExportBusinessData(DataExportRecord);

        // [THEN] Child File is created empty
        VerifyFileIsEmpty(FolderName, ExpectedFileNames[2]);
        // [THEN] Parent File is not empty
        asserterror VerifyFileIsEmpty(FolderName, ExpectedFileNames[1]);
        Assert.ExpectedError(StrSubstNo(EmptyFileErr, ExpectedFileNames[1]))
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEntriesExcludedIfNotInPeriodFilter()
    var
        DataExportRecord: Record "Data Export Record Definition";
        TempEntryNo: Record "Integer" temporary;
        DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer";
        ExpectedFileNames: array[5] of Text;
        FolderName: Text;
    begin
        SetupParentChildTablesForExport(DataExportRecord, ExpectedFileNames);
        InsertChildEntries(LibraryRandom.RandIntInRange(2, 5));
        ShiftPostingDateInFirstChildEntry();
        FindChildEntriesToExport(DtldCVLedgEntryBuffer, TempEntryNo);

        FolderName := ExportBusinessData(DataExportRecord);

        VerifyEntryNosInDataFile(FolderName, ExpectedFileNames[2], TempEntryNo, FALSE);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultipleRecordsOfTwoRelatedTables()
    var
        DataExportRecord: Record "Data Export Record Definition";
        TempEntryNo: Record "Integer" temporary;
        DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer";
        ExpectedFileNames: array[5] of Text;
        ExpectedNoOfRecords: Integer;
        FolderName: Text;
    begin
        // [FEATURE] Digital Audit
        // [SCENARIO 082] Multiple records exported in two files
        // [GIVEN] 2 linked tables contains N and M records to export.
        SetupParentChildTablesForExport(DataExportRecord, ExpectedFileNames);
        ExpectedNoOfRecords := LibraryRandom.RandIntInRange(2, 5);
        InsertChildEntries(ExpectedNoOfRecords);
        FindChildEntriesToExport(DtldCVLedgEntryBuffer, TempEntryNo);

        // [WHEN] Export data
        FolderName := ExportBusinessData(DataExportRecord);

        // [THEN] 2 Files are created with N and M records
        VerifyEntryNosInDataFile(FolderName, ExpectedFileNames[2], TempEntryNo, FALSE);
        // [THEN] Log.txt reports: N (or M) data records exported
        ValidateLogFile(FolderName, 2, DtldCVLedgEntryBuffer.TableName, ExpectedNoOfRecords);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDTDFileNameInIndexXML()
    var
        DataExportRecord: Record "Data Export Record Definition";
        FolderName: Text;
    begin
        FolderName := ExportMinBusinessData(DataExportRecord);

        VerifyDTDFileNameInIndexXML(FolderName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMediaNameTagInIndexXML()
    var
        DataExportRecord: Record "Data Export Record Definition";
        FolderName: Text;
    begin
        FolderName := ExportMinBusinessData(DataExportRecord);

        VerifyElementValueInIndexXML(FolderName, 'Name', 'Media', DataExportRecord."Data Exp. Rec. Type Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFieldCountInIndexXML()
    var
        DataExportRecord: Record "Data Export Record Definition";
        ExpectedFileNames: array[5] of Text;
        FolderName: Text;
    begin
        SetupParentChildTablesForExport(DataExportRecord, ExpectedFileNames);
        InsertChildEntries(1);

        FolderName := ExportBusinessData(DataExportRecord);

        VerifyElementCountInIndexXML(FolderName, 'Table', 2);
        VerifyElementCountInIndexXML(FolderName, 'VariablePrimaryKey', 2);
        VerifyElementCountInIndexXML(FolderName, 'VariableColumn', 5);
        VerifyElementCountInIndexXML(FolderName, 'Date', 1);
        VerifyElementCountInIndexXML(FolderName, 'AlphaNumeric', 2);
        VerifyElementCountInIndexXML(FolderName, 'Numeric', 4);
        VerifyElementCountInIndexXML(FolderName, 'Accuracy', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectTableNameUsedInIndexXML()
    var
        DataExportRecord: Record "Data Export Record Definition";
        DataExportRecordSource: Record "Data Export Record Source";
        FolderName: Text;
    begin
        FolderName := ExportDtldMinBusinessData(DataExportRecord, DataExportRecordSource);

        VerifyElementValueInIndexXML(FolderName, 'Name', 'Table', DataExportRecordSource."Export Table Name");
        DataExportRecordSource.CalcFields("Table Name");
        VerifyElementValueInIndexXML(FolderName, 'Description', 'Table', DataExportRecordSource."Table Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectPKFieldNameUsedInIndexXML()
    var
        DataExportRecord: Record "Data Export Record Definition";
        DataExportRecordSource: Record "Data Export Record Source";
        ExpectedName: array[2] of Text;
        FolderName: Text;
    begin
        FolderName := ExportDtldMinBusinessData(DataExportRecord, DataExportRecordSource);
        GetExportFieldName(DataExportRecordSource, GetPKFieldIndex(), ExpectedName);

        VerifyElementValueInIndexXML(FolderName, 'Name', 'VariablePrimaryKey', ExpectedName[2]);
        VerifyElementValueInIndexXML(FolderName, 'Description', 'VariablePrimaryKey', ExpectedName[1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectFieldNameUsedInIndexXML()
    var
        DataExportRecord: Record "Data Export Record Definition";
        DataExportRecordSource: Record "Data Export Record Source";
        ExpectedName: array[2] of Text;
        FolderName: Text;
    begin
        FolderName := ExportDtldMinBusinessData(DataExportRecord, DataExportRecordSource);
        GetExportFieldName(DataExportRecordSource, GetFirstNonPKFieldIndex(), ExpectedName);

        VerifyElementValueInIndexXML(FolderName, 'Name', 'VariableColumn', ExpectedName[2]);
        VerifyElementValueInIndexXML(FolderName, 'Description', 'VariableColumn', ExpectedName[1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCompanyInfoUmlautRemovedFromXML()
    var
        DataExportRecord: Record "Data Export Record Definition";
        CompanyInformation: Record "Company Information";
        GermanicUmlautTxt: Text;
        ConvertedGermanicUmlautTxt: Text;
        FolderName: Text;
    begin
        // [FEATURE] Digital Audit
        // [SCENARIO 200] XML Convert String, XML file does not contain umlaut.
        GermanicUmlautTxt := 'ÄÖÜüöäß';
        ConvertedGermanicUmlautTxt := 'AeOeUeueoeaess';

        // [GIVEN] Company information contrains umlauts in the following fields:,Address,Adress2,City,Description.
        CompanyInformation.FindFirst();
        CompanyInformation.Address := GermanicUmlautTxt;
        CompanyInformation."Address 2" := GermanicUmlautTxt;
        CompanyInformation.City := GermanicUmlautTxt;
        CompanyInformation.Modify(true);

        // [WHEN] Export Data.
        FolderName := ExportMinBusinessData(DataExportRecord);

        // [THEN] In the XML file the following data does not contain umlauts: Address,Adress2,City,Description.
        VerifyElementValueInIndexXML(
          FolderName, 'Location', 'DataSupplier',
          ConvertedGermanicUmlautTxt +
          ' ' + ConvertedGermanicUmlautTxt + ' ' + CompanyInformation."Post Code" + ' ' + ConvertedGermanicUmlautTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestExportVendorNameUnconverted()
    var
        DataExportRecord: Record "Data Export Record Definition";
        DataExportRecordSource: Record "Data Export Record Source";
        Vendor: Record Vendor;
        ExportFileName: Text;
        GermanicUmlautTxt: Text;
        FolderName: Text;
    begin
        // [FEATURE] Digital Audit
        // [SCENARIO 201] Exported table file contains umlauts.
        CreateRecDefinition(DataExportRecord);
        GermanicUmlautTxt := 'ÄÖÜüöäß';

        // [GIVEN] Vendor table exists in Data Source Export, with Name field set to export.
        LibraryPurchase.CreateVendor(Vendor);
        AddRecordSourceWithFilters(
          DataExportRecord, VendorTableNo(),
          Vendor.TableName + ':' + Vendor.FieldName("No.") + '=' + Vendor."No.", DataExportRecordSource);
        ExportFileName := DataExportRecordSource."Export File Name";

        // [GIVEN] Vendor name contains umlauts.
        Vendor.Name := GermanicUmlautTxt;
        Vendor.Modify(true);

        // [WHEN] Export Data.
        FolderName := ExportBusinessData(DataExportRecord);

        // [THEN] Vendor name still contains umlauts.
        ValidateExportedFieldDataFromFileFile(
          FolderName, ExportFileName, GermanicUmlautTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestKeyNoUsage()
    var
        DataExportRecord: Record "Data Export Record Definition";
        TempEntryNo: Record "Integer" temporary;
        DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer";
        ExpectedFileNames: array[5] of Text;
        FolderName: Text;
    begin
        SetupParentChildTablesForExport(DataExportRecord, ExpectedFileNames);
        SetKeyNoAsNotPK(DataExportRecord, ChildTableNo());

        InsertChildEntries(2);
        SetNonEmptyCustNoInFirstChildEntry();
        FolderName := ExportBusinessData(DataExportRecord);

        FindChildEntriesToExport(DtldCVLedgEntryBuffer, TempEntryNo);
        TempEntryNo.FindFirst();
        TempEntryNo.Delete();

        VerifyEntryNosInDataFile(FolderName, ExpectedFileNames[2], TempEntryNo, TRUE);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTableFilter()
    var
        DataExportRecord: Record "Data Export Record Definition";
        TempEntryNo: Record "Integer" temporary;
        DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer";
        ExpectedFileNames: array[5] of Text;
        FolderName: Text;
    begin
        SetupParentChildTablesForExport(DataExportRecord, ExpectedFileNames);
        SetTableFilter(DataExportRecord, ChildTableNo(), 'Detailed CV Ledg. Entry Buffer: Entry Type=Application');

        InsertChildEntries(2);
        ShiftDocTypeInFirstChildEntry();
        DuplicateParentChildEntries();

        FolderName := ExportBusinessData(DataExportRecord);

        DtldCVLedgEntryBuffer.SetRange("Entry Type", DtldCVLedgEntryBuffer."Entry Type"::Application);
        FindChildEntriesToExport(DtldCVLedgEntryBuffer, TempEntryNo);

        VerifyEntryNosInDataFile(FolderName, ExpectedFileNames[2], TempEntryNo, FALSE);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIgnoredFilterOnPeriodFieldByTableFilter()
    var
        DataExportRecord: Record "Data Export Record Definition";
        ExpectedFileNames: array[5] of Text;
    begin
        // [FEATURE] Digital Audit
        // [SCENARIO 050] 'Period Field No.' cannot be used in 'Table Filter'
        // [GIVEN] 'Posting Date' is aet as 'Period Field No.'
        SetupParentChildTablesForExport(DataExportRecord, ExpectedFileNames);
        // [WHEN] User adds a filter on 'Posting Date' to 'Table Filter'
        asserterror SetTableFilter(DataExportRecord, ChildTableNo(), 'Detailed CV Ledg. Entry Buffer: Posting Date=' + Format(WorkDate() + 1));
        // [THEN] Error message: You cannot use the period field 'Posting Date' in 'Table Filter'
        Assert.ExpectedError(PeriodFieldFilterErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSettingTableFilterWithoutPeriodField()
    var
        DataExportRecord: Record "Data Export Record Definition";
        DataExportRecordSource: Record "Data Export Record Source";
        CVLedgEntryBuffer: Record "CV Ledger Entry Buffer";
        TableFilterText: Text;
    begin
        // Bug ID 322904
        TableFilterText := CVLedgEntryBuffer.TableName + ': ' + CVLedgEntryBuffer.FieldName("Posting Date") + '=' + Format(WorkDate());
        SetupParentTableForExport(DataExportRecord, DataExportRecordSource);

        DataExportRecordSource.Validate("Period Field No.", 0);
        Evaluate(DataExportRecordSource."Table Filter", TableFilterText);
        DataExportRecordSource.Validate("Table Filter");
        Assert.AreEqual(TableFilterText, Format(DataExportRecordSource."Table Filter"), WrongTableFilterTextErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DifferentTableFlowFilterApplied()
    var
        DataExportRecord: Record "Data Export Record Definition";
        DataExportRecordSource: Record "Data Export Record Source";
        Customer: Record Customer;
        DateFilterHandling: Option " ",Period,"End Date","Start Date";
        FolderName: Text;
    begin
        // [FEATURE] Digital Audit
        // [SCENARIO 090] Independent calculation of FlowFields on table and record level
        // [GIVEN] Create customers with zero and positive balance.
        // [GIVEN] Two of the customers have non-zero balance at WorkDate(), two at later dates
        // [GIVEN] 'Date Filter Handling' on the field is 'Period'
        InitializeFlowFieldScenario(DataExportRecord, DataExportRecordSource, Customer, DateFilterHandling::Period);
        SetTableFilter(DataExportRecord, CustomerTableNo(), FormatCustTableFilter(Customer.GetFilter("No.")));
        // [GIVEN] 'Date Filter Handling' on the table is 'End Date Only'
        DataExportRecordSource.Find();
        DataExportRecordSource."Date Filter Handling" := DataExportRecordSource."Date Filter Handling"::"End Date Only";
        DataExportRecordSource.Modify();

        // [WHEN] Export record with a flow filter for a period after WORKDATE
        FolderName := ExportBusinessDataSetPeriod(DataExportRecord, CalcDate('<1D>', WorkDate()), CalcDate('<1M>', WorkDate()));

        // [THEN] Two customers with positive balance and two with zero balance have been exported
        Customer.SetRange("Date Filter", CalcDate('<1D>', WorkDate()), CalcDate('<1M>', WorkDate()));
        VerifyBusinessDataExport(FolderName, DataExportRecordSource."Export File Name", Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestExportOneTableFlowFilterApplied()
    var
        DataExportRecord: Record "Data Export Record Definition";
        DataExportRecordSource: Record "Data Export Record Source";
        Customer: Record Customer;
        DateFilterHandling: Option " ",Period,"End Date","Start Date";
        FolderName: Text;
    begin
        // Setup: Create customers with zero and positive balance.
        // Two of the customers have non-zero balance at WorkDate(), two at later dates
        InitializeFlowFieldScenario(DataExportRecord, DataExportRecordSource, Customer, DateFilterHandling::Period);

        // Applying flowfilter
        SetTableFilter(DataExportRecord, CustomerTableNo(), FormatCustTableFilter(Customer.GetFilter("No.")));

        // Exercise: Export record with a flow filter
        FolderName := ExportBusinessDataSetPeriod(DataExportRecord, CalcDate('<-1M>', WorkDate()), WorkDate());

        // Verify: Two customers having positive balance at workdatedate have been exported
        VerifyBusinessDataExport(FolderName, DataExportRecordSource."Export File Name", Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestExportDateFilterHandlingEndDate()
    var
        DataExportRecord: Record "Data Export Record Definition";
        DataExportRecordSource: Record "Data Export Record Source";
        Customer: Record Customer;
        DateFilterHandling: Option " ",Period,"Start Date Only","End Date Only";
        FolderName: Text;
    begin
        // Setup: Create customers with zero and positive balance.
        // Two of the customers have non-zero balance at start date, two at later dates
        InitializeFlowFieldScenario(DataExportRecord, DataExportRecordSource, Customer, DateFilterHandling::"End Date Only");

        // Applying flowfilter
        SetTableFilter(DataExportRecord, CustomerTableNo(), FormatCustTableFilter(Customer.GetFilter("No.")));

        // Exercise: Export record with a flow filter
        FolderName := ExportBusinessDataSetPeriod(DataExportRecord, CalcDate('<-1M>', WorkDate()), WorkDate());

        // Verify: Two customers having positive balance at workdatedate have been exported
        VerifyBusinessDataExport(FolderName, DataExportRecordSource."Export File Name", Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestExportDateFilterHandlingStartDate()
    var
        DataExportRecord: Record "Data Export Record Definition";
        DataExportRecordSource: Record "Data Export Record Source";
        Customer: Record Customer;
        DateFilterHandling: Option " ",Period,"End Date Only","Start Date Only";
        FolderName: Text;
    begin
        // Setup: Create customers with zero and positive balance.
        // Two of the customers have non-zero balance at WorkDate(), two at later dates
        InitializeFlowFieldScenario(DataExportRecord, DataExportRecordSource, Customer, DateFilterHandling::"Start Date Only");

        // Applying flowfilter
        SetTableFilter(DataExportRecord, CustomerTableNo(), FormatCustTableFilter(Customer.GetFilter("No.")));

        // Exercise: Export record with a flow filter
        FolderName := ExportBusinessDataSetPeriod(DataExportRecord, CalcDate('<-1M>', WorkDate()), WorkDate());

        // Verify: Two customers having positive balance at workdatedate have been exported
        VerifyBusinessDataExport(FolderName, DataExportRecordSource."Export File Name", Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestExportDateFilterHandlingGLAccountClosingStartDate()
    var
        DataExportRecordDefinition: Record "Data Export Record Definition";
        DataExportRecordSource: Record "Data Export Record Source";
        GLAccount: Record "G/L Account";
        ExportDate: Date;
        AmountX: Decimal;
        AmountY: Decimal;
        FolderName: Text;
    begin
        // [SCENARIO 123684] Export Business Data with the Starting Balance in closed Accounting Period for Income Statement G/L Account
        // [GIVEN] G/L Account = "A"
        GLAccount.Init();
        GLAccount."No." := LibraryUtility.GenerateGUID();
        GLAccount.Insert();

        // [GIVEN] Data Export Record with settings for G/L Account = "A" with Starting Balance
        CreateGLAccountDataExport(
          DataExportRecordDefinition, DataExportRecordSource, GLAccount, DataExportRecordSource."Date Filter Handling"::"Start Date Only");

        // [GIVEN] G/L Entries for G/L Account = "A" and Amount = "X" before Export Date = "D"
        ExportDate := LibraryRandom.RandDate(5);
        AmountX := MockGLEntries(GLAccount."No.", ExportDate - 1, 1);
        // [GIVEN] Closed Income Statement G/L Entries for G/L Account = "A" and Amount = "Y" before Export Date = "D"
        AmountY := MockGLEntries(GLAccount."No.", ClosingDate(ExportDate - 1), -1);

        // [WHEN] Export Business Data on Export Date = "D"
        FolderName := ExportBusinessDataSetPeriod(DataExportRecordDefinition, ExportDate, ExportDate);

        // [THEN] Exported Starting Balance Amount calculated as Amount "X" - Amount "Y"
        VerifyGLAccountBusinessDataExport(
          FolderName, DataExportRecordSource."Export File Name",
          AmountX - AmountY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestExportRelatedTablesFlowFilterApplied()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DataExportRecord: Record "Data Export Record Definition";
        ParentDataExportRecordSource: Record "Data Export Record Source";
        DataExportRecordSource: Record "Data Export Record Source";
        DateFilterHandling: Option " ",Period,"End Date Only","Start Date Only";
        FolderName: Text;
    begin
        // Apply flow filter to master table and verify that related table has been filterd according to the relation setup
        InitializeFlowFieldScenario(DataExportRecord, DataExportRecordSource, Customer, DateFilterHandling::Period);

        ParentDataExportRecordSource := DataExportRecordSource;
        AddRecordSourceWithFields(DataExportRecord, CustLedgEntryTableNo(), DataExportRecordSource);
        DataExportRecordSource."Date Filter Handling" := DateFilterHandling::Period;
        DataExportRecordSource.Modify();
        Indent(DataExportRecordSource, ParentDataExportRecordSource);
        MakeRelation(
          DataExportRecordSource, CustLedgerEntry.FieldNo("Customer No."),
          ParentDataExportRecordSource, Customer.FieldNo("No."));

        SetTableFilter(DataExportRecord, CustomerTableNo(), FormatCustTableFilter(Customer.GetFilter("No.")));

        FolderName :=
          ExportBusinessDataSetPeriod(DataExportRecord, Customer.GetRangeMin("Date Filter"), Customer.GetRangeMax("Date Filter"));

        VerifyRelatedTablesExportFile(FolderName, DataExportRecordSource."Export File Name", Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestLogExportedRecords()
    var
        DataExportRecord: Record "Data Export Record Definition";
        DataExportRecordSource: Record "Data Export Record Source";
        Customer: Record Customer;
        ExpectedNoOfRecords: Integer;
        CustomerNoFIlter: Text;
        FolderName: Text;
    begin
        // [FEATURE] Digital Audit
        // [SCENARIO 081] Multiple records exported in one file
        // [GIVEN] Table contains N records to export.
        CustomerNoFIlter := '*000'; // expect 8 records on standard demodata
        Customer.SetFilter("No.", CustomerNoFIlter);
        ExpectedNoOfRecords := Customer.Count();

        CreateRecDefinition(DataExportRecord);
        AddRecordSourceWithFilters(
          DataExportRecord, CustomerTableNo(),
          Customer.TableName + ':' + Customer.FieldName("No.") + '=' + CustomerNoFIlter, DataExportRecordSource);

        // [WHEN] Export data
        FolderName := ExportBusinessData(DataExportRecord);

        // [THEN] File is created with N records
        VerifyCountOfExportedRecords(
          FolderName, DataExportRecordSource."Export File Name", ExpectedNoOfRecords);
        // [THEN] Log.txt reports: N data records exported, 1 file(s) created
        ValidateLogFile(FolderName, 1, Customer.TableName, ExpectedNoOfRecords);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestExportPeriodInLog()
    var
        DataExportRecord: Record "Data Export Record Definition";
        FolderName: Text;
    begin
        // Verify exported Period in Log file.
        PrepareEmptyBusinessDataToExport(DataExportRecord);

        FolderName := ExportBusinessDataSetPeriod(DataExportRecord, CalcDate('<-1M>', WorkDate()), WorkDate());

        VerifyPeriodInLogFile(FolderName, CalcDate('<-1M>', WorkDate()), WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTablesNumberInLog()
    var
        DataExportRecord: Record "Data Export Record Definition";
        DataExportRecordSource: Record "Data Export Record Source";
        Customer: Record Customer;
        Vendor: Record Vendor;
        LibrarySales: Codeunit "Library - Sales";
        FolderName: Text;
    begin
        // Verify the number of exported Tables in Log file.
        CreateRecDefinition(DataExportRecord);

        LibrarySales.CreateCustomer(Customer);

        AddRecordSourceWithFilters(
          DataExportRecord, CustomerTableNo(),
          Customer.TableName + ':' + Customer.FieldName("No.") + '=' + Customer."No.", DataExportRecordSource);

        LibraryPurchase.CreateVendor(Vendor);
        AddRecordSourceWithFilters(
          DataExportRecord, VendorTableNo(),
          Vendor.TableName + ':' + Vendor.FieldName("No.") + '=' + Vendor."No.", DataExportRecordSource);

        FolderName := ExportBusinessData(DataExportRecord);

        ValidateTablesNumberInLog(FolderName, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestsExportLogIfNothingToExport()
    var
        DataExportRecord: Record "Data Export Record Definition";
        FolderName: Text;
    begin
        // Verify that the Log file exported to the write Folder when there is no Data to export.
        PrepareEmptyBusinessDataToExport(DataExportRecord);

        FolderName := ExportBusinessData(DataExportRecord);

        VerifyFileExists(FolderName, LogFileTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotModifyTableNo()
    var
        DataExportRecordSource: Record "Data Export Record Source";
        DataExportRecord: Record "Data Export Record Definition";
    begin
        // [FEATURE] Digital Audit
        // [SCENARIO 079] User cannot modify 'Table No.'
        CreateRecDefinition(DataExportRecord);

        // [GIVEN] There is one data export source line for table X.
        AddRecordSourceWithFields(DataExportRecord, CustLedgEntryTableNo(), DataExportRecordSource);

        // [WHEN] User modifies 'Table No.' to Y
        asserterror DataExportRecordSource.Validate("Table No.", VendLedgEntryTableNo());
        // [THEN] Error message: 'You cannot modify Table No.'
        Assert.ExpectedError(CannotModifyTableNoErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNoFieldsInRecordSource()
    var
        DataExportRecord: Record "Data Export Record Definition";
        DataExportRecordSource: Record "Data Export Record Source";
    begin
        // Verify validation error if no fields are defined for a Record Source.
        CreateRecDefinition(DataExportRecord);
        AddRecordSource(DataExportRecord, CustomerTableNo(), DataExportRecordSource);

        asserterror ExportBusinessData(DataExportRecord);
        Assert.ExpectedError(StrSubstNo(NoFieldsDefinedErr, DataExportRecord."Data Export Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRecFieldsDeletion()
    var
        DataExportRecord: Record "Data Export Record Definition";
        DataExportRecordSource: Record "Data Export Record Source";
    begin
        // Test table setup deletion: verify that all related Fields are deleted as well.
        CreateRecDefinition(DataExportRecord);
        AddRecordSource(DataExportRecord, CustomerTableNo(), DataExportRecordSource);

        DeleteRecordSource(DataExportRecordSource);
        VerifyRecFieldsDeleted(DataExportRecord, CustomerTableNo());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRelatedTableDeletion()
    var
        DataExportRecord: Record "Data Export Record Definition";
        DataExportRecordSource: Record "Data Export Record Source";
        ParentDataExportRecordSource: Record "Data Export Record Source";
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Test table setup deletion: verify that all related Tables are deleted as well.
        CreateRecDefinition(DataExportRecord);
        AddRecordSource(DataExportRecord, CustomerTableNo(), DataExportRecordSource);
        ParentDataExportRecordSource := DataExportRecordSource;

        AddRecordSource(DataExportRecord, CustLedgEntryTableNo(), DataExportRecordSource);
        Indent(DataExportRecordSource, ParentDataExportRecordSource);
        MakeRelation(
          DataExportRecordSource, CustLedgerEntry.FieldNo("Customer No."),
          ParentDataExportRecordSource, Customer.FieldNo("No."));

        DeleteRecordSource(ParentDataExportRecordSource);
        VerifyRelatedTablesDeleted(DataExportRecord, ParentDataExportRecordSource."Table No.", ParentDataExportRecordSource."Line No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFlowFieldsCalcAccordingAppliedFilters()
    var
        DataExportRecord: Record "Data Export Record Definition";
        DataExportRecordSource: Record "Data Export Record Source";
        Customer: Record Customer;
        TableFilterText: Text;
        FolderName: Text;
    begin
        // Verify that flow fields are calculated according to applied filters while exporting Data.
        CreateRecDefinition(DataExportRecord);
        AddRecordSourceWithFields(DataExportRecord, CustomerTableNo(), DataExportRecordSource);

        Customer.SetFilter("Date Filter", FindAccountingPeriodRange());

        TableFilterText :=
          Customer.TableName + ': ' + Customer.FieldName("Net Change") + '=<>0,' +
          Customer.FieldName("Global Dimension 1 Filter") + '=' + Format(CreateCustWithGlobalDimCode());
        SetTableFilter(DataExportRecord, CustomerTableNo(), TableFilterText);

        FolderName :=
          ExportBusinessDataSetPeriod(DataExportRecord, Customer.GetRangeMin("Date Filter"), Customer.GetRangeMax("Date Filter"));

        VerifyCustNetChangeExport(FolderName, DataExportRecordSource."Export File Name", Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestExportTwoEqualFlowFields()
    var
        DataExportRecord: Record "Data Export Record Definition";
        DataExportRecordSource: Record "Data Export Record Source";
        Customer: Record Customer;
        TableFilterText: Text;
        FolderName: Text;
    begin
        // TFS338833: Verify that Business Data exported correctly when having two equal Flow Fields.
        CreateRecDefinition(DataExportRecord);
        AddCustRecordSourceWithSameFields(DataExportRecord, DataExportRecordSource);

        TableFilterText := StrSubstNo('%1: %2=<>0', Customer.TableName, Customer.FieldName("Net Change"));
        SetTableFilter(DataExportRecord, CustomerTableNo(), TableFilterText);

        FolderName := ExportBusinessDataSetPeriod(DataExportRecord, CalcDate('<-6M>', WorkDate()), WorkDate());

        VerifyCustNetChangeTwoValuesExport(
          FolderName, DataExportRecordSource."Export File Name",
          CalcDate('<-6M>', WorkDate()), WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDateFilterFieldNoIsFilled()
    var
        DataExportRecordSource: Record "Data Export Record Source";
        DataExportRecord: Record "Data Export Record Definition";
        Customer: Record Customer;
    begin
        // Verify that Table No. validation fills the date filter field no.
        CreateRecDefinition(DataExportRecord);
        AddRecordSource(DataExportRecord, CustomerTableNo(), DataExportRecordSource);

        // Exercise: Validate table no.
        DataExportRecordSource.Validate("Table No.");

        // Verify: Date Filter Field No. is set correctly
        Assert.AreEqual(
          Customer.FieldNo("Date Filter"), DataExportRecordSource."Date Filter Field No.",
          StrSubstNo(WrongDateFilterFieldNoErr, Customer.TableName));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestExportWithDateFilterFieldNo()
    var
        DataExportRecordSource: Record "Data Export Record Source";
        DataExportRecord: Record "Data Export Record Definition";
        Customer: Record Customer;
        DateFilterHandling: Option " ",Period,"End Date Only","Start Date Only";
        FolderName: Text;
    begin
        // Verify that business data is exported correctly with Date Filter Fileld No.
        InitializeFlowFieldScenario(DataExportRecord, DataExportRecordSource, Customer, DateFilterHandling::Period);

        // Validating table no. to fill the date filter field
        DataExportRecordSource.Validate("Table No.");
        DataExportRecordSource.Modify(true);

        SetTableFilter(DataExportRecord, CustomerTableNo(), FormatCustTableFilter(Customer.GetFilter("No.")));

        // Exercise: Export record with the date filter field no.
        FolderName := ExportBusinessDataSetPeriod(DataExportRecord, CalcDate('<-1M>', WorkDate()), WorkDate());

        // Verify: Customers have been exported, Date Filter Field No. does not affect data filtering
        VerifyBusinessDataExport(FolderName, DataExportRecordSource."Export File Name", Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestExportLongRecord()
    var
        CompanyInformation: Record "Company Information";
        DataExportRecord: Record "Data Export Record Definition";
        DataExportRecordSource: Record "Data Export Record Source";
        FolderName: Text;
    begin
        // Verify that exported data length is greater than 1024 bytes.

        // Setup: Add the records in record definition.
        CompanyInformation.Get();
        CreateRecDefinition(DataExportRecord);
        AddRecordSourceWithFilters(
          DataExportRecord, CompanyInfoTableNo(),
          CompanyInformation.TableName + ':' + CompanyInformation.FieldName("Primary Key") + '=' + CompanyInformation."Primary Key",
          DataExportRecordSource);

        // Excercise: Exported data length is greater than 1024 bytes.
        FolderName := ExportBusinessData(DataExportRecord);

        // Verify: Verify that exported data length is greater than 1024 bytes.
        ValidateExportedDataFile(FolderName, DataExportRecordSource."Export File Name");

        // Tear Down: Roll back to original Values.
        RollBackCompanyInformation(CompanyInformation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestExportSameTable2FilesCreated()
    var
        DataExportRecordSource: Record "Data Export Record Source";
        DataExportRecord: Record "Data Export Record Definition";
        ExpectedFileNames: array[5] of Text;
        FolderName: Text;
    begin
        // [FEATURE] Digital Audit
        // [SCENARIO 070] 349029 - Setup allows setting one table multiple times.
        CreateRecDefinition(DataExportRecord);

        // [GIVEN] There is one data export source line for table x. Export file name is A.
        AddRecordSourceWithFields(DataExportRecord, CustLedgEntryTableNo(), DataExportRecordSource);
        ExpectedFileNames[1] := DataExportRecordSource."Export File Name";
        // [GIVEN] There is another data export source line for table x. Export file name is B.
        AddRecordSourceWithFields(DataExportRecord, CustLedgEntryTableNo(), DataExportRecordSource);
        ExpectedFileNames[2] := DataExportRecordSource."Export File Name";

        ExpectedFileNames[3] := LogFileTxt;
        ExpectedFileNames[4] := IndexFileTxt;
        ExpectedFileNames[5] := DefaultDTDFileTxt;

        // [WHEN] Files are exported.
        FolderName := ExportBusinessData(DataExportRecord);

        // [THEN] There are 2 files in the exported folder.
        VerifyFileNames(FolderName, ExpectedFileNames);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestExportSameTableOnInsFileNameUnique()
    var
        DataExportRecordSource: Record "Data Export Record Source";
        DataExportRecord: Record "Data Export Record Definition";
        FileName: array[2] of Text;
        TableName: array[2] of Text;
    begin
        // [FEATURE] Digital Audit
        // [SCENARIO 072] Unique 'Export Table Name' and 'Export File Name' are generated on insert of duplicate export source.
        CreateRecDefinition(DataExportRecord);

        // [GIVEN] There is one data export source line with export file name: xyz.txt
        AddRecordSourceWithFields(DataExportRecord, CustLedgEntryTableNo(), DataExportRecordSource);
        FileName[1] := DataExportRecordSource."Export File Name";
        TableName[1] := DataExportRecordSource."Export Table Name";

        // [WHEN] Creating and inserting another data export line for the same Table No.
        AddRecordSourceWithFields(DataExportRecord, CustLedgEntryTableNo(), DataExportRecordSource);
        FileName[2] := DataExportRecordSource."Export File Name";
        TableName[2] := DataExportRecordSource."Export Table Name";

        // [THEN] Generated a new table name - xyz 1
        Assert.AreEqual(TableName[1] + ' 1', TableName[2], DataExportRecordSource.FieldName("Export Table Name"));
        // [THEN] Generated a new file name - xyz1.txt
        Assert.AreEqual(
          InsStr(FileName[1], '1', StrPos(FileName[1], '.')), FileName[2], DataExportRecordSource.FieldName("Export File Name"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestExportSameTableOnModFileNameUnique()
    var
        DataExportRecordSource: Record "Data Export Record Source";
        DataExportRecord: Record "Data Export Record Definition";
        FileName: array[2] of Text;
        TableName: array[2] of Text;
    begin
        // [FEATURE] Digital Audit
        // [SCENARIO 073] Unique 'Export Table Name' and 'Export File Name' are generated on modification of duplicate export source.
        CreateRecDefinition(DataExportRecord);

        // [GIVEN] There is one data export source line with export file name: xyz.txt
        AddRecordSourceWithFields(DataExportRecord, CustLedgEntryTableNo(), DataExportRecordSource);
        FileName[1] := DataExportRecordSource."Export File Name";
        TableName[1] := DataExportRecordSource."Export Table Name";

        // [GIVEN] There is another data export source line with export file name: xyz1.txt
        AddRecordSourceWithFields(DataExportRecord, CustLedgEntryTableNo(), DataExportRecordSource);
        // [GIVEN] 'Export Table Name' is modified to duplicate 'xyz'
        DataExportRecordSource.Validate("Export Table Name", TableName[1]);
        DataExportRecordSource.Modify();

        // [WHEN] Modifying 'Export File Name' to existing xyz.txt
        DataExportRecordSource.Validate("Export File Name", FileName[1]);
        FileName[2] := DataExportRecordSource."Export File Name";
        TableName[2] := DataExportRecordSource."Export Table Name";

        // [THEN] Generated a new table name - xyz 1
        Assert.AreEqual(TableName[1] + ' 1', TableName[2], DataExportRecordSource.FieldName("Export Table Name"));
        // [THEN] Generated a new file name - xyz1.txt
        Assert.AreEqual(
          InsStr(FileName[1], '1', StrPos(FileName[1], '.')), FileName[2], DataExportRecordSource.FieldName("Export File Name"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestExportSameTable2FilesCreatedWithDiffData()
    var
        DataExportRecordSource: Record "Data Export Record Source";
        DataExportRecord: Record "Data Export Record Definition";
        CompanyInfo: Record "Company Information";
        ExportFileName1: Text;
        ExportFileName2: Text;
        FolderName: Text;
    begin
        // [FEATURE] Digital Audit
        // [SCENARIO 071] Export the same table twice different fields are exported.
        CompanyInfo.Get();
        CreateRecDefinition(DataExportRecord);

        // [GIVEN] There is one data export source line for table x with exported field y. Export file name is A.
        AddRecordSource(DataExportRecord, CompanyInfoTableNo(), DataExportRecordSource);
        LinkFieldToSourceRecord(DataExportRecordSource, CompanyInfo.FieldNo(Name));
        ExportFileName1 := DataExportRecordSource."Export File Name";

        // [GIVEN] There is another data export source line for table x with exported field z. Export file name is B.
        AddRecordSource(DataExportRecord, CompanyInfoTableNo(), DataExportRecordSource);
        LinkFieldToSourceRecord(DataExportRecordSource, CompanyInfo.FieldNo(Address));
        ExportFileName2 := DataExportRecordSource."Export File Name";

        // [WHEN] File is exported.
        FolderName := ExportBusinessData(DataExportRecord);

        // [THEN] There are 2 files in the export folder: file A contains field y from table x, file B contains field z from table x.
        ValidateExportedDataFromFileFile(FolderName, ExportFileName1, CompanyInfo.Name);
        ValidateExportedDataFromFileFile(FolderName, ExportFileName2, CompanyInfo.Address);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ParentChildTwiceWithoutFilters()
    var
        DataExportRecord: Record "Data Export Record Definition";
        ExportFileName: array[2, 5] of Text;
        FolderName: Text;
    begin
        // [FEATURE] Digital Audit
        // [SCENARIO 074] Same tables Parent-Child used twice in setup
        // [GIVEN] Same pair of Parent-Child tables are set twice with empty table filters
        SetupTwoPairsOfParentChild(DataExportRecord, ExportFileName);

        // [WHEN] Export data
        FolderName := ExportBusinessData(DataExportRecord);

        // [THEN] Two pairs of identical files (named differently) are exported
        VerifyCountOfExportedRecords(FolderName, ExportFileName[1, 1], 1);
        VerifyCountOfExportedRecords(FolderName, ExportFileName[2, 1], 1);
        VerifyCountOfExportedRecords(FolderName, ExportFileName[1, 2], 3);
        VerifyCountOfExportedRecords(FolderName, ExportFileName[2, 2], 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteParentWhenDuplicateParentExists()
    var
        DataExportRecord: Record "Data Export Record Definition";
        DataExportRecordSource: Record "Data Export Record Source";
        ExportFileName: array[2, 5] of Text;
    begin
        // [FEATURE] Digital Audit
        // [SCENARIO 075] Deletion of a Parent does not affect a duplicate Parent

        // [GIVEN] Two pairs of Parent-Child are in Setup
        SetupTwoPairsOfParentChild(DataExportRecord, ExportFileName);

        // [WHEN] Parent 1 is deleted
        DataExportRecordSource.SetRange("Data Export Code", DataExportRecord."Data Export Code");
        DataExportRecordSource.SetRange("Data Exp. Rec. Type Code", DataExportRecord."Data Exp. Rec. Type Code");
        DataExportRecordSource.FindFirst();
        DataExportRecordSource.Delete(true);

        // [THEN] Pair of Parent 2-Chield 2 (with Relation 2) is still in Setup
        Assert.AreEqual(2, DataExportRecordSource.Count, StrSubstNo(WrongNoOfLinesErr, DataExportRecordSource.TableName));
        DataExportRecordSource.FindFirst();
        Assert.AreEqual(
          DATABASE::"CV Ledger Entry Buffer", DataExportRecordSource."Table No.", DataExportRecordSource.FieldName("Table No."));
        Assert.AreEqual(
          ExportFileName[2, 1], DataExportRecordSource."Export File Name", DataExportRecordSource.FieldName("Export File Name"));
        DataExportRecordSource.FindLast();
        Assert.AreEqual(
          DATABASE::"Detailed CV Ledg. Entry Buffer", DataExportRecordSource."Table No.", DataExportRecordSource.FieldName("Table No."));
        Assert.AreEqual(
          ExportFileName[2, 2], DataExportRecordSource."Export File Name", DataExportRecordSource.FieldName("Export File Name"));
        DataExportRecordSource.CalcFields("Table Relation Defined");
        Assert.IsTrue(DataExportRecordSource."Table Relation Defined", DataExportRecordSource.FieldName("Table Relation Defined"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteChildWhenDuplicateChildExists()
    var
        DataExportRecord: Record "Data Export Record Definition";
        DataExportRecordSource: Record "Data Export Record Source";
        DataExportTableRelation: Record "Data Export Table Relation";
        ExportFileName: array[2, 5] of Text;
    begin
        // [FEATURE] Digital Audit
        // [SCENARIO 076] Deletion of a Child does not affect a duplicate Child

        // [GIVEN] Two pairs of Parent-Child are in Setup
        SetupTwoPairsOfParentChild(DataExportRecord, ExportFileName);

        // [WHEN] Delete Child 1
        DataExportRecordSource.SetRange("Data Export Code", DataExportRecord."Data Export Code");
        DataExportRecordSource.SetRange("Data Exp. Rec. Type Code", DataExportRecord."Data Exp. Rec. Type Code");
        DataExportRecordSource.SetRange(Indentation, 1);
        DataExportRecordSource.FindFirst();
        DataExportRecordSource.Delete(true);

        // [THEN] Relation 1 is also deleted
        DataExportTableRelation.SetRange("Data Export Code", DataExportRecord."Data Export Code");
        DataExportTableRelation.SetRange("Data Exp. Rec. Type Code", DataExportRecord."Data Exp. Rec. Type Code");
        Assert.AreEqual(1, DataExportTableRelation.Count, StrSubstNo(WrongNoOfLinesErr, DataExportTableRelation.TableName));
        // [THEN] Relation 2 does still exist
        DataExportRecordSource.FindFirst();
        DataExportRecordSource.CalcFields("Table Relation Defined");
        Assert.IsTrue(DataExportRecordSource."Table Relation Defined", DataExportRecordSource.FieldName("Table Relation Defined"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIndentationSingleRecord()
    var
        DataExportRecordSource: Record "Data Export Record Source";
        DataExportRecordDefinition: Record "Data Export Record Definition";
    begin
        // [FEATURE] Digital Audit
        // [SCENARIO 100] Indentation - Cannot indent a single parent.
        DataExportRecordSource.DeleteAll(true);
        CreateRecDefinition(DataExportRecordDefinition);

        // [GIVEN] There is one Data Export Record Source X available.
        AddRecordSource(DataExportRecordDefinition, GLAccTableNo(), DataExportRecordSource);

        // [WHEN] Indent on X record.
        DataExportRecordSource.Validate(Indentation, 1);

        // [THEN] Indentation will not take place X.Indentation is 0.
        Assert.AreEqual(0, DataExportRecordSource.Indentation, WrongIndentErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIndentationLevel2Record()
    var
        DataExportRecordSource: Record "Data Export Record Source";
        DataExportRecordDefinition: Record "Data Export Record Definition";
        TableNoArr: array[10] of Integer;
        NoOfRecords: Integer;
    begin
        // [FEATURE] Digital Audit
        // [SCENARIO 101] Indentation - Able to indent records under a parent.
        DataExportRecordSource.DeleteAll(true);
        CreateRecDefinition(DataExportRecordDefinition);
        TableNoArr[1] := GLAccTableNo();
        TableNoArr[2] := GLEntryTableNo();
        NoOfRecords := 2;

        // [GIVEN] There is Data Export Record Source X and Data Export Record Source Y.
        AddSeveralRecordSourceAndIndent(DataExportRecordSource, DataExportRecordDefinition, TableNoArr, NoOfRecords, true);

        // [WHEN] Indenting record Y.
        DataExportRecordSource.Validate(Indentation, NoOfRecords - 1);

        // [THEN] Record Y is indented, Y.Indentation is 1.
        Assert.AreEqual(NoOfRecords - 1, DataExportRecordSource.Indentation, WrongIndentErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIndentationLevel3Record()
    var
        DataExportRecordSource: Record "Data Export Record Source";
        DataExportRecordDefinition: Record "Data Export Record Definition";
        TableNoArr: array[10] of Integer;
        NoOfRecords: Integer;
    begin
        // [FEATURE] Digital Audit
        // [SCENARIO 102] Indentation - Indentation level 3, indented with level 2.
        DataExportRecordSource.DeleteAll(true);
        CreateRecDefinition(DataExportRecordDefinition);
        TableNoArr[1] := GLAccTableNo();
        TableNoArr[2] := GLEntryTableNo();
        TableNoArr[3] := VATEntryTableNo();
        NoOfRecords := 3;

        // [GIVEN] There is un-indented Data Export Record Source X and an un-indented Data Export Record Source Y.
        AddSeveralRecordSourceAndIndent(DataExportRecordSource, DataExportRecordDefinition, TableNoArr, NoOfRecords, false);
        // [GIVEN] There Data Export Record Source Z which is indented to record Y
        DataExportRecordSource.Validate(Indentation, 1);

        // [WHEN] Indenting record Y.
        DataExportRecordSource.Reset();
        DataExportRecordSource.FindSet();
        DataExportRecordSource.Next();
        DataExportRecordSource.Validate(Indentation, 1);

        // [THEN] Record Y and record Z are both indented. Y.Indentation is 1, Z.Indentation is 2.
        DataExportRecordSource.SetRange("Table No.", VATEntryTableNo());
        DataExportRecordSource.FindFirst();
        Assert.AreEqual(NoOfRecords - 1, DataExportRecordSource.Indentation, WrongIndentErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUnIndentationLevel2Record()
    var
        DataExportRecordSource: Record "Data Export Record Source";
        DataExportRecordDefinition: Record "Data Export Record Definition";
        TableNoArr: array[10] of Integer;
        NoOfRecords: Integer;
    begin
        // [FEATURE] Digital Audit
        // [SCENARIO 103] Indentation - Unindent record level 2.
        DataExportRecordSource.DeleteAll(true);
        CreateRecDefinition(DataExportRecordDefinition);
        TableNoArr[1] := GLAccTableNo();
        TableNoArr[2] := GLEntryTableNo();
        NoOfRecords := 2;

        // [GIVEN] There is un-indented Data Export Record Source X and there is indented Data Export Record Source Y.
        AddSeveralRecordSourceAndIndent(DataExportRecordSource, DataExportRecordDefinition, TableNoArr, NoOfRecords, true);
        DataExportRecordSource.Validate(Indentation, NoOfRecords - 1);

        // [WHEN] Un-indenting record Y.
        DataExportRecordSource.Validate(Indentation, DataExportRecordSource.Indentation - 1);

        // [THEN] Record Y is un-indented, Y.Indentation is 0.
        Assert.AreEqual(0, DataExportRecordSource.Indentation, WrongIndentErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUnIndentationLevel3Record()
    var
        DataExportRecordSource: Record "Data Export Record Source";
        DataExportRecordDefinition: Record "Data Export Record Definition";
        TableNoArr: array[10] of Integer;
        NoOfRecords: Integer;
    begin
        // [FEATURE] Digital Audit
        // [SCENARIO 104] Indentation - Unindent Record level 2 which has an indented level 3 record.
        DataExportRecordSource.DeleteAll(true);
        CreateRecDefinition(DataExportRecordDefinition);
        TableNoArr[1] := GLAccTableNo();
        TableNoArr[2] := GLEntryTableNo();
        TableNoArr[3] := VATEntryTableNo();
        NoOfRecords := 3;

        // [GIVEN] There is un-indented Data Export Record Source X. and there is an indented Data Export Record Source Y.
        AddSeveralRecordSourceAndIndent(DataExportRecordSource, DataExportRecordDefinition, TableNoArr, NoOfRecords, true);

        // [GIVEN]  There is an indented to Data Export Record Source Y, record Z.
        DataExportRecordSource.Validate(Indentation, 2);

        // [WHEN] Un-indent record Y.
        DataExportRecordSource.Reset();
        DataExportRecordSource.FindSet();
        DataExportRecordSource.Next();
        DataExportRecordSource.Validate(Indentation, DataExportRecordSource.Indentation - 1);

        // [THEN] Both record Y and Z are un-indented: Y.Indentation is 0, Z.Indentationis 1.
        DataExportRecordSource.SetRange("Table No.", VATEntryTableNo());
        DataExportRecordSource.FindFirst();
        Assert.AreEqual(1, DataExportRecordSource.Indentation, WrongIndentErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmationHandler')]
    [Scope('OnPrem')]
    procedure TestUnIndentationLevel2RecordRelation()
    var
        DataExportRecordSourceChild: Record "Data Export Record Source";
        DataExportRecordSourceParent: Record "Data Export Record Source";
        DataExportRecordDefinition: Record "Data Export Record Definition";
        GLEntry: Record "G/L Entry";
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] Digital Audit
        // [SCENARIO 105] Indentation - Unindent would remove a relation if exists.
        DataExportRecordSourceParent.DeleteAll(true);
        CreateRecDefinition(DataExportRecordDefinition);

        // [GIVEN] There is un-indented Data Export Record Source X.
        AddRecordSource(DataExportRecordDefinition, GLAccTableNo(), DataExportRecordSourceParent);

        // [GIVEN]  There is an indented Data Export Record Source Y with a relation to record X defined.
        DataExportRecordSourceChild."Line No." := DataExportRecordSourceParent."Line No.";
        AddRecordSource(DataExportRecordDefinition, GLEntryTableNo(), DataExportRecordSourceChild);
        DataExportRecordSourceChild.Validate(Indentation, 1);
        MakeRelation(
          DataExportRecordSourceChild, GLEntry.FieldNo("G/L Account No."),
          DataExportRecordSourceParent, GLAccount.FieldNo("No."));

        // [WHEN] Un-indent record Y.
        DataExportRecordSourceChild.Validate(Indentation, DataExportRecordSourceChild.Indentation - 1);

        // [THEN] The relation flag is set to no.
        Assert.AreEqual(false, DataExportRecordSourceParent."Table Relation Defined", WrongIndentErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIndentationLevel1SecondObject()
    var
        DataExportRecordDefinition: Record "Data Export Record Definition";
        FolderName: Text;
    begin
        // [FEATURE] [Digital Audit]

        // [SCENARIO 363468] Export two tables indented on the same level.
        ClearParentChildTables();
        // [GIVEN] Parent Table ("Vendor" - "V")
        // [GIVEN] 2 Child Tables linked to "V" with Indent = 1 ("CV Ledg. Entry Buffer" and "Dtld. CV Ledg. Entry Buffer")
        // [GIVEN] Second child table contains multiple records, where "X" of them for "V"
        PrepareObjectsForExport();
        PrepareDataExportRecordDefinition(DataExportRecordDefinition);

        // [WHEN] Exporting data
        FolderName := ExportBusinessData(DataExportRecordDefinition);

        // [THEN] File with second child object contains "X" records.
        VerifyCountOfExportedRecords(FolderName, 'DetailedCVLedgEntryBuffer.txt', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestExportVendorNameBadSymbol()
    var
        DataExportRecordDefinition: Record "Data Export Record Definition";
        DataExportRecordSource: Record "Data Export Record Source";
        Vendor: Record Vendor;
        ExportFileName: Text;
        GermanicUmlautTxt: Text[50];
        FolderName: Text;
    begin
        // [FEATURE] [Digital Audit]
        // [SCENARIO 376698] Exported table file contains umlauts and '{', '}' chars.
        CreateRecDefinition(DataExportRecordDefinition);
        GermanicUmlautTxt := '{TEST}';

        // [GIVEN] Vendor table exists in Data Source Export, with Name field set to export.
        // [GIVEN] Vendor.Name = "{TEST}"
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Name := GermanicUmlautTxt;
        Vendor.Modify(true);
        AddRecordSourceWithFilters(
          DataExportRecordDefinition, VendorTableNo(),
          Vendor.TableName + ':' + Vendor.FieldName("No.") + '=' + Vendor."No.", DataExportRecordSource);
        ExportFileName := DataExportRecordSource."Export File Name";

        // [WHEN] Export Data.
        FolderName := ExportBusinessData(DataExportRecordDefinition);

        // [THEN] Exported vendor name equals "{TEST}".
        ValidateExportedFieldDataFromFileFile(
          FolderName, ExportFileName, GermanicUmlautTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestExportOptionValue()
    var
        DataExportRecordDefinition: Record "Data Export Record Definition";
        CompanyInformation: Record "Company Information";
        ExportFileName: Text;
        OptionValue: Integer;
        OldCheckAvail: Enum "Analysis Period Type";
        FolderName: Text;
    begin
        // [FEATURE] [Digital Audit]
        // [SCENARIO 379913] Export Business Data report replace options with option captions

        // [GIVEN] Data Export of Company Information table
        ExportFileName := CreateDataExportOfCompanyInformation(DataExportRecordDefinition);

        // [GIVEN] Value "C" assigned to CompanyInformation."Check-Avail. Time Bucket" option where values are: "A,B,C"
        OldCheckAvail := SetCompanyInformationCheckAvailTimeBucketValue(OptionValue, 0);

        // [WHEN] Run Export Business Data report
        FolderName := ExportBusinessData(DataExportRecordDefinition);

        // [THEN] Validate CompanyInformation."Check-Avail. Time Bucket" = "C" in file
        CompanyInformation.Get();
        ValidateOptionValueFromFile(
          FolderName, ExportFileName,
          Format(CompanyInformation."Check-Avail. Time Bucket"));
        CompanyInformation."Check-Avail. Time Bucket" := OldCheckAvail;
        CompanyInformation.Modify();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestExportWrongOptionValue()
    var
        DataExportRecordDefinition: Record "Data Export Record Definition";
        CompanyInformation: Record "Company Information";
        ExportFileName: Text;
        OptionValue: Integer;
        OldCheckAvail: Enum "Analysis Period Type";
        FolderName: Text;
    begin
        // [FEATURE] [Digital Audit]
        // [SCENARIO 379913] Export Business Data report replace wrong options with option index

        // [GIVEN] Data Export of Company Information table
        ExportFileName := CreateDataExportOfCompanyInformation(DataExportRecordDefinition);

        // [GIVEN] CompanyInformation."Check-Avail. Time Bucket" option assigned with value 3 where values are: "A,B,C" (max index = 2)
        OldCheckAvail := SetCompanyInformationCheckAvailTimeBucketValue(OptionValue, 1);

        // [WHEN] Run Export Business Data report
        FolderName := ExportBusinessData(DataExportRecordDefinition);

        // [THEN] Validate CompanyInformation."Check-Avail. Time Bucket" = 3 in file
        CompanyInformation.Get();
        ValidateOptionValueFromFile(
          FolderName, ExportFileName, Format(OptionValue));
        CompanyInformation."Check-Avail. Time Bucket" := OldCheckAvail;
        CompanyInformation.Modify();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DataExportRecordSourceExportTableNameOnValidateUnique()
    var
        DataExportRecordSource: Record "Data Export Record Source";
        DataExportRecordDefinition: Record "Data Export Record Definition";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 313218] Can validate Export Table Name to value that's part of another Record Source's Export Table Name

        // [GIVEN] Data Export Record Definition with Record Source RS1 = "Vendor" and RS2 = "CVLedgerEntryBuffer"
        CreateDataExportRecordSources(DataExportRecordDefinition);

        // [WHEN] Validate RS1."Export Table Name" = 'CVLedger' (substring of RS2)
        DataExportRecordSource.SetRange("Data Export Code", DataExportRecordDefinition."Data Export Code");
        DataExportRecordSource.SetRange("Table No.", DATABASE::Vendor);
        DataExportRecordSource.FindFirst();
        DataExportRecordSource.Validate("Export Table Name", 'CVLedger');

        // [THEN] Validates successfully
        DataExportRecordSource.TestField("Export Table Name", 'CVLedger');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DataExportRecordSourceExportTableNameOnValidateNotUnique()
    var
        DataExportRecordSource: Record "Data Export Record Source";
        DataExportRecordDefinition: Record "Data Export Record Definition";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 313218] Export Table Name modified to be unique, if record with such value exists

        // [GIVEN] Data Export Record Definition with Record Source RS1 = "Vendor" and RS2 = "CV Ledger Entry Buffer"
        CreateDataExportRecordSources(DataExportRecordDefinition);

        // [WHEN] Validate RS1."Export Table Name" = 'CV Ledger Entry Buffer'
        DataExportRecordSource.SetRange("Data Export Code", DataExportRecordDefinition."Data Export Code");
        DataExportRecordSource.SetRange("Table No.", DATABASE::Vendor);
        DataExportRecordSource.FindFirst();
        DataExportRecordSource.Validate("Export Table Name", 'CV Ledger Entry Buffer');

        // [THEN] Validates to 'CV Ledger Entry Buffer 1'
        DataExportRecordSource.TestField("Export Table Name", 'CV Ledger Entry Buffer 1');
        DataExportRecordSource.Modify(true);
        DataExportRecordSource.Reset();
        DataExportRecordSource.SetRange("Data Export Code", DataExportRecordDefinition."Data Export Code");
        DataExportRecordSource.SetRange("Table No.", DATABASE::"Detailed CV Ledg. Entry Buffer");
        DataExportRecordSource.FindFirst();
        DataExportRecordSource.Validate("Export Table Name", 'CV Ledger Entry Buffer');
        DataExportRecordSource.TestField("Export Table Name", 'CV Ledger Entry Buffer 2');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DataExportRecordSourceExportTableNameOnValidateNotUniqueSecond()
    var
        DataExportRecordSource: Record "Data Export Record Source";
        DataExportRecordDefinition: Record "Data Export Record Definition";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 313218] Export Table Name modified to be unique by numeric increment, if record with such value exists

        // [GIVEN] Data Export Record Definition with Record Source RS1 = "Vendor" and RS2 = "CV Ledger Entry Buffer", RS3 = 'Detailed CV Ledg Entry Buffer'
        CreateDataExportRecordSources(DataExportRecordDefinition);

        // [GIVEN] RS1."Export Table Name" = 'CV Ledger Entry Buffer 1'
        DataExportRecordSource.SetRange("Data Export Code", DataExportRecordDefinition."Data Export Code");
        DataExportRecordSource.SetRange("Table No.", DATABASE::Vendor);
        DataExportRecordSource.FindFirst();
        DataExportRecordSource.Validate("Export Table Name", 'CV Ledger Entry Buffer');
        DataExportRecordSource.Modify(true);

        // [WHEN] Validate RS3."Export Table Name" = 'CV Ledger Entry Buffer'
        DataExportRecordSource.Reset();
        DataExportRecordSource.SetRange("Data Export Code", DataExportRecordDefinition."Data Export Code");
        DataExportRecordSource.SetRange("Table No.", DATABASE::"Detailed CV Ledg. Entry Buffer");
        DataExportRecordSource.FindFirst();
        DataExportRecordSource.Validate("Export Table Name", 'CV Ledger Entry Buffer');

        // [THEN] Validates to 'CV Ledger Entry Buffer 2'
        DataExportRecordSource.TestField("Export Table Name", 'CV Ledger Entry Buffer 2');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DataExportRecordSourceExportFileNameOnValidateUnique()
    var
        DataExportRecordSource: Record "Data Export Record Source";
        DataExportRecordDefinition: Record "Data Export Record Definition";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 313218] Can validate Export File Name to value that's part of another Record Source's Export File Name

        // [GIVEN] Data Export Record Definition with Record Source RS1 = "Vendor" and RS2 = "CVLedgerEntryBuffer"
        CreateDataExportRecordSources(DataExportRecordDefinition);

        // [WHEN] Validate RS1."Export File Name" = 'CVLedger.txt' (substring of RS2)
        DataExportRecordSource.SetRange("Data Export Code", DataExportRecordDefinition."Data Export Code");
        DataExportRecordSource.SetRange("Table No.", DATABASE::Vendor);
        DataExportRecordSource.FindFirst();
        DataExportRecordSource.Validate("Export File Name", 'CVLedger.txt');

        // [THEN] Validates successfully
        DataExportRecordSource.TestField("Export File Name", 'CVLedger.txt');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DataExportRecordSourceExportFileNameOnValidateNotUnique()
    var
        DataExportRecordSource: Record "Data Export Record Source";
        DataExportRecordDefinition: Record "Data Export Record Definition";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 313218] Export File Name modified to be unique if record with such value exists

        // [GIVEN] Data Export Record Definition with Record Source RS1 = "Vendor" and RS2 = "CVLedgerEntryBuffer"
        CreateDataExportRecordSources(DataExportRecordDefinition);

        // [WHEN] Validate RS1."Export File Name" = 'CVLedgerEntryBuffer.txt' (same as RS2)
        DataExportRecordSource.SetRange("Data Export Code", DataExportRecordDefinition."Data Export Code");
        DataExportRecordSource.SetRange("Table No.", DATABASE::Vendor);
        DataExportRecordSource.FindFirst();
        DataExportRecordSource.Validate("Export File Name", 'CVLedgerEntryBuffer.txt');

        // [THEN] Validates to 'CVLedgerEntryBuffer1.txt'
        DataExportRecordSource.TestField("Export File Name", 'CVLedgerEntryBuffer1.txt');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DataExportRecordSourceExportFileNameOnValidateNotUniqueSecond()
    var
        DataExportRecordSource: Record "Data Export Record Source";
        DataExportRecordDefinition: Record "Data Export Record Definition";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 313218] Export File Name modified to be unique by increment if record with such value exists

        // [GIVEN] Data Export Record Definition with Record Source RS1 = "Vendor" and RS2 = "CVLedgerEntryBuffer"
        CreateDataExportRecordSources(DataExportRecordDefinition);

        // [Given] RS1."Export File Name" = 'CVLedgerEntryBuffer1.txt'
        DataExportRecordSource.SetRange("Data Export Code", DataExportRecordDefinition."Data Export Code");
        DataExportRecordSource.SetRange("Table No.", DATABASE::Vendor);
        DataExportRecordSource.FindFirst();
        DataExportRecordSource.Validate("Export File Name", 'CVLedgerEntryBuffer.txt');
        DataExportRecordSource.Modify(true);

        // [WHEN] Validate RS3."Export File Name" = 'CVLedgerEntryBuffer.txt'
        DataExportRecordSource.Reset();
        DataExportRecordSource.SetRange("Data Export Code", DataExportRecordDefinition."Data Export Code");
        DataExportRecordSource.SetRange("Table No.", DATABASE::"Detailed CV Ledg. Entry Buffer");
        DataExportRecordSource.FindFirst();
        DataExportRecordSource.Validate("Export File Name", 'CVLedgerEntryBuffer.txt');

        // [THEN] Validates to 'CVLedgerEntryBuffer2.txt'
        DataExportRecordSource.TestField("Export File Name", 'CVLedgerEntryBuffer2.txt');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportBusinessDataInsertsANSITagIntoIndexXml()
    var
        DataExportRecordDefinition: Record "Data Export Record Definition";
        ExpectedFileNames: array[5] of Text;
        FolderName: Text;
    begin
        // [FEATURE] [Digital Audit]
        // [SCENARIO 328510] Report "Export Business Data" is run for Data Export Record Definition with File Encoding "ANSI".

        // [GIVEN] Data Export Record Definiton with two tables and File Encoding set to "ANSI".
        SetupParentChildTablesForExport(DataExportRecordDefinition, ExpectedFileNames);
        DataExportRecordDefinition."File Encoding" := DataExportRecordDefinition."File Encoding"::ANSI;
        DataExportRecordDefinition.Modify();

        // [WHEN] Data exported using report 11015 "Export Business Data".
        FolderName := ExportBusinessData(DataExportRecordDefinition);

        // [THEN] "ANSI" tag is inserted for each table.
        VerifyElementCountInIndexXML(FolderName, Format(DataExportRecordDefinition."File Encoding"), 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportBusinessDataInsertsMacintoshTagIntoIndexXml()
    var
        DataExportRecordDefinition: Record "Data Export Record Definition";
        ExpectedFileNames: array[5] of Text;
        FolderName: Text;
    begin
        // [FEATURE] [Digital Audit]
        // [SCENARIO 328510] Report "Export Business Data" is run for Data Export Record Definition with File Encoding "Macintosh".

        // [GIVEN] Data Export Record Definiton with two tables and File Encoding set to "Macintosh".
        SetupParentChildTablesForExport(DataExportRecordDefinition, ExpectedFileNames);
        DataExportRecordDefinition."File Encoding" := DataExportRecordDefinition."File Encoding"::Macintosh;
        DataExportRecordDefinition.Modify();

        // [WHEN] Data exported using report 11015 "Export Business Data".
        FolderName := ExportBusinessData(DataExportRecordDefinition);

        // [THEN] "ANSI" tag is inserted for each table.
        VerifyElementCountInIndexXML(FolderName, Format(DataExportRecordDefinition."File Encoding"), 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportBusinessDataInsertsOEMTagIntoIndexXml()
    var
        DataExportRecordDefinition: Record "Data Export Record Definition";
        ExpectedFileNames: array[5] of Text;
        FolderName: Text;
    begin
        // [FEATURE] [Digital Audit]
        // [SCENARIO 328510] Report "Export Business Data" is run for Data Export Record Definition with File Encoding "OEM".

        // [GIVEN] Data Export Record Definiton with two tables and File Encoding set to "OEM".
        SetupParentChildTablesForExport(DataExportRecordDefinition, ExpectedFileNames);
        DataExportRecordDefinition."File Encoding" := DataExportRecordDefinition."File Encoding"::OEM;
        DataExportRecordDefinition.Modify();

        // [WHEN] Data exported using report 11015 "Export Business Data".
        FolderName := ExportBusinessData(DataExportRecordDefinition);

        // [THEN] "ANSI" tag is inserted for each table.
        VerifyElementCountInIndexXML(FolderName, Format(DataExportRecordDefinition."File Encoding"), 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportBusinessDataInsertsUTF7TagIntoIndexXml()
    var
        DataExportRecordDefinition: Record "Data Export Record Definition";
        ExpectedFileNames: array[5] of Text;
        FolderName: Text;
    begin
        // [FEATURE] [Digital Audit]
        // [SCENARIO 328510] Report "Export Business Data" is run for Data Export Record Definition with File Encoding "UTF7".

        // [GIVEN] Data Export Record Definiton with two tables and File Encoding set to "UTF7".
        SetupParentChildTablesForExport(DataExportRecordDefinition, ExpectedFileNames);
        DataExportRecordDefinition."File Encoding" := DataExportRecordDefinition."File Encoding"::UTF7;
        DataExportRecordDefinition.Modify();

        // [WHEN] Data exported using report 11015 "Export Business Data".
        FolderName := ExportBusinessData(DataExportRecordDefinition);

        // [THEN] "ANSI" tag is inserted for each table.
        VerifyElementCountInIndexXML(FolderName, Format(DataExportRecordDefinition."File Encoding"), 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportBusinessDataInsertsUTF8TagIntoIndexXml()
    var
        DataExportRecordDefinition: Record "Data Export Record Definition";
        ExpectedFileNames: array[5] of Text;
        FolderName: Text;
    begin
        // [FEATURE] [Digital Audit]
        // [SCENARIO 328510] Report "Export Business Data" is run for Data Export Record Definition with File Encoding "UTF8".

        // [GIVEN] Data Export Record Definiton with two tables and File Encoding set to "UTF8".
        SetupParentChildTablesForExport(DataExportRecordDefinition, ExpectedFileNames);
        DataExportRecordDefinition."File Encoding" := DataExportRecordDefinition."File Encoding"::UTF8;
        DataExportRecordDefinition.Modify();

        // [WHEN] Data exported using report 11015 "Export Business Data".
        FolderName := ExportBusinessData(DataExportRecordDefinition);

        // [THEN] "ANSI" tag is inserted for each table.
        VerifyElementCountInIndexXML(FolderName, Format(DataExportRecordDefinition."File Encoding"), 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportBusinessDataInsertsUTF16TagIntoIndexXml()
    var
        DataExportRecordDefinition: Record "Data Export Record Definition";
        ExpectedFileNames: array[5] of Text;
        FolderName: Text;
    begin
        // [FEATURE] [Digital Audit]
        // [SCENARIO 328510] Report "Export Business Data" is run for Data Export Record Definition with File Encoding "UTF16".

        // [GIVEN] Data Export Record Definiton with two tables and File Encoding set to "UTF16".
        SetupParentChildTablesForExport(DataExportRecordDefinition, ExpectedFileNames);
        DataExportRecordDefinition."File Encoding" := DataExportRecordDefinition."File Encoding"::UTF16;
        DataExportRecordDefinition.Modify();

        // [WHEN] Data exported using report 11015 "Export Business Data".
        FolderName := ExportBusinessData(DataExportRecordDefinition);

        // [THEN] "ANSI" tag is inserted for each table.
        VerifyElementCountInIndexXML(FolderName, Format(DataExportRecordDefinition."File Encoding"), 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportBusinessDataSameTableWithSameFieldsIndexXml()
    var
        DataExportRecordDefinition: Record "Data Export Record Definition";
        DataExportRecordSource: Record "Data Export Record Source";
        FolderName: Text;
    begin
        // [FEATURE] [Digital Audit]
        // [SCENARIO 341876] Exporting same table with the same fields doesn't lead to duplication of the said fields in index.xml.

        // [GIVEN] Data Export Record Definiton with Customer Table added twice with one primary field and two non-primary.
        CreateRecDefinition(DataExportRecordDefinition);
        AddCustRecordSourceWithSameFields(DataExportRecordDefinition, DataExportRecordSource);
        AddCustRecordSourceWithSameFields(DataExportRecordDefinition, DataExportRecordSource);

        // [WHEN] Data exported using report 11015 "Export Business Data".
        FolderName := ExportBusinessData(DataExportRecordDefinition);

        // [THEN] index.xml has exactly 2 'VariablePrimaryKey' tags and 4 'VariableColumn' tags.
        VerifyElementCountInIndexXML(FolderName, 'VariablePrimaryKey', 2);
        VerifyElementCountInIndexXML(FolderName, 'VariableColumn', 4);
    end;

    [Test]
    procedure RunExportBusinessDataOnGLAcc2022()
    var
        DataExportRecDef: Record "Data Export Record Definition";
        DataExportSetup: Record "Data Export Setup";
        LibraryFileMgtHandler: Codeunit "Library - File Mgt Handler";
        TempBlob: Codeunit "Temp Blob";
        DataExports: TestPage "Data Exports";
        FilesNames: List of [Text];
    begin
        // [SCENARIO 418608] Data is exported with Data Export "GLAcc 2022".

        // [GIVEN] Data Export with code "GLAcc 2022".
        // [GIVEN] Data Export Record Definition with Data Export Code and Data Export Rec Type Code "GLAcc 2022".
        DataExports.OpenEdit();
        DataExports.Close();

        // [GIVEN] Dtd file is attached to the Data Export Record Definition.
        DataExportRecDef.Get(GLAccTxt, GLAccTxt);
        CreateDummyDTDFileBlob(DataExportRecDef);

        // [WHEN] Run Export Business Data report on the Data Export Record Definition.
        LibraryFileMgtHandler.SetBeforeDownloadFromStreamHandlerActivated(true);
        BindSubscription(LibraryFileMgtHandler);
        RunExportBusinessDataZipStreamOutput(DataExportRecDef);
        UnbindSubscription(LibraryFileMgtHandler);

        // [THEN] Zip file is created, it contains index.xml, dtd file and files for exported table data.
        FilesNames.AddRange(IndexFileTxt, DefaultDTDFileTxt, LogFileTxt);
        LibraryFileMgtHandler.GetTempBlob(TempBlob);
        VerifyFileNamesAndCountInZip(TempBlob, FilesNames, 17);

        // tear down
        DeleteDataExportRecord(GLAccTxt, GLAccTxt);
        DeleteDataExportRecord(FAAccTxt, FAAccTxt);
        DeleteDataExportRecord(ItemAccTxt, ItemAccTxt);
        DataExportSetup.DeleteAll(true);
    end;

    [Test]
    procedure RunExportBusinessDataOnFAAcc2022()
    var
        DataExportRecDef: Record "Data Export Record Definition";
        DataExportSetup: Record "Data Export Setup";
        LibraryFileMgtHandler: Codeunit "Library - File Mgt Handler";
        TempBlob: Codeunit "Temp Blob";
        DataExports: TestPage "Data Exports";
        FilesNames: List of [Text];
    begin
        // [SCENARIO 418608] Data is exported with Data Export "FAAcc 2022".

        // [GIVEN] Data Export with code "FAAcc 2022".
        // [GIVEN] Data Export Record Definition with Data Export Code and Data Export Rec Type Code "FAAcc 2022".
        DataExports.OpenEdit();
        DataExports.Close();

        // [GIVEN] Dtd file is attached to the Data Export Record Definition.
        DataExportRecDef.Get(FAAccTxt, FAAccTxt);
        CreateDummyDTDFileBlob(DataExportRecDef);

        // [WHEN] Run Export Business Data report on the Data Export Record Definition.
        LibraryFileMgtHandler.SetBeforeDownloadFromStreamHandlerActivated(true);
        BindSubscription(LibraryFileMgtHandler);
        RunExportBusinessDataZipStreamOutput(DataExportRecDef);
        UnbindSubscription(LibraryFileMgtHandler);

        // [THEN] Zip file is created, it contains index.xml, dtd file and files for exported table data.
        FilesNames.AddRange(IndexFileTxt, DefaultDTDFileTxt, LogFileTxt);
        LibraryFileMgtHandler.GetTempBlob(TempBlob);
        VerifyFileNamesAndCountInZip(TempBlob, FilesNames, 7);

        // tear down
        DeleteDataExportRecord(GLAccTxt, GLAccTxt);
        DeleteDataExportRecord(FAAccTxt, FAAccTxt);
        DeleteDataExportRecord(ItemAccTxt, ItemAccTxt);
        DataExportSetup.DeleteAll(true);
    end;

    [Test]
    procedure RunExportBusinessDataOnItemAcc2022()
    var
        DataExportRecDef: Record "Data Export Record Definition";
        DataExportSetup: Record "Data Export Setup";
        LibraryFileMgtHandler: Codeunit "Library - File Mgt Handler";
        TempBlob: Codeunit "Temp Blob";
        DataExports: TestPage "Data Exports";
        FilesNames: List of [Text];
    begin
        // [SCENARIO 418608] Data is exported with Data Export "Item 2022".

        // [GIVEN] Data Export with code "Item 2022".
        // [GIVEN] Data Export Record Definition with Data Export Code and Data Export Rec Type Code "Item 2022".
        DataExports.OpenEdit();
        DataExports.Close();

        // [GIVEN] Dtd file is attached to the Data Export Record Definition.
        DataExportRecDef.Get(ItemAccTxt, ItemAccTxt);
        CreateDummyDTDFileBlob(DataExportRecDef);

        // [WHEN] Run Export Business Data report on the Data Export Record Definition.
        LibraryFileMgtHandler.SetBeforeDownloadFromStreamHandlerActivated(true);
        BindSubscription(LibraryFileMgtHandler);
        RunExportBusinessDataZipStreamOutput(DataExportRecDef);
        UnbindSubscription(LibraryFileMgtHandler);

        // [THEN] Zip file is created, it contains index.xml, dtd file and files for exported table data.
        FilesNames.AddRange(IndexFileTxt, DefaultDTDFileTxt, LogFileTxt);
        LibraryFileMgtHandler.GetTempBlob(TempBlob);
        VerifyFileNamesAndCountInZip(TempBlob, FilesNames, 7);

        // tear down
        DeleteDataExportRecord(GLAccTxt, GLAccTxt);
        DeleteDataExportRecord(FAAccTxt, FAAccTxt);
        DeleteDataExportRecord(ItemAccTxt, ItemAccTxt);
        DataExportSetup.DeleteAll(true);
    end;

    [Test]
    procedure RunReportWhenMultipleBlobsPerTable()
    var
        CVLedgEntryBuffer: Record "CV Ledger Entry Buffer";
        DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer";
        DataExportRecDefinition: Record "Data Export Record Definition";
        ExpectedFileNames: array[5] of Text;
        ZipFilePath: Text;
        NoOfParentEntries: Integer;
        NoOfChildEntries: Integer;
        i: Integer;
    begin
        // [SCENARIO 464058] Run Export Business Data when exported data size exceeds 2GB blob size.
        // To emulate scenario we set size threshold for blob to 30 bytes by invoking ExportBusinessData.InitializeBlobMaxSizeThreshold().
        // Size for each exported line is between 18 and 35 bytes, so in each blob there will be stored 1 or 2 lines.
        // In this scenario we test how data from multiple blobs is merged into one file. Default blob size threshold is ~1.7GB and set in OnInitReport().

        // [GIVEN] Data Export Record Definition with parent and child Record Sources "CVLedgerEntryBuffer" and "Detailed CV Ledg. Entry Buffer".
        // [GIVEN] 3 records CV Ledger Entry Buffer with 2 Detailed CV Ledg. Entry Buffer records for each CV Ledger Entry Buffer.
        SetupParentChildTablesForExport(DataExportRecDefinition, ExpectedFileNames);
        NoOfParentEntries := 3;
        NoOfChildEntries := 2;
        for i := 1 to NoOfParentEntries do
            InsertChildEntries(NoOfChildEntries);

        // [WHEN] Run Export Business Data report with limitation on blob size of 30 bytes.
        ZipFilePath := ExportBusinessDataSetBlobSize(DataExportRecDefinition, 30);

        // [THEN] Zip file is created, it contains CVLedgerEntryBuffer.txt, DetailedCVLedgEntryBuffer.txt and Log.txt files.
        // [THEN] CVLedgerEntryBuffer.txt contains 3 lines, DetailedCVLedgEntryBuffer.txt contains 6 lines.
        // [THEN] Log.txt contains information that 3 CVLedgerEntryBuffer and 6 DetailedCVLedgEntryBuffer records were exported.
        VerifyCVLedgerEntryContentInDataFile(ZipFilePath);
        VerifyDtldCVLedgerEntryContentInDataFile(ZipFilePath);
        ValidateLogFile(ZipFilePath, 1, CVLedgEntryBuffer.TableName, NoOfParentEntries);
        ValidateLogFile(ZipFilePath, 2, DtldCVLedgEntryBuffer.TableName, NoOfParentEntries * NoOfChildEntries);
    end;

    local procedure GetPKFieldIndex(): Integer
    begin
        exit(1);
    end;

    local procedure GetFirstNonPKFieldIndex(): Integer
    begin
        exit(GetPKFieldIndex() + 1);
    end;

    local procedure FindRecordSource(DataExportRecord: Record "Data Export Record Definition"; TableID: Integer; var DataExportRecordSource: Record "Data Export Record Source")
    begin
        DataExportRecordSource.SetRange("Data Export Code", DataExportRecord."Data Export Code");
        DataExportRecordSource.SetRange("Data Exp. Rec. Type Code", DataExportRecord."Data Exp. Rec. Type Code");
        DataExportRecordSource.SetRange("Table No.", TableID);
        DataExportRecordSource.FindFirst();
    end;

    local procedure SetKeyNoAsNotPK(DataExportRecord: Record "Data Export Record Definition"; TableID: Integer)
    var
        DataExportRecordSource: Record "Data Export Record Source";
    begin
        FindRecordSource(DataExportRecord, TableID, DataExportRecordSource);
        DataExportRecordSource.Validate("Key No.", FirstKeyWithCustNo());
        DataExportRecordSource.Modify();
    end;

    local procedure FirstKeyWithCustNo(): Integer
    begin
        exit(3); // Expected Key: Customer No.,Initial Entry Due Date,Posting Date,Currency Code
    end;

    local procedure SetTableFilter(DataExportRecord: Record "Data Export Record Definition"; TableID: Integer; TableFilterText: Text)
    var
        DataExportRecordSource: Record "Data Export Record Source";
    begin
        FindRecordSource(DataExportRecord, TableID, DataExportRecordSource);
        Evaluate(DataExportRecordSource."Table Filter", TableFilterText);
        DataExportRecordSource.Validate("Table Filter");
        DataExportRecordSource.Modify();
    end;

    local procedure FormatCustTableFilter(CustNoFilter: Code[250]): Text
    var
        Customer: Record Customer;
        TableFilter: Text;
    begin
        TableFilter := Customer.TableName + ': ' +
              Customer.FieldName("Net Change") + '=<>0,' +
              Customer.FieldName("No.") + '=' + CustNoFilter;

        exit(TableFilter);
    end;

    local procedure SetupParentTableForExport(var DataExportRecord: Record "Data Export Record Definition"; var DataExportRecordSource: Record "Data Export Record Source")
    begin
        ClearParentChildTables();

        CreateRecDefinition(DataExportRecord);
        AddRecordSourceWithFields(DataExportRecord, DATABASE::"CV Ledger Entry Buffer", DataExportRecordSource);
    end;

    local procedure SetupParentChildTablesForExport(var DataExportRecord: Record "Data Export Record Definition"; var ExportedFileNames: array[5] of Text)
    var
        DataExportRecordSource: Record "Data Export Record Source";
        ParentDataExportRecordSource: Record "Data Export Record Source";
        CVLedgEntryBuffer: Record "CV Ledger Entry Buffer";
        DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer";
    begin
        Clear(ExportedFileNames);

        SetupParentTableForExport(DataExportRecord, DataExportRecordSource);
        ExportedFileNames[1] := DataExportRecordSource."Export File Name";
        ParentDataExportRecordSource := DataExportRecordSource;

        AddRecordSourceWithFields(DataExportRecord, DATABASE::"Detailed CV Ledg. Entry Buffer", DataExportRecordSource);
        SetPeriodFieldNo(DataExportRecordSource, DtldCVLedgEntryBuffer.FieldNo("Posting Date"));
        ExportedFileNames[2] := DataExportRecordSource."Export File Name";

        Indent(DataExportRecordSource, ParentDataExportRecordSource);
        MakeRelation(
          DataExportRecordSource, DtldCVLedgEntryBuffer.FieldNo("CV Ledger Entry No."),
          ParentDataExportRecordSource, CVLedgEntryBuffer.FieldNo("Entry No."));
    end;

    local procedure SetupTwoPairsOfParentChild(var DataExportRecord: Record "Data Export Record Definition"; var ExportFileName: array[2, 5] of Text)
    var
        DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer";
        DataExportRecordSource: Record "Data Export Record Source";
        ParentDataExportRecordSource: Record "Data Export Record Source";
    begin
        SetupParentChildTablesForExport(DataExportRecord, ExportFileName[1]);
        // Same tables Parent-Child tables are set with empty table filters
        DataExportRecordSource.SetRange("Data Export Code", DataExportRecord."Data Export Code");
        DataExportRecordSource.SetRange("Data Exp. Rec. Type Code", DataExportRecord."Data Exp. Rec. Type Code");
        DataExportRecordSource.FindLast();

        AddRecordSourceWithFields(DataExportRecord, DATABASE::"CV Ledger Entry Buffer", DataExportRecordSource);
        ParentDataExportRecordSource := DataExportRecordSource;
        ExportFileName[2, 1] := DataExportRecordSource."Export File Name";

        AddRecordSourceWithFields(DataExportRecord, DATABASE::"Detailed CV Ledg. Entry Buffer", DataExportRecordSource);
        ExportFileName[2, 2] := DataExportRecordSource."Export File Name";
        SetPeriodFieldNo(DataExportRecordSource, DtldCVLedgEntryBuffer.FieldNo("Posting Date"));

        Indent(DataExportRecordSource, ParentDataExportRecordSource);

        // Parent has 1 record, Child has 3 records
        InsertChildEntries(3);
    end;

    local procedure CreateRecDefinition(var DataExportRecord: Record "Data Export Record Definition")
    begin
        DataExportRecord."Data Export Code" := GetDataExportCode();
        DataExportRecord."Data Exp. Rec. Type Code" := GetExpRecTypeCode();
        DataExportRecord.Description := DataExportRecord."Data Export Code" + DataExportRecord."Data Exp. Rec. Type Code";
        DataExportRecord.Insert();
        CreateDummyDTDFileBlob(DataExportRecord);
    end;

    local procedure GetDataExportCode(): Code[10]
    var
        DataExport: Record "Data Export";
    begin
        DataExport.Code := LibraryUtility.GenerateGUID();
        DataExport.Description := DataExport.Code;
        DataExport.Insert();
        exit(DataExport.Code);
    end;

    local procedure GetExpRecTypeCode(): Code[10]
    var
        DataExportRecType: Record "Data Export Record Type";
    begin
        DataExportRecType.Code := LibraryUtility.GenerateGUID();
        DataExportRecType.Description := DataExportRecType.Code;
        DataExportRecType.Insert();
        exit(DataExportRecType.Code);
    end;

    local procedure AddRecordSourceWithFilters(DataExportRecord: Record "Data Export Record Definition"; TableNo: Integer; FilterText: Text; var DataExportRecordSource: Record "Data Export Record Source")
    begin
        AddRecordSourceWithFields(DataExportRecord, TableNo, DataExportRecordSource);
        SetTableFilter(DataExportRecord, TableNo, FilterText);
    end;

    local procedure AddCustRecordSourceWithSameFields(DataExportRecord: Record "Data Export Record Definition"; var DataExportRecordSource: Record "Data Export Record Source")
    begin
        AddRecordSource(DataExportRecord, CustomerTableNo(), DataExportRecordSource);
        AddCustSameFields(DataExportRecordSource);
    end;

    local procedure AddRecordSourceWithFields(DataExportRecord: Record "Data Export Record Definition"; TableNo: Integer; var DataExportRecordSource: Record "Data Export Record Source")
    begin
        AddRecordSource(DataExportRecord, TableNo, DataExportRecordSource);
        AddFields(DataExportRecordSource);
    end;

    local procedure AddRecordSource(DataExportRecord: Record "Data Export Record Definition"; TableNo: Integer; var DataExportRecordSource: Record "Data Export Record Source")
    begin
        DataExportRecordSource.Init();
        DataExportRecordSource."Data Export Code" := DataExportRecord."Data Export Code";
        DataExportRecordSource."Data Exp. Rec. Type Code" := DataExportRecord."Data Exp. Rec. Type Code";
        DataExportRecordSource."Line No." := DataExportRecordSource."Line No." + 10000;
        DataExportRecordSource.Validate("Table No.", TableNo);
        DataExportRecordSource.Insert(true);
    end;

    local procedure AddRecordSourceWithDateFilterHandling(DataExportRecord: Record "Data Export Record Definition"; TableID: Integer; FieldID: Integer; DateFilterHandling: Option; var DataExportRecordSource: Record "Data Export Record Source")
    var
        DataExpRecField: Record "Data Export Record Field";
    begin
        AddRecordSourceWithFields(DataExportRecord, TableID, DataExportRecordSource);
        DataExportRecordSource."Date Filter Handling" := DateFilterHandling;
        DataExportRecordSource.Modify();

        DataExpRecField.SetRange("Data Export Code", DataExportRecord."Data Export Code");
        DataExpRecField.SetRange("Data Exp. Rec. Type Code", DataExportRecord."Data Exp. Rec. Type Code");
        DataExpRecField.SetRange("Table No.", TableID);
        DataExpRecField.SetRange("Field No.", FieldID);
        DataExpRecField.SetRange("Source Line No.", DataExportRecordSource."Line No.");
        DataExpRecField.FindFirst();

        DataExpRecField."Date Filter Handling" := DateFilterHandling;
        DataExpRecField.Modify();
    end;

    local procedure AddSeveralRecordSourceAndIndent(var DataExportRecordSource: Record "Data Export Record Source"; DataExportRecord: Record "Data Export Record Definition"; TableNo: array[10] of Integer; NoOfRecords: Integer; Indent: Boolean)
    var
        Counter: Integer;
    begin
        for Counter := 1 to NoOfRecords do begin
            DataExportRecordSource.Init();
            DataExportRecordSource."Data Export Code" := DataExportRecord."Data Export Code";
            DataExportRecordSource."Data Exp. Rec. Type Code" := DataExportRecord."Data Exp. Rec. Type Code";
            DataExportRecordSource."Line No." := DataExportRecordSource."Line No." + 10000;
            DataExportRecordSource.Validate("Table No.", TableNo[Counter]);
            DataExportRecordSource.Insert(true);
            if Indent and (Counter <> NoOfRecords) then
                DataExportRecordSource.Validate(Indentation, Counter - 1);
        end;
    end;

    local procedure CreateGLAccountDataExport(var DataExportRecordDefinition: Record "Data Export Record Definition"; var DataExportRecordSource: Record "Data Export Record Source"; GLAccount: Record "G/L Account"; DateFilterHandling: Option)
    begin
        CreateRecDefinition(DataExportRecordDefinition);
        AddRecordSourceWithDateFilterHandling(
          DataExportRecordDefinition,
          GLAccTableNo(),
          GLAccount.FieldNo("Balance at Date"),
          DateFilterHandling,
          DataExportRecordSource);
        SetTableFilter(
          DataExportRecordDefinition,
          GLAccTableNo(),
          GLAccount.TableName + ': ' + GLAccount.FieldName("No.") + '=' + GLAccount."No.");
    end;

    local procedure SetPeriodFieldNo(var DataExportRecordSource: Record "Data Export Record Source"; PeriodFieldNo: Integer)
    begin
        DataExportRecordSource."Period Field No." := PeriodFieldNo;
        DataExportRecordSource.Modify();
    end;

    local procedure AddCustSameFields(DataExportRecordSource: Record "Data Export Record Source")
    var
        DataExportRecField: Record "Data Export Record Field";
        Customer: Record Customer;
        DateFilterHandling: Option " ",Period,"End Date Only","Start Date Only";
    begin
        DataExportRecField."Data Export Code" := DataExportRecordSource."Data Export Code";
        DataExportRecField."Data Exp. Rec. Type Code" := DataExportRecordSource."Data Exp. Rec. Type Code";
        DataExportRecField."Table No." := DataExportRecordSource."Table No.";
        DataExportRecField."Line No." := 0;
        DataExportRecField."Source Line No." := DataExportRecordSource."Line No.";

        InsertCustFields(DataExportRecField);
        AddFieldWithDateFilterHandling(DataExportRecField, Customer.FieldNo("Net Change"), DateFilterHandling::"End Date Only");
    end;

    local procedure AddFields(DataExportRecordSource: Record "Data Export Record Source")
    var
        DataExportRecField: Record "Data Export Record Field";
    begin
        DataExportRecField."Data Export Code" := DataExportRecordSource."Data Export Code";
        DataExportRecField."Data Exp. Rec. Type Code" := DataExportRecordSource."Data Exp. Rec. Type Code";
        DataExportRecField.Validate("Table No.", DataExportRecordSource."Table No.");
        DataExportRecField."Line No." := 0;
        DataExportRecField."Source Line No." := DataExportRecordSource."Line No.";

        case DataExportRecField."Table No." of
            ParentTableNo():
                InsertCVLedgEntryBufFields(DataExportRecField);
            ChildTableNo():
                InsertDtldCVLedgEntryBufFields(DataExportRecField);
            CustomerTableNo():
                InsertCustFields(DataExportRecField);
            VendorTableNo():
                InsertVendFields(DataExportRecField);
            ItemTableNo():
                InsertItemFields(DataExportRecField);
            GLAccTableNo():
                InsertGLAccFields(DataExportRecField);
            CustLedgEntryTableNo():
                InsertCustLedgEntryFields(DataExportRecField);
            VendLedgEntryTableNo():
                InsertVendLedgEntryFields(DataExportRecField);
            ItemLedgEntryTableNo():
                InsertItemLedgEntryFields(DataExportRecField);
            GLEntryTableNo():
                InsertGLEntryFields(DataExportRecField);
            CompanyInfoTableNo():
                InsertCompanyInformationFields(DataExportRecField)
        end;
    end;

    local procedure InsertCVLedgEntryBufFields(var DataExportRecField: Record "Data Export Record Field")
    var
        CVLedgEntryBuffer: Record "CV Ledger Entry Buffer";
    begin
        AddField(DataExportRecField, CVLedgEntryBuffer.FieldNo("Entry No."));
        AddField(DataExportRecField, CVLedgEntryBuffer.FieldNo("Document Type"));
        AddField(DataExportRecField, CVLedgEntryBuffer.FieldNo(Amount));
    end;

    local procedure InsertDtldCVLedgEntryBufFields(var DataExportRecField: Record "Data Export Record Field")
    var
        DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer";
    begin
        AddField(DataExportRecField, DtldCVLedgEntryBuffer.FieldNo("Entry No."));
        AddField(DataExportRecField, DtldCVLedgEntryBuffer.FieldNo("CV Ledger Entry No."));
        AddField(DataExportRecField, DtldCVLedgEntryBuffer.FieldNo("Entry Type"));
        AddField(DataExportRecField, DtldCVLedgEntryBuffer.FieldNo("Posting Date"));
    end;

    local procedure InsertCustFields(var DataExportRecField: Record "Data Export Record Field")
    var
        Customer: Record Customer;
        DateFilterHandling: Option " ",Period,"End Date Only","Start Date Only";
    begin
        AddField(DataExportRecField, Customer.FieldNo("No."));
        AddFieldWithDateFilterHandling(DataExportRecField, Customer.FieldNo("Net Change"), DateFilterHandling::Period);
    end;

    local procedure InsertVendFields(var DataExportRecField: Record "Data Export Record Field")
    var
        Vendor: Record Vendor;
        DateFilterHandling: Option " ",Period,"End Date Only","Start Date Only";
    begin
        AddField(DataExportRecField, Vendor.FieldNo("No."));
        AddField(DataExportRecField, Vendor.FieldNo(Balance));
        AddField(DataExportRecField, Vendor.FieldNo(Name));
        AddFieldWithDateFilterHandling(DataExportRecField, Vendor.FieldNo("Net Change"), DateFilterHandling::Period);
    end;

    local procedure InsertItemFields(var DataExportRecField: Record "Data Export Record Field")
    var
        Item: Record Item;
        DateFilterHandling: Option " ",Period,"End Date Only","Start Date Only";
    begin
        AddField(DataExportRecField, Item.FieldNo("No."));
        AddField(DataExportRecField, Item.FieldNo("Unit Cost"));
        AddField(DataExportRecField, Item.FieldNo("Unit Price"));
        AddField(DataExportRecField, Item.FieldNo("Net Change"));
        AddFieldWithDateFilterHandling(DataExportRecField, Item.FieldNo(Inventory), DateFilterHandling::Period);
    end;

    local procedure InsertGLAccFields(var DataExportRecField: Record "Data Export Record Field")
    var
        GLAcc: Record "G/L Account";
        DateFilterHandling: Option " ",Period,"End Date Only","Start Date Only";
    begin
        AddField(DataExportRecField, GLAcc.FieldNo("No."));
        AddField(DataExportRecField, GLAcc.FieldNo(Name));
        AddField(DataExportRecField, GLAcc.FieldNo(Balance));
        AddFieldWithDateFilterHandling(DataExportRecField, GLAcc.FieldNo("Net Change"), DateFilterHandling::Period);
        AddFieldWithDateFilterHandling(DataExportRecField, GLAcc.FieldNo("Balance at Date"), DateFilterHandling::Period);
    end;

    local procedure InsertCustLedgEntryFields(var DataExportRecField: Record "Data Export Record Field")
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        DateFilterHandling: Option " ",Period,"End Date Only","Start Date Only";
    begin
        AddField(DataExportRecField, CustLedgEntry.FieldNo("Entry No."));
        AddField(DataExportRecField, CustLedgEntry.FieldNo("Customer No."));
        AddField(DataExportRecField, CustLedgEntry.FieldNo("Posting Date"));
        AddFieldWithDateFilterHandling(DataExportRecField, CustLedgEntry.FieldNo(Amount), DateFilterHandling::Period);
    end;

    local procedure InsertVendLedgEntryFields(var DataExportRecField: Record "Data Export Record Field")
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        DateFilterHandling: Option " ",Period,"End Date Only","Start Date Only";
    begin
        AddField(DataExportRecField, VendLedgEntry.FieldNo("Entry No."));
        AddField(DataExportRecField, VendLedgEntry.FieldNo("Vendor No."));
        AddField(DataExportRecField, VendLedgEntry.FieldNo("Posting Date"));
        AddFieldWithDateFilterHandling(DataExportRecField, VendLedgEntry.FieldNo(Amount), DateFilterHandling::Period);
    end;

    local procedure InsertItemLedgEntryFields(var DataExportRecField: Record "Data Export Record Field")
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        DateFilterHandling: Option " ",Period,"End Date Only","Start Date Only";
    begin
        AddField(DataExportRecField, ItemLedgEntry.FieldNo("Entry No."));
        AddField(DataExportRecField, ItemLedgEntry.FieldNo("Item No."));
        AddField(DataExportRecField, ItemLedgEntry.FieldNo("Posting Date"));
        AddField(DataExportRecField, ItemLedgEntry.FieldNo(Quantity));
        AddFieldWithDateFilterHandling(
          DataExportRecField,
          ItemLedgEntry.FieldNo("Cost Amount (Actual)"),
          DateFilterHandling::Period);
    end;

    local procedure InsertGLEntryFields(var DataExportRecField: Record "Data Export Record Field")
    var
        GLEntry: Record "G/L Entry";
        DateFilterHandling: Option " ",Period,"End Date Only","Start Date Only";
    begin
        AddField(DataExportRecField, GLEntry.FieldNo("Entry No."));
        AddField(DataExportRecField, GLEntry.FieldNo("G/L Account No."));
        AddField(DataExportRecField, GLEntry.FieldNo("Posting Date"));
        AddFieldWithDateFilterHandling(DataExportRecField, GLEntry.FieldNo(Amount), DateFilterHandling::Period);
    end;

    local procedure InsertCompanyInformationFields(var DataExportRecField: Record "Data Export Record Field")
    var
        CompanyInformation: Record "Company Information";
    begin
        UpdateValuesInCompanyInformation(CompanyInformation);
        AddField(DataExportRecField, CompanyInformation.FieldNo("Primary Key"));
        AddField(DataExportRecField, CompanyInformation.FieldNo(Name));
        AddField(DataExportRecField, CompanyInformation.FieldNo("Name 2"));
        AddField(DataExportRecField, CompanyInformation.FieldNo(Address));
        AddField(DataExportRecField, CompanyInformation.FieldNo("Address 2"));
        AddField(DataExportRecField, CompanyInformation.FieldNo("Bank Name"));
        AddField(DataExportRecField, CompanyInformation.FieldNo("Ship-to Name"));
        AddField(DataExportRecField, CompanyInformation.FieldNo("Ship-to Name 2"));
        AddField(DataExportRecField, CompanyInformation.FieldNo("Ship-to Address"));
        AddField(DataExportRecField, CompanyInformation.FieldNo("Ship-to Address 2"));
        AddField(DataExportRecField, CompanyInformation.FieldNo("Ship-to Contact"));
        AddField(DataExportRecField, CompanyInformation.FieldNo("Custom System Indicator Text"));
        AddField(DataExportRecField, CompanyInformation.FieldNo("Tax Office Name"));
        AddField(DataExportRecField, CompanyInformation.FieldNo("Tax Office Name 2"));
        AddField(DataExportRecField, CompanyInformation.FieldNo("Check-Avail. Time Bucket"));
    end;

    local procedure MockGLEntries(AccountNo: Code[20]; PostingDate: Date; Sign: Integer) GLAmount: Decimal
    begin
        GLAmount := LibraryRandom.RandDec(100, 2);
        MockGLEntry(AccountNo, PostingDate, GLAmount * Sign);
        MockGLEntry(LibraryUtility.GenerateGUID(), PostingDate, -GLAmount * Sign);
        exit(GLAmount);
    end;

    local procedure MockGLEntry(AccountNo: Code[20]; PostingDate: Date; GLAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
        RecRef: RecordRef;
    begin
        GLEntry.Init();
        RecRef.GetTable(GLEntry);
        GLEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, GLEntry.FieldNo("Entry No."));
        GLEntry."G/L Account No." := AccountNo;
        GLEntry."Posting Date" := PostingDate;
        GLEntry.Amount := GLAmount;
        GLEntry.Insert();
    end;

    local procedure PrepareObjectsForExport()
    begin
        MockCVLedgEntryBufAndDtldCVLedgEntryBuf(MockVendor());
    end;

    local procedure MockVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor.Init();
        Vendor."No." := LibraryUtility.GenerateRandomCode(Vendor.FieldNo("No."), DATABASE::Vendor);
        Vendor.Insert();
        exit(Vendor."No.");
    end;

    local procedure MockCVLedgEntryBufAndDtldCVLedgEntryBuf(VendorNo: Code[20])
    var
        CVLedgEntryBuffer: Record "CV Ledger Entry Buffer";
        DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(CVLedgEntryBuffer);
        CVLedgEntryBuffer."Entry No." := LibraryUtility.GetNewLineNo(RecRef, CVLedgEntryBuffer.FieldNo("Entry No."));
        CVLedgEntryBuffer."Posting Date" := WorkDate();
        CVLedgEntryBuffer."Document Type" := CVLedgEntryBuffer."Document Type"::Invoice;
        CVLedgEntryBuffer."CV No." := VendorNo;
        CVLedgEntryBuffer.Insert();
        RecRef.GetTable(DtldCVLedgEntryBuffer);
        DtldCVLedgEntryBuffer."Entry No." := LibraryUtility.GetNewLineNo(RecRef, DtldCVLedgEntryBuffer.FieldNo("Entry No."));
        DtldCVLedgEntryBuffer."CV Ledger Entry No." := CVLedgEntryBuffer."Entry No.";
        DtldCVLedgEntryBuffer."Posting Date" := WorkDate();
        DtldCVLedgEntryBuffer."Entry Type" := "Detailed CV Ledger Entry Type".FromInteger(DtldCVLedgEntryBuffer."Entry Type".AsInteger() + 1);
        DtldCVLedgEntryBuffer."CV No." := VendorNo;
        DtldCVLedgEntryBuffer.Insert();
    end;

    local procedure PrepareDataExportRecordDefinition(var DataExportRecordDefinition: Record "Data Export Record Definition")
    var
        ParentDataExportRecordSource: Record "Data Export Record Source";
        Vendor: Record Vendor;
        CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer";
        DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer";
    begin
        CreateDataExportRecordSources(DataExportRecordDefinition);
        GetDataExportRecordSourceAndAddFields(
          ParentDataExportRecordSource, DataExportRecordDefinition."Data Export Code",
          DataExportRecordDefinition."Data Exp. Rec. Type Code", DATABASE::Vendor);

        IndentAndMakeRelation(
          ParentDataExportRecordSource, DataExportRecordDefinition, DATABASE::"CV Ledger Entry Buffer",
          Vendor.FieldNo("No."), CVLedgerEntryBuffer.FieldNo("CV No."));

        IndentAndMakeRelation(
          ParentDataExportRecordSource, DataExportRecordDefinition, DATABASE::"Detailed CV Ledg. Entry Buffer",
          Vendor.FieldNo("No."), DtldCVLedgEntryBuffer.FieldNo("CV No."));
    end;

    local procedure CreateDataExportRecordSources(var DataExportRecordDefinition: Record "Data Export Record Definition")
    var
        DataExportRecordSource: Record "Data Export Record Source";
        TableNoArr: array[10] of Integer;
    begin
        DataExportRecordSource.DeleteAll(true);
        CreateRecDefinition(DataExportRecordDefinition);
        TableNoArr[1] := DATABASE::Vendor;
        TableNoArr[2] := DATABASE::"CV Ledger Entry Buffer";
        TableNoArr[3] := DATABASE::"Detailed CV Ledg. Entry Buffer";
        AddSeveralRecordSourceAndIndent(DataExportRecordSource, DataExportRecordDefinition, TableNoArr, 3, false);
    end;

    local procedure GetDataExportRecordSourceAndAddFields(var DataExportRecordSource: Record "Data Export Record Source"; DataExpCode: Code[10]; DataExpRecTypeCode: Code[10]; TableNo: Integer)
    begin
        DataExportRecordSource.SetRange("Data Export Code", DataExpCode);
        DataExportRecordSource.SetRange("Data Exp. Rec. Type Code", DataExpRecTypeCode);
        DataExportRecordSource.SetRange("Table No.", TableNo);
        DataExportRecordSource.FindFirst();
        AddFields(DataExportRecordSource);
    end;

    local procedure IndentAndMakeRelation(ParentDataExportRecordSource: Record "Data Export Record Source"; DataExportRecordDefinition: Record "Data Export Record Definition"; TableNo: Integer; ParentFieldNo: Integer; ChildFieldNo: Integer)
    var
        DataExportRecordSource: Record "Data Export Record Source";
    begin
        GetDataExportRecordSourceAndAddFields(
          DataExportRecordSource, DataExportRecordDefinition."Data Export Code",
          DataExportRecordDefinition."Data Exp. Rec. Type Code", TableNo);

        Indent(DataExportRecordSource, ParentDataExportRecordSource);
        MakeRelation(DataExportRecordSource, ChildFieldNo,
          ParentDataExportRecordSource, ParentFieldNo);
    end;

    local procedure DeleteRecordSource(var DataExportRecordSource: Record "Data Export Record Source")
    begin
        DataExportRecordSource.Find();
        DataExportRecordSource.Delete(true);
    end;

    local procedure DeleteDataExportRecord(DataExportCode: Code[10]; DataExportRecTypeCode: Code[10])
    var
        DataExport: Record "Data Export";
        DataExportRecType: Record "Data Export Record Type";
    begin
        DataExport.Get(DataExportCode);
        DataExport.Delete(true);
        DataExportRecType.Get(DataExportRecTypeCode);
        DataExportRecType.Delete(true);
    end;

    local procedure AddField(var DataExportRecField: Record "Data Export Record Field"; FieldID: Integer)
    var
        DateFilterHandling: Option " ",Period,"End Date Only","Start Date Only";
    begin
        AddFieldWithDateFilterHandling(DataExportRecField, FieldID, DateFilterHandling::" ");
    end;

    local procedure AddFieldWithDateFilterHandling(var DataExportRecField: Record "Data Export Record Field"; FieldID: Integer; DateFilterHandling: Option)
    begin
        DataExportRecField."Line No." := DataExportRecField."Line No." + 10000;
        DataExportRecField.Validate("Field No.", FieldID);
        DataExportRecField."Export Field Name" := 'F' + Format(DataExportRecField."Field No.");
        DataExportRecField."Date Filter Handling" := DateFilterHandling;
        DataExportRecField.Insert(true);
    end;

    local procedure MakeRelation(var DataExportRecordSource: Record "Data Export Record Source"; ChildFieldNo: Integer; ParentDataExportRecordSource: Record "Data Export Record Source"; ParentFieldNo: Integer)
    var
        DataExpTableRelation: Record "Data Export Table Relation";
    begin
        DataExpTableRelation."Data Export Code" := DataExportRecordSource."Data Export Code";
        DataExpTableRelation."Data Exp. Rec. Type Code" := DataExportRecordSource."Data Exp. Rec. Type Code";
        DataExpTableRelation."From Table No." := ParentDataExportRecordSource."Table No.";
        DataExpTableRelation."From Field No." := ParentFieldNo;
        DataExpTableRelation."To Table No." := DataExportRecordSource."Table No.";
        DataExpTableRelation."To Field No." := ChildFieldNo;
        DataExpTableRelation.Insert();
    end;

    local procedure Indent(var DataExportRecordSource: Record "Data Export Record Source"; ParentDataExportRecordSource: Record "Data Export Record Source")
    begin
        DataExportRecordSource.Indentation := ParentDataExportRecordSource.Indentation + 1;
        DataExportRecordSource."Relation To Line No." := ParentDataExportRecordSource."Line No.";
        DataExportRecordSource."Relation To Table No." := ParentDataExportRecordSource."Table No.";
        DataExportRecordSource.Modify();
    end;

    local procedure ClearParentChildTables()
    var
        CVLedgEntryBuffer: Record "CV Ledger Entry Buffer";
        DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer";
    begin
        CVLedgEntryBuffer.DeleteAll();
        DtldCVLedgEntryBuffer.DeleteAll();
    end;

    local procedure InsertParentEntry(): Integer
    var
        CVLedgEntryBuffer: Record "CV Ledger Entry Buffer";
        LastEntryNo: Integer;
        DummyEntryFound: Boolean;
    begin
        DummyEntryFound := CVLedgEntryBuffer.FindLast();
        LastEntryNo := CVLedgEntryBuffer."Entry No.";
        CVLedgEntryBuffer."Entry No." := LastEntryNo + 1;
        CVLedgEntryBuffer."Posting Date" := WorkDate();
        CVLedgEntryBuffer."Document Type" := CVLedgEntryBuffer."Document Type"::Invoice;
        CVLedgEntryBuffer.Insert();

        exit(CVLedgEntryBuffer."Entry No.");
    end;

    local procedure InsertChildEntries(NoOfEntries: Integer): Integer
    var
        DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer";
        ParentEntryNo: Integer;
        LastEntryNo: Integer;
        DummyEntryFound: Boolean;
        i: Integer;
    begin
        ParentEntryNo := InsertParentEntry();

        DummyEntryFound := DtldCVLedgEntryBuffer.FindLast();
        LastEntryNo := DtldCVLedgEntryBuffer."Entry No.";
        for i := 1 to NoOfEntries do begin
            DtldCVLedgEntryBuffer."Entry No." := LastEntryNo + i;
            DtldCVLedgEntryBuffer."CV Ledger Entry No." := ParentEntryNo;
            DtldCVLedgEntryBuffer."Posting Date" := WorkDate();
            DtldCVLedgEntryBuffer."Entry Type" := "Detailed CV Ledger Entry Type".FromInteger(i);
            DtldCVLedgEntryBuffer.Insert();
        end;

        exit(DtldCVLedgEntryBuffer."Entry No.");
    end;

    local procedure DuplicateParentChildEntries()
    var
        CVLedgEntryBuffer: Record "CV Ledger Entry Buffer";
        DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer";
        NewDtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer";
        NewChildEntryNo: Integer;
    begin
        CVLedgEntryBuffer.FindLast();
        CVLedgEntryBuffer."Entry No." += 1;
        CVLedgEntryBuffer.Insert();

        DtldCVLedgEntryBuffer.SetRange("CV Ledger Entry No.", CVLedgEntryBuffer."Entry No." - 1);
        if DtldCVLedgEntryBuffer.FindLast() then begin
            NewChildEntryNo := DtldCVLedgEntryBuffer."Entry No." + 1;
            if DtldCVLedgEntryBuffer.FindSet() then
                repeat
                    NewDtldCVLedgEntryBuffer := DtldCVLedgEntryBuffer;
                    NewDtldCVLedgEntryBuffer."Entry No." := NewChildEntryNo;
                    NewDtldCVLedgEntryBuffer."CV Ledger Entry No." += 1;
                    NewDtldCVLedgEntryBuffer.Insert();
                    NewChildEntryNo += 1;
                until DtldCVLedgEntryBuffer.Next() = 0;
        end;
    end;

    local procedure ShiftPostingDateInFirstChildEntry()
    var
        DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer";
    begin
        DtldCVLedgEntryBuffer.FindFirst();
        DtldCVLedgEntryBuffer."Posting Date" += 1;
        DtldCVLedgEntryBuffer.Modify();
    end;

    local procedure ShiftDocTypeInFirstChildEntry()
    var
        DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer";
    begin
        DtldCVLedgEntryBuffer.FindFirst();
        DtldCVLedgEntryBuffer."Document Type" :=
            "Gen. Journal Document Type".FromInteger(DtldCVLedgEntryBuffer."Document Type".AsInteger() + 1);
        DtldCVLedgEntryBuffer.Modify();
    end;

    local procedure SetNonEmptyCustNoInFirstChildEntry()
    var
        DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer";
    begin
        DtldCVLedgEntryBuffer.FindFirst();
        DtldCVLedgEntryBuffer."CV No." := 'X';
        DtldCVLedgEntryBuffer.Modify();
    end;

    local procedure FindChildEntriesToExport(var DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; var TempEntryNo: Record "Integer" temporary)
    begin
        DtldCVLedgEntryBuffer.SetRange("Posting Date", WorkDate());
        if DtldCVLedgEntryBuffer.FindSet() then
            repeat
                TempEntryNo.Number := DtldCVLedgEntryBuffer."Entry No.";
                TempEntryNo.Insert();
            until DtldCVLedgEntryBuffer.Next() = 0;
    end;

    local procedure CreateCustWithGlobalDimCode(): Code[20]
    var
        Customer: Record Customer;
        GLSetup: Record "General Ledger Setup";
        DimensionValue: Record "Dimension Value";
        GenJournalLine: Record "Gen. Journal Line";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryERM: Codeunit "Library - ERM";
    begin
        GLSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue, GLSetup."Global Dimension 1 Code");
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Global Dimension 1 Code", DimensionValue.Code);
        Customer.Modify(true);
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, Customer."No.",
          LibraryRandom.RandInt(100));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(Customer."Global Dimension 1 Code");
    end;

    local procedure FindAccountingPeriodRange(): Text
    var
        AccountingPeriod: Record "Accounting Period";
        DataRangeTxt: Text;
    begin
        AccountingPeriod.FindFirst();
        DataRangeTxt := Format(AccountingPeriod."Starting Date") + '..';
        AccountingPeriod.FindLast();
        DataRangeTxt += Format(AccountingPeriod."Starting Date");
        exit(DataRangeTxt);
    end;

    local procedure VerifyFileNames(ExportZipPath: Text; ExportedFileName: array[6] of Text)
    var
        EntryList: List of [Text];
        ZipFile: File;
        ZipInStream: InStream;
        i: Integer;
    begin
        ZipFile.Open(ExportZipPath);
        ZipFile.CreateInStream(ZipInStream);
        DataCompression.OpenZipArchive(ZipInStream, false);
        DataCompression.GetEntryList(EntryList);
        DataCompression.CloseZipArchive();
        ZipFile.Close();
        for i := 1 to ArrayLen(ExportedFileName) do
            if ExportedFileName[i] <> '' then
                Assert.IsTrue(EntryList.Contains(ExportedFileName[i]), StrSubstNo(CannotFindFileErr, ExportedFileName[i]));
    end;

    local procedure VerifyFileNamesAndCountInZip(var TempBlob: Codeunit "Temp Blob"; FilesNames: List of [Text]; FilesNumber: Integer)
    var
        DataCompression: Codeunit "Data Compression";
        ZipEntryList: List of [Text];
        FileName: Text;
    begin
        DataCompression.OpenZipArchive(TempBlob, false);
        DataCompression.GetEntryList(ZipEntryList);
        Assert.AreEqual(FilesNumber, ZipEntryList.Count, '');
        foreach FileName in FilesNames do
            Assert.IsTrue(ZipEntryList.Contains(FileName), '');
    end;

    local procedure VerifyEntryNosInDataFile(ZipFilePath: Text; ExportedFileName: Text; var TempEntryNo: Record "Integer" temporary; FirstLineOnly: Boolean)
    var
        TempBlob: Codeunit "Temp Blob";
        ExtractedFileOutStream: OutStream;
        ExtractedFileInStream: InStream;
        NoOfLinesInFile: Integer;
        ActualEntryNo: Integer;
        NoOfLinesExpected: Integer;
        DataLine: Text;
    begin
        TempEntryNo.FindSet();
        NoOfLinesExpected := TempEntryNo.Count();
        TempBlob.CreateOutStream(ExtractedFileOutStream);
        ExtractEntryFromZipFile(ZipFilePath, ExportedFileName, ExtractedFileOutStream);
        TempBlob.CreateInStream(ExtractedFileInStream);
        NoOfLinesInFile := 0;
        while not ExtractedFileInStream.EOS do begin
            ExtractedFileInStream.READTEXT(DataLine);
            ActualEntryNo := ReadEntryNo(DataLine);
            if ActualEntryNo >= 0 then
                NoOfLinesInFile += 1;
            if NoOfLinesExpected < NoOfLinesInFile then
                Error(WrongNoOfLinesExportedErr, NoOfLinesExpected);
            Assert.AreEqual(TempEntryNo.Number, ActualEntryNo, WrongEntryNoExportedErr);
            if FirstLineOnly then
                exit;
            TempEntryNo.Next();
        end;
    end;

    local procedure ReadEntryNo(DataLine: Text) EntryNo: Integer
    begin
        DataLine := CopyStr(DataLine, 1, StrPos(DataLine, ';') - 1);
        if DataLine = '' then
            EntryNo := -1
        else
            Evaluate(EntryNo, DataLine);
        exit(EntryNo);
    end;

    local procedure VerifyCVLedgerEntryContentInDataFile(ZipFilePath: Text)
    var
        CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer";
        TempBlob: Codeunit "Temp Blob";
        ExtractedFileOutStream: OutStream;
        ExtractedFileInStream: InStream;
        NoOfLinesInFile: Integer;
        NoOfCVLedgerEntries: Integer;
        ExpectedLine: Text;
        ActualLine: Text;
    begin
        NoOfCVLedgerEntries := CVLedgerEntryBuffer.Count();
        TempBlob.CreateOutStream(ExtractedFileOutStream);
        ExtractEntryFromZipFile(ZipFilePath, CVLedgerEntryFileNameTxt, ExtractedFileOutStream);
        TempBlob.CreateInStream(ExtractedFileInStream);
        NoOfLinesInFile := 0;
        CVLedgerEntryBuffer.FindSet();
        while not ExtractedFileInStream.EOS() do begin
            NoOfLinesInFile += 1;
            ExtractedFileInStream.ReadText(ActualLine);
            ExpectedLine :=
                StrSubstNo(CVLedgerEntryLineFormatTxt, CVLedgerEntryBuffer."Entry No.", CVLedgerEntryBuffer."Document Type",
                Format(CVLedgerEntryBuffer.Amount, 0, '<Precision,2><Standard Format,0>'));
            Assert.AreEqual(ExpectedLine, ActualLine, '');
            CVLedgerEntryBuffer.Next();
        end;
        Assert.AreEqual(NoOfCVLedgerEntries, NoOfLinesInFile, '');
    end;

    local procedure VerifyDtldCVLedgerEntryContentInDataFile(ZipFilePath: Text)
    var
        DtldCVLedgerEntryBuffer: Record "Detailed CV Ledg. Entry Buffer";
        TempBlob: Codeunit "Temp Blob";
        ExtractedFileOutStream: OutStream;
        ExtractedFileInStream: InStream;
        NoOfLinesInFile: Integer;
        NoOfCVLedgerEntries: Integer;
        ExpectedLine: Text;
        ActualLine: Text;
    begin
        NoOfCVLedgerEntries := DtldCVLedgerEntryBuffer.Count();
        TempBlob.CreateOutStream(ExtractedFileOutStream);
        ExtractEntryFromZipFile(ZipFilePath, DtldCVLedgEntryFileNameTxt, ExtractedFileOutStream);
        TempBlob.CreateInStream(ExtractedFileInStream);
        NoOfLinesInFile := 0;
        DtldCVLedgerEntryBuffer.FindSet();
        while not ExtractedFileInStream.EOS() do begin
            NoOfLinesInFile += 1;
            ExtractedFileInStream.ReadText(ActualLine);
            ExpectedLine :=
                StrSubstNo(DtldCVLedgEntryLineFormatTxt, DtldCVLedgerEntryBuffer."Entry No.", DtldCVLedgerEntryBuffer."CV Ledger Entry No.",
                DtldCVLedgerEntryBuffer."Entry Type", Format(DtldCVLedgerEntryBuffer."Posting Date", 10, '<day,2>.<month,2>.<year4>'));
            Assert.AreEqual(ExpectedLine, ActualLine, '');
            DtldCVLedgerEntryBuffer.Next();
        end;
        Assert.AreEqual(NoOfCVLedgerEntries, NoOfLinesInFile, '');
    end;

    local procedure VerifyDTDFileNameInIndexXML(ExportPath: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        ExtractedFileOutStream: OutStream;
        ExtractedFileInStream: InStream;
        DataLine: Text;
        ExpectedSubstring: Text;
    begin
        TempBlob.CreateOutStream(ExtractedFileOutStream);
        ExtractEntryFromZipFile(ExportPath, IndexFileTxt, ExtractedFileOutStream);
        TempBlob.CreateInStream(ExtractedFileInStream);

        ExtractedFileInStream.ReadText(DataLine);
        ExtractedFileInStream.ReadText(DataLine);
        ExpectedSubstring := 'SYSTEM "' + DefaultDTDFileTxt + '"';
        Assert.AreNotEqual(0, StrPos(DataLine, ExpectedSubstring), StrSubstNo(DTDMissedInDocTypeSectionErr, ExpectedSubstring));
    end;

    local procedure VerifyElementCountInIndexXML(ZipFilePath: Text; ElementName: Text; ExpectedCount: Integer)
    var
        TempBlob: Codeunit "Temp Blob";
        ExtractedFileOutStream: OutStream;
        ExtractedFileInStream: InStream;
        ActualCount: Integer;
        XmlText: Text;
        DataLine: Text;
    begin
        TempBlob.CreateOutStream(ExtractedFileOutStream);
        ExtractEntryFromZipFile(ZipFilePath, IndexFileTxt, ExtractedFileOutStream);
        TempBlob.CreateInStream(ExtractedFileInStream, TEXTENCODING::UTF8);
        while NOT ExtractedFileInStream.EOS do begin
            ExtractedFileInStream.ReadText(DataLine);
            XmlText += DataLine;
        end;
        LibraryXMLRead.InitializeFromXmlText(XmlText);
        ActualCount := LibraryXMLRead.GetNodesCount(ElementName);
        Assert.AreEqual(ExpectedCount, ActualCount, StrSubstNo(WrongCountOfElementsErr, ElementName));
    end;

    local procedure VerifyElementValueInIndexXML(ZipFilePath: Text; ElementName: Text; NodeName: Text; ExpectedName: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        ExtractedFileOutStream: OutStream;
        ExtractedFileInStream: InStream;
        XmlText: Text;
        DataLine: Text;
    begin
        TempBlob.CreateOutStream(ExtractedFileOutStream);
        ExtractEntryFromZipFile(ZipFilePath, IndexFileTxt, ExtractedFileOutStream);
        TempBlob.CreateInStream(ExtractedFileInStream, TEXTENCODING::UTF8);
        while not ExtractedFileInStream.EOS do begin
            ExtractedFileInStream.READTEXT(DataLine);
            XmlText += DataLine;
        end;
        LibraryXMLRead.InitializeFromXmlText(XmlText);
        Assert.AreEqual(
          ExpectedName, LibraryXMLRead.GetFirstElementValueFromNode(ElementName, NodeName),
          StrSubstNo(WrongElementValueErr, NodeName, ElementName));
    end;

    local procedure VerifyGLAccountBusinessDataExport(ZipFilePath: Text; FileName: Text; Amount: Decimal)
    var
        TempBlob: Codeunit "Temp Blob";
        ExtractedFileOutStream: OutStream;
        ExtractedFileInStream: InStream;
        DataLine: Text;
        ActualAmount: Decimal;
    begin
        TempBlob.CreateOutStream(ExtractedFileOutStream);
        ExtractEntryFromZipFile(ZipFilePath, FileName, ExtractedFileOutStream);
        TempBlob.CreateInStream(ExtractedFileInStream);
        ExtractedFileInStream.ReadText(DataLine);
        while StrPos(DataLine, ';') > 0 do
            DataLine := CopyStr(DataLine, StrPos(DataLine, ';') + 1);

        Evaluate(ActualAmount, DataLine);
        Assert.AreEqual(Amount, ActualAmount, WrongValueErr);
    end;

    local procedure GetExportFieldName(DataExportRecordSource: Record "Data Export Record Source"; FieldIndexNo: Integer; var Name: array[2] of Text)
    var
        DataExpRecField: Record "Data Export Record Field";
        Index: Integer;
    begin
        Clear(Name);
        Index := 0;
        DataExpRecField.SetRange("Data Export Code", DataExportRecordSource."Data Export Code");
        DataExpRecField.SetRange("Data Exp. Rec. Type Code", DataExportRecordSource."Data Exp. Rec. Type Code");
        DataExpRecField.SetRange("Table No.", DataExportRecordSource."Table No.");
        DataExpRecField.FindSet();
        repeat
            Index += 1;
            if FieldIndexNo = Index then begin
                DataExpRecField.CalcFields("Field Name");
                Name[1] := DataExpRecField."Field Name";
                Name[2] := DataExpRecField."Export Field Name";
            end;
        until DataExpRecField.Next() = 0;
    end;

    local procedure PrepareEmptyBusinessDataToExport(var DataExportRecord: Record "Data Export Record Definition")
    var
        DataExportRecordSource: Record "Data Export Record Source";
        Customer: Record Customer;
    begin
        CreateRecDefinition(DataExportRecord);
        AddRecordSourceWithFilters(
          DataExportRecord, CustomerTableNo(),
          Customer.TableName + ': ' + Customer.FieldName("No.") + '=' + LibraryUtility.GenerateGUID(), DataExportRecordSource);
    end;

    local procedure ExportMinBusinessData(var DataExportRecord: Record "Data Export Record Definition"): Text
    var
        DataExportRecordSource: Record "Data Export Record Source";
    begin
        exit(ExportDtldMinBusinessData(DataExportRecord, DataExportRecordSource));
    end;

    local procedure ExportDtldMinBusinessData(var DataExportRecord: Record "Data Export Record Definition"; var DataExportRecordSource: Record "Data Export Record Source"): Text
    begin
        SetupParentTableForExport(DataExportRecord, DataExportRecordSource);
        InsertParentEntry();
        exit(ExportBusinessData(DataExportRecord));
    end;

    local procedure ExportBusinessData(DataExportRecord: Record "Data Export Record Definition"): Text
    begin
        exit(ExportBusinessDataSetPeriod(DataExportRecord, WorkDate(), WorkDate()));
    end;

    local procedure ExportBusinessDataSetPeriod(var DataExportRecord: Record "Data Export Record Definition"; StartDate: Date; EndDate: Date) ZipFileName: Text
    var
        ExportBusData: Report "Export Business Data";
        LibraryFileMgtHandler: Codeunit "Library - File Mgt Handler";
        DummyFileName: Text;
    begin
        LibraryFileMgtHandler.SetDownloadSubscriberActivated(true);
        LibraryFileMgtHandler.SetSaveFileActivated(true);
        BindSubscription(LibraryFileMgtHandler);

        DummyFileName := LibraryUtility.GenerateGUID();
        ExportBusData.InitializeRequest(StartDate, EndDate);
        ExportBusData.SetClientFileName(DummyFileName);
        ExportBusData.UseRequestPage(false);
        DataExportRecord.SetRecFilter();
        ExportBusData.SetTableView(DataExportRecord);
        ExportBusData.Run();

        UnbindSubscription(LibraryFileMgtHandler);
        ZipFileName := LibraryFileMgtHandler.GetServerTempFileName();
    end;

    local procedure ExportBusinessDataSetBlobSize(var DataExportRecord: Record "Data Export Record Definition"; BlobMaxSizeThreshold: Integer) ZipFileName: Text
    var
        ExportBusData: Report "Export Business Data";
        LibraryFileMgtHandler: Codeunit "Library - File Mgt Handler";
        DummyFileName: Text;
    begin
        LibraryFileMgtHandler.SetDownloadSubscriberActivated(true);
        LibraryFileMgtHandler.SetSaveFileActivated(true);
        BindSubscription(LibraryFileMgtHandler);

        DummyFileName := LibraryUtility.GenerateGUID();
        ExportBusData.InitializeRequest(WorkDate(), WorkDate());
        ExportBusData.SetClientFileName(DummyFileName);
        ExportBusData.UseRequestPage(false);
        DataExportRecord.SetRecFilter();
        ExportBusData.SetTableView(DataExportRecord);
        ExportBusData.InitializeBlobMaxSizeThreshold(BlobMaxSizeThreshold);
        ExportBusData.Run();

        UnbindSubscription(LibraryFileMgtHandler);
        ZipFileName := LibraryFileMgtHandler.GetServerTempFileName();
    end;

    local procedure RunExportBusinessDataZipStreamOutput(DataExportRecDef: Record "Data Export Record Definition")
    var
        ExportBusinessData: Report "Export Business Data";
    begin
        Commit();
        DataExportRecDef.SetRecFilter();
        ExportBusinessData.SetTableView(DataExportRecDef);
        ExportBusinessData.SetClientFileName('');
        ExportBusinessData.UseRequestPage(false);
        ExportBusinessData.Run();
    end;

    local procedure InitializeFlowFieldScenario(var DataExportRecord: Record "Data Export Record Definition"; var DataExportRecordSource: Record "Data Export Record Source"; var Customer: Record Customer; DateFilterHandling: Option " ",Period,"End Date Only","Start Date Only")
    var
        Customers: array[5] of Record Customer;
        LibrarySales: Codeunit "Library - Sales";
        CustFilter: Text[250];
        BalanceDate: Date;
        i: Integer;
    begin
        for i := 1 to 5 do begin
            LibrarySales.CreateCustomer(Customers[i]);
            if CustFilter <> '' then
                CustFilter := CustFilter + '|';
            CustFilter := CustFilter + Customers[i]."No."
        end;

        if DateFilterHandling = DateFilterHandling::"Start Date Only" then
            BalanceDate := CalcDate('<-1M>', WorkDate())
        else
            BalanceDate := WorkDate();

        // Two of the customers must have positive balance in the specified period, 2 - outside of period dates
        for i := 2 to 5 do
            InsertCustLedgEntry(Customers[i]."No.", BalanceDate - Sign(i - 3.5) * LibraryRandom.RandInt(30));

        Customer.SetFilter("No.", CustFilter);
        Customer.SetRange("Date Filter", CalcDate('<-1M>', BalanceDate), BalanceDate);

        CreateRecDefinition(DataExportRecord);
        AddRecordSourceWithDateFilterHandling(
          DataExportRecord,
          CustomerTableNo(),
          Customer.FieldNo("Net Change"),
          DateFilterHandling,
          DataExportRecordSource);
    end;

    local procedure InsertCustLedgEntry(CustNo: Code[20]; PostingDate: Date)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        DetCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        NextEntryNo: Integer;
    begin
        if CustLedgEntry.FindLast() then
            NextEntryNo := CustLedgEntry."Entry No." + 1
        else
            NextEntryNo := 1;

        CustLedgEntry.Init();
        CustLedgEntry."Entry No." := NextEntryNo;
        CustLedgEntry."Customer No." := CustNo;
        CustLedgEntry."Posting Date" := PostingDate;
        CustLedgEntry.Insert();

        if DetCustLedgEntry.FindLast() then
            NextEntryNo := DetCustLedgEntry."Entry No." + 1
        else
            NextEntryNo := 1;

        DetCustLedgEntry.Init();
        DetCustLedgEntry."Entry No." := NextEntryNo;
        DetCustLedgEntry."Customer No." := CustNo;
        DetCustLedgEntry."Posting Date" := PostingDate;
        DetCustLedgEntry.Amount := LibraryRandom.RandDec(10000, 2);
        DetCustLedgEntry."Cust. Ledger Entry No." := CustLedgEntry."Entry No.";
        DetCustLedgEntry.Insert();
    end;

    local procedure ReadCustomersFromDataFile(ZipFilePath: Text; ExportedFileName: Text; var Customer: Record Customer temporary)
    var
        TempBlob: Codeunit "Temp Blob";
        ExtractedFileOutStream: OutStream;
        ExtractedFileInStream: InStream;
        DataLine: Text;
    begin
        TempBlob.CreateOutStream(ExtractedFileOutStream);
        ExtractEntryFromZipFile(ZipFilePath, ExportedFileName, ExtractedFileOutStream);
        TempBlob.CreateInStream(ExtractedFileInStream);
        while not ExtractedFileInStream.EOS do begin
            ExtractedFileInStream.ReadText(DataLine);
            if StrPos(DataLine, ';') > 0 then
                Customer."No." := DelChr(CopyStr(DataLine, 1, StrPos(DataLine, ';') - 1), '<>', '"')
            else
                Customer."No." := DataLine;
            Customer.Insert();
        end;
    end;

    local procedure ReadCustomersWithNetChangeFromDataFile(ZipFilePath: Text; ExportedFileName: Text; var CustBuffer: Record "Budget Buffer" temporary)
    var
        TempBlob: Codeunit "Temp Blob";
        ExtractedFileOutStream: OutStream;
        ExtractedFileInStream: InStream;
        DataLine: Text;
    begin
        TempBlob.CreateOutStream(ExtractedFileOutStream);
        ExtractEntryFromZipFile(ZipFilePath, ExportedFileName, ExtractedFileOutStream);
        TempBlob.CreateInStream(ExtractedFileInStream);
        while not ExtractedFileInStream.EOS do begin
            ExtractedFileInStream.ReadText(DataLine);
            if StrPos(DataLine, ';') > 0 then begin
                CustBuffer."G/L Account No." := DelChr(CopyStr(DataLine, 1, StrPos(DataLine, ';') - 1), '<>', '"');
                Evaluate(CustBuffer.Amount, DelChr(CopyStr(DataLine, StrPos(DataLine, ';') + 1, StrLen(DataLine)), '<>', '"'));
            end else
                CustBuffer."G/L Account No." := DataLine;
            CustBuffer.Insert();
        end;
    end;

    local procedure ReadCustomersWithTwoDecFieldsFromDateFile(ZipFilePath: Text; ExportedFileName: Text; var CustBuffer: Record "Aging Band Buffer")
    var
        TempBlob: Codeunit "Temp Blob";
        ExtractedFileOutStream: OutStream;
        ExtractedFileInStream: InStream;
        DataLine: Text;
    begin
        TempBlob.CreateOutStream(ExtractedFileOutStream);
        ExtractEntryFromZipFile(ZipFilePath, ExportedFileName, ExtractedFileOutStream);
        TempBlob.CreateInStream(ExtractedFileInStream);
        while not ExtractedFileInStream.EOS do begin
            ExtractedFileInStream.ReadText(DataLine);
            if StrPos(DataLine, ';') > 0 then begin
                CustBuffer."Currency Code" := DelChr(CopyStr(DataLine, 1, StrPos(DataLine, ';') - 1), '<>', '"');
                DataLine := CopyStr(DataLine, StrPos(DataLine, ';') + 1, StrLen(DataLine));
                Evaluate(CustBuffer."Column 1 Amt.", DelChr(CopyStr(DataLine, 1, StrPos(DataLine, ';') - 1), '<>', '"'));
                Evaluate(CustBuffer."Column 2 Amt.", DelChr(CopyStr(DataLine, StrPos(DataLine, ';') + 1, StrLen(DataLine)), '<>', '"'));
            end else
                CustBuffer."Currency Code" := DataLine;
            CustBuffer.Insert();
        end;
    end;

    local procedure RollBackCompanyInformation(CompanyInformation: Record "Company Information")
    var
        CompanyInformation2: Record "Company Information";
    begin
        CompanyInformation2.Get();
        CompanyInformation2.Name := CompanyInformation.Name;
        CompanyInformation2."Name 2" := CompanyInformation."Name 2";
        CompanyInformation2.Address := CompanyInformation.Address;
        CompanyInformation2."Address 2" := CompanyInformation."Address 2";
        CompanyInformation2."Bank Name" := CompanyInformation."Bank Name";
        CompanyInformation2."Ship-to Name" := CompanyInformation."Ship-to Name";
        CompanyInformation2."Ship-to Name 2" := CompanyInformation."Ship-to Name 2";
        CompanyInformation2."Ship-to Address" := CompanyInformation."Ship-to Address";
        CompanyInformation2."Ship-to Address 2" := CompanyInformation."Ship-to Address 2";
        CompanyInformation2."Ship-to Contact" := CompanyInformation."Ship-to Contact";
        CompanyInformation2."Custom System Indicator Text" := CompanyInformation."Custom System Indicator Text";
        CompanyInformation2."Tax Office Name" := CompanyInformation."Tax Office Name";
        CompanyInformation2."Tax Office Name 2" := CompanyInformation."Tax Office Name 2";
        CompanyInformation2.Modify();
    end;

    local procedure CalcNetChangeWithDim(var Customer: Record Customer): Decimal
    var
        DetailledCustLedgEnrty: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailledCustLedgEnrty.SetRange("Posting Date", Customer.GetRangeMin("Date Filter"), Customer.GetRangeMax("Date Filter"));
        DetailledCustLedgEnrty.SetRange("Customer No.", Customer."No.");
        DetailledCustLedgEnrty.SetRange("Initial Entry Global Dim. 1", Customer."Global Dimension 1 Code");
        DetailledCustLedgEnrty.CalcSums(Amount);
        exit(DetailledCustLedgEnrty.Amount);
    end;

    local procedure CalcNetChange(var Customer: Record Customer): Decimal
    var
        DetailledCustLedgEnrty: Record "Detailed Cust. Ledg. Entry";
    begin
        if StrPos(Customer.GetFilter("Date Filter"), '..') = 1 then
            DetailledCustLedgEnrty.SetRange("Posting Date", 0D, Customer.GetRangeMax("Date Filter"))
        else
            DetailledCustLedgEnrty.SetRange("Posting Date", Customer.GetRangeMin("Date Filter"), Customer.GetRangeMax("Date Filter"));
        DetailledCustLedgEnrty.SetRange("Customer No.", Customer."No.");
        DetailledCustLedgEnrty.CalcSums(Amount);
        exit(DetailledCustLedgEnrty.Amount);
    end;

    local procedure CheckBuffValues(var Customer: Record Customer; TableNo: Integer; FieldNo: Integer)
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.Open(TableNo);
        FieldRef := RecRef.Field(FieldNo);
        RecRef.FindSet();
        repeat
            Customer.Get(RecRef.Field(1).Value());
            Assert.AreEqual(
              CalcNetChange(Customer), FieldRef.Value(), FlowFilterRecExportErr)
        until RecRef.Next() = 0;
    end;

    local procedure VerifyBusinessDataExport(ZipFilePath: Text; FileName: Text; var Customer: Record Customer)
    var
        TempCustBuffer: Record "Budget Buffer" temporary;
    begin
        ReadCustomersWithNetChangeFromDataFile(ZipFilePath, FileName, TempCustBuffer);
        TempCustBuffer.FindSet();
        repeat
            Customer.Get(TempCustBuffer."G/L Account No.");
            Customer.CalcFields("Net Change");
            Assert.AreEqual(
              Customer."Net Change", TempCustBuffer.Amount, FlowFilterRecExportErr)
        until TempCustBuffer.Next() = 0;
    end;

    local procedure VerifyFileExists(ExportPath: Text; ExportedFileName: Text)
    var
        EntryList: List of [Text];
        ZipFile: File;
        ZipInStream: InStream;
    begin
        ZipFile.Open(ExportPath);
        ZipFile.CreateInStream(ZipInStream);
        DataCompression.OpenZipArchive(ZipInStream, false);
        DataCompression.GetEntryList(EntryList);
        DataCompression.CloseZipArchive();
        ZipFile.Close();
        if ExportedFileName <> '' then
            Assert.IsTrue(EntryList.Contains(ExportedFileName), StrSubstNo(CannotFindFileErr, ExportedFileName));
    end;

    local procedure VerifyFileIsEmpty(ExportPath: Text; ExportedFileName: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        ExtractedFileOutStream: OutStream;
        ExtractedFileInStream: InStream;
        DataLine: Text;
    begin
        TempBlob.CreateOutStream(ExtractedFileOutStream);
        ExtractEntryFromZipFile(ExportPath, ExportedFileName, ExtractedFileOutStream);
        TempBlob.CreateInStream(ExtractedFileInStream);
        ExtractedFileInStream.ReadText(DataLine);
        Assert.AreEqual('', DataLine, StrSubstNo(EmptyFileErr, ExportedFileName));
    end;

    local procedure VerifyCustNetChangeExport(ZipFilePath: Text; FileName: Text; var Customer: Record Customer)
    var
        TempCustBuffer: Record "Budget Buffer" temporary;
    begin
        ReadCustomersWithNetChangeFromDataFile(ZipFilePath, FileName, TempCustBuffer);
        TempCustBuffer.FindSet();
        repeat
            Customer.Get(TempCustBuffer."G/L Account No.");
            Assert.AreEqual(
              CalcNetChangeWithDim(Customer), TempCustBuffer.Amount, FlowFilterRecExportErr)
        until TempCustBuffer.Next() = 0;
    end;

    local procedure VerifyCustNetChangeTwoValuesExport(ZipFilePath: Text; FileName: Text; DateFrom: Date; DateTo: Date)
    var
        TempCustBuffer: Record "Aging Band Buffer";
        Cust: Record Customer;
    begin
        ReadCustomersWithTwoDecFieldsFromDateFile(ZipFilePath, FileName, TempCustBuffer);

        Cust.SetFilter("Date Filter", Format(DateFrom) + '..' + Format(DateTo));
        CheckBuffValues(Cust, TempCustBuffTableNo(), 2);

        Cust.SetFilter("Date Filter", '..' + Format(DateTo));
        CheckBuffValues(Cust, TempCustBuffTableNo(), 3);
    end;

    local procedure Sign(Num: Decimal): Integer
    begin
        if Num >= 0 then
            exit(1);

        exit(-1);
    end;

    local procedure ValidateLogFile(FileName: Text; TableLineNo: Integer; TableName: Text; ExportedRecords: Integer)
    var
        TempBlob: Codeunit "Temp Blob";
        ExtractedFileOutStream: OutStream;
        ExtractedFileInStream: InStream;
        DataLine: Text;
        ExpectedSubStr: Text;
        i: Integer;
    begin
        TempBlob.CreateOutStream(ExtractedFileOutStream);
        ExtractEntryFromZipFile(FileName, LogFileTxt, ExtractedFileOutStream);
        TempBlob.CreateInStream(ExtractedFileInStream);

        for i := 1 to 3 + TableLineNo do
            ExtractedFileInStream.ReadText(DataLine);

        ExpectedSubStr := StrSubstNo(LogFileLineTxt, TableName, ExportedRecords);
        Assert.AreNotEqual(0, StrPos(DataLine, ExpectedSubStr), StrSubstNo(LogFileErr, ExpectedSubStr));
    end;

    local procedure ValidateExportedDataFile(ZipFilePath: Text; FileName: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        ExtractedFileOutStream: OutStream;
        ExtractedFileInStream: InStream;
        DataLine: Text;
    begin
        TempBlob.CreateOutStream(ExtractedFileOutStream);
        ExtractEntryFromZipFile(ZipFilePath, FileName, ExtractedFileOutStream);
        TempBlob.CreateInStream(ExtractedFileInStream);
        ExtractedFileInStream.ReadText(DataLine);
        Assert.IsTrue(StrLen(DataLine) > 1024, ValueErr);
    end;

    local procedure VerifyPeriodInLogFile(FileName: Text; DateFrom: Date; DateTo: Date)
    var
        TempBlob: Codeunit "Temp Blob";
        ExtractedFileOutStream: OutStream;
        ExtractedFileInStream: InStream;
        DataLine: Text;
    begin
        TempBlob.CreateOutStream(ExtractedFileOutStream);
        ExtractEntryFromZipFile(FileName, LogFileTxt, ExtractedFileOutStream);
        TempBlob.CreateInStream(ExtractedFileInStream);
        ExtractedFileInStream.ReadText(DataLine);

        Assert.IsTrue(StrPos(DataLine, Format(DateFrom)) = 1, StrSubstNo(WrongPeriodErr, Format(DateFrom), DataLine));
        Assert.IsFalse(StrPos(DataLine, Format(DateTo)) = 0, StrSubstNo(WrongPeriodErr, Format(DateTo), DataLine));
    end;

    local procedure VerifyDurationInLogFile(FileName: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        ExtractedFileOutStream: OutStream;
        ExtractedFileInStream: InStream;
        DataLine: Text;
        Duration: Duration;
        DurationValueText: Text;
    begin
        TempBlob.CreateOutStream(ExtractedFileOutStream);
        ExtractEntryFromZipFile(FileName, LogFileTxt, ExtractedFileOutStream);
        TempBlob.CreateInStream(ExtractedFileInStream);
        while not ExtractedFileInStream.EOS do
            ExtractedFileInStream.ReadText(DataLine);

        DurationValueText :=
          CopyStr(DataLine, StrLen(DurationTxt) + 1, StrLen(DataLine) - StrLen(DurationTxt) - 1);
        Assert.IsTrue(Evaluate(Duration, DurationValueText), DurationErr);
    end;

    local procedure ValidateTablesNumberInLog(FileName: Text; ExpectedAmt: Integer)
    var
        TempBlob: Codeunit "Temp Blob";
        ExtractedFileOutStream: OutStream;
        ExtractedFileInStream: InStream;
        DataLine: Text;
        ActualAmt: Integer;
        i: Integer;
    begin
        TempBlob.CreateOutStream(ExtractedFileOutStream);
        ExtractEntryFromZipFile(FileName, LogFileTxt, ExtractedFileOutStream);
        TempBlob.CreateInStream(ExtractedFileInStream);
        for i := 1 to 6 do
            ExtractedFileInStream.ReadText(DataLine);

        DataLine := DelChr(CopyStr(DataLine, StrPos(DataLine, ':') + 1, StrLen(DataLine)), '<>');
        Evaluate(ActualAmt, DataLine);
        Assert.AreEqual(ExpectedAmt, ActualAmt, WrongTablesNumberErr);
    end;

    local procedure VerifyRelatedTablesExportFile(ZipFilePath: Text; FileName: Text; var Customer: Record Customer)
    var
        TempCust: Record Customer temporary;
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry.SetFilter("Posting Date", Customer.GetFilter("Date Filter"));
        ReadCustomersFromDataFile(ZipFilePath, FileName, TempCust);
        Customer.FindFirst();
        repeat
            CustLedgEntry.SetRange("Customer No.", Customer."No.");
            if CustLedgEntry.FindSet() then
                repeat
                    TempCust.SetRange("No.", Format(CustLedgEntry."Entry No."));
                    Assert.IsFalse(TempCust.IsEmpty, IncorrectNoOfRelatedRecsErr);
                until CustLedgEntry.Next() = 0;
        until Customer.Next() = 0;

        CustLedgEntry.SetFilter("Customer No.", Customer.GetFilter("No."));
        TempCust.Reset();
        TempCust.FindSet();
        repeat
            CustLedgEntry.SetFilter("Entry No.", TempCust."No.");
            Assert.IsFalse(CustLedgEntry.IsEmpty, IncorrectNoOfRelatedRecsErr);
        until TempCust.Next() = 0;
    end;

    local procedure VerifyRecFieldsDeleted(var DataExportRecord: Record "Data Export Record Definition"; TableNo: Integer)
    var
        DataExportRecField: Record "Data Export Record Field";
    begin
        DataExportRecField.SetRange("Data Export Code", DataExportRecord."Data Export Code");
        DataExportRecField.SetRange("Data Exp. Rec. Type Code", DataExportRecord."Data Exp. Rec. Type Code");
        DataExportRecField.SetRange("Table No.", TableNo);
        Assert.IsTrue(DataExportRecField.IsEmpty, NotAllRecFieldsDeletedErr);
    end;

    local procedure VerifyRelatedTablesDeleted(var DataExportRecord: Record "Data Export Record Definition"; ParentTableNo: Integer; ParentSourceLineNo: Integer)
    var
        DataExportRecordSource: Record "Data Export Record Source";
        DataExportTableRelation: Record "Data Export Table Relation";
    begin
        DataExportRecordSource.SetRange("Data Export Code", DataExportRecord."Data Export Code");
        DataExportRecordSource.SetRange("Data Exp. Rec. Type Code", DataExportRecord."Data Exp. Rec. Type Code");
        DataExportRecordSource.SetRange("Relation To Line No.", ParentSourceLineNo);
        Assert.IsTrue(DataExportRecordSource.IsEmpty, NotAllReleatedTablesDeletedErr);

        DataExportTableRelation.SetRange("Data Export Code", DataExportRecord."Data Export Code");
        DataExportTableRelation.SetRange("Data Exp. Rec. Type Code", DataExportRecord."Data Exp. Rec. Type Code");
        DataExportTableRelation.SetRange("From Table No.", ParentTableNo);
        Assert.IsTrue(DataExportTableRelation.IsEmpty, NotAllReleatedTablesDeletedErr);
    end;

    local procedure UpdateValuesInCompanyInformation(var CompanyInformation: Record "Company Information")
    begin
        CompanyInformation.Get();
        CompanyInformation.Name := GenerateRandomCode(100);
        CompanyInformation."Name 2" := GenerateRandomCode(50);
        CompanyInformation.Address := GenerateRandomCode(100);
        CompanyInformation."Address 2" := GenerateRandomCode(50);
        CompanyInformation."Bank Name" := GenerateRandomCode(100);
        CompanyInformation."Ship-to Name" := GenerateRandomCode(100);
        CompanyInformation."Ship-to Name 2" := GenerateRandomCode(50);
        CompanyInformation."Ship-to Address" := GenerateRandomCode(100);
        CompanyInformation."Ship-to Address 2" := GenerateRandomCode(50);
        CompanyInformation."Ship-to Contact" := GenerateRandomCode(100);
        CompanyInformation."Custom System Indicator Text" := GenerateRandomCode(240);
        CompanyInformation."Tax Office Name" := GenerateRandomCode(50);
        CompanyInformation."Tax Office Name 2" := GenerateRandomCode(50);
        CompanyInformation.Modify();
    end;

    local procedure ParentTableNo(): Integer
    begin
        exit(DATABASE::"CV Ledger Entry Buffer");
    end;

    local procedure ChildTableNo(): Integer
    begin
        exit(DATABASE::"Detailed CV Ledg. Entry Buffer");
    end;

    local procedure CustomerTableNo(): Integer
    begin
        exit(DATABASE::Customer);
    end;

    local procedure VendorTableNo(): Integer
    begin
        exit(DATABASE::Vendor);
    end;

    local procedure ItemTableNo(): Integer
    begin
        exit(DATABASE::Item);
    end;

    local procedure GLAccTableNo(): Integer
    begin
        exit(DATABASE::"G/L Account");
    end;

    local procedure CustLedgEntryTableNo(): Integer
    begin
        exit(DATABASE::"Cust. Ledger Entry");
    end;

    local procedure VendLedgEntryTableNo(): Integer
    begin
        exit(DATABASE::"Vendor Ledger Entry");
    end;

    local procedure ItemLedgEntryTableNo(): Integer
    begin
        exit(DATABASE::"Item Ledger Entry");
    end;

    local procedure GLEntryTableNo(): Integer
    begin
        exit(DATABASE::"G/L Entry");
    end;

    local procedure VATEntryTableNo(): Integer
    begin
        exit(DATABASE::"VAT Entry");
    end;

    local procedure TempCustBuffTableNo(): Integer
    begin
        exit(DATABASE::"Aging Band Buffer");
    end;

    local procedure CompanyInfoTableNo(): Integer
    begin
        exit(DATABASE::"Company Information");
    end;

    local procedure CreateDummyDTDFileBlob(var DataExportRecord: Record "Data Export Record Definition")
    begin
        DataExportRecord."DTD File Name" := DefaultDTDFileTxt;
        DataExportRecord.Modify();
    end;

    local procedure CreateDataExportOfCompanyInformation(var DataExportRecordDefinition: Record "Data Export Record Definition"): Text
    var
        DataExportRecordSource: Record "Data Export Record Source";
    begin
        CreateRecDefinition(DataExportRecordDefinition);
        AddRecordSourceWithFields(DataExportRecordDefinition, CompanyInfoTableNo(), DataExportRecordSource);
        exit(DataExportRecordSource."Export File Name");
    end;

    local procedure GenerateRandomCode(NumberOfDigit: Integer) CharLength: Text
    var
        Counter: Integer;
    begin
        for Counter := 1 to NumberOfDigit do
            CharLength := InsStr(CharLength, Format(LibraryRandom.RandInt(9)), Counter);
    end;

    local procedure LinkFieldToSourceRecord(DataExportRecordSource: Record "Data Export Record Source"; FieldId: Integer)
    var
        DataExportRecField: Record "Data Export Record Field";
    begin
        DataExportRecField."Data Export Code" := DataExportRecordSource."Data Export Code";
        DataExportRecField."Data Exp. Rec. Type Code" := DataExportRecordSource."Data Exp. Rec. Type Code";
        DataExportRecField."Table No." := DataExportRecordSource."Table No.";
        DataExportRecField."Source Line No." := DataExportRecordSource."Line No.";
        DataExportRecField."Line No." := DataExportRecField."Line No." + 10000;
        DataExportRecField."Field No." := FieldId;
        DataExportRecField."Export Field Name" := 'F' + Format(DataExportRecField."Field No.");
        DataExportRecField.Insert();
    end;

    local procedure ValidateExportedDataFromFileFile(ZipFilePath: Text; FileName: Text; Value: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        ExtractedFileOutStream: OutStream;
        ExtractedFileInStream: InStream;
        DataLine: Text;
    begin
        TempBlob.CreateOutStream(ExtractedFileOutStream);
        ExtractEntryFromZipFile(ZipFilePath, FileName, ExtractedFileOutStream);
        TempBlob.CreateInStream(ExtractedFileInStream, TEXTENCODING::UTF8);
        ExtractedFileInStream.ReadText(DataLine);
        Assert.AreEqual(Format(DataLine), Value, WrongValueErr);
    end;

    local procedure ValidateExportedFieldDataFromFileFile(ZipFilePath: Text; FileName: Text; Value: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        ExtractedFileOutStream: OutStream;
        ExtractedFileInStream: InStream;
        DataLine: Text;
    begin
        TempBlob.CreateOutStream(ExtractedFileOutStream);
        ExtractEntryFromZipFile(ZipFilePath, FileName, ExtractedFileOutStream);
        TempBlob.CreateInStream(ExtractedFileInStream, TEXTENCODING::UTF8);
        ExtractedFileInStream.ReadText(DataLine);
        Assert.AreNotEqual(0, StrPos(DataLine, Value), WrongValueErr);
    end;

    local procedure ValidateOptionValueFromFile(ZipFilePath: Text; FileName: Text; OptionValue: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        ExtractedFileOutStream: OutStream;
        ExtractedFileInStream: InStream;
        TextLine: Text;
    begin
        TempBlob.CreateOutStream(ExtractedFileOutStream);
        ExtractEntryFromZipFile(ZipFilePath, FileName, ExtractedFileOutStream);
        TempBlob.CreateInStream(ExtractedFileInStream, TEXTENCODING::UTF8);
        ExtractedFileInStream.ReadText(TextLine);
        Assert.IsTrue(StrPos(TextLine, ';"' + OptionValue + '"') > 0, OptionValueErr);
    end;

    local procedure VerifyCountOfExportedRecords(ZipFilePath: Text; FileName: Text; ExpectedNoOfRecords: Integer)
    var
        TempBlob: Codeunit "Temp Blob";
        ExtractedFileOutStream: OutStream;
        ExtractedFileInStream: InStream;
        DataLine: Text;
        ActualNoOfLines: Integer;
    begin
        TempBlob.CreateOutStream(ExtractedFileOutStream);
        ExtractEntryFromZipFile(ZipFilePath, FileName, ExtractedFileOutStream);
        TempBlob.CreateInStream(ExtractedFileInStream, TEXTENCODING::UTF8);
        while not ExtractedFileInStream.EOS do begin
            ExtractedFileInStream.ReadText(DataLine);
            ActualNoOfLines += 1;
        end;
        Assert.AreEqual(ExpectedNoOfRecords, ActualNoOfLines, WrongNoOfLinesExportedErr)
    end;

    local procedure SetCompanyInformationCheckAvailTimeBucketValue(var NewValue: Integer; OverMaxValue: Integer) OldValue: Enum "Analysis Period Type"
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        OldValue := CompanyInformation."Check-Avail. Time Bucket";
        NewValue :=
          LibraryUtility.GetMaxFieldOptionIndex(
            CompanyInfoTableNo(), CompanyInformation.FieldNo("Check-Avail. Time Bucket")) + OverMaxValue;
        CompanyInformation."Check-Avail. Time Bucket" := "Analysis Period Type".FromInteger(NewValue);
        CompanyInformation.Modify();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmationHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    local procedure ExtractEntryFromZipFile(ZipFilePath: Text; EntryName: Text; ExtractedEntryOutStream: OutStream);
    var
        ZipFile: File;
        ZipFileInStream: InStream;
    begin
        ZipFile.Open(ZipFilePath);
        ZipFile.CreateInStream(ZipFileInStream);
        DataCompression.OpenZipArchive(ZipFileInStream, false);
        DataCompression.ExtractEntry(EntryName, ExtractedEntryOutStream);
        DataCompression.CloseZipArchive();
        ZipFile.Close();
    end;
}
