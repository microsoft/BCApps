// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

/// <summary>
/// Enum Shpfy Incl. in Product Sync (ID 30179).
/// </summary>
enum 30179 "Shpfy Incl. in Product Sync"
{
    Caption = 'Include in Product Sync';
    Extensible = false;

    value(0; " ")
    {
        Caption = ' ', Locked = true;
    }
    value(1; "As Option")
    {
        Caption = 'As Option';
    }
}
