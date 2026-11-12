// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Bank.Statement;

pageextension 7441 "EA Bank Account Stmt. Lines" extends "Bank Account Statement Lines"
{
    layout
    {
        addafter(Description)
        {
            field("EA Corp Card Trans Entry No."; Rec."EA Corp Card Trans Entry No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the corporate card transaction represented by this statement line.';
            }
            field("EA Posted Exp. Report No."; Rec."EA Posted Exp. Report No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the posted expense report linked to this statement line.';
            }
        }
    }
}
