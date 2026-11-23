// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7146 "Exp. Report Change Log Entries"
{
    PageType = List;
    SourceTable = "Exp. Report Change Log Entry";
    SourceTableView = sorting("Entry No.") order(descending);
    Caption = 'Expense Report Change History';
    ApplicationArea = Basic, Suite;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    LinksAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Entries)
            {
                field("Changed At"; Rec."Changed At")
                {
                }
                field("User ID"; Rec."User ID")
                {
                }
                field("Document No."; Rec."Document No.")
                {
                    Visible = false;
                }
                field("Document Line No."; Rec."Document Line No.")
                {
                }
                field("Expense No."; Rec."Expense No.")
                {
                }
                field("Field Caption"; Rec."Field Caption")
                {
                }
                field("Old Value"; Rec."Old Value")
                {
                }
                field("New Value"; Rec."New Value")
                {
                }
            }
        }
    }
}
