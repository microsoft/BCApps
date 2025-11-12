// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Inbox;

using Microsoft.Intercompany.Dimension;

page 618 "Handled IC Inbox Jnl. Lines"
{
    Caption = 'Handled IC Inbox Jnl. Lines';
    DataCaptionFields = "IC Partner Code";
    PageType = List;
    SourceTable = "Handled IC Inbox Jnl. Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field("IC Partner Code"; Rec."IC Partner Code")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the code of the intercompany partner that the transaction is related to if the entry was created from an intercompany transaction.';
                    Visible = false;
                }
                field("Account Type"; Rec."Account Type")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the purpose of the account. Newly created accounts are automatically assigned the Posting account type, but you can change this.';
                }
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the account number that the entry on the journal line will be posted to.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies a description for the transaction on the journal line.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the total amount (including VAT) that the journal line consists of.';
                }
                field("VAT Amount"; Rec."VAT Amount")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the amount of VAT that is included in the total amount.';
                    Visible = false;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the currency that is used on the entry.';
                    Visible = false;
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies when the related invoice must be paid.';
                }
                field("Payment Discount %"; Rec."Payment Discount %")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the payment discount percentage that is granted if you pay on or before the date entered in the Pmt. Discount Date field. The discount percentage is specified in the Payment Terms Code field.';
                    Visible = false;
                }
                field("Payment Discount Date"; Rec."Payment Discount Date")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the last date on which the amount in the journal line must be paid for the order to qualify for a payment discount if the line is an invoice journal line.';
                    Visible = false;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies how many units of the item are specified on the line.';
                    Visible = false;
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
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(Dimensions)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    RunObject = Page "IC Inbox/Outbox Jnl. Line Dim.";
                    RunPageLink = "Table ID" = const(421),
                                  "Transaction No." = field("Transaction No."),
                                  "IC Partner Code" = field("IC Partner Code"),
                                  "Transaction Source" = field("Transaction Source"),
                                  "Line No." = field("Line No.");
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

