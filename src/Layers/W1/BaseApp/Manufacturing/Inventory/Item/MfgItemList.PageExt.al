// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Iventory.Item;

using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Reports;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Reports;
using Microsoft.Manufacturing.StandardCost;
using Microsoft.Manufacturing.Wizard;

pageextension 99000751 "Mfg. Item List" extends "Item List"
{
    layout
    {
        addafter("Assembly BOM")
        {
            field("Production BOM No."; Rec."Production BOM No.")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies the production BOM that is used to manufacture this item.';
            }
            field("Routing No."; Rec."Routing No.")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies the production route that contains the operations needed to manufacture this item.';
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
                action(Action29)
                {
                    AccessByPermission = TableData "BOM Component" = R;
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
                action(Action24)
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
                        CalculateStandardCost.CalcItem(Rec."No.", false);
                    end;
                }
            }
        }
        addafter(PrintLabel)
        {
            group(AssemblyProduction)
            {
                Caption = 'Assembly/Production';
                action("Where-Used (Top Level)")
                {
                    ApplicationArea = Assembly;
                    Caption = 'Where-Used (Top Level)';
                    Image = "Report";
                    RunObject = Report Microsoft.Manufacturing.Reports."Where-Used (Top Level)";
                    ToolTip = 'View where and in what quantities the item is used in the product structure. The report only shows information for the top-level item. For example, if item "A" is used to produce item "B", and item "B" is used to produce item "C", the report will show item B if you run this report for item A. If you run this report for item B, then item C will be shown as where-used.';
                }
                action("Quantity Explosion of BOM")
                {
                    ApplicationArea = Assembly;
                    Caption = 'Quantity Explosion of BOM';
                    Image = "Report";
                    RunObject = Report Microsoft.Manufacturing.Reports."Quantity Explosion of BOM";
                    ToolTip = 'View an indented BOM listing for the item or items that you specify in the filters. The production BOM is completely exploded for all levels.';
                }
            }
            group(Costing)
            {
                Caption = 'Costing';
                Image = ItemCosts;
                action("Inventory Valuation - WIP")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Inventory Valuation - WIP';
                    Image = "Report";
                    RunObject = Report "Inventory Valuation - WIP";
                    ToolTip = 'View inventory valuation for selected production orders in your WIP inventory. The report also shows information about the value of consumption, capacity usage and output in WIP. The printed report only shows invoiced amounts, that is, the cost of entries that have been posted as invoiced.';
                }
                action("Cost Shares Breakdown")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cost Shares Breakdown';
                    Image = "Report";
                    RunObject = Report "Cost Shares Breakdown";
                }
                action("Detailed Calculation")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Detailed Calculation';
                    Image = "Report";
                    RunObject = Report "Detailed Calculation";
                }
                action("Rolled-up Cost Shares")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Rolled-up Cost Shares';
                    Image = "Report";
                    RunObject = Report "Rolled-up Cost Shares";
                }
                action("Single-Level Cost Shares")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Single-Level Cost Shares';
                    Image = "Report";
                    RunObject = Report "Single-level Cost Shares";
                }
            }
        }
        addafter("Invt. Valuation - Cost Spec.")
        {
#if not CLEAN27
            action("Compare List")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Compare List (Obsolete)';
                Image = "Report";
                RunObject = Report "Compare List";
                ToolTip = 'View a comparison of components for two items. The printout compares the components, their unit cost, cost share and cost per component.';
                ObsoleteState = Pending;
                ObsoleteReason = 'This report has been replaced by the "Compare Production Cost Shares" report and will be removed in a future release.';
                ObsoleteTag = '27.0';
            }
#endif
            action("Compare Production Cost Shares")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Compare Production Cost Shares';
                Image = "Report";
                RunObject = Report "Compare Production Cost Shares";
            }
        }
        addafter("&Create Stockkeeping Unit")
        {
            action(RunProdDefinition)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Production Definition';
                Image = ProductionSetup;
                ToolTip = 'Define or review the bill of materials and routing for this item using the Production Definition Wizard.';

                trigger OnAction()
                var
                    ProductionDefinitionManager: Codeunit "Production Definition Manager";
                begin
                    ProductionDefinitionManager.RunForSource(Rec, "Prod. Definition Mode"::DefineItemStructure);
                end;
            }
        }
    }

    procedure SelectActiveItemsForProductionBOM(): Text
    var
        Item: Record Item;
    begin
        Item.SetFilter(Type, '<>%1', Item.Type::Service);
        exit(SelectInItemList(Item));
    end;
}