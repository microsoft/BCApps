codeunit 134904 "ERM Reminder For Additinal Fee"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [ERM] [Reminder]
        IsInitialized := false;
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryDimension: Codeunit "Library - Dimension";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        AmountError: Label 'Additional Fee must be %1.';
        IsInitialized: Boolean;
        ErrMsg: Label 'Rounding in the end is not expected.';
        DimensionValueErr: Label 'Dimension Value code should be %1', Comment = '%1 - Dimension Value Code';

    local procedure Initialize()
    var
        FeatureKey: Record "Feature Key";
        FeatureKeyUpdateStatus: Record "Feature Data Update Status";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Reminder For Additinal Fee");
        LibrarySetupStorage.Restore();
        if FeatureKey.Get('ReminderTermsCommunicationTexts') then begin
            FeatureKey.Enabled := FeatureKey.Enabled::None;
            FeatureKey.Modify();
        end;
        if FeatureKeyUpdateStatus.Get('ReminderTermsCommunicationTexts', CompanyName()) then begin
            FeatureKeyUpdateStatus."Feature Status" := FeatureKeyUpdateStatus."Feature Status"::Disabled;
            FeatureKeyUpdateStatus.Modify();
        end;
        // Lazy Setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Reminder For Additinal Fee");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        IsInitialized := true;
        Commit();

        LibrarySetupStorage.SaveGeneralLedgerSetup();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Reminder For Additinal Fee");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReminderWithAdditionalFee()
    var
        ReminderLevel: Record "Reminder Level";
        SalesHeader: Record "Sales Header";
        CurrencyCode: Code[10];
        Amount: Decimal;
        ReminderNo: Code[20];
    begin
        // Create Sales Invoice with Reminder and Check Additional Fee after Suggest Reminder Lines.

        // Setup: Create Reminder with Additional Fee and Sales Invoice and Post it.
        Initialize();
        CurrencyCode := CreateCurrency();
        CreateReminderTerms(ReminderLevel, CurrencyCode);
        CreateAndPostSalesInvoice(SalesHeader, CreateCustomer(ReminderLevel."Reminder Terms Code", CurrencyCode));
        Amount := LibraryERM.ConvertCurrency(ReminderLevel."Additional Fee (LCY)", '', CurrencyCode, WorkDate());

        // Exercise: Create and Suggest Reminder Lines.
        ReminderNo :=
          CreateAndSuggestReminder(
            SalesHeader."Sell-to Customer No.", CalcDate('<1D>', CalcDate(ReminderLevel."Grace Period", SalesHeader."Due Date")));

        // Verify: Verify Reminder Lines after Suggesting.
        VerifyReminderLine(ReminderNo, Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReminderFromRefund()
    var
        ReminderLevel: Record "Reminder Level";
        ReminderLine: Record "Reminder Line";
        GenJournalLine: Record "Gen. Journal Line";
        ReminderNo: Code[20];
    begin
        // Test Reminder Lines after Suggesting Lines for Reminder.

        // 1. Setup: Create Reminder Terms, Create Customer, Create and Post General Journal Line for Refund.
        Initialize();
        CreateReminderTerms(ReminderLevel, '');
        CreateAndPostGeneralJournal(GenJournalLine, CreateCustomer(ReminderLevel."Reminder Terms Code", ''));

        // 2. Exercise: Create Reminder Header and Suggest Lines.
        ReminderNo :=
          CreateAndSuggestReminder(
            GenJournalLine."Account No.",
            CalcDate('<' + Format(LibraryRandom.RandInt(3)) + 'D>', CalcDate(ReminderLevel."Grace Period", WorkDate())));

        // 3. Verify: Verify Reminder Lines.
        VerifyReminderLine(ReminderNo, ReminderLevel."Additional Fee (LCY)");
        FindReminderLine(ReminderLine, ReminderNo, ReminderLine.Type::"Customer Ledger Entry");
        ReminderLine.TestField("Remaining Amount", GenJournalLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IssuedReminderFromRefund()
    var
        ReminderLevel: Record "Reminder Level";
        IssuedReminderHeader: Record "Issued Reminder Header";
        IssuedReminderLine: Record "Issued Reminder Line";
        GenJournalLine: Record "Gen. Journal Line";
        ReminderHeader: Record "Reminder Header";
    begin
        // Test Issued Reminder Lines after Issuing Reminder.

        // 1. Setup: Create Reminder Terms, Create Customer, Create and Post General Journal Line for Refund, Create Reminder Header
        // and Suggest Lines.
        Initialize();
        CreateReminderTerms(ReminderLevel, '');
        CreateAndPostGeneralJournal(GenJournalLine, CreateCustomer(ReminderLevel."Reminder Terms Code", ''));
        ReminderHeader.Get(
          CreateAndSuggestReminder(
            GenJournalLine."Account No.",
            CalcDate('<' + Format(LibraryRandom.RandInt(3)) + 'D>', CalcDate(ReminderLevel."Grace Period", WorkDate()))));

        // 2. Exercise: Issue Reminder.
        IssueReminder(ReminderHeader);

        // 3. Verify: Verify Issued Reminder Lines.
        IssuedReminderHeader.SetRange("Pre-Assigned No.", ReminderHeader."No.");
        IssuedReminderHeader.FindFirst();
        VerifyIssuedReminderLine(IssuedReminderHeader."No.", IssuedReminderLine.Type::"Customer Ledger Entry", GenJournalLine.Amount, 0);
        VerifyIssuedReminderLine(
          IssuedReminderHeader."No.", IssuedReminderLine.Type::"G/L Account", 0, ReminderLevel."Additional Fee (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReminderWithRounding()
    var
        SalesHeader: Record "Sales Header";
        ReminderLevel: Record "Reminder Level";
        ReminderText: Record "Reminder Text";
        ReminderNo: Code[20];
        ReminderTermsCode: Code[10];
    begin
        // Setup: Set the Rounding Precision.
        Initialize();
        LibraryERM.SetInvRoundingPrecisionLCY(LibraryRandom.RandDec(1, 2));
        ReminderTermsCode := CreateReminderTerms(ReminderLevel, '');
        LibraryERM.CreateReminderText(ReminderText, ReminderTermsCode, ReminderLevel."No.",
          ReminderText.Position::Ending, 'Reminder Text');

        // Setup: Create and Post Sales Invoice.
        CreateAndPostSalesInvoice(SalesHeader, CreateCustomer(ReminderTermsCode, ''));

        // Setup: Re-Set the Rounding Precision.
        LibraryERM.SetInvRoundingPrecisionLCY(LibraryRandom.RandDec(1, 1));

        // Exercise: Create and Suggest Reminder Lines.
        ReminderNo :=
          CreateAndSuggestReminder(
            SalesHeader."Sell-to Customer No.", CalcDate('<1D>', CalcDate(ReminderLevel."Grace Period", SalesHeader."Due Date")));

        // Verify: Verify Reminder Lines after Suggesting.
        VerifyReminderRoundingLine(ReminderNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IssuedReminderAdditionalFeeLineDimensionCombine();
    var
        ReminderLevel: Record "Reminder Level";
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        GLAccount: Record "G/L Account";
        DefaultDimension: array[2] of Record "Default Dimension";
        ReminderHeader: Record "Reminder Header";
        ReminderTerms: Record "Reminder Terms";
        GLEntry: Record "G/L Entry";
        DimensionSetEntry: Record "Dimension Set Entry";
        IssuedReminderNo: Code[20];
    begin
        // [SCENARIO 416996] Issued Reminder Line with Additional Fee should combine dimensions from Header and G/L Account
        Initialize();

        // [GIVEN] Customer "C" with Reminder Terms and Post Additional Fee = True.
        CreateReminderTerms(ReminderLevel, '');
        ReminderTerms.GET(ReminderLevel."Reminder Terms Code");
        ReminderTerms."Post Additional Fee" := true;
        ReminderTerms.Modify(true);
        Customer.GET(CreateCustomer(ReminderLevel."Reminder Terms Code", ''));
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);

        // [GIVEN] Customer "C" has Default Dimension "DM1"
        LibraryDimension.CreateDefaultDimensionWithNewDimValue(
          DefaultDimension[1], DATABASE::Customer, Customer."No.",
          DefaultDimension[1]."Value Posting"::"Code Mandatory");

        // [GIVEN] Customer Posting Group with G/L Account "GL" with Default Dimension "DM2" and "Value Posting" = "Code Mandatory"
        GLAccount.GET(CustomerPostingGroup."Additional Fee Account");
        LibraryDimension.CreateDefaultDimensionWithNewDimValue(
          DefaultDimension[2], DATABASE::"G/L Account", GLAccount."No.",
          DefaultDimension[2]."Value Posting"::"Code Mandatory");
        Customer."Customer Posting Group" := CustomerPostingGroup.Code;
        Customer.Modify(true);

        // [GIVEN] Posted Sales Invoice for Customer "C" and Suggested Reminder with Additional Fee line
        CreateAndPostSalesInvoice(SalesHeader, Customer."No.");
        ReminderHeader.GET(
          CreateAndSuggestReminder(
            SalesHeader."Sell-to Customer No.",
            CALCDATE('<1D>', CALCDATE(ReminderLevel."Grace Period", SalesHeader."Due Date"))));

        // [WHEN] Reminder is issued
        IssuedReminderNo := IssueReminderAndGetIssuedNo(ReminderHeader."No.");

        // [THEN] No errors appear
        // [THEN] G/L Entry for "GL" created
        GLEntry.SETRANGE("Document Type", GLEntry."Document Type"::Reminder);
        GLEntry.SETRANGE("Document No.", IssuedReminderNo);
        GLEntry.SETRANGE("G/L Account No.", GLAccount."No.");
        GLEntry.FindFirst();

        // [THEN] G/L Entry contains both Dimensions "DM1" and "DM2"
        DimensionSetEntry.GET(GLEntry."Dimension Set ID", DefaultDimension[1]."Dimension Code");
        DimensionSetEntry.GET(GLEntry."Dimension Set ID", DefaultDimension[2]."Dimension Code");
        DeleteDefaultDimension(DefaultDimension[1]);
        DeleteDefaultDimension(DefaultDimension[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IssuedReminderAdditionalFeeLineShortcutDimension();
    var
        ReminderLevel: Record "Reminder Level";
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        GLAccount: Record "G/L Account";
        DefaultDimension: array[2] of Record "Default Dimension";
        ReminderHeader: Record "Reminder Header";
        ReminderTerms: Record "Reminder Terms";
        GLEntry: Record "G/L Entry";
        DimensionValue: Record "Dimension Value";
        GetShortcutDimValues: Codeunit "Get Shortcut Dimension Values";
        IssuedReminderNo: Code[20];
        Dim1CodeValue: Code[20];
        Dim2CodeValue: Code[20];
        ShortcutDimCode: array[8] of Code[20];
    begin
        // [SCENARIO 434195] To check if Global Dimension 1 Code and Global Dimension 2 Code are having the same value as there Dimension Set for Additional Fee Line Gl Entry.
        Initialize();

        // [GIVEN] There is Dimension Value as A in Global Dimension 1 Code
        Dim1CodeValue := 'A';
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue, Dim1CodeValue, LibraryERM.GetGlobalDimensionCode(1));

        // [GIVEN] There is Dimension Value as B in Global Dimension 2 Code
        Dim2CodeValue := 'B';
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue, Dim2CodeValue, LibraryERM.GetGlobalDimensionCode(2));

        // [GIVEN] Customer "C" with Reminder Terms and Post Additional Fee = True.
        CreateReminderTerms(ReminderLevel, '');
        ReminderTerms.Get(ReminderLevel."Reminder Terms Code");
        ReminderTerms."Post Additional Fee" := true;
        ReminderTerms.Modify(true);

        Customer.Get(CreateCustomer(ReminderLevel."Reminder Terms Code", ''));
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);

        // [GIVEN] Customer "C" has Default Dimension "DM1"
        LibraryDimension.CreateDefaultDimensionWithNewDimValue(
          DefaultDimension[1], DATABASE::Customer, Customer."No.",
          DefaultDimension[1]."Value Posting"::"Code Mandatory");

        // [GIVEN] Customer Posting Group with G/L Account "GL" having Shortcut Dimension 1 Code as A and also Shortcut Dimension 2 Code as B
        GLAccount.Get(CustomerPostingGroup."Additional Fee Account");
        GLAccount.ValidateShortcutDimCode(1, Dim1CodeValue);
        GLAccount.ValidateShortcutDimCode(2, Dim2CodeValue);
        GLAccount.Modify(true);

        // [GIVEN] Additional Default Dimension on GlAccount "DM2" and "Value Posting" = "Code Mandatory"
        LibraryDimension.CreateDefaultDimensionWithNewDimValue(
          DefaultDimension[2], DATABASE::"G/L Account", GLAccount."No.",
          DefaultDimension[2]."Value Posting"::"Code Mandatory");

        Customer.Validate("Customer Posting Group", CustomerPostingGroup.Code);
        Customer.Modify(true);

        // [GIVEN] Posted Sales Invoice for Customer "C" and Suggested Reminder with Additional Fee line
        CreateAndPostSalesInvoice(SalesHeader, Customer."No.");
        ReminderHeader.Get(
          CreateAndSuggestReminder(
            SalesHeader."Sell-to Customer No.",
            CalcDate('<1D>', CalcDate(ReminderLevel."Grace Period", SalesHeader."Due Date"))));

        // [WHEN] Reminder is issued
        IssuedReminderNo := IssueReminderAndGetIssuedNo(ReminderHeader."No.");

        // [THEN] No errors appear
        // [THEN] G/L Entry for "GL" created
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Reminder);
        GLEntry.SetRange("Document No.", IssuedReminderNo);
        GLEntry.SetRange("G/L Account No.", GLAccount."No.");
        GLEntry.FindFirst();

        // [THEN] G/L Entry contains Global Dimension 1 Code as A and Global Dimension 2 Code as B
        GetShortcutDimValues.GetShortcutDimensions(GLEntry."Dimension Set ID", ShortcutDimCode);
        Assert.AreEqual(Dim1CodeValue, ShortcutDimCode[1], StrSubstNo(DimensionValueErr, Dim1CodeValue));
        Assert.AreEqual(Dim2CodeValue, ShortcutDimCode[2], StrSubstNo(DimensionValueErr, Dim2CodeValue));
    end;

    [Test]
    procedure DimensionsInGeneralLedgerEntriesWhenDimensionsModifiedInReminderBeforeIssuing();
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        DefaultDimension: array[2] of Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        ReminderHeader: Record "Reminder Header";
        ReminderLevel: Record "Reminder Level";
        ReminderTerms: Record "Reminder Terms";
        SalesHeader: Record "Sales Header";
        GetShortcutDimValues: Codeunit "Get Shortcut Dimension Values";
        Dim1CodeValue: array[2] of Code[20];
        Dim2CodeValue: Code[20];
        IssuedReminderNo: Code[20];
        ShortcutDimCode: array[8] of Code[20];
    begin
        // [SCENARIO 590674] Dimensions assigned to General Ledger Entries when the Dimensions are modified in the Reminder before issuing it.
        Initialize();

        // [GIVEN] Create two Dimension Values for Global Dimension 1 Code.
        Dim1CodeValue[1] := LibraryUtility.GenerateGUID();
        Dim1CodeValue[2] := Dim1CodeValue[1] + '1';
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue, Dim1CodeValue[1], LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue, Dim1CodeValue[2], LibraryERM.GetGlobalDimensionCode(1));

        // [GIVEN] Create Dimension Value for Global Dimension 2 Code and assign it.
        Dim2CodeValue := LibraryUtility.GenerateGUID();
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue, Dim2CodeValue, LibraryERM.GetGlobalDimensionCode(2));

        // [GIVEN] Create Reminder Terms with Post Additional Fee = True.
        CreateReminderTerms(ReminderLevel, '');
        ReminderTerms.Get(ReminderLevel."Reminder Terms Code");
        ReminderTerms."Post Additional Fee" := true;
        ReminderTerms.Modify(true);

        // [GIVEN] Create Customer with Reminder Terms and Customer Posting Group.
        Customer.Get(CreateCustomer(ReminderLevel."Reminder Terms Code", ''));
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);

        // [GIVEN] Create Default Dimension for Customer with global Dimension 1 Code.
        LibraryDimension.CreateDefaultDimensionWithNewDimValue(
            DefaultDimension[1], DATABASE::Customer, Customer."No.",
            DefaultDimension[1]."Value Posting"::"Code Mandatory");

        // [GIVEN] Find GL Account for Additional Fee Account and assign Global Dimension 1 Code and Global Dimension 2 Code.
        GLAccount.Get(CustomerPostingGroup."Additional Fee Account");
        GLAccount.ValidateShortcutDimCode(1, Dim1CodeValue[1]);
        GLAccount.ValidateShortcutDimCode(2, Dim2CodeValue);
        GLAccount.Modify(true);

        // [GIVEN] Validate Customer Posting Group in Customer.
        Customer.Validate("Customer Posting Group", CustomerPostingGroup.Code);
        Customer.Modify(true);

        // [GIVEN] Posted Sales Invoice and Run Suggested Reminder with Additional Fee line.
        CreateAndPostSalesInvoice(SalesHeader, Customer."No.");
        ReminderHeader.Get(
          CreateAndSuggestReminder(
            SalesHeader."Sell-to Customer No.",
            CalcDate('<1D>', CalcDate(ReminderLevel."Grace Period", SalesHeader."Due Date"))));
        ReminderHeader.Validate("Shortcut Dimension 1 Code", Dim1CodeValue[2]);
        ReminderHeader.Modify(true);

        // [WHEN] Reminder is issued
        IssuedReminderNo := IssueReminderAndGetIssuedNo(ReminderHeader."No.");

        // [THEN] Find G/L Entry for Reminder with GL Account.
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Reminder);
        GLEntry.SetRange("Document No.", IssuedReminderNo);
        GLEntry.SetRange("G/L Account No.", GLAccount."No.");
        GLEntry.FindFirst();

        // [THEN] G/L Entry contains Global Dimension 1 Code as updated in Reminder Header.
        GetShortcutDimValues.GetShortcutDimensions(GLEntry."Dimension Set ID", ShortcutDimCode);
        Assert.AreEqual(Dim1CodeValue[2], ShortcutDimCode[1], StrSubstNo(DimensionValueErr, Dim1CodeValue[2]));
    end;

    [Scope('OnPrem')]
    procedure InterestAmountWithBeginningText()
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        Reminder: Report Reminder;
    begin
        // [SCENARIO 252587] Interest Amount is printed with Issued Reminder when begin text exist
        Initialize();

        // [GIVEN] Reminder with Interest amount "RM" and Beginning Text = "AAA"
        // [GIVEN] "RM" is issued
        CreateIssuedReminderWithInterestAmount(IssuedReminderHeader);

        // [WHEN] Print issued "RM"
        Commit();
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        IssuedReminderHeader.SetRecFilter();
        Reminder.SetTableView(IssuedReminderHeader);
        Reminder.SaveAsExcel(LibraryReportValidation.GetFileName());

        // [THEN] Interest amount is printed
        LibraryReportValidation.OpenExcelFile();
        Assert.IsTrue(LibraryReportValidation.CheckIfValueExists('Interest Amount'), 'Interest Amount must be printed');
    end;

    local procedure CreateAndPostGeneralJournal(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        CreateGeneralJournalBatch(GenJournalBatch);

        // Use Random because value is not important.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Refund,
          GenJournalLine."Account Type"::Customer, AccountNo, LibraryRandom.RandDec(1000, 2));
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalLine.Modify(true);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostSalesInvoice(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        // Take Random Quantity for Sales Invoice.
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
          Item, LibraryRandom.RandDec(1000, 2), LibraryRandom.RandDec(1000, 2));
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateAndPostSalesDocument(): Code[20]
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateSalesHeader(
            SalesHeader, SalesHeader."Document Type"::Invoice,
            CreateCustomerWithReminderSetup(VATPostingSetup."VAT Bus. Posting Group"));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item,
          LibraryInventory.CreateItemNo(),
          LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateCustomer(ReminderTermsCode: Code[10]; CurrencyCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Validate("Reminder Terms Code", ReminderTermsCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithReminderSetup(VATBusPostingGroupCode: Code[20]): Code[20]
    var
        Customer: Record Customer;
        ReminderTerms: Record "Reminder Terms";
    begin
        CreateReminderTerm(ReminderTerms);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Reminder Terms Code", ReminderTerms.Code);
        Customer.Validate("Customer Posting Group", LibrarySales.FindCustomerPostingGroup());
        Customer.Validate("Fin. Charge Terms Code", CreateFinanceChargeTerms());
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroupCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateFinanceChargeTerms(): Code[10]
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
    begin
        // Create Finance Charge Term with Random Interest Rate, Minimum Amount, Additional Amount, Grace Period, Interest Period and
        // Due Date Calculation.
        LibraryERM.CreateFinanceChargeTerms(FinanceChargeTerms);
        FinanceChargeTerms.Validate("Interest Rate", LibraryRandom.RandDec(10, 2));
        FinanceChargeTerms.Validate("Additional Fee (LCY)", LibraryRandom.RandDec(1000, 2));
        FinanceChargeTerms.Validate("Interest Period (Days)", LibraryRandom.RandInt(30));
        Evaluate(FinanceChargeTerms."Due Date Calculation", '<' + Format(LibraryRandom.RandInt(20)) + 'D>');
        FinanceChargeTerms.Validate("Post Additional Fee", true);
        FinanceChargeTerms.Validate("Post Interest", true);
        FinanceChargeTerms.Modify(true);
        exit(FinanceChargeTerms.Code);
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Recurring, false);
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::General);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateReminder(CustomerNo: Code[20]; DocumentDate: Date): Code[20]
    var
        ReminderHeader: Record "Reminder Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgEntryLineFeeOn: Record "Cust. Ledger Entry";
        ReminderMake: Codeunit "Reminder-Make";
    begin
        LibraryERM.CreateReminderHeader(ReminderHeader);
        ReminderHeader.Validate("Customer No.", CustomerNo);
        ReminderHeader.Validate("Posting Date", DocumentDate);
        ReminderHeader.Validate("Document Date", DocumentDate);
        ReminderHeader.Modify(true);
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        ReminderMake.SuggestLines(ReminderHeader, CustLedgerEntry, false, false, CustLedgEntryLineFeeOn);
        ReminderMake.Code();
        exit(ReminderHeader."No.");
    end;

    local procedure CreateReminderTerm(var ReminderTerms: Record "Reminder Terms")
    var
        ReminderLevel: Record "Reminder Level";
        ReminderText: Record "Reminder Text";
    begin
        LibraryERM.CreateReminderTerms(ReminderTerms);
        LibraryERM.CreateReminderLevel(ReminderLevel, ReminderTerms.Code);
        ReminderLevel.Validate("Calculate Interest", true);
        ReminderLevel.Modify(true);

        LibraryERM.CreateReminderText(
          ReminderText, ReminderTerms.Code, ReminderLevel."No.",
          ReminderText.Position::Beginning, LibraryUtility.GenerateGUID());
    end;

    local procedure CreateReminderTerms(var ReminderLevel: Record "Reminder Level"; CurrencyCode: Code[10]): Code[10]
    var
        ReminderTerms: Record "Reminder Terms";
    begin
        LibraryERM.CreateReminderTerms(ReminderTerms);
        CreateReminderLevel(ReminderLevel, ReminderTerms.Code);
        ModifyCurrencyOnReminderLevel(ReminderTerms.Code, ReminderLevel."Additional Fee (LCY)", CurrencyCode);
        exit(ReminderTerms.Code);
    end;

    local procedure CreateReminderLevel(var ReminderLevel: Record "Reminder Level"; ReminderTermsCode: Code[10])
    begin
        // Take Random Grace Period and Additional Fee.
        LibraryERM.CreateReminderLevel(ReminderLevel, ReminderTermsCode);
        Evaluate(ReminderLevel."Grace Period", '<' + Format(LibraryRandom.RandInt(5)) + 'M>');
        ReminderLevel.Validate("Additional Fee (LCY)", LibraryRandom.RandInt(10));
        ReminderLevel.Modify(true);
    end;

    local procedure CreateReminderWithInterestAmount(var ReminderHeader: Record "Reminder Header")
    var
        SalesInvHeader: Record "Sales Invoice Header";
        ReminderNo: Code[20];
    begin
        SalesInvHeader.Get(CreateAndPostSalesDocument());
        ReminderNo := CreateReminderWithGivenDocNo(SalesInvHeader."No.", SalesInvHeader."Sell-to Customer No.");
        ReminderHeader.Get(ReminderNo);
        ReminderHeader.CalcFields("Interest Amount");
    end;

    local procedure CreateReminderWithGivenDocNo(DocumentNo: Code[20]; CustomerNo: Code[20]): Code[20]
    var
        ReminderLevel: Record "Reminder Level";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        FindReminderLevel(ReminderLevel, Customer."Reminder Terms Code");
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, DocumentNo);

        // Calculate Document Date according to Reminder Level's Grace Period and add One day.
        exit(
          CreateReminder(
            CustomerNo, CalcDate('<1D>', CalcDate(ReminderLevel."Grace Period", CustLedgerEntry."Due Date"))));
    end;

    local procedure CreateIssuedReminderWithInterestAmount(var IssuedReminderHeader: Record "Issued Reminder Header")
    var
        ReminderHeader: Record "Reminder Header";
        IssuedReminderNo: Code[20];
    begin
        CreateReminderWithInterestAmount(ReminderHeader);
        IssuedReminderNo := IssueReminderAndGetIssuedNo(ReminderHeader."No.");
        IssuedReminderHeader.Get(IssuedReminderNo);
        IssuedReminderHeader.CalcFields("Interest Amount");
    end;

    local procedure DeleteDefaultDimension(DefaultDimension: Record "Default Dimension");
    begin
        DefaultDimension.Get(DefaultDimension."Table ID", DefaultDimension."No.", DefaultDimension."Dimension Code");
        DefaultDimension.Delete(true);
    end;

    local procedure FindReminderLine(var ReminderLine: Record "Reminder Line"; ReminderNo: Code[20]; Type: Enum "Reminder Source Type")
    begin
        ReminderLine.SetRange("Reminder No.", ReminderNo);
        ReminderLine.SetRange(Type, Type);
        ReminderLine.FindFirst();
    end;

    local procedure FindReminderLevel(var ReminderLevel: Record "Reminder Level"; ReminderTermsCode: Code[10])
    begin
        ReminderLevel.SetRange("Reminder Terms Code", ReminderTermsCode);
        ReminderLevel.FindFirst();
    end;

    local procedure IssueReminder(ReminderHeader: Record "Reminder Header")
    var
        ReminderIssue: Codeunit "Reminder-Issue";
    begin
        ReminderIssue.Set(ReminderHeader, false, ReminderHeader."Document Date");
        LibraryERM.RunReminderIssue(ReminderIssue);
    end;

    local procedure IssueReminderAndGetIssuedNo(ReminderNo: Code[20]) IssuedReminderNo: Code[20]
    var
        ReminderHeader: Record "Reminder Header";
        NoSeries: Codeunit "No. Series";
    begin
        ReminderHeader.Get(ReminderNo);
        IssuedReminderNo := NoSeries.PeekNextNo(ReminderHeader."Issuing No. Series");
        IssueReminder(ReminderHeader);
    end;

    local procedure ModifyCurrencyOnReminderLevel(ReminderTermsCode: Code[10]; AdditionalFee: Decimal; CurrencyCode: Code[10])
    var
        CurrencyForReminderLevel: Record "Currency for Reminder Level";
    begin
        LibraryERM.CreateCurrencyForReminderLevel(CurrencyForReminderLevel, ReminderTermsCode, CurrencyCode);
        CurrencyForReminderLevel.Validate("Additional Fee", AdditionalFee);
        CurrencyForReminderLevel.Modify(true);
    end;

    local procedure CreateAndSuggestReminder(CustomerNo: Code[20]; DocumentDate: Date): Code[20]
    var
        ReminderHeader: Record "Reminder Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgEntryLineFeeOn: Record "Cust. Ledger Entry";
        ReminderMake: Codeunit "Reminder-Make";
    begin
        LibraryERM.CreateReminderHeader(ReminderHeader);
        ReminderHeader.Validate("Customer No.", CustomerNo);
        ReminderHeader.Validate("Document Date", DocumentDate);
        ReminderHeader.Modify(true);

        ReminderMake.SuggestLines(ReminderHeader, CustLedgerEntry, true, false, CustLedgEntryLineFeeOn);
        ReminderMake.Code();
        exit(ReminderHeader."No.");
    end;

    local procedure VerifyIssuedReminderLine(ReminderNo: Code[20]; Type: Enum "Reminder Source Type"; RemainingAmount: Decimal; Amount: Decimal)
    var
        IssuedReminderLine: Record "Issued Reminder Line";
    begin
        IssuedReminderLine.SetRange("Reminder No.", ReminderNo);
        IssuedReminderLine.SetRange(Type, Type);
        IssuedReminderLine.FindFirst();
        IssuedReminderLine.TestField("Remaining Amount", RemainingAmount);
        IssuedReminderLine.TestField(Amount, Amount);
    end;

    local procedure VerifyReminderLine(ReminderNo: Code[20]; Amount: Decimal)
    var
        ReminderLine: Record "Reminder Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        Assert: Codeunit Assert;
    begin
        GeneralLedgerSetup.Get();
        ReminderLine.SetRange("Reminder No.", ReminderNo);
        ReminderLine.SetRange(Type, ReminderLine.Type::"G/L Account");
        ReminderLine.SetRange("Line Type", ReminderLine."Line Type"::"Additional Fee");
        ReminderLine.FindFirst();
        Assert.AreNearlyEqual(Amount, ReminderLine.Amount, GeneralLedgerSetup."Amount Rounding Precision", StrSubstNo(AmountError, Amount));
    end;

    local procedure VerifyReminderRoundingLine(ReminderNo: Code[20])
    var
        ReminderLine: Record "Reminder Line";
    begin
        ReminderLine.SetRange("Reminder No.", ReminderNo);
        ReminderLine.SetFilter("Line Type", '%1|%2',
          ReminderLine."Line Type"::Rounding, ReminderLine."Line Type"::"Ending Text");
        ReminderLine.FindLast();
        Assert.AreNotEqual(ReminderLine."Line Type"::Rounding, ReminderLine."Line Type", ErrMsg);
    end;
}

