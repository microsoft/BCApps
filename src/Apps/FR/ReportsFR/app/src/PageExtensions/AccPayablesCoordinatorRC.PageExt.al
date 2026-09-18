#if CLEAN28
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.RoleCenters;

using Microsoft.Purchases.Reports;

pageextension 10843 "Acc. Payables Coordinator RC" extends "Acc. Payables Coordinator RC"
{
    actions
    {
        addafter("Vendor - &Balance to date")
        {
            action("Vendor Trial Balance FR")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Vendor Trial Balance';
                Image = "Report";
                RunObject = Report "Vendor Trial Balance";
                ToolTip = 'View balances for all vendor accounts in six columns: Opening balance debit, Opening balance credit, Period balance debit, Period balance credit, Final balance debit, and Final balance credit.';
            }
            action("Vendor Detail Trial Balance FR")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Vendor Detail Trial Balance';
                Image = "Report";
                RunObject = Report "Vendor Detail Trial Balance";
                ToolTip = 'View transactions for all vendor accounts with subtotals per account. Each account shows the opening balance on the first line, and the list of transactions for the account and a closing balance on the last line.';
            }
        }
        addafter("P&urchase Statistics")
        {
            action("Vendor Journal FR")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Vendor Journal';
                Image = "Report";
                RunObject = Report "Vendor Journal FR";
                ToolTip = 'View transactions for all vendor accounts with subtotals per period. Each period shows subtotals per source code.';
            }
        }
    }
}
#endif