// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.ProductionBOM;

codeunit 9132 "Check Prod. Order Document"
{
    var
        CannotChangeItemWithOutstandingDocumentLinesErr: Label 'You cannot delete %1 %2 because there are one or more outstanding production orders that include this item.', Comment = '%1 - Item, %2 - Item No.';
        CannotChangeItemWithProductionComponentsErr: Label 'You cannot delete %1 %2 because there are one or more production order component lines that include this item with a remaining quantity that is not 0.', Comment = '%1 - Item, %2 - Item No.';
        CannotDeleteItemIfProdBOMVersionExistsErr: Label 'You cannot delete %1 %2 because there are one or more certified production BOM version that include this item.', Comment = '%1 - Tablecaption, %2 - No.';
        CannotDeleteItemIfCertifiedProdBOMLineExistsErr: Label 'You cannot delete %1 %2 because there are one or more certified Production BOM that include this item.', Comment = '%1 - Tablecaption, %2 - No.';

    [EventSubscriber(ObjectType::Table, Database::Item, 'OnAfterCheckDocuments', '', false, false)]
    local procedure ItemOnBeforeCheckDocuments(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text);
    begin
        CheckProdOrderLines(Item, CurrentFieldNo, CheckFieldNo, CheckFieldCaption);
        CheckProdOrderComponents(Item, CurrentFieldNo, CheckFieldNo, CheckFieldCaption);
        CheckProdBOMLines(Item, CurrentFieldNo, CheckFieldNo, CheckFieldCaption);
    end;

    internal procedure CheckProdOrderLines(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text)
    var
        ProdOrderLine: Record "Prod. Order Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckProdOrderLines(Item, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
#if not CLEAN25
        Item.RunOnBeforeCheckProdOrderLine(Item, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
#endif
        if IsHandled then
            exit;

        ProdOrderLine.SetCurrentKey(Status, "Item No.");
        ProdOrderLine.SetFilter(Status, '..%1', ProdOrderLine.Status::Released);
        ProdOrderLine.SetRange("Item No.", Item."No.");
        if not ProdOrderLine.IsEmpty() then begin
            if CurrentFieldNo = 0 then
                Error(
                    CannotChangeItemWithOutstandingDocumentLinesErr, Item.TableCaption(), Item."No.");
            if CurrentFieldNo = CheckFieldNo then
                Error(
                    Item.GetCannotChangeItemWithExistingDocumentLinesErr(),
                    CheckFieldCaption, Item.TableCaption(), Item."No.", ProdOrderLine.TableCaption());
        end;
    end;

    internal procedure CheckProdOrderComponents(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text)
    var
        ProdOrderComponent: Record "Prod. Order Component";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckProdOrderComponents(Item, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
#if not CLEAN25
        Item.RunOnBeforeCheckProdOrderCompLine(Item, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
#endif
        if IsHandled then
            exit;

        ProdOrderComponent.SetCurrentKey(Status, "Item No.");
        ProdOrderComponent.SetFilter(Status, '..%1', ProdOrderComponent.Status::Released);
        ProdOrderComponent.SetRange("Item No.", Item."No.");
        if not ProdOrderComponent.IsEmpty() then begin
            if CurrentFieldNo = 0 then
                Error(
                    CannotChangeItemWithProductionComponentsErr, Item.TableCaption(), Item."No.");
            if CurrentFieldNo = CheckFieldNo then
                Error(
                    Item.GetCannotChangeItemWithExistingDocumentLinesErr(),
                    CheckFieldCaption, Item.TableCaption(), Item."No.", ProdOrderComponent.TableCaption());
        end;
    end;

    internal procedure CheckProdBOMLines(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text)
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionBOMVersion: Record "Production BOM Version";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckProdBOMLines(Item, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
#if not CLEAN25
        Item.RunOnBeforeCheckProdBOMLine(Item, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
#endif
        if IsHandled then
            exit;

        ProductionBOMLine.Reset();
        ProductionBOMLine.SetCurrentKey(Type, "No.");
        ProductionBOMLine.SetRange(Type, ProductionBOMLine.Type::Item);
        ProductionBOMLine.SetRange("No.", Item."No.");
        if ProductionBOMLine.Find('-') then begin
            if CurrentFieldNo = CheckFieldNo then
                Error(
                    Item.GetCannotChangeItemWithExistingDocumentLinesErr(),
                    CheckFieldCaption, Item.TableCaption(), Item."No.", ProductionBOMLine.TableCaption());
            if CurrentFieldNo = 0 then
                repeat
                    if ProductionBOMHeader.Get(ProductionBOMLine."Production BOM No.") and
                       (ProductionBOMHeader.Status = ProductionBOMHeader.Status::Certified)
                    then
                        Error(
                            CannotDeleteItemIfCertifiedProdBOMLineExistsErr, Item.TableCaption(), Item."No.");
                    if ProductionBOMVersion.Get(ProductionBOMLine."Production BOM No.", ProductionBOMLine."Version Code") and
                       (ProductionBOMVersion.Status = ProductionBOMVersion.Status::Certified)
                    then
                        Error(
                            CannotDeleteItemIfProdBOMVersionExistsErr, Item.TableCaption(), Item."No.");
                until ProductionBOMLine.Next() = 0;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckProdOrderLines(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckProdOrderComponents(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckProdBOMLines(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
    end;
}
