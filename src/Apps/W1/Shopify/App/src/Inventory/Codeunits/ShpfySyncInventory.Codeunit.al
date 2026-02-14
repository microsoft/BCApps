// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

/// <summary>
/// Codeunit Shpfy Sync Inventory (ID 30197).
/// </summary>
codeunit 30197 "Shpfy Sync Inventory"
{
    Access = Internal;
    TableNo = "Shpfy Shop Inventory";

    var
        InventoryApi: Codeunit "Shpfy Inventory API";
        SkipImport: Boolean;

    trigger OnRun()
    var
        ShopInventory: Record "Shpfy Shop Inventory";
        ShopLocation: Record "Shpfy Shop Location";
        ShpfyInventoryEvents: Codeunit "Shpfy Inventory Events";
        ShopFilter: Text;
        VariantIdFilter: Text;
    begin
        ShopFilter := Rec.GetFilter("Shop Code");
        if ShopFilter <> '' then
            ShopLocation.SetRange("Shop Code", ShopFilter);

        ShopInventory.CopyFilters(Rec);

        if not SkipImport then begin
            ShopLocation.SetFilter("Stock Calculation", '<>%1', ShopLocation."Stock Calculation"::Disabled);
            if ShopLocation.FindSet(false) then begin
                InventoryApi.SetShop(ShopLocation."Shop Code");
                InventoryApi.SetInventoryIds();
                repeat
                    InventoryApi.ImportStock(ShopLocation);
                until ShopLocation.Next() = 0;
            end;
            InventoryApi.RemoveUnusedInventoryIds();
        end;

        InventoryApi.ExportStock(ShopInventory, SkipImport);
    end;

    internal procedure SetSkipImport(ImportSkip: Boolean)
    begin
        SkipImport := ImportSkip;
    end;
}