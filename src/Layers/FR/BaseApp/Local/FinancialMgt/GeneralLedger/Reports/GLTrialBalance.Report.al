// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.Period;

report 10803 "G/L Trial Balance"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/FinancialMgt/GeneralLedger/Reports/GLTrialBalance.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'G/L Trial Balance';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Date Filter";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(PreviousStartDateText; StrSubstNo(Text004, PreviousStartDate))
            {
            }
            column(PageCaption; StrSubstNo(Text005, ''))
            {
            }
            column(UserCaption; StrSubstNo(Text003, ''))
            {
            }
            column(GLAccTableCaptionFilter; "G/L Account".TableCaption + ': ' + Filter)
            {
            }
            column("Filter"; Filter)
            {
            }
            column(ShowNegativeAmounts; ShowNegAmts)
            {
            }
            column(FiscalYearStatusText; FiscalYearStatusText)
            {
            }
            column(No_GLAcc; "No.")
            {
            }
            column(Name_GLAcc; Name)
            {
            }
            column(GLAcc2DebitAmtCreditAmt; GLAccount2."Debit Amount" - GLAccount2."Credit Amount")
            {
            }
            column(GLAcc2CreditAmtDebitAmt; GLAccount2."Credit Amount" - GLAccount2."Debit Amount")
            {
            }
            column(DebitAmt_GLAcc; "Debit Amount")
            {
            }
            column(CreditAmt_GLAcc; "Credit Amount")
            {
            }
            column(BalAtEndingDateDebitCaption; GLAccount2."Debit Amount" + "Debit Amount" - GLAccount2."Credit Amount" - "Credit Amount")
            {
            }
            column(BalAtEndingDateCreditCaption; GLAccount2."Credit Amount" + "Credit Amount" - GLAccount2."Debit Amount" - "Debit Amount")
            {
            }
            column(TLAccType; TLAccountType)
            {
            }
            column(GLTrialBalCaption; GLTrialBalCaptionLbl)
            {
            }
            column(NoCaption; NoCaptionLbl)
            {
            }
            column(NameCaption; NameCaptionLbl)
            {
            }
            column(BalAtStartingDateCaption; BalAtStartingDateCaptionLbl)
            {
            }
            column(BalDateRangeCaption; BalDateRangeCaptionLbl)
            {
            }
            column(BalAtEndingdateCaption; BalAtEndingdateCaptionLbl)
            {
            }
            column(DebitCaption; DebitCaptionLbl)
            {
            }
            column(CreditCaption; CreditCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                GLAccount2.Copy("G/L Account");
                GLAccount2.SetRange("Date Filter", 0D, PreviousEndDate);
                GLAccount2.CalcFields("Debit Amount", "Credit Amount");
                if not ImprNonMvt and
                   (GLAccount2."Debit Amount" = 0) and
                   ("Debit Amount" = 0) and
                   (GLAccount2."Credit Amount" = 0) and
                   ("Credit Amount" = 0)
                then
                    CurrReport.Skip();

                if "Debit Amount" < 0 then begin
                    "Credit Amount" += -"Debit Amount";
                    "Debit Amount" := 0;
                end;
                if "Credit Amount" < 0 then begin
                    "Debit Amount" += -"Credit Amount";
                    "Credit Amount" := 0;
                end;

                TLAccountType := "G/L Account"."Account Type".AsInteger();
            end;

            trigger OnPreDataItem()
            begin
                if GetFilter("Date Filter") = '' then
                    Error(Text001, FieldCaption("Date Filter"));
                if CopyStr(GetFilter("Date Filter"), 1, 1) = '.' then
                    Error(Text002);
                StartDate := GetRangeMin("Date Filter");
                PreviousEndDate := ClosingDate(StartDate - 1);
                DateFilterCalc.CreateFiscalYearFilter(TextDate, TextDate, StartDate, 0);
                TextDate := ConvertStr(TextDate, '.', ',');
                DateFilterCalc.VerifiyDateFilter(TextDate);
                TextDate := CopyStr(TextDate, 1, 8);
                Evaluate(PreviousStartDate, TextDate);
                FiscalYearStatusText := StrSubstNo(Text007, FiscalYearFiscalClose.CheckFiscalYearStatus(GetFilter("Date Filter")));
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
                    field(PrintGLAccsWithoutBalance; ImprNonMvt)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print G/L Accs. without balance';
                        ToolTip = 'Specifies whether to include information about general ledger accounts without a balance.';
                    }
                    field(ShowNegAmounts; ShowNegAmts)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show negative amounts';
                        ToolTip = 'Specifies whether to show negative amounts.';
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
        Filter := "G/L Account".GetFilters();
    end;

    var
        Text001: Label 'You must fill in the %1 field.';
        Text002: Label 'You must specify a Starting Date.';
        Text003: Label 'Printed by %1';
        Text004: Label 'Fiscal Year Start Date : %1';
        Text005: Label 'Page %1';
        GLAccount2: Record "G/L Account";
        DateFilterCalc: Codeunit "DateFilter-Calc";
        FiscalYearFiscalClose: Codeunit "Fiscal Year-FiscalClose";
        StartDate: Date;
        PreviousStartDate: Date;
        PreviousEndDate: Date;
        TextDate: Text[30];
        ImprNonMvt: Boolean;
        ShowNegAmts: Boolean;
        "Filter": Text;
        FiscalYearStatusText: Text;
        Text007: Label 'Fiscal-Year Status: %1';
        TLAccountType: Integer;
        GLTrialBalCaptionLbl: Label 'G/L Trial Balance';
        NoCaptionLbl: Label 'No.';
        NameCaptionLbl: Label 'Name';
        BalAtStartingDateCaptionLbl: Label 'Balance at Starting Date';
        BalDateRangeCaptionLbl: Label 'Balance Date Range';
        BalAtEndingdateCaptionLbl: Label 'Balance at Ending date';
        DebitCaptionLbl: Label 'Debit';
        CreditCaptionLbl: Label 'Credit';
}