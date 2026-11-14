// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

enum 30212 "Shpfy Sync Direction"
{
    Access = Internal;
    Extensible = false;

    value(0; Undefined) { Caption = ' '; }
    value(1; Products) { Caption = 'Products'; }
    value(2; "Products to Shopify") { Caption = 'Products to Shopify'; }
    value(3; "Products from Shopify") { Caption = 'Products from Shopify'; }
    value(4; "Prices to Shopify") { Caption = 'Prices to Shopify'; }
    value(5; "Inventory to Shopify") { Caption = 'Inventory to Shopify'; }
    value(6; "Orders from Shopify") { Caption = 'Orders from Shopify'; }
    value(7; "Shipments to Shopify") { Caption = 'Shipments to Shopify'; }
    value(8; Customers) { Caption = 'Customers'; }
    value(9; "Customers from Shopify") { Caption = 'Customers from Shopify'; }
    value(10; "Customers to Shopify") { Caption = 'Customers to Shopify'; }
    value(11; "Customers to/from Shopify") { Caption = 'Customers to/from Shopify'; }
    value(12; Companies) { Caption = 'Companies'; }
    value(13; "Companies from Shopify") { Caption = 'Companies from Shopify'; }
    value(14; "Companies to Shopify") { Caption = 'Companies to Shopify'; }
    value(15; "Companies to/from Shopify") { Caption = 'Companies to/from Shopify'; }
    value(16; "Product images") { Caption = 'Product images'; }
    value(17; "Product images to Shopify") { Caption = 'Product images to Shopify'; }
    value(18; "Product images from Shopify") { Caption = 'Product images from Shopify'; }
    value(19; "Posted invoices to Shopify") { Caption = 'Posted invoices to Shopify'; }
    value(20; "Catalog prices to Shopify") { Caption = 'Catalog prices to Shopify'; }
}
