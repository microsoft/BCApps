// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Ledger;

pageextension 99001501 "Subc. ILEntries" extends "Item Ledger Entries"
{
    layout
    {
        addlast(Control1)
        {
            field("Subcontr. Purch. Order No."; Rec."Subcontr. Purch. Order No.")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies the number of the related purchase order.';
                Visible = false;
            }
            field("Subcontr. PO Line No."; Rec."Subcontr. PO Line No.")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies the number of the related purchase order line.';
                Visible = false;
            }
            field("Prod. Order No."; Rec."Prod. Order No.")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies the number of the related production order.';
                Visible = false;
            }
            field("Prod. Order Line No."; Rec."Prod. Order Line No.")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies the number of the related production order line.';
                Visible = false;
            }
        }
    }
    actions
    {
        addafter("&Application")
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
        SubcProdOrderFactboxMgmt.ShowProductionOrderRouting(RecRelatedVariant);
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