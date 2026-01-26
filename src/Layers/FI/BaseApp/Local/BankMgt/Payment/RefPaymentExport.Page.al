// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Bank.Payment;

using Microsoft.Foundation.Navigate;

page 32000004 "Ref. Payment - Export"
{
    Caption = 'Ref. Payment - Export';
    DataCaptionFields = "Due Date";
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "Ref. Payment - Exported";
    SourceTableView = sorting("Payment Date")
                      order(ascending);

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the reference payment.';
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a vendor number for the reference payment.';
                }
                field(Description2; Rec."Description 2")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description for the reference payment.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the due date of the purchase invoice.';
                }
                field("Payment Date"; Rec."Payment Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the payment will be debited from the bank account.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a document number for the reference payment.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a payable amount.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a currency code for the reference payment.';
                }
                field("Applies-to ID"; Rec."Applies-to ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an applied-to identification code for the reference payment.';
                }
                field("Transfer Time"; Rec."Transfer Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a transfer time if you have selected the Transferred field.';
                }
                field("Amount (LCY)"; Rec."Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount, in local currency, for the reference payment.';
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an external document number for the reference payment.';
                }
                field("Message Type"; Rec."Message Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a message type.';
                }
                field("Invoice Message"; Rec."Invoice Message")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an invoice message for the reference payment.';
                }
                field(Transferred; Rec.Transferred)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the reference payment is transferred.';
                }
                field("Transfer Date"; Rec."Transfer Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a transfer date if you have selected the Transferred field.';
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
                    Navigate.SetDoc(Rec."Posting Date", Rec."Document No.");
                    Navigate.Run();
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
        Navigate: Page Navigate;
}

