// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Calculation;

pageextension 11310 "VAT Specification Subform BE" extends "VAT Specification Subform"
{
    layout
    {
        addafter("VAT Base")
        {
            field("VAT Base (Lowered)"; Rec."VAT Base (Lowered)")
            {
                ApplicationArea = Basic, Suite;
                AutoFormatExpression = CurrencyCode;
                AutoFormatType = 1;
                ToolTip = 'Specifies the actual VAT base amount (lowered). It is calculated as follows: VAT Base = Line Amount - Invoice Discount Amount. VAT Base (Lowered) = VAT Base - Inv. Disc. Base Amount.';
            }
        }
        modify("VAT Base")
        {
            Visible = false;
        }
    }
}