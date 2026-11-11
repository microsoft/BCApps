// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

#pragma warning disable AS0088
pageextension 7000122 "Pstd. Sales Cr. Memo Update ES" extends "Pstd. Sales Cr. Memo - Update"
{
    layout
    {
        addafter(Payment)
        {
            group("Invoice Details")
            {
                Caption = 'Invoice Details';
                field("Correction Type"; Rec."Correction Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies the Correction Type.';
                }
                field("Corrected Invoice No."; Rec."Corrected Invoice No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies the number of the posted invoice that you need to correct.';
                }
            }
        }
    }
}
