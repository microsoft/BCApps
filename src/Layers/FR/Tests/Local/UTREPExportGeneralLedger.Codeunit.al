codeunit 144021 "UT REP Export General Ledger"
{
    // 1 - 3. Purpose of the test is to verify error of Report ID - 10820 (Export G/L Entries to XML).
    // 
    // Covers Test Cases for WI -  344464
    // ----------------------------------------------------------------------------------------------
    // Test Function Name                                                                      TFS ID
    // ----------------------------------------------------------------------------------------------
    // OnPreDataItemStartDateExportGLEntriesToXMLError                                  151904,151903
    // OnPreDataItemEndDateExportGLEntriesToXMLError                                           151905
    // OnPreDataItemExportGLEntriesToXMLError                          151755, 151907, 1517581,151646

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [HandlerFunctions('ExportGLEntriesToXMLRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemStartDateExportGLEntriesToXMLError()
    begin
        // Purpose of the test is to verify error for Report - 10820 (Export G/L Entries to XML) with blank Starting Date.
        // Verify actual error: "You must enter a Starting Date."
        ExportGLEntriesToXMLAndVerifyError(0D, 0D);  // Starting date and Ending Date as blank.
    end;

    [Test]
    [HandlerFunctions('ExportGLEntriesToXMLRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemEndDateExportGLEntriesToXMLError()
    begin
        // Purpose of the test is to verify error for Report - 10820 (Export G/L Entries to XML) with blank Ending Date.
        // Verify actual error: "You must enter an Ending Date."
        ExportGLEntriesToXMLAndVerifyError(WorkDate(), 0D);  // Ending Date as blank.
    end;

    [Test]
    [HandlerFunctions('ExportGLEntriesToXMLRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemExportGLEntriesToXMLError()
    begin
        // Purpose of the test is to verify error for Report - 10820 (Export G/L Entries to XML).
        // Verify actual error: "There are no entries to export within the defined filter. The file was not created."
        ExportGLEntriesToXMLAndVerifyError(WorkDate(), CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));  // Take random date.
    end;

    local procedure ExportGLEntriesToXMLAndVerifyError(StartingDate: Date; EndingDate: Date)
    begin
        // Setup.
        Initialize();
        LibraryVariableStorage.Enqueue(StartingDate);  // Enqueue required for ExportGLEntriesToXMLRequestPageHandler.
        LibraryVariableStorage.Enqueue(EndingDate);  // Enqueue required for ExportGLEntriesToXMLRequestPageHandler.

        // Exercise.
        asserterror REPORT.Run(REPORT::"Export G/L Entries to XML");

        // Verify.
        Assert.ExpectedErrorCode('Dialog');
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ExportGLEntriesToXMLRequestPageHandler(var ExportGLEntriesToXML: TestRequestPage "Export G/L Entries to XML")
    var
        EndingDate: Variant;
        StartingDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(StartingDate);
        LibraryVariableStorage.Dequeue(EndingDate);
        ExportGLEntriesToXML.StartingDate.SetValue(StartingDate);
        ExportGLEntriesToXML.EndingDate.SetValue(EndingDate);
        ExportGLEntriesToXML.OK().Invoke();
    end;
}

