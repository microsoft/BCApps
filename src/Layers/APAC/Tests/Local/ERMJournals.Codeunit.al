codeunit 141081 "ERM Journals"
{
    // 1. Test to verify Payment Journal is posted successfully using Apply Entries functionality.
    // 2. Test to verify error on entering value in Customer/Vendor Bank field of Gen. Journal Line which is not defined in Customer Bank Account List.
    // 3. Test to verify error on entering value in Customer/Vendor Bank field of Gen. Journal Line which is not defined in Vendor Bank Account List.
    // 4. Test to verify GST Purchase Entry created when Payment Journal is posted successfully using Apply Entries functionality with Payment Discount.
    // 5. Test to verify GST Sales Entry created when Payment Journal is posted successfully using Apply Entries functionality with Payment Discount.
    // 
    // Covers Test Cases for WI - 350167
    // ---------------------------------------------------------------------------------------
    // Test Function Name                                                               TFS ID
    // ---------------------------------------------------------------------------------------
    // PostPaymentJournalWithAppliedEntry                                               237143
    // CustomerBankCodeOnGenJournalLineError,VendorBankCodeOnGenJournalLineError        203833
    // 
    // Covers Test Cases for Bug Id - 72999
    // ---------------------------------------------------------------------------------------
    // Test Function Name                                                               TFS ID
    // ---------------------------------------------------------------------------------------
    // GSTPurchaseEntryAfterApplingInvoiceToPayment,GSTSalesEntryAfterApplingInvoiceToPayment

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Journal]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        CustomerVendorBankCodeErr: Label 'The field Customer/Vendor Bank of table Gen. Journal Line contains a value (%1)';
        AmountErr: Label 'Amount %1 must be equal to %2.';

    [Test]
    [HandlerFunctions('ApplyVendorEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostPaymentJournalWithAppliedEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Apply Entries]
        // [SCENARIO] Payment Journal is posted successfully using Apply Entries functionality.

        // [GIVEN] Post Purchase Invoice and apply Payment.
        DocumentNo := CreateAndPostPurchaseInvoice();
        PurchInvHeader.Get(DocumentNo);
        PurchInvHeader.CalcFields("Amount Including VAT");
        CreateGenJournalLine(
          GenJournalLine, PurchInvHeader."Buy-from Vendor No.", '', GenJournalLine."Account Type"::Vendor,
          PurchInvHeader."Amount Including VAT");  // Using blank value for Customer/Vendor Bank.
        OpenPaymentJournalPageAndApplyPaymentToInvoice(GenJournalLine."Journal Batch Name");

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Payment is fully applied to Invoice.
        VerifyVendorLedgerEntry(DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerBankCodeOnGenJournalLineError()
    var
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        CustomerVendorBankCode: Code[20];
    begin
        // [FEATURE] [Customer/Vendor Bank] [Sales]
        // [SCENARIO] Error on entering value in Customer/Vendor Bank field of Gen. Journal Line which is not defined in Customer Bank Account List.

        // [GIVEN] Create Customer, Customer Bank Account, General Journal Line and random code for Customer/Vendor Bank.
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");
        CreateGenJournalLine(
          GenJournalLine, Customer."No.", CustomerBankAccount.Code, GenJournalLine."Account Type"::Customer, 0);  // Using 0 for Amount.
        CustomerVendorBankCode := LibraryUtility.GenerateGUID();

        // Exercise.
        asserterror GenJournalLine.Validate("Customer/Vendor Bank", CustomerVendorBankCode);

        // Verify.
        Assert.ExpectedError(StrSubstNo(CustomerVendorBankCodeErr, CustomerVendorBankCode));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorBankCodeOnGenJournalLineError()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        CustomerVendorBankCode: Code[20];
    begin
        // [FEATURE] [Customer/Vendor Bank] [Purchase]
        // [SCENARIO] Error on entering value in Customer/Vendor Bank field of Gen. Journal Line which is not defined in Vendor Bank Account List.

        // [GIVEN] Create Vendor, Vendor Bank Account, General Journal Line and random code for Customer/Vendor Bank.
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        CreateGenJournalLine(
          GenJournalLine, Vendor."No.", VendorBankAccount.Code, GenJournalLine."Account Type"::Vendor, 0);  // Using 0 for Amount.
        CustomerVendorBankCode := LibraryUtility.GenerateGUID();

        // Exercise.
        asserterror GenJournalLine.Validate("Customer/Vendor Bank", CustomerVendorBankCode);

        // Verify.
        Assert.ExpectedError(StrSubstNo(CustomerVendorBankCodeErr, CustomerVendorBankCode));
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure GSTPurchaseEntryAfterApplingInvoiceToPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [GST] [Purchase] [Payment Discount]
        // [SCENARIO 313783] GST Purchase Entry is matching to VAT Entry when Payment is applied to Purchase Invoice with Payment Discount

        // [GIVEN] Purchase Invoice of Amount = 1000 with Payment Discount Possible = 100 and VAT % = 10
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(true, true, true);
        UpdateGeneralPostingSetup();
        CreateAndPostPurchaseOrder(PurchaseHeader);

        // [GIVEN] Payment for the invoice within Payment Discount Date
        CreateAndUpdateGenJournalLine(
          GenJournalLine, PurchaseHeader."Buy-from Vendor No.", GenJournalLine."Account Type"::Vendor, PurchaseHeader."Pmt. Discount Date");
        OpenPaymentJournalPageAndApplyPaymentToInvoice(GenJournalLine."Journal Batch Name");

        // [WHEN] Apply payment to the invoice
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] GST Purchase Entry has Amount = 10 (100 * 10%)
        FindVATEntry(VATEntry, VATEntry."Document Type"::Payment, GenJournalLine."Document No.");
        VerifyGSTPurchaseEntry(GenJournalLine."Document No.", VATEntry.Amount);

        // Tear Down.
        UpdateVATPostingSetup();
        UpdateGeneralLedgerSetup(GeneralLedgerSetup."Adjust for Payment Disc.",
          GeneralLedgerSetup."GST Report", GeneralLedgerSetup."Enable GST (Australia)");
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure GSTSalesEntryAfterApplingInvoiceToPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        ReasonCode: Record "Reason Code";
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [GST] [Sales] [Payment Discount]
        // [SCENARIO 313783] GST Sales Entry is matching to VAT Entry when Payment is applied to Sales Invoice with Payment Discount

        // [GIVEN] Sales Invoice of Amount = 1000 with Payment Discount Possible = 100 and VAT % = 10
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(true, true, true);
        UpdateGeneralPostingSetup();
        SalesReceivablesSetup.Get();
        LibraryERM.CreateReasonCode(ReasonCode);
        UpdateSalesReceivableSetup(ReasonCode.Code);

        // [GIVEN] Payment for the invoice within Payment Discount Date
        CreateAndPostSalesOrder(SalesHeader);
        CreateAndUpdateGenJournalLine(
          GenJournalLine, SalesHeader."Sell-to Customer No.", GenJournalLine."Account Type"::Customer, SalesHeader."Pmt. Discount Date");
        OpenPaymentJournalPageAndApplyPaymentToInvoice(GenJournalLine."Journal Batch Name");

        // [WHEN] Apply payment to the invoice
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        FindVATEntry(VATEntry, VATEntry."Document Type"::Payment, GenJournalLine."Document No.");

        // [THEN] GST Sales Entry has Amount = 10 (100 * 10%)
        VerifyGSTSalesEntry(GenJournalLine."Document No.", VATEntry.Amount);

        // Tear Down.
        UpdateVATPostingSetup();
        UpdateSalesReceivableSetup(SalesReceivablesSetup."Payment Discount Reason Code");
        UpdateGeneralLedgerSetup(GeneralLedgerSetup."Adjust for Payment Disc.",
          GeneralLedgerSetup."GST Report", GeneralLedgerSetup."Enable GST (Australia)");
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostPaymentJournalWithAppliedEntryTwoVendors()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        PurchInvHeader: Record "Purch. Inv. Header";
        DocumentNo: array[2] of Code[20];
    begin
        // [FEATURE] [Purchase] [Apply Entries]
        // [SCENARIO] Payment Journal is posted successfully using Apply Entries functionality with different Vendors but one GenJournalLine."Document No."

        // [GIVEN] Two posted purchase invoices with Vendors: V1, V2
        DocumentNo[1] := CreateAndPostPurchaseInvoice();
        DocumentNo[2] := CreateAndPostPurchaseInvoice();
        // [GIVEN] GL Setup has "Enable WHT" = TRUE
        UpdateGLSetupWHT(true);
        // [GIVEN] GenJournalBatch
        CreatePaymentJournalBatch(GenJournalBatch);
        // [GIVEN] GenJournalLine for V1 with "Document No." = N
        PurchInvHeader.Get(DocumentNo[1]);
        PurchInvHeader.CalcFields("Amount Including VAT");
        CreateGenJournalLineWithJournalBatch(
          GenJournalLine, GenJournalBatch, PurchInvHeader."Buy-from Vendor No.", '', GenJournalLine."Account Type"::Vendor,
          PurchInvHeader."Amount Including VAT", '');
        // [GIVEN] GenJournalLine for V2 with "Document No." = N
        PurchInvHeader.Get(DocumentNo[2]);
        PurchInvHeader.CalcFields("Amount Including VAT");
        CreateGenJournalLineWithJournalBatch(
          GenJournalLine, GenJournalBatch, PurchInvHeader."Buy-from Vendor No.", '', GenJournalLine."Account Type"::Vendor,
          PurchInvHeader."Amount Including VAT", GenJournalLine."Document No.");

        // [WHEN] Apply payments and Post GenJournalBatch
        OpenPaymentJournalPageAndApplyPaymentToInvoiceOnEntries(GenJournalLine."Journal Batch Name");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Payment is fully applied to Invoice.
        VerifyVendorLedgerEntry(DocumentNo[1]);
        VerifyVendorLedgerEntry(DocumentNo[2]);

        UpdateGLSetupWHT(false);
    end;

    local procedure CreateAndPostPurchaseInvoice(): Code[20]
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));  // Using random value for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));  // Post as Receive and Invoice.
    end;

    local procedure CreateAndUpdateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; AccountType: Enum "Gen. Journal Account Type"; PostingDate: Date)
    begin
        CreateGenJournalLine(GenJournalLine, AccountNo, '', AccountType, 0);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateCustomerWithPaymentTerms(GenBusPostingGroup: Code[20]; VATBusPostingGroup: Code[20]): Code[20]
    var
        PaymentTerms: Record "Payment Terms";
        Customer: Record Customer;
    begin
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; CustomerVendorBankCode: Code[20]; AccountType: Enum "Gen. Journal Account Type"; Amount: Decimal)
    var
        BankAccount: Record "Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        CreatePaymentJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Customer/Vendor Bank", CustomerVendorBankCode);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateAndPostPurchaseOrder(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("Adjust for Payment Discount", true);
        VATPostingSetup.Modify(true);
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
          CreateVendorWithPaymentTerms(GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group"));
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
            CreateItem(GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group"),
            LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateAndPostSalesOrder(var SalesHeader: Record "Sales Header")
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesLine: Record "Sales Line";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("Adjust for Payment Discount", true);
        VATPostingSetup.Modify(true);
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order,
          CreateCustomerWithPaymentTerms(GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group"));
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader,
            SalesLine.Type::Item, CreateItem(GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group"),
            LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateItem(GenProdPostingGroup: Code[20]; VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePaymentJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateVendorWithPaymentTerms(GenBusPostingGroup: Code[20]; VATBusPostingGroup: Code[20]): Code[20]
    var
        PaymentTerms: Record "Payment Terms";
        Vendor: Record Vendor;
    begin
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Terms Code", PaymentTerms.Code);
        Vendor.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateGenJournalLineWithJournalBatch(var GenJournalLine: Record "Gen. Journal Line"; var GenJournalBatch: Record "Gen. Journal Batch"; AccountNo: Code[20]; CustomerVendorBankCode: Code[20]; AccountType: Enum "Gen. Journal Account Type"; Amount: Decimal; DocumentNo: Code[20])
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Customer/Vendor Bank", CustomerVendorBankCode);
        GenJournalLine.Validate("Skip WHT", false);
        if DocumentNo <> '' then
            GenJournalLine.Validate("Document No.", DocumentNo);
        GenJournalLine.Modify(true);
    end;

    local procedure OpenPaymentJournalPageAndApplyPaymentToInvoice(CurrentJnlBatchName: Code[10])
    var
        PaymentJournal: TestPage "Payment Journal";
    begin
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(CurrentJnlBatchName);
        PaymentJournal.ApplyEntries.Invoke();  // Opens ApplyVendorEntriesPageHandler and ApplyCustomerEntriesPageHandler.
        PaymentJournal.OK().Invoke();
    end;

    local procedure OpenPaymentJournalPageAndApplyPaymentToInvoiceOnEntries(CurrentJnlBatchName: Code[10])
    var
        PaymentJournal: TestPage "Payment Journal";
    begin
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(CurrentJnlBatchName);
        PaymentJournal.ApplyEntries.Invoke();
        PaymentJournal.Next();
        PaymentJournal.ApplyEntries.Invoke();
        PaymentJournal.OK().Invoke();
    end;

    local procedure UpdateGeneralPostingSetup()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.CreateGLAccount(GLAccount);
        GeneralPostingSetup.Validate("Sales Pmt. Disc. Credit Acc.", GLAccount."No.");
        GeneralPostingSetup.Validate("Sales Pmt. Disc. Debit Acc.", GLAccount."No.");
        GeneralPostingSetup.Validate("Purch. Pmt. Disc. Debit Acc.", GLAccount."No.");
        GeneralPostingSetup.Validate("Purch. Pmt. Disc. Credit Acc.", GLAccount."No.");
        GeneralPostingSetup.Modify(true);
    end;

    local procedure UpdateGeneralLedgerSetup(AdjustForPaymentDisc: Boolean; GSTReport: Boolean; EnableGST: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Adjust for Payment Disc.", AdjustForPaymentDisc);
        GeneralLedgerSetup.Validate("GST Report", GSTReport);
        GeneralLedgerSetup.Validate("Enable GST (Australia)", EnableGST);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateVATPostingSetup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("Adjust for Payment Discount", false);
        VATPostingSetup.Modify(true);
    end;

    local procedure UpdateSalesReceivableSetup(ReasonCode: Code[10])
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Payment Discount Reason Code", ReasonCode);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateGLSetupWHT(EnableWHT: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Enable WHT", EnableWHT);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure VerifyGSTPurchaseEntry(DocumentNo: Code[20]; GSTAmount: Decimal)
    var
        GSTPurchaseEntry: Record "GST Purchase Entry";
    begin
        GSTPurchaseEntry.SetRange("Document No.", DocumentNo);
        GSTPurchaseEntry.FindFirst();
        Assert.AreEqual(GSTAmount, GSTPurchaseEntry.Amount, StrSubstNo(AmountErr, GSTAmount, GSTPurchaseEntry.Amount));
    end;

    local procedure VerifyGSTSalesEntry(DocumentNo: Code[20]; GSTAmount: Decimal)
    var
        GSTSalesEntry: Record "GST Sales Entry";
    begin
        GSTSalesEntry.SetRange("Document No.", DocumentNo);
        GSTSalesEntry.FindFirst();
        Assert.AreEqual(GSTAmount, GSTSalesEntry.Amount, StrSubstNo(AmountErr, GSTAmount, GSTSalesEntry.Amount));
    end;

    local procedure VerifyVendorLedgerEntry(DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, DocumentNo);
        VendorLedgerEntry.TestField(Open, false);
        VendorLedgerEntry.TestField("Remaining Amount", 0);
    end;

    local procedure FindVATEntry(var VATEntry: Record "VAT Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        VATEntry.SetRange("Document Type", DocumentType);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesModalPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        ApplyVendorEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesModalPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        ApplyCustomerEntries.OK().Invoke();
    end;
}

