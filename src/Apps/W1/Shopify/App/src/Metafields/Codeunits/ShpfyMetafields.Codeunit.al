// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

/// <summary>
/// Provides functionality for managing Shopify metafields.
/// </summary>
codeunit 30418 "Shpfy Metafields"
{
    Access = Public;

    var
        MetafieldAPI: Codeunit "Shpfy Metafield API";

    /// <summary>
    /// Retrieves the metafield definitions from Shopify for the specified resource.
    /// </summary>
    /// <param name="ParentTableNo">Table id of the parent resource (e.g., Database::"Shpfy Product").</param>
    /// <param name="OwnerId">Id of the parent resource in Shopify.</param>
    /// <param name="ShopCode">The code of the Shopify shop.</param>
    procedure GetMetafieldDefinitions(ParentTableNo: Integer; OwnerId: BigInteger; ShopCode: Code[20])
    begin
        MetafieldAPI.GetMetafieldDefinitions(ParentTableNo, OwnerId, ShopCode);
    end;

    /// <summary>
    /// Synchronizes a single metafield to Shopify, creating or updating it as needed.
    /// </summary>
    /// <param name="Metafield">The metafield record to synchronize to Shopify.</param>
    /// <param name="ShopCode">The code of the Shopify shop.</param>
    /// <returns>The Shopify Id of the metafield.</returns>
    procedure SyncMetafieldToShopify(var Metafield: Record "Shpfy Metafield"; ShopCode: Code[20]): BigInteger
    begin
        exit(MetafieldAPI.SyncMetafieldToShopify(Metafield, ShopCode));
    end;

    /// <summary>
    /// Synchronizes all metafields for the specified resource to Shopify.
    /// Only metafields that have been updated in BC since the last sync will be sent.
    /// </summary>
    /// <param name="ParentTableNo">Table id of the parent resource (e.g., Database::"Shpfy Product").</param>
    /// <param name="OwnerId">Id of the parent resource in Shopify.</param>
    /// <param name="ShopCode">The code of the Shopify shop.</param>
    procedure SyncMetafieldsToShopify(ParentTableNo: Integer; OwnerId: BigInteger; ShopCode: Code[20])
    begin
        MetafieldAPI.SyncMetafieldsToShopify(ParentTableNo, OwnerId, ShopCode);
    end;
}
