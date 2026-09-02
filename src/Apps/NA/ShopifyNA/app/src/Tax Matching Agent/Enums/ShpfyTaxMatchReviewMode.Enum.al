// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

/// <summary>
/// Enum Shpfy Tax Match Review Mode (ID 30471).
/// Per-shop policy for when a Tax Matching Agent order is held for human review before a Sales
/// Document is created. A rate conflict or an incomplete match always holds the order regardless
/// of this mode (those are hard safety gates).
/// </summary>
enum 30471 "Shpfy Tax Match Review Mode"
{
    Extensible = false;
    Caption = 'Tax Match Review Mode';

    value(0; Always)
    {
        Caption = 'Always';
    }
    value(1; "Low Confidence Only")
    {
        Caption = 'Low Confidence Only';
    }
    value(2; Never)
    {
        Caption = 'Never';
    }
}
