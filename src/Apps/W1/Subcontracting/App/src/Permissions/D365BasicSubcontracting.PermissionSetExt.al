// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using System.Security.AccessControl;

#pragma warning disable AS0072, AS0136
permissionsetextension 20502 "D365 BASIC - Subcontracting" extends "D365 BASIC"
{
    IncludedPermissionSets = "Subcontract. - Read";
}
#pragma warning restore AS0072, AS0136
