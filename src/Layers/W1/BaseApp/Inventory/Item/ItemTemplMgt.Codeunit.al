// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Setup;
using Microsoft.Sales.Setup;
using Microsoft.Utilities;
using System.IO;
using System.Reflection;
using System.Utilities;

codeunit 1336 "Item Templ. Mgt."
{
    trigger OnRun()
    begin
    end;

    var
        VATPostingSetupErr: Label 'VAT Posting Setup does not exist. "VAT Bus. Posting Group" = %1, "VAT Prod. Posting Group" = %2.', Comment = '%1 - vat bus. posting group code; %2 - vat prod. posting group code';
        UpdateExistingValuesQst: Label 'You are about to apply the template to selected records. Data from the template will replace data for the records in fields that do not already contain data.\\Do you want also data from the template to replace data for the records in fields that already contain data?';
        OpenBlankCardQst: Label 'Do you want to open the blank item card?';

    procedure CreateItemFromTemplate(var Item: Record Item; var IsHandled: Boolean; ItemTemplCode: Code[20]) Result: Boolean
    var
        ItemTempl: Record "Item Templ.";
        InventorySetup: Record "Inventory Setup";
    begin
        IsHandled := false;
        OnBeforeCreateItemFromTemplate(Item, Result, IsHandled);
        if IsHandled then
            exit(Result);

        IsHandled := true;

        OnCreateItemFromTemplateOnBeforeSelectItemTemplate(Item, ItemTempl);
        if ItemTemplCode = '' then begin
            if not SelectItemTemplate(ItemTempl) then
                exit(false);
        end
        else
            ItemTempl.Get(ItemTemplCode);

        Item.Init();
        InitItemNo(Item, ItemTempl);

        InventorySetup.SetLoadFields("Default Costing Method");
        InventorySetup.Get();
        Item."Costing Method" := InventorySetup."Default Costing Method";

        OnCreateItemFromTemplateOnBeforeItemInsert(Item);
        Item.Insert(true);

        ApplyItemTemplate(Item, ItemTempl, true);

        OnAfterCreateItemFromTemplate(Item, ItemTempl);
        exit(true);
    end;

    procedure CreateItemFromTemplate(var Item: Record Item; var IsHandled: Boolean): Boolean
    begin
        exit(CreateItemFromTemplate(Item, IsHandled, ''));
    end;

    procedure ApplyItemTemplate(var Item: Record Item; ItemTempl: Record "Item Templ.")
    begin
        ApplyItemTemplate(Item, ItemTempl, false);
    end;

    procedure ApplyItemTemplate(var Item: Record Item; ItemTempl: Record "Item Templ."; UpdateExistingValues: Boolean)
    begin
        ApplyTemplate(Item, ItemTempl, UpdateExistingValues);
        InsertDimensions(Item."No.", ItemTempl.Code, Database::Item, Database::"Item Templ.");
        OnApplyItemTemplateOnBeforeItemGet(Item, ItemTempl, UpdateExistingValues);
        Item.Get(Item."No.");
    end;

    internal procedure InitFromTemplate(var Item: Record Item; ItemTempl: Record "Item Templ."; UpdateExistingValues: Boolean)
    var
        TempItem: Record Item temporary;
        InventorySetup: Record "Inventory Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        ItemRecRef: RecordRef;
        EmptyItemRecRef: RecordRef;
        ItemTemplRecRef: RecordRef;
        EmptyItemTemplRecRef: RecordRef;
        ItemFldRef: FieldRef;
        EmptyItemFldRef: FieldRef;
        ItemTemplFldRef: FieldRef;
        EmptyItemTemplFldRef: FieldRef;
        i: Integer;
        FieldExclusionList: List of [Integer];
        FieldValidationList: List of [Integer];
    begin
        CheckItemTemplRoundingPrecision(ItemTempl);
        ItemRecRef.GetTable(Item);
        InventorySetup.Get();
        TempItem.Init();
        OnInitFromTemplateOnAfterPrepareTempItem(TempItem, Item, ItemTempl, UpdateExistingValues);
        EmptyItemRecRef.GetTable(TempItem);
        ItemTemplRecRef.GetTable(ItemTempl);
        EmptyItemTemplRecRef.Open(Database::"Item Templ.");
        EmptyItemTemplRecRef.Init();
        OnInitFromTemplateOnAfterPrepareEmptyItemTemplRecordRef(EmptyItemTemplRecRef, ItemTempl, UpdateExistingValues);

        FillFieldExclusionList(FieldExclusionList);

        for i := 3 to ItemTemplRecRef.FieldCount do begin
            ItemTemplFldRef := ItemTemplRecRef.FieldIndex(i);
            if TemplateFieldCanBeProcessed(ItemTemplFldRef.Number, FieldExclusionList) then begin
                ItemFldRef := ItemRecRef.Field(ItemTemplFldRef.Number);
                EmptyItemFldRef := EmptyItemRecRef.Field(ItemTemplFldRef.Number);
                EmptyItemTemplFldRef := EmptyItemTemplRecRef.Field(ItemTemplFldRef.Number);

                if DoUpdateValue(ItemFldRef, EmptyItemFldRef, ItemTemplFldRef, EmptyItemTemplFldRef, UpdateExistingValues) then begin
                    ItemFldRef.Value := ItemTemplFldRef.Value();
                    FieldValidationList.Add(ItemTemplFldRef.Number);
                end;
            end;
        end;

        OnInitFromTemplateOnBeforeValidateFields(ItemRecRef, ItemTemplRecRef, FieldExclusionList, FieldValidationList);

        for i := 1 to FieldValidationList.Count do begin
            ItemTemplFldRef := ItemTemplRecRef.Field(FieldValidationList.Get(i));
            ItemFldRef := ItemRecRef.Field(ItemTemplFldRef.Number);
            ItemFldRef.Validate(ItemTemplFldRef.Value);
        end;

        ItemRecRef.SetTable(Item);
        SetBaseUoM(Item, ItemTempl);
        if ItemTempl."Price Includes VAT" then begin
            SalesReceivablesSetup.Get();
            if not VATPostingSetup.Get(SalesReceivablesSetup."VAT Bus. Posting Gr. (Price)", ItemTempl."VAT Prod. Posting Group") then
                Error(VATPostingSetupErr, SalesReceivablesSetup."VAT Bus. Posting Gr. (Price)", ItemTempl."VAT Prod. Posting Group");
            Item.Validate("Price Includes VAT", ItemTempl."Price Includes VAT");
        end;
        if ShouldUpdateItemCategoryCode(Item, ItemTempl, UpdateExistingValues) then
            Item.Validate("Item Category Code", ItemTempl."Item Category Code");
        Item.Validate("Indirect Cost %", ItemTempl."Indirect Cost %");
    end;

    local procedure DoUpdateValue(ItemFldRef: FieldRef; EmptyItemFldRef: FieldRef; ItemTemplFldRef: FieldRef; EmptyItemTemplFldRef: FieldRef; UpdateExistingValues: Boolean): Boolean
    begin
        // UpdateExistingValues always rewrites the enumerable type field
        if ItemFldRef.IsEnum() or (ItemFldRef.Type = ItemFldRef.Type::Option) then
            exit(UpdateExistingValues);

        // If the field is empty in the item template, it will not be updated
        if ItemTemplFldRef.Value = EmptyItemTemplFldRef.Value then
            exit(false);

        // If the field is empty in the item, it will be updated
        exit(UpdateExistingValues or (ItemFldRef.Value = EmptyItemFldRef.Value));
    end;

    local procedure ShouldUpdateItemCategoryCode(Item: Record Item; ItemTempl: Record "Item Templ."; UpdateExistingValues: Boolean): Boolean
    begin
        if UpdateExistingValues then
            exit(ItemTempl."Item Category Code" <> Item."Item Category Code");
        exit((Item."Item Category Code" = '') and (ItemTempl."Item Category Code" <> ''));
    end;

    local procedure ApplyTemplate(var Item: Record Item; ItemTempl: Record "Item Templ."; UpdateExistingValues: Boolean)
    var
        IsHandled: Boolean;
    begin
        InitFromTemplate(Item, ItemTempl, UpdateExistingValues);

        IsHandled := false;
        OnApplyTemplateOnBeforeItemModify(Item, ItemTempl, IsHandled, UpdateExistingValues);
        if not IsHandled then
            Item.Modify(true);
    end;

    local procedure SelectItemTemplate(var ItemTempl: Record "Item Templ."): Boolean
    var
        SelectItemTemplList: Page "Select Item Templ. List";
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforeSelectItemTemplate(ItemTempl, IsHandled, Result);
        if IsHandled then
            exit(Result);

        if ItemTempl.Count = 1 then begin
            ItemTempl.FindFirst();
            exit(true);
        end;

        if (ItemTempl.Count > 1) and GuiAllowed then begin
            SelectItemTemplList.SetTableView(ItemTempl);
            SelectItemTemplList.LookupMode(true);
            if SelectItemTemplList.RunModal() = Action::LookupOK then begin
                SelectItemTemplList.GetRecord(ItemTempl);
                exit(true);
            end;
        end;

        exit(false);
    end;

    procedure InsertDimensions(DestNo: Code[20]; SourceNo: Code[20]; DestTableId: Integer; SourceTableId: Integer)
    var
        SourceDefaultDimension: Record "Default Dimension";
        DestDefaultDimension: Record "Default Dimension";
    begin
        SourceDefaultDimension.SetRange("Table ID", SourceTableId);
        SourceDefaultDimension.SetRange("No.", SourceNo);
        if SourceDefaultDimension.FindSet() then
            repeat
                DestDefaultDimension.Init();
                DestDefaultDimension.Validate("Table ID", DestTableId);
                DestDefaultDimension.Validate("No.", DestNo);
                DestDefaultDimension.Validate("Dimension Code", SourceDefaultDimension."Dimension Code");
                DestDefaultDimension.Validate("Dimension Value Code", SourceDefaultDimension."Dimension Value Code");
                DestDefaultDimension.Validate("Value Posting", SourceDefaultDimension."Value Posting");
                SetAllowedValuesFilterInDefaultDimension(DestDefaultDimension, SourceDefaultDimension);
                if not DestDefaultDimension.Get(DestDefaultDimension."Table ID", DestDefaultDimension."No.", DestDefaultDimension."Dimension Code") then
                    DestDefaultDimension.Insert(true)
                else
                    if DestDefaultDimension."Value Posting" = DestDefaultDimension."Value Posting"::" " then begin
                        DestDefaultDimension."Value Posting" := SourceDefaultDimension."Value Posting";
                        SetAllowedValuesFilterInDefaultDimension(DestDefaultDimension, SourceDefaultDimension);
                        DestDefaultDimension.Modify(true);
                    end;
            until SourceDefaultDimension.Next() = 0;
    end;

    procedure ItemTemplatesAreNotEmpty(var IsHandled: Boolean): Boolean
    var
        ItemTempl: Record "Item Templ.";
        TemplateFeatureMgt: Codeunit "Template Feature Mgt.";
    begin
        if not TemplateFeatureMgt.IsEnabled() then
            exit(false);

        IsHandled := true;
        exit(not ItemTempl.IsEmpty);
    end;

    procedure InsertItemFromTemplate(var Item: Record Item) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnInsertItemFromTemplate(Item, Result, IsHandled);
        if IsHandled then
            exit(Result);

        Result := CreateItemFromTemplate(Item, IsHandled);
    end;

    procedure TemplatesAreNotEmpty() Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnTemplatesAreNotEmpty(Result, IsHandled);
        if IsHandled then
            exit(Result);

        Result := ItemTemplatesAreNotEmpty(IsHandled);
    end;

    procedure IsEnabled() Result: Boolean
    var
        TemplateFeatureMgt: Codeunit "Template Feature Mgt.";
    begin
        Result := TemplateFeatureMgt.IsEnabled();

        OnAfterIsEnabled(Result);
    end;

    procedure UpdateItemFromTemplate(var Item: Record Item)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnUpdateItemFromTemplate(Item, IsHandled);
        if IsHandled then
            exit;

        UpdateFromTemplate(Item, IsHandled);
    end;

    local procedure UpdateFromTemplate(var Item: Record Item; var IsHandled: Boolean)
    var
        ItemTempl: Record "Item Templ.";
    begin
        IsHandled := false;
        OnBeforeUpdateFromTemplate(Item, IsHandled);
        if IsHandled then
            exit;

        if not CanBeUpdatedFromTemplate(ItemTempl, IsHandled) then
            exit;

        ApplyItemTemplate(Item, ItemTempl, GetUpdateExistingValuesParam());
    end;

    procedure UpdateItemsFromTemplate(var Item: Record Item)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnUpdateItemsFromTemplate(Item, IsHandled);
        if IsHandled then
            exit;

        UpdateMultipleFromTemplate(Item, IsHandled);
    end;

    local procedure UpdateMultipleFromTemplate(var Item: Record Item; var IsHandled: Boolean)
    var
        ItemTempl: Record "Item Templ.";
    begin
        IsHandled := false;
        OnBeforeUpdateMultipleFromTemplate(Item, IsHandled);
        if IsHandled then
            exit;

        if not CanBeUpdatedFromTemplate(ItemTempl, IsHandled) then
            exit;

        if Item.FindSet() then
            repeat
                ApplyItemTemplate(Item, ItemTempl, GetUpdateExistingValuesParam());
            until Item.Next() = 0;
    end;

    local procedure CanBeUpdatedFromTemplate(var ItemTempl: Record "Item Templ."; var IsHandled: Boolean): Boolean
    begin
        IsHandled := true;

        if not SelectItemTemplate(ItemTempl) then
            exit(false);

        exit(true);
    end;

    procedure SaveAsTemplate(Item: Record Item)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnSaveAsTemplate(Item, IsHandled);
        if IsHandled then
            exit;

        CreateTemplateFromItem(Item, IsHandled);
    end;

    procedure CreateTemplateFromItem(Item: Record Item; var IsHandled: Boolean)
    var
        ItemTempl: Record "Item Templ.";
    begin
        IsHandled := false;
        OnBeforeCreateTemplateFromItem(Item, IsHandled);
        if IsHandled then
            exit;

        IsHandled := true;

        InsertTemplateFromItem(ItemTempl, Item);
        InsertDimensions(ItemTempl.Code, Item."No.", Database::"Item Templ.", Database::Item);
        OnCreateTemplateFromItemOnBeforeItemTemplGet(Item, ItemTempl);
        ItemTempl.Get(ItemTempl.Code);
        ShowItemTemplCard(ItemTempl);
    end;

    local procedure InsertTemplateFromItem(var ItemTempl: Record "Item Templ."; Item: Record Item)
    var
        SavedItemTempl: Record "Item Templ.";
    begin
        ItemTempl.Init();
        ItemTempl.Code := GetItemTemplCode();
        SavedItemTempl := ItemTempl;
        ItemTempl.TransferFields(Item);
        ItemTempl.Code := SavedItemTempl.Code;
        ItemTempl.Description := SavedItemTempl.Description;
        OnInsertTemplateFromItemOnBeforeItemTemplInsert(ItemTempl, Item);
        ItemTempl.Insert();
    end;

    local procedure GetItemTemplCode() ItemTemplCode: Code[20]
    var
        Item: Record Item;
        ItemTempl: Record "Item Templ.";
    begin
        if ItemTempl.FindLast() and (IncStr(ItemTempl.Code) <> '') then
            ItemTemplCode := ItemTempl.Code
        else
            ItemTemplCode := CopyStr(Item.TableCaption(), 1, 4) + '000001';

        while ItemTempl.Get(ItemTemplCode) do
            ItemTemplCode := IncStr(ItemTemplCode);
    end;

    local procedure ShowItemTemplCard(ItemTempl: Record "Item Templ.")
    var
        ItemTemplCard: Page "Item Templ. Card";
    begin
        if not GuiAllowed then
            exit;

        Commit();
        ItemTemplCard.SetRecord(ItemTempl);
        ItemTemplCard.LookupMode := true;
        if ItemTemplCard.RunModal() = Action::LookupCancel then begin
            ItemTempl.Get(ItemTempl.Code);
            ItemTempl.Delete(true);
        end;
    end;

    procedure ShowTemplates()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnShowTemplates(IsHandled);
        if IsHandled then
            exit;

        ShowItemTemplList(IsHandled);
    end;

    local procedure ShowItemTemplList(var IsHandled: Boolean)
    begin
        IsHandled := true;
        Page.Run(Page::"Item Templ. List");
    end;

    procedure InitItemNo(var Item: Record Item; ItemTempl: Record "Item Templ.")
    var
        NoSeries: Codeunit "No. Series";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitItemNo(Item, ItemTempl, IsHandled);
        if IsHandled then
            exit;

        if ItemTempl."No. Series" = '' then
            exit;

        Item."No. Series" := ItemTempl."No. Series";
        if Item."No." <> '' then begin
            NoSeries.TestManual(Item."No. Series");
            exit;
        end;

        NoSeries.TestAutomatic(Item."No. Series");
        Item."No." := NoSeries.GetNextNo(Item."No. Series");
    end;

    local procedure GetUnitOfMeasureCode(): Code[10]
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        UnitOfMeasure.SetRange("International Standard Code", 'EA');
        if UnitOfMeasure.FindFirst() then
            exit(UnitOfMeasure.Code);

        UnitOfMeasure.SetRange("International Standard Code");
        if UnitOfMeasure.FindFirst() then
            exit(UnitOfMeasure.Code);

        exit('');
    end;

    local procedure TemplateFieldCanBeProcessed(FieldNumber: Integer; FieldExclusionList: List of [Integer]): Boolean
    var
        ItemField: Record Field;
        ItemTemplateField: Record Field;
    begin
        if FieldExclusionList.Contains(FieldNumber) or (FieldNumber > 2000000000) then
            exit(false);

        if not (ItemField.Get(Database::Item, FieldNumber) and ItemTemplateField.Get(Database::"Item Templ.", FieldNumber)) then
            exit(false);

        if (ItemField.Class <> ItemField.Class::Normal) or (ItemTemplateField.Class <> ItemTemplateField.Class::Normal) or
            (ItemField.Type <> ItemTemplateField.Type) or (ItemField.FieldName <> ItemTemplateField.FieldName) or
            (ItemField.Len <> ItemTemplateField.Len) or
            (ItemField.ObsoleteState = ItemField.ObsoleteState::Removed) or
            (ItemTemplateField.ObsoleteState = ItemTemplateField.ObsoleteState::Removed)
        then
            exit(false);

        exit(true);
    end;

    local procedure FillFieldExclusionList(var FieldExclusionList: List of [Integer])
    var
        ItemTempl: Record "Item Templ.";
    begin
        FieldExclusionList.Add(ItemTempl.FieldNo("Base Unit of Measure"));
        FieldExclusionList.Add(ItemTempl.FieldNo("No. Series"));
        FieldExclusionList.Add(ItemTempl.FieldNo("VAT Bus. Posting Gr. (Price)"));
        FieldExclusionList.Add(ItemTempl.FieldNo("Item Category Code"));

        OnAfterFillFieldExclusionList(FieldExclusionList);
    end;

    local procedure GetUpdateExistingValuesParam() Result: Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetUpdateExistingValuesParam(Result, IsHandled);
        if not IsHandled then
            Result := ConfirmManagement.GetResponseOrDefault(UpdateExistingValuesQst, false);
    end;

    local procedure SetBaseUoM(var Item: Record Item; var ItemTempl: Record "Item Templ.")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetBaseUoM(Item, ItemTempl, IsHandled);
        if IsHandled then
            exit;

        if ItemTempl."Base Unit of Measure" <> '' then
            Item.Validate("Base Unit of Measure", ItemTempl."Base Unit of Measure")
        else
            Item.Validate("Base Unit of Measure", GetUnitOfMeasureCode());
    end;

    local procedure CheckItemTemplRoundingPrecision(var ItemTempl: Record "Item Templ.")
    var
        ModifyTemplate: Boolean;
    begin
        if ItemTempl."Rounding Precision" = 0 then begin
            ItemTempl."Rounding Precision" := 1;
            ModifyTemplate := true;
        end;
        if (ItemTempl.Type = ItemTempl.Type::Service) and (ItemTempl.Reserve <> ItemTempl.Reserve::Never) then begin
            ItemTempl.Reserve := ItemTempl.Reserve::Never;
            ModifyTemplate := true;
        end;
        if ModifyTemplate then
            ItemTempl.Modify();
    end;

    procedure IsOpenBlankCardConfirmed() Result: Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOpenBlankCardConfirmed(Result, IsHandled);
        if IsHandled then
            exit(Result);

        exit(ConfirmManagement.GetResponse(OpenBlankCardQst, false));
    end;

    local procedure SetAllowedValuesFilterInDefaultDimension(var DestDefaultDimension: Record "Default Dimension"; SourceDefaultDimension: Record "Default Dimension")
    begin
        if SourceDefaultDimension."Allowed Values Filter" = '' then
            exit;

        if DestDefaultDimension."Value Posting" <> DestDefaultDimension."Value Posting"::"Code Mandatory" then
            exit;

        DestDefaultDimension.Validate("Allowed Values Filter", SourceDefaultDimension."Allowed Values Filter");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsEnabled(var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyTemplateOnBeforeItemModify(var Item: Record Item; ItemTempl: Record "Item Templ."; var IsHandled: Boolean; UpdateExistingValues: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyItemTemplateOnBeforeItemGet(var Item: Record Item; ItemTempl: Record "Item Templ."; UpdateExistingValues: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateItemFromTemplateOnBeforeSelectItemTemplate(Item: Record Item; var ItemTempl: Record "Item Templ.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertItemFromTemplate(var Item: Record Item; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTemplatesAreNotEmpty(var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateItemFromTemplate(var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateItemsFromTemplate(var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSaveAsTemplate(Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowTemplates(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillFieldExclusionList(var FieldExclusionList: List of [Integer])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateItemFromTemplate(var Item: Record Item; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateFromTemplate(var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateMultipleFromTemplate(var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateTemplateFromItem(Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTemplateFromItemOnBeforeItemTemplInsert(var ItemTempl: Record "Item Templ."; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetUpdateExistingValuesParam(var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetBaseUoM(var Item: Record Item; var ItemTempl: Record "Item Templ."; var IsHandled: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Config. Template Management", 'OnBeforeInsertRecordWithKeyFields', '', false, false)]
    local procedure OnBeforeInsertRecordWithKeyFieldsHandler(var RecRef: RecordRef; ConfigTemplateHeader: Record "Config. Template Header")
    begin
        FillItemKeyFromInitSeries(RecRef, ConfigTemplateHeader)
    end;

    procedure FillItemKeyFromInitSeries(var RecRef: RecordRef; ConfigTemplateHeader: Record "Config. Template Header")
    var
        Item: Record Item;
        NoSeries: Codeunit "No. Series";
        FldRef: FieldRef;
    begin
        if RecRef.Number = Database::Item then begin
            if ConfigTemplateHeader."Instance No. Series" = '' then
                exit;

            NoSeries.TestAutomatic(ConfigTemplateHeader."Instance No. Series");

            FldRef := RecRef.Field(Item.FieldNo("No."));
            FldRef.Value := NoSeries.GetNextNo(ConfigTemplateHeader."Instance No. Series");
            FldRef := RecRef.Field(Item.FieldNo("No. Series"));
            FldRef.Value := ConfigTemplateHeader."Instance No. Series";
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitItemNo(var Item: Record Item; ItemTempl: Record "Item Templ."; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTemplateFromItemOnBeforeItemTemplGet(Item: Record Item; ItemTempl: Record "Item Templ.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateItemFromTemplate(var Item: Record Item; ItemTempl: Record "Item Templ.");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitFromTemplateOnBeforeValidateFields(var ItemRecRef: RecordRef; var ItemTemplRecRef: RecordRef; FieldExclusionList: List of [Integer]; var FieldValidationList: List of [Integer])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSelectItemTemplate(ItemTempl: Record "Item Templ."; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenBlankCardConfirmed(var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateItemFromTemplateOnBeforeItemInsert(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitFromTemplateOnAfterPrepareTempItem(var TempItem: Record Item temporary; var Item: Record Item; ItemTempl: Record "Item Templ."; UpdateExistingValues: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitFromTemplateOnAfterPrepareEmptyItemTemplRecordRef(var EmptyItemTemplRecordRef: RecordRef; ItemTempl: Record "Item Templ."; UpdateExistingValues: Boolean)
    begin
    end;
}
