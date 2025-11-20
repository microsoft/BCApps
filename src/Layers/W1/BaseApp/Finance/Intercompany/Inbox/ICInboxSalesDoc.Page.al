// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Inbox;

using Microsoft.Intercompany.Dimension;

page 644 "IC Inbox Sales Doc."
{
    Caption = 'IC Inbox Sales Doc.';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Document;
    SourceTable = "IC Inbox Sales Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the type of the related document.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("IC Transaction No."; Rec."IC Transaction No.")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the number of the intercompany transaction. The transaction number indicates which line in the IC Outbox Transaction table the document is related to.';
                }
                field("IC Partner Code"; Rec."IC Partner Code")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the code of the intercompany partner that the transaction is related to if the entry was created from an intercompany transaction.';
                }
                field("Transaction Source"; Rec."Transaction Source")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies which company created the transaction.';
                }
                field("Sell-to Customer No."; Rec."Sell-to Customer No.")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the number of the customer.';
                }
                field("Bill-to Customer No."; Rec."Bill-to Customer No.")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the number of the customer that you send or sent the invoice or credit memo to.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies when the related invoice must be paid.';
                }
                field("Pmt. Discount Date"; Rec."Pmt. Discount Date")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the date on which the amount in the entry must be paid for a payment discount to be granted.';
                }
                field("Payment Discount %"; Rec."Payment Discount %")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the payment discount percentage that is granted if the customer pays on or before the date entered in the Pmt. Discount Date field. The discount percentage is specified in the Payment Terms Code field.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the currency that is used on the entry.';
                }
            }
            part(ICInboxSalesLines; "IC Inbox Sales Lines")
            {
                ApplicationArea = Intercompany;
                SubPageLink = "IC Transaction No." = field("IC Transaction No."),
                              "IC Partner Code" = field("IC Partner Code"),
                              "Transaction Source" = field("Transaction Source");
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field("Ship-to Name"; Rec."Ship-to Name")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the name of the customer at the address that the items are shipped to.';
                }
                field("Ship-to Address"; Rec."Ship-to Address")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the address that the items are shipped to.';
                }
                field("Ship-to City"; Rec."Ship-to City")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the city of the address that the items are shipped to.';
                }
                field("Promised Delivery Date"; Rec."Promised Delivery Date")
                {
                    ApplicationArea = OrderPromising;
                    ToolTip = 'Specifies the date that you have promised to deliver the order, as a result of the Order Promising function.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group(Document)
            {
                Caption = '&Document';
                Image = Document;
                action(Dimensions)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    RunObject = Page "IC Document Dimensions";
                    RunPageLink = "Table ID" = const(434),
                                  "Transaction No." = field("IC Transaction No."),
                                  "IC Partner Code" = field("IC Partner Code"),
                                  "Transaction Source" = field("Transaction Source"),
                                  "Line No." = const(0);
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
            }
        }
    }
}

