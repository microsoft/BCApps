// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using System.Threading;

/// <summary>
/// Shpfy - Rec. Sync Permissions (ID 30105).
/// </summary>
permissionset 30105 "Shpfy - Rec. Sync"
{
    Access = Internal;
    Assignable = false;
    Caption = 'Shopify - Recurring Sync', MaxLength = 30;

    Permissions =
        tabledata "Job Queue Category" = rim,
        tabledata "Job Queue Entry" = rim;
}
