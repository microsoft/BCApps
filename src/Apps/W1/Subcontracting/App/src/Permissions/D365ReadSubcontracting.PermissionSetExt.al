// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using System.Security.AccessControl;

permissionsetextension 99001500 "D365 READ - Subcontracting" extends "D365 READ"
{
    IncludedPermissionSets = "Subcontract. - Read";
}