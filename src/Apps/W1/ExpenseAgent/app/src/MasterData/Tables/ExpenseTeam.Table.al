// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

/// <summary>
/// Stores the teams that expense users can belong to.
/// </summary>
table 6931 "Expense Team"
{
    Caption = 'Expense Team';
    LookupPageId = "Expense Teams";
    DrillDownPageId = "Expense Teams";
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; "Description"; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Number Of Team Members"; Integer)
        {
            Caption = 'Number Of Team Members';
            FieldClass = FlowField;
            CalcFormula = count("Expense User" where("Expense Team Code" = field("Code")));
        }
    }
    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
    }
}
