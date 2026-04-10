codeunit 134376 "ERM Reminders - Grace Period"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [ERM] [Reminder] [Reminder Grace Period]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        IsInitialized: Boolean;
        AmountErr: Label '%1 must be equal to %2 in %3.';
        RemainingAmount4Txt: Label 'Remaining Amount %4';
        RemainingAmount1Txt: Label 'Remaining Amount %1';
        OpenEntriesNotDueTxt: Label 'Open Entries Not Due';

    [Test]
    [Scope('OnPrem')]
    procedure ReminderNotOverdue()
    var
        Customer: Record Customer;
        PostedInvoiceNo: Code[20];
        ReminderNo: Code[20];
    begin
        // Check that no Reminder Lines exists for a Document that is not Overdue.

        // Setup.
        Initialize();
        PostedInvoiceNo := CreateAndPostSalesInvoice(Customer);

        // Exercise: Make payment for the Invoice and Create Reminder for the Customer.
        MakePaymentOfInvoice(Customer."No.", PostedInvoiceNo, WorkDate());
        ReminderNo :=
          CreateReminder(Customer."No.", CalculateReminderDate(Customer."Reminder Terms Code", PostedInvoiceNo, '<1D>'), false, true);

        // Verify: Verify that no Reminder Lines exists.
        VerifyNoReminderLines(ReminderNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReminderBeforeGracePeriod()
    begin
        // Check that No Reminder Lines exists for a Document that is created before Grace Period End.

        Initialize();
        FirstLevelReminderWithNoLines('<-1D>');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReminderOnGracePeriod()
    begin
        // Check that no Reminder Lines exists after Suggesting Lines on the Grace Period.

        Initialize();
        FirstLevelReminderWithNoLines('<0D>');
    end;

    local procedure FirstLevelReminderWithNoLines(Period: Text[10])
    var
        Customer: Record Customer;
        PostedInvoiceNo: Code[20];
        ReminderNo: Code[20];
    begin
        // Setup: Create and Post Sales Invoice.
        PostedInvoiceNo := CreateAndPostSalesInvoice(Customer);

        // Exercise: Create Reminder as per the option Selected.
        ReminderNo :=
          CreateReminder(Customer."No.", CalculateReminderDate(Customer."Reminder Terms Code", PostedInvoiceNo, Period), false, true);

        // Verify: Verify that no Reminder Lines exists.
        VerifyNoReminderLines(ReminderNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReminderAfterGracePeriod()
    var
        Customer: Record Customer;
        PostedInvoiceNo: Code[20];
    begin
        // Check the Amount and Additional Fee on Reminder Lines After the Grace Period End.

        // Setup.
        Initialize();
        PostedInvoiceNo := CreateAndPostSalesInvoice(Customer);

        // Create Reminder and Verify Additional Fee and Amount on Reminder Lines.
        CreateReminderAndVerifyLines(Customer, PostedInvoiceNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReminderNegativeAmount()
    var
        Customer: Record Customer;
        PostedInvoiceNo: Code[20];
    begin
        // Check the Amount and Additional Fee on Reminder Lines With a Negative Amount.

        // Setup: Create and Post Sales Invoice and then Create and Post Credit Memo.
        Initialize();
        PostedInvoiceNo := CreateAndPostSalesInvoice(Customer);
        CreateAndPostSalesCreditMemo(Customer."No.", Customer."Reminder Terms Code");

        // Create Reminder and Verify Additional Fee and Amount on Reminder Lines.
        CreateReminderAndVerifyLines(Customer, PostedInvoiceNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReminderOnFirstGracePeriod()
    var
        Customer: Record Customer;
        ReminderLevel: Record "Reminder Level";
        PostedInvoiceNo: Code[20];
        ReminderDate: Date;
    begin
        // Check that no Reminder Lines exists after Suggesting Lines on Second Reminder with First Level Grace Period.

        // Setup.
        Initialize();
        PostedInvoiceNo := CreateAndIssueFirstReminder(Customer, ReminderLevel);

        // Calculate Reminder Date based on Sales Header Due Date and First Grace Period End.
        ReminderDate := CalculateReminderDate(Customer."Reminder Terms Code", PostedInvoiceNo, '<0D>');
        CreateReminderAndVerifyNoLines(Customer."No.", ReminderDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReminderOnSecondGracePeriod()
    var
        Customer: Record Customer;
        ReminderLevel: Record "Reminder Level";
        PostedInvoiceNo: Code[20];
        ReminderDate: Date;
    begin
        // Check that no Reminder Lines exists after Suggesting Lines on Second Reminder with Second Level Grace Period.

        // Setup.
        Initialize();
        PostedInvoiceNo := CreateAndIssueFirstReminder(Customer, ReminderLevel);

        // Calculate Reminder Date based on Sales Header Due Date and First Grace Period End.
        ReminderLevel.Next();
        ReminderDate := CalcDate(ReminderLevel."Grace Period", GetSalesInvoiceDueDate(PostedInvoiceNo));
        CreateReminderAndVerifyNoLines(Customer."No.", ReminderDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReminderBothGracePeriod()
    var
        Customer: Record Customer;
        ReminderLevel: Record "Reminder Level";
        PostedInvoiceNo: Code[20];
        ReminderDate: Date;
        FirstGracePeriod: DateFormula;
    begin
        // Check that no Reminder Lines exists after Suggesting Lines on a Date after Both Level Grace Period ends.
        // SecondLevelReminder(NextLevelGracePeriod::"Both Periods");

        // Setup.
        Initialize();
        PostedInvoiceNo := CreateAndIssueFirstReminder(Customer, ReminderLevel);

        // Calculate Reminder Date based on Sales Header Due Date and First Grace Period End.
        FirstGracePeriod := ReminderLevel."Grace Period";
        ReminderLevel.Next();
        ReminderDate := CalcDate(FirstGracePeriod, CalcDate(ReminderLevel."Grace Period", GetSalesInvoiceDueDate(PostedInvoiceNo)));
        CreateReminderAndVerifyNoLines(Customer."No.", ReminderDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReminderOnFirstReminderDueDate()
    var
        Customer: Record Customer;
        ReminderLevel: Record "Reminder Level";
        PostedInvoiceNo: Code[20];
        ReminderDate: Date;
    begin
        // Check that no Reminder Lines exists after Suggesting Lines on a Date after First Level Grace Period and First Reminder Due Date.

        // Setup.
        Initialize();
        PostedInvoiceNo := CreateAndIssueFirstReminder(Customer, ReminderLevel);

        // Calculate Reminder Date based on Sales Header Due Date and First Grace Period End.
        ReminderLevel.Next();
        ReminderDate :=
          CalcDate(ReminderLevel."Grace Period", CalculateReminderDate(Customer."Reminder Terms Code", PostedInvoiceNo, '<1D>'));
        CreateReminderAndVerifyNoLines(Customer."No.", ReminderDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReminderOnDueDatSecGracePeriod()
    var
        Customer: Record Customer;
        ReminderLevel: Record "Reminder Level";
        PostedInvoiceNo: Code[20];
        ReminderDate2: Date;
    begin
        // Check that no Reminder Lines exists after Suggesting Lines on a Date after Second Level Grace Period and First Reminder Due Date.

        // Setup.
        Initialize();
        PostedInvoiceNo := CreateAndIssueFirstReminder(Customer, ReminderLevel);

        // Calculate Reminder Date based on Sales Header Due Date and First Grace Period End.
        ReminderLevel.Next();
        ReminderDate2 :=
          CalcDate(ReminderLevel."Grace Period", CalculateReminderDate(Customer."Reminder Terms Code", PostedInvoiceNo, '<1D>'));
        CreateReminderAndVerifyNoLines(Customer."No.", ReminderDate2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReminderAfterSecondGracePeriod()
    var
        Customer: Record Customer;
        ReminderLevel: Record "Reminder Level";
        PostedInvoiceNo: Code[20];
        ReminderNo: Code[20];
        ReminderDate: Date;
    begin
        // Check that no Reminder Lines exists after Suggesting Lines on a Date after Second Level Grace Period and First Reminder Due Date.

        // Setup.
        Initialize();
        PostedInvoiceNo := CreateAndIssueFirstReminder(Customer, ReminderLevel);

        // Calculate Reminder Date based on Sales Header Due Date and First Grace Period End.
        ReminderLevel.Next();
        ReminderDate :=
          CalcDate('<1D>',
            CalcDate(
              ReminderLevel."Grace Period",
              CalculateReminderDate(Customer."Reminder Terms Code", PostedInvoiceNo, '<1D>')));

        // Create Level Two Reminder as per the option selected.
        ReminderNo := CreateReminder(Customer."No.", ReminderDate, false, true);

        // Verify: Verify Amount and Additional Fee on Reminder Lines.
        VerifyAmountOnReminderLines(ReminderNo, PostedInvoiceNo);
        VerifyAddnlFeeOnReminderLines(ReminderNo, Customer."Reminder Terms Code", ReminderLevel."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReminderOnThirdGracePeriod()
    var
        ReminderNo: Code[20];
    begin
        // Check that no Reminder Lines exists after Suggesting Lines on Third Level Grace Period.

        // Setup:
        Initialize();
        CreateThirdLevelReminder(ReminderNo, '<0D>');

        // Verify:
        VerifyNoReminderLines(ReminderNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReminderAfterThirdGracePeriod()
    var
        PostedInvoiceNo: Code[20];
        ReminderNo: Code[20];
    begin
        // Check the Amount and Additional Fee on Reminder Lines after Third Level Grace Period Starts.

        // Setup:
        Initialize();
        PostedInvoiceNo := CreateThirdLevelReminder(ReminderNo, '<1D>');

        // Verify: Verify Amount and Additional Fee on Reminder Lines.
        VerifyAmountAndAddnlFeeOnLines(ReminderNo, PostedInvoiceNo);
    end;

    local procedure CreateThirdLevelReminder(var ReminderNo: Code[20]; Period: Text[30]) PostedInvoiceNo: Code[20]
    var
        Customer: Record Customer;
        ReminderLevel: Record "Reminder Level";
        ReminderDate: Date;
        ReminderDate2: Date;
        DateDifference: DateFormula;
    begin
        // Setup: Create and Post Sales Invoice. Create and Issue Level 1 Reminder.
        PostedInvoiceNo := CreateAndIssueFirstReminder(Customer, ReminderLevel);

        // Create Level Two Reminder and Issue it. Take Reminder Date just after Second Grace Period Ends.
        ReminderLevel.Next();
        ReminderDate :=
          CalcDate('<1D>', CalcDate(ReminderLevel."Grace Period",
              CalculateReminderDate(Customer."Reminder Terms Code", PostedInvoiceNo, '<1D>')));
        CreateAndIssueReminder(Customer."No.", ReminderDate, false);

        // Exercise: Create Level 3 Reminder.
        ReminderLevel.Next();
        Evaluate(DateDifference, Period);
        ReminderDate2 := CalcDate(DateDifference, CalcDate(ReminderLevel."Grace Period", ReminderDate));
        ReminderNo := CreateReminder(Customer."No.", ReminderDate2, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReminderOnGracePeriodDueDate()
    var
        Customer: Record Customer;
        ReminderLevel: Record "Reminder Level";
        PostedInvoiceNo: Code[20];
        ReminderNo: Code[20];
        ReminderDate: Date;
        ReminderDate2: Date;
    begin
        // Setup: Add Due Date Calculation on Reminder Levels.
        Initialize();
        PostedInvoiceNo := CreateAndPostSalesInvoice(Customer);
        AddDueDateCalcOnReminderLevel(Customer."Reminder Terms Code");

        // Exercise: Create Level One Reminder for the Customer and issue it. Use Reminder Date just after First Grace Period End.
        ReminderLevel.SetRange("Reminder Terms Code", Customer."Reminder Terms Code");
        ReminderLevel.FindSet();
        ReminderDate := CalculateReminderDate(Customer."Reminder Terms Code", PostedInvoiceNo, '<1D>');
        CreateAndIssueReminder(Customer."No.", ReminderDate, true);

        // Create Level Two Reminder for the Customer. Take Reminder Date Just After Second Grace Period End.
        ReminderLevel.Next();
        ReminderDate2 := CalcDate(ReminderLevel."Grace Period", CalcDate(ReminderLevel."Grace Period", ReminderDate));
        ReminderNo := CreateReminder(Customer."No.", ReminderDate2, true, true);

        // Verify: Verify the Due Date on Reminder Header according to the Reminder Level Due Date Calculation.
        VerifyDueDateOnReminderHeader(ReminderNo, ReminderLevel."Due Date Calculation");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReminderForMultipleInvoices()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        ReminderHeader: Record "Reminder Header";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        Counter: Integer;
        PostedInvoiceNo: Code[20];
        ReminderNo: Code[20];
    begin
        // Setup: Create a Customer. Create Multiple Sales Invoices with newly created Item and a Random Quantity. Post the Sales Invoices.
        Initialize();
        CreateCustomer(Customer);

        // Create Multiple Sales Invoices using Random and Post them.
        for Counter := 1 to 1 + LibraryRandom.RandInt(5) do begin
            CreateSalesInvoice(SalesHeader, Customer."No.", Customer."Reminder Terms Code");
            PostedInvoiceNo := NoSeriesBatch.GetNextNo(SalesHeader."Posting No. Series");
            LibrarySales.PostSalesDocument(SalesHeader, true, true);
        end;

        // Exercise: Create Level One Reminder for the Customer. Use Reminder Date just after First Grace Period End.
        ReminderNo :=
          CreateReminder(Customer."No.", CalculateReminderDate(Customer."Reminder Terms Code", PostedInvoiceNo, '<1D>'), false, true);

        // Verify: Verify Amount and Additional Fee on Reminder Lines.
        ReminderHeader.Get(ReminderNo);
        VerifyAmountMultiInvoiceLines(Customer."No.", ReminderNo);
        VerifyAddnlFeeOnReminderLines(ReminderNo, Customer."Reminder Terms Code", ReminderHeader."Reminder Level");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReminderLineCheck()
    var
        Customer: Record Customer;
        ReminderLevel: Record "Reminder Level";
        ReminderNo: Code[20];
        PostedInvoiceNo: Code[20];
    begin
        // Create and Verify the Reminder Lines.

        // Setup.
        Initialize();
        PostedInvoiceNo := CreateAndPostSalesInvoice(Customer);

        // Exercise: Create Reminder for the Customer and calculating Reminder Date using LibraryRandom.
        ReminderNo :=
          CreateReminder(
            Customer."No.",
            CalculateReminderDate(Customer."Reminder Terms Code", PostedInvoiceNo, '<' + Format(LibraryRandom.RandInt(5)) + 'D>'),
            false, true);

        // Verify: Check Whether Lines are created in Reminder Line and verify a field.
        ReminderLevel.SetRange("Reminder Terms Code", Customer."Reminder Terms Code");
        ReminderLevel.FindFirst();
        VerifyReminderLine(ReminderNo, ReminderLevel."Additional Fee (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReminderWithOverdueEntriesYes()
    var
        ReminderNo: Code[20];
    begin
        // [SCENARIO 243869] Check that no Overdue Entry exist while Suggesting Reminder Line and Entries With Overdue Amount Field is set to TRUE.

        // Create and suggest Reminder when Include Entries with Overdue Amount = TRUE.
        Initialize();
        ReminderNo := RemindersWithOverdueEntries(true);

        // Verify: Verify that the Invoice that is Not Due is not appearing in the Reminder Lines.
        Assert.IsFalse(VerifyOverdueEntry(ReminderNo), '<Not Due> Reminder Line must not exist.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReminderWithOverdueEntriesNo()
    var
        ReminderNo: Code[20];
    begin
        // [SCENARIO 243869] Check that not Overdue Entry exist while Suggesting Reminder Line and Entries With Overdue Amount Field is set to FALSE.

        // Create and suggest Reminder when Include Entries with Overdue Amount = FALSE.
        Initialize();
        ReminderNo := RemindersWithOverdueEntries(false);

        // Verify: Verify that the Invoice that is Not Due is also appearing in the Reminder Lines.
        Assert.IsFalse(VerifyOverdueEntry(ReminderNo), '<Not Due> Reminder Line must not exist.');
    end;

    local procedure RemindersWithOverdueEntries(OverDueEntriesOnly: Boolean) ReminderNo: Code[20]
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        ReminderDate: Date;
        PostedInvoiceNo: Code[20];
    begin
        // Setup: Create and Post Sales Invoice. Issue Reminder and again Post Sales Invoice for Customer. Take Random Reminder Due Date.
        PostedInvoiceNo := CreateAndPostSalesInvoice(Customer);
        ReminderDate :=
          CalculateReminderDate(Customer."Reminder Terms Code", PostedInvoiceNo, '<' + Format(LibraryRandom.RandInt(10)) + 'D>');
        CreateAndIssueReminder(Customer."No.", ReminderDate, false);
        CreateSalesInvoice(SalesHeader, Customer."No.", Customer."Reminder Terms Code");
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise: Create another Reminder for the same Customer.
        ReminderNo := CreateReminder(Customer."No.", ReminderDate, false, OverDueEntriesOnly);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReminderWithGracePeriodOverdue()
    var
        Customer: Record Customer;
        PostedInvoiceNo: Code[20];
        ReminderNo: Code[20];
    begin
        // [SCENARIO 375725] Reminder Line should not be created when Due Date plus Grace Period is more then Reminder Date and "Only Entries with Overdue Amounts" = TRUE

        Initialize();
        // [GIVEN] Customer with Reminder Code and Grace Period = 20 days
        CreateCustomer(Customer);

        // [GIVEN] Posted Sales Invoice "A" with Due Date = 01.01
        // This sales invoice needed to make sure that Reminder will be created
        CreateAndPostSalesInvoiceWithPostingDate(Customer."No.", WorkDate());

        // [GIVEN] Posted Sales Invoice "B" with Due Date = 01.02
        PostedInvoiceNo := CreateAndPostSalesInvoiceWithPostingDate(Customer."No.", CalcDate('<1M>', WorkDate()));

        // [WHEN] Create Reminder with Reminder Date = 19.02, "Only Entries with Overdue Amounts" = TRUE
        ReminderNo :=
          CreateReminder(Customer."No.", CalculateReminderDate(Customer."Reminder Terms Code", PostedInvoiceNo, '<-1D>'), true, true);

        // [THEN] Reminder Line for Posted Sales Invoice "B" was not added
        VerifyReminderLineDoesNotExist(ReminderNo, PostedInvoiceNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReminderWithGracePeriodNotDue()
    var
        Customer: Record Customer;
        ReminderTerms: Record "Reminder Terms";
        PostedInvoiceNo: Code[20];
        ReminderNo: Code[20];
    begin
        // [SCENARIO 379031] Reminder Line should be created when Due Date plus Grace Period is more then Reminder Date and "Only Entries with Overdue Amounts" = FALSE

        Initialize();
        // [GIVEN] Customer with Reminder Code and Grace Period = 20 days
        CreateCustomer(Customer);
        ReminderTerms.SetRange(Code, Customer."Reminder Terms Code");
        ReminderTerms.FindFirst();
        Assert.RecordIsNotEmpty(ReminderTerms);
        ReminderTerms.Validate("Minimum Amount (LCY)", 0);
        ReminderTerms.Modify(true);
        // [GIVEN] Posted Sales Invoice "A" with Due Date = 01.01
        // This sales invoice needed to make sure that Reminder will be created
        CreateAndPostSalesInvoiceWithPostingDate(Customer."No.", WorkDate());

        // [GIVEN] Posted Sales Invoice "B" with Due Date = 01.02
        PostedInvoiceNo := CreateAndPostSalesInvoiceWithPostingDate(Customer."No.", CalcDate('<1M>', WorkDate()));

        // [WHEN] Create Reminder with Reminder Date = 19.02, "Only Entries with Overdue Amounts" = FALSE
        ReminderNo :=
          CreateReminder(Customer."No.", CalculateReminderDate(Customer."Reminder Terms Code", PostedInvoiceNo, '<-1D>'), true, false);

        // [THEN] Reminder Line for Posted Sales Invoice "B" is added
        VerifyReminderLineExists(ReminderNo, PostedInvoiceNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReminderWithGracePeriodBoardDate()
    var
        Customer: Record Customer;
        ReminderLine: Record "Reminder Line";
        ReminderTerms: Record "Reminder Terms";
        PostedInvoiceNo: Code[20];
        ReminderNo: Code[20];
    begin
        // [SCENARIO 379271] Reminder Line should be created when Invoice Due Date is the Reminder Date and "Only Entries with Overdue Amounts" = FALSE
        Initialize();

        // [GIVEN] Customer with Reminder Code and Grace Period = 20 days and Payment Terms = 20 days
        CreateCustomerWithPaymentTerms(Customer);
        ReminderTerms.SetRange(Code, Customer."Reminder Terms Code");
        ReminderTerms.FindFirst();
        Assert.RecordIsNotEmpty(ReminderTerms);
        ReminderTerms.Validate("Minimum Amount (LCY)", 0);
        ReminderTerms.Modify(true);
        // [GIVEN] Posted Sales Invoice "A" with Due Date = 01.01
        CreateAndPostSalesInvoiceWithPostingDate(Customer."No.", WorkDate());
        // [GIVEN] Posted Sales Invoice "B" with Due Date = 20.02
        PostedInvoiceNo := CreateAndPostSalesInvoiceWithPostingDate(Customer."No.", CalcDate('<1M>', WorkDate()));

        // [WHEN] Create Reminder with Reminder Date = 20.02, "Only Entries with Overdue Amounts" = FALSE
        ReminderNo := CreateReminder(Customer."No.", GetSalesInvoiceDueDate(PostedInvoiceNo) + 1, true, false);

        // [THEN] Reminder Line for Posted Sales Invoice "B" is added to section "Not Due"
        FilterReminderLine(
          ReminderLine, ReminderNo, PostedInvoiceNo, ReminderLine."Line Type"::"Not Due", ReminderLine."Document Type"::Invoice);
        Assert.RecordIsNotEmpty(ReminderLine);
        // [THEN] Reminder Line for Posted Sales Invoice "B" is not added to section ReminderLine
        FilterReminderLine(
          ReminderLine, ReminderNo, PostedInvoiceNo, ReminderLine."Line Type"::"Reminder Line", ReminderLine."Document Type"::Invoice);
        Assert.RecordIsEmpty(ReminderLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReminderWithGRacePeriodPaymentOrRefund()
    var
        Customer: Record Customer;
        ReminderLine: Record "Reminder Line";
        ReminderTerms: Record "Reminder Terms";
        PaymentNo: Code[20];
        ReminderNo: Code[20];
        PostedInvoiceNo: Code[20];
    begin
        // [SCENARIO 379583] Reminder Line should be created when Due Date plus Grace Period and "Only Entries with Overdue Amounts" = TRUE with document type = Payment of Refund
        Initialize();

        // [GIVEN] Customer with Reminder Code and Grace Period = 20 days
        CreateCustomer(Customer);
        ReminderTerms.SetRange(Code, Customer."Reminder Terms Code");
        ReminderTerms.FindFirst();
        Assert.RecordIsNotEmpty(ReminderTerms);
        ReminderTerms.Validate("Minimum Amount (LCY)", 0);
        ReminderTerms.Modify(true);
        // [GIVEN] Posted Sales Invoice "A" with Due Date = 01.01
        // This sales invoice needed to make sure that Reminder will be created
        PostedInvoiceNo := CreateAndPostSalesInvoiceWithPostingDate(Customer."No.", WorkDate());
        // [GIVEN] Posted Payment "B" with Due Date = 01.02
        PaymentNo := MakePaymentOfInvoice(Customer."No.", PostedInvoiceNo, CalcDate('<1M>', WorkDate()));

        // [WHEN] Create Reminder with Reminder Date = 05.02, "Only Entries with Overdue Amounts" = TRUE
        ReminderNo := CreateReminder(Customer."No.", GetPaymentDueDate(PaymentNo) + 5, true, true);

        // [THEN] Reminder Line for Payment "B" is added to section "Not Due"
        FilterReminderLine(
          ReminderLine, ReminderNo, PaymentNo, ReminderLine."Line Type"::"Not Due", ReminderLine."Document Type"::Payment);
        Assert.RecordIsNotEmpty(ReminderLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TwoRemLinesWithDiffLevelAfterTwoIssuedReminders()
    var
        ReminderTerms: Record "Reminder Terms";
        CustomerNo: Code[20];
        ReminderNo: Code[20];
        InvoiceNo: array[2] of Code[20];
    begin
        // [FEATURE] [Reminder Level]
        // [SCENARIO 261120] Two reminder lines are suggested for two invoices with different reminder levels (level 1 for one invoice and level 3 for other)
        // [SCENARIO 261120] after two issued reminders
        Initialize();

        // [GIVEN] Reminder Terms with 3 Levels: 13D, 13D, 30D
        LibraryERM.CreateReminderTerms(ReminderTerms);
        CreateReminderLevel(ReminderTerms.Code, 13, 0);
        CreateReminderLevel(ReminderTerms.Code, 13, 0);
        CreateReminderLevel(ReminderTerms.Code, 30, 0);

        // [GIVEN] Customer with given Reminder Terms
        // [GIVEN] Posted sales invoice "I1" on "Posting Date" = 01-09-2020
        // [GIVEN] Posted sales invoice "I2" on "Posting Date" = 01-10-2020
        CustomerNo := CreateCustomerWithGivenReminderTerms(ReminderTerms.Code);
        InvoiceNo[1] := CreateAndPostSalesInvoiceWithPostingDate(CustomerNo, DMY2Date(1, 9, Date2DMY(WorkDate(), 3)));
        InvoiceNo[2] := CreateAndPostSalesInvoiceWithPostingDate(CustomerNo, DMY2Date(1, 10, Date2DMY(WorkDate(), 3)));

        // [GIVEN] Create and Issue reminder on "Posting Date" = 15-09-2020
        // [GIVEN] The reminder has a line for invoice "I1" with reminder level = 1
        CreateIssueReminderAndVerifyLevel(CustomerNo, DMY2Date(15, 9, Date2DMY(WorkDate(), 3)), InvoiceNo[1], 1);

        // [GIVEN] Create and Issue reminder on "Posting Date" = 30-09-2020
        // [GIVEN] The reminder has a line for invoice "I1" with reminder level = 2
        CreateIssueReminderAndVerifyLevel(CustomerNo, DMY2Date(30, 9, Date2DMY(WorkDate(), 3)), InvoiceNo[1], 2);

        // [WHEN] Create and suggest reminder on "Posting Date" = 15-11-2020
        ReminderNo := CreateReminder(CustomerNo, DMY2Date(15, 11, Date2DMY(WorkDate(), 3)), true, false);

        // [THEN] The reminder has a line for invoice "I1" with reminder level = 3 and a line for invoice "I2" with reminder level = 1
        VerifyReminderLineLevel(ReminderNo, InvoiceNo[1], 3);
        VerifyReminderLineLevel(ReminderNo, InvoiceNo[2], 1);
    end;

    [Test]
    procedure ReminderWhenOneInvoiceGraceExpiredOneInvoiceGraceNotExpired()
    var
        ReminderTerms: Record "Reminder Terms";
        ReminderLevel: Record "Reminder Level";
        ReminderLine: Record "Reminder Line";
        CustomerNo: Code[20];
        ReminderNo: Code[20];
        InvoiceNo: array[2] of Code[20];
        RemainingAmountValue: Text;
        AddFeePerLine: Decimal;
    begin
        // [SCENARIO 401910] Suggest reminder lines for two overdue invoices. Grace period expired for first and not expired for second. Fee per line and Ending Text with Remaining Amount are set.
        Initialize();

        // [GIVEN] Reminder Terms with one Level with Grace Period = 10D, Add. Fee per Line = 2, Ending Text = "Remaining Amount %4".
        LibraryERM.CreateReminderTerms(ReminderTerms);
        AddFeePerLine := LibraryRandom.RandDecInRange(2, 4, 2);
        CreateReminderLevelWithText(ReminderTerms.Code, 10, 0, AddFeePerLine, RemainingAmount4Txt);

        // [GIVEN] Reminder Levels have a description text.
        ReminderLevel.SetRange("Reminder Terms Code", ReminderTerms.Code);
        if not ReminderLevel.IsEmpty() then begin
            ReminderLevel.FindSet();
            repeat
                ReminderLevel."Add. Fee per Line Description" := ReminderTerms.Code;
                ReminderLevel.Modify(true);
            until ReminderLevel.Next() = 0;
        end;

        // [GIVEN] Customer with given Reminder Terms.
        // [GIVEN] Posted Sales Invoice "I1" with "Due Date" = 01-09-2021 and Amount = "A1". Grace Period expires after 11-09-2021.
        // [GIVEN] Posted Sales Invoice "I2" with "Due Date" = 01-10-2021. Grace Period expires after 11-10-2021.
        CustomerNo := CreateCustomerWithGivenReminderTerms(ReminderTerms.Code);
        InvoiceNo[1] := CreateAndPostSalesInvoiceWithPostingDate(CustomerNo, DMY2Date(1, 9, Date2DMY(WorkDate(), 3)));
        InvoiceNo[2] := CreateAndPostSalesInvoiceWithPostingDate(CustomerNo, DMY2Date(1, 10, Date2DMY(WorkDate(), 3)));

        // [WHEN] Create reminder with Document Date = 11-10-2021 and suggest reminder lines.
        ReminderNo := CreateReminder(CustomerNo, DMY2Date(11, 10, Date2DMY(WorkDate(), 3)), true, false);

        // [THEN] One reminder line with Type "Reminder Line" was created. Document No. = "I1".
        VerifyReminderLinesCount(ReminderLine, ReminderNo, ReminderLine."Line Type"::"Reminder Line", 1);
        ReminderLine.FindFirst();
        VerifyReminderLineDocument(ReminderLine, ReminderLine."Document Type"::Invoice, InvoiceNo[1]);

        // [THEN] One reminder line with Type "Line Fee" was created. Applies-to Document No. = "I1", Amount = 2.
        VerifyReminderLinesCount(ReminderLine, ReminderNo, ReminderLine."Line Type"::"Line Fee", 1);
        ReminderLine.FindFirst();
        VerifyReminderLineAppliesToDoc(ReminderLine, ReminderLine."Document Type"::Invoice, InvoiceNo[1], AddFeePerLine);

        // [THEN] One reminder line with Type "Ending Text" was created. Description = "Remaining Amount A1".
        VerifyReminderLinesCount(ReminderLine, ReminderNo, ReminderLine."Line Type"::"Ending Text", 1);
        ReminderLine.FindFirst();
        RemainingAmountValue := Format(GetSalesInvoiceRemainingAmount(InvoiceNo[1]), 0, '<Precision,2:2><Standard Format,0>');
        ReminderLine.TestField(Description, StrSubstNo(RemainingAmount1Txt, RemainingAmountValue));

        // [THEN] Two reminder lines with Type "Not Due" was created. First with Description "Open Entries Not Due", second is for Document No. = "I2".
        VerifyReminderLinesCount(ReminderLine, ReminderNo, ReminderLine."Line Type"::"Not Due", 2);
        ReminderLine.FindFirst();
        ReminderLine.TestField(Description, OpenEntriesNotDueTxt);
        ReminderLine.FindLast();
        VerifyReminderLineDocument(ReminderLine, ReminderLine."Document Type"::Invoice, InvoiceNo[2]);
    end;

    [Test]
    procedure ReminderWhenTwoInvoicesGraceExpired()
    var
        ReminderTerms: Record "Reminder Terms";
        ReminderLevel: Record "Reminder Level";
        ReminderLine: Record "Reminder Line";
        CustomerNo: Code[20];
        ReminderNo: Code[20];
        InvoiceNo: array[2] of Code[20];
        TotalRemainingAmountValue: Text;
        AddFeePerLine: Decimal;
    begin
        // [SCENARIO 401910] Suggest reminder lines for two overdue invoices. Grace period expired for both. Fee per line and Ending Text with Remaining Amount are set.
        Initialize();

        // [GIVEN] Reminder Terms with one Level with Grace Period = 10D, Add. Fee per Line = 2, Ending Text = "Remaining Amount %4".
        LibraryERM.CreateReminderTerms(ReminderTerms);
        AddFeePerLine := LibraryRandom.RandDecInRange(2, 4, 2);
        CreateReminderLevelWithText(ReminderTerms.Code, 10, 0, AddFeePerLine, RemainingAmount4Txt);

        // [GIVEN] Reminder Levels have a description text.
        ReminderLevel.SetRange("Reminder Terms Code", ReminderTerms.Code);
        if not ReminderLevel.IsEmpty() then begin
            ReminderLevel.FindSet();
            repeat
                ReminderLevel."Add. Fee per Line Description" := ReminderTerms.Code;
                ReminderLevel.Modify(true);
            until ReminderLevel.Next() = 0;
        end;

        // [GIVEN] Customer with given Reminder Terms.
        // [GIVEN] Posted Sales Invoice "I1" with "Due Date" = 01-09-2021 and Amount = "A1". Grace Period expires after 11-09-2021.
        // [GIVEN] Posted Sales Invoice "I2" with "Due Date" = 01-10-2021 and Amount = "A2". Grace Period expires after 11-10-2021.
        CustomerNo := CreateCustomerWithGivenReminderTerms(ReminderTerms.Code);
        InvoiceNo[1] := CreateAndPostSalesInvoiceWithPostingDate(CustomerNo, DMY2Date(1, 9, Date2DMY(WorkDate(), 3)));
        InvoiceNo[2] := CreateAndPostSalesInvoiceWithPostingDate(CustomerNo, DMY2Date(1, 10, Date2DMY(WorkDate(), 3)));

        // [WHEN] Create reminder with Document Date = 12-10-2021 and suggest reminder lines.
        ReminderNo := CreateReminder(CustomerNo, DMY2Date(12, 10, Date2DMY(WorkDate(), 3)), true, false);

        // [THEN] Two reminder lines with Type "Reminder Line" was created. Document No. = "I1" / "I2".
        VerifyReminderLinesCount(ReminderLine, ReminderNo, ReminderLine."Line Type"::"Reminder Line", 2);
        ReminderLine.FindFirst();
        VerifyReminderLineDocument(ReminderLine, ReminderLine."Document Type"::Invoice, InvoiceNo[1]);
        ReminderLine.FindLast();
        VerifyReminderLineDocument(ReminderLine, ReminderLine."Document Type"::Invoice, InvoiceNo[2]);

        // [THEN] Two reminder lines with Type "Line Fee" was created. Applies-to Document No. = "I1" / "I2", Amount = 2.
        VerifyReminderLinesCount(ReminderLine, ReminderNo, ReminderLine."Line Type"::"Line Fee", 2);
        ReminderLine.FindFirst();
        VerifyReminderLineAppliesToDoc(ReminderLine, ReminderLine."Document Type"::Invoice, InvoiceNo[1], AddFeePerLine);
        ReminderLine.FindLast();
        VerifyReminderLineAppliesToDoc(ReminderLine, ReminderLine."Document Type"::Invoice, InvoiceNo[2], AddFeePerLine);

        // [THEN] One reminder line with Type "Ending Text" was created. Description = "Remaining Amount <A1 + A2>".
        VerifyReminderLinesCount(ReminderLine, ReminderNo, ReminderLine."Line Type"::"Ending Text", 1);
        ReminderLine.FindFirst();
        TotalRemainingAmountValue := Format(GetSalesInvoiceRemainingAmount(InvoiceNo[1]) + GetSalesInvoiceRemainingAmount(InvoiceNo[2]), 0, '<Precision,2:2><Standard Format,0>');
        ReminderLine.TestField(Description, StrSubstNo(RemainingAmount1Txt, TotalRemainingAmountValue));
    end;

    local procedure Initialize()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        FeatureKey: Record "Feature Key";
        FeatureKeyUpdateStatus: Record "Feature Data Update Status";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Reminders - Grace Period");
        if FeatureKey.Get('ReminderTermsCommunicationTexts') then begin
            FeatureKey.Enabled := FeatureKey.Enabled::None;
            FeatureKey.Modify();
        end;
        if FeatureKeyUpdateStatus.Get('ReminderTermsCommunicationTexts', CompanyName()) then begin
            FeatureKeyUpdateStatus."Feature Status" := FeatureKeyUpdateStatus."Feature Status"::Disabled;
            FeatureKeyUpdateStatus.Modify();
        end;
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Reminders - Grace Period");

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Link Doc. Date To Posting Date", true);
        PurchasesPayablesSetup.Modify();
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Link Doc. Date To Posting Date", true);
        SalesReceivablesSetup.Modify();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Reminders - Grace Period");
    end;

    local procedure AddDueDateCalcOnReminderLevel(ReminderTermsCode: Code[10])
    var
        ReminderLevel: Record "Reminder Level";
    begin
        // Update Random Due Date Calculation on First Grace Period of Reminder Level.
        ReminderLevel.SetRange("Reminder Terms Code", ReminderTermsCode);
        ReminderLevel.FindSet();
        repeat
            Evaluate(ReminderLevel."Due Date Calculation", '<' + Format(LibraryRandom.RandInt(5)) + 'D>');
        until ReminderLevel.Next() = 0;
    end;

    local procedure CalculateReminderDate(ReminderTermsCode: Code[10]; PostedInvoiceNo: Code[20]; Period: Text[10]) ReminderDate: Date
    var
        ReminderLevel: Record "Reminder Level";
        DateDifference: DateFormula;
    begin
        ReminderLevel.SetRange("Reminder Terms Code", ReminderTermsCode);
        ReminderLevel.FindFirst();
        Evaluate(DateDifference, Period);
        ReminderDate := CalcDate(DateDifference, CalcDate(ReminderLevel."Grace Period", GetSalesInvoiceDueDate(PostedInvoiceNo)));
    end;

    local procedure CreateAndIssueFirstReminder(var Customer: Record Customer; var ReminderLevel: Record "Reminder Level") PostedInvoiceNo: Code[20]
    var
        ReminderDate: Date;
    begin
        // Setup: Create and Post Sales Invoice. Create Level 1 Reminder and Issue it.
        PostedInvoiceNo := CreateAndPostSalesInvoice(Customer);

        // Find Reminder Level, Create Level 1 and Level 2 Reminders for Customer and Issue them.
        ReminderLevel.SetRange("Reminder Terms Code", Customer."Reminder Terms Code");
        ReminderLevel.FindSet();
        ReminderDate := CalculateReminderDate(Customer."Reminder Terms Code", PostedInvoiceNo, '<1D>');
        CreateAndIssueReminder(Customer."No.", ReminderDate, false);
    end;

    local procedure CreateAndIssueReminder(CustomerNo: Code[20]; ReminderDate: Date; GracePeriodDueDate: Boolean)
    var
        ReminderNo: Code[20];
    begin
        ReminderNo := CreateReminder(CustomerNo, ReminderDate, GracePeriodDueDate, true);
        IssueReminder(ReminderNo, ReminderDate);
    end;

    local procedure CreateIssueReminderAndVerifyLevel(CustomerNo: Code[20]; ReminderDate: Date; InvoiceNo: Code[20]; ExpectedLevel: Integer)
    var
        ReminderNo: Code[20];
    begin
        ReminderNo := CreateReminder(CustomerNo, ReminderDate, true, true);
        VerifyReminderLineLevel(ReminderNo, InvoiceNo, ExpectedLevel);
        IssueReminder(ReminderNo, ReminderDate);
    end;

    local procedure CreateAndPostSalesCreditMemo(CustomerNo: Code[20]; ReminderTermsCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesCreditMemo(SalesHeader, CustomerNo, ReminderTermsCode);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateAndPostSalesInvoice(var Customer: Record Customer) PostedInvoiceNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateCustomer(Customer);
        CreateSalesInvoice(SalesHeader, Customer."No.", Customer."Reminder Terms Code");
        PostedInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateAndPostSalesInvoiceWithPostingDate(CustNo: Code[20]; PostingDate: Date): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustNo);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateCustomer(var Customer: Record Customer)
    begin
        // Create a New Customer and update Reminder Terms.
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Reminder Terms Code", CreateReminderTerms());
        Customer.Modify(true);
    end;

    local procedure CreateCustomerWithPaymentTerms(var Customer: Record Customer)
    var
        PaymentTerms: Record "Payment Terms";
    begin
        CreateCustomer(Customer);
        LibraryERM.FindPaymentTerms(PaymentTerms);
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Modify(true);
    end;

    local procedure CreateCustomerWithGivenReminderTerms(ReminderTermsCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        LibrarySales.CreateCustomer(Customer);
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        CustomerPostingGroup.Validate("Add. Fee per Line Account", CustomerPostingGroup."Additional Fee Account");
        CustomerPostingGroup.Modify(true);
        Customer.Validate("Reminder Terms Code", ReminderTermsCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; CustomerNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Create General Journal Lines to Make Payment for the Customer.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, CustomerNo, -Amount);
    end;

    local procedure CreateReminder(CustomerNo: Code[20]; ReminderDate: Date; GracePeriodDueDate: Boolean; OverdueEntriesOnly: Boolean) ReminderNo: Code[20]
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ReminderHeader: Record "Reminder Header";
        CustLedgEntryLineFeeOn: Record "Cust. Ledger Entry";
        ReminderMake: Codeunit "Reminder-Make";
    begin
        // Create Reminder Header with Document Date.
        CreateReminderHeader(ReminderHeader, GracePeriodDueDate, CustomerNo, ReminderDate);

        // Suggest Reminder Lines with Options: Overdue Entries Only,Include Entries On Hold.
        ReminderMake.SuggestLines(ReminderHeader, CustLedgerEntry, OverdueEntriesOnly, false, CustLedgEntryLineFeeOn);
        ReminderMake.Code();
        ReminderNo := ReminderHeader."No.";
    end;

    local procedure CreateReminderAndVerifyLines(Customer: Record Customer; PostedInvoiceNo: Code[20])
    var
        ReminderNo: Code[20];
    begin
        // Exercise: Create Reminder after First Grace Period.
        ReminderNo :=
          CreateReminder(Customer."No.", CalculateReminderDate(Customer."Reminder Terms Code", PostedInvoiceNo, '<1D>'), false, true);

        // Verify: Verify Amount and Additional Fee on Reminder Lines.
        VerifyAmountAndAddnlFeeOnLines(ReminderNo, PostedInvoiceNo);
    end;

    local procedure CreateReminderAndVerifyNoLines(CustomerNo: Code[20]; ReminderDate: Date)
    var
        ReminderNo: Code[20];
    begin
        // Create Level Two Reminder as per the option selected
        ReminderNo := CreateReminder(CustomerNo, ReminderDate, false, true);

        // Verify: Verify thay no Reminder Lines exists.
        VerifyNoReminderLines(ReminderNo);
    end;

    local procedure CreateReminderHeader(var ReminderHeader: Record "Reminder Header"; GracePeriodDueDate: Boolean; CustomerNo: Code[20]; DocumentDate: Date)
    begin
        LibraryERM.CreateReminderHeader(ReminderHeader);
        ReminderHeader.Validate("Customer No.", CustomerNo);
        ReminderHeader.Validate("Document Date", DocumentDate);
        if not GracePeriodDueDate then
            ReminderHeader.Validate("Due Date", ReminderHeader."Document Date");
        ReminderHeader.Modify(true);
    end;

    local procedure CreateReminderLevel(ReminderTermsCode: Code[10]; GracePeriod: Integer; AdditionalFee: Decimal)
    var
        ReminderLevel: Record "Reminder Level";
    begin
        // Create Reminder Level with a Random Grace Period and a Random Additional Fee.
        LibraryERM.CreateReminderLevel(ReminderLevel, ReminderTermsCode);
        Evaluate(ReminderLevel."Grace Period", '<' + Format(GracePeriod) + 'D>');
        ReminderLevel.Validate("Additional Fee (LCY)", AdditionalFee);
        ReminderLevel.Modify(true);
    end;

    local procedure CreateReminderLevelWithText(ReminderTermsCode: Code[10]; GracePeriod: Integer; AdditionalFee: Decimal; AddFeePerLine: Decimal; ReminderEndingText: Text[100])
    var
        ReminderLevel: Record "Reminder Level";
        ReminderText: Record "Reminder Text";
    begin
        LibraryERM.CreateReminderLevel(ReminderLevel, ReminderTermsCode);
        Evaluate(ReminderLevel."Grace Period", '<' + Format(GracePeriod) + 'D>');
        ReminderLevel.Validate("Additional Fee (LCY)", AdditionalFee);
        ReminderLevel.Validate("Add. Fee per Line Amount (LCY)", AddFeePerLine);
        ReminderLevel.Modify(true);

        LibraryERM.CreateReminderText(ReminderText, ReminderTermsCode, ReminderLevel."No.", ReminderText.Position::Ending, ReminderEndingText);
    end;

    local procedure CreateReminderTerms(): Code[10]
    var
        ReminderTerms: Record "Reminder Terms";
        Counter: Integer;
        GracePeriod: Integer;
        AdditionalFee: Decimal;
    begin
        // Create a new Reminder Term and take Random Minimum Amount Greater than 10.
        LibraryERM.CreateReminderTerms(ReminderTerms);
        ReminderTerms.Validate("Minimum Amount (LCY)", 10 * LibraryRandom.RandDec(10, 2));
        ReminderTerms.Modify(true);

        // Create Levels for Reminder Term, Create Random Reminder Levels. Minimum 3 Levels are required. Take a Random Grace Period,
        // Additional Fee. Make sure that the next Reminder Level has a greater Grace Period and Additional Fee than Earlier one.
        GracePeriod := 5 * LibraryRandom.RandInt(5);
        AdditionalFee := 10 * LibraryRandom.RandInt(10);
        for Counter := 1 to 2 + LibraryRandom.RandInt(5) do begin
            CreateReminderLevel(ReminderTerms.Code, GracePeriod, AdditionalFee);
            GracePeriod := GracePeriod + LibraryRandom.RandInt(5);
            AdditionalFee += AdditionalFee;
        end;
        exit(ReminderTerms.Code);
    end;

    local procedure CreateSalesCreditMemo(var SalesHeader: Record "Sales Header"; SellToCustomerNo: Code[20]; ReminderTermsCode: Code[10])
    var
        SalesLine: Record "Sales Line";
        ReminderTerms: Record "Reminder Terms";
    begin
        // Create a Sales Header.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", SellToCustomerNo);

        // Create Sales Line with Random Quantity. Update Unit Price and Quantity to Ship on Sales Line.
        ReminderTerms.Get(ReminderTermsCode);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader,
          SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", ReminderTerms."Minimum Amount (LCY)");
        SalesLine.Validate("Qty. to Ship", 0);  // Qty to Ship must be zero in Sales Credit Memo.
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesInvoice(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; ReminderTermsCode: Code[10])
    var
        SalesLine: Record "Sales Line";
        ReminderTerms: Record "Reminder Terms";
        Counter: Integer;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);

        // Create Multiple Sales Lines with Random Quantity and Unit Price. Take Unit Price greater than Reminder Terms Minimum Amount.
        ReminderTerms.Get(ReminderTermsCode);
        for Counter := 1 to 1 + LibraryRandom.RandInt(5) do begin
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader,
              SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(10, 2));
            SalesLine.Validate("Unit Price", 10 + LibraryRandom.RandDec(10, 2) * ReminderTerms."Minimum Amount (LCY)");
            SalesLine.Modify(true);
        end;
    end;

    local procedure GetSalesInvoiceDueDate(No: Code[20]): Date
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(No);
        exit(SalesInvoiceHeader."Due Date");
    end;

    local procedure GetSalesInvoiceRemainingAmount(DocumentNo: Code[20]): Decimal
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(DocumentNo);
        SalesInvoiceHeader.CalcFields("Remaining Amount");
        exit(SalesInvoiceHeader."Remaining Amount");
    end;

    local procedure GetPaymentDueDate(PaymentNo: Code[20]): Date
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, PaymentNo);
        exit(CustLedgerEntry."Due Date");
    end;

    local procedure IssueReminder(ReminderNo: Code[20]; ReminderDate: Date)
    var
        ReminderHeader: Record "Reminder Header";
        ReminderIssue: Codeunit "Reminder-Issue";
    begin
        ReminderHeader.Get(ReminderNo);
        ReminderIssue.Set(ReminderHeader, false, ReminderDate);
        LibraryERM.RunReminderIssue(ReminderIssue);
    end;

    local procedure MakePaymentOfInvoice(CustomerNo: Code[20]; DocumentNo: Code[20]; PostingDate: Date): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields(Amount);
        CreateGeneralJournalLine(GenJournalLine, CustomerNo, CustLedgerEntry.Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure FilterReminderLine(var ReminderLine: Record "Reminder Line"; ReminderNo: Code[20]; DocumentNo: Code[20]; LineType: Enum "Reminder Line Type"; DocumentType: Enum "Gen. Journal Document Type")
    begin
        ReminderLine.SetRange("Reminder No.", ReminderNo);
        ReminderLine.SetRange("Line Type", LineType);
        ReminderLine.SetRange(Type, ReminderLine.Type::"Customer Ledger Entry");
        ReminderLine.SetRange("Document Type", DocumentType);
        ReminderLine.SetRange("Document No.", DocumentNo);
    end;

    local procedure VerifyAddnlFeeOnReminderLines(ReminderNo: Code[20]; ReminderTermsCode: Code[10]; ReminderLevelNo: Integer)
    var
        ReminderLine: Record "Reminder Line";
        ReminderLevel: Record "Reminder Level";
    begin
        ReminderLevel.Get(ReminderTermsCode, ReminderLevelNo);
        ReminderLine.SetRange("Reminder No.", ReminderNo);
        ReminderLine.SetRange("Line Type", ReminderLine."Line Type"::"Additional Fee");
        ReminderLine.SetFilter(Type, '<>''''');
        ReminderLine.FindFirst();
        Assert.AreEqual(
          ReminderLevel."Additional Fee (LCY)", ReminderLine.Amount,
          StrSubstNo(AmountErr, ReminderLine.FieldCaption(Amount), ReminderLevel."Additional Fee (LCY)",
            ReminderLine.TableCaption()));
    end;

    local procedure VerifyAmountAndAddnlFeeOnLines(ReminderNo: Code[20]; PostedDocumentNo: Code[20])
    var
        ReminderHeader: Record "Reminder Header";
    begin
        ReminderHeader.Get(ReminderNo);
        VerifyAmountOnReminderLines(ReminderHeader."No.", PostedDocumentNo);
        VerifyAddnlFeeOnReminderLines(ReminderHeader."No.", ReminderHeader."Reminder Terms Code", ReminderHeader."Reminder Level");
    end;

    local procedure VerifyAmountMultiInvoiceLines(CustomerNo: Code[20]; ReminderNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ReminderLine: Record "Reminder Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        ReminderLine.SetRange("Reminder No.", ReminderNo);
        ReminderLine.SetRange("Line Type", ReminderLine."Line Type"::"Reminder Line");
        ReminderLine.SetRange("Document Type", ReminderLine."Document Type"::Invoice);
        ReminderLine.SetRange(Type, ReminderLine.Type::"Customer Ledger Entry");
        ReminderLine.FindSet();

        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.FindSet();
        repeat
            CustLedgerEntry.CalcFields("Original Amount");
            Assert.AreNearlyEqual(
              CustLedgerEntry."Original Amount", ReminderLine."Original Amount", GeneralLedgerSetup."Inv. Rounding Precision (LCY)",
              StrSubstNo(AmountErr, ReminderLine.FieldCaption("Original Amount"), CustLedgerEntry."Original Amount",
                ReminderLine.TableCaption()));
            ReminderLine.Next();
        until CustLedgerEntry.Next() = 0;
    end;

    local procedure VerifyAmountOnReminderLines(ReminderNo: Code[20]; DocumentNo: Code[20])
    var
        ReminderLine: Record "Reminder Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        ReminderLine.SetRange("Reminder No.", ReminderNo);
        ReminderLine.SetRange("Line Type", ReminderLine."Line Type"::"Reminder Line");
        ReminderLine.SetRange("Document Type", ReminderLine."Document Type"::Invoice);
        ReminderLine.FindFirst();
        SalesInvoiceHeader.Get(DocumentNo);
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        Assert.AreNearlyEqual(
          SalesInvoiceHeader."Amount Including VAT", ReminderLine."Original Amount", LibraryERM.GetInvoiceRoundingPrecisionLCY(),
          StrSubstNo(AmountErr, ReminderLine.FieldCaption("Original Amount"),
            SalesInvoiceHeader."Amount Including VAT", ReminderLine.TableCaption()));
    end;

    local procedure VerifyDueDateOnReminderHeader(ReminderHeaderNo: Code[20]; DueDateCalculation: DateFormula)
    var
        ReminderHeader: Record "Reminder Header";
        DueDate: Date;
    begin
        ReminderHeader.Get(ReminderHeaderNo);
        DueDate := CalcDate(DueDateCalculation, ReminderHeader."Document Date");
        Assert.AreEqual(
          DueDate, ReminderHeader."Due Date", 'Due Date must be calculated according to Reminder Level Due Date Calculation.');
    end;

    local procedure VerifyNoReminderLines(ReminderNo: Code[20])
    var
        ReminderLine: Record "Reminder Line";
    begin
        ReminderLine.SetRange("Reminder No.", ReminderNo);
        Assert.IsTrue(ReminderLine.IsEmpty, 'Reminder Lines must not exist.');
    end;

    local procedure VerifyOverdueEntry(ReminderNo: Code[20]): Boolean
    var
        ReminderLine: Record "Reminder Line";
    begin
        ReminderLine.SetRange("Reminder No.", ReminderNo);
        ReminderLine.SetRange(Type, ReminderLine.Type::"Customer Ledger Entry");
        ReminderLine.SetRange("Line Type", ReminderLine."Line Type"::"Not Due");
        exit(ReminderLine.FindFirst())
    end;

    local procedure VerifyReminderLine(ReminderNo: Code[20]; Amount: Decimal)
    var
        ReminderLine: Record "Reminder Line";
    begin
        ReminderLine.SetRange("Reminder No.", ReminderNo);
        ReminderLine.SetRange(Type, ReminderLine.Type::"G/L Account");
        ReminderLine.FindFirst();
        ReminderLine.TestField(Amount, Amount);
    end;

    local procedure VerifyReminderLineDoesNotExist(ReminderNo: Code[20]; PostedInvoiceNo: Code[20])
    var
        ReminderLine: Record "Reminder Line";
    begin
        FilterReminderLine(
          ReminderLine, ReminderNo, PostedInvoiceNo, ReminderLine."Line Type"::"Reminder Line", ReminderLine."Document Type"::Invoice);
        Assert.RecordIsEmpty(ReminderLine);
    end;

    local procedure VerifyReminderLineExists(ReminderNo: Code[20]; PostedInvoiceNo: Code[20])
    var
        ReminderLine: Record "Reminder Line";
    begin
        FilterReminderLine(
          ReminderLine, ReminderNo, PostedInvoiceNo, ReminderLine."Line Type"::"Not Due", ReminderLine."Document Type"::Invoice);
        Assert.RecordIsNotEmpty(ReminderLine);
    end;

    local procedure VerifyReminderLineLevel(ReminderNo: Code[20]; InvoiceNo: Code[20]; ExpectedLevel: Integer)
    var
        ReminderLine: Record "Reminder Line";
    begin
        FilterReminderLine(ReminderLine, ReminderNo, InvoiceNo, ReminderLine."Line Type"::"Reminder Line", ReminderLine."Document Type"::Invoice);
        ReminderLine.FindFirst();
        ReminderLine.TestField("No. of Reminders", ExpectedLevel);
    end;

    local procedure VerifyReminderLinesCount(var ReminderLine: Record "Reminder Line"; ReminderNo: Code[20]; LineType: Enum "Reminder Line Type"; LinesCount: Integer)
    begin
        ReminderLine.Reset();
        ReminderLine.SetRange("Reminder No.", ReminderNo);
        ReminderLine.SetRange("Line Type", LineType);
        ReminderLine.SetFilter(Description, '<>%1', '');
        Assert.RecordCount(ReminderLine, LinesCount);
    end;

    local procedure VerifyReminderLineDocument(ReminderLine: Record "Reminder Line"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        ReminderLine.TestField("Document Type", DocumentType);
        ReminderLine.TestField("Document No.", DocumentNo);
    end;

    local procedure VerifyReminderLineAppliesToDoc(ReminderLine: Record "Reminder Line"; AppliesToDocType: Enum "Gen. Journal Document Type"; AppliesToDocNo: Code[20]; AmountValue: Decimal)
    begin
        ReminderLine.TestField("Applies-to Document Type", AppliesToDocType);
        ReminderLine.TestField("Applies-to Document No.", AppliesToDocNo);
        ReminderLine.TestField(Amount, AmountValue);
    end;
}

