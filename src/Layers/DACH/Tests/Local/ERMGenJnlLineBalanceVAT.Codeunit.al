codeunit 142084 "ERM Gen. Jnl. Line Balance VAT"
{
    // // [FEATURE] [Apply] [VAT]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryJournals: Codeunit "Library - Journals";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        PmtApplnErr: Label 'You cannot post and apply general journal line %1, %2, %3 because the corresponding balance contains VAT.', Comment = '%1 - Template name, %2 - Batch name, %3 - Line no.';

    [Test]
    [Scope('OnPrem')]
    procedure CustPmtWithApplnAndBalAccWithVAT()
    var
        InvGenJnlLine: Record "Gen. Journal Line";
        PmtGenJnlLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] System does not allow post sales payment applied to invoice when balancing account has VAT

        // [GIVEN] Sales "Invoice" Gen. Jnl. Line
        CreateInvGenJnlLine(
          InvGenJnlLine, InvGenJnlLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), LibraryRandom.RandInt(100));
        // [GIVEN] Sales "Payment" Gen. Jnl. Line with VAT in balance account and applied to "Invoice" Gen. Jnl. Line
        CreatePmtGenJnlLine(
          PmtGenJnlLine, InvGenJnlLine, CreateBalanceGLAcountNo(PmtGenJnlLine."Gen. Posting Type"::Sale));
        ApplyPmtToInvGenJnlLine(PmtGenJnlLine, InvGenJnlLine);

        // [WHEN] Post journal
        asserterror LibraryERM.PostGeneralJnlLine(PmtGenJnlLine);
        // [THEN] Error message "You cannot post and apply general journal line because the corresponding balance contains VAT." thrown
        VerifyApplicationWithVATBalancingError(PmtGenJnlLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendPmtWithApplnAndBalAccWithVAT()
    var
        InvGenJnlLine: Record "Gen. Journal Line";
        PmtGenJnlLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] System does not allow post purchase payment applied to invoice when balancing account has VAT

        // [GIVEN] Purchase "Invoice" Gen. Jnl. Line
        CreateInvGenJnlLine(
          InvGenJnlLine, InvGenJnlLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(), -LibraryRandom.RandInt(100));
        // [GIVEN] Purchase "Payment" Gen. Jnl. Line with VAT in balance account and applied to "Invoice" Gen. Jnl. Line
        CreatePmtGenJnlLine(
          PmtGenJnlLine, InvGenJnlLine, CreateBalanceGLAcountNo(PmtGenJnlLine."Gen. Posting Type"::Purchase));
        ApplyPmtToInvGenJnlLine(PmtGenJnlLine, InvGenJnlLine);

        // [WHEN] Post journal
        asserterror LibraryERM.PostGeneralJnlLine(PmtGenJnlLine);

        // [THEN] Error message "You cannot post and apply general journal line because the corresponding balance contains VAT." thrown
        VerifyApplicationWithVATBalancingError(PmtGenJnlLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPaymentJournalWithVATLine()
    var
        InvGenJnlLine: Record "Gen. Journal Line";
        PmtGenJnlLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 372831] System allows post two payments when 1st payment is applied to invoice, 2nd has VAT in balance account and they have different "Document No."

        // [GIVEN] Posted Sales Invoice
        CreateInvGenJnlLine(
          InvGenJnlLine, InvGenJnlLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), LibraryRandom.RandInt(100));
        PostInvoice(InvGenJnlLine);

        // [GIVEN] Payment Journal Line[1] with "Document No." = 1, without VAT in balance account and applied to posted invoice
        CreatePmtGenJnlLine(PmtGenJnlLine, InvGenJnlLine, LibraryERM.CreateGLAccountNo());
        ApplyPmtToInvGenJnlLine(PmtGenJnlLine, InvGenJnlLine);

        // [GIVEN] Payment Journal Line[2] with "Document No." = 2 and with VAT in balance account
        CreatePmtGenJnlLine(PmtGenJnlLine, InvGenJnlLine, CreateBalanceGLAcountNo(PmtGenJnlLine."Gen. Posting Type"::Sale));

        // [WHEN] Post sales "Payment" Gen. Jnl. Line
        LibraryERM.PostGeneralJnlLine(PmtGenJnlLine);

        // [THEN] Payments posted successfully
        VerifyPostedSalesDocuments(InvGenJnlLine."Account No.", 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasePaymentJournalWithVATLine()
    var
        InvGenJnlLine: Record "Gen. Journal Line";
        PmtGenJnlLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 372831] System allows post two payments when 1st payment is applied to invoice, 2nd has VAT in balance account and they have different "Document No."

        // [GIVEN] Posted Purchase Invoice
        CreateInvGenJnlLine(
          InvGenJnlLine, InvGenJnlLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(), -LibraryRandom.RandInt(100));
        PostInvoice(InvGenJnlLine);

        // [GIVEN] Payment Journal Line[1] with "Document No." = 1, without VAT in balance account and applied to posted invoice
        CreatePmtGenJnlLine(PmtGenJnlLine, InvGenJnlLine, LibraryERM.CreateGLAccountNo());
        ApplyPmtToInvGenJnlLine(PmtGenJnlLine, InvGenJnlLine);

        // [GIVEN] Payment Journal Line[2] with "Document No." = 2 and with VAT in balance account
        CreatePmtGenJnlLine(PmtGenJnlLine, InvGenJnlLine, CreateBalanceGLAcountNo(PmtGenJnlLine."Gen. Posting Type"::Purchase));

        // [WHEN] Post purchase "Payment" Gen. Jnl. Line
        LibraryERM.PostGeneralJnlLine(PmtGenJnlLine);

        // [THEN] Payments posted successfully
        VerifyPostedPurchaseDocuments(InvGenJnlLine."Account No.", 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPaymentJournalWithVATLineSameDocNo()
    var
        InvGenJnlLine: Record "Gen. Journal Line";
        PmtGenJnlLine: Record "Gen. Journal Line";
        GLEntry: array[2] of Record "G/L Entry";
        BalAccountNo: array[2] of Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 211225] System allows to post two payments when 1st payment is applied to invoice, 2nd has VAT in balance account and they have been posted in different transactions

        // [GIVEN] Posted Sales Invoice
        CreateInvGenJnlLine(
          InvGenJnlLine, InvGenJnlLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), LibraryRandom.RandInt(100));
        PostInvoice(InvGenJnlLine);

        // [GIVEN] Payment Journal Line[1] with "Document No." = 1, without VAT in balance account and applied to posted invoice. Balance = 0
        // [GIVEN] Payment Journal Line[2] with "Document No." = 1 and with VAT in balance account
        CreatePaymentLinesWithEqualDocNo(PmtGenJnlLine, InvGenJnlLine, PmtGenJnlLine."Gen. Posting Type"::Sale, BalAccountNo);

        // [WHEN] Post sales "Payment" Gen. Jnl. Line
        LibraryERM.PostGeneralJnlLine(PmtGenJnlLine);

        // [THEN] G/L Entries for payments created in different transactions
        FindPaymentGLEntryByBalanceAccountNo(GLEntry[1], PmtGenJnlLine."Document No.", BalAccountNo[1]);
        FindPaymentGLEntryByBalanceAccountNo(GLEntry[2], PmtGenJnlLine."Document No.", BalAccountNo[2]);

        Assert.AreNotEqual(GLEntry[1]."Entry No.", GLEntry[2]."Entry No.", 'Two entries expected to be found');
        Assert.AreNotEqual(GLEntry[1]."Transaction No.", GLEntry[2]."Transaction No.", 'G/L entrue');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasePaymentJournalWithVATLineSameDocNo()
    var
        InvGenJnlLine: Record "Gen. Journal Line";
        PmtGenJnlLine: Record "Gen. Journal Line";
        GLEntry: array[2] of Record "G/L Entry";
        BalAccountNo: array[2] of Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 211225] System allows to post two payments with the same Document No. when 1st payment is applied to invoice, 2nd has VAT in balance account and they have been posted in different transactions

        // [GIVEN] Posted Purchase Invoice
        CreateInvGenJnlLine(
          InvGenJnlLine, InvGenJnlLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(), -LibraryRandom.RandInt(100));
        PostInvoice(InvGenJnlLine);

        // [GIVEN] Payment Journal Line[1] with "Document No." = 1, without VAT in balance account and applied to posted invoice. Balance = 0
        // [GIVEN] Payment Journal Line[2] with "Document No." = 1 and with VAT in balance account
        CreatePaymentLinesWithEqualDocNo(PmtGenJnlLine, InvGenJnlLine, PmtGenJnlLine."Gen. Posting Type"::Purchase, BalAccountNo);

        // [WHEN] Post purchase "Payment" Gen. Jnl. Line
        LibraryERM.PostGeneralJnlLine(PmtGenJnlLine);

        // [THEN] G/L Entries for payments created in different transactions
        FindPaymentGLEntryByBalanceAccountNo(GLEntry[1], PmtGenJnlLine."Document No.", BalAccountNo[1]);
        FindPaymentGLEntryByBalanceAccountNo(GLEntry[2], PmtGenJnlLine."Document No.", BalAccountNo[2]);

        Assert.AreNotEqual(GLEntry[1]."Entry No.", GLEntry[2]."Entry No.", 'Two entries expected to be found');
        Assert.AreNotEqual(GLEntry[1]."Transaction No.", GLEntry[2]."Transaction No.", 'G/L entrue');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceAppliedToPaymentWithAdditionalLine()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        InvoiceGenJournalLine: Record "Gen. Journal Line";
        PaymentGenJournalLine: Record "Gen. Journal Line";
        AppliedPaymentGenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 228785] System does not allow post sales payment journal line applied to invoice when balancing account has VAT and second payment line is allowed for posting
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);

        // [GIVEN] Posted invoice "I" for customer "C"
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          InvoiceGenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          InvoiceGenJournalLine."Document Type"::Invoice,
          InvoiceGenJournalLine."Account Type"::"G/L Account",
          CreateBalanceGLAcountNo(InvoiceGenJournalLine."Gen. Posting Type"::Sale),
          InvoiceGenJournalLine."Bal. Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          -LibraryRandom.RandIntInRange(100, 200));

        LibraryERM.PostGeneralJnlLine(InvoiceGenJournalLine);

        // [GIVEN] First payment journal line for customer "C" applied to "I" with balancing G/L Account having VAT setup
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          PaymentGenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          PaymentGenJournalLine."Document Type"::Payment,
          PaymentGenJournalLine."Account Type"::Customer, InvoiceGenJournalLine."Bal. Account No.",
          PaymentGenJournalLine."Bal. Account Type"::"G/L Account", InvoiceGenJournalLine."Account No.",
          InvoiceGenJournalLine.Amount);

        ApplyPmtToInvGenJnlLine(PaymentGenJournalLine, InvoiceGenJournalLine);
        AppliedPaymentGenJournalLine := PaymentGenJournalLine;

        // [GIVEN] Second payment journal line without restriction to post
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          PaymentGenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          PaymentGenJournalLine."Document Type"::Payment,
          PaymentGenJournalLine."Account Type"::"G/L Account", InvoiceGenJournalLine."Account No.",
          PaymentGenJournalLine."Bal. Account Type"::"G/L Account", InvoiceGenJournalLine."Account No.",
          LibraryRandom.RandInt(10));

        // [WHEN] Post payment journal lines
        asserterror LibraryERM.PostGeneralJnlLine(PaymentGenJournalLine);

        // [THEN] Error message "You cannot post and apply general journal line because the corresponding balance contains VAT." thrown
        VerifyApplicationWithVATBalancingError(AppliedPaymentGenJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceAppliedToPaymentWithAdditionalLine()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        InvoiceGenJournalLine: Record "Gen. Journal Line";
        PaymentGenJournalLine: Record "Gen. Journal Line";
        AppliedPaymentGenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 228785] System does not allow post purchase payment journal line applied to invoice when balancing account has VAT and second payment line is allowed for posting
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);

        // [GIVEN] Posted invoice "I" for vendor "V"
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          InvoiceGenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          InvoiceGenJournalLine."Document Type"::Invoice,
          InvoiceGenJournalLine."Account Type"::"G/L Account",
          CreateBalanceGLAcountNo(InvoiceGenJournalLine."Gen. Posting Type"::Purchase),
          InvoiceGenJournalLine."Bal. Account Type"::Vendor, LibraryPurchase.CreateVendorNo(),
          LibraryRandom.RandIntInRange(100, 200));

        LibraryERM.PostGeneralJnlLine(InvoiceGenJournalLine);

        // [GIVEN] First payment journal line for vendor "V" applied to "I" with balancing G/L Account having VAT setup
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          PaymentGenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          PaymentGenJournalLine."Document Type"::Payment,
          PaymentGenJournalLine."Account Type"::Vendor, InvoiceGenJournalLine."Bal. Account No.",
          PaymentGenJournalLine."Bal. Account Type"::"G/L Account", InvoiceGenJournalLine."Account No.",
          InvoiceGenJournalLine.Amount);

        ApplyPmtToInvGenJnlLine(PaymentGenJournalLine, InvoiceGenJournalLine);
        AppliedPaymentGenJournalLine := PaymentGenJournalLine;

        // [GIVEN] Second payment journal line without restriction to post
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          PaymentGenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          PaymentGenJournalLine."Document Type"::Payment,
          PaymentGenJournalLine."Account Type"::"G/L Account", InvoiceGenJournalLine."Account No.",
          PaymentGenJournalLine."Bal. Account Type"::"G/L Account", InvoiceGenJournalLine."Account No.",
          -LibraryRandom.RandInt(10));

        // [WHEN] Post payment journal lines
        asserterror LibraryERM.PostGeneralJnlLine(PaymentGenJournalLine);

        // [THEN] Error message "You cannot post and apply general journal line because the corresponding balance contains VAT." thrown
        VerifyApplicationWithVATBalancingError(AppliedPaymentGenJournalLine);
    end;

    local procedure CreateInvGenJnlLine(var InvGenJnlLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal)
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          InvGenJnlLine, InvGenJnlLine."Document Type"::Invoice, AccountType, AccountNo, Amount);
    end;

    local procedure CreatePmtGenJnlLine(var PmtGenJnlLine: Record "Gen. Journal Line"; InvGenJnlLine: Record "Gen. Journal Line"; BalGLAccountNo: Code[20])
    begin
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          PmtGenJnlLine, InvGenJnlLine."Journal Template Name", InvGenJnlLine."Journal Batch Name",
          PmtGenJnlLine."Document Type"::Payment, InvGenJnlLine."Account Type",
          InvGenJnlLine."Account No.", PmtGenJnlLine."Bal. Account Type"::"G/L Account",
          BalGLAccountNo, -InvGenJnlLine.Amount);
    end;

    local procedure ApplyPmtToInvGenJnlLine(var PmtGenJnlLine: Record "Gen. Journal Line"; InvGenJnlLine: Record "Gen. Journal Line")
    begin
        PmtGenJnlLine.Validate("Applies-to Doc. Type", PmtGenJnlLine."Applies-to Doc. Type"::Invoice);
        PmtGenJnlLine.Validate("Applies-to Doc. No.", InvGenJnlLine."Document No.");
        PmtGenJnlLine.Modify(true);
    end;

    local procedure CreateBalanceGLAcountNo(GenPostingType: Enum "General Posting Type"): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandInt(10));
        exit(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GenPostingType));
    end;

    local procedure CreatePaymentLinesWithEqualDocNo(var PmtGenJnlLine: Record "Gen. Journal Line"; InvGenJnlLine: Record "Gen. Journal Line"; GenPostingType: Enum "General Posting Type"; var BalAccountNo: array[2] of Code[20])
    var
        DocNo: Code[20];
    begin
        CreatePmtGenJnlLine(PmtGenJnlLine, InvGenJnlLine, LibraryERM.CreateGLAccountNo());
        ApplyPmtToInvGenJnlLine(PmtGenJnlLine, InvGenJnlLine);
        DocNo := PmtGenJnlLine."Document No.";
        BalAccountNo[1] := PmtGenJnlLine."Bal. Account No.";

        CreatePmtGenJnlLine(PmtGenJnlLine, InvGenJnlLine, CreateBalanceGLAcountNo(GenPostingType));
        PmtGenJnlLine.Validate("Document No.", DocNo);
        PmtGenJnlLine.Modify(true);
        BalAccountNo[2] := PmtGenJnlLine."Bal. Account No.";
    end;

    local procedure FindPaymentGLEntryByBalanceAccountNo(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; BalAccountNo: Code[20])
    begin
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Payment);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Bal. Account No.", BalAccountNo);
        GLEntry.FindFirst();
    end;

    local procedure PostInvoice(var InvGenJnlLine: Record "Gen. Journal Line")
    begin
        LibraryERM.PostGeneralJnlLine(InvGenJnlLine);
    end;

    local procedure VerifyPostedSalesDocuments(CustomerNo: Code[20]; ExpectedCount: Integer)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        Assert.RecordCount(CustLedgerEntry, ExpectedCount);
    end;

    local procedure VerifyPostedPurchaseDocuments(VendorNo: Code[20]; ExpectedCount: Integer)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        Assert.RecordCount(VendorLedgerEntry, ExpectedCount);
    end;

    local procedure VerifyApplicationWithVATBalancingError(GenJournalLine: Record "Gen. Journal Line")
    begin
        Assert.ExpectedError(
              StrSubstNo(
                PmtApplnErr, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No."));
    end;
}

