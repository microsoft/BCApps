// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7447 "EA Corp Card Settlement"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Corporate Card Settlement';
    PageType = Document;
    SourceTable = "EA Corp Card Settlement";

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Settlement Entry No."; Rec."Settlement Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the internal settlement entry number.';
                }
                field("Provider Code"; Rec."Provider Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = Rec.Status = Rec.Status::Open;
                    ToolTip = 'Specifies the provider being settled.';
                }
                field("Settlement No."; Rec."Settlement No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = Rec.Status = Rec.Status::Open;
                    ToolTip = 'Specifies the provider settlement identifier.';
                }
                field("Settlement Date"; Rec."Settlement Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = Rec.Status = Rec.Status::Open;
                    ToolTip = 'Specifies the date of the provider settlement.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = Rec.Status = Rec.Status::Open;
                    ToolTip = 'Specifies the currency of the settlement.';
                }
                field("Settlement Amount"; Rec."Settlement Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = Rec.Status = Rec.Status::Open;
                    ToolTip = 'Specifies the amount that the provider will collect.';
                }
                field("Corp Card Bank Account No."; Rec."Corp Card Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = Rec.Status = Rec.Status::Open;
                    ToolTip = 'Specifies the corporate card liability bank account that will receive the transfer.';
                }
                field("Payment Bank Account No."; Rec."Payment Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = Rec.Status = Rec.Status::Open;
                    ToolTip = 'Specifies the real bank account from which the settlement will be paid.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the lifecycle status of the settlement.';
                }
                field("Statement Total"; Rec."Statement Total")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount of the included statements.';
                }
                field("Statement Count"; Rec."Statement Count")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of included statements.';
                }
                field("Posted Document No."; Rec."Posted Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number used to post the settlement.';
                }
                field("Posted Date"; Rec."Posted Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date on which the settlement was posted.';
                }
                field("Corp Card Bank Acc. Entry No."; Rec."Corp Card Bank Acc. Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account ledger entry that cleared the corporate card liability.';
                }
                field("Payment Bank Acc. Entry No."; Rec."Payment Bank Acc. Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account ledger entry for the payment from the real bank account.';
                }
                field("G/L Register No."; Rec."G/L Register No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the G/L register created by settlement posting.';
                }
                field("Transaction No."; Rec."Transaction No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction number assigned to the settlement entries.';
                }
                field("Reversal Reason"; Rec."Reversal Reason")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = Rec.Status = Rec.Status::Posted;
                    ToolTip = 'Specifies why the posted settlement must be reversed.';
                }
                field("Reversal Transaction No."; Rec."Reversal Transaction No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction number created by settlement reversal.';
                }
                field("Reversal G/L Register No."; Rec."Reversal G/L Register No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the G/L register created by settlement reversal.';
                }
                field("Corp Card Reversal Entry No."; Rec."Corp Card Reversal Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reversal entry for the corporate card bank account.';
                }
                field("Payment Reversal Entry No."; Rec."Payment Reversal Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reversal entry for the payment bank account.';
                }
                field("Reversed At"; Rec."Reversed At")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the settlement was reversed.';
                }
                field("Reversed By User ID"; Rec."Reversed By User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the user who reversed the settlement.';
                }
            }
            part(Statements; "EA Corp Card Settlement Lines")
            {
                ApplicationArea = Basic, Suite;
                Editable = Rec.Status = Rec.Status::Open;
                SubPageLink = "Settlement Entry No." = field("Settlement Entry No.");
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SetReadyToPost)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Set Ready to Post';
                Enabled = Rec.Status = Rec.Status::Open;
                Image = Approve;
                ToolTip = 'Validates the settlement setup and included statements, then marks the settlement ready for posting.';

                trigger OnAction()
                var
                    CorpCardSettlementMgt: Codeunit "EA Corp Card Settlement Mgt";
                begin
                    CorpCardSettlementMgt.SetReadyToPost(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(Reopen)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Reopen';
                Enabled = Rec.Status = Rec.Status::ReadyToPost;
                Image = ReOpen;
                ToolTip = 'Reopens the settlement for correction.';

                trigger OnAction()
                var
                    CorpCardSettlementMgt: Codeunit "EA Corp Card Settlement Mgt";
                begin
                    CorpCardSettlementMgt.Reopen(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(PostSettlement)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Post';
                Enabled = Rec.Status = Rec.Status::ReadyToPost;
                Image = Post;
                ToolTip = 'Posts the transfer from the payment bank account to the corporate card liability bank account.';

                trigger OnAction()
                var
                    CorpCardSettlementMgt: Codeunit "EA Corp Card Settlement Mgt";
                begin
                    if not Confirm(PostSettlementQst, false, Rec."Settlement No.") then
                        exit;

                    CorpCardSettlementMgt.PostSettlement(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(ReverseSettlement)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Reverse';
                Enabled = Rec.Status = Rec.Status::Posted;
                Image = ReverseRegister;
                ToolTip = 'Reverses the complete settlement transaction and releases its statements for reconciliation and replacement settlement.';

                trigger OnAction()
                var
                    CorpCardSettlementMgt: Codeunit "EA Corp Card Settlement Mgt";
                begin
                    Rec.TestField("Reversal Reason");
                    if not Confirm(ReverseSettlementQst, false, Rec."Settlement No.") then
                        exit;

                    CorpCardSettlementMgt.ReverseSettlement(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        PostSettlementQst: Label 'Do you want to post corporate card settlement %1?', Comment = '%1 = settlement number';
        ReverseSettlementQst: Label 'Do you want to reverse corporate card settlement %1?', Comment = '%1 = settlement number';
}
