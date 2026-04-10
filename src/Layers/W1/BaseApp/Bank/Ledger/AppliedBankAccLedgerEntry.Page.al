// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Ledger;

/// <summary>
/// List part page displaying bank account ledger entries that have been applied to bank statements.
/// Shows read-only view of entries that have been successfully matched during bank reconciliation,
/// providing audit trail and reference information for reconciled transactions.
/// </summary>
page 413 "Applied Bank Acc. Ledger Entry"
{
    Caption = 'Applied Bank Account Ledger Entry';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPart;
    SourceTable = "Bank Account Ledger Entry";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Remaining Amount"; Rec."Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field(Open; Rec.Open)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Check Ledger Entries"; Rec."Check Ledger Entries")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }
}

