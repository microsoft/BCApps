// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

enum 30210 "Shpfy Sync Readiness"
{
    Access = Internal;
    Extensible = false;

    value(0; "Not scheduled") { Caption = 'Not scheduled'; }
    value(1; "Setup required") { Caption = 'Setup required'; }
}
