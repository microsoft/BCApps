#if CLEAN28
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.RoleCenters;

using Microsoft.Bank.Reports;
using Microsoft.Finance.GeneralLedger.Reports;
using Microsoft.Purchases.Reports;
using Microsoft.Sales.Reports;

pageextension 10829 "Finance Manager Role Center" extends "Finance Manager Role Center"
{
    actions
    {
        addafter(Group11)
        {
            group("Group63_FR")
            {
                Caption = 'France';
                action("Journals1_FR")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Journals';
                    RunObject = report "Journals FR";
                    ToolTip = 'View all G/L transactions with subtotals per period. Each period shows subtotals per source code. There are several options for filtering the report. Choose the Journals option to display individual transaction amounts. Choose Centralized Journals to display amounts centralized per account. Choose Journals and Centralization to do both. You can also sort by posting date or document number.';
                }
                action("G/L Journal FR")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'G/L Journal';
                    RunObject = report "G/L Journal FR";
                    ToolTip = 'Run the G/L Journal report.';
                }
                action("G/L Trial Balance FR")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'G/L Trial Balance';
                    RunObject = report "G/L Trial Balance FR";
                    ToolTip = 'View, print, or send a report that shows the balances for the general ledger accounts, including the debits and credits. You can use this report to ensure accurate accounting practices.';
                }
                action("G/L Detail Trial Balance FR")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'G/L Detail Trial Balance';
                    RunObject = report "G/L Detail Trial Balance FR";
                    ToolTip = 'View transactions for all G/L accounts with subtotals per account. Each account shows the opening balance on the first line, the list of transactions for the account, and a closing balance on the last line.';
                }
                action("Customer Detail Trial Balance FR")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer Detail Trial Balance';
                    RunObject = report "Cust. Detail Trial Balance";
                    ToolTip = 'View transactions for all customer accounts with subtotals per account. Each account shows the opening balance on the first line, and the list of transactions for the account and a closing balance on the last line. You can sort the results by document, and exclude customers that have a balance but do not have a net change during the selected time period.';
                }
                action("Bank Account Trial Balance FR")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Account Trial Balance';
                    RunObject = report "Bank Acc. Trial Balance";
                    ToolTip = 'View balances for all bank accounts on six columns: Opening balance debit, Opening balance credit, Period balance debit, Period balance credit, Final balance debit, and Final balance credit.';
                }
                action("Bank Acc. Detail Trial Balance FR")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Acc. Detail Trial Balance';
                    RunObject = report "Bank Acc. Det. Trial Balance";
                    ToolTip = 'View, print, or send a report that shows a detailed trial balance for selected bank accounts. You can use the report at the close of an accounting period or fiscal year.';
                }
                action("Customer Journal FR")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer Journal';
                    RunObject = report "Customer Journal FR";
                    ToolTip = 'View transactions for all customer accounts with subtotals per period. Each period shows subtotals per source code.';
                }
                action("Vendor Journal FR")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor Journal';
                    RunObject = report "Vendor Journal FR";
                    ToolTip = 'View transactions for all vendor accounts with subtotals per period. Each period shows subtotals per source code.';
                }
                action("Bank Account Journal FR")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Account Journal';
                    RunObject = report "Bank Account Journal FR";
                    ToolTip = 'View transactions for all bank accounts with subtotals per period. Each period shows subtotals per source code.';
                }
            }
        }
        addafter("Customer - Balance to Date")
        {
            action("Customer Trial Balance FR")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Customer Trial Balance';
                RunObject = report "Customer Trial Balance";
                ToolTip = 'View the beginning and ending balance for customers with entries within a specified period. The report can be used to verify that the balance for a customer posting group is equal to the balance on the corresponding general ledger account on a certain date.';
            }
        }
        addafter("Vendor - Balance to Date")
        {
            action("Vendor Trial Balance FR")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Vendor Trial Balance';
                RunObject = report "Vendor Trial Balance";
                ToolTip = 'View balances for all vendor accounts in six columns: Opening balance debit, Opening balance credit, Period balance debit, Period balance credit, Final balance debit, and Final balance credit.';
            }
            action("Vendor - Detail Trial Balance FR")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Vendor Detail Trial Balance';
                RunObject = report "Vendor Detail Trial Balance";
                ToolTip = 'Run the Vendor - Detail Trial Balance report.';
            }
        }
    }
}
#endif