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
                }
                field("Wthldg. Tax Prod. Post. Group"; Rec."Wthldg. Tax Prod. Post. Group")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Withholding Group Code"; Rec."Withholding Group Code")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }
}
