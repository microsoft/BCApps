// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Requisition;

codeunit 99000814 "Requisition Line Management"
{
    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnBeforeModifyEvent', '', false, false)]
    local procedure ClearTargetWhenActionChanges(var Rec: Record "Requisition Line"; var xRec: Record "Requisition Line"; RunTrigger: Boolean)
    begin
        if xRec.HasPurchaseOrderTarget() and (Rec."Action Message" <> Rec."Action Message"::New) and
           (Rec."Ref. Order No." = xRec."Ref. Order No.") and (Rec."Ref. Line No." = xRec."Ref. Line No.")
        then
            Rec.ClearPurchaseOrderTarget();
    end;
}