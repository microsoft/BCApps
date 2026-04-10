codeunit 134910 "ERM Suggest Reminder"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [ERM] [Reminder] [Suggest]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        IsInitialized: Boolean;
        ReminderCaptionTxt: Label 'Reminder Text - %1 %2 Beginning', Comment = '%1=Reminder Terms Code;%2=Reminder Level';
        CaptionErr: Label 'Page Captions must match.';
        ReminderLineExistErr: Label 'Reminder Line must not exist.';
        ReminderHeaderExistErr: Label 'Reminder Header must not exist.';

    [Test]
    [Scope('OnPrem')]
    procedure SuggestReminderforCustomer()
    var
        ReminderHeaderNo: Code[20];
    begin
        // Check that Reminder Lines will be created after Running Suggest Reminder Lines Report.

        // Create Reminder and suggest Reminder Lines. Take random no. of days to calculate Document Date after Due Date.
        Initialize();
        ReminderHeaderNo := CreateAndSuggestReminderLine(LibraryRandom.RandInt(10), CreateCustomer());

        // Verify: Verify the Creation of Reminder Lines.
        VerifyReminderLine(ReminderHeaderNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoReminderLinesBeforeDueDate()
    var
        ReminderLine: Record "Reminder Line";
        Assert: Codeunit Assert;
        ReminderNo: Code[20];
    begin
        // Check that no Reminder Line exist while creating and suggesting Reminder through Page Testability and Document Date is before Due Date.

        // Create Reminder and suggest Reminder Lines. Take Negative random no. of days to calculate Document Date before Due Date.
        Initialize();
        ReminderNo := CreateAndSuggestReminderLine(-LibraryRandom.RandInt(10), CreateCustomer());

        // Verify: Check that no Reminder Line exists when Document Date is before Due Date.
        ReminderLine.SetRange("Reminder No.", ReminderNo);
        Assert.IsTrue(ReminderLine.IsEmpty, ReminderLineExistErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoReminderLinesWithInterestCalculation()
    var
        ReminderHeader: Record "Reminder Header";
        GenJournalLine: Record "Gen. Journal Line";
        Assert: Codeunit Assert;
        ReminderNo: Code[20];
        CustomerNo: Code[20];
        Amt: Decimal;
    begin
        // [SCENARIO TFS121135] Create Reminder and remove Reminder Header if total balance is negative.

        // [GIVEN] Create new customer.
        Initialize();
        CustomerNo := CreateCustomer();
        Amt := LibraryRandom.RandIntInRange(1000, 1500);

        // [GIVEN] Credit Memo posted with amount 'A1', where calculated Interest = 'I'.
        CreatePostGeneralJnlLine(
          CustomerNo, GenJournalLine."Document Type"::"Credit Memo", WorkDate(), -Amt);

        // [GIVEN] Invoice posted on the 1 year after work date with amount 'A2', where ('A1'+ 'I') > 'A2' > 'A1'.
        CreatePostGeneralJnlLine(
          CustomerNo, GenJournalLine."Document Type"::Invoice, CalcDate('<1Y>', WorkDate()),
          Amt + LibraryRandom.RandIntInRange(5, 10));

        // [WHEN] Create Reminder Header and Suggest Reminder Line.
        ReminderNo := CreateAndSuggestingReminder(CustomerNo, CalcDate('<1Y+1M>', WorkDate()));

        // [THEN] Check that no Reminder exists when Total Balance is negative.
        ReminderHeader.SetRange("No.", ReminderNo);
        Assert.IsTrue(ReminderHeader.IsEmpty, ReminderHeaderExistErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReminderTextPageCaption()
    var
        ReminderLevel: Record "Reminder Level";
        ReminderTerms: Record "Reminder Terms";
        ReminderText: Record "Reminder Text";
        ReminderLevels: TestPage "Reminder Levels";
        ReminderTextPage: TestPage "Reminder Text";
        ReminderTermsCode: Code[10];
        BeginningText: Text[100];
    begin
        // Check Reminder Text Page's caption updated according to Reminder Terms.

        // Setup: Create Reminder Terms with Reminder Level and Beginning Text.
        Initialize();
        ReminderTermsCode := CreateReminderTerms(true);
        BeginningText := ReminderTermsCode + Format(LibraryRandom.RandInt(10));  // Create any Beginning Text using Random.
        FindReminderLevel(ReminderLevel, ReminderTermsCode);
        LibraryERM.CreateReminderText(ReminderText, ReminderTermsCode, ReminderLevel."No.",
          ReminderText.Position::Beginning, BeginningText);

        // Open Reminder Text Page from Reminder Levels Page.
        OpenReminderTextPage(ReminderLevels, ReminderTermsCode, ReminderLevel."No.");
        ReminderTextPage.Trap();

        // Exercise: Invoke Reminder Text Page.
        ReminderLevels.BeginningText.Invoke();

        // Verify: Verify page caption for Reminder Text Page.
        Assert.AreEqual(StrSubstNo(ReminderCaptionTxt, ReminderTermsCode, ReminderLevel."No."), ReminderTextPage.Caption, CaptionErr);

        // Tear Down: Delete Reminder Terms created earlier.
        ReminderTerms.Get(ReminderTermsCode);
        ReminderTerms.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestReminderWithBlankDefaultVATProdPostGrpAndCalcInterest()
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        GLAccount: Record "G/L Account";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [SCENARIO 290183] When Gen. Product Posting Group has blank Default VAT Product Posting Group Sugessting Reminder Lines results in error
        Initialize();

        // [GIVEN] No VAT Posting Setup with blank VAT Prod. Posting Group.
        VATPostingSetup.SetRange("VAT Prod. Posting Group", '');
        VATPostingSetup.DeleteAll();

        // [GIVEN] Customer with Customer Posting Group "X" and Calculate Interest set to TRUE.
        CreateCustomerWithCustomerPostingGroup(Customer, CustomerPostingGroup, true);

        // [GIVEN] "X" has Additional Fee Account with blank Gen. Prod. Posting Group.
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        GLAccount.Get(CustomerPostingGroup."Additional Fee Account");
        GLAccount.Validate("Gen. Prod. Posting Group", GenProductPostingGroup.Code);

        // [WHEN] Suggesting reminder.
        CreateAndSuggestReminderLine(LibraryRandom.RandInt(10), Customer."No.");

        // [THEN] No error is shown.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestReminderWithBlankDefaultVATProdPostGrpAndNoCalcInterest()
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        GLAccount: Record "G/L Account";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [SCENARIO 290183] When Gen. Product Posting Group has blank Default VAT Product Posting Group Sugessting Reminder Lines results in error
        Initialize();

        // [GIVEN] No VAT Posting Setup with blank VAT Prod. Posting Group.
        VATPostingSetup.SetRange("VAT Prod. Posting Group", '');
        VATPostingSetup.DeleteAll();

        // [GIVEN] Customer with Customer Posting Group "X" and Calculate Interest set to FALSE.
        CreateCustomerWithCustomerPostingGroup(Customer, CustomerPostingGroup, false);

        // [GIVEN] "X" has Additional Fee Account with blank Gen. Prod. Posting Group.
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        GLAccount.Get(CustomerPostingGroup."Additional Fee Account");
        GLAccount.Validate("Gen. Prod. Posting Group", GenProductPostingGroup.Code);

        // [WHEN] Suggesting reminder.
        CreateAndSuggestReminderLine(LibraryRandom.RandInt(10), Customer."No.");

        // [THEN] No error is shown.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestReminderLinesForMultipleReminders()
    var
        ReminderHeader: array[2] of Record "Reminder Header";
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO 329294] Report "Suggest Reminder Lines" creates Reminder Lines for multiple Reminders.
        Initialize();

        // [GIVEN] Two Reminders.
        CreateAndPostSalesInvoice(SalesHeader, CreateCustomer());
        CreateReminderForCustomer(ReminderHeader[1], SalesHeader."Sell-to Customer No.", SalesHeader."Due Date");
        CreateAndPostSalesInvoice(SalesHeader, CreateCustomer());
        CreateReminderForCustomer(ReminderHeader[2], SalesHeader."Sell-to Customer No.", SalesHeader."Due Date");

        // [WHEN] Report "Suggest Reminder Lines" is run for two Reminders.
        ReminderHeader[1].SetFilter("No.", '%1|%2', ReminderHeader[1]."No.", ReminderHeader[2]."No.");
        Commit();
        REPORT.Run(REPORT::"Suggest Reminder Lines", false, true, ReminderHeader[1]);

        // [THEN] Lines are created for both Remiders.
        VerifyReminderLine(ReminderHeader[1]."No.");
        VerifyReminderLine(ReminderHeader[2]."No.");
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        FeatureKey: Record "Feature Key";
        FeatureKeyUpdateStatus: Record "Feature Data Update Status";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Suggest Reminder");
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
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Suggest Reminder");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Suggest Reminder");
    end;

    local procedure CreateGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateAndPostSalesInvoice(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        // Random value used are not important for test.
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(Item,
          LibraryRandom.RandDec(1000, 2), LibraryRandom.RandDec(1000, 2));
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(100, 2));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateAndSuggestReminderLine(NoOfDays: Integer; CustomerNo: Code[20]) ReminderNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
        GracePeriod: DateFormula;
    begin
        // Setup: Create and Post Sale Invoice, Calculate Document Date and Create Reminder for Customer.
        CreateAndPostSalesInvoice(SalesHeader, CustomerNo);
        GetReminderLevel(GracePeriod, SalesHeader."Sell-to Customer No.");

        // Exercise: Create Reminder Header and Suggest Reminder Line.
        ReminderNo :=
          CreateAndSuggestingReminder(
            SalesHeader."Sell-to Customer No.", CalcDate('<' + Format(NoOfDays) + 'D>', CalcDate(GracePeriod, SalesHeader."Due Date")));
    end;

    local procedure CreatePostGeneralJnlLine(CustomerNo: Code[20]; DocType: Enum "Gen. Journal Document Type"; DocDate: Date; Amt: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          DocType, GenJournalLine."Account Type"::Customer, CustomerNo,
          GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), Amt);
        GenJournalLine.Validate("Posting Date", DocDate);
        GenJournalLine.Modify(true);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Reminder Terms Code", CreateReminderTerms(true));
        Customer.Validate("Fin. Charge Terms Code", CreateFinanceChargeTerms());
        Customer.Modify(true);
        exit(Customer."No.")
    end;

    local procedure CreateCustomerWithCustomerPostingGroup(var Customer: Record Customer; var CustomerPostingGroup: Record "Customer Posting Group"; CalculateInterest: Boolean)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Reminder Terms Code", CreateReminderTerms(CalculateInterest));
        Customer.Validate("Fin. Charge Terms Code", CreateFinanceChargeTerms());
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
        Customer.Validate("Customer Posting Group", CustomerPostingGroup.Code);
        Customer.Modify(true);
    end;

    local procedure CreateReminderForCustomer(var ReminderHeader: Record "Reminder Header"; CustomerNo: Code[20]; DueDate: Date)
    var
        DocumentDate: Date;
        GracePeriod: DateFormula;
    begin
        GetReminderLevel(GracePeriod, CustomerNo);
        DocumentDate := CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', CalcDate(GracePeriod, DueDate));
        LibraryERM.CreateReminderHeader(ReminderHeader);
        ReminderHeader.Validate("Customer No.", CustomerNo);
        ReminderHeader.Validate("Document Date", DocumentDate);
        ReminderHeader.Modify(true);
    end;

    local procedure CreateReminderLevel(ReminderTermsCode: Code[10]; CalculateInterest: Boolean)
    var
        ReminderLevel: Record "Reminder Level";
    begin
        // Create Reminder Level with a Random Grace Period and Random Additional Fee.
        LibraryERM.CreateReminderLevel(ReminderLevel, ReminderTermsCode);
        Evaluate(ReminderLevel."Grace Period", '<' + Format(LibraryRandom.RandInt(10)) + 'D>');
        ReminderLevel.Validate("Calculate Interest", CalculateInterest);
        ReminderLevel.Validate("Additional Fee (LCY)", LibraryRandom.RandInt(10));
        ReminderLevel.Modify(true);
    end;

    local procedure CreateReminderTerms(CalculateInterest: Boolean): Code[10]
    var
        ReminderTerms: Record "Reminder Terms";
    begin
        LibraryERM.CreateReminderTerms(ReminderTerms);
        ReminderTerms.Validate("Post Interest", true);
        ReminderTerms.Modify(true);
        CreateReminderLevel(ReminderTerms.Code, CalculateInterest);
        exit(ReminderTerms.Code);
    end;

    local procedure CreateFinanceChargeTerms(): Code[10]
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
    begin
        LibraryERM.CreateFinanceChargeTerms(FinanceChargeTerms);
        FinanceChargeTerms.Validate("Interest Rate", LibraryRandom.RandDec(10, 2));
        FinanceChargeTerms.Validate("Additional Fee (LCY)", LibraryRandom.RandDec(100, 2));
        FinanceChargeTerms.Validate("Interest Period (Days)", LibraryRandom.RandInt(30));
        Evaluate(FinanceChargeTerms."Due Date Calculation", '<' + Format(LibraryRandom.RandInt(30)) + 'D>');
        FinanceChargeTerms.Validate("Post Additional Fee", true);
        FinanceChargeTerms.Validate("Post Interest", true);
        FinanceChargeTerms.Modify(true);
        exit(FinanceChargeTerms.Code);
    end;

    local procedure GetReminderLevel(var GracePeriod: DateFormula; CustomerNo: Code[20])
    var
        Customer: Record Customer;
        ReminderLevel: Record "Reminder Level";
    begin
        Customer.Get(CustomerNo);
        FindReminderLevel(ReminderLevel, Customer."Reminder Terms Code");
        GracePeriod := ReminderLevel."Grace Period";
    end;

    local procedure CreateAndSuggestingReminder(CustomerNo: Code[20]; DocumentDate: Date): Code[20]
    var
        ReminderHeader: Record "Reminder Header";
        SuggestReminderLines: Report "Suggest Reminder Lines";
    begin
        LibraryERM.CreateReminderHeader(ReminderHeader);
        ReminderHeader.Validate("Customer No.", CustomerNo);
        ReminderHeader.Validate("Document Date", DocumentDate);
        ReminderHeader.Modify(true);

        ReminderHeader.SetRange("No.", ReminderHeader."No.");
        SuggestReminderLines.SetTableView(ReminderHeader);
        SuggestReminderLines.UseRequestPage(false);
        SuggestReminderLines.Run();
        exit(ReminderHeader."No.");
    end;

    local procedure FindReminderLevel(var ReminderLevel: Record "Reminder Level"; ReminderTermsCode: Code[10])
    begin
        ReminderLevel.SetRange("Reminder Terms Code", ReminderTermsCode);
        ReminderLevel.FindFirst();
    end;

    local procedure OpenReminderTextPage(var ReminderLevels: TestPage "Reminder Levels"; "Code": Code[10]; No: Integer)
    var
        ReminderTerms: TestPage "Reminder Terms";
    begin
        ReminderTerms.OpenEdit();
        ReminderTerms.FILTER.SetFilter(Code, Code);
        ReminderLevels.Trap();
        ReminderTerms."&Levels".Invoke();
        ReminderLevels.FILTER.SetFilter("No.", Format(No));
    end;

    local procedure VerifyReminderLine(ReminderNo: Code[20])
    var
        ReminderLine: Record "Reminder Line";
    begin
        ReminderLine.SetRange("Reminder No.", ReminderNo);
        ReminderLine.FindFirst();
    end;
}

