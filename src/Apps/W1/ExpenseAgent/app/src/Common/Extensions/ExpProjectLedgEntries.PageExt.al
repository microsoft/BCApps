// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Projects.Project.Ledger;

pageextension 6900 "Exp. Project Ledg. Entries" extends "Job Ledger Entries"
{
    layout
    {
        addafter("Location Code")
        {
            field("Expense Report No."; Rec."Expense Report No.")
            {
                ApplicationArea = Basic, Suite;
            }
            field("Expense Report Line No."; Rec."Expense Report Line No.")
            {
                ApplicationArea = Basic, Suite;
            }
        }
    }
}