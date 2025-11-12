// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.StandardCost;

pageextension 99000750 "Mfg. Item Card" extends "Item Card"
{
    layout
    {
        addafter("Qty. on Purch. Order")
        {
            field("Qty. on Prod. Order"; Rec."Qty. on Prod. Order")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies how many units of the item are allocated to production orders, meaning listed on outstanding production order lines.';
            }
            field("Qty. on Component Lines"; Rec."Qty. on Component Lines")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies how many units of the item are allocated as production order components, meaning listed under outstanding production order lines.';
            }
        }
        addafter(Purchase)
        {
            group(Replenishment_Production)
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
                    ToolTip = 'Specifies the production route that contains the operations needed to manufacture this item.';
                }
                field("Production BOM No."; Rec."Production BOM No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the production BOM that is used to manufacture this item.';
                }
                field("Rounding Precision"; Rec."Rounding Precision")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies how calculated consumption quantities are rounded when entered on consumption journal lines.';
                }
                field("Flushing Method"; Rec."Flushing Method")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies how consumption of the item (component) is calculated and handled in production processes. Manual: Enter and post consumption in the consumption journal manually. Forward: Automatically posts consumption according to the production order component lines when the first operation starts. Backward: Automatically calculates and posts consumption according to the production order component lines when the production order is finished. Pick + Forward / Pick + Backward: Variations with warehousing.';
                }
                field("Overhead Rate"; Rec."Overhead Rate")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = IsInventoriable;
                    Importance = Additional;
                    ToolTip = 'Specifies the item''s indirect cost as an absolute amount.';
                }
                field("Scrap %"; Rec."Scrap %")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the percentage of the item that you expect to be scrapped in the production process.';
                }
                field("Lot Size"; Rec."Lot Size")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the default number of units of the item that are processed in one production operation. This affects standard cost calculations and capacity planning. If the item routing includes fixed costs such as setup time, the value in this field is used to calculate the standard cost and distribute the setup costs. During demand planning, this value is used together with the value in the Default Dampener % field to ignore negligible changes in demand and avoid re-planning. Note that if you leave the field blank, it will be threated as 1.';
                }
                field("Allow Whse. Overpick"; Rec."Allow Whse. Overpick")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Production Blocked"; Rec."Production Blocked")
                {
                    ApplicationArea = Manufacturing;
                }
            }
        }
    }
    actions
    {
        addafter(Assembly)
        {
            group(Production)
            {
                Caption = 'Production';
                Image = Production;
                action("Production BOM")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Production BOM';
                    Image = BOM;
                    RunObject = Page "Production BOM";
                    RunPageLink = "No." = field("Production BOM No.");
                    ToolTip = 'Open the item''s production bill of material to view or edit its components.';
                }
                action("Prod. Active BOM Version")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Prod. Active BOM Version';
                    Image = BOMVersions;
                    ToolTip = 'Open the item''s active production bill of material to view or edit the components.';

                    trigger OnAction()
                    begin
                        Rec.OpenActiveProdBOMForItem(Rec."Production BOM No.", Rec."No.");
                    end;
                }
                action(Action78)
                {
                    AccessByPermission = TableData "Production BOM Header" = R;
                    ApplicationArea = Manufacturing;
                    Caption = 'Where-Used';
                    Image = "Where-Used";
                    ToolTip = 'View a list of production BOMs in which the item is used.';

                    trigger OnAction()
                    var
                        ProdBOMWhereUsed: Page "Prod. BOM Where-Used";
                    begin
                        ProdBOMWhereUsed.SetItem(Rec, WorkDate());
                        ProdBOMWhereUsed.RunModal();
                    end;
                }
                action(Action5)
                {
                    AccessByPermission = TableData "Production BOM Header" = R;
                    ApplicationArea = Manufacturing;
                    Caption = 'Calc. Production Std. Cost';
                    Image = CalculateCost;
                    ToolTip = 'Calculate the unit cost of the item by rolling up the unit cost of each component and resource in the item''s production BOM. The unit cost of a parent item must equal the total of the unit costs of its components, subassemblies, and any resources.';

                    trigger OnAction()
                    var
                        CalculateStandardCost: Codeunit "Calculate Standard Cost";
                    begin
                        Clear(CalculateStandardCost);
                        CalculateStandardCost.CalcItem(Rec."No.", false);
                    end;
                }
            }
        }
        addafter("Export Item Data")
        {
            action("Mfg. Export Item Data")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Export Item Data';
                Image = ExportFile;
                ToolTip = 'Use this function to export manufacturing item related data to text file (you can attach this file to support requests in case you may have issues with costing calculation).';

                trigger OnAction()
                var
                    Item: Record Item;
                begin
                    Item.SetRange("No.", Rec."No.");
                    Xmlport.Run(XmlPort::"Mfg. Export Item Data", false, false, Item);
                end;
            }
        }
    }
}
