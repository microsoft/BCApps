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
        addafter(Description)
        {
            field("Transfer WIP Item"; Rec."Transfer WIP Item")
            {
                ApplicationArea = Manufacturing;
            }
        }
        addafter("Receipt Date")
        {
            field("Subc. Purch. Order No."; Rec."Subc. Purch. Order No.")
            {
                ApplicationArea = Manufacturing;
                Editable = false;
                Visible = false;
            }
            field("Subc. Purch. Order Line No."; Rec."Subc. Purch. Order Line No.")
            {
                ApplicationArea = Manufacturing;
                Editable = false;
                Visible = false;
            }
            field("Prod. Order No."; Rec."Subc. Prod. Order No.")
            {
                ApplicationArea = Manufacturing;
                Editable = false;
                Visible = false;
            }
            field("Subc. Prod. Order Line No."; Rec."Subc. Prod. Order Line No.")
            {
                ApplicationArea = Manufacturing;
                Editable = false;
                Visible = false;
            }
            field("Subc. Prod. Ord. Comp. Line No."; Rec."Subc. Prod. Ord. Comp Line No.")
            {
                ApplicationArea = Manufacturing;
                Editable = false;
                Visible = false;
            }
            field("Subc. Routing No."; Rec."Subc. Routing No.")
            {
                ApplicationArea = Manufacturing;
                Editable = false;
                Visible = false;
            }
            field("Subc. Routing Reference No."; Rec."Subc. Routing Reference No.")
            {
                ApplicationArea = Manufacturing;
                Editable = false;
                Visible = false;
            }
            field("Subc. WorkCenter No."; Rec."Subc. Work Center No.")
            {
                ApplicationArea = Manufacturing;
                Editable = false;
                Visible = false;
            }
            field("Subc. Operation No."; Rec."Subc. Operation No.")
            {
                ApplicationArea = Manufacturing;
                Editable = false;
                Visible = false;
            }
        }
    }
    actions
    {
        modify(Reserve)
        {
            Enabled = not Rec."Transfer WIP Item";
        }
        modify(ReserveFromInventory)
        {
            Enabled = not Rec."Transfer WIP Item";
        }
        modify("Item &Tracking Lines")
        {
            Enabled = not Rec."Transfer WIP Item";
        }
        modify(Shipment)
        {
            Enabled = not Rec."Transfer WIP Item";
        }
        modify(Receipt)
        {
            Enabled = not Rec."Transfer WIP Item";
        }
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
                    ToolTip = 'View the related production order.';
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
                    ToolTip = 'View the related production order routing.';
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
                    ToolTip = 'View the related production order components.';
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
                    ToolTip = 'View the related subcontracting purchase order.';
                    trigger OnAction()
                    begin
                        ShowPurchaseOrder(Rec);
                    end;
                }
            }
        }
    }
    var
        SubcProdOrderFactboxMgmt: Codeunit "Subc. ProdO. Factbox Mgmt.";
        SubcPurchFactboxMgmt: Codeunit "Subc. Purch. Factbox Mgmt.";

    local procedure ShowProductionOrder(RecRelatedVariant: Variant)
    begin
        SubcProdOrderFactboxMgmt.ShowProductionOrder(RecRelatedVariant);
    end;

    local procedure ShowProductionOrderRouting(RecRelatedVariant: Variant)
    begin
        SubcProdOrderFactboxMgmt.ShowProductionOrderRouting(RecRelatedVariant)
    end;

    local procedure ShowProductionOrderComponents(RecRelatedVariant: Variant)
    begin
        SubcProdOrderFactboxMgmt.ShowProductionOrderComponents(RecRelatedVariant);
    end;

    local procedure ShowPurchaseOrder(RecRelatedVariant: Variant)
    begin
        SubcPurchFactboxMgmt.ShowPurchaseOrder(RecRelatedVariant);
    end;
}