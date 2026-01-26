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
                    ToolTip = 'Specifies the depended Production Order of this Subcontracting Purchase Order.';
                    trigger OnAction()
                    begin
                        if Rec."Source Type" = Database::"Purchase Line" then
                            if PurchaseLine.Get(Rec."Source Subtype", Rec."Source No.", Rec."Source Line No.") then
                                ShowProductionOrder(PurchaseLine);
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
                        if Rec."Source Type" = Database::"Purchase Line" then
                            if PurchaseLine.Get(Rec."Source Subtype", Rec."Source No.", Rec."Source Line No.") then
                                ShowProductionOrderRouting(PurchaseLine);
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
                        if Rec."Source Type" = Database::"Purchase Line" then
                            if PurchaseLine.Get(Rec."Source Subtype", Rec."Source No.", Rec."Source Line No.") then
                                ShowProductionOrderComponents(PurchaseLine);
                    end;
                }
                action("Transfer Order")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Subcontracting Transfer Order';
                    Image = TransferOrder;
                    ToolTip = 'Specifies the depended Transfer Order of this Subcontracting Purchase Order.';
                    trigger OnAction()
                    begin
                        if Rec."Source Type" = Database::"Purchase Line" then
                            if PurchaseLine.Get(Rec."Source Subtype", Rec."Source No.", Rec."Source Line No.") then
                                SubcFactboxMgmt.ShowTransferOrdersAndReturnOrder(Rec, true, false);
                    end;
                }
                action("Return Transfer Order")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Subcontracting Return Transfer Order';
                    Image = ReturnRelated;
                    ToolTip = 'Specifies the depended Return Transfer Order of this Subcontracting Purchase Order.';
                    trigger OnAction()
                    begin
                        if Rec."Source Type" = Database::"Purchase Line" then
                            if PurchaseLine.Get(Rec."Source Subtype", Rec."Source No.", Rec."Source Line No.") then
                                SubcFactboxMgmt.ShowTransferOrdersAndReturnOrder(Rec, true, true);
                    end;
                }
            }
        }
    }
    var
        PurchaseLine: Record "Purchase Line";
        SubcFactboxMgmt: Codeunit "Subc. Factbox Mgmt.";

    local procedure ShowProductionOrder(RecRelatedVariant: Variant)
    begin
        SubcFactboxMgmt.ShowProductionOrder(RecRelatedVariant);
    end;

    local procedure ShowProductionOrderComponents(RecRelatedVariant: Variant)
    begin
        SubcFactboxMgmt.ShowProductionOrderComponents(RecRelatedVariant);
    end;

    local procedure ShowProductionOrderRouting(RecRelatedVariant: Variant)
    begin
        SubcFactboxMgmt.ShowProductionOrderRouting(RecRelatedVariant);
    end;
}