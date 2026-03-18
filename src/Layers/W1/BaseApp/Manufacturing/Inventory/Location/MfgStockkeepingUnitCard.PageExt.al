// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Location;

pageextension 99000754 "Mfg. Stockkeeping Unit Card" extends "Stockkeeping Unit Card"
{
    layout
    {
        addafter("Qty. on Purch. Order")
        {
            field("Qty. on Prod. Order"; Rec."Qty. on Prod. Order")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies how many item units have been planned for production, which is how many units are on outstanding production order lines.';
            }
        }
        addafter("Qty. in Transit")
        {
            field("Qty. on Component Lines"; Rec."Qty. on Component Lines")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies how many item units are needed for production, which is how many units remain on outstanding production order component lists.';
            }
        }
        addafter("Lot Size")
        {
            field("Routing No."; Rec."Routing No.")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies the production route that contains the operations needed to manufacture this item.';
            }
            field("Production BOM No."; Rec."Production BOM No.")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies the production BOM that is used to manufacture this item.';
            }
        }
    }
    actions
    {
        addafter(History)
        {
            group(Production_Navigation)
            {
                Caption = 'Production';
                Image = Production;
                action("Production BOM")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Production BOM';
                    Image = BOM;
                    ToolTip = 'Open the stockkeeping unit''s production bill of material to view or edit its components. If production bill of material is not defined in the stockkeeping unit, the production bill of material from the item card is used.';

                    trigger OnAction()
                    begin
                        Rec.OpenProductionBOMForSKUItem(Rec."Production BOM No.", Rec."Item No.");
                    end;
                }
                action("Prod. Active BOM Version")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Prod. Active BOM Version';
                    Image = BOMVersions;
                    ToolTip = 'Open the stockkeeping unit''s active production bill of material to view or edit the components. If production bill of material is not defined in the stockkeeping unit, the production bill of material from the item card is used.';

                    trigger OnAction()
                    begin
                        Rec.OpenActiveProductionBOMForSKUItem(Rec."Production BOM No.", Rec."Item No.");
                    end;
                }
            }
        }
        addafter("C&alculate Counting Period")
        {
            action("Calc. Production Std. Cost")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Calc. Production Std. Cost';
                Image = CalculateCost;
                ToolTip = 'Calculate the unit cost of the SKUs by rolling up the unit cost of each component and resource in the item''s production BOM. The unit cost of a parent item must equal the total of the unit costs of its components, subassemblies, and any resources.';

                trigger OnAction()
                var
                    CalculateStandardCost: Codeunit Microsoft.Manufacturing.StandardCost."Calculate Standard Cost";
                begin
                    CalculateStandardCost.CalcItemSKU(Rec."Item No.", Rec."Location Code", Rec."Variant Code");
                end;
            }
        }
    }
}