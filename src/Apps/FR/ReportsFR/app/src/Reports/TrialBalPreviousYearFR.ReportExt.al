// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.GeneralLedger.Account;

reportextension 10826 "Trial Bal. Previous Year FR" extends "Trial Balance/Previous Year"
{
    dataset
    {
        add("G/L Account")
        {
#if not CLEAN30
            column(GLAccTableCaptionGLFilter; "G/L Account".TableCaption + ': ' + GLFilter)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'This compatibility column is provided by the standard Trial Balance/Previous Year report after delocalization.';
                ObsoleteTag = '30.0';
            }
            column(LongText; StrSubstNo(PeriodTxt, FiscalYearStartDate, FiscalYearEndDate, LastYearStartDate, LastYearEndDate))
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'This compatibility column is provided by the standard Trial Balance/Previous Year report after delocalization.';
                ObsoleteTag = '30.0';
            }
            column(PageNoCaption; PageTxt)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'This compatibility column is provided by the standard Trial Balance/Previous Year report after delocalization.';
                ObsoleteTag = '30.0';
            }
            column(NameCaption; NameTxt)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'This compatibility column is provided by the standard Trial Balance/Previous Year report after delocalization.';
                ObsoleteTag = '30.0';
            }
            column(DebitCaption; DebitTxt)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'This compatibility column is provided by the standard Trial Balance/Previous Year report after delocalization.';
                ObsoleteTag = '30.0';
            }
            column(CreditCaption; CreditTxt)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'This compatibility column is provided by the standard Trial Balance/Previous Year report after delocalization.';
                ObsoleteTag = '30.0';
            }
            column(PercentCaption; PercentTxt)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'This compatibility column is provided by the standard Trial Balance/Previous Year report after delocalization.';
                ObsoleteTag = '30.0';
            }
            column(LastYearCaption; LastYearTxt)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'This compatibility column is provided by the standard Trial Balance/Previous Year report after delocalization.';
                ObsoleteTag = '30.0';
            }
#endif
            column(FRHeaderAccountNo; "G/L Account"."No.")
            {
            }
            column(FRAccountFilter; "G/L Account".TableCaption + ': ' + GLFilter)
            {
            }
            column(FRFilter; GLFilter)
            {
            }
            column(FRPeriodText; StrSubstNo(PeriodTxt, FiscalYearStartDate, FiscalYearEndDate, LastYearStartDate, LastYearEndDate))
            {
            }
            column(FRPageCaption; PageTxt)
            {
            }
            column(FRNameCaption; NameTxt)
            {
            }
            column(FRDebitCaption; DebitTxt)
            {
            }
            column(FRCreditCaption; CreditTxt)
            {
            }
            column(FRPercentCaption; PercentTxt)
            {
            }
            column(FRLastYearCaption; LastYearTxt)
            {
            }
        }
        add(Integer)
        {
#if not CLEAN30
            column(No_GLAccountCaption; "G/L Account".FieldCaption("No."))
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'This compatibility column is provided by the standard Trial Balance/Previous Year report after delocalization.';
                ObsoleteTag = '30.0';
            }
            column(GLAccIndentationGLAccName; PadStr('', "G/L Account".Indentation * 2) + "G/L Account".Name)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'This compatibility column is provided by the standard Trial Balance/Previous Year report after delocalization.';
                ObsoleteTag = '30.0';
            }
            column(NegFiscalYearNetChange; -FiscalYearNetChange)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'This compatibility column is provided by the standard Trial Balance/Previous Year report after delocalization.';
                ObsoleteTag = '30.0';
                AutoFormatType = 1;
                DecimalPlaces = 0 : 0;
            }
            column(FiscalYearBalance; FiscalYearBalance)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'This compatibility column is provided by the standard Trial Balance/Previous Year report after delocalization.';
                ObsoleteTag = '30.0';
                AutoFormatType = 1;
                DecimalPlaces = 0 : 0;
            }
            column(NegFiscalYearBalance; -FiscalYearBalance)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'This compatibility column is provided by the standard Trial Balance/Previous Year report after delocalization.';
                ObsoleteTag = '30.0';
                AutoFormatType = 1;
                DecimalPlaces = 0 : 0;
            }
#endif
            column(FRAccountNo; "G/L Account"."No.")
            {
                IncludeCaption = true;
            }
            column(FRAccountName; PadStr('', "G/L Account".Indentation * 2) + "G/L Account".Name)
            {
            }
            column(FRPeriodDebitAmount; PeriodDebitAmount)
            {
                AutoFormatType = 1;
                DecimalPlaces = 0 : 0;
            }
            column(FRPeriodCreditAmount; PeriodCreditAmount)
            {
                AutoFormatType = 1;
                DecimalPlaces = 0 : 0;
            }
            column(FRCumulativeDebitAmount; CumulativeDebitAmount)
            {
                AutoFormatType = 1;
                DecimalPlaces = 0 : 0;
            }
            column(FRCumulativeCreditAmount; CumulativeCreditAmount)
            {
                AutoFormatType = 1;
                DecimalPlaces = 0 : 0;
            }
            column(FRBlankLines; "G/L Account"."No. of Blank Lines")
            {
            }
        }
        modify("G/L Account")
        {
            trigger OnAfterAfterGetRecord()
            var
                GLAccount: Record "G/L Account";
            begin
                GLAccount.Copy("G/L Account");
                GLAccount.SecurityFiltering(SecurityFilter::Filtered);
                GLAccount.SetRange("Date Filter", FiscalYearStartDate, FiscalYearEndDate);
                GLAccount.CalcFields("Debit Amount", "Credit Amount");
                PeriodDebitAmount := GLAccount."Debit Amount";
                PeriodCreditAmount := GLAccount."Credit Amount";
                GLAccount.SetFilter("Date Filter", '..%1', FiscalYearEndDate);
                GLAccount.CalcFields("Debit Amount", "Credit Amount");
                CumulativeDebitAmount := GLAccount."Debit Amount";
                CumulativeCreditAmount := GLAccount."Credit Amount";
            end;
        }
    }

    rendering
    {
        layout(FRFinancialReporting)
        {
            Type = RDLC;
            LayoutFile = './src/Reports/TrialBalancePreviousYearFR.rdlc';
            Caption = 'French trial balance with previous year';
            Summary = 'Separate period and cumulative debit and credit movements, with signed previous-year comparisons.';
        }
    }

    var
        PeriodDebitAmount: Decimal;
        PeriodCreditAmount: Decimal;
        CumulativeDebitAmount: Decimal;
        CumulativeCreditAmount: Decimal;
        PeriodTxt: Label 'Period: %1..%2 versus %3..%4', Comment = '%1, %2 = current period dates, %3, %4 = previous period dates';
        PageTxt: Label 'Page';
        NameTxt: Label 'Name';
        DebitTxt: Label 'Debit';
        CreditTxt: Label 'Credit';
        PercentTxt: Label '% of';
        LastYearTxt: Label 'Last Year';
}
