codeunit 144042 "UT REP XBRLIMPORT"
{
    //  1. Purpose of this test is to verify error for blank Current Period(CP) Starting Date.
    //  2. Purpose of this test is to verify error for blank Current Period(CP) Ending Date.
    //  3. Purpose of this test is to verify error for blank Comparative Period Starting Date when Ending Date is filled in.
    //  4. Purpose of this test is to verify error for blank Comparative Period Ending Date when Starting Date is filled in.
    //  5. Purpose of this test is to verify error for blank File name.
    //  6. Purpose of this test is to verify error when Current Period(CP) Ending Date is before Starting Date.
    //  7. Purpose of this test is to verify error when Comparative Period Ending Date is before Starting Date.
    //  8. Purpose of this test is to verify error when Current Period(CP) Starting Date and Ending Date do not belong to the same fiscal year.
    //  9. Purpose of this test is to verify error when Comparative Period Starting Date and Ending Date do not belong to the same fiscal year.
    // 10. Purpose of this test is to verify error for current Starting Date is not within any valid accounting Period.
    // 11. Purpose of this test is to verify error for Comparative Starting Date is not within any valid accounting Period.
    // 12. Purpose of this test is to validate XMLFilename - OnValidate Trigger of Report 11420 - Export Financial Data to XML.
    // 13. Purpose of the test is to validate GL Account - OnAfterGetRecord Trigger of Report 11420 - Export Financial Data to XML.
    // 14. Purpose of the test is to validate GL Account 2 - OnPreDataItem Trigger of Report 11420 - Export Financial Data to XML.
    // 15. Purpose of the test is to validate GL Account - OnPreDataItem Trigger of Report 11420 - Export Financial Data to XML.
    // 
    // Covers Test Cases for WI - 342850
    // ----------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                        TFS ID
    // ----------------------------------------------------------------------------------------------------------------
    // OnPreReportExportFinDataToXMLBlankCPStartDateError                                                        155951
    // OnPreReportExportFinDataToXMLBlankCPEndDateError                                                          155952
    // OnPreReportExportFinDataToXMLBlankStartDateError                                                          155955
    // OnPreReportExportFinDataToXMLBlankEndDateError                                                            155956
    // OnPreReportExportFinDataToXMLBlankFileNameError                                                           155961
    // OnPreReportExportFinDataToXMLCurrentStartDateError                                                        155953
    // OnPreReportExportFinDataToXMLStartDateError                                                               155957
    // OnPreReportExportFinDataToXMLCPDiffFiscalYearError                                                        155954
    // OnPreReportExportFinDataToXMLDiffFiscalYearError                                                          155958
    // OnPreReportExportFinDataToXMLCPAccPeriodError, OnPreReportExportFinDataToXMLAccPeriodError
    // 
    // Covers Test Cases for WI - 342851
    // ----------------------------------------------------------------------------------------------------------------
    //  Test Function Name                                                                                       TFS ID
    // ----------------------------------------------------------------------------------------------------------------
    // OnValidateBlankXMLFileNameError                                                      155989,155990,155991,155992
    // OnAfterGetRecordGLAccountExportFinancialDataToXML                                    155970,155971,155972,155973
    // OnPreDataItemGLAccount2ExportFinancialDataToXML                                      155980,155981,155982,155983
    // OnPreDataItemGLAccountExportFinancialDataToXML                                155988,155984,155985,155986,155987

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryXMLRead: Codeunit "Library - XML Read";

    [Test]
    [HandlerFunctions('ExportFinancialDataToXMLRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportExportFinDataToXMLBlankCPStartDateError()
    begin
        // Purpose of this test is to verify error for blank Current Period(CP) Starting Date.
        Initialize();
        ExportFinancialDataToXML(0D, WorkDate(), WorkDate(), WorkDate());  // 0D for Current Period(CP) Starting Date.
    end;

    [Test]
    [HandlerFunctions('ExportFinancialDataToXMLRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportExportFinDataToXMLBlankCPEndDateError()
    begin
        // Purpose of this test is to verify error for blank Current Period(CP) Ending Date.
        Initialize();
        ExportFinancialDataToXML(WorkDate(), 0D, WorkDate(), WorkDate());  // 0D for Ending Date.
    end;

    [Test]
    [HandlerFunctions('ExportFinancialDataToXMLRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportExportFinDataToXMLBlankStartDateError()
    begin
        // Purpose of this test is to verify error for blank Comparative Period Starting Date when Ending Date is filled in.
        Initialize();
        ExportFinancialDataToXML(WorkDate(), WorkDate(), 0D, WorkDate());  // 0D for Comparative Period Starting Date.
    end;

    [Test]
    [HandlerFunctions('ExportFinancialDataToXMLEndDateRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportExportFinDataToXMLBlankEndDateError()
    begin
        // Purpose of this test is to verify error for blank Comparative Period Ending Date when Starting Date is filled in.
        Initialize();
        ExportFinancialDataToXML(WorkDate(), WorkDate(), WorkDate(), 0D);  // 0D for Comparative Period Ending Date.
    end;

    [Test]
    [HandlerFunctions('ExportFinancialDataToXMLRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportExportFinDataToXMLCPStartDateError()
    begin
        // Purpose of this test is to verify error when Current Period(CP) Ending Date is before Starting Date.
        Initialize();
        ExportFinancialDataToXML(
          CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate()), WorkDate(),
          WorkDate(), WorkDate());  // Added random days to WORKDATE for Starting Date.
    end;

    [Test]
    [HandlerFunctions('ExportFinancialDataToXMLRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportExportFinDataToXMLStartDateError()
    begin
        // Purpose of this test is to verify error when Comparative Period Ending Date is before Starting Date.
        Initialize();
        ExportFinancialDataToXML(
          WorkDate(), WorkDate(), CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate()),
          WorkDate());  // Added random days to WORKDATE for Comparative Starting Date.
    end;

    [Test]
    [HandlerFunctions('ExportFinancialDataToXMLRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportExportFinDataToXMLCPDiffFiscalYearError()
    begin
        // Purpose of this test is to verify error when Current Period(CP) Starting Date and Ending Date do not belong to the same fiscal year.
        Initialize();
        ExportFinancialDataToXML(
          CalcDate('<-' + Format(LibraryRandom.RandInt(10)) + 'Y>', WorkDate()), WorkDate(), WorkDate(),
          WorkDate());  // Subtracted random years from WORKDATE for different fiscal years.
    end;

    [Test]
    [HandlerFunctions('ExportFinancialDataToXMLRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportExportFinDataToXMLDiffFiscalYearError()
    begin
        // Purpose of this test is to verify error when Comparative Period Starting Date and Ending Date do not belong to the same fiscal year.
        Initialize();
        ExportFinancialDataToXML(
          WorkDate(), WorkDate(), CalcDate('<-1Y>', WorkDate()),
          WorkDate());  // Subtracted 1 years from WORKDATE for different fiscal years.
    end;

    [Test]
    [HandlerFunctions('ExportFinancialDataToXMLRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportExportFinDataToXMLCPAccPeriodError()
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        // Purpose of this test is to verify error for current Starting Date is not within any valid accounting Period.
        Initialize();
        AccountingPeriod.FindFirst();
        ExportFinancialDataToXML(
          CalcDate('<-' + Format(LibraryRandom.RandInt(10)) + 'Y>', AccountingPeriod."Starting Date"), WorkDate(), WorkDate(),
          WorkDate());  // Subtracted random years from Accounting Period Starting Date.

        // Exercise and Verify.
        RunAndVerifyExportFinancialDataToXML();
    end;

    [Test]
    [HandlerFunctions('ExportFinancialDataToXMLRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportExportFinDataToXMLAccPeriodError()
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        // Purpose of this test is to verify error for Comparative Starting Date is not within any valid accounting Period.
        Initialize();
        AccountingPeriod.FindFirst();
        ExportFinancialDataToXML(
          WorkDate(), WorkDate(), CalcDate('<-' + Format(LibraryRandom.RandInt(10)) + 'Y>', AccountingPeriod."Starting Date"),
          WorkDate());  // Subtracted random years from Accounting Period Starting Date.

        // Exercise and Verify.
        RunAndVerifyExportFinancialDataToXML();
    end;

    [Test]
    [HandlerFunctions('ExportFinancialDataToXMLRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGLAccountExportFinancialDataToXML()
    begin
        // Purpose of the test is to validate GL Account - OnAfterGetRecord Trigger of Report 11420 - Export Financial Data to XML.
        RunReportAndVerifyXMLData(CreateGLBudgetName(), WorkDate());
    end;

    [Test]
    [HandlerFunctions('ExportFinancialDataToXMLRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemGLAccount2ExportFinancialDataToXML()
    begin
        // Purpose of the test is to validate GL Account 2 - OnPreDataItem Trigger of Report 11420 - Export Financial Data to XML.
        RunReportAndVerifyXMLData(CreateGLBudgetName(), 0D);  // 0D for Starting Date.
    end;

    [Test]
    [HandlerFunctions('ExportFinancialDataToXMLRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemGLAccountExportFinancialDataToXML()
    begin
        // Purpose of the test is to validate GL Account - OnPreDataItem Trigger of Report 11420 - Export Financial Data to XML.
        RunReportAndVerifyXMLData('', WorkDate());  // GL Budget Name as blank.
    end;

    local procedure RunReportAndVerifyXMLData(GLBudgetName: Code[10]; StartingDate: Date)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        FileManagement: Codeunit "File Management";
        GLAccountNo: Code[20];
        FileName: Text;
    begin
        // Setup and Exercise.
        FileName := FileManagement.ServerTempFileName('xml');
        GLAccountNo := CreateGLAccountAndRunReport(GLBudgetName, StartingDate, FileName);
        GeneralLedgerSetup.Get();

        // Verify: Verify values of Account Code, Due Date, Period Start and Currency Code on Report Export Financial Data to XML.
        LibraryXMLRead.Initialize(FileName);
        LibraryXMLRead.VerifyNodeValue('AccountCode', GLAccountNo);
        LibraryXMLRead.VerifyNodeValue('DueDate', Format(WorkDate(), 0, 9));
        LibraryXMLRead.VerifyNodeValue('PeriodStart', Format(WorkDate(), 0, 9));
        LibraryXMLRead.VerifyNodeValue('CurrencyCode', GeneralLedgerSetup."LCY Code");
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"UT REP XBRLIMPORT");
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount."No." := LibraryUTUtility.GetNewCode10();
        GLAccount."Account Type" := GLAccount."Account Type"::Posting;
        GLAccount.Insert();
        exit(GLAccount."No.");
    end;

    local procedure CreateGLAccountAndRunReport(GLBudgetName: Code[10]; StartingDate: Date; FileName: Text) GLAccountNo: Code[20]
    var
        ExportFinancialDataToXML: Report "Export Financial Data to XML";
    begin
        // Setup.
        Initialize();
        GLAccountNo := CreateGLAccount();
        EnqueueValuesForExportFinancialDataToXML(
          GLAccountNo, GLBudgetName, WorkDate(), WorkDate(), StartingDate, StartingDate);

        // Exercise.
        ExportFinancialDataToXML.SetFileName(FileName);
        ExportFinancialDataToXML.Run();
    end;

    local procedure CreateGLBudgetName(): Code[10]
    var
        GLBudgetName: Record "G/L Budget Name";
    begin
        GLBudgetName.Name := LibraryUTUtility.GetNewCode10();
        GLBudgetName.Insert();
        exit(GLBudgetName.Name);
    end;

    local procedure EnqueueValuesForExportFinancialDataToXML(GLAccountNo: Code[20]; GLBudgetName: Code[10]; StartingDateCurrentPeriod: Date; EndingDateCurrentPeriod: Date; StartingDate: Date; EndingDate: Date)
    begin
        // Enqueue values for ExportFinancialDataToXMLRequestPageHandler and ExportFinancialDataToXMLEndDateRequestPageHandler.
        LibraryVariableStorage.Enqueue(GLAccountNo);
        LibraryVariableStorage.Enqueue(GLBudgetName);
        LibraryVariableStorage.Enqueue(StartingDateCurrentPeriod);
        LibraryVariableStorage.Enqueue(EndingDateCurrentPeriod);
        LibraryVariableStorage.Enqueue(StartingDate);
        LibraryVariableStorage.Enqueue(EndingDate);
    end;

    local procedure ExportFinancialDataToXML(StartingDateCurrent: Date; EndingDateCurrent: Date; StartingDate: Date; EndingDate: Date)
    begin
        // Setup.
        EnqueueValuesForExportFinancialDataToXML('', '', StartingDateCurrent, EndingDateCurrent, StartingDate, EndingDate);  // GL Account No and GL Budget name as blank.

        // Exercise and Verify.
        RunAndVerifyExportFinancialDataToXML();
    end;

    local procedure RunAndVerifyExportFinancialDataToXML()
    var
        ExportFinancialDataToXML: Report "Export Financial Data to XML";
        FileManagement: Codeunit "File Management";
    begin
        // Exercise.
        ExportFinancialDataToXML.SetFileName(FileManagement.ServerTempFileName('xml'));
        asserterror ExportFinancialDataToXML.Run();

        // Verify: Verify Actual error - "File name must be specified."
        Assert.ExpectedErrorCode('Dialog');
    end;

    local procedure SetValuesOnExportFinancialDataToXML(var ExportFinancialDataToXML: TestRequestPage "Export Financial Data to XML")
    var
        No: Variant;
        BudgetName: Variant;
        StartingDateCurrentPeriod: Variant;
        EndingDateCurrentPeriod: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(BudgetName);
        LibraryVariableStorage.Dequeue(StartingDateCurrentPeriod);
        LibraryVariableStorage.Dequeue(EndingDateCurrentPeriod);
        ExportFinancialDataToXML."G/L Account".SetFilter("No.", No);
        ExportFinancialDataToXML.StartingDate_CurrentPeriod.SetValue(StartingDateCurrentPeriod);
        ExportFinancialDataToXML.EndingDate_CurrentPeriod.SetValue(EndingDateCurrentPeriod);
        ExportFinancialDataToXML.BudgetNameOptional.SetValue(CreateGLBudgetName());
        ExportFinancialDataToXML.BudgetName.SetValue(BudgetName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ExportFinancialDataToXMLEndDateRequestPageHandler(var ExportFinancialDataToXML: TestRequestPage "Export Financial Data to XML")
    var
        StartingDateComparativePeriod: Variant;
        EndingDateComparativePeriod: Variant;
    begin
        SetValuesOnExportFinancialDataToXML(ExportFinancialDataToXML);
        LibraryVariableStorage.Dequeue(StartingDateComparativePeriod);
        LibraryVariableStorage.Dequeue(EndingDateComparativePeriod);
        ExportFinancialDataToXML.EndingDate_ComparativePeriod.SetValue(EndingDateComparativePeriod);
        ExportFinancialDataToXML.StartingDate_ComparativePeriod.SetValue(StartingDateComparativePeriod);
        ExportFinancialDataToXML.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ExportFinancialDataToXMLRequestPageHandler(var ExportFinancialDataToXML: TestRequestPage "Export Financial Data to XML")
    var
        StartingDateComparativePeriod: Variant;
        EndingDateComparativePeriod: Variant;
    begin
        SetValuesOnExportFinancialDataToXML(ExportFinancialDataToXML);
        LibraryVariableStorage.Dequeue(StartingDateComparativePeriod);
        LibraryVariableStorage.Dequeue(EndingDateComparativePeriod);
        ExportFinancialDataToXML.StartingDate_ComparativePeriod.SetValue(StartingDateComparativePeriod);
        ExportFinancialDataToXML.EndingDate_ComparativePeriod.SetValue(EndingDateComparativePeriod);
        ExportFinancialDataToXML.OK().Invoke();
    end;
}

