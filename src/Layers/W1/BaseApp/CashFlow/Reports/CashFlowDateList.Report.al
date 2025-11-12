// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CashFlow.Reports;

using Microsoft.CashFlow.Forecast;
using System.Utilities;

report 846 "Cash Flow Date List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './CashFlow/Reports/CashFlowDateList.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Cash Flow Date List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(CashFlow; "Cash Flow Forecast")
        {
            RequestFilterFields = "No.";
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(CashFlow__No__; "No.")
            {
            }
            column(CashFlow_Description; Description)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(CashFlow_Date_ListCaption; CashFlow_Date_ListCaptionLbl)
            {
            }
            column(CashFlow__No__Caption; FieldCaption("No."))
            {
            }
            column(CashFlow_DescriptionCaption; FieldCaption(Description))
            {
            }
            dataitem(EditionPeriod; "Integer")
            {
                DataItemTableView = sorting(Number) order(ascending);
                column(NewCFSumTotal; NewCFSumTotal)
                {
                }
                column(BeforeSumTotal; BeforeSumTotal)
                {
                }
                column(Liquidity; Values[CFForecastEntry."Source Type"::"Liquid Funds".AsInteger()])
                {
                }
                column(Receivables; Values[CFForecastEntry."Source Type"::Receivables.AsInteger()])
                {
                }
                column(Sales_Orders_; Values[CFForecastEntry."Source Type"::"Sales Orders".AsInteger()])
                {
                }
                column(Service_Orders_; Values[CFForecastEntry."Source Type"::"Service Orders".AsInteger()])
                {
                }
                column(ManualRevenues; Values[CFForecastEntry."Source Type"::"Cash Flow Manual Revenue".AsInteger()])
                {
                }
                column(Payables; Values[CFForecastEntry."Source Type"::Payables.AsInteger()])
                {
                }
                column(Purchase_Orders_; Values[CFForecastEntry."Source Type"::"Purchase Orders".AsInteger()])
                {
                }
                column(ManualExpenses; Values[CFForecastEntry."Source Type"::"Cash Flow Manual Expense".AsInteger()])
                {
                }
                column(InvFixedAssets; Values[CFForecastEntry."Source Type"::"Fixed Assets Budget".AsInteger()])
                {
                }
                column(SaleFixedAssets; Values[CFForecastEntry."Source Type"::"Fixed Assets Disposal".AsInteger()])
                {
                }
                column(GLBudget; Values[CFForecastEntry."Source Type"::"G/L Budget".AsInteger()])
                {
                }
                column(EditionPeriod_Number; Number)
                {
                }
                column(Period_Number; PeriodNumber)
                {
                }
                column(Receivables_Control2; Values[CFForecastEntry."Source Type"::Receivables.AsInteger()])
                {
                }
                column(Sales_Orders__Control9; Values[CFForecastEntry."Source Type"::"Sales Orders".AsInteger()])
                {
                }
                column(Payables_Control12; Values[CFForecastEntry."Source Type"::Payables.AsInteger()])
                {
                }
                column(Purchase_Orders__Control15; Values[CFForecastEntry."Source Type"::"Purchase Orders".AsInteger()])
                {
                }
                column(ManualRevenues_Control23; Values[CFForecastEntry."Source Type"::"Cash Flow Manual Revenue".AsInteger()])
                {
                }
                column(ManualExpenses_Control25; Values[CFForecastEntry."Source Type"::"Cash Flow Manual Expense".AsInteger()])
                {
                }
                column(FORMAT_DateTo_; Format(CurrentDateTo))
                {
                }
                column(FORMAT_DateFrom_; Format(CurrentDateFrom))
                {
                }
                column(InvFixedAssets_Control49; Values[CFForecastEntry."Source Type"::"Fixed Assets Budget".AsInteger()])
                {
                }
                column(SaleFixedAssets_Control51; Values[CFForecastEntry."Source Type"::"Fixed Assets Disposal".AsInteger()])
                {
                }
                column(NewCFSumTotal_Control1; NewCFSumTotal)
                {
                }
                column(Service_Orders__Control59; Values[CFForecastEntry."Source Type"::"Service Orders".AsInteger()])
                {
                }
                column(Service_Orders__Control59Caption; Service_Orders__Control59CaptionLbl)
                {
                }
                column(Jobs; Values[CFForecastEntry."Source Type"::Job.AsInteger()])
                {
                }
                column(JobsLbl; JobsLbl)
                {
                }
                column(Taxes; Values[CFForecastEntry."Source Type"::Tax.AsInteger()])
                {
                }
                column(TaxesLbl; TaxesLbl)
                {
                }
                column(SumTotal_Control18Caption; SumTotal_Control18CaptionLbl)
                {
                }
                column(Purchase_Orders__Control15Caption; Purchase_Orders__Control15CaptionLbl)
                {
                }
                column(Payables_Control12Caption; Payables_Control12CaptionLbl)
                {
                }
                column(Sales_Orders__Control9Caption; Sales_Orders__Control9CaptionLbl)
                {
                }
                column(Receivables_Control2Caption; Receivables_Control2CaptionLbl)
                {
                }
                column(ManualRevenues_Control23Caption; ManualRevenues_Control23CaptionLbl)
                {
                }
                column(ManualExpenses_Control25Caption; ManualExpenses_Control25CaptionLbl)
                {
                }
                column(FORMAT_DateFrom_Caption; FORMAT_DateFrom_CaptionLbl)
                {
                }
                column(FORMAT_DateTo_Caption; FORMAT_DateTo_CaptionLbl)
                {
                }
                column(InvFixedAssets_Control49Caption; InvFixedAssets_Control49CaptionLbl)
                {
                }
                column(SaleFixedAssets_Control51Caption; SaleFixedAssets_Control51CaptionLbl)
                {
                }
                column(before_Caption; before_CaptionLbl)
                {
                }
                column(after_Caption; after_CaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    CalculatePeriodLine(CashFlow, Number, NewCFSumTotal);
                end;

                trigger OnPreDataItem()
                begin
                    SetRange(Number, 0, PeriodNumber + 1);
                    CashFlow.CalculateAllAmounts(0D, UserInputDateFrom - 1, Values, BeforeSumTotal);
                end;
            }
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
                    field(FromDate; UserInputDateFrom)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'From Date';
                        ToolTip = 'Specifies the first date to be included in the report.';
                    }
                    field(PeriodNumber; PeriodNumber)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Number of Intervals';
                        ToolTip = 'Specifies the number of intervals.';
                    }
                    field(Interval; Interval)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Interval Length';
                        ToolTip = 'Specifies the length of each interval, such as 1M for one month, 1W for one week, or 1D for one day.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            UserInputDateFrom := WorkDate();
        end;
    }

    labels
    {
        GLBudget_Caption = 'G/L Budget';
        Liquidity_Caption = 'Liquidity';
    }

    var
        CFForecastEntry: Record "Cash Flow Forecast Entry";
        Interval: DateFormula;
        UserInputDateFrom: Date;
        CurrentDateFrom: Date;
        CurrentDateTo: Date;
        PeriodNumber: Integer;
        Values: array[15] of Decimal;
        BeforeSumTotal: Decimal;
        NewCFSumTotal: Decimal;

        CurrReport_PAGENOCaptionLbl: Label 'Page';
        CashFlow_Date_ListCaptionLbl: Label 'Cash Flow Date List';
        Service_Orders__Control59CaptionLbl: Label 'Service Orders';
        SumTotal_Control18CaptionLbl: Label 'Cash Flow Interference';
        Purchase_Orders__Control15CaptionLbl: Label 'Purchase Orders';
        Payables_Control12CaptionLbl: Label 'Payables';
        Sales_Orders__Control9CaptionLbl: Label 'Sales Orders';
        Receivables_Control2CaptionLbl: Label 'Receivables';
        ManualRevenues_Control23CaptionLbl: Label 'Cash Flow Manual Revenues';
        ManualExpenses_Control25CaptionLbl: Label 'Cash Flow Manual Expenses';
        FORMAT_DateFrom_CaptionLbl: Label 'From';
        FORMAT_DateTo_CaptionLbl: Label 'To';
        InvFixedAssets_Control49CaptionLbl: Label 'Fixed Assets Budget';
        SaleFixedAssets_Control51CaptionLbl: Label 'Fixed Assets Disposal';
        before_CaptionLbl: Label 'Before:';
        after_CaptionLbl: Label 'After:';
        JobsLbl: Label 'Projects';
        TaxesLbl: Label 'Taxes';

    procedure InitializeRequest(FromDate: Date; NumberOfIntervals: Integer; IntervalLength: DateFormula)
    begin
        UserInputDateFrom := FromDate;
        PeriodNumber := NumberOfIntervals;
        Interval := IntervalLength;
    end;

    procedure GetPeriod(var DateFrom: Date; var DateTo: Date)
    begin
        DateFrom := CurrentDateFrom;
        DateTo := CurrentDateTo;
    end;

    local procedure CalculatePeriodLine(var CashFlowForecast: Record "Cash Flow Forecast"; Number: Integer; var NewCFSumTotal: Decimal)
    var
        CFSumTotal: Decimal;
    begin
        CashFlowForecast.SetCashFlowDateFilter(CurrentDateFrom, CurrentDateTo);
        case Number of
            0:
                begin
                    CurrentDateTo := UserInputDateFrom - 1;
                    CurrentDateFrom := 0D;
                end;
            PeriodNumber + 1:
                begin
                    CurrentDateFrom := CurrentDateTo + 1;
                    CurrentDateTo := 0D;
                end;
            else begin
                CurrentDateFrom := CurrentDateTo + 1;
                CurrentDateTo := CalcDate(Interval, CurrentDateFrom) - 1;
            end
        end;

        CashFlowForecast.CalculateAllAmounts(CurrentDateFrom, CurrentDateTo, Values, CFSumTotal);
        NewCFSumTotal := NewCFSumTotal + CFSumTotal;
    end;
}

