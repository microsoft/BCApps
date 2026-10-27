// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;

page 3337 "Payables Agent Role Center"
{
    Extensible = false;
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
            action(Items)
            {
                ApplicationArea = All;
                Caption = 'Items';
                ToolTip = 'Search items when matching the products described on an invoice.';
                RunObject = page "Item List";
            }
            action(ItemReferences)
            {
                ApplicationArea = All;
                Caption = 'Item References';
                ToolTip = 'Search vendor and other external item references when an invoice uses a different item number.';
                RunObject = page "Item References";
            }
            action(ChartOfAccounts)
            {
                ApplicationArea = All;
                Caption = 'Chart of Accounts';
                ToolTip = 'Search G/L accounts when an invoice line does not clearly match an item.';
                RunObject = page "Chart of Accounts";
            }
            action(PostedPurchaseInvoices)
            {
                ApplicationArea = All;
                Caption = 'Posted Purchase Invoices';
                ToolTip = 'Review posted purchase invoices and their lines for relevant purchasing history.';
                RunObject = page "Posted Purchase Invoices";
            }
            action(PostedPurchaseCreditMemos)
            {
                ApplicationArea = All;
                Caption = 'Posted Purchase Credit Memos';
                ToolTip = 'Review purchase credit memos that have already been posted.';
                RunObject = page "Posted Purchase Credit Memos";
            }
            action(PostedPurchaseReceipts)
            {
                ApplicationArea = All;
                Caption = 'Posted Purchase Receipts';
                ToolTip = 'Review posted receipts when checking whether invoice lines relate to received purchase orders.';
                RunObject = page "Posted Purchase Receipts";
            }
        }
    }
}
