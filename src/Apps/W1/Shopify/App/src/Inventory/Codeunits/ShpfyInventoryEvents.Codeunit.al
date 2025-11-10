// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using Microsoft.Inventory.Item;

/// <summary>
/// Codeunit Shpfy Inventory Events (ID 30196).
/// </summary>
codeunit 30196 "Shpfy Inventory Events"
{
    [IntegrationEvent(false, false)]
    /// <summary> 
    /// Raised Before Calculation Stock.
    /// </summary>
    /// <param name="Item">Parameter of type Record Item.</param>
    /// <param name="ShopifyShop">Parameter of type Record "Shopify Shop".</param>
    /// <param name="ShopLocation">Parameter of type Record "Shopify Shop Location".</param>
    /// <param name="Stock">Parameter of type Decimal.</param>
    /// <param name="StockCalculation">Parameter of type Interface "Shpfy Stock Calculation".</param>
    /// <param name="ShopInventory">Parameter of type Record "Shopify Shop Inventory".</param>
    /// <param name="IsHandled">Parameter of type Boolean.</param>
    internal procedure OnBeforeCalculationStock(Item: Record Item; ShopifyShop: Record "Shpfy Shop"; ShopLocation: Record "Shpfy Shop Location"; var Stock: Decimal; StockCalculation: Interface "Shpfy Stock Calculation"; ShopInventory: Record "Shpfy Shop Inventory"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    /// <summary> 
    /// Raised After Calculation Stock.
    /// </summary>
    /// <param name="Item">Parameter of type Record Item.</param>
    /// <param name="ShopifyShop">Parameter of type Record "Shopify Shop".</param>
    /// <param name="LocationFilter">Parameter of type Text.</param>
    /// <param name="StockResult">Parameter of type Decimal.</param>
    internal procedure OnAfterCalculationStock(Item: Record Item; ShopifyShop: Record "Shpfy Shop"; LocationFilter: Text; var StockResult: Decimal)
    begin
    end;
}