// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExternalStorage.DocumentAttachments;

/// <summary>
/// Permission set for External Storage functionality.
/// Grants necessary permissions to use external storage features.
/// </summary>
permissionset 8751 "DA Ext. Stor. Admin"
{
    Assignable = true;
    Caption = 'DA - External Storage Admin';
    Permissions = tabledata "DA External Storage Setup" = rimd;
}