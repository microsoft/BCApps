codeunit 141057 "ERM Prepayment APAC"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Prepayment]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        AmountMustBeEqual: Label 'Amount must be equal.';

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesPrepaymentInvoiceWithDiffPrepaymentPct()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
    begin
        // [SCENARIO] GL Entry,VAT Entry,GST Sales Entry and Posted Invoice after posting Sales prepayment wiht discount and different Prepayment %.

        // [GIVEN] Create Sales Order, Reopen and Change Prepayment %.
        Initialize();
        CreateSalesOrder(SalesLine, CreateCustomerWithInvoiceDiscount());
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        DocumentNo := GetPostedDocumentNo(SalesHeader."Posting No. Series");
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        LibrarySales.ReopenSalesDocument(SalesHeader);
        ModifyPrepaymentPctOnSalesHeader(SalesHeader, 100);  // 100 is required prepayment in test case.
        DocumentNo2 := GetPostedDocumentNo(SalesHeader."Posting No. Series");

        // Exercise.
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // Verify.
        VerifyGLEntry(
          DocumentNo2, -(SalesLine.Amount - ((SalesLine.Amount * SalesLine."Prepayment %") / 100)));
        VerifyVATEntry(DocumentNo, -(SalesLine."Amount Including VAT" - SalesLine.Amount));
        VerifyGSTSalesEntry(DocumentNo, -(SalesLine."Amount Including VAT" - SalesLine.Amount));
        VerifyPostedSalesInvoice(DocumentNo2, (SalesLine.Amount - ((SalesLine.Amount * SalesLine."Prepayment %") / 100)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntryAfterPostingSalesPrepaymentCreditMemo()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
    begin
        // [SCENARIO] Sales credit memo after posting Sales Invoice prepayment and Credit Memo prepayment.

        // [GIVEN] Create Sales Order and Post prepayment.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateSalesOrder(SalesLine, Customer."No.");
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // Exercise.
        SalesPostPrepayments.CreditMemo(SalesHeader);

        // Verify.
        SalesCrMemoHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesCrMemoHeader.FindFirst();
        SalesCrMemoHeader.CalcFields(Amount);
        VerifyGLEntry(SalesCrMemoHeader."No.", SalesCrMemoHeader.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchPrepaymentOrderWithDiffPrepaymentPct()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
        Amount: Decimal;
    begin
        // [SCENARIO] GL Entry,VAT Entry,GST Sales Entry and Posted Invoice after posting Purchase prepayment with different Prepayment %.

        // [GIVEN] Create Purchase order, Modify Percentage and Post Prepayment.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        ModifyPrepaymentPctOnPurchaseHeader(PurchaseHeader, LibraryRandom.RandDec(10, 2));  // Random for Prepayment %.
        CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));  // Random for Quantity.
        Amount := (PurchaseLine.Amount * PurchaseLine."Prepayment %") / 100;
        DocumentNo := GetPostedDocumentNo(PurchaseHeader."Posting No. Series");
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        UpdateVendorInvoiceNoOnPurchaseHeader(PurchaseHeader);
        ModifyPrepaymentPctOnPurchaseLine(PurchaseLine);

        // Exercise.
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // Verify.
        VerifyGLEntry(DocumentNo, Amount);
        VerifyVATEntry(DocumentNo, (PurchaseLine."Amount Including VAT" - PurchaseLine.Amount));
        VerifyGSTPurchaseEntry(DocumentNo, (PurchaseLine."Amount Including VAT" - PurchaseLine.Amount));
        PurchInvHeader.SetRange("No.", DocumentNo);
        PurchInvHeader.FindFirst();
        PurchInvHeader.CalcFields(Amount);
        Assert.AreNearlyEqual(Amount, PurchInvHeader.Amount, LibraryERM.GetAmountRoundingPrecision(), AmountMustBeEqual);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderWithNegativeLineTypeGL()
    var
        GLEntry: Record "G/L Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
        GLAccountNo: Code[20];
        Amount: Decimal;
    begin
        // [SCENARIO] GL Entry after posting purchase order with multiple purchase line.

        // Setup.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        GLAccountNo := CreateGLAccount();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccountNo, LibraryRandom.RandDec(10, 2));  // Random for Quantity.
        CreatePurchaseLine(
          PurchaseLine2, PurchaseHeader, PurchaseLine2.Type::"G/L Account", GLAccountNo, -LibraryRandom.RandDec(10, 2));  // Random for Quantity.
        PurchaseLine2.Validate("Qty. to Receive", 0);
        PurchaseLine2.Modify(true);
        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // True for receive and invoice.

        // Verify.
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindSet();
        repeat
            Amount += GLEntry."Credit Amount";
        until GLEntry.Next() = 0;
        Assert.AreNearlyEqual(Amount, PurchaseLine."Amount Including VAT", LibraryERM.GetAmountRoundingPrecision(), AmountMustBeEqual);
        Assert.AreNearlyEqual(
          -Amount, PurchaseLine2."Amount Including VAT" - (PurchaseLine."Amount Including VAT" + PurchaseLine2."Amount Including VAT"),
          LibraryERM.GetAmountRoundingPrecision(), AmountMustBeEqual);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesPrepmtInvWithDiffPrepmtPctWithGenJnlLine()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
    begin
        // [SCENARIO] GL Entry,VAT Entry,GST Sales Entry and Posted Invoice after posting Sales prepayment with different Prepayment % and General Journal Line.

        // Setup.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateSalesOrder(SalesLine, Customer."No.");
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        DocumentNo := GetPostedDocumentNo(SalesHeader."Posting No. Series");
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        LibrarySales.ReopenSalesDocument(SalesHeader);
        ModifyPrepaymentPctOnSalesHeader(SalesHeader, 100);  // 100 is required prepayment in test case.
        DocumentNo2 := GetPostedDocumentNo(SalesHeader."Posting No. Series");
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // Exercise.
        CreateAndPostGeneralJournalLine(
          GenJournalLine, SalesHeader."Sell-to Customer No.", -SalesLine.Amount - ((SalesLine.Amount * SalesLine."Prepayment %") / 100));

        // Verify.
        VerifyGLEntry(
          DocumentNo2, -(SalesLine.Amount - ((SalesLine.Amount * SalesLine."Prepayment %") / 100)));
        VerifyVATEntry(DocumentNo, -(SalesLine."Amount Including VAT" - SalesLine.Amount));
        VerifyGSTSalesEntry(DocumentNo, -(SalesLine."Amount Including VAT" - SalesLine.Amount));
        VerifyPostedSalesInvoice(DocumentNo2, (SalesLine.Amount - ((SalesLine.Amount * SalesLine."Prepayment %") / 100)));
    end;

    local procedure Initialize()
    begin
        UpdateGeneralLedgerSetup();
    end;

    local procedure CreateAndPostGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, AccountNo, Amount);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", CreateGLAccount());
        GenJournalLine.Validate("Bal. Gen. Posting Type", GenJournalLine."Bal. Gen. Posting Type"::Sale);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateCustomerWithInvoiceDiscount(): Code[20]
    var
        Customer: Record Customer;
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, Customer."No.", '', LibraryRandom.RandDec(10, 2));  // Using blank for currency and random for discount.
        exit(Customer."No.");
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Type: Enum "Purchase Line Type"; No: Code[20]; Quantity: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesLine: Record "Sales Line"; CustomerNo: Code[20])
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
    begin
        Customer.Get(CustomerNo);
        LibraryInventory.CreateItem(Item);
        UpdatePrepmtAccInGeneralPostingSetup(Customer."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group");
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        ModifyPrepaymentPctOnSalesHeader(SalesHeader, LibraryRandom.RandDec(10, 2));  // Random for Prepayment %.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));  // Random for Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure GetPostedDocumentNo(NoSeries: Code[20]): Code[20]
    var
        NoSeriesCodeunit: Codeunit "No. Series";
    begin
        exit(NoSeriesCodeunit.PeekNextNo(NoSeries));
    end;

    local procedure ModifyPrepaymentPctOnPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; PrepaymentPct: Decimal)
    begin
        PurchaseHeader.Validate("Prepayment %", PrepaymentPct);
        PurchaseHeader.Modify(true);
    end;

    local procedure ModifyPrepaymentPctOnPurchaseLine(var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.Validate("Prepayment %", 100);  // 100 is required prepayment in test case.
        PurchaseLine.Modify(true);
    end;

    local procedure ModifyPrepaymentPctOnSalesHeader(var SalesHeader: Record "Sales Header"; PrepaymentPct: Decimal)
    begin
        SalesHeader.Validate("Prepayment %", PrepaymentPct);
        SalesHeader.Modify(true);
    end;

    local procedure UpdateGeneralLedgerSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Enable GST (Australia)", true);
        GeneralLedgerSetup.Validate("Adjustment Mandatory", true);
        GeneralLedgerSetup.Validate("GST Report", true);
        GeneralLedgerSetup.Validate("Full GST on Prepayment", true);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdatePrepmtAccInGeneralPostingSetup(GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup);
        GeneralPostingSetup."Sales Prepayments Account" := CreateGLAccount();
        GeneralPostingSetup."Purch. Prepayments Account" := CreateGLAccount();
        GeneralPostingSetup.Modify(true);
    end;

    local procedure UpdateVendorInvoiceNoOnPurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(Amount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), AmountMustBeEqual);
    end;

    local procedure VerifyGSTPurchaseEntry(DocumentNo: Code[20]; Amount: Decimal)
    var
        GSTPurchaseEntry: Record "GST Purchase Entry";
    begin
        GSTPurchaseEntry.SetRange("Document No.", DocumentNo);
        GSTPurchaseEntry.FindFirst();
        Assert.AreNearlyEqual(Amount, GSTPurchaseEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), AmountMustBeEqual);
    end;

    local procedure VerifyGSTSalesEntry(DocumentNo: Code[20]; Amount: Decimal)
    var
        GSTSalesEntry: Record "GST Sales Entry";
    begin
        GSTSalesEntry.SetRange("Document No.", DocumentNo);
        GSTSalesEntry.FindFirst();
        Assert.AreNearlyEqual(Amount, GSTSalesEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), AmountMustBeEqual);
    end;

    local procedure VerifyPostedSalesInvoice(No: Code[20]; Amount: Decimal)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetRange("No.", No);
        SalesInvoiceHeader.FindFirst();
        SalesInvoiceHeader.CalcFields(Amount);
        Assert.AreNearlyEqual(Amount, SalesInvoiceHeader.Amount, LibraryERM.GetAmountRoundingPrecision(), AmountMustBeEqual);
    end;

    local procedure VerifyVATEntry(DocumentNo: Code[20]; Amount: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
        Assert.AreNearlyEqual(Amount, VATEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), AmountMustBeEqual);
    end;
}

