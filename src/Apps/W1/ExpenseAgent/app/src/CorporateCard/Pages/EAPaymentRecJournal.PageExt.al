// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Bank.Reconciliation;

pageextension 7440 "EA Payment Rec. Journal" extends "Payment Reconciliation Journal"
{
    layout
    {
        addafter("Transaction ID")
        {
            field("EA Corp Card Trans Entry No."; Rec."EA Corp Card Trans Entry No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the corporate card transaction that created this payment reconciliation line.';
            }
            field("EA Posted Exp. Report No."; Rec."EA Posted Exp. Report No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the posted expense report linked to this payment reconciliation line.';
            }
        }
    }
}
