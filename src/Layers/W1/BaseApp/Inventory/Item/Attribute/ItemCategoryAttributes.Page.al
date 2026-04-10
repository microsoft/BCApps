// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Attribute;

using Microsoft.Inventory.Item;

page 5734 "Item Category Attributes"
{
    Caption = 'Item Category Attributes';
    LinksAllowed = false;
    PageType = ListPart;
    RefreshOnActivate = true;
    SourceTable = "Item Attribute Value Selection";
    SourceTableTemporary = true;
    SourceTableView = sorting("Inheritance Level", "Attribute Name")
                      order(ascending);

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                Enabled = RowEditable;
                ShowCaption = false;
                field("Attribute Name"; Rec."Attribute Name")
                {
                    ApplicationArea = Basic, Suite;
                    AssistEdit = false;
                    Caption = 'Attribute';
                    StyleExpr = StyleTxt;
                    TableRelation = "Item Attribute".Name where(Blocked = const(false));

                    trigger OnValidate()
                    begin
                        PersistInheritanceData();
                    end;
                }
                field(Value; Rec.Value)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Default Value';
                    StyleExpr = StyleTxt;
                    TableRelation = if ("Attribute Type" = const(Option)) "Item Attribute Value".Value where("Attribute ID" = field("Attribute ID"),
                                                                                                            Blocked = const(false));

                    trigger OnValidate()
                    begin
                        PersistInheritanceData();
                        ChangeDefaultValue();
                        if (Rec.Value <> '') and not HasBlankOptionAttributes() then
                            ClearBlankOptionAttributeNotification();
                    end;
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = StyleTxt;
                }
                field("Inherited-From Key Value"; Rec."Inherited-From Key Value")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Inherited From';
                    Editable = false;
                    StyleExpr = StyleTxt;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateProperties();
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateProperties();
    end;

    trigger OnClosePage()
    begin
        TempRecentlyItemAttributeValueMapping.DeleteAll();
    end;

    trigger OnDeleteRecord(): Boolean
    var
        TempItemAttributeValueToDelete: Record "Item Attribute Value" temporary;
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemAttributeManagement: Codeunit "Item Attribute Management";
    begin
        if Rec."Inherited-From Key Value" <> '' then
            Error(DeleteInheritedAttribErr);

        ItemAttributeValueMapping.SetRange("Table ID", DATABASE::"Item Category");
        ItemAttributeValueMapping.SetRange("No.", ItemCategoryCode);
        ItemAttributeValueMapping.SetRange("Item Attribute ID", Rec."Attribute ID");
        if ItemAttributeValueMapping.FindFirst() then begin
            if ItemAttributeManagement.SearchCategoryItemsForAttribute(ItemCategoryCode, Rec."Attribute ID") then
                if Confirm(StrSubstNo(DeleteItemInheritedParentCategoryAttributesQst, ItemCategoryCode, ItemCategoryCode)) then begin
                    ItemAttributeValue.SetRange("Attribute ID", Rec."Attribute ID");
                    ItemAttributeValue.SetRange(ID, ItemAttributeValueMapping."Item Attribute Value ID");
                    if ItemAttributeValue.FindFirst() then begin
                        TempItemAttributeValueToDelete.TransferFields(ItemAttributeValue);
                        TempItemAttributeValueToDelete.Insert();
                        DeleteRecentlyItemAttributeValueMapping(Rec."Attribute ID");
                        ItemAttributeManagement.DeleteCategoryItemsAttributeValueMapping(TempItemAttributeValueToDelete, ItemCategoryCode);
                    end;
                end;
            ItemAttributeValueMapping.Delete();
        end else
            DeleteRecentlyItemAttributeValueMapping(Rec."Attribute ID");
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        ItemAttribute: Record "Item Attribute";
        TempItemAttributeValueToInsert: Record "Item Attribute Value" temporary;
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemAttributeManagement: Codeunit "Item Attribute Management";
    begin
        if ItemCategoryCode <> '' then begin
            ItemAttribute.Get(Rec."Attribute ID");

            if (ItemAttribute.Type = ItemAttribute.Type::Option) and (Rec.Value = '') then begin
                ShowBlankOptionAttributeNotification(Rec."Attribute Name");
                exit(true);
            end;

            ItemAttributeValueMapping."Table ID" := DATABASE::"Item Category";
            ItemAttributeValueMapping."No." := ItemCategoryCode;
            ItemAttributeValueMapping."Item Attribute ID" := Rec."Attribute ID";
            ItemAttributeValueMapping."Item Attribute Value ID" := Rec.GetAttributeValueID(TempItemAttributeValueToInsert);
            OnInsertRecordOnBeforeItemAttributeValueMappingInsert(ItemAttributeValueMapping, TempItemAttributeValueToInsert, Rec);
            ItemAttributeValueMapping.Insert();
            ItemAttributeManagement.InsertCategoryItemsBufferedAttributeValueMapping(
              TempItemAttributeValueToInsert, TempRecentlyItemAttributeValueMapping, ItemCategoryCode);
            InsertRecentlyAddedCategoryAttribute(ItemAttributeValueMapping);
        end;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if HasBlankOptionAttributes() then begin
            Message(OptionTypeMsg);
            if Rec."Inherited-From Key Value" = '' then
                exit(false);
        end;
        exit(true);
    end;

    var
        ItemCategoryCode: Code[20];
        DeleteInheritedAttribErr: Label 'You cannot delete attributes that are inherited from a parent item category.';
        RowEditable: Boolean;
        StyleTxt: Text;
        ChangingDefaultValueMsg: Label 'The new default value will not apply to items that use the current item category, ''''%1''''. It will only apply to new items.', Comment = '%1 - item category code';
        DeleteItemInheritedParentCategoryAttributesQst: Label 'One or more items belong to item category ''''%1''''.\\Do you want to delete the inherited item attributes for the items in question?', Comment = '%1 - item category code,%2 - item category code';
        BlankOptionAttributeNotificationMsg: Label 'You must enter a value for the Option attribute %1. Blank values are not allowed for Option-type attributes.', Comment = '%1 - attribute name';
        OptionTypeMsg: Label 'You must enter a value for all Option-type attributes before closing this page.';

    protected var
        TempRecentlyItemAttributeValueMapping: Record "Item Attribute Value Mapping" temporary;

    procedure LoadAttributes(CategoryCode: Code[20])
    var
        TempItemAttributeValue: Record "Item Attribute Value" temporary;
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemCategory: Record "Item Category";
        CurrentCategoryCode: Code[20];
    begin
        Rec.Reset();
        Rec.DeleteAll();
        if CategoryCode = '' then
            exit;
        SortByInheritance();
        ItemAttributeValueMapping.SetRange("Table ID", DATABASE::"Item Category");
        SetItemCategoryCode(CategoryCode);
        CurrentCategoryCode := CategoryCode;
        repeat
            if ItemCategory.Get(CurrentCategoryCode) then begin
                ItemAttributeValueMapping.SetRange("No.", CurrentCategoryCode);
                if ItemAttributeValueMapping.FindSet() then
                    repeat
                        if ItemAttributeValue.Get(
                             ItemAttributeValueMapping."Item Attribute ID", ItemAttributeValueMapping."Item Attribute Value ID")
                        then begin
                            TempItemAttributeValue.TransferFields(ItemAttributeValue);

                            OnLoadAttributesOnBeforeTempItemAttributeValueInsert(ItemAttributeValueMapping, TempItemAttributeValue);
                            if TempItemAttributeValue.Insert() then
                                if not AttributeExists(TempItemAttributeValue."Attribute ID") then begin
                                    if CurrentCategoryCode = ItemCategoryCode then
                                        Rec.InsertRecord(TempItemAttributeValue, DATABASE::"Item Category", '')
                                    else
                                        Rec.InsertRecord(TempItemAttributeValue, DATABASE::"Item Category", CurrentCategoryCode);
                                    Rec."Inheritance Level" := ItemCategory.Indentation;
                                    Rec.Modify();
                                end;
                        end
                    until ItemAttributeValueMapping.Next() = 0;
                CurrentCategoryCode := ItemCategory."Parent Category";
            end else
                CurrentCategoryCode := '';
        until CurrentCategoryCode = '';
        Rec.Reset();
        CurrPage.Update(false);
        SortByInheritance();
    end;

    procedure SaveAttributes(CategoryCode: Code[20])
    var
        TempNewItemAttributeValue: Record "Item Attribute Value" temporary;
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemAttribute: Record "Item Attribute";
        TempNewCategItemAttributeValue: Record "Item Attribute Value" temporary;
        TempOldCategItemAttributeValue: Record "Item Attribute Value" temporary;
        ItemAttributeManagement: Codeunit "Item Attribute Management";
    begin
        if CategoryCode = '' then
            exit;
        TempOldCategItemAttributeValue.LoadCategoryAttributesFactBoxData(CategoryCode);

        Rec.SetRange("Inherited-From Table ID", DATABASE::"Item Category");
        Rec.SetRange("Inherited-From Key Value", '');
        Rec.PopulateItemAttributeValue(TempNewItemAttributeValue);
        ItemAttributeValueMapping.SetRange("Table ID", DATABASE::"Item Category");
        ItemAttributeValueMapping.SetRange("No.", CategoryCode);
        ItemAttributeValueMapping.DeleteAll();

        if TempNewItemAttributeValue.FindSet() then
            repeat
                ItemAttributeValueMapping."Table ID" := DATABASE::"Item Category";
                ItemAttributeValueMapping."No." := CategoryCode;
                ItemAttributeValueMapping."Item Attribute ID" := TempNewItemAttributeValue."Attribute ID";
                ItemAttributeValueMapping."Item Attribute Value ID" := TempNewItemAttributeValue.ID;
                OnSaveAttributesOnBeforeItemAttributeValueMappingInsert(ItemAttributeValueMapping, TempNewItemAttributeValue);
                ItemAttributeValueMapping.Insert();
                ItemAttribute.Get(ItemAttributeValueMapping."Item Attribute ID");
                ItemAttribute.RemoveUnusedArbitraryValues();
            until TempNewItemAttributeValue.Next() = 0;

        TempNewCategItemAttributeValue.LoadCategoryAttributesFactBoxData(CategoryCode);
        ItemAttributeManagement.UpdateCategoryItemsAttributeValueMapping(
          TempNewCategItemAttributeValue, TempOldCategItemAttributeValue, ItemCategoryCode, ItemCategoryCode);
    end;

    local procedure PersistInheritanceData()
    begin
        Rec."Inherited-From Table ID" := DATABASE::"Item Category";
        CurrPage.SaveRecord();
    end;

    procedure SetItemCategoryCode(CategoryCode: Code[20])
    begin
        if ItemCategoryCode <> CategoryCode then begin
            ItemCategoryCode := CategoryCode;
            TempRecentlyItemAttributeValueMapping.DeleteAll();
        end;
    end;

    procedure SortByInheritance()
    begin
        Rec.SetCurrentKey("Inheritance Level", "Attribute Name");
    end;

    local procedure UpdateProperties()
    begin
        RowEditable := Rec."Inherited-From Key Value" = '';
        if RowEditable then
            StyleTxt := 'Standard'
        else
            StyleTxt := 'Strong';
    end;

    local procedure AttributeExists(AttributeID: Integer) AttribExist: Boolean
    begin
        Rec.SetRange("Attribute ID", AttributeID);
        AttribExist := not Rec.IsEmpty();
        Rec.Reset();
    end;

    local procedure ChangeDefaultValue()
    var
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        TempItemAttributeValueToInsert: Record "Item Attribute Value" temporary;
        ItemAttributeManagement: Codeunit "Item Attribute Management";
        AttributeValueID: Integer;
    begin
        ItemAttributeValueMapping.SetRange("Table ID", DATABASE::"Item Category");
        ItemAttributeValueMapping.SetRange("No.", ItemCategoryCode);
        ItemAttributeValueMapping.SetRange("Item Attribute ID", Rec."Attribute ID");

        AttributeValueID := Rec.GetAttributeValueID(TempItemAttributeValueToInsert);

        if ItemAttributeValueMapping.FindFirst() then begin
            ItemAttributeValueMapping."Item Attribute Value ID" := AttributeValueID;
            ItemAttributeValueMapping.Modify();
        end else
            if AttributeValueID > 0 then
                InsertItemAttributeValueMapping(ItemCategoryCode, Rec."Attribute ID", AttributeValueID);

        if IsRecentlyAddedCategoryAttribute(Rec."Attribute ID") then
            UpdateRecentlyItemAttributeValueMapping(TempItemAttributeValueToInsert)
        else
            if ItemAttributeManagement.SearchCategoryItemsForAttribute(ItemCategoryCode, Rec."Attribute ID") then
                Message(StrSubstNo(ChangingDefaultValueMsg, ItemCategoryCode));
    end;

    local procedure InsertRecentlyAddedCategoryAttribute(ItemAttributeValueMapping: Record "Item Attribute Value Mapping")
    begin
        TempRecentlyItemAttributeValueMapping.TransferFields(ItemAttributeValueMapping);
        if TempRecentlyItemAttributeValueMapping.Insert() then;
    end;

    local procedure IsRecentlyAddedCategoryAttribute(AttributeID: Integer): Boolean
    begin
        TempRecentlyItemAttributeValueMapping.SetRange("Item Attribute ID", AttributeID);
        exit(not TempRecentlyItemAttributeValueMapping.IsEmpty)
    end;

    local procedure UpdateRecentlyItemAttributeValueMapping(var TempItemAttributeValueToInsert: Record "Item Attribute Value" temporary)
    var
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
    begin
        TempRecentlyItemAttributeValueMapping.SetRange("Item Attribute ID", TempItemAttributeValueToInsert."Attribute ID");
        if TempRecentlyItemAttributeValueMapping.FindSet() then
            repeat
                ItemAttributeValueMapping.SetRange("Table ID", TempRecentlyItemAttributeValueMapping."Table ID");
                ItemAttributeValueMapping.SetRange("No.", TempRecentlyItemAttributeValueMapping."No.");
                ItemAttributeValueMapping.SetRange("Item Attribute ID", TempRecentlyItemAttributeValueMapping."Item Attribute ID");
                ItemAttributeValueMapping.FindFirst();
                ItemAttributeValueMapping.Validate("Item Attribute Value ID", TempItemAttributeValueToInsert.ID);
                ItemAttributeValueMapping.Modify();
            until TempRecentlyItemAttributeValueMapping.Next() = 0;
    end;

    local procedure DeleteRecentlyItemAttributeValueMapping(AttributeID: Integer)
    begin
        TempRecentlyItemAttributeValueMapping.SetRange("Item Attribute ID", AttributeID);
        TempRecentlyItemAttributeValueMapping.DeleteAll();
        ClearBlankOptionAttributeNotification();
    end;

    procedure GetItemCategoryCode(): Code[20];
    begin
        exit(ItemCategoryCode);
    end;

    local procedure ShowBlankOptionAttributeNotification(AttributeName: Text[250])
    var
        BlankOptionNotification: Notification;
    begin
        BlankOptionNotification.Id := GetBlankOptionAttributeNotificationID();
        BlankOptionNotification.Message := StrSubstNo(BlankOptionAttributeNotificationMsg, AttributeName);
        BlankOptionNotification.Scope := NotificationScope::LocalScope;
        BlankOptionNotification.Send();
    end;

    local procedure ClearBlankOptionAttributeNotification()
    var
        BlankOptionNotification: Notification;
    begin
        BlankOptionNotification.Id := GetBlankOptionAttributeNotificationID();
        BlankOptionNotification.Recall();
    end;

    local procedure HasBlankOptionAttributes(): Boolean
    var
        ItemAttribute: Record "Item Attribute";
    begin
        if Rec.FindSet() then
            repeat
                if Rec.Value = '' then begin
                    ItemAttribute.SetLoadFields("Type");
                    ItemAttribute.Get(Rec."Attribute ID");
                    if ItemAttribute.Type = ItemAttribute.Type::Option then
                        exit(true);
                end;
            until Rec.Next() = 0;
        exit(false);
    end;

    local procedure InsertItemAttributeValueMapping(ItemCategory: Code[20]; AttributeID: Integer; AttributeValueID: Integer)
    var
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
    begin
        ItemAttributeValueMapping.Init();
        ItemAttributeValueMapping."Table ID" := DATABASE::"Item Category";
        ItemAttributeValueMapping."No." := ItemCategory;
        ItemAttributeValueMapping."Item Attribute ID" := AttributeID;
        ItemAttributeValueMapping."Item Attribute Value ID" := AttributeValueID;
        ItemAttributeValueMapping.Insert();
        InsertRecentlyAddedCategoryAttribute(ItemAttributeValueMapping);
    end;

    procedure GetBlankOptionAttributeNotificationID(): Guid
    begin
        exit('1ab28806-432f-46cc-844e-85b0fc36f883');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertRecordOnBeforeItemAttributeValueMappingInsert(var ItemAttributeValueMapping: Record "Item Attribute Value Mapping"; var ItemAttributeValue: Record "Item Attribute Value"; ItemAttributeValueSelection: Record "Item Attribute Value Selection")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLoadAttributesOnBeforeTempItemAttributeValueInsert(ItemAttributeValueMapping: Record "Item Attribute Value Mapping"; var TempItemAttributeValue: Record "Item Attribute Value" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSaveAttributesOnBeforeItemAttributeValueMappingInsert(var ItemAttributeValueMapping: Record "Item Attribute Value Mapping"; ItemAttributeValue: Record "Item Attribute Value")
    begin
    end;
}

