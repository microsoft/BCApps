// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using System.Security.AccessControl;

permissionsetextension 99001501 "D365 BUS FULL ACCESS - Prod. Subcon." extends "D365 BUS FULL ACCESS"
{
    IncludedPermissionSets = "Prod. Subcon. - Edit";
}