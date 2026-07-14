// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

pageextension 5005276 DRPurchaseOrder extends "Purchase Order"
{
    actions
    {
        addafter(Action186)
        {
            action("Deliv. Reminder Ledger &Entries")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Deliv. Reminder Ledger &Entries';
                Image = ReceiptReminder;
                RunObject = Page "Deliv. Reminder Ledger Entries";
                RunPageLink = "Order No." = field("No.");
                RunPageView = sorting("Order No.", "Order Line No.", "Posting Date")
                              order(ascending);
                ToolTip = 'View the entries that were created when delivery reminders were created. You can navigate to investigate each entry further.';
            }
        }
    }
}
