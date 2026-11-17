// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.PaymentTerms;

using Microsoft.CashFlow.Account;
using Microsoft.CashFlow.Forecast;
using Microsoft.CashFlow.Setup;
using Microsoft.CashFlow.Worksheet;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;

codeunit 134498 "ERM Installment Forecast"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInstallments: Codeunit "Library - ERM Installments";
        LibraryCashFlow: Codeunit "Library - Cash Flow";

    [Test]
    procedure ForecastAndRegistrationRetainSeparateInstallmentObligations()
    var
        Invoice: Record "Sales Invoice Header";
        Forecast: Record "Cash Flow Forecast";
        Line: Record "Cash Flow Worksheet Line";
        ForecastEntry: Record "Cash Flow Forecast Entry";
        Index: Integer;
    begin
        LibraryInstallments.CreatePostedInvoice(Invoice, '', false);
        ConfigureForecast(Forecast);

        for Index := 1 to 2 do begin
            FillForecast(Forecast, Index = 2);

            VerifyOpenInstallments(Forecast, Invoice, 3, 125);
        end;

        FilterInvoiceLines(Line, Forecast, Invoice);
        LibraryCashFlow.PostJournalLines(Line);

        ForecastEntry.SetRange("Cash Flow Forecast No.", Forecast."No.");
        ForecastEntry.SetRange("Source Type", ForecastEntry."Source Type"::Receivables);
        ForecastEntry.SetRange("Document No.", Invoice."No.");
        Assert.AreEqual(3, ForecastEntry.Count(), 'Registration must not merge obligations sharing an invoice number.');
        for Index := 1 to 3 do begin
            ForecastEntry.SetRange("Cash Flow Date", CalcDate(StrSubstNo('<%1D>', Index * 30), Invoice."Document Date"));
            Assert.AreEqual(1, ForecastEntry.Count(), 'Each installment must retain its forecast date after registration.');
        end;
        Forecast.CalcFields("Amount (LCY)");
        Forecast.TestField("Amount (LCY)", 125);
    end;

    [Test]
    procedure ForecastExcludesSettledAndReducesPartlyPaidInstallments()
    var
        Invoice: Record "Sales Invoice Header";
        Forecast: Record "Cash Flow Forecast";
    begin
        LibraryInstallments.CreatePostedInvoice(Invoice, '', false);
        LibraryInstallments.PayInstallment(Invoice."Installment Plan ID", 1, 41.67);
        LibraryInstallments.PayInstallment(Invoice."Installment Plan ID", 3, 10);
        ConfigureForecast(Forecast);

        FillForecast(Forecast, false);

        VerifyOpenInstallments(Forecast, Invoice, 2, 73.33);
        LibraryInstallments.PayInstallment(Invoice."Installment Plan ID", 2, 41.67);
        LibraryInstallments.PayInstallment(Invoice."Installment Plan ID", 3, 31.66);

        FillForecast(Forecast, false);

        VerifyOpenInstallments(Forecast, Invoice, 0, 0);
    end;

    [Test]
    procedure ForecastReflectsSelectedCreditWithoutMirroringCreditSchedule()
    var
        Invoice: Record "Sales Invoice Header";
        Forecast: Record "Cash Flow Forecast";
        Line: Record "Cash Flow Worksheet Line";
        CreditNo: Code[20];
    begin
        LibraryInstallments.CreatePostedInvoice(Invoice, '', false);
        LibraryInstallments.PayInstallment(Invoice."Installment Plan ID", 3, 10);
        CreditNo := LibraryInstallments.CreditInstallment(Invoice, 2, 20, WorkDate());
        ConfigureForecast(Forecast);

        FillForecast(Forecast, false);

        VerifyOpenInstallments(Forecast, Invoice, 3, 95);
        Line.SetRange("Cash Flow Forecast No.", Forecast."No.");
        Line.SetRange("Source Type", Line."Source Type"::Receivables);
        Line.SetRange("Document Type", Line."Document Type"::"Credit Memo");
        Line.SetRange("Document No.", CreditNo);
        Assert.IsTrue(Line.IsEmpty(), 'The fully applied native credit must not be forecast as another obligation.');
    end;

    [Test]
    procedure ForeignCurrencyForecastUsesRemainingLedgerLCYNotCurrentExchangeRate()
    var
        Invoice: Record "Sales Invoice Header";
        Forecast: Record "Cash Flow Forecast";
        Entry: Record "Cust. Ledger Entry";
        CurrencyCode: Code[10];
        RemainingLCY: Decimal;
        Index: Integer;
    begin
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate() - 1, 0.3, 0.3);
        LibraryInstallments.CreatePostedInvoice(Invoice, CurrencyCode, false);
        LibraryInstallments.PayInstallment(Invoice."Installment Plan ID", 1, 10);
        LibraryInstallments.PayInstallment(Invoice."Installment Plan ID", 2, 41.67);
        for Index := 1 to 3 do begin
            LibraryInstallments.GetInstallment(Entry, Invoice."Installment Plan ID", Index);
            Entry.CalcFields("Remaining Amt. (LCY)");
            RemainingLCY += Entry."Remaining Amt. (LCY)";
        end;
        LibraryERM.CreateExchangeRate(CurrencyCode, WorkDate(), 0.6, 0.6);
        ConfigureForecast(Forecast);

        FillForecast(Forecast, false);

        VerifyOpenInstallments(Forecast, Invoice, 2, RemainingLCY);
    end;

    [Test]
    procedure ForecastDiscountsFollowIndividualDatesAndAmounts()
    var
        Invoice: Record "Sales Invoice Header";
        Forecast: Record "Cash Flow Forecast";
        Line: Record "Cash Flow Worksheet Line";
        Entry: Record "Cust. Ledger Entry";
        ExpectedDate: Date;
        ExpectedAmount: Decimal;
        Index: Integer;
    begin
        LibraryInstallments.CreatePostedInvoice(Invoice, '', true);
        ConfigureForecast(Forecast);
        Forecast.Validate("Consider Discount", true);
        Forecast.Modify(true);

        FillForecast(Forecast, false);

        FilterInvoiceLines(Line, Forecast, Invoice);
        Assert.AreEqual(3, Line.Count(), 'Discount forecasting must retain all three obligations.');
        for Index := 1 to 3 do begin
            LibraryInstallments.GetInstallment(Entry, Invoice."Installment Plan ID", Index);
            Entry.CalcFields("Remaining Amt. (LCY)");
            ExpectedDate := Entry."Due Date";
            ExpectedAmount := Entry."Remaining Amt. (LCY)";
            if Entry."Pmt. Discount Date" >= WorkDate() then begin
                ExpectedDate := Entry."Pmt. Discount Date";
                ExpectedAmount -= Entry."Remaining Pmt. Disc. Possible";
            end;
            Line.SetRange("Cash Flow Date", ExpectedDate);
            Assert.AreEqual(1, Line.Count(), 'Forecast discounts must use the selected installment date, not the anchor date.');
            Line.FindFirst();
            Line.TestField("Amount (LCY)", ExpectedAmount);
        end;
        Line.SetRange("Cash Flow Date");
        Line.CalcSums("Amount (LCY)");
        Assert.AreEqual(123.75, Line."Amount (LCY)", 'Only the two eligible installment discounts may reduce forecast receipts.');
    end;

    [Test]
    procedure ForecastPreservesExplicitCustomerPaymentTermOverride()
    var
        Invoice: Record "Sales Invoice Header";
        Forecast: Record "Cash Flow Forecast";
        Line: Record "Cash Flow Worksheet Line";
        Customer: Record Customer;
        Terms: Record "Payment Terms";
        Entry: Record "Cust. Ledger Entry";
        Index: Integer;
    begin
        LibraryInstallments.CreatePostedInvoice(Invoice, '', false);
        LibraryERM.CreatePaymentTerms(Terms);
        Evaluate(Terms."Due Date Calculation", '<45D>');
        Terms.Validate("Discount %", 0);
        Terms.Modify(true);
        Customer.Get(Invoice."Bill-to Customer No.");
        Customer.Validate("Cash Flow Payment Terms Code", Terms.Code);
        Customer.Modify(true);
        ConfigureForecast(Forecast);

        FillForecast(Forecast, false);

        VerifyOpenInstallments(Forecast, Invoice, 3, 125);
        Forecast.Validate("Consider CF Payment Terms", true);
        Forecast.Modify(true);

        FillForecast(Forecast, false);

        FilterInvoiceLines(Line, Forecast, Invoice);
        Line.SetRange("Cash Flow Date", CalcDate('<45D>', Invoice."Document Date"));
        Assert.AreEqual(3, Line.Count(), 'An explicitly enabled native customer forecast override must apply without merging installments.');
        Line.CalcSums("Amount (LCY)");
        Assert.AreEqual(125, Line."Amount (LCY)", 'Forecast terms must not change the original aggregate receivable.');
        for Index := 1 to 3 do begin
            LibraryInstallments.GetInstallment(Entry, Invoice."Installment Plan ID", Index);
            Entry.TestField("Due Date", CalcDate(StrSubstNo('<%1D>', Index * 30), Invoice."Document Date"));
        end;
        Forecast.Validate("Consider CF Payment Terms", false);
        Forecast.Modify(true);

        FillForecast(Forecast, false);

        VerifyOpenInstallments(Forecast, Invoice, 3, 125);
    end;

    [Test]
    procedure OverdueForecastDateOptionDoesNotRewriteInstallmentDueDates()
    var
        Header: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Invoice: Record "Sales Invoice Header";
        Forecast: Record "Cash Flow Forecast";
        Line: Record "Cash Flow Worksheet Line";
        Entry: Record "Cust. Ledger Entry";
    begin
        LibraryInstallments.CreateInvoice(Header, SalesLine, '');
        Header.Validate("Document Date", WorkDate() - 45);
        Header.Validate("External Document No.", LibraryUtility.GenerateGUID());
        Header.Modify(true);
        Invoice.Get(LibrarySales.PostSalesDocument(Header, true, true));
        ConfigureForecast(Forecast);

        FillForecast(Forecast, false);

        VerifyOpenInstallments(Forecast, Invoice, 3, 125);
        Forecast.Validate("Overdue CF Dates to Work Date", true);
        Forecast.Modify(true);

        FillForecast(Forecast, false);

        FilterInvoiceLines(Line, Forecast, Invoice);
        Assert.AreEqual(3, Line.Count(), 'Moving an overdue forecast date must not duplicate the invoice.');
        Line.SetRange("Cash Flow Date", WorkDate());
        Assert.AreEqual(1, Line.Count(), 'Only the overdue installment must move to the work date.');
        Line.FindFirst();
        Line.TestField(Overdue, true);
        Line.TestField("Amount (LCY)", 41.67);
        LibraryInstallments.GetInstallment(Entry, Invoice."Installment Plan ID", 1);
        Entry.TestField("Due Date", WorkDate() - 15);
        Line.SetRange("Cash Flow Date", WorkDate() + 15);
        Assert.AreEqual(1, Line.Count(), 'The second installment must keep its future date.');
        Line.SetRange("Cash Flow Date", WorkDate() + 45);
        Assert.AreEqual(1, Line.Count(), 'The third installment must keep its future date.');
    end;

    local procedure ConfigureForecast(var Forecast: Record "Cash Flow Forecast")
    var
        Setup: Record "Cash Flow Setup";
        Account: Record "Cash Flow Account";
    begin
        if not Setup.Get() then
            Setup.Insert(true);
        LibraryCashFlow.CreateCashFlowAccount(Account, Account."Account Type"::Entry);
        Setup.Validate("Receivables CF Account No.", Account."No.");
        Setup.Modify(true);
        LibraryCashFlow.CreateCashFlowCard(Forecast);
        Forecast.Validate("Consider Discount", false);
        Forecast.Validate("Consider CF Payment Terms", false);
        Forecast.Validate("Consider Pmt. Tol. Amount", false);
        Forecast.Validate("Overdue CF Dates to Work Date", false);
        Forecast.Modify(true);
    end;

    local procedure FillForecast(Forecast: Record "Cash Flow Forecast"; GroupByDocumentType: Boolean)
    var
        Sources: array[16] of Boolean;
    begin
        Sources["Cash Flow Source Type"::Receivables.AsInteger()] := true;
        LibraryCashFlow.FillJournal(Sources, Forecast."No.", GroupByDocumentType);
    end;

    local procedure FilterInvoiceLines(var Line: Record "Cash Flow Worksheet Line"; Forecast: Record "Cash Flow Forecast"; Invoice: Record "Sales Invoice Header")
    begin
        Line.Reset();
        Line.SetRange("Cash Flow Forecast No.", Forecast."No.");
        Line.SetRange("Source Type", Line."Source Type"::Receivables);
        Line.SetRange("Document No.", Invoice."No.");
    end;

    local procedure VerifyOpenInstallments(Forecast: Record "Cash Flow Forecast"; Invoice: Record "Sales Invoice Header"; ExpectedCount: Integer; ExpectedLCY: Decimal)
    var
        Line: Record "Cash Flow Worksheet Line";
        Entry: Record "Cust. Ledger Entry";
        Index: Integer;
    begin
        FilterInvoiceLines(Line, Forecast, Invoice);
        Assert.AreEqual(ExpectedCount, Line.Count(), 'Forecasts must contain each open installment once and omit settled obligations.');
        Line.CalcSums("Amount (LCY)");
        Assert.AreEqual(ExpectedLCY, Line."Amount (LCY)", 'Forecast totals must reconcile to the remaining ledger balances, not repeated header amounts.');
        for Index := 1 to 3 do begin
            LibraryInstallments.GetInstallment(Entry, Invoice."Installment Plan ID", Index);
            Entry.CalcFields("Remaining Amt. (LCY)");
            Line.SetRange("Cash Flow Date", Entry."Due Date");
            if Entry.Open then begin
                Assert.AreEqual(1, Line.Count(), 'Each open installment must use its own due date.');
                Line.FindFirst();
                Line.TestField("Amount (LCY)", Entry."Remaining Amt. (LCY)");
            end else
                Assert.IsTrue(Line.IsEmpty(), 'A settled installment must not remain in the forecast.');
        end;
    end;
}
