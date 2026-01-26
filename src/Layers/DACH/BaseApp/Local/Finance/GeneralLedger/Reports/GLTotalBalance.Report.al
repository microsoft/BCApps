// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Period;
using System.Utilities;

report 11002 "G/L Total-Balance"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/GeneralLedger/Reports/GLTotalBalance.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'G/L Total-Balance';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Account Type", "Date Filter", "Global Dimension 1 Filter", "Global Dimension 2 Filter";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(PeriodText_GLAcc; StrSubstNo(Text1140001, PeriodText))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(HeaderText; HeaderText)
            {
            }
            column(GLAccFilterTableCaption; "G/L Account".TableCaption + ': ' + GLAccFilter)
            {
            }
            column(GLAccFilter; GLAccFilter)
            {
            }
            column(PeriodText; PeriodText)
            {
            }
            column(PeriodCaption; PeriodCaptionLbl)
            {
            }
            column(YearCaption; YearCaptionLbl)
            {
            }
            column(YearText; YearText)
            {
            }
            column(YearStartDateFormatted; '..' + Format(YearStartDate - 1))
            {
            }
            column(AccPeriodStartingDate; '..' + Format(AccountingPeriod."Starting Date" - 1))
            {
            }
            column(EndDateFormatted; '..' + Format(EndDate))
            {
            }
            column(No_GLAcc; "No.")
            {
            }
            column(GLTotalBalanceCaption; GLTotalBalanceCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(GLAccountNoCaption_GLAcc; FieldCaption("No."))
            {
            }
            column(GLAccIndentNameCaption; GLAccIndentNameCaptionLbl)
            {
            }
            column(StartingBalanceCaption; StartingBalanceCaptionLbl)
            {
            }
            column(DebitCaption; DebitCaptionLbl)
            {
            }
            column(CreditCaption; CreditCaptionLbl)
            {
            }
            column(YearEndingBalanceCaption; YearEndingBalanceCaptionLbl)
            {
            }
            column(DebitCreditCaption; DebitCreditCaptionLbl)
            {
            }
            column(PeriodEndBalanceCaption; PeriodEndBalanceCaptionLbl)
            {
            }
            dataitem(BlankLineCounter; "Integer")
            {
                DataItemTableView = sorting(Number);
                column(PageGroupNo1; PageGroupNo)
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
                column(GLAccountNo; "G/L Account"."No.")
                {
                }
                column(GLAccountName; PadStr('', "G/L Account".Indentation * 2) + "G/L Account".Name)
                {
                }
                column(StartBalance; StartBalance)
                {
                    AutoFormatType = 1;
                }
                column(PeriodDebitAmount; PeriodDebitAmount)
                {
                    AutoFormatType = 1;
                }
                column(PeriodCreditAmount; PeriodCreditAmount)
                {
                    AutoFormatType = 1;
                }
                column(YearDebitAmount; YearDebitAmount)
                {
                    AutoFormatType = 1;
                }
                column(YearCreditAmount; YearCreditAmount)
                {
                    AutoFormatType = 1;
                }
                column(EndBalance; EndBalance)
                {
                    AutoFormatType = 1;
                }
                column(StartBalanceType; StartBalanceType)
                {
                    OptionCaption = ' ,Debit,Credit';
                }
                column(EndBalanceType; EndBalanceType)
                {
                    OptionCaption = ' ,Debit,Credit';
                }
                column(PeriodEndBalance; PeriodEndBalance)
                {
                    AutoFormatType = 1;
                }
                column(PeriodEndBalanceType; PeriodEndBalanceType)
                {
                    OptionCaption = ' ,Debit,Credit';
                }
                column(PageGroupNo; PageGroupNo)
                {
                }
                column(AccountTypeIntB; AccountTypeInt)
                {
                }
                column(NoOfBlankLines_GLAcc; "G/L Account"."No. of Blank Lines")
                {
                }
                column(EmptyStringCaption; EmptyStringCaptionLbl)
                {
                }
            }

            trigger OnAfterGetRecord()
            begin
                if "G/L Account".GetFilter("No.") <> '' then
                    if (("Account Type" = "G/L Account"."Account Type"::Total) or
                        ("Account Type" = "G/L Account"."Account Type"::"End-Total"))
                    then
                        "G/L Account".Totaling := '(' + Totaling + ')' + '&' + '(' + "G/L Account".GetFilter("No.") + ')';

                SetRange("Date Filter", 0D, ClosingDate(YearStartDate - 1));
                CalcFields("Net Change");
                if "Net Change" <> 0 then
                    if "Net Change" > 0 then
                        StartBalanceType := StartBalanceType::Debit
                    else
                        StartBalanceType := StartBalanceType::Credit
                else
                    StartBalanceType := 0;
                StartBalance := Abs("Net Change");

                SetRange("Date Filter", StartDate, EndDate);
                CalcFields("Debit Amount", "Credit Amount");
                PeriodDebitAmount := "Debit Amount";
                PeriodCreditAmount := "Credit Amount";

                SetRange("Date Filter", 0D, EndDate);
                CalcFields("Net Change");
                if "Net Change" <> 0 then
                    if "Net Change" > 0 then
                        PeriodEndBalanceType := PeriodEndBalanceType::Debit
                    else
                        PeriodEndBalanceType := PeriodEndBalanceType::Credit
                else
                    PeriodEndBalanceType := 0;
                PeriodEndBalance := Abs("Net Change");

                SetRange("Date Filter", YearStartDate, EndDate);
                CalcFields("Debit Amount", "Credit Amount");
                YearDebitAmount := "Debit Amount";
                YearCreditAmount := "Credit Amount";

                SetRange("Date Filter", 0D, AccountingPeriod."Starting Date" - 1);
                CalcFields("Net Change");
                if "Net Change" <> 0 then
                    if "Net Change" > 0 then
                        EndBalanceType := EndBalanceType::Debit
                    else
                        EndBalanceType := EndBalanceType::Credit
                else
                    EndBalanceType := 0;
                EndBalance := Abs("Net Change");

                SetRange("Date Filter", StartDate, EndDate);

                AccountTypeInt := "G/L Account"."Account Type".AsInteger();
                if NewPage then begin
                    PageGroupNo := PageGroupNo + 1;
                    NewPage := false;
                end;
                NewPage := "New Page";
            end;

            trigger OnPreDataItem()
            begin
                PageGroupNo := 1;
                NewPage := false;
            end;
        }
    }

    requestpage
    {

        layout
        {
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
        GLAccFilter := "G/L Account".GetFilters();
        PeriodText := "G/L Account".GetFilter("Date Filter");
        StartDate := "G/L Account".GetRangeMin("Date Filter");
        EndDate := "G/L Account".GetRangeMax("Date Filter");

        AccountingPeriod.Reset();
        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod."Starting Date" := StartDate;
        AccountingPeriod.Find('=<');
        YearStartDate := AccountingPeriod."Starting Date";
        if AccountingPeriod.Next() = 0 then
            Error(Text1140000);

        YearText := Format(YearStartDate) + '..' + Format(EndDate);

        GLSetup.Get();
        GLSetup.TestField("LCY Code");
        HeaderText := StrSubstNo(Text1140021, GLSetup."LCY Code");
    end;

    var
        Text1140000: Label 'Accounting Period is not available';
        Text1140001: Label 'Period: %1';
        Text1140021: Label 'All amounts are in %1';
        AccountingPeriod: Record "Accounting Period";
        GLSetup: Record "General Ledger Setup";
        GLAccFilter: Text;
        PeriodText: Text;
        YearText: Text[30];
        HeaderText: Text[50];
        StartDate: Date;
        EndDate: Date;
        YearStartDate: Date;
        StartBalanceType: Option " ",Debit,Credit;
        StartBalance: Decimal;
        PeriodDebitAmount: Decimal;
        PeriodCreditAmount: Decimal;
        YearDebitAmount: Decimal;
        YearCreditAmount: Decimal;
        PageGroupNo: Integer;
        NewPage: Boolean;
        AccountTypeInt: Integer;
        PeriodCaptionLbl: Label 'Period';
        YearCaptionLbl: Label 'Year';
        GLTotalBalanceCaptionLbl: Label 'G/L Total-Balance';
        CurrReportPageNoCaptionLbl: Label 'Page';
        GLAccIndentNameCaptionLbl: Label 'Name';
        StartingBalanceCaptionLbl: Label 'Starting Balance';
        DebitCaptionLbl: Label 'Debit';
        CreditCaptionLbl: Label 'Credit';
        YearEndingBalanceCaptionLbl: Label 'Year Ending Balance';
        DebitCreditCaptionLbl: Label 'Debit/ Credit';
        PeriodEndBalanceCaptionLbl: Label 'Period Ending Balance';
        EmptyStringCaptionLbl: Label '**';

    protected var
        EndBalance: Decimal;
        EndBalanceType: Option " ",Debit,Credit;
        PeriodEndBalance: Decimal;
        PeriodEndBalanceType: Option " ",Debit,Credit;
}

