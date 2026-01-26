// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Period;
using Microsoft.Foundation.Reporting;
using System.Utilities;

/// <summary>
/// Generates standard income statement report using predefined account schedule templates.
/// Produces formatted profit and loss statement showing revenues, expenses, and net income.
/// </summary>
/// <remarks>
/// Template-driven income statement report using standard account schedule configuration.
/// Processes general ledger transactions through account schedule engine for standardized
/// profit and loss presentation. Supports period-based analysis and comparative reporting.
/// </remarks>
report 28025 "Income Statement"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Finance/FinancialReports/IncomeStatement.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Income Statement';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = sorting("No.") where("Income/Balance" = const("Income Statement"));
            RequestFilterFields = "No.", "Account Type", "Date Filter", "Global Dimension 1 Filter", "Global Dimension 2 Filter";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(LongText_1____LongText_2____LongText_3____LongText_4_; LongText[1] + LongText[2] + LongText[3] + LongText[4])
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(USERID; UserId)
            {
            }
            column(TotalLongText; TotalLongText)
            {
            }
            column(HeaderText; HeaderText)
            {
            }
            column(TotalHeaderText; TotalHeaderText)
            {
            }
            column(G_L_Account__TABLENAME__________GLFilter; "G/L Account".TableName + ': ' + GLFilter)
            {
            }
            column(GLFilter; GLFilter)
            {
            }
            column(RoundFactorText; RoundFactorText)
            {
            }
            column(EmptyString; '')
            {
            }
            column(PageGroupNo; PageGroupNo)
            {
            }
            column(NextPageGroupNo; NextPageGroupNo)
            {
            }
            column(G_L_Account_No_; "No.")
            {
            }
            column(Income_StatementCaption; Income_StatementCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Current_PeriodCaption; Current_PeriodCaptionLbl)
            {
            }
            column(No_Caption; No_CaptionLbl)
            {
            }
            column(PADSTR_____G_L_Account__Indentation___2___G_L_Account__Name_Control1500023Caption; PADSTR_____G_L_Account__Indentation___2___G_L_Account__Name_Control1500023CaptionLbl)
            {
            }
            column(CurrentPeriodNetChangeCaption; CurrentPeriodNetChangeCaptionLbl)
            {
            }
            column(CurrentPeriodNetChange_Control1500025Caption; CurrentPeriodNetChange_Control1500025CaptionLbl)
            {
            }
            column(Current_Period_Last_YearCaption; Current_Period_Last_YearCaptionLbl)
            {
            }
            column(Current_YTDCaption; Current_YTDCaptionLbl)
            {
            }
            column(Last_YTDCaption; Last_YTDCaptionLbl)
            {
            }
            column(HideEmptyLines; HideEmptyLines)
            {
            }
            dataitem(BlankLineCounter; "Integer")
            {
                DataItemTableView = sorting(Number);
                column(G_L_Account___No__of_Blank_Lines_; "G/L Account"."No. of Blank Lines")
                {
                }
                column(BlankLineCounter_Number; Number)
                {
                }

                trigger OnPreDataItem()
                begin
                    SetRange(Number, 1, "G/L Account"."No. of Blank Lines");
                end;
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(G_L_Account___No__; "G/L Account"."No.")
                {
                }
                column(PADSTR_____G_L_Account__Indentation___2___G_L_Account__Name; PadStr('', "G/L Account".Indentation * 2) + "G/L Account".Name)
                {
                }
                column(ShowAccType; ShowAccType)
                {
                }
                column(G_L_Account___No___Control1500022; "G/L Account"."No.")
                {
                }
                column(PADSTR_____G_L_Account__Indentation___2___G_L_Account__Name_Control1500023; PadStr('', "G/L Account".Indentation * 2) + "G/L Account".Name)
                {
                }
                column(CurrentPeriodNetChange; CurrentPeriodNetChange)
                {
                    DecimalPlaces = 0 : 2;
                }
                column(CurrentPeriodNetChange_Control1500025; -CurrentPeriodNetChange)
                {
                    DecimalPlaces = 0 : 2;
                }
                column(LastYrCurrPeriodNetChange; LastYrCurrPeriodNetChange)
                {
                    DecimalPlaces = 0 : 2;
                }
                column(CurrentYTDNetChange; CurrentYTDNetChange)
                {
                    DecimalPlaces = 0 : 2;
                }
                column(LastYTDNetChange; LastYTDNetChange)
                {
                    DecimalPlaces = 0 : 2;
                }
                column(G_L_Account___No___Control1500029; "G/L Account"."No.")
                {
                }
                column(PADSTR_____G_L_Account__Indentation___2___G_L_Account__Name_Control1500030; PadStr('', "G/L Account".Indentation * 2) + "G/L Account".Name)
                {
                }
                column(LastYTDNetChange_Control1500031; LastYTDNetChange)
                {
                    DecimalPlaces = 0 : 2;
                }
                column(LastYrCurrPeriodNetChange_Control1500032; LastYrCurrPeriodNetChange)
                {
                    DecimalPlaces = 0 : 2;
                }
                column(CurrentYTDNetChange_Control1500033; CurrentYTDNetChange)
                {
                    DecimalPlaces = 0 : 2;
                }
                column(CurrentPeriodNetChange_Control1500034; -CurrentPeriodNetChange)
                {
                    DecimalPlaces = 0 : 2;
                }
                column(CurrentPeriodNetChange_Control1500035; CurrentPeriodNetChange)
                {
                    DecimalPlaces = 0 : 2;
                }
                column(G_L_Account___Account_Type_; "G/L Account"."Account Type")
                {
                }
                column(Integer_Number; Number)
                {
                }
                column(Precision; Precision)
                {
                }
            }

            trigger OnAfterGetRecord()
            begin
                if not AddCurr then begin
                    SetRange("Date Filter", CurrentPeriodStart, CurrentPeriodEnd);
                    CalcFields("Net Change");
                    CurrentPeriodNetChange := ReportMngmt.RoundAmount("Net Change", RoundingFactor);

                    SetRange("Date Filter", CurrentYearStart, CurrentPeriodEnd);
                    CalcFields("Net Change");
                    CurrentYTDNetChange := ReportMngmt.RoundAmount("Net Change", RoundingFactor);

                    SetRange("Date Filter", LastYearCurrentPeriodStart, LastYearCurrentPeriodEnd);
                    CalcFields("Net Change");
                    LastYrCurrPeriodNetChange := ReportMngmt.RoundAmount("Net Change", RoundingFactor);

                    SetRange("Date Filter", LastYearStart, LastYearCurrentPeriodEnd);
                    CalcFields("Net Change");
                    LastYTDNetChange := ReportMngmt.RoundAmount("Net Change", RoundingFactor);

                    if (CurrentPeriodNetChange = 0) and (CurrentYTDNetChange = 0) and
                       (LastYrCurrPeriodNetChange = 0) and (LastYTDNetChange = 0) and
                       ("Account Type" = "Account Type"::Posting)
                    then
                        CurrReport.Skip();
                end else begin
                    SetRange("Date Filter", CurrentPeriodStart, CurrentPeriodEnd);
                    CalcFields("Additional-Currency Net Change");
                    CurrentPeriodNetChange :=
                      ReportMngmt.RoundAmount("Additional-Currency Net Change", RoundingFactor);

                    SetRange("Date Filter", CurrentYearStart, CurrentPeriodEnd);
                    CalcFields("Additional-Currency Net Change");
                    CurrentYTDNetChange :=
                      ReportMngmt.RoundAmount("Additional-Currency Net Change", RoundingFactor);

                    SetRange("Date Filter", LastYearCurrentPeriodStart, LastYearCurrentPeriodEnd);
                    CalcFields("Additional-Currency Net Change");
                    LastYrCurrPeriodNetChange :=
                      ReportMngmt.RoundAmount("Additional-Currency Net Change", RoundingFactor);

                    SetRange("Date Filter", LastYearStart, LastYearCurrentPeriodEnd);
                    CalcFields("Net Change");
                    LastYTDNetChange :=
                      ReportMngmt.RoundAmount("Additional-Currency Net Change", RoundingFactor);

                    if (CurrentPeriodNetChange = 0) and (CurrentYTDNetChange = 0) and
                       (LastYrCurrPeriodNetChange = 0) and (LastYTDNetChange = 0) and
                       ("Account Type" = "Account Type"::Posting)
                    then
                        CurrReport.Skip();
                end;

                Precision := GetDecimalPrecision();

                PageGroupNo := NextPageGroupNo;
                ShowAccType := "G/L Account"."Account Type".AsInteger();
                if "G/L Account"."New Page" then
                    NextPageGroupNo := PageGroupNo + 1;
                if PageGroupNo = NextPageGroupNo then
                    PageGroupNo := NextPageGroupNo - 1;
            end;

            trigger OnPreDataItem()
            begin
                // Add TotalLongText,TotalHeaderText.Begin,COMMENTS
                TotalLongText :=
                  StrSubstNo(
                    'Period: %1..%2 versus %3..%4',
                    CurrentPeriodStart, CurrentPeriodEnd, LastYearCurrentPeriodStart, LastYearCurrentPeriodEnd) + '' + '' + '';

                GLSetupNNC.Get();
                if AddCurr then
                    TotalHeaderText := StrSubstNo(Text1450000, GLSetupNNC."Additional Reporting Currency")
                else begin
                    GLSetupNNC.TestField("LCY Code");
                    TotalHeaderText := StrSubstNo(Text1450000, GLSetupNNC."LCY Code");
                end;
                // Add TotalLongText,TotalHeaderText.End

                PageGroupNo := 1;
                NextPageGroupNo := 1;
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Income Statement';
        AboutText = 'The **Income Statement** report is a key finance report with data and layout based on a financial report definition. You can change the financial report definition used for the report on the *General Ledger Setup* page under the *Reporting* section.';

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(AmountsInWhole; RoundingFactor)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Amounts in Whole';
                        ToolTip = 'Specifies if the amounts in the report are shown in whole 1000s.';
                    }
                    field(ShowAmountsInAddReportingCurrency; AddCurr)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Amounts in Add. Reporting Currency';
                        MultiLine = true;
                        ToolTip = 'Specifies if you want report amounts to be shown in the additional reporting currency.';
                    }
                    field(HideEmptyLines; HideEmptyLines)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Hide Empty Lines';
                        ToolTip = 'Specifies if you want to filter out the empty lines.';
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
    }

    trigger OnPreReport()
    begin
        GLFilter := "G/L Account".GetFilters();
        RoundFactorText := ReportMngmt.RoundDescription(RoundingFactor);
        CurrentPeriodStart := "G/L Account".GetRangeMin("Date Filter");
        CurrentPeriodEnd := "G/L Account".GetRangeMax("Date Filter");

        LastYearCurrentPeriodStart := CalcDate('-1Y', NormalDate(CurrentPeriodStart) + 1) - 1;
        LastYearCurrentPeriodEnd := CalcDate('-1Y', NormalDate(CurrentPeriodEnd) + 1) - 1;
        if CurrentPeriodStart <> NormalDate(CurrentPeriodStart) then
            LastYearCurrentPeriodStart := ClosingDate(LastYearCurrentPeriodStart);
        if CurrentPeriodEnd <> NormalDate(CurrentPeriodEnd) then
            LastYearCurrentPeriodEnd := ClosingDate(LastYearCurrentPeriodEnd);

        AccPeriod.Reset();
        AccPeriod.SetRange("New Fiscal Year", true, true);
        AccPeriod.SetFilter("Starting Date", '..%1', CurrentPeriodEnd);
        AccPeriod.FindLast();
        CurrentYearStart := AccPeriod."Starting Date";

        AccPeriod.SetFilter("Starting Date", '..%1', LastYearCurrentPeriodEnd);
        if AccPeriod.FindLast() then
            LastYearStart := AccPeriod."Starting Date";
    end;

    var
        AccPeriod: Record "Accounting Period";
        ReportMngmt: Codeunit "Report Management APAC";
        GLFilter: Text[250];
        LongText: array[4] of Text[132];
        CurrentPeriodStart: Date;
        CurrentPeriodEnd: Date;
        LastYearCurrentPeriodStart: Date;
        LastYearCurrentPeriodEnd: Date;
        CurrentYearStart: Date;
        LastYearStart: Date;
        CurrentPeriodNetChange: Decimal;
        CurrentYTDNetChange: Decimal;
        LastYrCurrPeriodNetChange: Decimal;
        LastYTDNetChange: Decimal;
        AddCurr: Boolean;
        RoundingFactor: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
        HeaderText: Text[50];
        RoundFactorText: Text[50];
        Text1450000: Label 'All amounts are in %1.';
        PageGroupNo: Integer;
        TotalLongText: Text[250];
        TotalHeaderText: Text[250];
        GLSetupNNC: Record "General Ledger Setup";
        ShowAccType: Integer;
        NextPageGroupNo: Integer;
        Income_StatementCaptionLbl: Label 'Income Statement';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Current_PeriodCaptionLbl: Label 'Current Period';
        No_CaptionLbl: Label 'No.';
        PADSTR_____G_L_Account__Indentation___2___G_L_Account__Name_Control1500023CaptionLbl: Label 'Name';
        CurrentPeriodNetChangeCaptionLbl: Label 'Debit';
        CurrentPeriodNetChange_Control1500025CaptionLbl: Label 'Credit';
        Current_Period_Last_YearCaptionLbl: Label 'Current Period Last Year';
        Current_YTDCaptionLbl: Label 'Current YTD';
        Last_YTDCaptionLbl: Label 'Last YTD';
        HideEmptyLines: Boolean;
        Precision: Integer;

    local procedure GetDecimalPrecision(): Integer
    begin
        case RoundingFactor of
            RoundingFactor::" ":
                exit(2);
            RoundingFactor::Tens, RoundingFactor::Hundreds, RoundingFactor::"Hundred Thousands", RoundingFactor::Millions:
                exit(1);
            RoundingFactor::Thousands:
                exit(0);
        end;
    end;
}

