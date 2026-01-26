// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#pragma warning disable AA0247
pageextension 12145 NoSeriesIT extends "No. Series"
{
    layout
    {
        addafter(Code)
        {
            field("No. Series Type"; Rec."No. Series Type")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'No. Series Type';
                ToolTip = 'Specifies the number series type that is associated with the number series code.';
            }
        }
        addafter(Description)
        {
            field("VAT Register"; Rec."VAT Register")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the VAT register that is associated with the number series code.';
            }
            field("Reverse Sales VAT No. Series"; Rec."Reverse Sales VAT No. Series")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the numbers series that must be used for a reverse sales VAT transaction.';
            }
            field("VAT Reg. Print Priority"; Rec."VAT Reg. Print Priority")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the print priority that is associated with the VAT register.';
            }
        }
    }

}