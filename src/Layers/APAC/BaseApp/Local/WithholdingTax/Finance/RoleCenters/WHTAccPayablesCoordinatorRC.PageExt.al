// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Finance.RoleCenters;

pageextension 28006 WHTAccPayablesCoordinatorRC extends "Acc. Payables Coordinator RC"
{
    actions
    {
        addafter("Purchase Receipts")
        {
            action("Purch. - Tax Invoice")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Purch. - Tax Invoice';
                Image = "Report";
                RunObject = Report "Purch. - Tax Invoice";
                ToolTip = 'Create a new purchase tax credit invoice.';
            }
            action("Purch. - Tax Credit Memo")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Purch. - Tax Credit Memo';
                Image = "Report";
                RunObject = Report "Purch. - Tax Cr. Memo";
                ToolTip = 'Create a new purchase tax credit memo.';
            }
            separator(Action1500008)
            {
            }
            action("WHT Certificate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'WHT Certificate';
                Image = "Report";
                RunObject = Report "WHT Certificate";
                ToolTip = 'View the withholding tax certificate.';
            }
            action("WHT Certificate Preprint")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'WHT Certificate Preprint';
                Image = "Report";
                RunObject = Report "WHT certificate preprint";
                ToolTip = 'View the withholding tax certificate.';
            }
            action("WHT Certificate TH - Copy")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'WHT Certificate TH - Copy';
                Image = "Report";
                RunObject = Report "WHT Certificate TH - Copy";
                ToolTip = 'View the withholding tax certificate.';
            }
            action("WHT Certificate Preprint - Copy")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'WHT Certificate Preprint - Copy';
                Image = "Report";
                RunObject = Report "WHT certificate preprint Copy";
                ToolTip = 'View the withholding tax certificate.';
            }
            action("WHT Certificate - Other")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'WHT Certificate - Other';
                Image = "Report";
                RunObject = Report "WHT Certificate - Other";
                ToolTip = 'View the withholding tax certificate.';
            }
            action("WHT Certificate - Other Copy")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'WHT Certificate - Other Copy';
                Image = "Report";
                RunObject = Report "WHT Certificate - Other Copy";
                ToolTip = 'View the withholding tax certificate.';
            }
        }
        addafter("G/L Registers")
        {
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
