// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

/// <summary>
/// Calculates and displays commission amounts for salespeople based on customer ledger entries and configured commission percentages.
/// </summary>

using Microsoft.CRM.Team;
using Microsoft.Inventory.Costing;
using Microsoft.Sales.Receivables;
using System.Utilities;

report 115 "Salesperson - Commission"
{
    ApplicationArea = Suite;
    Caption = 'Salesperson - Commission';
    ToolTip = 'View a list of invoices for each salesperson for a selected period. The following information is shown for each invoice: Customer number, sales amount, profit amount, and the commission on sales amount and profit amount. The report also shows the adjusted profit and the adjusted profit commission, which are the profit figures that reflect any changes to the original costs of the goods sold.';
    DefaultRenderingLayout = Excel;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Salesperson/Purchaser"; "Salesperson/Purchaser")
        {
            DataItemTableView = sorting(Code);
            PrintOnlyIfDetail = true;
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
            column(Salesperson_Purchaser_Code; Code)
            {
            }
            column(Salesperson_Purchaser_Name; Name)
            {
            }
            column(Salesperson_Purchaser__Commission___; "Commission %")
            {
            }
            dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
            {
                DataItemLink = "Salesperson Code" = field(Code);
                DataItemTableView = sorting("Salesperson Code", "Posting Date") where("Document Type" = filter(Invoice | "Credit Memo"));
                RequestFilterFields = "Posting Date";
                column(Cust__Ledger_Entry__Posting_Date_; Format("Posting Date"))
                {
                }
                column(Cust__Ledger_Entry__Document_No__; "Document No.")
                {
                }
                column(Cust__Ledger_Entry__Customer_No__; "Customer No.")
                {
                }
                column(Cust__Ledger_Entry__Sales__LCY__; "Sales (LCY)")
                {
                }
                column(Cust__Ledger_Entry__Profit__LCY__; "Profit (LCY)")
                {
                }
                column(CustLedgerEntry_CustomerName; "Customer Name")
                {
                }
                column(SalesCommissionAmt_Control32; SalesCommissionAmt)
                {
                    AutoFormatType = 1;
                }
                column(ProfitCommissionAmt_Control33; ProfitCommissionAmt)
                {
                    AutoFormatType = 1;
                }
                column(AdjProfit_Control39; AdjProfit)
                {
                    AutoFormatType = 1;
                }
                column(AdjProfitCommissionAmt_Control45; AdjProfitCommissionAmt)
                {
                    AutoFormatType = 1;
                }
                column(SalespersonPurchaser_Code; "Salesperson/Purchaser".Code)
                {
                    IncludeCaption = true;
                }
                column(Salesperson_Purchaser__Name; "Salesperson/Purchaser".Name)
                {
                    IncludeCaption = true;
                }

                trigger OnAfterGetRecord()
                var
                    CostCalcMgt: Codeunit "Cost Calculation Management";
                begin
                    SalesCommissionAmt := Round("Sales (LCY)" * "Salesperson/Purchaser"."Commission %" / 100);
                    ProfitCommissionAmt := Round("Profit (LCY)" * "Salesperson/Purchaser"."Commission %" / 100);
                    AdjProfit := "Profit (LCY)" + CostCalcMgt.CalcCustLedgAdjmtCostLCY("Cust. Ledger Entry");
                    AdjProfitCommissionAmt := Round(AdjProfit * "Salesperson/Purchaser"."Commission %" / 100);
                    // Calculate SubTotals for Word Layout
                    SubtotalsSales += "Sales (LCY)";
                    SubtotalsProfit += "Profit (LCY)";
                    SubtotalsAdjProfit += AdjProfit;
                    SubtotalsSalesCommission += SalesCommissionAmt;
                    SubtotalsProfitCommission += ProfitCommissionAmt;
                    SubtotalsAdjProfitCommission += AdjProfitCommissionAmt;
                    // Calculate Grand Totals for Word Layout
                    TotalsSales += "Sales (LCY)";
                    TotalsProfit += "Profit (LCY)";
                    TotalsAdjProfit += AdjProfit;
                    TotalsSalesCommission += SalesCommissionAmt;
                    TotalsProfitCommission += ProfitCommissionAmt;
                    TotalsAdjProfitCommission += AdjProfitCommissionAmt;

                    if not ReportHasData then
                        ReportHasData := true;
                end;

                trigger OnPreDataItem()
                begin
                    ClearAmounts();
                end;
            }
            dataitem(Subtotals; Integer)
            {
                DataItemTableView = sorting(Number) where(Number = const(1));

                // Used for test cases mapping
                column(Subtotals_Salesperson_Code; "Salesperson/Purchaser".Code)
                {
                }
                column(Subtotals_Sales; SubtotalsSales)
                {
                    AutoFormatType = 1;
                }
                column(Subtotals_Profit; SubtotalsProfit)
                {
                    AutoFormatType = 1;
                }
                column(Subtotals_AdjProfit; SubtotalsAdjProfit)
                {
                    AutoFormatType = 1;
                }
                column(Subtotals_SalesCommission; SubtotalsSalesCommission)
                {
                    AutoFormatType = 1;
                }
                column(Subtotals_ProfitCommission; SubtotalsProfitCommission)
                {
                    AutoFormatType = 1;
                }
                column(Subtotals_AdjProfitCommission; SubtotalsAdjProfitCommission)
                {
                    AutoFormatType = 1;
                }

                trigger OnPreDataItem()
                begin
                    if "Cust. Ledger Entry".IsEmpty() then
                        CurrReport.Break();
                end;
            }

            trigger OnAfterGetRecord()
            begin
#if not CLEAN28
                if PrintOnlyOnePerPageReq then
                    PageGroupNo := PageGroupNo + 1;
#endif

                // Reset SubTotals for Word Layout
                SubtotalsSales := 0;
                SubtotalsProfit := 0;
                SubtotalsAdjProfit := 0;
                SubtotalsSalesCommission := 0;
                SubtotalsProfitCommission := 0;
                SubtotalsAdjProfitCommission := 0;
            end;

            trigger OnPreDataItem()
            begin
                PageGroupNo := 1;
                ClearAmounts();
            end;
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
            column(Totals_SalesCommission; TotalsSalesCommission)
            {
                AutoFormatType = 1;
            }
            column(Totals_ProfitCommission; TotalsProfitCommission)
            {
                AutoFormatType = 1;
            }
            column(Totals_AdjProfitCommission; TotalsAdjProfitCommission)
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
        AboutTitle = 'About Salesperson - Commission';
        AboutText = 'Analyze the commissions by salesperson. See the customer, document, sales amounts and profit amounts provided by a salesperson''s contributions.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
#if not CLEAN28
                    field(PrintOnlyOnePerPage; PrintOnlyOnePerPageReq)
                    {
                        ApplicationArea = Suite;
                        Caption = 'New Page per Person';
                        ToolTip = 'Specifies if each person''s information is printed on a new page if you have chosen two or more persons to be included in the report.';
                        ObsoleteState = Pending;
                        ObsoleteReason = 'The New Page per Person option is only supported by the RDLC layout which has been deprecated.';
                        ObsoleteTag = '28.0';
                        Visible = false;
                    }
#endif
                    // Used to set the Period on the report header across multiple languages
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
            Caption = 'Salesperson Commission Excel';
            Type = Excel;
            LayoutFile = './Sales/Reports/SalespersonCommission.xlsx';
            Summary = 'Report layout primarily made for data analysis. Use an Excel editor to modify the layout.';
        }
        layout(Word)
        {
            Caption = 'Salesperson Commission Word';
            Type = Word;
            LayoutFile = './Sales/Reports/SalespersonCommission.docx';
            Summary = 'Report layout made for print. Use a Word editor to modify the layout.';
        }
    }

    labels
    {
        SalespersonCommissionLabel = 'Salesperson - Commission';
        SalespersonCommissionPrint = 'Salesperson Commission (Print)', MaxLength = 31, Comment = 'Excel worksheet name.';
        SalespersonCommissionAnalysis = 'Salesp. Commission (Analysis)', MaxLength = 31, Comment = 'Excel worksheet name.';
        DataRetrieved = 'Data retrieved:';
        PeriodCaption = 'Period:';
        DocumentNoLabel = 'Document No.';
        CustomerNoLabel = 'Customer No.';
        CustomerNameLabel = 'Customer Name';
        SalesLabel = 'Sales (LCY)';
        ProfitLabel = 'Profit (LCY)';
        PostingDateLabel = 'Posting Date';
        SalesCommissionLabel = 'Sales Commission (LCY)';
        ProfitCommissionLabel = 'Profit Commission (LCY)';
        AdjustedProfitLabel = 'Adjusted Profit (LCY)';
        AdjustedProfitCommissionLabel = 'Adjusted Profit Commission (LCY)';
        CommissionPercentLabel = 'Commission %';
        AllAmountsAreInLCYLabel = 'All amounts are in LCY';
        TotalsCaption = 'Total';
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
        // Ensures Layout Filter Headings are up to date
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
        ProfitCommissionAmt: Decimal;
        AdjProfitCommissionAmt: Decimal;
        SalesCommissionAmt: Decimal;
#if not CLEAN28
        PrintOnlyOnePerPageReq: Boolean;
#endif
        PageGroupNo: Integer;
        // SubTotals for the Word Layout
        SubtotalsSales: Decimal;
        SubtotalsProfit: Decimal;
        SubtotalsAdjProfit: Decimal;
        SubtotalsSalesCommission: Decimal;
        SubtotalsProfitCommission: Decimal;
        SubtotalsAdjProfitCommission: Decimal;
        // Grand Totals for the Word Layout
        TotalsSales: Decimal;
        TotalsProfit: Decimal;
        TotalsAdjProfit: Decimal;
        TotalsSalesCommission: Decimal;
        TotalsProfitCommission: Decimal;
        TotalsAdjProfitCommission: Decimal;
        ReportHasData: Boolean;

    local procedure ClearAmounts()
    begin
        Clear(AdjProfit);
        Clear(ProfitCommissionAmt);
        Clear(AdjProfitCommissionAmt);
        Clear(SalesCommissionAmt);
    end;

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

