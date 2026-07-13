// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseTaxIntegration;

using Microsoft.ExpenseAgent;
using Microsoft.WithholdingTax;

tableextension 7055 "WHT Expense Category Ext" extends "Expense Category"
{
    fields
    {
        field(7055; "Withholding Selection Mode"; Enum "Withholding Selection Mode")
        {
            Caption = 'Withholding Selection Mode';
            DataClassification = CustomerContent;
        }
        field(7056; "Wthldg. Tax Prod. Post. Group"; Code[20])
        {
            Caption = 'Withholding Tax Prod. Post. Group';
            TableRelation = "Wthldg. Tax Prod. Post. Group";
            DataClassification = CustomerContent;
        }
        field(7057; "Withholding Group Code"; Code[20])
        {
            Caption = 'Withholding Group Code';
            TableRelation = "Withholding Tax Group";
            DataClassification = CustomerContent;
        }
    }
}
