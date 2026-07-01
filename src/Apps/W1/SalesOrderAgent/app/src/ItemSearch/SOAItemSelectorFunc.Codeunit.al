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
        Confidence: Text;
    begin
        MatchingItems := '';
        AlternativeItems := '';

        // Parse per-item confidence payloads and separate into matching/alternative lists.
        if Arguments.Get('selected_items', ResultToken) then
            if ResultToken.IsArray() then begin
                SelectedItemsArray := ResultToken.AsArray();
                foreach ItemToken in SelectedItemsArray do
                    if ItemToken.IsObject() then begin
                        ItemObject := ItemToken.AsObject();
                        if ItemObject.Get('item_no', ResultToken) then
                            ItemNo := ResultToken.AsValue().AsText()
                        else
                            continue;

                        if ItemObject.Get('confidence', ResultToken) then
                            Confidence := ResultToken.AsValue().AsText()
                        else
                            continue;

                        if ItemNo = '' then
                            continue;

                        if Confidence = MatchingTok then
                            AddItemToList(MatchingItems, ItemNo)
                        else
                            if Confidence = AlternativeTok then
                                AddItemToList(AlternativeItems, ItemNo);
                    end;
            end;

        exit(MatchingItems);
    end;

    local procedure AddItemToList(var ItemList: Text; ItemNo: Text)
    begin
        ItemNo := ItemNo.Trim();
        ItemNo := DelChr(ItemNo, '=', '|');
        if ItemNo = '' then
            exit;

        if not IsAllowedItemNoFormat(ItemNo) then
            exit;

        if ItemList = '' then
            ItemList := ItemNo
        else
            ItemList += '|' + ItemNo;
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

    procedure GetName(): Text
    begin
        exit(FunctionNameTok);
    end;

    internal procedure GetSelectionResult(var MatchingItemsFilter: Text; var AlternativeItemsFilter: Text)
    begin
        MatchingItemsFilter := MatchingItems;
        AlternativeItemsFilter := AlternativeItems;
    end;
}
