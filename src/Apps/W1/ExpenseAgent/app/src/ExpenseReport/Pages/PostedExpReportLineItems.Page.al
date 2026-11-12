// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6944 "Posted Exp. Report Line Items"
{
    Caption = 'Posted Expense Report Line Itemizations';
    PageType = List;
    SourceTable = "Posted Exp. Rep. Line Item";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Expense Subcategory Code"; Rec."Expense Subcategory Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the expense subcategory code for this itemization.';
                }
                field("Description"; Rec."Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description for this itemization.';
                }
                field("Start Date"; Rec."Start Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the start date for this itemization.';
                }
                field("Quantity"; Rec.Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity for this itemization.';
                }
                field("Daily Rate"; Rec."Daily Rate")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the daily rate for this itemization.';
                }
                field("Amount"; Rec."Amount")
                {
                    Caption = 'Itemized Amount';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount for all itemization lines.';
                }
            }
        }
    }
}