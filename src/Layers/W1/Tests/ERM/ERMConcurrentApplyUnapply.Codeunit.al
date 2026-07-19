// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 134081 "ERM Concurrent Apply Unapply"
{
    Permissions = TableData "Cust. Ledger Entry" = rimd,
                  TableData "Vendor Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Apply] [Unapply] [Concurrent Posting]
        IsInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryHumanResource: Codeunit "Library - Human Resource";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        UnappliedErr: Label '%1 %2 field must be true after Unapply entries.', Locked = true;
        TotalAmountErr: Label 'Total Amount must be %1 in %2 table for %3 field : %4.', Locked = true;

    // -------------------------------------------------------------------------
    // Customer Apply / Unapply with Concurrent Posting
    // -------------------------------------------------------------------------

    [Test]
    [Scope('OnPrem')]
    procedure ApplyUnapplyCustPaymentConcurrent()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Customer] [Concurrent Posting]
        // [SCENARIO] After Apply and Unapply of a customer payment with concurrent posting enabled, Detailed Ledger
        // entries are marked Unapplied and the Customer Ledger Entry Remaining Amount equals its Amount.
        Initialize();

        ApplyUnapplyCustEntries(
            GenJournalLine."Document Type"::Invoice,
            GenJournalLine."Document Type"::Payment,
            LibraryRandom.RandInt(500));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyUnapplyCustRefundConcurrent()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Customer] [Concurrent Posting]
        // [SCENARIO] After Apply and Unapply of a customer refund with concurrent posting enabled, Detailed Ledger
        // entries are marked Unapplied and the Customer Ledger Entry Remaining Amount equals its Amount.
        Initialize();

        ApplyUnapplyCustEntries(
            GenJournalLine."Document Type"::"Credit Memo",
            GenJournalLine."Document Type"::Refund,
            -LibraryRandom.RandInt(500));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyUnapplyApplyCustPaymentConcurrent()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Customer] [Concurrent Posting]
        // [SCENARIO] After Apply, Unapply, and Re-Apply of a customer payment with concurrent posting enabled,
        // the Application entries in Detailed Customer Ledger sum to zero.
        Initialize();

        ApplyUnapplyApplyCustEntries(
            GenJournalLine."Document Type"::Invoice,
            GenJournalLine."Document Type"::Payment,
            LibraryRandom.RandInt(500));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyUnapplyApplyCustRefundConcurrent()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Customer] [Concurrent Posting]
        // [SCENARIO] After Apply, Unapply, and Re-Apply of a customer refund with concurrent posting enabled,
        // the Application entries in Detailed Customer Ledger sum to zero.
        Initialize();

        ApplyUnapplyApplyCustEntries(
            GenJournalLine."Document Type"::"Credit Memo",
            GenJournalLine."Document Type"::Refund,
            -LibraryRandom.RandInt(500));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyCustInvoiceLedgerConcurrent()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Customer] [Concurrent Posting]
        // [SCENARIO] Unapply a Customer Invoice from the Invoice side with concurrent posting enabled;
        // Detailed entries are marked Unapplied and GL entries have correct SIFT Bucket No.
        Initialize();

        UnapplyCustEntries(
            GenJournalLine."Document Type"::Invoice,
            GenJournalLine."Document Type"::Payment,
            LibraryRandom.RandInt(500));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyCustCrMemoLedgerConcurrent()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Customer] [Concurrent Posting]
        // [SCENARIO] Unapply a Customer Credit Memo from the Credit Memo side with concurrent posting enabled;
        // Detailed entries are marked Unapplied and GL entries have correct SIFT Bucket No.
        Initialize();

        UnapplyCustEntries(
            GenJournalLine."Document Type"::"Credit Memo",
            GenJournalLine."Document Type"::Refund,
            -LibraryRandom.RandInt(500));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyCustPaymentGLEntriesHaveCorrectSIFTBucketConcurrent()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        DocumentNo: Code[20];
        NoOfLines: Integer;
    begin
        // [FEATURE] [Customer] [SIFT Bucket No.] [Concurrent Posting]
        // [SCENARIO] GL entries created during customer apply/unapply with concurrent posting have SIFT Bucket No. = Entry No. mod 5.
        Initialize();

        // [GIVEN] A customer invoice and payment posted, then applied
        NoOfLines := 2 * LibraryRandom.RandInt(2);
        CreateAndPostCustGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, NoOfLines, LibraryRandom.RandInt(500));
        DocumentNo := GenJournalLine."Document No.";

        ApplyAndPostCustomerEntry(DocumentNo, DocumentNo, -GenJournalLine.Amount, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment);

        // [WHEN] The unapply is done
        UnapplyCustLedgerEntry(GenJournalLine."Document Type"::Payment, DocumentNo);

        // [THEN] All GL entries related to this document have SIFT Bucket No. = Entry No. mod 5
        GLEntry.SetRange("Document No.", DocumentNo);
        Assert.IsTrue(GLEntry.FindSet(), 'GL entries must exist for the posted document');
        repeat
            Assert.AreEqual(
                GLEntry."Entry No." mod 5,
                GLEntry."SIFT Bucket No.",
                'SIFT Bucket No. must equal Entry No. mod 5 for all G/L entries');
        until GLEntry.Next() = 0;
    end;

    // -------------------------------------------------------------------------
    // Vendor Apply / Unapply with Concurrent Posting
    // -------------------------------------------------------------------------

    [Test]
    [Scope('OnPrem')]
    procedure ApplyUnapplyVendPaymentConcurrent()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Vendor] [Concurrent Posting]
        // [SCENARIO] After Apply and Unapply of a vendor payment with concurrent posting enabled, Detailed Vendor Ledger
        // entries are marked Unapplied and the Vendor Ledger Entry Remaining Amount equals its Amount.
        Initialize();

        ApplyUnapplyVendorEntriesAndVerify(
            GenJournalLine."Document Type"::Invoice,
            GenJournalLine."Document Type"::Payment,
            -1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyUnapplyVendRefundConcurrent()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Vendor] [Concurrent Posting]
        // [SCENARIO] After Apply and Unapply of a vendor refund with concurrent posting enabled, Detailed Vendor Ledger
        // entries are marked Unapplied and the Vendor Ledger Entry Remaining Amount equals its Amount.
        Initialize();

        ApplyUnapplyVendorEntriesAndVerify(
            GenJournalLine."Document Type"::"Credit Memo",
            GenJournalLine."Document Type"::Refund,
            1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyUnapplyApplyVendPaymentConcurrent()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Vendor] [Concurrent Posting]
        // [SCENARIO] After Apply, Unapply, and Re-Apply of a vendor payment with concurrent posting enabled,
        // the Application entries in Detailed Vendor Ledger sum to zero.
        Initialize();

        ApplyUnapplyApplyVendorEntries(
            GenJournalLine."Document Type"::Invoice,
            GenJournalLine."Document Type"::Payment,
            -1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyUnapplyApplyVendRefundConcurrent()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Vendor] [Concurrent Posting]
        // [SCENARIO] After Apply, Unapply, and Re-Apply of a vendor refund with concurrent posting enabled,
        // the Application entries in Detailed Vendor Ledger sum to zero.
        Initialize();

        ApplyUnapplyApplyVendorEntries(
            GenJournalLine."Document Type"::"Credit Memo",
            GenJournalLine."Document Type"::Refund,
            1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyVendPaymentGLEntriesHaveCorrectSIFTBucketConcurrent()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
        InvoiceDocNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Vendor] [SIFT Bucket No.] [Concurrent Posting]
        // [SCENARIO] GL entries created during vendor apply/unapply with concurrent posting have SIFT Bucket No. = Entry No. mod 5.
        Initialize();

        Amount := -100 * LibraryRandom.RandInt(10);
        LibraryPurchase.CreateVendor(Vendor);

        CreateVendorJournalLine(GenJournalLine, 1, Vendor."No.", GenJournalLine."Document Type"::Invoice, Amount);
        InvoiceDocNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        CreateVendorJournalLine(GenJournalLine, 1, Vendor."No.", GenJournalLine."Document Type"::Payment, -Amount);
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        ApplyVendorLedgerEntry(GenJournalLine."Document Type"::Payment, GenJournalLine."Document Type"::Invoice, DocumentNo, InvoiceDocNo);

        // [WHEN] Unapply the payment
        UnapplyVendorLedgerEntry(GenJournalLine."Document Type"::Payment, DocumentNo);

        // [THEN] All GL entries related to this document have SIFT Bucket No. = Entry No. mod 5
        GLEntry.SetRange("Document No.", DocumentNo);
        Assert.IsTrue(GLEntry.FindSet(), 'GL entries must exist for the posted document');
        repeat
            Assert.AreEqual(
                GLEntry."Entry No." mod 5,
                GLEntry."SIFT Bucket No.",
                'SIFT Bucket No. must equal Entry No. mod 5');
        until GLEntry.Next() = 0;
    end;

    // -------------------------------------------------------------------------
    // Employee Apply / Unapply with Concurrent Posting
    // -------------------------------------------------------------------------

    [Test]
    [Scope('OnPrem')]
    procedure ApplyUnapplyEmplPaymentConcurrent()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Employee] [Concurrent Posting]
        // [SCENARIO] After Apply and Unapply of an employee payment with concurrent posting enabled, Detailed Employee Ledger
        // entries are marked Unapplied and the Employee Ledger Entry Remaining Amount equals its Amount.
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();

        ApplyUnapplyEmployeeEntriesAndVerify(
            GenJournalLine."Document Type"::" ",
            GenJournalLine."Document Type"::Payment,
            -1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyUnapplyApplyEmplPaymentConcurrent()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Employee] [Concurrent Posting]
        // [SCENARIO] After Apply, Unapply, and Re-Apply of an employee payment with concurrent posting enabled,
        // the Application entries in Detailed Employee Ledger sum to zero.
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();

        ApplyUnapplyApplyEmployeeEntries(
            GenJournalLine."Document Type"::" ",
            GenJournalLine."Document Type"::Payment);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyEmplPaymentGLEntriesHaveCorrectSIFTBucketConcurrent()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        Employee: Record Employee;
        DocumentNo: Code[20];
        ExpenseDocNo: Code[20];
        Amount: Integer;
    begin
        // [FEATURE] [Employee] [SIFT Bucket No.] [Concurrent Posting]
        // [SCENARIO] GL entries created during employee apply/unapply with concurrent posting have SIFT Bucket No. = Entry No. mod 5.
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();

        Amount := 100 * LibraryRandom.RandInt(10);
        CreateEmployee(Employee);

        CreateEmployeeJournalLine(GenJournalLine, 1, Employee."No.", GenJournalLine."Document Type"::" ", -Amount);
        ExpenseDocNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        CreateEmployeeJournalLine(GenJournalLine, 1, Employee."No.", GenJournalLine."Document Type"::Payment, Amount);
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        ApplyEmployeeLedgerEntry(GenJournalLine."Document Type"::Payment, GenJournalLine."Document Type"::" ", DocumentNo, ExpenseDocNo);

        // [WHEN] Unapply
        UnapplyEmployeeLedgerEntry(GenJournalLine."Document Type"::Payment, DocumentNo);

        // [THEN] All GL entries for the payment document have SIFT Bucket No. = Entry No. mod 5
        GLEntry.SetRange("Document No.", DocumentNo);
        Assert.IsTrue(GLEntry.FindSet(), 'GL entries must exist for the payment document');
        repeat
            Assert.AreEqual(
                GLEntry."Entry No." mod 5,
                GLEntry."SIFT Bucket No.",
                'SIFT Bucket No. must equal Entry No. mod 5');
        until GLEntry.Next() = 0;
    end;

    // -------------------------------------------------------------------------
    // Detailed ledger entry count consistency
    // -------------------------------------------------------------------------

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyCustPaymentDetailedEntriesCreatedConcurrent()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        LastDtldEntryNo: Integer;
        NoOfLines: Integer;
        DocNo: Code[20];
    begin
        // [FEATURE] [Customer] [Concurrent Posting]
        // [SCENARIO] Unapplying a customer payment with concurrent posting creates new Detailed Cust. Ledg. entries
        // (the unapplication records) beyond the last entry number that existed before the unapply.
        Initialize();

        if DetailedCustLedgEntry.FindLast() then
            LastDtldEntryNo := DetailedCustLedgEntry."Entry No.";

        // [GIVEN] An invoice and payment applied to each other
        NoOfLines := 2 * LibraryRandom.RandInt(2);
        CreateAndPostCustGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, NoOfLines, LibraryRandom.RandInt(500));
        DocNo := GenJournalLine."Document No.";
        ApplyAndPostCustomerEntry(DocNo, DocNo, -GenJournalLine.Amount, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment);

        // [WHEN] The payment is unapplied
        UnapplyCustLedgerEntry(GenJournalLine."Document Type"::Payment, DocNo);

        // [THEN] New Detailed Cust. Ledg. entries were created for the unapplication
        DetailedCustLedgEntry.SetFilter("Entry No.", '>%1', LastDtldEntryNo);
        Assert.IsTrue(DetailedCustLedgEntry.FindFirst(), 'New Detailed Cust. Ledg. entries must be created by the unapplication');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyVendPaymentDetailedEntriesCreatedConcurrent()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        Vendor: Record Vendor;
        LastDtldEntryNo: Integer;
        InvoiceDocNo: Code[20];
        PaymentDocNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Vendor] [Concurrent Posting]
        // [SCENARIO] Unapplying a vendor payment with concurrent posting creates new Detailed Vendor Ledg. entries.
        Initialize();

        if DetailedVendorLedgEntry.FindLast() then
            LastDtldEntryNo := DetailedVendorLedgEntry."Entry No.";

        Amount := -100 * LibraryRandom.RandInt(10);
        LibraryPurchase.CreateVendor(Vendor);

        CreateVendorJournalLine(GenJournalLine, 1, Vendor."No.", GenJournalLine."Document Type"::Invoice, Amount);
        InvoiceDocNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        CreateVendorJournalLine(GenJournalLine, 1, Vendor."No.", GenJournalLine."Document Type"::Payment, -Amount);
        PaymentDocNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        ApplyVendorLedgerEntry(GenJournalLine."Document Type"::Payment, GenJournalLine."Document Type"::Invoice, PaymentDocNo, InvoiceDocNo);

        // [WHEN] Unapply the payment
        UnapplyVendorLedgerEntry(GenJournalLine."Document Type"::Payment, PaymentDocNo);

        // [THEN] New Detailed Vendor Ledg. entries were created for the unapplication
        DetailedVendorLedgEntry.SetFilter("Entry No.", '>%1', LastDtldEntryNo);
        Assert.IsTrue(DetailedVendorLedgEntry.FindFirst(), 'New Detailed Vendor Ledg. entries must be created by the unapplication');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyEmplPaymentDetailedEntriesCreatedConcurrent()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry";
        Employee: Record Employee;
        LastDtldEntryNo: Integer;
        ExpenseDocNo: Code[20];
        PaymentDocNo: Code[20];
        Amount: Integer;
    begin
        // [FEATURE] [Employee] [Concurrent Posting]
        // [SCENARIO] Unapplying an employee payment with concurrent posting creates new Detailed Employee Ledger entries.
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();

        if DetailedEmployeeLedgerEntry.FindLast() then
            LastDtldEntryNo := DetailedEmployeeLedgerEntry."Entry No.";

        Amount := 100 * LibraryRandom.RandInt(10);
        CreateEmployee(Employee);

        CreateEmployeeJournalLine(GenJournalLine, 1, Employee."No.", GenJournalLine."Document Type"::" ", -Amount);
        ExpenseDocNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        CreateEmployeeJournalLine(GenJournalLine, 1, Employee."No.", GenJournalLine."Document Type"::Payment, Amount);
        PaymentDocNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        ApplyEmployeeLedgerEntry(GenJournalLine."Document Type"::Payment, GenJournalLine."Document Type"::" ", PaymentDocNo, ExpenseDocNo);

        // [WHEN] Unapply the payment
        UnapplyEmployeeLedgerEntry(GenJournalLine."Document Type"::Payment, PaymentDocNo);

        // [THEN] New Detailed Employee Ledger entries were created for the unapplication
        DetailedEmployeeLedgerEntry.SetFilter("Entry No.", '>%1', LastDtldEntryNo);
        Assert.IsTrue(DetailedEmployeeLedgerEntry.FindFirst(), 'New Detailed Employee Ledger entries must be created by the unapplication');
    end;

    // -------------------------------------------------------------------------
    // Local helper scenario procedures
    // -------------------------------------------------------------------------

    local procedure ApplyUnapplyCustEntries(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        NoOfLines: Integer;
    begin
        NoOfLines := 2 * LibraryRandom.RandInt(2);
        CreateAndPostCustGenJournalLine(GenJournalLine, DocumentType, DocumentType2, NoOfLines, Amount);

        ApplyAndPostCustomerEntry(
            GenJournalLine."Document No.", GenJournalLine."Document No.", -GenJournalLine.Amount, DocumentType, DocumentType2);
        UnapplyCustLedgerEntry(DocumentType2, GenJournalLine."Document No.");

        VerifyUnappliedDtldCustLedgEntry(GenJournalLine."Document No.", DocumentType);
        VerifyCustLedgerEntryForRemAmt(GenJournalLine."Document Type", GenJournalLine."Document No.");
    end;

    local procedure ApplyUnapplyApplyCustEntries(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        NoOfLines: Integer;
    begin
        NoOfLines := 2 * LibraryRandom.RandInt(2);
        CreateAndPostCustGenJournalLine(GenJournalLine, DocumentType, DocumentType2, NoOfLines, Amount);

        ApplyAndPostCustomerEntry(
            GenJournalLine."Document No.", GenJournalLine."Document No.", -GenJournalLine.Amount, DocumentType, DocumentType2);
        UnapplyCustLedgerEntry(DocumentType2, GenJournalLine."Document No.");

        ApplyAndPostCustomerEntry(
            GenJournalLine."Document No.", GenJournalLine."Document No.", -GenJournalLine.Amount, DocumentType, DocumentType2);

        VerifyDtldCustLedgEntryApplicationSum(GenJournalLine."Document No.", DocumentType);
    end;

    local procedure UnapplyCustEntries(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        NoOfLines: Integer;
    begin
        NoOfLines := 2 * LibraryRandom.RandInt(2);
        CreateAndPostCustGenJournalLine(GenJournalLine, DocumentType, DocumentType2, NoOfLines, Amount);

        ApplyAndPostCustomerEntry(
            GenJournalLine."Document No.", GenJournalLine."Document No.", -GenJournalLine.Amount, DocumentType, DocumentType2);
        UnapplyCustLedgerEntry(DocumentType, GenJournalLine."Document No.");

        VerifyUnappliedDtldCustLedgEntry(GenJournalLine."Document No.", DocumentType);
        VerifySIFTBucketNoForDocument(GenJournalLine."Document No.");
    end;

    local procedure ApplyUnapplyVendorEntriesAndVerify(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; Sign: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        NoOfLines: Integer;
        Amount: Decimal;
        FirstDocNo: Code[20];
    begin
        NoOfLines := 2 * LibraryRandom.RandInt(2);
        Amount := Sign * 100 * LibraryRandom.RandInt(10);
        LibraryPurchase.CreateVendor(Vendor);

        CreateVendorJournalLine(GenJournalLine, 1, Vendor."No.", DocumentType, Amount);
        FirstDocNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CreateVendorJournalLine(GenJournalLine, NoOfLines, Vendor."No.", DocumentType2, -Amount / NoOfLines);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        ApplyVendorLedgerEntry(DocumentType2, DocumentType, GenJournalLine."Document No.", FirstDocNo);
        UnapplyVendorLedgerEntry(DocumentType2, GenJournalLine."Document No.");

        VerifyRemainingAmountVendor(DocumentType2, GenJournalLine."Document No.");
        VerifyUnappliedDtldVendLedgEntry(GenJournalLine."Document No.", Vendor."No.");
    end;

    local procedure ApplyUnapplyApplyVendorEntries(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; Sign: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        NoOfLines: Integer;
        Amount: Decimal;
        FirstDocNo: Code[20];
    begin
        NoOfLines := 2 * LibraryRandom.RandInt(2);
        Amount := Sign * 100 * LibraryRandom.RandInt(10);
        LibraryPurchase.CreateVendor(Vendor);

        CreateVendorJournalLine(GenJournalLine, 1, Vendor."No.", DocumentType, Amount);
        FirstDocNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CreateVendorJournalLine(GenJournalLine, NoOfLines, Vendor."No.", DocumentType2, -Amount / NoOfLines);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        ApplyVendorLedgerEntry(DocumentType2, DocumentType, GenJournalLine."Document No.", FirstDocNo);
        UnapplyVendorLedgerEntry(DocumentType2, GenJournalLine."Document No.");

        ApplyVendorLedgerEntry(DocumentType2, DocumentType, GenJournalLine."Document No.", FirstDocNo);

        VerifyDtldVendLedgEntryApplicationSum(GenJournalLine."Document No.", Vendor."No.");
    end;

    local procedure ApplyUnapplyEmployeeEntriesAndVerify(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; Sign: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
        Employee: Record Employee;
        NoOfLines: Integer;
        Amount: Integer;
        FirstDocNo: Code[20];
    begin
        NoOfLines := 2 * LibraryRandom.RandInt(2);
        Amount := Sign * 100 * LibraryRandom.RandInt(10);
        CreateEmployee(Employee);

        CreateEmployeeJournalLine(GenJournalLine, 1, Employee."No.", DocumentType, Amount);
        FirstDocNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CreateEmployeeJournalLine(GenJournalLine, NoOfLines, Employee."No.", DocumentType2, -Amount / NoOfLines);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        ApplyEmployeeLedgerEntry(DocumentType2, DocumentType, GenJournalLine."Document No.", FirstDocNo);
        UnapplyEmployeeLedgerEntry(DocumentType2, GenJournalLine."Document No.");

        VerifyRemainingAmountEmployee(DocumentType2, GenJournalLine."Document No.");
        VerifyUnappliedDtldEmplLedgEntry(GenJournalLine."Document No.", Employee."No.");
    end;

    local procedure ApplyUnapplyApplyEmployeeEntries(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type")
    var
        GenJournalLine: Record "Gen. Journal Line";
        Employee: Record Employee;
        NoOfLines: Integer;
        Amount: Integer;
        FirstDocNo: Code[20];
    begin
        NoOfLines := 2 * LibraryRandom.RandInt(2);
        Amount := 100 * LibraryRandom.RandInt(10);
        CreateEmployee(Employee);

        CreateEmployeeJournalLine(GenJournalLine, 1, Employee."No.", DocumentType, -Amount);
        FirstDocNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CreateEmployeeJournalLine(GenJournalLine, NoOfLines, Employee."No.", DocumentType2, Amount / NoOfLines);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        ApplyEmployeeLedgerEntry(DocumentType2, DocumentType, GenJournalLine."Document No.", FirstDocNo);
        UnapplyEmployeeLedgerEntry(DocumentType2, GenJournalLine."Document No.");

        ApplyEmployeeLedgerEntry(DocumentType2, DocumentType, GenJournalLine."Document No.", FirstDocNo);

        VerifyDtldEmplLedgEntryApplicationSum(GenJournalLine."Document No.", Employee."No.");
    end;

    // -------------------------------------------------------------------------
    // Initialize
    // -------------------------------------------------------------------------

    local procedure Initialize()
    var
        EmployeePostingGroup: Record "Employee Posting Group";
        Employee: Record Employee;
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ERM Concurrent Apply Unapply");
        LibrarySetupStorage.Restore();

        EmployeePostingGroup.DeleteAll();
        Employee.DeleteAll();
        CreateEmployeePostingGroup(LibraryERM.CreateGLAccountNoWithDirectPosting());

        if IsInitialized then begin
            EnableConcurrentPosting(true);
            Commit();
            exit;
        end;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ERM Concurrent Apply Unapply");

        LibrarySales.SetInvoiceRounding(false);
        LibraryPurchase.SetInvoiceRounding(false);
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateAccountInCustomerPostingGroup();
        LibraryERMCountryData.UpdateAccountInVendorPostingGroups();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.RemoveBlankGenJournalTemplate();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        IsInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Source Code Setup");

        EnableConcurrentPosting(true);
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ERM Concurrent Apply Unapply");
    end;

    // -------------------------------------------------------------------------
    // General Ledger Setup
    // -------------------------------------------------------------------------

    local procedure EnableConcurrentPosting(Enable: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Use Concurrent Posting" := Enable;
        GeneralLedgerSetup.Modify();
    end;

    // -------------------------------------------------------------------------
    // Customer helpers
    // -------------------------------------------------------------------------

    local procedure CreateAndPostCustGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; NoOfLines: Integer; Amount: Decimal)
    var
        Customer: Record Customer;
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        SelectCustGenJournalBatch(GenJournalBatch);
        LibrarySales.CreateCustomer(Customer);
        CreateCustGeneralJournalLines(GenJournalLine, GenJournalBatch, 1, Customer."No.", DocumentType, Amount);
        CreateCustGeneralJournalLines(
            GenJournalLine, GenJournalBatch, NoOfLines, Customer."No.", DocumentType2, -GenJournalLine.Amount / NoOfLines);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateCustGeneralJournalLines(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; NoofLines: Integer; CustomerNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        Counter: Integer;
    begin
        for Counter := 1 to NoofLines do
            LibraryERM.CreateGeneralJnlLine(
                GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
                GenJournalLine."Account Type"::Customer, CustomerNo, Amount);
    end;

    local procedure ApplyAndPostCustomerEntry(DocumentNo: Code[20]; DocumentNo2: Code[20]; AmountToApply: Decimal; DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntry, AmountToApply);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry2, DocumentType2, DocumentNo2);
        CustLedgerEntry2.FindSet();
        repeat
            CustLedgerEntry2.CalcFields("Remaining Amount");
            CustLedgerEntry2.Validate("Amount to Apply", CustLedgerEntry2."Remaining Amount");
            CustLedgerEntry2.Modify(true);
        until CustLedgerEntry2.Next() = 0;
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry2);
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);
    end;

    local procedure UnapplyCustLedgerEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgerEntry);
    end;

    local procedure SelectCustGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    // -------------------------------------------------------------------------
    // Vendor helpers
    // -------------------------------------------------------------------------

    local procedure CreateVendorJournalLine(var GenJournalLine: Record "Gen. Journal Line"; NoOfLine: Integer; VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        Counter: Integer;
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        for Counter := 1 to NoOfLine do
            LibraryERM.CreateGeneralJnlLine(
                GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
                GenJournalLine."Account Type"::Vendor, VendorNo, Amount);
    end;

    local procedure ApplyVendorLedgerEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; DocumentNo2: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, DocumentNo);
        VendorLedgerEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyVendorEntry(VendorLedgerEntry, VendorLedgerEntry."Remaining Amount");
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry2, DocumentType2, DocumentNo2);
        VendorLedgerEntry2.FindSet();
        repeat
            VendorLedgerEntry2.CalcFields("Remaining Amount");
            VendorLedgerEntry2.Validate("Amount to Apply", VendorLedgerEntry2."Remaining Amount");
            VendorLedgerEntry2.Modify(true);
        until VendorLedgerEntry2.Next() = 0;
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry2);
        LibraryERM.PostVendLedgerApplication(VendorLedgerEntry);
    end;

    local procedure UnapplyVendorLedgerEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, DocumentNo);
        VendorLedgerEntry.SetRange(Open, false);
        VendorLedgerEntry.FindLast();
        LibraryERM.UnapplyVendorLedgerEntry(VendorLedgerEntry);
    end;

    // -------------------------------------------------------------------------
    // Employee helpers
    // -------------------------------------------------------------------------

    local procedure CreateEmployee(var Employee: Record Employee)
    var
        EmployeePostingGroup: Record "Employee Posting Group";
    begin
        LibraryHumanResource.CreateEmployee(Employee);
        EmployeePostingGroup.FindFirst();
        Employee.Validate("Employee Posting Group", EmployeePostingGroup.Code);
        Employee.Validate("Application Method", Employee."Application Method"::Manual);
        Employee.Modify(true);
    end;

    local procedure CreateEmployeePostingGroup(GLAccountNo: Code[20])
    var
        EmployeePostingGroup: Record "Employee Posting Group";
    begin
        EmployeePostingGroup.Init();
        EmployeePostingGroup.Code := LibraryERM.CreateNoSeriesCode();
        EmployeePostingGroup."Payables Account" := GLAccountNo;
        EmployeePostingGroup.Insert(true);
    end;

    local procedure CreateEmployeeJournalLine(var GenJournalLine: Record "Gen. Journal Line"; NoOfLine: Integer; EmployeeNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        Counter: Integer;
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        for Counter := 1 to NoOfLine do
            LibraryERM.CreateGeneralJnlLine(
                GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
                GenJournalLine."Account Type"::Employee, EmployeeNo, Amount);
    end;

    local procedure ApplyEmployeeLedgerEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; DocumentNo2: Code[20])
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        EmployeeLedgerEntry2: Record "Employee Ledger Entry";
    begin
        LibraryERM.FindEmployeeLedgerEntry(EmployeeLedgerEntry, DocumentType, DocumentNo);
        EmployeeLedgerEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyEmployeeEntry(EmployeeLedgerEntry, EmployeeLedgerEntry."Remaining Amount");
        LibraryERM.FindEmployeeLedgerEntry(EmployeeLedgerEntry2, DocumentType2, DocumentNo2);
        EmployeeLedgerEntry2.FindSet();
        repeat
            EmployeeLedgerEntry2.CalcFields("Remaining Amount");
            EmployeeLedgerEntry2.Validate("Amount to Apply", EmployeeLedgerEntry2."Remaining Amount");
            EmployeeLedgerEntry2.Modify(true);
        until EmployeeLedgerEntry2.Next() = 0;
        LibraryERM.SetAppliestoIdEmployee(EmployeeLedgerEntry2);
        LibraryERM.PostEmplLedgerApplication(EmployeeLedgerEntry);
    end;

    local procedure UnapplyEmployeeLedgerEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        LibraryERM.FindEmployeeLedgerEntry(EmployeeLedgerEntry, DocumentType, DocumentNo);
        EmployeeLedgerEntry.SetRange(Open, false);
        EmployeeLedgerEntry.FindLast();
        LibraryERM.UnapplyEmployeeLedgerEntry(EmployeeLedgerEntry);
    end;

    // -------------------------------------------------------------------------
    // Verify helpers
    // -------------------------------------------------------------------------

    local procedure VerifyUnappliedDtldCustLedgEntry(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::Application);
        DetailedCustLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedCustLedgEntry.SetRange("Document Type", DocumentType);
        DetailedCustLedgEntry.FindSet();
        repeat
            Assert.IsTrue(
                DetailedCustLedgEntry.Unapplied,
                StrSubstNo(UnappliedErr, DetailedCustLedgEntry.TableCaption(), DetailedCustLedgEntry.Unapplied));
        until DetailedCustLedgEntry.Next() = 0;
    end;

    local procedure VerifyCustLedgerEntryForRemAmt(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        repeat
            CustLedgerEntry.CalcFields("Remaining Amount", Amount);
            CustLedgerEntry.TestField("Remaining Amount", CustLedgerEntry.Amount);
        until CustLedgerEntry.Next() = 0;
    end;

    local procedure VerifyDtldCustLedgEntryApplicationSum(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        TotalAmount: Decimal;
    begin
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::Application);
        DetailedCustLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedCustLedgEntry.SetRange("Document Type", DocumentType);
        DetailedCustLedgEntry.FindSet();
        repeat
            TotalAmount += DetailedCustLedgEntry.Amount;
        until DetailedCustLedgEntry.Next() = 0;
        Assert.AreEqual(
            0, TotalAmount,
            StrSubstNo(TotalAmountErr, 0, DetailedCustLedgEntry.TableCaption(),
                DetailedCustLedgEntry.FieldCaption("Entry Type"), DetailedCustLedgEntry."Entry Type"));
    end;

    local procedure VerifyUnappliedDtldVendLedgEntry(DocumentNo: Code[20]; VendorNo: Code[20])
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgEntry.SetRange("Entry Type", DetailedVendorLedgEntry."Entry Type"::Application);
        DetailedVendorLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedVendorLedgEntry.SetRange("Vendor No.", VendorNo);
        DetailedVendorLedgEntry.FindSet();
        repeat
            Assert.IsTrue(
                DetailedVendorLedgEntry.Unapplied,
                StrSubstNo(UnappliedErr, DetailedVendorLedgEntry.TableCaption(), DetailedVendorLedgEntry.Unapplied));
        until DetailedVendorLedgEntry.Next() = 0;
    end;

    local procedure VerifyRemainingAmountVendor(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, DocumentNo);
        repeat
            VendorLedgerEntry.CalcFields("Remaining Amount", Amount);
            VendorLedgerEntry.TestField("Remaining Amount", VendorLedgerEntry.Amount);
        until VendorLedgerEntry.Next() = 0;
    end;

    local procedure VerifyDtldVendLedgEntryApplicationSum(DocumentNo: Code[20]; VendorNo: Code[20])
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        TotalAmount: Decimal;
    begin
        DetailedVendorLedgEntry.SetRange("Entry Type", DetailedVendorLedgEntry."Entry Type"::Application);
        DetailedVendorLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedVendorLedgEntry.SetRange("Vendor No.", VendorNo);
        DetailedVendorLedgEntry.FindSet();
        repeat
            TotalAmount += DetailedVendorLedgEntry.Amount;
        until DetailedVendorLedgEntry.Next() = 0;
        Assert.AreEqual(
            0, TotalAmount,
            StrSubstNo(TotalAmountErr, 0, DetailedVendorLedgEntry.TableCaption(),
                DetailedVendorLedgEntry.FieldCaption("Entry Type"), DetailedVendorLedgEntry."Entry Type"));
    end;

    local procedure VerifyUnappliedDtldEmplLedgEntry(DocumentNo: Code[20]; EmployeeNo: Code[20])
    var
        DetailedEmployeeLedgEntry: Record "Detailed Employee Ledger Entry";
    begin
        DetailedEmployeeLedgEntry.SetRange("Entry Type", DetailedEmployeeLedgEntry."Entry Type"::Application);
        DetailedEmployeeLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedEmployeeLedgEntry.SetRange("Employee No.", EmployeeNo);
        DetailedEmployeeLedgEntry.FindSet();
        repeat
            Assert.IsTrue(
                DetailedEmployeeLedgEntry.Unapplied,
                StrSubstNo(UnappliedErr, DetailedEmployeeLedgEntry.TableCaption(), DetailedEmployeeLedgEntry.Unapplied));
        until DetailedEmployeeLedgEntry.Next() = 0;
    end;

    local procedure VerifyRemainingAmountEmployee(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        LibraryERM.FindEmployeeLedgerEntry(EmployeeLedgerEntry, DocumentType, DocumentNo);
        repeat
            EmployeeLedgerEntry.CalcFields("Remaining Amount", Amount);
            EmployeeLedgerEntry.TestField("Remaining Amount", EmployeeLedgerEntry.Amount);
        until EmployeeLedgerEntry.Next() = 0;
    end;

    local procedure VerifyDtldEmplLedgEntryApplicationSum(DocumentNo: Code[20]; EmployeeNo: Code[20])
    var
        DetailedEmployeeLedgEntry: Record "Detailed Employee Ledger Entry";
        TotalAmount: Decimal;
    begin
        DetailedEmployeeLedgEntry.SetRange("Entry Type", DetailedEmployeeLedgEntry."Entry Type"::Application);
        DetailedEmployeeLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedEmployeeLedgEntry.SetRange("Employee No.", EmployeeNo);
        DetailedEmployeeLedgEntry.FindSet();
        repeat
            TotalAmount += DetailedEmployeeLedgEntry.Amount;
        until DetailedEmployeeLedgEntry.Next() = 0;
        Assert.AreEqual(
            0, TotalAmount,
            StrSubstNo(TotalAmountErr, 0, DetailedEmployeeLedgEntry.TableCaption(),
                DetailedEmployeeLedgEntry.FieldCaption("Entry Type"), DetailedEmployeeLedgEntry."Entry Type"));
    end;

    local procedure VerifySIFTBucketNoForDocument(DocumentNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        if GLEntry.FindSet() then
            repeat
                Assert.AreEqual(
                    GLEntry."Entry No." mod 5,
                    GLEntry."SIFT Bucket No.",
                    'SIFT Bucket No. must equal Entry No. mod 5 for all G/L entries');
            until GLEntry.Next() = 0;
    end;
}
