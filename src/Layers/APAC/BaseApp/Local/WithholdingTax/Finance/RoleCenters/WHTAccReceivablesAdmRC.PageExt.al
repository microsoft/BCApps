// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Finance.RoleCenters;

pageextension 28007 WHTAccReceivablesAdmRC extends "Acc. Receivables Adm. RC"
{
    actions
    {
        addafter("Cus&tomer/Item Sales")
        {
            separator(Action20)
            {
            }
            action("Sales - Tax Invoice")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Sales - Tax Invoice';
                Image = "Report";
                RunObject = Report "Sales - Tax Invoice";
                ToolTip = 'Create a new sales tax invoice.';
            }
            action("Sales - Tax Credit Memo")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Sales - Tax Credit Memo';
                Image = "Report";
                RunObject = Report "Sales - Tax Cr. Memo";
                ToolTip = 'Create a new sales tax credit memo.';
            }
        }
        addafter("G/L Registers")
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
        }
    }
}
