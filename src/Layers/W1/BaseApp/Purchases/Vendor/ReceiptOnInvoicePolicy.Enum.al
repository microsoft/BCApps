// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

enum 5820 "Receipt on Invoice Policy"
{
    Extensible = true;

    value(0; Manual) { Caption = 'Manual'; }
    value(1; Enabled) { Caption = 'Enabled'; }
}
