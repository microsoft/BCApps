// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

page 7000006 "Posted Cartera Documents"
{
    Caption = 'Posted Cartera Documents';
    Editable = false;
    PageType = List;
    SourceTable = "Posted Cartera Doc.";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Bill Gr./Pmt. Order No."; Rec."Bill Gr./Pmt. Order No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number assigned to this document in a bill group/payment order.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the creation of this document was posted.';
                    Visible = false;
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the due date of this document in a posted bill group/payment order.';
                }
                field("Payment Method Code"; Rec."Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment method code for the document number.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the document in a posted bill group/payment order, from which this document was generated.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of a bill in a posted bill group/payment order.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this posted document.';
                }
                field("Amount for Collection"; Rec."Amount for Collection")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount for which this document in a posted bill group/payment order was created.';
                }
                field("Amt. for Collection (LCY)"; Rec."Amt. for Collection (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount due for this document in a posted bill group/payment order.';
                    Visible = false;
                }
                field("Remaining Amount"; Rec."Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the pending amount for this document, in a posted bill group/payment order, to be settled in full.';
                }
                field("Remaining Amt. (LCY)"; Rec."Remaining Amt. (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the pending amount in order for this document, in a posted bill group/payment order, to be settled in full.';
                    Visible = false;
                }
                field(Place; Rec.Place)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the company bank and customer bank are in the same area.';
                    Visible = false;
                }
                field("Category Code"; Rec."Category Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a filter for the categories for which documents are shown.';
                }
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account type associated with this document in a posted bill group/payment order.';
                    Visible = false;
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ledger entry number associated with this posted document.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                begin
                    CarteraManagement.NavigatePostedDoc(Rec);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
            }
        }
    }

    var
        CarteraManagement: Codeunit CarteraManagement;
}

