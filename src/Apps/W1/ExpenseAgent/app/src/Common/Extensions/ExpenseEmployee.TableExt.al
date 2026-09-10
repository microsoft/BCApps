// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.HumanResources.Employee;

tableextension 7110 "Expense Employee" extends Employee
{
    fields
    {
        field(7100; "Is Expense User"; Boolean)
        {
            Caption = 'Is Expense User';
            FieldClass = FlowField;
            CalcFormula = exist("Expense User" where("Employee No." = field("No.")));
        }
        field(7101; "Travel Request No. Filter"; Code[20])
        {
            Caption = 'Travel Request No. Filter';
            FieldClass = FlowFilter;
        }
    }
}
