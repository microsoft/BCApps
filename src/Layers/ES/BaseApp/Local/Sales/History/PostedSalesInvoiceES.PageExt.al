// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

#pragma warning disable AS0088
pageextension 10751 "Posted Sales Invoice ES" extends "Posted Sales Invoice"
{
    layout
    {
        addafter("Payment Terms Code")
        {
            field("Cust. Bank Acc. Code"; Rec."Cust. Bank Acc. Code")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ToolTip = 'Specifies the client''s bank code that was on the sales header when the invoice was created.';
            }
        }
#if not CLEAN30
        addafter("Invoice Details")
        {
            group(Payment)
            {
                Caption = 'Payment';
                Visible = false;
                ObsoleteState = Pending;
                ObsoleteReason = 'Standard fields are in Invoice Details. The customer bank account field is added by the Posted Sales Invoice ES page extension.';
                ObsoleteTag = '30.0';
            }
        }
#endif
        modify("Payment Method Code")
        {
            Importance = Promoted;
        }
    }

    actions
    {
        addafter("&Track Package")
        {
            action(FindCorrectiveInvoices)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Find Corrective Invoices';
                Image = FindCreditMemo;
                RunObject = Page "Posted Sales Credit Memos";
                RunPageLink = "Corrected Invoice No." = field("No.");
                ToolTip = 'View related corrective invoices. You can send a corrective invoice when there is an error or dispute that affects a VAT amount or fiscal data. This invoice includes all legally required data and refers to the original invoice or invoices.';
            }
        }
    }
}
