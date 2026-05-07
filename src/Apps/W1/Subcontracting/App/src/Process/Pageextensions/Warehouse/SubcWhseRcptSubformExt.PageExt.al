// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Purchases.Document;
using Microsoft.Warehouse.Document;

pageextension 99001533 "Subc. Whse Rcpt Subform Ext." extends "Whse. Receipt Subform"
{
    actions
    {
        addafter(ItemTrackingLines)
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
                        if GetSourcePurchaseLine() then
                            ShowProductionOrder(PurchaseLine);
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
                        if GetSourcePurchaseLine() then
                            ShowProductionOrderRouting(PurchaseLine);
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
                        if GetSourcePurchaseLine() then
                            ShowProductionOrderComponents(PurchaseLine);
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
                        if GetSourcePurchaseLine() then
                            SubcPurchFactboxMgmt.ShowTransferOrdersAndReturnOrder(PurchaseLine, true, false);
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
                        if GetSourcePurchaseLine() then
                            SubcPurchFactboxMgmt.ShowTransferOrdersAndReturnOrder(PurchaseLine, true, true);
                    end;
                }
            }
        }
    }
    var
        PurchaseLine: Record "Purchase Line";
        SubcProdOrderFactboxMgmt: Codeunit "Subc. ProdO. Factbox Mgmt.";
        SubcPurchFactboxMgmt: Codeunit "Subc. Purch. Factbox Mgmt.";

    local procedure GetSourcePurchaseLine(): Boolean
    begin
        if Rec."Source Type" <> Database::"Purchase Line" then
            exit(false);
        if (PurchaseLine."Document Type".AsInteger() = Rec."Source Subtype") and
           (PurchaseLine."Document No." = Rec."Source No.") and
           (PurchaseLine."Line No." = Rec."Source Line No.") then
            exit(true);
        exit(PurchaseLine.Get(Rec."Source Subtype", Rec."Source No.", Rec."Source Line No."));
    end;

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