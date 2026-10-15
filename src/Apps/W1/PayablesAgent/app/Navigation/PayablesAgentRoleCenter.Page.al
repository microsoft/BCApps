// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;

page 3337 "Payables Agent Role Center"
{
    PageType = RoleCenter;
    Caption = 'Payables Agent', Locked = true;
    InherentEntitlements = X;
    InherentPermissions = X;

    actions
    {
        area(Embedding)
        {
            action(PayablesAgentTasks)
            {
                ApplicationArea = All;
                Caption = 'Payables Agent Tasks';
                ToolTip = 'View the tasks of the payables agent, what they came from and what they produced.';
                RunObject = page "Payables Agent Tasks";
            }
            action(PurchaseInvoices)
            {
                ApplicationArea = All;
                Caption = 'Purchase Invoices';
                ToolTip = 'View or create purchase invoices.';
                RunObject = page "Purchase Invoices";
            }
            action(PurchaseOrders)
            {
                ApplicationArea = All;
                Caption = 'Purchase Orders';
                ToolTip = 'View or create purchase orders.';
                RunObject = page "Purchase Order List";
            }
            action(PurchaseCreditMemos)
            {
                ApplicationArea = All;
                Caption = 'Purchase Credit Memos';
                ToolTip = 'View or create purchase credit memos.';
                RunObject = page "Purchase Credit Memos";
            }
            action(Vendors)
            {
                ApplicationArea = All;
                Caption = 'Vendors';
                ToolTip = 'View or edit the vendors that you trade with.';
                RunObject = page "Vendor List";
            }
            action(PostedPurchaseInvoices)
            {
                ApplicationArea = All;
                Caption = 'Posted Purchase Invoices';
                ToolTip = 'View the purchase invoices that have been posted.';
                RunObject = page "Posted Purchase Invoices";
            }
        }
    }
}
