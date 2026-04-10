codeunit 144505 "ERM RU Apply Unapply Vend"
{
    // // [FEATURE] [Purchase] [Unapply]
    // ---------------------------------------------------------------------------
    // Test Function Name                                                  TFS ID
    // ---------------------------------------------------------------------------
    // 1. UnapplyPaymentAtAllowedDate                                      322866

    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        Assert: Codeunit Assert;
        UnappliedErr: Label '%1 field must be true after Unapply entries.';
        WrongVendBackPrepaymentErr: Label 'Wrong Vendor Back Prepayment.';

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyPaymentAtAllowedDate()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorNo: Code[20];
        PaymentNo: Code[20];
        PostingDateFrom: Date;
        OldPostingDateFrom: Date;
        Amount: Decimal;
    begin
        // [SCENARIO 322866] Unapply Vendor Ledger Entry when "Allow Posting From" date is defined
        // [GIVEN] Posted and Applied Vendor Ledger Entries with PaymentNo = "X"
        VendorNo := LibraryPurchase.CreateVendorNo();
        PostApplyVendLedgerEntries(PaymentNo, Amount, VendorNo, VendorLedgerEntry."Document Type"::Invoice, false);

        // [GIVEN] Set Allow Posting From Date = "D"
        PostingDateFrom := CalcDate('<1Y>', WorkDate());
        OldPostingDateFrom := SetAllowPostingFrom(PostingDateFrom);

        // [WHEN] Unapply Vendor Ledger Entry on Posting From Date = "D" for PaymentNo = "X"
        UnapplyVendLedgerEntry(VendorLedgerEntry."Document Type"::Payment, PaymentNo, PostingDateFrom);

        // [THEN] Detailed Vendor Ledger Entries marked as Unapplied
        VerifyUnappliedDtldLedgEntry(PaymentNo, VendorLedgerEntry."Document Type"::Payment);

        // TearDown
        SetAllowPostingFrom(OldPostingDateFrom);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyVendorPrepayment()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorNo: Code[20];
        PaymentNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Prepayment]
        // [SCENARIO 123864] Unapply Vendor Ledger Entry with Prepayment
        // [GIVEN] Posted and Applied Vendor Ledger Entries with PaymentNo = "X" and prepayment Amount = "A"
        VendorNo := LibraryPurchase.CreateVendorNo();
        PostApplyVendLedgerEntries(PaymentNo, Amount, VendorNo, VendorLedgerEntry."Document Type"::Invoice, true);

        // [WHEN] Unapply Vendor Ledger Entry for PaymentNo = "X"
        UnapplyVendLedgerEntry(VendorLedgerEntry."Document Type"::Payment, PaymentNo, WorkDate());

        // [THEN] G/L Register created with Source Code for Unapplication with Amount = "A"
        VerifyUnappliedGLEntries(VendorNo, Amount);
    end;

    local procedure ApplyVendorInvoiceToPayment(InvoiceDocNo: Code[20]; PaymentDocNo: Code[20])
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.ApplyVendorLedgerEntry(
          VendLedgEntry."Document Type"::Invoice, InvoiceDocNo,
          VendLedgEntry."Document Type"::Payment, PaymentDocNo);
    end;

    local procedure PostApplyVendLedgerEntries(var PaymentNo: Code[20]; var Amount: Decimal; VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Prepayment: Boolean)
    var
        GenJournalLine: Record "Gen. Journal Line";
        InvoiceNo: Code[20];
    begin
        Amount := LibraryRandom.RandDec(100, 2);
        InvoiceNo :=
          CreateAndPostGenJournalLine(
            GenJournalLine,
            VendorNo, DocumentType, GenJournalLine."Document Type"::Payment, -Amount, Prepayment);

        // Exercise: Apply and Unapply Posted General Lines for Vendor Ledger Entry,
        // change Posting Date when Unapply.
        ApplyVendorInvoiceToPayment(InvoiceNo, GenJournalLine."Document No.");
        PaymentNo := GenJournalLine."Document No.";
    end;

    local procedure CreateAndPostGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; Amount: Decimal; Prepayment: Boolean) InvoiceNo: Code[20]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Create Vendor, General Journal Line for 1 Invoice and 1 Payment
        CreateGenJournalBatch(GenJournalBatch);
        CreateGenJnlLine(
          GenJournalLine, GenJournalBatch, VendorNo, DocumentType, Amount, false);
        InvoiceNo := GenJournalLine."Document No.";
        CreateGenJnlLine(
          GenJournalLine, GenJournalBatch, VendorNo, DocumentType2, -GenJournalLine.Amount, Prepayment);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure UnapplyVendLedgerEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; PostingDateFrom: Date): Decimal
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        ApplyUnapplyParameters: Record "Apply Unapply Parameters";
        VendEntryApplyPostedEntries: Codeunit "VendEntry-Apply Posted Entries";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, DocumentNo);
        DtldVendLedgEntry.SetRange("Entry Type", DtldVendLedgEntry."Entry Type"::Application);
        DtldVendLedgEntry.SetRange("Vendor No.", VendorLedgerEntry."Vendor No.");
        DtldVendLedgEntry.SetRange("Document No.", VendorLedgerEntry."Document No.");
        DtldVendLedgEntry.FindFirst();
        ApplyUnapplyParameters."Document No." := DtldVendLedgEntry."Document No.";
        ApplyUnapplyParameters."Posting Date" := PostingDateFrom;
        VendEntryApplyPostedEntries.PostUnApplyVendor(DtldVendLedgEntry, ApplyUnapplyParameters);
        exit(-DtldVendLedgEntry.Amount);
    end;

    local procedure CreateGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal; Prepayment: Boolean)
    begin
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::Vendor, VendorNo,
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
          Amount);
        GenJournalLine.Validate(Prepayment, Prepayment);
        GenJournalLine.Modify();
    end;

    local procedure SetAllowPostingFrom(AllowPostingFrom: Date) OldAllowPostingFrom: Date
    var
        GenLedgSetup: Record "General Ledger Setup";
    begin
        GenLedgSetup.Get();
        OldAllowPostingFrom := GenLedgSetup."Allow Posting From";
        GenLedgSetup."Allow Posting From" := AllowPostingFrom;
        GenLedgSetup.Modify(true);
    end;

    local procedure FindDetailedVendLedgerEntry(var DetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; EntryType: Enum "Detailed CV Ledger Entry Type")
    begin
        DetailedVendLedgEntry.SetRange("Entry Type", EntryType);
        DetailedVendLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedVendLedgEntry.SetRange("Document Type", DocumentType);
        DetailedVendLedgEntry.FindSet();
    end;

    local procedure FindPrepaymentAcc(VendorNo: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        Vendor.Get(VendorNo);
        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        exit(VendorPostingGroup."Prepayment Account");
    end;

    local procedure VerifyUnappliedDtldLedgEntry(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    var
        DetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        FindDetailedVendLedgerEntry(DetailedVendLedgEntry, DocumentNo, DocumentType, DetailedVendLedgEntry."Entry Type"::Application);
        repeat
            Assert.IsTrue(
              DetailedVendLedgEntry.Unapplied, StrSubstNo(UnappliedErr, DetailedVendLedgEntry.TableCaption()));
        until DetailedVendLedgEntry.Next() = 0;
    end;

    local procedure VerifyUnappliedGLEntries(SourceNo: Code[20]; GLAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        GLEntry.SetRange("G/L Account No.", FindPrepaymentAcc(SourceNo));
        GLEntry.SetRange("Source No.", SourceNo);
        GLEntry.SetRange("Source Code", SourceCodeSetup."Unapplied Purch. Entry Appln.");
        GLEntry.FindFirst();
        Assert.AreEqual(GLEntry.Amount, GLAmount, WrongVendBackPrepaymentErr);
    end;
}

