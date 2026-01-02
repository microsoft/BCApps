// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Transfer;

pageextension 99001532 "Sub. PstdDirectTransfSub" extends "Posted Direct Transfer Subform"
{
    layout
    {
        addlast(Control1)
        {
            field("Subcontr. Purch. Order No."; Rec."Subcontr. Purch. Order No.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the number of the related purchase order.';
                Visible = false;
            }
            field("Subcontr. PO Line No."; Rec."Subcontr. PO Line No.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the number of the related purchase order line.';
                Visible = false;
            }
            field("Prod. Order No."; Rec."Prod. Order No.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the number of the related production order.';
                Visible = false;
            }
            field("Prod. Order Line No."; Rec."Prod. Order Line No.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the number of the related production order line.';
                Visible = false;
            }
            field("Prod. Order. Comp. Line No."; Rec."Prod. Order Comp. Line No.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the line number of the related production order component line.';
                Visible = false;
            }
            field("Routing No."; Rec."Routing No.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the number of the related production routing.';
                Visible = false;
            }
            field("Routing Reference No."; Rec."Routing Reference No.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the number of the related production routing reference no.';
                Visible = false;
            }
            field("WorkCenter No."; Rec."Work Center No.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the number of the related production work center.';
                Visible = false;
            }
            field("Operation No."; Rec."Operation No.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the number of the related production operation no.';
                Visible = false;
            }
        }
    }
    actions
    {
        addafter("&Line")
        {
            group(Production)
            {
                Caption = 'Production';
                action("Production Order")
                {
                    ApplicationArea = All;
                    Caption = 'Production Order';
                    Image = Production;
                    ToolTip = 'Specifies the depended Production Order of this Subcontracting Transfer Order.';
                    trigger OnAction()
                    begin
                        ShowProductionOrder(Rec);
                    end;
                }
                action("Production Order Routing")
                {
                    ApplicationArea = All;
                    Caption = 'Production Order Routing';
                    Image = Route;
                    ToolTip = 'Specifies the depended Production Routing of this Subcontracting Purchase Order.';
                    trigger OnAction()
                    begin
                        ShowProductionOrderRouting(Rec);
                    end;
                }
                action("Production Order Components")
                {
                    ApplicationArea = All;
                    Caption = 'Production Order Components';
                    Image = Components;
                    ToolTip = 'Specifies the depended Production Components of this Subcontracting Purchase Order.';
                    trigger OnAction()
                    begin
                        ShowProductionOrderComponents(Rec);
                    end;
                }
                action("Purchase Order")
                {
                    ApplicationArea = All;
                    Caption = 'Subcontracting Purchase Order';
                    Image = Order;
                    ToolTip = 'Specifies the Subcontracting Purchase Order associated with the Transfer Order.';
                    trigger OnAction()
                    begin
                        ShowPurchaseOrder(Rec);
                    end;
                }
            }
        }
    }
    var
        SubcontractingFactboxMgmt: Codeunit "Sub. Factbox Mgmt.";

    local procedure ShowProductionOrder(RecRelatedVariant: Variant)
    begin
        SubcontractingFactboxMgmt.ShowProductionOrder(RecRelatedVariant);
    end;

    local procedure ShowProductionOrderRouting(RecRelatedVariant: Variant)
    begin
        SubcontractingFactboxMgmt.ShowProductionOrderRouting(RecRelatedVariant);
    end;

    local procedure ShowProductionOrderComponents(RecRelatedVariant: Variant)
    begin
        SubcontractingFactboxMgmt.ShowProductionOrderComponents(RecRelatedVariant);
    end;

    local procedure ShowPurchaseOrder(RecRelatedVariant: Variant)
    begin
        SubcontractingFactboxMgmt.ShowPurchaseOrder(RecRelatedVariant);
    end;
}