// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;

using System.Security.AccessControl;

/// <summary>
/// Extends the D365 BASIC permission set to include Avalara E-Document connector edit permissions.
/// </summary>
permissionsetextension 6374 "Avl. EDoc. Connector - Edit" extends "D365 BASIC"
{
    IncludedPermissionSets = "Avalara Edit";
}