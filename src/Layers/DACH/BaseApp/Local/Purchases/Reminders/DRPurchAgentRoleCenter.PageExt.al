// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.RoleCenters;

using Microsoft.Purchases.Document;

pageextension 5005275 DRPurchAgentRoleCenter extends "Purchasing Agent Role Center"
{
    actions
    {
        addafter("Purchase Credit Memos")
        {
            action("Delivery Reminders")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Delivery Reminders';
                RunObject = Page "Delivery Reminder List";
                ToolTip = 'View the list of ongoing reminders to vendors about late delivery.';
            }
        }
        addafter("Posted Purchase Credit Memos")
        {
            action("Issued Delivery Reminders")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Issued Delivery Reminders';
                RunObject = Page "Issued Delivery Reminders List";
                ToolTip = 'View or print the delivery reminder.';
            }
        }
        addafter("Purchase &Return Order")
        {
            action("Delivery Reminder")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Delivery Reminder';
                Image = ReceiptReminder;
                RunObject = Page "Delivery Reminder";
                ToolTip = 'Create a reminder to a vendor about late delivery.';
            }
        }
        addafter(Administration)
        {
            action("Delivery Reminder Terms")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Delivery Reminder Terms';
                RunObject = Page "Delivery Reminder Terms";
                ToolTip = 'Set up reminder terms that you select from on vendor cards to define when and how to remind the vendor of late delivery.';
            }
        }
    }
}
