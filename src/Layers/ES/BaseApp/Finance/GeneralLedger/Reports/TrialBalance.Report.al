#if not CLEAN28
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Period;
using System.Utilities;

/// <summary>
/// Generates standard trial balance report displaying account balances and period movements.
/// Shows opening balances, period debits/credits, and closing balances for comprehensive G/L account analysis.
/// </summary>
/// <remarks>
/// Data source: G/L Account table with balance calculations and period filtering capabilities.
/// Used for financial statement preparation, account reconciliation, and period-end procedures.
/// Supports filtering by account types, date ranges, and global dimensions for customized trial balance reporting.
/// </remarks>
report 6 "Trial Balance"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Finance/GeneralLedger/Reports/TrialBalance.rdlc';
    AdditionalSearchTerms = 'year closing,close accounting period,close fiscal year';
    ApplicationArea = Basic, Suite;
    Caption = 'Trial Balance (Obsolete)';
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;
    DataAccessIntent = ReadOnly;
    ObsoleteState = Pending;
    ObsoleteReason = 'This report has been replaced by the report Trial Balance (Excel). This report will be removed in a future release.';
    ObsoleteTag = '28.0';

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Account Type", "Date Filter", "Global Dimension 1 Filter", "Global Dimension 2 Filter";
            column(WorkDateFormatted; Format(WorkDate(), 0, 4))
            {
            }
            column(PeriodText1; Text1100003 + PeriodText)
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(PeriodText; PeriodText)
            {
            }
            column(HeaderText; HeaderText)
            {
            }
            column(IncludeEntries; IncludeEntries)
            {
            }
            column(GLFilter_GLAccount; TableCaption() + ': ' + GetFilters())
            {
            }
            column(GLFilter; GLFilter)
            {
            }
            column(AcumBalance; AcumBalance)
            {
            }
            column(TotalDebitAmtAtEnd; TotalDebitAmtAtEnd)
            {
            }
            column(TotalCreditAmtAtEnd; TotalCreditAmtAtEnd)
            {
            }
            column(TotalBalanceAtEnd; TotalBalanceAtEnd)
            {
            }
            column(TotalPeriodDebitAmt; TotalPeriodDebitAmt)
            {
            }
            column(TotalPeriodCreditAmt; TotalPeriodCreditAmt)
            {
            }
            column(G_L_Account_No_; "No.")
            {
            }
            column(TrialBalanceCaption; TrialBalanceCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(AccinPeriodCaption; AccinPeriodCaptionLbl)
            {
            }
            column(AccPeriodatDateCaption; AccPeriodatDateCaptionLbl)
            {
            }
            column(AccountCaption; AccountCaptionLbl)
            {
            }
            column(NameCaption; NameCaptionLbl)
            {
            }
            column(DebitCaption; DebitCaptionLbl)
            {
            }
            column(CreditCaption; CreditCaptionLbl)
            {
            }
            column(BalanceatDateCaption; BalanceatDateCaptionLbl)
            {
            }
            column(AcumBalanceatDateCaption; AcumBalanceatDateCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(G_L_Account___No__; "G/L Account"."No.")
                {
                }
                column(IndentName_GLAccount; PadStr('', "G/L Account".Indentation * 2) + "G/L Account".Name)
                {
                }
                column(DebitAmount_GLAccount; "G/L Account"."Debit Amount" + OpenDebitAmt + CloseDebitAmt)
                {
                }
                column(CreditAmount_GLAccount; "G/L Account"."Credit Amount" + OpenCreditAmt + CloseCreditAmt)
                {
                }
                column(DebitAmount2_GLAccount; GLAcc2."Debit Amount" + OpenDebitAmtEnd + CloseDebitAmt)
                {
                }
                column(CreditAmount2_GLAccount; GLAcc2."Credit Amount" + OpenCreditAmtEnd + CloseCreditAmt)
                {
                }
                column(BalanceType; BalanceType)
                {
                }
                column(CreditAmount3_GLAccount; GLAcc2."Add.-Currency Credit Amount" + OpenCreditAmtEnd + CloseCreditAmt)
                {
                }
                column(DebitAmount3_GLAccount; GLAcc2."Add.-Currency Debit Amount" + OpenDebitAmtEnd + CloseDebitAmt)
                {
                }
                column(CreditAmount4_GLAccount; "G/L Account"."Add.-Currency Credit Amount" + OpenCreditAmt + CloseCreditAmt)
                {
                }
                column(DebitAmount4_GLAccount; "G/L Account"."Add.-Currency Debit Amount" + OpenDebitAmt + CloseDebitAmt)
                {
                }
                column(AccountType_GLAccount; Format("G/L Account"."Account Type", 0, 2))
                {
                }
                column(GLFilterOption; Format(GLFilterOption, 0, 2))
                {
                }
                column(NoofBlankLines_GLAccount; "G/L Account"."No. of Blank Lines")
                {
                }
                column(PrintAmountsInAddCurrency; PrintAmountsInAddCurrency)
                {
                }
                column(PageGroupNo; PageGroupNo)
                {
                }
                column(AccountType_GLAcc; "G/L Account"."Account Type")
                {
                }
                dataitem(BlankLineRepeater; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    column(BlankLineNo; BlankLineNo)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if BlankLineNo = 0 then
                            CurrReport.Break();

                        BlankLineNo -= 1;
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    BlankLineNo := "G/L Account"."No. of Blank Lines" + 1;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                Accumulate := false;
                CalcFields("Debit Amount", "Credit Amount", "Balance at Date", "Add.-Currency Debit Amount",
                           "Add.-Currency Credit Amount", "Add.-Currency Balance at Date", "Net Change", "Balance at Date");
                GLAcc2 := "G/L Account";
                SetGLAccDateFilter();
                if GlobalDim1 <> '' then
                    "G/L Account".CopyFilter("G/L Account"."Global Dimension 1 Filter", GLAcc2."Global Dimension 1 Filter");
                if GlobalDim2 <> '' then
                    "G/L Account".CopyFilter("G/L Account"."Global Dimension 2 Filter", GLAcc2."Global Dimension 2 Filter");
                GLAcc2.CalcFields("Additional-Currency Net Change", "Net Change", "Debit Amount", "Credit Amount",
                                  "Add.-Currency Debit Amount", "Add.-Currency Credit Amount", "Balance at Date");
                if PrintAmountsInAddCurrency then begin
                    PreviousBalance := GLAcc2."Additional-Currency Net Change";
                    BalanceType := GLAcc2."Additional-Currency Net Change";
                    if AcumBalance then
                        BalanceType := GLAcc2."Add.-Currency Balance at Date";
                end else begin
                    PreviousBalance := GLAcc2."Net Change";
                    BalanceType := GLAcc2."Net Change";
                    if AcumBalance then
                        BalanceType := GLAcc2."Balance at Date";
                end;
                OpenCreditAmt := 0;
                OpenDebitAmt := 0;
                OpenCreditAmtEnd := 0;
                OpenDebitAmtEnd := 0;
                if OpenEntries then begin
                    if "Account Type" = "Account Type"::Heading then
                        CalcOpenEntriesHeading()
                    else
                        CalcOpenEntries();
                    if not AcumBalance then
                        BalanceType := BalanceType + OpenDebitAmtEnd - OpenCreditAmtEnd
                    else begin
                        OpenDebitAmtEnd := 0;
                        OpenCreditAmtEnd := 0;
                    end;
                end;
                CloseDebitAmt := 0;
                CloseCreditAmt := 0;
                if CloseEntries then begin
                    if "Account Type" = "Account Type"::Heading then
                        CalcCloseEntriesHeading()
                    else
                        CalcCloseEntries();
                    if not AcumBalance then
                        BalanceType := BalanceType + CloseDebitAmt - CloseCreditAmt
                    else
                        BalanceType := GLAcc2."Net Change" - BalanceType;
                end;

                if AcumBalance and (not OpenEntries) and (not CloseEntries) then
                    BalanceType := GLAcc2."Net Change";

                PreviousDebit := 0;
                PreviousCredit := 0;
                if PreviousBalance > 0 then
                    PreviousDebit := PreviousBalance
                else
                    PreviousCredit := Abs(PreviousBalance);
                GLAcc.SetRange("Date Filter", FromFec, ToFec);
                if GlobalDim1 <> '' then
                    "G/L Account".CopyFilter("G/L Account"."Global Dimension 1 Filter", GLAcc2."Global Dimension 1 Filter");
                if GlobalDim2 <> '' then
                    "G/L Account".CopyFilter("G/L Account"."Global Dimension 2 Filter", GLAcc2."Global Dimension 2 Filter");
                GLAcc.CalcFields("Debit Amount", "Credit Amount", "Add.-Currency Debit Amount", "Add.-Currency Credit Amount",
                  "Net Change", "Balance at Date");
                if not PrintAmountsInAddCurrency then begin
                    DebitAmtAtEnd := GLAcc2."Debit Amount";
                    CreditAmtAtEnd := GLAcc2."Credit Amount";
                    I := I + 1;
                    if I = 1 then
                        FixedLevel := StrLen("No.");
                    if (CopyStr("No.", 1, 1) <> PrevAccount) and (StrLen("No.") >= FixedLevel) then begin
                        Accumulate := true;
                        FirstLevel := StrLen("No.");
                    end else
                        Accumulate := GetAccumulate();
                    if Accumulate or (GLFilterOption = GLFilterOption::Posting) then begin
                        TotalPeriodDebitAmt := TotalPeriodDebitAmt + "Debit Amount" + CloseDebitAmt;
                        TotalPeriodCreditAmt := TotalPeriodCreditAmt + "Credit Amount" + CloseCreditAmt;
                        if IsOpenDate then begin
                            TotalPeriodDebitAmt := TotalPeriodDebitAmt + OpenDebitAmt;
                            TotalPeriodCreditAmt := TotalPeriodCreditAmt + OpenCreditAmt;
                        end;
                        TotalDebitAmtAtEnd := TotalDebitAmtAtEnd + DebitAmtAtEnd + OpenDebitAmtEnd + CloseDebitAmt;
                        TotalCreditAmtAtEnd := TotalCreditAmtAtEnd + CreditAmtAtEnd + OpenCreditAmtEnd + CloseCreditAmt;
                        if OpenEntries or CloseEntries then
                            TotalBalanceAtEnd := TotalBalanceAtEnd + BalanceType
                        else
                            TotalBalanceAtEnd := TotalBalanceAtEnd + PreviousBalance;
                        AddAccumulatedAccountsFilter();
                    end;
                end else begin
                    DebitAmtAtEnd := GLAcc2."Add.-Currency Debit Amount";
                    CreditAmtAtEnd := GLAcc2."Add.-Currency Credit Amount";
                    if CopyStr("No.", 1, 1) <> PrevAccount then begin
                        Accumulate := true;
                        FirstLevel := StrLen("No.");
                    end else
                        if (StrLen("No.") <= PreviousLevel) and (StrLen("No.") <= FirstLevel) then
                            Accumulate := true
                        else
                            Accumulate := false;
                    if Accumulate or (GLFilterOption = GLFilterOption::Posting) then begin
                        TotalPeriodDebitAmt := TotalPeriodDebitAmt + "Add.-Currency Debit Amount" + CloseDebitAmt;
                        TotalPeriodCreditAmt := TotalPeriodCreditAmt + "Add.-Currency Credit Amount" + CloseCreditAmt;
                        if IsOpenDate then begin
                            TotalPeriodDebitAmt := TotalPeriodDebitAmt + OpenDebitAmt;
                            TotalPeriodCreditAmt := TotalPeriodCreditAmt + OpenCreditAmt;
                        end;
                        TotalDebitAmtAtEnd := TotalDebitAmtAtEnd + DebitAmtAtEnd + OpenDebitAmtEnd + CloseDebitAmt;
                        TotalCreditAmtAtEnd := TotalCreditAmtAtEnd + CreditAmtAtEnd + OpenCreditAmtEnd + CloseCreditAmt;
                        if OpenEntries or CloseEntries then
                            TotalBalanceAtEnd := TotalBalanceAtEnd + BalanceType
                        else
                            TotalBalanceAtEnd := TotalBalanceAtEnd + PreviousBalance;
                        AddAccumulatedAccountsFilter();
                    end;
                end;

                if (StrLen("No.") >= FixedLevel) then begin
                    PreviousLevel := StrLen("No.");
                    PrevAccount := CopyStr("No.", 1, 1);
                end;

                if PrintAllHavingBal and ("Balance at Date" = 0) and ("Debit Amount" = 0) and ("Credit Amount" = 0) then
                    CurrReport.Skip();

                if GlobalNo < 1 then begin
                    GLSetup.Get();
                    if PrintAmountsInAddCurrency then
                        HeaderText := StrSubstNo(Text1100004, GLSetup."Additional Reporting Currency")
                    else begin
                        GLSetup.TestField("LCY Code");
                        HeaderText := StrSubstNo(Text1100004, GLSetup."LCY Code");
                    end;
                    if OpenEntries and not CloseEntries then
                        IncludeEntries := Text1100005;
                    if CloseEntries and not OpenEntries then
                        IncludeEntries := Text1100006;
                    if CloseEntries and OpenEntries then
                        IncludeEntries := Text1100007;
                    GlobalNo := GlobalNo + 1;
                end;

                PageGroupNo := NextPageGroupNo;
                if "New Page" then
                    NextPageGroupNo := PageGroupNo + 1;
            end;

            trigger OnPostDataItem()
            begin
                "G/L Account".SetRange("Date Filter");
                "G/L Account".SetRange("Global Dimension 1 Filter");
                "G/L Account".SetRange("Global Dimension 2 Filter");
                /*CurrReport.SHOWOUTPUT(Cuenta.GETFILTERS = '');*/

            end;

            trigger OnPreDataItem()
            var
                UndefinedValue: Integer;
            begin
                UndefinedValue := -1;
                FromFec := 0D;
                if GetFilter("Date Filter") = '' then
                    ToFec := DMY2Date(31, 12, 9999)
                else begin
                    FromFec := GetRangeMin("Date Filter");
                    ToFec := GetRangeMax("Date Filter");
                end;
                DebitAmtAtEnd := 0;
                CreditAmtAtEnd := 0;
                GLFilter := "G/L Account".GetFilter("Account Type");
                if GLFilter <> '' then begin
                    // Only accept single account type filter, to display both 2 types user should leave this filter blank.
                    GLFilterValue := GetRangeMin("Account Type");
                    GLFilterOption := GLFilterValue.AsInteger();
                    SetRange("Account Type", GLFilterOption);
                end else
                    GLFilterOption := UndefinedValue;

                if CloseEntries then
                    if ToFec <> NormalDate(ToFec) then
                        IsClosingDate(ToFec)
                    else
                        Error(Text1100002, ToFec);
                if OpenEntries then
                    IsOpenDate := IsOpeningDate(FromFec);
                I := 0;

                PageGroupNo := 1;
                NextPageGroupNo := 1;
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Trial Balance (Obsolete)';
        AboutText = 'View a snapshot of your chart of accounts with a balance at date and net change in the specified period.** This report is obsolete and will be removed in a future release.** Please refer to the report documentation for alternative ways to retrieve this information.';

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(OnlyGLAccountsWithBalanceAtDate; PrintAllHavingBal)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Only G/L accounts with Balance at Date';
                        MultiLine = true;
                        ToolTip = 'Specifies if only the general ledger accounts with a balance are included in the report.';
                    }
                    field(ShowAmountsInAddCurrency; PrintAmountsInAddCurrency)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Amounts in Add. Currency';
                        ToolTip = 'Specifies if amounts in the additional currency are included.';
                    }
                    field(AcumBalanceAtDate; AcumBalance)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Acum. Balance at date';
                        ToolTip = 'Specifies if the report displays an accumulative balance.';
                    }
                    field(IncludeOpeningEntries; OpenEntries)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include Opening Entries';
                        ToolTip = 'Specifies if opening entries are included in the report.';
                    }
                    field(IncludeClosingEntries; CloseEntries)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include Closing Entries';
                        ToolTip = 'Specifies if closing entries are included in the report.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            PrintAllHavingBal := true;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        "G/L Account".SecurityFiltering(SecurityFilter::Filtered);
        PeriodText := "G/L Account".GetFilter("Date Filter");
        GlobalDim1 := "G/L Account".GetFilter("G/L Account"."Global Dimension 1 Filter");
        GlobalDim2 := "G/L Account".GetFilter("G/L Account"."Global Dimension 2 Filter");
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1100002: Label 'The date %1 is not a Closing Date';
        Text1100003: Label 'Period: ';
        Text1100004: Label 'All Amounts in %1';
        Text1100005: Label 'Include Opening Entries';
        Text1100006: Label 'Include Closing Entries';
        Text1100007: Label 'Include Closing/Opening Entries';
        Text1100008: Label 'The fiscal year does not exist';
#pragma warning restore AA0470
#pragma warning restore AA0074
        GLSetup: Record "General Ledger Setup";
        GLAcc: Record "G/L Account";
        GLAcc2: Record "G/L Account";
        AccumulateAccountsFilter: TextBuilder;
        HeaderText: Text[30];
        PeriodText: Text[30];
        FromFec: Date;
        ToFec: Date;
        IncludeEntries: Text[40];
        GLFilterOption: Option Posting,Heading;
        GLFilterValue: Enum "G/L Account Type";
        PreviousBalance: Decimal;
        PreviousDebit: Decimal;
        PreviousCredit: Decimal;
        IsOpenDate: Boolean;
        DebitAmtAtEnd: Decimal;
        CreditAmtAtEnd: Decimal;
        TotalPeriodDebitAmt: Decimal;
        TotalPeriodCreditAmt: Decimal;
        TotalBalanceAtEnd: Decimal;
        TotalDebitAmtAtEnd: Decimal;
        TotalCreditAmtAtEnd: Decimal;
        OpenCreditAmt: Decimal;
        OpenDebitAmt: Decimal;
        CloseCreditAmt: Decimal;
        CloseDebitAmt: Decimal;
        OpenCreditAmtEnd: Decimal;
        OpenDebitAmtEnd: Decimal;
        PreviousLevel: Integer;
        PrevAccount: Code[1];
        FirstLevel: Integer;
        Accumulate: Boolean;
        GlobalDim1: Text[30];
        GlobalDim2: Text[30];
        I: Integer;
        FixedLevel: Integer;
        GlobalNo: Integer;
        TrialBalanceCaptionLbl: Label 'Trial Balance';
        PageCaptionLbl: Label 'Page';
        AccinPeriodCaptionLbl: Label 'Acc. in Period';
        AccPeriodatDateCaptionLbl: Label 'Acc. Period at Date';
        AccountCaptionLbl: Label 'Account';
        NameCaptionLbl: Label 'Name';
        DebitCaptionLbl: Label 'Debit';
        CreditCaptionLbl: Label 'Credit';
        BalanceatDateCaptionLbl: Label 'Balance at Date';
        AcumBalanceatDateCaptionLbl: Label 'Acum. Balance at Date';
        TotalCaptionLbl: Label 'Total. . . . . . . . ';
        BlankLineNo: Integer;

    protected var
        AcumBalance: Boolean;
        CloseEntries: Boolean;
        OpenEntries: Boolean;
        GLFilter: Text;
        PageGroupNo: Integer;
        NextPageGroupNo: Integer;
        PrintAllHavingBal: Boolean;
        PrintAmountsInAddCurrency: Boolean;
        BalanceType: Decimal;

    [Scope('OnPrem')]
    procedure StartingPeriod(Date: Date): Date
    var
        AccPeriod: Record "Accounting Period";
    begin
        AccPeriod.SetRange("New Fiscal Year", true);
        AccPeriod.SetFilter("Starting Date", '<= %1', Date);
        if AccPeriod.FindLast() then
            exit(AccPeriod."Starting Date")
        else
            Error(Text1100008);
    end;

    [Scope('OnPrem')]
    procedure IsOpeningDate(Date: Date): Boolean
    var
        AccPeriod5: Record "Accounting Period";
    begin
        AccPeriod5.SetRange(AccPeriod5."New Fiscal Year", true);
        AccPeriod5.SetRange(AccPeriod5."Starting Date", Date);
        exit(not AccPeriod5.IsEmpty());
    end;

    [Scope('OnPrem')]
    procedure IsClosingDate(ToFec: Date)
    var
        AccPeriod2: Record "Accounting Period";
    begin
        AccPeriod2.SetRange(AccPeriod2."New Fiscal Year", true);
        if AccPeriod2.Get(NormalDate(ToFec) + 1) then
            exit
        else
            Error(Text1100002, ToFec);
    end;

    [Scope('OnPrem')]
    procedure CalcOpenEntries()
    var
        GlAccount3: Record "G/L Account";
        AccPeriod3: Record "Accounting Period";
    begin
        AccPeriod3.SetRange(AccPeriod3."New Fiscal Year", true);
        AccPeriod3.SetFilter(AccPeriod3."Starting Date", '<= %1', FromFec);
        if not AccPeriod3.FindLast() then
            exit;

        GlAccount3.Get("G/L Account"."No.");
        GlAccount3.SetRange(GlAccount3."Date Filter", 0D, ClosingDate((AccPeriod3."Starting Date" - 1)));
        if GlobalDim1 <> '' then
            GlAccount3.SetFilter("Global Dimension 1 Filter", GlobalDim1);
        if GlobalDim2 <> '' then
            GlAccount3.SetFilter("Global Dimension 2 Filter", GlobalDim2);
        GlAccount3.CalcFields("Additional-Currency Net Change", "Net Change");
        if PrintAmountsInAddCurrency then begin
            if GlAccount3."Additional-Currency Net Change" > 0 then
                OpenDebitAmtEnd := GlAccount3."Additional-Currency Net Change"
            else
                OpenCreditAmtEnd := Abs(GlAccount3."Additional-Currency Net Change");
        end else
            if GlAccount3."Net Change" > 0 then
                OpenDebitAmtEnd := GlAccount3."Net Change"
            else
                OpenCreditAmtEnd := Abs(GlAccount3."Net Change");
        if IsOpenDate then begin
            OpenDebitAmt := OpenDebitAmtEnd;
            OpenCreditAmt := OpenCreditAmtEnd;
        end;
    end;

    [Scope('OnPrem')]
    procedure CalcCloseEntries()
    var
        GlAccount4: Record "G/L Account";
        AccPeriod4: Record "Accounting Period";
    begin
        AccPeriod4.SetRange(AccPeriod4."New Fiscal Year", true);
        AccPeriod4.Get((NormalDate(ToFec) + 1));
        GlAccount4.Get("G/L Account"."No.");
        GlAccount4.SetRange(GlAccount4."Date Filter", 0D, ToFec);
        if GlobalDim1 <> '' then
            GlAccount4.SetFilter("Global Dimension 1 Filter", GlobalDim1);
        if GlobalDim2 <> '' then
            GlAccount4.SetFilter("Global Dimension 2 Filter", GlobalDim2);
        GlAccount4.CalcFields("Additional-Currency Net Change", "Net Change");
        if PrintAmountsInAddCurrency then begin
            if GlAccount4."Additional-Currency Net Change" > 0 then
                CloseCreditAmt := Abs(GlAccount4."Additional-Currency Net Change")
            else
                CloseDebitAmt := Abs(GlAccount4."Additional-Currency Net Change");
        end else
            if GlAccount4."Net Change" > 0 then
                CloseCreditAmt := Abs(GlAccount4."Net Change")
            else
                CloseDebitAmt := Abs(GlAccount4."Net Change");
    end;

    [Scope('OnPrem')]
    procedure CalcCloseEntriesHeading()
    var
        GLAcc: Record "G/L Account";
    begin
        GLAcc.SetRange("Date Filter", 0D, ToFec);
        GLAcc.SetFilter("No.", "G/L Account".Totaling);
        GLAcc.SetRange("Account Type", GLAcc."Account Type"::Posting);
        if GlobalDim1 <> '' then
            GLAcc.SetFilter("Global Dimension 1 Filter", GlobalDim1);
        if GlobalDim2 <> '' then
            GLAcc.SetFilter("Global Dimension 2 Filter", GlobalDim2);

        GLAcc.SetAutoCalcFields("Additional-Currency Net Change", "Net Change");
        if GLAcc.FindSet() then
            repeat
                if PrintAmountsInAddCurrency then begin
                    if GLAcc."Additional-Currency Net Change" > 0 then
                        CloseCreditAmt := CloseCreditAmt + Abs(GLAcc."Additional-Currency Net Change")
                    else
                        CloseDebitAmt := CloseDebitAmt + Abs(GLAcc."Additional-Currency Net Change");
                end else
                    if GLAcc."Net Change" > 0 then
                        CloseCreditAmt := CloseCreditAmt + Abs(GLAcc."Net Change")
                    else
                        CloseDebitAmt := CloseDebitAmt + Abs(GLAcc."Net Change");
            until GLAcc.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CalcOpenEntriesHeading()
    var
        GLAcc: Record "G/L Account";
        AccPeriod3: Record "Accounting Period";
    begin
        AccPeriod3.SetRange(AccPeriod3."New Fiscal Year", true);
        AccPeriod3.SetFilter(AccPeriod3."Starting Date", '<= %1', FromFec);
        if not AccPeriod3.FindLast() then
            exit;

        GLAcc.SetRange("Date Filter", 0D, ClosingDate((AccPeriod3."Starting Date" - 1)));
        GLAcc.SetFilter("No.", "G/L Account".Totaling);
        GLAcc.SetRange("Account Type", GLAcc."Account Type"::Posting);
        if GlobalDim1 <> '' then
            GLAcc.SetFilter("Global Dimension 1 Filter", GlobalDim1);
        if GlobalDim2 <> '' then
            GLAcc.SetFilter("Global Dimension 2 Filter", GlobalDim2);
        GLAcc.SetAutoCalcFields("Additional-Currency Net Change", "Net Change");
        if GLAcc.FindSet() then
            repeat
                if PrintAmountsInAddCurrency then begin
                    if GLAcc."Additional-Currency Net Change" > 0 then
                        OpenDebitAmtEnd := OpenDebitAmtEnd + Abs(GLAcc."Additional-Currency Net Change")
                    else
                        OpenCreditAmtEnd := OpenCreditAmtEnd + Abs(GLAcc."Additional-Currency Net Change");
                end else
                    if GLAcc."Net Change" > 0 then
                        OpenDebitAmtEnd := OpenDebitAmtEnd + Abs(GLAcc."Net Change")
                    else
                        OpenCreditAmtEnd := OpenCreditAmtEnd + Abs(GLAcc."Net Change");
            until GLAcc.Next() = 0;
        if IsOpenDate then begin
            OpenDebitAmt := OpenDebitAmtEnd;
            OpenCreditAmt := OpenCreditAmtEnd;
        end;
    end;

    local procedure SetGLAccDateFilter()
    begin
        if AcumBalance then
            GLAcc2.SetRange("Date Filter", 0D, ToFec)
        else
            GLAcc2.SetRange("Date Filter", StartingPeriod(FromFec), ToFec);
    end;

    local procedure GetAccumulate(): Boolean
    begin
        if not GLAccountCalculated() then
            exit(true);

        if StrLen("G/L Account"."No.") = FixedLevel then
            exit(true);

        if (StrLen("G/L Account"."No.") <= PreviousLevel) and (StrLen("G/L Account"."No.") <= FirstLevel) and ((StrLen("G/L Account"."No.") <> FixedLevel) or (StrLen("G/L Account"."No.") = FixedLevel)) then
            exit(true);

        exit(false);
    end;

    local procedure GLAccountCalculated(): Boolean
    var
        GLAccount: Record "G/L Account";
    begin
        if CopyStr("G/L Account"."No.", 1, 1) <> PrevAccount then
            exit(false);

        if AccumulateAccountsFilter.Length = 0 then
            exit(false);

        GLAccount.SetFilter("No.", AccumulateAccountsFilter.ToText());
        if GLAccount.FindSet() then
            repeat
                if "G/L Account"."No." = GLAccount."No." then
                    exit(true);
            until GLAccount.Next() = 0;

        exit(false);
    end;

    local procedure AddAccumulatedAccountsFilter()
    begin
        if "G/L Account".Totaling = '' then
            exit;

        if AccumulateAccountsFilter.Length = 0 then
            AccumulateAccountsFilter.Append("G/L Account".Totaling)
        else
            AccumulateAccountsFilter.Append(StrSubstNo('|%1', "G/L Account".Totaling));
    end;
}

#endif