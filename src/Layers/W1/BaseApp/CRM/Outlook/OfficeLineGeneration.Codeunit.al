// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Outlook;

using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using System;

codeunit 1639 "Office Line Generation"
{
    // This codeunit contains algorithms for finding item references within text.


    trigger OnRun()
    begin
    end;

    var
        NumbersTxt: Label 'one|two|three|four|five|six|seven|eight|nine|ten', Comment = 'This is a ''|'' separated list of cardinal numbers from one to ten. This is used to find mentions of quantities of certain items.';
        RestrictedWordsTxt: Label 'and|for|the', Comment = 'Words that should not be used to find items in the item table (separated by "|").';
        TelemetryClosedPageTxt: Label 'Suggested line items closed via %2 action.%1  Items Suggested: %3%1  Items selected: %4', Locked = true;
        TelemetryAlgorithmPerformanceTxt: Label 'Item generation algorithm finished in %2ms.%1  Length of mail body: %3%1  Total items found:   %4%1  Single item matches: %5%1  Total matched items: %6', Locked = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Office Document Handler", 'OnGenerateLinesFromText', '', false, false)]
    local procedure CreateLinesBasedOnQuantityReferences(var HeaderRecRef: RecordRef; var TempOfficeSuggestedLineItem: Record "Office Suggested Line Item" temporary; EmailBody: Text)
    var
        OfficeMgt: Codeunit "Office Management";
        Match: DotNet Match;
        Matches: DotNet MatchCollection;
        Regex: DotNet Regex;
        Stopwatch: DotNet Stopwatch;
        SanitizedBody: Text;
        QuantityText: Text;
        FoundPre: Integer;
        PreItemNo: Text[50];
        PreText: Text;
        StrengthPre: Decimal;
        FoundPost: Integer;
        PostItemNo: Text[50];
        PostText: Text;
        StrengthPost: Decimal;
        Quantity: Integer;
        SingleMatches: Integer;
        TotalMatches: Integer;
        AlreadyFound: Boolean;
        IsHandled: Boolean;
    begin
        // Searches for quantity keywords (1,2,..,999,one,two,..,nine) and takes the first four
        // words on either side of the keyword as the "pretext" and the "posttext". Using the
        // pretext and posttext values, we try to take substrings and find matches in the Item
        // table. If multiple matches are found, then we allow the user to resolve the item.
        IsHandled := false;
        OnBeforeCreateLinesBasedOnQuantityReferences(HeaderRecRef, TempOfficeSuggestedLineItem, EmailBody, IsHandled);
        if IsHandled then
            exit;

        // Measure the time it takes to find the items
        Stopwatch := Stopwatch.StartNew();

        // Find the words on each side of the quantity key word
        // Use negative lookahead to find overlapping matches
        Regex := Regex.Regex(StrSubstNo('((\w+ ?){0,4}\s+(?!>=(\d{1,3}|%1)))(?=(\d{1,3}|%1)\s+?((\w+ ?){0,4}))', NumbersTxt));
        Matches := Regex.Matches(EmailBody);

        // Get rid of insignificant words
        SanitizedBody := SanitizeText(EmailBody, 2);

        foreach Match in Matches do begin
            PreItemNo := '';
            PostItemNo := '';
            FoundPre := 0;

            PreText := SanitizeText(Match.Groups.Item(1).Value, 3);
            PostText := SanitizeText(Match.Groups.Item(5).Value, 3);
            QuantityText := Match.Groups.Item(4).Value();

            FoundPre := FindItemFromText(PreItemNo, PreText, SanitizedBody, ' ', true);
            AlreadyFound := ItemAlreadyFound(TempOfficeSuggestedLineItem, PreItemNo);
            StrengthPre := CalculateMatchStrength(PreItemNo, FoundPre, PreText, AlreadyFound);

            FoundPost := FindItemFromText(PostItemNo, PostText, SanitizedBody, ' ', true);
            AlreadyFound := ItemAlreadyFound(TempOfficeSuggestedLineItem, PostItemNo);
            StrengthPost := CalculateMatchStrength(PostItemNo, FoundPost, PostText, AlreadyFound);

            ConvertToInteger(Quantity, QuantityText);
            if (StrengthPre > 0) and (StrengthPre > StrengthPost) then
                InsertSuggestedLineItem(TempOfficeSuggestedLineItem, PreItemNo, PreText, Quantity, FoundPre)
            else
                if StrengthPost > 0 then
                    InsertSuggestedLineItem(TempOfficeSuggestedLineItem, PostItemNo, PostText, Quantity, FoundPost)
        end;

        Stopwatch.Stop();
        GetMatchTotals(TempOfficeSuggestedLineItem, SingleMatches, TotalMatches);
        Session.LogMessage('00001KH', StrSubstNo(TelemetryAlgorithmPerformanceTxt, NewLine(),
            Stopwatch.ElapsedMilliseconds,
            StrLen(EmailBody),
            TempOfficeSuggestedLineItem.Count,
            SingleMatches,
            TotalMatches), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', OfficeMgt.GetOfficeAddinTelemetryCategory());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Office Document Handler", 'OnGenerateLinesFromText', '', false, false)]
    local procedure CreateLinesBasedOnItemReferences(var HeaderRecRef: RecordRef; var TempOfficeSuggestedLineItem: Record "Office Suggested Line Item" temporary; EmailBody: Text)
    var
        OfficeMgt: Codeunit "Office Management";
        Match: DotNet Match;
        Regex: DotNet Regex;
        Stopwatch: DotNet Stopwatch;
        Word: DotNet String;
        WordMatches: DotNet MatchCollection;
        SanitizedBody: Text;
        ItemNo: Text[50];
        BestItem: Text[50];
        BestText: Text;
        BestCount: Integer;
        BestStrength: Decimal;
        SingleMatches: Integer;
        TotalMatches: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateLinesBasedOnItemReferences(HeaderRecRef, TempOfficeSuggestedLineItem, EmailBody, IsHandled);
        if IsHandled then
            exit;

        if not TempOfficeSuggestedLineItem.IsEmpty() then
            exit;

        Stopwatch := Stopwatch.StartNew();

        SanitizedBody := SanitizeText(EmailBody, 2);
        Regex := Regex.Regex('([\w\d]{3,})');
        WordMatches := Regex.Matches(SanitizedBody);

        foreach Match in WordMatches do begin
            ItemNo := '';
            BestCount := 999999;
            BestStrength := 0;
            BestText := '';
            BestItem := '';
            Word := StrSubstNo('%1', Match.Value);
            if PerformSearch(ItemNo, Word, BestCount, BestText, BestItem, BestStrength, SanitizedBody, true) then
                InsertSuggestedLineItem(TempOfficeSuggestedLineItem, ItemNo, Match.Value, 0, BestCount);
        end;

        Stopwatch.Stop();
        GetMatchTotals(TempOfficeSuggestedLineItem, SingleMatches, TotalMatches);
        Session.LogMessage('00001KI', StrSubstNo(TelemetryAlgorithmPerformanceTxt, NewLine(),
            Stopwatch.ElapsedMilliseconds,
            StrLen(EmailBody),
            TempOfficeSuggestedLineItem.Count,
            SingleMatches,
            TotalMatches), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', OfficeMgt.GetOfficeAddinTelemetryCategory());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Office Document Handler", 'OnCloseSuggestedLineItemsPage', '', false, false)]
    local procedure CreateLineItemsOnCloseSuggestedLineItems(var TempOfficeSuggestedLineItem: Record "Office Suggested Line Item" temporary; var HeaderRecRef: RecordRef; PageCloseAction: Action)
    var
        OfficeMgt: Codeunit "Office Management";
        AddedCount: Integer;
    begin
        if PageCloseAction in [ACTION::OK, ACTION::LookupOK] then
            if TempOfficeSuggestedLineItem.FindSet() then
                repeat
                    if TempOfficeSuggestedLineItem.Add then begin
                        InsertLineItem(HeaderRecRef, TempOfficeSuggestedLineItem."Item No.", TempOfficeSuggestedLineItem.Quantity);
                        AddedCount += 1;
                    end;
                until TempOfficeSuggestedLineItem.Next() = 0;

        Session.LogMessage('00001KJ', StrSubstNo(TelemetryClosedPageTxt, NewLine(),
            PageCloseAction,
            TempOfficeSuggestedLineItem.Count,
            AddedCount), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', OfficeMgt.GetOfficeAddinTelemetryCategory());
    end;

    local procedure CalculateMatchStrength(ItemNo: Text[50]; Matches: Integer; SearchText: Text; AlreadyFound: Boolean) Strength: Decimal
    var
        Item: Record Item;
    begin
        // Determines the strength of the matched item or items based on the length
        // of the search text that was used to find those items and how close the search text
        // is to the actual description of the item.

        case true of
            Matches = 0:
                Strength := 0;
            (Matches = 1) and AlreadyFound:
                Strength := 0.01;
            (Matches = 1) and Item.Get(ItemNo):
                Strength := 1 + ((StrLen(SearchText) / StrLen(Item.Description)) * (StrLen(SearchText) / StrLen(Item.Description)));
            Matches > 1:
                Strength := 1 + (1 / Matches) - (1 / (1 + StrLen(SearchText)));
        end;

        if AlreadyFound then
            Strength *= (1 - (1 / (Matches + 1))); // Strength is weakened if the item has already been found. More so if there are fewer matches.
    end;

    local procedure ConvertToInteger(var NumberValue: Integer; NumberText: Text)
    var
        NumbersList: DotNet IList;
        NumbersString: DotNet String;
        Separator: DotNet String;
    begin
        if Evaluate(NumberValue, NumberText) then
            exit;

        NumbersString := NumbersTxt;
        Separator := '|';
        NumbersList := NumbersString.Split(Separator.ToCharArray());
        NumberValue := NumbersList.IndexOf(NumberText) + 1;
    end;

    local procedure FindItemFromText(var ItemNo: Text[50]; var SearchText: Text; EmailBody: Text; Separator: Text; Recurse: Boolean): Integer
    var
        TermsArray: DotNet Array;
        SearchTerms: DotNet String;
        SeparatorString: DotNet String;
        i: Integer;
        "Count": Integer;
        BestCount: Integer;
        BestText: Text;
        BestItem: Text[50];
        BestStrength: Decimal;
    begin
        if StrLen(SearchText) < 3 then
            exit(0);

        SeparatorString := Separator;
        SearchTerms := DelChr(SearchText, '<>', ' ');
        TermsArray := SearchTerms.Split(SeparatorString.ToCharArray());
        Count := TermsArray.Length;

        BestCount := 999999; // Sentinel value

        PerformSearch(ItemNo, SearchText, BestCount, BestText, BestItem, BestStrength, EmailBody, Recurse);

        // Try to resolve the item. The best search is the search that yields the lowest, non-zero number of results.
        for i := 1 to Count - 1 do begin
            // Try with the last (n - i) words of the search phrase
            SearchText := OmitFirst(TermsArray, i, Separator);
            PerformSearch(ItemNo, SearchText, BestCount, BestText, BestItem, BestStrength, EmailBody, Recurse);

            // Try with the first (n - i) words of the search phrase
            SearchText := OmitLast(TermsArray, i, Separator);
            PerformSearch(ItemNo, SearchText, BestCount, BestText, BestItem, BestStrength, EmailBody, Recurse);

            // Try with the ith word of the search phrase
            SearchText := TermsArray.GetValue(i);
            PerformSearch(ItemNo, SearchText, BestCount, BestText, BestItem, BestStrength, EmailBody, Recurse);
        end;

        if BestCount < 999999 then begin
            SearchText := BestText;
            ItemNo := BestItem;
            exit(BestCount);
        end;
    end;

    local procedure FindItemsByDescription(var ItemNo: Text; Description: Text) FoundCount: Integer
    var
        Item: Record Item;
        SearchText: Text;
    begin
        // Searches for items by the specified description.
        // (1) Look for the item no.
        // (2) Look for an exact match on the description
        // (3) Look for items that start with the description
        // (4) Look for items that include the description

        Item.SetRange("No.", CopyStr(Description, 1, 20));
        if not Item.IsEmpty() then begin
            FoundCount := Item.Count();
            Item.FindFirst();
            ItemNo := Item."No.";
            exit;
        end;
        Item.SetRange("No.");

        SearchText := '''@' + Description + '''';
        Item.SetFilter(Description, Description);
        if not Item.IsEmpty() then begin
            FoundCount := Item.Count();
            Item.FindFirst();
            ItemNo := Item."No.";
            exit;
        end;

        SearchText := '''@' + Description + '*''';
        Item.SetFilter(Description, SearchText);
        if not Item.IsEmpty() then begin
            FoundCount := Item.Count();
            Item.FindFirst();
            ItemNo := Item."No.";
            exit;
        end;

        SearchText := '''@* ' + Description + '*''';
        Item.SetFilter(Description, SearchText);
        if not Item.IsEmpty() then begin
            FoundCount := Item.Count();
            Item.FindFirst();
            ItemNo := Item."No.";
            exit;
        end;
    end;

    local procedure GetMatchTotals(var TempOfficeSuggestedLineItem: Record "Office Suggested Line Item" temporary; var SingleMatches: Integer; var TotalMatches: Integer)
    begin
        TempOfficeSuggestedLineItem.SetRange(Matches, 1);
        SingleMatches := TempOfficeSuggestedLineItem.Count();
        TempOfficeSuggestedLineItem.SetRange(Matches);

        if TempOfficeSuggestedLineItem.FindSet() then
            repeat
                TotalMatches += TempOfficeSuggestedLineItem.Matches;
            until TempOfficeSuggestedLineItem.Next() = 0;
    end;

    local procedure ItemAlreadyFound(var TempOfficeSuggestedLineItem: Record "Office Suggested Line Item" temporary; ItemNo: Text) Found: Boolean
    begin
        TempOfficeSuggestedLineItem.SetRange("Item No.", ItemNo);
        Found := not TempOfficeSuggestedLineItem.IsEmpty();
        TempOfficeSuggestedLineItem.SetRange("Item No.");
    end;

    local procedure InsertSuggestedLineItem(var TempOfficeSuggestedLineItem: Record "Office Suggested Line Item" temporary; ItemNo: Text[50]; SearchKeyword: Text; Quantity: Integer; Matches: Integer)
    var
        LastLineNo: Integer;
    begin
        if (Matches = 0) or (SearchKeyword = '') then
            exit;

        if not TempOfficeSuggestedLineItem.IsEmpty() then
            TempOfficeSuggestedLineItem.FindLast();

        LastLineNo := TempOfficeSuggestedLineItem."Line No.";

        if Matches > 1 then
            TempOfficeSuggestedLineItem.SetRange("Item Description", CopyStr(SearchKeyword, 1, 50))
        else
            TempOfficeSuggestedLineItem.SetRange("Item No.", ItemNo);

        if TempOfficeSuggestedLineItem.FindFirst() then begin
            if (TempOfficeSuggestedLineItem.Quantity = 0) and (Quantity > 0) then
                TempOfficeSuggestedLineItem.Validate(Quantity, Quantity);
            TempOfficeSuggestedLineItem.Modify(true);
        end else begin
            TempOfficeSuggestedLineItem.Init();
            TempOfficeSuggestedLineItem.Validate("Line No.", LastLineNo + 1000);
            if Matches = 1 then
                TempOfficeSuggestedLineItem.Validate("Item No.", CopyStr(ItemNo, 1, 20))
            else
                TempOfficeSuggestedLineItem.Validate("Item Description", CopyStr(SearchKeyword, 1, 50));
            TempOfficeSuggestedLineItem.Validate(Quantity, Quantity);
            TempOfficeSuggestedLineItem.Validate(Matches, Matches);
            TempOfficeSuggestedLineItem.Insert(true);
        end;

        TempOfficeSuggestedLineItem.SetRange("Item No.");
        TempOfficeSuggestedLineItem.SetRange("Item Description");
    end;

    local procedure InsertLineItem(var HeaderRecRef: RecordRef; ItemNo: Text[50]; Quantity: Integer)
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
    begin
        case HeaderRecRef.Number of
            DATABASE::"Sales Header":
                begin
                    HeaderRecRef.SetTable(SalesHeader);
                    InsertSalesLine(SalesHeader, ItemNo, Quantity);
                end;
            DATABASE::"Purchase Header":
                begin
                    HeaderRecRef.SetTable(PurchaseHeader);
                    InsertPurchaseLine(PurchaseHeader, ItemNo, Quantity);
                end;
        end;
    end;

    local procedure InsertSalesLine(var SalesHeader: Record "Sales Header"; ItemNo: Text[50]; Quantity: Integer)
    var
        SalesLine: Record "Sales Line";
        LineNo: Integer;
    begin
        LineNo := 10000;
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindLast() then
            LineNo := SalesLine."Line No." + 10000;

        SalesLine.Init();
        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");
        SalesLine.Validate("Line No.", LineNo);
        SalesLine.Validate("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesLine.Validate(Type, SalesLine.Type::Item);
        SalesLine.Validate("No.", CopyStr(ItemNo, 1, 20));
        SalesLine.Validate(Quantity, Quantity);
        SalesLine.Insert(true);
        Commit();
    end;

    local procedure InsertPurchaseLine(var PurchaseHeader: Record "Purchase Header"; ItemNo: Text[50]; Quantity: Integer)
    var
        PurchaseLine: Record "Purchase Line";
        LineNo: Integer;
    begin
        LineNo := 10000;
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        if PurchaseLine.FindLast() then
            LineNo := PurchaseLine."Line No." + 10000;

        PurchaseLine.Init();
        PurchaseLine.Validate("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.Validate("Document No.", PurchaseHeader."No.");
        PurchaseLine.Validate("Line No.", LineNo);
        PurchaseLine.Validate("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        PurchaseLine.Validate(Type, PurchaseLine.Type::Item);
        PurchaseLine.Validate("No.", CopyStr(ItemNo, 1, 20));
        PurchaseLine.Validate(Quantity, Quantity);
        PurchaseLine.Insert(true);
        Commit();
    end;

    local procedure NewLine() CrLf: Text[2]
    begin
        CrLf[1] := 13;
        CrLf[2] := 10;
    end;

    local procedure OmitFirst(SearchTerms: DotNet Array; i: Integer; Separator: Text) Result: Text
    var
        TempResult: Text;
        j: Integer;
    begin
        for j := i to SearchTerms.Length - 1 do begin
            Evaluate(TempResult, SearchTerms.GetValue(j));
            Result += TempResult + Separator;
        end;
        Result := DelChr(Result, '>', Separator);
    end;

    local procedure OmitLast(SearchTerms: DotNet Array; i: Integer; Separator: Text) Result: Text
    var
        TempResult: Text;
        j: Integer;
    begin
        for j := 0 to SearchTerms.Length - 1 - i do begin
            Evaluate(TempResult, SearchTerms.GetValue(j));
            Result += TempResult + Separator;
        end;
        Result := DelChr(Result, '>', Separator);
    end;

    local procedure PerformSearch(var ItemNo: Text[50]; var SearchText: Text; var BestCount: Integer; var BestText: Text; var BestItem: Text[50]; var BestStrength: Decimal; EmailBody: Text; Recurse: Boolean): Boolean
    var
        FoundCount: Integer;
        Strength: Decimal;
    begin
        FoundCount := FindItemsByDescription(ItemNo, SearchText);
        Strength := CalculateMatchStrength(ItemNo, FoundCount, SearchText, false);
        if (FoundCount > 0) and (Strength > BestStrength) then begin
            BestCount := FoundCount;
            BestStrength := Strength;
            BestText := SearchText;
            BestItem := ItemNo;
        end;
        if Recurse and (FoundCount > 1) then begin
            FoundCount := ResolveItem(ItemNo, SearchText, EmailBody);
            Strength := CalculateMatchStrength(ItemNo, FoundCount, SearchText, false);
            if (FoundCount > 0) and (Strength > BestStrength) then begin
                BestStrength := Strength;
                BestCount := FoundCount;
                BestText := SearchText;
                BestItem := ItemNo;
            end;
        end;

        exit(FoundCount > 0);
    end;

    local procedure ResolveItem(var ItemNo: Text[50]; var Description: Text; EmailBody: Text): Integer
    var
        PreRegex: DotNet Regex;
        PreMatches: DotNet MatchCollection;
        PostRegex: DotNet Regex;
        PostMatches: DotNet MatchCollection;
        Match: DotNet Match;
        NewDescription: DotNet String;
        FoundCount: Integer;
        BestCount: Integer;
        BestDescription: Text;
        OriginalDescription: Text;
        Strength: Decimal;
        BestStrength: Decimal;
    begin
        if StrLen(Description) < 4 then
            exit(0);

        OriginalDescription := Description;
        FoundCount := FindItemsByDescription(ItemNo, Description);
        if FoundCount = 1 then
            exit(FoundCount);

        BestCount := 999999; // sentinel value

        // Find all phrases around Description - up to 2 words on left side
        PreRegex := PreRegex.Regex(StrSubstNo('([^\W\d]+ ?){0,2} ?\b%1\b', Description));
        PreMatches := PreRegex.Matches(EmailBody);
        foreach Match in PreMatches do begin
            NewDescription := PreRegex.Replace(SanitizeText(Match.Value, 3), ' ', '*');
            NewDescription := NewDescription.Replace(ConvertStr(OriginalDescription, ' ', '*'), OriginalDescription);
            if Format(NewDescription) <> OriginalDescription then begin
                FoundCount := FindItemFromText(ItemNo, NewDescription, EmailBody, '*', false);
                Strength := CalculateMatchStrength(ItemNo, FoundCount, NewDescription, false);
                if (FoundCount > 0) and (Strength > BestStrength) then begin
                    BestStrength := Strength;
                    BestDescription := NewDescription;
                end;
            end;
        end;

        // Find all phrases around Description - up to 2 words on right side
        PostRegex := PostRegex.Regex(StrSubstNo('\b%1\b ?([^\W\d]+ ?){0,2}', Description));
        PostMatches := PostRegex.Matches(EmailBody);
        foreach Match in PostMatches do begin
            NewDescription := PostRegex.Replace(SanitizeText(Match.Value, 3), ' ', '*');
            NewDescription := NewDescription.Replace(ConvertStr(OriginalDescription, ' ', '*'), OriginalDescription);
            if Format(NewDescription) <> OriginalDescription then begin
                FoundCount := FindItemFromText(ItemNo, NewDescription, EmailBody, '*', false);
                Strength := CalculateMatchStrength(ItemNo, FoundCount, NewDescription, false);
                if (FoundCount > 0) and (Strength > BestStrength) then begin
                    BestCount := FoundCount;
                    BestDescription := NewDescription;
                end;
            end;
        end;

        if (BestCount < 999999) and (StrPos(BestDescription, ConvertStr(OriginalDescription, ' ', '*')) > 0) then begin
            Description := BestDescription;
            if BestCount = 1 then
                FindItemFromText(ItemNo, BestDescription, EmailBody, '*', false);
            exit(BestCount);
        end;
    end;

    local procedure SanitizeText(Text: Text; MinWordLength: Integer) Sanitized: Text
    var
        CultureInfo: DotNet CultureInfo;
        PluralizationService: DotNet PluralizationService;
        Regex: DotNet Regex;
        WordMatches: DotNet MatchCollection;
        Match: DotNet Match;
        Word: Text;
        Restricted: Text;
    begin
        if Text = '' then
            exit;

        // Sanitization:
        // 1. Trim white space
        // 2. Remove any words < specified minimum word lengthh
        // 3. Remove any restricted words (the, for, but, etc.)
        // 4. Singularize each word

        Sanitized := Text;

        Sanitized := Regex.Replace(Sanitized, StrSubstNo('\b\w{1,%1}\b\s?', MinWordLength - 1), '');
        Sanitized := Regex.Replace(Sanitized, '\b\d{1,3}\b', '');
        Restricted := '\b' + Regex.Replace(RestrictedWordsTxt, '\|', '\b|\b') + '\b'; // Make sure to match whole words only
        Sanitized := Regex.Replace(Sanitized, Restricted, '');
        Sanitized := Regex.Replace(Sanitized, '^\s*', ''); // Trim white space
        Sanitized := Regex.Replace(Sanitized, '\s*$', ''); // Trim white space
        Sanitized := Regex.Replace(Sanitized, '[^\s]{51,}', ''); // Remove words longer than 50 characters

        // The pluralization service only supports English
        PluralizationService := PluralizationService.CreateService(CultureInfo.CultureInfo('en'));
        WordMatches := Regex.Matches(Sanitized, '\b(\w+)\b');
        foreach Match in WordMatches do begin
            Word := Match.Groups.Item(1).Value();
            if PluralizationService.IsPlural(Word) then
                Sanitized := Regex.Replace(Sanitized, Word, PluralizationService.Singularize(Word));
        end;
        Sanitized := PluralizationService.Singularize(Sanitized);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateLinesBasedOnQuantityReferences(var HeaderRecRef: RecordRef; var TempOfficeSuggestedLineItem: Record "Office Suggested Line Item" temporary; EmailBody: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateLinesBasedOnItemReferences(var HeaderRecRef: RecordRef; var TempOfficeSuggestedLineItem: Record "Office Suggested Line Item" temporary; EmailBody: Text; var IsHandled: Boolean)
    begin
    end;
}

