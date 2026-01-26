codeunit 144162 "ERM Debit Credit"
{
    //  1. Test to verify Debit and Credit Amounts are equivalent on G/L entries and G/L Book entries after posting Cash Receipt Journal.
    //  2. Test to verify Credit Amount gets updated on entering negative Amount on Cash Receipt Journal.
    //  3. Test to verify Debit Amount gets updated on entering positive Amount on Cash Receipt Journal.
    //  4. Test to verify positive Amount gets updated on entering positive Debit Amount on Cash Receipt Journal.
    //  5. Test to verify negative Amount gets updated on entering negative Debit Amount on Cash Receipt Journal.
    //  6. Test to verify negative Amount gets updated on entering positive Credit Amount on Cash Receipt Journal.
    //  7. Test to verify positive Amount gets updated on entering negative Credit Amount on Cash Receipt Journal.
    //  8. Test to verify Debit and Credit Amounts are equivalent on G/L entries and G/L Book entries after posting Payment Journal.
    //  9. Test to verify Credit Amount gets updated on entering negative Amount on Payment Journal.
    // 10. Test to verify Debit Amount gets updated on entering positive Amount on Payment Journal.
    // 11. Test to verify positive Amount gets updated on entering positive Debit Amount on Payment Journal.
    // 12. Test to verify negative Amount gets updated on entering negative Debit Amount on Payment Journal.
    // 13. Test to verify negative Amount gets updated on entering positive Credit Amount on Payment Journal.
    // 14. Test to verify positive Amount gets updated on entering negative Credit Amount on Payment Journal.
    // 
    // Covers Test Cases for WI - 345857
    // ----------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                 TFS ID
    // ----------------------------------------------------------------------------------------------------------------
    // PostPaymentAppliedToInvoiceOnCashReceiptJnl                                                        151452,151451
    // CreditAmtOnCashReceiptJnlWithNegativeAmt,DebitAmtOnCashReceiptJnlWithPositiveAmt                   151454
    // PositiveAmtOnCashReceiptJnlWithPositiveDebitAmt,NegativeAmtOnCashReceiptJnlWithNegativeDebitAmt    151454
    // NegativeAmtOnCashReceiptJnlWithPositiveCreditAmt,PositiveAmtOnCashReceiptJnlWithNegativeCreditAmt  151454
    // PostPaymentAppliedToInvoiceOnPaymentJnl                                                            151449,151455
    // CreditAmtOnPaymentJnlWithNegativeAmt,DebitAmtOnPaymentJnlWithPositiveAmt                           151457
    // PositiveAmtOnPaymentJnlWithPositiveDebitAmt,NegativeAmtOnPaymentJnlWithNegativeDebitAmt            151457
    // NegativeAmtOnPaymentJnlWithPositiveCreditAmt,PositiveAmtOnPaymentJnlWithNegativeCreditAmt          151457

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [Scope('OnPrem')]
    procedure PostPaymentAppliedToInvoiceOnCashReceiptJnl()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
        SalesLine: Record "Sales Line";
        AppliesToDocNo: Code[20];
    begin
        // Test to verify Debit and Credit Amounts are equivalent on G/L entries and G/L Book entries after posting Cash Receipt Journal.

        // Setup: Create and Post Sales Invoice and create Cash Receipt Journal.
        AppliesToDocNo := CreateAndPostSalesInvoice(SalesLine);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalTemplate.Type::"Cash Receipts", GenJournalLine."Account Type"::Customer,
          SalesLine."Sell-to Customer No.", -SalesLine."Amount Including VAT", CreateGLAccount(GLAccount."Gen. Posting Type"::Sale),
          AppliesToDocNo);

        // Exercise: Post Cash Receipt Journal.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: G/L entries and G/L Book entries.
        VerifyGLEntries(GenJournalLine."Document No.", SalesLine."Amount Including VAT");
        VerifyGLBookEntries(GenJournalLine."Document No.", SalesLine."Amount Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreditAmtOnCashReceiptJnlWithNegativeAmt()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // Test to verify Credit Amount gets updated on entering negative Amount on Cash Receipt Journal.

        // Exercise: Create Cash Receipt Journal line.
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalTemplate.Type::"Cash Receipts", GenJournalLine."Account Type"::Customer, CreateCustomer(),
          -LibraryRandom.RandDec(100, 2), '', '');  // Use Random value for Amount. Use Blank for Bal. Account No. and Applies To Doc. No.

        // Verify: Credit Amount gets updated on Cash Receipt Journal line.
        GenJournalLine.TestField("Credit Amount", Abs(GenJournalLine.Amount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DebitAmtOnCashReceiptJnlWithPositiveAmt()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // Test to verify Debit Amount gets updated on entering positive Amount on Cash Receipt Journal.

        // Exercise: Create Cash Receipt Journal line.
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalTemplate.Type::"Cash Receipts", GenJournalLine."Account Type"::Customer, CreateCustomer(),
          LibraryRandom.RandDec(100, 2), '', '');  // Use Random value for Amount. Use Blank for Bal. Account No. and Applies To Doc. No.

        // Verify: Debit Amount gets updated on Cash Receipt Journal line.
        GenJournalLine.TestField("Debit Amount", Abs(GenJournalLine.Amount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PositiveAmtOnCashReceiptJnlWithPositiveDebitAmt()
    begin
        // Test to verify positive Amount gets updated on entering positive Debit Amount on Cash Receipt Journal.
        AmountOnCashReceiptJournalWithDebitAmount(LibraryRandom.RandDec(100, 2));  // Use Random value for Debit Amount
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NegativeAmtOnCashReceiptJnlWithNegativeDebitAmt()
    begin
        // Test to verify negative Amount gets updated on entering negative Debit Amount on Cash Receipt Journal.
        AmountOnCashReceiptJournalWithDebitAmount(-LibraryRandom.RandDec(100, 2));  // Use Random value for Debit Amount
    end;

    local procedure AmountOnCashReceiptJournalWithDebitAmount(DebitAmount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // Setup: Create Cash Receipt Journal line.
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalTemplate.Type::"Cash Receipts", GenJournalLine."Account Type"::Customer, CreateCustomer(), 0, '', '');  // Value Zero required for Amount. Use Blank for Bal. Account No. and Applies To Doc. No.

        // Exercise: Update Debit Amount on Cash Receipt Journal line.
        UpdateDebitAmountOnGenJournalLine(GenJournalLine, DebitAmount);

        // Verify: Negative Amount gets updated on Cash Receipt Journal line.
        GenJournalLine.TestField(Amount, GenJournalLine."Debit Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NegativeAmtOnCashReceiptJnlWithPositiveCreditAmt()
    begin
        // Test to verify negative Amount gets updated on entering positive Credit Amount on Cash Receipt Journal.
        AmountOnCashReceiptJournalWithCreditAmount(LibraryRandom.RandDec(100, 2));  // Use Random value for Credit Amount
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PositiveAmtOnCashReceiptJnlWithNegativeCreditAmt()
    begin
        // Test to verify positive Amount gets updated on entering negative Credit Amount on Cash Receipt Journal.
        AmountOnCashReceiptJournalWithCreditAmount(-LibraryRandom.RandDec(100, 2));  // Use Random value for Credit Amount
    end;

    local procedure AmountOnCashReceiptJournalWithCreditAmount(CreditAmount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // Setup: Create Cash Receipt Journal line.
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalTemplate.Type::"Cash Receipts", GenJournalLine."Account Type"::Customer, CreateCustomer(), 0, '', '');  // Value Zero required for Amount. Use Blank for Bal. Account No. and Applies To Doc. No.

        // Exercise: Update Credit Amount on Cash Receipt Journal line.
        UpdateCreditAmountOnGenJournalLine(GenJournalLine, CreditAmount);

        // Verify: Positive Amount gets updated on Cash Receipt Journal line.
        GenJournalLine.TestField(Amount, -GenJournalLine."Credit Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPaymentAppliedToInvoiceOnPaymentJnl()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
        PurchaseLine: Record "Purchase Line";
        AppliesToDocNo: Code[20];
    begin
        // Test to verify Debit and Credit Amounts are equivalent on G/L entries and G/L Book entries after posting Payment Journal.

        // Setup: Create and Post Purchase Invoice. Create Payment Journal.
        AppliesToDocNo := CreateAndPostPurchaseInvoice(PurchaseLine);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalTemplate.Type::Payments, GenJournalLine."Account Type"::Vendor, PurchaseLine."Buy-from Vendor No.",
          PurchaseLine."Amount Including VAT", CreateGLAccount(GLAccount."Gen. Posting Type"::Purchase), AppliesToDocNo);

        // Exercise: Post Payment Journal.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: G/L entries and G/L Book entries.
        VerifyGLEntries(GenJournalLine."Document No.", PurchaseLine."Amount Including VAT");
        VerifyGLBookEntries(GenJournalLine."Document No.", PurchaseLine."Amount Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreditAmtOnPaymentJnlWithNegativeAmt()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // Test to verify Credit Amount gets updated on entering negative Amount on Payment Journal.

        // Exercise: Create Payment Journal line.
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalTemplate.Type::Payments, GenJournalLine."Account Type"::Vendor, CreateVendor(),
          -LibraryRandom.RandDec(100, 2), '', '');  // Use Random value for Amount. Use Blank for Bal. Account No. and Applies To Doc. No.

        // Verify: Credit Amount gets updated on Payment Journal line.
        GenJournalLine.TestField("Credit Amount", Abs(GenJournalLine.Amount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DebitAmtOnPaymentJnlWithPositiveAmt()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // Test to verify Debit Amount gets updated on entering positive Amount on Payment Journal.

        // Exercise: Create Payment Journal line.
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalTemplate.Type::Payments, GenJournalLine."Account Type"::Vendor, CreateVendor(),
          LibraryRandom.RandDec(100, 2), '', '');  // Use Random value for Amount. Use Blank for Bal. Account No. and Applies To Doc. No.

        // Verify: Debit Amount gets updated on Payment Journal line.
        GenJournalLine.TestField("Debit Amount", Abs(GenJournalLine.Amount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PositiveAmtOnPaymentJnlWithPositiveDebitAmt()
    begin
        // Test to verify positive Amount gets updated on entering positive Debit Amount on Payment Journal.
        AmountOnPaymentJournalWithDebitAmount(LibraryRandom.RandDec(100, 2));  // Use Random value for Debit Amount
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NegativeAmtOnPaymentJnlWithNegativeDebitAmt()
    begin
        // Test to verify negative Amount gets updated on entering negative Debit Amount on Payment Journal.
        AmountOnPaymentJournalWithDebitAmount(-LibraryRandom.RandDec(100, 2));  // Use Random value for Debit Amount
    end;

    local procedure AmountOnPaymentJournalWithDebitAmount(DebitAmount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // Setup: Create Payment Journal line.
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalTemplate.Type::Payments, GenJournalLine."Account Type"::Vendor, CreateVendor(), 0, '', '');  // Value Zero required for Amount. Use Blank for Bal. Account No. and Applies To Doc. No.

        // Exercise: Update Debit Amount on Payment Journal line.
        UpdateDebitAmountOnGenJournalLine(GenJournalLine, DebitAmount);

        // Verify: Negative Amount gets updated on Payment Journal line.
        GenJournalLine.TestField(Amount, GenJournalLine."Debit Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NegativeAmtOnPaymentJnlWithPositiveCreditAmt()
    begin
        // Test to verify negative Amount gets updated on entering positive Credit Amount on Payment Journal.
        AmountOnPaymentJournalWithCreditAmount(LibraryRandom.RandDec(100, 2));  // Use Random value for Credit Amount
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PositiveAmtOnPaymentJnlWithNegativeCreditAmt()
    begin
        // Test to verify positive Amount gets updated on entering negative Credit Amount on Payment Journal.
        AmountOnPaymentJournalWithCreditAmount(-LibraryRandom.RandDec(100, 2));  // Use Random value for Credit Amount
    end;

    local procedure AmountOnPaymentJournalWithCreditAmount(CreditAmount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // Setup: Create Payment Journal line.
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalTemplate.Type::Payments, GenJournalLine."Account Type"::Vendor, CreateVendor(), 0, '', '');  // Value Zero required for Amount. Use Blank for Bal. Account No. and Applies To Doc. No.

        // Exercise: Update Credit Amount on Payment Journal line.
        UpdateCreditAmountOnGenJournalLine(GenJournalLine, CreditAmount);

        // Verify: Positive Amount gets updated on Payment Journal line.
        GenJournalLine.TestField(Amount, -GenJournalLine."Credit Amount");
    end;

    local procedure CreateAndPostPurchaseInvoice(var PurchaseLine: Record "Purchase Line"): Code[20]
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(100, 2));  // Use Random value for Quantity
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));  // Use Random value for Direct Unit Cost
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));  // Post as Invoice
    end;

    local procedure CreateAndPostSalesInvoice(var SalesLine: Record "Sales Line"): Code[20]
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer());
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(100, 2));  // Use Random value for Quantity
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));  // Use Random value for Unit Price
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));  // Post as Invoice
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure CreateGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; Type: Enum "Gen. Journal Template Type")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, Type);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; Type: Enum "Gen. Journal Template Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal; BalAccountNo: Code[20]; AppliesToDocNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJournalBatch(GenJournalBatch, Type);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          AccountType, AccountNo, Amount);
        UpdateGenJournalLine(GenJournalLine, BalAccountNo, AppliesToDocNo);
    end;

    local procedure CreateGLAccount(GenPostingType: Enum "General Posting Type"): Code[20]
    var
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.FindZeroVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Validate("Gen. Posting Type", GenPostingType);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        exit(Vendor."No.");
    end;

    local procedure FindGLBookEntry(var GLBookEntry: Record "GL Book Entry"; DocumentNo: Code[20]; Positive: Boolean)
    begin
        GLBookEntry.SetRange("Document No.", DocumentNo);
        GLBookEntry.SetRange(Positive, Positive);
        GLBookEntry.FindFirst();
        GLBookEntry.CalcFields("Credit Amount", "Debit Amount");
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; Positive: Boolean)
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange(Positive, Positive);
        GLEntry.FindFirst();
    end;

    local procedure UpdateCreditAmountOnGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; CreditAmount: Decimal)
    begin
        GenJournalLine.Validate("Credit Amount", CreditAmount);
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateDebitAmountOnGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DebitAmount: Decimal)
    begin
        GenJournalLine.Validate("Debit Amount", DebitAmount);
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; BalAccountNo: Code[20]; AppliesToDocNo: Code[20])
    begin
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Modify(true);
    end;

    local procedure VerifyGLEntries(DocumentNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        FindGLEntry(GLEntry, DocumentNo, false);  // False for Negative
        GLEntry.TestField("Credit Amount", Amount);
        GLEntry.Reset();
        FindGLEntry(GLEntry, DocumentNo, true);  // True for Positive
        GLEntry.TestField("Debit Amount", Amount);
    end;

    local procedure VerifyGLBookEntries(DocumentNo: Code[20]; Amount: Decimal)
    var
        GLBookEntry: Record "GL Book Entry";
    begin
        FindGLBookEntry(GLBookEntry, DocumentNo, false);  // False for Negative
        GLBookEntry.TestField("Credit Amount", Amount);
        GLBookEntry.Reset();
        FindGLBookEntry(GLBookEntry, DocumentNo, true);  // True for Positive
        GLBookEntry.TestField("Debit Amount", Amount);
    end;
}

