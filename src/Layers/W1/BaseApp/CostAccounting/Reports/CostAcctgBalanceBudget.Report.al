// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Reports;

using Microsoft.CostAccounting.Account;

report 1138 "Cost Acctg. Balance/Budget"
{
    DefaultLayout = RDLC;
    RDLCLayout = './CostAccounting/Reports/CostAcctgBalanceBudget.rdlc';
    ApplicationArea = CostAccounting;
    Caption = 'Cost Acctg. Balance/Budget';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Cost Type"; "Cost Type")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", Type, "Budget Filter", "Cost Center Filter", "Cost Object Filter";
            column(YearHeading; YearHeading)
            {
            }
            column(YtdHeading; YtdHeading)
            {
            }
            column(FilterTxt; FilterTxt)
            {
            }
            column(ActPeriodHeading; ActPeriodHeading)
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(ActPct; ActPct)
            {
                DecimalPlaces = 1 : 1;
            }
            column(ActDiff; ActDiff)
            {
                AutoFormatType = 1;
                DecimalPlaces = 0 : 0;
            }
            column(ActBud; ActBud)
            {
                AutoFormatType = 1;
                DecimalPlaces = 0 : 0;
            }
            column(ActAmt; ActAmt)
            {
                AutoFormatType = 1;
                DecimalPlaces = 0 : 0;
            }
            column(NameIndented; PadStr('', Indentation * 2) + Name)
            {
            }
            column(No_CostType; "No.")
            {
            }
            column(YtdPct; YtdPct)
            {
                DecimalPlaces = 1 : 1;
            }
            column(YtdDiff; YtdDiff)
            {
                AutoFormatType = 1;
                DecimalPlaces = 0 : 0;
            }
            column(YtdBud; YtdBud)
            {
                AutoFormatType = 1;
                DecimalPlaces = 0 : 0;
            }
            column(YtdAmt; YtdAmt)
            {
                AutoFormatType = 1;
                DecimalPlaces = 0 : 0;
            }
            column(YearBugdet; YearBugdet)
            {
                AutoFormatType = 1;
                DecimalPlaces = 0 : 0;
            }
            column(ShareYearActPct; ShareYearActPct)
            {
                AutoFormatType = 1;
                DecimalPlaces = 1 : 1;
            }
            column(ShareYearBudPct; ShareYearBudPct)
            {
                AutoFormatType = 1;
                DecimalPlaces = 1 : 1;
            }
            column(LineType_CostType; CostTypeLineType)
            {
            }
            column(BlankLine_CostType; "Blank Line")
            {
            }
            column(PageGroupNo; PageGroupNo)
            {
            }
            column(CurrReportPAGENOCaption; CurrReportPAGENOCaptionLbl)
            {
            }
            column(CostCenterReportCaption; CostCenterReportCaptionLbl)
            {
            }
            column(ActDiffCaption; ActDiffCaptionLbl)
            {
            }
            column(ActPctCaption; ActPctCaptionLbl)
            {
            }
            column(ActBudCaption; ActBudCaptionLbl)
            {
            }
            column(ActAmtCaption; ActAmtCaptionLbl)
            {
            }
            column(PADSTRIndentation2NameCaption; PADSTRIndentation2NameCaptionLbl)
            {
            }
            column(CostTypeNoCaption; CostTypeNoCaptionLbl)
            {
            }
            column(ShareYearBudPctCaption; ShareYearBudPctCaptionLbl)
            {
            }
            column(ShareYearActPctCaption; ShareYearActPctCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                // Period
                SetRange("Date Filter", StartDate, EndDate);
                CalcFields("Net Change", "Budget Amount");
                ActAmt := "Net Change";
                ActBud := "Budget Amount";
                if ActBud < 0 then
                    ActDiff := ActBud - ActAmt
                else
                    ActDiff := ActAmt - ActBud;

                ActPct := 0;
                if ActBud <> 0 then
                    ActPct := Round(ActAmt * 100 / ActBud, 0.1);

                // YDT
                SetRange("Date Filter", YearStartDate, EndDate);
                CalcFields("Net Change", "Budget Amount");
                YtdAmt := "Net Change";
                YtdBud := "Budget Amount";

                if YtdAmt < 0 then
                    YtdDiff := YtdBud - YtdAmt
                else
                    YtdDiff := YtdAmt - YtdBud;

                YtdPct := 0;
                if YtdBud <> 0 then
                    YtdPct := Round(YtdAmt * 100 / YtdBud, 0.1);

                // Year
                SetRange("Date Filter", YearStartDate, YearEndDate);
                CalcFields("Budget Amount");
                YearBugdet := "Budget Amount";

                ShareYearActPct := 0;
                ShareYearBudPct := 0;
                if YearBugdet <> 0 then begin
                    ShareYearActPct := Round(YtdAmt * 100 / YearBugdet, 0.1);
                    ShareYearBudPct := Round(YtdBud * 100 / YearBugdet, 0.1);
                end;

                if (Type = Type::"Cost Type") and OnlyAccWithEntries and
                   (ActAmt = 0) and (ActBud = 0) and
                   (YtdAmt = 0) and (YtdBud = 0) and (YearBugdet = 0)
                then
                    CurrReport.Skip();

                PageGroupNo := NextPageGroupNo;
                if "New Page" then
                    NextPageGroupNo := PageGroupNo + 1;
                CostTypeLineType := Type.AsInteger();
            end;

            trigger OnPreDataItem()
            begin
                if (StartDate = 0D) or (EndDate = 0D) or (YearStartDate = 0D) or (YearEndDate = 0D) then
                    Error(Text000);

                if (EndDate < StartDate) or (YearEndDate < YearStartDate) then
                    Error(Text001);

                if GetFilters <> '' then
                    FilterTxt := Text002 + GetFilters();

                if (GetFilter("Cost Center Filter") = '') and (GetFilter("Cost Object Filter") = '') then
                    if not Confirm(Text003) then
                        Error('');

                if GetFilter("Budget Filter") = '' then
                    if not Confirm(Text004) then
                        Error('');

                ActPeriodHeading := StrSubstNo(Text005, StartDate, EndDate);
                YtdHeading := StrSubstNo(Text006, YearStartDate, EndDate);
                YearHeading := StrSubstNo(Text007, YearStartDate, YearEndDate);

                PageGroupNo := 1;
                NextPageGroupNo := 1;
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Cost Acctg. Balance/Budget';
        AboutText = 'The **Cost Acctg. Balance/Budget** report summarizes balances in cost accounts and budget figures, with filters for fiscal year, cost type, or budget version to enhance accuracy. Use it for analyzing cost and budget balances to support financial planning, control, and informed decision-making. ';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    group("Actual period")
                    {
                        Caption = 'Actual period';
                        field(StartDate; StartDate)
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Starting Date';
                            ToolTip = 'Specifies the date for the beginning of the period covered by the report.';

                            trigger OnValidate()
                            begin
                                CalcPeriod();
                            end;
                        }
                        field(EndDate; EndDate)
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Ending Date';
                            ToolTip = 'Specifies the end date.';
                        }
                    }
                    group("Fiscal Year")
                    {
                        Caption = 'Fiscal Year';
                        field(YearStartDate; YearStartDate)
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Year Starting Date';
                            ToolTip = 'Specifies a start date for the fiscal year.';
                        }
                        field(YearEndDate; YearEndDate)
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Year Ending Date';
                            ToolTip = 'Specifies an end date for the fiscal year.';
                        }
                    }
                    field(OnlyShowAccWithEntries; OnlyAccWithEntries)
                    {
                        ApplicationArea = CostAccounting;
                        Caption = 'Only Cost Centers with Balance or Cost Entries';
                        ToolTip = 'Specifies that you only want cost centers with balance or cost entries.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if StartDate = 0D then
                StartDate := CalcDate('<-CM>', Today);

            CalcPeriod();
        end;
    }

    labels
    {
    }

    var
        StartDate: Date;
        EndDate: Date;
        YearStartDate: Date;
        YearEndDate: Date;
        FilterTxt: Text;
        OnlyAccWithEntries: Boolean;
        ActPeriodHeading: Text[80];
        YtdHeading: Text[80];
        YearHeading: Text[80];
        ActAmt: Decimal;
        ActBud: Decimal;
        ActDiff: Decimal;
        ActPct: Decimal;
        YtdAmt: Decimal;
        YtdBud: Decimal;
        YtdDiff: Decimal;
        YtdPct: Decimal;
        YearBugdet: Decimal;
        ShareYearActPct: Decimal;
        ShareYearBudPct: Decimal;
        PageGroupNo: Integer;
        NextPageGroupNo: Integer;
        CostTypeLineType: Integer;
#pragma warning disable AA0074
        Text000: Label 'Starting date and ending date in the actual period must be defined.';
        Text001: Label 'Ending date must not be before starting date.';
        Text002: Label 'Filter: ';
        Text003: Label 'You have not defined a filter on cost center or cost object.\Do you want to start the report anyway?';
        Text004: Label 'You have not defined a budget filter. Do you want to start the report anyway?';
        Text005: Label 'Actual period %1 - %2', Comment = '%1=date,%2=date';
        Text006: Label 'Cumulated %1 - %2', Comment = '%1=date,%2=date';
        Text007: Label 'Year %1 - %2', Comment = '%1=date,%2=date';
#pragma warning restore AA0074
        CurrReportPAGENOCaptionLbl: Label 'Page';
        CostCenterReportCaptionLbl: Label 'Cost Acctg. Balance/Budget';
        ActDiffCaptionLbl: Label 'Difference';
        ActPctCaptionLbl: Label 'Act %';
        ActBudCaptionLbl: Label 'Budget';
        ActAmtCaptionLbl: Label 'Act.';
        PADSTRIndentation2NameCaptionLbl: Label 'Name';
        CostTypeNoCaptionLbl: Label 'Number';
        ShareYearBudPctCaptionLbl: Label 'Accum. Budget %';
        ShareYearActPctCaptionLbl: Label 'Accum. Actual %';

    local procedure CalcPeriod()
    begin
        if StartDate = 0D then
            StartDate := CalcDate('<-CM>', Today);

        EndDate := CalcDate('<CM>', StartDate);
        YearStartDate := CalcDate('<-CY>', StartDate);
        YearEndDate := CalcDate('<CY>', StartDate);
    end;
}

