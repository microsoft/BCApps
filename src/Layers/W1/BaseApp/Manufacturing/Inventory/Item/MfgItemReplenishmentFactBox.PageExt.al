// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.ProductionBOM;

pageextension 99000758 "Mfg. ItemReplenishmentFactBox" extends "Item Replenishment FactBox"
{
    layout
    {
        addafter(Purchase)
        {
            group(Production)
            {
                Caption = 'Production';
                field("Manufacturing Policy"; Rec."Manufacturing Policy")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies if additional orders for any related components are calculated.';
                }
                field("Routing No."; Rec."Routing No.")
                {
                    ApplicationArea = Manufacturing;
                    Lookup = false;
                    ToolTip = 'Specifies the production route that contains the operations needed to manufacture this item.';

                    trigger OnDrillDown()
                    var
                        RoutingHeader: Record "Routing Header";
                    begin
                        if Rec."Routing No." <> '' then
                            RoutingHeader.SetRange("No.", Rec."Routing No.");
                        Page.Run(Page::Routing, RoutingHeader);
                    end;
                }
                field("Production BOM No."; Rec."Production BOM No.")
                {
                    ApplicationArea = Manufacturing;
                    Lookup = false;
                    ToolTip = 'Specifies the production BOM that is used to manufacture this item.';

                    trigger OnDrillDown()
                    var
                        ProductionBOMHeader: Record "Production BOM Header";
                    begin
                        if Rec."Production BOM No." <> '' then
                            ProductionBOMHeader.SetRange("No.", Rec."Production BOM No.");
                        Page.Run(Page::"Production BOM", ProductionBOMHeader);
                    end;
                }
            }
        }
    }
}
