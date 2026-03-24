// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Permissions;

using System.Security.AccessControl;

#pragma warning disable AS0090
permissionsetextension 20400 "D365 BASIC ISV - QltyMgmt" extends "D365 BASIC ISV"
{
    IncludedPermissionSets = "QltyMgmt - Admin";
}
#pragma warning restore AS0090