// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Attribute;

using Microsoft.Inventory.Item;
using System.Text;

codeunit 7500 "Item Attribute Management"
{

    trigger OnRun()
    begin
    end;

    var
        DeleteAttributesInheritedFromOldCategoryQst: Label 'Do you want to delete the attributes that are inherited from item category ''%1''?', Comment = '%1 - item category code';
        DeleteItemInheritedParentCategoryAttributesQst: Label 'One or more items belong to item category ''''%1'''', which is a child of item category ''''%2''''.\\Do you want to delete the inherited item attributes for the items in question?', Comment = '%1 - item category code,%2 - item category code';

    procedure FindItemsByAttribute(var FilterItemAttributesBuffer: Record "Filter Item Attributes Buffer") ItemFilter: Text
    var
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemAttribute: Record "Item Attribute";
        AttributeValueIDFilter: Text;
        CurrentItemFilter: Text;
    begin
        if not FilterItemAttributesBuffer.FindSet() then
            exit;

        ItemFilter := '<>*';

        ItemAttributeValueMapping.SetRange("Table ID", DATABASE::Item);
        CurrentItemFilter := '*';

        repeat
            ItemAttribute.SetRange(Name, FilterItemAttributesBuffer.Attribute);
            if ItemAttribute.FindFirst() then begin
                ItemAttributeValueMapping.SetRange("Item Attribute ID", ItemAttribute.ID);
                AttributeValueIDFilter := GetItemAttributeValueFilter(FilterItemAttributesBuffer, ItemAttribute);
                if AttributeValueIDFilter = '' then
                    exit;

                CurrentItemFilter := GetItemNoFilter(ItemAttributeValueMapping, CurrentItemFilter, AttributeValueIDFilter);
                if CurrentItemFilter = '' then
                    exit;
            end;
        until FilterItemAttributesBuffer.Next() = 0;

        ItemFilter := CurrentItemFilter;
    end;

    procedure FindItemsByAttributes(var FilterItemAttributesBuffer: Record "Filter Item Attributes Buffer"; var TempFilteredItem: Record Item temporary)
    var
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemAttribute: Record "Item Attribute";
        AttributeValueIDFilter: Text;
    begin
        if not FilterItemAttributesBuffer.FindSet() then
            exit;

        ItemAttributeValueMapping.SetRange("Table ID", DATABASE::Item);

        OnFindItemsByAttributesOnBeforeFilterItemAttributesBufferLoop(FilterItemAttributesBuffer, TempFilteredItem, ItemAttributeValueMapping);
        repeat
            ItemAttribute.SetRange(Name, FilterItemAttributesBuffer.Attribute);
            if ItemAttribute.FindFirst() then begin
                ItemAttributeValueMapping.SetRange("Item Attribute ID", ItemAttribute.ID);
                AttributeValueIDFilter := GetItemAttributeValueFilter(FilterItemAttributesBuffer, ItemAttribute);
                if AttributeValueIDFilter = '' then begin
                    TempFilteredItem.DeleteAll();
                    exit;
                end;

                GetFilteredItems(ItemAttributeValueMapping, TempFilteredItem, AttributeValueIDFilter);
                if TempFilteredItem.IsEmpty() then
                    exit;
            end;
        until FilterItemAttributesBuffer.Next() = 0;
    end;

    local procedure GetItemAttributeValueFilter(var FilterItemAttributesBuffer: Record "Filter Item Attributes Buffer"; var ItemAttribute: Record "Item Attribute") AttributeFilter: Text
    var
        ItemAttributeValue: Record "Item Attribute Value";
    begin
        ItemAttributeValue.SetRange("Attribute ID", ItemAttribute.ID);
        ItemAttributeValue.SetValueFilter(ItemAttribute, FilterItemAttributesBuffer.Value);

        if not ItemAttributeValue.FindSet() then
            exit;

        repeat
            AttributeFilter += StrSubstNo('%1|', ItemAttributeValue.ID);
        until ItemAttributeValue.Next() = 0;

        exit(CopyStr(AttributeFilter, 1, StrLen(AttributeFilter) - 1));
    end;

    local procedure GetItemNoFilter(var ItemAttributeValueMapping: Record "Item Attribute Value Mapping"; PreviousItemNoFilter: Text; AttributeValueIDFilter: Text) ItemNoFilter: Text
    begin
        ItemAttributeValueMapping.SetFilter("No.", PreviousItemNoFilter);
        ItemAttributeValueMapping.SetFilter("Item Attribute Value ID", AttributeValueIDFilter);

        if not ItemAttributeValueMapping.FindSet() then
            exit;

        repeat
            ItemNoFilter += StrSubstNo('%1|', ItemAttributeValueMapping."No.");
        until ItemAttributeValueMapping.Next() = 0;

        exit(CopyStr(ItemNoFilter, 1, StrLen(ItemNoFilter) - 1));
    end;

    local procedure GetFilteredItems(var ItemAttributeValueMapping: Record "Item Attribute Value Mapping"; var TempFilteredItem: Record Item temporary; AttributeValueIDFilter: Text)
    var
        Item: Record Item;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetFilteredItems(ItemAttributeValueMapping, TempFilteredItem, AttributeValueIDFilter, IsHandled);
        if IsHandled then
            exit;

        ItemAttributeValueMapping.SetFilter("Item Attribute Value ID", AttributeValueIDFilter);

        if ItemAttributeValueMapping.IsEmpty() then begin
            TempFilteredItem.Reset();
            TempFilteredItem.DeleteAll();
            exit;
        end;

        if not TempFilteredItem.FindSet() then begin
            if ItemAttributeValueMapping.FindSet() then
                repeat
                    Item.Get(ItemAttributeValueMapping."No.");
                    TempFilteredItem.TransferFields(Item);
                    TempFilteredItem.Insert();
                until ItemAttributeValueMapping.Next() = 0;
            exit;
        end;

        repeat
            ItemAttributeValueMapping.SetRange("No.", TempFilteredItem."No.");
            if ItemAttributeValueMapping.IsEmpty() then
                TempFilteredItem.Delete();
        until TempFilteredItem.Next() = 0;
        ItemAttributeValueMapping.SetRange("No.");
    end;

    procedure GetItemNoFilterText(var TempFilteredItem: Record Item temporary; var ParameterCount: Integer) FilterText: Text
    var
        NextItem: Record Item;
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
        PreviousNo: Text;
        ItemNo: Text;
        FilterRangeStarted: Boolean;
    begin
        if not TempFilteredItem.FindSet() then begin
            FilterText := '<>*';
            exit;
        end;

        repeat
            ItemNo := SelectionFilterManagement.AddQuotes(TempFilteredItem."No.");

            if FilterText = '' then begin
                FilterText := ItemNo;
                NextItem."No." := TempFilteredItem."No.";
                ParameterCount += 1;
            end else begin
                if NextItem.Next() = 0 then
                    NextItem."No." := '';
                if TempFilteredItem."No." = NextItem."No." then begin
                    if not FilterRangeStarted then
                        FilterText += '..';
                    FilterRangeStarted := true;
                end else begin
                    if not FilterRangeStarted then begin
                        FilterText += StrSubstNo('|%1', ItemNo);
                        ParameterCount += 1;
                    end else begin
                        FilterText += StrSubstNo('%1|%2', PreviousNo, ItemNo);
                        FilterRangeStarted := false;
                        ParameterCount += 2;
                    end;
                    NextItem := TempFilteredItem;
                end;
            end;
            PreviousNo := ItemNo;
        until TempFilteredItem.Next() = 0;

        // close range if needed
        if FilterRangeStarted then begin
            FilterText += StrSubstNo('%1', PreviousNo);
            ParameterCount += 1;
        end;
    end;

    procedure InheritAttributesFromItemCategory(var Item: Record Item; NewItemCategoryCode: Code[20]; OldItemCategoryCode: Code[20])
    var
        TempItemAttributeValueToInsert: Record "Item Attribute Value" temporary;
        TempItemAttributeValueToDelete: Record "Item Attribute Value" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInheritAttributesFromItemCategory(Item, NewItemCategoryCode, OldItemCategoryCode, IsHandled);
        if IsHandled then
            exit;

        GenerateAttributesToInsertAndToDelete(
          TempItemAttributeValueToInsert, TempItemAttributeValueToDelete, NewItemCategoryCode, OldItemCategoryCode);

        if not TempItemAttributeValueToDelete.IsEmpty() then
            if not GuiAllowed then
                DeleteItemAttributeValueMapping(Item, TempItemAttributeValueToDelete)
            else
                if Confirm(StrSubstNo(DeleteAttributesInheritedFromOldCategoryQst, OldItemCategoryCode)) then
                    DeleteItemAttributeValueMapping(Item, TempItemAttributeValueToDelete);

        if not TempItemAttributeValueToInsert.IsEmpty() then
            InsertItemAttributeValueMapping(Item, TempItemAttributeValueToInsert);

        OnAfterInheritAttributesFromItemCategory(Item, NewItemCategoryCode, OldItemCategoryCode);
    end;

    procedure UpdateCategoryAttributesAfterChangingParentCategory(ItemCategoryCode: Code[20]; NewParentItemCategory: Code[20]; OldParentItemCategory: Code[20])
    var
        TempNewParentItemAttributeValue: Record "Item Attribute Value" temporary;
        TempOldParentItemAttributeValue: Record "Item Attribute Value" temporary;
    begin
        TempNewParentItemAttributeValue.LoadCategoryAttributesFactBoxData(NewParentItemCategory);
        TempOldParentItemAttributeValue.LoadCategoryAttributesFactBoxData(OldParentItemCategory);
        UpdateCategoryItemsAttributeValueMapping(
          TempNewParentItemAttributeValue, TempOldParentItemAttributeValue, ItemCategoryCode, OldParentItemCategory);
    end;

    local procedure GenerateAttributesToInsertAndToDelete(var TempItemAttributeValueToInsert: Record "Item Attribute Value" temporary; var TempItemAttributeValueToDelete: Record "Item Attribute Value" temporary; NewItemCategoryCode: Code[20]; OldItemCategoryCode: Code[20])
    var
        TempNewCategItemAttributeValue: Record "Item Attribute Value" temporary;
        TempOldCategItemAttributeValue: Record "Item Attribute Value" temporary;
    begin
        TempNewCategItemAttributeValue.LoadCategoryAttributesFactBoxData(NewItemCategoryCode);
        TempOldCategItemAttributeValue.LoadCategoryAttributesFactBoxData(OldItemCategoryCode);
        GenerateAttributeDifference(TempNewCategItemAttributeValue, TempOldCategItemAttributeValue, TempItemAttributeValueToInsert);
        GenerateAttributeDifference(TempOldCategItemAttributeValue, TempNewCategItemAttributeValue, TempItemAttributeValueToDelete);
    end;

    local procedure GenerateAttributeDifference(var TempFirstItemAttributeValue: Record "Item Attribute Value" temporary; var TempSecondItemAttributeValue: Record "Item Attribute Value" temporary; var TempResultingItemAttributeValue: Record "Item Attribute Value" temporary)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGenerateAttributeDifference(TempFirstItemAttributeValue, TempSecondItemAttributeValue, TempResultingItemAttributeValue, IsHandled);
        if IsHandled then
            exit;

        if TempFirstItemAttributeValue.FindFirst() then
            repeat
                if not TempSecondItemAttributeValue.Get(TempFirstItemAttributeValue."Attribute ID", TempFirstItemAttributeValue.ID) then begin
                    TempResultingItemAttributeValue.TransferFields(TempFirstItemAttributeValue);
                    TempResultingItemAttributeValue.Insert();
                end;
            until TempFirstItemAttributeValue.Next() = 0;
    end;

    procedure DeleteItemAttributeValueMapping(Item: Record Item; var TempItemAttributeValueToRemove: Record "Item Attribute Value" temporary)
    begin
        DeleteItemAttributeValueMappingWithTriggerOption(Item, TempItemAttributeValueToRemove, true);
    end;

    local procedure DeleteItemAttributeValueMappingWithTriggerOption(Item: Record Item; var TempItemAttributeValueToRemove: Record "Item Attribute Value" temporary; RunTrigger: Boolean)
    var
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemAttributeValuesToRemoveTxt: Text;
    begin
        ItemAttributeValueMapping.SetRange("Table ID", DATABASE::Item);
        ItemAttributeValueMapping.SetRange("No.", Item."No.");
        if TempItemAttributeValueToRemove.FindFirst() then begin
            repeat
                if ItemAttributeValuesToRemoveTxt <> '' then
                    ItemAttributeValuesToRemoveTxt += StrSubstNo('|%1', TempItemAttributeValueToRemove."Attribute ID")
                else
                    ItemAttributeValuesToRemoveTxt := Format(TempItemAttributeValueToRemove."Attribute ID");
            until TempItemAttributeValueToRemove.Next() = 0;
            ItemAttributeValueMapping.SetFilter("Item Attribute ID", ItemAttributeValuesToRemoveTxt);
            ItemAttributeValueMapping.DeleteAll(RunTrigger);
        end;
    end;

    local procedure InsertItemAttributeValueMapping(Item: Record Item; var TempItemAttributeValueToInsert: Record "Item Attribute Value" temporary)
    var
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
    begin
        if TempItemAttributeValueToInsert.FindFirst() then
            repeat
                ItemAttributeValueMapping."Table ID" := DATABASE::Item;
                ItemAttributeValueMapping."No." := Item."No.";
                ItemAttributeValueMapping."Item Attribute ID" := TempItemAttributeValueToInsert."Attribute ID";
                ItemAttributeValueMapping."Item Attribute Value ID" := TempItemAttributeValueToInsert.ID;
                OnBeforeItemAttributeValueMappingInsert(ItemAttributeValueMapping, TempItemAttributeValueToInsert);
                if ItemAttributeValueMapping.Insert(true) then;
            until TempItemAttributeValueToInsert.Next() = 0;
    end;

    procedure UpdateCategoryItemsAttributeValueMapping(var TempNewItemAttributeValue: Record "Item Attribute Value" temporary; var TempOldItemAttributeValue: Record "Item Attribute Value" temporary; ItemCategoryCode: Code[20]; OldItemCategoryCode: Code[20])
    var
        TempItemAttributeValueToInsert: Record "Item Attribute Value" temporary;
        TempItemAttributeValueToDelete: Record "Item Attribute Value" temporary;
    begin
        GenerateAttributeDifference(TempNewItemAttributeValue, TempOldItemAttributeValue, TempItemAttributeValueToInsert);
        GenerateAttributeDifference(TempOldItemAttributeValue, TempNewItemAttributeValue, TempItemAttributeValueToDelete);

        if not TempItemAttributeValueToDelete.IsEmpty() then
            if not GuiAllowed then
                DeleteCategoryItemsAttributeValueMapping(TempItemAttributeValueToDelete, ItemCategoryCode)
            else
                if Confirm(StrSubstNo(DeleteItemInheritedParentCategoryAttributesQst, ItemCategoryCode, OldItemCategoryCode)) then
                    DeleteCategoryItemsAttributeValueMapping(TempItemAttributeValueToDelete, ItemCategoryCode);

        if not TempItemAttributeValueToInsert.IsEmpty() then
            InsertCategoryItemsAttributeValueMapping(TempItemAttributeValueToInsert, ItemCategoryCode);
    end;

    procedure DeleteCategoryItemsAttributeValueMapping(var TempItemAttributeValueToRemove: Record "Item Attribute Value" temporary; CategoryCode: Code[20])
    var
        Item: Record Item;
        ItemCategory: Record "Item Category";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemAttributeValue: Record "Item Attribute Value";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteCategoryItemsAttributeValueMapping(TempItemAttributeValueToRemove, CategoryCode, IsHandled);
        if IsHandled then
            exit;

        Item.SetRange("Item Category Code", CategoryCode);
        if Item.FindSet() then
            repeat
                DeleteItemAttributeValueMappingWithTriggerOption(Item, TempItemAttributeValueToRemove, false);
            until Item.Next() = 0;

        ItemCategory.SetRange("Parent Category", CategoryCode);
        if ItemCategory.FindSet() then
            repeat
                DeleteCategoryItemsAttributeValueMapping(TempItemAttributeValueToRemove, ItemCategory.Code);
            until ItemCategory.Next() = 0;

        if TempItemAttributeValueToRemove.FindSet() then
            repeat
                ItemAttributeValueMapping.SetRange("Item Attribute ID", TempItemAttributeValueToRemove."Attribute ID");
                ItemAttributeValueMapping.SetRange("Item Attribute Value ID", TempItemAttributeValueToRemove.ID);
                if ItemAttributeValueMapping.IsEmpty() then
                    if ItemAttributeValue.Get(TempItemAttributeValueToRemove."Attribute ID", TempItemAttributeValueToRemove.ID) then
                        ItemAttributeValue.Delete();
            until TempItemAttributeValueToRemove.Next() = 0;
    end;

    procedure InsertCategoryItemsAttributeValueMapping(var TempItemAttributeValueToInsert: Record "Item Attribute Value" temporary; CategoryCode: Code[20])
    var
        Item: Record Item;
        ItemCategory: Record "Item Category";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertCategoryItemsAttributeValueMapping(TempItemAttributeValueToInsert, CategoryCode, IsHandled);
        if IsHandled then
            exit;

        Item.SetRange("Item Category Code", CategoryCode);
        if Item.FindSet() then
            repeat
                InsertItemAttributeValueMapping(Item, TempItemAttributeValueToInsert);
            until Item.Next() = 0;

        ItemCategory.SetRange("Parent Category", CategoryCode);
        if ItemCategory.FindSet() then
            repeat
                InsertCategoryItemsAttributeValueMapping(TempItemAttributeValueToInsert, ItemCategory.Code);
            until ItemCategory.Next() = 0;
    end;

    procedure InsertCategoryItemsBufferedAttributeValueMapping(var TempItemAttributeValueToInsert: Record "Item Attribute Value" temporary; var TempInsertedItemAttributeValueMapping: Record "Item Attribute Value Mapping" temporary; CategoryCode: Code[20])
    var
        Item: Record Item;
        ItemCategory: Record "Item Category";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertCategoryItemsBufferedAttributeValueMapping(TempItemAttributeValueToInsert, TempInsertedItemAttributeValueMapping, CategoryCode, IsHandled);
        if IsHandled then
            exit;

        Item.SetRange("Item Category Code", CategoryCode);
        if Item.FindSet() then
            repeat
                InsertBufferedItemAttributeValueMapping(Item, TempItemAttributeValueToInsert, TempInsertedItemAttributeValueMapping);
            until Item.Next() = 0;

        ItemCategory.SetRange("Parent Category", CategoryCode);
        if ItemCategory.FindSet() then
            repeat
                InsertCategoryItemsBufferedAttributeValueMapping(
                  TempItemAttributeValueToInsert, TempInsertedItemAttributeValueMapping, ItemCategory.Code);
            until ItemCategory.Next() = 0;
    end;

    local procedure InsertBufferedItemAttributeValueMapping(Item: Record Item; var TempItemAttributeValueToInsert: Record "Item Attribute Value" temporary; var TempInsertedItemAttributeValueMapping: Record "Item Attribute Value Mapping" temporary)
    var
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
    begin
        if TempItemAttributeValueToInsert.FindFirst() then
            repeat
                ItemAttributeValueMapping."Table ID" := DATABASE::Item;
                ItemAttributeValueMapping."No." := Item."No.";
                ItemAttributeValueMapping."Item Attribute ID" := TempItemAttributeValueToInsert."Attribute ID";
                ItemAttributeValueMapping."Item Attribute Value ID" := TempItemAttributeValueToInsert.ID;
                OnInsertBufferedItemAttributeValueMappingOnBeforeItemAttributeValueMappingInsert(TempItemAttributeValueToInsert, ItemAttributeValueMapping);
                if ItemAttributeValueMapping.Insert(true) then begin
                    TempInsertedItemAttributeValueMapping.TransferFields(ItemAttributeValueMapping);
                    OnBeforeBufferedItemAttributeValueMappingInsert(ItemAttributeValueMapping, TempInsertedItemAttributeValueMapping);
                    TempInsertedItemAttributeValueMapping.Insert();
                end;
            until TempItemAttributeValueToInsert.Next() = 0;
    end;

    procedure SearchCategoryItemsForAttribute(CategoryCode: Code[20]; AttributeID: Integer): Boolean
    var
        Item: Record Item;
        ItemCategory: Record "Item Category";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        IsHandled: Boolean;
        ReturnValue: Boolean;
    begin
        Item.SetRange("Item Category Code", CategoryCode);
        if Item.FindSet() then
            repeat
                ItemAttributeValueMapping.SetRange("Table ID", DATABASE::Item);
                ItemAttributeValueMapping.SetRange("No.", Item."No.");
                ItemAttributeValueMapping.SetRange("Item Attribute ID", AttributeID);
                if not ItemAttributeValueMapping.IsEmpty() then
                    exit(true);
            until Item.Next() = 0;

        IsHandled := false;
        OnSearchCategoryItemsForAttributeOnBeforeSearchByParentCategory(CategoryCode, AttributeID, IsHandled, ReturnValue);
        if IsHandled then
            exit(ReturnValue);

        ItemCategory.SetRange("Parent Category", CategoryCode);
        if ItemCategory.FindSet() then
            repeat
                if SearchCategoryItemsForAttribute(ItemCategory.Code, AttributeID) then
                    exit(true);
            until ItemCategory.Next() = 0;
    end;

    procedure DoesValueExistInItemAttributeValues(Text: Text[250]; var ItemAttributeValue: Record "Item Attribute Value"): Boolean
    begin
        ItemAttributeValue.Reset();
        ItemAttributeValue.SetFilter(Value, '@' + Text);
        exit(ItemAttributeValue.FindSet());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeItemAttributeValueMappingInsert(var ItemAttributeValueMapping: Record "Item Attribute Value Mapping"; var TempItemAttributeValue: Record "Item Attribute Value" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertCategoryItemsAttributeValueMapping(var TempItemAttributeValueToInsert: Record "Item Attribute Value" temporary; CategoryCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertCategoryItemsBufferedAttributeValueMapping(var TempItemAttributeValueToInsert: Record "Item Attribute Value" temporary; var TempInsertedItemAttributeValueMapping: Record "Item Attribute Value Mapping" temporary; CategoryCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBufferedItemAttributeValueMappingInsert(var ItemAttributeValueMapping: Record "Item Attribute Value Mapping"; var TempItemAttributeValueMapping: Record "Item Attribute Value Mapping" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteCategoryItemsAttributeValueMapping(var TempItemAttributeValueToRemove: Record "Item Attribute Value" temporary; CategoryCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenerateAttributeDifference(var TempFirstItemAttributeValue: Record "Item Attribute Value" temporary; var TempSecondItemAttributeValue: Record "Item Attribute Value" temporary; var TempResultingItemAttributeValue: Record "Item Attribute Value" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetFilteredItems(var ItemAttributeValueMapping: Record "Item Attribute Value Mapping"; var TempFilteredItem: Record Item temporary; AttributeValueIDFilter: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindItemsByAttributesOnBeforeFilterItemAttributesBufferLoop(var FilterItemAttributesBuffer: Record "Filter Item Attributes Buffer"; var TempFilteredItem: Record Item temporary; var ItemAttributeValueMapping: Record "Item Attribute Value Mapping")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertBufferedItemAttributeValueMappingOnBeforeItemAttributeValueMappingInsert(var TempItemAttributeValueToInsert: Record "Item Attribute Value" temporary; var ItemAttributeValueMapping: Record "Item Attribute Value Mapping")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSearchCategoryItemsForAttributeOnBeforeSearchByParentCategory(CategoryCode: Code[20]; AttributeID: Integer; var IsHandled: Boolean; var ReturnValue: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInheritAttributesFromItemCategory(var Item: Record Item; NewItemCategoryCode: Code[20]; OldItemCategoryCode: Code[20]; var Handle: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInheritAttributesFromItemCategory(var Item: Record Item; NewItemCategoryCode: Code[20]; OldItemCategoryCode: Code[20])
    begin
    end;
}

