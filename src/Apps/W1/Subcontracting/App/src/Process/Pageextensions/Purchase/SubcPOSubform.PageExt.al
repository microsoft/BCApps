// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.Document;
using Microsoft.Utilities;
using System.Utilities;

pageextension 99001524 "Subc. PO Subform" extends "Purchase Order Subform"
{
    actions
    {
        addlast("F&unctions")
        {
            action(CreateProdOrder)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Create Production Order';
                Image = CreateSerialNo;
                ToolTip = 'Create the production order for the current purchase order.';
                trigger OnAction()
                begin
                    Rec.TestStatusOpen();
                    CreateProductionOrder(Codeunit::"Subc. CrPurchSubcon(Yes/No)", true);
                end;
            }
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

    local procedure CreateProductionOrder(CreatingCodeunitID: Integer; ShowCreatedDocument: Boolean)
    var
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ErrorMessageManagement: Codeunit "Error Message Management";
        InstructionMgt: Codeunit "Instruction Mgt.";
        SubcNotificationMgmt: Codeunit "Subc. Notification Mgmt.";
        ProdOrderCreated: Boolean;
    begin
        ErrorMessageManagement.Activate(ErrorMessageHandler);

        Commit(); // Used for following call of codeunit run
        ProdOrderCreated := Codeunit.Run(CreatingCodeunitID, Rec);

        if CreatingCodeunitID <> Codeunit::"Subc. CrPurchSubcon(Yes/No)" then
            exit;

        if ProdOrderCreated then begin
            if ShowCreatedDocument then
                if InstructionMgt.IsEnabled(SubcNotificationMgmt.ShowCreatedProductionOrderConfirmationMessageCode()) then
                    ShowCreatedProdOrderConfirmationMessage()
        end else
            ErrorMessageHandler.ShowErrors();
    end;

    local procedure ShowCreatedProdOrderConfirmationMessage()
    var
        ProductionOrder: Record "Production Order";
        InstructionMgt: Codeunit "Instruction Mgt.";
        PageManagement: Codeunit "Page Management";
        SubcNotificationMgmt: Codeunit "Subc. Notification Mgmt.";
        OpenCreatedTransferOrderQst: Label 'The production order %1 was created from the current purchase order.\\Would you like to open the production order?', Comment = '%1=Production Order No.';
    begin
        ProductionOrder.SetRange(Status, "Production Order Status"::Released);
        ProductionOrder.SetRange("No.", Rec."Prod. Order No.");
        if ProductionOrder.FindFirst() then
            if InstructionMgt.ShowConfirm(StrSubstNo(OpenCreatedTransferOrderQst, ProductionOrder."No."),
              SubcNotificationMgmt.ShowCreatedProductionOrderConfirmationMessageCode()) then
                PageManagement.PageRun(ProductionOrder);
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