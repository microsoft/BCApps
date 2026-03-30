// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

/// <summary>
/// Controls the verbosity of Shopify connector activity logging.
/// </summary>
enum 30141 "Shpfy Logging Mode"
{
    Extensible = false;

    value(0; "Error Only")
    {
        Caption = 'Error Only';
    }
    value(1; All)
    {
        Caption = 'All';
    }
    value(2; Disabled)
    {
        Caption = 'Disabled';
    }
}