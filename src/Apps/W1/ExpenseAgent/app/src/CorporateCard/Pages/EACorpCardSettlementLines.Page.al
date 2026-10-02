// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7448 "EA Corp Card Settlement Lines"
{
    ApplicationArea = Basic, Suite;
    AutoSplitKey = true;
    Caption = 'Settlement Statements';
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "EA Corp Card Settlement Line";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Statement Entry No."; Rec."Statement Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the validated statement included in the settlement.';
                }
                field("Statement No."; Rec."Statement No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the provider statement number.';
                }
                field("Statement Date"; Rec."Statement Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date of the included statement.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency of the included statement.';
                }
                field("Statement Amount"; Rec."Statement Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the included statement.';
                }
                field(Inactive; Rec.Inactive)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the historical settlement relationship was released by settlement reversal.';
                }
            }
        }
    }
}
