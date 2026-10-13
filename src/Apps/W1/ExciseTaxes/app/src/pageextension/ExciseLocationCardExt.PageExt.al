// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExciseTaxes;

using Microsoft.Inventory.Location;

pageextension 7417 "Excise Location Card Ext" extends "Location Card"
{
    layout
    {
        addlast(Content)
        {
            group("Excise Tax")
            {
                Caption = 'Excise Tax';
                field("Excise Bonded Location"; Rec."Excise Bonded Location")
                {
                    ApplicationArea = All;
                }
                field("Excise Bond Identifier"; Rec."Excise Bond Identifier")
                {
                    ApplicationArea = All;
                }
                field("Bond Authorization No."; Rec."Bond Authorization No.")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}