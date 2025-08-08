// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

/// <summary>
/// Enum Shpfy Currency Handling (ID 30169).
/// </summary>
enum 30169 "Shpfy Currency Handling"
{
    Extensible = false;
    Caption = 'Shopify Currency Handling';

    value(0; "Shop Currency")
    {
        Caption = 'Shop Currency';
    }
    value(1; "Presentment Currency")
    {
        Caption = 'Presentment Currency';
    }
}
