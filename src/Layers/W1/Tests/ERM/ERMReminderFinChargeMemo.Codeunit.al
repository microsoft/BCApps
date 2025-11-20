codeunit 134909 "ERM Reminder/Fin.Charge Memo"
{
    Permissions = TableData "Issued Reminder Header" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [ERM]
        IsInitialized := false;
    end;

    var
        TableName: Label 'DocEntryTableName';
        NoOfRecords: Label 'DocEntryNoofRecords';
        IssuedReminderHeaderNo: Label 'No_IssuedReminderHeader';
        AddFeeCaption: Label 'AddFee_IssuedReminderHeader';
        RemAmountCaption: Label 'RemAmt_IssReminderHeader';
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryFinanceChargeMemo: Codeunit "Library - Finance Charge Memo";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryDimension: Codeunit "Library - Dimension";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;
        FinChrgMemoAddFeeCaption: Label 'AddFee_IssuedFinChrgMemoHeader';
        FinChrgMemoRemAmountCaption: Label 'RmnAmt_IssuedFinChrgMemoHeader';
        IssuedFinChrgMemoHeaderNo: Label 'No_IssuedFinChrgMemoHeader';
        CancelNextLevelReminderErr: Label 'You must cancel the issued reminder %1 before canceling issued reminder %2.';
        CancelAppliedEntryReminderErr: Label 'You must unapply customer ledger entry %1 before canceling issued reminder %2.', Comment = '%1 - entry number, %2 - issued reminder number';
        CancelAppliedEntryFinChargeMemoErr: Label 'You must unapply customer ledger entry %1 before canceling issued finance charge memo %2.', Comment = '%1 - entry number, %2 - issued reminder number';
        NotAllRemindersCancelledTxt: Label 'One or more of the selected issued reminders could not be canceled.\\Do you want to see a list of the issued reminders that were not canceled?';
        NotAllFinChMemosCancelledTxt: Label 'One or more of the selected issued finance charge memos could not be canceled.\\Do you want to see a list of the issued finance charge memos that were not canceled?';
        IssuedReminderErr: Label 'Amount must be in opposite sign.';

    [Test]
    [HandlerFunctions('DocumentEntriesRequestPageHandler,NavigatePagehandler')]
    [Scope('OnPrem')]
    procedure DocumentEntriesForIssuedReminderInFCY()
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
    begin
        // [FEATURE] [Reminder] [FCY]
        // Verify Document Entries Report for Issued Reminder in FCY.

        // Setup and Exercise.
        DocumentEntriesForIssuedReminder(IssuedReminderHeader, false);  // False for Show Amount in LCY.

        // Verify: Verify Additional Fee and Remaining Amount in FCY on Document Entries Report.
        VerifyDocumentEntries(
          IssuedReminderHeaderNo, IssuedReminderHeader."No.", AddFeeCaption, IssuedReminderHeader."Additional Fee");
        VerifyDocumentEntries(
          IssuedReminderHeaderNo, IssuedReminderHeader."No.", RemAmountCaption, IssuedReminderHeader."Remaining Amount");
    end;

    [Test]
    [HandlerFunctions('DocumentEntriesRequestPageHandler,NavigatePagehandler')]
    [Scope('OnPrem')]
    procedure DocumentEntriesForIssuedReminderInLCY()
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
    begin
        // [FEATURE] [Reminder]
        // Verify Document Entries Report for Issued Reminder in LCY.

        // Setup and Exercise.
        DocumentEntriesForIssuedReminder(IssuedReminderHeader, true);  // True for Show Amount in LCY.

        // Verify: Verify Additional Fee and Remaining Amount in LCY on Document Entries Report.
        VerifyDocumentEntries(
          IssuedReminderHeaderNo, IssuedReminderHeader."No.", AddFeeCaption,
          LibraryERM.ConvertCurrency(IssuedReminderHeader."Additional Fee", IssuedReminderHeader."Currency Code", '', WorkDate()));
        VerifyDocumentEntries(
          IssuedReminderHeaderNo, IssuedReminderHeader."No.", RemAmountCaption,
          LibraryERM.ConvertCurrency(IssuedReminderHeader."Remaining Amount", IssuedReminderHeader."Currency Code", '', WorkDate()));
    end;

    [Test]
    [HandlerFunctions('DocumentEntriesRequestPageHandler,NavigatePagehandler')]
    [Scope('OnPrem')]
    procedure DocumentEntriesForIssuedFinanceChargeMemoInFCY()
    var
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
    begin
        // [FEATURE] [Finance Charge Memo] [FCY]
        // Verify Document Entries Report for Issued Finance Charge Memo in FCY.

        // Setup and Exercise.
        DocumentEntriesForIssuedFinanceChargeMemo(IssuedFinChargeMemoHeader, false);  // False for Show Amount in LCY.

        // Verify: Verify Additional Fee and Remaining Amount in FCY on Document Entries Report.
        VerifyDocumentEntries(
          IssuedFinChrgMemoHeaderNo, IssuedFinChargeMemoHeader."No.", FinChrgMemoAddFeeCaption,
          IssuedFinChargeMemoHeader."Additional Fee");
        VerifyDocumentEntries(
          IssuedFinChrgMemoHeaderNo, IssuedFinChargeMemoHeader."No.", FinChrgMemoRemAmountCaption,
          IssuedFinChargeMemoHeader."Remaining Amount");
    end;

    [Test]
    [HandlerFunctions('DocumentEntriesRequestPageHandler,NavigatePagehandler')]
    [Scope('OnPrem')]
    procedure DocumentEntriesForIssuedFinanceChargeMemoInLCY()
    var
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
    begin
        // [FEATURE] [Finance Charge Memo]
        // Verify Document Entries Report for Issued Finance Charge Memo in LCY.

        // Setup and Exercise.
        DocumentEntriesForIssuedFinanceChargeMemo(IssuedFinChargeMemoHeader, true);  // True for Show Amount in LCY.

        // Verify: Verify Additional Fee and Remaining Amount in LCY on Document Entries Report.
        VerifyDocumentEntries(
          IssuedFinChrgMemoHeaderNo, IssuedFinChargeMemoHeader."No.", FinChrgMemoAddFeeCaption,
          LibraryERM.ConvertCurrency(IssuedFinChargeMemoHeader."Additional Fee", IssuedFinChargeMemoHeader."Currency Code",
            '', WorkDate()));
        VerifyDocumentEntries(
          IssuedFinChrgMemoHeaderNo, IssuedFinChargeMemoHeader."No.", FinChrgMemoRemAmountCaption,
          LibraryERM.ConvertCurrency(IssuedFinChargeMemoHeader."Remaining Amount", IssuedFinChargeMemoHeader."Currency Code",
            '', WorkDate()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotDueReminderLineNotChangesLastIssuedReminderLevel()
    var
        ReminderLine: Record "Reminder Line";
        Customer: Record Customer;
        ReminderHeaderNo: Code[20];
        ReminderTermsCode: Code[10];
        GracePeriod: DateFormula;
        DueDateCalc: DateFormula;
    begin
        // [FEATURE] [Reminder] [Sales]
        // [SCENARIO 376778] Not Due Reminder Entries do not reset Cust. Ledg. Entries "Last Issued Reminder Level"

        // [GIVEN] Reminder Terms With 2 Levels and Due Date Calc = 7D
        Initialize();
        ReminderTermsCode := CreateReminderTermsWithDueDate(2);
        CreateCustomer(Customer, '', '', ReminderTermsCode);

        // [GIVEN] Posted Sales Invoice "X" with Posting Date = 26/01/17
        ReminderHeaderNo :=
          CreateAndSuggestReminderLineWithDueDate(Customer."No.");
        // [GIVEN] Issued Reminder for CLE of Invoice "X" and Posting Date = 27/01/17
        IssueReminder(ReminderHeaderNo, WorkDate());

        // [GIVEN] Posted Sales Invoice "Y" with Posting Date = 26/01/17
        ReminderHeaderNo :=
          CreateAndSuggestReminderLineWithDueDate(Customer."No.");
        // [GIVEN] Issued Reminder (Posting Date = 27/01/17) with Suggested CLE for Sales Invoice "Y" (Reminder Level 1) and "Not Due" line for Sales Invoice "X"
        IssueReminder(ReminderHeaderNo, WorkDate());

        // [WHEN] Suggested Reminder for Date = 09/02/17
        CreateAndPostSalesInvoice(Customer."No.");
        GetCustomerReminderLevel(GracePeriod, DueDateCalc, Customer."No.", 1);
        ReminderHeaderNo :=
          CreateReminder(Customer."No.", CalcDate(DueDateCalc, CalcDate(DueDateCalc, FindLastSalesInvPostingDate(Customer."No."))));

        // [THEN] 2 Lines suggested with value of "No. of Reminders" = 2 for each line
        ReminderLine.SetRange("Reminder No.", ReminderHeaderNo);
        ReminderLine.SetRange("No. of Reminders", 1);
        ReminderLine.FindSet();
        Assert.RecordCount(ReminderLine, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplaceReminderLineStandardTextWithExtText()
    var
        ReminderHeader: Record "Reminder Header";
        ReminderLine: Record "Reminder Line";
        StandardText: Record "Standard Text";
        ExtendedText: Text;
    begin
        // [FEATURE] [Reminder] [Standard Text] [Extended Text]
        // [SCENARIO 380579] Replacing of Reminder Line's Standard Text Code updates attached Extended Text lines
        Initialize();

        // [GIVEN] Standard Text (Code = "ST1", Description = "SD1") with Extended Text "ET1".
        // [GIVEN] Standard Text (Code = "ST2", Description = "SD2") with Extended Text "ET2".
        // [GIVEN] Reminder with line: "Type" = "", "No." = "ST1"
        LibraryERM.CreateReminderHeader(ReminderHeader);
        MockReminderLine(ReminderLine, ReminderHeader);
        ValidateReminderLineStandardCode(ReminderLine, LibrarySales.CreateStandardTextWithExtendedText(StandardText, ExtendedText));

        // [WHEN] Validate Reminder Line "No." = "ST2"
        ValidateReminderLineStandardCode(ReminderLine, LibrarySales.CreateStandardTextWithExtendedText(StandardText, ExtendedText));

        // [THEN] There are two Reminder lines:
        // [THEN] Line1: Type = "", "No." = "ST2", Description = "SD2"
        // [THEN] Line2: Type = "", "No." = "", Description = "ET2"
        VerifyReminderLineCount(ReminderHeader, 2);
        VerifyReminderLineDescription(ReminderLine, ReminderLine.Type::" ", StandardText.Code, StandardText.Description);
        ReminderLine.Next();
        VerifyReminderLineDescription(ReminderLine, ReminderLine.Type::" ", '', ExtendedText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplaceFinChargeMemoLineStandardTextWithExtText()
    var
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
        StandardText: Record "Standard Text";
        ExtendedText: Text;
    begin
        // [FEATURE] [Finance Charge Memo] [Standard Text] [Extended Text]
        // [SCENARIO 380579] Replacing of Finance Charge Memo Line's Standard Text Code updates attached Extended Text lines
        Initialize();

        // [GIVEN] Standard Text (Code = "ST1", Description = "SD1") with Extended Text "ET1".
        // [GIVEN] Standard Text (Code = "ST2", Description = "SD2") with Extended Text "ET2".
        // [GIVEN] Finance Charge Memo with line: "Type" = "", "No." = "ST1"
        LibraryERM.CreateFinanceChargeMemoHeader(FinanceChargeMemoHeader, LibrarySales.CreateCustomerNo());
        MockFinChargeMemoLine(FinanceChargeMemoLine, FinanceChargeMemoHeader);
        ValidateFinChargeMemoLineStandardCode(
          FinanceChargeMemoLine, LibrarySales.CreateStandardTextWithExtendedText(StandardText, ExtendedText));

        // [WHEN] Validate Finance Charge Memo Line "No." = "ST2"
        ValidateFinChargeMemoLineStandardCode(
          FinanceChargeMemoLine, LibrarySales.CreateStandardTextWithExtendedText(StandardText, ExtendedText));

        // [THEN] There are two Finance Charge Memo lines:
        // [THEN] Line1: Type = "", "No." = "ST2", Description = "SD2"
        // [THEN] Line2: Type = "", "No." = "", Description = "ET2"
        VerifyFinChargeMemoLineCount(FinanceChargeMemoHeader, 2);
        VerifyFinChargeMemoLineDescription(
          FinanceChargeMemoLine, FinanceChargeMemoLine.Type::" ", StandardText.Code, StandardText.Description);
        FinanceChargeMemoLine.Next();
        VerifyFinChargeMemoLineDescription(FinanceChargeMemoLine, FinanceChargeMemoLine.Type::" ", '', ExtendedText);
    end;

    [Test]
    [HandlerFunctions('ReminderRequestPageHandlerWithCalcCalls')]
    [Scope('OnPrem')]
    procedure PrintIssuedRemindersAllAtOnceForSingleCustomer()
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
    begin
        // [FEATURE] [Reminder]
        // [SCENARIO 209796] When printing multiple issued reminders there should be only one request page to print all of them for single customer
        Initialize();
        LibraryVariableStorage.AssertEmpty();

        // [GIVEN] 2 Issued Reminders for a certain customer
        MockTwoIssuedRemindersSingleCustomer(IssuedReminderHeader);

        // [WHEN] Print 2 Issued Reminders.
        Commit();
        LibraryVariableStorage.Enqueue(0);
        IssuedReminderHeader.SetRange("Customer No.", IssuedReminderHeader."Customer No.");
        IssuedReminderHeader.PrintRecords(true, false, true);

        // [THEN] The reminder report request page appeared once for two reminders.
        Assert.AreEqual(1, LibraryVariableStorage.DequeueInteger(), 'The Reminder report should be called only once.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteReminderCommentLineAfterIssueReminder()
    var
        ReminderCommentLine: Record "Reminder Comment Line";
        ReminderNo: Code[20];
        IssuedReminderNo: Code[20];
        DocumentDate: Date;
    begin
        // [FEATURE] [Reminder] [Comment]
        // [SCENARIO 297133] The Reminder Comment Line has been deleted after issue the reminder
        Initialize();

        // [GIVEN] Create Reminder with comment line
        CreateIssueReminderWithCommentLine(ReminderNo, DocumentDate);

        // [WHEN] Issue reminder
        IssuedReminderNo := IssueReminder(ReminderNo, DocumentDate);

        // [THEN] Reminder Comment Line of original Reminder is deleted
        ReminderCommentLine.SetRange(Type, ReminderCommentLine.Type::Reminder);
        ReminderCommentLine.SetRange("No.", ReminderNo);
        Assert.RecordIsEmpty(ReminderCommentLine);

        // [THEN] Reminder Comment Line of Issued Reminder exists
        ReminderCommentLine.SetRange(Type, ReminderCommentLine.Type::"Issued Reminder");
        ReminderCommentLine.SetRange("No.", IssuedReminderNo);
        Assert.RecordIsNotEmpty(ReminderCommentLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteFinChargeCommentLineAfterIssueFinCharge()
    var
        FinChargeCommentLine: Record "Fin. Charge Comment Line";
        FinChargeNo: Code[20];
        IssueFinChargeNo: Code[20];
    begin
        // [FEATURE] [Finance Charge Memo] [Comment]
        // [SCENARIO 297133] The Fin. Charge Comment Line has been deleted after issue the fin. charge memo
        Initialize();

        // [GIVEN] Create Fin. Charge Memo with comment line
        CreateIssueFinChargeWithCommentLine(FinChargeNo);

        // [WHEN] Issue Fin. Charge Memo
        IssueFinChargeNo := IssuingFinanceChargeMemos(FinChargeNo);

        // [THEN] Fin. Charge Comment Line of original Fin. Charge memo is deleted
        FinChargeCommentLine.SetRange(Type, FinChargeCommentLine.Type::"Finance Charge Memo");
        FinChargeCommentLine.SetRange("No.", FinChargeNo);
        Assert.RecordIsEmpty(FinChargeCommentLine);

        // [THEN] Fin. Charge Comment Line of Issued Fin. Charge Memo exists
        FinChargeCommentLine.SetRange(Type, FinChargeCommentLine.Type::"Issued Finance Charge Memo");
        FinChargeCommentLine.SetRange("No.", IssueFinChargeNo);
        Assert.RecordIsNotEmpty(FinChargeCommentLine);
    end;

    [Test]
    [HandlerFunctions('BatchCancelIssuedRemindersRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CancelReminderSunshine()
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        ReminderFinChargeEntry: Record "Reminder/Fin. Charge Entry";
        ReminderNo: Code[20];
    begin
        // [FEATURE] [Cancel Reminder]
        // [SCENARIO 287121] Cancel issued reminder makes Cancelled = Yes for Issued Reminder Header and Reminder/Fin. Charge Entry
        Initialize();

        // [GIVEN] Issued single level reminder
        ReminderNo := CreateReminderWithReminderTerms(CreateOneLevelReminderTerms());

        // [GIVEN] Issue reminder
        IssuedReminderHeader.Get(
          IssueReminder(ReminderNo, WorkDate()));

        // [WHEN] Cancel issued reminder
        RunCancelIssuedReminder(IssuedReminderHeader);

        // [THEN] Issued reminder header has Cancelled = Yes
        IssuedReminderHeader.Find();
        IssuedReminderHeader.TestField(Canceled, true);

        // [THEN] Issued reminder header has Cancelled By = current user ID
        IssuedReminderHeader.TestField("Canceled By", UserId);
        IssuedReminderHeader.TestField("Canceled Date", Today);
        // [THEN] Issued reminder header has Cancelled Date = current date

        // [THEN] Reminder/Fin. Charge Entry has Cancelled = Yes
        ReminderFinChargeEntry.SetRange(Type, ReminderFinChargeEntry.Type::Reminder);
        ReminderFinChargeEntry.SetRange("No.", IssuedReminderHeader."No.");
        ReminderFinChargeEntry.FindFirst();
        ReminderFinChargeEntry.TestField(Canceled, true);
    end;

    [Test]
    [HandlerFunctions('BatchCancelIssuedRemindersRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CancelAlreadyCancelledReminder()
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        ReminderNo: Code[20];
    begin
        // [FEATURE] [Cancel Reminder]
        // [SCENARIO 287121] Cancel issued reminder which has been already cancelled leads to error "Cancelled must be equal to 'No' ..."
        Initialize();

        // [GIVEN] Issued single level reminder
        ReminderNo := CreateReminderWithReminderTerms(CreateOneLevelReminderTerms());

        // [GIVEN] Issue reminder
        IssuedReminderHeader.Get(
          IssueReminder(ReminderNo, WorkDate()));

        // [GIVEN] Cancel issued reminder
        RunCancelIssuedReminder(IssuedReminderHeader);

        // [WHEN] Run cancel issued reminder again
        IssuedReminderHeader.Find();
        asserterror RunCancelIssuedReminder(IssuedReminderHeader);

        // [THEN] Error "Cancelled must be equal to 'No' ..."
        Assert.ExpectedTestFieldError(IssuedReminderHeader.FieldCaption(Canceled), Format(false));
    end;

    [Test]
    [HandlerFunctions('BatchCancelIssuedRemindersRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CancelReminderDontUseSameDocumentNo()
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        NoSeries: Codeunit "No. Series";
        ReminderNo: Code[20];
        NumberSeriesCode: Code[20];
        ExpectedDocumentNo: Code[20];
    begin
        // [FEATURE] [Cancel Reminder]
        // [SCENARIO 287121] Cancel issued reminder with "Use Same Document No." = No takes Document No. for reversing entries from SalesSetup."Cancelled Issued Reminders Nos."
        Initialize();

        // [GIVEN] Create number series "CIR_NOS"
        NumberSeriesCode := LibraryERM.CreateNoSeriesCode();
        ExpectedDocumentNo := NoSeries.PeekNextNo(NumberSeriesCode, Today());

        // [GIVEN] Set SalesSetup."Cancelled Issued Reminders Nos." = "CIR_NOS"
        SetSalesSetupCancelledIssuedRemindersNos(NumberSeriesCode);

        // [GIVEN] Issued single level reminder
        ReminderNo := CreateReminderWithReminderTerms(CreateReminderTerms(false, false, true, false));
        IssuedReminderHeader.SetRange("No.", IssueReminder(ReminderNo, WorkDate()));

        // [WHEN] Run cancel issued reminder with "Use Same Document No." = No
        IssuedReminderHeader.FindFirst();
        RunCancelIssuedReminderReportWithParameters(IssuedReminderHeader, false, true, 0D);

        // [THEN] G/L entries reversed with Document No. from number series "CIR_NOS"
        VerifyReversedGLEntriesExtended(IssuedReminderHeader."No.", ExpectedDocumentNo, IssuedReminderHeader."Posting Date");
    end;

    [Test]
    [HandlerFunctions('BatchCancelIssuedRemindersRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CancelReminderUseNewPostingDate()
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        ReminderNo: Code[20];
        ExpectedPostingDate: Date;
    begin
        // [FEATURE] [Cancel Reminder]
        // [SCENARIO 287121] Cancel issued reminder with "Use Same Posting Date" = No set new Posting Date for corrective entries
        Initialize();

        // [GIVEN] Issued single level reminder with "Posting Date" = 01.01.2020
        ReminderNo := CreateReminderWithReminderTerms(CreateReminderTerms(false, false, true, false));
        IssuedReminderHeader.SetRange("No.", IssueReminder(ReminderNo, WorkDate()));

        // [WHEN] Run cancel issued reminder with "Use Same Posting Date" = No and New Posting Date = 10.01.2020
        ExpectedPostingDate := CalcDate('<10D>', WorkDate());
        IssuedReminderHeader.FindFirst();
        RunCancelIssuedReminderReportWithParameters(IssuedReminderHeader, true, false, ExpectedPostingDate);

        // [THEN] G/L entries reversed with "Posting Date" = 10.01.2020
        VerifyReversedGLEntriesExtended(IssuedReminderHeader."No.", IssuedReminderHeader."No.", ExpectedPostingDate);
    end;

    [Test]
    [HandlerFunctions('BatchCancelIssuedRemindersRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CreateReminderAfterCancel()
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        ReminderNo: Code[20];
        NewReminderNo: Code[20];
    begin
        // [FEATURE] [Cancel Reminder]
        // [SCENARIO 287121] Function "Create Reminders" creates same reminder after cancel initial one
        Initialize();

        // [GIVEN] Single level reminder "1" with "Remaining Amount" = "100"
        ReminderNo := CreateReminderWithReminderTerms(CreateOneLevelReminderTerms());

        // [GIVEN] Issue reminder "1"
        IssuedReminderHeader.Get(
          IssueReminder(ReminderNo, WorkDate()));

        // [GIVEN] Cancel issued reminder "1"
        RunCancelIssuedReminder(IssuedReminderHeader);

        // [WHEN] Run "Create Reminders" function
        NewReminderNo := CreateReminder(IssuedReminderHeader."Customer No.", IssuedReminderHeader."Posting Date");

        // [THEN] Created reminder "2" with "Remaining Amount" = "100"
        VerifyRecreatedReminder(IssuedReminderHeader, NewReminderNo);
    end;

    [Test]
    [HandlerFunctions('BatchCancelIssuedRemindersRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CancelReminderWithPostLineFee()
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        ReminderNo: Code[20];
    begin
        // [FEATURE] [Cancel Reminder]
        // [SCENARIO 287121] Cancel issued reminder with "Post Line Fee" = "Yes" reversed Customer, VAT and G/L entries
        Initialize();

        // [GIVEN] Single level reminder with "Post Line Fee" = "Yes", "Remaining Amount" = "100"
        ReminderNo := CreateReminderWithReminderTerms(CreateReminderTerms(false, false, true, false));

        // [GIVEN] Issue reminder
        IssuedReminderHeader.Get(
          IssueReminder(ReminderNo, WorkDate()));

        // [WHEN] Cancel issued reminder
        RunCancelIssuedReminder(IssuedReminderHeader);

        // [THEN] G/L entries reversed
        VerifyReminderReversedGLEntries(IssuedReminderHeader."No.");
        // [THEN] VAT entry reversed
        VerifyReversedVATEntries(IssuedReminderHeader."No.");
        // [THEN] Customer ledger enery is closed
        VerifyCanceledReminderCustLedgerEntries(IssuedReminderHeader."No.");
    end;

    [Test]
    [HandlerFunctions('BatchCancelIssuedRemindersRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CancelReminderWithPostLineFeeSeveralInvoices()
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        ReminderNo: Code[20];
    begin
        // [FEATURE] [Cancel Reminder]
        // [SCENARIO 287121] Cancel issued reminder with several invoices and full reminder terms setup
        Initialize();

        // [GIVEN] Single level reminder with "Post Add. Fee per Line" = "Yes","Post Interest" = "Yes", "Post Additional Fee" = "Yes", "Remaining Amount" = "100"
        ReminderNo := CreateReminderForSeveralInvoicesWithReminderTerms(CreateReminderTerms(true, true, true, false));

        // [GIVEN] Issue reminder
        IssuedReminderHeader.Get(
          IssueReminder(ReminderNo, WorkDate()));

        // [WHEN] Cancel issued reminder
        RunCancelIssuedReminder(IssuedReminderHeader);

        // [THEN] G/L entries reversed
        VerifyReminderReversedGLEntries(IssuedReminderHeader."No.");
        // [THEN] VAT entry reversed
        VerifyReversedVATEntries(IssuedReminderHeader."No.");
        // [THEN] Customer ledger enery is closed
        VerifyCanceledReminderCustLedgerEntries(IssuedReminderHeader."No.");
    end;

    [Test]
    [HandlerFunctions('BatchCancelIssuedRemindersRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CancelReminderNoGLPosting()
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        GLEntry: Record "G/L Entry";
        ReminderNo: Code[20];
    begin
        // [FEATURE] [Cancel Reminder]
        // [SCENARIO 287121] Cancel issued reminder with "Post Line Fee" = "No" does not post G/L entries
        Initialize();

        // [GIVEN] Single level reminder with "Post Line Fee" = "No"
        ReminderNo := CreateReminderWithReminderTerms(CreateReminderTerms(false, false, false, false));

        // [GIVEN] Issue reminder
        IssuedReminderHeader.Get(
          IssueReminder(ReminderNo, WorkDate()));

        // [WHEN] Cancel issued reminder
        RunCancelIssuedReminder(IssuedReminderHeader);

        // [THEN] G/L entries are not created
        GLEntry.SetRange("Document No.", IssuedReminderHeader."No.");
        Assert.RecordIsEmpty(GLEntry);
    end;

    [Test]
    [HandlerFunctions('BatchCancelIssuedRemindersRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CancelMultilevelReminderLastLevel()
    var
        Customer: Record Customer;
        IssuedReminderHeader: Record "Issued Reminder Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ReminderHeaderNo: Code[20];
        ReminderTermsCode: Code[10];
        GracePeriod: DateFormula;
        DueDateCalc: DateFormula;
    begin
        // [FEATURE] [Cancel Reminder]
        // [SCENARIO 287121] Cancel issued second level reminder set Last Issued Reminder Level = 1
        Initialize();

        // [GIVEN] Reminder Terms With 2 Levels and Due Date Calc = 7D
        ReminderTermsCode := CreateReminderTermsWithDueDate(2);
        CreateCustomer(Customer, '', '', ReminderTermsCode);

        // [GIVEN] Posted Sales Invoice "X" with Posting Date = 26/01/17
        ReminderHeaderNo :=
          CreateAndSuggestReminderLineWithDueDate(Customer."No.");
        // [GIVEN] Issued Reminder "1" for CLE of Invoice "X" and Posting Date = 27/01/17
        IssueReminder(ReminderHeaderNo, WorkDate());

        // [GIVEN] Posted Sales Invoice "Y" with Posting Date = 26/01/17
        ReminderHeaderNo :=
          CreateAndSuggestReminderLineWithDueDate(Customer."No.");
        // [GIVEN] Issued Reminder "2" (Posting Date = 27/01/17) with Suggested CLE for Sales Invoice "Y" (Reminder Level 1) and "Not Due" line for Sales Invoice "X"
        IssueReminder(ReminderHeaderNo, WorkDate());

        // [GIVEN] Suggested Reminder for Date = 09/02/17
        CreateAndPostSalesInvoice(Customer."No.");
        GetCustomerReminderLevel(GracePeriod, DueDateCalc, Customer."No.", 1);
        ReminderHeaderNo :=
          CreateReminder(Customer."No.", CalcDate(DueDateCalc, CalcDate(DueDateCalc, FindLastSalesInvPostingDate(Customer."No."))));

        // [GIVEN] Issued Reminder "3" (Posting Date = 09/02/17)
        IssuedReminderHeader.Get(IssueReminder(ReminderHeaderNo, WorkDate()));

        // [WHEN] Issued Reminder "3" is being cancelled
        RunCancelIssuedReminder(IssuedReminderHeader);

        // [THEN] Customer ledger entries for invoices "X" and "Y" have "Last Issued Reminder Level" = 1
        CustLedgerEntry.SetRange("Customer No.", Customer."No.");
        CustLedgerEntry.FindLast();
        CustLedgerEntry.Next(-1);
        repeat
            CustLedgerEntry.TestField("Last Issued Reminder Level", 1);
        until CustLedgerEntry.Next(-1) = 0;
    end;

    [Test]
    [HandlerFunctions('BatchCancelIssuedRemindersRequestPageHandler,CannotCancelReminderNotificationHandler,IssuedReminderPageHandler')]
    [Scope('OnPrem')]
    procedure CancelMultilevelReminderFirstLevel()
    var
        Customer: Record Customer;
        IssuedReminderHeader: array[2] of Record "Issued Reminder Header";
        ReminderHeaderNo: Code[20];
        ReminderTermsCode: Code[10];
        GracePeriod: DateFormula;
        DueDateCalc: DateFormula;
    begin
        // [FEATURE] [Cancel Reminder]
        // [SCENARIO 287121] User cannot cancel issued first level reminder if second level reminder is not cancelled
        Initialize();

        // [GIVEN] Reminder Terms With 2 Levels and Due Date Calc = 7D
        ReminderTermsCode := CreateReminderTermsWithDueDate(2);
        CreateCustomer(Customer, '', '', ReminderTermsCode);

        // [GIVEN] Posted Sales Invoice "X" with Posting Date = 26/01/17
        ReminderHeaderNo :=
          CreateAndSuggestReminderLineWithDueDate(Customer."No.");
        // [GIVEN] Issued Reminder "1" for CLE of Invoice "X" and Posting Date = 27/01/17
        IssuedReminderHeader[1].Get(IssueReminder(ReminderHeaderNo, WorkDate()));

        // [GIVEN] Suggested Reminder for Date = 09/02/17
        GetCustomerReminderLevel(GracePeriod, DueDateCalc, Customer."No.", 1);
        ReminderHeaderNo :=
          CreateReminder(Customer."No.", CalcDate(DueDateCalc, CalcDate(DueDateCalc, FindLastSalesInvPostingDate(Customer."No."))));

        // [GIVEN] Issued Reminder "2" for CLE of Invoice "X" and Posting Date = 09/02/17
        IssuedReminderHeader[2].Get(IssueReminder(ReminderHeaderNo, WorkDate()));

        // [WHEN] Issued Reminder "1" is being cancelled
        RunCancelIssuedReminder(IssuedReminderHeader[1]);

        // [THEN] Issued Reminder "1" is not cancelled
        IssuedReminderHeader[1].Find();
        IssuedReminderHeader[1].TestField(Canceled, false);

        // [THEN] Notification "You cannot cancel issued reminder..." with action Show Issued Reminder "2"
        Assert.AreEqual(
          StrSubstNo(
            CancelNextLevelReminderErr,
            IssuedReminderHeader[2]."No.",
            IssuedReminderHeader[1]."No."),
          LibraryVariableStorage.DequeueText(),
          'Invalid notificaion message');

        // [THEN] Action Show Issued Reminder opens issued reminder card with issued reminder "2"
        Assert.AreEqual(IssuedReminderHeader[2]."No.", LibraryVariableStorage.DequeueText(), 'Invalid Issued Reminder No.');

        NotificationLifecycleMgt.RecallAllNotifications();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('BatchCancelIssuedRemindersRequestPageHandler,AppliedCustomerLedgeEntryReminderNotificationHandler,CustomerLedgerEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure CancelReminderWhenCustLedgerEntryAlreadyApplied()
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        ReminderNo: Code[20];
        ReminderCustLedgerEntryNo: Integer;
    begin
        // [FEATURE] [Cancel Reminder]
        // [SCENARIO 287121] User cannot cancel issued reminder if reminder customer ledger entry is already applied
        Initialize();

        // [GIVEN] Single level reminder with "Post Line Fee" = "Yes", "Remaining Amount" = "100"
        ReminderNo := CreateReminderWithReminderTerms(CreateReminderTerms(true, true, true, false));

        // [GIVEN] Issue reminder with Fee Amount = "10"
        IssuedReminderHeader.Get(
          IssueReminder(ReminderNo, WorkDate()));

        // [GIVEN] Payment with "Amount" = "10" applied to reminder fee customer ledger "123"
        ReminderCustLedgerEntryNo := CreatePostPaymentApplyToReminderFee(IssuedReminderHeader);

        // [WHEN] Cancel issued reminder
        RunCancelIssuedReminder(IssuedReminderHeader);

        // [THEN] Notification "You must unapply customer ledger entry ... before cancelling issued reminder ..."
        Assert.AreEqual(
          StrSubstNo(
            CancelAppliedEntryReminderErr,
            ReminderCustLedgerEntryNo,
            IssuedReminderHeader."No."),
          LibraryVariableStorage.DequeueText(),
          'Invalid notificaion message');

        // [WHEN] Choose action "Show customer ledger entry"
        // [THEN] Customer ledger entries page openend with entry "123"
        Assert.AreEqual(ReminderCustLedgerEntryNo, LibraryVariableStorage.DequeueInteger(), 'Invalid customer ledger entry no.');

        NotificationLifecycleMgt.RecallAllNotifications();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('BatchCancelIssuedRemindersRequestPageHandler')]
    [Scope('OnPrem')]
    procedure BatchCancelReminders()
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        FirstIssuedReminderNo: Code[20];
        LastIssuedReminderNo: Code[20];
    begin
        // [FEATURE] [Cancel Reminder]
        // [SCENARIO 287121] User is able to cancel several reminders at once
        Initialize();

        // [GIVEN] 5 Issued single level reminders
        CreateIssueSeveralReminders(FirstIssuedReminderNo, LastIssuedReminderNo, LibraryRandom.RandIntInRange(5, 10));

        // [WHEN] run Cancel Reminders with filter for created reminders
        IssuedReminderHeader.SetRange("No.", FirstIssuedReminderNo, LastIssuedReminderNo);
        RunCancelIssuedReminders(IssuedReminderHeader);

        // [THEN] All 5 issued reminders are cancelled
        IssuedReminderHeader.FindSet();
        repeat
            IssuedReminderHeader.TestField(Canceled, true);
        until IssuedReminderHeader.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('BatchCancelIssuedRemindersRequestPageHandler,ConfirmHandlerYes,IssuedReminderListModalPageHandler')]
    [Scope('OnPrem')]
    procedure BatchCancelRemindersShowErrors()
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        FirstIssuedReminderNo: Code[20];
        LastIssuedReminderNo: Code[20];
    begin
        // [FEATURE] [Cancel Reminder]
        // [SCENARIO 287121] Batch cancel report shows issued reminders which cannot be cancelled due to errors
        Initialize();

        // [GIVEN] 5 Issued single level reminders "1" - "5"
        CreateIssueSeveralReminders(FirstIssuedReminderNo, LastIssuedReminderNo, LibraryRandom.RandIntInRange(5, 10));

        // [GIVEN] Apply payment to the Fee customer entry for reminders "1" and "5" to cause errors during cancelling
        IssuedReminderHeader.Get(FirstIssuedReminderNo);
        CreatePostPaymentApplyToReminderFee(IssuedReminderHeader);

        IssuedReminderHeader.Get(LastIssuedReminderNo);
        CreatePostPaymentApplyToReminderFee(IssuedReminderHeader);

        // [WHEN] run Cancel Reminders with filter for created reminders
        IssuedReminderHeader.SetRange("No.", FirstIssuedReminderNo, LastIssuedReminderNo);
        RunCancelIssuedReminders(IssuedReminderHeader);

        // [THEN] Dialog "One or more of the selected issued reminders could not be canceled. Do you want to see a list of the issued reminders that were not canceled? "
        Assert.AreEqual(NotAllRemindersCancelledTxt, LibraryVariableStorage.DequeueText(), 'Invalid dialog text');

        // [WHEN] Confirm "see a list" question
        // [THEN] Page Issued Reminders List" opened with filtered reminders "1" and "5" only
        Assert.AreEqual(
          StrSubstNo('%1|%2', FirstIssuedReminderNo, LastIssuedReminderNo),
          LibraryVariableStorage.DequeueText(),
          'Unexpected issued reminders');

        NotificationLifecycleMgt.RecallAllNotifications();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('BatchCancelIssuedFinChargeMemosRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CancelFinChargeMemoSunshine()
    var
        Customer: Record Customer;
        FinanceChargeTerms: Record "Finance Charge Terms";
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        ReminderFinChargeEntry: Record "Reminder/Fin. Charge Entry";
        DueDate: Date;
    begin
        // [FEATURE] [Cancel Finance Charge Memo]
        // [SCENARIO 287121] Cancel issued fin. charge memeo makes Cancelled = Yes for Issued Fin. Charge Memo Header and Reminder/Fin. Charge Entry
        Initialize();

        // [GIVEN] Issued fin. charge memo
        LibraryFinanceChargeMemo.CreateFinanceChargeTermAndText(FinanceChargeTerms);
        CreateCustomer(Customer, FinanceChargeTerms.Code, CreateCurrency(), CreateOneLevelReminderTerms());
        DueDate := CreateAndPostSalesInvoice(Customer."No.");

        // Create Finance Charge Memo and Suggest Lines for Customer. Issue Finance Charge Memo. Take Random integer to calculate Date.
        CreateSuggestFinanceChargeMemo(
          FinanceChargeMemoHeader, Customer."No.", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>',
            CalcDate(FinanceChargeTerms."Grace Period", DueDate)));

        // [GIVEN] Issue fin. charge memo
        IssuedFinChargeMemoHeader.Get(
          IssuingFinanceChargeMemos(FinanceChargeMemoHeader."No."));

        // [WHEN] Cancel issued fin. charge memo
        // [THEN] Issued fin. charge memo header has Cancelled Date = current date
        RunCancelIssuedFinChargeMemo(IssuedFinChargeMemoHeader);

        // [THEN] Issued fin. charge memo header has Cancelled = Yes
        IssuedFinChargeMemoHeader.Find();
        IssuedFinChargeMemoHeader.TestField(Canceled, true);

        // [THEN] Issued fin. charge memo header has Cancelled By = current user ID
        IssuedFinChargeMemoHeader.TestField("Canceled By", UserId);
        // [THEN] Issued fin. charge memo header has Cancelled Date = current date
        IssuedFinChargeMemoHeader.TestField("Canceled Date", Today);

        // [THEN] Reminder/Fin. Charge Entry has Cancelled = Yes
        ReminderFinChargeEntry.SetRange(Type, ReminderFinChargeEntry.Type::"Finance Charge Memo");
        ReminderFinChargeEntry.SetRange("No.", IssuedFinChargeMemoHeader."No.");
        ReminderFinChargeEntry.FindFirst();
        ReminderFinChargeEntry.TestField(Canceled, true);
    end;

    [Test]
    [HandlerFunctions('BatchCancelIssuedFinChargeMemosRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CancelAlreadyCancelledFinChargeMemo()
    var
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
    begin
        // [FEATURE] [Cancel Finance Charge Memo]
        // [SCENARIO 287121] Cancel issued fin. charge memo which has been already cancelled leads to error "Cancelled must be equal to 'No' ..."
        Initialize();

        // [GIVEN] Fin. charge memo
        CreateFinChargeMemo(FinanceChargeMemoHeader);

        // [GIVEN] Issue fin. charge memo
        IssuedFinChargeMemoHeader.Get(
          IssuingFinanceChargeMemos(FinanceChargeMemoHeader."No."));

        // [WHEN] Cancel issued fin. charge memo
        RunCancelIssuedFinChargeMemo(IssuedFinChargeMemoHeader);

        // [WHEN] Run cancel issued fin. charge memo again
        IssuedFinChargeMemoHeader.Find();
        asserterror RunCancelIssuedFinChargeMemo(IssuedFinChargeMemoHeader);

        // [THEN] Error "Cancelled must be equal to 'No' ..."
        Assert.ExpectedError('Canceled must be equal to ''No''');
    end;

    [Test]
    [HandlerFunctions('BatchCancelIssuedFinChargeMemosRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CancelFinChargeMemoDontUseSameDocumentNo()
    var
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        NoSeries: Codeunit "No. Series";
        NumberSeriesCode: Code[20];
        ExpectedDocumentNo: Code[20];
    begin
        // [FEATURE] [Cancel Finance Charge Memo]
        // [SCENARIO 287121] Cancel issued fin. charge memo with "Use Same Document No." = No takes Document No. for reversing entries from SalesSetup."Canc. Iss. Fin. Ch. Mem. Nos."
        Initialize();

        // [GIVEN] Create number series "CIR_NOS"
        NumberSeriesCode := LibraryERM.CreateNoSeriesCode();
        ExpectedDocumentNo := NoSeries.PeekNextNo(NumberSeriesCode, Today);

        // [GIVEN] Set SalesSetup."Canc. Iss. Fin. Ch. Mem. Nos." = "CIR_NOS"
        SetSalesSetupCancelledIssuedFinChargeMemosNos(NumberSeriesCode);

        // [GIVEN] Fin. charge memo
        CreateFinChargeMemo(FinanceChargeMemoHeader);

        // [GIVEN] Issue fin. charge memo
        IssuedFinChargeMemoHeader.SetFilter("No.", IssuingFinanceChargeMemos(FinanceChargeMemoHeader."No."));

        // [WHEN] Run cancel issued fin. charge memo with "Use Same Document No." = No
        IssuedFinChargeMemoHeader.FindFirst();
        RunCancelIssuedFinChargeMemoReportWithParameters(IssuedFinChargeMemoHeader, false, true, 0D);

        // [THEN] G/L entries reversed with Document No. from number series "CIR_NOS"
        VerifyReversedGLEntriesExtended(IssuedFinChargeMemoHeader."No.", ExpectedDocumentNo, IssuedFinChargeMemoHeader."Posting Date");
    end;

    [Test]
    [HandlerFunctions('BatchCancelIssuedFinChargeMemosRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CancelFinChargeMemoUseNewPostingDate()
    var
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        ExpectedPostingDate: Date;
    begin
        // [FEATURE] [Cancel Finance Charge Memo]
        // [SCENARIO 287121] Cancel issued fin. charge memo with "Use Same Posting Date" = No set new Posting Date for corrective entries
        Initialize();

        // [GIVEN] Fin. charge memo with "Posting Date" = 01.01.2020
        CreateFinChargeMemo(FinanceChargeMemoHeader);

        // [GIVEN] Issue fin. charge memo
        IssuedFinChargeMemoHeader.SetFilter("No.", IssuingFinanceChargeMemos(FinanceChargeMemoHeader."No."));

        // [WHEN] Run cancel issued fin. charge memo with "Use Same Posting Date" = No and New Posting Date = 10.01.2020
        ExpectedPostingDate := CalcDate('<10D>', WorkDate());
        IssuedFinChargeMemoHeader.FindFirst();
        RunCancelIssuedFinChargeMemoReportWithParameters(IssuedFinChargeMemoHeader, true, false, ExpectedPostingDate);

        // [THEN] G/L entries reversed with "Posting Date" = 10.01.2020
        VerifyReversedGLEntriesExtended(IssuedFinChargeMemoHeader."No.", IssuedFinChargeMemoHeader."No.", ExpectedPostingDate);
    end;

    [Test]
    [HandlerFunctions('BatchCancelIssuedFinChargeMemosRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CreateFinChargeMemoAfterCancel()
    var
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        NewFinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
    begin
        // [FEATURE] [Cancel Finance Charge Memo]
        // [SCENARIO 287121] Function "Create Finance Charge Memos" creates same fin. charge memo after cancel initial one
        Initialize();

        // [GIVEN] Fin. charge memo "1"
        CreateFinChargeMemo(FinanceChargeMemoHeader);

        // [GIVEN] Issue fin. charge memo "1"
        IssuedFinChargeMemoHeader.SetFilter("No.", IssuingFinanceChargeMemos(FinanceChargeMemoHeader."No."));

        // [GIVEN] Cancel issued fin. charge memo "1"
        IssuedFinChargeMemoHeader.FindFirst();
        RunCancelIssuedFinChargeMemo(IssuedFinChargeMemoHeader);

        // [WHEN] Run "Create Finance Charge Memos" function to create fin. charge memo "2"
        CreateSuggestFinanceChargeMemo(
          NewFinanceChargeMemoHeader, IssuedFinChargeMemoHeader."Customer No.", IssuedFinChargeMemoHeader."Document Date");

        // [THEN] Created fin. charge memo "2" with "Remaining Amount" = "100"
        VerifyRecreatedFinChargeMemo(IssuedFinChargeMemoHeader, NewFinanceChargeMemoHeader);
    end;

    [Test]
    [HandlerFunctions('BatchCancelIssuedFinChargeMemosRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CancelFinChargeMemoSeveralInvoices()
    var
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
    begin
        // [FEATURE] [Cancel Finance Charge Memo]
        // [SCENARIO 287121] Cancel issued fin. charge memo for several invoices
        Initialize();

        // [GIVEN] Issued fin. charge memo for several invoices
        IssuedFinChargeMemoHeader.Get(IssuingFinanceChargeMemos(CreateFinChargeMemoForSeveralInvoices()));

        // [WHEN] Cancel issued reminder
        RunCancelIssuedFinChargeMemo(IssuedFinChargeMemoHeader);

        // [THEN] G/L entries reversed
        VerifyFinChanrgeMemoReversedGLEntries(IssuedFinChargeMemoHeader);
        // [THEN] VAT entry reversed
        VerifyReversedVATEntries(IssuedFinChargeMemoHeader."No.");
        // [THEN] Customer ledger enery is closed
        VerifyCanceledFinChargeMemoCustLedgerEntries(IssuedFinChargeMemoHeader."No.");
    end;

    [Test]
    [HandlerFunctions('BatchCancelIssuedFinChargeMemosRequestPageHandler,AppliedCustomerLedgeEntryFinChargeMemoNotificationHandler,CustomerLedgerEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure CancelFinChargeMemoWhenCustLedgerEntryAlreadyApplied()
    var
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        ReminderCustLedgerEntryNo: Integer;
    begin
        // [FEATURE] [Cancel Finance Charge Memo]
        // [SCENARIO 287121] User cannot cancel issued fin. charge memo if interest customer ledger entry is already applied
        Initialize();

        // [GIVEN] Issued fin. charge memo with Fee Amount = "10"
        CreateFinChargeMemo(FinanceChargeMemoHeader);
        IssuedFinChargeMemoHeader.Get(IssuingFinanceChargeMemos(FinanceChargeMemoHeader."No."));

        // [GIVEN] Payment with "Amount" = "10" applied to fin. charge memo interest customer ledger "123"
        ReminderCustLedgerEntryNo := CreatePostPaymentApplyToFinChargeMemoFee(IssuedFinChargeMemoHeader);

        // [WHEN] Cancel issued reminder
        RunCancelIssuedFinChargeMemo(IssuedFinChargeMemoHeader);

        // [THEN] Notification "You must unapply customer ledger entry ... before cancelling issued reminder ..."
        Assert.AreEqual(
          StrSubstNo(
            CancelAppliedEntryFinChargeMemoErr,
            ReminderCustLedgerEntryNo,
            IssuedFinChargeMemoHeader."No."),
          LibraryVariableStorage.DequeueText(),
          'Invalid notificaion message');

        // [WHEN] Choose action "Show customer ledger entry"
        // [THEN] Customer ledger entries page openend with entry "123"
        Assert.AreEqual(ReminderCustLedgerEntryNo, LibraryVariableStorage.DequeueInteger(), 'Invalid customer ledger entry no.');

        NotificationLifecycleMgt.RecallAllNotifications();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('BatchCancelIssuedFinChargeMemosRequestPageHandler')]
    [Scope('OnPrem')]
    procedure BatchCancelFinChargeMemos()
    var
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        FirstIssuedFinChMemoNo: Code[20];
        LastIssuedFinChMemoNo: Code[20];
    begin
        // [FEATURE] [Cancel Finance Charge Memo]
        // [SCENARIO 287121] User is able to cancel several fin. charge memos at once
        Initialize();

        // [GIVEN] 5 Issued single level fin. charge memos
        CreateIssueSeveralFinChargeMemos(FirstIssuedFinChMemoNo, LastIssuedFinChMemoNo, LibraryRandom.RandIntInRange(5, 10));

        // [WHEN] run Cancel Fin. Charge Memos with filter for created fin. charge memos
        IssuedFinChargeMemoHeader.SetRange("No.", FirstIssuedFinChMemoNo, LastIssuedFinChMemoNo);
        RunCancelIssuedFinChargeMemos(IssuedFinChargeMemoHeader);

        // [THEN] All 5 issued fin. charge memos are cancelled
        IssuedFinChargeMemoHeader.FindSet();
        repeat
            IssuedFinChargeMemoHeader.TestField(Canceled, true);
        until IssuedFinChargeMemoHeader.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('BatchCancelIssuedFinChargeMemosRequestPageHandler,ConfirmHandlerYes,IssuedFinChargeMemoListModalPageHandler')]
    [Scope('OnPrem')]
    procedure BatchCancelFinChargeMemosShowErrors()
    var
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        FirstIssuedFinChMemoNo: Code[20];
        LastIssuedFinChMemoNo: Code[20];
    begin
        // [FEATURE] [Cancel Finance Charge Memo]
        // [SCENARIO 287121] Batch cancel report shows issued fin. charge memos which cannot be cancelled due to errors
        Initialize();

        // [GIVEN] 5 Issued single level fin. charge memos "1" - "5"
        CreateIssueSeveralFinChargeMemos(FirstIssuedFinChMemoNo, LastIssuedFinChMemoNo, LibraryRandom.RandIntInRange(5, 10));

        // [GIVEN] Apply payment to the Fee customer entry for reminders "1" and "5" to cause errors during cancelling
        IssuedFinChargeMemoHeader.Get(FirstIssuedFinChMemoNo);
        CreatePostPaymentApplyToFinChargeMemoFee(IssuedFinChargeMemoHeader);

        IssuedFinChargeMemoHeader.Get(LastIssuedFinChMemoNo);
        CreatePostPaymentApplyToFinChargeMemoFee(IssuedFinChargeMemoHeader);

        // [WHEN] run Cancel Reminders with filter for created fin. charge memos
        IssuedFinChargeMemoHeader.SetRange("No.", FirstIssuedFinChMemoNo, LastIssuedFinChMemoNo);
        RunCancelIssuedFinChargeMemos(IssuedFinChargeMemoHeader);

        // [THEN] Dialog "One or more of the selected issued fin. charge memos could not be canceled. Do you want to see a list of the issued fin. charge memos that were not canceled? "
        Assert.AreEqual(NotAllFinChMemosCancelledTxt, LibraryVariableStorage.DequeueText(), 'Invalid dialog text');

        // [WHEN] Confirm "see a list" question
        // [THEN] Page Issued Reminders List" opened with filtered fin. charge memos "1" and "5" only
        Assert.AreEqual(
          StrSubstNo('%1|%2', FirstIssuedFinChMemoNo, LastIssuedFinChMemoNo),
          LibraryVariableStorage.DequeueText(),
          'Unexpected issued reminders');

        NotificationLifecycleMgt.RecallAllNotifications();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IssueFinChargeWithGLAccLineWithDefDimension()
    var
        DefaultDimension: Record "Default Dimension";
        DimensionSetEntry: Record "Dimension Set Entry";
        DimValue: Record "Dimension Value";
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
        FinanceChargeTerms: Record "Finance Charge Terms";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        IssuedFinChargeMemoHeaderNo: Code[20];
    begin
        // [FEATURE] [Finance Charge Memo] [Dimensions]
        // [SCENARIO 307849] Issued Finance Charge Memo is created when Finance charge Memo with G/L Account Line with Default Dimension is issued.
        Initialize();

        // [GIVEN] G/L Account with Default Dimension with Value Posting set to "Code Mandatory".
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        GenProductPostingGroup.Get(GLAccount."Gen. Prod. Posting Group");
        GenProductPostingGroup.Validate("Def. VAT Prod. Posting Group", GLAccount."VAT Prod. Posting Group");
        GenProductPostingGroup.Modify(true);
        LibraryDimension.CreateDimWithDimValue(DimValue);
        LibraryDimension.CreateDefaultDimensionGLAcc(DefaultDimension, GLAccount."No.", DimValue."Dimension Code", DimValue.Code);
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
        DefaultDimension.Modify(true);

        // [GIVEN] Finance Charge Memo with Finance Charge Memo Line for G/L Account.
        LibraryERM.CreateFinanceChargeTerms(FinanceChargeTerms);
        LibraryERM.CreateFinanceChargeMemoHeader(FinanceChargeMemoHeader, LibrarySales.CreateCustomerNo());
        FinanceChargeMemoHeader.Validate("Fin. Charge Terms Code", FinanceChargeTerms.Code);
        FinanceChargeMemoHeader.Modify(true);
        LibraryERM.CreateFinanceChargeMemoLine(
          FinanceChargeMemoLine, FinanceChargeMemoHeader."No.", FinanceChargeMemoLine.Type::"G/L Account");
        FinanceChargeMemoLine.Validate("No.", GLAccount."No.");
        FinanceChargeMemoLine.Validate(Amount, LibraryRandom.RandIntInRange(100, 1000) * 100); // to avoid invoice rounding
        FinanceChargeMemoLine.Modify(true);

        // [WHEN] Finance Charge Memo is issued.
        IssuedFinChargeMemoHeaderNo := IssuingFinanceChargeMemos(FinanceChargeMemoHeader."No.");

        // [THEN] Issued Finance Charge Memo exists.
        IssuedFinChargeMemoHeader.SetRange("No.", IssuedFinChargeMemoHeaderNo);
        Assert.RecordIsNotEmpty(IssuedFinChargeMemoHeader);

        // [THEN] G/L Entry has Dimension of G/L Account.
        GLEntry.SetRange("Document No.", IssuedFinChargeMemoHeaderNo);
        GLEntry.SetRange("G/L Account No.", GLAccount."No.");
        GLEntry.FindFirst();
        LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, GLEntry."Dimension Set ID");
        Assert.AreEqual(DimValue.Code, DimensionSetEntry."Dimension Value Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoSeriesOfIssuedFinChargeMemo()
    var
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        FinanceChargeMemoHeaderNo: Code[20];
        IssuedFinChargeMemoHeaderNo: Code[20];
    begin
        // [FEATURE] [Finance Charge Memo] [No. Series]
        // [SCENARIO 309515] Correct "No. Series" and "Pre-Assigned No. Series" assigned to Issued Finance Charge Memo.

        // [GIVEN] Finance Charge Memo.
        CreateIssueFinChargeWithCommentLine(FinanceChargeMemoHeaderNo);
        FinanceChargeMemoHeader.Get(FinanceChargeMemoHeaderNo);

        // [WHEN] Finance Charge Memo is issued.
        IssuedFinChargeMemoHeaderNo := IssuingFinanceChargeMemos(FinanceChargeMemoHeaderNo);
        IssuedFinChargeMemoHeader.Get(IssuedFinChargeMemoHeaderNo);

        // [THEN] For Issued Finance Charge Memo "Pre-Assigned No. Series" is equal to "No. Series" of Finance Charge Memo.
        Assert.AreEqual(FinanceChargeMemoHeader."No. Series", IssuedFinChargeMemoHeader."Pre-Assigned No. Series", '');
        // [THEN] For Issued Finance Charge Memo "No. Series" is equal to "No. Series" of Finance Charge Memo.
        Assert.AreEqual(FinanceChargeMemoHeader."Issuing No. Series", IssuedFinChargeMemoHeader."No. Series", '');
    end;

    [Test]
    [HandlerFunctions('ReminderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReminderReportCompanyInfoVATRegistrationNoCaption()
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        CompanyInformation: Record "Company Information";
    begin
        // [FEATURE] [UT] [Reminder]
        // [SCENARIO 315402] Report Reminder prints VAT Registration No. caption for company information section
        Initialize();

        // [GIVEN] Issued reminder 
        MockIssuedReminder(IssuedReminderHeader);

        // [WHEN] Reminder is being printed
        IssuedReminderHeader.SetRecFilter();
        Commit();
        REPORT.Run(REPORT::Reminder, true, false, IssuedReminderHeader);

        // [THEN] VAT Registration No. caption printed in company information section
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('CompanyVATRegistrationNoCaption', CompanyInformation.GetVATRegistrationNumberLbl());
    end;

    [Test]
    [HandlerFunctions('FinanceChargeMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure FinanceChargeMemoReportCustomerEnterpriseNo()
    var
        IssuedFinanceChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        CompanyInformation: Record "Company Information";
    begin
        // [FEATURE] [UT] [Finance Charge Memo]
        // [SCENARIO 315402] Report Finance Charge Memo prints VAT Registration No. caption for company information section
        Initialize();

        // [GIVEN] Issued Finance Charge Memo 
        MockIssuedFinanceChargeMemo(IssuedFinanceChargeMemoHeader);

        // [WHEN] Finance Charge Memo is being printed
        IssuedFinanceChargeMemoHeader.SetRecFilter();
        Commit();
        REPORT.Run(REPORT::"Finance Charge Memo", true, false, IssuedFinanceChargeMemoHeader);

        // [THEN] VAT Registration No. caption printed in company information section
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('CompanyVATRegistrationNoCaption', CompanyInformation.GetVATRegistrationNumberLbl());
    end;

    [Test]
    [HandlerFunctions('BatchCancelIssuedRemindersRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CancelIssuedReminderWithInterestAmount()
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        ReminderNo: Code[20];
    begin
        // [FEATURE] [Cancel Reminder]
        // [SCENARIO 332963] Cancel issued reminder with "Calculate Interest" = "Yes" , "Post Interest" = "Yes" reversed Customer, VAT and G/L entries
        Initialize();

        // [GIVEN] Single level reminder with "Post Interest" = "Yes", "Remaining Amount" = "100", "Calculate Interest" = "Yes"
        ReminderNo := CreateReminderWithReminderTermsAndFinChargeTerms(CreateReminderTerms(false, true, true, true));

        // [GIVEN] Issue reminder
        IssuedReminderHeader.Get(
          IssueReminder(ReminderNo, WorkDate()));

        // [WHEN] Cancel issued reminder
        RunCancelIssuedReminder(IssuedReminderHeader);

        // [THEN] G/L entries reversed
        VerifyReminderReversedGLEntries(IssuedReminderHeader."No.");
        // [THEN] VAT entry reversed
        VerifyReversedVATEntries(IssuedReminderHeader."No.");
        // [THEN] Customer ledger enery is closed
        VerifyCanceledReminderCustLedgerEntries(IssuedReminderHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReminderWithCurrencyRounding()
    var
        Customer: Record Customer;
        Currency: Record Currency;
        CurrencyForReminderLevel: Record "Currency for Reminder Level";
        ReminderLevel: Record "Reminder Level";
        ReminderLine: Record "Reminder Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReminderNo: Code[20];
    begin
        // [SCENARIO 409875] Reminder with Currency creation should use Currency Rounding instead of Invoice Rounding
        Initialize();

        // [GIVEN] General Ledger Setup "Invoice Rounding Precision (LCY)" = 10
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Inv. Rounding Precision (LCY)" := 10;
        GeneralLedgerSetup.Modify();

        // [GIVEN] Sales & Receivables Setup "Invoice Rounding" = true
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Invoice Rounding" := true;
        SalesReceivablesSetup.Modify();

        // [GIVEN] Currency "C" with exchange rate 1:1 and Invoice/Amount Rounding Precision = 0.01
        Currency.Get(LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 1));
        Currency."Invoice Rounding Precision" := 0.01;
        Currency."Amount Rounding Precision" := 0.01;
        Currency.Modify();

        // [GIVEN] Reminder Level with Currency "C"
        LibraryERM.CreateCurrencyForReminderLevel(CurrencyForReminderLevel, CreateOneLevelReminderTerms(), Currency.Code);

        // [GIVEN] Posted Sales Invoice for Customer "Cust" and Amount = 6 (if test fails there will be rounding line with amount 4)
        CreateCustomer(Customer, '', Currency.Code, CurrencyForReminderLevel."Reminder Terms Code");
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), 1);
        SalesLine.Validate("Unit Price", 6);
        SalesLine.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        GetReminderLevel(ReminderLevel, Customer."Reminder Terms Code", 0);

        // [WHEN] Reminder is created for Customer "CUST"
        ReminderNo :=
            CreateReminder(
                Customer."No.",
                LibraryRandom.RandDateFrom(CalcDate(ReminderLevel."Grace Period", SalesHeader."Due Date"), LibraryRandom.RandIntInRange(1, 10)));

        // [THEN] Reminder line with "Remaining Amount" = Amount of Sales Invoice
        ReminderLine.SetRange("Reminder No.", ReminderNo);
        ReminderLine.SetRange(Type, ReminderLine.Type::"Customer Ledger Entry");
        ReminderLine.SetRange("Remaining Amount", SalesLine."Amount Including VAT");
        Assert.RecordIsNotEmpty(ReminderLine);

        ReminderLine.Reset();

        // [THEN] No Rounding Line added
        ReminderLine.SetRange("Reminder No.", ReminderNo);
        ReminderLine.SetRange("Line Type", ReminderLine."Line Type"::Rounding);
        Assert.RecordIsEmpty(ReminderLine);
    end;

    [Test]
    [HandlerFunctions('BatchCancelIssuedRemindersRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CancelIssuedReminderMultipleTimesWithInterestAmount()
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        ReminderTerms: Record "Reminder Terms";
        Customer: Record Customer;
        CancelDocumentCount: Integer;
        DocumentDate: Date;
    begin
        // [SCENARIO 474463] Verify and cancel the issued reminder multiple times with the interest amount.
        Initialize();

        // [GIVEN] Create Reminder Terms and Reminder Level With Calculate Interest.
        CreateReminderTermsAndLevelWithCalculateInterest(ReminderTerms, true);

        // [GIVEN] Create a customer with finance charge terms, reminder terms and an interest rate.
        CreateCustomerWithFinanceChargeTermsAndInterestRate(Customer, ReminderTerms.Code);

        // [GIVEN] Post the sales invoice and save a document date.
        DocumentDate := CreateAndPostSalesInvoice(Customer."No.") + LibraryRandom.RandInt(1000);

        // [GIVEN] Generate and save the cancelled document count.
        CancelDocumentCount := LibraryRandom.RandIntInRange(2, 10);

        // [WHEN] Create and cancel the issued reminder with interest amount.
        CreateAndCancelIssuedReminder(Customer."No.", DocumentDate, CancelDocumentCount);

        // [VERIFY] Verify that cancelled issued reminder multiple times with the interest amount.
        IssuedReminderHeader.SetRange("Customer No.", Customer."No.");
        IssuedReminderHeader.SetRange(Canceled, true);
        Assert.RecordCount(IssuedReminderHeader, CancelDocumentCount);
    end;

    [Test]
    [HandlerFunctions('BatchCancelIssuedRemindersRequestPageHandler')]
    procedure CancelIssuedReminderCancelsCorrectAmount()
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        ReminderNo: Code[20];
    begin
        // [SCENARIO 558925] Correct Interest Amounts upon the Reversal of an Issued Reminder.
        Initialize();

        // [GIVEN] Create Reminder with Reminder Terms and Finance Charge Terms.
        ReminderNo := CreateReminderWithReminderTermsAndFinChargeTerms(CreateReminderTerms(false, true, true, true));

        // [GIVEN] Create Issued Reminder.
        IssuedReminderHeader.Get(IssueReminder(ReminderNo, WorkDate()));

        // [WHEN] Cancel Issued Reminder.
        RunCancelIssuedReminder(IssuedReminderHeader);

        // [THEN] Amount must be same but in opposite sign.
        VerifyAmountInGLEntries(IssuedReminderHeader."No.");
    end;

    local procedure Initialize()
    var
        FeatureKey: Record "Feature Key";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Reminder/Fin.Charge Memo");
        LibraryVariableStorage.Clear();
        // Clear global variable.
        Clear(LibraryReportDataset);
        Clear(LibraryVariableStorage);
        LibrarySetupStorage.Restore();

        if FeatureKey.Get('ReminderTermsCommunicationTexts') then begin
            FeatureKey.Enabled := FeatureKey.Enabled::None;
            FeatureKey.Modify();
        end;

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Reminder/Fin.Charge Memo");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        LibrarySetupStorage.SaveSalesSetup();
        LibrarySetupStorage.SaveGeneralLedgerSetup();
        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Reminder/Fin.Charge Memo");
    end;

    local procedure CreateAndPostSalesInvoice(CustomerNo: Code[20]): Date
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Take Random Quantity for Sales Invoice.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        exit(SalesHeader."Due Date");
    end;

    local procedure CreateAndSuggestReminderLineWithDueDate(CustomerNo: Code[20]) ReminderNo: Code[20]
    var
        GracePeriod: DateFormula;
        DueDateCalc: DateFormula;
        DocumentDueDate: Date;
    begin
        DocumentDueDate := CreateAndPostSalesInvoice(CustomerNo);
        GetCustomerReminderLevel(GracePeriod, DueDateCalc, CustomerNo, 0);
        ReminderNo := CreateReminder(CustomerNo, CalcDate(DueDateCalc, DocumentDueDate));
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateCustomer(var Customer: Record Customer; FinChargeTermsCode: Code[10]; CurrencyCode: Code[10]; ReminderTermsCode: Code[10])
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Validate("Reminder Terms Code", ReminderTermsCode);
        Customer.Validate("Fin. Charge Terms Code", FinChargeTermsCode);
        Customer.Modify(true);
        UpdateCustomerPostingGroupAddFeePerLineAccount(Customer."Customer Posting Group");
    end;

    local procedure CreateFinChargeMemo(var FinanceChargeMemoHeader: Record "Finance Charge Memo Header")
    var
        Customer: Record Customer;
        FinanceChargeTerms: Record "Finance Charge Terms";
        DueDate: Date;
    begin
        LibraryFinanceChargeMemo.CreateFinanceChargeTermAndText(FinanceChargeTerms);
        CreateCustomer(Customer, FinanceChargeTerms.Code, CreateCurrency(), CreateOneLevelReminderTerms());
        DueDate := CreateAndPostSalesInvoice(Customer."No.");

        // Create Finance Charge Memo and Suggest Lines for Customer. Issue Finance Charge Memo. Take Random integer to calculate Date.
        CreateSuggestFinanceChargeMemo(
          FinanceChargeMemoHeader, Customer."No.", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>',
            CalcDate(FinanceChargeTerms."Grace Period", DueDate)));
    end;

    local procedure CreateFinChargeMemoForSeveralInvoices(): Code[20]
    var
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        Customer: Record Customer;
        FinanceChargeTerms: Record "Finance Charge Terms";
        DueDate: Date;
        i: Integer;
    begin
        LibraryFinanceChargeMemo.CreateFinanceChargeTermAndText(FinanceChargeTerms);
        CreateCustomer(Customer, FinanceChargeTerms.Code, CreateCurrency(), CreateOneLevelReminderTerms());

        DueDate := CreateAndPostSalesInvoice(Customer."No.");
        for i := 1 to LibraryRandom.RandInt(5) do
            DueDate := CreateAndPostSalesInvoice(Customer."No.");

        CreateSuggestFinanceChargeMemo(
          FinanceChargeMemoHeader, Customer."No.", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>',
            CalcDate(FinanceChargeTerms."Grace Period", DueDate)));
        exit(FinanceChargeMemoHeader."No.");
    end;

    local procedure CreateReminder(CustomerNo: Code[20]; DocumentDate: Date): Code[20]
    var
        Customer: Record Customer;
        ReminderHeader: Record "Reminder Header";
        CreateReminders: Report "Create Reminders";
    begin
        Clear(CreateReminders);
        Customer.SetRange("No.", CustomerNo);
        CreateReminders.SetTableView(Customer);
        CreateReminders.InitializeRequest(DocumentDate, DocumentDate, false, false, false);
        CreateReminders.UseRequestPage(false);
        CreateReminders.Run();
        ReminderHeader.SetRange("Customer No.", CustomerNo);
        ReminderHeader.SetRange("Document Date", DocumentDate);
        ReminderHeader.FindLast();
        exit(ReminderHeader."No.");
    end;

    local procedure CreateReminderLevel(ReminderTermsCode: Code[10]; CalcInterest: Boolean)
    var
        ReminderLevel: Record "Reminder Level";
    begin
        // Create Reminder Level with a Random Grace Period and Random Additional Fee.
        LibraryERM.CreateReminderLevel(ReminderLevel, ReminderTermsCode);
        Evaluate(ReminderLevel."Grace Period", '<' + Format(LibraryRandom.RandInt(10)) + 'D>');
        ReminderLevel.Validate("Additional Fee (LCY)", LibraryRandom.RandInt(10));
        ReminderLevel.Validate("Add. Fee per Line Amount (LCY)", LibraryRandom.RandInt(10));
        ReminderLevel.Validate("Calculate Interest", CalcInterest);
        ReminderLevel.Modify(true);
    end;

    local procedure CreateReminderTerms(PostLineFee: Boolean; PostInterest: Boolean; PostAddFee: Boolean; CalcInterest: Boolean): Code[10]
    var
        ReminderTerms: Record "Reminder Terms";
    begin
        LibraryERM.CreateReminderTerms(ReminderTerms);
        ReminderTerms.Validate("Post Interest", PostInterest);
        ReminderTerms.Validate("Post Add. Fee per Line", PostLineFee);
        ReminderTerms.Validate("Post Additional Fee", PostAddFee);
        ReminderTerms.Validate("Note About Line Fee on Report", '%1 %2 %3 %4');
        ReminderTerms.Modify(true);
        CreateReminderLevel(ReminderTerms.Code, CalcInterest);
        exit(ReminderTerms.Code)
    end;

    local procedure CreateOneLevelReminderTerms(): Code[10]
    var
        ReminderTerms: Record "Reminder Terms";
    begin
        LibraryERM.CreateReminderTerms(ReminderTerms);
        CreateReminderLevel(ReminderTerms.Code, false);
        exit(ReminderTerms.Code);
    end;

    local procedure CreateReminderLevelWithDueDate(ReminderTermsCode: Code[10])
    var
        ReminderLevel: Record "Reminder Level";
    begin
        LibraryERM.CreateReminderLevel(ReminderLevel, ReminderTermsCode);
        Evaluate(ReminderLevel."Due Date Calculation", '<' + Format(LibraryRandom.RandInt(10)) + 'D>');
        ReminderLevel.Modify(true);
    end;

    local procedure CreateReminderTermsWithDueDate(Levels: Integer): Code[10]
    var
        ReminderTerms: Record "Reminder Terms";
        i: Integer;
    begin
        LibraryERM.CreateReminderTerms(ReminderTerms);
        for i := 1 to Levels do
            CreateReminderLevelWithDueDate(ReminderTerms.Code);
        exit(ReminderTerms.Code);
    end;

    local procedure CreateSuggestFinanceChargeMemo(var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; CustomerNo: Code[20]; DocumentDate: Date)
    begin
        LibraryERM.CreateFinanceChargeMemoHeader(FinanceChargeMemoHeader, CustomerNo);
        FinanceChargeMemoHeader.Validate("Document Date", DocumentDate);
        FinanceChargeMemoHeader.Modify(true);
        SuggestFinanceChargeMemoLines(FinanceChargeMemoHeader);
    end;

    local procedure CreateReminderCommentLine(ReminderNo: Code[20])
    var
        ReminderCommentLine: Record "Reminder Comment Line";
    begin
        ReminderCommentLine.Init();
        ReminderCommentLine.Validate(
          "Line No.", LibraryUtility.GetNewRecNo(ReminderCommentLine, ReminderCommentLine.FieldNo("Line No.")));
        ReminderCommentLine.Validate("No.", ReminderNo);
        ReminderCommentLine.Validate(Type, ReminderCommentLine.Type::Reminder);
        ReminderCommentLine.Insert(true);
    end;

    local procedure CreateReminderWithReminderTerms(ReminderTermsCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
        ReminderLevel: Record "Reminder Level";
        DueDate: Date;
        DocumentDate: Date;
    begin
        CreateCustomer(Customer, '', '', ReminderTermsCode);
        DueDate := CreateAndPostSalesInvoice(Customer."No.");
        GetReminderLevel(ReminderLevel, Customer."Reminder Terms Code", 0);
        DocumentDate := LibraryRandom.RandDateFrom(CalcDate(ReminderLevel."Grace Period", DueDate), LibraryRandom.RandIntInRange(1, 10));
        exit(CreateReminder(Customer."No.", DocumentDate));
    end;

    local procedure CreateReminderWithReminderTermsAndFinChargeTerms(ReminderTermsCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
        ReminderLevel: Record "Reminder Level";
        FinanceChargeTerms: Record "Finance Charge Terms";
        DueDate: Date;
        DocumentDate: Date;
    begin
        LibraryFinanceChargeMemo.CreateFinanceChargeTermAndText(FinanceChargeTerms);
        CreateCustomer(Customer, FinanceChargeTerms.Code, '', ReminderTermsCode);
        DueDate := CreateAndPostSalesInvoice(Customer."No.");
        GetReminderLevel(ReminderLevel, Customer."Reminder Terms Code", 0);
        DocumentDate := LibraryRandom.RandDateFrom(CalcDate(ReminderLevel."Grace Period", DueDate), LibraryRandom.RandIntInRange(1, 10));
        exit(CreateReminder(Customer."No.", DocumentDate));
    end;

    local procedure CreateReminderForSeveralInvoicesWithReminderTerms(ReminderTermsCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
        ReminderLevel: Record "Reminder Level";
        DueDate: Date;
        DocumentDate: Date;
        i: Integer;
    begin
        CreateCustomer(Customer, '', '', ReminderTermsCode);
        DueDate := CreateAndPostSalesInvoice(Customer."No.");
        for i := 1 to LibraryRandom.RandInt(5) do
            CreateAndPostSalesInvoice(Customer."No.");
        GetReminderLevel(ReminderLevel, Customer."Reminder Terms Code", 0);
        DocumentDate := LibraryRandom.RandDateFrom(CalcDate(ReminderLevel."Grace Period", DueDate), LibraryRandom.RandIntInRange(1, 10));
        exit(CreateReminder(Customer."No.", DocumentDate));
    end;

    local procedure CreateFinChargeCommentLine(FinChargeNo: Code[20])
    var
        FinChargeCommentLine: Record "Fin. Charge Comment Line";
    begin
        FinChargeCommentLine.Init();
        FinChargeCommentLine.Validate(
          "Line No.", LibraryUtility.GetNewRecNo(FinChargeCommentLine, FinChargeCommentLine.FieldNo("Line No.")));
        FinChargeCommentLine.Validate("No.", FinChargeNo);
        FinChargeCommentLine.Validate(Type, FinChargeCommentLine.Type::"Finance Charge Memo");
        FinChargeCommentLine.Insert(true);
    end;

    local procedure CreateIssueReminderWithCommentLine(var ReminderNo: Code[20]; var DocumentDate: Date)
    var
        Customer: Record Customer;
        ReminderLevel: Record "Reminder Level";
        DueDate: Date;
    begin
        CreateCustomer(Customer, '', CreateCurrency(), CreateOneLevelReminderTerms());
        DueDate := CreateAndPostSalesInvoice(Customer."No.");
        GetReminderLevel(ReminderLevel, Customer."Reminder Terms Code", 0);
        DocumentDate := LibraryRandom.RandDateFrom(CalcDate(ReminderLevel."Grace Period", DueDate), LibraryRandom.RandIntInRange(1, 10));
        ReminderNo := CreateReminder(Customer."No.", DocumentDate);
        CreateReminderCommentLine(ReminderNo);
    end;

    local procedure CreateIssueFinChargeWithCommentLine(var FinChargeNo: Code[20])
    var
        Customer: Record Customer;
        FinanceChargeTerms: Record "Finance Charge Terms";
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        DueDate: Date;
    begin
        LibraryFinanceChargeMemo.CreateFinanceChargeTermAndText(FinanceChargeTerms);
        CreateCustomer(Customer, FinanceChargeTerms.Code, CreateCurrency(), CreateOneLevelReminderTerms());
        DueDate := CreateAndPostSalesInvoice(Customer."No.");
        CreateSuggestFinanceChargeMemo(
          FinanceChargeMemoHeader, Customer."No.",
          LibraryRandom.RandDateFrom(CalcDate(FinanceChargeTerms."Grace Period", DueDate),
            LibraryRandom.RandIntInRange(1, 10)));
        FinChargeNo := FinanceChargeMemoHeader."No.";
        CreateFinChargeCommentLine(FinChargeNo);
    end;

    local procedure CreateIssueSeveralReminders(var FirstIssuedReminderNo: Code[20]; var LastIssuedReminderNo: Code[20]; NumberOfReminders: Integer)
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        i: Integer;
    begin
        for i := 1 to NumberOfReminders do begin
            IssuedReminderHeader.Get(
              IssueReminder(CreateReminderWithReminderTerms(CreateReminderTerms(true, true, true, false)), WorkDate()));
            if i = 1 then
                FirstIssuedReminderNo := IssuedReminderHeader."No.";
            if i = NumberOfReminders then
                LastIssuedReminderNo := IssuedReminderHeader."No."
        end;
    end;

    local procedure CreateIssueSeveralFinChargeMemos(var FirstIssuedReminderNo: Code[20]; var LastIssuedReminderNo: Code[20]; NumberOfReminders: Integer)
    var
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        i: Integer;
    begin
        for i := 1 to NumberOfReminders do begin
            CreateFinChargeMemo(FinanceChargeMemoHeader);
            IssuedFinChargeMemoHeader.Get(IssuingFinanceChargeMemos(FinanceChargeMemoHeader."No."));
            if i = 1 then
                FirstIssuedReminderNo := IssuedFinChargeMemoHeader."No.";
            if i = NumberOfReminders then
                LastIssuedReminderNo := IssuedFinChargeMemoHeader."No."
        end;
    end;

    local procedure CreatePaymentJnlLine(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, AccountNo, Amount);
    end;

    local procedure CreatePostPaymentApplyToReminderFee(IssuedReminderHeader: Record "Issued Reminder Header"): Integer
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", IssuedReminderHeader."Customer No.");
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Reminder);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields("Remaining Amt. (LCY)");
        CreatePaymentJnlLine(GenJournalLine, IssuedReminderHeader."Customer No.", -CustLedgerEntry."Remaining Amt. (LCY)");

        GenJournalLine.Validate("Posting Date", CustLedgerEntry."Posting Date");
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Reminder);
        GenJournalLine.Validate("Applies-to Doc. No.", CustLedgerEntry."Document No.");
        GenJournalLine.Modify();

        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        exit(CustLedgerEntry."Entry No.");
    end;

    local procedure CreatePostPaymentApplyToFinChargeMemoFee(IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header"): Integer
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", IssuedFinChargeMemoHeader."Customer No.");
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::"Finance Charge Memo");
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields("Remaining Amt. (LCY)");
        CreatePaymentJnlLine(GenJournalLine, IssuedFinChargeMemoHeader."Customer No.", -CustLedgerEntry."Remaining Amt. (LCY)");

        GenJournalLine.Validate("Posting Date", CustLedgerEntry."Posting Date");
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::"Finance Charge Memo");
        GenJournalLine.Validate("Applies-to Doc. No.", CustLedgerEntry."Document No.");
        GenJournalLine.Modify();

        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        exit(CustLedgerEntry."Entry No.");
    end;

    local procedure GetFirstTransactionNo(IssuedReminderNo: Code[20]): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", IssuedReminderNo);
        GLEntry.FindFirst();
        exit(GLEntry."Transaction No.");
    end;

    local procedure GetLastTransactionNo(IssuedReminderNo: Code[20]): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", IssuedReminderNo);
        GLEntry.FindLast();
        exit(GLEntry."Transaction No.");
    end;

    local procedure MockReminderLine(var ReminderLine: Record "Reminder Line"; ReminderHeader: Record "Reminder Header")
    begin
        ReminderLine."Reminder No." := ReminderHeader."No.";
        ReminderLine."Line No." := LibraryUtility.GetNewRecNo(ReminderLine, ReminderLine.FieldNo("Line No."));
        ReminderLine.Insert();
    end;

    local procedure MockFinChargeMemoLine(var FinanceChargeMemoLine: Record "Finance Charge Memo Line"; FinanceChargeMemoHeader: Record "Finance Charge Memo Header")
    begin
        FinanceChargeMemoLine."Finance Charge Memo No." := FinanceChargeMemoHeader."No.";
        FinanceChargeMemoLine."Line No." := LibraryUtility.GetNewRecNo(FinanceChargeMemoLine, FinanceChargeMemoLine.FieldNo("Line No."));
        FinanceChargeMemoLine.Insert();
    end;

    local procedure MockTwoIssuedRemindersSingleCustomer(var IssuedReminderHeader: Record "Issued Reminder Header")
    var
        Customer: Record Customer;
        IssuedReminderLine: Record "Issued Reminder Line";
        RemindersQty: Integer;
    begin
        LibrarySales.CreateCustomer(Customer);
        for RemindersQty := 1 to 2 do begin
            IssuedReminderHeader.Init();
            IssuedReminderHeader."No." := LibraryUtility.GenerateGUID();
            IssuedReminderHeader."Customer No." := Customer."No.";
            IssuedReminderHeader."Customer Posting Group" := Customer."Gen. Bus. Posting Group";
            IssuedReminderHeader."VAT Bus. Posting Group" := Customer."VAT Bus. Posting Group";
            IssuedReminderHeader."Posting Date" := WorkDate();
            IssuedReminderHeader."Document Date" := WorkDate();
            IssuedReminderHeader."Due Date" := WorkDate();
            IssuedReminderHeader.Insert();
            IssuedReminderLine.Init();
            IssuedReminderLine."Reminder No." := IssuedReminderHeader."No.";
            IssuedReminderLine.Amount := LibraryRandom.RandDec(100, 2);
            IssuedReminderLine.Type := IssuedReminderLine.Type::"Customer Ledger Entry";
            IssuedReminderLine."Line No." := 1;
            IssuedReminderLine.Insert();
        end;
    end;

    local procedure MockIssuedReminder(var IssuedReminderHeader: Record "Issued Reminder Header")
    var
        IssuedReminderLine: Record "Issued Reminder Line";
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        IssuedReminderHeader.Init();
        IssuedReminderHeader."No." :=
          LibraryUtility.GenerateRandomCode(IssuedReminderHeader.FieldNo("No."), DATABASE::"Issued Reminder Header");
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
        CustomerPostingGroup."Additional Fee Account" := '';
        CustomerPostingGroup.Modify();
        IssuedReminderHeader."Customer Posting Group" := CustomerPostingGroup.Code;
        IssuedReminderHeader."Due Date" := LibraryRandom.RandDate(LibraryRandom.RandIntInRange(10, 100));
        IssuedReminderHeader.Insert();
        IssuedReminderLine.Init();
        IssuedReminderLine."Line No." := LibraryUtility.GetNewRecNo(IssuedReminderLine, IssuedReminderLine.FieldNo("Line No."));
        IssuedReminderLine."Line Type" := IssuedReminderLine."Line Type"::"Reminder Line";
        IssuedReminderLine."Reminder No." := IssuedReminderHeader."No.";
        IssuedReminderLine."Due Date" := IssuedReminderHeader."Due Date";
        IssuedReminderLine."Remaining Amount" := LibraryRandom.RandIntInRange(10, 100);
        IssuedReminderLine.Amount := IssuedReminderLine."Remaining Amount";
        IssuedReminderLine.Type := IssuedReminderLine.Type::"G/L Account";
        IssuedReminderLine.Insert();
    end;

    local procedure MockIssuedFinanceChargeMemo(var IssuedFinanceChargeMemoHeader: Record "Issued Fin. Charge Memo Header")
    var
        IssuedFinanceChargeMemoLine: Record "Issued Fin. Charge Memo Line";
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        IssuedFinanceChargeMemoHeader.Init();
        IssuedFinanceChargeMemoHeader."No." :=
          LibraryUtility.GenerateRandomCode(IssuedFinanceChargeMemoHeader.FieldNo("No."), DATABASE::"Issued Fin. Charge Memo Header");
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
        CustomerPostingGroup."Additional Fee Account" := '';
        CustomerPostingGroup.Modify();
        IssuedFinanceChargeMemoHeader."Customer Posting Group" := CustomerPostingGroup.Code;
        IssuedFinanceChargeMemoHeader."Customer No." := LibrarySales.CreateCustomerNo();
        IssuedFinanceChargeMemoHeader."Due Date" := LibraryRandom.RandDate(LibraryRandom.RandIntInRange(10, 100));
        IssuedFinanceChargeMemoHeader.Insert();
        IssuedFinanceChargeMemoLine.Init();
        IssuedFinanceChargeMemoLine."Line No." := LibraryUtility.GetNewRecNo(IssuedFinanceChargeMemoLine, IssuedFinanceChargeMemoLine.FieldNo("Line No."));
        IssuedFinanceChargeMemoLine."Finance Charge Memo No." := IssuedFinanceChargeMemoHeader."No.";
        IssuedFinanceChargeMemoLine."Due Date" := IssuedFinanceChargeMemoHeader."Due Date";
        IssuedFinanceChargeMemoLine."Remaining Amount" := LibraryRandom.RandIntInRange(10, 100);
        IssuedFinanceChargeMemoLine.Amount := IssuedFinanceChargeMemoLine."Remaining Amount";
        IssuedFinanceChargeMemoLine.Type := IssuedFinanceChargeMemoLine.Type::"G/L Account";
        IssuedFinanceChargeMemoLine.Insert();
    end;

    local procedure UpdateCustomerPostingGroupAddFeePerLineAccount(CustomerPostingGroupCode: Code[20])
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        CustomerPostingGroup.Get(CustomerPostingGroupCode);
        if CustomerPostingGroup."Add. Fee per Line Account" = '' then begin
            CustomerPostingGroup.Validate("Add. Fee per Line Account", LibraryERM.CreateGLAccountWithSalesSetup());
            CustomerPostingGroup.Modify();
        end;
    end;

    local procedure ValidateReminderLineStandardCode(var ReminderLine: Record "Reminder Line"; StandardTextCode: Code[20])
    var
        TransferExtendedText: Codeunit "Transfer Extended Text";
    begin
        ReminderLine.Validate("No.", StandardTextCode);
        ReminderLine.Modify(true);
        TransferExtendedText.ReminderCheckIfAnyExtText(ReminderLine, false);
        TransferExtendedText.InsertReminderExtText(ReminderLine);
    end;

    local procedure ValidateFinChargeMemoLineStandardCode(var FinanceChargeMemoLine: Record "Finance Charge Memo Line"; StandardTextCode: Code[20])
    var
        TransferExtendedText: Codeunit "Transfer Extended Text";
    begin
        FinanceChargeMemoLine.Validate("No.", StandardTextCode);
        FinanceChargeMemoLine.Modify(true);
        TransferExtendedText.FinChrgMemoCheckIfAnyExtText(FinanceChargeMemoLine, false);
        TransferExtendedText.InsertFinChrgMemoExtText(FinanceChargeMemoLine);
    end;

    local procedure DocumentEntriesForIssuedReminder(var IssuedReminderHeader: Record "Issued Reminder Header"; ShowInLCY: Boolean)
    var
        Customer: Record Customer;
        ReminderLevel: Record "Reminder Level";
        IssuedReminder: TestPage "Issued Reminder";
        IssuedReminderPage: Page "Issued Reminder";
        DueDate: Date;
        DocumentDate: Date;
        IssuedReminderNo: Code[20];
        ReminderNo: Code[20];
    begin
        // Setup: Create Customer. Create and post Sales Invoice.
        Initialize();
        CreateCustomer(Customer, '', CreateCurrency(), CreateOneLevelReminderTerms());
        DueDate := CreateAndPostSalesInvoice(Customer."No.");
        GetReminderLevel(ReminderLevel, Customer."Reminder Terms Code", 0);

        // Use Random Integer value to calculate Document date.
        DocumentDate :=
          CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', CalcDate(ReminderLevel."Grace Period", DueDate));

        // Create and Issue the Reminder.
        ReminderNo := CreateReminder(Customer."No.", DocumentDate);
        IssuedReminderNo := IssueReminder(ReminderNo, DocumentDate);
        LibraryVariableStorage.Enqueue(ShowInLCY);  // Enqueue value for DocumentEntriesRequestPageHandler.
        IssuedReminder.OpenView();
        IssuedReminder.FILTER.SetFilter("No.", IssuedReminderNo);

        // Exercise: Run Document Entries Report from NavigatePagehandler.
        IssuedReminder."&Navigate".Invoke();  // Invoking Navigate.

        // Verify: Verify Issued Reminder Table Name and number of Records on Document Entries Report.
        LibraryReportDataset.LoadDataSetFile();
        IssuedReminderHeader.SetRange("No.", IssuedReminderNo);
        VerifyDocumentEntries(TableName, IssuedReminderPage.Caption, NoOfRecords, IssuedReminderHeader.Count);
        IssuedReminderHeader.FindFirst();
        IssuedReminderHeader.CalcFields("Additional Fee", "Remaining Amount");
    end;

    local procedure DocumentEntriesForIssuedFinanceChargeMemo(var IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header"; ShowInLCY: Boolean)
    var
        Customer: Record Customer;
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        FinanceChargeTerms: Record "Finance Charge Terms";
        IssuedFinanceChargeMemo: TestPage "Issued Finance Charge Memo";
        IssuedFinanceChargeMemoPage: Page "Issued Finance Charge Memo";
        DueDate: Date;
    begin
        // Setup: Create Finance Charge Terms and Customer. Create and post Sales Invoice. Calculated Document Date.
        Initialize();
        LibraryFinanceChargeMemo.CreateFinanceChargeTermAndText(FinanceChargeTerms);
        CreateCustomer(Customer, FinanceChargeTerms.Code, CreateCurrency(), CreateOneLevelReminderTerms());
        DueDate := CreateAndPostSalesInvoice(Customer."No.");

        // Create Finance Charge Memo and Suggest Lines for Customer. Issue Finance Charge Memo. Take Random integer to calculate Date.
        CreateSuggestFinanceChargeMemo(
          FinanceChargeMemoHeader, Customer."No.", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>',
            CalcDate(FinanceChargeTerms."Grace Period", DueDate)));
        IssuingFinanceChargeMemos(FinanceChargeMemoHeader."No.");
        LibraryVariableStorage.Enqueue(ShowInLCY);  // Enqueue value for DocumentEntriesRequestPageHandler.
        IssuedFinanceChargeMemo.OpenView();
        IssuedFinanceChargeMemo.FILTER.SetFilter("Pre-Assigned No.", FinanceChargeMemoHeader."No.");

        // Exercise: Run Document Entries Report from NavigatePagehandler.
        IssuedFinanceChargeMemo."&Navigate".Invoke();  // Invoking Navigate.

        // Verify: Verify Issued Reminder Table Name and number of Records on Document Entries Report.
        LibraryReportDataset.LoadDataSetFile();
        IssuedFinChargeMemoHeader.SetRange("Pre-Assigned No.", FinanceChargeMemoHeader."No.");
        VerifyDocumentEntries(TableName, IssuedFinanceChargeMemoPage.Caption, NoOfRecords, IssuedFinChargeMemoHeader.Count);
        IssuedFinChargeMemoHeader.FindFirst();
        IssuedFinChargeMemoHeader.CalcFields("Additional Fee", "Remaining Amount");
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(Item,
          LibraryRandom.RandDec(1000, 2), LibraryRandom.RandDec(1000, 2));
        exit(Item."No.");
    end;

    local procedure FindLastSalesInvPostingDate(CustomerNo: Code[20]): Date
    var
        SalesInvHeader: Record "Sales Invoice Header";
    begin
        SalesInvHeader.SetRange("Sell-to Customer No.", CustomerNo);
        SalesInvHeader.FindLast();
        exit(SalesInvHeader."Posting Date");
    end;

    local procedure GetReminderLevel(var ReminderLevel: Record "Reminder Level"; ReminderTermsCode: Code[10]; Shift: Integer)
    begin
        ReminderLevel.SetRange("Reminder Terms Code", ReminderTermsCode);
        ReminderLevel.FindFirst();
        ReminderLevel.Next(Shift);
    end;

    local procedure GetCustomerReminderLevel(var GracePeriod: DateFormula; var DueDateCalc: DateFormula; CustomerNo: Code[20]; Shift: Integer)
    var
        Customer: Record Customer;
        ReminderLevel: Record "Reminder Level";
    begin
        Customer.Get(CustomerNo);
        GetReminderLevel(ReminderLevel, Customer."Reminder Terms Code", Shift);
        GracePeriod := ReminderLevel."Grace Period";
        DueDateCalc := ReminderLevel."Due Date Calculation"
    end;

    local procedure IssuingFinanceChargeMemos(FinanceChargeMemoHeaderNo: Code[20]) IssuedFinChargeNo: Code[20]
    var
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        NoSeries: Codeunit "No. Series";
    begin
        FinanceChargeMemoHeader.Get(FinanceChargeMemoHeaderNo);
        FinanceChargeMemoHeader.SetRecFilter();
        IssuedFinChargeNo := NoSeries.PeekNextNo(FinanceChargeMemoHeader."Issuing No. Series");
        LibraryERM.IssueFinanceChargeMemo(FinanceChargeMemoHeader);
    end;

    local procedure IssueReminder(ReminderNo: Code[20]; DocumentDate: Date) IssuedReminderNo: Code[20]
    var
        ReminderHeader: Record "Reminder Header";
        ReminderIssue: Codeunit "Reminder-Issue";
        NoSeries: Codeunit "No. Series";
    begin
        ReminderHeader.Get(ReminderNo);
        IssuedReminderNo := NoSeries.PeekNextNo(ReminderHeader."Issuing No. Series");
        ReminderIssue.Set(ReminderHeader, false, DocumentDate);
        LibraryERM.RunReminderIssue(ReminderIssue);
    end;

    local procedure SetSalesSetupCancelledIssuedRemindersNos(NewNos: Code[20])
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        SalesSetup.Validate("Canceled Issued Reminder Nos.", NewNos);
        SalesSetup.Modify();
    end;

    local procedure SetSalesSetupCancelledIssuedFinChargeMemosNos(NewNos: Code[20])
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        SalesSetup.Validate("Canc. Iss. Fin. Ch. Mem. Nos.", NewNos);
        SalesSetup.Modify();
    end;

    local procedure SuggestFinanceChargeMemoLines(FinanceChargeMemoHeader: Record "Finance Charge Memo Header")
    var
        SuggestFinChargeMemoLines: Report "Suggest Fin. Charge Memo Lines";
    begin
        FinanceChargeMemoHeader.SetRange("No.", FinanceChargeMemoHeader."No.");
        SuggestFinChargeMemoLines.SetTableView(FinanceChargeMemoHeader);
        SuggestFinChargeMemoLines.UseRequestPage(false);
        SuggestFinChargeMemoLines.Run();
    end;

    local procedure RunCancelIssuedReminder(IssuedReminderHeader: Record "Issued Reminder Header")
    begin
        IssuedReminderHeader.SetRecFilter();
        RunCancelIssuedReminderReportWithParameters(IssuedReminderHeader, true, true, 0D);
    end;

    local procedure RunCancelIssuedReminders(var IssuedReminderHeader: Record "Issued Reminder Header")
    begin
        RunCancelIssuedReminderReportWithParameters(IssuedReminderHeader, true, true, 0D);
    end;

    local procedure RunCancelIssuedReminderReportWithParameters(var IssuedReminderHeader: Record "Issued Reminder Header"; UseSameDocumentNo: Boolean; UseSamePostingDate: Boolean; NewPostingDate: Date)
    begin
        LibraryVariableStorage.Enqueue(UseSameDocumentNo);
        LibraryVariableStorage.Enqueue(UseSamePostingDate);
        LibraryVariableStorage.Enqueue(NewPostingDate);
        Commit();
        REPORT.RunModal(REPORT::"Cancel Issued Reminders", true, false, IssuedReminderHeader);
    end;

    local procedure RunCancelIssuedFinChargeMemo(IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header")
    begin
        IssuedFinChargeMemoHeader.SetRecFilter();
        RunCancelIssuedFinChargeMemoReportWithParameters(IssuedFinChargeMemoHeader, true, true, 0D);
    end;

    local procedure RunCancelIssuedFinChargeMemos(var IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header")
    begin
        RunCancelIssuedFinChargeMemoReportWithParameters(IssuedFinChargeMemoHeader, true, true, 0D);
    end;

    local procedure RunCancelIssuedFinChargeMemoReportWithParameters(var IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header"; UseSameDocumentNo: Boolean; UseSamePostingDate: Boolean; NewPostingDate: Date)
    begin
        LibraryVariableStorage.Enqueue(UseSameDocumentNo);
        LibraryVariableStorage.Enqueue(UseSamePostingDate);
        LibraryVariableStorage.Enqueue(NewPostingDate);
        Commit();
        REPORT.RunModal(REPORT::"Cancel Issued Fin.Charge Memos", true, false, IssuedFinChargeMemoHeader);
    end;

    local procedure VerifyDocumentEntries(RowCaption: Text[50]; RowValue: Variant; ColumnCaption: Text[50]; ColumnValue: Variant)
    begin
        LibraryReportDataset.SetRange(RowCaption, RowValue);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(ColumnCaption, ColumnValue);
    end;

    local procedure VerifyReminderLineCount(ReminderHeader: Record "Reminder Header"; ExpectedCount: Integer)
    var
        DummyReminderLine: Record "Reminder Line";
    begin
        DummyReminderLine.SetRange("Reminder No.", ReminderHeader."No.");
        Assert.RecordCount(DummyReminderLine, ExpectedCount);
    end;

    local procedure VerifyFinChargeMemoLineCount(FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; ExpectedCount: Integer)
    var
        DummyFinanceChargeMemoLine: Record "Finance Charge Memo Line";
    begin
        DummyFinanceChargeMemoLine.SetRange("Finance Charge Memo No.", FinanceChargeMemoHeader."No.");
        Assert.RecordCount(DummyFinanceChargeMemoLine, ExpectedCount);
    end;

    local procedure VerifyReminderLineDescription(ReminderLine: Record "Reminder Line"; ExpectedType: Enum "Reminder Line Type"; ExpectedNo: Code[20]; ExpectedDescription: Text)
    begin
        Assert.AreEqual(ExpectedType, ReminderLine.Type, ReminderLine.FieldCaption(Type));
        Assert.AreEqual(ExpectedNo, ReminderLine."No.", ReminderLine.FieldCaption("No."));
        Assert.AreEqual(ExpectedDescription, ReminderLine.Description, ReminderLine.FieldCaption(Description));
    end;

    local procedure VerifyFinChargeMemoLineDescription(FinanceChargeMemoLine: Record "Finance Charge Memo Line"; ExpectedType: Option; ExpectedNo: Code[20]; ExpectedDescription: Text)
    begin
        Assert.AreEqual(ExpectedType, FinanceChargeMemoLine.Type, FinanceChargeMemoLine.FieldCaption(Type));
        Assert.AreEqual(ExpectedNo, FinanceChargeMemoLine."No.", FinanceChargeMemoLine.FieldCaption("No."));
        Assert.AreEqual(ExpectedDescription, FinanceChargeMemoLine.Description, FinanceChargeMemoLine.FieldCaption(Description));
    end;

    local procedure VerifyRecreatedReminder(IssuedReminderHeader: Record "Issued Reminder Header"; NewReminderNo: Code[20])
    var
        ReminderHeader: Record "Reminder Header";
        ReminderLine: Record "Reminder Line";
        IssuedReminderLine: Record "Issued Reminder Line";
    begin
        ReminderHeader.Get(NewReminderNo);
        IssuedReminderLine.SetRange("Reminder No.", IssuedReminderHeader."No.");
        IssuedReminderLine.FindSet();
        ReminderLine.SetRange("Reminder No.", NewReminderNo);
        ReminderLine.FindSet();
        repeat
            ReminderLine.TestField(Type, IssuedReminderLine.Type);
            ReminderLine.TestField("No.", IssuedReminderLine."No.");
            ReminderLine.TestField("Document Type", IssuedReminderLine."Document Type");
            ReminderLine.TestField("Document No.", IssuedReminderLine."Document No.");
            ReminderLine.Next();
        until IssuedReminderLine.Next() = 0;
    end;

    local procedure VerifyReminderReversedGLEntries(IssuedReminderNo: Code[20])
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
    begin
        IssuedReminderHeader.Get(IssuedReminderNo);
        VerifyReversedGLEntriesExtended(IssuedReminderNo, IssuedReminderNo, IssuedReminderHeader."Posting Date");
    end;

    local procedure VerifyFinChanrgeMemoReversedGLEntries(IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header")
    begin
        VerifyReversedGLEntriesExtended(
          IssuedFinChargeMemoHeader."No.", IssuedFinChargeMemoHeader."No.", IssuedFinChargeMemoHeader."Posting Date");
    end;

    local procedure VerifyReversedGLEntriesExtended(DocumentNo: Code[20]; CancelledDocumentNo: Code[20]; CancelledDocumentPostingDate: Date)
    var
        SourceGLEntry: Record "G/L Entry";
        ReversedGLEntry: Record "G/L Entry";
        FirstTransactionNo: Integer;
        LastTransactionNo: Integer;
    begin
        FirstTransactionNo := GetFirstTransactionNo(DocumentNo);
        LastTransactionNo := GetLastTransactionNo(CancelledDocumentNo);
        Assert.IsTrue(FirstTransactionNo <> LastTransactionNo, 'Reversed G/L entries not found');
        SourceGLEntry.SetRange("Transaction No.", FirstTransactionNo);
        SourceGLEntry.FindSet();
        ReversedGLEntry.SetRange("Transaction No.", LastTransactionNo);
        ReversedGLEntry.FindSet();
        repeat
            ReversedGLEntry.TestField("Document No.", CancelledDocumentNo);
            ReversedGLEntry.TestField("Posting Date", CancelledDocumentPostingDate);
            ReversedGLEntry.TestField("G/L Account No.", SourceGLEntry."G/L Account No.");
            ReversedGLEntry.TestField(Amount, -SourceGLEntry.Amount);
            ReversedGLEntry.Next();
        until SourceGLEntry.Next() = 0;
    end;

    local procedure VerifyReversedVATEntries(DocumentNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.CalcSums(Amount, Base);
        VATEntry.TestField(Amount, 0);
        VATEntry.TestField(Base, 0);
    end;

    local procedure VerifyCanceledReminderCustLedgerEntries(DocumentNo: Code[20])
    var
        ReminderCustLedgerEntry: Record "Cust. Ledger Entry";
        CorrectiveCustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        ReminderCustLedgerEntry.SetRange("Document No.", DocumentNo);
        ReminderCustLedgerEntry.SetRange("Document Type", ReminderCustLedgerEntry."Document Type"::Reminder);
        ReminderCustLedgerEntry.FindFirst();
        ReminderCustLedgerEntry.TestField(Open, false);

        CorrectiveCustLedgerEntry.SetRange("Document No.", DocumentNo);
        CorrectiveCustLedgerEntry.SetRange("Document Type", CorrectiveCustLedgerEntry."Document Type"::" ");
        CorrectiveCustLedgerEntry.FindFirst();
        CorrectiveCustLedgerEntry.TestField(Open, false);
        CorrectiveCustLedgerEntry.TestField(Amount, -ReminderCustLedgerEntry.Amount);
    end;

    local procedure VerifyCanceledFinChargeMemoCustLedgerEntries(DocumentNo: Code[20])
    var
        InitialCustLedgerEntry: Record "Cust. Ledger Entry";
        CorrectiveCustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        InitialCustLedgerEntry.SetRange("Document No.", DocumentNo);
        InitialCustLedgerEntry.SetRange("Document Type", InitialCustLedgerEntry."Document Type"::"Finance Charge Memo");
        InitialCustLedgerEntry.FindFirst();
        InitialCustLedgerEntry.TestField(Open, false);

        CorrectiveCustLedgerEntry.SetRange("Document No.", DocumentNo);
        CorrectiveCustLedgerEntry.SetRange("Document Type", CorrectiveCustLedgerEntry."Document Type"::" ");
        CorrectiveCustLedgerEntry.FindFirst();
        CorrectiveCustLedgerEntry.TestField(Open, false);
        CorrectiveCustLedgerEntry.TestField(Amount, -InitialCustLedgerEntry.Amount);
    end;

    local procedure VerifyRecreatedFinChargeMemo(IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header"; FinanceChargeMemoHeader: Record "Finance Charge Memo Header")
    var
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
        IssuedFinChargeMemoLine: Record "Issued Fin. Charge Memo Line";
    begin
        IssuedFinChargeMemoLine.SetRange("Finance Charge Memo No.", IssuedFinChargeMemoHeader."No.");
        IssuedFinChargeMemoLine.FindSet();
        FinanceChargeMemoLine.SetRange("Finance Charge Memo No.", FinanceChargeMemoHeader."No.");
        FinanceChargeMemoLine.FindSet();
        repeat
            FinanceChargeMemoLine.TestField(Type, IssuedFinChargeMemoLine.Type);
            FinanceChargeMemoLine.TestField("No.", IssuedFinChargeMemoLine."No.");
            FinanceChargeMemoLine.TestField("Document Type", IssuedFinChargeMemoLine."Document Type");
            FinanceChargeMemoLine.TestField("Document No.", IssuedFinChargeMemoLine."Document No.");
            FinanceChargeMemoLine.Next();
        until IssuedFinChargeMemoLine.Next() = 0;
    end;

    local procedure CreateReminderTermsAndLevelWithCalculateInterest(var ReminderTerms: Record "Reminder Terms"; CalculateInterest: Boolean)
    var
        ReminderLevel: Record "Reminder Level";
    begin
        LibraryERM.CreateReminderTerms(ReminderTerms);

        LibraryERM.CreateReminderLevel(ReminderLevel, ReminderTerms.Code);
        ReminderLevel.Validate("Calculate Interest", CalculateInterest);
        ReminderLevel.Modify(true);
    end;

    local procedure CreateCustomerWithFinanceChargeTermsAndInterestRate(var Customer: Record Customer; ReminderTermsCode: Code[20])
    var
        FinanceChargeInterestRate: Record "Finance Charge Interest Rate";
        FinanceChargeTerms: Record "Finance Charge Terms";
    begin
        LibraryFinanceChargeMemo.CreateFinanceChargeTermAndText(FinanceChargeTerms);

        FinanceChargeInterestRate.Init();
        FinanceChargeInterestRate.Validate("Fin. Charge Terms Code", FinanceChargeTerms.Code);
        FinanceChargeInterestRate.Validate("Start Date", WorkDate() - LibraryRandom.RandInt(1000));
        FinanceChargeInterestRate.Validate("Interest Rate", LibraryRandom.RandInt(10));
        FinanceChargeInterestRate.Validate("Interest Period (Days)", LibraryRandom.RandInt(100));
        FinanceChargeInterestRate.Insert();

        CreateCustomer(Customer, FinanceChargeTerms.Code, '', ReminderTermsCode);
    end;

    local procedure CreateAndCancelIssuedReminder(CustomerNo: Code[20]; DocumentDate: Date; CancelDocumentCount: Integer)
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        i: Integer;
    begin
        for i := 1 to CancelDocumentCount do begin
            IssuedReminderHeader.Get(IssueReminder(CreateReminder(CustomerNo, DocumentDate), WorkDate()));
            RunCancelIssuedReminder(IssuedReminderHeader);
        end;
    end;

    local procedure VerifyAmountInGLEntries(IssuedReminderNo: Code[20])
    var
        GLEntry: array[2] of Record "G/L Entry";
    begin
        GLEntry[1].SetRange("Document No.", IssuedReminderNo);
        GLEntry[1].SetRange("Document Type", GLEntry[1]."Document Type"::Reminder);
        GLEntry[1].FindSet();
        repeat
            GLEntry[2].SetRange("Document No.", IssuedReminderNo);
            GLEntry[2].SetRange(Amount, -GLEntry[1].Amount);
            GLEntry[2].FindFirst();
            Assert.AreEqual(GLEntry[1].Amount, -GLEntry[2].Amount, IssuedReminderErr);
        until GLEntry[1].Next() = 0;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReminderRequestPageHandlerWithCalcCalls(var Reminder: TestRequestPage Reminder)
    begin
        LibraryVariableStorage.Enqueue(LibraryVariableStorage.DequeueInteger() + 1); // count of handler call's
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReminderRequestPageHandler(var Reminder: TestRequestPage Reminder)
    begin
        Reminder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure FinanceChargeMemoRequestPageHandler(var FinanceChargeMemo: TestRequestPage "Finance Charge Memo")
    begin
        FinanceChargeMemo.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text; var Reply: Boolean)
    begin
        LibraryVariableStorage.Enqueue(Question);
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DocumentEntriesRequestPageHandler(var DocumentEntries: TestRequestPage "Document Entries")
    var
        ShowAmountInLCY: Variant;
    begin
        LibraryVariableStorage.Dequeue(ShowAmountInLCY);  // Dequeue variable.
        DocumentEntries.PrintAmountsInLCY.SetValue(ShowAmountInLCY);   // Setting Show Amount In LCY.
        DocumentEntries.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure NavigatePagehandler(var Navigate: TestPage Navigate)
    begin
        Commit();  // Required to run the Document Entries report.
        Navigate.Print.Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure IssuedReminderPageHandler(var IssuedReminder: TestPage "Issued Reminder")
    begin
        LibraryVariableStorage.Enqueue(IssuedReminder."No.".Value);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure IssuedReminderListModalPageHandler(var IssuedReminderList: TestPage "Issued Reminder List")
    var
        IssuedReminders: Text;
    begin
        if IssuedReminderList.First() then
            repeat
                if IssuedReminders = '' then
                    IssuedReminders := IssuedReminderList."No.".Value
                else
                    IssuedReminders := IssuedReminders + '|' + IssuedReminderList."No.".Value();
            until not IssuedReminderList.Next();
        LibraryVariableStorage.Enqueue(IssuedReminders);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure IssuedFinChargeMemoListModalPageHandler(var IssuedFinChargeMemoList: TestPage "Issued Fin. Charge Memo List")
    var
        IssuedFinChargeMemos: Text;
    begin
        if IssuedFinChargeMemoList.First() then
            repeat
                if IssuedFinChargeMemos = '' then
                    IssuedFinChargeMemos := IssuedFinChargeMemoList."No.".Value
                else
                    IssuedFinChargeMemos := IssuedFinChargeMemos + '|' + IssuedFinChargeMemoList."No.".Value();
            until not IssuedFinChargeMemoList.Next();
        LibraryVariableStorage.Enqueue(IssuedFinChargeMemos);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BatchCancelIssuedRemindersRequestPageHandler(var BatchCancelIssuedReminders: TestRequestPage "Cancel Issued Reminders")
    var
        UseSameDocumentNo: Boolean;
        UseSamePostingDate: Boolean;
        NewPostingDate: Date;
    begin
        UseSameDocumentNo := LibraryVariableStorage.DequeueBoolean();
        UseSamePostingDate := LibraryVariableStorage.DequeueBoolean();
        NewPostingDate := LibraryVariableStorage.DequeueDate();
        BatchCancelIssuedReminders.UseSameDocumentNo.SetValue(UseSameDocumentNo);
        BatchCancelIssuedReminders.UseSamePostingDate.SetValue(UseSamePostingDate);
        if not UseSamePostingDate then
            BatchCancelIssuedReminders.NewPostingDate.SetValue(NewPostingDate);
        BatchCancelIssuedReminders.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BatchCancelIssuedFinChargeMemosRequestPageHandler(var CancelIssuedFinChargeMemos: TestRequestPage "Cancel Issued Fin.Charge Memos")
    var
        UseSameDocumentNo: Boolean;
        UseSamePostingDate: Boolean;
        NewPostingDate: Date;
    begin
        UseSameDocumentNo := LibraryVariableStorage.DequeueBoolean();
        UseSamePostingDate := LibraryVariableStorage.DequeueBoolean();
        NewPostingDate := LibraryVariableStorage.DequeueDate();
        CancelIssuedFinChargeMemos.UseSameDocumentNo.SetValue(UseSameDocumentNo);
        CancelIssuedFinChargeMemos.UseSamePostingDate.SetValue(UseSamePostingDate);
        if not UseSamePostingDate then
            CancelIssuedFinChargeMemos.NewPostingDate.SetValue(NewPostingDate);
        CancelIssuedFinChargeMemos.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CustomerLedgerEntriesPageHandler(var CustomerLedgerEntries: TestPage "Customer Ledger Entries")
    begin
        LibraryVariableStorage.Enqueue(CustomerLedgerEntries."Entry No.".Value);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure CannotCancelReminderNotificationHandler(var Notification: Notification): Boolean
    var
        CancelIssuedReminder: Codeunit "Cancel Issued Reminder";
    begin
        LibraryVariableStorage.Enqueue(Format(Notification.Message));
        CancelIssuedReminder.ShowIssuedReminder(Notification);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure AppliedCustomerLedgeEntryReminderNotificationHandler(var Notification: Notification): Boolean
    var
        CancelIssuedReminder: Codeunit "Cancel Issued Reminder";
    begin
        LibraryVariableStorage.Enqueue(Format(Notification.Message));
        CancelIssuedReminder.ShowCustomerLedgerEntry(Notification);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure AppliedCustomerLedgeEntryFinChargeMemoNotificationHandler(var Notification: Notification): Boolean
    var
        CancelIssuedFinChargeMemo: Codeunit "Cancel Issued Fin. Charge Memo";
    begin
        if Notification.Id = CancelIssuedFinChargeMemo.GetAppliedCustomerLedgerEntryNotificationId() then begin
            LibraryVariableStorage.Enqueue(Format(Notification.Message));
            CancelIssuedFinChargeMemo.ShowCustomerLedgerEntry(Notification);
        end;
    end;
}

