// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using System.Utilities;

report 11306 "Trial Balance - Debit/Credit"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/FinancialMgt/FinancialReports/TrialBalanceDebitCredit.rdlc';
    Caption = 'Trial Balance - Debit/Credit';

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Account Type", "Date Filter", "Global Dimension 1 Filter", "Global Dimension 2 Filter";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(PeriodPeriodText; Text11302 + PeriodText)
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(PeriodText; PeriodText)
            {
            }
            column(GLAccountGLFilter; "G/L Account".TableCaption + ': ' + GLFilter)
            {
            }
            column(GLFilter; GLFilter)
            {
            }
            column(AmountInGLSetupAddReportingCurr; StrSubstNo(Text11303, GLSetup."Additional Reporting Currency"))
            {
            }
            column(UseAmtsInAddCurr; UseAmtsInAddCurr)
            {
            }
            column(TrialBalanceCaption; TrialBalanceCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(EndBalanceCaption; EndBalanceCaptionLbl)
            {
            }
            column(NoCaption; NoCaptionLbl)
            {
            }
            column(NameCaption; NameCaptionLbl)
            {
            }
            column(NetChangeDebitCaption; NetChangeDebitCaptionLbl)
            {
            }
            column(NetChangeCreditCaption; NetChangeCreditCaptionLbl)
            {
            }
            column(BeginBalanceCaption; BeginBalanceCaptionLbl)
            {
            }
            column(No_GLAcc; "No.")
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
                column(GLAccNo; "G/L Account"."No.")
                {
                }
                column(GLAccIndentation2GLAccName; PadStr('', "G/L Account".Indentation * 2) + "G/L Account".Name)
                {
                }
                column(YearDebit; YearDebit)
                {
                    AutoFormatExpression = GetCurrency();
                    AutoFormatType = 1;
                }
                column(YearCredit; YearCredit)
                {
                    AutoFormatExpression = GetCurrency();
                    AutoFormatType = 1;
                }
                column(ABSYearBalanceAtDate; Abs(YearBalanceAtDate))
                {
                    AutoFormatExpression = GetCurrency();
                    AutoFormatType = 1;
                }
                column(FormattedBBT; Format(BBT))
                {
                }
                column(FormattedEBT; Format(EBT))
                {
                }
                column(ABSYearNetChange; Abs(YearNetChange))
                {
                    AutoFormatExpression = GetCurrency();
                    AutoFormatType = 1;
                }
                column(GLAccNoOfBlankLines; "G/L Account"."No. of Blank Lines")
                {
                }
                column(GLAccIndentation; "G/L Account".Indentation)
                {
                }
                column(AccountType; AccountType)
                {
                }
                column(PageGroupNo; PageGroupNo)
                {
                }
            }

            trigger OnAfterGetRecord()
            begin
                SetRange("Date Filter", 0D, ClosingDate(ToDate1));
                CalcFields("Net Change", "Additional-Currency Net Change");

                if "Additional-Currency Net Change" > 0 then
                    BBT := Text11300
                else
                    if "Additional-Currency Net Change" < 0 then
                        BBT := Text11301
                    else
                        BBT := ' ';

                if "Net Change" > 0 then
                    BBT := Text11300
                else
                    if "Net Change" < 0 then
                        BBT := Text11301
                    else
                        BBT := ' ';

                SetRange("Date Filter", FromDate, ToDate);
                CalcFields("Debit Amount", "Credit Amount", "Balance at Date", "Add.-Currency Debit Amount",
                  "Add.-Currency Credit Amount", "Add.-Currency Balance at Date");

                if "Add.-Currency Balance at Date" > 0 then
                    EBT := Text11300
                else
                    if "Add.-Currency Balance at Date" < 0 then
                        EBT := Text11301
                    else
                        EBT := ' ';

                if "Balance at Date" > 0 then
                    EBT := Text11300
                else
                    if "Balance at Date" < 0 then
                        EBT := Text11301
                    else
                        EBT := ' ';

                if UseAmtsInAddCurr then begin
                    YearNetChange := "Additional-Currency Net Change";
                    YearBalanceAtDate := "Add.-Currency Balance at Date";
                    YearDebit := "Add.-Currency Debit Amount";
                    YearCredit := "Add.-Currency Credit Amount";
                end else begin
                    YearNetChange := "Net Change";
                    YearBalanceAtDate := "Balance at Date";
                    YearDebit := "Debit Amount";
                    YearCredit := "Credit Amount";
                end;

                // new client
                AccountType := "G/L Account"."Account Type".AsInteger();
                if NewPage then begin
                    PageGroupNo := PageGroupNo + 1;
                    NewPage := false;
                end;
                NewPage := "New Page";
            end;

            trigger OnPreDataItem()
            begin
                GLSetup.Get();

                // new client
                PageGroupNo := 1;
                NewPage := false;
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
                    field(UseAmtsInAddCurr; UseAmtsInAddCurr)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Amounts in Add. Reporting Currency';
                        MultiLine = true;
                        ToolTip = 'Specifies if you want the amounts to be printed in the additional reporting currency. If you leave this check box empty, the amounts will be printed in LCY.';
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
        FromDate := "G/L Account".GetRangeMin("Date Filter");
        ToDate := "G/L Account".GetRangeMax("Date Filter");
        if FromDate > 00000101D then
            ToDate1 := FromDate - 1
        else
            ToDate1 := 0D;
    end;

    var
        Text11300: Label 'D', Locked = true;
        Text11301: Label 'C', Locked = true;
        Text11302: Label 'Period: ';
        Text11303: Label 'Amounts are in %1.';
        GLSetup: Record "General Ledger Setup";
        GLFilter: Text[250];
        PeriodText: Text[30];
        FromDate: Date;
        ToDate: Date;
        ToDate1: Date;
        BBT: Text[1];
        EBT: Text[1];
        UseAmtsInAddCurr: Boolean;
        YearNetChange: Decimal;
        YearBalanceAtDate: Decimal;
        YearDebit: Decimal;
        YearCredit: Decimal;
        AccountType: Integer;
        PageGroupNo: Integer;
        NewPage: Boolean;
        TrialBalanceCaptionLbl: Label 'Trial Balance';
        PageCaptionLbl: Label 'Page';
        EndBalanceCaptionLbl: Label 'End Balance';
        NoCaptionLbl: Label 'No.';
        NameCaptionLbl: Label 'Name';
        NetChangeDebitCaptionLbl: Label 'Net Change Debit';
        NetChangeCreditCaptionLbl: Label 'Net Change Credit';
        BeginBalanceCaptionLbl: Label 'Begin Balance';

    [Scope('OnPrem')]
    procedure GetCurrency(): Code[10]
    begin
        if UseAmtsInAddCurr then
            exit(GLSetup."Additional Reporting Currency");
        exit('');
    end;
}

