// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

using Microsoft.Finance.ReceivablesPayables;

codeunit 32 "Customer Card Calculations"
{
    trigger OnRun()
    var
        Customer: record Customer;
        AgedAccReceivable: Codeunit "Aged Acc. Receivable";
        CustomerMgt: Codeunit "Customer Mgt.";
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        CustomerNo: Code[20];
        CustomerFilters: Text;
        AmountOnPostedInvoices: Decimal;
        AmountOnPostedCrMemos: Decimal;
        AmountOnOutstandingInvoices: Decimal;
        AmountOnOutstandingCrMemos: Decimal;
        Totals: Decimal;
        AdjmtCostLCY: Decimal;
        AdjCustProfit: Decimal;
        AdjProfitPct: Decimal;
        CustInvDiscAmountLCY: Decimal;
        CustPaymentsLCY: Decimal;
        CustSalesLCY: Decimal;
        CustProfit: Decimal;
        NoPostedInvoices: Integer;
        NoPostedCrMemos: Integer;
        NoOutstandingInvoices: Integer;
        NoOutstandingCrMemos: Integer;
        NewWorkDate: Date;
        BalanceAsVendor: Decimal;
        LinkedVendorNo: Code[20];
    begin
        Params := Page.GetBackgroundParameters();
        CustomerNo := CopyStr(Params.Get(GetCustomerNoLabel()), 1, MaxStrLen(CustomerNo));
        if not Customer.Get(CustomerNo) then
            exit;
        CustomerFilters := Params.Get(GetFiltersLabel());
        if CustomerFilters <> '' then
            Customer.SetView(CustomerFilters);
        if Evaluate(NewWorkDate, Params.Get(GetWorkDateLabel())) then
            WorkDate := NewWorkDate;
        AmountOnPostedInvoices := CustomerMgt.CalcAmountsOnPostedInvoices(Customer."No.", NoPostedInvoices);
        AmountOnPostedCrMemos := CustomerMgt.CalcAmountsOnPostedCrMemos(Customer."No.", NoPostedCrMemos);
        AmountOnOutstandingInvoices := CustomerMgt.CalculateAmountsOnUnpostedInvoices(Customer."No.", NoOutstandingInvoices);
        AmountOnOutstandingCrMemos := CustomerMgt.CalculateAmountsOnUnpostedCrMemos(Customer."No.", NoOutstandingCrMemos);
        Totals := AmountOnPostedInvoices + AmountOnPostedCrMemos + AmountOnOutstandingInvoices + AmountOnOutstandingCrMemos;

        CustomerMgt.CalculateStatistic(Customer, AdjmtCostLCY, AdjCustProfit, AdjProfitPct, CustInvDiscAmountLCY, CustPaymentsLCY, CustSalesLCY, CustProfit);
        CustomerMgt.CalculatePaymentStats(Customer."No.", Results);
        CustomerMgt.CalculateInteractionStats(Customer."No.", Results);
        CustomerMgt.CalcNumberOfDistinctItemsSold(Customer."No.", Results);

        BalanceAsVendor := Customer.GetBalanceAsVendor(LinkedVendorNo);

        Results.Add(GetAvgDaysPastDueDateLabel(), Format(AgedAccReceivable.InvoicePaymentDaysAverage(Customer."No.")));
        Results.Add(GetExpectedMoneyOwedLabel(), Format(CustomerMgt.CalculateAmountsWithVATOnUnpostedDocuments(Customer."No.")));
        Results.Add(GetAmountOnPostedInvoicesLabel(), Format(AmountOnPostedInvoices));
        Results.Add(GetAmountOnPostedCrMemosLabel(), Format(AmountOnPostedCrMemos));
        Results.Add(GetAmountOnOutstandingInvoicesLabel(), Format(AmountOnOutstandingInvoices));
        Results.Add(GetAmountOnOutstandingCrMemosLabel(), Format(AmountOnOutstandingCrMemos));
        Results.Add(GetTotalsLabel(), Format(Totals));
        Results.Add(GetAdjmtCostLCYLabel(), Format(AdjmtCostLCY));
        Results.Add(GetAdjCustProfitLabel(), Format(AdjCustProfit));
        Results.Add(GetAdjProfitPctLabel(), Format(AdjProfitPct));
        Results.Add(GetCustInvDiscAmountLCYLabel(), Format(CustInvDiscAmountLCY));
        Results.Add(GetCustPaymentsLCYLabel(), Format(CustPaymentsLCY));
        Results.Add(GetCustSalesLCYLabel(), Format(CustSalesLCY));
        Results.Add(GetCustProfitLabel(), Format(CustProfit));
        Results.Add(GetNoPostedInvoicesLabel(), Format(NoPostedInvoices));
        Results.Add(GetNoPostedCrMemosLabel(), Format(NoPostedCrMemos));
        Results.Add(GetNoOutstandingInvoicesLabel(), Format(NoOutstandingInvoices));
        Results.Add(GetNoOutstandingCrMemosLabel(), Format(NoOutstandingCrMemos));
        Results.Add(GetOverdueBalanceLabel(), Format(Customer.CalcOverdueBalance()));
        Results.Add(GetBalanceAsVendorLabel(), Format(BalanceAsVendor));
        Results.Add(GetLinkedVendorNoLabel(), Format(LinkedVendorNo));

        Page.SetBackgroundTaskResult(Results);
    end;

    var
        ExpectedMoneyOwedLbl: label 'Expected Money Owed', Locked = true;
        AvgDaysPastDueDateLbl: label 'Avg. Days Past Due', Locked = true;
        AvgDaysToPayLbl: label 'Avg. Days to pay', Locked = true;
        AmountOnPostedInvoicesLbl: label 'Amount on Posted Invoices', Locked = true;
        AmountOnPostedCrMemosLbl: label 'Amount On Posted Cr. Memos', Locked = true;
        AmountOnOutstandingInvoicesLbl: label 'Amount On Outstanding Invoices', Locked = true;
        AmountOnOutstandingCrMemosLbl: label 'Amount On Outstanding Cr. Memos', Locked = true;
        TotalsLbl: label 'Totals', Locked = true;
        AdjmtCostLCYLbl: label 'Adjmt. Cost LCY', Locked = true;
        AdjCustProfitLbl: label 'Adj. Cust Profit', Locked = true;
        AdjProfitPctLbl: label 'Adj. Profit Pct.', Locked = true;
        CustInvDiscAmountLCYLbl: label 'Cust. Inv. Disc. Amount LCY', Locked = true;
        CustPaymentsLCYLbl: label 'Cust. Payments LCY', Locked = true;
        CustSalesLCYLbl: label 'Cust. Sales LCY', Locked = true;
        CustProfitLbl: label 'Cust. Profit', Locked = true;
        NoPostedInvoicesLbl: label 'No. Posted Invoices', Locked = true;
        NoPostedCrMemosLbl: label 'No. Posted Cr. Memos', Locked = true;
        NoOutstandingInvoicesLbl: label 'No. Outstanding Invoices', Locked = true;
        NoOutstandingCrMemosLbl: label 'No. Outstanding Cr. Memos', Locked = true;
        OverdueBalanceLbl: label 'Overdue Balance', Locked = true;
        CustomerNoLbl: label 'Customer No.', Locked = true;
        FiltersLbl: label 'Filters', Locked = true;
        BalanceAsVendorLbl: Label 'BalanceAsVendor', Locked = true;
        LinkedVendorNoLbl: Label 'LinkedVendorNo', Locked = true;
        WorkDateLbl: label 'Work Date', Locked = true;
        PaidLateCountLbl: label 'Paid Late Count', Locked = true;
        PaidOnTimeCountLbl: label 'Paid On Time Count', Locked = true;
        PercentPaidLateLbl: label 'Percent Paid Late', Locked = true;
        OverdueCountLbl: label 'Overdue Count', Locked = true;
        LastPaymentDateLbl: label 'Last Payment Date', Locked = true;
        LastPaymentAmountLbl: label 'Last Payment Amount', Locked = true;
        LastPaymentOnTimeLbl: label 'Last Payment On Time', Locked = true;
        InteractionCountLbl: label 'Interaction Count', Locked = true;
        LastInteractionDateLbl: label 'Last Interaction Date', Locked = true;
        LastInteractionTypeLbl: label 'Last Interaction Type', Locked = true;
        MostFrequentInteractionTypeLbl: label 'Most Frequent Interaction Type', Locked = true;
        DaysSinceLastSaleLbl: label 'Days Since Last Sale', Locked = true;
        GetDistinctItemsSoldLbl: label 'Distinct Items Sold', Locked = true;

    internal procedure GetWorkDateLabel(): Text
    begin
        exit(WorkDateLbl);
    end;

    internal procedure GetExpectedMoneyOwedLabel(): Text
    begin
        exit(ExpectedMoneyOwedLbl);
    end;

    internal procedure GetAvgDaysPastDueDateLabel(): Text
    begin
        exit(AvgDaysPastDueDateLbl);
    end;

    internal procedure GetPaidLateCountLabel(): Text
    begin
        exit(PaidLateCountLbl);
    end;

    internal procedure GetPaidOnTimeCountLabel(): Text
    begin
        exit(PaidOnTimeCountLbl);
    end;

    internal procedure GetPercentPaidLateLabel(): Text
    begin
        exit(PercentPaidLateLbl);
    end;

    internal procedure GetOverdueCountLabel(): Text
    begin
        exit(OverdueCountLbl);
    end;

    internal procedure GetLastPaymentDateLabel(): Text
    begin
        exit(LastPaymentDateLbl);
    end;

    internal procedure GetLastPaymentAmountLabel(): Text
    begin
        exit(LastPaymentAmountLbl);
    end;

    internal procedure GetLastPaymentOnTimeLabel(): Text
    begin
        exit(LastPaymentOnTimeLbl);
    end;

    internal procedure GetAvgDaysToPayLabel(): Text
    begin
        exit(AvgDaysToPayLbl);
    end;

    internal procedure GetCustomerNoLabel(): Text
    begin
        exit(CustomerNoLbl);
    end;

    internal procedure GetAmountOnPostedInvoicesLabel(): Text
    begin
        exit(AmountOnPostedInvoicesLbl);
    end;

    internal procedure GetAmountOnPostedCrMemosLabel(): Text
    begin
        exit(AmountOnPostedCrMemosLbl);
    end;

    internal procedure GetAmountOnOutstandingInvoicesLabel(): Text
    begin
        exit(AmountOnOutstandingInvoicesLbl);
    end;

    internal procedure GetAmountOnOutstandingCrMemosLabel(): Text
    begin
        exit(AmountOnOutstandingCrMemosLbl);
    end;

    internal procedure GetTotalsLabel(): Text
    begin
        exit(TotalsLbl);
    end;

    internal procedure GetAdjmtCostLCYLabel(): Text
    begin
        exit(AdjmtCostLCYLbl);
    end;

    internal procedure GetAdjCustProfitLabel(): Text
    begin
        exit(AdjCustProfitLbl);
    end;

    internal procedure GetAdjProfitPctLabel(): Text
    begin
        exit(AdjProfitPctLbl);
    end;

    internal procedure GetCustInvDiscAmountLCYLabel(): Text
    begin
        exit(CustInvDiscAmountLCYLbl);
    end;

    internal procedure GetCustPaymentsLCYLabel(): Text
    begin
        exit(CustPaymentsLCYLbl);
    end;

    internal procedure GetCustSalesLCYLabel(): Text
    begin
        exit(CustSalesLCYLbl);
    end;

    internal procedure GetCustProfitLabel(): Text
    begin
        exit(CustProfitLbl);
    end;

    internal procedure GetNoPostedInvoicesLabel(): Text
    begin
        exit(NoPostedInvoicesLbl);
    end;

    internal procedure GetNoPostedCrMemosLabel(): Text
    begin
        exit(NoPostedCrMemosLbl);
    end;

    internal procedure GetNoOutstandingInvoicesLabel(): Text
    begin
        exit(NoOutstandingInvoicesLbl);
    end;

    internal procedure GetNoOutstandingCrMemosLabel(): Text
    begin
        exit(NoOutstandingCrMemosLbl);
    end;

    internal procedure GetOverdueBalanceLabel(): Text
    begin
        exit(OverdueBalanceLbl);
    end;

    internal procedure GetFiltersLabel(): Text
    begin
        exit(FiltersLbl);
    end;

    internal procedure GetBalanceAsVendorLabel(): Text
    begin
        exit(BalanceAsVendorLbl);
    end;

    internal procedure GetLinkedVendorNoLabel(): Text
    begin
        exit(LinkedVendorNoLbl);
    end;

    internal procedure GetInteractionCountLabel(): Text
    begin
        exit(InteractionCountLbl);
    end;

    internal procedure GetLastInteractionDateLabel(): Text
    begin
        exit(LastInteractionDateLbl);
    end;

    internal procedure GetLastInteractionTypeLabel(): Text
    begin
        exit(LastInteractionTypeLbl);
    end;

    internal procedure GetMostFrequentInteractionTypeLabel(): Text
    begin
        exit(MostFrequentInteractionTypeLbl);
    end;

    internal procedure GetDaysSinceLastSaleLabel(): Text
    begin
        exit(DaysSinceLastSaleLbl);
    end;

    internal procedure GetDistinctItemsSoldLabel(): Text
    begin
        exit(GetDistinctItemsSoldLbl)
    end;
}
