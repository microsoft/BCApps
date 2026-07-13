// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.WithholdingTax;

using Microsoft.ExpenseAgent;

pageextension 7055 "WHT Expense Categories" extends "Expense Category Card"
{
    layout
    {
        addlast("General")
        {
            group(WHT)
            {
                Caption = 'Withholding Tax';
                ShowCaption = true;

                field("Withholding Selection Mode"; Rec."Withholding Selection Mode")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the expense category uses a single tax or a tax group for withholding tax calculation.';
                }
                field("Wthldg. Tax Prod. Post. Group"; Rec."Wthldg. Tax Prod. Post. Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the withholding tax product posting group for the expense category.';
                }
                field("Withholding Group Code"; Rec."Withholding Group Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the withholding tax group code for the expense category.';
                }
            }
        }
    }
}
