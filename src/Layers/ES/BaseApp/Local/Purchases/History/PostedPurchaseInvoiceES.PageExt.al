// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

#pragma warning disable AS0088
pageextension 10752 "Posted Purchase Invoice ES" extends "Posted Purchase Invoice"
{
    layout
    {
        addafter("Currency Code")
        {
            field("Autoinvoice No."; Rec."Autoinvoice No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the invoice number if the original invoice was an autoinvoice.';
            }
        }
        addafter("Expected Receipt Date")
        {
            field("Vendor Bank Acc. Code"; Rec."Vendor Bank Acc. Code")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ToolTip = 'Specifies the vendor''s bank code that was on the purchase header when this invoice was created.';
            }
        }
        addafter("Invoice Details")
        {
            group(Payment)
            {
                Caption = 'Payment';
                Visible = false;
                ObsoleteState = Pending;
                ObsoleteReason = 'Standard fields are in Invoice Details. The vendor bank account field is added by the Posted Purchase Invoice ES page extension.';
                ObsoleteTag = '30.0';
            }
        }
    }

    actions
    {
        addafter("&Navigate")
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Print &Autoinvoice")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Print &Autoinvoice';
                    Image = CreateDocument;
                    ToolTip = 'Print the automatically created invoice.';

                    trigger OnAction()
                    var
                        PurchInvHeader: Record "Purch. Inv. Header";
                    begin
                        CurrPage.SetSelectionFilter(PurchInvHeader);
                        PurchInvHeader.PrintRecordsAutoInv(true);
                    end;
                }
                action(FindCorrectiveInvoices)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Find Corrective Invoices';
                    Image = FindCreditMemo;
                    RunObject = Page "Posted Purchase Credit Memos";
                    RunPageLink = "Corrected Invoice No." = field("No.");
                    ToolTip = 'View related corrective invoices. You can send a corrective invoice when there is an error or dispute that affects a VAT amount or fiscal data. This invoice includes all legally required data and refers to the original invoice or invoices.';
                }
            }
        }
    }
}
