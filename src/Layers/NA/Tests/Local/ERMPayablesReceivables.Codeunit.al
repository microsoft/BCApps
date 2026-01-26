codeunit 142052 "ERM Payables/Receivables"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Deposit] [Reconciliation]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        AmountError: Label 'Amount must be equal.';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryJournals: Codeunit "Library - Journals";
        IsInitialized: Boolean;
        NothingToAdjustTxt: Label 'There is nothing to adjust.';

    [Test]
    [Scope('OnPrem')]
    procedure DescriptionOnCheckLedgerEntry()
    var
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
        CheckLedgerEntry: Record "Check Ledger Entry";
    begin
        // Verify Description in Check Ledger same as in Payment Journal after post Payment Entry to Vendor.

        // Setup: Create Bank Account and Vendor, create payment journal with manual check and post.
        Initialize();
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryPurchase.CreateVendor(Vendor);

        // Exercise.
        CreateAndPostGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, Vendor."No.", BankAccount."No.",
          GenJournalLine."Bank Payment Type"::"Manual Check", LibraryRandom.RandInt(100), GenJournalTemplate.Type::Payments,
          GenJournalLine."Document Type"::Payment);  // Using Random value for Deposit Amount.

        // Verify: Verify Description in Check Ledger same as in Payment Journal.
        CheckLedgerEntry.SetRange("Bank Account No.", BankAccount."No.");
        CheckLedgerEntry.FindFirst();
        CheckLedgerEntry.TestField(Description, GenJournalLine.Description);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentRequestPageHandler,MessageHandler,ConfirmHandler,GeneralJournalTemplateListPageHandler')]
    [Scope('OnPrem')]
    procedure SuggestVendFullPaymentAgainstInvoiceAndCrMemo()
    begin
        // Verify Vendor balance after post payment of remaining balance in case of fully applied Credit Memo.
        SuggestVendPaymentAgainstInvoiceAndCrMemo(1);  // Using 1 as multiplication factor for full value.
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentRequestPageHandler,MessageHandler,ConfirmHandler,GeneralJournalTemplateListPageHandler')]
    [Scope('OnPrem')]
    procedure SuggestVendPartialPaymentAgainstInvoiceAndCrMemo()
    begin
        // Verify Vendor balance after post payment of remaining balance in case of partial applied Credit Memo.
        SuggestVendPaymentAgainstInvoiceAndCrMemo(2);   // Using 2 as multiplication factor for partial value.
    end;

    local procedure SuggestVendPaymentAgainstInvoiceAndCrMemo(PartialFactor: Decimal)
    var
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // Setup: Create Vendor, Post Purchase Invoice and Credit Memo.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.CreateBankAccount(BankAccount);
        PostPurchInvAndCrMemo(Vendor."No.", Vendor."VAT Bus. Posting Group", PartialFactor);

        // Open Payment Journal, Suggest Vendor Payment and Post.
        GenJournalBatch.SetRange("Template Type", GenJournalBatch."Template Type"::Payments);
        GenJournalBatch.FindFirst();
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryVariableStorage.Enqueue(Vendor."No.");
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        Commit();  // Commit required for open Payment Journal.
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        PaymentJournal.SuggestVendorPayments.Invoke();

        // Exercise.
        PaymentJournal.Post.Invoke();  // Post.

        // Verify: Verify Vendor balance after post payment of remaining balance.
        Vendor.CalcFields("Balance (LCY)");
        Vendor.TestField("Balance (LCY)", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyEntriesForVendPartialPaymentAgainstInvoiceAndCrMemo()
    var
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Verify Vendor balance after post payment of remaining balance through Apply Entries.

        // Setup: Create Vendor, Post Purchase Invoice and Credit Memo.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.CreateBankAccount(BankAccount);
        PostPurchInvAndCrMemo(Vendor."No.", Vendor."VAT Bus. Posting Group", 2);  // Using 2 for partial payment.

        // Open Payment Journal, Suggest Vendor Payment and Post.
        CreatePaymentGenJournal(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, Vendor."No.", BankAccount."No.",
          GenJournalLine."Bank Payment Type"::"Manual Check", 0, GenJournalTemplate.Type::Payments,
          GenJournalLine."Document Type"::Payment);

        // Apply Vendor Ledger Entry and update Amount to Apply on Payment Journal.
        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry);
        GenJournalLine.Validate(Amount, VendorLedgerEntry."Amount to Apply");
        GenJournalLine.Modify(true);

        // Excercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Vendor balance after post payment of remaining balance through Apply Entries.
        Vendor.CalcFields("Balance (LCY)");
        Assert.AreNearlyEqual(0, Vendor."Balance (LCY)", LibraryERM.GetAmountRoundingPrecision(), AmountError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyEntriesForCustPartialPaymentAgainstInvoiceAndCrMemo()
    var
        Item: Record Item;
        Customer: Record Customer;
        BankAccount: Record "Bank Account";
        SalesLine: Record "Sales Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
        CustomerLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Verify Customer balance after post payment of remaining balance through Apply Entries.

        // Setup: Create Customer, Bank and Item.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryInventory.CreateItem(Item);

        // Post Sales Invoice and Credit Memo with partial quantity.
        CreateAndPostSalesDocument(SalesLine, Customer."No.", SalesLine."Document Type"::Invoice, SalesLine.Type::Item, Item."No.",
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(100));  // Using Random value for Quantity and Unit Price.
        CreateAndPostSalesDocument(SalesLine, Customer."No.", SalesLine."Document Type"::"Credit Memo", SalesLine.Type::Item, Item."No.",
          SalesLine.Quantity / 2, SalesLine."Unit Price");  // Using divide by 2 for partial value of Invoice.

        // Open Payment Journal, Suggest Customer Payment and Post.
        CreatePaymentGenJournal(
          GenJournalLine, GenJournalLine."Account Type"::Customer, Customer."No.", BankAccount."No.",
          GenJournalLine."Bank Payment Type"::"Manual Check", 0, GenJournalTemplate.Type::Payments,
          GenJournalLine."Document Type"::Payment);

        // Apply Customer Ledger Entry and update Amount to Apply on Payment Journal.
        CustomerLedgerEntry.SetRange("Customer No.", Customer."No.");
        LibraryERM.SetAppliestoIdCustomer(CustomerLedgerEntry);
        GenJournalLine.Validate(Amount, CustomerLedgerEntry."Amount to Apply");
        GenJournalLine.Modify(true);

        // Excercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Customer balance after post payment of remaining balance through Apply Entries.
        Customer.CalcFields("Balance (LCY)");
        Assert.AreNearlyEqual(0, Customer."Balance (LCY)", LibraryERM.GetAmountRoundingPrecision(), AmountError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPreviewContainsVendorAddress()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        Country: Record "Country/Region";
        CheckPreview: TestPage "Check Preview";
    begin
        // [FEATURE] [Payables]
        // [SCENARIO 378666] When we run Preview Check function from the Payment Journal correct Payee address is shown

        // [GIVEN] Vendor: Address=A, "Address 2"=B, City=C, County=D, "Post Code"=E,  "Country/Region Code"="Country/Region".Code; "Country/Region".Name=F
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Address := 'A';
        Vendor."Address 2" := 'B';
        Vendor.City := 'C';
        Vendor.County := 'D';
        Vendor."Post Code" := 'E';
        LibraryERM.CreateCountryRegion(Country);
        Country.Name := 'F';
        Country.Modify();
        Vendor."Country/Region Code" := Country.Code;
        Vendor.Modify();
        // [GIVEN] Gen. Journal Line payment to Vendor
        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, Vendor."No.", 100);

        // [WHEN] Calling page "Check Preview"
        CallCheckPreview(CheckPreview, GenJournalLine);

        // [THEN] Page "Address" field is 'A, B, C, E, D, F'
        CheckPreview.Address.AssertEquals('A, B, C, E, D, F');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPreviewContainsCustomerAddress()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        Country: Record "Country/Region";
        CheckPreview: TestPage "Check Preview";
    begin
        // [FEATURE] [Receivables]
        // [SCENARIO 378666] When we run Preview Check function from the Payment Journal correct Payee address is shown

        // [GIVEN] Customer: Address=A, "Address 2"=B, City=C, County=D, "Post Code"=E,  "Country/Region Code"="Country/Region".Code; "Country/Region".Name=F
        LibrarySales.CreateCustomer(Customer);
        Customer.Address := 'A';
        Customer."Address 2" := 'B';
        Customer.City := 'C';
        Customer.County := 'D';
        Customer."Post Code" := 'E';
        LibraryERM.CreateCountryRegion(Country);
        Country.Name := 'F';
        Country.Modify();
        Customer."Country/Region Code" := Country.Code;
        Customer.Modify();
        // [GIVEN] Gen. Journal Line refund to Customer
        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLine, GenJournalLine."Document Type"::Refund,
          GenJournalLine."Account Type"::Customer, Customer."No.", 100);

        // [WHEN] Calling page "Check Preview"
        CallCheckPreview(CheckPreview, GenJournalLine);

        // [THEN] Page "Address" field is 'A, B, C, E, D, F'
        CheckPreview.Address.AssertEquals('A, B, C, E, D, F');
    end;

    local procedure Initialize()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;
        LibraryERMCountryData.CreateVATData();
        LibraryInventory.NoSeriesSetup(InventorySetup);
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        UpdateGenLedgerSetup('');
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        IsInitialized := true;
        Commit();
    end;

    local procedure CreateVATPostingSetup(VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if not VATPostingSetup.Get(VATBusPostingGroup, VATProdPostingGroup) then
            LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup, VATProdPostingGroup);
    end;

    local procedure CreateAndPostGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; BalAccountNo: Code[20]; BankPaymentType: Enum "Bank Payment Type"; Amount: Decimal; Type: Enum "Gen. Journal Template Type"; DocumentType: Enum "Gen. Journal Document Type")
    begin
        CreatePaymentGenJournal(
          GenJournalLine, AccountType, AccountNo, BalAccountNo, BankPaymentType, Amount, Type, DocumentType);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; BuyfromVendorNo: Code[20]; No: Code[20]; Type: Enum "Purchase Line Type"; Quantity: Decimal; DirectUnitCost: Decimal): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, BuyfromVendorNo);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostSalesDocument(var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; DocumentType: Enum "Sales Document Type"; Type: Enum "Sales Line Type"; No: Code[20]; Quantity: Decimal; UnitPrice: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, No, Quantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; Type: Enum "Gen. Journal Template Type")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, Type);
        GenJournalTemplate.Modify(true);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreatePaymentGenJournal(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; BalAccountNo: Code[20]; BankPaymentType: Enum "Bank Payment Type"; Amount: Decimal; Type: Enum "Gen. Journal Template Type"; DocumentType: Enum "Gen. Journal Document Type")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJournalBatch(GenJournalBatch, Type);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          AccountType, AccountNo, Amount);  // Using Random value for Deposit Amount.
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Validate("Bank Payment Type", BankPaymentType);
        GenJournalLine.Modify(true);
    end;

    local procedure PostPurchInvAndCrMemo(VendorNo: Code[20]; VATBusPostingGroup: Code[20]; PartialFactor: Decimal)
    var
        GLAccount: Record "G/L Account";
        PurchaseLine: Record "Purchase Line";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.FindGenProductPostingGroup(GenProductPostingGroup);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProductPostingGroup.Code);
        GLAccount.Modify(true);
        CreateVATPostingSetup(VATBusPostingGroup, GLAccount."VAT Prod. Posting Group");
        CreateAndPostPurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Invoice, VendorNo, GLAccount."No.", PurchaseLine.Type::"G/L Account",
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(100));  // Using Random value for Quantity and Direct Unit Cost.
        CreateAndPostPurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::"Credit Memo", VendorNo, GLAccount."No.", PurchaseLine.Type::"G/L Account",
          PurchaseLine.Quantity / PartialFactor, PurchaseLine."Direct Unit Cost");
    end;

    local procedure UpdateGenLedgerSetup(CurrencyCode: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Additional Reporting Currency" := CurrencyCode; // Validate is not required.
        GeneralLedgerSetup.Validate("Deposit Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        GeneralLedgerSetup.Validate("Bank Rec. Adj. Doc. Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure CallCheckPreview(var CheckPreview: TestPage "Check Preview"; GenJournalLine: Record "Gen. Journal Line")
    begin
        CheckPreview.OpenView();
        CheckPreview.FILTER.SetFilter("Journal Template Name", GenJournalLine."Journal Template Name");
        CheckPreview.FILTER.SetFilter("Journal Batch Name", GenJournalLine."Journal Batch Name");
        CheckPreview.FILTER.SetFilter("Line No.", Format(GenJournalLine."Line No."));
        CheckPreview.First();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GeneralJournalBatchesPageHandler(var GeneralJournalBatches: TestPage "General Journal Batches")
    begin
        GeneralJournalBatches.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GeneralJournalTemplateListPageHandler(var GeneralJournalTemplateList: TestPage "General Journal Template List")
    begin
        GeneralJournalTemplateList.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentRequestPageHandler(var SuggestVendorPayments: TestRequestPage "Suggest Vendor Payments")
    var
        BalAccountType: Enum "Gen. Journal Account Type";
        BankAccountNo: Variant;
        VendorNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(VendorNo);
        LibraryVariableStorage.Dequeue(BankAccountNo);
        SuggestVendorPayments.LastPaymentDate.SetValue(CalcDate(Format(LibraryRandom.RandInt(3)) + 'M', WorkDate()));  // 1 Using Random for No. of Months.
        SuggestVendorPayments.PostingDate.SetValue(WorkDate());
        SuggestVendorPayments.SummarizePerVendor.SetValue(true);
        SuggestVendorPayments.StartingDocumentNo.SetValue(LibraryRandom.RandInt(1000));
        SuggestVendorPayments.BalAccountType.SetValue(BalAccountType::"Bank Account");
        SuggestVendorPayments.BalAccountNo.SetValue(BankAccountNo);
        SuggestVendorPayments.Vendor.SetFilter("No.", VendorNo);
        SuggestVendorPayments.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure NothingAdjustedMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(NothingToAdjustTxt, Message);
    end;
}