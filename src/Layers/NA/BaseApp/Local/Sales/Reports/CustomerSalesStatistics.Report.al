// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Foundation.Company;
using Microsoft.Inventory.Costing;
using Microsoft.Sales.Customer;

report 10047 "Customer Sales Statistics"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Reports/CustomerSalesStatistics.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Customer Sales Statistics';
    UsageCategory = ReportsAndAnalysis;
    DataAccessIntent = ReadOnly;

    dataset
    {
        dataitem(Customer; Customer)
        {
            RequestFilterFields = "No.", "Search Name", "Customer Posting Group", "Currency Code", "Global Dimension 1 Code", "Global Dimension 2 Code", "Salesperson Code";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(TIME; Time)
            {
            }
            column(CompanyInformation_Name; CompanyInformation.Name)
            {
            }
            column(USERID; UserId)
            {
            }
            column(FilterString; FilterString)
            {
            }
            column(FilterString_Control1400000; FilterString)
            {
            }
            column(PeriodStartingDate_2_; PeriodStartingDate[2])
            {
            }
            column(PeriodStartingDate_3_; PeriodStartingDate[3])
            {
            }
            column(PeriodStartingDate_4_; PeriodStartingDate[4])
            {
            }
            column(PeriodStartingDate_2__Control14; PeriodStartingDate[2])
            {
            }
            column(PeriodStartingDate_3__1; PeriodStartingDate[3] - 1)
            {
            }
            column(PeriodStartingDate_4__1; PeriodStartingDate[4] - 1)
            {
            }
            column(PeriodStartingDate_5__1; PeriodStartingDate[5] - 1)
            {
            }
            column(PeriodStartingDate_5__1_Control18; PeriodStartingDate[5] - 1)
            {
            }
            column(Customer__No__; "No.")
            {
            }
            column(Customer_Name; Name)
            {
            }
            column(Sales___1_; "Sales$"[1])
            {
            }
            column(Sales___2_; "Sales$"[2])
            {
            }
            column(Sales___3_; "Sales$"[3])
            {
            }
            column(Sales___4_; "Sales$"[4])
            {
            }
            column(Sales___5_; "Sales$"[5])
            {
            }
            column(CostOfSales___1_; "CostOfSales$"[1])
            {
            }
            column(CostOfSales___2_; "CostOfSales$"[2])
            {
            }
            column(CostOfSales___3_; "CostOfSales$"[3])
            {
            }
            column(CostOfSales___4_; "CostOfSales$"[4])
            {
            }
            column(CostOfSales___5_; "CostOfSales$"[5])
            {
            }
            column(Profits___1_; "Profits$"[1])
            {
            }
            column(Profits___2_; "Profits$"[2])
            {
            }
            column(Profits___3_; "Profits$"[3])
            {
            }
            column(Profits___4_; "Profits$"[4])
            {
            }
            column(Profits___5_; "Profits$"[5])
            {
            }
            column(Profit___1_; "Profit%"[1])
            {
            }
            column(Profit___2_; "Profit%"[2])
            {
            }
            column(Profit___3_; "Profit%"[3])
            {
            }
            column(Profit___4_; "Profit%"[4])
            {
            }
            column(Profit___5_; "Profit%"[5])
            {
            }
            column(InvoiceDiscounts___1_; "InvoiceDiscounts$"[1])
            {
            }
            column(InvoiceDiscounts___2_; "InvoiceDiscounts$"[2])
            {
            }
            column(InvoiceDiscounts___3_; "InvoiceDiscounts$"[3])
            {
            }
            column(InvoiceDiscounts___4_; "InvoiceDiscounts$"[4])
            {
            }
            column(InvoiceDiscounts___5_; "InvoiceDiscounts$"[5])
            {
            }
            column(PaymentDiscounts___1_; "PaymentDiscounts$"[1])
            {
            }
            column(PaymentDiscounts___2_; "PaymentDiscounts$"[2])
            {
            }
            column(PaymentDiscounts___3_; "PaymentDiscounts$"[3])
            {
            }
            column(PaymentDiscounts___4_; "PaymentDiscounts$"[4])
            {
            }
            column(PaymentDiscounts___5_; "PaymentDiscounts$"[5])
            {
            }
            column(Payments___1_; "Payments$"[1])
            {
            }
            column(Payments___2_; "Payments$"[2])
            {
            }
            column(Payments___3_; "Payments$"[3])
            {
            }
            column(Payments___4_; "Payments$"[4])
            {
            }
            column(Payments___5_; "Payments$"[5])
            {
            }
            column(FinanceCharges___1_; "FinanceCharges$"[1])
            {
            }
            column(FinanceCharges___2_; "FinanceCharges$"[2])
            {
            }
            column(FinanceCharges___3_; "FinanceCharges$"[3])
            {
            }
            column(FinanceCharges___4_; "FinanceCharges$"[4])
            {
            }
            column(FinanceCharges___5_; "FinanceCharges$"[5])
            {
            }
            column(Sales___1__Control71; "Sales$"[1])
            {
            }
            column(Sales___2__Control72; "Sales$"[2])
            {
            }
            column(Sales___3__Control73; "Sales$"[3])
            {
            }
            column(Sales___4__Control74; "Sales$"[4])
            {
            }
            column(Sales___5__Control75; "Sales$"[5])
            {
            }
            column(CostOfSales___1__Control77; "CostOfSales$"[1])
            {
            }
            column(CostOfSales___2__Control78; "CostOfSales$"[2])
            {
            }
            column(CostOfSales___3__Control79; "CostOfSales$"[3])
            {
            }
            column(CostOfSales___4__Control80; "CostOfSales$"[4])
            {
            }
            column(CostOfSales___5__Control81; "CostOfSales$"[5])
            {
            }
            column(Profits___1__Control83; "Profits$"[1])
            {
            }
            column(Profits___2__Control84; "Profits$"[2])
            {
            }
            column(Profits___3__Control85; "Profits$"[3])
            {
            }
            column(Profits___4__Control86; "Profits$"[4])
            {
            }
            column(Profits___5__Control87; "Profits$"[5])
            {
            }
            column(Profit___1__Control89; "Profit%"[1])
            {
            }
            column(Profit___2__Control90; "Profit%"[2])
            {
            }
            column(Profit___3__Control91; "Profit%"[3])
            {
            }
            column(Profit___4__Control92; "Profit%"[4])
            {
            }
            column(Profit___5__Control93; "Profit%"[5])
            {
            }
            column(InvoiceDiscounts___1__Control95; "InvoiceDiscounts$"[1])
            {
            }
            column(InvoiceDiscounts___2__Control96; "InvoiceDiscounts$"[2])
            {
            }
            column(InvoiceDiscounts___3__Control97; "InvoiceDiscounts$"[3])
            {
            }
            column(InvoiceDiscounts___4__Control98; "InvoiceDiscounts$"[4])
            {
            }
            column(InvoiceDiscounts___5__Control99; "InvoiceDiscounts$"[5])
            {
            }
            column(PaymentDiscounts___1__Control101; "PaymentDiscounts$"[1])
            {
            }
            column(PaymentDiscounts___2__Control102; "PaymentDiscounts$"[2])
            {
            }
            column(PaymentDiscounts___3__Control103; "PaymentDiscounts$"[3])
            {
            }
            column(PaymentDiscounts___4__Control104; "PaymentDiscounts$"[4])
            {
            }
            column(PaymentDiscounts___5__Control105; "PaymentDiscounts$"[5])
            {
            }
            column(Payments___1__Control107; "Payments$"[1])
            {
            }
            column(Payments___2__Control108; "Payments$"[2])
            {
            }
            column(Payments___3__Control109; "Payments$"[3])
            {
            }
            column(Payments___4__Control110; "Payments$"[4])
            {
            }
            column(Payments___5__Control111; "Payments$"[5])
            {
            }
            column(FinanceCharges___1__Control113; "FinanceCharges$"[1])
            {
            }
            column(FinanceCharges___2__Control114; "FinanceCharges$"[2])
            {
            }
            column(FinanceCharges___3__Control115; "FinanceCharges$"[3])
            {
            }
            column(FinanceCharges___4__Control116; "FinanceCharges$"[4])
            {
            }
            column(FinanceCharges___5__Control117; "FinanceCharges$"[5])
            {
            }
            column(Customer_Sales_StatisticsCaption; Customer_Sales_StatisticsCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(BeforeCaption; BeforeCaptionLbl)
            {
            }
            column(AfterCaption; AfterCaptionLbl)
            {
            }
            column(Customer__No__Caption; Customer__No__CaptionLbl)
            {
            }
            column(Customer_NameCaption; FieldCaption(Name))
            {
            }
            column(SalesCaption; SalesCaptionLbl)
            {
            }
            column(Cost_of_SalesCaption; Cost_of_SalesCaptionLbl)
            {
            }
            column(Contrib__MarginCaption; Contrib__MarginCaptionLbl)
            {
            }
            column(Contrib__Ratio__Caption; Contrib__Ratio__CaptionLbl)
            {
            }
            column(Invoice_DiscountCaption; Invoice_DiscountCaptionLbl)
            {
            }
            column(Payment_DiscountCaption; Payment_DiscountCaptionLbl)
            {
            }
            column(PaymentsCaption; PaymentsCaptionLbl)
            {
            }
            column(Finance_ChargesCaption; Finance_ChargesCaptionLbl)
            {
            }
            column(Report_TotalCaption; Report_TotalCaptionLbl)
            {
            }
            column(Cost_of_SalesCaption_Control82; Cost_of_SalesCaption_Control82Lbl)
            {
            }
            column(Contrib__MarginCaption_Control88; Contrib__MarginCaption_Control88Lbl)
            {
            }
            column(Contrib__Ratio__Caption_Control94; Contrib__Ratio__Caption_Control94Lbl)
            {
            }
            column(Invoice_DiscountCaption_Control100; Invoice_DiscountCaption_Control100Lbl)
            {
            }
            column(Payment_DiscountCaption_Control106; Payment_DiscountCaption_Control106Lbl)
            {
            }
            column(PaymentsCaption_Control112; PaymentsCaption_Control112Lbl)
            {
            }
            column(Finance_ChargesCaption_Control118; Finance_ChargesCaption_Control118Lbl)
            {
            }
            column(SalesCaption_Control1; SalesCaption_Control1Lbl)
            {
            }

            trigger OnAfterGetRecord()
            var
                CostCalcMgt: Codeunit "Cost Calculation Management";
            begin
                for i := 1 to 5 do begin
                    SetRange("Date Filter", PeriodStartingDate[i], PeriodStartingDate[i + 1] - 1);
                    CalcFields("Sales (LCY)", "Profit (LCY)", "Inv. Discounts (LCY)", "Pmt. Discounts (LCY)",
                      "Fin. Charge Memo Amounts (LCY)", "Payments (LCY)");
                    "Sales$"[i] := "Sales (LCY)";
                    "Profits$"[i] := Round("Profit (LCY)" + CostCalcMgt.CalcCustAdjmtCostLCY(Customer));
                    "CostOfSales$"[i] := Round("Sales$"[i] - "Profits$"[i]);
                    if "Sales$"[i] > 0 then
                        "Profit%"[i] := Round("Profits$"[i] / "Sales$"[i] * 100, 0.1)
                    else
                        "Profit%"[i] := 0;
                    "InvoiceDiscounts$"[i] := "Inv. Discounts (LCY)";
                    "PaymentDiscounts$"[i] := "Pmt. Discounts (LCY)";
                    "Payments$"[i] := "Payments (LCY)";
                    "FinanceCharges$"[i] := "Fin. Charge Memo Amounts (LCY)";
                end;
                SetRange("Date Filter");
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field("PeriodStartingDate[2]"; PeriodStartingDate[2])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Start Date';
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';
                    }
                    field(LengthOfPeriods; PeriodLength)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Length of Periods';
                        ToolTip = 'Specifies the interval used to compute statistics. The default is 1M, or one month. You can select any period you like, such as 4D for four days or 10W for 10 weeks, and so on.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if PeriodStartingDate[2] = 0D then
                PeriodStartingDate[2] := WorkDate();
            if Format(PeriodLength) = '' then
                Evaluate(PeriodLength, '<1M>');
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if Format(PeriodLength) = '' then
            Evaluate(PeriodLength, '<1M>');
        PeriodStartingDate[1] := 0D;
        for i := 2 to 4 do
            PeriodStartingDate[i + 1] := CalcDate(PeriodLength, PeriodStartingDate[i]);
        PeriodStartingDate[6] := 99991231D;
        CompanyInformation.Get();
        FilterString := Customer.GetFilters();
    end;

    var
        FilterString: Text;
        PeriodStartingDate: array[6] of Date;
        PeriodLength: DateFormula;
        i: Integer;
        "Profit%": array[5] of Decimal;
        "Profits$": array[5] of Decimal;
        "InvoiceDiscounts$": array[5] of Decimal;
        "PaymentDiscounts$": array[5] of Decimal;
        "Sales$": array[5] of Decimal;
        "Payments$": array[5] of Decimal;
        "FinanceCharges$": array[5] of Decimal;
        "CostOfSales$": array[5] of Decimal;
        CompanyInformation: Record "Company Information";
        Customer_Sales_StatisticsCaptionLbl: Label 'Customer Sales Statistics';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        BeforeCaptionLbl: Label 'Before';
        AfterCaptionLbl: Label 'After';
        Customer__No__CaptionLbl: Label 'Customer';
        SalesCaptionLbl: Label 'Sales';
        Cost_of_SalesCaptionLbl: Label 'Cost of Sales';
        Contrib__MarginCaptionLbl: Label 'Contrib. Margin';
        Contrib__Ratio__CaptionLbl: Label 'Contrib. Ratio %';
        Invoice_DiscountCaptionLbl: Label 'Invoice Discount';
        Payment_DiscountCaptionLbl: Label 'Payment Discount';
        PaymentsCaptionLbl: Label 'Payments';
        Finance_ChargesCaptionLbl: Label 'Finance Charges';
        Report_TotalCaptionLbl: Label 'Report Total';
        Cost_of_SalesCaption_Control82Lbl: Label 'Cost of Sales';
        Contrib__MarginCaption_Control88Lbl: Label 'Contrib. Margin';
        Contrib__Ratio__Caption_Control94Lbl: Label 'Contrib. Ratio %';
        Invoice_DiscountCaption_Control100Lbl: Label 'Invoice Discount';
        Payment_DiscountCaption_Control106Lbl: Label 'Payment Discount';
        PaymentsCaption_Control112Lbl: Label 'Payments';
        Finance_ChargesCaption_Control118Lbl: Label 'Finance Charges';
        SalesCaption_Control1Lbl: Label 'Sales';
}

