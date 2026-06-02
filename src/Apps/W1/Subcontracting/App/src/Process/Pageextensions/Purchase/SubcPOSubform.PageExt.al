// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Purchases.Document;

pageextension 99001524 "Subc. PO Subform" extends "Purchase Order Subform"
{
    layout
    {
        addlast(Control1)
        {
            field("Transfer WIP Item"; Rec."Transfer WIP Item")
            {
                ApplicationArea = Manufacturing;
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
                action("Transfer Order")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Subcontracting Transfer Order';
                    Image = TransferOrder;
                    ToolTip = 'View the related transfer order.';
                    trigger OnAction()
                    begin
                        SubcPurchFactboxMgmt.ShowTransferOrdersAndReturnOrder(Rec, true, false);
                    end;
                }
                action("Return Transfer Order")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Subcontracting Return Transfer Order';
                    Image = ReturnRelated;
                    ToolTip = 'View the related return transfer order.';
                    trigger OnAction()
                    begin
                        SubcPurchFactboxMgmt.ShowTransferOrdersAndReturnOrder(Rec, true, true);
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

    local procedure ShowProductionOrderComponents(RecRelatedVariant: Variant)
    begin
        SubcProdOrderFactboxMgmt.ShowProductionOrderComponents(RecRelatedVariant);
    end;

    local procedure ShowProductionOrderRouting(RecRelatedVariant: Variant)
    begin
        SubcProdOrderFactboxMgmt.ShowProductionOrderRouting(RecRelatedVariant);
    end;
}