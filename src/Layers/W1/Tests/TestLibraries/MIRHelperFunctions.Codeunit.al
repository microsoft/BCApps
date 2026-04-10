codeunit 132477 "MIR - Helper Functions"
{

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";

    [Scope('OnPrem')]
    procedure CreateFinChrgInterestRates(FinanceChargeTerms: Record "Finance Charge Terms"; StartDate: Date; InterestRate: Integer; InterestDays: Integer)
    var
        FinanceChargeInterestRate: Record "Finance Charge Interest Rate";
    begin
        // Create a new Finance Charge Term Interest Rate for the Finance Charge Term.
        FinanceChargeInterestRate.Init();
        FinanceChargeInterestRate.Validate("Fin. Charge Terms Code", FinanceChargeTerms.Code);
        FinanceChargeInterestRate.Validate("Start Date", StartDate);
        FinanceChargeInterestRate.Insert(true);
        FinanceChargeInterestRate.Validate("Interest Rate", InterestRate);
        FinanceChargeInterestRate.Validate("Interest Period (Days)", InterestDays);
        FinanceChargeInterestRate.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure UpdateFinChargeTermsOnCustomer(FinanceChargeTermsCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        // Create a Customer and attach the Finance Charge Term to it.
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Fin. Charge Terms Code", FinanceChargeTermsCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    [Scope('OnPrem')]
    procedure CreateFinanceChargeMemo(var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; CustomerNo: Code[20]; DocumentDate: Date)
    begin
        LibraryERM.CreateFinanceChargeMemoHeader(FinanceChargeMemoHeader, CustomerNo);
        FinanceChargeMemoHeader.Validate("Posting Date", CalcDate('<1D>', DocumentDate));
        FinanceChargeMemoHeader.Validate("Document Date", DocumentDate);
        FinanceChargeMemoHeader.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure SuggestFinChargeMemoLines(FinanceChargeMemoHeader: Record "Finance Charge Memo Header")
    var
        SuggestFinChargeMemoLinesRep: Report "Suggest Fin. Charge Memo Lines";
    begin
        // Run Report Suggest Fin. Charge Memo Lines to suggest Finance Charge Memo Lines.
        FinanceChargeMemoHeader.SetRange("No.", FinanceChargeMemoHeader."No.");
        SuggestFinChargeMemoLinesRep.SetTableView(FinanceChargeMemoHeader);
        SuggestFinChargeMemoLinesRep.UseRequestPage(false);
        SuggestFinChargeMemoLinesRep.Run();
    end;

    [Scope('OnPrem')]
    procedure VerifyIntAmtOnFinChargeMemo(FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; SalesHeader: Record "Sales Header")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        FinanceChargeInterestRate: Record "Finance Charge Interest Rate";
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
        SecondFinanceChargeMemoLine: Record "Finance Charge Memo Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        InterestAmount: Decimal;
        TotalInterestAmountOnHeader: Decimal;
        DaysOverdue: Integer;
        DueDateOnFinChrgLines: Date;
    begin
        // Verify the Finance Charge Interest Amount on Finance Charge Memo Lines.

        // Use Invoice Rounding Precision from General Ledger Setup.
        GeneralLedgerSetup.Get();
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", FinanceChargeMemoHeader."Customer No.");
        SalesInvoiceHeader.SetRange("Pre-Assigned No.", SalesHeader."No.");
        SalesInvoiceHeader.FindFirst();

        SalesInvoiceLine.SetRange("Sell-to Customer No.", FinanceChargeMemoHeader."Customer No.");
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.FindFirst();

        FinanceChargeInterestRate.SetRange("Fin. Charge Terms Code", FinanceChargeMemoHeader."Fin. Charge Terms Code");
        FinanceChargeInterestRate.FindSet();

        // Create First instance of Finance Charge Memo Line to validate Remaining Amount, Posting Date and Due Dates.
        FinanceChargeMemoLine.SetRange("Finance Charge Memo No.", FinanceChargeMemoHeader."No.");
        FinanceChargeMemoLine.SetRange("Detailed Interest Rates Entry", true);
        FinanceChargeMemoLine.FindSet();

        // Creating another instance of Finance Charge Memo Line to store the values of first instance and then use them to calculate
        // the differences between Due Dates.
        SecondFinanceChargeMemoLine.SetRange("Finance Charge Memo No.", FinanceChargeMemoHeader."No.");
        SecondFinanceChargeMemoLine.SetRange("Detailed Interest Rates Entry", true);
        SecondFinanceChargeMemoLine.FindSet();

        // Validate Remaining Amount, Posting Date and Due Date on Finance Charge Memo Lines.
        repeat
            DueDateOnFinChrgLines := CalcDate('<1D>', SalesHeader."Due Date");
            if FinanceChargeInterestRate."Start Date" > DueDateOnFinChrgLines then
                DueDateOnFinChrgLines := FinanceChargeInterestRate."Start Date";
            FinanceChargeMemoLine.TestField("Due Date", DueDateOnFinChrgLines);
            CustLedgerEntry.Get(FinanceChargeMemoLine."Entry No.");
            CustLedgerEntry.CalcFields("Remaining Amount");
            FinanceChargeMemoLine.TestField("Remaining Amount", CustLedgerEntry."Remaining Amount");
            FinanceChargeMemoLine.TestField("Posting Date", SalesHeader."Posting Date");
            if SecondFinanceChargeMemoLine.Next() <> 0 then
                DaysOverdue := SecondFinanceChargeMemoLine."Due Date" - FinanceChargeMemoLine."Due Date"
            else
                DaysOverdue := (FinanceChargeMemoHeader."Document Date" - FinanceChargeMemoLine."Due Date") + 1;

            // Formula to calculate the Interest Amounts on Lines.
            InterestAmount := Round(
                FinanceChargeMemoLine."Remaining Amount" * (DaysOverdue / FinanceChargeInterestRate."Interest Period (Days)") *
                (FinanceChargeMemoLine."Interest Rate" / 100), GeneralLedgerSetup."Amount Rounding Precision");

            // Validate Interest Amount and Posting Date on Finance Charge Memo Lines.
            FinanceChargeMemoLine.TestField(Amount, InterestAmount);
            FinanceChargeInterestRate.Next();
            TotalInterestAmountOnHeader += InterestAmount;
        until FinanceChargeMemoLine.Next() = 0;

        // Validate Total Interest Amount, Posting Date, Due Date and Remaining Amount on Finance Charge Memo Lines for Header Line.
        FinanceChargeMemoLine.Reset();
        FinanceChargeMemoLine.SetRange("Finance Charge Memo No.", FinanceChargeMemoHeader."No.");
        FinanceChargeMemoLine.SetRange(Type, FinanceChargeMemoLine.Type::"Customer Ledger Entry");
        FinanceChargeMemoLine.FindFirst();
        CustLedgerEntry.Get(FinanceChargeMemoLine."Entry No.");
        CustLedgerEntry.CalcFields("Remaining Amount");

        // Validate Total Interest Amount, Posting Date, Due Date and Remaining Amount.
        FinanceChargeMemoLine.TestField(Amount, TotalInterestAmountOnHeader);
        FinanceChargeMemoLine.TestField("Remaining Amount", CustLedgerEntry."Remaining Amount");
        FinanceChargeMemoLine.TestField("Posting Date", SalesHeader."Posting Date");
        FinanceChargeMemoLine.TestField("Due Date", SalesHeader."Due Date");
    end;

    [Scope('OnPrem')]
    procedure CreateFinanceChargeInterestRate(var FinanceChargeInterestRate: Record "Finance Charge Interest Rate"; FinChargeTermsCode: Code[10]; StartDate: Date)
    begin
        FinanceChargeInterestRate.Init();
        FinanceChargeInterestRate.Validate("Fin. Charge Terms Code", FinChargeTermsCode);
        FinanceChargeInterestRate.Validate("Start Date", StartDate);
        FinanceChargeInterestRate.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateAndPostSalesInvoiceBySalesJournal(CustomerNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Sales);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGLAccount(GLAccount);

        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, CustomerNo, 50 * LibraryRandom.RandDec(100, 2));  // Multiplying Amount by 50 to have more amount than minimum amount on Finance Charge Term.
        GenJournalLine.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;
}

