// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

/// <summary>
/// Codeunit Shpfy Product Collection API (ID 30404).
/// </summary>
codeunit 30404 "Shpfy Product Collection API"
{
    Access = Internal;

    var
        JsonHelper: Codeunit "Shpfy Json Helper";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";

    /// <summary>
    /// Retrieves the custom product collections from Shopify and updates the table with the new product collections.
    /// </summary>
    /// <param name="ShopCode">The code of the shop.</param>
    internal procedure RetrieveCustomProductCollectionsFromShopify(ShopCode: Code[20])
    var
        GraphQLType: Enum "Shpfy GraphQL Type";
        JResponse: JsonToken;
        JPublications: JsonArray;
        Cursor: Text;
        Parameters: Dictionary of [Text, Text];
        CurrentCollections: List of [BigInteger];
    begin
        CurrentCollections := this.RetrieveCollections(ShopCode);

        this.CommunicationMgt.SetShop(ShopCode);
        GraphQLType := GraphQLType::GetCustomProductCollections;

        repeat
            JResponse := this.CommunicationMgt.ExecuteGraphQL(GraphQLType, Parameters);
            if this.JsonHelper.GetJsonArray(JResponse, JPublications, 'data.collections.edges') then begin
                this.ExtractProductCollections(JPublications, ShopCode, CurrentCollections, Cursor);
                if Parameters.ContainsKey('After') then
                    Parameters.Set('After', Cursor)
                else
                    Parameters.Add('After', Cursor);
                GraphQLType := GraphQLType::GetNextCustomProductCollections;
            end;
        until not this.JsonHelper.GetValueAsBoolean(JResponse, 'data.collections.pageInfo.hasNextPage');

        this.RemoveNotExistingCollections(CurrentCollections);
    end;

    local procedure RetrieveCollections(ShopCode: Code[20]): List of [BigInteger]
    var
        ProductCollection: Record "Shpfy Product Collection";
        Collections: List of [BigInteger];
    begin
        ProductCollection.SetRange("Shop Code", ShopCode);
        if ProductCollection.FindSet() then
            repeat
                Collections.Add(ProductCollection.Id);
            until ProductCollection.Next() = 0;
        exit(Collections);
    end;

    local procedure RemoveNotExistingCollections(CurrentCollections: List of [BigInteger])
    var
        ProductCollection: Record "Shpfy Product Collection";
        CollectionId: BigInteger;
    begin
        foreach CollectionId in CurrentCollections do begin
            ProductCollection.Get(CollectionId);
            ProductCollection.Delete(true);
        end;
    end;

    local procedure ExtractProductCollections(JPublications: JsonArray; ShopCode: Code[20]; CurrentCollections: List of [BigInteger]; var Cursor: Text)
    var
        ProductCollection: Record "Shpfy Product Collection";
        JPublication: JsonToken;
        CollectionId: BigInteger;
    begin
        foreach JPublication in JPublications do begin
            Cursor := this.JsonHelper.GetValueAsText(JPublication, 'cursor');
            CollectionId := this.CommunicationMgt.GetIdOfGId(this.JsonHelper.GetValueAsText(JPublication, '$.node.id'));
            if not ProductCollection.Get(CollectionId) then begin
                ProductCollection.Init();
                ProductCollection.Validate(Id, CollectionId);
                ProductCollection.Validate(Name, this.JsonHelper.GetValueAsText(JPublication, '$.node.title'));
                ProductCollection.Validate("Shop Code", ShopCode);
                ProductCollection.Insert(true);
            end else
                CurrentCollections.Remove(CollectionId);
        end;
    end;
}
