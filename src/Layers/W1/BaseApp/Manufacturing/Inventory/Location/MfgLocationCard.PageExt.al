// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Location;

pageextension 99000756 "Mfg. Location Card" extends "Location Card"
{
    layout
    {
        addafter("Purch., Sales & Transfer")
        {
            group("Production Warehouse Handling")
            {
                Caption = 'Production';
                field("Prod. Consumption Whse. Handling"; Rec."Prod. Consump. Whse. Handling")
                {
                    Caption = 'Prod. Consumption Whse. Handling';
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the warehouse handling for consumption in production scenarios.';
                    Enabled = ProdPickWhseHandlingEnable;
                }
                field("Prod. Output Whse. Handling"; Rec."Prod. Output Whse. Handling")
                {
                    Caption = 'Prod. Output Whse. Handling';
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the warehouse handling for output in production scenarios';
                    Enabled = ProdPutawayWhseHandlingEnable;
                }
            }
        }
        addafter(Warehouse)
        {
            group("Stockkeeping Unit")
            {
                Caption = 'Stockkeeping Unit';
                field("SKU Creation Policy"; Rec."SKU Creation Policy")
                {
                    Caption = 'SKU Creation Policy';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the SKU creation policy for the location.';
                }
                field("Missing SKU Planning Policy"; Rec."Missing SKU Planning Policy")
                {
                    Caption = 'Missing SKU Planning Policy';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the missing SKU planning policy for the location.';
                }
            }
        }
    }
}
