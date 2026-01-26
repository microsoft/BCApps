// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Transfer;

pageextension 99001529 "Subc. Trans. Order Sub." extends "Transfer Order Subform"
{
    layout
    {
        addafter("Receipt Date")
        {
            field("Subcontr. Purch. Order No."; Rec."Subcontr. Purch. Order No.")
            {
                ApplicationArea = Manufacturing;
                Editable = false;
                Visible = false;
            }
            field("Subcontr. PO Line No."; Rec."Subcontr. PO Line No.")
            {
                ApplicationArea = Manufacturing;
                Editable = false;
                Visible = false;
            }
            field("Prod. Order No."; Rec."Prod. Order No.")
            {
                ApplicationArea = Manufacturing;
                Editable = false;
                Visible = false;
            }
            field("Prod. Order Line No."; Rec."Prod. Order Line No.")
            {
                ApplicationArea = Manufacturing;
                Editable = false;
                Visible = false;
            }
            field("Prod. Order. Comp. Line No."; Rec."Prod. Order Comp. Line No.")
            {
                ApplicationArea = Manufacturing;
                Editable = false;
                Visible = false;
            }
            field("Routing No."; Rec."Routing No.")
            {
                ApplicationArea = Manufacturing;
                Editable = false;
                Visible = false;
            }
            field("Routing Reference No."; Rec."Routing Reference No.")
            {
                ApplicationArea = Manufacturing;
                Editable = false;
                Visible = false;
            }
            field("WorkCenter No."; Rec."Work Center No.")
            {
                ApplicationArea = Manufacturing;
                Editable = false;
                Visible = false;
            }
            field("Operation No."; Rec."Operation No.")
            {
                ApplicationArea = Manufacturing;
                Editable = false;
                Visible = false;
            }
        }
    }
    actions
    {
        addafter("F&unctions")
        {
            group(Production)
            {
                Caption = 'Production';
                action("Production Order")
                {
                    ApplicationArea = Manufacturing;
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
                    ApplicationArea = Manufacturing;
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
                    ApplicationArea = Manufacturing;
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
                    ApplicationArea = Manufacturing;
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
        SubcFactboxMgmt: Codeunit "Subc. Factbox Mgmt.";

    local procedure ShowProductionOrder(RecRelatedVariant: Variant)
    begin
        SubcFactboxMgmt.ShowProductionOrder(RecRelatedVariant);
    end;

    local procedure ShowProductionOrderRouting(RecRelatedVariant: Variant)
    begin
        SubcFactboxMgmt.ShowProductionOrderRouting(RecRelatedVariant)
    end;

    local procedure ShowProductionOrderComponents(RecRelatedVariant: Variant)
    begin
        SubcFactboxMgmt.ShowProductionOrderComponents(RecRelatedVariant);
    end;

    local procedure ShowPurchaseOrder(RecRelatedVariant: Variant)
    begin
        SubcFactboxMgmt.ShowPurchaseOrder(RecRelatedVariant);
    end;
}