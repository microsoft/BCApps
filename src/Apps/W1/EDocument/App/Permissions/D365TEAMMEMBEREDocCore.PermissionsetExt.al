// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using System.Security.AccessControl;

#pragma warning disable AA0052, AS0112, PTE0018
permissionsetextension 6101 "D365 TEAM MEMBER - E-Doc. Core" extends "D365 TEAM MEMBER"
{
    IncludedPermissionSets = "E-Doc. Core - User";
}
#pragma warning restore AA0052, AS0112, PTE0018