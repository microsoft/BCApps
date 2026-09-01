// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Projects.Project.Ledger;

tableextension 6906 "Exp. Project Ledg. Entry Ext" extends "Job Ledger Entry"
{
    fields
    {
        field(6900; "Expense Report No."; Code[20])
        {
            Caption = 'Expense Report No.';
            DataClassification = CustomerContent;
            TableRelation = "Posted Expense Report Header"."No.";
            ToolTip = 'Specifies the number of the posted expense report associated with this project ledger entry.';
        }
        field(6901; "Expense Report Line No."; Integer)
        {
            Caption = 'Expense Report Line No.';
            DataClassification = CustomerContent;
            TableRelation = "Posted Expense Report Line"."Line No." where("Document No." = field("Expense Report No."));
            ToolTip = 'Specifies the line number of the posted expense report associated with this project ledger entry.';
        }
    }
}