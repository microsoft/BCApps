// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Planning;

pageextension 99000834 "Mfg. Planning Component List" extends "Planning Component List"
{
    layout
    {
        addafter(Description)
        {
            field("Scrap %"; Rec."Scrap %")
            {
                ApplicationArea = Planning;
                ToolTip = 'Specifies the percentage of the item that you expect to be scrapped in the production process.';
                Visible = false;
            }
        }
        addafter("Location Code")
        {
            field("Routing Link Code"; Rec."Routing Link Code")
            {
                ApplicationArea = Planning;
                ToolTip = 'Specifies a routing link code to link a planning component with a specific operation.';
            }
        }
    }
}