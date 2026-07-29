// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.SalesOrderAgent;

using System.AI;

codeunit 4416 "SOA Item Selector Func" implements "AOAI Function"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        MatchingItems: Text;
        AlternativeItems: Text;
        MatchingItemVariants: Dictionary of [Text, List of [Code[10]]];
        AlternativeItemVariants: Dictionary of [Text, List of [Code[10]]];
        UnresolvedVariantRequests: Dictionary of [Text, Boolean];
        FunctionNameTok: Label 'select_best_matching_item', Locked = true;
        MatchingTok: Label 'matching', Locked = true;
        AlternativeTok: Label 'alternative', Locked = true;
        UnresolvedInterchangeableTok: Label 'unresolved_interchangeable', Locked = true;
        UnresolvedNonInterchangeableTok: Label 'unresolved_non_interchangeable', Locked = true;

    [NonDebuggable]
    procedure GetPrompt(): JsonObject
    var
        SOAInstructions: Codeunit "SOA Instructions";
        PromptJson: JsonObject;
    begin
        PromptJson.ReadFrom(SOAInstructions.GetItemSelectorPrompt().Unwrap());
        exit(PromptJson);
    end;

    procedure Execute(Arguments: JsonObject): Variant
    var
        ResultToken, ItemToken : JsonToken;
        SelectedItemsArray: JsonArray;
        ItemObject: JsonObject;
        ItemNo: Text;
        VariantCode: Text;
        VariantResolution: Text;
        Confidence: Text;
        AlternativesAllowed: Boolean;
    begin
        MatchingItems := '';
        AlternativeItems := '';
        Clear(MatchingItemVariants);
        Clear(AlternativeItemVariants);
        Clear(UnresolvedVariantRequests);

        // Parse per-item confidence payloads and separate into matching/alternative lists.
        if Arguments.Get('selected_items', ResultToken) then
            if ResultToken.IsArray() then begin
                SelectedItemsArray := ResultToken.AsArray();
                foreach ItemToken in SelectedItemsArray do
                    if ItemToken.IsObject() then begin
                        ItemNo := '';
                        VariantCode := '';
                        VariantResolution := '';
                        Confidence := '';
                        ItemObject := ItemToken.AsObject();
                        if ItemObject.Get('item_no', ResultToken) then
                            ItemNo := ResultToken.AsValue().AsText()
                        else
                            continue;

                        if ItemObject.Get('variant_code', ResultToken) then
                            VariantCode := ResultToken.AsValue().AsText();

                        if ItemObject.Get('confidence', ResultToken) then
                            Confidence := ResultToken.AsValue().AsText()
                        else
                            continue;

                        if ItemNo = '' then
                            continue;

                        if Confidence = MatchingTok then begin
                            if AddItemToList(MatchingItems, ItemNo) then
                                AddVariantCodeToDictionary(MatchingItemVariants, ItemNo, VariantCode);
                        end
                        else
                            if Confidence = AlternativeTok then
                                if AddItemToList(AlternativeItems, ItemNo) then
                                    AddVariantCodeToDictionary(AlternativeItemVariants, ItemNo, VariantCode);

                        if ItemObject.Get('variant_resolution', ResultToken) then
                            VariantResolution := ResultToken.AsValue().AsText();
                        case VariantResolution of
                            UnresolvedInterchangeableTok:
                                if not UnresolvedVariantRequests.ContainsKey(ItemNo) then
                                    UnresolvedVariantRequests.Add(ItemNo, true);
                            UnresolvedNonInterchangeableTok:
                                if not UnresolvedVariantRequests.ContainsKey(ItemNo) then
                                    UnresolvedVariantRequests.Add(ItemNo, false);
                        end;
                    end;
            end;

        if Arguments.Get('unresolved_variant_requests', ResultToken) then
            if ResultToken.IsArray() then begin
                SelectedItemsArray := ResultToken.AsArray();
                foreach ItemToken in SelectedItemsArray do
                    if ItemToken.IsObject() then begin
                        ItemObject := ItemToken.AsObject();
                        if not ItemObject.Get('item_no', ResultToken) then
                            continue;
                        ItemNo := ResultToken.AsValue().AsText().Trim();
                        if not IsAllowedItemNoFormat(ItemNo) then
                            continue;

                        if not ItemObject.Get('alternatives_allowed', ResultToken) then
                            continue;
                        AlternativesAllowed := ResultToken.AsValue().AsBoolean();

                        if not UnresolvedVariantRequests.ContainsKey(ItemNo) then
                            UnresolvedVariantRequests.Add(ItemNo, AlternativesAllowed);
                    end;
            end;

        exit(MatchingItems);
    end;

    local procedure AddItemToList(var ItemList: Text; var ItemNo: Text): Boolean
    begin
        ItemNo := ItemNo.Trim();
        ItemNo := DelChr(ItemNo, '=', '|');
        if ItemNo = '' then
            exit(false);

        if not IsAllowedItemNoFormat(ItemNo) then
            exit(false);

        if ItemNoAlreadyInList(ItemList, ItemNo) then
            exit(true);

        if ItemList = '' then
            ItemList := ItemNo
        else
            ItemList += '|' + ItemNo;

        exit(true);
    end;

    local procedure ItemNoAlreadyInList(ItemList: Text; ItemNo: Text): Boolean
    var
        ExistingItemNo: Text;
    begin
        if ItemList = '' then
            exit(false);

        foreach ExistingItemNo in ItemList.Split('|') do
            if ExistingItemNo = ItemNo then
                exit(true);

        exit(false);
    end;

    local procedure AddVariantCodeToDictionary(var ItemVariants: Dictionary of [Text, List of [Code[10]]]; ItemNo: Text; VariantCodeText: Text)
    var
        VariantCodes: List of [Code[10]];
        VariantCode: Code[10];
    begin
        VariantCodeText := VariantCodeText.Trim();
        if IsAllowedVariantCodeFormat(VariantCodeText) then
            VariantCode := CopyStr(VariantCodeText, 1, MaxStrLen(VariantCode));

        if ItemVariants.ContainsKey(ItemNo) then
            VariantCodes := ItemVariants.Get(ItemNo);

        if (VariantCode <> '') and not VariantCodes.Contains(VariantCode) then
            VariantCodes.Add(VariantCode);

        if ItemVariants.ContainsKey(ItemNo) then
            ItemVariants.Set(ItemNo, VariantCodes)
        else
            ItemVariants.Add(ItemNo, VariantCodes);
    end;

    local procedure IsAllowedItemNoFormat(ItemNo: Text): Boolean
    var
        CharTxt: Text[1];
        CharCode: Integer;
        i: Integer;
    begin
        if (ItemNo = '') or (StrLen(ItemNo) > 20) then
            exit(false);

        for i := 1 to StrLen(ItemNo) do begin
            CharTxt := CopyStr(ItemNo, i, 1);
            CharCode := CharTxt[1];

            // Reject control characters (0-31), pipe (124), and DEL (127).
            if (CharCode <= 31) or (CharCode = 124) or (CharCode = 127) then
                exit(false);
        end;

        exit(true);
    end;

    local procedure IsAllowedVariantCodeFormat(VariantCode: Text): Boolean
    var
        CharTxt: Text[1];
        CharCode: Integer;
        i: Integer;
    begin
        if VariantCode = '' then
            exit(true);

        if StrLen(VariantCode) > 10 then
            exit(false);

        for i := 1 to StrLen(VariantCode) do begin
            CharTxt := CopyStr(VariantCode, i, 1);
            CharCode := CharTxt[1];

            // Reject control characters (0-31) and DEL (127).
            if (CharCode <= 31) or (CharCode = 127) then
                exit(false);
        end;

        exit(true);
    end;

    procedure GetName(): Text
    begin
        exit(FunctionNameTok);
    end;

    internal procedure GetSelectionResult(var MatchingItemsFilter: Text; var AlternativeItemsFilter: Text)
    begin
        MatchingItemsFilter := MatchingItems;
        AlternativeItemsFilter := AlternativeItems;
    end;

    internal procedure GetSelectionResultWithVariants(var MatchingItemsFilter: Text; var AlternativeItemsFilter: Text; var MatchingVariants: Dictionary of [Text, List of [Code[10]]]; var AlternativeVariants: Dictionary of [Text, List of [Code[10]]])
    begin
        GetSelectionResult(MatchingItemsFilter, AlternativeItemsFilter);
        MatchingVariants := MatchingItemVariants;
        AlternativeVariants := AlternativeItemVariants;
    end;

    internal procedure GetSelectionResultWithVariantsAndUnresolvedRequests(var MatchingItemsFilter: Text; var AlternativeItemsFilter: Text; var MatchingVariants: Dictionary of [Text, List of [Code[10]]]; var AlternativeVariants: Dictionary of [Text, List of [Code[10]]]; var UnresolvedRequests: Dictionary of [Text, Boolean])
    begin
        GetSelectionResultWithVariants(MatchingItemsFilter, AlternativeItemsFilter, MatchingVariants, AlternativeVariants);
        UnresolvedRequests := UnresolvedVariantRequests;
    end;
}
