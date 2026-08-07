// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

/// <summary>
/// Applies merchant normalization rules to corporate card transactions.
/// Normalizes raw merchant names using configured patterns and priority-based rules.
/// </summary>
codeunit 7210 EACorpCardMerchantNorm
{
    Access = Internal;

    internal procedure NormalizeTransaction(var CorpCardTrans: Record EACorpCardTrans)
    var
        NormalizedName: Text[100];
        MatchedCategory: Code[20];
    begin
        if CorpCardTrans."Merchant Raw" = '' then
            exit;

        if not FindMatchingRule(CorpCardTrans."Merchant Raw", NormalizedName, MatchedCategory) then begin
            CorpCardTrans."Merchant Norm" := CopyStr(CorpCardTrans."Merchant Raw", 1, MaxStrLen(CorpCardTrans."Merchant Norm"));
            exit;
        end;

        CorpCardTrans."Merchant Norm" := NormalizedName;
        if MatchedCategory <> '' then
            CorpCardTrans.MCC := '';
    end;

    local procedure FindMatchingRule(MerchantRaw: Text[100]; var NormalizedName: Text[100]; var MatchedCategory: Code[20]): Boolean
    var
        MerchantRule: Record EACorpCardMerchantRule;
    begin
        MerchantRule.SetRange(Active, true);
        MerchantRule.SetCurrentKey(Priority);

        if not MerchantRule.FindSet() then
            exit(false);

        repeat
            if PatternMatches(MerchantRaw, MerchantRule.Pattern) then begin
                NormalizedName := MerchantRule."Normalized Name";
                MatchedCategory := MerchantRule."Expense Category";
                exit(true);
            end;
        until MerchantRule.Next() = 0;

        exit(false);
    end;

    local procedure PatternMatches(MerchantName: Text; Pattern: Text): Boolean
    begin
        if Pattern = '' then
            exit(false);

        // Simple substring matching (supports patterns like "*hotel*", "*airline*", etc.)
        // Remove wildcards and check if pattern text exists in merchant name
        Pattern := DelChr(Pattern, '=', '*');
        exit(StrPos(LowerCase(MerchantName), LowerCase(Pattern)) > 0);
    end;
}
