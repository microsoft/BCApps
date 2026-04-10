codeunit 134000 "ERM Apply Sales/Receivables"
{
    Permissions = TableData "Cust. Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Sales]
        isInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryJournals: Codeunit "Library - Journals";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        Assert: Codeunit Assert;
        isInitialized: Boolean;
        WrongValErr: Label '%1 must be %2 in %3.';
        AppliesToIDIsNotEmptyOnLedgEntryErr: Label 'Applies-to ID is not empty in %1.';
        AmountToApplyErr: Label '"Amount to Apply" should be zero.';
        DimensionUsedErr: Label 'A dimension used in %1 %2, %3, %4 has caused an error.';
        DialogTxt: Label 'Dialog';
        EarlierPostingDateErr: Label 'You cannot apply and post an entry to an entry with an earlier posting date.';
        DifferentCurrenciesErr: Label 'All entries in one application must be in the same currency.';
        AppliesToDocErr: Label 'Applies-To Doc, should not be blank.';
        AppliesToIDErr: Label 'Applies-to ID, should not be blank.';
        SummedAmountWrongErr: Label 'Summed amount on cash receipt journal line is not correct.';

    [Test]
    [Scope('OnPrem')]
    procedure TestPmntDiscWithinDueDate()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DueDate: Date;
        PaymentDiscountPercent: Decimal;
        DiscountAmount: Decimal;
    begin
        // Create General Journal Line for Customer, Post and Validate Customer Ledger Entry and Detailed Customer Ledger Entry for
        // Payment Discount(Amount and "Amount LCY") field.

        // Calculate Due Date and Payment Discount Percent then Post and Apply General Lines.
        Initialize();
        CalcDueDateAndPaymentDiscount(DueDate, PaymentDiscountPercent);
        PostAndApplyGenLines(GenJournalLine, DueDate);
        DiscountAmount := Round(GenJournalLine.Amount * PaymentDiscountPercent / 100);

        // Verify: Verify Applied Entry.
        VerifyPaymentWithDiscount(GenJournalLine."Document No.", DiscountAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPmntDiscAfterDueDate()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DueDate: Date;
        PaymentDiscountPercent: Decimal;
    begin
        // Create General Journal Line for Customer, Post and Validate "Original Pmt. Disc. Possible" and "Open" field for Payment line in
        // Customer Ledger Entry.

        // Calculate Due Date and Payment Discount Percent then Post and Apply General Lines.
        Initialize();
        CalcDueDateAndPaymentDiscount(DueDate, PaymentDiscountPercent);
        PostAndApplyGenLines(GenJournalLine, CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', DueDate));

        // Verify: Verify Payment Applied Entry.
        VerifyPaymentWithoutDiscount(GenJournalLine."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUnapplyPmntDisc()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DueDate: Date;
        PaymentDiscountPercent: Decimal;
        DocumentNo: Code[20];
    begin
        // Create General Journal Line for Customer, Post and Validate "Original Pmt. Disc. Possible" and "Open" field for Payment line in
        // Customer Ledger Entry.

        // Calculate Due Date and Payment Discount Percent then Post and Apply General Lines.
        Initialize();
        CalcDueDateAndPaymentDiscount(DueDate, PaymentDiscountPercent);
        DocumentNo := PostAndApplyGenLines(GenJournalLine, DueDate);

        // Exercise: Unapply Payment to Invoice.
        UnapplyCustLedgerEntry(GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.");

        // Verify: Verify UnApplied Entry.
        VerifyUnapplyPaymentDiscount(DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplnRoundingForInvoice()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Application Rounding Entry in Detailed Customer Ledger Entry with Apply and Unapply Invoice and Payment with Random Values.
        // Using 0 for Application Rounding Precision for Currency.
        Initialize();
        ApplyUnapplyCustRounding(
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, CreateCurrency(0),
          10 * LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(5, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplnRoundingForCreditMemo()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Application Rounding Entry in Detailed Customer Ledger Entry with Apply and Unapply Credit Memo and Refund
        // with Random Values and using 0 for Application Rounding Precision for Currency..
        Initialize();
        ApplyUnapplyCustRounding(
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, CreateCurrency(0),
          -10 * LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(5, 2));
    end;

    local procedure ApplyUnapplyCustRounding(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; CurrencyCode: Code[10]; Amount: Decimal; AppRounding: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Setup.
        CreatePostApplyGenJournalLine(GenJournalLine, DocumentType, DocumentType2, CurrencyCode, Amount, AppRounding);

        // Exercise.
        UnapplyCustLedgerEntry(DocumentType2, GenJournalLine."Document No.");

        // Verify: Verify Application Rounding Entry on Detailed Customer Ledger Entry.
        VerifyApplnRoundingCustLedger(GenJournalLine."Document No.", -AppRounding);
        exit(GenJournalLine."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyPmntAdditionalCurr()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
        DocumentNo: Code[20];
        AppRounding: Decimal;
    begin
        // Check Application Rounding Entry in Detailed Customer Ledger Entry and Additional Currency Amount in G/L Entry
        // with Apply and Unapply Invoice and Payment with Random Values and using 0 for Application Rounding Precision for Currency..
        Initialize();
        CurrencyCode := CreateCurrency(0);
        LibraryERM.SetAddReportingCurrency(CurrencyCode);
        AppRounding := LibraryRandom.RandDec(5, 2);
        DocumentNo :=
          ApplyUnapplyCustRounding(
            GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, CurrencyCode,
            10 * LibraryRandom.RandDec(100, 2), AppRounding);

        // Verify: Verify Additional Currency Amount in G/L Entry.
        VerifyGLEntry(DocumentNo, CurrencyCode, GenJournalLine."Document Type"::" ", AppRounding);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyRefAdditionalCurr()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
        DocumentNo: Code[20];
        AppRounding: Decimal;
    begin
        // Check Application Rounding Entry in Detailed Customer Ledger Entry and Additional Currency Amount in G/L Entry
        // with Apply and Unapply Credit Memo and Refund with Random Values and using 0 for Application Rounding Precision for Currency..
        Initialize();
        CurrencyCode := CreateCurrency(0);
        LibraryERM.SetAddReportingCurrency(CurrencyCode);
        AppRounding := LibraryRandom.RandDec(5, 2);
        DocumentNo :=
          ApplyUnapplyCustRounding(
            GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, CurrencyCode,
            -10 * LibraryRandom.RandDec(100, 2), AppRounding);

        // Verify: Verify Additional Currency Amount in G/L Entry.
        VerifyGLEntry(DocumentNo, CurrencyCode, GenJournalLine."Document Type"::" ", AppRounding);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyApplyPmntAdditionalCurr()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Application Rounding Entry in Detailed Customer Ledger Entry and Additional Currency Amount in G/L Entry
        // with Apply already Unapplied Invoice and Payment with Random Values.
        Initialize();
        UnapplyApplyAdditionalCurr(
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, 10 * LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyApplyRefAdditionalCurr()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Application Rounding Entry in Detailed Customer Ledger Entry and Additional Currency Amount in G/L Entry
        // with Apply already Unapplied Credit Memo and Refund with Random Values.
        Initialize();
        UnapplyApplyAdditionalCurr(
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund,
          -10 * LibraryRandom.RandDec(100, 2));
    end;

    local procedure UnapplyApplyAdditionalCurr(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        CurrencyCode: Code[10];
        AppRounding: Decimal;
    begin
        // Setup.
        CurrencyCode := CreateCurrency(0);  // Using 0 for Application Rounding Precision for Currency.
        LibraryERM.SetAddReportingCurrency(CurrencyCode);
        AppRounding := LibraryRandom.RandDec(5, 2);
        DocumentNo := CreatePostApplyGenJournalLine(GenJournalLine, DocumentType, DocumentType2, CurrencyCode, Amount, AppRounding);
        UnapplyCustLedgerEntry(DocumentType2, GenJournalLine."Document No.");

        // Exercise. Apply already Unapplied Document from Customer Ledger Entry.
        LibraryERM.ApplyCustomerLedgerEntries(DocumentType2, DocumentType, GenJournalLine."Document No.", DocumentNo);

        // Verify: Verify Application Rounding Entry on Detailed Customer Ledger Entry and Additional Currency Amount in G/L Entry.
        VerifyApplnRoundingCustLedger(GenJournalLine."Document No.", -AppRounding);
        VerifyGLEntry(GenJournalLine."Document No.", CurrencyCode, GenJournalLine."Document Type"::" ", AppRounding);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyPmntApplnRoundingError()
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
        CurrencyCode: Code[10];
        AppRounding: Decimal;
    begin
        // Verify Error when Unapply Entry of the type Appln. Rounding from Detailed Customer Ledger Entry.

        // Setup.
        CurrencyCode := CreateCurrency(0);  // Using 0 for Application Rounding Precision for Currency.
        LibraryERM.SetAddReportingCurrency(CurrencyCode);
        AppRounding := LibraryRandom.RandDec(5, 2);

        CreatePostApplyGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, CurrencyCode,
          10 * LibraryRandom.RandDec(100, 2), AppRounding);

        FindDetailedLedgerEntry(
          DetailedCustLedgEntry, GenJournalLine."Document No.", DetailedCustLedgEntry."Entry Type"::"Appln. Rounding");

        // Exercise. Unapply Payment from Detailed Customer ledger Entry.
        asserterror CustEntryApplyPostedEntries.UnApplyDtldCustLedgEntry(DetailedCustLedgEntry);

        // Verify: Verify Error when Unapply Entry of the type Appln. Rounding from Detailed Customer Ledger Entry.
        Assert.ExpectedTestFieldError(DetailedCustLedgEntry.FieldCaption("Entry Type"), Format(DetailedCustLedgEntry."Entry Type"::Application));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ClearAppliesToIDFromCLEWhenChangeValueOnGenJnlLine()
    var
        GenJnlLine: Record "Gen. Journal Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        // [SCENARIO 118226] Applies-to ID is cleared from Customer Ledger Entry when change value of General Journal Line
        Initialize();

        // [GIVEN] Customer Ledger Entry and General Journal Line with the same Applies-to ID
        FindOpenInvCustLedgEntry(CustLedgEntry);
        SetAppliesToIDOnCustLedgEntry(CustLedgEntry);
        CreateGenJnlLineWithAppliesToID(
          GenJnlLine, GenJnlLine."Account Type"::Customer, CustLedgEntry."Customer No.", CustLedgEntry."Applies-to ID");

        // [WHEN] Change "Applies-to ID" in General Journal Line
        GenJnlLine.Validate("Applies-to ID", LibraryUtility.GenerateGUID());
        GenJnlLine.Modify(true);

        // [THEN] "Applies-to ID" in Customer Ledger Entry is empty
        CustLedgEntry.Find();
        Assert.AreEqual('', CustLedgEntry."Applies-to ID", StrSubstNo(AppliesToIDIsNotEmptyOnLedgEntryErr, CustLedgEntry.TableCaption()));
        Assert.AreEqual(0, CustLedgEntry."Amount to Apply", AmountToApplyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ClearAppliesToIDFromCLEWhenDeleteGenJnlLine()
    var
        GenJnlLine: Record "Gen. Journal Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        // [SCENARIO 118226] Applies-to ID is cleared from Customer Ledger Entry when delete General Journal Line
        Initialize();

        // [GIVEN] Customer Ledger Entry and General Journal Line with the same Applies-to ID
        FindOpenInvCustLedgEntry(CustLedgEntry);
        SetAppliesToIDOnCustLedgEntry(CustLedgEntry);
        CreateGenJnlLineWithAppliesToID(
          GenJnlLine, GenJnlLine."Account Type"::Customer, CustLedgEntry."Customer No.", CustLedgEntry."Applies-to ID");

        // [WHEN] Delete General Journal Line
        GenJnlLine.Delete(true);

        // [THEN] "Applies-to ID" in Customer Ledger Entry is empty
        CustLedgEntry.Find();
        Assert.AreEqual('', CustLedgEntry."Applies-to ID", StrSubstNo(AppliesToIDIsNotEmptyOnLedgEntryErr, CustLedgEntry.TableCaption()));
        Assert.AreEqual(0, CustLedgEntry."Amount to Apply", AmountToApplyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ClearAppliesToDocNoValueFromGenJnlLine()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 120733] Customer Ledger Entry "Amount-to Apply" = 0 when blank "Applies-to Doc. No." field in General Journal Line
        Initialize();

        // [GIVEN] Customer Ledger Entry and General Journal Line with "Applies-to Doc. No"
        FindOpenInvCustLedgEntry(CustLedgEntry);
        CreateGenJnlLineWithAppliesToDocNo(
          GenJnlLine, GenJnlLine."Account Type"::Customer, CustLedgEntry."Customer No.", CustLedgEntry."Document No.");

        // [WHEN] Blank "Applies-to Doc. No." field in General Journal Line
        GenJnlLine.Validate("Applies-to Doc. No.", '');
        GenJnlLine.Modify(true);

        // [THEN] Customer Ledger Entry "Amount to Apply" = 0
        CustLedgEntry.Find();
        Assert.AreEqual(0, CustLedgEntry."Amount to Apply", AmountToApplyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteGenJnlLineWithAppliesToDocNo()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 120733] Customer Ledger Entry "Amount-to Apply" = 0 when delete General Journal Line with "Applies-to Doc. No."
        Initialize();

        // [GIVEN] Customer Ledger Entry and General Journal Line with "Applies-to Doc. No."
        FindOpenInvCustLedgEntry(CustLedgEntry);
        CreateGenJnlLineWithAppliesToDocNo(
          GenJnlLine, GenJnlLine."Account Type"::Customer, CustLedgEntry."Customer No.", CustLedgEntry."Document No.");

        // [WHEN] Delete General Journal Line
        GenJnlLine.Delete(true);

        // [THEN] Customer Ledger Entry "Amount to Apply" = 0
        CustLedgEntry.Find();
        Assert.AreEqual(0, CustLedgEntry."Amount to Apply", AmountToApplyErr);
    end;

    [Test]
    [HandlerFunctions('GeneralJournalTemplateListModalPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyAmountApplToExtDocNoWhenSetValue()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
        PostedDocNo: Code[20];
        ExpectedExtDocNo: Code[35];
    begin
        // [FEATURE] [Application] [Cash Receipt]
        // [SCENARIO 363069] Verify that External Doc No transferred when setting 'Applies-to Doc. No.' value in Cash Receipt Journal.

        // [GIVEN] Invoice customer ('External Document No.' non-empty).
        Initialize();
        PostInvoice(GenJournalLine);
        ExpectedExtDocNo := GenJournalLine."External Document No.";
        PostedDocNo := GenJournalLine."Document No.";

        // [GIVEN] Create Cash Receipt Journal Line for the customer.
        CreateCashReceiptJnlLine(GenJournalLine, GenJournalLine."Account No.");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        Commit();

        CashReceiptJournal.OpenEdit();
        CashReceiptJournal."Applies-to Doc. Type".SetValue(GenJournalLine."Applies-to Doc. Type"::Invoice);

        // [WHEN] Set 'Applies-to Doc. No.' manually to Posted Invoice doc. no.
        CashReceiptJournal."Applies-to Doc. No.".SetValue(PostedDocNo);
        CashReceiptJournal.OK().Invoke();

        // [THEN] External doc. no. transferred to 'Applied-to Ext. Doc. No.', but Amount is not.
        VerifyExtDocNoAmount(GenJournalLine, ExpectedExtDocNo, 0);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesModalPageHandler,GeneralJournalTemplateListModalPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyAmountApplToExtDocNoWhenLookUp()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
        ExpectedExtDocNo: Code[35];
        ExpectedAmount: Decimal;
    begin
        // [FEATURE] [Application] [Cash Receipt]
        // [SCENARIO 363069] Verify that Amount and External Doc No transferred when looking up 'Applies-to Doc. No.' value in Cash Receipt Journal.

        // [GIVEN] Invoice customer ('External Document No.' non-empty).
        Initialize();
        PostInvoice(GenJournalLine);
        ExpectedAmount := -GenJournalLine.Amount;
        ExpectedExtDocNo := GenJournalLine."External Document No.";

        // [GIVEN] Create Cash Receipt Journal Line for the customer.
        CreateCashReceiptJnlLine(GenJournalLine, GenJournalLine."Account No.");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        Commit();

        CashReceiptJournal.OpenEdit();
        CashReceiptJournal."Applies-to Doc. Type".SetValue(GenJournalLine."Applies-to Doc. Type"::Invoice);

        // [WHEN] Look up and set 'Applies-to Doc. No.' to Posted Invoice doc. no.
        CashReceiptJournal."Applies-to Doc. No.".Lookup();
        CashReceiptJournal.OK().Invoke();

        // [THEN] External doc. no. transferred to 'Applied-to Ext. Doc. No.' as well as Amount.
        VerifyExtDocNoAmount(GenJournalLine, ExpectedExtDocNo, ExpectedAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtJnlApplToInvWithNoDimDiscountAndDefDimErr()
    var
        DimensionValue: Record "Dimension Value";
        GenJournalLine: Record "Gen. Journal Line";
        CustomerNo: Code[20];
        PaymentAmount: Decimal;
    begin
        // [FEATURE] [Dimension] [Payment Discount]
        // [SCENARIO 376797] Error try posting sales payment journal without dimension applied to posted Invoice in case of Discount, "Payment Disc. Debit Acc." with default dimension with "Value Posting" = "Same Code"
        Initialize();

        // [GIVEN] Customer with "Payment Disc. Debit Acc." = "A"
        // [GIVEN] Default Dimension "D" with "Value Posting" = "Same Code" is set for G/L Account "A"
        CustomerNo := CreateCustomer();
        CreateDefaultDimensionGLAccSameValue(DimensionValue, CreateCustPostingGrPmtDiscDebitAccNo(CustomerNo));

        // [GIVEN] Posted Sales Invoice with Amount Including VAT = 10000 and possible Discount = 2%. No dimension is set.
        CreateAndPostGenJnlLine(
          GenJournalLine, WorkDate(), GenJournalLine."Document Type"::Invoice, LibraryRandom.RandIntInRange(1000, 2000), CustomerNo, '');
        PaymentAmount := -GenJournalLine.Amount + GenJournalLine.Amount * GetPmtTermsDiscountPct() / 100;

        // [GIVEN] Sales Journal with Payment Amount = 9800 and applied to posted Invoice. No dimension is set.
        // [WHEN] Post Sales Journal
        asserterror LibrarySales.CreatePaymentAndApplytoInvoice(
            GenJournalLine, CustomerNo, GenJournalLine."Document No.", PaymentAmount);

        // [THEN] Error occurs: "A dimension used in Gen. Journal Line GENERAL, CASH, 10000 has caused an error."
        Assert.ExpectedErrorCode(DialogTxt);
        Assert.ExpectedError(
          StrSubstNo(DimensionUsedErr,
            GenJournalLine.TableCaption(), GenJournalLine."Journal Template Name",
            GenJournalLine."Journal Batch Name", GenJournalLine."Line No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtJnlApplToInvWithDimDiscountAndDefDim()
    var
        DimensionValue: Record "Dimension Value";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        CustomerNo: Code[20];
        GLAccountNo: Code[20];
        PaymentAmount: Decimal;
    begin
        // [FEATURE] [Dimension] [Payment Discount]
        // [SCENARIO 376797] Sales payment journal with dimension applied to posted Invoice can be posted in case of Discount, "Payment Disc. Debit Acc." with default dimension with "Value Posting" = "Same Code"
        Initialize();

        // [GIVEN] Customer with "Payment Disc. Debit Acc." = "A"
        // [GIVEN] Default Dimension "D" with "Value Posting" = "Same Code" is set for G/L Account "A"
        CustomerNo := CreateCustomer();
        GLAccountNo := CreateCustPostingGrPmtDiscDebitAccNo(CustomerNo);
        CreateDefaultDimensionGLAccSameValue(DimensionValue, GLAccountNo);

        // [GIVEN] Posted Sales Invoice with Amount Including VAT = 10000 and possible Discount = 2%. No dimension is set.
        CreateAndPostGenJnlLine(
          GenJournalLine, WorkDate(), GenJournalLine."Document Type"::Invoice, LibraryRandom.RandIntInRange(1000, 2000), CustomerNo, '');
        PaymentAmount := -GenJournalLine.Amount + GenJournalLine.Amount * GetPmtTermsDiscountPct() / 100;

        // [GIVEN] Sales Journal with Payment Amount = 9800 and applied to posted Invoice. Dimension "D" is set.
        CreateGenJnlLineWithAppliesToDocNo(
          GenJournalLine, GenJournalLine."Account Type"::Customer, CustomerNo, GenJournalLine."Document No.");
        GenJournalLine.Validate("Dimension Set ID", LibraryDimension.CreateDimSet(0, DimensionValue."Dimension Code", DimensionValue.Code));
        GenJournalLine.Validate(Amount, PaymentAmount);
        GenJournalLine.Modify();

        // [WHEN] Post Sales Journal
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Posted G/L Entry with "G/L Account No." = "A" has Dimension "D"
        FindGLEntry(GLEntry, GenJournalLine."Document No.", GLAccountNo);
        Assert.AreEqual(GenJournalLine."Dimension Set ID", GLEntry."Dimension Set ID", GLEntry.FieldCaption("Dimension Set ID"))
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtToInvApplWithNoDimDiscountAndDefDim()
    var
        DimensionValue: Record "Dimension Value";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        CustomerNo: Code[20];
        InvoiceDocumentNo: Code[20];
        GLAccountNo: Code[20];
        PaymentAmount: Decimal;
    begin
        // [FEATURE] [Dimension] [Payment Discount]
        // [SCENARIO 376797] Posted sales payment without dimension can be applied to posted Invoice in case of Discount, "Payment Disc. Debit Acc." with default dimension with "Value Posting" = "Same Code"
        Initialize();

        // [GIVEN] Customer with "Payment Disc. Debit Acc." = "A"
        // [GIVEN] Default Dimension "D" with "Value Posting" = "Same Code" is set for G/L Account "A"
        CustomerNo := CreateCustomer();
        GLAccountNo := CreateCustPostingGrPmtDiscDebitAccNo(CustomerNo);
        CreateDefaultDimensionGLAccSameValue(DimensionValue, GLAccountNo);

        // [GIVEN] Posted Sales Invoice with Amount Including VAT = 10000 and possible Discount = 2%. No dimension is set.
        CreateAndPostGenJnlLine(
          GenJournalLine, WorkDate(), GenJournalLine."Document Type"::Invoice, LibraryRandom.RandIntInRange(1000, 2000), CustomerNo, '');
        InvoiceDocumentNo := GenJournalLine."Document No.";
        PaymentAmount := -GenJournalLine.Amount + GenJournalLine.Amount * GetPmtTermsDiscountPct() / 100;

        // [GIVEN] Posted Sales Payment with Amount = 9800. No dimension is set.
        CreateAndPostGenJnlLine(
          GenJournalLine, WorkDate(), GenJournalLine."Document Type"::Payment,
          PaymentAmount, GenJournalLine."Account No.", '');

        // [WHEN] Post Payment to Invoice application
        ApplyAndPostPaymentToInvoice(GenJournalLine."Document No.", InvoiceDocumentNo);

        // [THEN] Posted G/L Entry with "G/L Account No." = "A" has no Dimension ("Dimension Set ID" = 0).
        FindGLEntry(GLEntry, GenJournalLine."Document No.", GLAccountNo);
        Assert.AreEqual(0, GLEntry."Dimension Set ID", GLEntry.FieldCaption("Dimension Set ID"))
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesWithSetAppliesToIDModalPageHandler,GeneralJournalTemplateListModalPageHandler')]
    [Scope('OnPrem')]
    procedure ClearAmountToApplyWhenDeleteAppliesToIDUT()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
        ExpectedAmount: Decimal;
    begin
        // [FEATURE] [Application] [Cash Receipt]
        // [SCENARIO 230936] When deleting the value in "Applies-to-ID" field on the "Apply Customer Entries" page manually, "Amount to Apply" must be reset to zero

        // [GIVEN] Posted Sales Invoice
        Initialize();

        PostInvoice(GenJournalLine);
        ExpectedAmount := GenJournalLine.Amount;

        // [GIVEN] Create Cash Receipt Journal Line
        CreateCashReceiptJnlLine(GenJournalLine, GenJournalLine."Account No.");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        Commit();

        CashReceiptJournal.OpenEdit();
        CashReceiptJournal."Applies-to Doc. Type".SetValue(GenJournalLine."Applies-to Doc. Type"::Invoice);

        // [GIVEN] Open "Apply Customer Entries" page
        LibraryVariableStorage.Enqueue(ExpectedAmount);
        CashReceiptJournal."Apply Entries".Invoke();

        // [GIVEN] Use "Set Applies-to ID"
        // Done in ApplyCustomerEntriesWithSetAppliesToIDModalPageHandler

        // [WHEN] Manually remove "Applies-to ID"
        // Done in ApplyCustomerEntriesWithSetAppliesToIDModalPageHandler

        // [THEN] "Amount to apply" on "Apply Customer Entries" page is 0
        // Done in ApplyCustomerEntriesWithSetAppliesToIDModalPageHandler

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('TwoApplyCustomerEntriesModalPageHandler,GeneralJournalTemplateListModalPageHandler')]
    [Scope('OnPrem')]
    procedure ClearAppliesToIDInOneRecordOfSeveralCustLedgEntries()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        // [FEATURE] [Application] [Cash Receipt]
        // [SCENARIO 230936] When deleting the value in "Applies-to-ID" field on the "Apply Customer Entries" page manually, "Applies-to-ID" should not be deleted in other lines having the same "Applies-to-ID"

        Initialize();

        // [GIVEN] Two Posted Sales Invoices
        CreateAndPostTwoGenJournalLinesForSameCustomer(GenJournalLine);

        // [GIVEN] Create Cash Receipt Journal Line
        CreateCashReceiptJnlLine(GenJournalLine, GenJournalLine."Account No.");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        Commit();

        CashReceiptJournal.OpenEdit();
        CashReceiptJournal."Applies-to Doc. Type".SetValue(GenJournalLine."Applies-to Doc. Type"::Invoice);

        // [GIVEN] Open "Apply Customer Entries" page with two lines
        CashReceiptJournal."Apply Entries".Invoke();

        // [GIVEN] Use "Set Applies-to ID" on both lines, "Applies-to ID" of the 1st line = "A", "Applies-to ID" of the 2nd line = "A"
        // Done in SeveralEntriesWithSameAppliesToIDModalPageHandler

        // [WHEN] Manually remove "Applies-to ID" on the 2nd line
        // Done in SeveralEntriesWithSameAppliesToIDModalPageHandler

        // [THEN] "Applies-to ID" of the 1st line = "A"
        // Done in SeveralEntriesWithSameAppliesToIDModalPageHandler

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('TwoEntriesWithSameAppliesToIDModalPageHandler,GeneralJournalTemplateListModalPageHandler')]
    [Scope('OnPrem')]
    procedure SetAppliesToIDInOneRecordOfSeveralCustLedgEntries()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        // [FEATURE] [Application] [Cash Receipt]
        // [SCENARIO 230936] When manually set the value in "Applies-to-ID" field on the "Apply Customer Entries" page, "Applies-to-ID" of the other lines with the same value is not changed

        Initialize();

        // [GIVEN] Two Posted Sales Invoices
        CreateAndPostTwoGenJournalLinesForSameCustomer(GenJournalLine);

        // [GIVEN] Create Cash Receipt Journal Line
        CreateCashReceiptJnlLine(GenJournalLine, GenJournalLine."Account No.");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        Commit();

        CashReceiptJournal.OpenEdit();
        CashReceiptJournal."Applies-to Doc. Type".SetValue(GenJournalLine."Applies-to Doc. Type"::Invoice);

        // [GIVEN] Open "Apply Customer Entries" page with two lines
        CashReceiptJournal."Apply Entries".Invoke();

        // [GIVEN] Use "Set Applies-to ID" action on 1st line, "Applies-to ID" of the 1st line = "A"
        // Done in SeveralApplyCustomerEntriesModalPageHandler

        // [WHEN] Manually set "Applies-to ID" on the 2nd line = "A"
        // Done in SeveralApplyCustomerEntriesModalPageHandler

        // [THEN] "Applies-to ID" of the 1st line = "A"
        // Done in SeveralApplyCustomerEntriesModalPageHandler

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('TwoEntriesWithDifferentAppliesToIDModalPageHandler,GeneralJournalTemplateListModalPageHandler')]
    [Scope('OnPrem')]
    procedure SetDifferentAppliesToIDInOneRecordOfSeveralCustLedgEntries()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        // [FEATURE] [Application] [Cash Receipt]
        // [SCENARIO 230936] When manually set the value in "Applies-to-ID" field on the "Apply Customer Entries" page, "Applies-to-ID" of the other lines with different value is not changed

        Initialize();

        // [GIVEN] Two Posted Sales Invoices
        CreateAndPostTwoGenJournalLinesForSameCustomer(GenJournalLine);

        // [GIVEN] Create Cash Receipt Journal Line
        CreateCashReceiptJnlLine(GenJournalLine, GenJournalLine."Account No.");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        Commit();

        CashReceiptJournal.OpenEdit();
        CashReceiptJournal."Applies-to Doc. Type".SetValue(GenJournalLine."Applies-to Doc. Type"::Invoice);

        // [GIVEN] Open "Apply Customer Entries" page with two lines
        CashReceiptJournal."Apply Entries".Invoke();

        // [GIVEN] Use "Set Applies-to ID" action on 1st line, "Applies-to ID" of the 1st line = "A"
        // Done in SeveralEntriesWithDifferentAppliesToIDModalPageHandler

        // [WHEN] Manually set "Applies-to ID" of the 2nd line = "B"
        // Done in SeveralEntriesWithDifferentAppliesToIDModalPageHandler

        // [THEN] "Applies-to ID" of the 1st line = "A", "Applies-to ID" of the 2nd line = "B"
        // Done in SeveralEntriesWithDifferentAppliesToIDModalPageHandler

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GeneralJournalTemplateListModalPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyExtDocNoWhenAppliesToDocSetValue()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
        PostedDocNo: Code[35];
        OriginalExtDocNo: Code[35];
        InvoiceExtDocNo: Code[35];
    begin
        // [FEATURE] [Application] [Cash Receipt]
        // [SCENARIO 278790] Verify that External Doc No is not filled when looking up 'Applies-to Doc. No.' value and "Applies-to Ext. Doc. No" is
        Initialize();

        // [GIVEN] Invoice customer ('External Document No.' non-empty).
        PostInvoice(GenJournalLine);
        PostedDocNo := GenJournalLine."Document No.";
        InvoiceExtDocNo := GenJournalLine."External Document No.";

        // [GIVEN] Create Cash Receipt Journal Line for the customer with a filled external doc no but empty Account No
        CreateCashReceiptJnlLine(GenJournalLine, '');
        OriginalExtDocNo := GenJournalLine."External Document No.";

        // [GIVEN] Cash Receipt Journal was open
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        Commit();
        CashReceiptJournal.OpenEdit();

        // [WHEN] Set 'Applies-to Doc. No.' value to Posted Invoice doc. no.
        CashReceiptJournal."Applies-to Doc. No.".SetValue(PostedDocNo);
        CashReceiptJournal.OK().Invoke();

        // [THEN] External doc. no. of posted invoice is not transferred to 'External Document No.' of Cash Receipt Journal Line
        GenJournalLine.Find();
        GenJournalLine.TestField("External Document No.", OriginalExtDocNo);
        // [THEN] Applies-to Ext. Doc. No. of Cash Receipt Journal Line contains External Document No. of the posted invoice
        GenJournalLine.TestField("Applies-to Ext. Doc. No.", InvoiceExtDocNo);
    end;

    [Test]
    [HandlerFunctions('GeneralJournalTemplateListModalPageHandler,ApplyCustomerEntriesWithAmountModalPageHandler')]
    [Scope('OnPrem')]
    procedure ApplyInvoiceToSecondPaymentLineWhenAnotherInvoiceIsMarkedAsApplied()
    var
        GenJournalLineInv: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [FEATURE] [Application] [Payment Journal] [UI]
        // [SCENARIO 379474] Apply payment line to the invoice when another invoice has Applied-to ID
        Initialize();

        // [GIVEN] Two invoices "Inv1" of Amount = 1000 and "Inv2" of Amount = 2000
        CreateAndPostTwoGenJournalLinesForSameCustomer(GenJournalLineInv);
        CustLedgerEntry.SetRange("Customer No.", GenJournalLineInv."Account No.");
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields(Amount);

        // [GIVEN] Two payment journal lines for the customer with Amount = 0
        CreatePaymentJournalBatch(GenJournalBatch);
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, GenJournalLineInv."Account No.",
          "Gen. Journal Account Type"::"G/L Account", '', 0);
        GenJournalLine.Validate(
            "Document No.", LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("Document No."), DATABASE::"Gen. Journal Line"));
        GenJournalLine."Line No." := LibraryUtility.GetNewRecNo(GenJournalLine, GenJournalLine.FieldNo("Line No."));
        GenJournalLine.Insert();
        Commit();

        // [GIVEN] Set Applies-to ID on first payment line for first invoice, payment journal Line gets Amount = -1000
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        PaymentJournal.OpenEdit();
        LibraryVariableStorage.Enqueue(CustLedgerEntry."Document No.");
        LibraryVariableStorage.Enqueue(CustLedgerEntry.Amount);
        PaymentJournal.ApplyEntries.Invoke();
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.FindFirst();
        GenJournalLine.TestField(Amount, -CustLedgerEntry.Amount);

        // [WHEN] Set Applies-to ID on second payment line for second invoice, Amount to Apply = 1000
        LibraryVariableStorage.Enqueue(GenJournalLineInv."Document No.");
        LibraryVariableStorage.Enqueue(GenJournalLineInv.Amount / 2);
        PaymentJournal.Next();
        PaymentJournal.ApplyEntries.Invoke();
        PaymentJournal.OK().Invoke();

        // [THEN] Second payment journal line gets Amount = -1000
        GenJournalLine.FindLast();
        GenJournalLine.TestField(Amount, -GenJournalLineInv.Amount / 2);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyFCYInvoicesToFCYPaymentsWithBalancePaymentLineApplnBtwCurrenciesAll()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry1: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        CurrencyCode1: Code[10];
        CurrencyCode2: Code[10];
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Application] [Currency]
        // [SCENARIO 379474] Apply two FCY invoices to two FCY payments with "Appln. between Currencies" = All
        Initialize();

        // [GIVEN] "Appln. between Currencies" = All in Sales Setup
        UpdateApplnBetweenCurrenciesAllInSalesSetup();

        // [GIVEN] Two invoices "Inv1" in "FCY1" of Amount = 1000 and "Inv2" in "FCY2" of Amount = 2000
        CurrencyCode1 := CreateCurrency(0);
        CurrencyCode2 := CreateCurrency(0);
        CustomerNo := LibrarySales.CreateCustomerNo();
        CreateCustomerInvoice(CustLedgerEntry1, CustomerNo, LibraryRandom.RandIntInRange(1000, 2000), CurrencyCode1);
        CreateCustomerInvoice(CustLedgerEntry2, CustomerNo, LibraryRandom.RandIntInRange(1000, 2000), CurrencyCode2);

        // [GIVEN] First payment journal line for the customer with Amount = -2000 in "FCY2"
        // [GIVEN] Second invoice in "FCY2" is marked with Applies-to ID and Amount to Apply = 2000
        CreatePaymentJournalBatch(GenJournalBatch);
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, CustomerNo,
          "Gen. Journal Account Type"::"G/L Account", '', 0);
        UpdateGenJnlLineAppln(GenJournalLine, CurrencyCode2, -CustLedgerEntry2.Amount);
        UpdateCustLedgerEntryAppln(CustLedgerEntry2, GenJournalLine."Document No.", CustLedgerEntry2.Amount);

        // [GIVEN] Second payment journal line for the customer with Amount = -500 in "FCY1"
        // [GIVEN] First invoice in "FCY1" is marked with Applies-to ID and Amount to Apply = 500
        GenJournalLine."Line No." := LibraryUtility.GetNewRecNo(GenJournalLine, GenJournalLine.FieldNo("Line No."));
        GenJournalLine.Insert();
        UpdateGenJnlLineAppln(GenJournalLine, CurrencyCode1, -CustLedgerEntry1.Amount / 2);
        UpdateCustLedgerEntryAppln(CustLedgerEntry1, GenJournalLine."Document No.", CustLedgerEntry1.Amount / 2);

        // [GIVEN] Balance payment journal line for bank account in LCY
        GenJournalLine."Line No." := LibraryUtility.GetNewRecNo(GenJournalLine, GenJournalLine.FieldNo("Line No."));
        GenJournalLine.Insert();
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::"Bank Account");
        GenJournalLine.Validate("Account No.", LibraryERM.CreateBankAccountNo());
        UpdateGenJnlLineAppln(
          GenJournalLine, '', CustLedgerEntry1."Amount (LCY)" / 2 + CustLedgerEntry2."Amount (LCY)");

        // [WHEN] Post payment journal lines
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Invoice in "FCY1" has "Remaining Amount" = 500, Invoice in "FCY2" has "Remaining Amount" = 0
        CustLedgerEntry1.CalcFields("Remaining Amount");
        CustLedgerEntry1.TestField("Remaining Amount", CustLedgerEntry1.Amount / 2);
        CustLedgerEntry2.CalcFields("Remaining Amount");
        CustLedgerEntry2.TestField("Remaining Amount", 0);

        // [THEN] First payment lines in "FCY2" is applied with to both first and second invoices
        VerifyPaymentWithDetailedEntries(
          CustomerNo, CurrencyCode2, CustLedgerEntry1."Entry No.", CustLedgerEntry2."Entry No.", 1, 1);
        // [THEN] Second payment line in "FCY1" is applied to second invoice in "FCY2"
        VerifyPaymentWithDetailedEntries(
          CustomerNo, CurrencyCode1, CustLedgerEntry1."Entry No.", CustLedgerEntry2."Entry No.", 0, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyFCYInvoicesToFCYPaymentsWithBalancePaymentLineApplnBtwCurrenciesNone()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry1: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        CurrencyCode1: Code[10];
        CurrencyCode2: Code[10];
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Application] [Currency]
        // [SCENARIO 379474] Apply two FCY invoices to two FCY payments with "Appln. between Currencies" = None
        Initialize();

        // [GIVEN] "Appln. between Currencies" = None in Sales Setup
        UpdateApplnBetweenCurrenciesNoneInSalesSetup();

        // [GIVEN] Two invoices "Inv1" in "FCY1" of Amount = 1000 and "Inv2" in "FCY2" of Amount = 2000
        CurrencyCode1 := CreateCurrency(0);
        CurrencyCode2 := CreateCurrency(0);
        CustomerNo := LibrarySales.CreateCustomerNo();
        CreateCustomerInvoice(CustLedgerEntry1, CustomerNo, LibraryRandom.RandIntInRange(1000, 2000), CurrencyCode1);
        CreateCustomerInvoice(CustLedgerEntry2, CustomerNo, LibraryRandom.RandIntInRange(1000, 2000), CurrencyCode2);

        // [GIVEN] First payment journal line for the customer with Amount = -2000 in "FCY2"
        // [GIVEN] Second invoice in "FCY2" is marked with Applies-to ID and Amount to Apply = 2000
        CreatePaymentJournalBatch(GenJournalBatch);
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, CustomerNo,
          "Gen. Journal Account Type"::"G/L Account", '', 0);
        UpdateGenJnlLineAppln(GenJournalLine, CurrencyCode2, -CustLedgerEntry2.Amount);
        UpdateCustLedgerEntryAppln(CustLedgerEntry2, GenJournalLine."Document No.", CustLedgerEntry2.Amount);

        // [GIVEN] Second payment journal line for the customer with Amount = -500 in "FCY1"
        // [GIVEN] First invoice in "FCY1" is marked with Applies-to ID and Amount to Apply = 500
        GenJournalLine."Line No." := LibraryUtility.GetNewRecNo(GenJournalLine, GenJournalLine.FieldNo("Line No."));
        GenJournalLine.Insert();
        UpdateGenJnlLineAppln(GenJournalLine, CurrencyCode1, -CustLedgerEntry1.Amount / 2);
        UpdateCustLedgerEntryAppln(CustLedgerEntry1, GenJournalLine."Document No.", CustLedgerEntry1.Amount / 2);

        // [GIVEN] Balance payment journal line for bank account in LCY
        GenJournalLine."Line No." := LibraryUtility.GetNewRecNo(GenJournalLine, GenJournalLine.FieldNo("Line No."));
        GenJournalLine.Insert();
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::"Bank Account");
        GenJournalLine.Validate("Account No.", LibraryERM.CreateBankAccountNo());
        UpdateGenJnlLineAppln(
          GenJournalLine, '', CustLedgerEntry1."Amount (LCY)" / 2 + CustLedgerEntry2."Amount (LCY)");

        // [WHEN] Post payment journal lines
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Invoice in "FCY1" has "Remaining Amount" = 500, Invoice in "FCY2" has "Remaining Amount" = 0
        CustLedgerEntry1.CalcFields("Remaining Amount");
        CustLedgerEntry1.TestField("Remaining Amount", CustLedgerEntry1.Amount / 2);
        CustLedgerEntry2.CalcFields("Remaining Amount");
        CustLedgerEntry2.TestField("Remaining Amount", 0);

        // [THEN] First payment lines in "FCY2" is applied with the second invoice in "FCY2"
        VerifyPaymentWithDetailedEntries(
          CustomerNo, CurrencyCode2, CustLedgerEntry1."Entry No.", CustLedgerEntry2."Entry No.", 0, 1);
        // [THEN] Second payment line in "FCY1" is applied to the first invoice in "FCY1"
        VerifyPaymentWithDetailedEntries(
          CustomerNo, CurrencyCode1, CustLedgerEntry1."Entry No.", CustLedgerEntry2."Entry No.", 1, 0);
    end;

    [Test]
    [HandlerFunctions('MultipleSelectionApplyCustomerEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure CheckPostingDateForMultipleCustLedgEntriesWhenSetAppliesToIDOnApplyCustomerEntries()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Application]
        // [SCENARIO 383611] When "Set Applies-to ID" on "Apply Customer Entries" page is used for multiple lines, Posting date of each line is checked.
        Initialize();

        // [GIVEN] Two Posted Sales Invoices with Posting Date = "01.01.21" / "21.01.21".
        LibrarySales.CreateCustomer(Customer);
        CreateAndPostGenJnlLine(
            GenJournalLine, LibraryRandom.RandDate(-10),
            GenJournalLine."Document Type"::Invoice, LibraryRandom.RandInt(100), Customer."No.", '');
        CreateAndPostGenJnlLine(
            GenJournalLine, LibraryRandom.RandDate(10),
            GenJournalLine."Document Type"::Invoice, LibraryRandom.RandInt(100), Customer."No.", '');

        // [GIVEN] Cash Receipt Journal Line with Posting Date = "11.01.21"
        CreateCashReceiptJnlLine(GenJournalLine, GenJournalLine."Account No.");

        // [GIVEN] Cash Receipt Journal Line with Currency = blank.
        CreateCashReceiptJnlLine(GenJournalLine, GenJournalLine."Account No.");
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Modify(true);

        // [GIVEN] "Apply Customer Entries" page is opened by Codeunit "Gen. Jnl.-Apply" run for Cash Receipt Journal Line.
        LibraryVariableStorage.Enqueue(GenJournalLine."Account No.");
        asserterror CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Apply", GenJournalLine);

        // [WHEN] Multiple lines are selected on "Apply Customer Entries" page and action "Set Applies-to ID" is used.
        // Done in MultipleSelectionApplyCustomerEntriesModalPageHandler

        // [THEN] Error "You cannot apply and post an entry to an entry with an earlier posting date." is thrown.
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(EarlierPostingDateErr);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MultipleSelectionApplyCustomerEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure CheckCurrencyForMultipleCustLedgEntriesWhenSetAppliesToIDOnApplyCustomerEntries()
    var
        Currency: Record Currency;
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [Application]
        // [SCENARIO 383611] When "Set Applies-to ID" on "Apply Customer Entries" page is used for multiple lines, Currency Code of each line is checked.
        Initialize();

        // [GIVEN] "Appln. between Currencies" in "Sales & Receivables Setup" is set to None.
        LibrarySales.SetApplnBetweenCurrencies(SalesReceivablesSetup."Appln. between Currencies"::None);

        // [GIVEN] Two Posted Sales Invoices with Currency Code = blank / "JPY".
        LibrarySales.CreateCustomer(Customer);
        CreateAndPostGenJnlLine(
            GenJournalLine, WorkDate(),
            GenJournalLine."Document Type"::Invoice, LibraryRandom.RandInt(100), Customer."No.", '');
        Currency.Get(LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 1));
        CreateAndPostGenJnlLine(
            GenJournalLine, WorkDate(),
            GenJournalLine."Document Type"::Invoice, LibraryRandom.RandInt(100), Customer."No.", Currency.Code);

        // [GIVEN] Cash Receipt Journal Line with Currency = blank.
        CreateCashReceiptJnlLine(GenJournalLine, GenJournalLine."Account No.");
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Modify(true);

        // [GIVEN] "Apply Customer Entries" page is opened by Codeunit "Gen. Jnl.-Apply" run for Cash Receipt Journal Line.
        LibraryVariableStorage.Enqueue(GenJournalLine."Account No.");
        asserterror CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Apply", GenJournalLine);

        // [WHEN] Multiple lines are selected on "Apply Customer Entries" page and action "Set Applies-to ID" is used.
        // Done in MultipleSelectionApplyCustomerEntriesModalPageHandler

        // [THEN] Error "All entries in one application must be in the same currency." is thrown.
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(DifferentCurrenciesErr);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotClearAppliesToDocNoValueFromGenJnlLine()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 446576] When selecting the Applies-to Doc. No. manually in General Journal, the Account No. is  filled automatically, 
        // but the Applies-to Doc. No. deleted, if the lines is created from Bank Acc. Reconciliation.

        Initialize();

        // [GIVEN] Customer Ledger Entry and General Journal Line with "Applies-to Doc. No"
        FindOpenInvCustLedgEntry(CustLedgEntry);
        CreateGenJnlLineWithAppliesToDocNo(
          GenJnlLine, GenJnlLine."Account Type"::Customer, '', CustLedgEntry."Document No.");

        // [WHEN] Validate "Applies-to Doc. No." field in General Journal Line. And "Applies-to Doc. No." will not be deleted.
        GenJnlLine.Validate("Applies-to Doc. No.", CustLedgEntry."Document No.");
        GenJnlLine.Modify(true);

        // [VERIFY] "Applies-to Doc. No." will be same as  in Customer Ledger Entry
        Assert.AreEqual(GenJnlLine."Applies-to Doc. No.", CustLedgEntry."Document No.", AppliesToDocErr);
    end;

    [Test]
    [HandlerFunctions('MultiplCustomerEntrieseApplyModalPageHandler')]
    [Scope('OnPrem')]
    procedure ValidateAmountOnCashReceiptJournalLineWhenSetAppliesToIDOnApplyCustomerEntries()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        ExpectedAmount: Decimal;
    begin
        // [FEATURE] [Application]
        // [SCENARIO 461143] When a user applies multiple documents in the Apply Customer Entries page the summed amount on the journal line is not correct.
        Initialize();

        // [GIVEN] Create Customer and Post first Sales Invoice
        LibrarySales.CreateCustomer(Customer);
        CreateAndPostGenJnlLine(
            GenJournalLine, WorkDate(),
            GenJournalLine."Document Type"::Invoice, LibraryRandom.RandInt(100), Customer."No.", '');
        ExpectedAmount := -GenJournalLine.Amount;

        // [GIVEN] Cash Receipt Journal Line
        CreateCashReceiptJnlLine(GenJournalLine2, GenJournalLine."Account No.");
        GenJournalLine2.Validate("Applies-to Doc. Type", GenJournalLine2."Applies-to Doc. Type"::Invoice);
        GenJournalLine2.Modify(true);

        // [GIVEN] "Apply Customer Entries" page is opened by Codeunit "Gen. Jnl.-Apply" run for Cash Receipt Journal Line.
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Apply", GenJournalLine2);

        // [GIVEN] Set Cash Receipt General Line amount to Zero
        GenJournalLine2.Validate(Amount, 0);
        GenJournalLine2.Modify();

        // [GIVEN] Post another Sales Invoice
        CreateAndPostGenJnlLine(
            GenJournalLine, WorkDate(),
            GenJournalLine."Document Type"::Invoice, LibraryRandom.RandInt(100), Customer."No.", '');
        ExpectedAmount -= GenJournalLine.Amount;

        // [GIVEN] "Apply Customer Entries" page is opened by Codeunit "Gen. Jnl.-Apply" run for Cash Receipt Journal Line.
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Apply", GenJournalLine2);

        // [VERIFY] Verify: Summed Amount on Cash Receipt Journal Line
        Assert.AreEqual(true, (GenJournalLine2."Applies-to ID" <> ''), AppliesToIDErr);
        Assert.AreEqual(ExpectedAmount, GenJournalLine2.Amount, SummedAmountWrongErr);
    end;

    [Test]
    [HandlerFunctions('GeneralJournalTemplateListModalPageHandler,ApplyCustomerEntriesModalPageHandlerWithSetAppliesID')]
    procedure SourceCurrAmountHasCorrectSignUsingMultiplePostingGroup()
    var
        Currency: Record Currency;
        Customer: Record Customer;
        CustomerPostingGroup: array[2] of Record "Customer Posting Group";
        GenJournalLine: Record "Gen. Journal Line";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvHeader: Record "Sales Invoice Header";
        VATPostingSetup: Record "VAT Posting Setup";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
        VATCalculationType: Enum "Tax Calculation Type";
        PaymentDocNo: Code[20];
    begin
        // [SCENARIO 563179] Source Currency Amount has correct sign if pay non-base currency invoice using Multiple Posting Groups feature.
        Initialize();

        // [GIVEN] Enable Multiple Posting Group in Sales Setup.
        SetSalesAllowMultiplePostingGroups(true);

        // [GIVEN] Create Customer Posting Group One.
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup[1]);

        // [GIVEN] Create Alternative Customer Posting Group. 
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup[2]);
        LibrarySales.CreateAltCustomerPostingGroup(CustomerPostingGroup[1].Code, CustomerPostingGroup[2].Code);
        LibrarySales.CreateAltCustomerPostingGroup(CustomerPostingGroup[2].Code, CustomerPostingGroup[1].Code);

        // [GIVEN] Create VAT Posting Setup.
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATCalculationType::"Normal VAT", 25);

        // [GIVEN Create Customer.
        CreateCustomerWithAllowMultiplePostingGroups(
            Customer, CustomerPostingGroup[1].Code,
            Currency.Code, VATPostingSetup."VAT Bus. Posting Group");

        // [GIVEN] Create Currency with Exchange Rates.
        Currency.Get(LibraryERM.CreateCurrencyWithRandomExchRates());

        // [GIVEN] Create Item.
        Item.Get(LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"));

        // [GIVEN] Create Sales Header and validate currency code and customer posting group.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Currency Code", Currency.Code);
        SalesHeader.Validate("Customer Posting Group", CustomerPostingGroup[2].Code);
        SalesHeader.Modify(true);

        // [GIVEN] Create Sales Line.
        LibrarySales.CreateSalesLineWithUnitPrice(
            SalesLine, SalesHeader, Item."No.", LibraryRandom.RandIntInRange(100, 100), LibraryRandom.RandInt(0));

        // [GIVEN] Post Sales Invoice.
        SalesInvHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [GIVEN] Create Cash Receipt Journal Line for the customer.
        CreateCashReceiptJnlLine(GenJournalLine, Customer."No.");
        GenJournalLine.Validate("Currency Code", Currency.Code);
        GenJournalLine.Modify(true);
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        PaymentDocNo := GenJournalLine."Document No.";
        Commit();

        // [WHEN] Apply Cash Receipt to Posted Invoice and Post
        LibraryVariableStorage.Enqueue(SalesInvHeader."No.");
        CashReceiptJournal.OpenEdit();
        CashReceiptJournal."Applies-to Doc. Type".SetValue(GenJournalLine."Applies-to Doc. Type"::Invoice);
        CashReceiptJournal."Apply Entries".Invoke();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] VErify Source Currency amount has same sign as appear in GL Entry Amount field.
        VerifyGLEntrySourceCurrenyAmount(PaymentDocNo, Currency.Code, GenJournalLine."Document Type"::Payment);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Apply Sales/Receivables");

        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Apply Sales/Receivables");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateAccountInCustomerPostingGroup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        ModifyGenJnlBatchNoSeries();
        isInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Apply Sales/Receivables");
    end;

    local procedure ApplyAndPostPaymentToInvoice(PmtDocumentNo: Code[20]; InvDocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.ApplyCustomerLedgerEntries(
          CustLedgerEntry."Document Type"::Payment, CustLedgerEntry."Document Type"::Invoice,
          PmtDocumentNo, InvDocumentNo);
    end;

    local procedure PostAndApplyGenLines(var GenJournalLine: Record "Gen. Journal Line"; DueDate: Date) DocumentNo: Code[20]
    begin
        // Setup: Create Invoice and Payment General Lines and Post them.
        CreateAndPostGenJnlLine(
          GenJournalLine, WorkDate(), GenJournalLine."Document Type"::Invoice, LibraryRandom.RandInt(10000), CreateCustomer(), '');
        DocumentNo := GenJournalLine."Document No.";
        CreateAndPostGenJnlLine(
          GenJournalLine, DueDate, GenJournalLine."Document Type"::Payment, -GenJournalLine.Amount, GenJournalLine."Account No.", '');

        // Exercise: Apply a Payment to Invoice.
        ApplyAndPostPaymentToInvoice(GenJournalLine."Document No.", DocumentNo);
    end;

    local procedure CalcDueDateAndPaymentDiscount(var DueDate: Date; var PaymentDiscountPercent: Decimal)
    var
        PaymentTerms: Record "Payment Terms";
    begin
        // Calculate Due Date and Discount Percentage.
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        DueDate := CalcDate(PaymentTerms."Discount Date Calculation", WorkDate());
        PaymentDiscountPercent := PaymentTerms."Discount %";
    end;

    local procedure CreateCurrency(ApplnRoundingPrecision: Decimal): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        Currency.Validate("Residual Gains Account", Currency."Realized Gains Acc.");
        Currency.Validate("Residual Losses Account", Currency."Realized Losses Acc.");
        Currency.Validate("Appln. Rounding Precision", ApplnRoundingPrecision);
        Currency.Modify(true);

        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        PaymentTerms: Record "Payment Terms";
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerInvoice(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; Amount: Decimal; Currency: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.Init();
        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLine,
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, CustomerNo, Amount);
        GenJournalLine.Validate("Currency Code", Currency);
        GenJournalLine.Modify(true);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        CustLedgerEntry.CalcFields(Amount, "Amount (LCY)", "Remaining Amount");
    end;

    local procedure CreateAndPostGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal; CustomerNo: Code[20]; CurrencyCode: Code[10])
    begin
        CreateGenJnlLine(GenJournalLine, PostingDate, DocumentType, Amount, CustomerNo, CurrencyCode);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal; CustomerNo: Code[20]; CurrencyCode: Code[10])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::Customer, CustomerNo, Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateAndPostTwoGenJournalLinesForSameCustomer(var GenJournalLine: Record "Gen. Journal Line")
    var
        CustomerNo: Code[20];
    begin
        CustomerNo := LibrarySales.CreateCustomerNo();
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer,
          CustomerNo, LibraryRandom.RandIntInRange(1000, 2000));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer,
          CustomerNo, LibraryRandom.RandIntInRange(1000, 2000));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePostApplyGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; CurrencyCode: Code[10]; Amount: Decimal; AppRounding: Decimal) DocumentNo: Code[20]
    var
        Customer: Record Customer;
    begin
        // Setup: Create Invoice Line and Post with Currency without Application Rounding then Payment Line with Currency
        // Application Rounding.
        LibrarySales.CreateCustomer(Customer);
        CreateAndPostGenJnlLine(GenJournalLine, WorkDate(), DocumentType, Amount, Customer."No.", CurrencyCode);
        DocumentNo := GenJournalLine."Document No.";
        CreateAndPostGenJnlLine(
          GenJournalLine, WorkDate(), DocumentType2, -GenJournalLine.Amount + AppRounding, Customer."No.", CreateCurrency(AppRounding));
        LibraryERM.ApplyCustomerLedgerEntries(DocumentType2, DocumentType, GenJournalLine."Document No.", DocumentNo);
    end;

    local procedure CreateGenJnlLineWithAppliesToID(var GenJnlLine: Record "Gen. Journal Line"; AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; AppliesToID: Code[50])
    var
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJnlLine, GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Payment, AccType, AccNo, 0);
        GenJnlLine."Applies-to ID" := AppliesToID;
        GenJnlLine.Modify();
    end;

    local procedure CreateGenJnlLineWithAppliesToDocNo(var GenJnlLine: Record "Gen. Journal Line"; AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; AppliesToDocNo: Code[20])
    var
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJnlLine, GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Payment, AccType, AccNo, 0);
        GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::Invoice;
        GenJnlLine."Applies-to Doc. No." := AppliesToDocNo;
        GenJnlLine.Modify();
    end;

    local procedure CreateCashReceiptJnlLine(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::"Cash Receipts");
        GenJournalTemplate.Modify(true);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, AccountNo,
          GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), 0);
    end;

    local procedure CreateDefaultDimensionGLAccSameValue(var DimensionValue: Record "Dimension Value"; GLAccountNo: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionGLAcc(DefaultDimension, GLAccountNo, DimensionValue."Dimension Code", DimensionValue.Code);
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Same Code");
        DefaultDimension.Modify();
    end;

    local procedure CreateCustPostingGrPmtDiscDebitAccNo(CustomerNo: Code[20]): Code[20]
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        CustomerPostingGroup.Validate("Payment Disc. Debit Acc.", LibraryERM.CreateGLAccountNo());
        CustomerPostingGroup.Modify(true);
        exit(CustomerPostingGroup."Payment Disc. Debit Acc.");
    end;

    local procedure CreatePaymentJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::Payments);
        GenJournalTemplate.Modify(true);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure PostInvoice(var GenJournalLine: Record "Gen. Journal Line")
    begin
        CreateGenJnlLine(
            GenJournalLine, WorkDate(), GenJournalLine."Document Type"::Invoice, LibraryRandom.RandIntInRange(1000, 2000),
            LibrarySales.CreateCustomerNo(), '');
        GenJournalLine.Validate("External Document No.", LibraryUtility.GenerateGUID());
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure FindDetailedLedgerEntry(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; DocumentNo: Code[20]; EntryType: Enum "Detailed CV Ledger Entry Type")
    begin
        DetailedCustLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedCustLedgEntry.SetRange("Entry Type", EntryType);
        DetailedCustLedgEntry.FindFirst();
    end;

    local procedure FindOpenInvCustLedgEntry(var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
        CustLedgEntry.SetRange("Applying Entry", false);
        CustLedgEntry.SetRange(Open, true);
        CustLedgEntry.FindFirst();
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; GLAccountNo: Code[20])
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
    end;

    local procedure SetAppliesToIDOnCustLedgEntry(var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        CustLedgEntry."Applies-to ID" := LibraryUtility.GenerateGUID();
        CustLedgEntry.Modify();
    end;

    local procedure GetPmtTermsDiscountPct(): Decimal
    var
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        exit(PaymentTerms."Discount %");
    end;

    local procedure ModifyGenJnlBatchNoSeries()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJnlBatch);
        GenJnlBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        GenJnlBatch.Modify(true);
    end;

    local procedure UpdateGenJnlLineAppln(var GenJournalLine: Record "Gen. Journal Line"; CurrencyCode: Code[10]; AmountToApply: Decimal)
    begin
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate(Amount, AmountToApply);
        GenJournalLine.Validate("Applies-to ID", GenJournalLine."Document No.");
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateCustLedgerEntryAppln(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocumentNo: Code[20]; AmountToApply: Decimal)
    begin
        CustLedgerEntry.Validate("Applies-to ID", DocumentNo);
        CustLedgerEntry.Validate("Amount to Apply", AmountToApply);
        CustLedgerEntry.Modify(true);
    end;

    local procedure UnapplyCustLedgerEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgerEntry);
    end;

    local procedure UpdateApplnBetweenCurrenciesNoneInSalesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Appln. between Currencies", SalesReceivablesSetup."Appln. between Currencies"::None);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateApplnBetweenCurrenciesAllInSalesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Appln. between Currencies", SalesReceivablesSetup."Appln. between Currencies"::All);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure VerifyApplnRoundingCustLedger(DocumentNo: Code[20]; Amount: Decimal)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        Assert: Codeunit Assert;
    begin
        FindDetailedLedgerEntry(DetailedCustLedgEntry, DocumentNo, DetailedCustLedgEntry."Entry Type"::"Appln. Rounding");
        Assert.AreEqual(
          Amount, DetailedCustLedgEntry.Amount,
          StrSubstNo(WrongValErr, DetailedCustLedgEntry.FieldCaption(Amount), Amount, DetailedCustLedgEntry.TableCaption()));
    end;

    local procedure VerifyPaymentWithDiscount(DocumentNo: Code[20]; Amount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // Select Customer Payment Entries.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, DocumentNo);

        // Verify Payment Discount.
        FindDetailedLedgerEntry(
          DetailedCustLedgEntry, CustLedgerEntry."Document No.", DetailedCustLedgEntry."Entry Type"::"Payment Discount");
        CustLedgerEntry.TestField(Open);
        DetailedCustLedgEntry.TestField(Amount, Amount);
    end;

    local procedure VerifyPaymentWithoutDiscount(DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // If Payment is made after Due Date, verify "Original Pmt Disc. Possible" equal to zero and "Open" must be FALSE in the Customer
        // Ledger Entry.

        // Select Customer Payment Entries.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, DocumentNo);

        // Verify Payment Discount.
        CustLedgerEntry.TestField(Open, false);
        CustLedgerEntry.TestField("Original Pmt. Disc. Possible", 0);
    end;

    local procedure VerifyPaymentWithDetailedEntries(CustomerNo: Code[20]; CurrencyCode: Code[10]; EntryNoInvoice1: Integer; EntryNoInvoice2: Integer; AppliedEntries1: Integer; AppliedEntries2: Integer)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Currency Code", CurrencyCode);
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Payment);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields("Remaining Amount");
        CustLedgerEntry.TestField("Remaining Amount", 0);

        DetailedCustLedgEntry.SetRange("Customer No.", CustomerNo);
        DetailedCustLedgEntry.SetRange("Applied Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
        DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", EntryNoInvoice1);
        Assert.RecordCount(DetailedCustLedgEntry, AppliedEntries1);
        DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", EntryNoInvoice2);
        Assert.RecordCount(DetailedCustLedgEntry, AppliedEntries2);
    end;

    local procedure VerifyUnapplyPaymentDiscount(DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Verify "Original Pmt Disc. Possible" and "Remaining Pmt. Disc. Possible" should be equal in the Customer Ledger Entry.

        // Select Customer Invoice Entries.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, DocumentNo);

        // Verify Unapply Payment Discount.
        CustLedgerEntry.CalcFields("Original Amount", "Original Amt. (LCY)", "Remaining Amount", "Remaining Amt. (LCY)");
        CustLedgerEntry.TestField("Original Amount", CustLedgerEntry."Remaining Amount");
        CustLedgerEntry.TestField("Original Amt. (LCY)", CustLedgerEntry."Remaining Amt. (LCY)");
        CustLedgerEntry.TestField("Original Pmt. Disc. Possible", CustLedgerEntry."Remaining Pmt. Disc. Possible");
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; CurrencyCode: Code[10]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
        Currency: Record Currency;
    begin
        Currency.Get(CurrencyCode);
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          Amount / 2, LibraryERM.ConvertCurrency(Amount, '', CurrencyCode, WorkDate()), Currency."Amount Rounding Precision",
          'Amount must be equal');
    end;

    local procedure VerifyExtDocNoAmount(GenJournalLine: Record "Gen. Journal Line"; ExpectedExtDocNo: Code[35]; ExpectedAmount: Decimal)
    begin
        GenJournalLine.Find();
        Assert.AreEqual(
          ExpectedExtDocNo, GenJournalLine."Applies-to Ext. Doc. No.",
          StrSubstNo(WrongValErr, GenJournalLine.FieldCaption("Applies-to Ext. Doc. No."), ExpectedExtDocNo, GenJournalLine.TableCaption));
        Assert.AreEqual(
          ExpectedAmount, GenJournalLine.Amount,
          StrSubstNo(WrongValErr, GenJournalLine.FieldCaption(Amount), ExpectedAmount, GenJournalLine.TableCaption));
    end;

    local procedure SetSalesAllowMultiplePostingGroups(AllowMultiplePostingGroups: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Allow Multiple Posting Groups" := AllowMultiplePostingGroups;
        SalesReceivablesSetup."Check Multiple Posting Groups" := "Posting Group Change Method"::"Alternative Groups";
        SalesReceivablesSetup.Modify();
    end;

    local procedure CreateCustomerWithAllowMultiplePostingGroups(
        var Customer: Record Customer;
        CustomerPostingGroupCode: Code[20];
        CurrencyCode: Code[20];
        VATBusPostGroupCode: Code[20])
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Allow Multiple Posting Groups", true);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostGroupCode);
        Customer.Validate("Customer Posting Group", CustomerPostingGroupCode);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Modify(true);
    end;

    local procedure VerifyGLEntrySourceCurrenyAmount(DocumentNo: Code[20]; CurrencyCode: Code[10]; DocumentType: Enum "Gen. Journal Document Type")
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Source Currency Code", CurrencyCode);
        GLEntry.CalcSums("Source Currency Amount");
        Assert.Equal(0, GLEntry."Source Currency Amount");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesModalPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesWithSetAppliesToIDModalPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        ApplyCustomerEntries.AppliedAmount.AssertEquals(LibraryVariableStorage.DequeueDecimal());

        ApplyCustomerEntries.AppliesToID.SetValue('');
        ApplyCustomerEntries.AppliedAmount.AssertEquals(0);
        ApplyCustomerEntries."Amount to Apply".AssertEquals(0);
        ApplyCustomerEntries.ApplnAmountToApply.AssertEquals(0);

        ApplyCustomerEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesWithAmountModalPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries.FILTER.SetFilter("Document No.", LibraryVariableStorage.DequeueText());
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        ApplyCustomerEntries."Amount to Apply".SetValue(LibraryVariableStorage.DequeueDecimal());
        ApplyCustomerEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure MultipleSelectionApplyCustomerEntriesModalPageHandler(var ApplyCustomerEntries: Page "Apply Customer Entries"; var Response: Action)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", LibraryVariableStorage.DequeueText());
        ApplyCustomerEntries.CheckCustLedgEntry(CustLedgerEntry);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TwoApplyCustomerEntriesModalPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    var
        AppliesToID: Code[20];
    begin
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        AppliesToID := ApplyCustomerEntries.AppliesToID.Value();

        ApplyCustomerEntries.Next();
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        ApplyCustomerEntries.AppliesToID.SetValue('');
        ApplyCustomerEntries.AppliesToID.AssertEquals('');

        ApplyCustomerEntries.Previous();
        ApplyCustomerEntries.AppliesToID.AssertEquals(AppliesToID);

        ApplyCustomerEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TwoEntriesWithSameAppliesToIDModalPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    var
        AppliesToID: Code[20];
    begin
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        AppliesToID := ApplyCustomerEntries.AppliesToID.Value();

        ApplyCustomerEntries.Next();
        ApplyCustomerEntries.AppliesToID.SetValue(AppliesToID);
        ApplyCustomerEntries.AppliesToID.AssertEquals(AppliesToID);

        ApplyCustomerEntries.Previous();
        ApplyCustomerEntries.AppliesToID.AssertEquals(AppliesToID);

        ApplyCustomerEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TwoEntriesWithDifferentAppliesToIDModalPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    var
        AppliesToID: Code[20];
        AlternativeAppliesToID: Code[20];
    begin
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        AppliesToID := ApplyCustomerEntries.AppliesToID.Value();

        ApplyCustomerEntries.Next();
        AlternativeAppliesToID := LibraryUtility.GenerateGUID();
        ApplyCustomerEntries.AppliesToID.SetValue(AlternativeAppliesToID);
        ApplyCustomerEntries.AppliesToID.AssertEquals(AlternativeAppliesToID);

        ApplyCustomerEntries.Previous();
        ApplyCustomerEntries.AppliesToID.AssertEquals(AppliesToID);

        ApplyCustomerEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GeneralJournalTemplateListModalPageHandler(var GeneralJournalTemplateList: TestPage "General Journal Template List")
    begin
        GeneralJournalTemplateList.GotoKey(LibraryVariableStorage.DequeueText());
        GeneralJournalTemplateList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure MultiplCustomerEntrieseApplyModalPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    var
        AppliesToID: Code[20];
    begin
        AppliesToID := ApplyCustomerEntries.AppliesToID.Value();
        if AppliesToID = '' then
            ApplyCustomerEntries."Set Applies-to ID".Invoke();

        if (ApplyCustomerEntries.Next()) then begin
            ApplyCustomerEntries.AppliesToID.SetValue(AppliesToID);
            ApplyCustomerEntries.AppliesToID.AssertEquals(AppliesToID);
            ApplyCustomerEntries.Previous();
            ApplyCustomerEntries.AppliesToID.AssertEquals(AppliesToID);
        end;
        ApplyCustomerEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesModalPageHandlerWithSetAppliesID(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries.FILTER.SetFilter("Document No.", LibraryVariableStorage.DequeueText());
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        ApplyCustomerEntries.OK().Invoke();
    end;
}

