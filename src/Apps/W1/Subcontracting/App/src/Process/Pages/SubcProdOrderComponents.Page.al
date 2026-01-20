// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Document;

page 99001503 "Subc. Prod. Order Components"
{
    ApplicationArea = Manufacturing;
    Caption = 'Prod. Order Comp. Line List';
    Editable = false;
    PageType = List;
    SourceTable = "Prod. Order Component";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Subcontracting Type"; Rec."Subcontracting Type")
                {
                    ToolTip = 'Specifies the Type of Subcontracting that is assigned to the Production Order Component.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ToolTip = 'Specifies the number of the item that is a component in the production order component list.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies a description of the item on the line.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ToolTip = 'Specifies the location where the component is stored. Copies the location code from the corresponding field on the production order line.';
                    Visible = false;
                }
                field("Quantity per"; Rec."Quantity per")
                {
                    AutoFormatType = 0;
                    ToolTip = 'Specifies how many units of the component are required to produce the parent item.';
                }
                field("Expected Quantity"; Rec."Expected Quantity")
                {
                    AutoFormatType = 0;
                    ToolTip = 'Specifies the quantity of the component expected to be consumed during the production of the quantity on this line.';
                }
                field("Remaining Quantity"; Rec."Remaining Quantity")
                {
                    AutoFormatType = 0;
                    ToolTip = 'Specifies the difference between the finished and planned quantities, or zero if the finished quantity is greater than the remaining quantity.';
                }
                field("OutQtyOnPurch Order (Base)"; FactBoxmanagement.GetPurchOrderOutstandingQtyBaseFromProdOrderComp(Rec))
                {
                    AutoFormatType = 0;
                    Caption = 'Outstanding Qty (Base)';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the outstanding item amount that is on the subcontracting order.';
                    trigger OnDrillDown()
                    begin
                        FactBoxmanagement.ShowPurchOrderOutstandingQtyBaseFromProdOrderComp(Rec);
                    end;
                }
                field("ReceivedQtyOnPurch Order (Base)"; FactBoxmanagement.GetPurchOrderQtyReceivedBaseFromProdOrderComp(Rec))
                {
                    AutoFormatType = 0;
                    Caption = 'Qty. received (Base)';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the received item amount that is on the subcontracting order.';
                    trigger OnDrillDown()
                    begin
                        FactBoxmanagement.ShowPurchOrderQtyReceivedBaseFromProdOrderComp(Rec);
                    end;
                }
                field("Qty. on Transfer Order (Base)"; Rec."Qty. on Trans Order (Base)")
                {
                    ToolTip = 'Specifies the item amount that is on the transfer order.';
                }
                field("RetQtyOnTransOrder (Base)"; Rec."RetQtyOnTransOrder (Base)")
                {
                    ToolTip = 'Specifies the item amount that is on the transfer order to be returned.';
                }
                field("Qty. in Transit (Base)"; Rec."Qty. in Transit (Base)")
                {
                    ToolTip = 'Specifies the items that are in transit.';
                    Visible = false;
                }
                field("RetQtyInTransit (Base)"; Rec."RetQtyInTransit (Base)")
                {
                    ToolTip = 'Specifies the items that are in transit for return.';
                    Visible = false;
                }
                field("Qty. transf. to Subcontractor"; Rec."Qty. transf. to Subcontr")
                {
                    ToolTip = 'Specifies the item amount transferred to the subcontractor.';
                }
                field(ConsumedQty; FactBoxmanagement.GetConsumptionQtyFromProdOrderComponent(Rec))
                {
                    AutoFormatType = 0;
                    Caption = 'Consumed';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the consumed Quantity from assigned Components.';
                    trigger OnDrillDown()
                    begin
                        FactBoxmanagement.ShowConsumptionQtyFromProdOrderComponent(Rec);
                    end;
                }
                field("Due Date"; Rec."Due Date")
                {
                    ToolTip = 'Specifies the date when the produced item must be available. The date is copied from the header of the production order.';
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                    AutoFormatExpression = '';
                    AutoFormatType = 2;
                    ToolTip = 'Specifies the cost of one unit of the item or resource on the line.';
                    Visible = false;
                }
                field("Cost Amount"; Rec."Cost Amount")
                {
                    AutoFormatExpression = '';
                    AutoFormatType = 2;
                    ToolTip = 'Specifies the total cost on the line by multiplying the unit cost by the quantity.';
                    Visible = false;
                }
            }
        }
        area(FactBoxes)
        {
            systempart(Control1900383207; Links)
            {
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                Visible = false;
            }
        }
    }
    actions
    {
        area(Navigation)
        {
            group("Line")
            {
                Caption = 'Line';
                Image = Line;
                action("Item Tracking Lines")
                {
                    Caption = 'Item Tracking Lines';
                    Image = ItemTrackingLines;
                    ShortcutKey = 'Shift+Ctrl+I';
                    ToolTip = 'View or edit serial numbers and lot numbers that are assigned to the item on the document or journal line.';

                    trigger OnAction()
                    begin
                        Rec.OpenItemTrackingLines();
                    end;
                }
            }
        }
    }

    var
        FactBoxmanagement: Codeunit "Subc. Factbox Mgmt.";
}