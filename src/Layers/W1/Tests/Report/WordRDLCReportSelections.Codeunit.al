codeunit 134775 "Word & RDLC Report Selections"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Report] [Custom Report Selection] [Statement]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        ExpectedMissingFilePathErr: Label 'Expected files to not be present in output directory. Found %1', Comment = '%1 - filename';
        ExpectedFilePathErr: Label 'Expected files as report output in temporary directory. None found. Expected file %1.', Comment = '%1 - filename.';
        NoOutputErr: Label 'No data exists for the specified report filters.';
        PlatformEmptyErr: Label 'The error, The report couldn’t be generated, because it was empty. Adjust your filters and try again.';
        BlankStartDateErr: Label 'Start Date must have a value.';
        BlankEndDateErr: Label 'End Date must have a value.';
        HandlerOptionRef: Option Update,Verify;
        LastUsedTxt: Label 'Last used options and filters';
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('StatementPDFHandler')]
    [Scope('OnPrem')]
    procedure OneCustomer_OneSelection_RDLC_Ok()
    var
        Customer: Record Customer;
        WordRDLCReportSelections: Codeunit "Word & RDLC Report Selections";
    begin
        // [FEATURE] [RDLC]
        // [SCENARIO 228763] Print customer statement report (SaveAs PDF) in case of one customer with entries, one RDLC report selections
        Initialize();
        BindSubscription(WordRDLCReportSelections);

        // [GIVEN] Report Selections setup:
        // [GIVEN] Usage = "C.Statement", Sequence = 1, Report ID = "Statement" (RDLC)
        // [GIVEN] Customer with entries
        // [WHEN] Run "Statement" (SaveAs PDF) report
        OneCustomer_OneSelection(CreateCustomerWithEntry(Customer), REPORT::Statement, WorkDate(), WorkDate());

        // [THEN] "Statement" PDF file has been created
        VerifyReportOutputFileExists(Customer.Name, GetStatementReportName());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StatementPDFHandler')]
    [Scope('OnPrem')]
    procedure OneCustomer_OneSelection_RDLC_Blanked()
    var
        Customer: Record Customer;
        WordRDLCReportSelections: Codeunit "Word & RDLC Report Selections";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [RDLC]
        // [SCENARIO 228763] Print customer statement report (SaveAs PDF) in case of one customer without entries, one RDLC report selections
        Initialize();
        BindSubscription(WordRDLCReportSelections);


        // [GIVEN] Report Selections setup:
        // [GIVEN] Usage = "C.Statement", Sequence = 1, Report ID = "Statement" (RDLC)
        // [GIVEN] Customer without entries
        // [WHEN] Run "Statement" (SaveAs PDF) report
        ErrorMessages.Trap();
        asserterror OneCustomer_OneSelection(CreateCustomer(Customer), REPORT::Statement, WorkDate(), WorkDate());

        // [THEN] Error "No data exists for the specified report filters." is returned
        // [THEN] "Statement" PDF file has not been created
        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.First(), NoOutputErr);
        AssertNoMoreErrorMessageOnPage(ErrorMessages);
        VerifyReportOutputFileNotExists(Customer.Name, GetStatementReportName());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StatementPDFHandler')]
    [Scope('OnPrem')]
    procedure OneCustomer_OneSelection_RDLC_Error_NoEntries()
    var
        Customer: Record Customer;
        WordRDLCReportSelections: Codeunit "Word & RDLC Report Selections";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [RDLC]
        // [SCENARIO 228763] Print customer statement report (SaveAs PDF) in case of one customer without entries, one RDLC report selections, blanked start date
        Initialize();
        BindSubscription(WordRDLCReportSelections);

        // [GIVEN] Report Selections setup:
        // [GIVEN] Usage = "C.Statement", Sequence = 1, Report ID = "Statement" (RDLC)
        // [GIVEN] Customer without entries
        // [WHEN] Run "Statement" (SaveAs PDF) report (use blanked "Start Date")
        ErrorMessages.Trap();
        asserterror OneCustomer_OneSelection(CreateCustomer(Customer), REPORT::Statement, 0D, WorkDate());

        // [THEN] Error on blanked "Start Date" is returned
        // [THEN] "Statement" PDF file has not been created
        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.First(), BlankStartDateErr);
        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.Next(), NoOutputErr);
        AssertNoMoreErrorMessageOnPage(ErrorMessages);
        VerifyReportOutputFileNotExists(Customer.Name, GetStatementReportName());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StatementPDFHandler')]
    [Scope('OnPrem')]
    procedure OneCustomer_OneSelection_RDLC_Error_WithEntries()
    var
        Customer: Record Customer;
        WordRDLCReportSelections: Codeunit "Word & RDLC Report Selections";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [RDLC]
        // [SCENARIO 228763] Print customer statement report (SaveAs PDF) in case of one customer with entries, one RDLC report selections, blanked start date
        Initialize();
        BindSubscription(WordRDLCReportSelections);

        // [GIVEN] Report Selections setup:
        // [GIVEN] Usage = "C.Statement", Sequence = 1, Report ID = "Statement" (RDLC)
        // [GIVEN] Customer with entries
        // [WHEN] Run "Statement" (SaveAs PDF) report (use blanked "Start Date")
        ErrorMessages.Trap();
        asserterror OneCustomer_OneSelection(CreateCustomerWithEntry(Customer), REPORT::Statement, 0D, WorkDate());

        // [THEN] Error on blanked "Start Date" is returned
        // [THEN] "Statement" PDF file has not been created
        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.First(), BlankStartDateErr);
        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.Next(), NoOutputErr);
        AssertNoMoreErrorMessageOnPage(ErrorMessages);
        VerifyReportOutputFileNotExists(Customer.Name, GetStatementReportName());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementPDFHandler')]
    [Scope('OnPrem')]
    procedure OneCustomer_OneSelection_WORD_Ok()
    var
        Customer: Record Customer;
        WordRDLCReportSelections: Codeunit "Word & RDLC Report Selections";
    begin
        // [FEATURE] [Word]
        // [SCENARIO 228763] Print customer statement report (SaveAs PDF) in case of one customer with entries, one WORD report selections
        Initialize();
        BindSubscription(WordRDLCReportSelections);

        // [GIVEN] Report Selections setup:
        // [GIVEN] Usage = "C.Statement", Sequence = 1, Report ID = "Standard Statement" (WORD)
        // [GIVEN] Customer with entries
        // [WHEN] Run "Statement" (SaveAs PDF) report
        OneCustomer_OneSelection(CreateCustomerWithEntry(Customer), REPORT::"Standard Statement", WorkDate(), WorkDate());

        // [THEN] "Standard Statement" PDF file has been created
        VerifyReportOutputFileExists(Customer.Name, GetStandardStatementReportName());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementPDFHandler')]
    [Scope('OnPrem')]
    procedure OneCustomer_OneSelection_WORD_Blanked()
    var
        Customer: Record Customer;
        WordRDLCReportSelections: Codeunit "Word & RDLC Report Selections";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Word]
        // [SCENARIO 228763] Print customer statement report (SaveAs PDF) in case of one customer without entries, one WORD report selections
        Initialize();
        BindSubscription(WordRDLCReportSelections);

        // [GIVEN] Report Selections setup:
        // [GIVEN] Usage = "C.Statement", Sequence = 1, Report ID = "Standard Statement" (WORD)
        // [GIVEN] Customer without entries
        // [WHEN] Run "Statement" (SaveAs PDF) report
        ErrorMessages.Trap();
        asserterror OneCustomer_OneSelection(CreateCustomer(Customer), REPORT::"Standard Statement", WorkDate(), WorkDate());

        // [THEN] Error "No data exists for the specified report filters." is returned
        // [THEN] "Standard Statement" PDF file has not been created
        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.First(), PlatformEmptyErr);
        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.Next(), NoOutputErr);

        AssertNoMoreErrorMessageOnPage(ErrorMessages);
        VerifyReportOutputFileNotExists(Customer.Name, GetStandardStatementReportName());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementPDFHandler')]
    [Scope('OnPrem')]
    procedure OneCustomer_OneSelection_WORD_Error_NoEntries()
    var
        Customer: Record Customer;
        WordRDLCReportSelections: Codeunit "Word & RDLC Report Selections";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Word]
        // [SCENARIO 228763] Print customer statement report (SaveAs PDF) in case of one customer without entries, one WORD report selections, blanked start date
        Initialize();
        BindSubscription(WordRDLCReportSelections);

        // [GIVEN] Report Selections setup:
        // [GIVEN] Usage = "C.Statement", Sequence = 1, Report ID = "Standard Statement" (WORD)
        // [GIVEN] Customer without entries
        // [WHEN] Run "Statement" (SaveAs PDF) report (use blanked "Start Date")
        ErrorMessages.Trap();
        asserterror OneCustomer_OneSelection(CreateCustomer(Customer), REPORT::"Standard Statement", 0D, WorkDate());

        // [THEN] Error on blanked "Start Date" is returned
        // [THEN] "Standard Statement" PDF file has not been created
        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.First(), BlankStartDateErr);
        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.Next(), NoOutputErr);
        AssertNoMoreErrorMessageOnPage(ErrorMessages);
        VerifyReportOutputFileNotExists(Customer.Name, GetStandardStatementReportName());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementPDFHandler')]
    [Scope('OnPrem')]
    procedure OneCustomer_OneSelection_WORD_Error_WithEntries()
    var
        Customer: Record Customer;
        WordRDLCReportSelections: Codeunit "Word & RDLC Report Selections";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Word]
        // [SCENARIO 228763] Print customer statement report (SaveAs PDF) in case of one customer with entries, one WORD report selections, blanked start date
        Initialize();
        BindSubscription(WordRDLCReportSelections);

        // [GIVEN] Report Selections setup:
        // [GIVEN] Usage = "C.Statement", Sequence = 1, Report ID = "Standard Statement" (WORD)
        // [GIVEN] Customer with entries
        // [WHEN] Run "Statement" (SaveAs PDF) report (use blanked "Start Date")
        ErrorMessages.Trap();
        asserterror OneCustomer_OneSelection(CreateCustomerWithEntry(Customer), REPORT::"Standard Statement", 0D, WorkDate());

        // [THEN] Error on blanked "Start Date" is returned
        // [THEN] "Standard Statement" PDF file has not been created
        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.First(), BlankStartDateErr);
        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.Next(), NoOutputErr);
        AssertNoMoreErrorMessageOnPage(ErrorMessages);
        VerifyReportOutputFileNotExists(Customer.Name, GetStandardStatementReportName());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementPDFHandler,StatementPDFHandler')]
    [Scope('OnPrem')]
    procedure OneCustomer_TwoSelections_RDLC_Ok_WORD_Ok()
    var
        Customer: Record Customer;
        WordRDLCReportSelections: Codeunit "Word & RDLC Report Selections";
    begin
        // [FEATURE] [RDLC] [Word]
        // [SCENARIO 228763] Print customer statement report (SaveAs PDF) in case of one customer with entries,
        // [SCENARIO 228763] two report selections (1 - RDLC, 2 - WORD)
        Initialize();
        BindSubscription(WordRDLCReportSelections);

        // [GIVEN] Report Selections setup:
        // [GIVEN] Usage = "C.Statement", Sequence = 1, Report ID = "Statement" (RDLC)
        // [GIVEN] Usage = "C.Statement", Sequence = 2, Report ID = "Standard Statement" (WORD)
        // [GIVEN] Customer with entries
        // [WHEN] Run "Statement" (SaveAs PDF) report
        OneCustomer_TwoSelections(
          CreateCustomerWithEntry(Customer), REPORT::Statement, REPORT::"Standard Statement", WorkDate(), WorkDate(), WorkDate(), WorkDate());

        // [THEN] "Statement" PDF file has been created
        // [THEN] "Standard Statement" PDF file has been created
        VerifyReportOutputFileExists(Customer.Name, GetStatementReportName());
        VerifyReportOutputFileExists(Customer.Name, GetStandardStatementReportName());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementPDFHandler,StatementPDFHandler')]
    [Scope('OnPrem')]
    procedure OneCustomer_TwoSelections_RDLC_Ok_WORD_Error()
    var
        Customer: Record Customer;
        WordRDLCReportSelections: Codeunit "Word & RDLC Report Selections";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [RDLC] [Word]
        // [SCENARIO 228763] Print customer statement report (SaveAs PDF) in case of one customer with entries,
        // [SCENARIO 228763] two report selections (1 - RDLC, 2 - WORD), blanked end date for WORD
        Initialize();
        BindSubscription(WordRDLCReportSelections);

        // [GIVEN] Report Selections setup:
        // [GIVEN] Usage = "C.Statement", Sequence = 1, Report ID = "Statement" (RDLC)
        // [GIVEN] Usage = "C.Statement", Sequence = 2, Report ID = "Standard Statement" (WORD)
        // [GIVEN] Customer with entries
        // [WHEN] Run "Statement" (SaveAs PDF) report (use blanked "End Date" for "Standard Statement")
        ErrorMessages.Trap();
        asserterror OneCustomer_TwoSelections(
          CreateCustomerWithEntry(Customer), REPORT::Statement, REPORT::"Standard Statement", WorkDate(), WorkDate(), WorkDate(), 0D);

        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.First(), BlankEndDateErr);
        AssertNoMoreErrorMessageOnPage(ErrorMessages);
        // [THEN] "Statement" PDF file has been created
        // [THEN] "Standard Statement" PDF file has not been created
        VerifyReportOutputFileExists(Customer.Name, GetStatementReportName());
        VerifyReportOutputFileNotExists(Customer.Name, GetStandardStatementReportName());
    end;

    [Test]
    [HandlerFunctions('StandardStatementPDFHandler,StatementPDFHandler')]
    [Scope('OnPrem')]
    procedure OneCustomer_TwoSelections_RDLC_Blanked_WORD_Error()
    var
        Customer: Record Customer;
        WordRDLCReportSelections: Codeunit "Word & RDLC Report Selections";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [RDLC] [Word]
        // [SCENARIO 228763] Print customer statement report (SaveAs PDF) in case of one customer without entries,
        // [SCENARIO 228763] two report selections (1 - RDLC, 2 - WORD), blanked end date for WORD
        Initialize();
        BindSubscription(WordRDLCReportSelections);

        // [GIVEN] Report Selections setup:
        // [GIVEN] Usage = "C.Statement", Sequence = 1, Report ID = "Statement" (RDLC)
        // [GIVEN] Usage = "C.Statement", Sequence = 2, Report ID = "Standard Statement" (WORD)
        // [GIVEN] Customer without entries
        // [WHEN] Run "Statement" (SaveAs PDF) report (use blanked "End Date" for "Standard Statement")
        ErrorMessages.Trap();
        asserterror OneCustomer_TwoSelections(
            CreateCustomer(Customer), REPORT::Statement, REPORT::"Standard Statement", WorkDate(), WorkDate(), WorkDate(), 0D);

        // [THEN] Error on blanked "End Date" is returned
        // [THEN] "Statement" PDF file has not been created
        // [THEN] "Standard Statement" PDF file has not been created
        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.First(), BlankEndDateErr);
        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.Next(), NoOutputErr);
        AssertNoMoreErrorMessageOnPage(ErrorMessages);
        VerifyReportOutputFileNotExists(Customer.Name, GetStatementReportName());
        VerifyReportOutputFileNotExists(Customer.Name, GetStandardStatementReportName());
    end;

    [Test]
    [HandlerFunctions('StandardStatementPDFHandler,StatementPDFHandler')]
    [Scope('OnPrem')]
    procedure OneCustomer_TwoSelections_RDLC_Blanked_WORD_Blanked()
    var
        Customer: Record Customer;
        WordRDLCReportSelections: Codeunit "Word & RDLC Report Selections";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [RDLC] [Word]
        // [SCENARIO 228763] Print customer statement report (SaveAs PDF) in case of one customer without entries,
        // [SCENARIO 228763] two report selections (1 - RDLC, 2 - WORD)
        Initialize();
        BindSubscription(WordRDLCReportSelections);

        // [GIVEN] Report Selections setup:
        // [GIVEN] Usage = "C.Statement", Sequence = 1, Report ID = "Statement" (RDLC)
        // [GIVEN] Usage = "C.Statement", Sequence = 2, Report ID = "Standard Statement" (WORD)
        // [GIVEN] Customer without entries
        // [WHEN] Run "Statement" (SaveAs PDF) report
        ErrorMessages.Trap();
        asserterror OneCustomer_TwoSelections(
            CreateCustomer(Customer), REPORT::Statement, REPORT::"Standard Statement", WorkDate(), WorkDate(), WorkDate(), WorkDate());

        // [THEN] Error "No data exists for the specified report filters." is returned
        // [THEN] "Statement" PDF file has not been created
        // [THEN] "Standard Statement" PDF file has not been created
        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.First(), PlatformEmptyErr);
        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.Next(), NoOutputErr);
        AssertNoMoreErrorMessageOnPage(ErrorMessages);
        VerifyReportOutputFileNotExists(Customer.Name, GetStatementReportName());
        VerifyReportOutputFileNotExists(Customer.Name, GetStatementReportName());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementPDFHandler,StatementPDFHandler')]
    [Scope('OnPrem')]
    procedure OneCustomer_TwoSelections_RDLC_Error_WORD_Ok()
    var
        Customer: Record Customer;
        WordRDLCReportSelections: Codeunit "Word & RDLC Report Selections";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [RDLC] [Word]
        // [SCENARIO 228763] Print customer statement report (SaveAs PDF) in case of one customer with entries,
        // [SCENARIO 228763] two report selections (1 - RDLC, 2 - WORD), blanked start date for WORD
        Initialize();
        BindSubscription(WordRDLCReportSelections);

        // [GIVEN] Report Selections setup:
        // [GIVEN] Usage = "C.Statement", Sequence = 1, Report ID = "Statement" (RDLC)
        // [GIVEN] Usage = "C.Statement", Sequence = 2, Report ID = "Standard Statement" (WORD)
        // [GIVEN] Customer with entries
        // [WHEN] Run "Statement" (SaveAs PDF) report (use blanked "Start Date" for "Statement")
        ErrorMessages.Trap();
        asserterror OneCustomer_TwoSelections(
          CreateCustomerWithEntry(Customer), REPORT::Statement, REPORT::"Standard Statement", 0D, WorkDate(), WorkDate(), WorkDate());

        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.First(), BlankStartDateErr);
        AssertNoMoreErrorMessageOnPage(ErrorMessages);
        // [THEN] "Statement" PDF file has not been created
        // [THEN] "Standard Statement" PDF file has been created
        VerifyReportOutputFileNotExists(Customer.Name, GetStatementReportName());
        VerifyReportOutputFileExists(Customer.Name, GetStandardStatementReportName());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementPDFHandler,StatementPDFHandler')]
    [Scope('OnPrem')]
    procedure OneCustomer_TwoSelections_RDLC_Error_WORD_Blanked()
    var
        Customer: Record Customer;
        WordRDLCReportSelections: Codeunit "Word & RDLC Report Selections";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [RDLC] [Word]
        // [SCENARIO 228763] Print customer statement report (SaveAs PDF) in case of one customer without entries,
        // [SCENARIO 228763] two report selections (1 - RDLC, 2 - WORD), blanked start date for WORD
        Initialize();
        BindSubscription(WordRDLCReportSelections);

        // [GIVEN] Report Selections setup:
        // [GIVEN] Usage = "C.Statement", Sequence = 1, Report ID = "Statement" (RDLC)
        // [GIVEN] Usage = "C.Statement", Sequence = 2, Report ID = "Standard Statement" (WORD)
        // [GIVEN] Customer without entries
        // [WHEN] Run "Statement" (SaveAs PDF) report (use blanked "Start Date" for "Statement")
        ErrorMessages.Trap();
        asserterror OneCustomer_TwoSelections(
            CreateCustomer(Customer), REPORT::Statement, REPORT::"Standard Statement", 0D, WorkDate(), WorkDate(), WorkDate());

        // [THEN] Error on blanked "Start Date" is returned
        // [THEN] "Statement" PDF file has not been created
        // [THEN] "Standard Statement" PDF file has not been created
        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.First(), BlankStartDateErr);
        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.Next(), PlatformEmptyErr);
        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.Next(), NoOutputErr);
        AssertNoMoreErrorMessageOnPage(ErrorMessages);
        VerifyReportOutputFileNotExists(Customer.Name, GetStatementReportName());
        VerifyReportOutputFileNotExists(Customer.Name, GetStandardStatementReportName());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementPDFHandler,StatementPDFHandler')]
    [Scope('OnPrem')]
    procedure OneCustomer_TwoSelections_RDLC_Error_WORD_Error()
    var
        Customer: Record Customer;
        WordRDLCReportSelections: Codeunit "Word & RDLC Report Selections";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [RDLC] [Word]
        // [SCENARIO 228763] Print customer statement report (SaveAs PDF) in case of one customer without entries,
        // [SCENARIO 228763] two report selections (1 - RDLC, 2 - WORD), blanked start date for RDLC, blanked end date for WORD
        Initialize();
        BindSubscription(WordRDLCReportSelections);

        // [GIVEN] Report Selections setup:
        // [GIVEN] Usage = "C.Statement", Sequence = 1, Report ID = "Statement" (RDLC)
        // [GIVEN] Usage = "C.Statement", Sequence = 2, Report ID = "Standard Statement" (WORD)
        // [GIVEN] Customer without entries
        // [WHEN] Run "Statement" (SaveAs PDF) report (use blanked "Start Date" for "Statement", blanked "End Date" for "Standard Statement")
        ErrorMessages.Trap();
        asserterror OneCustomer_TwoSelections(
            CreateCustomer(Customer), REPORT::Statement, REPORT::"Standard Statement", 0D, WorkDate(), WorkDate(), 0D);

        // [THEN] Error on blanked "Start Date" is returned
        // [THEN] "Statement" PDF file has not been created
        // [THEN] "Standard Statement" PDF file has not been created
        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.First(), BlankStartDateErr);
        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.Next(), BlankEndDateErr);
        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.Next(), NoOutputErr);
        AssertNoMoreErrorMessageOnPage(ErrorMessages);
        VerifyReportOutputFileNotExists(Customer.Name, GetStatementReportName());
        VerifyReportOutputFileNotExists(Customer.Name, GetStandardStatementReportName());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementPDFHandler,StatementPDFHandler')]
    [Scope('OnPrem')]
    procedure OneCustomer_TwoSelections_WORD_Ok_RDLC_Ok()
    var
        Customer: Record Customer;
        WordRDLCReportSelections: Codeunit "Word & RDLC Report Selections";
    begin
        // [FEATURE] [RDLC] [Word]
        // [SCENARIO 228763] Print customer statement report (SaveAs PDF) in case of one customer with entries,
        // [SCENARIO 228763] two report selections (1 - WORD, 2 - RDLC)
        Initialize();
        BindSubscription(WordRDLCReportSelections);

        // [GIVEN] Report Selections setup:
        // [GIVEN] Usage = "C.Statement", Sequence = 1, Report ID = "Standard Statement" (WORD)
        // [GIVEN] Usage = "C.Statement", Sequence = 2, Report ID = "Statement" (RDLC)
        // [GIVEN] Customer with entries
        // [WHEN] Run "Statement" (SaveAs PDF) report
        OneCustomer_TwoSelections(
          CreateCustomerWithEntry(Customer), REPORT::"Standard Statement", REPORT::Statement, WorkDate(), WorkDate(), WorkDate(), WorkDate());

        // [THEN] "Standard Statement" PDF file has been created
        // [THEN] "Statement" PDF file has been created
        VerifyReportOutputFileExists(Customer.Name, GetStandardStatementReportName());
        VerifyReportOutputFileExists(Customer.Name, GetStatementReportName());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementPDFHandler,StatementPDFHandler')]
    [Scope('OnPrem')]
    procedure OneCustomer_TwoSelections_WORD_Ok_RDLC_Error()
    var
        Customer: Record Customer;
        WordRDLCReportSelections: Codeunit "Word & RDLC Report Selections";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [RDLC] [Word]
        // [SCENARIO 228763] Print customer statement report (SaveAs PDF) in case of one customer with entries,
        // [SCENARIO 228763] two report selections (1 - WORD, 2 - RDLC), blanked end date for RDLC
        Initialize();
        BindSubscription(WordRDLCReportSelections);

        // [GIVEN] Report Selections setup:
        // [GIVEN] Usage = "C.Statement", Sequence = 1, Report ID = "Standard Statement" (WORD)
        // [GIVEN] Usage = "C.Statement", Sequence = 2, Report ID = "Statement" (RDLC)
        // [GIVEN] Customer with entries
        // [WHEN] Run "Statement" (SaveAs PDF) report (use blanked "End Date" for "Statement")
        ErrorMessages.Trap();
        asserterror OneCustomer_TwoSelections(
          CreateCustomerWithEntry(Customer), REPORT::"Standard Statement", REPORT::Statement, WorkDate(), WorkDate(), WorkDate(), 0D);

        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.First(), BlankEndDateErr);
        AssertNoMoreErrorMessageOnPage(ErrorMessages);
        // [THEN] "Standard Statement" PDF file has been created
        // [THEN] "Statement" PDF file has not been created
        VerifyReportOutputFileExists(Customer.Name, GetStandardStatementReportName());
        VerifyReportOutputFileNotExists(Customer.Name, GetStatementReportName());
    end;

    [Test]
    [HandlerFunctions('StandardStatementPDFHandler,StatementPDFHandler')]
    [Scope('OnPrem')]
    procedure OneCustomer_TwoSelections_WORD_Blanked_RDLC_Error()
    var
        Customer: Record Customer;
        WordRDLCReportSelections: Codeunit "Word & RDLC Report Selections";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [RDLC] [Word]
        // [SCENARIO 228763] Print customer statement report (SaveAs PDF) in case of one customer without entries,
        // [SCENARIO 228763] two report selections (1 - WORD, 2 - RDLC), blanked end date for RDLC
        Initialize();
        BindSubscription(WordRDLCReportSelections);

        // [GIVEN] Report Selections setup:
        // [GIVEN] Usage = "C.Statement", Sequence = 1, Report ID = "Standard Statement" (WORD)
        // [GIVEN] Usage = "C.Statement", Sequence = 2, Report ID = "Statement" (RDLC)
        // [GIVEN] Customer without entries
        // [WHEN] Run "Statement" (SaveAs PDF) report (use blanked "End Date" for "Statement")
        ErrorMessages.Trap();
        asserterror OneCustomer_TwoSelections(
            CreateCustomer(Customer), REPORT::"Standard Statement", REPORT::Statement, WorkDate(), WorkDate(), WorkDate(), 0D);

        // [THEN] Error on blanked "End Date" is returned
        // [THEN] "Standard Statement" PDF file has not been created
        // [THEN] "Statement" PDF file has not been created

        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.First(), PlatformEmptyErr);
        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.Next(), BlankEndDateErr);
        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.Next(), NoOutputErr);
        AssertNoMoreErrorMessageOnPage(ErrorMessages);
        VerifyReportOutputFileNotExists(Customer.Name, GetStandardStatementReportName());
        VerifyReportOutputFileNotExists(Customer.Name, GetStatementReportName());
    end;

    [Test]
    [HandlerFunctions('StandardStatementPDFHandler,StatementPDFHandler')]
    [Scope('OnPrem')]
    procedure OneCustomer_TwoSelections_WORD_Blanked_RDLC_Blanked()
    var
        Customer: Record Customer;
        WordRDLCReportSelections: Codeunit "Word & RDLC Report Selections";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [RDLC] [Word]
        // [SCENARIO 228763] Print customer statement report (SaveAs PDF) in case of one customer without entries,
        // [SCENARIO 228763] two report selections (1 - WORD, 2 - RDLC)
        Initialize();
        BindSubscription(WordRDLCReportSelections);

        // [GIVEN] Report Selections setup:
        // [GIVEN] Usage = "C.Statement", Sequence = 1, Report ID = "Standard Statement" (WORD)
        // [GIVEN] Usage = "C.Statement", Sequence = 2, Report ID = "Statement" (RDLC)
        // [GIVEN] Customer without entries
        // [WHEN] Run "Statement" (SaveAs PDF) report
        ErrorMessages.Trap();
        asserterror OneCustomer_TwoSelections(
            CreateCustomer(Customer), REPORT::"Standard Statement", REPORT::Statement, WorkDate(), WorkDate(), WorkDate(), WorkDate());

        // [THEN] Error "No data exists for the specified report filters." is returned
        // [THEN] "Standard Statement" PDF file has not been created
        // [THEN] "Statement" PDF file has not been created
        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.First(), PlatformEmptyErr);
        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.Next(), NoOutputErr);
        AssertNoMoreErrorMessageOnPage(ErrorMessages);
        VerifyReportOutputFileNotExists(Customer.Name, GetStandardStatementReportName());
        VerifyReportOutputFileNotExists(Customer.Name, GetStatementReportName());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementPDFHandler,StatementPDFHandler')]
    [Scope('OnPrem')]
    procedure OneCustomer_TwoSelections_WORD_Error_RDLC_Ok()
    var
        Customer: Record Customer;
        WordRDLCReportSelections: Codeunit "Word & RDLC Report Selections";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [RDLC] [Word]
        // [SCENARIO 228763] Print customer statement report (SaveAs PDF) in case of one customer with entries,
        // [SCENARIO 228763] two report selections (1 - WORD, 2 - RDLC), blanked start date for WORD
        Initialize();
        BindSubscription(WordRDLCReportSelections);

        // [GIVEN] Report Selections setup:
        // [GIVEN] Usage = "C.Statement", Sequence = 1, Report ID = "Standard Statement" (WORD)
        // [GIVEN] Usage = "C.Statement", Sequence = 2, Report ID = "Statement" (RDLC)
        // [GIVEN] Customer with entries
        // [WHEN] Run "Statement" (SaveAs PDF) report (use blanked "Start Date" for "Standard Statement")
        ErrorMessages.Trap();
        asserterror OneCustomer_TwoSelections(
          CreateCustomerWithEntry(Customer), REPORT::"Standard Statement", REPORT::Statement, 0D, WorkDate(), WorkDate(), WorkDate());

        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.First(), BlankStartDateErr);
        AssertNoMoreErrorMessageOnPage(ErrorMessages);
        // [THEN] "Standard Statement" PDF file has not been created
        // [THEN] "Statement" PDF file has been created
        VerifyReportOutputFileNotExists(Customer.Name, GetStandardStatementReportName());
        VerifyReportOutputFileExists(Customer.Name, GetStatementReportName());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementPDFHandler,StatementPDFHandler')]
    [Scope('OnPrem')]
    procedure OneCustomer_TwoSelections_WORD_Error_RDLC_Blanked()
    var
        Customer: Record Customer;
        WordRDLCReportSelections: Codeunit "Word & RDLC Report Selections";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [RDLC] [Word]
        // [SCENARIO 228763] Print customer statement report (SaveAs PDF) in case of one customer without entries,
        // [SCENARIO 228763] two report selections (1 - WORD, 2 - RDLC), blanked start date for WORD
        Initialize();
        BindSubscription(WordRDLCReportSelections);

        // [GIVEN] Report Selections setup:
        // [GIVEN] Usage = "C.Statement", Sequence = 1, Report ID = "Standard Statement" (WORD)
        // [GIVEN] Usage = "C.Statement", Sequence = 2, Report ID = "Statement" (RDLC)
        // [GIVEN] Customer without entries
        // [WHEN] Run "Statement" (SaveAs PDF) report (use blanked "Start Date" for "Standard Statement")
        ErrorMessages.Trap();
        asserterror OneCustomer_TwoSelections(
            CreateCustomer(Customer), REPORT::"Standard Statement", REPORT::Statement, 0D, WorkDate(), WorkDate(), WorkDate());

        // [THEN] Error on blanked "Start Date" is returned
        // [THEN] "Standard Statement" PDF file has not been created
        // [THEN] "Statement" PDF file has not been created
        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.First(), BlankStartDateErr);
        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.Next(), NoOutputErr);
        AssertNoMoreErrorMessageOnPage(ErrorMessages);
        VerifyReportOutputFileNotExists(Customer.Name, GetStandardStatementReportName());
        VerifyReportOutputFileNotExists(Customer.Name, GetStatementReportName());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementPDFHandler,StatementPDFHandler')]
    [Scope('OnPrem')]
    procedure OneCustomer_TwoSelections_WORD_Error_RDLC_Error()
    var
        Customer: Record Customer;
        WordRDLCReportSelections: Codeunit "Word & RDLC Report Selections";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [RDLC] [Word]
        // [SCENARIO 228763] Print customer statement report (SaveAs PDF) in case of one customer without entries,
        // [SCENARIO 228763] two report selections (1 - WORD, 2 - RDLC), blanked start date for WORD, blanked end date for RDLC
        Initialize();
        BindSubscription(WordRDLCReportSelections);

        // [GIVEN] Report Selections setup:
        // [GIVEN] Usage = "C.Statement", Sequence = 1, Report ID = "Standard Statement" (WORD)
        // [GIVEN] Usage = "C.Statement", Sequence = 2, Report ID = "Statement" (RDLC)
        // [GIVEN] Customer without entries
        ErrorMessages.Trap();
        asserterror OneCustomer_TwoSelections(
            CreateCustomer(Customer), REPORT::"Standard Statement", REPORT::Statement, 0D, WorkDate(), WorkDate(), 0D);

        // [THEN] Error on blanked "Start Date" is returned
        // [THEN] "Standard Statement" PDF file has not been created
        // [THEN] "Statement" PDF file has not been created
        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.First(), BlankStartDateErr);
        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.Next(), BlankEndDateErr);
        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.Next(), NoOutputErr);
        AssertNoMoreErrorMessageOnPage(ErrorMessages);
        VerifyReportOutputFileNotExists(Customer.Name, GetStandardStatementReportName());
        VerifyReportOutputFileNotExists(Customer.Name, GetStatementReportName());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StatementPDFHandler')]
    [Scope('OnPrem')]
    procedure TwoCustomers_OneSelection_RDLC_Ok()
    var
        Customer: array[2] of Record Customer;
        WordRDLCReportSelections: Codeunit "Word & RDLC Report Selections";
    begin
        // [FEATURE] [RDLC]
        // [SCENARIO 228763] Print customer statement report (SaveAs PDF) in case of two customers with entries, one RDLC report selections
        Initialize();
        BindSubscription(WordRDLCReportSelections);

        // [GIVEN] Report Selections setup:
        // [GIVEN] Usage = "C.Statement", Sequence = 1, Report ID = "Statement" (RDLC)
        // [GIVEN] Customer "C1" with entries, customer "C2" with entries
        // [WHEN] Run "Statement" report (SaveAs PDF) with filter for both customers
        TwoCustomers_OneSelection(
          CreateCustomerWithEntry(Customer[1]), CreateCustomerWithEntry(Customer[2]), REPORT::Statement, WorkDate(), WorkDate());

        // [THEN] "Standard Statement" PDF file has been created for "C1"
        // [THEN] "Standard Statement" PDF file has been created for "C2"
        VerifyReportOutputFileExists(Customer[1].Name, GetStatementReportName());
        VerifyReportOutputFileExists(Customer[2].Name, GetStatementReportName());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StatementPDFHandler')]
    [Scope('OnPrem')]
    procedure TwoCustomers_OneSelection_RDLC_FirstCustWithoutEntries()
    var
        Customer: array[2] of Record Customer;
        WordRDLCReportSelections: Codeunit "Word & RDLC Report Selections";
    begin
        // [FEATURE] [RDLC]
        // [SCENARIO 228763] Print customer statement report (SaveAs PDF) in case of two customers (first without entries), one RDLC report selections
        Initialize();
        BindSubscription(WordRDLCReportSelections);

        // [GIVEN] Report Selections setup:
        // [GIVEN] Usage = "C.Statement", Sequence = 1, Report ID = "Statement" (RDLC)
        // [GIVEN] Customer "C1" without entries, customer "C2" with entries
        // [WHEN] Run "Statement" report (SaveAs PDF) with filter for both customers
        TwoCustomers_OneSelection(
          CreateCustomer(Customer[1]), CreateCustomerWithEntry(Customer[2]), REPORT::Statement, WorkDate(), WorkDate());

        // [THEN] "Standard Statement" PDF file has not been created for "C1"
        // [THEN] "Standard Statement" PDF file has been created for "C2"
        VerifyReportOutputFileNotExists(Customer[1].Name, GetStatementReportName());
        VerifyReportOutputFileExists(Customer[2].Name, GetStatementReportName());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StatementPDFHandler')]
    [Scope('OnPrem')]
    procedure TwoCustomers_OneSelection_RDLC_SecondCustWithoutEntries()
    var
        Customer: array[2] of Record Customer;
        WordRDLCReportSelections: Codeunit "Word & RDLC Report Selections";
    begin
        // [FEATURE] [RDLC]
        // [SCENARIO 228763] Print customer statement report (SaveAs PDF) in case of two customers (second without entries), one RDLC report selections
        Initialize();
        BindSubscription(WordRDLCReportSelections);

        // [GIVEN] Report Selections setup:
        // [GIVEN] Usage = "C.Statement", Sequence = 1, Report ID = "Statement" (RDLC)
        // [GIVEN] Customer "C1" with entries, customer "C2" without entries
        // [WHEN] Run "Statement" report (SaveAs PDF) with filter for both customers
        TwoCustomers_OneSelection(
          CreateCustomerWithEntry(Customer[1]), CreateCustomer(Customer[2]), REPORT::Statement, WorkDate(), WorkDate());

        // [THEN] "Standard Statement" PDF file has been created for "C1"
        // [THEN] "Standard Statement" PDF file has not been created for "C2"
        VerifyReportOutputFileExists(Customer[1].Name, GetStatementReportName());
        VerifyReportOutputFileNotExists(Customer[2].Name, GetStatementReportName());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StatementPDFHandler')]
    [Scope('OnPrem')]
    procedure TwoCustomers_OneSelection_RDLC_Blanked()
    var
        Customer: array[2] of Record Customer;
        WordRDLCReportSelections: Codeunit "Word & RDLC Report Selections";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [RDLC]
        // [SCENARIO 228763] Print customer statement report (SaveAs PDF) in case of two customers without entries, one RDLC report selections
        Initialize();
        BindSubscription(WordRDLCReportSelections);

        // [GIVEN] Report Selections setup:
        // [GIVEN] Usage = "C.Statement", Sequence = 1, Report ID = "Statement" (RDLC)
        // [GIVEN] Customer "C1" without entries, customer "C2" without entries
        // [WHEN] Run "Statement" report (SaveAs PDF) with filter for both customers
        ErrorMessages.Trap();
        asserterror TwoCustomers_OneSelection(
            CreateCustomer(Customer[1]), CreateCustomer(Customer[2]), REPORT::Statement, WorkDate(), WorkDate());

        // [THEN] Error "No data exists for the specified report filters." is returned
        // [THEN] "Standard Statement" PDF file has not been created for "C1"
        // [THEN] "Standard Statement" PDF file has not been created for "C2"
        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.First(), NoOutputErr);
        AssertNoMoreErrorMessageOnPage(ErrorMessages);
        VerifyReportOutputFileNotExists(Customer[1].Name, GetStatementReportName());
        VerifyReportOutputFileNotExists(Customer[2].Name, GetStatementReportName());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StatementPDFHandler')]
    [Scope('OnPrem')]
    procedure TwoCustomers_OneSelection_RDLC_Error()
    var
        Customer: array[2] of Record Customer;
        WordRDLCReportSelections: Codeunit "Word & RDLC Report Selections";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [RDLC]
        // [SCENARIO 228763] Print customer statement report (SaveAs PDF) in case of two customers without entries, one RDLC report selections, blanked start date
        Initialize();
        BindSubscription(WordRDLCReportSelections);

        // [GIVEN] Report Selections setup:
        // [GIVEN] Usage = "C.Statement", Sequence = 1, Report ID = "Statement" (RDLC)
        // [GIVEN] Customer "C1" without entries, customer "C2" without entries
        // [WHEN] Run "Statement" report (SaveAs PDF) with filter for both customers (use blanked "Start Date" for "Standard Statement")
        ErrorMessages.Trap();
        asserterror TwoCustomers_OneSelection(
            CreateCustomer(Customer[1]), CreateCustomer(Customer[2]), REPORT::Statement, 0D, WorkDate());

        // [THEN] Error on blanked "Start Date" is returned
        // [THEN] "Standard Statement" PDF file has not been created for "C1"
        // [THEN] "Standard Statement" PDF file has not been created for "C2"
        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.First(), BlankStartDateErr);
        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.Next(), BlankStartDateErr);
        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.Next(), NoOutputErr);
        AssertNoMoreErrorMessageOnPage(ErrorMessages);
        VerifyReportOutputFileNotExists(Customer[1].Name, GetStatementReportName());
        VerifyReportOutputFileNotExists(Customer[2].Name, GetStatementReportName());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementPDFHandler')]
    [Scope('OnPrem')]
    procedure TwoCustomers_OneSelection_WORD_Ok()
    var
        Customer: array[2] of Record Customer;
        WordRDLCReportSelections: Codeunit "Word & RDLC Report Selections";
    begin
        // [FEATURE] [Word]
        // [SCENARIO 228763] Print customer statement report (SaveAs PDF) in case of two customers with entries, one WORD report selections
        Initialize();
        BindSubscription(WordRDLCReportSelections);

        // [GIVEN] Report Selections setup:
        // [GIVEN] Usage = "C.Statement", Sequence = 1, Report ID = "Standard Statement" (WORD)
        // [GIVEN] Customer "C1" with entries, customer "C2" with entries
        // [WHEN] Run "Statement" report (SaveAs PDF) with filter for both customers
        TwoCustomers_OneSelection(
          CreateCustomerWithEntry(Customer[1]), CreateCustomerWithEntry(Customer[2]), REPORT::"Standard Statement", WorkDate(), WorkDate());

        // [THEN] "Standard Statement" PDF file has been created for "C1"
        // [THEN] "Standard Statement" PDF file has been created for "C2"
        VerifyReportOutputFileExists(Customer[1].Name, GetStandardStatementReportName());
        VerifyReportOutputFileExists(Customer[2].Name, GetStandardStatementReportName());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementPDFHandler')]
    [Scope('OnPrem')]
    procedure TwoCustomers_OneSelection_WORD_FirstCustWithoutEntries()
    var
        Customer: array[2] of Record Customer;
        WordRDLCReportSelections: Codeunit "Word & RDLC Report Selections";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Word]
        // [SCENARIO 228763] Print customer statement report (SaveAs PDF) in case of two customers (first without entries), one WORD report selections
        Initialize();
        BindSubscription(WordRDLCReportSelections);

        // [GIVEN] Report Selections setup:
        // [GIVEN] Usage = "C.Statement", Sequence = 1, Report ID = "Standard Statement" (WORD)
        // [GIVEN] Customer "C1" without entries, customer "C2" with entries
        // [WHEN] Run "Statement" report (SaveAs PDF) with filter for both customers

        ErrorMessages.Trap();
        asserterror TwoCustomers_OneSelection(
          CreateCustomer(Customer[1]), CreateCustomerWithEntry(Customer[2]), REPORT::"Standard Statement", WorkDate(), WorkDate());

        // [THEN] "Standard Statement" PDF file has not been created for "C1"
        // [THEN] "Standard Statement" PDF file has been created for "C2"
        VerifyReportOutputFileNotExists(Customer[1].Name, GetStandardStatementReportName());
        VerifyReportOutputFileExists(Customer[2].Name, GetStandardStatementReportName());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementPDFHandler')]
    [Scope('OnPrem')]
    procedure TwoCustomers_OneSelection_WORD_SecondCustWithoutEntries()
    var
        Customer: array[2] of Record Customer;
        WordRDLCReportSelections: Codeunit "Word & RDLC Report Selections";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Word]
        // [SCENARIO 228763] Print customer statement report (SaveAs PDF) in case of two customers (second without entries), one WORD report selections
        Initialize();
        BindSubscription(WordRDLCReportSelections);

        // [GIVEN] Report Selections setup:
        // [GIVEN] Usage = "C.Statement", Sequence = 1, Report ID = "Standard Statement" (WORD)
        // [GIVEN] Customer "C1" with entries, customer "C2" without entries
        // [WHEN] Run "Statement" report (SaveAs PDF) with filter for both customers
        ErrorMessages.Trap();
        asserterror TwoCustomers_OneSelection(
          CreateCustomerWithEntry(Customer[1]), CreateCustomer(Customer[2]), REPORT::"Standard Statement", WorkDate(), WorkDate());

        // [THEN] "Standard Statement" PDF file has been created for "C1"
        // [THEN] "Standard Statement" PDF file has not been created for "C2"
        VerifyReportOutputFileExists(Customer[1].Name, GetStandardStatementReportName());
        VerifyReportOutputFileNotExists(Customer[2].Name, GetStandardStatementReportName());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementPDFHandler')]
    [Scope('OnPrem')]
    procedure TwoCustomers_OneSelection_WORD_Blanked()
    var
        Customer: array[2] of Record Customer;
        WordRDLCReportSelections: Codeunit "Word & RDLC Report Selections";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Word]
        // [SCENARIO 228763] Print customer statement report (SaveAs PDF) in case of two customers without entries, one WORD report selections
        Initialize();
        BindSubscription(WordRDLCReportSelections);

        // [GIVEN] Report Selections setup:
        // [GIVEN] Usage = "C.Statement", Sequence = 1, Report ID = "Standard Statement" (WORD)
        // [GIVEN] Customer "C1" without entries, customer "C2" without entries
        // [WHEN] Run "Statement" report (SaveAs PDF) with filter for both customers
        ErrorMessages.Trap();
        asserterror TwoCustomers_OneSelection(
            CreateCustomer(Customer[1]), CreateCustomer(Customer[2]), REPORT::"Standard Statement", WorkDate(), WorkDate());

        // [THEN] Error "No data exists for the specified report filters." is returned
        // [THEN] "Standard Statement" PDF file has not been created for "C1"
        // [THEN] "Standard Statement" PDF file has not been created for "C2"
        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.First(), PlatformEmptyErr);
        //AssertNoMoreErrorMessageOnPage(ErrorMessages);
        VerifyReportOutputFileNotExists(Customer[1].Name, GetStandardStatementReportName());
        VerifyReportOutputFileNotExists(Customer[2].Name, GetStandardStatementReportName());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementPDFHandler')]
    [Scope('OnPrem')]
    procedure TwoCustomers_OneSelection_WORD_Error()
    var
        Customer: array[2] of Record Customer;
        WordRDLCReportSelections: Codeunit "Word & RDLC Report Selections";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Word]
        // [SCENARIO 228763] Print customer statement report (SaveAs PDF) in case of two customers without entries, one WORD report selections, blanked start date
        Initialize();
        BindSubscription(WordRDLCReportSelections);

        // [GIVEN] Report Selections setup:
        // [GIVEN] Usage = "C.Statement", Sequence = 1, Report ID = "Standard Statement" (WORD)
        // [GIVEN] Customer "C1" without entries, customer "C2" without entries
        // [WHEN] Run "Statement" report (SaveAs PDF) with filter for both customers (use blanked "Start Date" for "Standard Statement")
        ErrorMessages.Trap();
        asserterror TwoCustomers_OneSelection(
            CreateCustomer(Customer[1]), CreateCustomer(Customer[2]), REPORT::"Standard Statement", 0D, WorkDate());

        // [THEN] Error on blanked "Start Date" is returned
        // [THEN] "Standard Statement" PDF file has not been created for "C1"
        // [THEN] "Standard Statement" PDF file has not been created for "C2"
        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.First(), BlankStartDateErr);
        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.Next(), BlankStartDateErr);
        AssertErrorMessageOnPage(ErrorMessages, ErrorMessages.Next(), NoOutputErr);
        AssertNoMoreErrorMessageOnPage(ErrorMessages);
        VerifyReportOutputFileNotExists(Customer[1].Name, GetStandardStatementReportName());
        VerifyReportOutputFileNotExists(Customer[2].Name, GetStandardStatementReportName());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardStatementMultiplePDFHandler')]
    [Scope('OnPrem')]
    procedure OneCustomer_OneSelection_WORD_Ok_Twice()
    var
        Customer: Record Customer;
        WordRDLCReportSelections: Codeunit "Word & RDLC Report Selections";
        ObjectOptions: Record "Object Options";
    begin
        // [FEATURE] [Word]
        // [SCENARIO 258701] Print Customer Statement report two times with saved report parameters
        Initialize();
        BindSubscription(WordRDLCReportSelections);

        // [GIVEN] Report Selections setup:
        // [GIVEN] Usage = "C.Statement", Sequence = 1, Report ID = "Standard Statement"
        // [GIVEN] Customer with an entry on workdate
        CreateCustomerWithEntry(Customer);

        // [GIVEN] Run "Statement" with 'PDF' report output from date before workdate till workdate
        LibraryVariableStorage.Enqueue(HandlerOptionRef::Update);
        OneCustomer_OneSelection(Customer."No.", REPORT::"Standard Statement", WorkDate() - 1, WorkDate());

        // [GIVEN] Object options with report parameters created for "Standard Statement" report
        Assert.IsTrue(
          ObjectOptions.Get(
            LastUsedTxt, REPORT::"Standard Statement", ObjectOptions."Object Type"::Report, UserId, CompanyName), '');

        // [WHEN] Run "Statement" (SaveAs PDF) report second time
        LibraryVariableStorage.Enqueue(HandlerOptionRef::Verify);
        RunStatementReport_OneCust_OneSelection(Customer."No.", WorkDate() - 1, WorkDate());

        // [THEN] "Standard Statement" PDF file has been created
        // [THEN] Request page uses saved Start Date as date before workdate and End Date as workdate
        // [THEN] Request page uses 'PDF' Report Output
        VerifyReportOutputFileExists(Customer.Name, GetStandardStatementReportName());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Scope('OnPrem')]
    procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Word & RDLC Report Selections");
        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Word & RDLC Report Selections");
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Word & RDLC Report Selections");
    end;

    local procedure OneCustomer_OneSelection(CustomerNo: Code[20]; ReportID: Integer; StartDate: Date; EndDate: Date)
    var
        DummyReportSelections: Record "Report Selections";
    begin
        LibraryERM.SetupReportSelection(DummyReportSelections.Usage::"C.Statement", ReportID);
        RunStatementReport_OneCust_OneSelection(CustomerNo, StartDate, EndDate);
    end;

    local procedure OneCustomer_TwoSelections(CustomerNo: Code[20]; ReportID1: Integer; ReportID2: Integer; StartingDate1: Date; EndingDate1: Date; StartingDate2: Date; EndingDate2: Date)
    var
        DummyReportSelections: Record "Report Selections";
    begin
        LibraryERM.SetupReportSelection(DummyReportSelections.Usage::"C.Statement", ReportID1);
        CreateReportSelection(DummyReportSelections.Usage::"C.Statement", '2', ReportID2);
        RunStatementReport_OneCust_TwoSelections(CustomerNo, StartingDate1, EndingDate1, StartingDate2, EndingDate2);
    end;

    local procedure TwoCustomers_OneSelection(CustomerNo1: Code[20]; CustomerNo2: Code[20]; ReportID: Integer; StartingDate: Date; EndingDate: Date)
    var
        DummyReportSelections: Record "Report Selections";
    begin
        LibraryERM.SetupReportSelection(DummyReportSelections.Usage::"C.Statement", ReportID);
        RunStatementReport_TwoCust_OneSelection(CustomerNo1, CustomerNo2, StartingDate, EndingDate);
    end;

    local procedure CreateReportSelection(ReportSelectionsUsage: Enum "Report Selection Usage"; SequenceCode: Code[10]; ReportId: Integer)
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.Init();
        ReportSelections.Usage := ReportSelectionsUsage;
        ReportSelections.Sequence := SequenceCode;
        ReportSelections."Report ID" := ReportId;
        ReportSelections.Insert();
    end;

    local procedure CreateCustomer(var Customer: Record Customer): Code[20]
    begin
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithEntry(var Customer: Record Customer): Code[20]
    begin
        LibrarySales.CreateCustomer(Customer);
        MockCustLedgerEntry(Customer."No.");
        exit(Customer."No.");
    end;

    local procedure MockCustLedgerEntry(CustomerNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(CustLedgerEntry, CustLedgerEntry.FieldNo("Entry No."));
        CustLedgerEntry."Customer No." := CustomerNo;
        CustLedgerEntry."Document Type" := CustLedgerEntry."Document Type"::Invoice;
        CustLedgerEntry."Document No." := LibraryUtility.GenerateGUID();
        CustLedgerEntry."Posting Date" := WorkDate();
        CustLedgerEntry.Amount := LibraryRandom.RandDecInRange(1000, 2000, 2);
        CustLedgerEntry.Open := true;
        CustLedgerEntry.Insert();
        MockDetailedCustLedgerEntry(CustLedgerEntry."Entry No.", CustLedgerEntry."Customer No.", CustLedgerEntry."Document No.", CustLedgerEntry.Amount, CustLedgerEntry."Posting Date");
    end;

    local procedure MockDetailedCustLedgerEntry(CustLedgerEntryNo: Integer; CustomerNo: Code[20]; DocumentNo: Code[20]; EntryAmount: Decimal; PostingDate: Date)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.Init();
        DetailedCustLedgEntry."Entry No." := LibraryUtility.GetNewRecNo(DetailedCustLedgEntry, DetailedCustLedgEntry.FieldNo("Entry No."));
        DetailedCustLedgEntry."Customer No." := CustomerNo;
        DetailedCustLedgEntry."Document Type" := DetailedCustLedgEntry."Document Type"::Invoice;
        DetailedCustLedgEntry."Document No." := DocumentNo;
        DetailedCustLedgEntry."Cust. Ledger Entry No." := CustLedgerEntryNo;
        DetailedCustLedgEntry.Amount := EntryAmount;
        DetailedCustLedgEntry."Amount (LCY)" := EntryAmount;
        DetailedCustLedgEntry."Posting Date" := PostingDate;
        DetailedCustLedgEntry.Insert();
    end;

    local procedure GetReportOutputFullFileName(CustomerName: Text; ReportName: Text): Text
    var
        FileMgt: Codeunit "File Management";
    begin
        exit(FileMgt.CombinePath(TemporaryPath, GetReportOutputFileName(CustomerName, ReportName)));
    end;

    local procedure GetReportOutputFileName(CustomerName: Text; ReportName: Text): Text
    begin
        exit(StrSubstNo('%1 for %2 as of %3.pdf', ReportName, CustomerName, Format(WorkDate(), 0, 9)));
    end;

    local procedure GetStandardStatementReportName(): Text
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Report, REPORT::"Standard Statement");
        exit(AllObjWithCaption."Object Caption");
    end;

    local procedure GetStatementReportName(): Text
    var
        AllObj: Record AllObj;
    begin
        AllObj.Get(AllObj."Object Type"::Report, REPORT::Statement);
        exit(AllObj."Object Name");
    end;

    local procedure RunStatementReport_OneCust_OneSelection(CustomerNo: Code[20]; StartingDate: Date; EndingDate: Date)
    var
        Customer: Record Customer;
    begin
        LibraryVariableStorage.Enqueue(StartingDate);
        LibraryVariableStorage.Enqueue(EndingDate);
        Customer.SetRange("No.", CustomerNo);
        RunStatementReport(Customer);
    end;

    local procedure RunStatementReport_OneCust_TwoSelections(CustomerNo: Code[20]; StartingDate1: Date; EndingDate1: Date; StartingDate2: Date; EndingDate2: Date)
    var
        Customer: Record Customer;
    begin
        LibraryVariableStorage.Enqueue(StartingDate1);
        LibraryVariableStorage.Enqueue(EndingDate1);
        LibraryVariableStorage.Enqueue(StartingDate2);
        LibraryVariableStorage.Enqueue(EndingDate2);
        Customer.SetRange("No.", CustomerNo);
        RunStatementReport(Customer);
    end;

    local procedure RunStatementReport_TwoCust_OneSelection(CustomerNo1: Code[20]; CustomerNo2: Code[20]; StartingDate: Date; EndingDate: Date)
    var
        Customer: Record Customer;
    begin
        LibraryVariableStorage.Enqueue(StartingDate);
        LibraryVariableStorage.Enqueue(EndingDate);
        Customer.SetFilter("No.", '%1|%2', CustomerNo1, CustomerNo2);
        RunStatementReport(Customer);
    end;

    local procedure RunStatementReport(var Customer: Record Customer)
    var
        ReportSelections: Record "Report Selections";
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
        CustomerRecordRef: RecordRef;
    begin
        CustomerRecordRef.GetTable(Customer);
        CustomerRecordRef.SetView(Customer.GetView());
        CustomLayoutReporting.SetOutputSupression(false);
        CustomLayoutReporting.SetSavePath(TemporaryPath);
        Commit();
        CustomLayoutReporting.ProcessReportData(
          ReportSelections.Usage::"C.Statement", CustomerRecordRef,
          Customer.FieldName("No."), DATABASE::Customer, Customer.FieldName("No."), true);
    end;

    local procedure VerifyReportOutputFileExists(CustomerName: Text; ReportName: Text)
    var
        FileMgt: Codeunit "File Management";
        FullFilePath: Text;
        FileName: Text;
    begin
        FullFilePath := GetReportOutputFullFileName(CustomerName, ReportName);
        FileName := GetReportOutputFileName(CustomerName, ReportName);
        Assert.IsTrue(FileMgt.ServerFileExists(FullFilePath), StrSubstNo(ExpectedFilePathErr, FileName));
    end;

    local procedure VerifyReportOutputFileNotExists(CustomerName: Text; ReportName: Text)
    var
        FileMgt: Codeunit "File Management";
        FullFilePath: Text;
        FileName: Text;
    begin
        FullFilePath := GetReportOutputFullFileName(CustomerName, ReportName);
        FileName := GetReportOutputFileName(CustomerName, ReportName);
        Assert.IsFalse(FileMgt.ServerFileExists(FullFilePath), StrSubstNo(ExpectedMissingFilePathErr, FileName));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Custom Layout Reporting", 'OnIsTestMode', '', false, false)]
    local procedure EnableTestModeOnIsTestMode(var TestMode: Boolean)
    begin
        TestMode := true
    end;

    local procedure AssertErrorMessageOnPage(var ErrorMessages: TestPage "Error Messages"; HasRecord: Boolean; ExpectedErrorMessage: Text)
    begin
        Assert.IsTrue(HasRecord, 'Error Messages page does not have record');
        Assert.ExpectedMessage(ExpectedErrorMessage, ErrorMessages.Description.Value);
    end;

    local procedure AssertNoMoreErrorMessageOnPage(var ErrorMessages: TestPage "Error Messages")
    begin
        if ErrorMessages.Next() then
            Assert.Fail(StrSubstNo('Unexpected error: %1', ErrorMessages.Description.Value));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardStatementPDFHandler(var StandardStatement: TestRequestPage "Standard Statement")
    begin
        StandardStatement."Start Date".SetValue(LibraryVariableStorage.DequeueDate());
        StandardStatement."End Date".SetValue(LibraryVariableStorage.DequeueDate());
        StandardStatement.ReportOutput.SetValue('PDF');
        StandardStatement.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardStatementMultiplePDFHandler(var StandardStatement: TestRequestPage "Standard Statement")
    begin
        case LibraryVariableStorage.DequeueInteger() of
            HandlerOptionRef::Update:
                begin
                    StandardStatement."Start Date".SetValue(LibraryVariableStorage.DequeueDate());
                    StandardStatement."End Date".SetValue(LibraryVariableStorage.DequeueDate());
                    StandardStatement.ReportOutput.SetValue('PDF');
                    StandardStatement.OK().Invoke();
                end;
            HandlerOptionRef::Verify:
                begin
                    StandardStatement."Start Date".AssertEquals(LibraryVariableStorage.DequeueDate());
                    StandardStatement."End Date".AssertEquals(LibraryVariableStorage.DequeueDate());
                    StandardStatement.ReportOutput.AssertEquals('PDF');
                    StandardStatement.OK().Invoke();
                end;
        end;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StatementPDFHandler(var Statement: TestRequestPage Statement)
    begin
        Statement."Start Date".SetValue(LibraryVariableStorage.DequeueDate());
        Statement."End Date".SetValue(LibraryVariableStorage.DequeueDate());
        Statement.ReportOutput.SetValue('PDF');
        Statement.OK().Invoke();
    end;
}

