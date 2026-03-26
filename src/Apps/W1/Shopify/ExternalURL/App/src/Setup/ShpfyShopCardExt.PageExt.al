// ------------------------------------------------------------------------------------------------
// This file is licensed under the MIT License.
// See the LICENSE file in the project root for more information.
// ------------------------------------------------------------------------------------------------

namespace OpenSource.Shopify.ExternalURL;

using Microsoft.Integration.Shopify;

pageextension 50100 "Shpfy Shop Card Ext." extends "Shpfy Shop Card"
{
    layout
    {
        addafter("Product Metafields To Shopify")
        {
            field("Product URL Template"; Rec."Product URL Template")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies a URL template for the external product page URL synced to Shopify as the external_url variant metafield. Use placeholders: {item-no}, {variant-code}, {sku}, {barcode}, {shopify-product-id}, {shopify-variant-id}. Example: https://mywebshop.com/products/{item-no}';
            }
        }
    }
}
