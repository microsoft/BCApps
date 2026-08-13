// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7105 "Expense Activity Log FactBox"
{
    PageType = ListPart;
    SourceTable = "Expense Activity Log Entry";
    SourceTableView = sorting("Source Table ID", "Source Record System ID", "Occurred At", "Entry No.") order(descending);
    Permissions = tabledata "Expense Activity Log Entry" = r;
    Caption = 'Activity Log';
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
                field("Event Type"; Rec."Event Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies what happened to the expense report.';
                }
                field("Occurred At"; Rec."Occurred At")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the activity occurred.';
                }
                field("Actor Display Name"; Rec."Actor Display Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the person who performed the activity, when there was one.';
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the message recorded with the activity.';
                }
            }
        }
    }
}
