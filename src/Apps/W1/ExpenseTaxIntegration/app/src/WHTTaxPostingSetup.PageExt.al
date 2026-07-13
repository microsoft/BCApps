// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseTaxIntegration;

using Microsoft.WithholdingTax;

pageextension 7056 "WHT Tax Posting Setup" extends "Withholding Tax Posting Setup"
{
    layout
    {
        addlast(GroupName)
        {
            field("Threshold Category Code"; Rec."Threshold Category Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the threshold category code used to accumulate withholding tax threshold amounts for the expense category.';
            }
        }
    }
}
