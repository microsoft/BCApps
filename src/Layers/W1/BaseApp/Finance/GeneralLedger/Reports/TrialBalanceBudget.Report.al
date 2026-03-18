#if not CLEAN28
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.Period;
using System.Utilities;

/// <summary>
/// Generates trial balance with budget comparison analysis showing actual vs. budgeted amounts and variances.
/// Displays actual balances alongside budget figures with variance calculations for performance analysis.
/// </summary>
/// <remarks>
/// Data source: G/L Account table with budget filter integration for actual vs. budget comparison.
/// Shows period movements, budget amounts, and variance analysis for comprehensive budget monitoring.
/// Used for budget performance evaluation, variance analysis, and management reporting requirements.
/// </remarks>
report 9 "Trial Balance/Budget"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Trial Balance/Budget (Obsolete)';
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;
    ObsoleteState = Pending;
    ObsoleteReason = 'This report has been replaced by the report Trial Balance/Budget (Excel). This report will be removed in a future release.';
    ObsoleteTag = '28.0';
    DefaultRenderingLayout = RDLCLayout;

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Account Type", "Date Filter", "Budget Filter", "Global Dimension 1 Filter", "Global Dimension 2 Filter";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(STRSUBSTNO_Text000_PeriodText_; StrSubstNo(Text000, PeriodText))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(USERID; UserId)
            {
            }
            column(GLBudgetFilter; GLBudgetFilter)
            {
            }
            column(NoOfBlankLines; "No. of Blank Lines")
            {
            }
            column(G_L_Account__TABLECAPTION__________GLFilter; TableCaption + ': ' + GLFilter)
            {
            }
            column(GLFilter; GLFilter)
            {
            }
            column(GLAccType; "Account Type")
            {
            }
            column(AccountTypePosting; GLAccountTypePosting)
            {
            }
            column(G_L_Account_No_; "No.")
            {
            }
            column(Trial_Balance_BudgetCaption; Trial_Balance_BudgetCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(GLBudgetFilterCaption; GLBudgetFilterCaptionLbl)
            {
            }
            column(Net_ChangeCaption; Net_ChangeCaptionLbl)
            {
            }
            column(BalanceCaption; BalanceCaptionLbl)
            {
            }
            column(G_L_Account___No__Caption; FieldCaption("No."))
            {
            }
            column(PADSTR_____G_L_Account__Indentation___2___G_L_Account__NameCaption; PADSTR_____G_L_Account__Indentation___2___G_L_Account__NameCaptionLbl)
            {
            }
            column(G_L_Account___Net_Change_Caption; G_L_Account___Net_Change_CaptionLbl)
            {
            }
            column(G_L_Account___Net_Change__Control28Caption; G_L_Account___Net_Change__Control28CaptionLbl)
            {
            }
            column(DiffPctCaption; DiffPctCaptionLbl)
            {
            }
            column(G_L_Account___Budgeted_Amount_Caption; G_L_Account___Budgeted_Amount_CaptionLbl)
            {
            }
            column(G_L_Account___Balance_at_Date_Caption; G_L_Account___Balance_at_Date_CaptionLbl)
            {
            }
            column(G_L_Account___Balance_at_Date__Control32Caption; G_L_Account___Balance_at_Date__Control32CaptionLbl)
            {
            }
            column(DiffAtDatePctCaption; DiffAtDatePctCaptionLbl)
            {
            }
            column(GLAcc2__Budget_at_Date_Caption; GLAcc2__Budget_at_Date_CaptionLbl)
            {
            }
            column(RowNumber; RowNumber)
            {
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
                column(G_L_Account___Net_Change_; +"G/L Account"."Net Change")
                {
                    DecimalPlaces = 0 : 0;
                }
                column(G_L_Account___Net_Change__Control28; -"G/L Account"."Net Change")
                {
                    DecimalPlaces = 0 : 0;
                }
                column(DiffPct; DiffPct)
                {
                    DecimalPlaces = 1 : 1;
                }
                column(G_L_Account___Budgeted_Amount_; +"G/L Account"."Budgeted Amount")
                {
                    DecimalPlaces = 0 : 0;
                }
                column(G_L_Account___Balance_at_Date_; +"G/L Account"."Balance at Date")
                {
                    DecimalPlaces = 0 : 0;
                }
                column(G_L_Account___Balance_at_Date__Control32; -"G/L Account"."Balance at Date")
                {
                    DecimalPlaces = 0 : 0;
                }
                column(DiffAtDatePct; DiffAtDatePct)
                {
                    DecimalPlaces = 1 : 1;
                }
                column(GLAcc2__Budget_at_Date_; +GLAcc2."Budget at Date")
                {
                    DecimalPlaces = 0 : 0;
                }
                column(G_L_Account___No___Control35; "G/L Account"."No.")
                {
                }
                column(PADSTR_____G_L_Account__Indentation___2___G_L_Account__Name_Control36; PadStr('', "G/L Account".Indentation * 2) + "G/L Account".Name)
                {
                }
                column(G_L_Account___Net_Change__Control37; +"G/L Account"."Net Change")
                {
                    DecimalPlaces = 0 : 0;
                }
                column(G_L_Account___Net_Change__Control38; -"G/L Account"."Net Change")
                {
                    DecimalPlaces = 0 : 0;
                }
                column(DiffPct_Control39; DiffPct)
                {
                    DecimalPlaces = 1 : 1;
                }
                column(G_L_Account___Budgeted_Amount__Control40; +"G/L Account"."Budgeted Amount")
                {
                    DecimalPlaces = 0 : 0;
                }
                column(G_L_Account___Balance_at_Date__Control41; +"G/L Account"."Balance at Date")
                {
                    DecimalPlaces = 0 : 0;
                }
                column(G_L_Account___Balance_at_Date__Control42; -"G/L Account"."Balance at Date")
                {
                    DecimalPlaces = 0 : 0;
                }
                column(DiffAtDatePct_Control43; DiffAtDatePct)
                {
                    DecimalPlaces = 1 : 1;
                }
                column(GLAcc2__Budget_at_Date__Control44; +GLAcc2."Budget at Date")
                {
                    DecimalPlaces = 0 : 0;
                }
            }

            trigger OnAfterGetRecord()
            begin
                CalcFields("Net Change", "Budgeted Amount", "Balance at Date");
                GLAcc2 := "G/L Account";
                GLAcc2.CalcFields("Budget at Date");
                if "Budgeted Amount" = 0 then
                    DiffPct := 0
                else
                    DiffPct := "Net Change" / "Budgeted Amount" * 100;
                if GLAcc2."Budget at Date" = 0 then
                    DiffAtDatePct := 0
                else
                    DiffAtDatePct := "Balance at Date" / GLAcc2."Budget at Date" * 100;

                GLAccountTypePosting := "Account Type" = "Account Type"::Posting;
                RowNumber += 1;
            end;

            trigger OnPreDataItem()
            begin
                GLAcc2.CopyFilters("G/L Account");
                AccountingPeriod.Reset();
                AccountingPeriod.SetRange("New Fiscal Year", true);
                EndDate := GetRangeMax("Date Filter");
                AccountingPeriod."Starting Date" := GetRangeMin("Date Filter");
                AccountingPeriod.Find('=<');
                GLAcc2.SetRange("Date Filter", AccountingPeriod."Starting Date", EndDate);
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Trial Balance/Budget (Obsolete)';
        AboutText = 'View a snapshot of your chart of accounts to check the debit and credit net change and closing balance compared to the budget. Shows the percentage of actual vs. budget.** This report is obsolete and will be removed in a future release.** Please refer to the report documentation for alternative ways to retrieve this information.';

        layout
        {
        }

        actions
        {
        }
    }

    rendering
    {
        layout(RDLCLayout)
        {
            Type = RDLC;
            LayoutFile = './Finance/GeneralLedger/Reports/TrialBalanceBudget.rdlc';
            Summary = 'Report layout made in the legacy RDLC format. Use an RDLC editor to modify the layout.';
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        GLFilter := "G/L Account".GetFilters();
        PeriodText := "G/L Account".GetFilter("Date Filter");
        GLBudgetFilter := "G/L Account".GetFilter("Budget Filter");
    end;

    var
        GLAcc2: Record "G/L Account";
        AccountingPeriod: Record "Accounting Period";
        GLBudgetFilter: Text[30];
        PeriodText: Text[30];
        EndDate: Date;
        DiffPct: Decimal;
        DiffAtDatePct: Decimal;
        GLAccountTypePosting: Boolean;
        RowNumber: Integer;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Period: %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
        Trial_Balance_BudgetCaptionLbl: Label 'Trial Balance/Budget';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        GLBudgetFilterCaptionLbl: Label 'Budget Filter';
        Net_ChangeCaptionLbl: Label 'Net Change';
        BalanceCaptionLbl: Label 'Balance';
        PADSTR_____G_L_Account__Indentation___2___G_L_Account__NameCaptionLbl: Label 'Name';
        G_L_Account___Net_Change_CaptionLbl: Label 'Debit';
        G_L_Account___Net_Change__Control28CaptionLbl: Label 'Credit';
        DiffPctCaptionLbl: Label '% of';
        G_L_Account___Budgeted_Amount_CaptionLbl: Label 'Budget';
        G_L_Account___Balance_at_Date_CaptionLbl: Label 'Debit';
        G_L_Account___Balance_at_Date__Control32CaptionLbl: Label 'Credit';
        DiffAtDatePctCaptionLbl: Label '% of';
        GLAcc2__Budget_at_Date_CaptionLbl: Label 'Budget';

    protected var
        GLFilter: Text;
}

#endif