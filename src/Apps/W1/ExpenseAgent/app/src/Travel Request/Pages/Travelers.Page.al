// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7101 Travelers
{
    PageType = List;
    ApplicationArea = Basic, Suite;
    SourceTable = Traveler;
    Caption = 'Travelers';
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Expense User No."; Rec."Expense User No.")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                }
                field("Expense User Name"; Rec."Expense User Name")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }
}