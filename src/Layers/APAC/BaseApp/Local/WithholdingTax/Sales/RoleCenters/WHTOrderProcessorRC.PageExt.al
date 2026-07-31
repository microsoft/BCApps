// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Sales.RoleCenters;

pageextension 28003 WHTOrderProcessorRC extends "Order Processor Role Center"
{
    actions
    {
        addafter(Action54)
        {
            action("Posted Sales Tax Invoices")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Posted Sales Tax Invoices';
                RunObject = Page "Posted Sales Tax Invoices";
                ToolTip = 'View the list of posted documents.';
            }
            action("Posted Sales Tax Credit Memos")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Posted Sales Tax Credit Memos';
                RunObject = Page "Posted Sales Tax Cr. Memos";
                ToolTip = 'View the list of posted documents.';
            }
            action("Posted Purch. Tax Invoices")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Posted Purch. Tax Invoices';
                RunObject = Page "Posted Purch. Tax Invoices";
                ToolTip = 'View the list of posted documents.';
            }
            action("Posted Purch. Tax Credit Memos")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Posted Purch. Tax Credit Memos';
                RunObject = Page "Posted Purch. Tax Cr. Memos";
                ToolTip = 'View the list of posted documents.';
            }
        }
    }
}
