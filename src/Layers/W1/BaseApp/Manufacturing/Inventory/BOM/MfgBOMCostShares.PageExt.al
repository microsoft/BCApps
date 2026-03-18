// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.BOM;

pageextension 99000757 "Mfg. BOM Cost Shares" extends "BOM Cost Shares"
{
    layout
    {
        addafter("Lot Size")
        {
            field("Production BOM No."; Rec."Production BOM No.")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies the number of the production BOM that the item represents.';
                Visible = false;
            }
            field("Routing No."; Rec."Routing No.")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies the number of the item''s production order routing.';
                Visible = false;
            }
        }
    }
}