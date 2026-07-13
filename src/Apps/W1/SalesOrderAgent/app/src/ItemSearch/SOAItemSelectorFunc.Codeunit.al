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
        MatchingItemVariants: Dictionary of [Text, Text];
        AlternativeItemVariants: Dictionary of [Text, Text];
        FunctionNameTok: Label 'select_best_matching_item', Locked = true;
        MatchingTok: Label 'matching', Locked = true;
        AlternativeTok: Label 'alternative', Locked = true;

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
        Confidence: Text;
    begin
        MatchingItems := '';
        AlternativeItems := '';
        Clear(MatchingItemVariants);
        Clear(AlternativeItemVariants);

        // Parse per-item confidence payloads and separate into matching/alternative lists.
        if Arguments.Get('selected_items', ResultToken) then
            if ResultToken.IsArray() then begin
                SelectedItemsArray := ResultToken.AsArray();
                foreach ItemToken in SelectedItemsArray do
                    if ItemToken.IsObject() then begin
                        ItemNo := '';
                        VariantCode := '';
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

        if ItemList = '' then
            ItemList := ItemNo
        else
            ItemList += '|' + ItemNo;

        exit(true);
    end;

    local procedure AddVariantCodeToDictionary(var ItemVariants: Dictionary of [Text, Text]; ItemNo: Text; VariantCode: Text)
    begin
        VariantCode := VariantCode.Trim();
        if not IsAllowedVariantCodeFormat(VariantCode) then
            VariantCode := '';

        if not ItemVariants.ContainsKey(ItemNo) then
            ItemVariants.Add(ItemNo, VariantCode);
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

            // Reject control characters (0-31), pipe (124), and DEL (127).
            if (CharCode <= 31) or (CharCode = 124) or (CharCode = 127) then
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

    internal procedure GetSelectionResultWithVariants(var MatchingItemsFilter: Text; var AlternativeItemsFilter: Text; var MatchingVariants: Dictionary of [Text, Text]; var AlternativeVariants: Dictionary of [Text, Text])
    begin
        GetSelectionResult(MatchingItemsFilter, AlternativeItemsFilter);
        MatchingVariants := MatchingItemVariants;
        AlternativeVariants := AlternativeItemVariants;
    end;
}
