// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

using Microsoft.CRM.Interaction;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.Period;
using Microsoft.Inventory.Costing;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;

/// <summary>
/// Provides customer management functions including statistics calculations and sales analysis.
/// </summary>
codeunit 1302 "Customer Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        FiscalYearTotals: Boolean;

#if not CLEAN27
    /// <summary>
    /// Calculates the average number of days it takes for a customer to pay their invoices.
    /// </summary>
    /// <param name="CustNo">Specifies the customer number to calculate the average days to pay for.</param>
    /// <returns>The average number of days to pay as a decimal value.</returns>
    [Obsolete('Use procedure CalculatePaymentStats(CustomerNo: Code[20]; var Stats: Dictionary of [Text, Text]) instead.', '27.0')]
    procedure AvgDaysToPay(CustNo: Code[20]) AverageDaysToPay: Decimal
    var
        Stats: Dictionary of [Text, Text];
    begin
        CalculatePaymentStats(CustNo, Stats);
        exit(GetAvgDaysToPay(stats));
    end;

    local procedure GetAvgDaysToPay(var Stats: Dictionary of [Text, Text]) AverageDaysToPay: Decimal
    var
        CustomerCardCalculations: Codeunit "Customer Card Calculations";
        AverageDaysToPayText: Text;
    begin
        if Stats.Get(CustomerCardCalculations.GetAvgDaysToPayLabel(), AverageDaysToPayText) then
            if Evaluate(AverageDaysToPay, AverageDaysToPayText, 0) then
                exit(AverageDaysToPay);
    end;
#endif
    /// <summary>
    /// Calculates payment statistics for a customer including average days to pay, late payment counts, and overdue invoices.
    /// </summary>
    /// <param name="CustomerNo">Specifies the customer number to calculate payment statistics for.</param>
    /// <param name="Stats">Returns a dictionary containing the calculated payment statistics.</param>
    procedure CalculatePaymentStats(CustomerNo: Code[20]; var Stats: Dictionary of [Text, Text])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        CustomerCardCalculations: Codeunit "Customer Card Calculations";
        TotalDaysToPay: Decimal;
        TotalNoOfInv: Integer;
        PaidLateCount: Decimal;
    begin
        TotalDaysToPay := 0;
        TotalNoOfInv := 0;
        PaidLateCount := 0;

        CustLedgerEntry.SetCurrentKey("Customer No.", "Posting Date");
        SetFilterForPostedDocs(CustLedgerEntry, CustomerNo, CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange(Open, false);

        if CustLedgerEntry.FindSet() then
            repeat
                case true of
                    CustLedgerEntry."Closed at Date" > CustLedgerEntry."Posting Date":
                        begin
                            TotalDaysToPay += CustLedgerEntry."Closed at Date" - CustLedgerEntry."Posting Date";
                            TotalNoOfInv += 1;
                            if CustLedgerEntry."Closed at Date" > CustLedgerEntry."Due Date" then
                                PaidLateCount += 1;
                        end;
                    CustLedgerEntry."Closed by Entry No." <> 0:
                        if CustLedgerEntry2.Get(CustLedgerEntry."Closed by Entry No.") then begin
                            TotalDaysToPay += CustLedgerEntry2."Posting Date" - CustLedgerEntry."Posting Date";
                            TotalNoOfInv += 1;
                            if CustLedgerEntry2."Posting Date" > CustLedgerEntry."Due Date" then
                                PaidLateCount += 1;
                        end;
                    else begin
                        CustLedgerEntry2.SetCurrentKey("Closed by Entry No.");
                        CustLedgerEntry2.SetRange("Closed by Entry No.", CustLedgerEntry."Entry No.");
                        if CustLedgerEntry2.FindFirst() then begin
                            TotalDaysToPay += CustLedgerEntry2."Posting Date" - CustLedgerEntry."Posting Date";
                            TotalNoOfInv += 1;
                            if CustLedgerEntry2."Posting Date" > CustLedgerEntry."Due Date" then
                                PaidLateCount += 1;
                        end
                    end;
                end;
            until CustLedgerEntry.Next() = 0;

        if TotalNoOfInv <> 0 then begin
            Stats.Add(CustomerCardCalculations.GetAvgDaysToPayLabel(), (TotalDaysToPay / TotalNoOfInv).ToText());
            Stats.Add(CustomerCardCalculations.GetPaidLateCountLabel(), PaidLateCount.ToText());
            Stats.Add(CustomerCardCalculations.GetPaidOnTimeCountLabel(), (TotalNoOfInv - PaidLateCount).ToText());
            Stats.Add(CustomerCardCalculations.GetPercentPaidLateLabel(), Round((PaidLateCount / TotalNoOfInv) * 100).ToText());
        end;

        CustLedgerEntry.SetRange(Open, true);
        CustLedgerEntry.SetRange("Due Date", 0D, WorkDate() - 1);
        Stats.Add(CustomerCardCalculations.GetOverdueCountLabel(), CustLedgerEntry.Count().ToText());

        CalcLastPaymentInfo(CustomerNo, Stats);

        CustLedgerEntry.Reset();
        CustLedgerEntry.SetCurrentKey("Posting Date");
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetFilter("Sales (LCY)", '>%1', 0);
        if CustLedgerEntry.FindLast() then
            Stats.Add(CustomerCardCalculations.GetDaysSinceLastSaleLabel(), (WorkDate() - CustLedgerEntry."Posting Date").ToText());
    end;

    /// <summary>
    /// Retrieves the last payment information for a customer including date, amount, and whether it was paid on time.
    /// </summary>
    /// <param name="CustomerNo">Specifies the customer number to retrieve payment information for.</param>
    /// <param name="Stats">Returns a dictionary containing the last payment date, amount, and on-time status.</param>
    procedure CalcLastPaymentInfo(CustomerNo: Code[20]; var Stats: Dictionary of [Text, Text])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        CustomerCardCalculations: Codeunit "Customer Card Calculations";
    begin
        CustLedgerEntry.SetCurrentKey("Document Type", "Customer No.", "Posting Date", "Currency Code");
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Payment);
        CustLedgerEntry.SetRange(Reversed, false);
        if CustLedgerEntry.FindLast() then begin
            CustLedgerEntry.CalcFields("Amount (LCY)");
            Stats.Add(CustomerCardCalculations.GetLastPaymentDateLabel(), CustLedgerEntry."Posting Date".ToText());
            Stats.Add(CustomerCardCalculations.GetLastPaymentAmountLabel(), (-CustLedgerEntry."Amount (LCY)").ToText());
            CustLedgerEntry2.SetRange("Closed by Entry No.", CustLedgerEntry."Entry No.");
            if CustLedgerEntry2.FindLast() then
                Stats.Add(CustomerCardCalculations.GetLastPaymentOnTimeLabel(), (CustLedgerEntry2."Closed at Date" < CustLedgerEntry2."Due Date").ToText())
        end;
    end;

    /// <summary>
    /// Calculates the number of distinct items that have been sold to a customer.
    /// </summary>
    /// <param name="CustomerNo">Specifies the customer number to count distinct items for.</param>
    /// <param name="Stats">Returns a dictionary containing the count of distinct items sold.</param>
    procedure CalcNumberOfDistinctItemsSold(CustomerNo: Code[20]; var Stats: Dictionary of [Text, Text])
    var
        CustomerCardCalculations: Codeunit "Customer Card Calculations";
        DistinctItemsSoldQuery: Query "Distinct Items Sold";
        DistinctItemCount: Integer;
    begin
        DistinctItemCount := 0;
        DistinctItemsSoldQuery.SetRange(CustomerNoFilter, CustomerNo);

        if DistinctItemsSoldQuery.Open() then
            while DistinctItemsSoldQuery.Read() do
                DistinctItemCount += 1;
        Stats.Add(CustomerCardCalculations.GetDistinctItemsSoldLabel(), DistinctItemCount.ToText())
    end;

    /// <summary>
    /// Calculates interaction statistics for a customer including total count, last interaction date, and most frequent type.
    /// </summary>
    /// <param name="CustomerNo">Specifies the customer number to calculate interaction statistics for.</param>
    /// <param name="Stats">Returns a dictionary containing the calculated interaction statistics.</param>
    procedure CalculateInteractionStats(CustomerNo: Code[20]; var Stats: Dictionary of [Text, Text])
    var
        InteractionLogEntry: Record "Interaction Log Entry";
        InteractionGroup: Record "Interaction Group";
        CustomerCardCalculations: Codeunit "Customer Card Calculations";
        CustomerInteractionStats: Query "Customer Interaction Stats.";
        EntryCount, MaxEntryNo, MaxGroupCount : integer;
        MaxGroupDescription: Text[100];
    begin
        MaxEntryNo := 0;
        MaxGroupCount := 0;
        CustomerInteractionStats.SetRange(CustomerNo, CustomerNo);
        CustomerInteractionStats.SetFilter(InteractionDate, GetCurrentYearFilter());
        CustomerInteractionStats.Open();
        while CustomerInteractionStats.Read() do begin
            EntryCount += CustomerInteractionStats.InteractionCount;
            if MaxGroupCount < CustomerInteractionStats.InteractionCount then begin
                MaxGroupCount := CustomerInteractionStats.InteractionCount;
                MaxGroupDescription := CustomerInteractionStats.Description;
            end;
            if MaxEntryNo < CustomerInteractionStats.MaxEntryNo then
                MaxEntryNo := CustomerInteractionStats.MaxEntryNo;
        end;
        Stats.Add(CustomerCardCalculations.GetInteractionCountLabel(), EntryCount.ToText());
        if InteractionLogEntry.Get(MaxEntryNo) then begin
            Stats.Add(CustomerCardCalculations.GetLastInteractionDateLabel(), InteractionLogEntry.Date.ToText());
            if InteractionGroup.Get(InteractionLogEntry."Interaction Group Code") then
                Stats.Add(CustomerCardCalculations.GetLastInteractionTypeLabel(), InteractionGroup.Description);
            Stats.Add(CustomerCardCalculations.GetMostFrequentInteractionTypeLabel(), MaxGroupDescription);
        end;

    end;

    /// <summary>
    /// Calculates customer statistics including sales, profit, and cost adjustments for the current fiscal year.
    /// </summary>
    /// <param name="Customer">Specifies the customer record to calculate statistics for.</param>
    /// <param name="AdjmtCostLCY">Returns the adjusted cost in local currency.</param>
    /// <param name="AdjCustProfit">Returns the adjusted customer profit.</param>
    /// <param name="AdjProfitPct">Returns the adjusted profit percentage.</param>
    /// <param name="CustInvDiscAmountLCY">Returns the customer invoice discount amount in local currency.</param>
    /// <param name="CustPaymentsLCY">Returns the customer payments in local currency.</param>
    /// <param name="CustSalesLCY">Returns the customer sales in local currency.</param>
    /// <param name="CustProfit">Returns the customer profit.</param>
    procedure CalculateStatistic(Customer: Record Customer; var AdjmtCostLCY: Decimal; var AdjCustProfit: Decimal; var AdjProfitPct: Decimal; var CustInvDiscAmountLCY: Decimal; var CustPaymentsLCY: Decimal; var CustSalesLCY: Decimal; var CustProfit: Decimal)
    begin
        Customer.SetFilter("Date Filter", GetCurrentYearFilter());
        Customer.CalcFields("Sales (LCY)", "Profit (LCY)", "Inv. Discounts (LCY)", "Payments (LCY)");

        CalculateStatisticsWithCurrentCustomerValues(Customer, AdjmtCostLCY, AdjCustProfit, AdjProfitPct, CustInvDiscAmountLCY, CustPaymentsLCY, CustSalesLCY, CustProfit)
    end;

    /// <summary>
    /// Calculates customer statistics using current customer field values without applying date filters.
    /// </summary>
    /// <param name="Customer">Specifies the customer record with pre-calculated field values.</param>
    /// <param name="AdjmtCostLCY">Returns the adjusted cost in local currency.</param>
    /// <param name="AdjCustProfit">Returns the adjusted customer profit.</param>
    /// <param name="AdjProfitPct">Returns the adjusted profit percentage.</param>
    /// <param name="CustInvDiscAmountLCY">Returns the customer invoice discount amount in local currency.</param>
    /// <param name="CustPaymentsLCY">Returns the customer payments in local currency.</param>
    /// <param name="CustSalesLCY">Returns the customer sales in local currency.</param>
    /// <param name="CustProfit">Returns the customer profit.</param>
    procedure CalculateStatisticsWithCurrentCustomerValues(var Customer: Record Customer; var AdjmtCostLCY: Decimal; var AdjCustProfit: Decimal; var AdjProfitPct: Decimal; var CustInvDiscAmountLCY: Decimal; var CustPaymentsLCY: Decimal; var CustSalesLCY: Decimal; var CustProfit: Decimal)
    var
        CostCalcuMgt: Codeunit "Cost Calculation Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculateStatisticsWithCurrentCustomerValues(Customer, AdjmtCostLCY, AdjCustProfit, AdjProfitPct, CustInvDiscAmountLCY, CustPaymentsLCY, CustSalesLCY, CustProfit, IsHandled);
        if IsHandled then
            exit;

        // Costs (LCY):
        CustSalesLCY := Customer."Sales (LCY)";
        CustProfit := Customer."Profit (LCY)" + CostCalcuMgt.NonInvtblCostAmt(Customer);
        AdjmtCostLCY := CustSalesLCY - CustProfit + CostCalcuMgt.CalcCustActualCostLCY(Customer);
        AdjCustProfit := CustProfit + AdjmtCostLCY;

        // Profit %
        if Customer."Sales (LCY)" <> 0 then
            AdjProfitPct := Round(100 * AdjCustProfit / Customer."Sales (LCY)", 0.1)
        else
            AdjProfitPct := 0;

        CustInvDiscAmountLCY := Customer."Inv. Discounts (LCY)";

        CustPaymentsLCY := Customer."Payments (LCY)";
    end;

    /// <summary>
    /// Calculates the total sales amount on posted invoices for a customer within the current year.
    /// </summary>
    /// <param name="CustNo">Specifies the customer number to calculate posted invoice amounts for.</param>
    /// <param name="RecCount">Returns the count of posted invoices.</param>
    /// <returns>The total sales amount in local currency on posted invoices.</returns>
    procedure CalcAmountsOnPostedInvoices(CustNo: Code[20]; var RecCount: Integer): Decimal
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        exit(CalcAmountsOnPostedDocs(CustNo, RecCount, CustLedgEntry."Document Type"::Invoice));
    end;

    /// <summary>
    /// Calculates the total sales amount on posted credit memos for a customer within the current year.
    /// </summary>
    /// <param name="CustNo">Specifies the customer number to calculate posted credit memo amounts for.</param>
    /// <param name="RecCount">Returns the count of posted credit memos.</param>
    /// <returns>The total sales amount in local currency on posted credit memos.</returns>
    procedure CalcAmountsOnPostedCrMemos(CustNo: Code[20]; var RecCount: Integer): Decimal
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        exit(CalcAmountsOnPostedDocs(CustNo, RecCount, CustLedgEntry."Document Type"::"Credit Memo"));
    end;

    /// <summary>
    /// Calculates the total outstanding amount on sales orders for a customer.
    /// </summary>
    /// <param name="CustNo">Specifies the customer number to calculate sales order amounts for.</param>
    /// <param name="RecCount">Returns the count of sales orders.</param>
    /// <returns>The total outstanding amount in local currency on sales orders.</returns>
    procedure CalcAmountsOnOrders(CustNo: Code[20]; var RecCount: Integer): Decimal
    var
        SalesHeader: Record "Sales Header";
    begin
        exit(CalculateAmountsOnUnpostedDocs(CustNo, RecCount, SalesHeader."Document Type"::Order));
    end;

    /// <summary>
    /// Calculates the total outstanding amount on sales quotes for a customer.
    /// </summary>
    /// <param name="CustNo">Specifies the customer number to calculate sales quote amounts for.</param>
    /// <param name="RecCount">Returns the count of sales quotes.</param>
    /// <returns>The total outstanding amount in local currency on sales quotes.</returns>
    procedure CalcAmountsOnQuotes(CustNo: Code[20]; var RecCount: Integer): Decimal
    var
        SalesHeader: Record "Sales Header";
    begin
        exit(CalculateAmountsOnUnpostedDocs(CustNo, RecCount, SalesHeader."Document Type"::Quote));
    end;

    local procedure CalcAmountsOnPostedDocs(CustNo: Code[20]; var RecCount: Integer; DocType: Enum "Gen. Journal Document Type"): Decimal
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        SetFilterForPostedDocs(CustLedgerEntry, CustNo, DocType);
        RecCount := CustLedgerEntry.Count();
        CustLedgerEntry.CalcSums("Sales (LCY)");
        exit(CustLedgerEntry."Sales (LCY)");
    end;

    /// <summary>
    /// Calculates the total outstanding amount including VAT on unposted invoices and credit memos for a customer.
    /// </summary>
    /// <param name="CustNo">Specifies the customer number to calculate amounts for.</param>
    /// <returns>The total outstanding amount including VAT on unposted documents.</returns>
    procedure CalculateAmountsWithVATOnUnpostedDocuments(CustNo: Code[20]): Decimal
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        SalesLine: Record "Sales Line";
        Result: Decimal;
    begin
        if CustNo = '' then
            exit;
        SetFilterForUnpostedLines(SalesLine, CustNo, SalesLine."Document Type"::Invoice, true);
        SalesLine.CalcSums("Outstanding Amount (LCY)");
        Result := SalesLine."Outstanding Amount (LCY)";

        SetFilterForUnpostedLines(SalesLine, CustNo, SalesLine."Document Type"::"Credit Memo", true);
        SalesLine.CalcSums("Outstanding Amount (LCY)");
        Result -= SalesLine."Outstanding Amount (LCY)";

        exit(Result);
    end;

    /// <summary>
    /// Calculates the total outstanding amount on unposted sales invoices for a customer.
    /// </summary>
    /// <param name="CustNo">Specifies the customer number to calculate unposted invoice amounts for.</param>
    /// <param name="RecCount">Returns the count of unposted invoices.</param>
    /// <returns>The total outstanding amount in local currency on unposted invoices.</returns>
    procedure CalculateAmountsOnUnpostedInvoices(CustNo: Code[20]; var RecCount: Integer): Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        exit(CalculateAmountsOnUnpostedDocs(CustNo, RecCount, SalesLine."Document Type"::Invoice));
    end;

    /// <summary>
    /// Calculates the total outstanding amount on unposted sales credit memos for a customer.
    /// </summary>
    /// <param name="CustNo">Specifies the customer number to calculate unposted credit memo amounts for.</param>
    /// <param name="RecCount">Returns the count of unposted credit memos.</param>
    /// <returns>The total outstanding amount in local currency on unposted credit memos.</returns>
    procedure CalculateAmountsOnUnpostedCrMemos(CustNo: Code[20]; var RecCount: Integer): Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        exit(CalculateAmountsOnUnpostedDocs(CustNo, RecCount, SalesLine."Document Type"::"Credit Memo"));
    end;

    local procedure CalculateAmountsOnUnpostedDocs(CustNo: Code[20]; var RecCount: Integer; DocumentType: Enum "Sales Document Type") Result: Decimal
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        SalesHeader: Record "Sales Header";
        SalesOutstdAmountOnVAT: Query "Sales Outstd. Amount On VAT";
        Factor: Integer;
    begin
        RecCount := 0;
        Result := 0;
        if CustNo = '' then
            exit;

        SalesHeader.SetRange("Document Type", DocumentType);
        SalesHeader.SetRange("Bill-to Customer No.", CustNo);
        RecCount := SalesHeader.Count();

        case DocumentType of
            "Sales Document Type"::Invoice,
        "Sales Document Type"::Order,
        "Sales Document Type"::Quote:
                Factor := 1;
            "Sales Document Type"::"Credit Memo":
                Factor := -1;
        end;
        SalesOutstdAmountOnVAT.SetRange(Document_Type, DocumentType);
        SalesOutstdAmountOnVAT.SetRange(Bill_to_Customer_No_, CustNo);
        SalesOutstdAmountOnVAT.Open();
        while SalesOutstdAmountOnVAT.Read() do
            Result += Factor * SalesOutstdAmountOnVAT.Sum_Outstanding_Amount__LCY_ * 100 / (100 + SalesOutstdAmountOnVAT.VAT__);
        SalesOutstdAmountOnVAT.Close();

        exit(Round(Result));
    end;

    /// <summary>
    /// Opens the Posted Sales Invoices page filtered for the specified customer within the current year.
    /// </summary>
    /// <param name="CustNo">Specifies the customer number to filter posted invoices for.</param>
    procedure DrillDownOnPostedInvoices(CustNo: Code[20])
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetRange("Bill-to Customer No.", CustNo);
        SalesInvoiceHeader.SetFilter("Posting Date", GetCurrentYearFilter());

        PAGE.Run(PAGE::"Posted Sales Invoices", SalesInvoiceHeader);
    end;

    /// <summary>
    /// Opens the Posted Sales Credit Memos page filtered for the specified customer within the current year.
    /// </summary>
    /// <param name="CustNo">Specifies the customer number to filter posted credit memos for.</param>
    procedure DrillDownOnPostedCrMemo(CustNo: Code[20])
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        SalesCrMemoHeader.SetRange("Bill-to Customer No.", CustNo);
        SalesCrMemoHeader.SetFilter("Posting Date", GetCurrentYearFilter());

        PAGE.Run(PAGE::"Posted Sales Credit Memos", SalesCrMemoHeader);
    end;

    /// <summary>
    /// Opens the Sales Order List page filtered for the specified customer.
    /// </summary>
    /// <param name="CustNo">Specifies the customer number to filter sales orders for.</param>
    procedure DrillDownOnOrders(CustNo: Code[20])
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetRange("Bill-to Customer No.", CustNo);
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);

        PAGE.Run(PAGE::"Sales Order List", SalesHeader);
    end;

    /// <summary>
    /// Opens the Sales Quotes page filtered for the specified customer.
    /// </summary>
    /// <param name="CustNo">Specifies the customer number to filter sales quotes for.</param>
    procedure DrillDownOnQuotes(CustNo: Code[20])
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetRange("Bill-to Customer No.", CustNo);
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Quote);

        PAGE.Run(PAGE::"Sales Quotes", SalesHeader);
    end;

    /// <summary>
    /// Opens the Sales List page showing unposted invoices and credit memos for the specified customer.
    /// </summary>
    /// <param name="CustNo">Specifies the customer number to filter expected money owed documents for.</param>
    procedure DrillDownMoneyOwedExpected(CustNo: Code[20])
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        SalesHeader: Record "Sales Header";
    begin
        SetFilterForUnpostedDocs(SalesHeader, CustNo, -1);
        PAGE.Run(PAGE::"Sales List", SalesHeader)
    end;

    /// <summary>
    /// Opens the Sales Invoice List page filtered for unposted invoices of the specified customer.
    /// </summary>
    /// <param name="CustNo">Specifies the customer number to filter unposted invoices for.</param>
    procedure DrillDownOnUnpostedInvoices(CustNo: Code[20])
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        SalesHeader: Record "Sales Header";
    begin
        SetFilterForUnpostedDocs(SalesHeader, CustNo, SalesHeader."Document Type"::Invoice.AsInteger());
        PAGE.Run(PAGE::"Sales Invoice List", SalesHeader)
    end;

    /// <summary>
    /// Opens the Sales Credit Memos page filtered for unposted credit memos of the specified customer.
    /// </summary>
    /// <param name="CustNo">Specifies the customer number to filter unposted credit memos for.</param>
    procedure DrillDownOnUnpostedCrMemos(CustNo: Code[20])
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        SalesHeader: Record "Sales Header";
    begin
        SetFilterForUnpostedDocs(SalesHeader, CustNo, SalesHeader."Document Type"::"Credit Memo".AsInteger());
        PAGE.Run(PAGE::"Sales Credit Memos", SalesHeader)
    end;

    local procedure SetFilterForUnpostedDocs(var SalesHeader: Record "Sales Header"; CustNo: Code[20]; DocumentType: Integer)
    begin
        SalesHeader.SetRange("Bill-to Customer No.", CustNo);
        SalesHeader.SetFilter("Posting Date", GetCurrentYearFilter());

        if DocumentType = -1 then
            SalesHeader.SetFilter("Document Type", '%1|%2', SalesHeader."Document Type"::Invoice, SalesHeader."Document Type"::"Credit Memo")
        else
            SalesHeader.SetRange("Document Type", DocumentType);
    end;

    local procedure SetFilterForUnpostedLines(var SalesLine: Record "Sales Line"; CustNo: Code[20]; DocumentType: Enum "Sales Document Type"; Posted: Boolean)
    begin
        SalesLine.SetRange("Bill-to Customer No.", CustNo);
        if Posted then
            SalesLine.SetFilter("Posting Date", GetCurrentYearFilter());

        SalesLine.SetRange("Document Type", DocumentType);

        OnAfterSetFilterForUnpostedLines(SalesLine);
    end;

    local procedure SetFilterForPostedDocs(var CustLedgEntry: Record "Cust. Ledger Entry"; CustNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    begin
        CustLedgEntry.SetRange("Customer No.", CustNo);
        CustLedgEntry.SetFilter("Posting Date", GetCurrentYearFilter());
        CustLedgEntry.SetRange("Document Type", DocumentType);

        OnAfterSetFilterForPostedDocs(CustLedgEntry);
    end;

    /// <summary>
    /// Retrieves the date filter for the current fiscal year or accounting period.
    /// </summary>
    /// <returns>A text filter representing the current year date range.</returns>
    procedure GetCurrentYearFilter(): Text[30]
    var
        DateFilterCalc: Codeunit "DateFilter-Calc";
        CustDateFilter: Text[30];
        CustDateName: Text[30];
        SkipSetFilter: Boolean;
    begin
        SkipSettingFilter(SkipSetFilter);
        if SkipSetFilter then
            exit(CustDateFilter);

        if FiscalYearTotals then
            DateFilterCalc.CreateAccountingPeriodFilter(CustDateFilter, CustDateName, WorkDate(), 0)
        else
            DateFilterCalc.CreateFiscalYearFilter(CustDateFilter, CustDateName, WorkDate(), 0);

        exit(CustDateFilter);
    end;

    /// <summary>
    /// Calculates the total sales for a customer including posted and outstanding invoices and credit memos.
    /// </summary>
    /// <param name="CustNo">Specifies the customer number to calculate total sales for.</param>
    /// <returns>The total sales amount in local currency.</returns>
    procedure GetTotalSales(CustNo: Code[20]) Result: Decimal
    var
        Totals: Decimal;
        AmountOnPostedInvoices: Decimal;
        AmountOnPostedCrMemos: Decimal;
        AmountOnOutstandingInvoices: Decimal;
        AmountOnOutstandingCrMemos: Decimal;
        NoPostedInvoices: Integer;
        NoPostedCrMemos: Integer;
        NoOutstandingInvoices: Integer;
        NoOutstandingCrMemos: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetTotalSales(CustNo, Result, IsHandled);
        if IsHandled then
            exit(Result);

        AmountOnPostedInvoices := CalcAmountsOnPostedInvoices(CustNo, NoPostedInvoices);
        AmountOnPostedCrMemos := CalcAmountsOnPostedCrMemos(CustNo, NoPostedCrMemos);

        AmountOnOutstandingInvoices := CalculateAmountsOnUnpostedInvoices(CustNo, NoOutstandingInvoices);
        AmountOnOutstandingCrMemos := CalculateAmountsOnUnpostedCrMemos(CustNo, NoOutstandingCrMemos);

        Totals := AmountOnPostedInvoices + AmountOnPostedCrMemos + AmountOnOutstandingInvoices + AmountOnOutstandingCrMemos;
        exit(Totals)
    end;

    /// <summary>
    /// Calculates the year-to-date sales for a customer using fiscal year totals.
    /// </summary>
    /// <param name="CustNo">Specifies the customer number to calculate year-to-date sales for.</param>
    /// <returns>The year-to-date sales amount in local currency.</returns>
    procedure GetYTDSales(CustNo: Code[20]): Decimal
    var
        Totals: Decimal;
    begin
        FiscalYearTotals := true;
        Totals := GetTotalSales(CustNo);
        FiscalYearTotals := false;
        exit(Totals);
    end;


    /// <summary>
    /// Searches for duplicate external document numbers in sales documents and posted documents.
    /// </summary>
    /// <param name="OriginalSalesHeader">Specifies the sales header to search for matching external document numbers.</param>
    /// <returns>True if a duplicate external document number is found, otherwise false.</returns>
    procedure SearchForExternalDocNo(var OriginalSalesHeader: Record "Sales Header"): Boolean
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        IsHandled: Boolean;
        ResultFound: Boolean;
    begin
        OnBeforeSearchForExternalDocNo(OriginalSalesHeader, ResultFound, IsHandled);
        if IsHandled then
            exit(ResultFound);

        SalesHeader.SetLoadFields("Document Type", "No.", "Sell-to Customer No.", "External Document No.");
        SalesHeader.SetRange("Document Type", OriginalSalesHeader."Document Type");
        SalesHeader.SetFilter("No.", '<>%1', OriginalSalesHeader."No.");
        SalesHeader.SetRange("Sell-to Customer No.", OriginalSalesHeader."Sell-to Customer No.");
        SalesHeader.SetRange("External Document No.", OriginalSalesHeader."External Document No.");
        if not SalesHeader.IsEmpty() then
            exit(true);

        case OriginalSalesHeader."Document Type" of
            OriginalSalesHeader."Document Type"::Invoice, OriginalSalesHeader."Document Type"::Order:
                begin
                    SalesInvoiceHeader.SetLoadFields("Sell-to Customer No.", "External Document No.");
                    SalesInvoiceHeader.SetRange("Sell-to Customer No.", OriginalSalesHeader."Sell-to Customer No.");
                    SalesInvoiceHeader.SetRange("External Document No.", OriginalSalesHeader."External Document No.");
                    exit(not SalesInvoiceHeader.IsEmpty());
                end;
            OriginalSalesHeader."Document Type"::"Credit Memo":
                begin
                    SalesCrMemoHeader.SetLoadFields("Sell-to Customer No.", "External Document No.");
                    SalesCrMemoHeader.SetRange("Sell-to Customer No.", OriginalSalesHeader."Sell-to Customer No.");
                    SalesCrMemoHeader.SetRange("External Document No.", OriginalSalesHeader."External Document No.");
                    exit(not SalesCrMemoHeader.IsEmpty());
                end;
        end;
    end;

    /// <summary>
    /// Calculates the ship-to and bill-to options based on the sales header address information.
    /// </summary>
    /// <param name="ShipToOptions">Returns the calculated ship-to option based on address comparison.</param>
    /// <param name="BillToOptions">Returns the calculated bill-to option based on customer and address comparison.</param>
    /// <param name="SalesHeader">Specifies the sales header to evaluate for ship-to and bill-to options.</param>
    procedure CalculateShipBillToOptions(var ShipToOptions: Enum "Sales Ship-to Options"; var BillToOptions: Enum "Sales Bill-to Options"; var SalesHeader: Record "Sales Header")
    var
        ShipToNameEqualsSellToName: Boolean;
    begin
        ShipToNameEqualsSellToName :=
            (SalesHeader."Ship-to Name" = SalesHeader."Sell-to Customer Name") and (SalesHeader."Ship-to Name 2" = SalesHeader."Sell-to Customer Name 2");

        case true of
            (SalesHeader."Ship-to Code" = '') and ShipToNameEqualsSellToName and SalesHeader.ShipToAddressEqualsSellToAddress():
                ShipToOptions := ShipToOptions::"Default (Sell-to Address)";
            (SalesHeader."Ship-to Code" = '') and (not ShipToNameEqualsSellToName or not SalesHeader.ShipToAddressEqualsSellToAddress()):
                ShipToOptions := ShipToOptions::"Custom Address";
            SalesHeader."Ship-to Code" <> '':
                ShipToOptions := ShipToOptions::"Alternate Shipping Address";
        end;

        case true of
            (SalesHeader."Bill-to Customer No." = SalesHeader."Sell-to Customer No.") and SalesHeader.BillToAddressEqualsSellToAddress():
                BillToOptions := BillToOptions::"Default (Customer)";
            (SalesHeader."Bill-to Customer No." = SalesHeader."Sell-to Customer No.") and (not SalesHeader.BillToAddressEqualsSellToAddress()):
                BillToOptions := BillToOptions::"Custom Address";
            SalesHeader."Bill-to Customer No." <> SalesHeader."Sell-to Customer No.":
                BillToOptions := BillToOptions::"Another Customer";
        end;

        OnAfterCalculateShipBillToOptions(ShipToOptions, BillToOptions, SalesHeader);
    end;

    /// <summary>
    /// Raised after setting filters for posted customer ledger entries.
    /// </summary>
    /// <param name="CustLedgEntry">The customer ledger entry record with filters applied.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetFilterForPostedDocs(var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

    /// <summary>
    /// Raised after setting filters for unposted sales lines.
    /// </summary>
    /// <param name="SalesLine">The sales line record with filters applied.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetFilterForUnpostedLines(var SalesLine: Record "Sales Line")
    begin
    end;

    /// <summary>
    /// Raised before calculating the total sales for a customer.
    /// </summary>
    /// <param name="CustNo">The customer number.</param>
    /// <param name="Result">Set to the result to override the calculation.</param>
    /// <param name="IsHandled">Set to true to skip the default calculation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetTotalSales(CustNo: Code[20]; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised to allow skipping the date filter setting for current year calculations.
    /// </summary>
    /// <param name="SkipSetFilter">Set to true to skip the date filter.</param>
    [IntegrationEvent(false, false)]
    local procedure SkipSettingFilter(var SkipSetFilter: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after calculating the ship-to and bill-to options for a sales header.
    /// </summary>
    /// <param name="ShipToOptions">The calculated ship-to option that can be modified.</param>
    /// <param name="BillToOptions">The calculated bill-to option that can be modified.</param>
    /// <param name="SalesHeader">The sales header used for the calculation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateShipBillToOptions(var ShipToOptions: Enum "Sales Ship-to Options"; var BillToOptions: Enum "Sales Bill-to Options"; SalesHeader: Record "Sales Header")
    begin
    end;

    /// <summary>
    /// Raised before searching for duplicate external document numbers.
    /// </summary>
    /// <param name="OriginalSalesHeader">The sales header to check for duplicates.</param>
    /// <param name="ResultFound">Set to true if a duplicate was found.</param>
    /// <param name="IsHandled">Set to true to skip the default search.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSearchForExternalDocNo(var OriginalSalesHeader: Record "Sales Header"; var ResultFound: Boolean; var IsHandled: Boolean)
    begin
    end;


    /// <summary>
    /// Raised before calculating customer statistics using current customer field values.
    /// </summary>
    /// <param name="Customer">The customer record.</param>
    /// <param name="AdjmtCostLCY">The adjusted cost in local currency to override.</param>
    /// <param name="AdjCustProfit">The adjusted customer profit to override.</param>
    /// <param name="AdjProfitPct">The adjusted profit percentage to override.</param>
    /// <param name="CustInvDiscAmountLCY">The invoice discount amount to override.</param>
    /// <param name="CustPaymentsLCY">The customer payments to override.</param>
    /// <param name="CustSalesLCY">The customer sales to override.</param>
    /// <param name="CustProfit">The customer profit to override.</param>
    /// <param name="IsHandled">Set to true to skip the default calculation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateStatisticsWithCurrentCustomerValues(var Customer: Record Customer; var AdjmtCostLCY: Decimal; var AdjCustProfit: Decimal; var AdjProfitPct: Decimal; var CustInvDiscAmountLCY: Decimal; var CustPaymentsLCY: Decimal; var CustSalesLCY: Decimal; var CustProfit: Decimal; var IsHandled: Boolean)
    begin
    end;
}
