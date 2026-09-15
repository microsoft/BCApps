// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Location;

pageextension 99000835 "Mfg. Location Card Part" extends "Location Card Part"
{
    layout
    {
        addafter(RequireShipment)
        {
            field("Prod. Consump. Whse. Handling"; Rec."Prod. Consump. Whse. Handling")
            {
                ApplicationArea = All;
                Caption = 'Production Consumption';
                ToolTip = 'Specifies the warehouse handling for consumption in production scenarios.';
            }           
        }
    }
}