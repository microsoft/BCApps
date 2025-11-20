namespace Microsoft.API.Upgrade;

using Microsoft.Inventory.Item;
using Microsoft.Sales.Customer;
using Microsoft.Purchases.Vendor;
using Microsoft.Integration.Graph;
using Microsoft.Finance.Dimension;
using Microsoft.Sales.History;
using Microsoft.Purchases.History;

codeunit 5152 "API - Update Referenced Fields"
{
    SingleInstance = true;
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Table, Database::"Item", 'OnBeforeInsertEvent', '', false, false)]
    local procedure UpdateReferencedIdsItemOnInsert(var Rec: Record Item; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;
        Rec.UpdateReferencedIds();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Customer", 'OnBeforeInsertEvent', '', false, false)]
    local procedure UpdateReferencedIdsCustomerOnInsert(var Rec: Record Customer; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;
        Rec.UpdateReferencedIds();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor", 'OnBeforeInsertEvent', '', false, false)]
    local procedure UpdateReferencedIdsVendorOnInsert(var Rec: Record Vendor; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;
        Rec.UpdateReferencedIds();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item", 'OnBeforeModifyEvent', '', false, false)]
    local procedure UpdateReferencedIdsItemOnModify(var Rec: Record Item; var xRec: Record Item; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;
        if GetExecutionContext() = ExecutionContext::Upgrade then
            exit;
        Rec.UpdateReferencedIds();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Customer", 'OnBeforeModifyEvent', '', false, false)]
    local procedure UpdateReferencedIdsCustomerOnModify(var Rec: Record Customer; var xRec: Record Customer; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;
        Rec.UpdateReferencedIds();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor", 'OnBeforeModifyEvent', '', false, false)]
    local procedure UpdateReferencedIdsVendorOnModify(var Rec: Record Vendor; var xRec: Record Vendor; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;
        Rec.UpdateReferencedIds();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Unlinked Attachment", 'OnBeforeInsertEvent', '', false, false)]
    local procedure UpdateIdUnlinkedAttachmentOnInsert(var Rec: Record "Unlinked Attachment"; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary() then
            exit;

        Rec.Id := Rec.SystemId;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Default Dimension", 'OnBeforeInsertEvent', '', false, false)]
    local procedure UpdateIdDefaultDimensionOnInsert(var Rec: Record "Default Dimension"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;
        Rec.UpdateReferencedIdFields();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Variant", 'OnBeforeInsertEvent', '', false, false)]
    local procedure UpdateReferencedIdsItemVariantOnInsert(var Rec: Record "Item Variant"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;
        Rec.UpdateReferencedIds();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Variant", 'OnBeforeRenameEvent', '', false, false)]
    local procedure UpdateReferencedIdsItemVariantOnRename(var Rec: Record "Item Variant"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;
        Rec.UpdateReferencedIds();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Shipment Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure UpdateReferencedIdsSalesShipmentLineOnInsert(var Rec: Record "Sales Shipment Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;
        Rec.UpdateReferencedIds();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purch. Rcpt. Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure UpdateReferencedIdsPurchRcptLineOnInsert(var Rec: Record "Purch. Rcpt. Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;
        Rec.UpdateReferencedIds();
    end;
}