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
        ResolvedItemVariants: Dictionary of [Text, Code[10]];
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

    [EventSubscriber(ObjectType::Page, Page::"SOA Multi Items Availability", OnGetResolvedVariantCodeOnBeforeExit, '', false, false)]
    local procedure OnGetResolvedVariantCodeOnBeforeExit(ItemSystemId: Guid; var VariantCode: Code[10])
    begin
        if ResolvedItemVariants.ContainsKey(Format(ItemSystemId)) then
            VariantCode := ResolvedItemVariants.Get(Format(ItemSystemId));
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
        TaskMessageReader: Codeunit "SOA Task Message Reader";
        CandidateArray: JsonArray;
        SearchKeyWordsTrimmed: List of [Text];
        SelectedMatchingItemVariants: Dictionary of [Text, List of [Code[10]]];
        SelectedAlternativeItemVariants: Dictionary of [Text, List of [Code[10]]];
        UnresolvedVariantRequests: Dictionary of [Text, Boolean];
        EmptyItemVariants: Dictionary of [Text, List of [Code[10]]];
        AvailableMatchingItemVariants: Dictionary of [Text, Code[10]];
        AvailableAlternativeItemVariants: Dictionary of [Text, Code[10]];
        AvailableItemVariants: Dictionary of [Text, Code[10]];
        SearchFilter: Text;
        SearchQuery: Text;
        SplitSearchKeywords: Text;
        ItemFilter: Text;
        SelectedMatchingItemFilter: Text;
        SelectedAlternativeItemFilter: Text;
        MessageContent: Text;
        SearchType: Text;
        OriginalFilterGroup: Integer;
        CountBeforeAvailabilityCheck: Integer;
        ApplyAvailabilityFilter: Boolean;
        ItemSelectorUsed: Boolean;
    begin
        MatchingItem := true;
        OriginalFilterGroup := Rec.FilterGroup();
        Rec.FilterGroup(-1);
        SearchFilter := Rec.GetFilter("No."); //Get current search filter
        Rec.FilterGroup(OriginalFilterGroup);

        if SearchFilter = CrossColumnSearchFilter then //If the search filter is the same as the last one, then we don't need to search
            exit;
        CrossColumnSearchFilter := SearchFilter;
        Clear(ResolvedItemVariants);
        if SearchFilter = '=''<>*''' then //If the search filter is empty, clear the previous search state without running a new search
            exit;

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
                    MessageContent := TaskMessageReader.GetLastIncomingMessageContent(AgentTaskID);
                    if SelectBestItem(ItemFilter, SearchQuery, MessageContent, CandidateArray, SelectedMatchingItemFilter, SelectedAlternativeItemFilter, SelectedMatchingItemVariants, SelectedAlternativeItemVariants, UnresolvedVariantRequests) then begin
                        NormalizeVariantAlternatives(SelectedMatchingItemFilter, SelectedMatchingItemVariants, SelectedAlternativeItemFilter, SelectedAlternativeItemVariants, UnresolvedVariantRequests);
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
                        MatchingItem := false;
                    end else begin
                        StoreResolvedItemVariants(ItemFilter, AvailableMatchingItemVariants);
                        MatchingItem := true;
                    end;
                end else
                    if ItemSelectorUsed then begin
                        if SelectedAlternativeItemFilter <> '' then begin
                            ItemFilter := BuildFilteredItemFilter(SelectedAlternativeItemFilter, Rec, RequiredQuantity, InUOMCode, ApplyAvailabilityFilter, SelectedAlternativeItemVariants, AvailableAlternativeItemVariants);
                            StoreResolvedItemVariants(ItemFilter, AvailableAlternativeItemVariants);
                            MatchingItem := false;
                        end else
                            ItemFilter := '';
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

    local procedure SelectBestItem(ItemFilter: Text; SearchQuery: Text; MessageContent: Text; CandidateArray: JsonArray; var SelectedMatchingItemFilter: Text; var SelectedAlternativeItemFilter: Text; var SelectedMatchingItemVariants: Dictionary of [Text, List of [Code[10]]]; var SelectedAlternativeItemVariants: Dictionary of [Text, List of [Code[10]]]; var UnresolvedVariantRequests: Dictionary of [Text, Boolean]): Boolean
    var
        Item: Record Item;
        ItemSelector: Codeunit "SOA Item Selector";
        ItemNoToSystemId: Dictionary of [Text, Text];
        RawSelectedMatchingItemVariants: Dictionary of [Text, List of [Code[10]]];
        RawSelectedAlternativeItemVariants: Dictionary of [Text, List of [Code[10]]];
        RawUnresolvedVariantRequests: Dictionary of [Text, Boolean];
        RawSelectedMatchingItemFilter: Text;
        RawSelectedAlternativeItemFilter: Text;
        SelectedMatchingItemNo: Text;
        SelectedAlternativeItemNo: Text;
        UnresolvedVariantItemNo: Text;
    begin
        SelectedMatchingItemFilter := '';
        SelectedAlternativeItemFilter := '';
        Clear(SelectedMatchingItemVariants);
        Clear(SelectedAlternativeItemVariants);
        Clear(UnresolvedVariantRequests);

        if CandidateArray.Count() > 0 then
            if ItemSelector.SelectBestMatchingItemWithVariantsAndUnresolvedRequests(SearchQuery, MessageContent, CandidateArray, SelectedMatchingItemFilter, SelectedAlternativeItemFilter, RawSelectedMatchingItemVariants, RawSelectedAlternativeItemVariants, RawUnresolvedVariantRequests) then begin
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

                foreach UnresolvedVariantItemNo in RawUnresolvedVariantRequests.Keys() do
                    if ItemNoToSystemId.ContainsKey(UnresolvedVariantItemNo) then
                        UnresolvedVariantRequests.Add(ItemNoToSystemId.Get(UnresolvedVariantItemNo), RawUnresolvedVariantRequests.Get(UnresolvedVariantItemNo));

                if (SelectedMatchingItemFilter <> '') or (SelectedAlternativeItemFilter <> '') or (UnresolvedVariantRequests.Count() > 0) then
                    exit(true);
            end;
        exit(false);
    end;

    local procedure NormalizeVariantAlternatives(var SelectedMatchingItemFilter: Text; var SelectedMatchingItemVariants: Dictionary of [Text, List of [Code[10]]]; var SelectedAlternativeItemFilter: Text; var SelectedAlternativeItemVariants: Dictionary of [Text, List of [Code[10]]]; UnresolvedVariantRequests: Dictionary of [Text, Boolean])
    begin
        AddAllowedUnresolvedVariantAlternatives(SelectedAlternativeItemFilter, SelectedAlternativeItemVariants, UnresolvedVariantRequests);
        RemoveUnresolvedAlternativeItemsWithoutVariants(SelectedAlternativeItemFilter, SelectedAlternativeItemVariants, UnresolvedVariantRequests);
        RemoveMatchingItemsWithBlankVariantAndSameItemAlternatives(SelectedMatchingItemFilter, SelectedMatchingItemVariants, SelectedAlternativeItemVariants, UnresolvedVariantRequests);
    end;

    local procedure AddAllowedUnresolvedVariantAlternatives(var SelectedAlternativeItemFilter: Text; var SelectedAlternativeItemVariants: Dictionary of [Text, List of [Code[10]]]; UnresolvedVariantRequests: Dictionary of [Text, Boolean])
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        VariantCodes: List of [Code[10]];
        ItemSystemId: Text;
    begin
        Item.SetLoadFields("No.");
        ItemVariant.SetLoadFields(Code);
        foreach ItemSystemId in UnresolvedVariantRequests.Keys() do begin
            if not UnresolvedVariantRequests.Get(ItemSystemId) then
                continue;

            Clear(VariantCodes);
            if SelectedAlternativeItemVariants.ContainsKey(ItemSystemId) then begin
                VariantCodes := SelectedAlternativeItemVariants.Get(ItemSystemId);
                if VariantCodes.Count() > 0 then
                    continue;
            end;

            if not Item.GetBySystemId(ItemSystemId) then
                continue;

            ItemVariant.SetRange("Item No.", Item."No.");
            if ItemVariant.FindSet() then
                repeat
                    VariantCodes.Add(ItemVariant.Code);
                until ItemVariant.Next() = 0;

            if VariantCodes.Count() = 0 then
                continue;

            if SelectedAlternativeItemVariants.ContainsKey(ItemSystemId) then
                SelectedAlternativeItemVariants.Set(ItemSystemId, VariantCodes)
            else begin
                SelectedAlternativeItemVariants.Add(ItemSystemId, VariantCodes);
                if SelectedAlternativeItemFilter = '' then
                    SelectedAlternativeItemFilter := ItemSystemId
                else
                    SelectedAlternativeItemFilter += '|' + ItemSystemId;
            end;
        end;
    end;

    local procedure RemoveUnresolvedAlternativeItemsWithoutVariants(var SelectedAlternativeItemFilter: Text; var SelectedAlternativeItemVariants: Dictionary of [Text, List of [Code[10]]]; UnresolvedVariantRequests: Dictionary of [Text, Boolean])
    var
        NewSelectedAlternativeItemVariants: Dictionary of [Text, List of [Code[10]]];
        VariantCodes: List of [Code[10]];
        ItemSystemId: Text;
        NewSelectedAlternativeItemFilter: Text;
    begin
        if SelectedAlternativeItemFilter = '' then
            exit;

        foreach ItemSystemId in SelectedAlternativeItemFilter.Split('|') do begin
            Clear(VariantCodes);
            if SelectedAlternativeItemVariants.ContainsKey(ItemSystemId) then
                VariantCodes := SelectedAlternativeItemVariants.Get(ItemSystemId);

            if UnresolvedVariantRequests.ContainsKey(ItemSystemId) and (VariantCodes.Count() = 0) then
                continue;

            if NewSelectedAlternativeItemFilter = '' then
                NewSelectedAlternativeItemFilter := ItemSystemId
            else
                NewSelectedAlternativeItemFilter += '|' + ItemSystemId;

            if not NewSelectedAlternativeItemVariants.ContainsKey(ItemSystemId) then
                NewSelectedAlternativeItemVariants.Add(ItemSystemId, VariantCodes);
        end;

        SelectedAlternativeItemFilter := NewSelectedAlternativeItemFilter;
        SelectedAlternativeItemVariants := NewSelectedAlternativeItemVariants;
    end;

    local procedure RemoveMatchingItemsWithBlankVariantAndSameItemAlternatives(var SelectedMatchingItemFilter: Text; var SelectedMatchingItemVariants: Dictionary of [Text, List of [Code[10]]]; SelectedAlternativeItemVariants: Dictionary of [Text, List of [Code[10]]]; UnresolvedVariantRequests: Dictionary of [Text, Boolean])
    var
        NewSelectedMatchingItemVariants: Dictionary of [Text, List of [Code[10]]];
        AlternativeVariantCodes: List of [Code[10]];
        MatchingVariantCodes: List of [Code[10]];
        ItemSystemId: Text;
        NewSelectedMatchingItemFilter: Text;
    begin
        if SelectedMatchingItemFilter = '' then
            exit;

        foreach ItemSystemId in SelectedMatchingItemFilter.Split('|') do begin
            Clear(MatchingVariantCodes);
            if SelectedMatchingItemVariants.ContainsKey(ItemSystemId) then
                MatchingVariantCodes := SelectedMatchingItemVariants.Get(ItemSystemId);

            if MatchingVariantCodes.Count() = 0 then
                if UnresolvedVariantRequests.ContainsKey(ItemSystemId) then
                    continue
                else
                    if SelectedAlternativeItemVariants.ContainsKey(ItemSystemId) then begin
                        AlternativeVariantCodes := SelectedAlternativeItemVariants.Get(ItemSystemId);
                        if AlternativeVariantCodes.Count() > 0 then
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
        ItemNoFilterBuilder: Record Item;
        ItemVariant: Record "Item Variant";
        ItemVariants: Dictionary of [Code[20], JsonArray];
        CandidateObject: JsonObject;
        ColumnValuesObject: JsonObject;
        VariantArray: JsonArray;
        VariantObject: JsonObject;
        ItemNoFilter: Text;
    begin
        Clear(CandidateArray);
        if ItemFilter = '' then
            exit;

        Item.SetLoadFields("No.", Description, "Description 2", SystemId);
        Item.SetFilter(SystemId, ItemFilter);
        if not Item.FindSet() then
            exit;

        repeat
            ItemNoFilterBuilder.SetRange("No.", Item."No.");
            if ItemNoFilter <> '' then
                ItemNoFilter += '|';
            ItemNoFilter += ItemNoFilterBuilder.GetFilter("No.");
        until Item.Next() = 0;

        ItemVariant.SetLoadFields("Item No.", Code, Description, "Description 2");
        ItemVariant.SetFilter("Item No.", ItemNoFilter);
        if ItemVariant.FindSet() then
            repeat
                Clear(VariantArray);
                if ItemVariants.Get(ItemVariant."Item No.", VariantArray) then;

                Clear(VariantObject);
                VariantObject.Add('Code', ItemVariant.Code);
                VariantObject.Add('Description', ItemVariant.Description);
                VariantObject.Add('Description 2', ItemVariant."Description 2");
                VariantArray.Add(VariantObject);

                if ItemVariants.ContainsKey(ItemVariant."Item No.") then
                    ItemVariants.Set(ItemVariant."Item No.", VariantArray)
                else
                    ItemVariants.Add(ItemVariant."Item No.", VariantArray);
            until ItemVariant.Next() = 0;

        if not Item.FindSet() then
            exit;

        repeat
            Clear(CandidateObject);
            Clear(ColumnValuesObject);
            Clear(VariantArray);

            ColumnValuesObject.Add('No.', Item."No.");
            ColumnValuesObject.Add('Description', Item.Description);
            ColumnValuesObject.Add('Description 2', Item."Description 2");

            if ItemVariants.Get(Item."No.", VariantArray) then;

            ColumnValuesObject.Add('Variants', VariantArray);
            CandidateObject.Add('system_id', Format(Item.SystemId));
            CandidateObject.Add('column_values', ColumnValuesObject);
            CandidateArray.Add(CandidateObject);
        until Item.Next() = 0;
    end;

    local procedure AddSelectedItem(var SelectedItemFilter: Text; var SelectedItemVariants: Dictionary of [Text, List of [Code[10]]]; SelectedItemNo: Text; ItemNoToSystemId: Dictionary of [Text, Text]; RawSelectedItemVariants: Dictionary of [Text, List of [Code[10]]])
    var
        ItemVariant: Record "Item Variant";
        RawVariantCodes: List of [Code[10]];
        ValidVariantCodes: List of [Code[10]];
        VariantCode: Code[10];
        ItemSystemId: Text;
    begin
        if SelectedItemNo = '' then
            exit;
        if not ItemNoToSystemId.ContainsKey(SelectedItemNo) then
            exit;

        if RawSelectedItemVariants.ContainsKey(SelectedItemNo) then begin
            RawVariantCodes := RawSelectedItemVariants.Get(SelectedItemNo);
            foreach VariantCode in RawVariantCodes do
                if ItemVariant.Get(CopyStr(SelectedItemNo, 1, MaxStrLen(ItemVariant."Item No.")), VariantCode) then
                    ValidVariantCodes.Add(VariantCode);

            if (RawVariantCodes.Count() > 0) and (ValidVariantCodes.Count() = 0) then
                exit;
        end;

        ItemSystemId := ItemNoToSystemId.Get(SelectedItemNo);
        if SelectedItemFilter = '' then
            SelectedItemFilter := ItemSystemId
        else
            SelectedItemFilter += '|' + ItemSystemId;

        if not SelectedItemVariants.ContainsKey(ItemSystemId) then
            SelectedItemVariants.Add(ItemSystemId, ValidVariantCodes);
    end;

    local procedure StoreResolvedItemVariants(ItemFilter: Text; SelectedItemVariants: Dictionary of [Text, Code[10]])
    var
        ItemSystemId: Text;
        VariantCode: Code[10];
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

    local procedure BuildFilteredItemFilter(SourceItemFilter: Text; var Rec: Record Item; RequiredQuantity: Decimal; InUOMCode: Code[10]; ApplyAvailabilityFilter: Boolean; SelectedItemVariants: Dictionary of [Text, List of [Code[10]]]; var AvailableItemVariants: Dictionary of [Text, Code[10]]): Text
    var
        Item: Record Item;
        ItemSystemId: Guid;
        VariantCode: Code[10];
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

    local procedure FindFirstAvailableVariant(var Item: Record Item; ItemSystemId: Text; RequiredQuantity: Decimal; InUOMCode: Code[10]; SelectedItemVariants: Dictionary of [Text, List of [Code[10]]]; var AvailableVariantCode: Code[10]): Boolean
    var
        VariantCodes: List of [Code[10]];
        VariantCode: Code[10];
    begin
        AvailableVariantCode := '';
        if SelectedItemVariants.ContainsKey(ItemSystemId) then
            VariantCodes := SelectedItemVariants.Get(ItemSystemId);

        if VariantCodes.Count() = 0 then begin
            Item.SetRange("Variant Filter", '');
            exit(IsRequiredQuantityAvailable(Item, RequiredQuantity, InUOMCode));
        end;

        foreach VariantCode in VariantCodes do begin
            Item.SetRange("Variant Filter", CopyStr(VariantCode, 1, MaxStrLen(Item."Variant Filter")));
            if IsRequiredQuantityAvailable(Item, RequiredQuantity, InUOMCode) then begin
                AvailableVariantCode := VariantCode;
                exit(true);
            end;
        end;

        exit(false);
    end;

    local procedure GetFirstVariantCode(ItemSystemId: Text; SelectedItemVariants: Dictionary of [Text, List of [Code[10]]]): Code[10]
    var
        VariantCodes: List of [Code[10]];
        VariantCode: Code[10];
    begin
        if not SelectedItemVariants.ContainsKey(ItemSystemId) then
            exit('');

        VariantCodes := SelectedItemVariants.Get(ItemSystemId);
        foreach VariantCode in VariantCodes do
            exit(VariantCode);

        exit('');
    end;

    local procedure AddAvailableItemVariant(var AvailableItemVariants: Dictionary of [Text, Code[10]]; ItemSystemId: Text; VariantCode: Code[10])
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
        FeatureTelemetry.LogUsage('0000QB7', SOASetup.GetFeatureName(), 'SOA Multi Items Availability: Find Items v2', TelemetryCustomDimension)
    end;

    [InternalEvent(false, false)]
    local procedure OnAfterFindRecordItem(ItemFilter: Text; Which: Text; CrossColumnSearchFilter: Text; Found: Boolean; RequiredQuantity: Decimal; InUOMCode: Code[10])
    begin
    end;
}