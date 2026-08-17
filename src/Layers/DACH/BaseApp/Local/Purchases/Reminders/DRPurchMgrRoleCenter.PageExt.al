// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.RoleCenters;

using Microsoft.Purchases.Document;

pageextension 5005274 DRPurchMgrRoleCenter extends "Purchasing Manager Role Center"
{
    actions
    {
        addafter("Orders")
        {
            action("Delivery Reminder")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Delivery Reminder';
                RunObject = page "Delivery Reminder";
                ToolTip = 'Create a reminder to a vendor about late delivery.';
            }
        }
        addafter("Posted Purchase Receipts")
        {
            action("Issued Delivery Reminder")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Issued Delivery Reminder';
                RunObject = page "Issued Delivery Reminder";
                ToolTip = 'View the issued delivery reminder.';
            }
        }
        addafter("Shipment Methods")
        {
            action("Delivery Reminder Terms")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Delivery Reminder Terms';
                RunObject = page "Delivery Reminder Terms";
                ToolTip = 'Set up reminder terms that you select from on vendor cards to define when and how to remind the vendor of late delivery.';
            }
        }
    }
}
