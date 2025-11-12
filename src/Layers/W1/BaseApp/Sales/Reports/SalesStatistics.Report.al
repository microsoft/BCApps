// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Inventory.Costing;
using Microsoft.Sales.Customer;
using Microsoft.Utilities;

report 112 "Sales Statistics"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Sales/Reports/SalesStatistics.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Sales Statistics';
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;
    DataAccessIntent = ReadOnly;

    dataset
    {
        dataitem(Customer; Customer)
        {
            RequestFilterFields = "No.", "Search Name", "Customer Posting Group", "Currency Code";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(CustTableCaptCustFilter; TableCaption + ': ' + CustFilter)
            {
            }
            column(CustFilter; CustFilter)
            {
            }
            column(PeriodStartDate2; Format(PeriodStartDate[2]))
            {
            }
            column(PeriodStartDate3; Format(PeriodStartDate[3]))
            {
            }
            column(PeriodStartDate4; Format(PeriodStartDate[4]))
            {
            }
            column(PeriodStartDate31; Format(PeriodStartDate[3] - 1))
            {
            }
            column(PeriodStartDate41; Format(PeriodStartDate[4] - 1))
            {
            }
            column(PeriodStartDate51; Format(PeriodStartDate[5] - 1))
            {
            }
            column(No_Customer; "No.")
            {
                IncludeCaption = true;
            }
            column(Name_Customer; Name)
            {
                IncludeCaption = true;
            }
            column(CustSalesLCY1; CustSalesLCY[1])
            {
                AutoFormatType = 1;
            }
            column(CustSalesLCY2; CustSalesLCY[2])
            {
                AutoFormatType = 1;
            }
            column(CustSalesLCY3; CustSalesLCY[3])
            {
                AutoFormatType = 1;
            }
            column(CustSalesLCY4; CustSalesLCY[4])
            {
                AutoFormatType = 1;
            }
            column(CustSalesLCY5; CustSalesLCY[5])
            {
                AutoFormatType = 1;
            }
            column(CustProfitLCY1; CustProfitLCY[1])
            {
                AutoFormatType = 1;
            }
            column(CustProfitLCY2; CustProfitLCY[2])
            {
                AutoFormatType = 1;
            }
            column(CustProfitLCY3; CustProfitLCY[3])
            {
                AutoFormatType = 1;
            }
            column(CustProfitLCY4; CustProfitLCY[4])
            {
                AutoFormatType = 1;
            }
            column(CustProfitLCY5; CustProfitLCY[5])
            {
                AutoFormatType = 1;
            }
            column(ProfitPct1; ProfitPct[1])
            {
                DecimalPlaces = 1 : 1;
            }
            column(ProfitPct2; ProfitPct[2])
            {
                DecimalPlaces = 1 : 1;
            }
            column(ProfitPct3; ProfitPct[3])
            {
                DecimalPlaces = 1 : 1;
            }
            column(ProfitPct4; ProfitPct[4])
            {
                DecimalPlaces = 1 : 1;
            }
            column(ProfitPct5; ProfitPct[5])
            {
                DecimalPlaces = 1 : 1;
            }
            column(CustInvDiscAmountLCY1; CustInvDiscAmountLCY[1])
            {
                AutoFormatType = 1;
            }
            column(CustInvDiscAmountLCY2; CustInvDiscAmountLCY[2])
            {
                AutoFormatType = 1;
            }
            column(CustInvDiscAmountLCY3; CustInvDiscAmountLCY[3])
            {
                AutoFormatType = 1;
            }
            column(CustInvDiscAmountLCY4; CustInvDiscAmountLCY[4])
            {
                AutoFormatType = 1;
            }
            column(CustInvDiscAmountLCY5; CustInvDiscAmountLCY[5])
            {
                AutoFormatType = 1;
            }
            column(CustPaymentDiscLCY1; CustPaymentDiscLCY[1])
            {
                AutoFormatType = 1;
            }
            column(CustPaymentDiscLCY2; CustPaymentDiscLCY[2])
            {
                AutoFormatType = 1;
            }
            column(CustPaymentDiscLCY3; CustPaymentDiscLCY[3])
            {
                AutoFormatType = 1;
            }
            column(CustPaymentDiscLCY4; CustPaymentDiscLCY[4])
            {
                AutoFormatType = 1;
            }
            column(CustPaymentDiscLCY5; CustPaymentDiscLCY[5])
            {
                AutoFormatType = 1;
            }
            column(CustPaymentDiscTolLCY2; CustPaymentDiscTolLCY[2])
            {
                AutoFormatType = 1;
            }
            column(CustPaymentDiscTolLCY3; CustPaymentDiscTolLCY[3])
            {
                AutoFormatType = 1;
            }
            column(CustPaymentDiscTolLCY4; CustPaymentDiscTolLCY[4])
            {
                AutoFormatType = 1;
            }
            column(CustPaymentDiscTolLCY5; CustPaymentDiscTolLCY[5])
            {
                AutoFormatType = 1;
            }
            column(CustPaymentDiscTolLCY1; CustPaymentDiscTolLCY[1])
            {
                AutoFormatType = 1;
            }
            column(CustPaymentTolLCY2; CustPaymentTolLCY[2])
            {
                AutoFormatType = 1;
            }
            column(CustPaymentTolLCY3; CustPaymentTolLCY[3])
            {
                AutoFormatType = 1;
            }
            column(CustPaymentTolLCY4; CustPaymentTolLCY[4])
            {
                AutoFormatType = 1;
            }
            column(CustPaymentTolLCY5; CustPaymentTolLCY[5])
            {
                AutoFormatType = 1;
            }
            column(CustPaymentTolLCY1; CustPaymentTolLCY[1])
            {
                AutoFormatType = 1;
            }
            column(CustSalesLCY5CustProfLCY5; CustSalesLCY[5] - CustProfitLCY[5])
            {
                AutoFormatType = 1;
            }
            column(CustSalesLCY4CustProfLCY4; CustSalesLCY[4] - CustProfitLCY[4])
            {
                AutoFormatType = 1;
            }
            column(CustSalesLCY3CustProfLCY3; CustSalesLCY[3] - CustProfitLCY[3])
            {
                AutoFormatType = 1;
            }
            column(CustSalesLCY2CustProfLCY2; CustSalesLCY[2] - CustProfitLCY[2])
            {
                AutoFormatType = 1;
            }
            column(CustSalesLCY1CustProfLCY1; CustSalesLCY[1] - CustProfitLCY[1])
            {
                AutoFormatType = 1;
            }
            column(AdjProfitPct1; AdjProfitPct[1])
            {
                DecimalPlaces = 1 : 1;
            }
            column(AdjProfitPct2; AdjProfitPct[2])
            {
                DecimalPlaces = 1 : 1;
            }
            column(AdjProfitPct3; AdjProfitPct[3])
            {
                DecimalPlaces = 1 : 1;
            }
            column(AdjProfitPct4; AdjProfitPct[4])
            {
                DecimalPlaces = 1 : 1;
            }
            column(AdjProfitPct5; AdjProfitPct[5])
            {
                DecimalPlaces = 1 : 1;
            }
            column(AdjCustProfitLCY1; AdjCustProfitLCY[1])
            {
                AutoFormatType = 1;
            }
            column(AdjCustProfitLCY2; AdjCustProfitLCY[2])
            {
                AutoFormatType = 1;
            }
            column(AdjCustProfitLCY3; AdjCustProfitLCY[3])
            {
                AutoFormatType = 1;
            }
            column(AdjCustProfitLCY4; AdjCustProfitLCY[4])
            {
                AutoFormatType = 1;
            }
            column(AdjCustProfitLCY5; AdjCustProfitLCY[5])
            {
                AutoFormatType = 1;
            }
            column(CustSalProfAdjmtCostLCY5; CustSalesLCY[5] - CustProfitLCY[5] - AdjmtCostLCY[5])
            {
                AutoFormatType = 1;
            }
            column(CustSalProfAdjmtCostLCY4; CustSalesLCY[4] - CustProfitLCY[4] - AdjmtCostLCY[4])
            {
                AutoFormatType = 1;
            }
            column(CustSalProfAdjmtCostLCY3; CustSalesLCY[3] - CustProfitLCY[3] - AdjmtCostLCY[3])
            {
                AutoFormatType = 1;
            }
            column(CustSalProfAdjmtCostLCY2; CustSalesLCY[2] - CustProfitLCY[2] - AdjmtCostLCY[2])
            {
                AutoFormatType = 1;
            }
            column(CustSalProfAdjmtCostLCY1; CustSalesLCY[1] - CustProfitLCY[1] - AdjmtCostLCY[1])
            {
                AutoFormatType = 1;
            }
            column(AdjmtCostLCY5; -AdjmtCostLCY[5])
            {
                AutoFormatType = 1;
            }
            column(AdjmtCostLCY4; -AdjmtCostLCY[4])
            {
                AutoFormatType = 1;
            }
            column(AdjmtCostLCY3; -AdjmtCostLCY[3])
            {
                AutoFormatType = 1;
            }
            column(AdjmtCostLCY2; -AdjmtCostLCY[2])
            {
                AutoFormatType = 1;
            }
            column(AdjmtCostLCY1; -AdjmtCostLCY[1])
            {
                AutoFormatType = 1;
            }
            column(AdjmtCostLCY1Control163; AdjmtCostLCY[1])
            {
                AutoFormatType = 1;
            }
            column(SalesStatisticsCaption; SalesStatisticsCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(beforeCaption; beforeCaptionLbl)
            {
            }
            column(afterCaption; afterCaptionLbl)
            {
            }
            column(CustSalesLCY1Caption; CustSalesLCY1CaptionLbl)
            {
            }
            column(CustProfitLCY1Caption; CustProfitLCY1CaptionLbl)
            {
            }
            column(ProfitPct1Caption; ProfitPct1CaptionLbl)
            {
            }
            column(CustInvDiscAmountLCY1Caption; CustInvDiscAmountLCY1CaptionLbl)
            {
            }
            column(CustPaymentDiscLCY1Caption; CustPaymentDiscLCY1CaptionLbl)
            {
            }
            column(CustPaymentDiscTolLCY1Caption; CustPaymentDiscTolLCY1CaptionLbl)
            {
            }
            column(CustPaymentTolLCY1Caption; CustPaymentTolLCY1CaptionLbl)
            {
            }
            column(CustSalesLCY1CustProfitLCY1Caption; CustSalesLCY1CustProfitLCY1CaptionLbl)
            {
            }
            column(AdjProfitPct1Caption; AdjProfitPct1CaptionLbl)
            {
            }
            column(AdjCustProfitLCY1Caption; AdjCustProfitLCY1CaptionLbl)
            {
            }
            column(AdjustedCostsLCYCaption; AdjustedCostsLCYCaptionLbl)
            {
            }
            column(AdjmtCostLCY1Caption; AdjmtCostLCY1CaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            var
                CostCalcMgt: Codeunit "Cost Calculation Management";
            begin
                PrintCust := false;
                for i := 1 to 5 do begin
                    SetRange("Date Filter", PeriodStartDate[i], PeriodStartDate[i + 1] - 1);
                    CalcFields(
                      "Sales (LCY)", "Profit (LCY)", "Inv. Discounts (LCY)", "Pmt. Discounts (LCY)",
                      "Pmt. Disc. Tolerance (LCY)", "Pmt. Tolerance (LCY)");
                    CustSalesLCY[i] := "Sales (LCY)";
                    CustProfitLCY[i] := "Profit (LCY)";
                    AdjmtCostLCY[i] :=
                      "Sales (LCY)" - CustProfitLCY[i] + CostCalcMgt.CalcCustActualCostLCY(Customer) + CostCalcMgt.NonInvtblCostAmt(Customer);
                    AdjCustProfitLCY[i] := CustProfitLCY[i] + AdjmtCostLCY[i];

                    if CustSalesLCY[i] = 0 then begin
                        ProfitPct[i] := 0;
                        AdjProfitPct[i] := 0;
                    end else begin
                        ProfitPct[i] := CustProfitLCY[i] / CustSalesLCY[i] * 100;
                        AdjProfitPct[i] := AdjCustProfitLCY[i] / CustSalesLCY[i] * 100;
                    end;

                    CustInvDiscAmountLCY[i] := "Inv. Discounts (LCY)";
                    CustPaymentDiscLCY[i] := "Pmt. Discounts (LCY)";
                    CustPaymentDiscTolLCY[i] := "Pmt. Disc. Tolerance (LCY)";
                    CustPaymentTolLCY[i] := "Pmt. Tolerance (LCY)";
                    if (CustSalesLCY[i] <> 0) or (CustProfitLCY[i] <> 0) or
                       (CustInvDiscAmountLCY[i] <> 0) or (CustPaymentDiscLCY[i] <> 0) or
                       (CustPaymentDiscTolLCY[i] <> 0) or (CustPaymentTolLCY[i] <> 0)
                    then
                        PrintCust := true;
                end;
                if not PrintCust then
                    CurrReport.Skip();
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Sales Statistics';
        AboutText = 'Analyze earnings from an individual customer or trends in earnings.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(StartingDate; PeriodStartDate[2])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';
                    }
                    field(PeriodLength; PeriodLengthReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period Length';
                        ToolTip = 'Specifies the period for which data is shown in the report. For example, enter "1M" for one month, "30D" for thirty days, "3Q" for three quarters, or "5Y" for five years.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if PeriodStartDate[2] = 0D then
                PeriodStartDate[2] := WorkDate();
            if Format(PeriodLengthReq) = '' then
                Evaluate(PeriodLengthReq, '<1M>');
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        FormatDocument: Codeunit "Format Document";
    begin
        CustFilter := FormatDocument.GetRecordFiltersWithCaptions(Customer);
        for i := 2 to 4 do
            PeriodStartDate[i + 1] := CalcDate(PeriodLengthReq, PeriodStartDate[i]);
        PeriodStartDate[6] := DMY2Date(31, 12, 9999);
    end;

    var
        PeriodLengthReq: DateFormula;
        PeriodStartDate: array[6] of Date;
        CustFilter: Text;
        ProfitPct: array[5] of Decimal;
        AdjProfitPct: array[5] of Decimal;
        CustProfitLCY: array[5] of Decimal;
        AdjCustProfitLCY: array[5] of Decimal;
        AdjmtCostLCY: array[5] of Decimal;
        CustInvDiscAmountLCY: array[5] of Decimal;
        CustPaymentDiscLCY: array[5] of Decimal;
        CustPaymentDiscTolLCY: array[5] of Decimal;
        CustPaymentTolLCY: array[5] of Decimal;
        CustSalesLCY: array[5] of Decimal;
        PrintCust: Boolean;
        i: Integer;
        SalesStatisticsCaptionLbl: Label 'Sales Statistics';
        CurrReportPageNoCaptionLbl: Label 'Page';
        beforeCaptionLbl: Label '...before';
        afterCaptionLbl: Label 'after...';
        CustSalesLCY1CaptionLbl: Label 'Sales (LCY)';
        CustProfitLCY1CaptionLbl: Label 'Original Profit (LCY)';
        ProfitPct1CaptionLbl: Label 'Original Profit %';
        CustInvDiscAmountLCY1CaptionLbl: Label 'Inv. Discounts (LCY)';
        CustPaymentDiscLCY1CaptionLbl: Label 'Pmt. Discounts (LCY)';
        CustPaymentDiscTolLCY1CaptionLbl: Label 'Pmt. Disc Tol. (LCY)';
        CustPaymentTolLCY1CaptionLbl: Label 'Pmt. Tolerances (LCY)';
        CustSalesLCY1CustProfitLCY1CaptionLbl: Label 'Original Costs (LCY)';
        AdjProfitPct1CaptionLbl: Label 'Adjusted Profit %';
        AdjCustProfitLCY1CaptionLbl: Label 'Adjusted Profit (LCY)';
        AdjustedCostsLCYCaptionLbl: Label 'Adjusted Costs (LCY)';
        AdjmtCostLCY1CaptionLbl: Label 'Cost Adjmt. Amounts (LCY)';
        TotalCaptionLbl: Label 'Total';
}

