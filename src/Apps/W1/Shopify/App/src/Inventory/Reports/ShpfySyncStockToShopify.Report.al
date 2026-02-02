// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

/// <summary>
/// Report Shpfy Sync Stock to Shopify (ID 30102).
/// </summary>
report 30102 "Shpfy Sync Stock to Shopify"
{
    ApplicationArea = All;
    Caption = 'Sync Stock To Shopify';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem(Shop; "Shpfy Shop")
        {
            RequestFilterFields = Code;

            trigger OnAfterGetRecord()
            var
                ShopifyShopInventory: Record "Shpfy Shop Inventory";
                ShpfySyncInventory: Codeunit "Shpfy Sync Inventory";
            begin
                ShopifyShopInventory.Reset();
                ShopifyShopInventory.SetRange("Shop Code", Shop.Code);

                if VariantIdFilter <> '' then
                    ShopifyShopInventory.SetFilter("Variant ID", VariantIdFilter);

                ShpfySyncInventory.SetSkipImport(SkipImport);
                ShpfySyncInventory.Run(ShopifyShopInventory);
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(content)
            {
                group(Group)
                {
                    Caption = 'Options';
                    field(SkipImport; SkipImport)
                    {
                        Caption = 'Skip Import Stock';
                        ToolTip = 'Specifies whether to skip importing stock from Shopify before exporting stock to Shopify.';
                    }
                    field(VariantIdFilter; VariantIdFilter)
                    {
                        Caption = 'Variant ID Filter';
                        ToolTip = 'Specifies a filter for the Variant ID to limit which inventory items are synchronized.';
                    }
                }
            }
        }
    }

    protected var
        VariantIdFilter: Text;
        SkipImport: Boolean;
}