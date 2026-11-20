// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

enum 30207 "Shpfy Sync Workload"
{
    Access = Internal;
    Extensible = false;

    value(0; Undefined) { Caption = ' '; }
    value(1; Products) { Caption = 'Products'; }
    value(2; Prices) { Caption = 'Prices'; }
    value(3; Inventory) { Caption = 'Inventory'; }
    value(4; Orders) { Caption = 'Orders'; }
    value(5; Shipments) { Caption = 'Shipments'; }
    value(6; Customers) { Caption = 'Customers'; }
    value(7; Companies) { Caption = 'Companies'; }
    value(8; "Product Images") { Caption = 'Product Images'; }
    value(9; "Posted Invoices") { Caption = 'Posted Invoices'; }
    value(10; "Catalog Prices") { Caption = 'Catalog Prices'; }
}
