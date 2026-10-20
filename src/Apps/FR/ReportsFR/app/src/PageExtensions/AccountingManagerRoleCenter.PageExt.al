#if CLEAN30
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.RoleCenters;

using Microsoft.Bank.Reports;
using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.GeneralLedger.Reports;
using Microsoft.Purchases.Reports;
using Microsoft.Sales.Reports;

pageextension 10825 "Accounting Manager Role Center" extends "Accounting Manager Role Center"
{
    actions
    {
        addfirst(reporting)
        {
            action("&G/L Trial Balance FR")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&G/L Trial Balance';
                Image = "Report";
                RunObject = Report "G/L Trial Balance FR";
                ToolTip = 'View, print, or send a report that shows the balances for the general ledger accounts, including the debits and credits. You can use this report to ensure accurate accounting practices.';
            }
            action("G/L Detail Trial Balance FR")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'G/L Detail Trial Balance';
                Image = "Report";
                RunObject = Report "G/L Detail Trial Balance FR";
                ToolTip = 'View transactions for all G/L accounts with subtotals per account. Each account shows the opening balance on the first line, the list of transactions for the account, and a closing balance on the last line.';
            }
            action("Bank Trial Balance FR")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bank Trial Balance';
                Image = "Report";
                RunObject = Report "Bank Acc. Trial Balance";
                ToolTip = 'View balances for all bank accounts on six columns: Opening balance debit, Opening balance credit, Period balance debit, Period balance credit, Final balance debit, and Final balance credit.';
            }
            action("&Bank Detail Trial Balance FR")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Bank Detail Trial Balance';
                Image = "Report";
                RunObject = Report "Bank Acc. Det. Trial Balance";
                ToolTip = 'View, print, or send a report that shows a detailed trial balance for selected bank accounts. You can use the report at the close of an accounting period or fiscal year.';
            }
        }
        addafter("Cost Accounting Analysis")
        {
            separator(Action1120008_FR)
            {
            }
            action("Journals FR")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Journals';
                Image = "Report";
                RunObject = Report "Journals FR";
                ToolTip = 'View all G/L transactions with subtotals per period. Each period shows subtotals per source code. There are several options for filtering the report. Choose the Journals option to display individual transaction amounts. Choose Centralized Journals to display amounts centralized per account. Choose Journals and Centralization to do both. You can also sort by posting date or document number.';
            }
            action("Customer Journal FR")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Customer Journal';
                Image = "Report";
                RunObject = Report "Customer Journal FR";
                ToolTip = 'View transactions for all customer accounts with subtotals per period. Each period shows subtotals per source code.';
            }
            action("Vendor Journal FR")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Vendor Journal';
                Image = "Report";
                RunObject = Report "Vendor Journal FR";
                ToolTip = 'View transactions for all vendor accounts with subtotals per period. Each period shows subtotals per source code.';
            }
            action("Bank Account Journal FR")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bank Account Journal';
                Image = "Report";
                RunObject = Report "Bank Account Journal FR";
                ToolTip = 'View transactions for all bank accounts with subtotals per period. Each period shows subtotals per source code.';
            }
        }
        addlast(reporting)
        {
            action(FRFinancialScheduleNames)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Balance Sheet & Income Statement';
                Image = Account;
                RunObject = page "FR Financial Schedule Names";
                ToolTip = 'Maintain French balance-sheet and income-statement definitions.';
            }
            action(FRFinancialScheduleReport)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'FR Account Schedule';
                Image = Report;
                RunObject = report "FR Financial Schedule";
                ToolTip = 'Print French financial schedules with current and previous-period figures.';
            }
            action(FRGLAccountStatement)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'G/L Account Statement';
                Image = Report;
                RunObject = report "G/L Account Statement FR";
                ToolTip = 'View general ledger transactions, application letters, review status, and account balances.';
            }
        }
    }
}
#endif