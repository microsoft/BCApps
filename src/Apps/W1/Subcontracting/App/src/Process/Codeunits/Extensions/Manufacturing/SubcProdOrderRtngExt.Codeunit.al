// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.WorkCenter;
using System.Utilities;

codeunit 99001520 "Subc. Prod. Order Rtng. Ext."
{
    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Routing Line", OnAfterDeleteEvent, '', false, false)]
    local procedure OnAfterDeleteProdOrderRtngLine(var Rec: Record "Prod. Order Routing Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary then
            exit;

        if not RunTrigger then
            exit;

        HandleSubcontractingAfterRoutingLineDelete(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Routing Line", OnBeforeValidateEvent, "No.", false, false)]
    local procedure OnBeforeValidateNo(var Rec: Record "Prod. Order Routing Line"; var xRec: Record "Prod. Order Routing Line"; CurrFieldNo: Integer)
    var
        SubcontractingManagement: Codeunit "Subcontracting Management";
    begin
        if Rec.IsTemporary then
            exit;

        if (xRec."No." <> Rec."No.") and (Rec."Routing Link Code" <> '') then
            SubcontractingManagement.UpdLinkedComponents(Rec, true);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Routing Line", OnAfterValidateEvent, "Routing Link Code", false, false)]
    local procedure OnAfterValidateRoutingLinkCode(var Rec: Record "Prod. Order Routing Line"; var xRec: Record "Prod. Order Routing Line"; CurrFieldNo: Integer)
    begin
        if Rec.IsTemporary then
            exit;
        HandleRoutingLinkCodeValidation(Rec, xRec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Routing Line", OnAfterValidateEvent, "Standard Task Code", false, false)]
    local procedure OnAfterValidateStandardTaskCode(var Rec: Record "Prod. Order Routing Line"; var xRec: Record "Prod. Order Routing Line"; CurrFieldNo: Integer)
    var
        SubcPriceManagement: Codeunit "Subc. Price Management";
    begin
        if Rec.IsTemporary then
            exit;
        SubcPriceManagement.GetSubcPriceList(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Routing Line", OnAfterWorkCenterTransferFields, '', false, false)]
    local procedure OnAfterWorkCenterTransferFields(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; WorkCenter: Record "Work Center")
    var
        SubcPriceManagement: Codeunit "Subc. Price Management";
    begin
        SubcPriceManagement.GetSubcPriceList(ProdOrderRoutingLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Prod. Order Route Management", OnCalculateOnBeforeProdOrderRtngLineLoopIteration, '', false, false)]
    local procedure CheckSubcontractingOnCalculateOnBeforeProdOrderRtngLineLoopIteration(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var ProdOrderLine: Record "Prod. Order Line"; var IsHandled: Boolean)
    begin
        ProdOrderRoutingLine.CheckForSubcontractingPurchaseLineTypeMismatch();
    end;

    local procedure HandleRoutingLinkCodeValidation(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var xProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        ProdOrderRoutingLine2: Record "Prod. Order Routing Line";
        ConfirmManagement: Codeunit "Confirm Management";
        SubcontractingManagement: Codeunit "Subcontracting Management";
        UpdateCanceledErr: Label 'Update cancelled.';
        UpdateRoutingQst: Label '%1 %2 used more than once on this Routing. Do you want to update it anyway?', Comment = '%1=Field Caption, %2=Routing Link Code';
    begin
        ProdOrderRoutingLine2 := ProdOrderRoutingLine;
        ProdOrderRoutingLine2.SetRecFilter();
        ProdOrderRoutingLine2.SetRange("Operation No.");
        ProdOrderRoutingLine2.SetRange("Routing Link Code", ProdOrderRoutingLine."Routing Link Code");
        if not ProdOrderRoutingLine2.IsEmpty() then
            if not ConfirmManagement.GetResponse(StrSubstNo(UpdateRoutingQst, ProdOrderRoutingLine.FieldCaption(ProdOrderRoutingLine."Routing Link Code"), ProdOrderRoutingLine."Routing Link Code"), false) then
                Error(UpdateCanceledErr);

        if ProdOrderRoutingLine."Routing Link Code" <> xProdOrderRoutingLine."Routing Link Code" then
            if xProdOrderRoutingLine."Routing Link Code" <> '' then begin
                SubcontractingManagement.DelLocationLinkedComponents(xProdOrderRoutingLine, true);
                if ProdOrderRoutingLine."Routing Link Code" <> '' then
                    SubcontractingManagement.UpdLinkedComponents(ProdOrderRoutingLine, false);
            end else
                if ProdOrderRoutingLine."Routing Link Code" <> '' then
                    SubcontractingManagement.UpdLinkedComponents(ProdOrderRoutingLine, true);
    end;

    local procedure HandleSubcontractingAfterRoutingLineDelete(var ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        WorkCenter: Record "Work Center";
        SubcontractingManagement: Codeunit "Subcontracting Management";
    begin
        if ProdOrderRoutingLine.Status = ProdOrderRoutingLine.Status::Released then
            if ProdOrderRoutingLine.Type = ProdOrderRoutingLine.Type::"Work Center" then begin
                WorkCenter.SetLoadFields("Subcontractor No.");
                if WorkCenter.Get(ProdOrderRoutingLine."No.") then
                    if (ProdOrderRoutingLine."Routing Link Code" <> '') and (WorkCenter."Subcontractor No." <> '') then
                        SubcontractingManagement.DelLocationLinkedComponents(ProdOrderRoutingLine, false);
            end;
    end;
}