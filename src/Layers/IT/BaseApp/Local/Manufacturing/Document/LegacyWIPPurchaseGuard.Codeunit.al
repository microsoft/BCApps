#if not CLEANSCHEMA30
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Setup;

using Microsoft.Inventory;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;

codeunit 99008504 "Legacy WIP Purchase Guard"
{
    var
        ReopenLegacyWIPPurchaseLineErr: Label 'You cannot increase Quantity on a completed purchase line with a WIP Item after Legacy Subcontracting has been disabled.';
        UndoLegacyWIPPurchaseReceiptErr: Label 'You cannot undo receipt for a completed purchase line with a WIP Item after Legacy Subcontracting has been disabled.';

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnBeforeValidateQuantity', '', false, false)]
    local procedure PreventQuantityIncrease(var PurchaseLine: Record "Purchase Line"; var xPurchaseLine: Record "Purchase Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        if IsHandled or (CurrentFieldNo <> PurchaseLine.FieldNo(Quantity)) then
            exit;
        if IsLegacySubcontractingEnabled() then
            exit;
        if PurchaseLine."Document Type" <> PurchaseLine."Document Type"::Order then
            exit;
#pragma warning disable AL0432
        if not xPurchaseLine."WIP Item" then
#pragma warning restore AL0432
            exit;
        if xPurchaseLine."Outstanding Quantity" <> 0 then
            exit;
        if Abs(PurchaseLine.Quantity) > Abs(PurchaseLine."Quantity Received") then
            Error(ReopenLegacyWIPPurchaseLineErr);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Undo Purchase Receipt Line", 'OnBeforeCode', '', false, false)]
    local procedure PreventReceiptUndo(var PurchRcptLine: Record "Purch. Rcpt. Line"; var UndoPostingManagement: Codeunit "Undo Posting Management")
    var
        PurchaseLine: Record "Purchase Line";
        PurchRcptLineToCheck: Record "Purch. Rcpt. Line";
    begin
        if IsLegacySubcontractingEnabled() then
            exit;

        PurchRcptLineToCheck.Copy(PurchRcptLine);
        PurchRcptLineToCheck.SetFilter(Quantity, '<>0');
        PurchRcptLineToCheck.SetRange(Correction, false);
        if not PurchRcptLineToCheck.FindSet() then
            exit;

        repeat
            if PurchaseLine.Get(PurchaseLine."Document Type"::Order, PurchRcptLineToCheck."Order No.", PurchRcptLineToCheck."Order Line No.") then
#pragma warning disable AL0432
                if PurchaseLine."WIP Item" and (PurchaseLine."Outstanding Quantity" = 0) then
#pragma warning restore AL0432
                    Error(UndoLegacyWIPPurchaseReceiptErr);
        until PurchRcptLineToCheck.Next() = 0;
    end;

    local procedure IsLegacySubcontractingEnabled(): Boolean
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        if not ManufacturingSetup.Get() then
            exit(false);
#pragma warning disable AL0432
        exit(ManufacturingSetup."Legacy Subcontracting");
#pragma warning restore AL0432
    end;
}
#endif
