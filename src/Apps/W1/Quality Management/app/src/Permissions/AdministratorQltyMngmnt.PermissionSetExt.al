// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Permissions;

using System.Security.AccessControl;

permissionsetextension 20402 "Administrator - QltyMngmnt" extends "Administrator"
{
    IncludedPermissionSets = "QltyMngmnt - Edit";
}