// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reports;

using Microsoft.Bank.BankAccount;
using Microsoft.Foundation.Period;

report 10809 "Bank Account Trial Balance"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/BankMgt/Reports/BankAccountTrialBalance.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Bank Account Trial Balance';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Bank Account"; "Bank Account")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Search Name", "Date Filter";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(STRSUBSTNO_Text003_USERID_; StrSubstNo(Text003, UserId))
            {
            }
            column(STRSUBSTNO_Text004_PreviousStartDate_; StrSubstNo(Text004, PreviousStartDate))
            {
            }
            column(STRSUBSTNO_Text005_____; StrSubstNo(Text005, ' '))
            {
            }
            column(PrintedByCaption; StrSubstNo(Text003, ''))
            {
            }
            column(Bank_Account__TABLECAPTION__________Filter; "Bank Account".TableCaption + ': ' + Filter)
            {
            }
            column("Filter"; Filter)
            {
            }
            column(Bank_Account__No__; "No.")
            {
            }
            column(Bank_Account_Name; Name)
            {
            }
            column(BankAccount2__Debit_Amount__LCY_____BankAccount2__Credit_Amount__LCY__; BankAccount2."Debit Amount (LCY)" - BankAccount2."Credit Amount (LCY)")
            {
            }
            column(BankAccount2__Credit_Amount__LCY_____BankAccount2__Debit_Amount__LCY__; BankAccount2."Credit Amount (LCY)" - BankAccount2."Debit Amount (LCY)")
            {
            }
            column(Bank_Account__Debit_Amount__LCY__; "Debit Amount (LCY)")
            {
            }
            column(Bank_Account__Credit_Amount__LCY__; "Credit Amount (LCY)")
            {
            }
            column(BankAccount2__Debit_Amount__LCY______Debit_Amount__LCY_____BankAccount2__Credit_Amount__LCY______Credit_Amount__LCY__; BankAccount2."Debit Amount (LCY)" + "Debit Amount (LCY)" - BankAccount2."Credit Amount (LCY)" - "Credit Amount (LCY)")
            {
            }
            column(BankAccount2__Credit_Amount__LCY______Credit_Amount__LCY_____BankAccount2__Debit_Amount__LCY______Debit_Amount__LCY__; BankAccount2."Credit Amount (LCY)" + "Credit Amount (LCY)" - BankAccount2."Debit Amount (LCY)" - "Debit Amount (LCY)")
            {
            }
            column(BankAccount2__Debit_Amount__LCY_____BankAccount2__Credit_Amount__LCY___Control1120069; BankAccount2."Debit Amount (LCY)" - BankAccount2."Credit Amount (LCY)")
            {
            }
            column(BankAccount2__Credit_Amount__LCY_____BankAccount2__Debit_Amount__LCY___Control1120072; BankAccount2."Credit Amount (LCY)" - BankAccount2."Debit Amount (LCY)")
            {
            }
            column(Bank_Account__Debit_Amount__LCY___Control1120075; "Debit Amount (LCY)")
            {
            }
            column(Bank_Account__Credit_Amount__LCY___Control1120078; "Credit Amount (LCY)")
            {
            }
            column(BankAccount2__Debit_Amount__LCY_Control1120081; BankAccount2."Debit Amount (LCY)" + "Debit Amount (LCY)" - BankAccount2."Credit Amount (LCY)" - "Credit Amount (LCY)")
            {
            }
            column(BankAccount2__Credit_Amount__LCY_Control1120084; BankAccount2."Credit Amount (LCY)" + "Credit Amount (LCY)" - BankAccount2."Debit Amount (LCY)" - "Debit Amount (LCY)")
            {
            }
            column(Bank_Account_Trial_BalanceCaption; Bank_Account_Trial_BalanceCaptionLbl)
            {
            }
            column(No_Caption; No_CaptionLbl)
            {
            }
            column(NameCaption; NameCaptionLbl)
            {
            }
            column(Balance_at_Starting_DateCaption; Balance_at_Starting_DateCaptionLbl)
            {
            }
            column(Balance_Date_RangeCaption; Balance_Date_RangeCaptionLbl)
            {
            }
            column(Balance_at_Ending_dateCaption; Balance_at_Ending_dateCaptionLbl)
            {
            }
            column(DebitCaption; DebitCaptionLbl)
            {
            }
            column(CreditCaption; CreditCaptionLbl)
            {
            }
            column(DebitCaption_Control1120030; DebitCaption_Control1120030Lbl)
            {
            }
            column(CreditCaption_Control1120032; CreditCaption_Control1120032Lbl)
            {
            }
            column(DebitCaption_Control1120034; DebitCaption_Control1120034Lbl)
            {
            }
            column(CreditCaption_Control1120036; CreditCaption_Control1120036Lbl)
            {
            }
            column(Grand_totalCaption; Grand_totalCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                BankAccount2 := "Bank Account";
                BankAccount2.SetRange("Date Filter", 0D, PreviousEndDate);
                BankAccount2.CalcFields("Debit Amount (LCY)", "Credit Amount (LCY)");
                if not PrintBanksWithoutBalance and
                   (BankAccount2."Debit Amount (LCY)" = 0) and
                   ("Debit Amount (LCY)" = 0) and
                   (BankAccount2."Credit Amount (LCY)" = 0) and
                   ("Credit Amount (LCY)" = 0)
                then
                    CurrReport.Skip();
            end;

            trigger OnPreDataItem()
            begin
                if GetFilter("Date Filter") = '' then
                    Error(Text001, FieldCaption("Date Filter"));
                if CopyStr(GetFilter("Date Filter"), 1, 1) = '.' then
                    Error(Text002);
                StartDate := GetRangeMin("Date Filter");
                PreviousEndDate := ClosingDate(StartDate - 1);
                FiltreDateCalc.CreateFiscalYearFilter(TextDate, TextDate, StartDate, 0);
                TextDate := ConvertStr(TextDate, '.', ',');
                FiltreDateCalc.VerifiyDateFilter(TextDate);
                TextDate := CopyStr(TextDate, 1, 8);
                Evaluate(PreviousStartDate, TextDate);
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
                    field(PrintBanksWithoutBalance; PrintBanksWithoutBalance)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Banks without Balance';
                        ToolTip = 'Specifies whether to include information about banks without a balance.';
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
        Filter := "Bank Account".GetFilters();
    end;

    var
        Text001: Label 'You must fill in the %1 field.';
        Text002: Label 'You must specify a Starting Date.';
        Text003: Label 'Printed by %1';
        Text004: Label 'Fiscal Year Start Date : %1';
        Text005: Label 'Page %1';
        BankAccount2: Record "Bank Account";
        FiltreDateCalc: Codeunit "DateFilter-Calc";
        StartDate: Date;
        PreviousStartDate: Date;
        PreviousEndDate: Date;
        TextDate: Text;
        PrintBanksWithoutBalance: Boolean;
        "Filter": Text;
        Bank_Account_Trial_BalanceCaptionLbl: Label 'Bank Account Trial Balance';
        No_CaptionLbl: Label 'No.';
        NameCaptionLbl: Label 'Name';
        Balance_at_Starting_DateCaptionLbl: Label 'Balance at Starting Date';
        Balance_Date_RangeCaptionLbl: Label 'Balance Date Range';
        Balance_at_Ending_dateCaptionLbl: Label 'Balance at Ending date';
        DebitCaptionLbl: Label 'Debit';
        CreditCaptionLbl: Label 'Credit';
        DebitCaption_Control1120030Lbl: Label 'Debit';
        CreditCaption_Control1120032Lbl: Label 'Credit';
        DebitCaption_Control1120034Lbl: Label 'Debit';
        CreditCaption_Control1120036Lbl: Label 'Credit';
        Grand_totalCaptionLbl: Label 'Grand total';
}

