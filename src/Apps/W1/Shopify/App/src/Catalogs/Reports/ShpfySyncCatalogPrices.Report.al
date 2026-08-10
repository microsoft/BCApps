// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

/// <summary>
/// Report Shpfy Sync Catalog Prices (ID 30116).
/// </summary>
report 30116 "Shpfy Sync Catalog Prices"
{
    Caption = 'Shopify Sync Catalog Prices';
    UsageCategory = Tasks;
    ApplicationArea = All;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Shop; "Shpfy Shop")
        {
            RequestFilterFields = Code;

            dataitem(Catalog; "Shpfy Catalog")
            {
                DataItemLink = "Shop Code" = field(Code);
                RequestFilterFields = "Id", "Name";

                trigger OnPreDataItem()
                begin
                    Catalog.AddLoadFields(
                        "Id", "Company SystemId", "Name", "Shop Code", "Sync Prices", "Catalog Type",
                        "Customer Price Group", "Customer Discount Group", "Gen. Bus. Posting Group",
                        "VAT Bus. Posting Group", "Tax Area Code", "Tax Liable", "VAT Country/Region Code",
                        "Customer Posting Group", "Prices Including VAT", "Allow Line Disc.", "Customer No.",
                        "Currency Code", SystemModifiedAt);
                    Catalog.SetRange("Sync Prices", true);
                    if CompanyId <> '' then
                        Catalog.SetRange("Company SystemId", CompanyId);
                    if CatalogType <> CatalogType::" " then
                        Catalog.SetRange("Catalog Type", CatalogType);
                end;

                trigger OnAfterGetRecord()
                begin
                    SyncCatalogPrices.SyncCatalog(Catalog);
                end;
            }

            trigger OnPreDataItem()
            begin
                if not Shop.HasFilter() then
                    Error(NoShopSelectedErr);
            end;

            trigger OnAfterGetRecord()
            begin
                SyncCatalogPrices.SetCatalogType(CatalogType);
                SyncCatalogPrices.SetShop(Shop);
            end;
        }
    }
    requestpage
    {
        layout
        {
            area(Content)
            {
                field(ShopifyCompanyId; CompanyId)
                {
                    Caption = 'Company Id';
                    Tooltip = 'Specifies the company id to sync prices for. If empty, all companies will be synced.';
                    ApplicationArea = All;
                    Visible = false;
                }
                field(ShopifyCatalogType; CatalogType)
                {
                    Caption = 'Catalog Type';
                    Tooltip = 'Specifies the catalog type to sync prices for.';
                    ApplicationArea = All;
                    Visible = false;
                }
            }
        }
    }

    var
        SyncCatalogPrices: Codeunit "Shpfy Sync Catalog Prices";
        CompanyId: Text;
        NoShopSelectedErr: Label 'You must select a shop to sync prices for.';
        CatalogType: Enum "Shpfy Catalog Type";

    internal procedure SetCatalogType(ShpfyCatalogType: Enum "Shpfy Catalog Type")
    begin
        CatalogType := ShpfyCatalogType;
        SyncCatalogPrices.SetCatalogType(ShpfyCatalogType);
    end;
}