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
        SelectionResultValid: Boolean;
        SelectionResultFailureCategory: Text;
        FunctionNameTok: Label 'select_best_matching_item', Locked = true;
        MatchingTok: Label 'matching', Locked = true;
        AlternativeTok: Label 'alternative', Locked = true;
        NotRequestedTok: Label 'not_requested', Locked = true;
        SafeSubstitutionTok: Label 'safe', Locked = true;
        UnsafeSubstitutionTok: Label 'unsafe', Locked = true;
        NotApplicableSubstitutionTok: Label 'not_applicable', Locked = true;
        MalformedFunctionResponseFailureTok: Label 'MalformedFunctionResponse', Locked = true;
        InvalidItemNumberFailureTok: Label 'InvalidItemNumber', Locked = true;
        InvalidVariantCodeFailureTok: Label 'InvalidVariantCode', Locked = true;
        RejectedVariantMatchCombinationFailureTok: Label 'RejectedVariantMatchCombination', Locked = true;

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
        ResultToken: JsonToken;
        SelectedItemsArray: JsonArray;
    begin
        MatchingItems := '';
        AlternativeItems := '';
        Clear(MatchingItemVariants);
        Clear(AlternativeItemVariants);
        SelectionResultValid := false;
        SelectionResultFailureCategory := MalformedFunctionResponseFailureTok;

        if not Arguments.Get('selected_items', ResultToken) or not ResultToken.IsArray() then
            exit;
        SelectedItemsArray := ResultToken.AsArray();
        if not ParseSelectedItems(SelectedItemsArray) then
            exit;

        SelectionResultValid := true;
        SelectionResultFailureCategory := '';

        exit(MatchingItems);
    end;

    local procedure ParseSelectedItems(SelectedItemsArray: JsonArray): Boolean
    var
        ItemToken: JsonToken;
        ResultToken: JsonToken;
        ItemObject: JsonObject;
        Confidence: Text;
        ItemNo: Text;
        VariantCode: Text;
        VariantMatch: Text;
        VariantSubstitutionSafety: Text;
    begin
        foreach ItemToken in SelectedItemsArray do begin
            if not ItemToken.IsObject() then
                exit(false);

            ItemObject := ItemToken.AsObject();
            if not ItemObject.Get('item_no', ResultToken) or not ResultToken.IsValue() then
                exit(SetSelectionResultFailure(InvalidItemNumberFailureTok));
            ItemNo := ResultToken.AsValue().AsText().Trim();
            if not IsAllowedItemNoFormat(ItemNo) then
                exit(SetSelectionResultFailure(InvalidItemNumberFailureTok));

            VariantCode := '';
            if ItemObject.Get('variant_code', ResultToken) then begin
                if not ResultToken.IsValue() then
                    exit(SetSelectionResultFailure(InvalidVariantCodeFailureTok));
                VariantCode := ResultToken.AsValue().AsText().Trim();
            end;
            if not IsAllowedVariantCodeFormat(VariantCode) then
                exit(SetSelectionResultFailure(InvalidVariantCodeFailureTok));

            if not ItemObject.Get('variant_match', ResultToken) or not ResultToken.IsValue() then
                exit(SetSelectionResultFailure(RejectedVariantMatchCombinationFailureTok));
            VariantMatch := ResultToken.AsValue().AsText();
            if (VariantMatch <> MatchingTok) and (VariantMatch <> AlternativeTok) and (VariantMatch <> NotRequestedTok) then
                exit(SetSelectionResultFailure(RejectedVariantMatchCombinationFailureTok));
            if ((VariantCode = '') and (VariantMatch <> NotRequestedTok)) or
               ((VariantCode <> '') and (VariantMatch = NotRequestedTok))
            then
                exit(SetSelectionResultFailure(RejectedVariantMatchCombinationFailureTok));

            VariantSubstitutionSafety := NotApplicableSubstitutionTok;
            if ItemObject.Get('variant_substitution_safety', ResultToken) then begin
                if not ResultToken.IsValue() then
                    exit(SetSelectionResultFailure(RejectedVariantMatchCombinationFailureTok));
                VariantSubstitutionSafety := ResultToken.AsValue().AsText();
            end;
            if (VariantSubstitutionSafety <> SafeSubstitutionTok) and
               (VariantSubstitutionSafety <> UnsafeSubstitutionTok) and
               (VariantSubstitutionSafety <> NotApplicableSubstitutionTok)
            then
                if VariantMatch = AlternativeTok then
                    continue
                else
                    exit(SetSelectionResultFailure(RejectedVariantMatchCombinationFailureTok));
            if (VariantMatch = AlternativeTok) and (VariantSubstitutionSafety <> SafeSubstitutionTok) then
                continue;

            if not ItemObject.Get('confidence', ResultToken) or not ResultToken.IsValue() then
                exit(false);
            Confidence := ResultToken.AsValue().AsText();
            if (Confidence <> MatchingTok) and (Confidence <> AlternativeTok) then
                exit(false);
            if (Confidence = MatchingTok) and (VariantMatch = AlternativeTok) then
                Confidence := AlternativeTok;

            if not ItemObject.Get('reason', ResultToken) or not ResultToken.IsValue() then
                exit(false);

            if Confidence = MatchingTok then begin
                if not AddItemToList(MatchingItems, ItemNo) then
                    exit(SetSelectionResultFailure(InvalidItemNumberFailureTok));
                AddVariantCodeToDictionary(MatchingItemVariants, ItemNo, VariantCode);
            end else begin
                if not AddItemToList(AlternativeItems, ItemNo) then
                    exit(SetSelectionResultFailure(InvalidItemNumberFailureTok));
                AddVariantCodeToDictionary(AlternativeItemVariants, ItemNo, VariantCode);
            end;
        end;

        exit(true);
    end;

    local procedure SetSelectionResultFailure(FailureCategory: Text): Boolean
    begin
        SelectionResultFailureCategory := FailureCategory;
        exit(false);
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

    internal procedure IsSelectionResultValid(): Boolean
    begin
        exit(SelectionResultValid);
    end;

    internal procedure GetSelectionResultFailureCategory(): Text
    begin
        exit(SelectionResultFailureCategory);
    end;

    internal procedure GetSelectionResult(var MatchingItemsFilter: Text; var AlternativeItemsFilter: Text; var MatchingVariants: Dictionary of [Text, List of [Code[10]]]; var AlternativeVariants: Dictionary of [Text, List of [Code[10]]])
    begin
        MatchingItemsFilter := MatchingItems;
        AlternativeItemsFilter := AlternativeItems;
        MatchingVariants := MatchingItemVariants;
        AlternativeVariants := AlternativeItemVariants;
    end;

}
