codeunit 144024 "Exch. Rate Adjmt. VAT Sales"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        EntryDoesNotExist: Label 'Cannot find entry in table %1 with filters %2.';

    local procedure UpdateGLSetup(NewSummarizeGainsLosses: Boolean)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup.Validate("Enable Russian Accounting", true);
        GLSetup.Validate("Summarize Gains/Losses", NewSummarizeGainsLosses);
        GLSetup.Validate("Currency Adjmt with Correction", false);
        GLSetup.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RealizedGainApply()
    begin
        // Pass TRUE for Raise Exch. Rate, FALSE for Unapply, FALSE for Summarize Gains/Losses
        SetupPostGainLossEntries(true, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RealiedGainUnapply()
    begin
        SetupPostGainLossEntries(true, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RealizedLossApply()
    begin
        SetupPostGainLossEntries(false, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RealizedLossUnapply()
    begin
        SetupPostGainLossEntries(false, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RealizedGainApplySumm()
    begin
        SetupPostGainLossEntries(true, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RealizedGainUnapplySumm()
    begin
        SetupPostGainLossEntries(true, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RealizedLossApplySumm()
    begin
        SetupPostGainLossEntries(false, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RealizedLossUnapplySumm()
    begin
        SetupPostGainLossEntries(false, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RealizedGainApplySummDiffAcc()
    begin
        // Pass TRUE for Raise Exch. Rate, FALSE for Unapply
        SetupPostGainLossEntriesDiffAc(true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RealizedGainUnapplySummDiffAcc()
    begin
        SetupPostGainLossEntriesDiffAc(true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RealizedLossApplySummDiffAcc()
    begin
        SetupPostGainLossEntriesDiffAc(false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RealizedLossUnapplySummDiffAcc()
    begin
        SetupPostGainLossEntriesDiffAc(false, true);
    end;

    local procedure SetupPostGainLossEntries(IsRaise: Boolean; IsUnapply: Boolean; IsSummarizeGainsLosses: Boolean)
    var
        PostingDate: Date;
        CurrencyCode: Code[10];
        ExchRateAmount: array[3] of Decimal;
    begin
        // Check that Summarize Gain/Loss option works correctly in case of the same accounts for gain/losses
        UpdateGLSetup(IsSummarizeGainsLosses);
        SetupExchRateAmount(ExchRateAmount, IsRaise);
        PostingDate := WorkDate();
        CurrencyCode := CreateCurrencyWithExchRates(PostingDate, ExchRateAmount, false);

        PostGainLossEntries(PostingDate, CurrencyCode, IsRaise, IsUnapply, IsSummarizeGainsLosses);
    end;

    local procedure SetupPostGainLossEntriesDiffAc(IsRaise: Boolean; IsUnapply: Boolean)
    var
        PostingDate: Date;
        CurrencyCode: Code[10];
        ExchRateAmount: array[3] of Decimal;
    begin
        // Check that Summarize Gain/Loss option does not work in case of different accounts for real/unreal gain/losses
        UpdateGLSetup(true);
        SetupExchRateAmount(ExchRateAmount, IsRaise);
        PostingDate := WorkDate();
        CurrencyCode := CreateCurrencyWithExchRates(PostingDate, ExchRateAmount, true);

        PostGainLossEntries(PostingDate, CurrencyCode, IsRaise, IsUnapply, false);
    end;

    local procedure PostGainLossEntries(PostingDate: Date; CurrencyCode: Code[10]; IsRaise: Boolean; IsUnapply: Boolean; IsSummarizeGainsLosses: Boolean)
    var
        SalesLine: Record "Sales Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustNo: Code[20];
        InvNo: array[2] of Code[20];
        PmtNo: Code[20];
        PmtAmount: Decimal;
        i: Integer;
    begin
        CustNo := LibrarySales.CreateCustomerNo();
        for i := 1 to ArrayLen(InvNo) do begin
            InvNo[i] := CreatePostInvoice(SalesLine, CustNo, PostingDate, CurrencyCode);
            PmtAmount += SalesLine."Amount Including VAT";
            PostingDate := CalcDate('<1M>', PostingDate);
        end;
        PmtNo :=
          CreatePostPayment(PostingDate, SalesLine."Sell-to Customer No.", CurrencyCode, -PmtAmount);
        Commit();
        RunAdjExchRates(CurrencyCode, WorkDate(), GetInvPostingDate(SalesLine."Document No."), SalesLine."Sell-to Customer No.");
        ApplyPaymentToPairedInvoice(PmtNo, InvNo);
        if IsUnapply then begin
            UnapplyLedgerEntries(CustLedgEntry."Document Type"::Payment, PmtNo);
            // All unapplied entries goes with pmt. doc. no.
            for i := 1 to ArrayLen(InvNo) do
                InvNo[i] := PmtNo;
        end;
        VerifyGainLossAppEntries(InvNo, IsRaise, IsSummarizeGainsLosses, CurrencyCode);
    end;

    local procedure SetupExchRateAmount(var ExchRateAmount: array[3] of Decimal; IsRaise: Boolean)
    var
        GLSetup: Record "General Ledger Setup";
        Factor: Decimal;
    begin
        GLSetup.Get();
        ExchRateAmount[1] := 1 + LibraryRandom.RandDec(10, 2);
        if IsRaise then
            Factor := 1.3
        else
            Factor := 0.7;
        ExchRateAmount[2] :=
          Round(ExchRateAmount[1] * Factor, GLSetup."Amount Rounding Precision");
        ExchRateAmount[3] := ExchRateAmount[1];
    end;

    local procedure CreateCurrencyWithExchRates(StartingDate: Date; ExchRateAmount: array[3] of Decimal; IsDiffAccounts: Boolean) CurrencyCode: Code[10]
    var
        i: Integer;
    begin
        CurrencyCode := CreateCurrency(IsDiffAccounts);
        for i := 1 to ArrayLen(ExchRateAmount) do begin
            CreateCurrExchRates(CurrencyCode, StartingDate, ExchRateAmount[i]);
            StartingDate := CalcDate('<1M>', StartingDate);
        end;
        exit(CurrencyCode);
    end;

    local procedure CreateCurrency(IsDiffAccounts: Boolean): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Unrealized Gains Acc.", LibraryERM.CreateGLAccountNo());
        Currency.Validate("Unrealized Losses Acc.", LibraryERM.CreateGLAccountNo());
        if IsDiffAccounts then begin
            Currency.Validate("Realized Gains Acc.", LibraryERM.CreateGLAccountNo());
            Currency.Validate("Realized Losses Acc.", LibraryERM.CreateGLAccountNo());
        end else begin
            Currency.Validate("Realized Gains Acc.", Currency."Unrealized Gains Acc.");
            Currency.Validate("Realized Losses Acc.", Currency."Unrealized Losses Acc.");
        end;
        Currency.Validate("Sales PD Gains Acc. (TA)", LibraryERM.CreateGLAccountNo());
        Currency.Validate("Sales PD Losses Acc. (TA)", LibraryERM.CreateGLAccountNo());
        Currency.Validate("PD Bal. Gain/Loss Acc. (TA)", LibraryERM.CreateGLAccountNo());
        Currency.Modify(true);
        exit(Currency.Code);
    end;

    local procedure CreateCurrExchRates(CurrencyCode: Code[10]; StartingDate: Date; RelationalAmount: Decimal)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        LibraryERM.CreateExchRate(CurrencyExchangeRate, CurrencyCode, StartingDate);
        CurrencyExchangeRate.Validate("Exchange Rate Amount", 1);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", 1);
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", RelationalAmount);
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", RelationalAmount);
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure CreatePostInvoice(var SalesLine: Record "Sales Line"; CustNo: Code[20]; PostingDate: Date; CurrencyCode: Code[10]): Code[20]
    begin
        CreateInvoice(SalesLine, CustNo, PostingDate, CurrencyCode);
        exit(PostInvoice(SalesLine));
    end;

    local procedure CreateInvoice(var SalesLine: Record "Sales Line"; CustNo: Code[20]; PostingDate: Date; CurrencyCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
        AccNo: Code[20];
    begin
        AccNo := LibraryERM.CreateGLAccountWithSalesSetup();
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustNo);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", AccNo, LibraryRandom.RandInt(100));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure PostInvoice(SalesLine: Record "Sales Line"): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreatePostPayment(PostingDate: Date; CustNo: Code[20]; CurrencyCode: Code[10]; PmtAmount: Decimal): Code[20]
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        InitGenJnlLine(GenJnlLine);
        LibraryERM.CreateGeneralJnlLine(
          GenJnlLine, GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name", GenJnlLine."Document Type"::Payment, GenJnlLine."Account Type"::Customer, CustNo, PmtAmount);
        GenJnlLine.Validate("Posting Date", PostingDate);
        GenJnlLine.Validate("Currency Code", CurrencyCode);
        GenJnlLine.Validate(Amount, PmtAmount);
        GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::"G/L Account");
        GenJnlLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJnlLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
        exit(GenJnlLine."Document No.");
    end;

    local procedure InitGenJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        GenJnlTemplate.SetRange(Type, GenJnlTemplate.Type::General);
        LibraryERM.FindGenJournalTemplate(GenJnlTemplate);
        GenJnlBatch.SetRange(Recurring, false);
        LibraryERM.FindGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);
        LibraryERM.ClearGenJournalLines(GenJnlBatch);
        GenJnlLine.Init();
        GenJnlLine."Journal Template Name" := GenJnlBatch."Journal Template Name";
        GenJnlLine."Journal Batch Name" := GenJnlBatch.Name;
    end;

    local procedure ApplyPaymentToPairedInvoice(PmtNo: Code[20]; InvNo: array[2] of Code[20])
    var
        CustLedgerEntryFrom: Record "Cust. Ledger Entry";
        CustLedgerEntryTo: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntryFrom, CustLedgerEntryFrom."Document Type"::Payment, PmtNo);
        CustLedgerEntryFrom.CalcFields("Remaining Amount");
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntryFrom, CustLedgerEntryFrom."Remaining Amount");

        CustLedgerEntryTo.SetRange("Document Type", CustLedgerEntryTo."Document Type"::Invoice);
        CustLedgerEntryTo.SetFilter("Document No.", '%1|%2', InvNo[1], InvNo[2]);
        CustLedgerEntryTo.FindSet();
        repeat
            CustLedgerEntryTo.CalcFields("Remaining Amount");
            CustLedgerEntryTo.Validate("Amount to Apply", CustLedgerEntryTo."Remaining Amount");
            CustLedgerEntryTo.Modify(true);
        until CustLedgerEntryTo.Next() = 0;

        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntryTo);
        LibraryERM.PostCustLedgerApplication(CustLedgerEntryFrom);
    end;

    local procedure UnapplyLedgerEntries(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20])
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        ApplyUnapplyParameters: Record "Apply Unapply Parameters";
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgEntry, DocType, DocNo);
        DtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgEntry."Entry No.");
        DtldCustLedgEntry.SetRange("Entry Type", DtldCustLedgEntry."Entry Type"::Application);
        DtldCustLedgEntry.FindFirst();
        ApplyUnapplyParameters."Document No." := CustLedgEntry."Document No.";
        ApplyUnapplyParameters."Posting Date" := DtldCustLedgEntry."Posting Date";
        CustEntryApplyPostedEntries.PostUnApplyCustomer(DtldCustLedgEntry, ApplyUnapplyParameters);
    end;

    local procedure FindDtldCustLedgEntry(var DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; EntryType: Enum "Detailed CV Ledger Entry Type"; DocNo: Code[20])
    begin
        DtldCustLedgEntry.SetRange("Entry Type", EntryType);
        DtldCustLedgEntry.SetRange("Document Type", DtldCustLedgEntry."Document Type"::Invoice);
        DtldCustLedgEntry.SetRange("Document No.", DocNo);
        DtldCustLedgEntry.FindLast();
    end;

    local procedure GetInvPostingDate(OrderNo: Code[20]): Date
    var
        SalesInvHeader: Record "Sales Invoice Header";
    begin
        SalesInvHeader.SetRange("Pre-Assigned No.", OrderNo);
        SalesInvHeader.FindLast();
        exit(SalesInvHeader."Posting Date");
    end;

    local procedure CalcGainLossParameters(var EntryType: array[2] of Enum "Detailed CV Ledger Entry Type"; var AccNo: array[2] of Code[20]; CurrencyCode: Code[10]; IsRaise: Boolean; IsSummarizeGainsLosses: Boolean)
    var
        Currency: Record Currency;
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        Currency.Get(CurrencyCode);
        if IsRaise then begin
            EntryType[1] := DtldCustLedgEntry."Entry Type"::"Unrealized Gain";
            EntryType[2] := DtldCustLedgEntry."Entry Type"::"Realized Loss";
            if IsSummarizeGainsLosses then
                AccNo[1] := Currency."Realized Losses Acc."
            else
                AccNo[1] := Currency."Unrealized Gains Acc.";
            AccNo[2] := Currency."Realized Losses Acc.";
        end else begin
            EntryType[1] := DtldCustLedgEntry."Entry Type"::"Unrealized Loss";
            EntryType[2] := DtldCustLedgEntry."Entry Type"::"Realized Gain";
            if IsSummarizeGainsLosses then
                AccNo[1] := Currency."Realized Gains Acc."
            else
                AccNo[1] := Currency."Unrealized Losses Acc.";
            AccNo[2] := Currency."Realized Gains Acc.";
        end;
    end;

    local procedure RunAdjExchRates(CurrencyCode: Code[10]; StartDate: Date; EndDate: Date; CustNo: Code[20])
    var
        Currency: Record Currency;
        Customer: Record Customer;
        ExchRateAdjustment: Report "Exch. Rate Adjustment";
    begin
        Currency.SetRange(Code, CurrencyCode);
        Customer.SetRange("No.", CustNo);
        ExchRateAdjustment.SetTableView(Currency);
        ExchRateAdjustment.SetTableView(Customer);
        ExchRateAdjustment.InitializeRequest2(StartDate, EndDate, '', EndDate, LibraryUtility.GenerateGUID(), true, false);
        ExchRateAdjustment.UseRequestPage(false);
        ExchRateAdjustment.SetHideUI(true);
        ExchRateAdjustment.Run();
    end;

    local procedure VerifyGainLossAppEntries(InvNo: array[2] of Code[20]; IsRaise: Boolean; IsSummarizeGainsLosses: Boolean; CurrencyCode: Code[10])
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GLEntry: Record "G/L Entry";
        EntryType: array[2] of Enum "Detailed CV Ledger Entry Type";
        AccNo: array[2] of Code[20];
        i: Integer;
    begin
        CalcGainLossParameters(EntryType, AccNo, CurrencyCode, IsRaise, IsSummarizeGainsLosses);
        for i := 1 to ArrayLen(InvNo) do begin
            FindDtldCustLedgEntry(DtldCustLedgEntry, EntryType[i], InvNo[i]);
            GLEntry.SetRange("G/L Account No.", AccNo[i]);
            GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
            GLEntry.SetRange("Document No.", DtldCustLedgEntry."Document No.");
            GLEntry.SetRange("Transaction No.", DtldCustLedgEntry."Transaction No.");
            Assert.IsTrue(
              GLEntry.FindLast(), StrSubstNo(EntryDoesNotExist, GLEntry.TableCaption(), GLEntry.GetFilters));
        end;
    end;
}

