// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

enum 30208 "Shpfy Sync Coverage"
{
    Access = Internal;
    Extensible = false;

    value(0; Undefined) { Caption = ' '; }
    value(1; "All Shops") { Caption = 'All Shops'; }
    value(2; "Current Shop") { Caption = 'Current Shop'; }
    value(3; "Multiple Shops") { Caption = 'Multiple Shops'; }
    value(4; "Other Shops") { Caption = 'Other Shops'; }
}
