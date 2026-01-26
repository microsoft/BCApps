// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.CRM.Team;
using Microsoft.Foundation.Reporting;
using Microsoft.Inventory.Costing;
using Microsoft.Sales.Receivables;

report 114 "Salesperson - Sales Statistics"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Sales/Reports/SalespersonSalesStatistics.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Salesperson - Sales Statistics';
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Salesperson/Purchaser"; "Salesperson/Purchaser")
        {
            DataItemTableView = sorting(Code);
            RequestFilterFields = "Code";
            column(STRSUBSTNO_Text000_PeriodText_; StrSubstNo(Text000, PeriodText))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(USERID; UserId)
            {
            }
            column(RoundingText; RoundingText)
            {
            }
            column(RoundingNO; RoundingNO)
            {
            }
            column(Salesperson_Purchaser__TABLECAPTION__________SalespersonFilter; TableCaption + ': ' + SalespersonFilter)
            {
            }
            column(SalespersonFilter; SalespersonFilter)
            {
            }
            column(Cust__Ledger_Entry__TABLECAPTION__________CustLedgEntryFilter; "Cust. Ledger Entry".TableCaption + ': ' + CustLedgEntryFilter)
            {
            }
            column(CustLedgEntryFilter; CustLedgEntryFilter)
            {
            }
            column(Cust__Ledger_Entry___Sales__LCY__; SalesLCY)
            {
            }
            column(Cust__Ledger_Entry___Profit__LCY__; ProfitLCY)
            {
            }
            column(Cust__Ledger_Entry___Inv__Discount__LCY__; InvDiscLCY)
            {
            }
            column(Cust__Ledger_Entry___Pmt__Disc__Given__LCY__; PmtDiscGivenLCY)
            {
            }
            column(Cust__Ledger_Entry___Pmt__Tolerance__LCY__; PmtToleranceLCY)
            {
            }
            column(AdjProfit; AdjProfit)
            {
            }
            column(Salesperson_Purchaser_Code; Code)
            {
            }

            trigger OnAfterGetRecord()
            var
                [SecurityFiltering(SecurityFilter::Filtered)]
                CustLedgEntry: Record "Cust. Ledger Entry";
                CostCalculationMgt: Codeunit "Cost Calculation Management";
            begin
                SalesLCY := 0;
                ProfitLCY := 0;
                InvDiscLCY := 0;
                PmtDiscGivenLCY := 0;
                PmtToleranceLCY := 0;
                AdjProfit := 0;

                CustLedgEntry.CopyFilters("Cust. Ledger Entry");
                CustLedgEntry.SetRange("Salesperson Code", Code);
                if CustLedgEntry.FindSet() then
                    repeat
                        SalesLCY += CustLedgEntry."Sales (LCY)";
                        ProfitLCY += CustLedgEntry."Profit (LCY)";
                        InvDiscLCY += CustLedgEntry."Inv. Discount (LCY)";
                        PmtDiscGivenLCY += CustLedgEntry."Pmt. Disc. Given (LCY)";
                        PmtToleranceLCY += CustLedgEntry."Pmt. Tolerance (LCY)";
                        if CustLedgEntry."Document Type" in [CustLedgEntry."Document Type"::Invoice,
                                                             CustLedgEntry."Document Type"::"Credit Memo"]
                        then
                            AdjProfit += CustLedgEntry."Profit (LCY)" + CostCalculationMgt.CalcCustLedgAdjmtCostLCY(CustLedgEntry)
                        else
                            AdjProfit += CustLedgEntry."Profit (LCY)"
                    until CustLedgEntry.Next() = 0
                else
                    CurrReport.Skip();

                SalesLCY := ReportMgmnt.RoundAmount(SalesLCY, Rounding);
                ProfitLCY := ReportMgmnt.RoundAmount(ProfitLCY, Rounding);
                InvDiscLCY := ReportMgmnt.RoundAmount(InvDiscLCY, Rounding);
                PmtDiscGivenLCY := ReportMgmnt.RoundAmount(PmtDiscGivenLCY, Rounding);
                PmtToleranceLCY := ReportMgmnt.RoundAmount(PmtToleranceLCY, Rounding);
                AdjProfit := ReportMgmnt.RoundAmount(AdjProfit, Rounding)
            end;
        }
        dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
        {
            MaxIteration = 0;
            RequestFilterFields = "Posting Date";
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(AmountsInWhole; Rounding)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Amounts in whole';
                        ToolTip = 'Specifies if the amounts in the report are shown in whole 1000s.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
        ReportLabel = 'Salesperson - Sales Statistics';
        PageLabel = 'Page';
        AmountsInLCYLabel = 'All amounts are in LCY';
        ProfitPctLabel = 'Profit %';
        InvDiscAmountLabel = 'Invoice Disc. Amount (LCY)';
        PmtDiscGivenLabel = 'Payment Disc. Given (LCY)';
        PmtToleranceLabel = 'Pmt. Tolerance (LCY)';
        AdjProfitPctLabel = 'Adjusted Profit %';
        AdjProfitLCYLabel = 'Adjusted Profit (LCY)';
        TotalLabel = 'Total';
        SalesLCYLabel = 'Sales (LCY)';
        ProfitLCYLabel = 'Profit (LCY)';
        CodeLabel = 'Code';
    }

    trigger OnPreReport()
    begin
        "Cust. Ledger Entry".SecurityFiltering(SecurityFilter::Filtered);
        SalespersonFilter := "Salesperson/Purchaser".GetFilters();
        CustLedgEntryFilter := "Cust. Ledger Entry".GetFilters();
        PeriodText := "Cust. Ledger Entry".GetFilter("Posting Date");
        RoundingNO := Rounding;
        RoundingText := ReportMgmnt.RoundDescription(Rounding)
    end;

    var
        Text000: Label 'Period: %1';
        SalespersonFilter: Text;
        CustLedgEntryFilter: Text;
        PeriodText: Text;
        AdjProfit: Decimal;
        SalesLCY: Decimal;
        ProfitLCY: Decimal;
        InvDiscLCY: Decimal;
        PmtDiscGivenLCY: Decimal;
        PmtToleranceLCY: Decimal;
        ReportMgmnt: Codeunit "Report Management APAC";
        RoundingText: Text[50];
        Rounding: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
        RoundingNO: Integer;
}
