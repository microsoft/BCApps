// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.CRM.Team;
using Microsoft.Inventory.Costing;
using Microsoft.Sales.Receivables;
using System.Utilities;

report 114 "Salesperson - Sales Statistics"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Salesperson - Sales Statistics';
    DefaultRenderingLayout = Word;
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Salesperson/Purchaser"; "Salesperson/Purchaser")
        {
            DataItemTableView = sorting(Code);
            RequestFilterFields = "Code";
            column(STRSUBSTNO_Text000_PeriodText_; StrSubstNo(PeriodTxt, PeriodText))
            {
            }
            column(Salesperson_Purchaser__TABLECAPTION__________SalespersonFilter; SalespersonFilterHeading)
            {
            }
            column(Cust__Ledger_Entry__TABLECAPTION__________CustLedgEntryFilter; CustLedgEntryFilterHeading)
            {
            }
            column(Cust__Ledger_Entry___Sales__LCY__; SalesLCY)
            {
                AutoFormatType = 1;
            }
            column(Cust__Ledger_Entry___Profit__LCY__; ProfitLCY)
            {
                AutoFormatType = 1;
            }
            column(ProfitPercent; ProfitPercent)
            {
                AutoFormatType = 1;
            }
            column(Cust__Ledger_Entry___Inv__Discount__LCY__; InvDiscLCY)
            {
                AutoFormatType = 1;
            }
            column(Cust__Ledger_Entry___Pmt__Disc__Given__LCY__; PmtDiscGivenLCY)
            {
                AutoFormatType = 1;
            }
            column(Cust__Ledger_Entry___Pmt__Tolerance__LCY__; PmtToleranceLCY)
            {
                AutoFormatType = 1;
            }
            column(AdjProfit; AdjProfit)
            {
                AutoFormatType = 1;
            }
            column(AdjProfitPercent; AdjProfitPercent)
            {
                AutoFormatType = 1;
            }
            column(Salesperson_Purchaser_Code; Code)
            {
                IncludeCaption = true;
            }
#if not CLEAN27
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(SalespersonFilter; SalespersonFilter)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(CustLedgEntryFilter; CustLedgEntryFilter)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
#endif

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
                if CustLedgEntry.FindSet() then begin
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
                    until CustLedgEntry.Next() = 0;

                    ProfitPercent := CalculateProfitPercent(SalesLCY, ProfitLCY);
                    AdjProfitPercent := CalculateProfitPercent(SalesLCY, AdjProfit);

                    // Calculate Totals for Word Layout
                    TotalsSales += SalesLCY;
                    TotalsProfit += ProfitLCY;
                    TotalsAdjProfit += AdjProfit;
                    TotalsProfitPct := CalculateProfitPercent(TotalsSales, TotalsProfit);
                    TotalsAdjProfitPct := CalculateProfitPercent(TotalsSales, TotalsAdjProfit);
                    TotalsInvDiscAmount += InvDiscLCY;
                    TotalsPmtDiscGiven += PmtDiscGivenLCY;
                    TotalsPmtTolerance += PmtToleranceLCY;

                    if not ReportHasData then
                        ReportHasData := true;
                end else
                    CurrReport.Skip();
            end;
        }
        dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
        {
            MaxIteration = 0;
            RequestFilterFields = "Posting Date";
        }
        dataitem(Totals; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            column(Totals_Sales; TotalsSales)
            {
                AutoFormatType = 1;
            }
            column(Totals_Profit; TotalsProfit)
            {
                AutoFormatType = 1;
            }
            column(Totals_AdjProfit; TotalsAdjProfit)
            {
                AutoFormatType = 1;
            }
            column(Totals_ProfitPct; TotalsProfitPct)
            {
                AutoFormatType = 1;
            }
            column(Totals_AdjProfitPct; TotalsAdjProfitPct)
            {
                AutoFormatType = 1;
            }
            column(Totals_InvDiscAmount; TotalsInvDiscAmount)
            {
                AutoFormatType = 1;
            }
            column(Totals_PmtDiscGiven; TotalsPmtDiscGiven)
            {
                AutoFormatType = 1;
            }
            column(Totals_PmtTolerance; TotalsPmtTolerance)
            {
                AutoFormatType = 1;
            }

            trigger OnPreDataItem()
            begin
                if not ReportHasData then
                    CurrReport.Break();
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Salesperson - Sales Statistics';
        AboutText = 'Analyze the sales contributions by salesperson. Provides data on Sales, Profits, Discounts and more.';

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    // Used to set the date filter on the report header across multiple languages
                    field(RequestPeriodText; PeriodText)
                    {
                        ApplicationArea = All;
                        Caption = 'Period';
                        ToolTip = 'Specifies the Date Period applied to this report.';
                        Visible = false;
                    }
                    // Used to set the Salesperson Filter on the report header across multiple languages
                    field(RequestSalespersonFilterHeading; SalespersonFilterHeading)
                    {
                        ApplicationArea = All;
                        Caption = 'Salesperson Filter';
                        ToolTip = 'Specifies the Salesperson Filters applied to this report.';
                        Visible = false;
                    }
                    // Used to set the Cust. Ledg. Entry Filter on the report header across multiple languages
                    field(RequestCustLedgEntryFilterHeading; CustLedgEntryFilterHeading)
                    {
                        ApplicationArea = All;
                        Caption = 'Cust. Ledg. Entry Filter';
                        ToolTip = 'Specifies the Customer Ledger Entry filters applied to this report.';
                        Visible = false;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnClosePage()
        begin
            // Ensures Layout Filter Headings are up to date
            UpdateRequestPageFilterValues();
        end;
    }

    rendering
    {
        layout(Excel)
        {
            Caption = 'Salesperson Sales Statistics Excel';
            Type = Excel;
            LayoutFile = './Sales/Reports/SalespersonSalesStatistics.xlsx';
        }
        layout(Word)
        {
            Caption = 'Salesperson Sales Statistics Word';
            Type = Word;
            LayoutFile = './Sales/Reports/SalespersonSalesStatistics.docx';
        }
#if not CLEAN27
        layout(RDLC)
        {
            Caption = 'Salesperson Sales Statistics RDLC';
            Type = RDLC;
            LayoutFile = './Sales/Reports/SalespersonSalesStatistics.rdlc';
            ObsoleteState = Pending;
            ObsoleteReason = 'The RDLC layout has been replaced by the Excel and Word layouts and will be removed in a future release.';
            ObsoleteTag = '27.0';
        }
#endif
    }

    labels
    {
        ReportLabel = 'Salesperson - Sales Statistics';
        SalespersonSalesStatsPrint = 'Salesperson Sales Stats (Print)', MaxLength = 31, Comment = 'Excel worksheet name.';
        SalespersonSalesStatsAnalysis = 'Salesp. Sales Stats (Analysis)', MaxLength = 31, Comment = 'Excel worksheet name.';
        DataRetrieved = 'Data retrieved:';
        PeriodCaption = 'Period:';
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
        // About the report labels
        AboutTheReportLabel = 'About the report';
        EnvironmentLabel = 'Environment';
        CompanyLabel = 'Company';
        UserLabel = 'User';
        RunOnLabel = 'Run on';
        ReportNameLabel = 'Report name';
        DocumentationLabel = 'Documentation';
    }

    trigger OnPreReport()
    begin
        "Cust. Ledger Entry".SecurityFiltering(SecurityFilter::Filtered);
        UpdateRequestPageFilterValues();
    end;

    var
        PeriodTxt: Label 'Period: %1', Comment = '%1 - period text';
        SalespersonFilter: Text;
        CustLedgEntryFilter: Text;
        SalespersonFilterHeading: Text;
        CustLedgEntryFilterHeading: Text;
        PeriodText: Text;
        AdjProfit: Decimal;
        AdjProfitPercent: Decimal;
        SalesLCY: Decimal;
        ProfitLCY: Decimal;
        ProfitPercent: Decimal;
        InvDiscLCY: Decimal;
        PmtDiscGivenLCY: Decimal;
        PmtToleranceLCY: Decimal;
        TotalsSales: Decimal;
        TotalsProfit: Decimal;
        TotalsAdjProfit: Decimal;
        TotalsProfitPct: Decimal;
        TotalsAdjProfitPct: Decimal;
        TotalsInvDiscAmount: Decimal;
        TotalsPmtDiscGiven: Decimal;
        TotalsPmtTolerance: Decimal;
        ReportHasData: Boolean;

    procedure CalculateProfitPercent(Amount: Decimal; ProfitAmt: Decimal) ProfitPct: Decimal
    begin
        if Amount <> 0 then
            ProfitPct := Round((100 * ProfitAmt / Amount), 0.1, '=')
        else
            ProfitPct := 0;
    end;

    // Ensures Layout Filter Headings are up to date
    local procedure UpdateRequestPageFilterValues()
    begin
        SalespersonFilter := "Salesperson/Purchaser".GetFilters();
        CustLedgEntryFilter := "Cust. Ledger Entry".GetFilters();
        PeriodText := "Cust. Ledger Entry".GetFilter("Posting Date");

        SalespersonFilterHeading := '';
        CustLedgEntryFilterHeading := '';
        if SalespersonFilter <> '' then
            SalespersonFilterHeading := "Salesperson/Purchaser".TableCaption + ': ' + SalespersonFilter;
        if CustLedgEntryFilter <> '' then
            CustLedgEntryFilterHeading := "Cust. Ledger Entry".TableCaption + ': ' + CustLedgEntryFilter;
    end;
}

