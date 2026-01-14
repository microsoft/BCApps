// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.Document;
using Microsoft.Utilities;
using System.Utilities;

pageextension 99001524 "Sub. PO Subform" extends "Purchase Order Subform"
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
                ToolTip = 'Creates the production order belonging to the order for provision.';
                trigger OnAction()
                begin
                    Rec.TestStatusOpen();
                    CreateProductionOrder(Codeunit::"Sub. CrPurchSubcon(Yes/No)", true);
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
                    ToolTip = 'Specifies the depended Production Order of this Subcontracting Purchase Order.';
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
                action("Transfer Order")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Subcontracting Transfer Order';
                    Image = TransferOrder;
                    ToolTip = 'Specifies the depended Transfer Order of this Subcontracting Purchase Order.';
                    trigger OnAction()
                    begin
                        SubcontractingFactboxMgmt.ShowTransferOrdersAndReturnOrder(Rec, true, false);
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
                        SubcontractingFactboxMgmt.ShowTransferOrdersAndReturnOrder(Rec, true, true);
                    end;
                }
            }
        }
    }
    var
        SubcontractingFactboxMgmt: Codeunit "Sub. Factbox Mgmt.";

    local procedure CreateProductionOrder(CreatingCodeunitID: Integer; ShowCreatedDocument: Boolean)
    var
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ErrorMessageMgt: Codeunit "Error Message Management";
        InstructionMgt: Codeunit "Instruction Mgt.";
        NotificationMgt: Codeunit "Sub. Notification Mgmt.";
        ProdOrderCreated: Boolean;
    begin
        ErrorMessageMgt.Activate(ErrorMessageHandler);

        Commit(); // Used for following call of codeunit run
        ProdOrderCreated := Codeunit.Run(CreatingCodeunitID, Rec);

        if CreatingCodeunitID <> Codeunit::"Sub. CrPurchSubcon(Yes/No)" then
            exit;

        if ProdOrderCreated then begin
            if ShowCreatedDocument then
                if InstructionMgt.IsEnabled(NotificationMgt.ShowCreatedProductionOrderConfirmationMessageCode()) then
                    ShowCreatedProdOrderConfirmationMessage()
        end else
            ErrorMessageHandler.ShowErrors();
    end;

    local procedure ShowCreatedProdOrderConfirmationMessage()
    var
        ProdOrder: Record "Production Order";
        InstructionMgt: Codeunit "Instruction Mgt.";
        PageManagement: Codeunit "Page Management";
        NotificationMgt: Codeunit "Sub. Notification Mgmt.";
        OpenCreatedTransferOrderQst: Label 'The production order %1 was created from the current purchase order.\\Would you like to open the production order?', Comment = '%1=Production Order No.';
    begin
        ProdOrder.SetRange(Status, "Production Order Status"::Released);
        ProdOrder.SetRange("No.", Rec."Prod. Order No.");
        if ProdOrder.FindFirst() then
            if InstructionMgt.ShowConfirm(StrSubstNo(OpenCreatedTransferOrderQst, ProdOrder."No."),
              NotificationMgt.ShowCreatedProductionOrderConfirmationMessageCode()) then
                PageManagement.PageRun(ProdOrder);
    end;

    local procedure ShowProductionOrder(RecRelatedVariant: Variant)
    begin
        SubcontractingFactboxMgmt.ShowProductionOrder(RecRelatedVariant);
    end;

    local procedure ShowProductionOrderComponents(RecRelatedVariant: Variant)
    begin
        SubcontractingFactboxMgmt.ShowProductionOrderComponents(RecRelatedVariant);
    end;

    local procedure ShowProductionOrderRouting(RecRelatedVariant: Variant)
    begin
        SubcontractingFactboxMgmt.ShowProductionOrderRouting(RecRelatedVariant);
    end;
}