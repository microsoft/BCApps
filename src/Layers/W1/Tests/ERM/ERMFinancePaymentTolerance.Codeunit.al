codeunit 134024 "ERM Finance Payment Tolerance"
{
    Permissions = TableData "Cust. Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Payment Tolerance] [Sales]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        OptionValue: Integer;
        isInitialized: Boolean;
        AmountError: Label '%1 and %2 must be same.';
        ConfirmMessageForPayment: Label 'Do you want to change all open entries for every customer and vendor that are not blocked?';
        SuccessPostingMsg: Label 'The journal lines were successfully posted.';
        AppliedError: Label 'Customer ledger entries are not applied correctly';

    [Normal]
    local procedure Initialize()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Finance Payment Tolerance");
        LibrarySetupStorage.Restore();

        // Lazy Setup.
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Finance Payment Tolerance");
        LibrarySales.SetCreditWarningsToNoWarnings();
        LibrarySales.SetApplnBetweenCurrencies(SalesReceivablesSetup."Appln. between Currencies"::All);
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Finance Payment Tolerance");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ApplyPaymentToInvoice()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        // Test application of Payment To Invoice by using Set Applies-to ID.

        Initialize();
        Amount := 10 * LibraryRandom.RandDec(1000, 2);  // Using Large Random Number for Amount.
        AmountToApplyBySetAppliesToID(GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, Amount, -Amount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ApplyRefundToCreditMemo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        // Test application of Refund To Credit Memo by using Set Applies-to ID.

        Initialize();
        Amount := 10 * LibraryRandom.RandDec(1000, 2);  // Using Large Random Number for Amount.
        AmountToApplyBySetAppliesToID(
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, -Amount, Amount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ApplyInvoiceToPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        // Test application of Invoice To Payment by using Set Applies-to ID.

        Initialize();
        Amount := 10 * LibraryRandom.RandDec(1000, 2);  // Using Large Random Number for Amount.
        AmountToApplyBySetAppliesToID(GenJournalLine."Document Type"::Payment, GenJournalLine."Document Type"::Invoice, -Amount, Amount);
    end;

    [Normal]
    local procedure AmountToApplyBySetAppliesToID(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; GenJournalLineAmount: Decimal; GenJournalLineAmount2: Decimal)
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GLAccountNo: Code[20];
    begin
        // 1.Setup: Update General Ledger Setup,Create new Customer with Payment Terms,new General Journal Batch and General Journal
        // Template. Create G/L Account and Create and post General Journal Lines of type Invoice,Payment and Credit Memo.
        UpdateGeneralLedgerSetup();
        CreateCustomerWithPaymentTerm(Customer);
        UpdateCustomerPostingGroup(Customer."Customer Posting Group");
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        CreateGeneralJournalLine(
          GenJournalLine, DocumentType, GenJournalLine."Account Type"::Customer, Customer."No.",
          GenJournalLineAmount, GenJournalLine."Bal. Account Type"::"G/L Account", GLAccountNo);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CreateGeneralJournalLine(
          GenJournalLine, DocumentType2, GenJournalLine."Account Type"::Customer, Customer."No.",
          GenJournalLineAmount2, GenJournalLine."Bal. Account Type"::"G/L Account", GLAccountNo);

        // 2.Exercise: General Journal Lines of Payment,Refund,Invoice and apply to Invoice,Credit Memo,Payment and Post.
        ApplyAndPostGenJournalLine(CustLedgerEntry, GenJournalLine, DocumentType);

        // 3.Verify: Verify Remaining Amount in Customer Ledger Entry.
        VerifyRemainingAmount(CustLedgerEntry, GenJournalLineAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PaymentToleranceWarning')]
    [Scope('OnPrem')]
    procedure ApplyPaymentToleranceWarning()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        Amount: Decimal;
    begin
        // Test application of Payment To Invoice by using Set Applies-to ID with Payment Tolerance Warning.

        Initialize();
        Amount := 10 * LibraryRandom.RandDec(1000, 2);  // Using Large Random Number for Amount.
        OptionValue := 1;  // Assign Global Variable for Page Handler.
        AmountToApplyToleranceWarning(
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, Amount, -Amount,
          DetailedCustLedgEntry."Document Type"::Payment);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PaymentToleranceWarning')]
    [Scope('OnPrem')]
    procedure ApplyRefundToleranceWarning()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        Amount: Decimal;
    begin
        // Test application of Refund To Credit Memo by using Set Applies-to ID with Payment Tolerance Warning.

        Initialize();
        Amount := 10 * LibraryRandom.RandDec(1000, 2);  // Using Large Random Number for Amount.
        OptionValue := 1;  // Assign Global Variable for Page Handler.
        AmountToApplyToleranceWarning(
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, -Amount, Amount,
          DetailedCustLedgEntry."Document Type"::Refund);
    end;

    [Normal]
    local procedure AmountToApplyToleranceWarning(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; GenJournalLineAmount: Decimal; GenJournalLineAmount2: Decimal; DocumentType3: Enum "Gen. Journal Document Type")
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        MaxPaymentTolerance: Decimal;
        GLAccountNo: Code[20];
    begin
        // 1.Setup: Update General Ledger Setup.Create Customer with Payment Terms,General Journal Batch and General Journal Template.
        // Create a new G/L Account and Create and post General Journal Lines of type Invoice and Credit memo.
        UpdateGeneralLedgerSetup();
        CreateCustomerWithPaymentTerm(Customer);
        UpdateCustomerPostingGroup(Customer."Customer Posting Group");
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        CreateGeneralJournalLine(
          GenJournalLine, DocumentType, GenJournalLine."Account Type"::Customer, Customer."No.",
          GenJournalLineAmount, GenJournalLine."Bal. Account Type"::"G/L Account", GLAccountNo);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CreateGeneralJournalLine(
          GenJournalLine, DocumentType2, GenJournalLine."Account Type"::Customer, Customer."No.",
          GenJournalLineAmount2, GenJournalLine."Bal. Account Type"::"G/L Account", GLAccountNo);

        // 2.Exercise: Partially apply General Journal Lines of Payment,Refund and with Payment Tolerance to Invoice,Credit Memo and Post.
        FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Account No.", DocumentType);
        MaxPaymentTolerance := CustLedgerEntry."Max. Payment Tolerance" / 2;  // Use for Verify partial Payment Tolerance Amount.
        ApplyAndPostGenJnlLineWarning(CustLedgerEntry, GenJournalLine, GenJournalLineAmount);

        // 3.Verify: Verify Remaining Amount in Customer Ledger. Verify Payment Tolerance and Payment Discount in Detailed Customer Ledger.
        VerifyLedgerEntry(
          CustLedgerEntry, GenJournalLineAmount, DocumentType3, GenJournalLine."Document No.", -MaxPaymentTolerance);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PaymentToleranceWarning')]
    [Scope('OnPrem')]
    procedure ApplyPaymentToInvoiceDiscount()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        MaxPaymentTolerance: Decimal;
        GLAccountNo: Code[20];
    begin
        // Test application of Payment To Invoice by using Set Applies-to ID with Payment Discount and Payment Tolerance Warning
        // Posting Date of Payment with in Payment Discount Grace Period.

        // 1.Setup: Update General Ledger Setup.Create a new Customer with Payment Terms, new General Journal Batch and General Journal
        // Template.Create a new G/L Account and Create and post General Journal Line of type Invoice.
        Initialize();
        UpdateGeneralLedgerSetup();
        UpdatePaymentGracePeriod();
        CreateCustomerWithPaymentTerm(Customer);
        UpdateCustomerPostingGroup(Customer."Customer Posting Group");
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        OptionValue := 1;  // Assign Global Variable for Page Handler.

        // Using Large Random Number for Amount.
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, Customer."No.",
          10 * LibraryRandom.RandDec(1000, 2), GenJournalLine."Bal. Account Type"::"G/L Account", GLAccountNo);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::"G/L Account", GLAccountNo,
          GenJournalLine.Amount, GenJournalLine."Bal. Account Type"::Customer, Customer."No.");

        // 2.Exercise: General Journal Line of Payment with Account Type as G/L Account
        // and partially apply with Payment Tolerance to Invoice and post.
        FindCustomerLedgerEntry(CustLedgerEntry, Customer."No.", CustLedgerEntry."Document Type"::Invoice);
        MaxPaymentTolerance := CustLedgerEntry."Max. Payment Tolerance" / 2;  // Use for Verify partial Payment Tolerance Amount.
        ApplyAndPostGenJnlLineDiscount(CustLedgerEntry, GenJournalLine);

        // 3.Verify: Verify Remaining Amount in Customer Ledger. Verify Payment Tolerance and Payment Discount in Detailed Customer Ledger.
        VerifyLedgerEntry(
          CustLedgerEntry, GenJournalLine.Amount, DetailedCustLedgEntry."Document Type"::Payment,
          GenJournalLine."Document No.", -MaxPaymentTolerance);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PaymentToleranceWarning')]
    [Scope('OnPrem')]
    procedure ApplyToInvoiceWithAppliesToDoc()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GLAccountNo: Code[20];
        DocumentNo: Code[20];
        MaxPaymentTolerance: Decimal;
    begin
        // Test application of Payment To Invoice by using Applies-to Doc. Type and Applies-to Doc. No. with Payment Discount
        // and Payment Tolerance Warning Posting Date of Payment with in Payment Discount Grace Period.

        // 1.Setup: Update General Ledger Setup.Create a new Customer with Payment Terms, new General Journal Batch and
        // General Journal Template. Create G/L Account and Create and post General Journal Line of type Invoice.
        Initialize();
        UpdateGeneralLedgerSetup();
        UpdatePaymentGracePeriod();
        CreateCustomerWithPaymentTerm(Customer);
        UpdateCustomerPostingGroup(Customer."Customer Posting Group");
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        OptionValue := 1;  // Assign Global Variable for Page Handler.

        // Using Large Random Number for Amount.
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, Customer."No.",
          10 * LibraryRandom.RandDec(1000, 2), GenJournalLine."Bal. Account Type"::"G/L Account", GLAccountNo);
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::"G/L Account", GLAccountNo,
          GenJournalLine.Amount, GenJournalLine."Bal. Account Type"::Customer, Customer."No.");

        // 2.Exercise: General Journal Line of Payment with Account Type as G/L Account and partially applies to Doc No. with
        // Payment Tolerance to Invoice and post.
        FindCustomerLedgerEntry(CustLedgerEntry, Customer."No.", CustLedgerEntry."Document Type"::Invoice);
        MaxPaymentTolerance := CustLedgerEntry."Max. Payment Tolerance" / 2;  // Use for Verify partial Payment Tolerance Amount.
        AppliesToDocAndPostGenJnlLine(CustLedgerEntry, GenJournalLine, DocumentNo);

        // 3.Verify: Verify Remaining Amount in Customer Ledger. Verify Payment Tolerance and Payment Discount in Detailed Customer Ledger.
        VerifyLedgerEntry(
          CustLedgerEntry, GenJournalLine.Amount, DetailedCustLedgEntry."Document Type"::Payment,
          GenJournalLine."Document No.", -MaxPaymentTolerance);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PaymentToleranceWarning')]
    [Scope('OnPrem')]
    procedure ApplyToInvoiceAfterGracePeriod()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GLAccountNo: Code[20];
        NewPostingDate: Date;
        MaxPaymentTolerance: Decimal;
        GracePeriodDays: Integer;
        DiscountDays: Integer;
    begin
        // Test application of Payment To Invoice by using Applies-to Doc. Type and Applies-to Doc. No. without Payment Discount
        // and Payment Tolerance Warning, Posting Date of Payment After Payment Discount Grace Period.

        // 1.Setup: Update and General Ledger Setup,Create a new Customer with Payment Terms, new General Journal Batch and
        // General Journal Template.Create a new G/L Account and Create and post General Journal Lines of type Invoice.
        Initialize();
        UpdateGeneralLedgerSetup();
        GracePeriodDays := UpdatePaymentGracePeriod();
        DiscountDays := CreateCustomerWithPaymentTerm(Customer);
        UpdateCustomerPostingGroup(Customer."Customer Posting Group");
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        OptionValue := 1;  // Assign Global Variable for Page Handler.

        // Using Large Random Number for Amount.
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, Customer."No.",
          10 * LibraryRandom.RandDec(1000, 2), GenJournalLine."Bal. Account Type"::"G/L Account", GLAccountNo);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Using Random Number for Posting Date After Grace Period.
        NewPostingDate := CalcDate('<' + Format(GracePeriodDays + DiscountDays + LibraryRandom.RandInt(10)) + 'D>', WorkDate());
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::"G/L Account",
          GLAccountNo, GenJournalLine.Amount, GenJournalLine."Bal. Account Type"::Customer, Customer."No.");

        // 2.Exercise: General Journal Lines of Payment as postig date After Payment Discount Grace Period with
        // Account Type as G/L Account and partially apply with Payment Tolerance to Invoice and post.
        FindCustomerLedgerEntry(CustLedgerEntry, Customer."No.", CustLedgerEntry."Document Type"::Invoice);
        MaxPaymentTolerance := CustLedgerEntry."Max. Payment Tolerance" / 2;
        UpdatePostingDateGenJnlLine(GenJournalLine, NewPostingDate);
        ApplyPostGenJnlLineGracePeriod(CustLedgerEntry, GenJournalLine);

        // 3.Verify: Verify Remaining Amount in Customer Ledger.Verify Payment Tolerance in Detailed Customer Ledger Entry.
        VerifyRemainingAmount(CustLedgerEntry, GenJournalLine.Amount);
        VerifyAmountInDetailedLedger(
          DetailedCustLedgEntry."Document Type"::Payment, DetailedCustLedgEntry."Entry Type"::"Payment Tolerance",
          GenJournalLine."Document No.", -MaxPaymentTolerance);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure OverPaymentBothWarningLCY()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        Amount: Decimal;
        PaymentAmount: Decimal;
    begin
        // Test the Payment Tolerance with Over Payment and before Payment Discount Date.

        // 1. Setup: Change the Sales and Receivable Setup, create Payment Terms, create Customer and Currency, create General Journal Line
        // for Invoice and Payment, change warnings in General Ledger Setup.
        Initialize();
        CreatePaymentTerms(PaymentTerms, LibraryRandom.RandInt(10), LibraryRandom.RandDec(5, 2));
        CreateCustomerWithCurrency(Customer, PaymentTerms.Code);
        Amount := LibraryRandom.RandDec(1000, 2);  // Taking Random value for Amount.
        CreateGenJournalLine(GenJournalLine, Customer."No.", '', GenJournalLine."Document Type"::Invoice, Amount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        PaymentAmount := Amount + LibraryRandom.RandInt(10);  // Taking Random value for Amount.
        CreateGenJournalLine(
          GenJournalLine2, Customer."No.", '', GenJournalLine2."Document Type"::Payment, -PaymentAmount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);
        WarningsInGeneralLedgerSetup(true, true);

        // 2. Exercise: Apply and Post the Customer Ledger Entry.
        ApplyCustomerEntry(
          CustLedgerEntry2, GenJournalLine2."Document Type"::Payment,
          GenJournalLine2."Document Type"::Invoice, GenJournalLine2."Document No.", GenJournalLine."Document No.");
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry2);

        // 3. Verify: Verify the Ledger Entries.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        VerifyDetldCustomerLedgerEntry(
          GenJournalLine2, DetailedCustLedgEntry."Entry Type"::"Payment Discount", -CustLedgerEntry."Original Pmt. Disc. Possible");
        VerifyLedgerEntries(GenJournalLine, GenJournalLine2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure OverPaymentDiscountWarningFCY()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        CurrencyCode: Code[10];
        Amount: Decimal;
        RefundAmount: Decimal;
    begin
        // Test the Payment Tolerance with Over Payment and before Payment Discount Date.

        // 1. Setup: Change the Sales and Receivable Setup, create Payment Terms, create Customer and Currency, create General Journal Line
        // for Credit Memo and Refund, change warnings in General Ledger Setup.
        Initialize();
        CreatePaymentTerms(PaymentTerms, LibraryRandom.RandInt(10), LibraryRandom.RandDec(5, 2));
        CurrencyCode := CreateCustomerWithCurrency(Customer, PaymentTerms.Code);
        Amount := LibraryRandom.RandDec(1000, 2);  // Taking Random value for Amount.
        CreateGenJournalLine(
          GenJournalLine, Customer."No.", CurrencyCode, GenJournalLine."Document Type"::"Credit Memo", -Amount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        RefundAmount := Amount + LibraryRandom.RandInt(50);  // Taking Random value for Amount.
        CreateGenJournalLine(
          GenJournalLine2,
          Customer."No.", CurrencyCode, GenJournalLine2."Document Type"::Refund, RefundAmount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);
        WarningsInGeneralLedgerSetup(true, false);

        // 2. Exercise: Apply and Post the Customer Ledger Entry.
        ApplyCustomerEntry(
          CustLedgerEntry2, GenJournalLine2."Document Type"::Refund,
          GenJournalLine2."Document Type"::"Credit Memo", GenJournalLine2."Document No.", GenJournalLine."Document No.");
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry2);

        // 3. Verify: Verify the Ledger Entries.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        VerifyDetldCustomerLedgerEntry(
          GenJournalLine2, DetailedCustLedgEntry."Entry Type"::"Payment Discount", -CustLedgerEntry."Original Pmt. Disc. Possible");
        VerifyLedgerEntries(GenJournalLine, GenJournalLine2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure OverPaymentToleranceWarningFCY()
    var
        Currency: Record Currency;
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        CurrencyCode: Code[10];
        Amount: Decimal;
        PaymentAmount: Decimal;
    begin
        // Test the Payment Tolerance with Over Payment and before Payment Discount Date.

        // 1. Setup: Change the Sales and Receivable Setup, create Payment Terms, create Customer and Currency, create General Journal Line
        // for Invoice and Payment, change warnings in General Ledger Setup.
        Initialize();
        CreatePaymentTerms(PaymentTerms, LibraryRandom.RandInt(10), LibraryRandom.RandDec(5, 2));
        CurrencyCode := CreateCustomerWithCurrency(Customer, PaymentTerms.Code);
        CreateCurrencyWithSetup(Currency);
        RunChangePaymentTolerance(Currency.Code, LibraryRandom.RandDec(5, 2), LibraryRandom.RandDec(10, 2));
        Amount := LibraryRandom.RandDec(1000, 2);  // Taking Random value for Amount.
        CreateGenJournalLine(GenJournalLine, Customer."No.", CurrencyCode, GenJournalLine."Document Type"::Invoice, Amount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        PaymentAmount := 2 * Amount + LibraryRandom.RandInt(10);  // Taking Random value for Amount.
        CreateGenJournalLine(
          GenJournalLine2,
          Customer."No.", Currency.Code, GenJournalLine2."Document Type"::Payment, -PaymentAmount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);
        WarningsInGeneralLedgerSetup(false, true);

        // 2. Exercise: Apply and Post the Customer Ledger Entry.
        ApplyCustomerEntry(
          CustLedgerEntry2, GenJournalLine2."Document Type"::Payment,
          GenJournalLine2."Document Type"::Invoice, GenJournalLine2."Document No.", GenJournalLine."Document No.");
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry2);

        // 3. Verify: Verify the Ledger Entries.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        VerifyDetldCustomerLedgerEntry(
          GenJournalLine2, DetailedCustLedgEntry."Entry Type"::"Payment Discount", -CustLedgerEntry."Original Pmt. Disc. Possible");
        VerifyLedgerEntries(GenJournalLine, GenJournalLine2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SamePaymentBothWarningLCY()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        Amount: Decimal;
    begin
        // Test the Payment Tolerance with Payment equal invoce amount and before Payment Discount Date.

        // 1. Setup: Change the Sales and Receivable Setup, create Payment Terms, create Customer and Currency, create General Journal Line
        // for Invoice and Payment, change warnings in General Ledger Setup.
        Initialize();
        CreatePaymentTerms(PaymentTerms, LibraryRandom.RandInt(10), LibraryRandom.RandDec(5, 2));
        CreateCustomerWithCurrency(Customer, PaymentTerms.Code);
        Amount := LibraryRandom.RandDec(1000, 2);  // Taking Random value for Amount.
        CreateGenJournalLine(GenJournalLine, Customer."No.", '', GenJournalLine."Document Type"::Invoice, Amount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CreateGenJournalLine(GenJournalLine2, Customer."No.", '', GenJournalLine2."Document Type"::Payment, -Amount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);
        WarningsInGeneralLedgerSetup(true, true);

        // 2. Exercise: Apply and Post the Customer Ledger Entry.
        ApplyCustomerEntry(
          CustLedgerEntry2, GenJournalLine2."Document Type"::Payment,
          GenJournalLine2."Document Type"::Invoice, GenJournalLine2."Document No.", GenJournalLine."Document No.");
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry2);

        // 3. Verify: Verify the Ledger Entries.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        VerifyDetldCustomerLedgerEntry(
          GenJournalLine2, DetailedCustLedgEntry."Entry Type"::"Payment Discount", -CustLedgerEntry."Original Pmt. Disc. Possible");
        VerifyLedgerEntries(GenJournalLine, GenJournalLine2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SamePaymentDiscountWarningFCY()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        CurrencyCode: Code[10];
        Amount: Decimal;
    begin
        // Test the Payment Tolerance with Payment equal invoce amount and before Payment Discount Date.

        // 1. Setup: Change the Sales and Receivable Setup, create Payment Terms, create Customer and Currency, create General Journal Line
        // for Credit Memo and Refund, change warnings in General Ledger Setup.
        Initialize();
        CreatePaymentTerms(PaymentTerms, LibraryRandom.RandInt(10), LibraryRandom.RandDec(5, 2));
        CurrencyCode := CreateCustomerWithCurrency(Customer, PaymentTerms.Code);
        Amount := LibraryRandom.RandDec(1000, 2);  // Taking Random value for Amount.
        CreateGenJournalLine(
          GenJournalLine, Customer."No.", CurrencyCode, GenJournalLine."Document Type"::"Credit Memo", -Amount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CreateGenJournalLine(
          GenJournalLine2, Customer."No.", CurrencyCode, GenJournalLine2."Document Type"::Refund, Amount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);
        WarningsInGeneralLedgerSetup(true, false);

        // 2. Exercise: Apply and Post the Customer Ledger Entry.
        ApplyCustomerEntry(
          CustLedgerEntry2, GenJournalLine2."Document Type"::Refund,
          GenJournalLine2."Document Type"::"Credit Memo", GenJournalLine2."Document No.", GenJournalLine."Document No.");
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry2);

        // 3. Verify: Verify the Ledger Entries.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        VerifyDetldCustomerLedgerEntry(
          GenJournalLine2, DetailedCustLedgEntry."Entry Type"::"Payment Discount", -CustLedgerEntry."Original Pmt. Disc. Possible");
        VerifyLedgerEntries(GenJournalLine, GenJournalLine2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SamePaymentToleranceWarningFCY()
    var
        Currency: Record Currency;
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        CurrencyCode: Code[10];
        Amount: Decimal;
        PaymentAmount: Decimal;
    begin
        // Test the Payment Tolerance with Payment equal invoce amount and before Payment Discount Date.

        // 1. Setup: Change the Sales and Receivable Setup, create Payment Terms, create Customer and Currency, create General Journal Line
        // for Invoice and Payment, change warnings in General Ledger Setup.
        Initialize();
        CreatePaymentTerms(PaymentTerms, LibraryRandom.RandInt(10), LibraryRandom.RandDec(5, 2));
        CurrencyCode := CreateCustomerWithCurrency(Customer, PaymentTerms.Code);
        CreateCurrencyWithSetup(Currency);
        RunChangePaymentTolerance(Currency.Code, LibraryRandom.RandDec(5, 2), LibraryRandom.RandDec(10, 2));
        Amount := LibraryRandom.RandDec(1000, 2);  // Taking Random value for Amount.
        CreateGenJournalLine(GenJournalLine, Customer."No.", CurrencyCode, GenJournalLine."Document Type"::Invoice, Amount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        PaymentAmount := 2 * Amount;  // PaymentAmount atleast 2 times than Amount.
        CreateGenJournalLine(
          GenJournalLine2,
          Customer."No.", Currency.Code, GenJournalLine2."Document Type"::Payment, -PaymentAmount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);
        WarningsInGeneralLedgerSetup(false, true);

        // 2. Exercise: Apply and Post the Customer Ledger Entry.
        ApplyCustomerEntry(
          CustLedgerEntry2, GenJournalLine2."Document Type"::Payment,
          GenJournalLine2."Document Type"::Invoice, GenJournalLine2."Document No.", GenJournalLine."Document No.");
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry2);

        // 3. Verify: Verify the Ledger Entries.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        VerifyDetldCustomerLedgerEntry(
          GenJournalLine2, DetailedCustLedgEntry."Entry Type"::"Payment Discount", -CustLedgerEntry."Original Pmt. Disc. Possible");
        VerifyLedgerEntries(GenJournalLine, GenJournalLine2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PaymentToleranceWarning')]
    [Scope('OnPrem')]
    procedure LessPaymentBothWarningLCY()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        Amount: Decimal;
        PaymentAmount: Decimal;
    begin
        // Test the Payment Tolerance with Payment under invoce amount and before Payment Discount Date.

        // 1. Setup: Change the Sales and Receivable Setup, create Payment Terms, create Customer and Currency, create General Journal Line
        // for Invoice and Payment, change warnings in General Ledger Setup.
        Initialize();
        CreatePaymentTerms(PaymentTerms, LibraryRandom.RandInt(10), LibraryRandom.RandDec(5, 2));
        CreateCustomerWithCurrency(Customer, PaymentTerms.Code);
        Amount := LibraryRandom.RandDec(1000, 2);  // Taking Random value for Amount.
        CreateGenJournalLine(GenJournalLine, Customer."No.", '', GenJournalLine."Document Type"::Invoice, Amount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        PaymentAmount := Amount - LibraryRandom.RandInt(10);  // Taking Random value for Amount.
        CreateGenJournalLine(
          GenJournalLine2, Customer."No.", '', GenJournalLine2."Document Type"::Payment, -PaymentAmount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);
        WarningsInGeneralLedgerSetup(true, true);

        // 2. Exercise: Apply and Post the Customer Ledger Entry.
        ApplyCustomerEntry(
          CustLedgerEntry2, GenJournalLine2."Document Type"::Payment,
          GenJournalLine2."Document Type"::Invoice, GenJournalLine2."Document No.", GenJournalLine."Document No.");
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry2);

        // 3. Verify: Verify the Ledger Entries.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        VerifyDetldCustomerLedgerEntry(
          GenJournalLine2, DetailedCustLedgEntry."Entry Type"::"Payment Discount", -CustLedgerEntry."Original Pmt. Disc. Possible");
        VerifyLedgerEntries(GenJournalLine, GenJournalLine2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PaymentToleranceWarning')]
    [Scope('OnPrem')]
    procedure LessPaymentDiscountWarningFCY()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        CurrencyCode: Code[10];
        Amount: Decimal;
        RefundAmount: Decimal;
    begin
        // Test the Payment Tolerance with Payment under invoce amount and before Payment Discount Date.

        // 1. Setup: Change the Sales and Receivable Setup, create Payment Terms, create Customer and Currency, create General Journal Line
        // for Credit Memo and Refund, change warnings in General Ledger Setup.
        Initialize();
        CreatePaymentTerms(PaymentTerms, LibraryRandom.RandInt(10), LibraryRandom.RandDec(5, 2));
        CurrencyCode := CreateCustomerWithCurrency(Customer, PaymentTerms.Code);
        Amount := LibraryRandom.RandDec(500, 2);  // Taking Random value for Amount.
        CreateGenJournalLine(
          GenJournalLine, Customer."No.", CurrencyCode, GenJournalLine."Document Type"::"Credit Memo", -Amount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        RefundAmount := Amount - LibraryRandom.RandInt(10);  // Taking Random value for Amount.
        CreateGenJournalLine(
          GenJournalLine2,
          Customer."No.", CurrencyCode, GenJournalLine2."Document Type"::Refund, RefundAmount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);
        WarningsInGeneralLedgerSetup(true, false);

        // 2. Exercise: Apply and Post the Customer Ledger Entry.
        ApplyCustomerEntry(
          CustLedgerEntry2, GenJournalLine2."Document Type"::Refund,
          GenJournalLine2."Document Type"::"Credit Memo", GenJournalLine2."Document No.", GenJournalLine."Document No.");
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry2);

        // 3. Verify: Verify the Ledger Entries.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        VerifyDetldCustomerLedgerEntry(
          GenJournalLine2, DetailedCustLedgEntry."Entry Type"::"Payment Discount", -CustLedgerEntry."Original Pmt. Disc. Possible");
        VerifyLedgerEntries(GenJournalLine, GenJournalLine2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure LessPaymentToleranceWarningFCY()
    var
        Currency: Record Currency;
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        CurrencyCode: Code[10];
        Amount: Decimal;
        PaymentAmount: Decimal;
    begin
        // Test the Payment Tolerance with Payment under invoce amount and before Payment Discount Date.

        // 1. Setup: Change the Sales and Receivable Setup, create Payment Terms, create Customer and Currency, create General Journal Line
        // for Invoice and Payment, change warnings in General Ledger Setup.
        Initialize();
        CreatePaymentTerms(PaymentTerms, LibraryRandom.RandInt(10), LibraryRandom.RandDec(5, 2));
        CurrencyCode := CreateCustomerWithCurrency(Customer, PaymentTerms.Code);
        CreateCurrencyWithSetup(Currency);
        RunChangePaymentTolerance(Currency.Code, LibraryRandom.RandDec(5, 2), LibraryRandom.RandDec(10, 2));
        Amount := LibraryRandom.RandDec(1000, 2);  // Taking Random value for Amount.
        CreateGenJournalLine(
          GenJournalLine, Customer."No.", CurrencyCode, GenJournalLine."Document Type"::Invoice, Amount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        PaymentAmount := 2 * Amount - LibraryRandom.RandInt(10);  // Taking Random value for Amount.
        CreateGenJournalLine(
          GenJournalLine2,
          Customer."No.", Currency.Code, GenJournalLine2."Document Type"::Payment, -PaymentAmount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);
        WarningsInGeneralLedgerSetup(false, true);

        // 2. Exercise: Apply and Post the Customer Ledger Entry.
        ApplyCustomerEntry(
          CustLedgerEntry2, GenJournalLine2."Document Type"::Payment,
          GenJournalLine2."Document Type"::Invoice, GenJournalLine2."Document No.", GenJournalLine."Document No.");
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry2);

        // 3. Verify: Verify the Ledger Entries.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        VerifyDetldCustomerLedgerEntry(
          GenJournalLine2, DetailedCustLedgEntry."Entry Type"::"Payment Discount", -CustLedgerEntry."Original Pmt. Disc. Possible");
        VerifyLedgerEntries(GenJournalLine, GenJournalLine2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PaymentToleranceWarning')]
    [Scope('OnPrem')]
    procedure UnderDiscDateBothWarningLCY()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        Amount: Decimal;
        PaymentAmount: Decimal;
    begin
        // Test the Payment Tolerance with Payment under invoce amount and before Payment Discount Date.

        // 1. Setup: Change the Sales and Receivable Setup, create Payment Terms, create Customer and Currency, create General Journal Line
        // for Invoice and Payment, change warnings in General Ledger Setup.
        Initialize();
        CreatePaymentTerms(PaymentTerms, LibraryRandom.RandInt(10), LibraryRandom.RandDec(5, 2));
        CreateCustomerWithCurrency(Customer, PaymentTerms.Code);
        Amount := LibraryRandom.RandDec(1000, 2);  // Taking Random value for Amount.
        CreateGenJournalLine(GenJournalLine, Customer."No.", '', GenJournalLine."Document Type"::Invoice, Amount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        PaymentAmount := Amount - ((Amount * PaymentTerms."Discount %") / 100) + GetMaxTolerancePaymentAmount() / 2;
        CreateGenJournalLine(
          GenJournalLine2, Customer."No.", '', GenJournalLine2."Document Type"::Payment, -PaymentAmount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);
        WarningsInGeneralLedgerSetup(true, true);
        OptionValue := 0;  // Assign Global Variable for Page Handler.

        // 2. Exercise: Apply and Post the Customer Ledger Entry.
        ApplyCustomerEntry(
          CustLedgerEntry2, GenJournalLine2."Document Type"::Payment,
          GenJournalLine2."Document Type"::Invoice, GenJournalLine2."Document No.", GenJournalLine."Document No.");
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry2);

        // 3. Verify: Verify the Ledger Entries.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        VerifyDetldCustomerLedgerEntry(
          GenJournalLine2, DetailedCustLedgEntry."Entry Type"::"Payment Discount", -CustLedgerEntry."Original Pmt. Disc. Possible");
        VerifyDetldCustomerLedgerEntry(
          GenJournalLine2, DetailedCustLedgEntry."Entry Type"::"Payment Tolerance", Round(GetMaxTolerancePaymentAmount() / 2, 0.01, '='));
        VerifyLedgerEntries(GenJournalLine, GenJournalLine2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PaymentToleranceWarning')]
    [Scope('OnPrem')]
    procedure UnderDiscDateDiscWarningFCY()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        CurrencyCode: Code[10];
        Amount: Decimal;
        RefundAmount: Decimal;
        MaxPaymentTolerance: Decimal;
    begin
        // Test the Payment Tolerance with Payment under invoce amount and before Payment Discount Date.

        // 1. Setup: Change the Sales and Receivable Setup, create Payment Terms, create Customer and Currency, create General Journal Line
        // for Credit Memo and Refund, change warnings in General Ledger Setup.
        Initialize();
        CreatePaymentTerms(PaymentTerms, LibraryRandom.RandInt(10), LibraryRandom.RandDec(5, 2));
        CurrencyCode := CreateCustomerWithCurrency(Customer, PaymentTerms.Code);
        Amount := LibraryRandom.RandDec(1000, 2);  // Taking Random value for Amount.
        CreateGenJournalLine(
          GenJournalLine, Customer."No.", CurrencyCode, GenJournalLine."Document Type"::"Credit Memo", -Amount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", GenJournalLine."Document No.");
        CustLedgerEntry.CalcFields(Amount);
        MaxPaymentTolerance := Abs(CustLedgerEntry."Max. Payment Tolerance");
        RefundAmount := Abs(CustLedgerEntry.Amount) - Abs(CustLedgerEntry."Remaining Pmt. Disc. Possible") + MaxPaymentTolerance;
        CreateGenJournalLine(
          GenJournalLine2,
          Customer."No.", CurrencyCode, GenJournalLine2."Document Type"::Refund, RefundAmount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);
        WarningsInGeneralLedgerSetup(true, false);
        OptionValue := 0;  // Assign Global Variable for Page Handler.

        // 2. Exercise: Apply and Post the Customer Ledger Entry.
        ApplyCustomerEntry(
          CustLedgerEntry2, GenJournalLine2."Document Type"::Refund,
          GenJournalLine2."Document Type"::"Credit Memo", GenJournalLine2."Document No.", GenJournalLine."Document No.");
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry2);

        // 3. Verify: Verify the Ledger Entries.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        VerifyDetldCustomerLedgerEntry(
          GenJournalLine2, DetailedCustLedgEntry."Entry Type"::"Payment Discount", -CustLedgerEntry."Original Pmt. Disc. Possible");
        VerifyDetldCustomerLedgerEntry(
          GenJournalLine2, DetailedCustLedgEntry."Entry Type"::"Payment Tolerance", -MaxPaymentTolerance);
        VerifyLedgerEntries(GenJournalLine, GenJournalLine2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UnderDiscDateTolWarningFCY()
    var
        Currency: Record Currency;
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        CurrencyCode: Code[10];
        Amount: Decimal;
        PaymentAmount: Decimal;
    begin
        // Test the Payment Tolerance with Payment under invoce amount and before Payment Discount Date.

        // 1. Setup: Change the Sales and Receivable Setup, create Payment Terms, create Customer and Currency, create General Journal Line
        // for Invoice and Payment, change warnings in General Ledger Setup.
        Initialize();
        CreatePaymentTerms(PaymentTerms, LibraryRandom.RandInt(10), LibraryRandom.RandDec(5, 2));
        CurrencyCode := CreateCustomerWithCurrency(Customer, PaymentTerms.Code);
        CreateCurrencyWithSetup(Currency);
        RunChangePaymentTolerance(Currency.Code, LibraryRandom.RandDec(5, 2), LibraryRandom.RandDec(10, 2));
        Amount := LibraryRandom.RandDec(1000, 2);  // Taking Random value for Amount.
        CreateGenJournalLine(
          GenJournalLine, Customer."No.", CurrencyCode, GenJournalLine."Document Type"::Invoice, Amount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        PaymentAmount := Amount - ((Amount * PaymentTerms."Discount %") / 100) + GetMaxTolerancePaymentAmount();
        CreateGenJournalLine(
          GenJournalLine2, Customer."No.", Currency.Code, GenJournalLine2."Document Type"::Payment, -PaymentAmount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);
        WarningsInGeneralLedgerSetup(false, true);

        // 2. Exercise: Apply and Post the Customer Ledger Entry.
        ApplyCustomerEntry(
          CustLedgerEntry2, GenJournalLine2."Document Type"::Payment,
          GenJournalLine2."Document Type"::Invoice, GenJournalLine2."Document No.", GenJournalLine."Document No.");
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry2);

        // 3. Verify: Verify the Ledger Entries.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        VerifyDetldCustomerLedgerEntry(
          GenJournalLine2, DetailedCustLedgEntry."Entry Type"::"Payment Discount", -CustLedgerEntry."Original Pmt. Disc. Possible");
        VerifyLedgerEntries(GenJournalLine, GenJournalLine2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PaymentToleranceWarning')]
    [Scope('OnPrem')]
    procedure UnderTolDateBothWarningLCY()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        PaymentTerms: Record "Payment Terms";
        Amount: Decimal;
        PaymentAmount: Decimal;
    begin
        // Test the Payment Tolerance with Payment under invoce amount and before Payment Discount Date.

        // 1. Setup: Change the Sales and Receivable Setup, create Payment Terms, create Customer and Currency, create General Journal Line
        // for Invoice and Payment, change warnings in General Ledger Setup.
        Initialize();
        CreatePaymentTerms(PaymentTerms, LibraryRandom.RandInt(10), LibraryRandom.RandDec(5, 2));
        CreateCustomerWithCurrency(Customer, PaymentTerms.Code);
        Amount := LibraryRandom.RandDec(1000, 2);  // Taking Random value for Amount.
        CreateGenJournalLine(GenJournalLine, Customer."No.", '', GenJournalLine."Document Type"::Invoice, Amount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        PaymentAmount := Amount - 2 * LibraryRandom.RandInt(50);
        CreateGenJournalLine(
          GenJournalLine2,
          Customer."No.", '', GenJournalLine2."Document Type"::Payment, -PaymentAmount,
          CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);
        WarningsInGeneralLedgerSetup(true, true);

        // 2. Exercise: Apply and Post the Customer Ledger Entry.
        ApplyCustomerEntry(
          CustLedgerEntry, GenJournalLine2."Document Type"::Payment,
          GenJournalLine2."Document Type"::Invoice, GenJournalLine2."Document No.", GenJournalLine."Document No.");
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);

        // 3. Verify: Verify the Ledger Entries.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
        DetailedCustLedgEntry.FindSet();

        DetailedCustLedgEntry.TestField("Entry Type", DetailedCustLedgEntry."Entry Type"::"Initial Entry");
        DetailedCustLedgEntry.TestField(Amount, Amount);
        DetailedCustLedgEntry.Next();
        DetailedCustLedgEntry.TestField("Entry Type", DetailedCustLedgEntry."Entry Type"::Application);
        DetailedCustLedgEntry.TestField(Amount, -Amount);

        CustLedgerEntry.Reset();
        DetailedCustLedgEntry.Reset();
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine2."Document Type", GenJournalLine2."Document No.");
        DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
        DetailedCustLedgEntry.FindSet();
        DetailedCustLedgEntry.TestField("Entry Type", DetailedCustLedgEntry."Entry Type"::"Initial Entry");
        DetailedCustLedgEntry.TestField(Amount, -PaymentAmount);
        DetailedCustLedgEntry.Next(3);
        // Skips two because the sum of payment discount + tolerance adds up to the difference between amount and payment amount
        DetailedCustLedgEntry.TestField("Entry Type", DetailedCustLedgEntry."Entry Type"::Application);
        DetailedCustLedgEntry.TestField(Amount, Amount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PaymentToleranceWarning')]
    [Scope('OnPrem')]
    procedure UnderTolDateDiscWarningFCY()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        PaymentTerms: Record "Payment Terms";
        CurrencyCode: Code[10];
        Amount: Decimal;
        RefundAmount: Decimal;
    begin
        // Test the Payment Tolerance with Payment under invoce amount and before Payment Discount Date.

        // 1. Setup: Change the Sales and Receivable Setup, create Payment Terms, create Customer and Currency, create General Journal Line
        // for Credit Memo and Refund, change warnings in General Ledger Setup.
        Initialize();
        CreatePaymentTerms(PaymentTerms, LibraryRandom.RandInt(10), LibraryRandom.RandDec(5, 2));
        CurrencyCode := CreateCustomerWithCurrency(Customer, PaymentTerms.Code);
        Amount := LibraryRandom.RandDec(1000, 2);  // Taking Random value for Amount.
        CreateGenJournalLine(
          GenJournalLine, Customer."No.", CurrencyCode, GenJournalLine."Document Type"::"Credit Memo", -Amount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        RefundAmount := Amount - 2 * LibraryRandom.RandInt(50);  // Taking Random value for Amount.
        CreateGenJournalLine(
          GenJournalLine2,
          Customer."No.", CurrencyCode, GenJournalLine2."Document Type"::Refund, RefundAmount,
          CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);
        WarningsInGeneralLedgerSetup(true, false);

        // 2. Exercise: Apply and Post the Customer Ledger Entry.
        ApplyCustomerEntry(
          CustLedgerEntry, GenJournalLine2."Document Type"::Refund,
          GenJournalLine2."Document Type"::"Credit Memo", GenJournalLine2."Document No.", GenJournalLine."Document No.");
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);

        // 3. Verify: Verify the Ledger Entries.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
        DetailedCustLedgEntry.FindSet();

        DetailedCustLedgEntry.TestField("Entry Type", DetailedCustLedgEntry."Entry Type"::"Initial Entry");
        DetailedCustLedgEntry.TestField(Amount, -Amount);
        DetailedCustLedgEntry.Next();
        DetailedCustLedgEntry.TestField("Entry Type", DetailedCustLedgEntry."Entry Type"::Application);
        DetailedCustLedgEntry.TestField(Amount, Amount);

        CustLedgerEntry.Reset();
        DetailedCustLedgEntry.Reset();
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine2."Document Type", GenJournalLine2."Document No.");
        DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
        DetailedCustLedgEntry.FindSet();
        DetailedCustLedgEntry.TestField("Entry Type", DetailedCustLedgEntry."Entry Type"::"Initial Entry");
        DetailedCustLedgEntry.TestField(Amount, RefundAmount);
        DetailedCustLedgEntry.Next(3);
        // Skips two because the sum of payment discount + tolerance adds up to the difference between amount and refund amount
        DetailedCustLedgEntry.TestField("Entry Type", DetailedCustLedgEntry."Entry Type"::Application);
        DetailedCustLedgEntry.TestField(Amount, -Amount);
    end;


    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UnderTolDateTolWarningFCY()
    var
        Currency: Record Currency;
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        CurrencyCode: Code[10];
        Amount: Decimal;
        PaymentAmount: Decimal;
    begin
        // Test the Payment Tolerance with Payment under invoce amount and before Payment Discount Date.

        // 1. Setup: Change the Sales and Receivable Setup, create Payment Terms, create Customer and Currency, create General Journal Line
        // for Invoice and Payment, change warnings in General Ledger Setup.
        Initialize();
        CreatePaymentTerms(PaymentTerms, LibraryRandom.RandInt(10), LibraryRandom.RandDec(5, 2));
        CurrencyCode := CreateCustomerWithCurrency(Customer, PaymentTerms.Code);
        CreateCurrencyWithSetup(Currency);
        RunChangePaymentTolerance(Currency.Code, LibraryRandom.RandDec(5, 2), LibraryRandom.RandDec(10, 2));
        Amount := LibraryRandom.RandDec(1000, 2);  // Taking Random value for Amount.
        CreateGenJournalLine(GenJournalLine, Customer."No.", CurrencyCode, GenJournalLine."Document Type"::Invoice, Amount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        PaymentAmount := 2 * Amount - 2 * LibraryRandom.RandInt(50);  // Taking Random value for Amount.
        CreateGenJournalLine(
          GenJournalLine2, Customer."No.", Currency.Code,
          GenJournalLine2."Document Type"::Payment, -PaymentAmount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);
        WarningsInGeneralLedgerSetup(false, true);

        // 2. Exercise: Apply and Post the Customer Ledger Entry.
        ApplyCustomerEntry(
          CustLedgerEntry, GenJournalLine2."Document Type"::Payment,
          GenJournalLine2."Document Type"::Invoice, GenJournalLine2."Document No.", GenJournalLine."Document No.");
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);

        // 3. Verify: Verify the Ledger Entries.
        VerifyLedgerEntries(GenJournalLine, GenJournalLine2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ToleranceWarningPageHandler')]
    [Scope('OnPrem')]
    procedure OverPaymentTolBothWarningLCY()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        Amount: Decimal;
        PaymentAmount: Decimal;
    begin
        // Test the Payment Tolerance with Payment less what is owed but not within Tolerance and before Payment Discount Date.

        // 1. Setup: Change the Sales and Receivable Setup, create Payment Terms, create Customer and Currency, create General Journal Line
        // for Invoice and Payment, change warnings in General Ledger Setup.
        Initialize();
        CreatePaymentTerms(PaymentTerms, LibraryRandom.RandInt(10), LibraryRandom.RandDec(5, 2));
        CreateCustomerWithCurrency(Customer, PaymentTerms.Code);
        Amount := LibraryRandom.RandDec(1000, 2);  // Taking Random value for Amount.
        CreateGenJournalLine(GenJournalLine, Customer."No.", '', GenJournalLine."Document Type"::Invoice, Amount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        PaymentAmount := Amount + LibraryRandom.RandInt(10);  // Taking Random value for Amount.
        CreateGenJournalLine(GenJournalLine2, Customer."No.", '', GenJournalLine2."Document Type"::Payment, -PaymentAmount,
          CalcDate('<1D>', CalcDate(PaymentTerms."Discount Date Calculation", WorkDate())));
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);
        WarningsInGeneralLedgerSetup(true, true);

        // 2. Exercise: Apply and Post the Customer Ledger Entry.
        ApplyCustomerEntry(
          CustLedgerEntry2, GenJournalLine2."Document Type"::Payment,
          GenJournalLine2."Document Type"::Invoice, GenJournalLine2."Document No.", GenJournalLine."Document No.");
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry2);

        // 3. Verify: Verify the Ledger Entries.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        VerifyDetldCustomerLedgerEntry(
          GenJournalLine2,
          DetailedCustLedgEntry."Entry Type"::"Payment Discount Tolerance", -CustLedgerEntry."Original Pmt. Disc. Possible");
        VerifyLedgerEntries(GenJournalLine, GenJournalLine2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure OverPaymentTolDiscWarningFCY()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        CurrencyCode: Code[10];
        Amount: Decimal;
        RefundAmount: Decimal;
    begin
        // Test the Payment Tolerance with Payment less what is owed but not within Tolerance and before Payment Discount Date.

        // 1. Setup: Change the Sales and Receivable Setup, create Payment Terms, create Customer and Currency, create General Journal Line
        // for Credit Memo and Refund, change warnings in General Ledger Setup.
        Initialize();
        CreatePaymentTerms(PaymentTerms, LibraryRandom.RandInt(10), LibraryRandom.RandDec(5, 2));
        CurrencyCode := CreateCustomerWithCurrency(Customer, PaymentTerms.Code);
        Amount := LibraryRandom.RandDec(1000, 2);  // Taking Random value for Amount.
        CreateGenJournalLine(
          GenJournalLine, Customer."No.", CurrencyCode, GenJournalLine."Document Type"::"Credit Memo", -Amount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        RefundAmount := Amount + LibraryRandom.RandInt(10);  // Taking Random value for Amount.
        CreateGenJournalLine(
          GenJournalLine2, Customer."No.", CurrencyCode, GenJournalLine2."Document Type"::Refund, RefundAmount,
          CalcDate('<1D>', CalcDate(PaymentTerms."Discount Date Calculation", WorkDate())));
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);
        WarningsInGeneralLedgerSetup(true, false);

        // 2. Exercise: Apply and Post the Customer Ledger Entry.
        ApplyCustomerEntry(
          CustLedgerEntry2, GenJournalLine2."Document Type"::Refund,
          GenJournalLine2."Document Type"::"Credit Memo", GenJournalLine2."Document No.", GenJournalLine."Document No.");
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry2);

        // 3. Verify: Verify the Ledger Entries.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        VerifyDetldCustomerLedgerEntry(
          GenJournalLine2,
          DetailedCustLedgEntry."Entry Type"::"Payment Discount Tolerance", -CustLedgerEntry."Original Pmt. Disc. Possible");
        VerifyLedgerEntries(GenJournalLine, GenJournalLine2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ToleranceWarningPageHandler')]
    [Scope('OnPrem')]
    procedure OverPaymentTolAndTolWarningFCY()
    var
        Currency: Record Currency;
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        CurrencyCode: Code[10];
        Amount: Decimal;
        PaymentAmount: Decimal;
    begin
        // Test the Payment Tolerance with Payment less what is owed but not within Tolerance and before Payment Discount Date.

        // 1. Setup: Change the Sales and Receivable Setup, create Payment Terms, create Customer and Currency, create General Journal Line
        // for Invoice and Payment, change warnings in General Ledger Setup.
        Initialize();
        CreatePaymentTerms(PaymentTerms, LibraryRandom.RandInt(10), LibraryRandom.RandDec(5, 2));
        CurrencyCode := CreateCustomerWithCurrency(Customer, PaymentTerms.Code);
        CreateCurrencyWithSetup(Currency);
        RunChangePaymentTolerance(Currency.Code, LibraryRandom.RandDec(5, 2), LibraryRandom.RandDec(10, 2));
        Amount := LibraryRandom.RandDec(1000, 2);  // Taking Random value for Amount.
        CreateGenJournalLine(GenJournalLine, Customer."No.", CurrencyCode, GenJournalLine."Document Type"::Invoice, Amount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        PaymentAmount := 2 * Amount + LibraryRandom.RandInt(100);  // Taking Random value for Amount.
        CreateGenJournalLine(GenJournalLine2, Customer."No.", Currency.Code, GenJournalLine2."Document Type"::Payment, -PaymentAmount,
          CalcDate('<1D>', CalcDate(PaymentTerms."Discount Date Calculation", WorkDate())));
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);
        WarningsInGeneralLedgerSetup(false, true);

        // 2. Exercise: Apply and Post the Customer Ledger Entry.
        ApplyCustomerEntry(
          CustLedgerEntry2, GenJournalLine2."Document Type"::Payment,
          GenJournalLine2."Document Type"::Invoice, GenJournalLine2."Document No.", GenJournalLine."Document No.");
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry2);

        // 3. Verify: Verify the Ledger Entries.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        VerifyDetldCustomerLedgerEntry(
          GenJournalLine2,
          DetailedCustLedgEntry."Entry Type"::"Payment Discount Tolerance", -CustLedgerEntry."Original Pmt. Disc. Possible");
        VerifyLedgerEntries(GenJournalLine, GenJournalLine2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ToleranceWarningPageHandler')]
    [Scope('OnPrem')]
    procedure SamePaymentTolBothWarningLCY()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        Amount: Decimal;
    begin
        // Test the Payment Tolerance with Over Payment and within Payment Tolerance Date.

        // 1. Setup: Change the Sales and Receivable Setup, create Payment Terms, create Customer and Currency, create General Journal Line
        // for Invoice and Payment, change warnings in General Ledger Setup.
        Initialize();
        CreatePaymentTerms(PaymentTerms, LibraryRandom.RandInt(10), LibraryRandom.RandDec(5, 2));
        CreateCustomerWithCurrency(Customer, PaymentTerms.Code);
        Amount := LibraryRandom.RandDec(1000, 2);  // Taking Random value for Amount.
        CreateGenJournalLine(GenJournalLine, Customer."No.", '', GenJournalLine."Document Type"::Invoice, Amount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CreateGenJournalLine(GenJournalLine2, Customer."No.", '', GenJournalLine2."Document Type"::Payment, -Amount,
          CalcDate('<1D>', CalcDate(PaymentTerms."Discount Date Calculation", WorkDate())));
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);
        WarningsInGeneralLedgerSetup(true, true);
        OptionValue := 0;  // Assign Global Variable for Page Handler.

        // 2. Exercise: Apply and Post the Customer Ledger Entry.
        ApplyCustomerEntry(
          CustLedgerEntry2, GenJournalLine2."Document Type"::Payment,
          GenJournalLine2."Document Type"::Invoice, GenJournalLine2."Document No.", GenJournalLine."Document No.");
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry2);

        // 3. Verify: Verify the Ledger Entries.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        VerifyDetldCustomerLedgerEntry(
          GenJournalLine2,
          DetailedCustLedgEntry."Entry Type"::"Payment Discount Tolerance", -CustLedgerEntry."Original Pmt. Disc. Possible");
        VerifyLedgerEntries(GenJournalLine, GenJournalLine2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SamePaymentTolDiscWarningFCY()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        CurrencyCode: Code[10];
        Amount: Decimal;
    begin
        // Test the Payment Tolerance with Over Payment and within Payment Tolerance Date.

        // 1. Setup: Change the Sales and Receivable Setup, create Payment Terms, create Customer and Currency, create General Journal Line
        // for Credit Memo and Refund, change warnings in General Ledger Setup.
        Initialize();
        CreatePaymentTerms(PaymentTerms, LibraryRandom.RandInt(10), LibraryRandom.RandDec(5, 2));
        CurrencyCode := CreateCustomerWithCurrency(Customer, PaymentTerms.Code);
        Amount := LibraryRandom.RandDec(1000, 2);  // Taking Random value for Amount.
        CreateGenJournalLine(
          GenJournalLine, Customer."No.", CurrencyCode, GenJournalLine."Document Type"::"Credit Memo", -Amount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", GenJournalLine."Document No.");
        CreateGenJournalLine(GenJournalLine2, Customer."No.", CurrencyCode, GenJournalLine2."Document Type"::Refund, Amount,
          CalcDate('<1D>', CalcDate(PaymentTerms."Discount Date Calculation", WorkDate())));
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);
        WarningsInGeneralLedgerSetup(true, false);
        OptionValue := 0;  // Assign Global Variable for Page Handler.

        // 2. Exercise: Apply and Post the Customer Ledger Entry.
        ApplyCustomerEntry(
          CustLedgerEntry2, GenJournalLine2."Document Type"::Refund,
          GenJournalLine2."Document Type"::"Credit Memo", GenJournalLine2."Document No.", GenJournalLine."Document No.");
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry2);

        // 3. Verify: Verify the Ledger Entries.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        VerifyDetldCustomerLedgerEntry(
          GenJournalLine2,
          DetailedCustLedgEntry."Entry Type"::"Payment Discount Tolerance", -CustLedgerEntry."Original Pmt. Disc. Possible");
        VerifyLedgerEntries(GenJournalLine, GenJournalLine2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ToleranceWarningPageHandler')]
    [Scope('OnPrem')]
    procedure SamePaymentTolAndTolWarningFCY()
    var
        Currency: Record Currency;
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        CurrencyCode: Code[10];
        Amount: Decimal;
    begin
        // Test the Payment Tolerance with Over Payment and within Payment Tolerance Date.

        // 1. Setup: Change the Sales and Receivable Setup, create Payment Terms, create Customer and Currency, create General Journal Line
        // for Invoice and Payment, change warnings in General Ledger Setup.
        Initialize();
        CreatePaymentTerms(PaymentTerms, LibraryRandom.RandInt(10), LibraryRandom.RandDec(5, 2));
        CurrencyCode := CreateCustomerWithCurrency(Customer, PaymentTerms.Code);
        CreateCurrencyWithSetup(Currency);
        RunChangePaymentTolerance(Currency.Code, LibraryRandom.RandDec(5, 2), LibraryRandom.RandDec(10, 2));
        Amount := LibraryRandom.RandDec(1000, 2);  // Taking Random value for Amount.
        CreateGenJournalLine(GenJournalLine, Customer."No.", CurrencyCode, GenJournalLine."Document Type"::Invoice, Amount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CreateGenJournalLine(
          GenJournalLine2, Customer."No.", Currency.Code, GenJournalLine2."Document Type"::Payment, -Amount,
          CalcDate('<1D>', CalcDate(PaymentTerms."Discount Date Calculation", WorkDate())));
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);
        WarningsInGeneralLedgerSetup(false, true);

        // 2. Exercise: Apply and Post the Customer Ledger Entry.
        ApplyCustomerEntry(
          CustLedgerEntry2, GenJournalLine2."Document Type"::Payment,
          GenJournalLine2."Document Type"::Invoice, GenJournalLine2."Document No.", GenJournalLine."Document No.");
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry2);

        // 3. Verify: Verify the Ledger Entries.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        VerifyDetldCustomerLedgerEntry(
          GenJournalLine2,
          DetailedCustLedgEntry."Entry Type"::"Payment Discount Tolerance", -CustLedgerEntry."Original Pmt. Disc. Possible");
        VerifyLedgerEntries(GenJournalLine, GenJournalLine2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ToleranceWarningPageHandler,PaymentToleranceWarning')]
    [Scope('OnPrem')]
    procedure LessPaymentTolBothWarningLCY()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        Amount: Decimal;
        PaymentAmount: Decimal;
    begin
        // Test the Payment Tolerance with Payment equal invoice amount and within Payment Tolerance Date.

        // 1. Setup: Change the Sales and Receivable Setup, create Payment Terms, create Customer and Currency, create General Journal Line
        // for Invoice and Payment, change warnings in General Ledger Setup.
        Initialize();
        CreatePaymentTerms(PaymentTerms, LibraryRandom.RandInt(10), LibraryRandom.RandDec(5, 2));
        CreateCustomerWithCurrency(Customer, PaymentTerms.Code);
        Amount := LibraryRandom.RandDec(1000, 2);  // Taking Random value for Amount.
        CreateGenJournalLine(GenJournalLine, Customer."No.", '', GenJournalLine."Document Type"::Invoice, Amount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        PaymentAmount := Amount - LibraryRandom.RandInt(5);  // Taking Random value for Amount.
        CreateGenJournalLine(GenJournalLine2, Customer."No.", '', GenJournalLine2."Document Type"::Payment, -PaymentAmount,
          CalcDate('<1D>', CalcDate(PaymentTerms."Discount Date Calculation", WorkDate())));
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);
        WarningsInGeneralLedgerSetup(true, true);

        // 2. Exercise: Apply and Post the Customer Ledger Entry.
        ApplyCustomerEntry(
          CustLedgerEntry2, GenJournalLine2."Document Type"::Payment,
          GenJournalLine2."Document Type"::Invoice, GenJournalLine2."Document No.", GenJournalLine."Document No.");
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry2);

        // 3. Verify: Verify the Ledger Entries.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        VerifyDetldCustomerLedgerEntry(
          GenJournalLine2,
          DetailedCustLedgEntry."Entry Type"::"Payment Discount Tolerance", -CustLedgerEntry."Original Pmt. Disc. Possible");
        VerifyLedgerEntries(GenJournalLine, GenJournalLine2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure LessPaymentTolDiscWarningFCY()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        CurrencyCode: Code[10];
        Amount: Decimal;
        RefundAmount: Decimal;
    begin
        // Test the Payment Tolerance with Payment equal invoice amount and within Payment Tolerance Date.

        // 1. Setup: Change the Sales and Receivable Setup, create Payment Terms, create Customer and Currency, create General Journal Line
        // for Credit Memo and Refund, change warnings in General Ledger Setup.
        Initialize();
        CreatePaymentTerms(PaymentTerms, LibraryRandom.RandInt(10), LibraryRandom.RandDec(5, 2));
        CurrencyCode := CreateCustomerWithCurrency(Customer, PaymentTerms.Code);
        Amount := LibraryRandom.RandDec(1000, 2);  // Taking Random value for Amount.
        CreateGenJournalLine(
          GenJournalLine, Customer."No.", CurrencyCode, GenJournalLine."Document Type"::"Credit Memo", -Amount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", GenJournalLine."Document No.");
        RefundAmount := Amount - LibraryRandom.RandInt(5);  // Taking Random value for Amount.
        CreateGenJournalLine(GenJournalLine2, Customer."No.", CurrencyCode, GenJournalLine2."Document Type"::Refund, RefundAmount,
          CalcDate('<1D>', CalcDate(PaymentTerms."Discount Date Calculation", WorkDate())));
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);
        WarningsInGeneralLedgerSetup(true, false);

        // 2. Exercise: Apply and Post the Customer Ledger Entry.
        ApplyCustomerEntry(
          CustLedgerEntry2, GenJournalLine2."Document Type"::Refund,
          GenJournalLine2."Document Type"::"Credit Memo", GenJournalLine2."Document No.", GenJournalLine."Document No.");
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry2);

        // 3. Verify: Verify the Ledger Entries.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        VerifyDetldCustomerLedgerEntry(
          GenJournalLine2,
          DetailedCustLedgEntry."Entry Type"::"Payment Discount Tolerance", -CustLedgerEntry."Original Pmt. Disc. Possible");
        VerifyLedgerEntries(GenJournalLine, GenJournalLine2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ToleranceWarningPageHandler')]
    [Scope('OnPrem')]
    procedure LessPaymentTolAndTolWarningFCY()
    var
        Currency: Record Currency;
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        CurrencyCode: Code[10];
        Amount: Decimal;
        PaymentAmount: Decimal;
    begin
        // Test the Payment Tolerance with Payment equal invoice amount and within Payment Tolerance Date.

        // 1. Setup: Change the Sales and Receivable Setup, create Payment Terms, create Customer and Currency, create General Journal Line
        // for Invoice and Payment, change warnings in General Ledger Setup.
        Initialize();
        CreatePaymentTerms(PaymentTerms, LibraryRandom.RandInt(10), LibraryRandom.RandDec(5, 2));
        CurrencyCode := CreateCustomerWithCurrency(Customer, PaymentTerms.Code);
        CreateCurrencyWithSetup(Currency);
        RunChangePaymentTolerance(Currency.Code, LibraryRandom.RandDec(5, 2), LibraryRandom.RandDec(10, 2));
        Amount := LibraryRandom.RandDec(1000, 2);  // Taking Random value for Amount.
        CreateGenJournalLine(GenJournalLine, Customer."No.", CurrencyCode, GenJournalLine."Document Type"::Invoice, Amount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        PaymentAmount := 2 * Amount - LibraryRandom.RandInt(5);  // Taking Random value for Amount.
        CreateGenJournalLine(GenJournalLine2, Customer."No.", Currency.Code, GenJournalLine2."Document Type"::Payment, -PaymentAmount,
          CalcDate('<1D>', CalcDate(PaymentTerms."Discount Date Calculation", WorkDate())));
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);
        WarningsInGeneralLedgerSetup(false, true);

        // 2. Exercise: Apply and Post the Customer Ledger Entry.
        ApplyCustomerEntry(
          CustLedgerEntry2, GenJournalLine2."Document Type"::Payment,
          GenJournalLine2."Document Type"::Invoice, GenJournalLine2."Document No.", GenJournalLine."Document No.");
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry2);

        // 3. Verify: Verify the Ledger Entries.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        VerifyDetldCustomerLedgerEntry(
          GenJournalLine2,
          DetailedCustLedgEntry."Entry Type"::"Payment Discount Tolerance", -CustLedgerEntry."Original Pmt. Disc. Possible");
        VerifyLedgerEntries(GenJournalLine, GenJournalLine2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ToleranceWarningPageHandler,PaymentToleranceWarning')]
    [Scope('OnPrem')]
    procedure LessToleranceBothWarningLCY()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        Amount: Decimal;
        PaymentAmount: Decimal;
    begin
        // Test the Payment Discount Tolerance and Payment Tolerance with positive amount and Payment Amount
        // less than and with both warnings.

        // 1. Setup: Change the Sales and Receivable Setup, create Payment Terms, create Customer and Currency, create General Journal Line
        // for Invoice and Payment, change warnings in General Ledger Setup.
        Initialize();
        CreatePaymentTerms(PaymentTerms, LibraryRandom.RandInt(10), LibraryRandom.RandDec(5, 2));
        CreateCustomerWithCurrency(Customer, PaymentTerms.Code);
        Amount := LibraryRandom.RandDec(1000, 2);  // Taking Random value for Amount.
        CreateGenJournalLine(GenJournalLine, Customer."No.", '', GenJournalLine."Document Type"::Invoice, Amount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        PaymentAmount := Amount - ((Amount * PaymentTerms."Discount %") / 100) + GetMaxTolerancePaymentAmount() / 2;
        CreateGenJournalLine(
          GenJournalLine2, Customer."No.", '', GenJournalLine2."Document Type"::Payment, -PaymentAmount,
          CalcDate('<1D>', CalcDate(PaymentTerms."Discount Date Calculation", WorkDate())));
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);
        WarningsInGeneralLedgerSetup(true, true);

        // 2. Exercise: Apply and Post the Customer Ledger Entry.
        ApplyCustomerEntry(
          CustLedgerEntry2, GenJournalLine2."Document Type"::Payment,
          GenJournalLine2."Document Type"::Invoice, GenJournalLine2."Document No.", GenJournalLine."Document No.");
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry2);

        // 3. Verify: Verify the Ledger Entries.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        VerifyDetldCustomerLedgerEntry(
          GenJournalLine2,
          DetailedCustLedgEntry."Entry Type"::"Payment Discount Tolerance", -CustLedgerEntry."Original Pmt. Disc. Possible");
        VerifyDetldCustomerLedgerEntry(
          GenJournalLine2, DetailedCustLedgEntry."Entry Type"::"Payment Tolerance", Round(GetMaxTolerancePaymentAmount() / 2, 0.01, '='));
        VerifyLedgerEntries(GenJournalLine, GenJournalLine2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure LessToleranceDiscWarningFCY()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        CurrencyCode: Code[10];
        Amount: Decimal;
        RefundAmount: Decimal;
    begin
        // Test the Payment Discount Tolerance and Payment Tolerance with positive amount and Payment Amount
        // less than Amount and with Discount warning.

        // 1. Setup: Change the Sales and Receivable Setup, create Payment Terms, create Customer and Currency, create General Journal Line
        // for Credit Memo and Refund, change warnings in General Ledger Setup.
        Initialize();
        CreatePaymentTerms(PaymentTerms, LibraryRandom.RandInt(10), LibraryRandom.RandDec(5, 2));
        CurrencyCode := CreateCustomerWithCurrency(Customer, PaymentTerms.Code);
        Amount := LibraryRandom.RandDec(1000, 2);  // Taking Random value for Amount.
        CreateGenJournalLine(GenJournalLine, Customer."No.", CurrencyCode, GenJournalLine."Document Type"::"Credit Memo", -Amount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        //LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", GenJournalLine."Document No.");
        RefundAmount := Amount - ((Amount * PaymentTerms."Discount %") / 100) + GetMaxTolerancePaymentAmount() / 2;
        CreateGenJournalLine(GenJournalLine2, Customer."No.", CurrencyCode, GenJournalLine2."Document Type"::Refund, RefundAmount,
          CalcDate('<1D>', CalcDate(PaymentTerms."Discount Date Calculation", WorkDate())));
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);
        WarningsInGeneralLedgerSetup(true, false);

        // 2. Exercise: Apply and Post the Customer Ledger Entry.
        ApplyCustomerEntry(
          CustLedgerEntry2, GenJournalLine2."Document Type"::Refund,
          GenJournalLine2."Document Type"::"Credit Memo", GenJournalLine2."Document No.", GenJournalLine."Document No.");
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry2);

        // 3. Verify: Verify the Ledger Entries.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        VerifyDetldCustomerLedgerEntry(
          GenJournalLine2,
          DetailedCustLedgEntry."Entry Type"::"Payment Discount Tolerance", -CustLedgerEntry."Original Pmt. Disc. Possible");
        VerifyDetldCustomerLedgerEntry(
          GenJournalLine2, DetailedCustLedgEntry."Entry Type"::Application, -Amount);
        VerifyLedgerEntries(GenJournalLine, GenJournalLine2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ToleranceWarningPageHandler')]
    [Scope('OnPrem')]
    procedure LessToleranceWithWarningFCY()
    var
        Currency: Record Currency;
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        CurrencyCode: Code[10];
        Amount: Decimal;
        PaymentAmount: Decimal;
        MaxPaymentTolerance: Decimal;
    begin
        // Test the Payment Discount Tolerance and Payment Tolerance with positive amount and Payment
        // Amount less than Inivoice Amount and with Tolerance warning.

        // 1. Setup: Change the Sales and Receivable Setup, create Payment Terms, create Customer and Currency, create General Journal Line
        // for Invoice and Payment, change warnings in General Ledger Setup.
        Initialize();
        CreatePaymentTerms(PaymentTerms, LibraryRandom.RandInt(10), LibraryRandom.RandDec(5, 2));
        CurrencyCode := CreateCustomerWithCurrency(Customer, PaymentTerms.Code);
        CreateCurrencyWithSetup(Currency);
        Amount := LibraryRandom.RandDec(1000, 2);  // Taking Random value for Amount.
        CreateGenJournalLine(GenJournalLine, Customer."No.", CurrencyCode, GenJournalLine."Document Type"::Invoice, Amount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, GenJournalLine."Document No.");
        CustLedgerEntry.CalcFields(Amount);
        MaxPaymentTolerance := Abs(CustLedgerEntry."Max. Payment Tolerance");
        PaymentAmount := Abs(CustLedgerEntry.Amount) - Abs(CustLedgerEntry."Remaining Pmt. Disc. Possible") + MaxPaymentTolerance;
        CreateGenJournalLine(GenJournalLine2, Customer."No.", Currency.Code, GenJournalLine2."Document Type"::Payment, -PaymentAmount,
          CalcDate('<1D>', CalcDate(PaymentTerms."Discount Date Calculation", WorkDate())));
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);
        WarningsInGeneralLedgerSetup(false, true);

        // 2. Exercise: Apply and Post the Customer Ledger Entry.
        ApplyCustomerEntry(
          CustLedgerEntry2, GenJournalLine2."Document Type"::Payment,
          GenJournalLine2."Document Type"::Invoice, GenJournalLine2."Document No.", GenJournalLine."Document No.");
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry2);

        // 3. Verify: Verify the Ledger Entries.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        VerifyDetldCustomerLedgerEntry(
          GenJournalLine2,
          DetailedCustLedgEntry."Entry Type"::"Payment Discount Tolerance", -CustLedgerEntry."Original Pmt. Disc. Possible");
        VerifyDetldCustomerLedgerEntry(
          GenJournalLine2, DetailedCustLedgEntry."Entry Type"::"Payment Tolerance", MaxPaymentTolerance);
        VerifyLedgerEntries(GenJournalLine, GenJournalLine2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ToleranceWarningPageHandler,PaymentToleranceWarning')]
    [Scope('OnPrem')]
    procedure PaymentBothWarningWithDiscount()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        Amount: Decimal;
        PaymentAmount: Decimal;
    begin
        // Test the Payment Discount Tolerance and Payment Tolerance with negative amount and Payment Amount
        // less than Inivoice Amount and with both warnings.

        // 1. Setup: Change the Sales and Receivable Setup, create Payment Terms, create Customer and Currency, create General Journal Line
        // for Invoice and Payment, change warnings in General Ledger Setup.
        Initialize();
        CreatePaymentTerms(PaymentTerms, LibraryRandom.RandInt(10), LibraryRandom.RandDec(5, 2));
        CreateCustomerWithCurrency(Customer, PaymentTerms.Code);
        Amount := LibraryRandom.RandDec(1000, 2);  // Taking Random value for Amount.
        CreateGenJournalLine(GenJournalLine, Customer."No.", '', GenJournalLine."Document Type"::Invoice, Amount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        PaymentAmount := Amount - ((Amount * PaymentTerms."Discount %") / 100) - GetMaxTolerancePaymentAmount();
        CreateGenJournalLine(
          GenJournalLine2, Customer."No.", '', GenJournalLine2."Document Type"::Payment, -PaymentAmount,
          CalcDate('<1D>', CalcDate(PaymentTerms."Discount Date Calculation", WorkDate())));
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);
        WarningsInGeneralLedgerSetup(true, true);

        // 2. Exercise: Apply and Post the Customer Ledger Entry.
        ApplyCustomerEntry(
          CustLedgerEntry2, GenJournalLine2."Document Type"::Payment,
          GenJournalLine2."Document Type"::Invoice, GenJournalLine2."Document No.", GenJournalLine."Document No.");
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry2);

        // 3. Verify: Verify the Ledger Entries.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        VerifyDetldCustomerLedgerEntry(
          GenJournalLine2,
          DetailedCustLedgEntry."Entry Type"::"Payment Discount Tolerance", -CustLedgerEntry."Original Pmt. Disc. Possible");
        VerifyDetldCustomerLedgerEntry(
          GenJournalLine2, DetailedCustLedgEntry."Entry Type"::"Payment Tolerance", -GetMaxTolerancePaymentAmount());
        VerifyLedgerEntries(GenJournalLine, GenJournalLine2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PaymentToleranceWarning')]
    [Scope('OnPrem')]
    procedure DiscountWarningWithDiscount()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        CurrencyCode: Code[10];
        Amount: Decimal;
        RefundAmount: Decimal;
        MaxPaymentTolerance: Decimal;
    begin
        // Test the Payment Discount Tolerance and Payment Tolerance with negative amount and Payment Amount
        // less than Inivoice Amount and with both warnings.

        // 1. Setup: Change the Sales and Receivable Setup, create Payment Terms, create Customer and Currency, create General Journal Line
        // for Credit Memo and Refund, change warnings in General Ledger Setup.
        Initialize();
        CreatePaymentTerms(PaymentTerms, LibraryRandom.RandInt(10), LibraryRandom.RandDec(5, 2));
        CurrencyCode := CreateCustomerWithCurrency(Customer, PaymentTerms.Code);
        Amount := LibraryRandom.RandDec(1000, 2);  // Taking Random value for Amount.
        CreateGenJournalLine(GenJournalLine, Customer."No.", CurrencyCode, GenJournalLine."Document Type"::"Credit Memo", -Amount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", GenJournalLine."Document No.");
        CustLedgerEntry.CalcFields(Amount);
        MaxPaymentTolerance := Abs(CustLedgerEntry."Max. Payment Tolerance");
        RefundAmount := Abs(CustLedgerEntry.Amount) - Abs(CustLedgerEntry."Remaining Pmt. Disc. Possible") - MaxPaymentTolerance;
        CreateGenJournalLine(GenJournalLine2, Customer."No.", CurrencyCode, GenJournalLine2."Document Type"::Refund, RefundAmount,
          CalcDate('<1D>', CalcDate(PaymentTerms."Discount Date Calculation", WorkDate())));
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);
        WarningsInGeneralLedgerSetup(true, false);

        // 2. Exercise: Apply and Post the Customer Ledger Entry.
        ApplyCustomerEntry(
          CustLedgerEntry2, GenJournalLine2."Document Type"::Refund,
          GenJournalLine2."Document Type"::"Credit Memo", GenJournalLine2."Document No.", GenJournalLine."Document No.");
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry2);

        // 3. Verify: Verify the Ledger Entries.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        VerifyDetldCustomerLedgerEntry(
          GenJournalLine2,
          DetailedCustLedgEntry."Entry Type"::"Payment Discount Tolerance", -CustLedgerEntry."Original Pmt. Disc. Possible");
        VerifyDetldCustomerLedgerEntry(
          GenJournalLine2, DetailedCustLedgEntry."Entry Type"::"Payment Tolerance", MaxPaymentTolerance);
        VerifyLedgerEntries(GenJournalLine, GenJournalLine2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PaymentTolWarningWithDiscount()
    var
        Currency: Record Currency;
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        CurrencyCode: Code[10];
        Amount: Decimal;
        PaymentAmount: Decimal;
    begin
        // Test the Payment Discount Tolerance and Payment Tolerance with negative amount and Payment Amount
        // less than Inivoice Amount and with both warnings.

        // 1. Setup: Change the Sales and Receivable Setup, create Payment Terms, create Customer and Currency, create General Journal Line
        // for Invoice and Payment, change warnings in General Ledger Setup.
        Initialize();
        CreatePaymentTerms(PaymentTerms, LibraryRandom.RandInt(10), LibraryRandom.RandDec(5, 2));
        CurrencyCode := CreateCustomerWithCurrency(Customer, PaymentTerms.Code);
        CreateCurrencyWithSetup(Currency);
        Amount := LibraryRandom.RandDec(1000, 2);  // Taking Random value for Amount.
        CreateGenJournalLine(GenJournalLine, Customer."No.", CurrencyCode, GenJournalLine."Document Type"::Invoice, Amount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        PaymentAmount := Amount - ((Amount * PaymentTerms."Discount %") / 100) - GetMaxTolerancePaymentAmount() / 2;
        CreateGenJournalLine(GenJournalLine2, Customer."No.", Currency.Code, GenJournalLine2."Document Type"::Payment, -PaymentAmount,
          CalcDate('<1D>', CalcDate(PaymentTerms."Discount Date Calculation", WorkDate())));
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);
        WarningsInGeneralLedgerSetup(false, true);

        // 2. Exercise: Apply and Post the Customer Ledger Entry.
        ApplyCustomerEntry(
          CustLedgerEntry2, GenJournalLine2."Document Type"::Payment,
          GenJournalLine2."Document Type"::Invoice, GenJournalLine2."Document No.", GenJournalLine."Document No.");
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry2);

        // 3. Verify: Verify the Ledger Entries.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        VerifyDetldCustomerLedgerEntry(
          GenJournalLine2,
          DetailedCustLedgEntry."Entry Type"::"Initial Entry", -PaymentAmount);
        VerifyDetldCustomerLedgerEntry(GenJournalLine2, DetailedCustLedgEntry."Entry Type"::"Initial Entry", GenJournalLine2.Amount);
        VerifyDetldCustomerLedgerEntry(GenJournalLine2, DetailedCustLedgEntry."Entry Type"::Application, -GenJournalLine2.Amount);
        VerifyDetldCustomerLedgerEntry(GenJournalLine, DetailedCustLedgEntry."Entry Type"::"Initial Entry", GenJournalLine.Amount);
        VerifyDetldCustomerLedgerEntry(GenJournalLine, DetailedCustLedgEntry."Entry Type"::Application, GenJournalLine2.Amount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure LessPaymentApplicationRounding()
    var
        Currency: Record Currency;
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        CurrencyCode: Code[10];
        Amount: Decimal;
        PaymentAmount: Decimal;
    begin
        // Test the Application Rounding Entry with less Payment Application Rounding and both warnings.

        // 1. Setup: Change the Sales and Receivable Setup, create Payment Terms, create Customer and Currency, create General Journal Line
        // for Credit Memo and Refund, change warnings in General Ledger Setup.
        Initialize();
        CreatePaymentTerms(PaymentTerms, LibraryRandom.RandInt(10), 0);
        CurrencyCode := CreateCustomerWithCurrency(Customer, PaymentTerms.Code);
        CreateCurrencyWithSetup(Currency);
        ApplicationRoundingInCurrency(Currency);
        RunChangePaymentTolerance(Currency.Code, LibraryRandom.RandDec(5, 2), LibraryRandom.RandDec(10, 2));
        Amount := LibraryRandom.RandDec(1000, 2);  // Taking Random value for Amount.
        CreateGenJournalLine(
          GenJournalLine, Customer."No.", CurrencyCode, GenJournalLine."Document Type"::Invoice, Amount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        PaymentAmount := LibraryERM.ConvertCurrency(Amount, CurrencyCode, Currency.Code, WorkDate()) - Currency."Appln. Rounding Precision";
        CreateGenJournalLine(
          GenJournalLine2,
          Customer."No.", Currency.Code, GenJournalLine2."Document Type"::Payment, -PaymentAmount,
          CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);
        WarningsInGeneralLedgerSetup(true, true);

        // 2. Exercise: Apply and Post the Customer Ledger Entry.
        ApplyCustomerEntry(
          CustLedgerEntry2, GenJournalLine2."Document Type"::Payment,
          GenJournalLine2."Document Type"::Invoice, GenJournalLine2."Document No.", GenJournalLine."Document No.");
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry2);

        // 3. Verify: Verify the Ledger Entries.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        VerifyDetldCustomerLedgerEntry(
          GenJournalLine2, DetailedCustLedgEntry."Entry Type"::"Appln. Rounding", -Currency."Appln. Rounding Precision");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure MorePaymentApplicationRounding()
    var
        Currency: Record Currency;
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        CurrencyCode: Code[10];
        Amount: Decimal;
        RefundAmount: Decimal;
    begin
        // Test the Application Rounding Entry with more Payment Application Rounding and both warnings.

        // 1. Setup: Change the Sales and Receivable Setup, create Payment Terms, create Customer and Currency, create General Journal Line
        // for Credit Memo and Refund, change warnings in General Ledger Setup.
        Initialize();
        CreatePaymentTerms(PaymentTerms, LibraryRandom.RandInt(10), 0);
        CurrencyCode := CreateCustomerWithCurrency(Customer, PaymentTerms.Code);
        CreateCurrencyWithSetup(Currency);
        ApplicationRoundingInCurrency(Currency);
        RunChangePaymentTolerance(Currency.Code, LibraryRandom.RandDec(5, 2), LibraryRandom.RandDec(10, 2));
        Amount := LibraryRandom.RandDec(1000, 2);  // Taking Random value for Amount.
        CreateGenJournalLine(
          GenJournalLine, Customer."No.", CurrencyCode, GenJournalLine."Document Type"::"Credit Memo", -Amount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        RefundAmount := LibraryERM.ConvertCurrency(Amount, CurrencyCode, Currency.Code, WorkDate()) + Currency."Appln. Rounding Precision";
        CreateGenJournalLine(
          GenJournalLine2,
          Customer."No.", Currency.Code, GenJournalLine2."Document Type"::Refund, RefundAmount,
          CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);
        WarningsInGeneralLedgerSetup(true, true);

        // 2. Exercise: Apply and Post the Customer Ledger Entry.
        ApplyCustomerEntry(
          CustLedgerEntry2, GenJournalLine2."Document Type"::Refund,
          GenJournalLine2."Document Type"::"Credit Memo", GenJournalLine2."Document No.", GenJournalLine."Document No.");
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry2);

        // 3. Verify: Verify the Ledger Entries.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        VerifyDetldCustomerLedgerEntry(
          GenJournalLine2, DetailedCustLedgEntry."Entry Type"::"Appln. Rounding", -Currency."Appln. Rounding Precision");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure OverPaymentToInvoicesRemainingPmtDiscAmountZeroSales()
    var
        Customer: Record Customer;
        CustLedgerEntryPayment: Record "Cust. Ledger Entry";
        CustLedgerEntryInvoice: Record "Cust. Ledger Entry";
        GenJournalLinePayment: Record "Gen. Journal Line";
        GenJournalLineInvoice: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        InvoiceAmount: array[3] of Decimal;
        PaymentAmount: Decimal;
        AmountToApplyInvoice: array[3] of Decimal;
        PaymentTolerancePercent: Decimal;
        PaymentDiscountDayRange: Integer;
        Index: Integer;
        PostingDateInvoice: array[3] of Date;
        InvoiceNo: array[3] of Code[20];
    begin
        // [FEATURE] [Sales] [Payment] [Invoice]
        // [SCENARIO 333081] CLE is not closed when it is applied to payment when its "Amount to Apply" < "Remaining Amount" and "Remaining Pmt. Disc. Possible" = 0
        // See the scenario on refered TFS
        Initialize();
        PaymentDiscountDayRange := LibraryRandom.RandIntInRange(5, 10);
        PaymentTolerancePercent := LibraryRandom.RandDecInRange(2, 5, 2);
        CreatePaymentTerms(PaymentTerms, PaymentDiscountDayRange, PaymentTolerancePercent);
        CreateCustomerWithCurrency(Customer, PaymentTerms.Code);
        WarningsInGeneralLedgerSetup(false, false);

        PostingDateInvoice[1] := CalcDate('<-CY>', WorkDate());
        PostingDateInvoice[2] := CalcDate('<-' + Format(PaymentDiscountDayRange + 1) + 'D>', WorkDate());
        PostingDateInvoice[3] := CalcDate('<' + Format(PaymentDiscountDayRange + 3) + 'D>', WorkDate());

        PaymentAmount := LibraryRandom.RandDecInRange(100, 200, 2);
        InvoiceAmount[1] := PaymentAmount;
        for Index := 2 to ArrayLen(InvoiceAmount) do
            InvoiceAmount[Index] := Round(PaymentAmount / 3);

        AmountToApplyInvoice[1] := Round(PaymentAmount / 3);
        AmountToApplyInvoice[2] := Round(InvoiceAmount[2] * (1 - PaymentTolerancePercent / 100));
        AmountToApplyInvoice[3] := InvoiceAmount[3];

        RunChangePaymentTolerance('', PaymentTolerancePercent, InvoiceAmount[3]);

        for Index := 1 to ArrayLen(InvoiceAmount) do begin
            Clear(GenJournalLineInvoice);
            CreateGenJournalLine(
              GenJournalLineInvoice, Customer."No.", '',
              GenJournalLineInvoice."Document Type"::Invoice, InvoiceAmount[Index], PostingDateInvoice[Index]);
            LibraryERM.PostGeneralJnlLine(GenJournalLineInvoice);
            InvoiceNo[Index] := GenJournalLineInvoice."Document No.";
        end;

        CreateGenJournalLine(
          GenJournalLinePayment, Customer."No.", '',
          GenJournalLinePayment."Document Type"::Payment, -PaymentAmount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLinePayment);

        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntryPayment, CustLedgerEntryPayment."Document Type"::Payment, GenJournalLinePayment."Document No.");
        CustLedgerEntryPayment.CalcFields("Remaining Amount");
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntryPayment, CustLedgerEntryPayment."Remaining Amount");

        for Index := 1 to ArrayLen(InvoiceAmount) do begin
            LibraryERM.FindCustomerLedgerEntry(
              CustLedgerEntryInvoice, CustLedgerEntryInvoice."Document Type"::Invoice, InvoiceNo[Index]);
            CustLedgerEntryInvoice.CalcFields("Remaining Amount");
            CustLedgerEntryInvoice.Validate("Remaining Pmt. Disc. Possible", 0);
            CustLedgerEntryInvoice.Validate("Amount to Apply", AmountToApplyInvoice[Index]);
            CustLedgerEntryInvoice.Validate("Applies-to ID", UserId);
            CustLedgerEntryInvoice.Modify(true);
        end;

        LibraryERM.PostCustLedgerApplication(CustLedgerEntryPayment);

        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntryInvoice, CustLedgerEntryInvoice."Document Type"::Invoice, InvoiceNo[2]);
        CustLedgerEntryInvoice.TestField(Open, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure OverPaymentToInvoicesRemainingPmtDiscAmountZeroPurchase()
    var
        Vendor: Record Vendor;
        VendorLedgerEntryPayment: Record "Vendor Ledger Entry";
        VendorLedgerEntryInvoice: Record "Vendor Ledger Entry";
        GenJournalLinePayment: Record "Gen. Journal Line";
        GenJournalLineInvoice: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        InvoiceAmount: array[3] of Decimal;
        PaymentAmount: Decimal;
        AmountToApplyInvoice: array[3] of Decimal;
        PaymentTolerancePercent: Decimal;
        PaymentDiscountDayRange: Integer;
        Index: Integer;
        PostingDateInvoice: array[3] of Date;
        InvoiceNo: array[3] of Code[20];
    begin
        // [FEATURE] [Purchase] [Payment] [Invoice]
        // [SCENARIO 333081] VLE is not closed when it is applied to payment when its "Amount to Apply" < "Remaining Amount" and "Remaining Pmt. Disc. Possible" = 0
        // See the scenario on refered TFS
        Initialize();
        PaymentDiscountDayRange := LibraryRandom.RandIntInRange(5, 10);
        PaymentTolerancePercent := LibraryRandom.RandDecInRange(2, 5, 2);
        CreatePaymentTerms(PaymentTerms, PaymentDiscountDayRange, PaymentTolerancePercent);
        CreateVendorWithCurrency(Vendor, PaymentTerms.Code);
        WarningsInGeneralLedgerSetup(false, false);

        PostingDateInvoice[1] := CalcDate('<-CY>', WorkDate());
        PostingDateInvoice[2] := CalcDate('<-' + Format(PaymentDiscountDayRange + 1) + 'D>', WorkDate());
        PostingDateInvoice[3] := CalcDate('<' + Format(PaymentDiscountDayRange + 3) + 'D>', WorkDate());

        PaymentAmount := -LibraryRandom.RandDecInRange(100, 200, 2);
        InvoiceAmount[1] := PaymentAmount;
        for Index := 2 to ArrayLen(InvoiceAmount) do
            InvoiceAmount[Index] := Round(PaymentAmount / 3);

        AmountToApplyInvoice[1] := Round(PaymentAmount / 3);
        AmountToApplyInvoice[2] := Round(InvoiceAmount[2] * (1 - PaymentTolerancePercent / 100));
        AmountToApplyInvoice[3] := InvoiceAmount[3];

        RunChangePaymentTolerance('', PaymentTolerancePercent, InvoiceAmount[3]);

        for Index := 1 to ArrayLen(InvoiceAmount) do begin
            Clear(GenJournalLineInvoice);
            CreateGenJournalLineVendor(
              GenJournalLineInvoice, Vendor."No.", '',
              GenJournalLineInvoice."Document Type"::Invoice, InvoiceAmount[Index], PostingDateInvoice[Index]);
            LibraryERM.PostGeneralJnlLine(GenJournalLineInvoice);
            InvoiceNo[Index] := GenJournalLineInvoice."Document No.";
        end;

        CreateGenJournalLineVendor(
          GenJournalLinePayment, Vendor."No.", '',
          GenJournalLinePayment."Document Type"::Payment, -PaymentAmount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLinePayment);

        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntryPayment, VendorLedgerEntryPayment."Document Type"::Payment, GenJournalLinePayment."Document No.");
        VendorLedgerEntryPayment.CalcFields("Remaining Amount");
        LibraryERM.SetApplyVendorEntry(VendorLedgerEntryPayment, VendorLedgerEntryPayment."Remaining Amount");

        for Index := 1 to ArrayLen(InvoiceAmount) do begin
            LibraryERM.FindVendorLedgerEntry(
              VendorLedgerEntryInvoice, VendorLedgerEntryInvoice."Document Type"::Invoice, InvoiceNo[Index]);
            VendorLedgerEntryInvoice.CalcFields("Remaining Amount");
            VendorLedgerEntryInvoice.Validate("Remaining Pmt. Disc. Possible", 0);
            VendorLedgerEntryInvoice.Validate("Amount to Apply", AmountToApplyInvoice[Index]);
            VendorLedgerEntryInvoice.Validate("Applies-to ID", UserId);
            VendorLedgerEntryInvoice.Modify(true);
        end;

        LibraryERM.PostVendLedgerApplication(VendorLedgerEntryPayment);

        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntryInvoice, VendorLedgerEntryInvoice."Document Type"::Invoice, InvoiceNo[2]);
        VendorLedgerEntryInvoice.TestField(Open, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure OverRefundToCreditMemosRemainingPmtDiscAmountZeroSales()
    var
        Customer: Record Customer;
        CustLedgerEntryRefund: Record "Cust. Ledger Entry";
        CustLedgerEntryCreditMemo: Record "Cust. Ledger Entry";
        GenJournalLineRefund: Record "Gen. Journal Line";
        GenJournalLineCreditMemo: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        CreditMemoAmount: array[3] of Decimal;
        RefundAmount: Decimal;
        AmountToApplyCreditMemo: array[3] of Decimal;
        PaymentTolerancePercent: Decimal;
        PaymentDiscountDayRange: Integer;
        Index: Integer;
        PostingDateCreditMemo: array[3] of Date;
        CreditMemoNo: array[3] of Code[20];
    begin
        // [FEATURE] [Sales] [Refund] [Credit Memo]
        // [SCENARIO 333081] CLE is not closed when it is applied to payment when its "Amount to Apply" < "Remaining Amount" and "Remaining Pmt. Disc. Possible" = 0
        // See the scenario on refered TFS
        Initialize();
        PaymentDiscountDayRange := LibraryRandom.RandIntInRange(5, 10);
        PaymentTolerancePercent := LibraryRandom.RandDecInRange(2, 5, 2);
        CreatePaymentTerms(PaymentTerms, PaymentDiscountDayRange, PaymentTolerancePercent);
        CreateCustomerWithCurrency(Customer, PaymentTerms.Code);
        WarningsInGeneralLedgerSetup(false, false);

        PostingDateCreditMemo[1] := CalcDate('<-CY>', WorkDate());
        PostingDateCreditMemo[2] := CalcDate('<-' + Format(PaymentDiscountDayRange + 1) + 'D>', WorkDate());
        PostingDateCreditMemo[3] := CalcDate('<' + Format(PaymentDiscountDayRange + 3) + 'D>', WorkDate());

        RefundAmount := -LibraryRandom.RandDecInRange(100, 200, 2);
        CreditMemoAmount[1] := RefundAmount;
        for Index := 2 to ArrayLen(CreditMemoAmount) do
            CreditMemoAmount[Index] := Round(RefundAmount / 3);

        AmountToApplyCreditMemo[1] := Round(RefundAmount / 3);
        AmountToApplyCreditMemo[2] := Round(CreditMemoAmount[2] * (1 - PaymentTolerancePercent / 100));
        AmountToApplyCreditMemo[3] := CreditMemoAmount[3];

        RunChangePaymentTolerance('', PaymentTolerancePercent, CreditMemoAmount[3]);

        for Index := 1 to ArrayLen(CreditMemoAmount) do begin
            Clear(GenJournalLineCreditMemo);
            CreateGenJournalLine(
              GenJournalLineCreditMemo, Customer."No.", '',
              GenJournalLineCreditMemo."Document Type"::"Credit Memo", CreditMemoAmount[Index], PostingDateCreditMemo[Index]);
            LibraryERM.PostGeneralJnlLine(GenJournalLineCreditMemo);
            CreditMemoNo[Index] := GenJournalLineCreditMemo."Document No.";
        end;

        CreateGenJournalLine(
          GenJournalLineRefund, Customer."No.", '',
          GenJournalLineRefund."Document Type"::Refund, -RefundAmount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLineRefund);

        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntryRefund, CustLedgerEntryRefund."Document Type"::Refund, GenJournalLineRefund."Document No.");
        CustLedgerEntryRefund.CalcFields("Remaining Amount");
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntryRefund, CustLedgerEntryRefund."Remaining Amount");

        for Index := 1 to ArrayLen(CreditMemoAmount) do begin
            LibraryERM.FindCustomerLedgerEntry(
              CustLedgerEntryCreditMemo, CustLedgerEntryCreditMemo."Document Type"::"Credit Memo", CreditMemoNo[Index]);
            CustLedgerEntryCreditMemo.CalcFields("Remaining Amount");
            CustLedgerEntryCreditMemo.Validate("Remaining Pmt. Disc. Possible", 0);
            CustLedgerEntryCreditMemo.Validate("Amount to Apply", AmountToApplyCreditMemo[Index]);
            CustLedgerEntryCreditMemo.Validate("Applies-to ID", UserId);
            CustLedgerEntryCreditMemo.Modify(true);
        end;

        LibraryERM.PostCustLedgerApplication(CustLedgerEntryRefund);

        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntryCreditMemo, CustLedgerEntryCreditMemo."Document Type"::"Credit Memo", CreditMemoNo[2]);
        CustLedgerEntryCreditMemo.TestField(Open, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure OverRefundToCreditMemosRemainingPmtDiscAmountZeroPurchase()
    var
        Vendor: Record Vendor;
        VendorLedgerEntryRefund: Record "Vendor Ledger Entry";
        VendorLedgerEntryCreditMemo: Record "Vendor Ledger Entry";
        GenJournalLineRefund: Record "Gen. Journal Line";
        GenJournalLineCreditMemo: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        CreditMemoAmount: array[3] of Decimal;
        RefundAmount: Decimal;
        AmountToApplyCreditMemo: array[3] of Decimal;
        PaymentTolerancePercent: Decimal;
        PaymentDiscountDayRange: Integer;
        Index: Integer;
        PostingDateCreditMemo: array[3] of Date;
        CreditMemoNo: array[3] of Code[20];
    begin
        // [FEATURE] [Purchase] [Refund] [Credit Memo]
        // [SCENARIO 333081] Credit Memo VLE is not closed when it is applied to refund when its "Amount to Apply" < "Remaining Amount" and "Remaining Pmt. Disc. Possible" = 0
        // See the scenario on refered TFS
        Initialize();
        PaymentDiscountDayRange := LibraryRandom.RandIntInRange(5, 10);
        PaymentTolerancePercent := LibraryRandom.RandDecInRange(2, 5, 2);
        CreatePaymentTerms(PaymentTerms, PaymentDiscountDayRange, PaymentTolerancePercent);
        CreateVendorWithCurrency(Vendor, PaymentTerms.Code);
        WarningsInGeneralLedgerSetup(false, false);

        PostingDateCreditMemo[1] := CalcDate('<-CY>', WorkDate());
        PostingDateCreditMemo[2] := CalcDate('<-' + Format(PaymentDiscountDayRange + 1) + 'D>', WorkDate());
        PostingDateCreditMemo[3] := CalcDate('<' + Format(PaymentDiscountDayRange + 3) + 'D>', WorkDate());

        RefundAmount := LibraryRandom.RandDecInRange(100, 200, 2);
        CreditMemoAmount[1] := RefundAmount;
        for Index := 2 to ArrayLen(CreditMemoAmount) do
            CreditMemoAmount[Index] := Round(RefundAmount / 3);

        AmountToApplyCreditMemo[1] := Round(RefundAmount / 3);
        AmountToApplyCreditMemo[2] := Round(CreditMemoAmount[2] * (1 - PaymentTolerancePercent / 100));
        AmountToApplyCreditMemo[3] := CreditMemoAmount[3];

        RunChangePaymentTolerance('', PaymentTolerancePercent, CreditMemoAmount[3]);

        for Index := 1 to ArrayLen(CreditMemoAmount) do begin
            Clear(GenJournalLineCreditMemo);
            CreateGenJournalLineVendor(
              GenJournalLineCreditMemo, Vendor."No.", '',
              GenJournalLineCreditMemo."Document Type"::"Credit Memo", CreditMemoAmount[Index], PostingDateCreditMemo[Index]);
            LibraryERM.PostGeneralJnlLine(GenJournalLineCreditMemo);
            CreditMemoNo[Index] := GenJournalLineCreditMemo."Document No.";
        end;

        CreateGenJournalLineVendor(
          GenJournalLineRefund, Vendor."No.", '',
          GenJournalLineRefund."Document Type"::Refund, -RefundAmount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLineRefund);

        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntryRefund, VendorLedgerEntryRefund."Document Type"::Refund, GenJournalLineRefund."Document No.");
        VendorLedgerEntryRefund.CalcFields("Remaining Amount");
        LibraryERM.SetApplyVendorEntry(VendorLedgerEntryRefund, VendorLedgerEntryRefund."Remaining Amount");

        for Index := 1 to ArrayLen(CreditMemoAmount) do begin
            LibraryERM.FindVendorLedgerEntry(
              VendorLedgerEntryCreditMemo, VendorLedgerEntryCreditMemo."Document Type"::"Credit Memo", CreditMemoNo[Index]);
            VendorLedgerEntryCreditMemo.CalcFields("Remaining Amount");
            VendorLedgerEntryCreditMemo.Validate("Remaining Pmt. Disc. Possible", 0);
            VendorLedgerEntryCreditMemo.Validate("Amount to Apply", AmountToApplyCreditMemo[Index]);
            VendorLedgerEntryCreditMemo.Validate("Applies-to ID", UserId);
            VendorLedgerEntryCreditMemo.Modify(true);
        end;

        LibraryERM.PostVendLedgerApplication(VendorLedgerEntryRefund);

        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntryCreditMemo, VendorLedgerEntryCreditMemo."Document Type"::"Credit Memo", CreditMemoNo[2]);
        VendorLedgerEntryCreditMemo.TestField(Open, true);
    end;

    [Test]
    [HandlerFunctions('ToleranceWarningPageHandler')]
    procedure VerifyPaymentDiscountToleranceWarningOnPayment()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        Amount: Decimal;
    begin
        // [SCENARIO 563299] When selecting "Post as Payment Discount Tolerance" in the Cash Receipt Journal, the system incorrectly suggests the full invoice amount instead of applying the 5% discount — leading to overposting instead of discount deduction.

        // [GIVEN] Create Setups for Application under General Ledger Setup
        Initialize();
        UpdatePmtToleranceFieldsInGeneralLedgerSetup();

        // [GIVEN] Set the payment term code to 1M due date calculation, 8D discount date calculation and 5% discount.
        CreatePaymentTerms(PaymentTerms, LibraryRandom.RandInt(8), LibraryRandom.RandDec(5, 2));

        // [GIVEN] Create Customer and attach Payment Terms
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Modify(true);

        // [GIVEN] Post a Sales Invoice
        Amount := LibraryRandom.RandDecInDecimalRange(100, 100, 0);  // Taking Random value for Amount.
        CreateGenJournalLine(GenJournalLine, Customer."No.", '', GenJournalLine."Document Type"::Invoice, Amount, CalcDate('<-1Y>', WorkDate()));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Create a Payment Entry and apply to the Invoice
        CreateGenJournalLine(GenJournalLine2, Customer."No.", '', GenJournalLine2."Document Type"::Payment, 0,
          CalcDate('<1D>', CalcDate(PaymentTerms."Discount Date Calculation", CalcDate('<-1Y>', WorkDate()))));

        // [WHEN] Apply Payment Entry to the Invoice And Post the Gen. Journal Line
        FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Account No.", CustLedgerEntry."Document Type"::Invoice);
        ApplyAndPostGenJnlLineWithPmtDiscWarning(CustLedgerEntry, GenJournalLine2, Amount);

        // [THEN] Verify Remaining Amount in Customer Ledger. Verify Payment Tolerance Discount in Detailed Customer Ledger.
        VerifyRemainingAmount(CustLedgerEntry, 100);
        VerifyDetldCustomerLedgerEntry(
          GenJournalLine2,
          DetailedCustLedgEntry."Entry Type"::"Payment Discount Tolerance", -CustLedgerEntry."Original Pmt. Disc. Possible");
    end;

    [Test]
    [HandlerFunctions('ToleranceWarningPageHandler,ConfirmHandlerTrue,SuccessMessageHandler')]
    procedure CashReceiptGenJournalLineErrorCheckWhenPaymentDiscountToleranceWarningOnPayment()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
        Amount: Decimal;
    begin
        // [SCENARIO ] When selecting "Post as Payment Discount Tolerance" in the Cash Receipt Journal, the system incorrectly suggests the full invoice amount instead of applying the 5% discount — leading to overposting instead of discount deduction.
        Initialize();

        // [GIVEN] Create Setups for Application under General Ledger Setup
        UpdatePmtToleranceFieldsInGeneralLedgerSetup();

        // [GIVEN] Set the payment term code to 1M due date calculation, 8D discount date calculation and 5% discount.
        CreatePaymentTerms(PaymentTerms, LibraryRandom.RandInt(8), LibraryRandom.RandDec(5, 2));

        // [GIVEN] Create Customer and attach Payment Terms
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Modify(true);

        // [GIVEN] Post a Sales Invoice
        Amount := LibraryRandom.RandDecInDecimalRange(100, 100, 0);  // Taking Random value for Amount.
        CreateGenJournalLine(GenJournalLine, Customer."No.", '', GenJournalLine."Document Type"::Invoice, Amount, CalcDate('<-1Y>', WorkDate()));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Create a Payment Entry and apply to the Invoice
        CreateGenJournalLine(GenJournalLine2, Customer."No.", '', GenJournalLine2."Document Type"::Payment, 0,
          CalcDate('<1D>', CalcDate(PaymentTerms."Discount Date Calculation", CalcDate('<-1Y>', WorkDate()))));

        // [WHEN] Apply Payment Entry to the Invoice And Post the Gen. Journal Line
        FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Account No.", CustLedgerEntry."Document Type"::Invoice);

        // [WHEN] Open and modify Cash Receipt Journal page
        CashReceiptJournal.Trap();
        Page.Run(Page::"Cash Receipt Journal", GenJournalLine2);
        CashReceiptJournal."Applies-to Doc. Type".SetValue(GenJournalLine2."Applies-to Doc. Type"::Invoice);
        CashReceiptJournal."Applies-to Doc. No.".SetValue(CustLedgerEntry."Document No.");
        CashReceiptJournal.Amount.SetValue(-(Amount + LibraryRandom.RandDecInRange(10, 20, 2)));

        // [THEN] Verify posting error on posting the Cash Receipt Journal Line
        CashReceiptJournal.Post.Invoke();
    end;

    [Test]
    [HandlerFunctions('GeneralJournalTemplateListModalPageHandler,ApplyCustomerEntriesPageHandlerWithDocumentNo,PmtDiscTolWarningModalPageHandler,PmtTolWarningModalPageHandler')]
    procedure CashReceiptGenJournalLineErrorCheckWhenPaymentDiscountToleranceWarningOnPaymentWithMultipleApply()
    var
        Customer: Record Customer;
        GeneralJournalLine: array[3] of Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        PaymentTerms: Record "Payment Terms";
        DocumentNo: array[2] of Code[20];
        PaymentDocNo: Code[20];
        Amount: Decimal;
    begin
        // [SCENARIO 602838] When a single Payment line in the Cash Receipt Journals page is applied against multiple Entries, each with a discount, the post fails with error: An error occurred and the transaction is stopped.
        Initialize();

        // [GIVEN] Create Setups for Application under General Ledger Setup.
        UpdatePmtToleranceFieldsInGeneralLedgerSetup();

        // [GIVEN] Set the payment term code to 1M due date calculation.
        CreatePaymentTerms(PaymentTerms, 0, 0);

        // [GIVEN] Create Customer and attach Payment Terms
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Modify(true);

        // [GIVEN] Create two Sales Invoices.
        Amount := LibraryRandom.RandDecInDecimalRange(4500, 4500, 0);
        CreateGeneralJournalBatch(GenJournalBatch);
        CreateSalesinvoices(GeneralJournalLine, GenJournalBatch, Customer."No.", CalcDate('<-1Y>', WorkDate()), Amount, DocumentNo);

        // [GIVEN] Create a Cash Receipt Journal Line with Amount to cover both Invoices.
        CreateCashRecGenJournalLine(GeneralJournalLine[3], GenJournalTemplate.Type::"Cash Receipts", GeneralJournalLine[3]."Account Type"::Customer,
          Customer."No.", -9000);
        GeneralJournalLine[3].Validate("Posting Date", CalcDate('<1D>', CalcDate(PaymentTerms."Discount Date Calculation", CalcDate('<-1Y>', WorkDate()))));
        GeneralJournalLine[3].Modify(true);
        LibraryVariableStorage.Enqueue(GeneralJournalLine[3]."Journal Template Name");

        // [GIVEN] Choice is Set to applies id.
        IsSetAppliesToID(true, DocumentNo);
        PaymentDocNo := GeneralJournalLine[3]."Document No.";

        // [WHEN] Open Apply Entries Page for Application.
        OpenCashRcptPage(GeneralJournalLine[3]."Document No.", GeneralJournalLine[3]."Document Type");

        // [WHEN] Apply both Invoices to the Payment Line and Post the Gen. Journal Line.
        LibraryERM.PostGeneralJnlLine(GeneralJournalLine[3]);

        // [THEN] Verify the Payment Entry is applied to both Invoices.
        VerifyCustLdgrEntryApplied(PaymentDocNo);
    end;

    [Normal]
    local procedure AmountToApplyInCustomerLedger(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    begin
        // Find Posted Customer Ledger Entries.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        CustLedgerEntry.CalcFields("Remaining Amount");
        CustLedgerEntry.Validate("Amount to Apply", CustLedgerEntry."Remaining Amount");
        CustLedgerEntry.Modify(true);
    end;

    [Normal]
    local procedure ApplicationRoundingInCurrency(var Currency: Record Currency)
    begin
        Currency.Validate("Appln. Rounding Precision", LibraryUtility.GenerateRandomFraction());
        Currency.Modify(true);
    end;

    [Normal]
    local procedure ApplyAndPostGenJournalLine(var CustLedgerEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type")
    begin
        FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Account No.", DocumentType);
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry);
        SetAppliesToIDGenJournalLine(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    [Normal]
    local procedure ApplyAndPostGenJnlLineWarning(var CustLedgerEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; GenJournalLineAmount: Decimal)
    var
        DifferenceAmount: Decimal;
    begin
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry);
        SetAppliesToIDGenJournalLine(GenJournalLine);

        // Use for partial Payment Tolerance Warning.
        DifferenceAmount := CustLedgerEntry."Original Pmt. Disc. Possible" + (CustLedgerEntry."Max. Payment Tolerance" / 2);
        PostGeneralJournalLine(GenJournalLine, -(GenJournalLineAmount - DifferenceAmount));
    end;

    [Normal]
    local procedure ApplyPostGenJnlLineGracePeriod(var CustLedgerEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry);
        SetAppliesToIDGenJournalLine(GenJournalLine);

        // Use for partial Payment Tolerance Warning.
        PostGeneralJournalLine(GenJournalLine, GenJournalLine.Amount - (CustLedgerEntry."Max. Payment Tolerance" / 2));
    end;

    [Normal]
    local procedure ApplyAndPostGenJnlLineDiscount(var CustLedgerEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    var
        DifferenceAmount: Decimal;
    begin
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry);
        SetAppliesToIDGenJournalLine(GenJournalLine);

        // Use for partial Payment Tolerance Warning.
        DifferenceAmount := CustLedgerEntry."Original Pmt. Disc. Possible" + (CustLedgerEntry."Max. Payment Tolerance" / 2);
        PostGeneralJournalLine(GenJournalLine, GenJournalLine.Amount - DifferenceAmount);
    end;

    local procedure ApplyCustomerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; DocumentNo2: Code[20])
    var
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        CustLedgerEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntry, CustLedgerEntry."Remaining Amount");
        AmountToApplyInCustomerLedger(CustLedgerEntry2, DocumentNo2, DocumentType2);

        // Set Applies-to ID.
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry2);
    end;

    [Normal]
    local procedure ApplyCustomerLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; AmounttoApply: Decimal)
    begin
        CustLedgerEntry.Validate("Amount to Apply", AmounttoApply);
        CustLedgerEntry.Modify(true);
    end;

    [Normal]
    local procedure AppliesToDocAndPostGenJnlLine(var CustLedgerEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; AppliesToDocNo: Code[20])
    var
        DifferenceAmount: Decimal;
    begin
        ApplyCustomerLedgerEntry(CustLedgerEntry, GenJournalLine.Amount);

        // Use for partial Payment Tolerance Warning.
        DifferenceAmount := CustLedgerEntry."Original Pmt. Disc. Possible" + (CustLedgerEntry."Max. Payment Tolerance" / 2);
        AppliestoDocNoGenJournalLine(GenJournalLine, GenJournalLine.Amount - DifferenceAmount, AppliesToDocNo);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    [Normal]
    local procedure AppliestoDocNoGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; Amount: Decimal; AppliesToDocNo: Code[20])
    begin
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Validate(Amount, Amount);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateCurrency(var Currency: Record Currency)
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        Currency.Validate("Residual Gains Account", Currency."Realized Gains Acc.");
        Currency.Validate("Residual Losses Account", Currency."Realized Losses Acc.");
        Currency.Modify(true);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
    end;

    [Normal]
    local procedure CreateCurrencyWithSetup(var Currency: Record Currency)
    begin
        CreateCurrency(Currency);
        UpdateAddCurrencySetup(Currency.Code);
    end;

    [Normal]
    local procedure CreateCustomerWithCurrency(var Customer: Record Customer; PaymentTermsCode: Code[10]): Code[10]
    var
        Currency: Record Currency;
        LibrarySales: Codeunit "Library - Sales";
    begin
        // Random Value for Payment Tolerance and Maximum Payment Tolerance Amount.
        LibrarySales.CreateCustomer(Customer);
        AttachPaymentTermsCustomer(Customer, PaymentTermsCode);
        CreateCurrencyWithSetup(Currency);
        RunChangePaymentTolerance(Currency.Code, LibraryRandom.RandDec(5, 2), LibraryRandom.RandDec(10, 2));
        exit(Currency.Code);
    end;

    [Normal]
    local procedure CreateCustomerWithPaymentTerm(var Customer: Record Customer) DiscountDays: Integer
    begin
        LibrarySales.CreateCustomer(Customer);
        DiscountDays := LibraryRandom.RandInt(5);  // Using Random Value for Days.
        Customer.Validate("Payment Terms Code", CreatePaymentTermsCode(DiscountDays));
        Customer.Modify(true);
    end;

    local procedure CreateVendorWithCurrency(var Vendor: Record Vendor; PaymentTermsCode: Code[10]): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Terms Code", PaymentTermsCode);
        Vendor.Modify(true);
        CreateCurrencyWithSetup(Currency);
        RunChangePaymentTolerance(Currency.Code, LibraryRandom.RandDec(5, 2), LibraryRandom.RandDec(10, 2));
        exit(Currency.Code);
    end;

    [Normal]
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

    [Normal]
    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; CurrencyCode: Code[10]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal; PostingDate: Date)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine,
          GenJournalBatch."Journal Template Name",
          GenJournalBatch.Name, DocumentType, GenJournalLine."Account Type"::Customer, AccountNo, Amount);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGenJournalLineVendor(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; CurrencyCode: Code[10]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal; PostingDate: Date)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine,
          GenJournalBatch."Journal Template Name",
          GenJournalBatch.Name, DocumentType, GenJournalLine."Account Type"::Vendor, AccountNo, Amount);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJournalLine.Modify(true);
    end;

    [Normal]
    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal; BalAccountType: Enum "Gen. Journal Account Type"; BalAccountNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Bal. Account Type", BalAccountType);
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Modify(true);
    end;

    [Normal]
    local procedure CreatePaymentTermsCode(DiscountDateCalculationDays: Integer): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        CreatePaymentTerms(PaymentTerms, DiscountDateCalculationDays, LibraryRandom.RandDec(5, 2));
        exit(PaymentTerms.Code);
    end;

    local procedure CreatePaymentTerms(var PaymentTerms: Record "Payment Terms"; DiscountDateCalculationDays: Integer; DiscountPercent: Decimal)
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        Evaluate(PaymentTerms."Due Date Calculation", '<' + Format(LibraryRandom.RandInt(2)) + 'M>');
        Evaluate(PaymentTerms."Discount Date Calculation", '<' + Format(DiscountDateCalculationDays) + 'D>');

        // Evaluate doesn't call validate trigger.
        PaymentTerms.Validate("Due Date Calculation", PaymentTerms."Due Date Calculation");
        PaymentTerms.Validate("Discount Date Calculation", PaymentTerms."Discount Date Calculation");
        PaymentTerms.Validate("Discount %", DiscountPercent);
        PaymentTerms.Validate("Calc. Pmt. Disc. on Cr. Memos", true);
        PaymentTerms.Modify(true);
    end;

    local procedure FindCustomerLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    begin
        CustLedgerEntry.SetRange("Document Type", DocumentType);
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields("Remaining Amount", Amount);
    end;

    [Normal]
    local procedure FindDetldCustomerLedgerEntry(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
        DetailedCustLedgEntry.FindSet();
    end;

    local procedure UpdatePmtToleranceFieldsInGeneralLedgerSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PaymentDiscountGracePeriod: DateFormula;
        GracePeriodDays: Integer;
    begin
        GeneralLedgerSetup.Get();

        GeneralLedgerSetup.Validate("Pmt. Disc. Tolerance Posting", GeneralLedgerSetup."Pmt. Disc. Tolerance Posting"::"Payment Discount Accounts");
        GeneralLedgerSetup.Validate("Payment Tolerance Posting", GeneralLedgerSetup."Payment Tolerance Posting"::"Payment Tolerance Accounts");
        GracePeriodDays := LibraryRandom.RandIntInRange(4, 4);
        Evaluate(
          PaymentDiscountGracePeriod, '<' + Format(GracePeriodDays) + 'D>');
        GeneralLedgerSetup.Validate("Payment Discount Grace Period", PaymentDiscountGracePeriod);
        GeneralLedgerSetup.Validate("Payment Tolerance Warning", true);
        GeneralLedgerSetup.Validate("Pmt. Disc. Tolerance Warning", true);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure ApplyAndPostGenJnlLineWithPmtDiscWarning(var CustLedgerEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; GenJournalLineAmount: Decimal)
    var
        DifferenceAmount: Decimal;
    begin
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry);
        SetAppliesToIDGenJournalLine(GenJournalLine);

        // Use for partial Payment Tolerance Warning.
        DifferenceAmount := CustLedgerEntry."Remaining Pmt. Disc. Possible";
        PostGeneralJournalLine(GenJournalLine, -(GenJournalLineAmount - DifferenceAmount));
    end;

    [Normal]
    local procedure GetMaxTolerancePaymentAmount(): Decimal
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        exit(GeneralLedgerSetup."Max. Payment Tolerance Amount");
    end;

    [Normal]
    local procedure AttachPaymentTermsCustomer(var Customer: Record Customer; PaymentTermsCode: Code[10])
    begin
        Customer.Validate("Payment Terms Code", PaymentTermsCode);
        Customer.Modify(true);
    end;

    [Normal]
    local procedure PostGeneralJournalLine(GenJournalLine: Record "Gen. Journal Line"; Amount: Decimal)
    begin
        UpdateGenJournalLine(GenJournalLine, Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    [Normal]
    local procedure RunChangePaymentTolerance(CurrencyCode: Code[10]; PaymentTolerance: Decimal; MaxPmtToleranceAmount: Decimal)
    var
        ChangePaymentTolerance: Report "Change Payment Tolerance";
    begin
        Clear(ChangePaymentTolerance);
        ChangePaymentTolerance.InitializeRequest(false, CurrencyCode, PaymentTolerance, MaxPmtToleranceAmount);
        ChangePaymentTolerance.UseRequestPage(false);
        ChangePaymentTolerance.Run();
    end;

    local procedure SetAppliesToIDGenJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.Validate("Applies-to ID", UserId);
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateAddCurrencySetup(CurrencyCode: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        UpdatePaymentToleranceInSetup(
          CurrencyCode,
          '<' + Format(LibraryRandom.RandInt(5)) + 'D>',
          GeneralLedgerSetup."Payment Tolerance Posting"::"Payment Tolerance Accounts",
          GeneralLedgerSetup."Pmt. Disc. Tolerance Posting"::"Payment Tolerance Accounts");
    end;

    [Normal]
    local procedure UpdateCustomerPostingGroup(PostingGroupCode: Code[20])
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        CustomerPostingGroup.Get(PostingGroupCode);
        CustomerPostingGroup.Validate("Payment Disc. Debit Acc.", LibraryERM.CreateGLAccountNo());
        CustomerPostingGroup.Validate("Payment Disc. Credit Acc.", LibraryERM.CreateGLAccountNo());
        CustomerPostingGroup.Validate("Payment Tolerance Debit Acc.", LibraryERM.CreateGLAccountNo());
        CustomerPostingGroup.Validate("Payment Tolerance Credit Acc.", LibraryERM.CreateGLAccountNo());
        CustomerPostingGroup.Modify(true);
    end;

    [Normal]
    local procedure UpdateGeneralLedgerSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate(
          "Payment Tolerance Posting", GeneralLedgerSetup."Payment Tolerance Posting"::"Payment Tolerance Accounts");
        GeneralLedgerSetup.Validate(
          "Pmt. Disc. Tolerance Posting", GeneralLedgerSetup."Pmt. Disc. Tolerance Posting"::"Payment Discount Accounts");
        GeneralLedgerSetup.Validate("Payment Tolerance Warning", true);
        GeneralLedgerSetup.Validate("Pmt. Disc. Tolerance Warning", true);
        GeneralLedgerSetup.Modify(true);

        // Using Random Number for Payment Tolerance Percentage and Maximum Payment Tolerance Amount.
        RunChangePaymentTolerance('', LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
    end;

    [Normal]
    local procedure UpdateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; Amount: Decimal)
    begin
        GenJournalLine.Validate(Amount, Amount);
        GenJournalLine.Modify(true);
    end;

    [Normal]
    local procedure UpdatePaymentGracePeriod() GracePeriodDays: Integer
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PaymentDiscountGracePeriod: DateFormula;
    begin
        GeneralLedgerSetup.Get();
        GracePeriodDays := LibraryRandom.RandInt(5);
        Evaluate(
          PaymentDiscountGracePeriod, '<' + Format(GracePeriodDays) + 'D>');  // Using Random Number for Days.
        GeneralLedgerSetup.Validate("Payment Discount Grace Period", PaymentDiscountGracePeriod);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdatePaymentToleranceInSetup(CurrencyCode: Code[10]; PaymentDiscountGracePeriod: Text[10]; PaymentTolerancePosting: Option; PmtDiscTolerancePosting: Option)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        Evaluate(GeneralLedgerSetup."Payment Discount Grace Period", PaymentDiscountGracePeriod);
        GeneralLedgerSetup.Validate("Payment Tolerance Posting", PaymentTolerancePosting);
        GeneralLedgerSetup.Validate("Pmt. Disc. Tolerance Posting", PmtDiscTolerancePosting);

        // As there is no need to run the Adjust Exchange Rate Report so we are not validating the Additional Reporting Currency field.
        GeneralLedgerSetup."Additional Reporting Currency" := CurrencyCode;
        GeneralLedgerSetup.Modify(true);
        RunChangePaymentTolerance('', LibraryRandom.RandDec(5, 2), LibraryRandom.RandDec(10, 2));
    end;

    [Normal]
    local procedure UpdatePostingDateGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date)
    begin
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
    end;

    [Normal]
    local procedure VerifyDetldCustomerLedgerEntry(GenJournalLine: Record "Gen. Journal Line"; EntryType: Enum "Detailed CV Ledger Entry Type"; Amount: Decimal)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        FindDetldCustomerLedgerEntry(DetailedCustLedgEntry, GenJournalLine."Document No.", GenJournalLine."Document Type");
        VerifyAmountInDetldCustomer(DetailedCustLedgEntry, EntryType, Amount);
    end;

    local procedure VerifyRemainingAmount(CustLedgerEntry: Record "Cust. Ledger Entry"; AmountApplied: Decimal)
    begin
        CustLedgerEntry.Get(CustLedgerEntry."Entry No.");
        CustLedgerEntry.CalcFields("Remaining Amount", Amount);
        CustLedgerEntry.TestField("Remaining Amount", CustLedgerEntry.Amount - AmountApplied);
        Assert.AreNotEqual(
          CustLedgerEntry.Amount,
          CustLedgerEntry."Remaining Amount",
          StrSubstNo(AmountError, CustLedgerEntry.FieldCaption(Amount), CustLedgerEntry.FieldCaption("Remaining Amount")));
    end;

    [Normal]
    local procedure VerifyAmountInDetldCustomer(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; EntryType: Enum "Detailed CV Ledger Entry Type"; Amount: Decimal)
    var
        Currency: Record Currency;
    begin
        if DetailedCustLedgEntry."Currency Code" <> '' then
            Currency.Get(DetailedCustLedgEntry."Currency Code");
        Currency.InitRoundingPrecision();
        DetailedCustLedgEntry.SetRange("Entry Type", EntryType);
        DetailedCustLedgEntry.FindFirst();
        Assert.AreNearlyEqual(
          Round(Amount, Currency."Invoice Rounding Precision"),
          DetailedCustLedgEntry.Amount,
          Currency."Amount Rounding Precision",
          StrSubstNo(AmountError, Round(Amount, Currency."Invoice Rounding Precision"), Amount));
    end;

    [Normal]
    local procedure VerifyAmountInDetailedLedger(DocumentType: Enum "Gen. Journal Document Type"; EntryType: Enum "Detailed CV Ledger Entry Type"; DocumentNo: Code[20]; Amount: Decimal)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.SetRange("Document Type", DocumentType);
        DetailedCustLedgEntry.SetRange("Document No.", DocumentNo);
        VerifyAmountInDetldCustomer(DetailedCustLedgEntry, EntryType, Amount);
    end;

    [Normal]
    local procedure VerifyLedgerEntries(GenJournalLine: Record "Gen. Journal Line"; GenJournalLine2: Record "Gen. Journal Line")
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        VerifyDetldCustomerLedgerEntry(GenJournalLine2, DetailedCustLedgEntry."Entry Type"::"Initial Entry", GenJournalLine2.Amount);
        VerifyDetldCustomerLedgerEntry(GenJournalLine2, DetailedCustLedgEntry."Entry Type"::Application, GenJournalLine.Amount);
        VerifyDetldCustomerLedgerEntry(GenJournalLine, DetailedCustLedgEntry."Entry Type"::"Initial Entry", GenJournalLine.Amount);
        VerifyDetldCustomerLedgerEntry(GenJournalLine, DetailedCustLedgEntry."Entry Type"::Application, -GenJournalLine.Amount);
    end;

    [Normal]
    local procedure VerifyLedgerEntry(CustLedgerEntry: Record "Cust. Ledger Entry"; GenJournalLineAmount: Decimal; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; MaxPaymentTolerance: Decimal)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        VerifyRemainingAmount(CustLedgerEntry, GenJournalLineAmount);
        VerifyAmountInDetailedLedger(
          DocumentType, DetailedCustLedgEntry."Entry Type"::"Payment Tolerance", DocumentNo, MaxPaymentTolerance);
        VerifyAmountInDetailedLedger(
          DocumentType, DetailedCustLedgEntry."Entry Type"::"Payment Discount", DocumentNo,
          -CustLedgerEntry."Original Pmt. Disc. Possible");
    end;

    [Normal]
    local procedure WarningsInGeneralLedgerSetup(PaymentToleranceWarning: Boolean; PmtDiscToleranceWarning: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Payment Tolerance Warning", PaymentToleranceWarning);
        GeneralLedgerSetup.Validate("Pmt. Disc. Tolerance Warning", PmtDiscToleranceWarning);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure verifyCustLdgrEntryApplied(PaymentDocNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        EntryNo: Integer;
    begin
        CustLedgerEntry.SetRange("Document No.", PaymentDocNo);
        CustLedgerEntry.FindFirst();
        EntryNo := CustLedgerEntry."Entry No.";
        CustLedgerEntry.Reset();
        CustLedgerEntry.SetRange("Closed by Entry No.", EntryNo);
        CustLedgerEntry.FindSet();
        Assert.AreEqual(2, CustLedgerEntry.Count(), AppliedError);
    end;

    local procedure OpenCashRcptPage(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type") Amount: Decimal
    var
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        CashReceiptJournal.OpenEdit();
        CashReceiptJournal.FILTER.SetFilter("Document No.", DocumentNo);
        CashReceiptJournal.FILTER.SetFilter("Document Type", Format(DocumentType));
        LibraryVariableStorage.Enqueue(true);
        CashReceiptJournal."Apply Entries".Invoke();
        Amount := LibraryRandom.RandDec(10, 2);
        CashReceiptJournal.OK().Invoke();
    end;

    local procedure IsSetAppliesToID(SetAppliesToIDValue: Boolean; DocumentNo: array[2] of Code[20])
    var
        i: Integer;
    begin
        LibraryVariableStorage.Enqueue(SetAppliesToIDValue);
        for i := 1 to 2 do
            LibraryVariableStorage.Enqueue(DocumentNo[i]);
    end;

    local procedure CreateSalesinvoices(GeneralJournalLine: array[2] of Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch";
      CustomerNo: Code[20]; PostingDate: Date; Amount: Decimal; var DocumentNo: array[2] of Code[20])
    var
        i: Integer;
        DocumentNoCode: Code[20];
    begin
        for i := 1 to 2 do begin
            CreateSalesJournalLines(GeneralJournalLine[i], GenJournalBatch, CustomerNo, PostingDate, Amount, DocumentNoCode);
            DocumentNo[i] := DocumentNoCode;
        end;
        PostJournalBatch(GenJournalBatch);
    end;

    local procedure CreateSalesJournalLines(var GeneralJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch";
      CustomerNo: Code[20]; PostingDate: Date; Amount: Decimal; var DocumentNo: Code[20])
    begin
        LibraryERM.CreateGeneralJnlLineWithBalAcc(GeneralJournalLine, GenJournalBatch."Journal Template Name",
            GenJournalBatch.Name, GeneralJournalLine."Document Type"::Invoice, GeneralJournalLine."Account Type"::Customer,
            CustomerNo, GeneralJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), Amount);
        if DocumentNo <> '' then
            GeneralJournalLine.Validate("Document No.", IncStr(DocumentNo));
        GeneralJournalLine.Validate("Posting Date", PostingDate);
        GeneralJournalLine.Modify(true);
        DocumentNo := GeneralJournalLine."Document No.";
    end;

    local procedure PostJournalBatch(GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetFilter("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.FindFirst();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateCashRecGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; TemplateType: Enum "Gen. Journal Template Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGeneralJournalBatch(GenJournalBatch, TemplateType);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::Payment, AccountType, AccountNo, Amount);
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; TemplateType: Enum "Gen. Journal Template Type")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        BankAccount: Record "Bank Account";
    begin
        CreateGeneralJournalTemplate(GenJournalTemplate, TemplateType);
        LibraryERM.FindBankAccount(BankAccount);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"Bank Account");
        GenJournalBatch.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateGeneralJournalTemplate(var GenJournalTemplate: Record "Gen. Journal Template"; TemplateType: Enum "Gen. Journal Template Type")
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, TemplateType);
        GenJournalTemplate.Modify(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := not (Question = ConfirmMessageForPayment);
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerTrue(QuestionText: Text[1024]; var Relpy: Boolean)
    begin
        Relpy := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentToleranceWarning(var PaymentToleranceWarning: Page "Payment Tolerance Warning"; var Response: Action)
    begin
        // Modal Page Handler for Payment Tolerance Warning.
        PaymentToleranceWarning.InitializeOption(OptionValue);
        Response := ACTION::Yes
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ToleranceWarningPageHandler(var PaymentDiscToleranceWarning: Page "Payment Disc Tolerance Warning"; var Response: Action)
    begin
        // Modal Page Handler for Payment Discount Tolerance Warning.
        PaymentDiscToleranceWarning.InitializeNewPostingAction(0);
        Response := ACTION::Yes
    end;

    [ModalPageHandler]
    procedure PmtDiscTolWarningModalPageHandler(var PaymentDiscToleranceWarning: TestPage "Payment Disc Tolerance Warning")
    begin
        PaymentDiscToleranceWarning.Posting.SetValue(1);
        PaymentDiscToleranceWarning.Yes().Invoke();
    end;

    [ModalPageHandler]
    procedure PmtTolWarningModalPageHandler(var PmtTolWarning: TestPage "Payment Tolerance Warning")
    begin
        PmtTolWarning.Posting.SetValue(1);
        PmtTolWarning.Yes().Invoke();
    end;

    [ModalPageHandler]
    procedure ApplyCustomerEntriesPageHandlerWithDocumentNo(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    var
        SetAppliesToIDValue: Variant;
        SetAppliesToID: Boolean;
        DocumentNo: array[8] of Variant;
        AmountToApply: Decimal;
        i: Integer;
    begin
        LibraryVariableStorage.Dequeue(SetAppliesToIDValue);
        SetAppliesToID := SetAppliesToIDValue;
        if SetAppliesToID then
            for i := 1 to 2 do begin
                LibraryVariableStorage.Dequeue(DocumentNo[i]);
                ApplyCustomerEntries.Filter.SetFilter("Document No.", DocumentNo[i]);
                ApplyCustomerEntries."Set Applies-to ID".Invoke();
                AmountToApply := ApplyCustomerEntries."Amount to Apply".AsDecimal();
                ApplyCustomerEntries.AppliedAmount.SetValue(AmountToApply);
                ApplyCustomerEntries."Remaining Pmt. Disc. Possible".SetValue(67.36);
                ApplyCustomerEntries."Max. Payment Tolerance".SetValue(100);
            end;
        ApplyCustomerEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure GeneralJournalTemplateListModalPageHandler(var GeneralJournalTemplateList: TestPage "General Journal Template List")
    begin
        GeneralJournalTemplateList.GotoKey(LibraryVariableStorage.DequeueText());
        GeneralJournalTemplateList.OK().Invoke();
    end;

    [MessageHandler]
    procedure SuccessMessageHandler(Msg: Text[1024])
    begin
        Assert.ExpectedMessage(SuccessPostingMsg, Msg);
    end;
}
