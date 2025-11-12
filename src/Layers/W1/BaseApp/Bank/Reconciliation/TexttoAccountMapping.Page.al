// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

page 1251 "Text-to-Account Mapping"
{
    AutoSplitKey = true;
    Caption = 'Text-to-Account Mapping';
    PageType = List;
    SaveValues = true;
    SourceTable = "Text-to-Account Mapping";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Mapping Text"; Rec."Mapping Text")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the text on the payment that is used to map the payment to a customer, vendor, or general ledger account when you choose the Apply Automatically function in the Payment Reconciliation Journal window.';
                }
                field("Debit Acc. No."; Rec."Debit Acc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the debit account that payments with this text-to-account mapping are matched with when you choose the Apply Automatically function in the Payment Reconciliation Journal window.';
                }
                field("Credit Acc. No."; Rec."Credit Acc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the credit account that payments with this text-to-account mapping are applied to when you choose the Apply Automatically function in the Payment Reconciliation Journal window.';
                }
                field("Bal. Source Type"; Rec."Bal. Source Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of balancing account that amounts on payments or incoming documents that have this text to account mapping are posted to. The Bank Account option is used only for incoming documents and cannot be used in payment reconciliation journals.';

                    trigger OnValidate()
                    begin
                        EnableBalSourceNo := Rec.IsBalSourceNoEnabled();
                    end;
                }
                field("Bal. Source No."; Rec."Bal. Source No.")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = EnableBalSourceNo;
                    ToolTip = 'Specifies the balancing account to post amounts on payments or incoming documents that have this text to account mapping. The Bank Account option in the Bal. Source Type cannot be used in payment reconciliation journals.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        EnableBalSourceNo := Rec.IsBalSourceNoEnabled();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        exit(Rec.CheckEntriesAreConsistent());
    end;

    var
        EnableBalSourceNo: Boolean;
}

