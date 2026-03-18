// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Reports;

using Microsoft.CostAccounting.Account;

report 1133 "Cost Acctg. Statement/Budget"
{
    DefaultLayout = RDLC;
    RDLCLayout = './CostAccounting/Reports/CostAcctgStatementBudget.rdlc';
    ApplicationArea = CostAccounting;
    Caption = 'Cost Acctg. Statement/Budget';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Cost Type"; "Cost Type")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Budget Filter", "Date Filter", "Cost Center Filter", "Cost Object Filter", Type, "Cost Classification";
            column(DateFilterTxt; DateFilterTxt)
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(CcFilterTxt; CCFilterTxt)
            {
            }
            column(BudFilterTxt; BudFilterTxt)
            {
            }
            column(CoFilterTxt; COFilterTxt)
            {
            }
            column(NetChange; -"Net Change")
            {
            }
            column(NetChange_CostType; "Net Change")
            {
            }
            column(NameIndented; PadStr('', Indentation * 2) + Name)
            {
            }
            column(No_CostType; "No.")
            {
            }
            column(BudPct; BudPct)
            {
            }
            column(BudgetAmount_CostType; "Budget Amount")
            {
            }
            column(BlankLine_CostType; "Blank Line")
            {
            }
            column(PageGroupNo; PageGroupNo)
            {
            }
            column(CostTypeLineType1; CostTypeLineType)
            {
            }
            column(CostAcctgStmtBudgetCaption; CostAcctgStmtBudgetCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(BudgetAmountCaption; BudgetAmountCaptionLbl)
            {
            }
            column(PercentageOfCaption; PercentageOfCaptionLbl)
            {
            }
            column(CreditCaption; CreditCaptionLbl)
            {
            }
            column(CostTypeCreditCaption; CostTypeCreditCaptionLbl)
            {
            }
            column(NameCaption; NameCaptionLbl)
            {
            }
            column(CostTypeCaption; CostTypeCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                CalcFields("Net Change", "Budget Amount");

                if SuppressZeroLines and ("Net Change" = 0) and ("Budget Amount" = 0) then
                    CurrReport.Skip();

                if "Budget Amount" = 0 then
                    BudPct := 0
                else
                    BudPct := "Net Change" / "Budget Amount" * 100;

                PageGroupNo := NextPageGroupNo;
                if "New Page" then
                    NextPageGroupNo := PageGroupNo + 1;
                CostTypeLineType := Type.AsInteger();
            end;

            trigger OnPreDataItem()
            begin
                PageGroupNo := 1;
                NextPageGroupNo := 1;
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Cost Acctg. Statement/Budget';
        AboutText = 'The **Cost Accounting Statement/Budget** report compares actual costs against budgeted amounts by cost center, highlighting variances in both value and percentage. Use it for evaluating budget performance during planning cycles, helping identify gaps between projected and actual costs to improve budgeting accuracy.';

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(SuppressZeroLines; SuppressZeroLines)
                    {
                        ApplicationArea = CostAccounting;
                        Caption = 'Suppress lines without amount';
                        ToolTip = 'Specifies that you want to print the report in a compact format, by suppressing the lines without amounts listed.';
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
        DateFilterTxt := Text000 + "Cost Type".GetFilter("Date Filter");
        BudFilterTxt := Text001 + "Cost Type".GetFilter("Budget Filter");

        if "Cost Type".GetFilter("Cost Center Filter") <> '' then
            CCFilterTxt := Text002 + "Cost Type".GetFilter("Cost Center Filter");

        if "Cost Type".GetFilter("Cost Object Filter") <> '' then
            COFilterTxt := Text003 + "Cost Type".GetFilter("Cost Object Filter");
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'Date Filter: ';
        Text001: Label 'Budget Name: ';
        Text002: Label 'Cost Center Filter: ';
        Text003: Label 'Cost Object Filter: ';
#pragma warning restore AA0074
        SuppressZeroLines: Boolean;
        BudFilterTxt: Text;
        DateFilterTxt: Text;
        BudPct: Decimal;
        CCFilterTxt: Text;
        COFilterTxt: Text;
        PageGroupNo: Integer;
        NextPageGroupNo: Integer;
        CostTypeLineType: Integer;
        CostAcctgStmtBudgetCaptionLbl: Label 'Cost Acctg. Statement/Budget';
        PageCaptionLbl: Label 'Page';
        BudgetAmountCaptionLbl: Label 'Budget Amount';
        PercentageOfCaptionLbl: Label '% of';
        CreditCaptionLbl: Label 'Credit';
        CostTypeCreditCaptionLbl: Label 'Debit';
        NameCaptionLbl: Label 'Name';
        CostTypeCaptionLbl: Label 'Cost Type';
}

