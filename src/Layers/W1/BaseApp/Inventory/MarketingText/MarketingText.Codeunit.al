// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.MarketingText;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Attribute;
using System.Text;

codeunit 5825 "Marketing Text"
{
    procedure EditMarketingText(ItemNo: Code[20])
    var
        TempEntityText: Record "Entity Text" temporary;
        EntityTextRec: Record "Entity Text";
        Item: Record Item;
        PageId: Integer;
    begin
        if not Item.Get(ItemNo) then
            exit;

        if not EntityTextRec.Get(CompanyName(), Database::Item, Item.SystemId, Enum::"Entity Text Scenario"::"Marketing Text") then begin
            EntityTextRec.Init();
            EntityTextRec.Company := CopyStr(CompanyName(), 1, MaxStrLen(EntityTextRec.Company));
            EntityTextRec."Source Table Id" := Database::Item;
            EntityTextRec."Source System Id" := Item.SystemId;
            EntityTextRec.Scenario := Enum::"Entity Text Scenario"::"Marketing Text";
            EntityTextRec.Insert();
            Commit();
        end;

        EntityTextRec.CalcFields(Text);
        TempEntityText.TransferFields(EntityTextRec, true);
        TempEntityText.Insert();

        PageId := Page::"Modify Marketing Text";

        if not (Page.RunModal(PageId, TempEntityText) in [Action::OK, Action::LookupOK]) then
            exit;

        TempEntityText.CalcFields(Text);
        EntityTextRec.TransferFields(TempEntityText, false);
        EntityTextRec.Modify();
    end;

    procedure GetMaximumFacts(): Integer
    begin
        // Product name is not counted towards this limit, so overall number of facts might be 16.
        exit(15);
    end;

    procedure IsMarketingTextVisible(): Boolean
    var
        EntityText: Record "Entity Text";
    begin
        exit(EntityText.ReadPermission());
    end;

    internal procedure GetItemRecordFactCount(var Facts: Dictionary of [Text, Text]): Integer
    var
        ItemRecordFacts: Integer;
    begin
        ItemRecordFacts := 0;
        if Facts.ContainsKey(ProductNameTxt) then
            ItemRecordFacts += 1;

        if Facts.ContainsKey(ItemCategoryTxt) then
            ItemRecordFacts += 1;

        exit(ItemRecordFacts);
    end;

    local procedure AddItemAttributeFacts(ItemNo: Code[20]; var Facts: Dictionary of [Text, Text])
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemAttributeValue: Record "Item Attribute Value";
    begin
        ItemAttributeValueMapping.SetRange("Table ID", Database::Item);
        ItemAttributeValueMapping.SetRange("No.", ItemNo);

        if ItemAttributeValueMapping.FindSet() then
            repeat
                if ItemAttribute.Get(ItemAttributeValueMapping."Item Attribute ID") and (not ItemAttribute.Blocked) then
                    if ItemAttributeValue.Get(ItemAttributeValueMapping."Item Attribute ID", ItemAttributeValueMapping."Item Attribute Value ID") then
                        if ItemAttributeValue.Value.Trim() <> '' then
                            if ItemAttribute.Type in [ItemAttribute.Type::Integer, ItemAttribute.Type::Decimal] then
                                Facts.Add(ItemAttribute.Name, ItemAttributeValue.Value + ' ' + ItemAttribute."Unit of Measure")
                            else
                                Facts.Add(ItemAttribute.Name, ItemAttributeValue.Value);
            until ItemAttributeValueMapping.Next() = 0;
    end;

    local procedure BuildFacts(Item: Record Item; var Facts: Dictionary of [Text, Text])
    var
        ItemCategory: Record "Item Category";
    begin
        Facts.Add(ProductNameTxt, Item.Description);

        if ItemCategory.Get(Item."Item Category Code") then
            if ItemCategory.Description <> '' then
                Facts.Add(ItemCategoryTxt, ItemCategory.Description)
            else
                Facts.Add(ItemCategoryTxt, ItemCategory.Code);

        AddItemAttributeFacts(Item."No.", Facts);
    end;

    internal procedure CreateWithCopilot(var TempEntityText: Record "Entity Text" temporary; PromptMode: PromptMode; var Action: Action)
    var
        EntityText: Codeunit "Entity Text";
        CopilotMarketingText: Page "Copilot Marketing Text";
        AllFacts: Dictionary of [Text, Text];
        Tone: Enum "Entity Text Tone";
        TextFormat: Enum "Entity Text Format";
        Handled: Boolean;
    begin
        if EntityText.CanSuggest() then begin
            EntityText.OnRequestEntityContext(TempEntityText."Source Table Id", TempEntityText."Source System Id", TempEntityText.Scenario, AllFacts, Tone, TextFormat, Handled);
            CopilotMarketingText.SetItemFacts(AllFacts);
            CopilotMarketingText.SetTone(Tone);
            CopilotMarketingText.SetTextFormat(TextFormat);
            CopilotMarketingText.SetPromptMode(PromptMode);
            Action := CopilotMarketingText.RunModal();
            if Action = Action::OK then begin
                EntityText.UpdateText(TempEntityText, CopilotMarketingText.GetMarketingText());
                TempEntityText.Modify();
            end;
        end
        else
            Session.LogMessage('0000LJ3', TelemetryEntityCannotSuggestTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryLbl);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Entity Text", 'OnRequestEntityContext', '', true, true)]
    local procedure OnRequestEntityContext(SourceTableId: Integer; SourceSystemId: Guid; SourceScenario: Enum "Entity Text Scenario"; var Facts: Dictionary of [Text, Text]; var TextTone: Enum "Entity Text Tone"; var TextFormat: Enum "Entity Text Format"; var Handled: Boolean)
    var
        Item: Record Item;
    begin
        if Handled then
            exit;

        if SourceScenario <> SourceScenario::"Marketing Text" then
            exit;

        if SourceTableId <> Database::Item then
            exit;

        if IsNullGuid(SourceSystemId) then
            Error(NoItemDescriptionErr); // The item is not inserted yet

        if not Item.GetBySystemId(SourceSystemId) then begin
            Session.LogMessage('0000JXY', TelemetrySystemIdNotFoundTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryLbl);
            exit;
        end;

        if Item.Description = '' then
            Error(NoItemDescriptionErr);

        BuildFacts(Item, Facts);

        if Facts.Count() < 2 then
            Error(NotEnoughInfoErr);

        TextTone := TextTone::Inspiring;

        TextFormat := TextFormat::TaglineParagraph;
        if Facts.Count() < 4 then // If there are less than 4 facts generate a tagline
            TextFormat := TextFormat::Tagline;

        Handled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Entity Text", 'OnEditEntityTextWithTriggerAction', '', true, true)]
    local procedure OnEditEntityTextWithTriggerAction(var TempEntityText: Record "Entity Text" temporary; var Action: Action; var Handled: Boolean; TriggerAction: Enum "Entity Text Actions")
    var
        Item: Record Item;
    begin
        if Handled then
            exit;

        if TempEntityText.Scenario <> TempEntityText.Scenario::"Marketing Text" then
            exit;

        if TempEntityText."Source Table Id" <> Database::Item then
            exit;

        if not Item.GetBySystemId(TempEntityText."Source System Id") then begin
            Session.LogMessage('0000JXZ', TelemetrySystemIdNotFoundTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryLbl);
            exit;
        end;

        case TriggerAction of
            Enum::"Entity Text Actions"::Edit:
                Action := Page.RunModal(Page::"Modify Marketing Text", TempEntityText);
            Enum::"Entity Text Actions"::Create:
                CreateWithCopilot(TempEntityText, PromptMode::Generate, Action);
            else
                Session.LogMessage('0000LIL', StrSubstNo(TelemetryTriggerActionNotSupportedTxt, TriggerAction), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryLbl);

        end;

        Handled := true;
    end;

    var
        NoItemDescriptionErr: Label 'Please provide a description for the item.';
        NotEnoughInfoErr: Label 'There''s not enough information to draft a text. You can provide more by setting an item category and item attributes.';
        TelemetryCategoryLbl: Label 'Marketing Text', Locked = true;
        TelemetrySystemIdNotFoundTxt: Label 'Entity Text was requested for an item that does not exist', Locked = true;
        TelemetryEntityCannotSuggestTxt: Label 'Entity Text generation was attempted with feature disabled or incorrectly configured.', Locked = true;
        TelemetryTriggerActionNotSupportedTxt: Label 'Entity Text was requested with an action that is not supported: %1', Locked = true;
        ProductNameTxt: Label 'Product Name', Locked = true;
        ItemCategoryTxt: Label 'Item Category', Locked = true;
}
