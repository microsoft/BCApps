codeunit 141064 "ERM VAT Calc With Pmt Disc"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Payment Discount] [VAT]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvAndPmtVATTolerancePctMoreThanDiscPct()
    begin
        // [SCENARIO] Payment Discount when 'VAT Tolerance%' is greater than the Discount% of the Payment terms On the General Ledger Setup for Sales Invoice.
        PostSalesInvAndPmtWithVATTolerancePct(WorkDate(), true);  // Using WORKDATE for PostingDate and True For Open Entries.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvAndPmtWithPmtPostedAfterDiscountDate()
    begin
        // [SCENARIO] Payment Discount when 'VAT Tolerance%' is greater than the Discount% of the Payment terms On the General Ledger Setup and payment is made after the due date for Sales Invoice.
        PostSalesInvAndPmtWithVATTolerancePct(CalcDate('<CM + 1M>', WorkDate()), false);  // Using the PostingDate of next month and False For Open Entries.
    end;

    local procedure PostSalesInvAndPmtWithVATTolerancePct(PostingDate: Date; Open: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATAmountLine: Record "VAT Amount Line";
        DocumentNo: Code[20];
        DiscountPct: Decimal;
        RemainingAmount: Decimal;
        VATAmount: Decimal;
        VATBase: Decimal;
    begin
        // Setup: Create and post Sales Invoice and apply Payment to it.
        GeneralLedgerSetup.Get();
        UpdatePmtDiscExclVATOnGeneralLedgerSetup(true);  // Using TRUE for Pmt. Disc. Excl. VAT.
        DiscountPct := LibraryRandom.RandDec(10, 2);
        UpdateVATTolerancePctOnGeneralLedgerSetup(LibraryRandom.RandDecInRange(10, 100, 2));  // Using Random value for VATTolerancePct.
        CreateSalesInvoice(SalesLine, DiscountPct);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        RemainingAmount := (SalesHeader.Amount * DiscountPct) / 100;
        VATAmount :=
          (SalesLine."VAT %" * SalesLine."Line Amount" / 100) - DiscountPct / 100 * (SalesLine."VAT %" * SalesLine."Line Amount") / 100;
        VATBase := SalesLine."Line Amount" - DiscountPct / 100 * SalesLine."Line Amount";
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Ship and Invoice.
        GetSalesVATAmountLine(VATAmountLine, DocumentNo);

        // Exercise.
        CreateAndPostGenJournalLine(
          GenJournalLine, DocumentNo, PostingDate, GenJournalLine."Account Type"::Customer,
          SalesHeader."Sell-to Customer No.", -SalesLine."Amount Including VAT");

        // Verify.
        VerifySalesVATCalculationOnPmtDiscount(GenJournalLine, VATAmountLine, DocumentNo, Open, RemainingAmount, Round(VATAmount), VATBase);

        // Tear Down.
        UpdateVATTolerancePctOnGeneralLedgerSetup(GeneralLedgerSetup."VAT Tolerance %");
        UpdatePmtDiscExclVATOnGeneralLedgerSetup(GeneralLedgerSetup."Pmt. Disc. Excl. VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvAndPmtVATTolerancePctLessThanDiscPct()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATAmountLine: Record "VAT Amount Line";
        DocumentNo: Code[20];
        DiscountPct: Decimal;
        RemainingAmount: Decimal;
        VATAmount: Decimal;
        VATBase: Decimal;
        VATTolerancePct: Decimal;
    begin
        // [SCENARIO] Payment Discount when 'VAT Tolerance%' is less than the Discount% of the Payment terms On the General Ledger Setup for Sales Invoice.

        // Setup: Create and post Sales Invoice and apply Payment to it.
        GeneralLedgerSetup.Get();
        VATTolerancePct := LibraryRandom.RandDec(5, 2);
        DiscountPct := LibraryRandom.RandDecInRange(10, 100, 2);
        UpdatePmtDiscExclVATOnGeneralLedgerSetup(true);  // Using TRUE for Pmt. Disc. Excl. VAT.
        UpdateVATTolerancePctOnGeneralLedgerSetup(VATTolerancePct);
        CreateSalesInvoice(SalesLine, DiscountPct);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        RemainingAmount := (SalesHeader.Amount * DiscountPct) / 100;
        VATAmount :=
          (SalesLine."VAT %" * SalesLine."Line Amount" / 100) -
          VATTolerancePct / 100 * (SalesLine."VAT %" * SalesLine."Line Amount") / 100;
        VATBase := SalesLine."Line Amount" - VATTolerancePct / 100 * SalesLine."Line Amount";
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Ship and Invoice.
        GetSalesVATAmountLine(VATAmountLine, DocumentNo);

        // Exercise.
        CreateAndPostGenJournalLine(
          GenJournalLine, DocumentNo, WorkDate(), GenJournalLine."Account Type"::Customer,
          SalesHeader."Sell-to Customer No.", -SalesLine."Amount Including VAT");

        // Verify: Verify Payment is fully applied to Invoice.
        VerifySalesVATCalculationOnPmtDiscount(GenJournalLine, VATAmountLine, DocumentNo, true, RemainingAmount, Round(VATAmount), VATBase);  // Using True For Open Entries.

        // Tear Down.
        UpdateVATTolerancePctOnGeneralLedgerSetup(GeneralLedgerSetup."VAT Tolerance %");
        UpdatePmtDiscExclVATOnGeneralLedgerSetup(GeneralLedgerSetup."Pmt. Disc. Excl. VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvAndPmtWithZeroVATTolerancePct()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATAmountLine: Record "VAT Amount Line";
        DocumentNo: Code[20];
        DiscountPct: Decimal;
        RemainingAmount: Decimal;
        VATAmount: Decimal;
    begin
        // [SCENARIO] Payment Discount when 'VAT Tolerance%' is zero the Discount% of the Payment terms On the General Ledger Setup for Sales Invoice.

        // Setup: Create and post Sales Invoice and apply Payment to it.
        GeneralLedgerSetup.Get();
        UpdatePmtDiscExclVATOnGeneralLedgerSetup(false);  // Using False for Pmt. Disc. Excl. VAT.
        DiscountPct := LibraryRandom.RandDecInRange(10, 100, 2);
        CreateSalesInvoice(SalesLine, DiscountPct);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        RemainingAmount := (SalesHeader.Amount * DiscountPct) / 100;
        VATAmount := (SalesLine."VAT %" * SalesLine."Line Amount") / 100;
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Ship and Invoice.
        GetSalesVATAmountLine(VATAmountLine, DocumentNo);

        // Exercise.
        CreateAndPostGenJournalLine(
          GenJournalLine, DocumentNo, WorkDate(), GenJournalLine."Account Type"::Customer,
          SalesHeader."Sell-to Customer No.", -SalesLine."Amount Including VAT");

        // Verify: Verify Payment is fully applied to Invoice.
        VerifySalesVATCalculationOnPmtDiscount(
          GenJournalLine, VATAmountLine, DocumentNo, true, RemainingAmount, Round(VATAmount), SalesLine."Line Amount");  // Using True For Open Entries.

        // Tear Down.
        UpdatePmtDiscExclVATOnGeneralLedgerSetup(GeneralLedgerSetup."Pmt. Disc. Excl. VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchInvAndPmtVATTolerancePctMoreThanDiscPct()
    begin
        // [SCENARIO] Payment Discount when 'VAT Tolerance%' is greater than the Discount% of the Payment terms On the General Ledger Setup for Purchase Invoice.
        PostPurchInvAndPmtWithVATTolerancePct(WorkDate(), true);  // Using WORKDATE for PostingDate and True For Open Entries.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchInvAndPmtWithPmtPostedAfterDiscountDate()
    begin
        // [SCENARIO] Payment Discount when 'VAT Tolerance%' is greater than the Discount% of the Payment terms On the General Ledger Setup and payment is made after the due date for Purchase Invoice.
        PostPurchInvAndPmtWithVATTolerancePct(CalcDate('<CM + 1M>', WorkDate()), false);  // Using the PostingDate of next month and False For Open Entries.
    end;

    local procedure PostPurchInvAndPmtWithVATTolerancePct(PostingDate: Date; Open: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATAmountLine: Record "VAT Amount Line";
        DocumentNo: Code[20];
        DiscountPct: Decimal;
        RemainingAmount: Decimal;
        VATAmount: Decimal;
        VATBase: Decimal;
    begin
        // Setup: Create and post Purchase Invoice and apply Payment to it.
        GeneralLedgerSetup.Get();
        DiscountPct := LibraryRandom.RandDec(10, 2);
        UpdatePmtDiscExclVATOnGeneralLedgerSetup(true);  // Using TRUE for Pmt. Disc. Excl. VAT.
        UpdateVATTolerancePctOnGeneralLedgerSetup(LibraryRandom.RandDecInRange(10, 100, 2));  // Using Random Value for VATTolearncePct.
        CreatePurchaseInvoice(PurchaseLine, DiscountPct);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        RemainingAmount := (PurchaseHeader.Amount * DiscountPct) / 100;
        VATAmount :=
          (PurchaseLine."VAT %" * PurchaseLine."Line Amount" / 100) - DiscountPct /
          100 * (PurchaseLine."VAT %" * PurchaseLine."Line Amount") / 100;
        VATBase := PurchaseLine."Line Amount" - DiscountPct / 100 * PurchaseLine."Line Amount";
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Recieve and Invoice.
        GetPurchaseVATAmountLine(VATAmountLine, DocumentNo);

        // Exercise.
        CreateAndPostGenJournalLine(
          GenJournalLine, DocumentNo, PostingDate, GenJournalLine."Account Type"::Vendor,
          PurchaseHeader."Buy-from Vendor No.", PurchaseLine."Amount Including VAT");

        // Verify: Verify Payment is fully applied to Invoice.
        VerifyPurchaseVATCalculationOnPmtDiscount(GenJournalLine, VATAmountLine, DocumentNo, Open, RemainingAmount, VATAmount, VATBase);

        // Tear Down.
        UpdateVATTolerancePctOnGeneralLedgerSetup(GeneralLedgerSetup."VAT Tolerance %");
        UpdatePmtDiscExclVATOnGeneralLedgerSetup(GeneralLedgerSetup."Pmt. Disc. Excl. VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchInvAndPmtVATTolerancePctLessThanDiscPct()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATAmountLine: Record "VAT Amount Line";
        DocumentNo: Code[20];
        DiscountPct: Decimal;
        RemainingAmount: Decimal;
        VATAmount: Decimal;
        VATBase: Decimal;
        VATTolerancePct: Decimal;
    begin
        // [SCENARIO] Payment Discount when 'VAT Tolerance%' is less than the Discount% of the Payment terms On the General Ledger Setup for Purchase Invoice.

        // Setup: Create and post Purchase Invoice and apply Payment to it.
        GeneralLedgerSetup.Get();
        VATTolerancePct := LibraryRandom.RandDec(5, 2);
        DiscountPct := LibraryRandom.RandDecInRange(10, 100, 2);
        UpdatePmtDiscExclVATOnGeneralLedgerSetup(true);  // Using TRUE for Pmt. Disc. Excl. VAT.
        UpdateVATTolerancePctOnGeneralLedgerSetup(VATTolerancePct);
        CreatePurchaseInvoice(PurchaseLine, DiscountPct);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        RemainingAmount := (PurchaseHeader.Amount * DiscountPct) / 100;
        VATAmount :=
          (PurchaseLine."VAT %" * PurchaseLine."Line Amount" / 100) - VATTolerancePct / 100 *
          (PurchaseLine."VAT %" * PurchaseLine."Line Amount") / 100;
        VATBase := PurchaseLine."Line Amount" - VATTolerancePct / 100 * PurchaseLine."Line Amount";
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Recieve and Invoice.
        GetPurchaseVATAmountLine(VATAmountLine, DocumentNo);

        // Exercise.
        CreateAndPostGenJournalLine(
          GenJournalLine, DocumentNo, WorkDate(), GenJournalLine."Account Type"::Vendor,
          PurchaseHeader."Buy-from Vendor No.", PurchaseLine."Amount Including VAT");

        // Verify.
        VerifyPurchaseVATCalculationOnPmtDiscount(GenJournalLine, VATAmountLine, DocumentNo, true, RemainingAmount, VATAmount, VATBase);  // Using True For Open Entries.

        // Tear Down.
        UpdateVATTolerancePctOnGeneralLedgerSetup(GeneralLedgerSetup."VAT Tolerance %");
        UpdatePmtDiscExclVATOnGeneralLedgerSetup(GeneralLedgerSetup."Pmt. Disc. Excl. VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchInvAndPmtWithZeroVATTolerancePct()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATAmountLine: Record "VAT Amount Line";
        DocumentNo: Code[20];
        DiscountPct: Decimal;
        RemainingAmount: Decimal;
        VATAmount: Decimal;
    begin
        // [SCENARIO] Payment Discount when 'VAT Tolerance%' is zero the Discount% of the Payment terms On the General Ledger Setup for Purchase Invoice.

        // Setup: Create and post Purchase Invoice and apply Payment to it.
        GeneralLedgerSetup.Get();
        DiscountPct := LibraryRandom.RandDecInRange(10, 100, 2);
        UpdatePmtDiscExclVATOnGeneralLedgerSetup(false);  // Using False for Pmt. Disc. Excl. VAT.
        CreatePurchaseInvoice(PurchaseLine, DiscountPct);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        RemainingAmount := (PurchaseHeader.Amount * DiscountPct) / 100;
        VATAmount := (PurchaseLine."VAT %" * PurchaseLine."Line Amount") / 100;
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Recieve and Invoice.
        GetPurchaseVATAmountLine(VATAmountLine, DocumentNo);

        // Exercise.
        CreateAndPostGenJournalLine(
          GenJournalLine, DocumentNo, WorkDate(), GenJournalLine."Account Type"::Vendor,
          PurchaseHeader."Buy-from Vendor No.", PurchaseLine."Amount Including VAT");

        // Verify.
        VerifyPurchaseVATCalculationOnPmtDiscount(
          GenJournalLine, VATAmountLine, DocumentNo, true, RemainingAmount, VATAmount, PurchaseLine."Line Amount");  // Using True For Open Entries.

        // Tear Down.
        UpdatePmtDiscExclVATOnGeneralLedgerSetup(GeneralLedgerSetup."Pmt. Disc. Excl. VAT");
    end;

    local procedure CreateAndPostGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentNo: Code[20]; PostingDate: Date; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[10]; Amount: Decimal)
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
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", DocumentNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateCustomer(DiscountPct: Decimal): Code[20]
    var
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, false);  // Using False for CalcPmtDiscOnCrMemos.
        PaymentTerms.Validate("Discount %", DiscountPct);
        PaymentTerms.Modify(true);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreatePaymentJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreatePurchaseInvoice(var PurchaseLine: Record "Purchase Line"; DiscountPct: Decimal)
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor(DiscountPct));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));  // Using Random value for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesInvoice(var SalesLine: Record "Sales Line"; DiscountPct: Decimal)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer(DiscountPct));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));  // Using Random value for Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateVendor(DiscountPct: Decimal): Code[20]
    var
        Vendor: Record Vendor;
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, false);  // Using False for CalcPmtDiscOnCrMemos.
        PaymentTerms.Validate("Discount %", DiscountPct);
        PaymentTerms.Modify(true);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Terms Code", PaymentTerms.Code);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure GetPurchaseVATAmountLine(var VATAmountLine: Record "VAT Amount Line"; DocumentNo: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvHeader.Get(DocumentNo);
        PurchInvLine.CalcVATAmountLines(PurchInvHeader, VATAmountLine);
    end;

    local procedure GetSalesVATAmountLine(var VATAmountLine: Record "VAT Amount Line"; DocumentNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceHeader.Get(DocumentNo);
        SalesInvoiceLine.CalcVATAmountLines(SalesInvoiceHeader, VATAmountLine);
    end;

    local procedure UpdatePmtDiscExclVATOnGeneralLedgerSetup(PmtDiscExclVAT: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Pmt. Disc. Excl. VAT", PmtDiscExclVAT);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateVATTolerancePctOnGeneralLedgerSetup(VATTolerancePct: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("VAT Tolerance %", VATTolerancePct);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure VerifyCustLedgerEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; Open: Boolean; RemainingAmount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        CustLedgerEntry.TestField(Open, Open);
        CustLedgerEntry.TestField("Remaining Amount", RemainingAmount);
    end;

    local procedure VerifyVendorLedgerEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; Open: Boolean; RemainingAmount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, DocumentNo);
        VendorLedgerEntry.TestField(Open, Open);
        VendorLedgerEntry.TestField("Remaining Amount", RemainingAmount);
    end;

    local procedure VerifyPurchaseVATCalculationOnPmtDiscount(GenJournalLine: Record "Gen. Journal Line"; VATAmountLine: Record "VAT Amount Line"; DocumentNo: Code[20]; Open: Boolean; RemainingAmount: Decimal; VATAmount: Decimal; VATBase: Decimal)
    begin
        VerifyVendorLedgerEntry(GenJournalLine."Document Type"::Invoice, DocumentNo, false, 0);  // Using 0 For Remaining Amount and False for Open.
        VerifyVendorLedgerEntry(GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.", Open, RemainingAmount);
        VATAmountLine.TestField("VAT Base", VATBase);
        VATAmountLine.TestField("VAT Amount", Round(VATAmount));
    end;

    local procedure VerifySalesVATCalculationOnPmtDiscount(GenJournalLine: Record "Gen. Journal Line"; VATAmountLine: Record "VAT Amount Line"; DocumentNo: Code[20]; Open: Boolean; RemainingAmount: Decimal; VATAmount: Decimal; VATBase: Decimal)
    begin
        VerifyCustLedgerEntry(GenJournalLine."Document Type"::Invoice, DocumentNo, false, 0);  // Using 0 For Remaining Amount and False for Open.
        VerifyCustLedgerEntry(GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.", Open, RemainingAmount);
        VATAmountLine.TestField("VAT Base", VATBase);
        VATAmountLine.TestField("VAT Amount", VATAmount);
    end;
}

