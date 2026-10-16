#if CLEAN28
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.RoleCenters;
using Microsoft.Sales.Reports;

pageextension 10844 "Acc. Receivables Adm. RC" extends "Acc. Receivables Adm. RC"
{
    actions
    {
        addafter("Customer - &Summary Aging Simp.")
        {
            action("Customer Trial Balan&ce FR")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Customer Trial Balan&ce';
                RunObject = Report "Customer Trial Balance";
                ToolTip = 'View the beginning and ending balance for customers with entries within a specified period. The report can be used to verify that the balance for a customer posting group is equal to the balance on the corresponding general ledger account on a certain date.';
            }
            action("Customer Detail Trial Balance FR")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Customer Detail Trial Balance';
                Image = "Report";
                RunObject = Report "Cust. Detail Trial Balance";
                ToolTip = 'View transactions for all customer accounts with subtotals per account. Each account shows the opening balance on the first line, and the list of transactions for the account and a closing balance on the last line. You can sort the results by document, and exclude customers that have a balance but do not have a net change during the selected time period.';
            }
        }
        addafter("Cus&tomer/Item Sales")
        {
            action("Customer Journal FR")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Customer Journal';
                Image = "Report";
                RunObject = Report "Customer Journal FR";
                ToolTip = 'View transactions for all customer accounts with subtotals per period. Each period shows subtotals per source code.';
            }
        }
    }
}
#endif