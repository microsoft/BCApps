// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Period;
using Microsoft.Foundation.Reporting;
using System.Utilities;

report 28026 "Financial Analysis Report"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/FinancialMgt/GeneralLedger/Reports/FinancialAnalysisReport.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Financial Analysis Report';
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
            column(HeaderText; HeaderText)
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
            column(ColumnHeader_1_; ColumnHeader[1])
            {
            }
            column(ColumnHeader_2_; ColumnHeader[2])
            {
            }
            column(ColumnSubHeader_6_; ColumnSubHeader[6])
            {
            }
            column(ColumnSubHeader_5_; ColumnSubHeader[5])
            {
            }
            column(ColumnSubHeader_4_; ColumnSubHeader[4])
            {
            }
            column(ColumnSubHeader_3_; ColumnSubHeader[3])
            {
            }
            column(ColumnSubHeader_2_; ColumnSubHeader[2])
            {
            }
            column(ColumnSubHeader_1_; ColumnSubHeader[1])
            {
            }
            column(NoOfColumns; NoOfColumns)
            {
            }
            column(GroupNo; GroupNo)
            {
            }
            column(G_L_Account_No_; "No.")
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(AccountName_Control1500031Caption; AccountName_Control1500031CaptionLbl)
            {
            }
            column(No_Caption; No_CaptionLbl)
            {
            }
            dataitem(BlankLineCounter; "Integer")
            {
                DataItemTableView = sorting(Number);
                MaxIteration = 1;
                column(BlankLineCounter_BlankLineCounter_Number; Number)
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
                column(AccountName; AccountName)
                {
                }
                column(bShowTLine; bShowTLine)
                {
                }
                column(G_L_Account___Account_Type_; "G/L Account"."Account Type")
                {
                }
                column(G_L_Account___No___Control1500030; "G/L Account"."No.")
                {
                }
                column(AccountName_Control1500031; AccountName)
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
                column(G_L_Account___No___Control1500038; "G/L Account"."No.")
                {
                }
                column(AccountName_Control1500039; AccountName)
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
                column(Integer_Number; Number)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    bShowTLine := ShowTotalLine("G/L Account");
                    if (("G/L Account"."Account Type" = "G/L Account"."Account Type"::Heading) or
                        ("G/L Account"."Account Type" = "G/L Account"."Account Type"::"Begin-Total") or
                        ("G/L Account"."Account Type" = "G/L Account"."Account Type"::Posting) or
                        bShowTLine) and "G/L Account"."New Page"
                    then
                        GroupNo := GroupNo + 1;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if IndentAccountName then
                    AccountName := PadStr('', "G/L Account".Indentation * 2) + "G/L Account".Name
                else
                    AccountName := "G/L Account".Name;

                CalculateAmount("G/L Account");

                RoundAmount();
                if (ColumnAmount[1] = 0) and (ColumnAmount[2] = 0) and (ColumnAmount[3] = 0) and
                   (ColumnAmount[4] = 0) and (ColumnAmount[5] = 0) and (ColumnAmount[6] = 0) and
                   ("G/L Account"."Account Type" = "G/L Account"."Account Type"::Posting)
                then
                    CurrReport.Skip();
                ConvertAmountToText();
            end;

            trigger OnPreDataItem()
            begin
                if ReportType = ReportType::" " then
                    Error(Text1450007);
                PopulateFormatString();
                PopulateColumnHeader();
                FilterGLAccount("G/L Account");

                GroupNo := 1;
                GLSetup.Get();
                if AddCurr then
                    HeaderText := StrSubstNo(Text1450013, GLSetup."Additional Reporting Currency")
                else begin
                    GLSetup.TestField("LCY Code");
                    HeaderText := StrSubstNo(Text1450013, GLSetup."LCY Code");
                end;
            end;
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
                    field(ReportType; ReportType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Report Type';
                        ToolTip = 'Specifies the type.';
                    }
                    field(IndentAccountName; IndentAccountName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Indent Account Name';
                        ToolTip = 'Specifies that you want to indent the report.';
                    }
                    field(AmountsInWhole; RoundingFactor)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Amounts in whole';
                        ToolTip = 'Specifies if the amounts in the report are shown in whole 1000s.';
                    }
                    field(AddCurr; AddCurr)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Amounts in Add. Reporting Currency';
                        MultiLine = true;
                        ToolTip = 'Specifies if you want report amounts to be shown in the additional reporting currency.';
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
        if CurrentPeriodStart <> NormalDate(CurrentPeriodStart) then
            LastYearCurrentPeriodStart := ClosingDate(LastYearCurrentPeriodStart);

        LastYearCurrentPeriodEnd := CalcDate('-1Y', NormalDate(CurrentPeriodEnd) + 1) - 1;
        if CurrentPeriodEnd <> NormalDate(CurrentPeriodEnd) then
            LastYearCurrentPeriodEnd := ClosingDate(LastYearCurrentPeriodEnd);

        AccPeriod.Reset();
        AccPeriod.SetRange("New Fiscal Year", true, true);
        AccPeriod.SetFilter("Starting Date", '..%1', CurrentPeriodEnd);
        AccPeriod.FindLast();
        CurrentYearStart := AccPeriod."Starting Date";

        AccPeriod.SetFilter("Starting Date", '..%1', LastYearCurrentPeriodEnd);
        AccPeriod.FindLast();
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
        CurrentYearStart: Date;
        LastYearStart: Date;
        RoundingFactor: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
        ColumnHeader: array[2] of Text[30];
        ColumnSubHeader: array[6] of Text[30];
        ColumnAmount: array[6] of Decimal;
        ColumnAmountText: array[6] of Text[30];
        DoNotRoundAmount: array[6] of Boolean;
        ReportName: Text[250];
        AddCurr: Boolean;
        ReportType: Option " ",,"Net Change/Budget","Net Change (This Year/Last Year)","Balance (This Year/Last Year)";
        CurrentPeriodStart: Date;
        LastYearCurrentPeriodStart: Date;
        LastYearCurrentPeriodEnd: Date;
        HeaderText: Text[250];
        NoOfColumns: Integer;
        IndentAccountName: Boolean;
        AccountName: Text[250];
        Text1450000: Label 'Current Year';
        Text1450001: Label 'Last Year';
        Text1450002: Label 'Balance';
        Text1450003: Label 'Budget';
        Text1450004: Label 'Variance %';
        Text1450005: Label 'Statement of Financial Position';
        Text1450006: Label 'Period: %1..%2 versus %3..%4';
        Text1450007: Label 'You must choose a Report Type.';
        Text1450008: Label 'Statement of Financial Performance (Profit and Loss)';
        Text1450009: Label 'Current Period';
        Text1450010: Label 'Year To Date';
        Text1450011: Label 'Net Change';
        Text1450012: Label 'Net Change - Period';
        Text1450013: Label 'All amounts are in %1.';
        Text1450015: Label '$ Difference';
        Text1450016: Label '% Difference';
        Text1450017: Label 'Period: %1..%2 versus %3..%4 and %5..%6 versus %7..%8';
        GroupNo: Integer;
        bShowTLine: Boolean;
        GLSetup: Record "General Ledger Setup";
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        AccountName_Control1500031CaptionLbl: Label 'Name';
        No_CaptionLbl: Label 'No.';

    local procedure PopulateColumnHeader()
    var
        i: Integer;
    begin
        for i := 1 to 6 do
            ColumnSubHeader[i] := '';
        for i := 1 to 2 do
            ColumnHeader[i] := '';
        LongText := '';

        case ReportType of
            1:
                begin
                    NoOfColumns := 6;
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
            ReportType::"Net Change/Budget":
                begin
                    NoOfColumns := 6;
                    ReportName := Text1450008;
                    ColumnHeader[1] := Text1450009;
                    ColumnHeader[2] := Text1450010;
                    ColumnSubHeader[1] := Text1450011;
                    ColumnSubHeader[2] := Text1450003;
                    ColumnSubHeader[3] := Text1450004;
                    ColumnSubHeader[4] := Text1450011;
                    ColumnSubHeader[5] := Text1450003;
                    ColumnSubHeader[6] := Text1450004;
                    LongText :=
                      StrSubstNo(
                        Text1450006,
                        CurrentPeriodStart, CurrentPeriodEnd, CurrentYearStart, CurrentPeriodEnd);
                end;
            ReportType::"Net Change (This Year/Last Year)":
                begin
                    NoOfColumns := 6;
                    ReportName := Text1450008;
                    ColumnHeader[1] := Text1450012;
                    ColumnHeader[2] := Text1450010;
                    ColumnSubHeader[1] := Text1450000;
                    ColumnSubHeader[2] := Text1450001;
                    ColumnSubHeader[3] := Text1450004;
                    ColumnSubHeader[4] := Text1450000;
                    ColumnSubHeader[5] := Text1450001;
                    ColumnSubHeader[6] := Text1450004;
                    LongText :=
                      StrSubstNo(
                        Text1450017,
                        CurrentPeriodStart, CurrentPeriodEnd,
                        LastYearCurrentPeriodStart, LastYearCurrentPeriodEnd,
                        CurrentYearStart, CurrentPeriodEnd,
                        LastYearStart, LastYearCurrentPeriodEnd);
                end;
            ReportType::"Balance (This Year/Last Year)":
                begin
                    NoOfColumns := 4;
                    ReportName := Text1450005;
                    ColumnSubHeader[1] := Text1450000;
                    ColumnSubHeader[2] := Text1450001;
                    ColumnSubHeader[3] := Text1450015;
                    ColumnSubHeader[4] := Text1450016;
                    LongText :=
                      StrSubstNo(
                        Text1450006,
                        CurrentYearStart, CurrentPeriodEnd, LastYearStart, LastYearCurrentPeriodEnd);
                end;
        end;
    end;

    local procedure ConvertAmountToText()
    var
        i: Integer;
    begin
        for i := 1 to 6 do
            if i <= NoOfColumns then begin
                if FormatString[i] <> '' then
                    ColumnAmountText[i] := Format(ColumnAmount[i], 0, FormatString[i])
                else
                    ColumnAmountText[i] := Format(ColumnAmount[i]);
            end else
                ColumnAmountText[i] := '';
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
        case ReportType of
            1, ReportType::"Net Change/Budget", ReportType::"Net Change (This Year/Last Year)":
                begin
                    FormatString[3] := '';
                    FormatString[6] := '';
                    DoNotRoundAmount[3] := true;
                    DoNotRoundAmount[6] := true;
                end;
            ReportType::"Balance (This Year/Last Year)":
                begin
                    FormatString[4] := '';
                    DoNotRoundAmount[4] := true;
                end;
        end;
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
        case ReportType of
            1, ReportType::"Balance (This Year/Last Year)":
                GLAccount.SetRange("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
            ReportType::"Net Change/Budget", ReportType::"Net Change (This Year/Last Year)":
                GLAccount.SetRange("Income/Balance", GLAccount."Income/Balance"::"Income Statement");
        end;
    end;

    local procedure CalculateAmount(var GLAccount: Record "G/L Account")
    var
        i: Integer;
    begin
        for i := 1 to 6 do
            ColumnAmount[i] := 0;
        case ReportType of
            1:
                begin
                    GLAccount.SetRange("Date Filter", CurrentYearStart, CurrentPeriodEnd);
                    GLAccount.CalcFields("Balance at Date", "Budget at Date");
                    ColumnAmount[1] := GLAccount."Balance at Date";
                    ColumnAmount[2] := GLAccount."Budget at Date";
                    if ColumnAmount[2] <> 0 then
                        ColumnAmount[3] := Round((ColumnAmount[2] - ColumnAmount[1]) / ColumnAmount[2] * 100, 1);

                    GLAccount.SetRange("Date Filter", LastYearStart, LastYearCurrentPeriodEnd);
                    GLAccount.CalcFields("Balance at Date", "Budget at Date");
                    ColumnAmount[4] := GLAccount."Balance at Date";
                    ColumnAmount[5] := GLAccount."Budget at Date";
                    if ColumnAmount[5] <> 0 then
                        ColumnAmount[6] := Round((ColumnAmount[5] - ColumnAmount[4]) / ColumnAmount[5] * 100, 1);
                end;
            ReportType::"Net Change/Budget":
                begin
                    GLAccount.SetRange("Date Filter", CurrentPeriodStart, CurrentPeriodEnd);
                    GLAccount.CalcFields("Net Change", "Budgeted Amount");
                    ColumnAmount[1] := GLAccount."Net Change";
                    ColumnAmount[2] := GLAccount."Budgeted Amount";
                    if ColumnAmount[2] <> 0 then
                        ColumnAmount[3] := Round((ColumnAmount[1] - ColumnAmount[2]) / ColumnAmount[2] * 100, 1);

                    GLAccount.SetRange("Date Filter", CurrentYearStart, CurrentPeriodEnd);
                    GLAccount.CalcFields("Net Change", "Budgeted Amount");
                    ColumnAmount[4] := GLAccount."Net Change";
                    ColumnAmount[5] := GLAccount."Budgeted Amount";
                    if ColumnAmount[5] <> 0 then
                        ColumnAmount[6] := Round((ColumnAmount[4] - ColumnAmount[5]) / ColumnAmount[5] * 100, 1);
                end;
            ReportType::"Net Change (This Year/Last Year)":
                begin
                    GLAccount.SetRange("Date Filter", CurrentPeriodStart, CurrentPeriodEnd);
                    GLAccount.CalcFields("Net Change", "Additional-Currency Net Change");
                    if AddCurr then
                        ColumnAmount[1] := GLAccount."Additional-Currency Net Change"
                    else
                        ColumnAmount[1] := GLAccount."Net Change";
                    GLAccount.SetRange("Date Filter", LastYearCurrentPeriodStart, LastYearCurrentPeriodEnd);
                    GLAccount.CalcFields("Net Change", "Additional-Currency Net Change");
                    if AddCurr then
                        ColumnAmount[2] := GLAccount."Additional-Currency Net Change"
                    else
                        ColumnAmount[2] := GLAccount."Net Change";
                    if ColumnAmount[2] <> 0 then
                        ColumnAmount[3] := Round((ColumnAmount[1] - ColumnAmount[2]) / ColumnAmount[2] * 100, 1);

                    GLAccount.SetRange("Date Filter", CurrentYearStart, CurrentPeriodEnd);
                    GLAccount.CalcFields("Net Change", "Additional-Currency Net Change");
                    if AddCurr then
                        ColumnAmount[4] := GLAccount."Additional-Currency Net Change"
                    else
                        ColumnAmount[4] := GLAccount."Net Change";
                    GLAccount.SetRange("Date Filter", LastYearStart, LastYearCurrentPeriodEnd);
                    GLAccount.CalcFields("Net Change", "Additional-Currency Net Change");
                    if AddCurr then
                        ColumnAmount[5] := GLAccount."Additional-Currency Net Change"
                    else
                        ColumnAmount[5] := GLAccount."Net Change";
                    if ColumnAmount[5] <> 0 then
                        ColumnAmount[6] := Round((ColumnAmount[4] - ColumnAmount[5]) / ColumnAmount[5] * 100, 1);
                end;
            ReportType::"Balance (This Year/Last Year)":
                begin
                    GLAccount.SetRange("Date Filter", CurrentYearStart, CurrentPeriodEnd);
                    GLAccount.CalcFields("Balance at Date", "Add.-Currency Balance at Date");
                    if AddCurr then
                        ColumnAmount[1] := GLAccount."Add.-Currency Balance at Date"
                    else
                        ColumnAmount[1] := GLAccount."Balance at Date";

                    GLAccount.SetRange("Date Filter", LastYearStart, LastYearCurrentPeriodEnd);
                    GLAccount.CalcFields("Balance at Date", "Add.-Currency Balance at Date");
                    if AddCurr then
                        ColumnAmount[2] := GLAccount."Add.-Currency Balance at Date"
                    else
                        ColumnAmount[2] := GLAccount."Balance at Date";
                    ColumnAmount[3] := ColumnAmount[1] - ColumnAmount[2];
                    if ColumnAmount[2] <> 0 then
                        ColumnAmount[4] := Round(((ColumnAmount[1] - ColumnAmount[2]) / ColumnAmount[2]) * 100, 1);
                end;
        end;
    end;

    local procedure ShowTotalLine(var GLAccount: Record "G/L Account"): Boolean
    begin
        if ((GLAccount."Account Type" = GLAccount."Account Type"::"End-Total") or
            (GLAccount."Account Type" = GLAccount."Account Type"::Total))
        then
            exit(true);

        exit(false);
    end;
}

