// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

/// <summary>
/// Enum Shpfy Catalog Type (ID 30169).
/// </summary>
enum 30169 "Shpfy Catalog Type"
{
    Extensible = true;

    value(0; " ")
    {
        Caption = ' ', Locked = true;
    }
    value(1; "Company")
    {
        Caption = 'Company';
    }
    value(2; "Market")
    {
        Caption = 'Market';
    }
}
