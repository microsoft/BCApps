// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
namespace Microsoft.Agent.SalesOrderAgent;

using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Item;
using Microsoft.Sales.Document;
using System.Environment.Configuration;
using System.Telemetry;

codeunit 4591 "SOA Item Search"
{
    Access = Internal;
    EventSubscriberInstance = Manual;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        AgentTaskID: BigInteger;
        ResolvedItemVariants: Dictionary of [Text, Text];
        NotificationMsg: Label 'The available inventory for item %1 is lower than the entered quantity at this location at the requested shipment date.', Comment = '%1=Item Description';
        NotificationCTPDateMsg: Label 'Earliest possible shipping date for the new quantity is %1.', Comment = '%1=Earliest Shipment Date';

    procedure SetAgentTaskID(NewAgentTaskID: BigInteger)
    begin
        AgentTaskID := NewAgentTaskID;
    end;

    [TryFunction]
    procedure GetItemFilters(var ItemFilter: Text; SearchPrimaryKeyWords: List of [Text])
    var
        DummySearchType: Text;
    begin
        GetItemFilters(ItemFilter, SearchPrimaryKeyWords, DummySearchType);
    end;

    [TryFunction]
    local procedure GetItemFilters(var ItemFilter: Text; SearchPrimaryKeyWords: List of [Text]; var SearchType: Text)
    var
        Item: Record Item;
        GlobalItemSearch: Codeunit "Global Item Search";
        BroaderItemSearch: Codeunit "SOA Broader Item Search";
        CandidateArray: JsonArray;
        DummySearchOptionalKeyWords: List of [Text];
        ItemNoFilter: Text;
    begin
        // If we can get the item uniquely by it's key fields i.e. No., then we don't need to perform extensive search when there is ItemNoFilter.
        if SearchPrimaryKeyWords.Count > 0 then begin
            ItemNoFilter := SearchPrimaryKeyWords.Get(1);
            if (ItemNoFilter <> '') and (StrLen(ItemNoFilter) <= MaxStrLen(Item."No.")) then begin
                Clear(Item);
                Item.SetLoadFields(SystemId);
                Item.ReadIsolation := IsolationLevel::ReadCommitted;
                Item.SetRange("No.", ItemNoFilter);
                Item.SetRange(Blocked, false);
                Item.SetRange("Sales Blocked", false);

                // Search only using key fields
                if Item.FindFirst() then begin
                    ItemFilter := Item.SystemId;
                    SearchType := 'item_get';
                    exit;
                end;
            end;
        end;

        GlobalItemSearch.CheckIsItemSearchReady(true);
        GlobalItemSearch.InitializeSearchOptionsObject(false, true);
        GlobalItemSearch.AddSearchFilter(Item.FieldNo(Blocked), Text.StrSubstNo('<> %1', true));
        GlobalItemSearch.AddSearchFilter(Item.FieldNo("Sales Blocked"), Text.StrSubstNo('<> %1', true));
        GlobalItemSearch.AddSearchRankingContext('', '', 0);
        GlobalItemSearch.SetupSOACapabilityInformation();
        GlobalItemSearch.SetupSearchQuery(SearchPrimaryKeyWords.Get(1), SearchPrimaryKeyWords, DummySearchOptionalKeyWords, true, 50);

        Clear(CandidateArray);
        if GlobalItemSearch.SearchAndReturnResultsWithColumnValues(SearchPrimaryKeyWords.Get(1), 0, CandidateArray) then
            ItemFilter := BroaderItemSearch.BuildResultFilterFromCandidates(CandidateArray, '|')
        else
            ItemFilter := '';

        SearchType := 'item_search';
    end;

    [EventSubscriber(ObjectType::Page, Page::"Item List", OnBeforeFindRecord, '', false, false)]
    local procedure FindRecordItemFromList(var Rec: Record Item; Which: Text; var CrossColumnSearchFilter: Text; var Found: Boolean; var IsHandled: Boolean)
    var
        MatchingItem: Boolean;
    begin
        FindRecordItem(Rec, Which, CrossColumnSearchFilter, Found, 0, '', IsHandled, false, MatchingItem);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Item Lookup", OnBeforeFindRecord, '', false, false)]
    local procedure FindRecordItemFromLookup(var Rec: Record Item; Which: Text; var CrossColumnSearchFilter: Text; var Found: Boolean; var IsHandled: Boolean)
    var
        MatchingItem: Boolean;
    begin
        FindRecordItem(Rec, Which, CrossColumnSearchFilter, Found, 0, '', IsHandled, false, MatchingItem);
    end;

    [EventSubscriber(ObjectType::Page, Page::"SOA Multi Items Availability", OnBeforeFindRecord, '', false, false)]
    local procedure FindRecordItemFromMultiItemsAvailability(var Rec: Record Item; Which: Text; var CrossColumnSearchFilter: Text; var Found: Boolean; RequiredQuantity: Decimal; InUOMCode: Code[10]; var IsHandled: Boolean; var MatchingItem: Boolean)
    var
        TelemetryCustomDimension: Dictionary of [Text, Text];
    begin
        FindRecordItem(Rec, Which, CrossColumnSearchFilter, Found, RequiredQuantity, InUOMCode, IsHandled, true, MatchingItem, TelemetryCustomDimension);
        LogTelemetryForFindItems(TelemetryCustomDimension);
    end;

    [EventSubscriber(ObjectType::Page, Page::"SOA Multi Items Availability", OnOpenPageEvent, '', false, false)]
    local procedure LogInventoryInquiryReplied()
    var
        SOABilling: Codeunit "SOA Billing";
    begin
        SOABilling.LogInventoryInquiryReplied(AgentTaskID);
    end;

    [EventSubscriber(ObjectType::Page, Page::"SOA Multi Items Availability", OnGetResolvedVariant, '', false, false)]
    local procedure GetResolvedVariant(ItemSystemId: Guid; var VariantCode: Code[10])
    var
        VariantCodeText: Text;
    begin
        if ResolvedItemVariants.ContainsKey(Format(ItemSystemId)) then begin
            VariantCodeText := ResolvedItemVariants.Get(Format(ItemSystemId));
            VariantCode := CopyStr(VariantCodeText, 1, MaxStrLen(VariantCode));
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", OnAfterCheckItemAvailable, '', false, false)]
    local procedure OnAfterCheckItemAvailable(var SalesLine: Record "Sales Line"; CalledByFieldNo: Integer; HideValidationDialog: Boolean)
    var
        Item: Record Item;
        SOASetup: Record "SOA Setup";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        SOAShipmentDateMgt: Codeunit "SOA Shipment Date Mgt.";
        QuoteAvailabilityCheckNotification: Notification;
        Msg: Text;
    begin
        if SalesLine.IsTemporary() or (SalesLine."Document Type" <> SalesLine."Document Type"::Quote) or
           (SalesLine.Type <> SalesLine.Type::Item) or (SalesLine."No." = '') or (SalesLine.Quantity = 0)
        then
            exit;

        if not SOASetup.FindFirst() or not SOASetup."Search Only Available Items" then
            exit;

        Item.Get(SalesLine."No.");
        Item.SetRange("Drop Shipment Filter", false);
        Item.SetRange("Variant Filter", SalesLine."Variant Code");
        Item.SetFilter("Date Filter", '..%1', SalesLine."Shipment Date");
        Item.SetFilter("Location Filter", '%1', SalesLine."Location Code");

        if IsRequiredQuantityAvailable(Item, SalesLine.Quantity, SalesLine."Unit of Measure Code") then
            exit;

        Msg := StrSubstNo(NotificationMsg, Item.Description);

        if SOASetup."Incl. Capable to Promise" then begin
            SOAShipmentDateMgt.SetParamenters(Item."No.", SalesLine."Variant Code", SalesLine."Location Code", SalesLine."Unit of Measure Code", SalesLine."Shipment Date", SalesLine.Quantity);
            SOAShipmentDateMgt.Run();
            if SOAShipmentDateMgt.GetEarliestShipmentDate() <= SalesLine."Shipment Date" then
                exit;
            Msg += StrSubstNo(NotificationCTPDateMsg, SOAShipmentDateMgt.GetEarliestShipmentDate());
        end;

        NotificationLifecycleMgt.RecallNotificationsForRecordWithAdditionalContext(SalesLine.RecordId, GetQuoteItemAvailabilityNotificationId(), true);
        QuoteAvailabilityCheckNotification.Id(CreateGuid());
        QuoteAvailabilityCheckNotification.Message(Msg);
        QuoteAvailabilityCheckNotification.Scope(NotificationScope::LocalScope);
        NotificationLifecycleMgt.SendNotificationWithAdditionalContext(QuoteAvailabilityCheckNotification, SalesLine.RecordId, GetQuoteItemAvailabilityNotificationId());
    end;

    local procedure GetQuoteItemAvailabilityNotificationId(): Guid
    begin
        exit('61dfb790-bf0c-47be-b95c-8e51afecd066');
    end;

    local procedure FindRecordItem(var Rec: Record Item; Which: Text; var CrossColumnSearchFilter: Text; var Found: Boolean; RequiredQuantity: Decimal; InUOMCode: Code[10]; var IsHandled: Boolean; CheckAvailability: Boolean; var MatchingItem: Boolean)
    var
        DummyCustomDimension: Dictionary of [Text, Text];
    begin
        FindRecordItem(Rec, Which, CrossColumnSearchFilter, Found, RequiredQuantity, InUOMCode, IsHandled, CheckAvailability, MatchingItem, DummyCustomDimension);
    end;

    local procedure FindRecordItem(var Rec: Record Item; Which: Text; var CrossColumnSearchFilter: Text; var Found: Boolean; RequiredQuantity: Decimal; InUOMCode: Code[10]; var IsHandled: Boolean; CheckAvailability: Boolean; var MatchingItem: Boolean; var TelemetryCustomDimension: Dictionary of [Text, Text])
    var
        SOASetup: Record "SOA Setup";
        Item: Record Item;
        BroaderItemSearch: Codeunit "SOA Broader Item Search";
        CandidateArray: JsonArray;
        SearchKeyWordsTrimmed: List of [Text];
        SearchFilter: Text;
        SearchQuery: Text;
        SplitSearchKeywords: Text;
        ItemFilter: Text;
        SelectedMatchingItemFilter: Text;
        SelectedAlternativeItemFilter: Text;
        SelectedMatchingItemVariants: Dictionary of [Text, Text];
        SelectedAlternativeItemVariants: Dictionary of [Text, Text];
        EmptyItemVariants: Dictionary of [Text, Text];
        AvailableMatchingItemVariants: Dictionary of [Text, Text];
        AvailableAlternativeItemVariants: Dictionary of [Text, Text];
        AvailableItemVariants: Dictionary of [Text, Text];
        SearchType: Text;
        OriginalFilterGroup: Integer;
        CountBeforeAvailabilityCheck: Integer;
        ApplyAvailabilityFilter: Boolean;
        ItemSelectorUsed: Boolean;
        SameItemVariantAlternativeOnly: Boolean;
    begin
        MatchingItem := true;
        OriginalFilterGroup := Rec.FilterGroup();
        Rec.FilterGroup(-1);
        SearchFilter := Rec.GetFilter("No."); //Get current search filter
        Rec.FilterGroup(OriginalFilterGroup);

        if (SearchFilter = CrossColumnSearchFilter) or (SearchFilter = '=''<>*''') then //If the search filter is the same as the last one, or empty filter then we don't need to search
            exit;
        CrossColumnSearchFilter := SearchFilter;
        Clear(ResolvedItemVariants);

        ExtractSearchKeyWords(SearchFilter, SplitSearchKeywords, SearchKeyWordsTrimmed);

        if SearchKeyWordsTrimmed.Count() = 0 then
            exit;
        if not GetItemFilters(ItemFilter, SearchKeyWordsTrimmed, SearchType) then //Search for the items using the entity search
            exit;

        if (ItemFilter <> '') and (CandidateArray.Count() = 0) then
            BuildCandidateArrayFromItemFilter(ItemFilter, CandidateArray);

        if (ItemFilter = '') and (SplitSearchKeywords <> '') then begin
            BroaderItemSearch.BroaderItemSearch(ItemFilter, SplitSearchKeywords.TrimEnd(','), CandidateArray);
            MatchingItem := false;
            SearchType := 'broader_item_search';
        end;

        if SOASetup.FindFirst() then
            if ItemFilter <> '' then begin
                CountBeforeAvailabilityCheck := ItemFilter.Split('|').Count();
                ApplyAvailabilityFilter := CheckAvailability and (SOASetup."Search Only Available Items" and not SOASetup."Incl. Capable to Promise");

                // Run item selection for all candidate payloads so variant resolution is consistent.
                if CandidateArray.Count() > 0 then begin
                    SearchQuery := BuildSearchQueryText(SearchKeyWordsTrimmed);
                    if SelectBestItem(ItemFilter, SearchQuery, CandidateArray, SelectedMatchingItemFilter, SelectedAlternativeItemFilter, SelectedMatchingItemVariants, SelectedAlternativeItemVariants) then begin
                        SameItemVariantAlternativeOnly := NormalizeVariantAlternatives(SelectedMatchingItemFilter, SelectedMatchingItemVariants, SelectedAlternativeItemFilter, SelectedAlternativeItemVariants, SearchQuery);
                        ItemSelectorUsed := true;
                        TelemetryCustomDimension.Add('ItemSelectorUsed', 'true');
                        TelemetryCustomDimension.Add('ItemSelectorMatchingCount', Format(CountFilterItems(SelectedMatchingItemFilter)));
                        TelemetryCustomDimension.Add('ItemSelectorAlternativeCount', Format(CountFilterItems(SelectedAlternativeItemFilter)));
                        TelemetryCustomDimension.Add('ItemSelectorNoMatchCount', Format(CountBeforeAvailabilityCheck - CountFilterItems(SelectedMatchingItemFilter) - CountFilterItems(SelectedAlternativeItemFilter)));
                    end else begin
                        ItemSelectorUsed := false;
                        TelemetryCustomDimension.Add('ItemSelectorUsed', 'false');
                    end;
                end;

                // When selector returns both sets, prefer available matching items.
                // If none are available, retry availability filtering for alternatives.
                if ItemSelectorUsed and (SelectedMatchingItemFilter <> '') then begin
                    ItemFilter := BuildFilteredItemFilter(SelectedMatchingItemFilter, Rec, RequiredQuantity, InUOMCode, ApplyAvailabilityFilter, SelectedMatchingItemVariants, AvailableMatchingItemVariants);
                    if (ItemFilter = '') and (SelectedAlternativeItemFilter <> '') then begin
                        ItemFilter := BuildFilteredItemFilter(SelectedAlternativeItemFilter, Rec, RequiredQuantity, InUOMCode, ApplyAvailabilityFilter, SelectedAlternativeItemVariants, AvailableAlternativeItemVariants);
                        StoreResolvedItemVariants(ItemFilter, AvailableAlternativeItemVariants);
                        MatchingItem := SameItemVariantAlternativeOnly;
                    end else begin
                        StoreResolvedItemVariants(ItemFilter, AvailableMatchingItemVariants);
                        MatchingItem := true;
                    end;
                end else
                    if ItemSelectorUsed and (SelectedAlternativeItemFilter <> '') then begin
                        ItemFilter := BuildFilteredItemFilter(SelectedAlternativeItemFilter, Rec, RequiredQuantity, InUOMCode, ApplyAvailabilityFilter, SelectedAlternativeItemVariants, AvailableAlternativeItemVariants);
                        StoreResolvedItemVariants(ItemFilter, AvailableAlternativeItemVariants);
                        MatchingItem := SameItemVariantAlternativeOnly;
                    end else
                        ItemFilter := BuildFilteredItemFilter(ItemFilter, Rec, RequiredQuantity, InUOMCode, ApplyAvailabilityFilter, EmptyItemVariants, AvailableItemVariants);
            end;

        if ItemFilter <> '' then begin
            Item.CopyFilters(Rec);

            Rec.Reset();
            Rec.SetFilter(SystemId, ItemFilter);

            Item.CopyFilter("Drop Shipment Filter", Rec."Drop Shipment Filter");
            Item.CopyFilter("Date Filter", Rec."Date Filter");
            Item.CopyFilter("Location Filter", Rec."Location Filter");
            Item.CopyFilter("Variant Filter", Rec."Variant Filter");
            Found := Rec.Find(Which);
        end;

        // Prepare Custom Dimensions for Telemetry
        TelemetryCustomDimension.Add('SearchType', SearchType);
        TelemetryCustomDimension.Add('ResultCount', Format(ItemFilter.Split('|').Count()));
        if SearchType = 'broader_item_search' then
            TelemetryCustomDimension.Add('BroaderSearchCandidateCount', Format(CountBeforeAvailabilityCheck))
        else
            TelemetryCustomDimension.Add('Tier1CandidateCount', Format(CountBeforeAvailabilityCheck));

        IsHandled := true;
        OnAfterFindRecordItem(ItemFilter, Which, CrossColumnSearchFilter, Found, RequiredQuantity, InUOMCode);
    end;

    local procedure SelectBestItem(ItemFilter: Text; SearchQuery: Text; CandidateArray: JsonArray; var SelectedMatchingItemFilter: Text; var SelectedAlternativeItemFilter: Text; var SelectedMatchingItemVariants: Dictionary of [Text, Text]; var SelectedAlternativeItemVariants: Dictionary of [Text, Text]): Boolean
    var
        Item: Record Item;
        ItemSelector: Codeunit "SOA Item Selector";
        ItemNoToSystemId: Dictionary of [Text, Text];
        RawSelectedMatchingItemVariants: Dictionary of [Text, Text];
        RawSelectedAlternativeItemVariants: Dictionary of [Text, Text];
        RawSelectedMatchingItemFilter: Text;
        RawSelectedAlternativeItemFilter: Text;
        SelectedMatchingItemNo: Text;
        SelectedAlternativeItemNo: Text;
    begin
        SelectedMatchingItemFilter := '';
        SelectedAlternativeItemFilter := '';
        Clear(SelectedMatchingItemVariants);
        Clear(SelectedAlternativeItemVariants);

        if CandidateArray.Count() > 0 then
            if ItemSelector.SelectBestMatchingItemWithVariants(SearchQuery, CandidateArray, SelectedMatchingItemFilter, SelectedAlternativeItemFilter, RawSelectedMatchingItemVariants, RawSelectedAlternativeItemVariants) then begin
                RawSelectedMatchingItemFilter := SelectedMatchingItemFilter;
                RawSelectedAlternativeItemFilter := SelectedAlternativeItemFilter;

                SelectedMatchingItemFilter := '';
                SelectedAlternativeItemFilter := '';

                // Single query: build a map of Item."No." -> SystemId for all candidates.
                Item.SetLoadFields("No.", SystemId);
                Item.SetFilter(SystemId, ItemFilter);
                if Item.FindSet() then
                    repeat
                        ItemNoToSystemId.Add(Item."No.", Format(Item.SystemId));
                    until Item.Next() = 0;

                foreach SelectedMatchingItemNo in RawSelectedMatchingItemFilter.Split('|') do
                    AddSelectedItem(SelectedMatchingItemFilter, SelectedMatchingItemVariants, SelectedMatchingItemNo, ItemNoToSystemId, RawSelectedMatchingItemVariants);

                foreach SelectedAlternativeItemNo in RawSelectedAlternativeItemFilter.Split('|') do
                    AddSelectedItem(SelectedAlternativeItemFilter, SelectedAlternativeItemVariants, SelectedAlternativeItemNo, ItemNoToSystemId, RawSelectedAlternativeItemVariants);

                if (SelectedMatchingItemFilter <> '') or (SelectedAlternativeItemFilter <> '') then
                    exit(true);
            end;
        exit(false);
    end;

    local procedure NormalizeVariantAlternatives(var SelectedMatchingItemFilter: Text; var SelectedMatchingItemVariants: Dictionary of [Text, Text]; var SelectedAlternativeItemFilter: Text; var SelectedAlternativeItemVariants: Dictionary of [Text, Text]; SearchQuery: Text): Boolean
    var
        SameItemVariantAlternativeOnly: Boolean;
    begin
        AddSameItemVariantAlternativesForMissingVariant(SelectedMatchingItemFilter, SelectedMatchingItemVariants, SelectedAlternativeItemFilter, SelectedAlternativeItemVariants, SearchQuery);
        SameItemVariantAlternativeOnly := KeepSameItemVariantAlternativesOnly(SelectedMatchingItemFilter, SelectedAlternativeItemFilter, SelectedAlternativeItemVariants);
        RemoveMatchingItemsWithBlankVariantAndSameItemAlternatives(SelectedMatchingItemFilter, SelectedMatchingItemVariants, SelectedAlternativeItemVariants);
        exit(SameItemVariantAlternativeOnly);
    end;

    local procedure AddSameItemVariantAlternativesForMissingVariant(SelectedMatchingItemFilter: Text; SelectedMatchingItemVariants: Dictionary of [Text, Text]; var SelectedAlternativeItemFilter: Text; var SelectedAlternativeItemVariants: Dictionary of [Text, Text]; SearchQuery: Text)
    var
        FallbackAlternativeItemVariants: Dictionary of [Text, Text];
        ItemSystemId: Text;
        AlternativeVariantCodes: Text;
        VariantCodes: Text;
        FallbackAlternativeItemFilter: Text;
        MatchingVariantCodes: Text;
    begin
        if SelectedMatchingItemFilter = '' then
            exit;

        foreach ItemSystemId in SelectedMatchingItemFilter.Split('|') do begin
            MatchingVariantCodes := '';
            if SelectedMatchingItemVariants.ContainsKey(ItemSystemId) then
                MatchingVariantCodes := SelectedMatchingItemVariants.Get(ItemSystemId);

            if MatchingVariantCodes <> '' then
                continue;
            if SelectedAlternativeItemVariants.ContainsKey(ItemSystemId) then begin
                AlternativeVariantCodes := SelectedAlternativeItemVariants.Get(ItemSystemId);
                if AlternativeVariantCodes <> '' then
                    continue;
            end;

            if HasVariantSignalForItem(ItemSystemId, SearchQuery) then begin
                VariantCodes := GetItemVariantCodes(ItemSystemId);
                if VariantCodes <> '' then begin
                    if FallbackAlternativeItemFilter = '' then
                        FallbackAlternativeItemFilter := ItemSystemId
                    else
                        FallbackAlternativeItemFilter += '|' + ItemSystemId;
                    FallbackAlternativeItemVariants.Add(ItemSystemId, VariantCodes);
                end;
            end;
        end;

        if FallbackAlternativeItemFilter = '' then
            exit;

        SelectedAlternativeItemFilter := FallbackAlternativeItemFilter;
        SelectedAlternativeItemVariants := FallbackAlternativeItemVariants;
    end;

    local procedure KeepSameItemVariantAlternativesOnly(SelectedMatchingItemFilter: Text; var SelectedAlternativeItemFilter: Text; var SelectedAlternativeItemVariants: Dictionary of [Text, Text]): Boolean
    var
        MatchingItemSystemIds: Dictionary of [Text, Boolean];
        SameItemAlternativeItemVariants: Dictionary of [Text, Text];
        AlternativeItemSystemId: Text;
        MatchingItemSystemId: Text;
        VariantCodes: Text;
        SameItemAlternativeItemFilter: Text;
    begin
        if (SelectedMatchingItemFilter = '') or (SelectedAlternativeItemFilter = '') then
            exit(false);

        foreach MatchingItemSystemId in SelectedMatchingItemFilter.Split('|') do
            if not MatchingItemSystemIds.ContainsKey(MatchingItemSystemId) then
                MatchingItemSystemIds.Add(MatchingItemSystemId, true);

        foreach AlternativeItemSystemId in SelectedAlternativeItemFilter.Split('|') do begin
            if not MatchingItemSystemIds.ContainsKey(AlternativeItemSystemId) then
                continue;
            if not SelectedAlternativeItemVariants.ContainsKey(AlternativeItemSystemId) then
                continue;

            VariantCodes := SelectedAlternativeItemVariants.Get(AlternativeItemSystemId);
            if VariantCodes = '' then
                continue;

            if SameItemAlternativeItemFilter = '' then
                SameItemAlternativeItemFilter := AlternativeItemSystemId
            else
                SameItemAlternativeItemFilter += '|' + AlternativeItemSystemId;

            if not SameItemAlternativeItemVariants.ContainsKey(AlternativeItemSystemId) then
                SameItemAlternativeItemVariants.Add(AlternativeItemSystemId, VariantCodes);
        end;

        if SameItemAlternativeItemFilter = '' then
            exit(false);

        SelectedAlternativeItemFilter := SameItemAlternativeItemFilter;
        SelectedAlternativeItemVariants := SameItemAlternativeItemVariants;
        exit(true);
    end;

    local procedure HasVariantSignalForItem(ItemSystemId: Text; SearchQuery: Text): Boolean
    var
        Item: Record Item;
        SearchToken: Text;
    begin
        if not Item.GetBySystemId(ItemSystemId) then
            exit(false);

        SearchQuery := LowerCase(SearchQuery);
        foreach SearchToken in SearchQuery.Split(' ') do begin
            SearchToken := SearchToken.Trim();
            if StrLen(SearchToken) <= 2 then
                continue;
            if StrPos(LowerCase(Item."No."), SearchToken) > 0 then
                continue;
            if StrPos(LowerCase(Item.Description), SearchToken) > 0 then
                continue;
            if StrPos(LowerCase(Item."Description 2"), SearchToken) > 0 then
                continue;
            exit(true);
        end;

        exit(false);
    end;

    local procedure GetItemVariantCodes(ItemSystemId: Text): Text
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        VariantCodes: Text;
    begin
        if not Item.GetBySystemId(ItemSystemId) then
            exit('');

        ItemVariant.SetRange("Item No.", Item."No.");
        if ItemVariant.FindSet() then
            repeat
                if VariantCodes = '' then
                    VariantCodes := ItemVariant.Code
                else
                    VariantCodes += '|' + ItemVariant.Code;
            until ItemVariant.Next() = 0;

        exit(VariantCodes);
    end;

    local procedure RemoveMatchingItemsWithBlankVariantAndSameItemAlternatives(var SelectedMatchingItemFilter: Text; var SelectedMatchingItemVariants: Dictionary of [Text, Text]; SelectedAlternativeItemVariants: Dictionary of [Text, Text])
    var
        NewSelectedMatchingItemVariants: Dictionary of [Text, Text];
        ItemSystemId: Text;
        AlternativeVariantCodes: Text;
        MatchingVariantCodes: Text;
        NewSelectedMatchingItemFilter: Text;
    begin
        if SelectedMatchingItemFilter = '' then
            exit;

        foreach ItemSystemId in SelectedMatchingItemFilter.Split('|') do begin
            MatchingVariantCodes := '';
            if SelectedMatchingItemVariants.ContainsKey(ItemSystemId) then
                MatchingVariantCodes := SelectedMatchingItemVariants.Get(ItemSystemId);

            if MatchingVariantCodes = '' then
                if SelectedAlternativeItemVariants.ContainsKey(ItemSystemId) then begin
                    AlternativeVariantCodes := SelectedAlternativeItemVariants.Get(ItemSystemId);
                    if AlternativeVariantCodes <> '' then
                        continue;
                end;

            if NewSelectedMatchingItemFilter = '' then
                NewSelectedMatchingItemFilter := ItemSystemId
            else
                NewSelectedMatchingItemFilter += '|' + ItemSystemId;

            if not NewSelectedMatchingItemVariants.ContainsKey(ItemSystemId) then
                NewSelectedMatchingItemVariants.Add(ItemSystemId, MatchingVariantCodes);
        end;

        SelectedMatchingItemFilter := NewSelectedMatchingItemFilter;
        SelectedMatchingItemVariants := NewSelectedMatchingItemVariants;
    end;

    local procedure BuildCandidateArrayFromItemFilter(ItemFilter: Text; var CandidateArray: JsonArray)
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        CandidateObject: JsonObject;
        ColumnValuesObject: JsonObject;
        VariantArray: JsonArray;
        VariantObject: JsonObject;
    begin
        Clear(CandidateArray);
        if ItemFilter = '' then
            exit;

        Item.SetLoadFields("No.", Description, "Description 2", SystemId);
        Item.SetFilter(SystemId, ItemFilter);
        if not Item.FindSet() then
            exit;

        repeat
            Clear(CandidateObject);
            Clear(ColumnValuesObject);
            Clear(VariantArray);

            ColumnValuesObject.Add('No.', Item."No.");
            ColumnValuesObject.Add('Description', Item.Description);
            ColumnValuesObject.Add('Description 2', Item."Description 2");

            ItemVariant.SetRange("Item No.", Item."No.");
            if ItemVariant.FindSet() then
                repeat
                    Clear(VariantObject);
                    VariantObject.Add('Code', ItemVariant.Code);
                    VariantObject.Add('Description', ItemVariant.Description);
                    VariantObject.Add('Description 2', ItemVariant."Description 2");
                    VariantArray.Add(VariantObject);
                until ItemVariant.Next() = 0;

            ColumnValuesObject.Add('Variants', VariantArray);
            CandidateObject.Add('system_id', Format(Item.SystemId));
            CandidateObject.Add('column_values', ColumnValuesObject);
            CandidateArray.Add(CandidateObject);
        until Item.Next() = 0;
    end;

    local procedure AddSelectedItem(var SelectedItemFilter: Text; var SelectedItemVariants: Dictionary of [Text, Text]; SelectedItemNo: Text; ItemNoToSystemId: Dictionary of [Text, Text]; RawSelectedItemVariants: Dictionary of [Text, Text])
    var
        ItemSystemId: Text;
        VariantCode: Text;
    begin
        if SelectedItemNo = '' then
            exit;
        if not ItemNoToSystemId.ContainsKey(SelectedItemNo) then
            exit;

        ItemSystemId := ItemNoToSystemId.Get(SelectedItemNo);
        if SelectedItemFilter = '' then
            SelectedItemFilter := ItemSystemId
        else
            SelectedItemFilter += '|' + ItemSystemId;

        if RawSelectedItemVariants.ContainsKey(SelectedItemNo) then
            VariantCode := RawSelectedItemVariants.Get(SelectedItemNo);

        if not SelectedItemVariants.ContainsKey(ItemSystemId) then
            SelectedItemVariants.Add(ItemSystemId, VariantCode);
    end;

    local procedure StoreResolvedItemVariants(ItemFilter: Text; SelectedItemVariants: Dictionary of [Text, Text])
    var
        ItemSystemId: Text;
        VariantCode: Text;
    begin
        if ItemFilter = '' then
            exit;

        foreach ItemSystemId in ItemFilter.Split('|') do
            if SelectedItemVariants.ContainsKey(ItemSystemId) then begin
                VariantCode := SelectedItemVariants.Get(ItemSystemId);
                if not ResolvedItemVariants.ContainsKey(ItemSystemId) then
                    ResolvedItemVariants.Add(ItemSystemId, VariantCode);
            end;
    end;

    local procedure BuildFilteredItemFilter(SourceItemFilter: Text; var Rec: Record Item; RequiredQuantity: Decimal; InUOMCode: Code[10]; ApplyAvailabilityFilter: Boolean; SelectedItemVariants: Dictionary of [Text, Text]; var AvailableItemVariants: Dictionary of [Text, Text]): Text
    var
        Item: Record Item;
        ItemSystemId: Guid;
        VariantCode: Text;
        FilteredItemFilter: Text;
        ResultCount: Integer;
    begin
        Clear(AvailableItemVariants);

        if SourceItemFilter = '' then
            exit('');

        foreach ItemSystemId in SourceItemFilter.Split('|') do begin
            if ApplyAvailabilityFilter then begin
                if Item.GetBySystemId(ItemSystemId) then begin
                    Item.CopyFilters(Rec);
                    if FindFirstAvailableVariant(Item, Format(ItemSystemId), RequiredQuantity, InUOMCode, SelectedItemVariants, VariantCode) then begin
                        FilteredItemFilter += ItemSystemId + '|';
                        AddAvailableItemVariant(AvailableItemVariants, Format(ItemSystemId), VariantCode);
                        ResultCount += 1;
                    end;
                end;
            end else begin
                FilteredItemFilter += ItemSystemId + '|';
                AddAvailableItemVariant(AvailableItemVariants, Format(ItemSystemId), GetFirstVariantCode(Format(ItemSystemId), SelectedItemVariants));
                ResultCount += 1;
            end;

            if ResultCount = 10 then
                break;
        end;

        exit(FilteredItemFilter.TrimEnd('|'));
    end;

    local procedure FindFirstAvailableVariant(var Item: Record Item; ItemSystemId: Text; RequiredQuantity: Decimal; InUOMCode: Code[10]; SelectedItemVariants: Dictionary of [Text, Text]; var AvailableVariantCode: Text): Boolean
    var
        VariantCode: Text;
        VariantCodes: Text;
    begin
        AvailableVariantCode := '';
        if SelectedItemVariants.ContainsKey(ItemSystemId) then
            VariantCodes := SelectedItemVariants.Get(ItemSystemId);

        if VariantCodes = '' then begin
            Item.SetRange("Variant Filter", '');
            exit(IsRequiredQuantityAvailable(Item, RequiredQuantity, InUOMCode));
        end;

        foreach VariantCode in VariantCodes.Split('|') do begin
            Item.SetRange("Variant Filter", CopyStr(VariantCode, 1, MaxStrLen(Item."Variant Filter")));
            if IsRequiredQuantityAvailable(Item, RequiredQuantity, InUOMCode) then begin
                AvailableVariantCode := VariantCode;
                exit(true);
            end;
        end;

        exit(false);
    end;

    local procedure GetFirstVariantCode(ItemSystemId: Text; SelectedItemVariants: Dictionary of [Text, Text]): Text
    var
        VariantCode: Text;
        VariantCodes: Text;
    begin
        if not SelectedItemVariants.ContainsKey(ItemSystemId) then
            exit('');

        VariantCodes := SelectedItemVariants.Get(ItemSystemId);
        foreach VariantCode in VariantCodes.Split('|') do
            exit(VariantCode);

        exit('');
    end;

    local procedure AddAvailableItemVariant(var AvailableItemVariants: Dictionary of [Text, Text]; ItemSystemId: Text; VariantCode: Text)
    begin
        if AvailableItemVariants.ContainsKey(ItemSystemId) then
            AvailableItemVariants.Set(ItemSystemId, VariantCode)
        else
            AvailableItemVariants.Add(ItemSystemId, VariantCode);
    end;

    local procedure ExtractSearchKeyWords(SearchFilter: Text; var SplitSearchKeywords: Text; var SearchKeyWordsTrimmed: List of [Text])
    var
        SearchKeyWord, KeyWord : Text;
        SearchKeyWords: List of [Text];
    begin
        if SearchFilter.StartsWith('&&') then begin // Modern search filter
            SearchKeyWords := SearchFilter.Split('&&');
            foreach KeyWord in SearchKeyWords do begin
                SearchKeyword := KeyWord.TrimStart('&').TrimEnd('*').Trim();
                if SearchKeyword <> '' then begin
                    SearchKeyWordsTrimmed.Add(SearchKeyword);
                    SplitSearchKeywords += SearchKeyword + ',';
                end;
            end;
        end
        else
            if SearchFilter.StartsWith('@*') then begin // Legacy search filter
                SearchKeyWords := SearchFilter.Split(' ');
                foreach KeyWord in SearchKeyWords do begin
                    SearchKeyword := KeyWord.TrimStart('@*').TrimEnd('*').Trim();
                    if SearchKeyword <> '' then begin
                        SearchKeyWordsTrimmed.Add(SearchKeyword);
                        SplitSearchKeywords += SearchKeyword + ',';
                    end;
                end;
            end;
    end;

    local procedure CountFilterItems(ItemFilter: Text): Integer
    begin
        if ItemFilter = '' then
            exit(0);
        exit(ItemFilter.Split('|').Count());
    end;

    local procedure BuildSearchQueryText(SearchKeyWordsTrimmed: List of [Text]): Text
    var
        SearchKeyword: Text;
        SearchQueryBuilder: TextBuilder;
    begin
        foreach SearchKeyword in SearchKeyWordsTrimmed do begin
            if SearchQueryBuilder.Length() > 0 then
                SearchQueryBuilder.Append(' ');
            SearchQueryBuilder.Append(SearchKeyword);
        end;

        exit(SearchQueryBuilder.ToText());
    end;

    local procedure IsRequiredQuantityAvailable(var Item: Record Item; RequiredQuantity: Decimal; LineUOM: Code[10]): Boolean
    var
        Item2: Record Item;
        ItemAvailFormsMgt: Codeunit "Item Availability Forms Mgt";
        ExpectedInventory, DummyQtyAvailable, PlannedOrderReleases, GrossRequirement, PlannedOrderRcpt, ScheduledRcpt, ProjAvailableBalance, ProjAvailableBalanceInOUM, AvailableInventory : Decimal;
    begin
        if Item.Type <> Item.Type::Inventory then
            exit(true);

        // Copy the item to avoid potential modifying the original record in ItemAvailFormsMgt.CalcAvailQuantities
        Item2.Copy(Item);
        ItemAvailFormsMgt.CalcAvailQuantities(Item2, true, GrossRequirement, PlannedOrderRcpt, ScheduledRcpt,
            PlannedOrderReleases, ProjAvailableBalance, ExpectedInventory, DummyQtyAvailable, AvailableInventory);

        if ProjAvailableBalance <= 0 then
            exit(false);

        if LineUOM = '' then
            LineUOM := Item."Sales Unit of Measure";

        ProjAvailableBalanceInOUM := CalcProjAvailableBalanceInUOM(Item, ProjAvailableBalance, LineUOM);
        if ProjAvailableBalanceInOUM <= 0 then
            exit(false);

        exit(ProjAvailableBalanceInOUM >= RequiredQuantity);
    end;

    internal procedure CalcProjAvailableBalanceInUOM(Item: Record Item; ProjAvailableBalance: Decimal; LineUOM: Code[10]): Decimal;
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        QtyRoundingPrecision: Decimal;
    begin
        if LineUOM in ['', Item."Base Unit of Measure"] then
            exit(ProjAvailableBalance)
        else
            if ItemUnitOfMeasure.Get(Item."No.", LineUOM) and (ItemUnitOfMeasure."Qty. per Unit of Measure" <> 0) then begin
                QtyRoundingPrecision := ItemUnitOfMeasure."Qty. Rounding Precision";
                if QtyRoundingPrecision = 0 then
                    QtyRoundingPrecision := 0.00001;
                exit(Round(ProjAvailableBalance / ItemUnitOfMeasure."Qty. per Unit of Measure", QtyRoundingPrecision));
            end else
                exit(0);
    end;

    local procedure LogTelemetryForFindItems(TelemetryCustomDimension: Dictionary of [Text, Text])
    var
        SOASetupRec: Record "SOA Setup";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        SOASetup: Codeunit "SOA Setup";
    begin
        // Log only for agent session
        if AgentTaskID = 0 then
            exit;

        // Agent session context
        TelemetryCustomDimension.Add('TaskId', Format(AgentTaskID));
        TelemetryCustomDimension.Add('AgentUserSecurityId', Format(UserSecurityId()));

        // Search setup
        if SOASetupRec.FindFirst() then begin
            TelemetryCustomDimension.Add('SearchOnlyAvailableItems', Format(SOASetupRec."Search Only Available Items"));
            TelemetryCustomDimension.Add('IncludeCapableToPromise', Format(SOASetupRec."Incl. Capable to Promise"));
        end;

        // Log usage
        FeatureTelemetry.LogUsage('0000QB0', SOASetup.GetFeatureName(), 'SOA Multi Items Availability: Find Items', TelemetryCustomDimension)
    end;

    [InternalEvent(false, false)]
    local procedure OnAfterFindRecordItem(ItemFilter: Text; Which: Text; CrossColumnSearchFilter: Text; Found: Boolean; RequiredQuantity: Decimal; InUOMCode: Code[10])
    begin
    end;
}