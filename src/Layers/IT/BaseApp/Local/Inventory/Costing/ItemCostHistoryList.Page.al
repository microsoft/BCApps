// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Inventory.Reports;

page 12118 "Item Cost History List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Item Cost History';
    Editable = false;
    PageType = List;
    SourceTable = "Item Cost History";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1130000)
            {
                ShowCaption = false;
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item number that is assigned to the item in inventory.';
                }
                field("Competence Year"; Rec."Competence Year")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date that is used to determine the LIFO valuation period.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the item that was entered in the Item Card window.';
                }
                field("Base Unit of Measure"; Rec."Base Unit of Measure")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the standard unit of measure that is used to track the item in inventory.';
                }
                field("Inventory Valuation"; Rec."Inventory Valuation")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the method of inventory valuation that is used to calculate item cost.';
                }
                field("Start Year Inventory"; Rec."Start Year Inventory")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity of the item that is in inventory at the beginning of the year.';
                }
                field("End Year Inventory"; Rec."End Year Inventory")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity of the item that is in inventory at the end of the year.';
                }
                field("Year Average Cost"; Rec."Year Average Cost")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the average cost of the item during the year.';
                }
                field("Weighted Average Cost"; Rec."Weighted Average Cost")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the year-end inventory valuation of the item using the weighted average cost method.';
                }
                field("FIFO Cost"; Rec."FIFO Cost")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the year-end inventory First In, First Out (FIFO) valuation of the item.';
                }
                field("LIFO Cost"; Rec."LIFO Cost")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the year-end inventory Last In, First Out (LIFO) valuation of the item.';
                }
                field("Discrete LIFO Cost"; Rec."Discrete LIFO Cost")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the year-end inventory Last In, First Out (LIFO) valuation of the discrete manufacturing item.';
                }
                field("Expected Cost Exist"; Rec."Expected Cost Exist")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if an expected item cost was used during the period for the item.';
                }
                field(Definitive; Rec.Definitive)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the year-end cost associated with this item is final.';
                }
                field("Purchase Quantity"; Rec."Purchase Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity of the item that was purchased.';
                    Visible = false;
                }
                field("Purchase Amount"; Rec."Purchase Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the monetary valuation of the items purchased.';
                    Visible = false;
                }
                field("Production Quantity"; Rec."Production Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity of the item that is in production.';
                    Visible = false;
                }
                field("Production Amount"; Rec."Production Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the monetary valuation of the item that is in production.';
                    Visible = false;
                }
                field("Direct Components Amount"; Rec."Direct Components Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the direct cost of the item, based on the component costs directly attributable to the manufacture of the item.';
                    Visible = false;
                }
                field("Direct Routing Amount"; Rec."Direct Routing Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the direct cost associated with the routing of an item.';
                    Visible = false;
                }
                field("Overhead Routing Amount"; Rec."Overhead Routing Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the overhead cost associated with the routing of an item.';
                    Visible = false;
                }
                field("Subcontracted Amount"; Rec."Subcontracted Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the cost of outsourcing operations to a subcontractor.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Print")
            {
                Caption = '&Print';
                Image = Print;
                action("Detail Data")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Detail Data';
                    ToolTip = 'View the related details.';

                    trigger OnAction()
                    var
                        ItemCostHistory: Record "Item Cost History";
                        DetailLedgEntries: Report "Ledger Entry Details";
                    begin
                        ItemCostHistory.Reset();
                        ItemCostHistory.SetRange("Item No.", Rec."Item No.");
                        ItemCostHistory.SetRange("Competence Year", Rec."Competence Year");
                        DetailLedgEntries.SetTableView(ItemCostHistory);
                        DetailLedgEntries.Run();
                    end;
                }
            }
        }
    }
}

