codeunit 144351 "CH DTA Reports"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        CompanyInformation: Record "Company Information";
        DummyGenJournalTemplate: Record "Gen. Journal Template";
        LibraryDTA: Codeunit "Library - DTA";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        DtaMgt: Codeunit DtaMgt;
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryUtility: Codeunit "Library - Utility";
        isInitialized: Boolean;
        NumberOfLinesErr: Label 'Number Of Lines Must be %1 in %2.';
        TestOption: Option "ESR5/15","ESR9/16","ESR9/27","ESR+5/15","ESR+9/16","ESR+9/27","Post Payment Domestic","Bank Payment Domestic","Cash Outpayment Order Domestic","Post Payment Abroad","Bank Payment Abroad","SWIFT Payment Abroad","Cash Outpayment Order Abroad","None";
        DiscountAmountZeroErr: Label 'The discount amount should be greater than zero.';
        UnexpectedConfirmDialogErr: Label 'An unexpected confirmation dialog popped up. Message: %1.';
        AmountNotCorrectlyDiscountedErr: Label 'The Gen. Jounrnal Line amount after running the DTA Suggest Vendor Payment report is not correctly discounted.';
        FieldIncorrectErr: Label 'The field was not correctly filled in as part of the ESR/ISR Coding Line validation. ';
        BankCodeChangeErr: Label 'Reference numbers are only permitted for ESR and ESR+.';
        GenJournalLineInfoErr: Label 'The Gen. Journal Line information is not correct after running the DTA Suggest Vendor Payment report.';
        CurrencyCodeHeaderTxt: Label 'Currency Code';
        CHFCurrencyTxt: Label 'CHF';
        TestDocNoTxt: Label 'TEST123Doc';
        DTANoVendorBankAccountTxt: Label 'There is no vendor bank account with payment type %2 for vendor %1. Do you want to create it?';
        DTAOpenBankCardTxt: Label 'Bank %2 has been created for vendor %1.\\Do you want to see the bank card to check the entry or to add a balance account, bank account number or position of invoice number?';
        DTAPaymentJournalLayout: Option Amounts,Bank;
        DTABankAccountNotChangeableTxt: Label 'The bank code should not be changeable in this situation.';
        DTAReferenceNoTxt: Label '213896001901268000010035573';
        DTAESRAmountFormattedTxt: Label '23607';
        BankPaymentFormChangedErr: Label 'The reference number may only be modified for payment type ESR and ESR+.';
        BankESRTypeChangedErr: Label 'The reference number may only be modified for ESR type 9/16 and 9/27.';
        DetailInfoMsg: Label '%1: %2.', Locked = true;

    [Test]
    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler,ConfirmHandler,VendorLedgerEntryPageHandler')]
    [Scope('OnPrem')]
    procedure TestSuggestVendorPaymentWithLateInvoice()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLineArray: array[3] of Record "Gen. Journal Line";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        Dates: array[3] of Date;
        Amounts: array[3] of Decimal;
    begin
        // Test Vendor Ledger Entry after Posting Payment Journal with running Suggest Vendor Payment against Invoices.

        // 1. Setup: Create and post two General Journal lines with Document Type as Invoice.
        Initialize();
        Dates[1] := CalcDate('<+1D>', WorkDate());
        Dates[2] := CalcDate('<+3D>', WorkDate());
        Amounts[1] := -LibraryRandom.RandDecInRange(100, 300, 2);
        Amounts[2] := Amounts[1] * 2;

        LibraryDTA.CreateTestGenJournalLines(
          Vendor, VendorBankAccount, GenJournalLineArray, GenJournalBatch, 2, Dates, Amounts, TestOption::"ESR5/15", '', '', false);

        // 2A. Exercise: Create Invoices and run the Suggest Vendor Payment report
        RunDTASuggestVendorPayment(GenJournalBatch, GenJournalLineArray[1]."Account No.", WorkDate(), WorkDate(), CalcDate('<+1Y>', WorkDate()), '');

        // 3A. Verify: Verify there are no lines in General Journal.
        VerifyGenJournalNoOfLines(GenJournalBatch, 0);

        // 2B. Exercise: Create Invoices and run the Suggest Vendor Payment report
        RunDTASuggestVendorPayment(GenJournalBatch,
          GenJournalLineArray[1]."Account No.", CalcDate('<+1D>', Dates[1]), WorkDate(), CalcDate('<+1Y>', WorkDate()), '');

        // 3B. Verify: Verify there is 1 line in General Journal.
        VerifyGenJournalNoOfLines(GenJournalBatch, 2);
    end;

    [Test]
    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestSuggestVendorPaymentWithNormalInvoices()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLineArray: array[3] of Record "Gen. Journal Line";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        Dates: array[3] of Date;
        Amounts: array[3] of Decimal;
    begin
        // Test Vendor Ledger Entry after Posting Payment Journal with running Suggest Vendor Payment against Invoices.

        // 1. Setup: Create and post two General Journal lines with Document Type as Invoice.
        Initialize();
        Dates[1] := CalcDate('<-1Y>', WorkDate());
        Dates[2] := WorkDate();
        Amounts[1] := -LibraryRandom.RandDecInRange(100, 300, 2);
        Amounts[2] := Amounts[1] * 2;

        LibraryDTA.CreateTestGenJournalLines(
          Vendor, VendorBankAccount, GenJournalLineArray, GenJournalBatch, 2, Dates, Amounts, TestOption::"ESR5/15", '', '', false);

        // 2. Exercise: Create Invoices and run the Suggest Vendor Payment report
        RunDTASuggestVendorPayment(GenJournalBatch, GenJournalLineArray[1]."Account No.", Dates[2], Dates[1], Dates[2], '');

        // 3. Verify: Verify there are 3 lines in General Journal.
        VerifyGenJournalNoOfLines(GenJournalBatch, 3);
    end;

    [Test]
    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestSuggestVendorPaymentForMoreVendors()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLineArray: array[3] of Record "Gen. Journal Line";
        Vendor1: Record Vendor;
        Vendor2: Record Vendor;
        Vendor3: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        Dates: array[3] of Date;
        Amounts: array[3] of Decimal;
        Amount1: Decimal;
        Amount2: Decimal;
        Amount3: Decimal;
    begin
        // Test Vendor Ledger Entry after Posting Payment Journal with running Suggest Vendor Payment against Invoices.

        // 1. Setup: Create and post two General Journal lines with Document Type as Invoice.
        Initialize();

        Dates[1] := WorkDate();
        Amounts[1] := LibraryRandom.RandDecInRange(100, 300, 2);
        Amount1 := Amounts[1];
        LibraryDTA.CreateTestGenJournalLines(
          Vendor1, VendorBankAccount, GenJournalLineArray, GenJournalBatch, 1, Dates, Amounts, TestOption::"ESR5/15", '', '', true);

        Dates[1] := CalcDate('<+4D>', WorkDate());
        Amounts[1] := LibraryRandom.RandDecInRange(100, 300, 2);
        Amount2 := Amounts[1];
        LibraryDTA.CreateTestGenJournalLines(
          Vendor2, VendorBankAccount, GenJournalLineArray, GenJournalBatch, 1, Dates, Amounts, TestOption::"ESR5/15", '', '', true);

        Dates[1] := CalcDate('<+6D>', WorkDate());
        Amounts[1] := LibraryRandom.RandDecInRange(100, 300, 2);
        Amount3 := Amounts[1];
        LibraryDTA.CreateTestGenJournalLines(
          Vendor3, VendorBankAccount, GenJournalLineArray, GenJournalBatch, 1, Dates, Amounts, TestOption::"ESR5/15", '', '', true);

        // 2. Exercise: Create Invoices and run the Suggest Vendor Payment report
        RunDTASuggestVendorPayment(
          GenJournalBatch,
          StrSubstNo('%1|%2|%3', Vendor1."No.", Vendor2."No.", Vendor3."No."),
          CalcDate('<+11D>', WorkDate()), CalcDate('<+10D>', WorkDate()), CalcDate('<+27D>', WorkDate()), '');

        // 3. Verify: Verify there are 3 lines in General Journal.
        VerifyGenJournalNoOfLines(GenJournalBatch, 4);
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.FindSet();
        Assert.AreEqual(Vendor1."No.", GenJournalLine."Account No.", GenJournalLineInfoErr);
        Assert.AreEqual(Amount1, GenJournalLine.Amount, GenJournalLineInfoErr);
        GenJournalLine.Next();
        Assert.AreEqual(Vendor2."No.", GenJournalLine."Account No.", GenJournalLineInfoErr);
        Assert.AreEqual(Amount2, GenJournalLine.Amount, GenJournalLineInfoErr);
        GenJournalLine.Next();
        Assert.AreEqual(Vendor3."No.", GenJournalLine."Account No.", GenJournalLineInfoErr);
        Assert.AreEqual(Amount3, GenJournalLine.Amount, GenJournalLineInfoErr);
        GenJournalLine.Next();
        Assert.AreEqual('G/L Account', Format(GenJournalLine."Account Type"), GenJournalLineInfoErr);
        Assert.AreEqual(-Amount1 - Amount2 - Amount3, GenJournalLine.Amount, GenJournalLineInfoErr);
    end;

    [Test]
    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestSuggestVendorPaymentWithPaymentDiscount()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        VendorBankAccount: Record "Vendor Bank Account";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        Dates: array[3] of Date;
        Amounts: array[3] of Decimal;
        ExpectedAmount: Decimal;
    begin
        // 1. Setup: Create and Post Purchase Order.
        Initialize();
        Dates[1] := WorkDate();
        Amounts[1] := LibraryRandom.RandDecInRange(100, 300, 2);

        LibraryDTA.CreateTestPurchaseOrder(Vendor, VendorBankAccount, PurchaseHeader,
          PurchaseLine, GenJournalBatch, Amounts[1], Dates[1], TestOption::"ESR5/15", '', true, true, true, true, true);

        // Get the discount amount from the Vendor Ledger Entry table.
        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        VendorLedgerEntry.FindFirst();
        ExpectedAmount := PurchaseLine."Amount Including VAT" + VendorLedgerEntry."Remaining Pmt. Disc. Possible";
        Assert.AreNotEqual(0, ExpectedAmount, DiscountAmountZeroErr);

        // 2. Exercise: Run Report DTA Suggest Vendor Payment.
        RunDTASuggestVendorPayment(GenJournalBatch, PurchaseHeader."Buy-from Vendor No.", Dates[1], Dates[1], Dates[1], '');

        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.FindFirst();
        Assert.AreEqual(ExpectedAmount, GenJournalLine.Amount, AmountNotCorrectlyDiscountedErr);
    end;

    [Test]
    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler,DTAPaymentJournalRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestDTAPmtJournalRepWithGenJournalLineESR515()
    begin
        TestDTAPmtJournalRepWithGenJournalLine(TestOption::"ESR5/15");
    end;

    [Test]
    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler,DTAPaymentJournalRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestDTAPmtJournalRepWithGenJournalLineESR916()
    begin
        TestDTAPmtJournalRepWithGenJournalLine(TestOption::"ESR9/16");
    end;

    [Test]
    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler,DTAPaymentJournalRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestDTAPmtJournalRepWithGenJournalLineESR927()
    begin
        TestDTAPmtJournalRepWithGenJournalLine(TestOption::"ESR9/27");
    end;

    [Test]
    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler,DTAPaymentJournalRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestDTAPmtJournalRepWithGenJournalLineESRP515()
    begin
        TestDTAPmtJournalRepWithGenJournalLine(TestOption::"ESR+5/15");
    end;

    [Test]
    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler,DTAPaymentJournalRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestDTAPmtJournalRepWithGenJournalLineESRP916()
    begin
        TestDTAPmtJournalRepWithGenJournalLine(TestOption::"ESR+9/16");
    end;

    [Test]
    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler,DTAPaymentJournalRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestDTAPmtJournalRepWithGenJournalLineESRP927()
    begin
        TestDTAPmtJournalRepWithGenJournalLine(TestOption::"ESR+9/27");
    end;

    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler,DTAPaymentJournalRequestPageHandler')]
    local procedure TestDTAPmtJournalRepWithGenJournalLine(PaymentMethod: Option)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLineArray: array[3] of Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        Vendor: Record Vendor;
        Dates: array[3] of Date;
        Amounts: array[3] of Decimal;
    begin
        // 1. Setup: Create and Post General Journal Line for Payment and Suggest Vendor Payment.
        Initialize();
        Dates[1] := WorkDate();
        Amounts[1] := -LibraryRandom.RandDecInRange(100, 300, 2);
        LibraryDTA.CreateTestGenJournalLines(
          Vendor, VendorBankAccount, GenJournalLineArray, GenJournalBatch, 1, Dates, Amounts, PaymentMethod, '', '', false);
        RunDTASuggestVendorPayment(GenJournalBatch, GenJournalLineArray[1]."Account No.", Dates[1], Dates[1], Dates[1], '');

        // 2. Exercise: Run Report DTA Payment Journal.
        LibraryVariableStorage.Enqueue(DTAPaymentJournalLayout::Amounts);
        REPORT.Run(REPORT::"DTA Payment Journal");

        // Verify: Verify Amount in generated XML file.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Amount_GenJournalLine', -GenJournalLineArray[1].Amount);
        LibraryReportDataset.AssertElementWithValueExists('JournalBatchName_GenJournalLine', GenJournalBatch.Name);
        LibraryReportDataset.AssertElementWithValueExists('VendorName', Vendor.Name);
        LibraryReportDataset.AssertElementWithValueExists('VendorBankAccountPaymentForm', Format(VendorBankAccount."Payment Form"));
        LibraryReportDataset.AssertElementWithValueExists('VendorLedgerEntryDueDate', Format(Dates[1]));
    end;

    [Test]
    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler,DTAPaymentJournalRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestDTAPmtJournalRepWithPurchaseOrderESR515()
    begin
        TestDTAPmtJournalRepWithPurchaseOrder(TestOption::"ESR5/15");
    end;

    [Test]
    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler,DTAPaymentJournalRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestDTAPmtJournalRepWithPurchaseOrderESR916()
    begin
        TestDTAPmtJournalRepWithPurchaseOrder(TestOption::"ESR9/16");
    end;

    [Test]
    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler,DTAPaymentJournalRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestDTAPmtJournalRepWithPurchaseOrderESR927()
    begin
        TestDTAPmtJournalRepWithPurchaseOrder(TestOption::"ESR9/27");
    end;

    [Test]
    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler,DTAPaymentJournalRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestDTAPmtJournalRepWithPurchaseOrderESRP515()
    begin
        TestDTAPmtJournalRepWithPurchaseOrder(TestOption::"ESR+5/15");
    end;

    [Test]
    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler,DTAPaymentJournalRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestDTAPmtJournalRepWithPurchaseOrderESRP916()
    begin
        TestDTAPmtJournalRepWithPurchaseOrder(TestOption::"ESR+9/16");
    end;

    [Test]
    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler,DTAPaymentJournalRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestDTAPmtJournalRepWithPurchaseOrderESRP927()
    begin
        TestDTAPmtJournalRepWithPurchaseOrder(TestOption::"ESR+9/27");
    end;

    [Test]
    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler,DTAPaymentJournalRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestDTAPmtJournalRepWithPurchaseOrderBankPmtDomestic()
    begin
        TestDTAPmtJournalRepWithPurchaseOrder(TestOption::"Bank Payment Domestic");
    end;

    [Test]
    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler,DTAPaymentJournalRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestDTAPmtJournalRepWithPurchaseOrderBankPmtAbroad()
    begin
        TestDTAPmtJournalRepWithPurchaseOrder(TestOption::"Bank Payment Abroad");
    end;

    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler,DTAPaymentJournalRequestPageHandler')]
    local procedure TestDTAPmtJournalRepWithPurchaseOrder(PaymentMethod: Option)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        VendorBankAccount: Record "Vendor Bank Account";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Dates: array[3] of Date;
        Amounts: array[3] of Decimal;
    begin
        // 1. Setup: Create and Post General Journal Line for Payment and Suggest Vendor Payment.
        Dates[1] := WorkDate();
        Amounts[1] := LibraryRandom.RandDecInRange(100, 300, 2);
        Initialize();

        LibraryDTA.CreateTestPurchaseOrder(Vendor, VendorBankAccount, PurchaseHeader, PurchaseLine,
          GenJournalBatch, Amounts[1], Dates[1], PaymentMethod, '', false, true, true, true, true);
        RunDTASuggestVendorPayment(GenJournalBatch, PurchaseHeader."Buy-from Vendor No.", Dates[1], Dates[1], Dates[1], '');

        // 2. Exercise: Run Report DTA Payment Journal.
        LibraryVariableStorage.Enqueue(DTAPaymentJournalLayout::Amounts);
        REPORT.Run(REPORT::"DTA Payment Journal");

        // Verify: Verify Amount in generated XML file.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Amount_GenJournalLine', PurchaseLine."Amount Including VAT");
        LibraryReportDataset.AssertElementWithValueExists('JournalBatchName_GenJournalLine', GenJournalBatch.Name);
        LibraryReportDataset.AssertElementWithValueExists('VendorName', Vendor.Name);
        LibraryReportDataset.AssertElementWithValueExists('VendorBankAccountPaymentForm', Format(VendorBankAccount."Payment Form"));
        LibraryReportDataset.AssertElementWithValueExists('VendorLedgerEntryDueDate', Format(Dates[1]));
        LibraryReportDataset.AssertElementWithValueExists('CurrencyCodeCaption_GenJournalLine', Format(CurrencyCodeHeaderTxt));
        if (PaymentMethod = TestOption::"Bank Payment Domestic") or (PaymentMethod = TestOption::"Bank Payment Abroad") then
            LibraryReportDataset.AssertElementWithValueExists('xAcc', 'CH9300762011623852957');
    end;

    [Test]
    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler,DTAPaymentJournalRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestDTAPmtJournalRepWithPurchaseOrderIBAN()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        VendorBankAccount: Record "Vendor Bank Account";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Dates: array[3] of Date;
        Amounts: array[3] of Decimal;
    begin
        // 1. Setup: Create and Post General Journal Line for Payment and Suggest Vendor Payment.
        Dates[1] := WorkDate();
        Amounts[1] := LibraryRandom.RandDecInRange(100, 300, 2);
        Initialize();

        LibraryDTA.CreateTestPurchaseOrder(Vendor, VendorBankAccount, PurchaseHeader, PurchaseLine,
          GenJournalBatch, Amounts[1], Dates[1], TestOption::"SWIFT Payment Abroad", '', false, true, true, true, true);
        RunDTASuggestVendorPayment(GenJournalBatch, PurchaseHeader."Buy-from Vendor No.", Dates[1], Dates[1], Dates[1], '');

        // 2. Exercise: Run Report DTA Payment Journal.
        LibraryVariableStorage.Enqueue(DTAPaymentJournalLayout::Bank);
        REPORT.Run(REPORT::"DTA Payment Journal");

        // Verify: Verify Amount in generated XML file.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Amount_GenJournalLine', PurchaseLine."Amount Including VAT");
        LibraryReportDataset.AssertElementWithValueExists('JournalBatchName_GenJournalLine', GenJournalBatch.Name);
        LibraryReportDataset.AssertElementWithValueExists('VendorName', Vendor.Name);
        LibraryReportDataset.AssertElementWithValueExists('VendorBankAccountPaymentForm', Format(VendorBankAccount."Payment Form"));
        LibraryReportDataset.AssertElementWithValueExists('VendorLedgerEntryDueDate', Format(Dates[1]));
        LibraryReportDataset.AssertElementWithValueExists('CurrencyCodeCaption_GenJournalLine', Format(CurrencyCodeHeaderTxt));
        LibraryReportDataset.AssertElementWithValueExists('xAcc', 'DE9300762011623852957');
    end;

    [Test]
    [HandlerFunctions('DTASpecificConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestESRISRCodingLineChangeAfterPurchaseOrderPost()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        VendorBankAccount: Record "Vendor Bank Account";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Dates: array[3] of Date;
        Amounts: array[3] of Decimal;
    begin
        // 1. Setup: Create and Post Purchase Order.
        Dates[1] := WorkDate();
        Amounts[1] := LibraryRandom.RandDecInRange(100, 300, 2);
        Initialize();

        LibraryDTA.CreateTestPurchaseOrder(Vendor, VendorBankAccount, PurchaseHeader, PurchaseLine,
          GenJournalBatch, Amounts[1], Dates[1], TestOption::None, '', true, false, true, false, true);
        // 2. Exercise: Change the DTA Line Field
        PurchaseHeader.Validate("ESR/ISR Coding Line", '2100000' + DTAESRAmountFormattedTxt + '5>' + DTAReferenceNoTxt + '+030008995>');
        PurchaseHeader.Modify(true);
        // 3. Verify: Validate that the fields are properly automatically filled.
        Assert.AreEqual(Format(DTAReferenceNoTxt), Format(PurchaseHeader."Reference No."), FieldIncorrectErr);
        Assert.AreEqual(Format(DTAESRAmountFormattedTxt), DelStr(Format(PurchaseHeader."ESR Amount" * 100), 3, 1), FieldIncorrectErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,DTASuggestVendorPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestDTABankCodeAfterPurchaseOrderCreation()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        VendorBankAccount: Record "Vendor Bank Account";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
        Dates: array[3] of Date;
        Amounts: array[3] of Decimal;
    begin
        // 1. Setup: Create and Post Purchase Order.
        Dates[1] := WorkDate();
        Amounts[1] := LibraryRandom.RandDecInRange(100, 300, 2);
        Initialize();

        LibraryDTA.CreateTestPurchaseOrder(Vendor, VendorBankAccount, PurchaseHeader, PurchaseLine,
          GenJournalBatch, Amounts[1], Dates[1], TestOption::"ESR9/27", '', true, true, false, false, true);

        // Create Another Vendor Bank Account
        LibraryDTA.CreateVendorBankAccount(VendorBankAccount, Vendor."No.", TestOption::"Bank Payment Domestic", '');

        // 2. Exercise: Change the DTA Line Field
        Commit();
        asserterror PurchaseHeader.Validate("Bank Code", VendorBankAccount.Code);
        Assert.IsTrue(StrPos(GetLastErrorText, Format(BankCodeChangeErr)) > 0, DTABankAccountNotChangeableTxt);

        PurchaseHeader.Validate("Reference No.", '');
        PurchaseHeader.Validate("Bank Code", VendorBankAccount.Code);
        PurchaseHeader.Modify(true);

        // Post Puchase Order after creating it.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        // Create General Journal Batch for Payment.
        LibraryDTA.CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::Payments, true);

        // Run Suggest Vendor Payment Report
        RunDTASuggestVendorPayment(GenJournalBatch, Vendor."No.", Dates[1], Dates[1], Dates[1], '');

        // 3. Verify: Verify there are 3 lines in General Journal and make sure the posting procedure succeeds.
        VerifyGenJournalNoOfLines(GenJournalBatch, 2);

        GenJournalLine.Init();
        GenJournalLine.SetRange(GenJournalLine."Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange(GenJournalLine."Journal Batch Name", GenJournalBatch.Name);
        if GenJournalLine.FindSet() then
            repeat
                LibraryERM.PostGeneralJnlLine(GenJournalLine);
            until GenJournalLine.Next() = 0
    end;

    [Test]
    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler,DTAPaymentOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestDTAPaymentOrderWithLCY()
    begin
        TestDTAPaymentOrder('');
    end;

    [Test]
    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler,DTAPaymentOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestDTAPaymentOrderWithFCY()
    begin
        TestDTAPaymentOrder('DKK');
    end;

    [Test]
    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler,DTAPaymentOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestDTAPaymentOrderWithEUR()
    begin
        TestDTAPaymentOrder('EUR');
    end;

    [Test]
    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler,ExchangeRatePageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestPaymentJournalBalanceEUR()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLineArray: array[3] of Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        Vendor: Record Vendor;
        DTASetup: Record "DTA Setup";
        PaymentJournal: TestPage "Payment Journal";
        Dates: array[3] of Date;
        Amounts: array[3] of Decimal;
    begin
        Initialize();
        LibraryDTA.CreateDTASetup(DTASetup, 'EUR', false);

        Dates[1] := WorkDate();
        Amounts[1] := -LibraryRandom.RandDecInRange(100, 300, 2);
        LibraryDTA.CreateTestGenJournalLines(Vendor, VendorBankAccount, GenJournalLineArray,
          GenJournalBatch, 1, Dates, Amounts, TestOption::"ESR5/15", '', DTASetup."Bank Code", false);
        RunDTASuggestVendorPayment(GenJournalBatch, GenJournalLineArray[1]."Account No.", Dates[1], Dates[1], Dates[1], '');

        // Change Exchange Rate
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        PaymentJournal."Currency Code".AssistEdit();

        // Verify Balanced (Posting and check lines are posted)
        PaymentJournal.Post.Invoke();
        VerifyGenJournalNoOfLines(GenJournalBatch, 0);
    end;

    [Test]
    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler,VendorPaymentOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestIBANOnPaymentOrder()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLineArray: array[3] of Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        Vendor: Record Vendor;
        DTASetup: Record "DTA Setup";
        Dates: array[3] of Date;
        Amounts: array[3] of Decimal;
    begin
        Initialize();
        LibraryDTA.CreateDTASetup(DTASetup, '', false);

        Dates[1] := WorkDate();
        Amounts[1] := -LibraryRandom.RandDecInRange(100, 300, 2);
        LibraryDTA.CreateTestGenJournalLines(Vendor, VendorBankAccount, GenJournalLineArray,
          GenJournalBatch, 1, Dates, Amounts, TestOption::"SWIFT Payment Abroad", '', DTASetup."Bank Code", false);
        RunDTASuggestVendorPayment(GenJournalBatch, GenJournalLineArray[1]."Account No.", Dates[1], Dates[1], Dates[1], '');

        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);

        // Run Payment Order Report
        REPORT.Run(REPORT::"Vendor Payment Order");

        // Verify Vendor IBAN on the report
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('BankAccNo', VendorBankAccount.IBAN);
    end;

    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler,DTAPaymentOrderRequestPageHandler')]
    local procedure TestDTAPaymentOrder(CurrencyCode: Code[3])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLineArray: array[3] of Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        Vendor: Record Vendor;
        DTASetup: Record "DTA Setup";
        Dates: array[3] of Date;
        Amounts: array[3] of Decimal;
        CHFCurrency: Text;
    begin
        // Verify Amount in generated XML file.

        // 1. Setup: Create and Post General Journal Line for Payment and Suggest Vendor Payment.
        Initialize();
        LibraryDTA.CreateDTASetup(DTASetup, CurrencyCode, false);

        Dates[1] := WorkDate();
        Amounts[1] := -LibraryRandom.RandDecInRange(100, 300, 2);
        LibraryDTA.CreateTestGenJournalLines(Vendor, VendorBankAccount, GenJournalLineArray,
          GenJournalBatch, 1, Dates, Amounts, TestOption::"ESR5/15", '', DTASetup."Bank Code", false);
        RunDTASuggestVendorPayment(GenJournalBatch, GenJournalLineArray[1]."Account No.", Dates[1], Dates[1], Dates[1], '');

        // 2. Exercise: Run Report DTA Payment Order.
        REPORT.Run(REPORT::"DTA Payment Order");

        // 3. Verify: Verify Amount in generated XML file.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetNextRow();

        // Verify company name
        LibraryReportDataset.AssertCurrentRowValueEquals('CompanySetup1', CompanyInformation.Name);

        // Verify bank information
        LibraryReportDataset.AssertCurrentRowValueEquals('BankAccountNo', DTASetup."DTA Debit Acc. No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('BankCode_DTASetup', DTASetup."Bank Code");

        // Verify payment info
        LibraryReportDataset.AssertCurrentRowValueEquals('iAmtNumber', -GenJournalLineArray[1].Amount);
        if CurrencyCode = '' then begin
            CHFCurrency := CHFCurrencyTxt;
            LibraryReportDataset.AssertCurrentRowValueEquals('DTACurrencyCode_DTASetup', CHFCurrency);
        end else
            LibraryReportDataset.AssertCurrentRowValueEquals('DTACurrencyCode_DTASetup', CurrencyCode);
    end;

    [Test]
    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler,EZAGPaymentOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestEZAGPaymentOrderWithLCY()
    begin
        TestEZAGPaymentOrder('');
    end;

    [Test]
    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler,EZAGPaymentOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestEZAGPaymentOrderWithFCY()
    begin
        TestEZAGPaymentOrder('DKK');
    end;

    [Test]
    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler,EZAGPaymentOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestEZAGPaymentOrderWithEUR()
    begin
        TestEZAGPaymentOrder('EUR');
    end;

    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler,EZAGPaymentOrderRequestPageHandler')]
    local procedure TestEZAGPaymentOrder(CurrencyCode: Code[3])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLineArray: array[3] of Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        Vendor: Record Vendor;
        DTASetup: Record "DTA Setup";
        Dates: array[3] of Date;
        Amounts: array[3] of Decimal;
        FormattedAmount: Text;
    begin
        // Verify Amount in generated XML file.

        // 1. Setup: Create an EZAG-type DTA Setup, create and Post General Journal Line for Payment and Suggest Vendor Payment.
        Initialize();
        LibraryDTA.CreateEZAGSetup(DTASetup, CurrencyCode);

        Dates[1] := WorkDate();
        Amounts[1] := -LibraryRandom.RandDecInRange(100, 300, 2);
        LibraryDTA.CreateTestGenJournalLines(Vendor, VendorBankAccount, GenJournalLineArray,
          GenJournalBatch, 1, Dates, Amounts, TestOption::"ESR5/15", CurrencyCode, DTASetup."Bank Code", false);
        RunDTASuggestVendorPayment(GenJournalBatch, GenJournalLineArray[1]."Account No.", Dates[1], Dates[1], Dates[1], '');

        // 2. Exercise: Run Report DTA Payment Order.
        LibraryVariableStorage.Enqueue(DTASetup."Bank Code");
        REPORT.Run(REPORT::"EZAG Payment Order");

        // 3. Verify: Verify Amount in generated XML file.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetNextRow();

        // Verify company name
        LibraryReportDataset.AssertCurrentRowValueEquals('Adr1', CompanyInformation.Name);

        // Verify account numbers
        LibraryReportDataset.AssertCurrentRowValueEquals('DtaSetupEZAGDebitAccountNo', DTASetup."EZAG Debit Account No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('DtaSetupEZAGChargesAccountNo', DTASetup."EZAG Charges Account No.");

        // Verify payment info
        LibraryReportDataset.AssertCurrentRowValueEquals('iCurrCode1', Format(CHFCurrencyTxt));
        FormattedAmount := ConvertStr(Format(-GenJournalLineArray[1].Amount, 14, 1), ' ', '0');
        LibraryReportDataset.AssertCurrentRowValueEquals('iAmtTxt1', FormattedAmount);
    end;

    [Test]
    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler,ConfirmHandler,ModifyDocumentNumberInputDialogHandler')]
    [Scope('OnPrem')]
    procedure UnitTestDtaMgtModifyDocumentNo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLineArray: array[3] of Record "Gen. Journal Line";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        DTASetup: Record "DTA Setup";
        Dates: array[3] of Date;
        Amounts: array[3] of Decimal;
    begin
        // 1. Setup: Create and post two General Journal lines with Document Type as Invoice.
        Initialize();
        LibraryDTA.CreateDTASetup(DTASetup, '', false);

        Dates[1] := WorkDate();
        Amounts[1] := -LibraryRandom.RandDecInRange(100, 300, 2);

        LibraryDTA.CreateTestGenJournalLines(Vendor, VendorBankAccount, GenJournalLineArray,
          GenJournalBatch, 1, Dates, Amounts, TestOption::"ESR5/15", '', DTASetup."Bank Code", false);
        RunDTASuggestVendorPayment(GenJournalBatch, GenJournalLineArray[1]."Account No.", Dates[1], Dates[1], Dates[1], '');
        Commit();

        // 2. Exercise: Call the ModifyDocNo method in order to change the Invoice Document No.
        DtaMgt.ModifyDocNo(GenJournalLineArray[1]);

        // 3. Assert that the invoice has the expected Document No.
        GenJournalLine.SetRange("Journal Template Name", GenJournalLineArray[1]."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLineArray[1]."Journal Batch Name");
        if GenJournalLine.Find() then
            repeat
                Assert.AreEqual(Format(TestDocNoTxt), Format(GenJournalLine."Document No."), GenJournalLineInfoErr);
            until GenJournalLine.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestSuggestVendorPaymentWithExtDocNo()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLineArray: array[3] of Record "Gen. Journal Line";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        Dates: array[3] of Date;
        Amounts: array[3] of Decimal;
    begin
        // [FEATURE] [DTA Suggest Vendor Payments]
        // [SCENARIO 363081] DTA Suggest Vendor Payment creates Gen. Jnl. Lines with "Applied-to Ext. Doc. No.".

        // [GIVEN] Create and post two General Journal lines, non-empty "External Document No.".
        Initialize();
        Dates[1] := CalcDate('<-1Y>', WorkDate());
        Dates[2] := WorkDate();
        Amounts[1] := -LibraryRandom.RandDecInRange(100, 300, 2);
        Amounts[2] := Amounts[1] * 2;

        LibraryDTA.CreateTestGenJournalLines(
          Vendor, VendorBankAccount, GenJournalLineArray, GenJournalBatch, 2, Dates, Amounts, TestOption::"ESR5/15", '', '', false);

        // [WHEN] Run the DTA Suggest Vendor Payment
        RunDTASuggestVendorPayment(GenJournalBatch, GenJournalLineArray[1]."Account No.", Dates[2], Dates[1], Dates[2], '');

        // [THEN] "Applied-to Exty. Doc. No." equals to the one in posted lines.
        VerifyGenJournalExtDocNo(GenJournalBatch);
    end;

    [Test]
    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentErrorAfterChangingPaymentForm()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLineArray: array[3] of Record "Gen. Journal Line";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        Dates: array[3] of Date;
        Amounts: array[3] of Decimal;
    begin
        // [FEATURE] [DTA Suggest Vendor Payments]
        // [SCENARIO 372205] DTA Suggest Vendor Payment throws an error with detailed info when Vendor Bank Account "Payment Form" is changed after posting
        Initialize();
        Dates[1] := WorkDate();
        Amounts[1] := -LibraryRandom.RandDecInRange(100, 300, 2);

        // [GIVEN] Vendor "V". Vendor Bank Account "VB" with "Payment Form" = "ESR"
        // [GIVEN] Create and post Purchase Invoice "PI"
        LibraryDTA.CreateTestGenJournalLines(
          Vendor, VendorBankAccount, GenJournalLineArray, GenJournalBatch, 1, Dates, Amounts, TestOption::"ESR9/27", '', '', false);

        // [GIVEN] Modify "VB"."Payment Form " = "Post Payment Domestic"
        VendorBankAccount.Validate("Payment Form", VendorBankAccount."Payment Form"::"Post Payment Domestic");
        VendorBankAccount.Modify();

        // [WHEN] Run the DTA Suggest Vendor Payment
        asserterror RunDTASuggestVendorPayment(GenJournalBatch, GenJournalLineArray[1]."Account No.", Dates[1], Dates[1], Dates[1], '');

        // [THEN] Error occurs:
        // [THEN] "The reference number may only be modified for payment type ESR and ESR+.
        // [THEN] Vendor: "V".
        // [THEN] Vendor Bank Account: "VB".
        // [THEN] Document Type: Invoice.
        // [THEN] Document No.: "PI"."
        VerifyExpectedErrorSuggestPayments(GenJournalLineArray[1], VendorBankAccount.Code, BankPaymentFormChangedErr);
    end;

    [Test]
    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentErrorAfterChangingESRType()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLineArray: array[3] of Record "Gen. Journal Line";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        Dates: array[3] of Date;
        Amounts: array[3] of Decimal;
    begin
        // [FEATURE] [DTA Suggest Vendor Payments]
        // [SCENARIO 372205] DTA Suggest Vendor Payment throws an error with detailed info when Vendor Bank Account "ESR Type" is changed after posting
        Initialize();
        Dates[1] := WorkDate();
        Amounts[1] := -LibraryRandom.RandDecInRange(100, 300, 2);

        // [GIVEN] Vendor "V". Vendor Bank Account "VB" with "ESR Type" = "9/27"
        // [GIVEN] Create and post Purchase Invoice "PI"
        LibraryDTA.CreateTestGenJournalLines(
          Vendor, VendorBankAccount, GenJournalLineArray, GenJournalBatch, 1, Dates, Amounts, TestOption::"ESR9/27", '', '', false);

        // [GIVEN] Modify "VB"."Payment Form " = "5/15"
        VendorBankAccount.Validate("ESR Type", VendorBankAccount."ESR Type"::"5/15");
        VendorBankAccount.Modify();

        // [WHEN] Run the DTA Suggest Vendor Payment
        asserterror RunDTASuggestVendorPayment(GenJournalBatch, GenJournalLineArray[1]."Account No.", Dates[1], Dates[1], Dates[1], '');

        // [THEN] Error occurs:
        // [THEN] "The reference number may only be modified for ESR type 9/16 and 9/27.
        // [THEN] Vendor: "V".
        // [THEN] Vendor Bank Account: "VB".
        // [THEN] Document Type: Invoice.
        // [THEN] Document No.: "PI"."
        VerifyExpectedErrorSuggestPayments(GenJournalLineArray[1], VendorBankAccount.Code, BankESRTypeChangedErr);
    end;

    [Test]
    [HandlerFunctions('DTASuggestVendorPaymentsRequestPageHandler,MessageHandler,DTAPaymentOrderSaveAsExcelPageHandler')]
    [Scope('OnPrem')]
    procedure DTAPaymentOrderFooterWithSeveralDTASetup()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        Vendor: array[3] of Record Vendor;
        DTASetup: array[3] of Record "DTA Setup";
        Amounts: array[3] of Decimal;
        i: Integer;
    begin
        // [FEATURE] [DTA Payment Order]
        // [SCENARIO 379934] DTA Payment Order shows proper footer values when printing several DTA Setup
        Initialize();

        // [GIVEN] Create batch for payments
        LibraryDTA.CreateGeneralJournalBatch(GenJournalBatch, DummyGenJournalTemplate.Type::Payments, true);

        // [GIVEN] Create 3 vendor invoices for different DTA Setup
        // [GIVEN] Create 3 vendor payments by Run DTA Suggest Vendor Payments report
        for i := 1 to ArrayLen(Amounts) do begin
            LibraryDTA.CreateDTASetup(DTASetup[i], '', false);
            CreateVendorAndPostVendorInvoice(Vendor[i], Amounts[i], DTASetup[i]."Bank Code");
            RunDTASuggestVendorPayment(GenJournalBatch, Vendor[i]."No.", WorkDate(), WorkDate(), WorkDate(), '');
        end;

        // [WHEN] Run report DTA Payment Order
        RunDTAPaymentOrderForJournalBatch(GenJournalBatch);

        // [THEN] Each of 3 footer total amount appears on appropriate page
        VerifyDTAPaymentOrderFooter(Amounts);
    end;

    local procedure Initialize()
    var
        GenJournalLine: Record "Gen. Journal Line";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryAzureKVMockMgmt: Codeunit "Library - Azure KV Mock Mgmt.";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"CH DTA Reports");
        // Clear globals.

        // Remove previously created GL lines
        GenJournalLine.DeleteAll();
        Clear(LibraryReportValidation);

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"CH DTA Reports");

        CompanyInformation.Get();

        LibraryAzureKVMockMgmt.InitMockAzureKeyvaultSecretProvider();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateAccountInVendorPostingGroups();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateGenJournalTemplate();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"CH DTA Reports");
    end;

    local procedure CreateVendorAndPostVendorInvoice(var Vendor: Record Vendor; var Amount: Decimal; DebitBankNo: Code[20])
    var
        VendorBankAccount: Record "Vendor Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryDTA.CreateVendor(Vendor);
        LibraryDTA.CreateVendorBankAccount(VendorBankAccount, Vendor."No.", TestOption::"Post Payment Domestic", DebitBankNo);
        // Post Invoice
        Amount := -LibraryRandom.RandDecInRange(100, 300, 2);
        LibraryDTA.CreateGeneralJournalBatch(GenJournalBatch, DummyGenJournalTemplate.Type::Purchases, false);
        LibraryDTA.CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, WorkDate(), Vendor."No.",
          GenJournalLine."Document Type"::Invoice, Amount, VendorBankAccount.Code,
          TestOption::"Post Payment Domestic", '');
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    [Scope('OnPrem')]
    procedure CreateGenJournalLineWithPaymentDiscount(var GenJournalLine: Record "Gen. Journal Line"; var GenJournalBatch: Record "Gen. Journal Batch"; PostingDate: Date; LineAmount: Decimal; CurrencyCode: Code[10])
    var
        Vendor: Record Vendor;
        PaymentTerms: Record "Payment Terms";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, true);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Terms Code", PaymentTerms.Code);
        Vendor.Modify(true);

        CreateGenJournalBatchType(GenJournalBatch, GenJournalTemplate.Type::Purchases);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor,
          Vendor."No.", GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
          LineAmount);

        GenJournalLine.Validate("External Document No.", GenJournalLine."Document No.");
        GenJournalLine.Validate("Posting Date", PostingDate);
        if CurrencyCode <> '' then
            GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateGenJournalBatchType(var GenJournalBatch: Record "Gen. Journal Batch"; Type: Enum "Gen. Journal Template Type")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        GenJournalTemplate.SetRange(Recurring, false);
        GenJournalTemplate.SetRange(Type, Type);
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryUtility.CreateNoSeries(NoSeries, true, false, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, LibraryUtility.GenerateGUID(), '');
        GenJournalBatch.Validate("No. Series", NoSeries.Code);
        GenJournalBatch.Modify(true);
    end;

    local procedure GetDTAPaymentOrderRowOffset(SheetNo: Integer): Integer
    begin
        // Row offset between sheets for Excel Buffer of DTA Payment Order
        exit((SheetNo - 1) * 28);
    end;

    local procedure RunDTASuggestVendorPayment(GenJournalBatch: Record "Gen. Journal Batch"; VendorNo: Code[80]; PostingDate: Date; DueDateFrom: Date; DueDateTo: Date; DebitToBank: Code[10])
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        DTASuggestVendorPayments: Report "DTA Suggest Vendor Payments";
    begin
        GenJournalLine.Init();  // INIT is mandatory for Gen. Journal Line to Set the General Template and General Batch Name.
        GenJournalLine.Validate("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.Validate("Journal Batch Name", GenJournalBatch.Name);
        DTASuggestVendorPayments.DefineJournalName(GenJournalLine);

        LibraryVariableStorage.Enqueue(PostingDate);
        LibraryVariableStorage.Enqueue(DueDateFrom);
        LibraryVariableStorage.Enqueue(DueDateTo);
        LibraryVariableStorage.Enqueue(DebitToBank);

        Vendor.SetFilter("No.", VendorNo);
        DTASuggestVendorPayments.SetTableView(Vendor);
        DTASuggestVendorPayments.UseRequestPage(true);
        Commit();
        DTASuggestVendorPayments.RunModal();
    end;

    local procedure RunDTAPaymentOrderForJournalBatch(GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);  // for the LibraryReportValidation file name
        REPORT.Run(REPORT::"DTA Payment Order", true, false, GenJournalLine);
    end;

    local procedure VerifyGenJournalNoOfLines(GenJournalBatch: Record "Gen. Journal Batch"; ExpectedNoOfLines: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        Assert.AreEqual(ExpectedNoOfLines, GenJournalLine.Count, StrSubstNo(NumberOfLinesErr, ExpectedNoOfLines, GenJournalLine.TableCaption));
    end;

    local procedure VerifyGenJournalExtDocNo(GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.FindSet();
        repeat
            Assert.AreEqual(
              GenJournalLine."Applies-to Doc. No.", GenJournalLine."Applies-to Ext. Doc. No.", GenJournalLine.FieldCaption("Applies-to Ext. Doc. No."));
        until GenJournalLine.Next() = 0;
    end;

    local procedure VerifyExpectedErrorSuggestPayments(GenJournalLine: Record "Gen. Journal Line"; VendBankAccCode: Code[20]; ExpectedError: Text)
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(ExpectedError);
        Assert.ExpectedError(StrSubstNo(DetailInfoMsg, Vendor.TableCaption(), GenJournalLine."Account No."));
        Assert.ExpectedError(StrSubstNo(DetailInfoMsg, VendorBankAccount.TableCaption(), VendBankAccCode));
        Assert.ExpectedError(
          StrSubstNo(DetailInfoMsg, GenJournalLine.FieldCaption("Document Type"), GenJournalLine."Document Type"::Invoice));
        Assert.ExpectedError(
          StrSubstNo(DetailInfoMsg, GenJournalLine.FieldCaption("Document No."), GenJournalLine."Document No."));
    end;

    local procedure VerifyDTAPaymentOrderFooter(Amount: array[3] of Decimal)
    var
        i: Integer;
    begin
        LibraryReportValidation.OpenExcelFile();
        for i := 1 to ArrayLen(Amount) do
            LibraryReportValidation.VerifyCellValueOnWorksheet(25 + GetDTAPaymentOrderRowOffset(i), 10, Format(-Amount[i]), Format(i));
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Message Handler.
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VendorLedgerEntryPageHandler(var VendorLedgerEntries: TestPage "Vendor Ledger Entries")
    begin
        VendorLedgerEntries.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure DTASpecificConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        if StrPos(Question, DTANoVendorBankAccountTxt) > 0 then begin
            Reply := true;
            exit;
        end;
        if StrPos(Question, DTAOpenBankCardTxt) > 0 then begin
            Reply := false;
            exit;
        end;

        Error(UnexpectedConfirmDialogErr, Question);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DTASuggestVendorPaymentsRequestPageHandler(var DTASuggestVendorPayments: TestRequestPage "DTA Suggest Vendor Payments")
    var
        VarPostingDate: Variant;
        VarDueDateFrom: Variant;
        VarDueDateTo: Variant;
        DebitToBank: Variant;
    begin
        LibraryVariableStorage.Dequeue(VarPostingDate);
        LibraryVariableStorage.Dequeue(VarDueDateFrom);
        LibraryVariableStorage.Dequeue(VarDueDateTo);
        LibraryVariableStorage.Dequeue(DebitToBank);

        DTASuggestVendorPayments."Posting Date".SetValue(VarPostingDate); // Posting Date
        DTASuggestVendorPayments."Due Date from".SetValue(VarDueDateFrom); // Due Date From
        DTASuggestVendorPayments."Due Date to".SetValue(VarDueDateTo); // Due Date To
        if Format(DebitToBank) <> '' then
            DTASuggestVendorPayments."ReqFormDebitBank.""Bank Code""".SetValue(DebitToBank);

        DTASuggestVendorPayments.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DTASuggestVendorPaymentsRequestAutoDebitPageHandler(var DTASuggestVendorPayments: TestRequestPage "DTA Suggest Vendor Payments")
    begin
        DTASuggestVendorPayments."Posting Date".SetValue(LibraryVariableStorage.DequeueDate()); // Posting Date
        DTASuggestVendorPayments."Due Date from".SetValue(LibraryVariableStorage.DequeueDate()); // Due Date From
        DTASuggestVendorPayments."Due Date to".SetValue(LibraryVariableStorage.DequeueDate()); // Due Date To
        DTASuggestVendorPayments."Cash Disc. Date from".SetValue(LibraryVariableStorage.DequeueDate()); // Cash Disc. Date from
        DTASuggestVendorPayments."Cash Disc. Date to".SetValue(LibraryVariableStorage.DequeueDate()); // Cash Disc. Date to
        DTASuggestVendorPayments."Auto. Debit Bank".SetValue(LibraryVariableStorage.DequeueBoolean()); // Auto. Debit Bank
        DTASuggestVendorPayments.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DTAPaymentJournalRequestPageHandler(var DTAPaymentJournal: TestRequestPage "DTA Payment Journal")
    var
        "Layout": Variant;
        LayoutOption: Option;
    begin
        LibraryVariableStorage.Dequeue(Layout);
        LayoutOption := Layout;

        DTAPaymentJournal.Layout.SetValue(LayoutOption);
        DTAPaymentJournal.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DTAPaymentOrderRequestPageHandler(var DTAPaymentOrder: TestRequestPage "DTA Payment Order")
    begin
        DTAPaymentOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DTAPaymentOrderSaveAsExcelPageHandler(var DTAPaymentOrder: TestRequestPage "DTA Payment Order")
    begin
        LibraryReportValidation.SetFileName(LibraryVariableStorage.DequeueText());
        DTAPaymentOrder.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure EZAGPaymentOrderRequestPageHandler(var EZAGPaymentOrder: TestRequestPage "EZAG Payment Order")
    var
        BankCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankCode);
        EZAGPaymentOrder."DtaSetup.""Bank Code""".SetValue(BankCode);
        EZAGPaymentOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModifyDocumentNumberInputDialogHandler(var ModifyDocumentNumberInput: TestPage "Modify Document Number Input")
    begin
        ModifyDocumentNumberInput.NewDocumentNo.SetValue(TestDocNoTxt);
        ModifyDocumentNumberInput.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorPaymentOrderRequestPageHandler(var VendorPaymentOrder: TestRequestPage "Vendor Payment Order")
    var
        BatchName: Variant;
    begin
        LibraryVariableStorage.Dequeue(BatchName);
        VendorPaymentOrder.JourName.SetValue(BatchName);
        VendorPaymentOrder.DebitDate.SetValue(WorkDate());
        VendorPaymentOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ExchangeRatePageHandler(var ChangeExchangeRate: TestPage "Change Exchange Rate")
    begin
        ChangeExchangeRate.RefExchRate.SetValue(LibraryRandom.RandDecInRange(100, 200, 2));
        ChangeExchangeRate.OK().Invoke();
    end;
}

