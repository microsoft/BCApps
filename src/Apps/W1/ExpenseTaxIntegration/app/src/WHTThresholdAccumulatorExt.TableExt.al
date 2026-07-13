// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseTaxIntegration;

using Microsoft.ExpenseAgent;
using Microsoft.WithholdingTax;

tableextension 7057 "WHT Threshold Accumulator Ext" extends "WHT Threshold Accumulator"
{
    fields
    {
        field(7055; "Expense Category Code"; Code[20])
        {
            Caption = 'Expense Category Code';
            TableRelation = "Expense Category";
            DataClassification = CustomerContent;
        }
    }
}
