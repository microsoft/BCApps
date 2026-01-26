// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.Period;
using Microsoft.Foundation.Reporting;
using System.Utilities;

/// <summary>
/// Generates standard balance sheet report using predefined account schedule templates.
/// Produces formatted financial statement showing assets, liabilities, and equity positions.
/// </summary>
/// <remarks>
/// Template-driven balance sheet report using standard account schedule configuration.
/// Processes general ledger balances through account schedule engine for standardized
/// financial statement presentation. Supports period-based analysis and drill-down capabilities.
/// </remarks>
report 28024 "Balance Sheet"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Finance/FinancialReports/BalanceSheet.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Balance Sheet';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Account Type", "Date Filter", "Budget Filter", "Global Dimension 1 Filter", "Global Dimension 2 Filter";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(LongText; LongText)
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(USERID; UserId)
            {
            }
            column(ReportName; ReportName)
            {
            }
            column(G_L_Account__TABLENAME__________GLFilter; "G/L Account".TableName + ': ' + GLFilter)
            {
            }
            column(RoundFactorText; RoundFactorText)
            {
            }
            column(EmptyString; '')
            {
            }
            column(EmptyString_Control1500013; '')
            {
            }
            column(ColumnHeader_1_; ColumnHeader[1])
            {
            }
            column(ColumnHeader_2_; ColumnHeader[2])
            {
            }
            column(ColumnSubHeader_1_; ColumnSubHeader[1])
            {
            }
            column(ColumnSubHeader_2_; ColumnSubHeader[2])
            {
            }
            column(ColumnSubHeader_3_; ColumnSubHeader[3])
            {
            }
            column(ColumnSubHeader_4_; ColumnSubHeader[4])
            {
            }
            column(ColumnSubHeader_5_; ColumnSubHeader[5])
            {
            }
            column(ColumnSubHeader_6_; ColumnSubHeader[6])
            {
            }
            column(NextPageGroupNo; NextPageGroupNo)
            {
            }
            column(PageGroupNo; PageGroupNo)
            {
            }
            column(G_L_Account_No_; "No.")
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(No_Caption; No_CaptionLbl)
            {
            }
            column(PADSTR_____G_L_Account__Indentation___2___G_L_Account__Name_Control1500025Caption; PADSTR_____G_L_Account__Indentation___2___G_L_Account__Name_Control1500025CaptionLbl)
            {
            }
            dataitem(BlankLineCounter; "Integer")
            {
                DataItemTableView = sorting(Number);
                MaxIteration = 1;
                column(ShowAccType; ShowAccType)
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
                MaxIteration = 1;
                column(G_L_Account___No__; "G/L Account"."No.")
                {
                }
                column(PADSTR_____G_L_Account__Indentation___2___G_L_Account__Name; PadStr('', "G/L Account".Indentation * 2) + "G/L Account".Name)
                {
                }
                column(G_L_Account___No__of_Blank_Lines_; "G/L Account"."No. of Blank Lines")
                {
                }
                column(G_L_Account___No___Control1500024; "G/L Account"."No.")
                {
                }
                column(PADSTR_____G_L_Account__Indentation___2___G_L_Account__Name_Control1500025; PadStr('', "G/L Account".Indentation * 2) + "G/L Account".Name)
                {
                }
                column(ColumnAmountText_1_; ColumnAmountText[1])
                {
                }
                column(ColumnAmountText_2_; ColumnAmountText[2])
                {
                }
                column(ColumnAmountText_3_; ColumnAmountText[3])
                {
                }
                column(ColumnAmountText_6_; ColumnAmountText[6])
                {
                }
                column(ColumnAmountText_5_; ColumnAmountText[5])
                {
                }
                column(ColumnAmountText_4_; ColumnAmountText[4])
                {
                }
                column(G_L_Account___No___Control1500032; "G/L Account"."No.")
                {
                }
                column(PADSTR_____G_L_Account__Indentation___2___G_L_Account__Name_Control1500033; PadStr('', "G/L Account".Indentation * 2) + "G/L Account".Name)
                {
                }
                column(ColumnAmountText_6__Control1500040; ColumnAmountText[6])
                {
                }
                column(ColumnAmountText_5__Control1500041; ColumnAmountText[5])
                {
                }
                column(ColumnAmountText_4__Control1500042; ColumnAmountText[4])
                {
                }
                column(ColumnAmountText_3__Control1500043; ColumnAmountText[3])
                {
                }
                column(ColumnAmountText_2__Control1500044; ColumnAmountText[2])
                {
                }
                column(ColumnAmountText_1__Control1500045; ColumnAmountText[1])
                {
                }
                column(G_L_Account___Account_Type_; "G/L Account"."Account Type")
                {
                }
                column(Integer_Number; Number)
                {
                }
            }

            trigger OnAfterGetRecord()
            begin
                CalculateAmount("G/L Account");

                RoundAmount();
                if (ColumnAmount[1] = 0) and (ColumnAmount[2] = 0) and (ColumnAmount[3] = 0) and
                   (ColumnAmount[4] = 0) and (ColumnAmount[5] = 0) and (ColumnAmount[6] = 0) and
                   ("G/L Account"."Account Type" = "G/L Account"."Account Type"::Posting)
                then
                    CurrReport.Skip();
                ConvertAmountToText();
                PageGroupNo := NextPageGroupNo;
                ShowAccType := "G/L Account"."Account Type".AsInteger();
                if "G/L Account"."New Page" then
                    NextPageGroupNo := PageGroupNo + 1;
                if PageGroupNo = NextPageGroupNo then
                    PageGroupNo := NextPageGroupNo - 1;
            end;

            trigger OnPreDataItem()
            begin
                PopulateFormatString();
                PopulateColumnHeader();
                FilterGLAccount("G/L Account");
                PageGroupNo := 1;
                NextPageGroupNo := 1;
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Balance Sheet';
        AboutText = 'The **Balance Sheet** report is a key finance report with data and layout based on a financial report definition. You can change the financial report definition used for the report on the *General Ledger Setup* page under the *Reporting* section.';

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
    }

    trigger OnPreReport()
    begin
        GLFilter := "G/L Account".GetFilters();
        RoundFactorText := ReportMngmt.RoundDescription(RoundingFactor);
        CurrentPeriodEnd := "G/L Account".GetRangeMax("Date Filter");

        LastYearCurrentPeriodEnd := CalcDate('-1Y', NormalDate(CurrentPeriodEnd) + 1) - 1;
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
        LongText: Text[250];
        RoundFactorText: Text[50];
        FormatString: array[6] of Text[50];
        CurrentPeriodEnd: Date;
        LastYearCurrentPeriodEnd: Date;
        CurrentYearStart: Date;
        LastYearStart: Date;
        RoundingFactor: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
        ColumnHeader: array[2] of Text[30];
        ColumnSubHeader: array[6] of Text[30];
        ColumnAmount: array[6] of Decimal;
        ColumnAmountText: array[6] of Text[30];
        DoNotRoundAmount: array[6] of Boolean;
        ReportName: Text[250];
        Text1450000: Label 'Current Year';
        Text1450001: Label 'Last Year';
        Text1450002: Label 'Balance';
        Text1450003: Label 'Budget';
        Text1450004: Label 'Variance %';
        Text1450005: Label 'Balance Sheet';
        Text1450006: Label 'Period: %1..%2 versus %3..%4';
        PageGroupNo: Integer;
        ShowAccType: Integer;
        NextPageGroupNo: Integer;
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        No_CaptionLbl: Label 'No.';
        PADSTR_____G_L_Account__Indentation___2___G_L_Account__Name_Control1500025CaptionLbl: Label 'Name';

    local procedure PopulateColumnHeader()
    begin
        ReportName := Text1450005;
        ColumnHeader[1] := Text1450000;
        ColumnHeader[2] := Text1450001;
        ColumnSubHeader[1] := Text1450002;
        ColumnSubHeader[2] := Text1450003;
        ColumnSubHeader[3] := Text1450004;
        ColumnSubHeader[4] := Text1450002;
        ColumnSubHeader[5] := Text1450003;
        ColumnSubHeader[6] := Text1450004;
        LongText :=
          StrSubstNo(
            Text1450006,
            CurrentYearStart, CurrentPeriodEnd, LastYearStart, LastYearCurrentPeriodEnd);
    end;

    local procedure ConvertAmountToText()
    var
        i: Integer;
    begin
        for i := 1 to 6 do
            if FormatString[i] <> '' then
                ColumnAmountText[i] := Format(ColumnAmount[i], 0, FormatString[i])
            else
                ColumnAmountText[i] := Format(ColumnAmount[i]);
    end;

    local procedure PopulateFormatString()
    var
        i: Integer;
    begin
        for i := 1 to 6 do
            if RoundingFactor = RoundingFactor::" " then
                FormatString[i] := '<Precision,2:><Standard Format,0>'
            else
                FormatString[i] := '<Precision,1:><Standard Format,0>';
        FormatString[3] := '';
        FormatString[6] := '';
        DoNotRoundAmount[3] := true;
        DoNotRoundAmount[6] := true;
    end;

    local procedure RoundAmount()
    var
        i: Integer;
    begin
        for i := 1 to 6 do
            if not DoNotRoundAmount[i] then
                ColumnAmount[i] := ReportMngmt.RoundAmount(ColumnAmount[i], RoundingFactor);
    end;

    local procedure FilterGLAccount(var GLAccount: Record "G/L Account")
    begin
        GLAccount.SetRange("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
    end;

    local procedure CalculateAmount(var GLAccount: Record "G/L Account")
    begin
        GLAccount.SetRange("Date Filter", CurrentYearStart, CurrentPeriodEnd);
        GLAccount.CalcFields("Balance at Date", "Budget at Date");
        ColumnAmount[1] := GLAccount."Balance at Date";
        ColumnAmount[2] := GLAccount."Budget at Date";
        ColumnAmount[3] := 0;
        if ColumnAmount[2] <> 0 then
            ColumnAmount[3] := Round((ColumnAmount[2] - ColumnAmount[1]) / ColumnAmount[2] * 100, 1);

        GLAccount.SetRange("Date Filter", LastYearStart, LastYearCurrentPeriodEnd);
        GLAccount.CalcFields("Balance at Date", "Budget at Date");
        ColumnAmount[4] := GLAccount."Balance at Date";
        ColumnAmount[5] := GLAccount."Budget at Date";
        ColumnAmount[6] := 0;
        if ColumnAmount[5] <> 0 then
            ColumnAmount[6] := Round((ColumnAmount[5] - ColumnAmount[4]) / ColumnAmount[5] * 100, 1);
    end;
}

