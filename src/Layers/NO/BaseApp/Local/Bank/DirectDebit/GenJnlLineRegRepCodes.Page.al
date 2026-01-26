// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.DirectDebit;

page 10608 "Gen. Jnl. Line Reg. Rep. Codes"
{
    Caption = 'Gen. Jnl. Line Reg. Rep. Codes';
    PageType = List;
    SourceTable = "Gen. Jnl. Line Reg. Rep. Code";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Reg. Code"; Rec."Reg. Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the registration code.';
                }
                field("Reg. Code Description"; Rec."Reg. Code Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the registration code.';
                }
            }
        }
    }

    actions
    {
    }
}

