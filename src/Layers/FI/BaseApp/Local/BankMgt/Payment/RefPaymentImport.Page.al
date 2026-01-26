// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Bank.Payment;

using Microsoft.Foundation.Navigate;

page 32000001 "Ref. Payment - Import"
{
    Caption = 'Ref. Payment - Import';
    DataCaptionFields = "Reference No.";
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "Ref. Payment - Imported";
    SourceTableView = sorting("No.")
                      order(ascending)
                      where("Filing Code" = filter(<> ''));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an entry number for the reference payment.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment amount for the reference payment.';
                }
                field("Filing Code"; Rec."Filing Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a filing code for the reference payment.';
                }
                field("Bank Account Code"; Rec."Bank Account Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a bank account code for the reference payment.';
                }
                field("Banks Posting Date"; Rec."Banks Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting date that is used by the bank.';
                }
                field("Banks Payment Date"; Rec."Banks Payment Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment date used by the bank.';
                }
                field("Reference No."; Rec."Reference No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reference number that is calculated from a reference number sequence.';
                }
                field("Payers Name"; Rec."Payers Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer name that is associated with the reference payment.';
                }
                field("Currency Code 2"; Rec."Currency Code 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a currency code for the reference payment.';
                }
                field("Name Source"; Rec."Name Source")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the general ledger source account.';
                }
                field("Correction Code"; Rec."Correction Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a correction code for the reference payment.';
                }
                field("Delivery Method"; Rec."Delivery Method")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a payment delivery method.';
                }
                field("Feedback Code"; Rec."Feedback Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a feedback code for the reference payment.';
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

