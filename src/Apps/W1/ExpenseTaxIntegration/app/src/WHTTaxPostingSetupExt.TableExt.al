// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseTaxIntegration;

using Microsoft.ExpenseAgent;
using Microsoft.WithholdingTax;

tableextension 7056 "WHT Tax Posting Setup Ext" extends "Withholding Tax Posting Setup"
{
    fields
    {
        field(7055; "Threshold Category Code"; Code[20])
        {
            Caption = 'Threshold Category Code';
            TableRelation = "Expense Category";
            DataClassification = CustomerContent;
        }
    }
}
