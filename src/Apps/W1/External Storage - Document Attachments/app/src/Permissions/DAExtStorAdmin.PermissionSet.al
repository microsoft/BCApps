// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExternalStorage.DocumentAttachments;

using System.Utilities;

/// <summary>
/// Permission set for External Storage functionality.
/// Grants necessary permissions to use external storage features.
/// </summary>
permissionset 8751 "DA Ext. Stor. Admin"
{
    Assignable = true;
    Caption = 'DA - External Storage Admin';
    Permissions = tabledata "DA External Storage Setup" = rimd,
                  tabledata "DA Internal Cleanup Entry" = r,
                  tabledata "Error Message" = ri,
                  tabledata "Error Message Register" = ri,
                  table "DA External Storage Setup" = X,
                  report "DA External Storage Migration" = X,
                  report "DA External Storage Sync" = X,
                  codeunit "DA Ext. Storage Sync Worker" = X,
                  codeunit "DA Feature Telemetry" = X,
                  codeunit "DA Internal Cleanup Mgt." = X,
                  page "DA Internal Cleanup Entries" = X,
                  page "Document Attachment - External" = X;
}
