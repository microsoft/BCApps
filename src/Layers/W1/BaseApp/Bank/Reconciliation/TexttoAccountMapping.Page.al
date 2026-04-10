// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

/// <summary>
/// Configuration page for text-to-account mapping rules.
/// Allows setup of automatic account assignment based on transaction text patterns.
/// </summary>
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
                }
                field("Debit Acc. No."; Rec."Debit Acc. No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Credit Acc. No."; Rec."Credit Acc. No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Bal. Source Type"; Rec."Bal. Source Type")
                {
                    ApplicationArea = Basic, Suite;

                    trigger OnValidate()
                    begin
                        EnableBalSourceNo := Rec.IsBalSourceNoEnabled();
                    end;
                }
                field("Bal. Source No."; Rec."Bal. Source No.")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = EnableBalSourceNo;
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

