// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Catalog;

using Microsoft.Service.Archive;
using Microsoft.Service.Document;
using Microsoft.Inventory.Item;

codeunit 6479 "Serv. Catalog Item Mgt."
{
    var
        CatalogItemManagement: Codeunit "Catalog Item Management";

    procedure DelNonStockFSM(var ServInvLine2: Record "Service Line")
    var
        NewItem: Record Item;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDelNonStockFSM(ServInvLine2, IsHandled);
#if not CLEAN25
        CatalogItemManagement.RunOnBeforeDelNonStockFSM(ServInvLine2, IsHandled);
#endif
        if IsHandled then
            exit;

        if ServInvLine2.Nonstock = false then
            exit;

        NewItem.Get(ServInvLine2."No.");
        ServInvLine2."No." := '';
        ServInvLine2.Modify();

        CatalogItemManagement.DelNonStockItem(NewItem);
    end;

    procedure NonStockFSM(var ServInvLine2: Record "Service Line")
    var
        NewItem: Record Item;
        NonStockItem: Record "Nonstock Item";
        IsHandled: Boolean;
    begin
        NonStockItem.Get(ServInvLine2."No.");
        if NonStockItem."Item No." <> '' then begin
            ServInvLine2."No." := NonStockItem."Item No.";
            exit;
        end;

        CatalogItemManagement.DetermineItemNoAndItemNoSeries(NonStockItem);
        NonStockItem.Modify();
        ServInvLine2."No." := NonStockItem."Item No.";
        OnNonStockFSMOnBeforeInsertItemUnitOfMeasure(NonStockItem);
#if not CLEAN25
        CatalogItemManagement.RunOnNonStockFSMOnBeforeInsertItemUnitOfMeasure(NonStockItem);
#endif
        CatalogItemManagement.InsertItemUnitOfMeasure(NonStockItem."Unit of Measure", ServInvLine2."No.");

        NewItem.SetRange("No.", ServInvLine2."No.");
        if NewItem.FindFirst() then
            exit;

        IsHandled := false;
        OnNonStockFSMOnBeforeProgWindowOpen(ServInvLine2, IsHandled);
#if not CLEAN25
        CatalogItemManagement.RunOnNonStockFSMOnBeforeProgWindowOpen(ServInvLine2, IsHandled);
#endif
        if not IsHandled and GuiAllowed() then
            CatalogItemManagement.OpenProgressDialog(NonStockItem, ServInvLine2."No.");

        CatalogItemManagement.CreateNewItem(NonStockItem);
        OnNonStockFSMOnAfterCreateNewItem(NewItem);
#if not CLEAN25
        CatalogItemManagement.RunOnNonStockFSMOnAfterCreateNewItem(NewItem);
#endif

        if CatalogItemManagement.CheckLicensePermission(DATABASE::"Item Vendor") then
            CatalogItemManagement.NonstockItemVend(NonStockItem);
        if CatalogItemManagement.CheckLicensePermission(DATABASE::"Item Reference") then
            CatalogItemManagement.NonstockItemReference(NonStockItem);

        IsHandled := false;
        OnNonStockFSMOnBeforeProgWindowClose(ServInvLine2, IsHandled);
#if not CLEAN25
        CatalogItemManagement.RunOnNonStockFSMOnBeforeProgWindowClose(IsHandled, ServInvLine2);
#endif
        if not IsHandled and GuiAllowed() then
            CatalogItemManagement.CloseProgressDialog();
    end;

    procedure DelNonStockServiceArch(var ServiceLineArchive: Record "Service Line Archive")
    var
        NewItem: Record Item;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDelNonStockServiceLineArchive(ServiceLineArchive, IsHandled);
        if IsHandled then
            exit;

        if NewItem.Get(ServiceLineArchive."No.") then begin
            ServiceLineArchive."No." := '';
            ServiceLineArchive.Modify();

            CatalogItemManagement.DelNonStockItem(NewItem);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Catalog Item Management", 'OnDelNonStockItemOnAfterCheckRelations', '', false, false)]
    local procedure OnDelNonStockItemOnAfterCheckRelations(var Item: Record Item; var ShouldExit: Boolean)
    var
        ServiceLine: Record "Service Line";
        ServiceLineArchive: Record "Service Line Archive";
    begin
        ServiceLine.SetCurrentKey(Type, "No.");
        ServiceLine.SetRange(Type, ServiceLine.Type::Item);
        ServiceLine.SetRange("No.", Item."No.");
        if not ServiceLine.IsEmpty() then
            ShouldExit := true;

        ServiceLineArchive.SetCurrentKey(Type, "No.");
        ServiceLineArchive.SetRange(Type, ServiceLine.Type::Item);
        ServiceLineArchive.SetRange("No.", Item."No.");
        if not ServiceLineArchive.IsEmpty() then
            ShouldExit := true;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnNonStockFSMOnAfterCreateNewItem(var NewItem: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnNonStockFSMOnBeforeInsertItemUnitOfMeasure(var NonStockItem: Record "Nonstock Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnNonStockFSMOnBeforeProgWindowOpen(var ServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDelNonStockFSM(var ServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnNonStockFSMOnBeforeProgWindowClose(ServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDelNonStockServiceLineArchive(var ServiceLineArchive: Record "Service Line Archive"; var IsHandled: Boolean)
    begin
    end;
}
