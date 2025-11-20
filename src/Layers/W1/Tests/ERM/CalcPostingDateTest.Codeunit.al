codeunit 134254 "Calc. Posting Date Test"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Suggest Vendor Payments] [Posting Date]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;
        PaymentWarningMsg: Label 'This posting date will cause an overdue payment.';
        ReplacePostDateMsg: Label 'For one or more entries, the requested posting date is before the work date.';
        PmtDiscUnavailableErr: Label 'You cannot use Summarize per Vendor together with Calculate Posting Date from Applies-to-Doc. Due Date, because the resulting posting date might not match the due date.';

    local procedure Initialize()
    var
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Calc. Posting Date Test");
        LibraryApplicationArea.EnableFoundationSetup();
        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Calc. Posting Date Test");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Calc. Posting Date Test");
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SuggVendFutureDueDatePostingDateBeforeDueDate()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        DueDateOffset: Integer;
    begin
        Initialize();

        // Setup.
        LibraryPurchase.CreateVendor(Vendor);
        PostVendorInvoice(Vendor."No.", LibraryRandom.RandIntInRange(5, 10), 0);
        FindLastInvoice(VendorLedgerEntry, Vendor."No.");
        LibraryPurchase.SelectPmtJnlBatch(GenJnlBatch);

        // Exercise.
        DueDateOffset := -LibraryRandom.RandIntInRange(1, VendorLedgerEntry."Due Date" - WorkDate());
        SuggestVendorPayments(GenJnlLine, GenJnlBatch, VendorLedgerEntry."Due Date", false, false, true, Format(DueDateOffset) + 'D',
          Vendor."No.");

        // Verify.
        VerifyGenJnlLine(GenJnlBatch, Vendor."No.", VendorLedgerEntry."Due Date" - Abs(DueDateOffset), '', '',
          -VendorLedgerEntry."Purchase (LCY)");
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SuggVendFutureDueDateOverduePostingDate()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        DueDateOffset: Integer;
    begin
        Initialize();

        // Setup.
        LibraryPurchase.CreateVendor(Vendor);
        PostVendorInvoice(Vendor."No.", LibraryRandom.RandIntInRange(5, 10), 0);
        FindLastInvoice(VendorLedgerEntry, Vendor."No.");
        LibraryPurchase.SelectPmtJnlBatch(GenJnlBatch);

        // Exercise.
        DueDateOffset := LibraryRandom.RandInt(10);
        SuggestVendorPayments(GenJnlLine, GenJnlBatch, VendorLedgerEntry."Due Date", false, false, true, Format(DueDateOffset) + 'D',
          Vendor."No.");

        // Verify.
        VerifyGenJnlLine(GenJnlBatch, Vendor."No.", VendorLedgerEntry."Due Date" + DueDateOffset, 'Unfavorable', PaymentWarningMsg,
          -VendorLedgerEntry."Purchase (LCY)");
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure SuggVendFutureDueDatePostingDateBeforeWorkDate()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        DueDateOffset: Integer;
    begin
        Initialize();

        // Setup.
        LibraryPurchase.CreateVendor(Vendor);
        PostVendorInvoice(Vendor."No.", LibraryRandom.RandIntInRange(5, 10), 0);
        FindLastInvoice(VendorLedgerEntry, Vendor."No.");
        LibraryPurchase.SelectPmtJnlBatch(GenJnlBatch);

        // Exercise.
        DueDateOffset := -(VendorLedgerEntry."Due Date" - WorkDate() + LibraryRandom.RandIntInRange(2, 10));
        SuggestVendorPayments(GenJnlLine, GenJnlBatch, VendorLedgerEntry."Due Date", false, false, true, Format(DueDateOffset) + 'D',
          Vendor."No.");

        // Verify.
        VerifyGenJnlLine(GenJnlBatch, Vendor."No.", WorkDate(), '', '', -VendorLedgerEntry."Purchase (LCY)");
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SuggVendPastDueDateFuturePostingDate()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        DueDateOffset: Integer;
    begin
        Initialize();

        // Setup.
        LibraryPurchase.CreateVendor(Vendor);
        PostVendorInvoice(Vendor."No.", -LibraryRandom.RandIntInRange(5, 10), 0);
        FindLastInvoice(VendorLedgerEntry, Vendor."No.");
        LibraryPurchase.SelectPmtJnlBatch(GenJnlBatch);

        // Exercise.
        DueDateOffset := WorkDate() - VendorLedgerEntry."Due Date" + LibraryRandom.RandIntInRange(1, 10);
        SuggestVendorPayments(GenJnlLine, GenJnlBatch, VendorLedgerEntry."Due Date", false, false, true, Format(DueDateOffset) + 'D',
          Vendor."No.");

        // Verify.
        VerifyGenJnlLine(GenJnlBatch, Vendor."No.", VendorLedgerEntry."Due Date" + Abs(DueDateOffset), 'Unfavorable', PaymentWarningMsg,
          -VendorLedgerEntry."Purchase (LCY)");
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure SuggVendPastDueDatePostingDateBeforeWorkDate()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        DueDateOffset: Integer;
    begin
        Initialize();

        // Setup.
        LibraryPurchase.CreateVendor(Vendor);
        PostVendorInvoice(Vendor."No.", -LibraryRandom.RandIntInRange(5, 10), 0);
        FindLastInvoice(VendorLedgerEntry, Vendor."No.");
        LibraryPurchase.SelectPmtJnlBatch(GenJnlBatch);

        // Exercise.
        DueDateOffset := LibraryRandom.RandInt(WorkDate() - VendorLedgerEntry."Due Date");
        SuggestVendorPayments(GenJnlLine, GenJnlBatch, VendorLedgerEntry."Due Date", false, false, true, Format(DueDateOffset) + 'D',
          Vendor."No.");

        // Verify.
        VerifyGenJnlLine(GenJnlBatch, Vendor."No.", WorkDate(), 'Unfavorable', PaymentWarningMsg, -VendorLedgerEntry."Purchase (LCY)");
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure SuggVendPastDueDatePostingDateBeforeDueDate()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        DueDateOffset: Integer;
    begin
        Initialize();

        // Setup.
        LibraryPurchase.CreateVendor(Vendor);
        PostVendorInvoice(Vendor."No.", -LibraryRandom.RandIntInRange(5, 10), 0);
        FindLastInvoice(VendorLedgerEntry, Vendor."No.");
        LibraryPurchase.SelectPmtJnlBatch(GenJnlBatch);

        // Exercise.
        DueDateOffset := -LibraryRandom.RandInt(10);
        SuggestVendorPayments(GenJnlLine, GenJnlBatch, VendorLedgerEntry."Due Date", false, false, true, Format(DueDateOffset) + 'D',
          Vendor."No.");

        // Verify.
        VerifyGenJnlLine(GenJnlBatch, Vendor."No.", WorkDate(), 'Unfavorable', PaymentWarningMsg, -VendorLedgerEntry."Purchase (LCY)");
    end;

    local procedure SuggVendMultipleMixedDates(DueDateRange: Integer; DueDateOffset: Integer; DiscDateOffset: Integer)
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        Initialize();

        // Setup.
        LibraryPurchase.CreateVendor(Vendor);
        PostVendorInvoice(Vendor."No.", DueDateRange, DiscDateOffset);
        PostVendorInvoice(Vendor."No.", -DueDateRange, DiscDateOffset);
        PostVendorInvoice(Vendor."No.", 0, DiscDateOffset);
        FindLastInvoice(VendorLedgerEntry, Vendor."No.");
        LibraryPurchase.SelectPmtJnlBatch(GenJnlBatch);

        // Exercise.
        SuggestVendorPayments(GenJnlLine, GenJnlBatch, VendorLedgerEntry."Due Date", false, false, true, Format(DueDateOffset) + 'D',
          Vendor."No.");

        // Verify.
        VerifyMultipleGenJnlLines(GenJnlBatch, Vendor."No.", DueDateOffset, 3);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure SuggVendFutureMultipleMixedDatesLessThanDueDateRange()
    var
        DueDateOffset: Integer;
        DueDateRange: Integer;
    begin
        DueDateRange := LibraryRandom.RandIntInRange(5, 10);
        DueDateOffset := LibraryRandom.RandIntInRange(1, DueDateRange - 1);
        SuggVendMultipleMixedDates(DueDateRange, DueDateOffset, 0);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SuggVendFutureMultipleMixedDatesMoreThanDueDateRange()
    var
        DueDateOffset: Integer;
        DueDateRange: Integer;
    begin
        DueDateRange := LibraryRandom.RandIntInRange(5, 10);
        DueDateOffset := DueDateRange + LibraryRandom.RandInt(10);
        SuggVendMultipleMixedDates(DueDateRange, DueDateOffset, 0);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure SuggVendPastMultipleMixedDatesLessThanDueDateRange()
    var
        DueDateOffset: Integer;
        DueDateRange: Integer;
    begin
        DueDateRange := LibraryRandom.RandIntInRange(5, 10);
        DueDateOffset := -LibraryRandom.RandIntInRange(1, DueDateRange - 1);
        SuggVendMultipleMixedDates(DueDateRange, DueDateOffset, 0);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure SuggVendPastMultipleMixedDatesMoreThanDueDateRange()
    var
        DueDateOffset: Integer;
        DueDateRange: Integer;
    begin
        DueDateRange := LibraryRandom.RandIntInRange(5, 10);
        DueDateOffset := -DueDateRange - LibraryRandom.RandInt(10);
        SuggVendMultipleMixedDates(DueDateRange, DueDateOffset, 0);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure SuggVendFuturePostDatePastDiscDate()
    var
        DueDateOffset: Integer;
        DueDateRange: Integer;
        DiscDateOffset: Integer;
    begin
        DueDateRange := LibraryRandom.RandIntInRange(5, 10);
        DueDateOffset := LibraryRandom.RandIntInRange(1, DueDateRange - 1);
        DiscDateOffset := LibraryRandom.RandIntInRange(1, DueDateRange - 1);
        SuggVendMultipleMixedDates(DueDateRange, DueDateOffset, DiscDateOffset);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure SuggVendPastPostDateDiscountPossible()
    var
        DueDateOffset: Integer;
        DueDateRange: Integer;
        DiscDateOffset: Integer;
    begin
        DueDateRange := LibraryRandom.RandIntInRange(5, 10);
        DueDateOffset := -LibraryRandom.RandIntInRange(3, DueDateRange - 1);
        DiscDateOffset := LibraryRandom.RandIntInRange(1, Abs(DueDateOffset) - 1);
        SuggVendMultipleMixedDates(DueDateRange, DueDateOffset, DiscDateOffset);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SuggVendSummarizePerVendErrorMsg()
    var
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        Initialize();

        // Setup.
        LibraryPurchase.SelectPmtJnlBatch(GenJnlBatch);

        // Exercise.
        asserterror SuggestVendorPayments(GenJnlLine, GenJnlBatch, WorkDate(), false, true, true, '0D', '');

        // Verify.
        Assert.ExpectedError(PmtDiscUnavailableErr);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SuggVendLegacyPostingDate()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        Initialize();

        // Setup.
        LibraryPurchase.CreateVendor(Vendor);
        PostVendorInvoice(Vendor."No.", LibraryRandom.RandIntInRange(5, 10), 0);
        FindLastInvoice(VendorLedgerEntry, Vendor."No.");
        LibraryPurchase.SelectPmtJnlBatch(GenJnlBatch);

        // Exercise.
        SuggestVendorPayments(GenJnlLine, GenJnlBatch, VendorLedgerEntry."Due Date", false, false, false, '0D', Vendor."No.");

        // Verify.
        VerifyGenJnlLine(GenJnlBatch, Vendor."No.", WorkDate(), '', '', -VendorLedgerEntry."Purchase (LCY)");
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler,ConfirmHandler,ModalPageHandler')]
    [Scope('OnPrem')]
    procedure SuggVendPostDateBeforeInvoiceDateExcluded()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry1: Record "Vendor Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        WorkDateOffset: Integer;
    begin
        Initialize();

        // Setup.
        LibraryPurchase.CreateVendor(Vendor);
        PostVendorInvoice(Vendor."No.", 0, 0);
        FindLastInvoice(VendorLedgerEntry, Vendor."No.");
        PostVendorInvoice(Vendor."No.", LibraryRandom.RandInt(10), 0);
        FindLastInvoice(VendorLedgerEntry1, Vendor."No.");
        LibraryPurchase.SelectPmtJnlBatch(GenJnlBatch);

        // Exercise.
        WorkDateOffset := -LibraryRandom.RandInt(10);
        WorkDate(WorkDate() + WorkDateOffset);
        SuggestVendorPayments(GenJnlLine, GenJnlBatch, VendorLedgerEntry1."Due Date", false, false, true, '-1D',
          Vendor."No.");

        // Verify.
        VerifyMultipleGenJnlLines(GenJnlBatch, Vendor."No.", -1, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtJnlMultipleMixedDates()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry1: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
        VendorLedgerEntry3: Record "Vendor Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        DueDateRange: Integer;
    begin
        Initialize();

        // Setup.
        LibraryPurchase.CreateVendor(Vendor);
        DueDateRange := LibraryRandom.RandInt(10);
        PostVendorInvoice(Vendor."No.", -DueDateRange, 0);
        FindLastInvoice(VendorLedgerEntry1, Vendor."No.");
        PostVendorInvoice(Vendor."No.", 0, 0);
        FindLastInvoice(VendorLedgerEntry2, Vendor."No.");
        PostVendorInvoice(Vendor."No.", DueDateRange, 0);
        FindLastInvoice(VendorLedgerEntry3, Vendor."No.");

        LibraryPurchase.SelectPmtJnlBatch(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Payment,
          GenJnlLine."Account Type"::Vendor, Vendor."No.", -VendorLedgerEntry1."Purchase (LCY)");
        ApplyToVendLedgEntry(GenJnlLine, VendorLedgerEntry1);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Payment,
          GenJnlLine."Account Type"::Vendor, Vendor."No.", -VendorLedgerEntry2."Purchase (LCY)");
        ApplyToVendLedgEntry(GenJnlLine, VendorLedgerEntry2);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Payment,
          GenJnlLine."Account Type"::Vendor, Vendor."No.", -VendorLedgerEntry3."Purchase (LCY)");
        ApplyToVendLedgEntry(GenJnlLine, VendorLedgerEntry3);

        // Exercise.
        GenJnlLine.SetRange("Account Type", GenJnlLine."Account Type"::Vendor);
        GenJnlLine.SetRange("Account No.", Vendor."No.");
        GenJnlLine.CalculatePostingDate();

        // Verify.
        VerifyMultipleGenJnlLines(GenJnlBatch, Vendor."No.", 0, 3);
    end;

    local procedure SuggestVendorPayments(var GenJnlLine: Record "Gen. Journal Line"; GenJnlBatch: Record "Gen. Journal Batch"; LastPaymentDate: Date; FindDiscounts: Boolean; SummarizePerVendor: Boolean; UseDueDateAsPostingDate: Boolean; DueDateOffset: Text; VendorNo: Code[20])
    var
        SuggestVendorPayments: Report "Suggest Vendor Payments";
        DueDateOffsetDateFormula: DateFormula;
    begin
        GenJnlLine.Init();
        GenJnlLine.Validate("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.Validate("Journal Batch Name", GenJnlBatch.Name);
        SuggestVendorPayments.SetGenJnlLine(GenJnlLine);

        LibraryVariableStorage.Enqueue(LastPaymentDate);
        LibraryVariableStorage.Enqueue(FindDiscounts);
        LibraryVariableStorage.Enqueue(SummarizePerVendor);
        LibraryVariableStorage.Enqueue(UseDueDateAsPostingDate);
        Evaluate(DueDateOffsetDateFormula, DueDateOffset);
        LibraryVariableStorage.Enqueue(DueDateOffsetDateFormula);
        LibraryVariableStorage.Enqueue(VendorNo);
        Commit();
        SuggestVendorPayments.RunModal();
    end;

    local procedure PostVendorInvoice(VendorNo: Code[20]; DateOffset: Integer; DiscDateOffset: Integer)
    var
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJnlBatch);
        LibraryERM.ClearGenJournalLines(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Invoice,
          GenJnlLine."Account Type"::Vendor, VendorNo, -LibraryRandom.RandDec(1000, 2));
        GenJnlLine.Validate("Posting Date", WorkDate());
        GenJnlLine.Validate("Due Date", WorkDate() + DateOffset);
        if DiscDateOffset <> 0 then begin
            GenJnlLine.Validate("Pmt. Discount Date", GenJnlLine."Due Date" - DiscDateOffset);
            GenJnlLine.Validate("Payment Discount %", LibraryRandom.RandInt(10));
        end;
        GenJnlLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
    end;

    local procedure FindLastInvoice(var VendLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20])
    begin
        VendLedgerEntry.SetCurrentKey("Vendor No.", "Applies-to ID", Open, Positive, "Due Date");
        VendLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendLedgerEntry.SetRange("Document Type", VendLedgerEntry."Document Type"::Invoice);
        VendLedgerEntry.FindLast();
    end;

    local procedure ApplyToVendLedgEntry(var GenJnlLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        GenJnlLine.Validate("Applies-to Doc. Type", VendorLedgerEntry."Document Type");
        GenJnlLine.Validate("Applies-to Doc. No.", VendorLedgerEntry."Document No.");
        GenJnlLine.Modify(true);
    end;

    local procedure VerifyGenJnlLine(GenJnlBatch: Record "Gen. Journal Batch"; VendorNo: Code[20]; ExpPostingDate: Date; ExpStyle: Text; ExpWarning: Text; ExpAmount: Decimal)
    var
        GenJnlLine: Record "Gen. Journal Line";
        ActualStyle: Text;
        ActualWarning: Text;
    begin
        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
        GenJnlLine.SetRange("Account Type", GenJnlLine."Account Type"::Vendor);
        GenJnlLine.SetRange("Account No.", VendorNo);
        GenJnlLine.FindFirst();
        Assert.AreEqual(ExpPostingDate, GenJnlLine."Posting Date", 'Wrong posting date.');
        ActualStyle := GenJnlLine.GetOverdueDateInteractions(ActualWarning);
        Assert.AreEqual(ExpStyle, ActualStyle, 'Wrong style for the record.');
        Assert.AreEqual(ExpWarning, ActualWarning, 'Wrong warning for the record.');
        Assert.AreEqual(ExpAmount, GenJnlLine.Amount, 'Wrong calculated amount');
    end;

    local procedure VerifyMultipleGenJnlLines(GenJnlBatch: Record "Gen. Journal Batch"; VendorNo: Code[20]; DueDateOffset: Integer; ExpPaymentLines: Integer)
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
        GenJnlLine.SetRange("Account Type", GenJnlLine."Account Type"::Vendor);
        GenJnlLine.SetRange("Account No.", VendorNo);

        VendLedgEntry.SetRange("Vendor No.", VendorNo);
        VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::Invoice);
        VendLedgEntry.SetFilter("Applies-to Doc. No.", '<>%1', '');
        Assert.AreEqual(ExpPaymentLines, GenJnlLine.Count, 'Wrong number of payments.');
        if VendLedgEntry.FindSet() then
            repeat
                GenJnlLine.SetRange("Applies-to Doc. No.", VendLedgEntry."Document No.");
                GenJnlLine.FindFirst();
                if VendLedgEntry."Due Date" + DueDateOffset < WorkDate() then
                    Assert.AreEqual(WorkDate(), GenJnlLine."Posting Date", 'Wrong posting date.')
                else
                    Assert.AreEqual(VendLedgEntry."Due Date" + DueDateOffset, GenJnlLine."Posting Date", 'Wrong posting date.');
                if VendLedgEntry."Pmt. Discount Date" >= GenJnlLine."Due Date" then
                    Assert.AreEqual(VendLedgEntry."Purchase (LCY)" - VendLedgEntry."Original Pmt. Disc. Possible", -GenJnlLine."Amount (LCY)",
                      'Wrong calculated discount.')
                else
                    Assert.AreEqual(VendLedgEntry."Purchase (LCY)", -GenJnlLine."Amount (LCY)", 'Wrong calculated amount.');
            until VendLedgEntry.Next() = 0;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MsgHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, ReplacePostDateMsg) > 0, 'Unexpected message');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentsRequestPageHandler(var SuggestVendorPayments: TestRequestPage "Suggest Vendor Payments")
    var
        LastPaymentDate: Variant;
        SummarizePerVendor: Variant;
        VendorNo: Variant;
        FindDiscounts: Variant;
        UseDueDateAsPostDate: Variant;
        DueDateOffset: Variant;
    begin
        LibraryVariableStorage.Dequeue(LastPaymentDate);
        SuggestVendorPayments.LastPaymentDate.SetValue(LastPaymentDate);

        LibraryVariableStorage.Dequeue(FindDiscounts);
        SuggestVendorPayments.FindPaymentDiscounts.SetValue(FindDiscounts);

        LibraryVariableStorage.Dequeue(SummarizePerVendor);
        SuggestVendorPayments.SummarizePerVendor.SetValue(SummarizePerVendor);

        SuggestVendorPayments.PostingDate.SetValue(WorkDate());
        LibraryVariableStorage.Dequeue(UseDueDateAsPostDate);
        SuggestVendorPayments.UseDueDateAsPostingDate.SetValue(UseDueDateAsPostDate);

        LibraryVariableStorage.Dequeue(DueDateOffset);
        SuggestVendorPayments.DueDateOffset.SetValue(DueDateOffset);
        SuggestVendorPayments.BalAccountNo.SetValue('');

        LibraryVariableStorage.Dequeue(VendorNo);
        SuggestVendorPayments.StartingDocumentNo.SetValue(VendorNo);
        SuggestVendorPayments.Vendor.SetFilter("No.", VendorNo);

        SuggestVendorPayments.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalPageHandler(var VendorLedgerEntries: TestPage "Vendor Ledger Entries")
    begin
        VendorLedgerEntries.First();
        Assert.AreEqual(false, VendorLedgerEntries.Next(), 'More entries than expected on the vendor ledger entries page.');
    end;
}

