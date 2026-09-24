// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6941 "Posted Exp. Rep. Line Per Diem"
{
    Caption = 'Posted Expense Report Line Per Diems';
    PageType = List;
    SourceTable = "Posted Exp. Rep. Line Per Diem";
    AutoSplitKey = true;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Description"; Rec."Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the per diem entry.';
                }
                field("Date"; Rec."Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date of the per diem entry.';
                }
                field("Breakfast"; Rec."Breakfast")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if breakfast is included.';
                }
                field("Lunch"; Rec."Lunch")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if lunch is included.';
                }
                field("Dinner"; Rec."Dinner")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if dinner is included.';
                }
                field("Per Diem Amount"; Rec."Per Diem Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the per diem amount.';
                }
            }
        }
    }
}