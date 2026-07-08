// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

/// <summary>
/// Codeunit Shpfy Shipping Methods (ID 30193).
/// </summary>
codeunit 30193 "Shpfy Shipping Methods"
{
    Access = Internal;

    var
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        JsonHelper: Codeunit "Shpfy Json Helper";

    /// <summary> 
    /// Description for GetShippingMethods.
    /// </summary>
    /// <param name="ShopifyShop">Parameter of type Record "Shopify Shop".</param>
    internal procedure GetShippingMethods(var ShopifyShop: Record "Shpfy Shop")
    var
        Shop: Record "Shpfy Shop";
        GraphQLType: Enum "Shpfy GraphQL Type";
        Parameters: Dictionary of [Text, Text];
        JDeliveryProfiles: JsonArray;
        JDeliveryProfile: JsonToken;
        JResponse: JsonToken;
    begin
        if ShopifyShop.GetFilters = '' then begin
            Shop := ShopifyShop;
            Shop.SetRecFilter();
        end else
            Shop.CopyFilters(ShopifyShop);
        if Shop.FindFirst() then begin
            CommunicationMgt.SetShop(Shop);
            if IsMarketDrivenShipping() then begin
                GetMarketShippingMethods(Shop);
                exit;
            end;
            GraphQLType := GraphQLType::Shipping_GetDeliveryProfiles;
            repeat
                JResponse := CommunicationMgt.ExecuteGraphQL(GraphQLType, Parameters);
                if JsonHelper.GetJsonArray(JResponse, JDeliveryProfiles, 'data.deliveryProfiles.edges') then
                    foreach JDeliveryProfile in JDeliveryProfiles do
                        GetProfileLocationGroups(JDeliveryProfile, Shop);

                if Parameters.ContainsKey('After') then
                    Parameters.Set('After', JsonHelper.GetValueAsText(JDeliveryProfile.AsObject(), 'cursor'))
                else
                    Parameters.Add('After', JsonHelper.GetValueAsText(JDeliveryProfile.AsObject(), 'cursor'));
                GraphQLType := GraphQLType::Shipping_GetNextDeliveryProfiles;
            until not JsonHelper.GetValueAsBoolean(JResponse, 'data.deliveryProfiles.pageInfo.hasNextPage');
        end;
    end;

    // Market-driven shipping moves merchant shipping configuration from delivery profiles to Markets.
    // For shops on that model the legacy deliveryProfiles query returns stale/incomplete data, so the
    // shipping methods are read from the Markets API instead. Shopify.dev upgrade guide, readers Option B.
    local procedure IsMarketDrivenShipping(): Boolean
    var
        JResponse: JsonToken;
    begin
        JResponse := CommunicationMgt.ExecuteGraphQL('{"query":"query { shop { features { marketDrivenShipping } } }"}');
        exit(JsonHelper.GetValueAsBoolean(JResponse, 'data.shop.features.marketDrivenShipping'));
    end;

    local procedure GetMarketShippingMethods(Shop: Record "Shpfy Shop")
    var
        GraphQLType: Enum "Shpfy GraphQL Type";
        Parameters: Dictionary of [Text, Text];
        JMarkets: JsonArray;
        JMarket: JsonToken;
        JResponse: JsonToken;
    begin
        GraphQLType := GraphQLType::Shipping_GetMarketShippingMethods;
        repeat
            JResponse := CommunicationMgt.ExecuteGraphQL(GraphQLType, Parameters);
            if JsonHelper.GetJsonArray(JResponse, JMarkets, 'data.markets.edges') then
                foreach JMarket in JMarkets do
                    AddMarketShippingMethods(JMarket, Shop);

            if JMarkets.Count() > 0 then
                if Parameters.ContainsKey('After') then
                    Parameters.Set('After', JsonHelper.GetValueAsText(JMarket.AsObject(), 'cursor'))
                else
                    Parameters.Add('After', JsonHelper.GetValueAsText(JMarket.AsObject(), 'cursor'));
            GraphQLType := GraphQLType::Shipping_GetNextMarketShippingMethods;
        until not JsonHelper.GetValueAsBoolean(JResponse, 'data.markets.pageInfo.hasNextPage');
    end;

    local procedure AddMarketShippingMethods(JMarket: JsonToken; Shop: Record "Shpfy Shop")
    var
        ShipmentMethodMapping: Record "Shpfy Shipment Method Mapping";
        JOptionDefinitions: JsonArray;
        JOptionDefinition: JsonToken;
        Name: Text;
    begin
        // A null shipping configuration means the market inherits shipping from its parent; the parent
        // market carries the same option names, so nothing is lost by skipping the inheriting market.
        // Carrier-calculated options have no static 'name' (rates are named by the carrier at checkout),
        // so they are not queried and simply yield an empty name that is skipped below.
        if not JsonHelper.GetValueAsBoolean(JMarket, 'node.delivery.shipping.isEnabled') then
            exit;
        if JsonHelper.GetJsonArray(JMarket, JOptionDefinitions, 'node.delivery.shipping.optionDefinitions.edges') then
            foreach JOptionDefinition in JOptionDefinitions do begin
                Name := JsonHelper.GetValueAsText(JOptionDefinition, 'node.name', MaxStrLen(ShipmentMethodMapping.Name));
                if JsonHelper.GetValueAsBoolean(JOptionDefinition, 'node.isActive') and (Name <> '') then
                    if not ShipmentMethodMapping.Get(Shop.Code, Name) then begin
                        Clear(ShipmentMethodMapping);
                        ShipmentMethodMapping."Shop Code" := Shop.Code;
                        ShipmentMethodMapping.Name := CopyStr(Name, 1, MaxStrLen(ShipmentMethodMapping.Name));
                        ShipmentMethodMapping.Insert();
                    end;
            end;
    end;

    local procedure GetProfileLocationGroups(JDeliveryProfile: JsonToken; Shop: Record "Shpfy Shop")
    var
        GraphQLType: Enum "Shpfy GraphQL Type";
        DeliveryProfileId: BigInteger;
        Parameters: Dictionary of [Text, Text];
        JProfileLocationGroups: JsonArray;
        JProfileLocationGroup: JsonToken;
        JResponse: JsonToken;
    begin
        DeliveryProfileId := CommunicationMgt.GetIdOfGId(JsonHelper.GetValueAsText(JDeliveryProfile.AsObject(), 'node.id'));
        Parameters.Add('DeliveryProfileId', Format(DeliveryProfileId));
        GraphQLType := GraphQLType::Inventory_GetLocationGroups;
        JResponse := CommunicationMgt.ExecuteGraphQL(GraphQLType, Parameters);
        if JsonHelper.GetJsonArray(JResponse, JProfileLocationGroups, 'data.deliveryProfile.profileLocationGroups') then
            foreach JProfileLocationGroup in JProfileLocationGroups do
                GetDeliveryMethods(CommunicationMgt.GetIdOfGId(JsonHelper.GetValueAsText(JProfileLocationGroup.AsObject(), 'locationGroup.id')), DeliveryProfileId, Shop);
    end;

    local procedure GetDeliveryMethods(ProfileLocationGroupId: BigInteger; DeliveryProfileId: BigInteger; Shop: Record "Shpfy Shop")
    var
        ShipmentMethodMapping: Record "Shpfy Shipment Method Mapping";
        GraphQLType: Enum "Shpfy GraphQL Type";
        Name: Text;
        Active: Boolean;
        Parameters: Dictionary of [Text, Text];
        JProfileLocationGroups: JsonArray;
        JProfileLocationGroup: JsonToken;
        JLocationGroupZones: JsonArray;
        JLocationGroupZone: JsonToken;
        JMethodDefinitions: JsonArray;
        JMethodDefinition: JsonToken;
        HasNextPage: Boolean;
        JResponse: JsonToken;
    begin
        GraphQLType := GraphQLType::Shipping_GetDeliveryMethods;
        Parameters.Add('DeliveryProfileId', Format(DeliveryProfileId));
        Parameters.Add('DeliveryLocationGroupId', Format(ProfileLocationGroupId));
        repeat
            JResponse := CommunicationMgt.ExecuteGraphQL(GraphQLType, Parameters);
            if JsonHelper.GetJsonArray(JResponse, JProfileLocationGroups, 'data.deliveryProfile.profileLocationGroups') then
                if JProfileLocationGroups.Count = 1 then begin
                    JProfileLocationGroups.Get(0, JProfileLocationGroup);
                    if JsonHelper.GetJsonArray(JProfileLocationGroup, JLocationGroupZones, 'locationGroupZones.edges') then
                        if JLocationGroupZones.Count > 0 then begin
                            foreach JLocationGroupZone in JLocationGroupZones do
                                if JsonHelper.GetJsonArray(JLocationGroupZone, JMethodDefinitions, 'node.methodDefinitions.edges') then
                                    foreach JMethodDefinition in JMethodDefinitions do begin
                                        Name := JsonHelper.GetValueAsText(JMethodDefinition, 'node.name', MaxStrLen(ShipmentMethodMapping.Name));
                                        Active := JsonHelper.GetValueAsBoolean(JMethodDefinition, 'node.active');
                                        if Active and (Name <> '') then
                                            if not ShipmentMethodMapping.Get(Shop.Code, Name) then begin
                                                Clear(ShipmentMethodMapping);
                                                ShipmentMethodMapping."Shop Code" := Shop.Code;
                                                ShipmentMethodMapping.Name := CopyStr(Name, 1, MaxStrLen(ShipmentMethodMapping.Name));
                                                ShipmentMethodMapping.Insert();
                                            end;
                                    end;
                            if Parameters.ContainsKey('After') then
                                Parameters.Set('After', JsonHelper.GetValueAsText(JLocationGroupZone.AsObject(), 'cursor'))
                            else
                                Parameters.Add('After', JsonHelper.GetValueAsText(JLocationGroupZone.AsObject(), 'cursor'));
                            HasNextPage := JsonHelper.GetValueAsBoolean(JProfileLocationGroup, 'locationGroupZones.pageInfo.hasNextPage');
                        end;
                end;
            GraphQLType := GraphQLType::Shipping_GetNextDeliveryMethods;
        until not HasNextPage;
    end;
}