// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension.Correction;

pageextension 8530 "ICDimCorrectPostedLedgEntr" extends "Dim Correct Posted Ledg Entr"
{
    layout
    {
        addafter("Global Dimension 2 Code")
        {
            field("IC Partner Code"; Rec."IC Partner Code")
            {
                ApplicationArea = Intercompany;
                Editable = false;
                Visible = false;
            }
        }
    }
}
