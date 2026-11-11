#if INTERCOMPANY_IT
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany;

using System.Security.AccessControl;

permissionsetextension 8561 "IC IT D365 BASIC" extends "D365 BASIC"
{
    IncludedPermissionSets = "IC IT - Objects";
}
#endif
