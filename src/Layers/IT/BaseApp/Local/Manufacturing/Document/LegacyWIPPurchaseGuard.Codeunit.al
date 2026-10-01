// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Setup;

using Microsoft.Inventory;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;

codeunit 99001048 "Legacy WIP Purchase Guard"
{
    Access = Internal;

    var
        ReopenLegacyWIPPurchaseLineErr: Label 'You cannot increase Quantity on a completed purchase line with a WIP Item after Legacy Subcontracting has been disabled.';
        UndoLegacyWIPPurchaseReceiptErr: Label 'You cannot undo receipt for a completed purchase line with a WIP Item after Legacy Subcontracting has been disabled.';

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnBeforeValidateQuantity', '', false, false)]
    local procedure PreventQuantityIncrease(var PurchaseLine: Record "Purchase Line"; var xPurchaseLine: Record "Purchase Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        if IsHandled or (CurrentFieldNo <> PurchaseLine.FieldNo(Quantity)) then
            exit;
        if PurchaseLine."Document Type" <> PurchaseLine."Document Type"::Order then
            exit;
        if not IsWIPItem(PurchaseLine) then
            exit;
        if xPurchaseLine."Outstanding Quantity" <> 0 then
            exit;
        if IsLegacySubcontractingEnabled() then
            exit;
        if Abs(PurchaseLine.Quantity) > Abs(PurchaseLine."Quantity Received") then
            Error(ReopenLegacyWIPPurchaseLineErr);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Undo Purchase Receipt Line", 'OnBeforeCode', '', false, false)]
    local procedure PreventReceiptUndo(var PurchRcptLine: Record "Purch. Rcpt. Line"; var UndoPostingManagement: Codeunit "Undo Posting Management")
    var
        PurchaseLine: Record "Purchase Line";
        PurchRcptLineToCheck: Record "Purch. Rcpt. Line";
        CheckedPurchaseLines: Dictionary of [Text, Boolean];
        PurchaseLineKey: Text;
    begin
        PurchRcptLineToCheck.Copy(PurchRcptLine);
        PurchRcptLineToCheck.SetFilter(Quantity, '<>0');
        PurchRcptLineToCheck.SetRange(Correction, false);
        PurchRcptLineToCheck.SetLoadFields("Order No.", "Order Line No.");
        if not PurchRcptLineToCheck.FindSet() then
            exit;
        if IsLegacySubcontractingEnabled() then
            exit;

        repeat
            PurchaseLineKey := StrSubstNo('%1|%2', PurchRcptLineToCheck."Order No.", PurchRcptLineToCheck."Order Line No.");
            if not CheckedPurchaseLines.ContainsKey(PurchaseLineKey) then begin
                CheckedPurchaseLines.Add(PurchaseLineKey, true);
                PurchaseLine.SetLoadFields("Outstanding Quantity");
                if PurchaseLine.Get(PurchaseLine."Document Type"::Order, PurchRcptLineToCheck."Order No.", PurchRcptLineToCheck."Order Line No.") and
                   IsWIPItem(PurchaseLine) and (PurchaseLine."Outstanding Quantity" = 0)
                then
                    Error(UndoLegacyWIPPurchaseReceiptErr);
            end;
        until PurchRcptLineToCheck.Next() = 0;
    end;

    local procedure IsLegacySubcontractingEnabled(): Boolean
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ManufacturingSetupRecordRef: RecordRef;
        LegacySubcontractingFieldRef: FieldRef;
    begin
        if not ManufacturingSetup.Get() then
            exit(false);

        ManufacturingSetupRecordRef.GetTable(ManufacturingSetup);
        if not ManufacturingSetupRecordRef.FieldExist(GetLegacySubcontractingFieldNo()) then
            exit(false);

        LegacySubcontractingFieldRef := ManufacturingSetupRecordRef.Field(GetLegacySubcontractingFieldNo());
        exit(LegacySubcontractingFieldRef.Value);
    end;

    local procedure IsWIPItem(PurchaseLine: Record "Purchase Line"): Boolean
    var
        PurchaseLineRecordRef: RecordRef;
        WIPItemFieldRef: FieldRef;
    begin
        PurchaseLineRecordRef.GetTable(PurchaseLine);
        if not PurchaseLineRecordRef.FieldExist(GetWIPItemFieldNo()) then
            exit(false);

        WIPItemFieldRef := PurchaseLineRecordRef.Field(GetWIPItemFieldNo());
        exit(WIPItemFieldRef.Value);
    end;

    local procedure GetLegacySubcontractingFieldNo(): Integer
    begin
        exit(5600);
    end;

    local procedure GetWIPItemFieldNo(): Integer
    begin
        exit(12180);
    end;
}
