// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GST;

using System.Security.AccessControl;

permissionsetextension 18355 "D365 READ - India GST" extends "D365 READ"
{
#pragma warning disable AA0052, PTE0018 // Accepted: The existing cross-application inclusion must remain to preserve the current permission composition.
    IncludedPermissionSets = "D365 Read Access - India GST";
#pragma warning restore AA0052, PTE0018
}
