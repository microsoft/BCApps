// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

enum 30211 "Shpfy Sync Setup Target"
{
    Access = Internal;
    Extensible = false;

    value(0; None) { Caption = ' '; }
    value(1; "Shop Card") { Caption = 'Shop Card'; }
    value(2; "Shop Locations") { Caption = 'Shopify Shop Locations'; }
    value(3; "Payment Terms Mapping") { Caption = 'Payment Terms Mapping'; }
}
