// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.BatchProcessing;

permissionset 1381 "Batch Processing - Read"
{
    Access = Internal;
    Assignable = false;

    Permissions = tabledata "Batch Processing Artifact" = r,
                  tabledata "Batch Processing Parameter" = r,
                  tabledata "Batch Processing Session Map" = r;
}