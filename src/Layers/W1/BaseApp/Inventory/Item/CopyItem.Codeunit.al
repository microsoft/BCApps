// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Comment;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Item.Attribute;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Setup;
using Microsoft.Pricing.PriceList;
using Microsoft.Purchases.Pricing;
using Microsoft.Sales.Pricing;
using System.Environment.Configuration;

codeunit 730 "Copy Item"
{
    TableNo = Item;

    trigger OnRun()
    var
        CopyItemPage: Page "Copy Item";
        IsItemCopied: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeOnRun(Rec, FirstItemNo, LastItemNo, IsItemCopied, IsHandled);
        if IsHandled then begin
            if IsItemCopied then
                ShowNotification(Rec);
            exit;
        end;

        CopyItemPage.SetItem(Rec);
        if CopyItemPage.RunModal() <> ACTION::OK then
            exit;

        CopyItemPage.GetParameters(TempCopyItemBuffer);

        DoCopyItem();

        OnRunOnAfterItemCopied(TempCopyItemBuffer);

        if TempCopyItemBuffer."Show Created Items" then
            ShowCreatedItems()
        else
            ShowNotification(Rec);
    end;

    var
        SourceItem: Record Item;
        TempCopyItemBuffer: Record "Copy Item Buffer" temporary;
        InventorySetup: Record "Inventory Setup";
        FirstItemNo: Code[20];
        LastItemNo: Code[20];
        TargetItemDoesNotExistErr: Label 'Target item number %1 already exists.', Comment = '%1 - item number.';
        ItemCopiedMsg: Label 'Item %1 was successfully copied.', Comment = '%1 - item number';
        ShowCreatedItemTxt: Label 'Show created item.';
        ShowCreatedItemsTxt: Label 'Show created items.';

    procedure DoCopyItem()
    var
        i: Integer;
    begin
        InventorySetup.Get();
        SourceItem.LockTable();
        SourceItem.Get(TempCopyItemBuffer."Source Item No.");

        for i := 1 to TempCopyItemBuffer."Number of Copies" do
            CopyItem(i);
    end;

    procedure SetCopyItemBuffer(NewCopyItemBuffer: Record "Copy Item Buffer" temporary)
    begin
        TempCopyItemBuffer := NewCopyItemBuffer;
        if SourceItem."No." <> TempCopyItemBuffer."Source Item No." then
            SourceItem.Get(TempCopyItemBuffer."Source Item No.");
    end;

    local procedure SetTargetItemNo(var TargetItem: Record Item; CopyCounter: Integer)
    var
        NoSeries: Codeunit "No. Series";
    begin
        if TempCopyItemBuffer."Target No. Series" <> '' then begin
            OnBeforeInitSeries(SourceItem, InventorySetup);
            InventorySetup.TestField("Item Nos.");
            TargetItem."No." := NoSeries.GetNextNo(TempCopyItemBuffer."Target No. Series");
            TargetItem."No. Series" := TempCopyItemBuffer."Target No. Series";
        end else begin
            NoSeries.TestManual(InventorySetup."Item Nos.");

            if CopyCounter > 1 then
                TempCopyItemBuffer."Target Item No." := IncStr(TempCopyItemBuffer."Target Item No.");
            TargetItem."No." := TempCopyItemBuffer."Target Item No.";
        end;

        CheckExistingItem(TargetItem."No.");

        if CopyCounter = 1 then
            FirstItemNo := TargetItem."No.";
        LastItemNo := TargetItem."No.";
    end;

    local procedure InitTargetItem(var TargetItem: Record Item; CopyCounter: Integer)
    begin
        TargetItem.TransferFields(SourceItem);

        SetTargetItemNo(TargetItem, CopyCounter);

        TargetItem."Last Date Modified" := Today;
        TargetItem."Created From Nonstock Item" := false;
        TargetItem."Cost is Adjusted" := true;
    end;

    procedure CopyItem(CopyCounter: Integer)
    var
        TargetItem: Record Item;
    begin
        OnBeforeCopyItem(SourceItem, TargetItem, CopyCounter, TempCopyItemBuffer);

        InitTargetItem(TargetItem, CopyCounter);

        if not (TempCopyItemBuffer."Sales Line Discounts" or TempCopyItemBuffer."Purchase Line Discounts") then
            TargetItem."Item Disc. Group" := '';

        CopyItemPicture(SourceItem, TargetItem);
        CopyItemUnisOfMeasure(SourceItem, TargetItem);
        CopyItemGlobalDimensions(SourceItem, TargetItem);
        OnCopyItemOnBeforeTargetItemInsert(SourceItem, TargetItem, CopyCounter, TempCopyItemBuffer);
        TargetItem.Insert();

        CopyExtendedTexts(SourceItem."No.", TargetItem);
        CopyItemDimensions(SourceItem, TargetItem."No.");
        CopyItemVariants(SourceItem."No.", TargetItem."No.", TargetItem.SystemId);
        CopyItemTranslations(SourceItem."No.", TargetItem."No.");
        CopyItemComments(SourceItem."No.", TargetItem."No.");
        CopyBOMComponents(SourceItem."No.", TargetItem."No.");
        CopyItemVendors(SourceItem."No.", TargetItem."No.");
        CopyItemPriceListLines(SourceItem."No.", TargetItem."No.");
        CopyItemSalesPrices(SourceItem."No.", TargetItem."No.");
        CopySalesLineDiscounts(SourceItem."No.", TargetItem."No.");
        CopyPurchasePrices(SourceItem."No.", TargetItem."No.");
        CopyPurchaseLineDiscounts(SourceItem."No.", TargetItem."No.");
        CopyItemAttributes(SourceItem."No.", TargetItem."No.");
        CopyItemReferences(SourceItem."No.", TargetItem."No.");

        OnAfterCopyItem(TempCopyItemBuffer, SourceItem, TargetItem);
    end;

    local procedure CheckExistingItem(ItemNo: Code[20])
    var
        Item: Record Item;
    begin
        if Item.Get(ItemNo) then
            Error(TargetItemDoesNotExistErr, ItemNo);
    end;

    local procedure CopyItemPicture(FromItem: Record Item; var ToItem: Record Item)
    begin
        if TempCopyItemBuffer.Picture then
            ToItem.Picture := FromItem.Picture
        else
            Clear(ToItem.Picture);
    end;

    procedure CopyItemRelatedTable(TableId: Integer; FieldNo: Integer; FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        SourceRecRef: RecordRef;
        TargetRecRef: RecordRef;
        SourceFieldRef: FieldRef;
        TargetFieldRef: FieldRef;
    begin
        SourceRecRef.Open(TableId);
        SourceFieldRef := SourceRecRef.Field(FieldNo);
        SourceFieldRef.SetRange(FromItemNo);
        if SourceRecRef.FindSet() then
            repeat
                TargetRecRef := SourceRecRef.Duplicate();
                TargetFieldRef := TargetRecRef.Field(FieldNo);
                TargetFieldRef.Value(ToItemNo);
                TargetRecRef.Insert();
            until SourceRecRef.Next() = 0;
    end;

    procedure CopyItemRelatedTableFromRecRef(var SourceRecRef: RecordRef; FieldNo: Integer; FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        TargetRecRef: RecordRef;
        SourceFieldRef: FieldRef;
        TargetFieldRef: FieldRef;
    begin
        SourceFieldRef := SourceRecRef.Field(FieldNo);
        SourceFieldRef.SetRange(FromItemNo);
        if SourceRecRef.FindSet() then
            repeat
                TargetRecRef := SourceRecRef.Duplicate();
                TargetFieldRef := TargetRecRef.Field(FieldNo);
                TargetFieldRef.Value(ToItemNo);
                TargetRecRef.Insert();
            until SourceRecRef.Next() = 0;
    end;

    local procedure CopyItemComments(FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        CommentLine: Record "Comment Line";
        RecRef: RecordRef;
    begin
        if not TempCopyItemBuffer.Comments then
            exit;

        CommentLine.SetRange("Table Name", CommentLine."Table Name"::Item);

        RecRef.GetTable(CommentLine);
        CopyItemRelatedTableFromRecRef(RecRef, CommentLine.FieldNo("No."), FromItemNo, ToItemNo);
    end;

    local procedure CopyItemUnisOfMeasure(FromItem: Record Item; var ToItem: Record Item)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        RecRef: RecordRef;
    begin
        if TempCopyItemBuffer."Units of Measure" then begin
            ItemUnitOfMeasure.SetRange("Item No.", FromItem."No.");
            RecRef.GetTable(ItemUnitOfMeasure);
            CopyItemRelatedTableFromRecRef(RecRef, ItemUnitOfMeasure.FieldNo("Item No."), FromItem."No.", ToItem."No.");
        end else begin
            ToItem."Base Unit of Measure" := '';
            ToItem."Sales Unit of Measure" := '';
            ToItem."Purch. Unit of Measure" := '';
            ToItem."Put-away Unit of Measure Code" := '';
        end;
    end;

    local procedure CopyItemVariants(FromItemNo: Code[20]; ToItemNo: Code[20]; ToItemId: Guid)
    var
        ItemVariant: Record "Item Variant";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyItemVariants(TempCopyItemBuffer, FromItemNo, ToItemNo, IsHandled);
        if IsHandled then
            exit;

        if not TempCopyItemBuffer."Item Variants" then
            exit;

        CopyItemRelatedTable(Database::"Item Variant", ItemVariant.FieldNo("Item No."), FromItemNo, ToItemNo);
        ItemVariant.SetRange("Item No.", ToItemNo);
        if not ItemVariant.IsEmpty() then
            ItemVariant.ModifyAll("Item Id", ToItemId);
    end;

    local procedure CopyItemTranslations(FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        ItemTranslation: Record "Item Translation";
        RecRef: RecordRef;
    begin
        if not TempCopyItemBuffer.Translations then
            exit;

        ItemTranslation.SetRange("Item No.", FromItemNo);
        if not TempCopyItemBuffer."Item Variants" then
            ItemTranslation.SetRange("Variant Code", '');

        RecRef.GetTable(ItemTranslation);
        CopyItemRelatedTableFromRecRef(RecRef, ItemTranslation.FieldNo("Item No."), FromItemNo, ToItemNo);
    end;

    local procedure CopyExtendedTexts(FromItemNo: Code[20]; var TargetItem: Record Item)
    var
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
        NewExtendedTextHeader: Record "Extended Text Header";
        NewExtendedTextLine: Record "Extended Text Line";
    begin
        if not TempCopyItemBuffer."Extended Texts" then
            exit;

        ExtendedTextHeader.SetRange("Table Name", ExtendedTextHeader."Table Name"::Item);
        ExtendedTextHeader.SetRange("No.", FromItemNo);
        if ExtendedTextHeader.FindSet() then
            repeat
                ExtendedTextLine.SetRange("Table Name", ExtendedTextHeader."Table Name");
                ExtendedTextLine.SetRange("No.", ExtendedTextHeader."No.");
                ExtendedTextLine.SetRange("Language Code", ExtendedTextHeader."Language Code");
                ExtendedTextLine.SetRange("Text No.", ExtendedTextHeader."Text No.");
                if ExtendedTextLine.FindSet() then
                    repeat
                        NewExtendedTextLine.TransferFields(ExtendedTextLine);
                        NewExtendedTextLine."No." := TargetItem."No.";
                        NewExtendedTextLine.Insert();
                    until ExtendedTextLine.Next() = 0;

                NewExtendedTextHeader.TransferFields(ExtendedTextHeader);
                NewExtendedTextHeader."No." := TargetItem."No.";
                NewExtendedTextHeader.Insert();
            until ExtendedTextHeader.Next() = 0;

        OnAfterCopyExtendedTexts(SourceItem, TargetItem);
    end;

    local procedure CopyBOMComponents(FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        BOMComponent: Record "BOM Component";
    begin
        if not TempCopyItemBuffer."BOM Components" then
            exit;

        CopyItemRelatedTable(Database::"BOM Component", BOMComponent.FieldNo("Parent Item No."), FromItemNo, ToItemNo);
    end;

    local procedure CopyItemVendors(FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        ItemVendor: Record "Item Vendor";
    begin
        if not TempCopyItemBuffer."Item Vendors" then
            exit;

        CopyItemRelatedTable(Database::"Item Vendor", ItemVendor.FieldNo("Item No."), FromItemNo, ToItemNo);
    end;

    local procedure CopyItemDimensions(FromItem: Record Item; ToItemNo: Code[20])
    var
        DefaultDim: Record "Default Dimension";
        NewDefaultDim: Record "Default Dimension";
    begin
        if TempCopyItemBuffer.Dimensions then begin
            DefaultDim.SetRange("Table ID", Database::Item);
            DefaultDim.SetRange("No.", FromItem."No.");
            if DefaultDim.FindSet() then
                repeat
                    NewDefaultDim.TransferFields(DefaultDim);
                    NewDefaultDim."No." := ToItemNo;
                    NewDefaultDim.Insert();
                until DefaultDim.Next() = 0;
        end;
    end;

    local procedure CopyItemGlobalDimensions(FromItem: Record Item; var ToItem: Record Item)
    begin
        if TempCopyItemBuffer.Dimensions then begin
            ToItem."Global Dimension 1 Code" := FromItem."Global Dimension 1 Code";
            ToItem."Global Dimension 2 Code" := FromItem."Global Dimension 2 Code";
        end else begin
            ToItem."Global Dimension 1 Code" := '';
            ToItem."Global Dimension 2 Code" := '';
        end;
    end;

    local procedure CopyItemPriceListLines(FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyItemPriceListLines(FromItemNo, ToItemNo, IsHandled);
        if IsHandled then
            exit;

        if TempCopyItemBuffer."Sales Prices" then
            CopyItemPriceListLines(FromItemNo, ToItemNo, Enum::"Price Type"::Sale, Enum::"Price Amount Type"::Price);
        if TempCopyItemBuffer."Sales Line Discounts" then
            CopyItemPriceListLines(FromItemNo, ToItemNo, Enum::"Price Type"::Sale, Enum::"Price Amount Type"::Discount);
        if TempCopyItemBuffer."Sales Prices" or TempCopyItemBuffer."Sales Line Discounts" then
            CopyItemPriceListLines(FromItemNo, ToItemNo, Enum::"Price Type"::Sale, Enum::"Price Amount Type"::Any);

        if TempCopyItemBuffer."Purchase Prices" then
            CopyItemPriceListLines(FromItemNo, ToItemNo, Enum::"Price Type"::Purchase, Enum::"Price Amount Type"::Price);
        if TempCopyItemBuffer."Purchase Line Discounts" then
            CopyItemPriceListLines(FromItemNo, ToItemNo, Enum::"Price Type"::Purchase, Enum::"Price Amount Type"::Discount);
        if TempCopyItemBuffer."Purchase Prices" or TempCopyItemBuffer."Purchase Line Discounts" then
            CopyItemPriceListLines(FromItemNo, ToItemNo, Enum::"Price Type"::Purchase, Enum::"Price Amount Type"::Any);
    end;

    local procedure CopyItemPriceListLines(FromItemNo: Code[20]; ToItemNo: Code[20]; PriceType: Enum "Price Type"; AmountType: Enum "Price Amount Type")
    var
        NewPriceListLine: Record "Price List Line";
        PriceListLine: Record "Price List Line";
    begin
        PriceListLine.SetRange("Price Type", PriceType);
        PriceListLine.SetRange("Amount Type", AmountType);
        PriceListLine.SetRange("Asset Type", PriceListLine."Asset Type"::Item);
        PriceListLine.SetRange("Asset No.", FromItemNo);
        OnCopyItemPriceListLinesOnAfterPriceListLineSetFilters(PriceListLine);
        if PriceListLine.FindSet() then
            repeat
                NewPriceListLine := PriceListLine;
                NewPriceListLine.SetAssetNo(ToItemNo);
                NewPriceListLine.SetNextLineNo();
                OnCopyItemPriceListLinesOnBeforeInsertNewPriceListLine(NewPriceListLine, PriceListLine);
                NewPriceListLine.Insert();
            until PriceListLine.Next() = 0;
    end;

    local procedure CopyItemSalesPrices(FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        SalesPrice: Record "Sales Price";
    begin
        if not TempCopyItemBuffer."Sales Prices" then
            exit;

        CopyItemRelatedTable(Database::"Sales Price", SalesPrice.FieldNo("Item No."), FromItemNo, ToItemNo);
    end;

    local procedure CopySalesLineDiscounts(FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        SalesLineDiscount: Record "Sales Line Discount";
        RecRef: RecordRef;
    begin
        if not TempCopyItemBuffer."Sales Line Discounts" then
            exit;

        SalesLineDiscount.SetRange(Type, SalesLineDiscount.Type::Item);

        RecRef.GetTable(SalesLineDiscount);
        CopyItemRelatedTableFromRecRef(RecRef, SalesLineDiscount.FieldNo(Code), FromItemNo, ToItemNo);
    end;

    local procedure CopyPurchasePrices(FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        PurchasePrice: Record "Purchase Price";
    begin
        if not TempCopyItemBuffer."Purchase Prices" then
            exit;

        CopyItemRelatedTable(Database::"Purchase Price", PurchasePrice.FieldNo("Item No."), FromItemNo, ToItemNo);
    end;

    local procedure CopyPurchaseLineDiscounts(FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        PurchLineDiscount: Record "Purchase Line Discount";
    begin
        if not TempCopyItemBuffer."Purchase Line Discounts" then
            exit;

        CopyItemRelatedTable(Database::"Purchase Line Discount", PurchLineDiscount.FieldNo("Item No."), FromItemNo, ToItemNo);
    end;

    local procedure CopyItemAttributes(FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        RecRef: RecordRef;
    begin
        if not TempCopyItemBuffer.Attributes then
            exit;

        ItemAttributeValueMapping.SetRange("Table ID", Database::Item);

        RecRef.GetTable(ItemAttributeValueMapping);
        CopyItemRelatedTableFromRecRef(RecRef, ItemAttributeValueMapping.FieldNo("No."), FromItemNo, ToItemNo);
    end;

    local procedure CopyItemReferences(FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        ItemReference: Record "Item Reference";
    begin
        if not TempCopyItemBuffer."Item References" then
            exit;

        CopyItemRelatedTable(Database::"Item Reference", ItemReference.FieldNo("Item No."), FromItemNo, ToItemNo);
    end;

    local procedure ShowNotification(Item: Record Item)
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        ItemCopiedNotification: Notification;
        ShowCreatedActionCaption: Text;
    begin
        ItemCopiedNotification.Id := CreateGuid();
        ItemCopiedNotification.Scope(NOTIFICATIONSCOPE::LocalScope);
        ItemCopiedNotification.SetData('FirstItemNo', FirstItemNo);
        ItemCopiedNotification.SetData('LastItemNo', LastItemNo);
        ItemCopiedNotification.Message(StrSubstNo(ItemCopiedMsg, Item."No."));
        if FirstItemNo = LastItemNo then
            ShowCreatedActionCaption := ShowCreatedItemTxt
        else
            ShowCreatedActionCaption := ShowCreatedItemsTxt;
        ItemCopiedNotification.AddAction(ShowCreatedActionCaption, CODEUNIT::"Copy Item", 'ShowCreatedItems');
        NotificationLifecycleMgt.SendNotification(ItemCopiedNotification, Item.RecordId);
    end;

    procedure ShowCreatedItems(var ItemCopiedNotification: Notification)
    var
        Item: Record Item;
    begin
        Item.SetRange(
          "No.",
          ItemCopiedNotification.GetData('FirstItemNo'),
          ItemCopiedNotification.GetData('LastItemNo'));
        if Item.FindFirst() then
            if Item.Count = 1 then
                PAGE.RunModal(PAGE::"Item Card", Item)
            else
                PAGE.RunModal(PAGE::"Item List", Item);
    end;

    local procedure ShowCreatedItems()
    var
        Item: Record Item;
    begin
        Item.SetRange("No.", FirstItemNo, LastItemNo);
        case Item.Count() of
            0:
                exit;
            1:
                PAGE.Run(PAGE::"Item Card", Item);
            else
                PAGE.Run(PAGE::"Item List", Item);
        end;
    end;

    procedure GetNewItemNo(var NewFirstItemNo: Code[20]; var NewLastItemNo: Code[20])
    begin
        NewFirstItemNo := FirstItemNo;
        NewLastItemNo := LastItemNo;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyExtendedTexts(var SourceItem: Record Item; var TargetItem: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItem(var CopyItemBuffer: Record "Copy Item Buffer"; SourceItem: Record Item; var TargetItem: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyItem(SourceItem: Record Item; var TargetItem: Record Item; CopyCounter: Integer; var CopyItemBuffer: Record "Copy Item Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyItemPriceListLines(FromItemNo: Code[20]; ToItemNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(Item: Record Item; var FirstItemNo: Code[20]; var LastItemNo: Code[20]; var IsItemCopied: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterItemCopied(var CopyItemBuffer: Record "Copy Item Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitSeries(var Item: Record Item; var InventorySetup: Record "Inventory Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyItemVariants(var TempCopyItemBuffer: Record "Copy Item Buffer" temporary; FromItemNo: Code[20]; ToItemNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyItemPriceListLinesOnAfterPriceListLineSetFilters(var PriceListLine: Record "Price List Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyItemOnBeforeTargetItemInsert(SourceItem: Record Item; var TargetItem: Record Item; CopyCounter: Integer; var CopyItemBuffer: Record "Copy Item Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyItemPriceListLinesOnBeforeInsertNewPriceListLine(var NewPriceListLine: Record "Price List Line"; PriceListLine: Record "Price List Line")
    begin
    end;
}

