codeunit 134422 "Rep. Selections - Std. Stmt."
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Report Selection] [Standard Statement] [Sales]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryFileMgtHandler: Codeunit "Library - File Mgt Handler";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Initialized: Boolean;
#pragma warning disable AA0240
        CustomerEmailTxt: Label 'Customer@contoso.com';
#pragma warning restore AA0240
        NoDataOutputErr: Label 'No data exists for the specified report filters.';
        PlatformEmptyErr: Label 'The error, The report couldn’t be generated, because it was empty. Adjust your filters and try again.';
        TargetEmailAddressErr: Label 'The target email address has not been specified on the document layout for';
        ReqParametersTemplatesTxt: Label '<?xml version="1.0" standalone="yes"?><ReportParameters name="Standard Statement" id="1316"><Options><Field name="StartDate">%1</Field><Field name="EndDate">%2</Field><Field name="PrintEntriesDue">false</Field><Field name="PrintAllHavingEntry">false</Field><Field name="PrintAllHavingBal">true</Field><Field name="PrintReversedEntries">false</Field><Field name="PrintUnappliedEntries">false</Field><Field name="IncludeAgingBand">false</Field><Field name="PeriodLength">1M+CM</Field><Field name="DateChoice">0</Field><Field name="LogInteraction">true</Field><Field name="SupportedOutputMethod">%3</Field><Field name="ChosenOutputMethod">%4</Field><Field name="PrintIfEmailIsMissing">%5</Field></Options><DataItems><DataItem name="Customer">VERSION(1) SORTING(Field1) WHERE(Field1=1(%6))</DataItem><DataItem name="Integer">VERSION(1) SORTING(Field1)</DataItem><DataItem name="CurrencyLoop">VERSION(1) SORTING(Field1)</DataItem><DataItem name="CustLedgEntryHdr">VERSION(1) SORTING(Field1)</DataItem><DataItem name="DtldCustLedgEntries">VERSION(1) SORTING(Field9,Field4,Field3,Field10)</DataItem><DataItem name="CustLedgEntryFooter">VERSION(1) SORTING(Field1)</DataItem><DataItem name="OverdueVisible">VERSION(1) SORTING(Field1)</DataItem><DataItem name="CustLedgEntry2">VERSION(1) SORTING(Field3,Field36,Field43,Field37,Field11)</DataItem><DataItem name="OverdueEntryFooder">VERSION(1) SORTING(Field1)</DataItem><DataItem name="AgingBandVisible">VERSION(1) SORTING(Field1)</DataItem><DataItem name="AgingCustLedgEntry">VERSION(1) SORTING(Field3,Field36,Field43,Field37,Field11)</DataItem><DataItem name="AgingBandLoop">VERSION(1) SORTING(Field1)</DataItem><DataItem name="LetterText">VERSION(1) SORTING(Field1)</DataItem></DataItems></ReportParameters>', Locked = true;
        ReqPageParamsTxt: Label '<?xml version="1.0" encoding="utf-8" standalone="yes"?><ReportParameters name="Standard Statement" id="1316"><Options><Field name="StartDate">%1</Field><Field name="EndDate">%2</Field><Field name="PrintAllHavingBal">true</Field><Field name="PeriodLength">1M+CM</Field><Field name="DateChoice">0</Field><Field name="SupportedOutputMethod">%3</Field><Field name="ChosenOutputMethod">%4</Field><Field name="PrintIfEmailIsMissing">%5</Field></Options><DataItems><DataItem name="Customer">VERSION(1) SORTING(Field1) WHERE(Field%6=1(%7))</DataItem></DataItems></ReportParameters>', Locked = true;
        StandardStatementReportOutputType: Option Print,Preview,Word,PDF,Email,XML;
        ConfirmStartJobQueueQst: Label 'Do you want to set the job queue entry up to run immediately?';
        UnexpectedConfirmationErr: Label 'Unxpected confimation.';
        StatementTitleDocxTxt: Label 'Statement for %1 as of %2.docx', Comment = '%1 is Customer Name, %2 is a date';
        StatementTitlePdfTxt: Label 'Statement for %1 as of %2.pdf', Comment = '%1 is Customer Name, %2 is a date';
        StatementTitleHtmlTxt: Label 'Statement for %1 as of %2.html', Comment = '%1 is Customer Name, %2 is a date';
        FailedToSendEmailErr: Label 'Failed to send email';
        MoreErrorsOnErrorMessagesPageErr: Label '%1 contains more errors than expected.', Comment = '%1 is the caption of the page';
        LessErrorsOnErrorMessagesPageErr: Label '%1 contains less errors than expected.', Comment = '%1 is the caption of the page';
        RequestParametersErr: Label 'Request parameters for the Standard Statement report have not been set up.';
        EscapeTok: Label '''%1''', Locked = true;
        StatementCountErr: Label 'Customer Statement are not Sent.';

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Email_SingleCustomer_BlankAddress()
    var
        Customer: Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Email]
        // [SCENARIO] Send email when Customer "A" with entries, email is not specified and Customer "B" does not exist. "Print Remaining" = FALSE
        Initialize();

        PrepareCustomerWithEntries(Customer, '', GetStandardStatementReportID());
        Commit();

        ErrorMessages.Trap();
        RunReportFromCard(Customer, StandardStatementReportOutputType::Email, false);

        AddExpectedErrorMessage(TempErrorMessage, TargetEmailAddressErr);
        AddExpectedErrorMessage(TempErrorMessage, NoDataOutputErr);
        AssertErrorsOnErrorMessagesPage(ErrorMessages, TempErrorMessage);

        Customer.Find();
        Customer.TestField("Last Statement No.", 0);
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Email_SingleCustomer_NoEntries()
    var
        Customer: Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Email]
        // [SCENARIO] Send email when Customer "A" without entries, email is specified and Customer "B" does not exist. "Print Remaining" = FALSE
        Initialize();

        PrepareCustomerWithoutEntries(Customer, CustomerEmailTxt, GetStandardStatementReportID());
        Commit();

        ErrorMessages.Trap();
        RunReportFromCard(Customer, StandardStatementReportOutputType::Email, false);

        AddExpectedErrorMessage(TempErrorMessage, PlatformEmptyErr);
        AddExpectedErrorMessage(TempErrorMessage, NoDataOutputErr);
        AssertErrorsOnErrorMessagesPage(ErrorMessages, TempErrorMessage);

        Customer.Find();
        Customer.TestField("Last Statement No.", 0);
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Email_SingleCustomer()
    var
        Customer: Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email]
        // [SCENARIO] Send email when Customer "A" with entries, email is specified and Customer "B" does not exist. "Print Remaining" = FALSE
        Initialize();

        PrepareCustomerWithEntries(Customer, CustomerEmailTxt, GetStandardStatementReportID());
        Commit();

        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunReportFromCard(Customer, StandardStatementReportOutputType::Email, false);

        LibraryTempNVBufferHandler.AssertEntry(Customer.Name);
        LibraryTempNVBufferHandler.AssertQueueEmpty();

        Customer.Find();
        Customer.TestField("Last Statement No.", 1);

    end;

    [Test]
    [Scope('OnPrem')]
    procedure Email_SingleCustomer_A_DataNoEmail_B_DataEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        RepSelectionsStdStmt: Codeunit "Rep. Selections - Std. Stmt.";
    begin
        // [FEATURE] [Email]
        // [SCENARIO] Send email when Customer "A" with entries, email is not specified and Customer "B" with entries, email is specified. "Print Remaining" = TRUE, Filter = "A"
        Initialize();

        PrepareCustomerWithEntries(Customer[1], '', GetStandardStatementReportID());
        PrepareCustomerWithEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID());
        Commit();

        BindSubscription(RepSelectionsStdStmt);
        RunReportWithParameters(GetSingleCustomerFilter(Customer[1]), StandardStatementReportOutputType::Email, true);

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 0);
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Email_SingleCustomer_A_NoDataEmail_B_DataEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Email]
        // [SCENARIO] Send email when Customer "A" without entries, email is specified and Customer "B" with entries, email is specified. "Print Remaining" = TRUE, Filter = "A"
        Initialize();

        PrepareCustomerWithoutEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID());
        PrepareCustomerWithEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID());
        Commit();

        ErrorMessages.Trap();
        RunReportFromCard(Customer[1], StandardStatementReportOutputType::Email, true);

        AddExpectedErrorMessage(TempErrorMessage, PlatformEmptyErr);
        AddExpectedErrorMessage(TempErrorMessage, NoDataOutputErr);
        AssertErrorsOnErrorMessagesPage(ErrorMessages, TempErrorMessage);

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 0);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Email_SingleCustomer_A_DataNoEmail_B_NoDataEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        RepSelectionsStdStmt: Codeunit "Rep. Selections - Std. Stmt.";
    begin
        // [FEATURE] [Email]
        // [SCENARIO] Send email when Customer "A" with entries, email is not specified and Customer "B" without entries, email is specified. "Print Remaining" = TRUE, Filter = "A"
        Initialize();

        PrepareCustomerWithEntries(Customer[1], '', GetStandardStatementReportID());
        PrepareCustomerWithoutEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID());
        Commit();

        BindSubscription(RepSelectionsStdStmt);
        RunReportWithParameters(GetSingleCustomerFilter(Customer[1]), StandardStatementReportOutputType::Email, true);

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 0);
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Email_SingleCustomer_A_NoDataEmail_B_NoDataEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Email]
        // [SCENARIO] Send email when Customer "A" without entries, email is specified and Customer "B" without entries, email is specified. "Print Remaining" = TRUE, Filter = "A"
        Initialize();

        PrepareCustomerWithoutEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID());
        PrepareCustomerWithoutEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID());
        Commit();

        ErrorMessages.Trap();
        RunReportFromCard(Customer[1], StandardStatementReportOutputType::Email, true);

        AddExpectedErrorMessage(TempErrorMessage, PlatformEmptyErr);
        AddExpectedErrorMessage(TempErrorMessage, NoDataOutputErr);
        AssertErrorsOnErrorMessagesPage(ErrorMessages, TempErrorMessage);

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 0);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 0);
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Email_SingleCustomer_A_DataEmail_B_DataEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email]
        // [SCENARIO] Send email when Customer "A" with entries, email is not specified and Customer "B" with entries, email is specified. "Print Remaining" = TRUE, Filter = "A"
        Initialize();

        PrepareCustomerWithEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID());
        PrepareCustomerWithEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID());
        Commit();

        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunReportFromCard(Customer[1], StandardStatementReportOutputType::Email, true);

        LibraryTempNVBufferHandler.AssertEntry(Customer[1].Name);
        LibraryTempNVBufferHandler.AssertQueueEmpty();

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 0);
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Email_SingleCustomer_A_DataEmail_B_DataNoEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email]
        // [SCENARIO] Send email when Customer "A" with entries, email is specified and Customer "B" with entries, email is not specified. "Print Remaining" = TRUE, Filter = "A"
        Initialize();

        PrepareCustomerWithEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID());
        PrepareCustomerWithEntries(Customer[2], '', GetStandardStatementReportID());
        Commit();

        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunReportFromCard(Customer[1], StandardStatementReportOutputType::Email, true);

        LibraryTempNVBufferHandler.AssertEntry(Customer[1].Name);
        LibraryTempNVBufferHandler.AssertQueueEmpty();

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 0);
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Email_SingleCustomer_A_DataEmail_B_NoDataEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email]
        // [SCENARIO] Send email when Customer "A" with entries, email is specified and Customer "B" without entries, email is specified. "Print Remaining" = TRUE, Filter = "A"
        Initialize();

        PrepareCustomerWithEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID());
        PrepareCustomerWithoutEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID());
        Commit();

        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunReportFromCard(Customer[1], StandardStatementReportOutputType::Email, true);

        LibraryTempNVBufferHandler.AssertEntry(Customer[1].Name);
        LibraryTempNVBufferHandler.AssertQueueEmpty();

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Email_TwoCustomer_A_DataNoEmail_B_DataEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        RepSelectionsStdStmt: Codeunit "Rep. Selections - Std. Stmt.";
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email]
        // [SCENARIO] Send email when Customer "A" with entries, email is not specified and Customer "B" with entries, email is specified. "Print Remaining" = TRUE, Filter = "A|B"
        Initialize();

        PrepareCustomerWithEntries(Customer[1], '', GetStandardStatementReportID());
        PrepareCustomerWithEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID());
        Commit();

        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        BindSubscription(RepSelectionsStdStmt);
        RunReportWithParameters(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, true);

        LibraryTempNVBufferHandler.AssertEntry(Customer[2].Name);
        LibraryTempNVBufferHandler.AssertQueueEmpty();

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Email_TwoCustomer_A_NoDataEmail_B_NoDataEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Email]
        // [SCENARIO] Send email when Customer "A" without entries, email is specified and Customer "B" without entries, email is specified. "Print Remaining" = TRUE, Filter = "A|B"
        Initialize();

        PrepareCustomerWithoutEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID());
        PrepareCustomerWithoutEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID());
        Commit();

        BindSubscription(LibraryTempNVBufferHandler);
        ErrorMessages.Trap();
        asserterror RunReportWithParameters(
            GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, true);

        AddExpectedErrorMessage(TempErrorMessage, PlatformEmptyErr);
        AddExpectedErrorMessage(TempErrorMessage, PlatformEmptyErr);
        AddExpectedErrorMessage(TempErrorMessage, NoDataOutputErr);
        AssertErrorsOnErrorMessagesPage(ErrorMessages, TempErrorMessage);

        LibraryTempNVBufferHandler.AssertQueueEmpty();

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 0);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Email_TwoCustomer_A_DataNoEmail_B_DataNoEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        RepSelectionsStdStmt: Codeunit "Rep. Selections - Std. Stmt.";
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
    begin
        // [FEATURE] [Email]
        // [SCENARIO] Send email when Customer "A" with entries, email is not specified and Customer "B" with entries, email is not specified. "Print Remaining" = TRUE, Filter = "A|B"
        Initialize();

        PrepareCustomerWithEntries(Customer[1], '', GetStandardStatementReportID());
        PrepareCustomerWithEntries(Customer[2], '', GetStandardStatementReportID());
        Commit();

        BindSubscription(LibraryTempNVBufferHandler);
        BindSubscription(RepSelectionsStdStmt);
        RunReportWithParameters(
          GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, true);

        LibraryTempNVBufferHandler.AssertQueueEmpty();

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Email_TwoCustomer_A_DataEmail_B_DataEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email]
        // [SCENARIO] Send email when Customer "A" with entries, email is specified and Customer "B" with entries, email is specified. "Print Remaining" = TRUE, Filter = "A|B"
        Initialize();

        PrepareCustomerWithEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID());
        PrepareCustomerWithEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID());
        Commit();

        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunReportWithParameters(
          GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, true);

        LibraryTempNVBufferHandler.AssertEntry(Customer[1].Name);
        LibraryTempNVBufferHandler.AssertEntry(Customer[2].Name);
        LibraryTempNVBufferHandler.AssertQueueEmpty();

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Email_TwoCustomer_A_DataEmail_B_DataNoEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        RepSelectionsStdStmt: Codeunit "Rep. Selections - Std. Stmt.";
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email]
        // [SCENARIO] Send email when Customer "A" with entries, email is specified and Customer "B" with entries, email is not specified. "Print Remaining" = TRUE, Filter = "A|B"
        Initialize();

        PrepareCustomerWithEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID());
        PrepareCustomerWithEntries(Customer[2], '', GetStandardStatementReportID());
        Commit();

        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        BindSubscription(RepSelectionsStdStmt);
        RunReportWithParameters(
          GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, true);

        LibraryTempNVBufferHandler.AssertEntry(Customer[1].Name);
        LibraryTempNVBufferHandler.AssertQueueEmpty();

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Email_TwoCustomer_A_DataNoEmail_B_NoDataEmail_DoNotPrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Email]
        // [SCENARIO] Send email when Customer "A" with entries, email is not specified and Customer "B" without entries, email is specified. "Print Remaining" = FALSE, Filter = "A|B"
        Initialize();

        PrepareCustomerWithEntries(Customer[1], '', GetStandardStatementReportID());
        PrepareCustomerWithoutEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID());
        Commit();

        BindSubscription(LibraryTempNVBufferHandler);
        ErrorMessages.Trap();
        asserterror RunReportWithParameters(
            GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, false);

        AddExpectedErrorMessage(TempErrorMessage, TargetEmailAddressErr);
        AddExpectedErrorMessage(TempErrorMessage, PlatformEmptyErr);
        AddExpectedErrorMessage(TempErrorMessage, NoDataOutputErr);
        AssertErrorsOnErrorMessagesPage(ErrorMessages, TempErrorMessage);

        LibraryTempNVBufferHandler.AssertQueueEmpty();

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 0);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Email_TwoCustomer_A_NoDataEmail_B_NoDataEmail_DoNotPrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Email]
        // [SCENARIO] Send email when Customer "A" without entries, email is specified and Customer "B" without entries, email is specified. "Print Remaining" = FALSE, Filter = "A|B"
        Initialize();

        PrepareCustomerWithoutEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID());
        PrepareCustomerWithoutEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID());
        Commit();

        BindSubscription(LibraryTempNVBufferHandler);
        ErrorMessages.Trap();
        asserterror RunReportWithParameters(
            GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, false);

        AddExpectedErrorMessage(TempErrorMessage, PlatformEmptyErr);
        AddExpectedErrorMessage(TempErrorMessage, PlatformEmptyErr);
        AddExpectedErrorMessage(TempErrorMessage, NoDataOutputErr);
        AssertErrorsOnErrorMessagesPage(ErrorMessages, TempErrorMessage);

        LibraryTempNVBufferHandler.AssertQueueEmpty();

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 0);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Email_TwoCustomer_A_DataNoEmail_B_DataNoEmail_DoNotPrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Email]
        // [SCENARIO] Send email when Customer "A" with entries, email is not specified and Customer "B" with entries, email is not specified. "Print Remaining" = FALSE, Filter = "A|B"
        Initialize();

        PrepareCustomerWithEntries(Customer[1], '', GetStandardStatementReportID());
        PrepareCustomerWithEntries(Customer[2], '', GetStandardStatementReportID());
        Commit();

        BindSubscription(LibraryTempNVBufferHandler);
        ErrorMessages.Trap();
        asserterror RunReportWithParameters(
            GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, false);

        AddExpectedErrorMessage(TempErrorMessage, TargetEmailAddressErr);
        AddExpectedErrorMessage(TempErrorMessage, TargetEmailAddressErr);
        AddExpectedErrorMessage(TempErrorMessage, NoDataOutputErr);
        AssertErrorsOnErrorMessagesPage(ErrorMessages, TempErrorMessage);

        LibraryTempNVBufferHandler.AssertQueueEmpty();

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 0);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Email_TwoCustomer_A_NoDataEmail_B_DataNoEmail_DoNotPrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        RepSelectionsStdStmt: Codeunit "Rep. Selections - Std. Stmt.";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Email]
        // [SCENARIO] Send email when Customer "A" without entries, email is specified and Customer "B" with entries, email is not specified. "Print Remaining" = FALSE, Filter = "A|B"
        Initialize();

        PrepareCustomerWithoutEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID());
        PrepareCustomerWithEntries(Customer[2], '', GetStandardStatementReportID());
        Commit();

        BindSubscription(LibraryTempNVBufferHandler);
        BindSubscription(RepSelectionsStdStmt);
        ErrorMessages.Trap();
        asserterror RunReportWithParameters(
            GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, false);

        AddExpectedErrorMessage(TempErrorMessage, PlatformEmptyErr);
        AddExpectedErrorMessage(TempErrorMessage, TargetEmailAddressErr);
        AddExpectedErrorMessage(TempErrorMessage, NoDataOutputErr);
        AssertErrorsOnErrorMessagesPage(ErrorMessages, TempErrorMessage);

        LibraryTempNVBufferHandler.AssertQueueEmpty();

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 0);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Email_TwoCustomer_A_DataEmail_B_DataEmail_DoNotPrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email]
        // [SCENARIO] Send email when Customer "A" with entries, email is specified and Customer "B" with entries, email is specified. "Print Remaining" = FALSE, Filter = "A|B"
        Initialize();

        PrepareCustomerWithEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID());
        PrepareCustomerWithEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID());
        Commit();

        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunReportWithParameters(
          GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, false);

        LibraryTempNVBufferHandler.AssertEntry(Customer[1].Name);
        LibraryTempNVBufferHandler.AssertEntry(Customer[2].Name);
        LibraryTempNVBufferHandler.AssertQueueEmpty();

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 1);
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_SingleCustomer_BlankAddress()
    var
        Customer: Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" with entries, email is not specified and Customer "B" does not exist. "Print Remaining" = FALSE
        Initialize();

        PrepareCustomerWithEntries(Customer, '', GetStandardStatementReportID());
        Commit();

        RunBackgroundReportFromCard(GetSingleCustomerFilter(Customer), StandardStatementReportOutputType::Email, false);

        AddExpectedErrorMessage(TempErrorMessage, TargetEmailAddressErr);
        AddExpectedErrorMessage(TempErrorMessage, NoDataOutputErr);
        AssertActivityLog(TempErrorMessage);

        AssertReportInboxEmpty();

        Customer.Find();
        Customer.TestField("Last Statement No.", 0);
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_SingleCustomer_NoEntries()
    var
        Customer: Record Customer;
        ActivityLog: Record "Activity Log";
        TempErrorMessage: Record "Error Message" temporary;
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" without entries, email is specified and Customer "B" does not exist. "Print Remaining" = FALSE
        Initialize();

        PrepareCustomerWithoutEntries(Customer, CustomerEmailTxt, GetStandardStatementReportID());
        Commit();

        ActivityLog.SetRange("User ID", UserId);
        Assert.RecordIsEmpty(ActivityLog);

        RunBackgroundReportFromCard(GetSingleCustomerFilter(Customer), StandardStatementReportOutputType::Email, false);

        AddExpectedErrorMessage(TempErrorMessage, PlatformEmptyErr);
        AddExpectedErrorMessage(TempErrorMessage, NoDataOutputErr);
        AssertActivityLog(TempErrorMessage);

        AssertReportInboxEmpty();

        Customer.Find();
        Customer.TestField("Last Statement No.", 0);
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_SingleCustomer()
    var
        Customer: Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" with entries, email is specified and Customer "B" does not exist. "Print Remaining" = FALSE
        Initialize();

        PrepareCustomerWithEntries(Customer, CustomerEmailTxt, GetStandardStatementReportID());
        Commit();

        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber();
        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber();
        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunBackgroundReportFromCard(GetSingleCustomerFilter(Customer), StandardStatementReportOutputType::Email, false);

        // generated docs
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer));
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleHtml(Customer));
        // added to zip docs
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer));
        LibraryTempNVBufferHandler.AssertQueueEmpty();

        Customer.Find();
        Customer.TestField("Last Statement No.", 1);
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_SingleCustomer_A_DataNoEmail_B_DataEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" with entries, email is not specified and Customer "B" with entries, email is specified. "Print Remaining" = TRUE, Filter = "A"
        Initialize();

        PrepareCustomerWithEntries(Customer[1], '', GetStandardStatementReportID());
        PrepareCustomerWithEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID());
        Commit();

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber();
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber();
        BindSubscription(LibraryTempNVBufferHandler);
        RunBackgroundReportFromCard(GetSingleCustomerFilter(Customer[1]), StandardStatementReportOutputType::Email, true);

        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleDocx(Customer[1]));
        LibraryTempNVBufferHandler.AssertQueueEmpty();

        AssertReportInboxCountWord(1);

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 0);
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_SingleCustomer_A_NoDataEmail_B_DataEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" without entries, email is specified and Customer "B" with entries, email is specified. "Print Remaining" = TRUE, Filter = "A"
        Initialize();

        PrepareCustomerWithoutEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID());
        PrepareCustomerWithEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID());
        Commit();

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber();
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber();
        BindSubscription(LibraryTempNVBufferHandler);
        RunBackgroundReportFromCard(GetSingleCustomerFilter(Customer[1]), StandardStatementReportOutputType::Email, true);

        AddExpectedErrorMessage(TempErrorMessage, PlatformEmptyErr);
        AddExpectedErrorMessage(TempErrorMessage, NoDataOutputErr);
        AssertActivityLog(TempErrorMessage);

        LibraryTempNVBufferHandler.AssertQueueEmpty();

        AssertReportInboxEmpty();

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 0);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 0);
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_SingleCustomer_A_DataNoEmail_B_NoDataEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" with entries, email is not specified and Customer "B" without entries, email is specified. "Print Remaining" = TRUE, Filter = "A"
        Initialize();

        PrepareCustomerWithEntries(Customer[1], '', GetStandardStatementReportID());
        PrepareCustomerWithoutEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID());
        Commit();

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber();
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber();
        BindSubscription(LibraryTempNVBufferHandler);
        RunBackgroundReportFromCard(GetSingleCustomerFilter(Customer[1]), StandardStatementReportOutputType::Email, true);

        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleDocx(Customer[1]));
        LibraryTempNVBufferHandler.AssertQueueEmpty();

        AssertReportInboxCountWord(1);

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 0);
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_SingleCustomer_A_NoDataEmail_B_NoDataEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" without entries, email is specified and Customer "B" without entries, email is specified. "Print Remaining" = TRUE, Filter = "A"
        Initialize();

        PrepareCustomerWithoutEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID());
        PrepareCustomerWithoutEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID());
        Commit();

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber();
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber();
        BindSubscription(LibraryTempNVBufferHandler);
        RunBackgroundReportFromCard(GetSingleCustomerFilter(Customer[1]), StandardStatementReportOutputType::Email, true);

        AddExpectedErrorMessage(TempErrorMessage, PlatformEmptyErr);
        AddExpectedErrorMessage(TempErrorMessage, NoDataOutputErr);
        AssertActivityLog(TempErrorMessage);

        LibraryTempNVBufferHandler.AssertQueueEmpty();

        AssertReportInboxEmpty();

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 0);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 0);
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_SingleCustomer_A_DataEmail_B_DataEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" with entries, email is specified and Customer "B" with entries, email is specified. "Print Remaining" = TRUE, Filter = "A"
        Initialize();

        PrepareCustomerWithEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID());
        PrepareCustomerWithEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID());
        Commit();

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber();
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber();
        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunBackgroundReportFromCard(GetSingleCustomerFilter(Customer[1]), StandardStatementReportOutputType::Email, true);

        // generated docs
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[1]));
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleHtml(Customer[1]));
        // added to zip
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[1]));
        LibraryTempNVBufferHandler.AssertQueueEmpty();

        // We canceled sending in test. That means No Error, but email was not sent to target.
        // Thus, we insert output into Report Inbox
        AssertReportInboxCountWord(1);

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 0);
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_SingleCustomer_A_DataEmail_B_DataNoEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" with entries, email is specified and Customer "B" with entries, email is not specified. "Print Remaining" = TRUE, Filter = "A"
        Initialize();

        PrepareCustomerWithEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID());
        PrepareCustomerWithEntries(Customer[2], '', GetStandardStatementReportID());
        Commit();

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber();
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber();
        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunBackgroundReportFromCard(GetSingleCustomerFilter(Customer[1]), StandardStatementReportOutputType::Email, true);

        // generated docs
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[1]));
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleHtml(Customer[1]));
        // added to zip
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[1]));
        LibraryTempNVBufferHandler.AssertQueueEmpty();

        // We canceled sending in test. That means No Error, but email was not sent to target.
        // Thus, we insert output into Report Inbox
        AssertReportInboxCountWord(1);

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 0);
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_SingleCustomer_A_DataEmail_B_NoDataEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" with entries, email is specified and Customer "B" without entries, email is specified. "Print Remaining" = TRUE, Filter = "A"
        Initialize();

        PrepareCustomerWithEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID());
        PrepareCustomerWithoutEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID());
        Commit();

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber();
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber();
        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunBackgroundReportFromCard(GetSingleCustomerFilter(Customer[1]), StandardStatementReportOutputType::Email, true);

        // generated docs
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[1]));
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleHtml(Customer[1]));
        // added to zip
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[1]));
        LibraryTempNVBufferHandler.AssertQueueEmpty();

        // We canceled sending in test. That means No Error, but email was not sent to target.
        // Thus, we insert output into Report Inbox
        AssertReportInboxCountWord(1);

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 0);
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_TwoCustomer_A_DataNoEmail_B_DataEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" with entries, email is not specified and Customer "B" with entries, email is specified. "Print Remaining" = TRUE, Filter = "A|B"
        Initialize();

        PrepareCustomerWithEntries(Customer[1], '', GetStandardStatementReportID());
        PrepareCustomerWithEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID());
        Commit();

        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber();
        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber();
        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunBackgroundReportFromCard(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, true);

        // generated docs
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleDocx(Customer[1]));
        // generated docs
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[2]));
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleHtml(Customer[2]));
        // added to zip
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[2]));
        LibraryTempNVBufferHandler.AssertQueueEmpty();

        // We canceled sending in test. That means No Error, but email was not sent to target.
        // Thus, we insert output into Report Inbox (Zip with two files)
        AssertReportInboxCountZip(1);

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 1);
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_TwoCustomer_A_NoDataEmail_B_DataEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" without entries, email is specified and Customer "B" with entries, email is specified. "Print Remaining" = TRUE, Filter = "A|B"
        Initialize();

        PrepareCustomerWithoutEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID());
        PrepareCustomerWithEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID());
        Commit();

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber();
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber();
        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunBackgroundReportFromCard(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, true);

        // generated docs
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[2]));
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleHtml(Customer[2]));
        // added to zip docs
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[2]));
        LibraryTempNVBufferHandler.AssertQueueEmpty();

        // We canceled sending in test. That means No Error, but email was not sent to target.
        // Thus, we insert output into Report Inbox
        AssertReportInboxCountWord(1);

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 0);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 1);
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_TwoCustomer_A_DataNoEmail_B_NoDataEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" with entries, email is not specified and Customer "B" without entries, email is specified. "Print Remaining" = TRUE, Filter = "A|B"
        Initialize();

        PrepareCustomerWithEntries(Customer[1], '', GetStandardStatementReportID());
        PrepareCustomerWithoutEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID());
        Commit();

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber();
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber();
        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunBackgroundReportFromCard(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, true);

        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleDocx(Customer[1]));
        LibraryTempNVBufferHandler.AssertQueueEmpty();

        AssertReportInboxCountWord(1);

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 0);
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_TwoCustomer_A_NoDataEmail_B_NoDataEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" without entries, email is specified and Customer "B" without entries, email is specified. "Print Remaining" = TRUE, Filter = "A|B"
        Initialize();

        PrepareCustomerWithoutEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID());
        PrepareCustomerWithoutEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID());
        Commit();

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber();
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber();
        BindSubscription(LibraryTempNVBufferHandler);
        RunBackgroundReportFromCard(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, true);

        AddExpectedErrorMessage(TempErrorMessage, PlatformEmptyErr);
        AddExpectedErrorMessage(TempErrorMessage, PlatformEmptyErr);
        AddExpectedErrorMessage(TempErrorMessage, NoDataOutputErr);
        AssertActivityLog(TempErrorMessage);
        LibraryTempNVBufferHandler.AssertQueueEmpty();

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 0);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 0);
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_TwoCustomer_A_DataNoEmail_B_DataNoEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" with entries, email is not specified and Customer "B" with entries, email is not specified. "Print Remaining" = TRUE, Filter = "A|B"
        Initialize();

        PrepareCustomerWithEntries(Customer[1], '', GetStandardStatementReportID());
        PrepareCustomerWithEntries(Customer[2], '', GetStandardStatementReportID());
        Commit();

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber();
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber();
        BindSubscription(LibraryTempNVBufferHandler);
        RunBackgroundReportFromCard(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, true);

        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleDocx(Customer[1]));
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleDocx(Customer[2]));
        LibraryTempNVBufferHandler.AssertQueueEmpty();

        AssertReportInboxCountZip(1);

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 1);
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_TwoCustomer_A_NoDataEmail_B_DataNoEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" without entries, email is specified and Customer "B" with entries, email is not specified. "Print Remaining" = TRUE, Filter = "A|B"
        Initialize();

        PrepareCustomerWithoutEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID());
        PrepareCustomerWithEntries(Customer[2], '', GetStandardStatementReportID());
        Commit();

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber();
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber();
        BindSubscription(LibraryTempNVBufferHandler);
        RunBackgroundReportFromCard(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, true);

        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleDocx(Customer[2]));
        LibraryTempNVBufferHandler.AssertQueueEmpty();

        AssertReportInboxCountWord(1);

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 0);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 1);
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_TwoCustomer_A_DataEmail_B_DataEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" with entries, email is specified and Customer "B" with entries, email is specified. "Print Remaining" = TRUE, Filter = "A|B"
        Initialize();

        PrepareCustomerWithEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID());
        PrepareCustomerWithEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID());
        Commit();

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber();
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber();
        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunBackgroundReportFromCard(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, true);

        // email attachment + body
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[1]));
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleHtml(Customer[1]));
        // zip for report inbox
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[1]));

        // email attachment + body
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[2]));
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleHtml(Customer[2]));
        // zip for report inbox
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[2]));

        LibraryTempNVBufferHandler.AssertQueueEmpty();

        // We canceled sending in test. That means No Error, but email was not sent to target.
        // Thus, we insert output into Report Inbox (Zip with 2 files)
        AssertReportInboxCountZip(1);

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 1);
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_TwoCustomer_A_DataEmail_B_DataNoEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" with entries, email is specified and Customer "B" with entries, email is not specified. "Print Remaining" = TRUE, Filter = "A|B"
        Initialize();

        PrepareCustomerWithEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID());
        PrepareCustomerWithEntries(Customer[2], '', GetStandardStatementReportID());
        Commit();

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber();
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber();
        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunBackgroundReportFromCard(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, true);

        // email attachment + body
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[1]));
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleHtml(Customer[1]));
        // zip for report inbox
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[1]));

        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleDocx(Customer[2]));
        LibraryTempNVBufferHandler.AssertQueueEmpty();

        // We canceled sending in test. That means No Error, but email was not sent to target.
        // Thus, we insert output into Report Inbox (Zip with 2 files)
        AssertReportInboxCountZip(1);

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 1);
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_TwoCustomer_A_DataEmail_B_NoDataEmail_PrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" with entries, email is specified and Customer "B" without entries, email is specified. "Print Remaining" = TRUE, Filter = "A|B"
        Initialize();

        PrepareCustomerWithEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID());
        PrepareCustomerWithoutEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID());
        Commit();

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber();
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber();
        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunBackgroundReportFromCard(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, true);

        // email attachment + body
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[1]));
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleHtml(Customer[1]));
        // word for report inbox
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[1]));

        LibraryTempNVBufferHandler.AssertQueueEmpty();

        AssertReportInboxCountWord(1);

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 0);
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_TwoCustomer_A_DataNoEmail_B_DataEmail_DoNotPrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" with entries, email is not specified and Customer "B" with entries, email is specified. "Print Remaining" = FALSE, Filter = "A|B"
        Initialize();

        PrepareCustomerWithEntries(Customer[1], '', GetStandardStatementReportID());
        PrepareCustomerWithEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID());
        Commit();

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber();
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber();
        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunBackgroundReportFromCard(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, false);

        AddExpectedErrorMessage(TempErrorMessage, TargetEmailAddressErr);
        AssertActivityLog(TempErrorMessage);

        // email attachment + body
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[2]));
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleHtml(Customer[2]));
        // pdf for report inbox
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[2]));

        LibraryTempNVBufferHandler.AssertQueueEmpty();

        AssertReportInboxCountPdf(1);

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 0);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 1);
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_TwoCustomer_A_NoDataEmail_B_DataEmail_DoNotPrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" without entries, email is specified and Customer "B" with entries, email is specified. "Print Remaining" = FALSE, Filter = "A|B"
        Initialize();

        PrepareCustomerWithoutEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID());
        PrepareCustomerWithEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID());
        Commit();

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber();
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber();
        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunBackgroundReportFromCard(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, false);

        // email attachment + body
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[2]));
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleHtml(Customer[2]));
        // pdf for report inbox
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[2]));

        LibraryTempNVBufferHandler.AssertQueueEmpty();

        AssertReportInboxCountPdf(1);

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 0);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 1);
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_TwoCustomer_A_DataNoEmail_B_NoDataEmail_DoNotPrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" with entries, email is not specified and Customer "B" without entries, email is specified. "Print Remaining" = FALSE, Filter = "A|B"
        Initialize();

        PrepareCustomerWithEntries(Customer[1], '', GetStandardStatementReportID());
        PrepareCustomerWithoutEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID());
        Commit();

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber();
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber();
        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunBackgroundReportFromCard(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, false);

        AddExpectedErrorMessage(TempErrorMessage, TargetEmailAddressErr);
        AddExpectedErrorMessage(TempErrorMessage, PlatformEmptyErr);
        AddExpectedErrorMessage(TempErrorMessage, NoDataOutputErr);
        AssertActivityLog(TempErrorMessage);

        LibraryTempNVBufferHandler.AssertQueueEmpty();

        AssertReportInboxEmpty();

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 0);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 0);
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_TwoCustomer_A_NoDataEmail_B_NoDataEmail_DoNotPrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" without entries, email is specified and Customer "B" without entries, email is specified. "Print Remaining" = FALSE, Filter = "A|B"
        Initialize();

        PrepareCustomerWithoutEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID());
        PrepareCustomerWithoutEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID());
        Commit();

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber();
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber();
        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunBackgroundReportFromCard(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, false);

        AddExpectedErrorMessage(TempErrorMessage, PlatformEmptyErr);
        AddExpectedErrorMessage(TempErrorMessage, PlatformEmptyErr);
        AddExpectedErrorMessage(TempErrorMessage, NoDataOutputErr);
        AssertActivityLog(TempErrorMessage);

        LibraryTempNVBufferHandler.AssertQueueEmpty();

        AssertReportInboxEmpty();

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 0);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 0);
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_TwoCustomer_A_DataNoEmail_B_DataNoEmail_DoNotPrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" with entries, email is not specified and Customer "B" with entries, email is not specified. "Print Remaining" = FALSE, Filter = "A|B"
        Initialize();

        PrepareCustomerWithEntries(Customer[1], '', GetStandardStatementReportID());
        PrepareCustomerWithEntries(Customer[2], '', GetStandardStatementReportID());
        Commit();

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber();
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber();
        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunBackgroundReportFromCard(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, false);

        AddExpectedErrorMessage(TempErrorMessage, TargetEmailAddressErr);
        AddExpectedErrorMessage(TempErrorMessage, TargetEmailAddressErr);
        AddExpectedErrorMessage(TempErrorMessage, NoDataOutputErr);
        AssertActivityLog(TempErrorMessage);

        LibraryTempNVBufferHandler.AssertQueueEmpty();

        AssertReportInboxEmpty();

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 0);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 0);
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_TwoCustomer_A_NoDataEmail_B_DataNoEmail_DoNotPrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" without entries, email is specified and Customer "B" with entries, email is not specified. "Print Remaining" = FALSE, Filter = "A|B"
        Initialize();

        PrepareCustomerWithoutEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID());
        PrepareCustomerWithEntries(Customer[2], '', GetStandardStatementReportID());
        Commit();

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber();
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber();
        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunBackgroundReportFromCard(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, false);

        //AddExpectedErrorMessage(TempErrorMessage, NoDataOutputErr);
        AddExpectedErrorMessage(TempErrorMessage, PlatformEmptyErr);
        AddExpectedErrorMessage(TempErrorMessage, TargetEmailAddressErr);
        AddExpectedErrorMessage(TempErrorMessage, NoDataOutputErr);
        AssertActivityLog(TempErrorMessage);

        LibraryTempNVBufferHandler.AssertQueueEmpty();

        AssertReportInboxEmpty();

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 0);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 0);
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_TwoCustomer_A_DataEmail_B_DataEmail_DoNotPrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" with entries, email is specified and Customer "B" with entries, email is specified. "Print Remaining" = FALSE, Filter = "A|B"
        Initialize();

        PrepareCustomerWithEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID());
        PrepareCustomerWithEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID());
        Commit();

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber();
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber();
        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunBackgroundReportFromCard(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, false);

        // email attachment + body
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[1]));
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleHtml(Customer[1]));
        // pdf to add to zip for report inbox
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[1]));

        // email attachment + body
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[2]));
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleHtml(Customer[2]));
        // pdf to add to zip for report inbox
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[2]));

        LibraryTempNVBufferHandler.AssertQueueEmpty();

        AssertReportInboxCountZip(1);

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 1);
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_TwoCustomer_A_DataEmail_B_DataNoEmail_DoNotPrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" with entries, email is specified and Customer "B" with entries, email is not specified. "Print Remaining" = FALSE, Filter = "A|B"
        Initialize();

        PrepareCustomerWithEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID());
        PrepareCustomerWithEntries(Customer[2], '', GetStandardStatementReportID());
        Commit();

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber();
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber();
        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunBackgroundReportFromCard(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, false);

        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[1]));
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleHtml(Customer[1]));
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[1]));
        LibraryTempNVBufferHandler.AssertQueueEmpty();

        AssertReportInboxCountPdf(1);

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 0);
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Email_Background_TwoCustomer_A_DataEmail_B_NoDataEmail_DoNotPrintIfEmailMissing()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueue email when Customer "A" with entries, email is specified and Customer "B" without entries, email is specified. "Print Remaining" = FALSE, Filter = "A|B"
        Initialize();

        PrepareCustomerWithEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID());
        PrepareCustomerWithoutEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID());
        Commit();

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber();
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber();
        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);
        RunBackgroundReportFromCard(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, false);

        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[1]));
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleHtml(Customer[1]));
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[1]));
        LibraryTempNVBufferHandler.AssertQueueEmpty();

        AssertReportInboxCountPdf(1);

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 0);
    end;

    [Test]
    [HandlerFunctions('StandardStatementReportHandler')]
    [Scope('OnPrem')]
    procedure Print_SingleCustomer_BlankAddress()
    var
        Customer: Record Customer;
        RepSelectionsStdStmt: Codeunit "Rep. Selections - Std. Stmt.";
    begin
        // [FEATURE] [Print]
        // [SCENARIO] Send to print when Customer "A" with entries, email is not specified and Customer "B" does not exist.
        Initialize();

        PrepareCustomerWithEntries(Customer, '', GetStandardStatementReportID());
        Commit();

        BindSubscription(RepSelectionsStdStmt);
        RunReportWithParameters(GetSingleCustomerFilter(Customer), StandardStatementReportOutputType::Print, false);

        Customer.Find();
        Customer.TestField("Last Statement No.", 1);

        Customer.Find();
        Customer.TestField("Last Statement No.", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Print_SingleCustomer_NoEntries()
    var
        Customer: Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        RepSelectionsStdStmt: Codeunit "Rep. Selections - Std. Stmt.";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Print]
        // [SCENARIO] Send to download when Customer "A" without entries and Customer "B" does not exist.
        Initialize();

        PrepareCustomerWithoutEntries(Customer, CustomerEmailTxt, GetStandardStatementReportID());
        Commit();

        BindSubscription(RepSelectionsStdStmt);

        ErrorMessages.Trap();
        asserterror RunReportWithParameters(GetSingleCustomerFilter(Customer), StandardStatementReportOutputType::PDF, false);

        AddExpectedErrorMessage(TempErrorMessage, PlatformEmptyErr);
        AddExpectedErrorMessage(TempErrorMessage, NoDataOutputErr);
        AssertErrorsOnErrorMessagesPage(ErrorMessages, TempErrorMessage);

        Customer.Find();
        Customer.TestField("Last Statement No.", 0);
    end;

    [Test]
    [HandlerFunctions('StandardStatementReportHandler')]
    [Scope('OnPrem')]
    procedure Print_SingleCustomer()
    var
        Customer: Record Customer;
        RepSelectionsStdStmt: Codeunit "Rep. Selections - Std. Stmt.";
    begin
        // [FEATURE] [Print]
        // [SCENARIO] Send to print when Customer "A" with entries and Customer "B" does not exist.
        Initialize();

        PrepareCustomerWithEntries(Customer, CustomerEmailTxt, GetStandardStatementReportID());
        Commit();

        BindSubscription(RepSelectionsStdStmt);
        RunReportWithParameters(GetSingleCustomerFilter(Customer), StandardStatementReportOutputType::Print, false);

        Customer.Find();
        Customer.TestField("Last Statement No.", 1);
    end;

    [Test]
    [HandlerFunctions('StandardStatementReportHandler')]
    [Scope('OnPrem')]
    procedure Print_TwoCustomers_A_Data_B_Data()
    var
        Customer: array[2] of Record Customer;
        RepSelectionsStdStmt: Codeunit "Rep. Selections - Std. Stmt.";
    begin
        // [FEATURE] [Print]
        // [SCENARIO] Send to print when Customer "A" with entries and Customer "B" with entries. Filter = "A|B"
        Initialize();

        PrepareCustomerWithEntries(Customer[1], '', GetStandardStatementReportID());
        PrepareCustomerWithEntries(Customer[2], '', GetStandardStatementReportID());
        Commit();

        BindSubscription(RepSelectionsStdStmt);
        RunReportWithParameters(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Print, false);

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 1);
    end;

    [Test]
    [HandlerFunctions('StandardStatementReportHandler')]
    [Scope('OnPrem')]
    procedure Print_TwoCustomers_A_NoData_B_Data()
    var
        Customer: array[2] of Record Customer;
        RepSelectionsStdStmt: Codeunit "Rep. Selections - Std. Stmt.";
    begin
        // [FEATURE] [Print]
        // [SCENARIO] Send to print when Customer "A" without entries and Customer "B" with entries.Filter = "A|B"
        Initialize();

        PrepareCustomerWithoutEntries(Customer[1], '', GetStandardStatementReportID());
        PrepareCustomerWithEntries(Customer[2], '', GetStandardStatementReportID());
        Commit();

        BindSubscription(RepSelectionsStdStmt);
        RunReportWithParameters(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Print, false);

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 0);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 1);
    end;

    [Test]
    [HandlerFunctions('StandardStatementReportHandler')]
    [Scope('OnPrem')]
    procedure Print_TwoCustomers_A_Data_B_NoData()
    var
        Customer: array[2] of Record Customer;
        RepSelectionsStdStmt: Codeunit "Rep. Selections - Std. Stmt.";
    begin
        // [FEATURE] [Print]
        // [SCENARIO] Send to print when Customer "A" with entries and Customer "B" without entries. Filter = "A|B"
        Initialize();

        PrepareCustomerWithEntries(Customer[1], '', GetStandardStatementReportID());
        PrepareCustomerWithoutEntries(Customer[2], '', GetStandardStatementReportID());
        Commit();

        BindSubscription(RepSelectionsStdStmt);
        RunReportWithParameters(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Print, false);

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Print_TwoCustomers_A_NoData_B_NoData()
    var
        Customer: array[2] of Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        RepSelectionsStdStmt: Codeunit "Rep. Selections - Std. Stmt.";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Print]
        // [SCENARIO] Send to download when Customer "A" without entries and Customer "B" without entries. Filter = "A|B"
        Initialize();

        PrepareCustomerWithoutEntries(Customer[1], '', GetStandardStatementReportID());
        PrepareCustomerWithoutEntries(Customer[2], '', GetStandardStatementReportID());
        Commit();

        BindSubscription(RepSelectionsStdStmt);

        ErrorMessages.Trap();
        asserterror RunReportWithParameters(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Word, false);

        AddExpectedErrorMessage(TempErrorMessage, PlatformEmptyErr);
        AddExpectedErrorMessage(TempErrorMessage, PlatformEmptyErr);
        AddExpectedErrorMessage(TempErrorMessage, NoDataOutputErr);
        AssertErrorsOnErrorMessagesPage(ErrorMessages, TempErrorMessage);

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 0);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 0);
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Print_Background_SingleCustomer_BlankAddress()
    var
        Customer: Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
    begin
        // [FEATURE] [Print] [Job Queue]
        // [SCENARIO] Enqueue to download when Customer "A" with entries, email is not specified and Customer "B" does not exist.
        Initialize();

        PrepareCustomerWithEntries(Customer, '', GetStandardStatementReportID());
        Commit();

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber();
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber();
        BindSubscription(LibraryTempNVBufferHandler);
        RunBackgroundReportFromCard(GetSingleCustomerFilter(Customer), StandardStatementReportOutputType::Word, false);

        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleDocx(Customer));
        LibraryTempNVBufferHandler.AssertQueueEmpty();

        AssertReportInboxCountWord(1);

        Customer.Find();
        Customer.TestField("Last Statement No.", 1);
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Print_Background_SingleCustomer_NoEntries()
    var
        Customer: Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
    begin
        // [FEATURE] [Print] [Job Queue]
        // [SCENARIO] Enqueue to download when Customer "A" without entries and Customer "B" without entries. Filter = "A"
        Initialize();

        PrepareCustomerWithoutEntries(Customer, CustomerEmailTxt, GetStandardStatementReportID());
        Commit();

        BindSubscription(LibraryTempNVBufferHandler);
        RunBackgroundReportFromCard(GetSingleCustomerFilter(Customer), StandardStatementReportOutputType::Word, false);

        AddExpectedErrorMessage(TempErrorMessage, PlatformEmptyErr);
        AddExpectedErrorMessage(TempErrorMessage, NoDataOutputErr);
        AssertActivityLog(TempErrorMessage);

        LibraryTempNVBufferHandler.AssertQueueEmpty();

        AssertReportInboxEmpty();

        Customer.Find();
        Customer.TestField("Last Statement No.", 0);
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Print_Background_SingleCustomer()
    var
        Customer: Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
    begin
        // [FEATURE] [Print] [Job Queue]
        // [SCENARIO] Enqueue to print when Customer "A" with entries and Customer "B" does not exist. Filter = "A"
        Initialize();

        PrepareCustomerWithEntries(Customer, CustomerEmailTxt, GetStandardStatementReportID());
        Commit();

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber();
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber();
        BindSubscription(LibraryTempNVBufferHandler);
        RunBackgroundReportFromCard(GetSingleCustomerFilter(Customer), StandardStatementReportOutputType::Word, false);

        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleDocx(Customer));
        LibraryTempNVBufferHandler.AssertQueueEmpty();

        AssertReportInboxCountWord(1);

        Customer.Find();
        Customer.TestField("Last Statement No.", 1);
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Print_Background_TwoCustomers_A_Data_B_Data()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
    begin
        // [FEATURE] [Print] [Job Queue]
        // [SCENARIO] Enqueue to Download when Customer "A" with entries and Customer "B" with entries. Filter = "A|B"
        Initialize();

        PrepareCustomerWithEntries(Customer[1], '', GetStandardStatementReportID());
        PrepareCustomerWithEntries(Customer[2], '', GetStandardStatementReportID());
        Commit();

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber();
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber();
        BindSubscription(LibraryTempNVBufferHandler);
        RunBackgroundReportFromCard(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Word, false);

        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleDocx(Customer[1]));
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleDocx(Customer[2]));

        LibraryTempNVBufferHandler.AssertQueueEmpty();

        AssertReportInboxCountZip(1);

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 1);
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Print_Background_TwoCustomers_A_NoData_B_Data()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
    begin
        // [FEATURE] [Print] [Job Queue]
        // [SCENARIO] Enqueue to Download when Customer "A" without entries and Customer "B" with entries. Filter = "A|B"
        Initialize();

        PrepareCustomerWithoutEntries(Customer[1], '', GetStandardStatementReportID());
        PrepareCustomerWithEntries(Customer[2], '', GetStandardStatementReportID());
        Commit();

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber();
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber();
        BindSubscription(LibraryTempNVBufferHandler);
        RunBackgroundReportFromCard(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Word, false);

        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleDocx(Customer[2]));
        LibraryTempNVBufferHandler.AssertQueueEmpty();

        AssertReportInboxCountWord(1);

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 0);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 1);
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Print_Background_TwoCustomers_A_Data_B_NoData()
    var
        Customer: array[2] of Record Customer;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
    begin
        // [FEATURE] [Print] [Job Queue]
        // [SCENARIO] Enqueue to Download when Customer "A" with entries and Customer "B" without entries. Filter = "A|B"
        Initialize();

        PrepareCustomerWithEntries(Customer[1], '', GetStandardStatementReportID());
        PrepareCustomerWithoutEntries(Customer[2], '', GetStandardStatementReportID());
        Commit();

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber();
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber();
        BindSubscription(LibraryTempNVBufferHandler);
        RunBackgroundReportFromCard(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Word, false);

        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleDocx(Customer[1]));
        LibraryTempNVBufferHandler.AssertQueueEmpty();

        AssertReportInboxCountWord(1);

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 0);
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Print_Background_TwoCustomers_A_NoData_B_NoData()
    var
        Customer: array[2] of Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
    begin
        // [FEATURE] [Print] [Job Queue]
        // [SCENARIO] Enqueue to Download when Customer "A" without entries and Customer "B" without entries. Filter = "A|B"
        Initialize();

        PrepareCustomerWithoutEntries(Customer[1], '', GetStandardStatementReportID());
        PrepareCustomerWithoutEntries(Customer[2], '', GetStandardStatementReportID());
        Commit();

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber();
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber();
        BindSubscription(LibraryTempNVBufferHandler);
        RunBackgroundReportFromCard(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Word, false);

        AddExpectedErrorMessage(TempErrorMessage, PlatformEmptyErr);
        AddExpectedErrorMessage(TempErrorMessage, PlatformEmptyErr);
        AddExpectedErrorMessage(TempErrorMessage, NoDataOutputErr);
        AssertActivityLog(TempErrorMessage);

        LibraryTempNVBufferHandler.AssertQueueEmpty();

        AssertReportInboxEmpty();

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 0);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_AddExpectedErrorMessage()
    var
        ErrorMessage: Record "Error Message";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Can't insert non temporary error entry
        asserterror AddExpectedErrorMessage(ErrorMessage, 'Some error');
        Assert.ExpectedError('Error message record must be temporary');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_CustomReportSelection_CheckSendToEmail()
    var
        CustomReportLayout: Record "Custom Report Layout";
        CustomReportSelection: Record "Custom Report Selection";
        Customer: Record Customer;
        DataRecRef: RecordRef;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] CheckEmailSendTo of TAB9657 throws error when "Send to Email" is blank
        Initialize();

        CreateCustomer(Customer);

        InsertCustomReportSelectionCustomer(
          CustomReportSelection, Customer."No.", GetStandardStatementReportID(), true, true,
          CustomReportLayout.InitBuiltInLayout(GetStandardStatementReportID(), CustomReportLayout.Type::Word.AsInteger()),
          '', CustomReportSelection.Usage::"C.Statement");

        DataRecRef.GETTABLE(Customer);
        asserterror CustomReportSelection.CheckEmailSendTo(DataRecRef);

        Assert.ExpectedError(StrSubstNo('%1 %2, %3', TargetEmailAddressErr, Customer.RECORDID, CustomReportSelection.Usage));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_COD8811_Run_Xml_Negative()
    var
        JobQueueEntry: Record "Job Queue Entry";
        TempErrorMessage: Record "Error Message" temporary;
    begin
        // [FEATURE] [Job Queue] [Xml] [UT]
        // [SCENARIO] Enqueue to print when Customer "A" with entries and Customer "B" with entries. Filter = "A|B"
        Initialize();

        JobQueueEntry.ID := CreateGuid();
        JobQueueEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(JobQueueEntry."User ID"));
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CODEUNIT::"Customer Statement via Queue";
        JobQueueEntry.Insert();
        CODEUNIT.Run(JobQueueEntry."Object ID to Run", JobQueueEntry);

        AddExpectedErrorMessage(TempErrorMessage, RequestParametersErr);
        AssertActivityLog(TempErrorMessage);
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Test_Email_Background_SingleCustomer_DataEmail()
    begin
        Email_Background_SingleCustomer_DataEmail();
    end;

    procedure Email_Background_SingleCustomer_DataEmail()
    var
        Customer: array[2] of Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        ConnectorMock: Codeunit "Connector Mock";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueueed email with Customer "A" having entries failed with SMTP error
        Initialize();

        PrepareCustomerWithEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID());
        Commit();

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber();
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber();
        BindSubscription(LibraryTempNVBufferHandler);
        // Email sending throws error (we don't handle it)
        ConnectorMock.FailOnSend(true);
        Commit();
        RunBackgroundReportFromCard(GetSingleCustomerFilter(Customer[1]), StandardStatementReportOutputType::Email, false);

        AddExpectedErrorMessage(TempErrorMessage, FailedToSendEmailErr);
        AssertActivityLog(TempErrorMessage);
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[1])); // buffer to delete temp file
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleHtml(Customer[1])); // buffer to delete temp file
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[1])); // buffer to add to report inbox
        LibraryTempNVBufferHandler.AssertQueueEmpty();

        Commit();
        AssertReportInboxCountPdf(1);

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 1);
    end;

    [Test]
    [HandlerFunctions('StandardStatementOKRequestPageHandler,StartJobQueueNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure Test_Email_Background_TwoCustomer_A_DataEmail_B_DataEmail()
    begin
        Email_Background_TwoCustomer_A_DataEmail_B_DataEmail();
    end;

    procedure Email_Background_TwoCustomer_A_DataEmail_B_DataEmail()
    var
        Customer: array[2] of Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        ConnectorMock: Codeunit "Connector Mock";
    begin
        // [FEATURE] [Email] [Job Queue]
        // [SCENARIO] Enqueueed email with Customers "A" and "B" both having entries failed with SMTP error
        Initialize();

        PrepareCustomerWithEntries(Customer[1], CustomerEmailTxt, GetStandardStatementReportID());
        PrepareCustomerWithEntries(Customer[2], CustomerEmailTxt, GetStandardStatementReportID());
        Commit();

        LibraryTempNVBufferHandler.DeactivateDefaultSubscriber();
        LibraryTempNVBufferHandler.ActivateBackgroundCaseSubscriber();
        BindSubscription(LibraryTempNVBufferHandler);
        // Email sending throws error (we don't handle it)
        ConnectorMock.FailOnSend(true);
        Commit();
        RunBackgroundReportFromCard(GetTwoCustomersFilter(Customer), StandardStatementReportOutputType::Email, false);

        AddExpectedErrorMessage(TempErrorMessage, FailedToSendEmailErr);
        AddExpectedErrorMessage(TempErrorMessage, FailedToSendEmailErr);
        AssertActivityLog(TempErrorMessage);

        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[1])); // buffer to delete temp file
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleHtml(Customer[1])); // buffer to delete temp file
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[1])); // buffer to add to report inbox
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[2])); // buffer to delete temp file
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitleHtml(Customer[2])); // buffer to delete temp file
        LibraryTempNVBufferHandler.AssertEntry(GetStatementTitlePdf(Customer[2])); // buffer to add to report inbox
        LibraryTempNVBufferHandler.AssertQueueEmpty();

        Commit();
        AssertReportInboxCountZip(1);

        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('StandardStatementOKRequestPageHandler')]
    procedure SendEmailFromCustomerWhenEmailIsBlankInCustomReportSelection()
    var
        CustomReportSelection: Record "Custom Report Selection";
        Customer: Record Customer;
        ReportSelections: Record "Report Selections";
        SalesHeader: Record "Sales Header";
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [SCENARIO 458928] The report should pick up the email address from the Customer Card  if Email on Document Layout is blank.
        Initialize();

        // [GIVEN] Create customer and assign email.
        CreateCustomer(Customer);
        Customer.Validate("E-Mail", CustomerEmailTxt);
        Customer.Modify(true);

        // [GIVEN] Create and Post sales invoice.
        CreateSalesInvoice(SalesHeader, Customer);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Create Report ID in Report Selection table.
        InsertReportSelections(
        ReportSelections, GetStandardStatementReportID(), false, false, '', ReportSelections.Usage::"C.Statement");

        // [GIVEN] Set Sendingdisable On SMTPMailHandler
        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);

        // [GIVEN] Insert Document Layout from Customer without Email
        InsertCustomReportSelectionCustomer(
          CustomReportSelection, Customer."No.", Report::"Standard Statement", false, false,
          '', '', CustomReportSelection.Usage::"C.Statement");

        // [THEN] Run Standard Statement report from Customer card.
        RunReportFromCard(Customer, StandardStatementReportOutputType::Email, false);

        // [VERIFY] Customer name exist on the NVBufferHandlerTable and Mail Queue is Empty
        LibraryTempNVBufferHandler.AssertEntry(Customer.Name);
        LibraryTempNVBufferHandler.AssertQueueEmpty();

        // [VERIFY] Email sent successfully by checking Customer statement Count increase to 1
        Customer.Get(Customer."No.");
        Assert.AreEqual(Customer."Last Statement No.", 1, StatementCountErr);
    end;

    [Test]
    procedure PrintCustomerStatementWhenCustomerNotInFilterAndHasCustomDocLayout()
    var
        Customer: array[2] of Record Customer;
        SalesHeader: Record "Sales Header";
        CustomReportLayout: Record "Custom Report Layout";
        SendingProfileCode: Code[20];
        CustomReportLayoutCode: Code[20];
    begin
        // [SCENARIO 546893] Run Customer Statement report when some customers have custom Document Layouts for Customer Statement and they are NOT included in report filter.

        // [GIVEN] Document Sending Profile P1.
        SendingProfileCode := CreateDocumentSendingProfile();

        // [GIVEN] Customer C1 with Document Sending Profile P1 and with posted Sales Invoice.
        LibrarySales.CreateCustomer(Customer[1]);
        Customer[1].Validate("Document Sending Profile", SendingProfileCode);
        Customer[1].Modify(true);
        CreateSalesInvoice(SalesHeader, Customer[1]);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Custom Report Layout RL1 with Report ID 1316 and Type RDLC.
        CustomReportLayoutCode := CustomReportLayout.InitBuiltInLayout(1316, CustomReportLayout.Type::RDLC.AsInteger());

        // [GIVEN] Customer C2 with Customer Report Selections for Customer Statement with Report ID 1316 and Custom Layout Description RL1.
        LibrarySales.CreateCustomer(Customer[2]);
        LibrarySales.CreateCustomerDocumentLayout(Customer[2]."No.", Enum::"Report Selection Usage"::"C.Statement", 1316, CustomReportLayoutCode, '');
        CreateSalesInvoice(SalesHeader, Customer[2]);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Run Standard Statement report with filter by Customer's Document Sending Profile P1 and Report Output Print.
        RunReportWithCustomerFieldsFilter(Customer[1].FieldNo("Document Sending Profile"), SendingProfileCode, StandardStatementReportOutputType::Print, false);

        // [THEN] Customer Statement is printed only for Customer C1 with default report layout. No errors are thrown.
        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 0);
    end;

    [Test]
    procedure PrintCustomerStatementWhenCustomerInFilterAndHasCustomDocLayout()
    var
        Customer: array[2] of Record Customer;
        SalesHeader: Record "Sales Header";
        CustomReportLayout: Record "Custom Report Layout";
        SendingProfileCode: Code[20];
        CustomReportLayoutCode: Code[20];
    begin
        // [SCENARIO 546893] Run Customer Statement report when some customers have custom Document Layouts for Customer Statement and they are included in report filter.

        // [GIVEN] Document Sending Profile P1.
        SendingProfileCode := CreateDocumentSendingProfile();

        // [GIVEN] Customer C1 with Document Sending Profile P1 and with posted Sales Invoice.
        LibrarySales.CreateCustomer(Customer[1]);
        Customer[1].Validate("Document Sending Profile", SendingProfileCode);
        Customer[1].Modify(true);
        CreateSalesInvoice(SalesHeader, Customer[1]);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Custom Report Layout RL1 with Report ID 1316 and Type RDLC.
        CustomReportLayoutCode := CustomReportLayout.InitBuiltInLayout(1316, CustomReportLayout.Type::RDLC.AsInteger());

        // [GIVEN] Customer C2 with Customer Report Selections for Customer Statement with Report ID 1316 and Custom Layout Description RL1.
        // [GIVEN] Customer C2 has Document Sending Profile P1 and posted Sales Invoice.
        LibrarySales.CreateCustomer(Customer[2]);
        LibrarySales.CreateCustomerDocumentLayout(Customer[2]."No.", Enum::"Report Selection Usage"::"C.Statement", 1316, CustomReportLayoutCode, '');
        Customer[2].Validate("Document Sending Profile", SendingProfileCode);
        Customer[2].Modify(true);
        CreateSalesInvoice(SalesHeader, Customer[2]);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Run Standard Statement report with filter by Customer's Document Sending Profile P1 and Report Output Print.
        RunReportWithCustomerFieldsFilter(Customer[1].FieldNo("Document Sending Profile"), SendingProfileCode, StandardStatementReportOutputType::Print, false);

        // [THEN] Customer Statement is printed for Customer C1 with DEFAULT report layout. No errors are thrown.
        // [THEN] Customer Statement is printed for Customer C2 with CUSTOM report layout.
        Customer[1].Find();
        Customer[1].TestField("Last Statement No.", 1);
        Customer[2].Find();
        Customer[2].TestField("Last Statement No.", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('StandardStatementOKRequestPageHandler')]
    procedure SendEmailForCustomerUsingLayoutOnCustomReportSelection()
    var
        Customer: array[2] of Record Customer;
        CustomReportSelection: Record "Custom Report Selection";
        ReportSelections: Record "Report Selections";
        SalesHeader: Record "Sales Header";
        LibraryTempNVBufferHandler: Codeunit "Library - TempNVBufferHandler";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
    begin
        // [SCENARIO 539373] When Emailing multiple customer, correct layoutis used to send the customer
        Initialize();

        // [GIVEN] Create Customers
        CreateCustomer(Customer[1]);
        CreateCustomer(Customer[2]);

        // [GIVEN] Update E-mail id to both the customer[1]
        Customer[1].Validate("E-Mail", CustomerEmailTxt);
        Customer[1].Modify(true);

        // [GIVEN] Update E-mail id to both the customer[2]
        Customer[2].Validate("E-Mail", CustomerEmailTxt);
        Customer[2].Modify(true);

        // [GIVEN] Create and Post sales invoice for Customer[1]
        CreateSalesInvoice(SalesHeader, Customer[1]);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Create and Post sales invoice for Customer[2]
        CreateSalesInvoice(SalesHeader, Customer[2]);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Create Report ID in Report Selection table.
        InsertReportSelections(
        ReportSelections, GetStandardStatementReportID(), false, false, '', ReportSelections.Usage::"C.Statement");

        // [GIVEN] Set Sending disable On SMTPMailHandler
        BindSubscription(LibraryTempNVBufferHandler);
        LibrarySMTPMailHandler.SetDisableSending(true);
        BindSubscription(LibrarySMTPMailHandler);

        // [GIVEN] Insert Document Layout for Customer[1]
        InsertCustomReportSelectionCustomer(
            CustomReportSelection, Customer[1]."No.", Report::"Standard Statement", false, false,
            '', '', CustomReportSelection.Usage::"C.Statement");

        // [WHEN] Run Standard Statement report from Customer card.
        RunReportFromCard(Customer[1], StandardStatementReportOutputType::Email, false);

        // [THEN] Customer name exist on the NVBufferHandlerTable and Mail Queue is Empty
        LibraryTempNVBufferHandler.AssertEntry(Customer[1].Name);
        LibraryTempNVBufferHandler.AssertQueueEmpty();

        // [WHEN] Run Custom Statement report from Customer card for Customer[2].
        InsertCustomReportSelectionCustomer(
            CustomReportSelection, Customer[2]."No.", Report::"Standard Statement", false, false,
            '', '', CustomReportSelection.Usage::"C.Statement");

        // [WHEN] Run Standard Statement report from Customer card.
        RunReportFromCard(Customer[2], StandardStatementReportOutputType::Email, false);

        // [THEN] Customer name exist on the NVBufferHandlerTable and Mail Queue is Empty
        LibraryTempNVBufferHandler.AssertEntry(Customer[2].Name);
        LibraryTempNVBufferHandler.AssertQueueEmpty();

        // [THEN] Email sent successfully by checking Customer statement Count increase to 1
        Customer[1].Find();
        Assert.AreEqual(Customer[1]."Last Statement No.", 1, StatementCountErr);
    end;

    local procedure Initialize()
    var
        ReportSelections: Record "Report Selections";
        CustomReportSelection: Record "Custom Report Selection";
        InventorySetup: Record "Inventory Setup";
        CompanyInformation: Record "Company Information";
        ReportLayoutSelection: Record "Report Layout Selection";
        JobQueueEntry: Record "Job Queue Entry";
        ActivityLog: Record "Activity Log";
        ReportInbox: Record "Report Inbox";
        LibraryEmail: Codeunit "Library - Email";
        CustomerCard: TestPage "Customer Card";
    begin
        LibraryEmail.SetUpEmailAccount();
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Rep. Selections - Std. Stmt.");

        LibraryVariableStorage.Clear();
        CustomReportSelection.DeleteAll();
        ReportSelections.DeleteAll();
        ReportLayoutSelection.DeleteAll();
        LibrarySetupStorage.Restore();

        // Page opening may cause DB (i.e. Business Chart insertion) transaction. So, open, close, commit  and reopen
        CustomerCard.OpenView();
        CustomerCard.Close();

        // Job Queue Entry could not be deleted when test fails unexpectedly. That caused other false negative results
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"Customer Statement via Queue");
        JobQueueEntry.SetRange("User ID", UserId);
        JobQueueEntry.DeleteAll();

        // We should clean legacy activity log.
        ActivityLog.SetRange("User ID", UserId);
        ActivityLog.DeleteAll();

        // We should clean legacy report inbox.
        ReportInbox.SetRange("User ID", UserId);
        ReportInbox.SetRange("Report ID", GetStandardStatementReportID());
        ReportInbox.DeleteAll();

        Commit();

        if Initialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Rep. Selections - Std. Stmt.");

        Initialized := true;

        CompanyInformation.Get();
        CompanyInformation."SWIFT Code" := 'A';
        CompanyInformation.Modify();

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryInventory.NoSeriesSetup(InventorySetup);
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Company Information");
        Commit();

        LibraryFileMgtHandler.SetDownloadSubscriberActivated(true);
        BindSubscription(LibraryFileMgtHandler);

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Rep. Selections - Std. Stmt.");
    end;

    local procedure AddExpectedErrorMessage(var TempErrorMessage: Record "Error Message" temporary; ErrorMessage: Text)
    begin
        Assert.IsTrue(TempErrorMessage.IsTemporary, 'Error message record must be temporary');
        TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, ErrorMessage);
    end;

    local procedure CreateCustomer(var Customer: Record Customer): Code[20]
    var
        CountryRegion: Record "Country/Region";
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Delete();
        // TFS 332244: We must support special symbols in customer "No."
        Customer."No." := CopyStr(LibraryUtility.GenerateGUID() + '&1', 1, MaxStrLen(Customer."No."));
        Customer.Insert();

        Customer.Validate(Name, LibraryUtility.GenerateGUID());
        Customer.Validate(Address, LibraryUtility.GenerateGUID());

        LibraryERM.CreateCountryRegion(CountryRegion);

        Customer.Validate("Country/Region Code", CountryRegion.Code);
        Customer.Validate(City, LibraryUtility.GenerateGUID());
        Customer.Validate("Post Code", LibraryUtility.GenerateGUID());
        Customer.Modify(true);

        exit(Customer."No.");
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));  // Take Random Unit Price greater than 1000 to avoid rounding issues.
        Item.Validate("Last Direct Cost", Item."Unit Price");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateSalesInvoice(var SalesHeader: Record "Sales Header"; Customer: Record Customer)
    var
        SalesLine: Record "Sales Line";
        ShippingAgent: Record "Shipping Agent";
    begin
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        LibraryInventory.CreateShippingAgent(ShippingAgent);
        SalesHeader.Validate("Package Tracking No.", GenerateRandomPackageTrackingNo());
        SalesHeader.Validate("Shipping Agent Code", ShippingAgent.Code);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), 1);
    end;

    local procedure CreateDocumentSendingProfile(): Code[20]
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        DocumentSendingProfile.Code := LibraryUtility.GenerateGUID();
        DocumentSendingProfile.Insert();
        exit(DocumentSendingProfile.Code);
    end;

    local procedure GetStandardStatementReportID(): Integer
    begin
        exit(REPORT::"Standard Statement");
    end;

    local procedure GenerateRandomPackageTrackingNo(): Text[50]
    var
        DummySalesHeader: Record "Sales Header";
    begin
        exit(CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(DummySalesHeader."Package Tracking No.")),
            1, MaxStrLen(DummySalesHeader."Package Tracking No.")));
    end;

    [Scope('OnPrem')]
    procedure GetLibraryVariableStorage(var LibraryVariableStorageReturn: Codeunit "Library - Variable Storage")
    begin
        LibraryVariableStorageReturn := LibraryVariableStorage;
    end;

    local procedure GetSingleCustomerFilter(Customer: Record Customer): Text
    begin
        exit(StrSubstNo(EscapeTok, Customer."No."));
    end;

    local procedure GetTwoCustomersFilter(Customer: array[2] of Record Customer): Text
    begin
        exit(StrSubstNo('%1|%2', StrSubstNo(EscapeTok, Customer[1]."No."), StrSubstNo(EscapeTok, Customer[2]."No.")));
    end;

    local procedure GetStatementTitleDocx(Customer: Record Customer): Text
    begin
        exit(StrSubstNo(StatementTitleDocxTxt, Customer.Name, Format(WorkDate(), 0, 9)));
    end;

    local procedure GetStatementTitlePdf(Customer: Record Customer): Text
    begin
        exit(StrSubstNo(StatementTitlePdfTxt, Customer.Name, Format(WorkDate(), 0, 9)));
    end;

    local procedure GetStatementTitleHtml(Customer: Record Customer): Text
    begin
        exit(StrSubstNo(StatementTitleHtmlTxt, Customer.Name, Format(WorkDate(), 0, 9)));
    end;

    local procedure InsertCustomReportSelectionCustomer(var CustomReportSelection: Record "Custom Report Selection"; CustomerNo: Code[20]; ReportID: Integer; UseForEmailAttachment: Boolean; UseForEmailBody: Boolean; EmailBodyLayoutCode: Code[20]; SendToAddress: Text[200]; ReportUsage: Enum "Report Selection Usage")
    begin
        CustomReportSelection.Init();
        CustomReportSelection.Validate("Source Type", DATABASE::Customer);
        CustomReportSelection.Validate("Source No.", CustomerNo);
        CustomReportSelection.Validate(Usage, ReportUsage);
        CustomReportSelection.Validate(Sequence, CustomReportSelection.Count + 1);
        CustomReportSelection.Validate("Report ID", ReportID);
        CustomReportSelection.Validate("Use for Email Attachment", UseForEmailAttachment);
        CustomReportSelection.Validate("Use for Email Body", UseForEmailBody);
        CustomReportSelection.Validate("Email Body Layout Code", EmailBodyLayoutCode);
        CustomReportSelection.Validate("Send To Email", SendToAddress);
        CustomReportSelection.Insert(true);
    end;

    local procedure InsertReportSelections(var ReportSelections: Record "Report Selections"; ReportID: Integer; UseForEmailAttachment: Boolean; UseForEmailBody: Boolean; EmailBodyLayoutCode: Code[20]; ReportUsage: Enum "Report Selection Usage")
    begin
        ReportSelections.SetRange(Usage, ReportUsage);
        ReportSelections.SetRange(Sequence, '1');
        ReportSelections.SetRange("Report ID", ReportID);
        if not ReportSelections.IsEmpty() then
            exit;

        ReportSelections.Init();
        ReportSelections.Validate(Usage, ReportUsage);
        ReportSelections.Validate(Sequence, '1');
        ReportSelections.Validate("Report ID", ReportID);
        ReportSelections.Validate("Use for Email Attachment", UseForEmailAttachment);
        ReportSelections.Validate("Use for Email Body", UseForEmailBody);
        ReportSelections.Validate("Email Body Layout Code", EmailBodyLayoutCode);
        ReportSelections.Insert(true);
    end;

    local procedure PrepareCustomerWithEntries(var Customer: Record Customer; EmailAddress: Text; ReportId: Integer)
    var
        SalesHeader: Record "Sales Header";
        ReportSelections: Record "Report Selections";
        CustomReportSelection: Record "Custom Report Selection";
        CustomReportLayout: Record "Custom Report Layout";
        CustomReportLayoutCode: Code[20];
    begin
        CreateCustomer(Customer);
        CreateSalesInvoice(SalesHeader, Customer);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        InsertReportSelections(
          ReportSelections, GetStandardStatementReportID(), false, false, '', ReportSelections.Usage::"C.Statement");

        CustomReportLayout.SetRange("Report ID", ReportId);
        CustomReportLayout.SetRange(Type, CustomReportLayout.Type::Word);
        if CustomReportLayout.FindFirst() then
            CustomReportLayoutCode := CustomReportLayout.Code
        else
            CustomReportLayoutCode := CustomReportLayout.InitBuiltInLayout(ReportId, CustomReportLayout.Type::Word.AsInteger());

        InsertCustomReportSelectionCustomer(
          CustomReportSelection, Customer."No.", ReportId, true, true,
          CustomReportLayoutCode, CopyStr(EmailAddress, 1, 200), CustomReportSelection.Usage::"C.Statement");
    end;

    local procedure PrepareCustomerWithoutEntries(var Customer: Record Customer; EmailAddress: Text; ReportId: Integer)
    var
        ReportSelections: Record "Report Selections";
        CustomReportSelection: Record "Custom Report Selection";
        CustomReportLayout: Record "Custom Report Layout";
        CustomReportLayoutCode: Code[20];
    begin
        CreateCustomer(Customer);

        InsertReportSelections(
          ReportSelections, GetStandardStatementReportID(), false, false, '', ReportSelections.Usage::"C.Statement");

        CustomReportLayout.SetRange("Report ID", ReportId);
        CustomReportLayout.SetRange(Type, CustomReportLayout.Type::Word);
        if CustomReportLayout.FindFirst() then
            CustomReportLayoutCode := CustomReportLayout.Code
        else
            CustomReportLayoutCode := CustomReportLayout.InitBuiltInLayout(ReportId, CustomReportLayout.Type::Word.AsInteger());

        InsertCustomReportSelectionCustomer(
          CustomReportSelection, Customer."No.", ReportId, true, true,
          CustomReportLayoutCode, CopyStr(EmailAddress, 1, 200), CustomReportSelection.Usage::"C.Statement");
    end;

    local procedure RunReportFromCard(Customer: Record Customer; ReportOutputType: Option; PrintIfEmailIsMissing: Boolean)
    var
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        CustomerCard: TestPage "Customer Card";
    begin
        LibraryVariableStorage.Enqueue(ReportOutputType);
        LibraryVariableStorage.Enqueue(StrSubstNo(EscapeTok, Customer."No."));
        LibraryVariableStorage.Enqueue(PrintIfEmailIsMissing);

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);

        CustomerCard.OpenEdit();
        CustomerCard.FILTER.SetFilter("No.", StrSubstNo(EscapeTok, Customer."No."));
        CustomerCard."Report Statement".Invoke();
        CustomerCard.Close();
    end;

    local procedure RunReportWithParameters(CustomerFilter: Text; ReportOutputType: Option; PrintRemaining: Boolean)
    var
        CustomerLayoutStatement: Codeunit "Customer Layout - Statement";
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        DotNet_SecurityElement: DotNet "System.Security.SecurityElement";
        OutputTypeInt: Integer;
        MethodTypeInt: Integer;
        ReportParameters: Text;
    begin
        OutputTypeInt := ReportOutputType;

        case ReportOutputType of
            StandardStatementReportOutputType::Email:
                MethodTypeInt := CustomLayoutReporting.GetEmailOption();
            StandardStatementReportOutputType::PDF:
                MethodTypeInt := CustomLayoutReporting.GetPDFOption();
            StandardStatementReportOutputType::Preview:
                MethodTypeInt := CustomLayoutReporting.GetPreviewOption();
            StandardStatementReportOutputType::Print:
                MethodTypeInt := CustomLayoutReporting.GetPrintOption();
            StandardStatementReportOutputType::Word:
                MethodTypeInt := CustomLayoutReporting.GetWordOption();
            StandardStatementReportOutputType::XML:
                MethodTypeInt := CustomLayoutReporting.GetXMLOption();
        end;

        ReportParameters :=
          StrSubstNo(
            ReqParametersTemplatesTxt, Format(WorkDate(), 0, 9), Format(WorkDate(), 0, 9),
            OutputTypeInt, MethodTypeInt, Format(PrintRemaining, 0, 9), DotNet_SecurityElement.Escape(CustomerFilter));

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        CustomerLayoutStatement.RunReportWithParameters(ReportParameters);
    end;

    local procedure RunReportWithCustomerFieldsFilter(FieldNo: Integer; FieldFilter: Text; ReportOutputType: Option; PrintRemaining: Boolean)
    var
        CustomerLayoutStatement: Codeunit "Customer Layout - Statement";
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        DotNet_SecurityElement: DotNet "System.Security.SecurityElement";
        OutputTypeInt: Integer;
        MethodTypeInt: Integer;
        ReportParameters: Text;
    begin
        OutputTypeInt := ReportOutputType;

        case ReportOutputType of
            StandardStatementReportOutputType::Email:
                MethodTypeInt := CustomLayoutReporting.GetEmailOption();
            StandardStatementReportOutputType::PDF:
                MethodTypeInt := CustomLayoutReporting.GetPDFOption();
            StandardStatementReportOutputType::Preview:
                MethodTypeInt := CustomLayoutReporting.GetPreviewOption();
            StandardStatementReportOutputType::Print:
                MethodTypeInt := CustomLayoutReporting.GetPrintOption();
            StandardStatementReportOutputType::Word:
                MethodTypeInt := CustomLayoutReporting.GetWordOption();
            StandardStatementReportOutputType::XML:
                MethodTypeInt := CustomLayoutReporting.GetXMLOption();
        end;

        ReportParameters :=
          StrSubstNo(
            ReqPageParamsTxt, Format(WorkDate(), 0, 9), Format(WorkDate(), 0, 9),
            OutputTypeInt, MethodTypeInt, Format(PrintRemaining, 0, 9), FieldNo, DotNet_SecurityElement.Escape(FieldFilter));

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        CustomerLayoutStatement.RunReportWithParameters(ReportParameters);
    end;

    local procedure RunBackgroundReportFromCard(CustomerFilter: Text; ReportOutputType: Option; PrintRemaining: Boolean)
    var
        TempJobQueueEntry: Record "Job Queue Entry" temporary;
        LibraryJobQueue: Codeunit "Library - Job Queue";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        CustomerCard: TestPage "Customer Card";
    begin
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryJobQueue);

        LibraryVariableStorage.Enqueue(ReportOutputType);
        LibraryVariableStorage.Enqueue(CustomerFilter);
        LibraryVariableStorage.Enqueue(PrintRemaining);
        CustomerCard.OpenEdit();
        CustomerCard.FILTER.SetFilter("No.", CustomerFilter);
        CustomerCard.BackgroundStatement.Invoke();
        CustomerCard.Close();

        LibraryJobQueue.GetCollectedJobQueueEntries(TempJobQueueEntry);
        Assert.RecordCount(TempJobQueueEntry, 1);
        TempJobQueueEntry.TestField("Object Type to Run", TempJobQueueEntry."Object Type to Run"::Codeunit);
        TempJobQueueEntry.TestField("Object ID to Run", CODEUNIT::"Customer Statement via Queue");

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Background);
        BindSubscription(TestClientTypeSubscriber);
        CODEUNIT.Run(TempJobQueueEntry."Object ID to Run", TempJobQueueEntry);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Custom Layout Reporting", 'OnIsTestMode', '', false, false)]
    local procedure EnableTestModeOnIsTestMode(var TestMode: Boolean)
    begin
        TestMode := true
    end;

    local procedure AssertActivityLog(var TempErrorMessage: Record "Error Message" temporary)
    var
        ActivityLog: Record "Activity Log";
    begin
        TempErrorMessage.FindSet();
        ActivityLog.SetRange("User ID", UserId);
        ActivityLog.FindSet();
        repeat
            Assert.ExpectedMessage(TempErrorMessage."Message", LibraryUtility.ConvertCRLFToBackSlash(ActivityLog.Description));
            ActivityLog.TestField(Status, ActivityLog.Status::Failed);
            ActivityLog.Next();
        until TempErrorMessage.Next() = 0;

        Assert.RecordCount(ActivityLog, TempErrorMessage.Count);
    end;

    local procedure AssertErrorsOnErrorMessagesPage(ErrorMessages: TestPage "Error Messages"; var TempErrorMessage: Record "Error Message" temporary)
    var
        Stop: Boolean;
    begin
        TempErrorMessage.FindSet();
        repeat
            Assert.ExpectedMessage(TempErrorMessage."Message", ErrorMessages.Description.Value);
            ErrorMessages."Message Type".AssertEquals(TempErrorMessage."Message Type");
            Stop := TempErrorMessage.Next() = 0;
            if not Stop then
#pragma warning disable AA0181
                Assert.IsTrue(ErrorMessages.Next(), StrSubstNo(LessErrorsOnErrorMessagesPageErr, ErrorMessages.Caption));
#pragma warning restore AA0181
        until Stop;

        Assert.IsFalse(ErrorMessages.Next(), StrSubstNo(MoreErrorsOnErrorMessagesPageErr, ErrorMessages.Caption));
    end;

    local procedure AssertReportInboxEmpty()
    var
        ReportInbox: Record "Report Inbox";
    begin
        ReportInbox.SetRange("Report ID", GetStandardStatementReportID());
        ReportInbox.SetRange("User ID", UserId);
        Assert.RecordIsEmpty(ReportInbox);
    end;

    local procedure AssertReportInboxCountWord(ExpectedCount: Integer)
    var
        ReportInbox: Record "Report Inbox";
    begin
        AssertReportInboxCountWithType(ExpectedCount, ReportInbox."Output Type"::Word);
    end;

    local procedure AssertReportInboxCountZip(ExpectedCount: Integer)
    var
        ReportInbox: Record "Report Inbox";
    begin
        AssertReportInboxCountWithType(ExpectedCount, ReportInbox."Output Type"::Zip);
    end;

    local procedure AssertReportInboxCountPdf(ExpectedCount: Integer)
    var
        ReportInbox: Record "Report Inbox";
    begin
        AssertReportInboxCountWithType(ExpectedCount, ReportInbox."Output Type"::PDF);
    end;

    local procedure AssertReportInboxCountWithType(ExpectedCount: Integer; OutputType: Enum "Report Inbox Output Type")
    var
        ReportInbox: Record "Report Inbox";
    begin
        ReportInbox.SetRange("Report ID", GetStandardStatementReportID());
        ReportInbox.SetRange("User ID", UserId);
        ReportInbox.FindSet();
        repeat
            ReportInbox.TestField("Output Type", OutputType);
            Assert.IsTrue(ReportInbox."Report Output".HasValue, 'Output must be saved in Report Inbox');
        until ReportInbox.Next() = 0;
        Assert.RecordCount(ReportInbox, ExpectedCount);
        ReportInbox.DeleteAll();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardStatementOKRequestPageHandler(var StandardStatement: TestRequestPage "Standard Statement")
    begin
        StandardStatement."Start Date".SetValue(WorkDate());
        StandardStatement."End Date".SetValue(WorkDate());
        StandardStatement.ReportOutput.SetValue(LibraryVariableStorage.DequeueInteger());
        StandardStatement.Customer.SetFilter("No.", LibraryVariableStorage.DequeueText());
        StandardStatement.PrintMissingAddresses.SetValue(LibraryVariableStorage.DequeueBoolean());
        StandardStatement.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure StartJobQueueNoConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.AreEqual(ConfirmStartJobQueueQst, Question, UnexpectedConfirmationErr);
        Reply := false;
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure StandardStatementReportHandler(var StandardStatement: Report "Standard Statement")
    var
        FileManagement: Codeunit "File Management";
    begin
        StandardStatement.SaveAsPdf(FileManagement.ServerTempFileName('.pdf'));
    end;
}
