// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.Period;
using System.Utilities;

report 10601 "Trial Balance/Previous Period"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/GeneralLedger/Reports/TrialBalancePreviousPeriod.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Trial Balance/Previous Period';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(IncomeOrBalance; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = filter(0 .. 1));
            dataitem("G/L Account"; "G/L Account")
            {
                DataItemTableView = sorting("No.");
                RequestFilterFields = "No.", "Account Type", "Date Filter", "Global Dimension 1 Filter", "Global Dimension 2 Filter";
                column(TodayFormatted; Format(Today, 0, 4))
                {
                }
                column(PeriodText; Text1080000 + ': ' + PeriodText)
                {
                }
                column(CompanyName; COMPANYPROPERTY.DisplayName())
                {
                }
                column(AccType_GLAcc; "G/L Account"."Account Type")
                {
                }
                column(NewPage_GLAcc; "G/L Account"."New Page")
                {
                }
                column(NoofBlankLines_GLAcc; "G/L Account"."No. of Blank Lines")
                {
                }
                column(GLFilter; "G/L Account".TableName + ': ' + GLFilter)
                {
                }
                column(IncomeBalance_GLAcc; "G/L Account"."Income/Balance")
                {
                }
                column(IncomeBalance_GLAccOption; IncomeBalanceOptionNo)
                {
                }
                column(DateFilter; Text1080000 + ' ' + "G/L Account".GetFilter("Date Filter"))
                {
                }
                column(YearToDateDateFilter; Text1080001 + ' ' + YearToDate.GetFilter("Date Filter"))
                {
                }
                column(IncomingBalance; StrSubstNo('Incoming Balance %1', FirstDayThisYear))
                {
                }
                column(IncomePageNo; IncomePageNo)
                {
                }
                column(BalancePageNo; BalancePageNo)
                {
                }
                column(IncomeHidden; IncomeHidden)
                {
                }
                column(BalanceHidden; BalanceHidden)
                {
                }
                column(TrialBalPreviousPeriodCaption; TrialBalPreviousPeriodCaptionLbl)
                {
                }
                column(PageNoCaption; PageNoCaptionLbl)
                {
                }
                column(NoCaption_GLAcc; FieldCaption("No."))
                {
                }
                column(GLAccNameCaption; GLAccNameCaptionLbl)
                {
                }
                column(PrevYearCaption; PrevYearCaptionLbl)
                {
                }
                column(DifferenceCaption; DifferenceCaptionLbl)
                {
                }
                column(PeriodPctCaption; PeriodPctCaptionLbl)
                {
                }
                column(YearToDateCaption; YearToDateCaptionLbl)
                {
                }
                column(OutgoingBalanceCaption; OutgoingBalanceCaptionLbl)
                {
                }
                column(GLAccountType; GLAccountType)
                {
                }
                dataitem(BlankLineCounter; "Integer")
                {
                    DataItemTableView = sorting(Number);

                    trigger OnPreDataItem()
                    begin
                        SetRange(Number, 1, "G/L Account"."No. of Blank Lines");
                    end;
                }
                dataitem("Integer"; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(No_GLAcc; "G/L Account"."No.")
                    {
                    }
                    column(GLAccName; PadStr('', "G/L Account".Indentation * 2) + "G/L Account".Name)
                    {
                    }
                    column(PeriodPrevYearNetChange; PeriodPrevYear."Net Change")
                    {
                    }
                    column(GLAccNetChangeDifference; "G/L Account"."Net Change" - PeriodPrevYear."Net Change")
                    {
                    }
                    column(PeriodPct; PeriodPct)
                    {
                        DecimalPlaces = 0 : 0;
                    }
                    column(YearToDateNetChange; YearToDate."Net Change")
                    {
                    }
                    column(YearToDatePct; YearToDatePct)
                    {
                        DecimalPlaces = 0 : 0;
                    }
                    column(PrevYearToDateNetChange; PrevYearToDate."Net Change")
                    {
                    }
                    column(NetChangeDifference; YearToDate."Net Change" - PrevYearToDate."Net Change")
                    {
                    }
                    column(GLAccNetChange; "G/L Account"."Net Change")
                    {
                    }
                    column(IncomingNetChange; Incoming."Net Change")
                    {
                    }
                    column(NetChange; Incoming."Net Change" + YearToDate."Net Change")
                    {
                    }
                    column(NoOfBlnkLin_GLAcct; "G/L Account"."No. of Blank Lines")
                    {
                    }
                    column(PADSTR; PadStr('', "G/L Account".Indentation * 2))
                    {
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    if NewPageStatus then
                        if IncomeOrBalance.Number = "Income/Balance"::"Income Statement".AsInteger() then
                            IncomePageNo += 1
                        else
                            BalancePageNo += 1;

                    NewPageStatus := false;
                    CalcFields("Net Change");

                    GLAccountType := "Account Type".AsInteger();

                    Incoming.Reset();
                    Incoming := "G/L Account";
                    Incoming.CopyFilters("G/L Account");
                    Incoming.SetRange("Date Filter", 0D, LastDayPrevYear);
                    Incoming.CalcFields("Net Change");

                    YearToDate.Reset();
                    YearToDate := "G/L Account";
                    YearToDate.CopyFilters("G/L Account");
                    YearToDate.SetRange("Date Filter", FirstDayThisYear, PeriodEndThisYear);
                    YearToDate.CalcFields("Net Change");

                    PrevYearToDate.Reset();
                    PrevYearToDate := "G/L Account";
                    PrevYearToDate.CopyFilters("G/L Account");
                    PrevYearToDate.SetRange("Date Filter", FirstDayPrevYear, PeriodEndPrevYear);
                    PrevYearToDate.CalcFields("Net Change");

                    PeriodPrevYear.Reset();
                    PeriodPrevYear := "G/L Account";
                    PeriodPrevYear.CopyFilters("G/L Account");
                    PeriodPrevYear.SetRange("Date Filter", PeriodStartPrevYear, PeriodEndPrevYear);
                    PeriodPrevYear.CalcFields("Net Change");

                    if PrevYearToDate."Net Change" = 0 then
                        if YearToDate."Net Change" = 0 then
                            YearToDatePct := 0
                        else
                            YearToDatePct := 100
                    else
                        YearToDatePct := (YearToDate."Net Change" -
                                          PrevYearToDate."Net Change") / PrevYearToDate."Net Change" * 100;

                    if PeriodPrevYear."Net Change" = 0 then
                        if "Net Change" = 0 then
                            PeriodPct := 0
                        else
                            PeriodPct := 100
                    else
                        PeriodPct := ("Net Change" - PeriodPrevYear."Net Change") / PeriodPrevYear."Net Change" * 100;

                    if OnlyIfChange and ("Net Change" = 0) and (YearToDate."Net Change" = 0) and
                       (PeriodPrevYear."Net Change" = 0) and (PrevYearToDate."Net Change" = 0)
                    then
                        if not (("Income/Balance" = "Income/Balance"::"Balance Sheet") and (Incoming."Net Change" <> 0)) then
                            CurrReport.Skip();
                    if "G/L Account"."New Page" then
                        NewPageStatus := true
                    else
                        NewPageStatus := false;

                    IncomeBalanceOptionNo := "Income/Balance".AsInteger();
                end;

                trigger OnPreDataItem()
                begin
                    "G/L Account".SetRange("Income/Balance", IncomeOrBalance.Number);

                    if IsEmpty() then
                        CurrReport.Skip();

                    PeriodStartThisYear := GetRangeMin("Date Filter");
                    PeriodEndThisYear := GetRangeMax("Date Filter");
                    PeriodStartPrevYear := CalcDate('<-1Y>', PeriodStartThisYear);
                    PeriodEndPrevYear := CalcDate('<-1Y>', PeriodEndThisYear);

                    if PeriodEndThisYear = CalcDate('<CM>', PeriodEndThisYear) then
                        PeriodEndPrevYear := CalcDate('<CM>', PeriodEndPrevYear);

                    // Find start of Fiscal Year
                    AccPeriod.SetRange("Starting Date", 0D, PeriodStartThisYear);
                    AccPeriod.SetRange("New Fiscal Year", true);
                    if AccPeriod.FindLast() then begin
                        FirstDayThisYear := AccPeriod."Starting Date";
                        LastDayPrevYear := ClosingDate(CalcDate('<-1D>', FirstDayThisYear));
                        FirstDayPrevYear := CalcDate('<-1Y>', FirstDayThisYear);
                    end else begin
                        FirstDayThisYear := 0D;
                        LastDayPrevYear := 0D;
                    end;
                end;
            }

            trigger OnPreDataItem()
            begin
                IncomePageNo := 0;
                BalancePageNo := 0;
                NewPageStatus := false;
                IncomeHidden := false;
                BalanceHidden := false;

                "G/L Account".SetRange("Income/Balance", "G/L Account"."Income/Balance"::"Income Statement");
                if "G/L Account".IsEmpty() then
                    IncomeHidden := true;
                "G/L Account".SetRange("Income/Balance", "G/L Account"."Income/Balance"::"Balance Sheet");
                if "G/L Account".IsEmpty() then
                    BalanceHidden := true;
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
                    field(OnlyIfChange; OnlyIfChange)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Accounts with netchange';
                        ToolTip = 'Specifies that you want to include only general ledger accounts that have a net change in the period defined in the date filter. If you do not select this field, all accounts will be displayed.';
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
        PeriodText := "G/L Account".GetFilter("Date Filter");
    end;

    var
        AccPeriod: Record "Accounting Period";
        Incoming: Record "G/L Account";
        YearToDate: Record "G/L Account";
        PrevYearToDate: Record "G/L Account";
        PeriodPrevYear: Record "G/L Account";
        GLFilter: Text[250];
        PeriodText: Text[30];
        LastDayPrevYear: Date;
        FirstDayThisYear: Date;
        FirstDayPrevYear: Date;
        PeriodStartThisYear: Date;
        PeriodEndThisYear: Date;
        PeriodStartPrevYear: Date;
        PeriodEndPrevYear: Date;
        YearToDatePct: Decimal;
        PeriodPct: Decimal;
        OnlyIfChange: Boolean;
        Text1080000: Label 'Period';
        Text1080001: Label 'Year To date';
        IncomePageNo: Integer;
        BalancePageNo: Integer;
        NewPageStatus: Boolean;
        TrialBalPreviousPeriodCaptionLbl: Label 'Trial Balance/Previous Period';
        PageNoCaptionLbl: Label 'Page No';
        GLAccNameCaptionLbl: Label 'Name';
        PrevYearCaptionLbl: Label 'Last Year';
        DifferenceCaptionLbl: Label 'Difference';
        PeriodPctCaptionLbl: Label '%';
        YearToDateCaptionLbl: Label 'This Year';
        OutgoingBalanceCaptionLbl: Label 'Outgoing Balance';
        IncomeHidden: Boolean;
        BalanceHidden: Boolean;
        GLAccountType: Integer;
        IncomeBalanceOptionNo: Integer;
}

