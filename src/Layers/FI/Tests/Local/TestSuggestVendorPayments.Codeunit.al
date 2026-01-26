codeunit 144024 "Test Suggest Vendor Payments"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Suggest Bank Payments] [Vendor]
        IsInitialized := false;
    end;

    var
        CountryRegion: Record "Country/Region";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryJournals: Codeunit "Library - Journals";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('RPHSuggestBankPayments')]
    [Scope('OnPrem')]
    procedure VerifyPaymentsPickedByDueDate()
    var
        PurchaseHeader: Record "Purchase Header";
        RefPmtExported: Record "Ref. Payment - Exported";
        BankAccountNo: Code[20];
        VendorNo: Code[20];
    begin
        Initialize();

        // Setup
        BankAccountNo := CreateBankAccount();
        VendorNo := CreateVendor();

        CreateAndPostPurchaseDocumentWithRandomAmounts(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo, false, true, PurchaseHeader."Message Type"::"Reference No.");

        // Exercise
        RunSuggestBankPayments(false, false, BankAccountNo, VendorNo, CalcDate('<-30D>', PurchaseHeader."Posting Date"));

        // Verify
        Assert.AreEqual(0, RefPmtExported.Count, 'Nothing should be added');

        // Exercise
        RunSuggestBankPayments(false, false, BankAccountNo, VendorNo, CalcDate('<30D>', PurchaseHeader."Posting Date"));

        // Verify
        Assert.RecordCount(RefPmtExported, 1);
        RefPmtExported.FindFirst();
        Assert.AreEqual(
          PurchaseHeader."Posting Date", RefPmtExported."Due Date", 'Due date sould be the same as posting date on the purchase invoice');
    end;

    [Test]
    [HandlerFunctions('RPHSuggestBankPayments')]
    [Scope('OnPrem')]
    procedure VerifyPaymentsPickedIncludeDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        RefPmtExported: Record "Ref. Payment - Exported";
        BankAccountNo: Code[20];
        VendorNo: Code[20];
    begin
        Initialize();

        // Setup
        BankAccountNo := CreateBankAccount();
        VendorNo := CreateVendorWithPmtTerms();

        CreateRefPaymentExportLinesFromJournal(BankAccountNo, VendorNo, PurchaseHeader."Document Type"::Invoice, -1000, '');
        CreateRefPaymentExportLinesFromJournal(BankAccountNo, VendorNo, PurchaseHeader."Document Type"::"Credit Memo", 100, '');

        // Exercise
        RunSuggestBankPayments(true, false, BankAccountNo, VendorNo, CalcDate('<300D>', WorkDate()));
        Commit();

        // Verify
        RefPmtExported.FindSet();
        Assert.RecordCount(RefPmtExported, 2);
        Assert.AreEqual(-90, RefPmtExported.Amount, 'Credit Memo amount with discount');
        RefPmtExported.Next();
        Assert.AreEqual(900, RefPmtExported.Amount, 'Invoice amount with discount');
    end;

    [Test]
    [HandlerFunctions('RPHSuggestBankPayments')]
    [Scope('OnPrem')]
    procedure VerifySuggestReportIgnoresBlockedVendor()
    var
        PurchaseHeader: Record "Purchase Header";
        RefPmtExported: Record "Ref. Payment - Exported";
        VendorNo: array[2] of Code[20];
    begin
        // [SCENARIO 273616] Blocked vendor is ignored when running a SuggestBankPayments report
        Initialize();

        // [GIVEN] A vendor[1] blocked by payment
        VendorNo[1] := CreateBlockedVendor();
        // [GIVEN] Vendor[2] not blocked
        VendorNo[2] := CreateVendor();
        // [GIVEN] Created and posted invoices for Vendor[1] and Vendor[2]
        CreateAndPostPurchaseDocumentWithRandomAmounts(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo[1], false, true, PurchaseHeader."Message Type"::"Reference No.");
        CreateAndPostPurchaseDocumentWithRandomAmounts(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo[2], false, true, PurchaseHeader."Message Type"::"Reference No.");

        // [WHEN] Run SuggestBankPayments report for both vendors
        RunSuggestBankPayments(false, false, '', VendorNo[1] + '|' + VendorNo[2], CalcDate('<30D>', PurchaseHeader."Posting Date"));

        // [THEN] Payment for Vendor[1] has not been suggested
        RefPmtExported.SetRange("Vendor No.", VendorNo[1]);
        Assert.RecordIsEmpty(RefPmtExported);
        // [THEN] Payment for Vendor[2] has been suggested
        RefPmtExported.SetRange("Vendor No.", VendorNo[2]);
        Assert.RecordIsNotEmpty(RefPmtExported);
    end;

    [Test]
    [HandlerFunctions('RPHSuggestBankPayments')]
    [Scope('OnPrem')]
    procedure VerifyPaymentsIncludePmtDiscountBeforeGracePeriod()
    var
        PurchaseHeader: Record "Purchase Header";
        RefPmtExported: Record "Ref. Payment - Exported";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccountNo: Code[20];
        VendorNo: Code[20];
    begin
        // [FEATURE] [Payment Discount Tolerance]
        // [SCENARIO 312144] Payment Discount is taken into account when Bank Payment is suggested on the date before grace period
        Initialize();

        // [GIVEN] Pmt. Disc. Tolerance with grace period = <5D> in G/L Setup
        SetPmtDiscToleranceGLSetup();

        // [GIVEN] Posted Purchase Invoice on 06-06-19 with 'Pmt. Discount Date' = 20-06-19 and 'Pmt. Disc. Tolerance Date' = 25-06-19
        // [GIVEN] Amount = 1000, Pmt. Disc. Possible = 100
        BankAccountNo := CreateBankAccount();
        VendorNo := CreateVendorWithPmtTerms();

        CreateRefPaymentExportLinesFromJournal(
          BankAccountNo, VendorNo, PurchaseHeader."Document Type"::Invoice, -LibraryRandom.RandDecInRange(1000, 2000, 2), '');
        UpdatePmtDiscDateVLE(VendorLedgerEntry, VendorNo, WorkDate() + 1);
        VendorLedgerEntry.TestField("Original Pmt. Disc. Possible");
        Commit();

        // [WHEN] Run Suggest Bank Payment report on 20-06-19 with option 'Find Payment Discount' = Yes, 'Find Payment Discount Tolerance' = No
        RunSuggestBankPayments(true, false, BankAccountNo, VendorNo, CalcDate('<300D>', WorkDate()));

        // [THEN] Suggested amount is equal to 900
        RefPmtExported.FindFirst();
        Assert.RecordCount(RefPmtExported, 1);
        RefPmtExported.TestField(Amount, -VendorLedgerEntry.Amount + VendorLedgerEntry."Original Pmt. Disc. Possible");
    end;

    [Test]
    [HandlerFunctions('RPHSuggestBankPayments')]
    [Scope('OnPrem')]
    procedure VerifyPaymentsDoNotIncludePmtDiscountWithinGracePeriod()
    var
        PurchaseHeader: Record "Purchase Header";
        RefPmtExported: Record "Ref. Payment - Exported";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccountNo: Code[20];
        VendorNo: Code[20];
    begin
        // [FEATURE] [Payment Discount Tolerance]
        // [SCENARIO 312144] Payment Discount is not taken into account when Bank Payment is suggested on the date within grace period when 'Find Payment Discount Tolerance' = No
        Initialize();

        // [GIVEN] Pmt. Disc. Tolerance with grace period = <5D> in G/L Setup
        SetPmtDiscToleranceGLSetup();

        // [GIVEN] Posted Purchase Invoice on 06-06-19 with 'Pmt. Discount Date' = 20-06-19 and 'Pmt. Disc. Tolerance Date' = 25-06-19
        // [GIVEN] Amount = 1000, Pmt. Disc. Possible = 100
        BankAccountNo := CreateBankAccount();
        VendorNo := CreateVendorWithPmtTerms();

        CreateRefPaymentExportLinesFromJournal(
          BankAccountNo, VendorNo, PurchaseHeader."Document Type"::Invoice, -LibraryRandom.RandDecInRange(1000, 2000, 2), '');
        UpdatePmtDiscDateVLE(VendorLedgerEntry, VendorNo, WorkDate());
        VendorLedgerEntry.TestField("Original Pmt. Disc. Possible");
        Commit();

        // [WHEN] Run Suggest Bank Payment report on 25-06-19 with options 'Find Payment Discount' = Yes, 'Find Payment Discount Tolerance' = No
        RunSuggestBankPayments(true, false, BankAccountNo, VendorNo, CalcDate('<300D>', WorkDate()));

        // [THEN] Suggested amount is equal to 1000
        RefPmtExported.FindFirst();
        Assert.RecordCount(RefPmtExported, 1);
        RefPmtExported.TestField(Amount, -VendorLedgerEntry.Amount);
    end;

    [Test]
    [HandlerFunctions('RPHSuggestBankPayments')]
    [Scope('OnPrem')]
    procedure VerifyPaymentsIncludePmtDiscToleranceWithinGracePeriod()
    var
        PurchaseHeader: Record "Purchase Header";
        RefPmtExported: Record "Ref. Payment - Exported";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccountNo: Code[20];
        VendorNo: Code[20];
    begin
        // [FEATURE] [Payment Discount Tolerance]
        // [SCENARIO 312144] Payment Discount is taken into account when Bank Payment is suggested on the date within grace period when 'Find Payment Discount Tolerance' = Yes
        Initialize();

        // [GIVEN] Pmt. Disc. Tolerance with grace period = <5D> in G/L Setup
        SetPmtDiscToleranceGLSetup();

        // [GIVEN] Posted Purchase Invoice on 06-06-19 with 'Pmt. Discount Date' = 20-06-19 and 'Pmt. Disc. Tolerance Date' = 25-06-19
        // [GIVEN] Amount = 1000, Pmt. Disc. Possible = 100
        BankAccountNo := CreateBankAccount();
        VendorNo := CreateVendorWithPmtTerms();

        CreateRefPaymentExportLinesFromJournal(
          BankAccountNo, VendorNo, PurchaseHeader."Document Type"::Invoice, -LibraryRandom.RandDecInRange(1000, 2000, 2), '');
        UpdatePmtDiscDateVLE(VendorLedgerEntry, VendorNo, WorkDate());
        VendorLedgerEntry.TestField("Original Pmt. Disc. Possible");
        Commit();

        // [WHEN] Run Suggest Bank Payment report on 25-06-19 with options 'Find Payment Discount' = Yes, 'Find Payment Discount Tolerance' = Yes
        RunSuggestBankPayments(true, true, BankAccountNo, VendorNo, CalcDate('<300D>', WorkDate()));

        // [THEN] Suggested amount is equal to 900
        RefPmtExported.FindFirst();
        Assert.RecordCount(RefPmtExported, 1);
        RefPmtExported.TestField(Amount, -VendorLedgerEntry.Amount + VendorLedgerEntry."Original Pmt. Disc. Possible");
    end;

    [Test]
    [HandlerFunctions('RPHSuggestBankPayments')]
    [Scope('OnPrem')]
    procedure VerifyPaymentsDoNotIncludePmtDiscountAfterGracePeriod()
    var
        PurchaseHeader: Record "Purchase Header";
        RefPmtExported: Record "Ref. Payment - Exported";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccountNo: Code[20];
        VendorNo: Code[20];
    begin
        // [FEATURE] [Payment Discount Tolerance]
        // [SCENARIO 312144] Payment Discount is not taken into account when Bank Payment is suggested on the date after grace period when 'Find Payment Discount' = Yes, 'Find Payment Discount Tolerance' = 'No'
        Initialize();

        // [GIVEN] Pmt. Disc. Tolerance with grace period = <5D> in G/L Setup
        SetPmtDiscToleranceGLSetup();

        // [GIVEN] Posted Purchase Invoice on 06-06-19 with 'Pmt. Discount Date' = 20-06-19 and 'Pmt. Disc. Tolerance Date' = 25-06-19
        // [GIVEN] Amount = 1000, Pmt. Disc. Possible = 100
        BankAccountNo := CreateBankAccount();
        VendorNo := CreateVendorWithPmtTerms();

        CreateRefPaymentExportLinesFromJournal(
          BankAccountNo, VendorNo, PurchaseHeader."Document Type"::Invoice, -LibraryRandom.RandDecInRange(1000, 2000, 2), '');
        UpdatePmtDiscDateVLE(VendorLedgerEntry, VendorNo, WorkDate() - 1);
        VendorLedgerEntry.TestField("Original Pmt. Disc. Possible");
        Commit();

        // [WHEN] Run Suggest Bank Payment report on 30-06-19 with options 'Find Payment Discount' = Yes, 'Find Payment Discount Tolerance' = No
        RunSuggestBankPayments(true, false, BankAccountNo, VendorNo, CalcDate('<300D>', WorkDate()));

        // [THEN] Suggested amount is equal to 1000
        RefPmtExported.FindFirst();
        Assert.RecordCount(RefPmtExported, 1);
        RefPmtExported.TestField(Amount, -VendorLedgerEntry.Amount);
    end;

    [Test]
    [HandlerFunctions('RPHSuggestBankPayments')]
    [Scope('OnPrem')]
    procedure VerifyPaymentsDoNotIncludePmtDiscToleranceAfterGracePeriod()
    var
        PurchaseHeader: Record "Purchase Header";
        RefPmtExported: Record "Ref. Payment - Exported";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccountNo: Code[20];
        VendorNo: Code[20];
    begin
        // [FEATURE] [Payment Discount Tolerance]
        // [SCENARIO 312144] Payment Discount is not taken into account when Bank Payment is suggested on the date after grace period when with options 'Find Payment Discount' = Yes, 'Find Payment Discount Tolerance' = Yes
        Initialize();

        // [GIVEN] Pmt. Disc. Tolerance with grace period = <5D> in G/L Setup
        SetPmtDiscToleranceGLSetup();

        // [GIVEN] Posted Purchase Invoice on 06-06-19 with 'Pmt. Discount Date' = 20-06-19 and 'Pmt. Disc. Tolerance Date' = 25-06-19
        // [GIVEN] Amount = 1000, Pmt. Disc. Possible = 100
        BankAccountNo := CreateBankAccount();
        VendorNo := CreateVendorWithPmtTerms();

        CreateRefPaymentExportLinesFromJournal(
          BankAccountNo, VendorNo, PurchaseHeader."Document Type"::Invoice, -LibraryRandom.RandDecInRange(1000, 2000, 2), '');
        UpdatePmtDiscDateVLE(VendorLedgerEntry, VendorNo, WorkDate() - 1);
        VendorLedgerEntry.TestField("Original Pmt. Disc. Possible");
        Commit();

        // [WHEN] Run Suggest Bank Payment report on 30-06-19 with options 'Find Payment Discount' = Yes, 'Find Payment Discount Tolerance' = Yes
        RunSuggestBankPayments(true, true, BankAccountNo, VendorNo, CalcDate('<300D>', WorkDate()));

        // [THEN] Suggested amount is equal to 1000
        RefPmtExported.FindFirst();
        Assert.RecordCount(RefPmtExported, 1);
        RefPmtExported.TestField(Amount, -VendorLedgerEntry.Amount);
    end;

    [Test]
    [HandlerFunctions('RPHSuggestBankPaymentsWithCurrencyFilter')]
    [Scope('OnPrem')]
    procedure CurrencyFilterShouldApplyOnBankPaymentToSendWhenSuggestVendorPayment()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        RefPmtExported: Record "Ref. Payment - Exported";
        BankAccountNo: Code[20];
    begin
        // [SCENARIO 562522] The Currency filter is not considered if you Suggest Vendor Payments from the Bank Payment to send page in the Finnish version
        Initialize();

        // [GIVEN] Create Vendor with currency and Bank Account No.
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", LibraryERM.CreateCurrencyWithRandomExchRates());
        Vendor.Modify(true);
        BankAccountNo := CreateBankAccount();

        // [GIVEN] Create and Post Purchase Invoice
        CreateAndPostPurchaseDocumentWithRandomAmounts(
            PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.",
            false, true, PurchaseHeader."Message Type"::Message);

        // [WHEN] Running Suggest Bank Payment with Currency Code filter
        RunSuggestBankPaymentsWithCurrencyCode(BankAccountNo, Vendor."No.", Vendor."Currency Code", CalcDate('<30D>', PurchaseHeader."Posting Date"));

        // [THEN] Verify count to confirm exported entry
        Assert.RecordCount(RefPmtExported, 1);
    end;

    local procedure Initialize()
    var
        RefPmtExported: Record "Ref. Payment - Exported";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Test Suggest Vendor Payments");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        RefPmtExported.DeleteAll();
        Commit();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Test Suggest Vendor Payments");
        IsInitialized := true;

        CountryRegion.Get('FI');
        InitCompanyInformation(CountryRegion.Code);
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Test Suggest Vendor Payments");
    end;

    local procedure InitCompanyInformation(CountryCode: Code[10])
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation."Country/Region Code" := CountryCode;
        CompanyInformation.Modify();
    end;

    local procedure CreateBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        exit(BankAccount."No.");
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorWithPmtTerms(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(CreateVendor());
        Vendor.Validate("Payment Terms Code", CreatePaymentTerms());
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateBlockedVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate(Blocked, Vendor.Blocked::Payment);
        Vendor.Modify();
        exit(Vendor."No.");
    end;

    local procedure CreateRefPaymentExportLinesFromJournal(BankAccountNo: Code[20]; VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal; CurrencyCode: Code[10])
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlTemplate.SetRange(Type, GenJnlTemplate.Type::Purchases);
        LibraryERM.FindGenJournalTemplate(GenJnlTemplate);
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);

        LibraryJournals.CreateGenJournalLine(
          GenJnlLine, GenJnlTemplate.Name, GenJnlBatch.Name, DocumentType, GenJnlLine."Account Type"::Vendor, VendorNo,
          GenJnlLine."Bal. Account Type"::"Bank Account", BankAccountNo, Amount);
        GenJnlLine.Validate("External Document No.", Format(LibraryRandom.RandIntInRange(1, 99)));
        GenJnlLine.Validate("Message Type", GenJnlLine."Message Type"::"Reference No");
        GenJnlLine.Validate("Invoice Message", '268745');
        GenJnlLine.Validate("Currency Code", CurrencyCode);
        GenJnlLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
    end;

    local procedure CreateAndPostPurchaseDocumentWithRandomAmounts(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Gen. Journal Document Type"; VendorNo: Code[20]; ToShipReceive: Boolean; ToInvoice: Boolean; MessageType: Option) DocumentNo: Code[20]
    var
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        Precision: Integer;
        InvoiceMessage: Text[250];
        InvoiceMessage2: Text[250];
    begin
        Precision := LibraryRandom.RandIntInRange(2, 5);
        if MessageType <> PurchaseHeader."Message Type"::"Reference No." then begin
            InvoiceMessage :=
              LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Invoice Message"), DATABASE::"Purchase Header");
            InvoiceMessage2 :=
              LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Invoice Message 2"), DATABASE::"Purchase Header");
        end else
            InvoiceMessage := '268745';
        LibraryInventory.CreateItem(Item);

        DocumentNo :=
          CreateAndPostPurchaseDocument(
            PurchaseHeader, DocumentType, VendorNo,
            PurchaseLine.Type::Item, Item."No.",
            LibraryRandom.RandDec(1000, Precision), LibraryRandom.RandDec(1000, Precision),
            ToShipReceive, ToInvoice,
            MessageType, InvoiceMessage, InvoiceMessage2);

        exit(DocumentNo);
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; LineType: Enum "Purchase Line Type"; No: Code[20]; Quantity: Decimal; Cost: Decimal; ToShipReceive: Boolean; ToInvoice: Boolean; MessageType: Option; InvoiceMessage: Text[250]; InvoiceMessage2: Text[250]): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify();

        PurchaseHeader.Validate("Message Type", MessageType);
        PurchaseHeader.Validate("Invoice Message", InvoiceMessage);
        PurchaseHeader.Validate("Invoice Message 2", InvoiceMessage2);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, LineType, No, Quantity);
        PurchaseLine.Validate("VAT %", 0);
        PurchaseLine.Validate("Direct Unit Cost", Cost);
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument2(PurchaseHeader, ToShipReceive, ToInvoice));
    end;

    local procedure CreatePaymentTerms(): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        PaymentTerms.Validate("Calc. Pmt. Disc. on Cr. Memos", true);
        PaymentTerms.Validate("Disreg. Pmt. Disc. at Full Pmt", true);
        Evaluate(PaymentTerms."Due Date Calculation", '<' + Format(LibraryRandom.RandIntInRange(1, 5)) + 'M>');
        Evaluate(PaymentTerms."Discount Date Calculation", '<' + Format(LibraryRandom.RandIntInRange(2, 10)) + 'D>');
        PaymentTerms.Validate("Due Date Calculation");
        PaymentTerms.Validate("Discount Date Calculation");
        PaymentTerms.Validate("Discount %", 10);
        PaymentTerms.Modify(true);
        exit(PaymentTerms.Code);
    end;

    local procedure SetPmtDiscToleranceGLSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Pmt. Disc. Tolerance Warning", true);
        Evaluate(GeneralLedgerSetup."Payment Discount Grace Period", StrSubstNo('<%1D>', LibraryRandom.RandIntInRange(5, 10)));
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdatePmtDiscDateVLE(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20]; PmtDiscTolDate: Date)
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.Validate("Pmt. Disc. Tolerance Date", PmtDiscTolDate);
        VendorLedgerEntry.Validate("Pmt. Discount Date", PmtDiscTolDate - 1);

        VendorLedgerEntry.Modify(true);
        VendorLedgerEntry.CalcFields(Amount);
    end;

    local procedure RunSuggestBankPayments(UsePaymentDisc: Boolean; UsePmtDiscTolerance: Boolean; BankAccountNo: Code[20]; VendorNo: Text; PaymentDate: Date)
    var
        SuggestBankPayments: Report "Suggest Bank Payments";
    begin
        LibraryVariableStorage.Enqueue(UsePaymentDisc);
        LibraryVariableStorage.Enqueue(UsePmtDiscTolerance);
        LibraryVariableStorage.Enqueue(BankAccountNo);
        LibraryVariableStorage.Enqueue(VendorNo);
        SuggestBankPayments.InitializeRequest(PaymentDate, true, 0);
        SuggestBankPayments.Run();

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure RunSuggestBankPaymentsWithCurrencyCode(BankAccountNo: Code[20]; VendorNo: Text; CurrencyCode: Code[10]; PaymentDate: Date)
    var
        SuggestBankPayments: Report "Suggest Bank Payments";
    begin
        LibraryVariableStorage.Enqueue(BankAccountNo);
        LibraryVariableStorage.Enqueue(VendorNo);
        LibraryVariableStorage.Enqueue(CurrencyCode);
        SuggestBankPayments.InitializeRequest(PaymentDate, true, 0);
        SuggestBankPayments.Run();

        LibraryVariableStorage.AssertEmpty();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RPHSuggestBankPayments(var RequestPage: TestRequestPage "Suggest Bank Payments")
    begin
        RequestPage."Find Payment Discounts".SetValue(LibraryVariableStorage.DequeueBoolean());
        RequestPage.UsePmtDiscTolerance.SetValue(LibraryVariableStorage.DequeueBoolean());
        RequestPage."Payment Account".SetValue(LibraryVariableStorage.DequeueText());
        RequestPage.Vendor.SetFilter("No.", LibraryVariableStorage.DequeueText());
        RequestPage.OK().Invoke();

        LibraryVariableStorage.AssertEmpty();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RPHSuggestBankPaymentsWithCurrencyFilter(var RequestPage: TestRequestPage "Suggest Bank Payments")
    begin
        RequestPage."Payment Account".SetValue(LibraryVariableStorage.DequeueText());
        RequestPage.Vendor.SetFilter("No.", LibraryVariableStorage.DequeueText());
        RequestPage.Vendor.SetFilter("Currency Filter", LibraryVariableStorage.DequeueText());
        RequestPage.OK().Invoke();

        LibraryVariableStorage.AssertEmpty();
    end;
}

