#if INTERCOMPANY_NA
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany;

using System.Security.AccessControl;

permissionsetextension 8560 "IC NA Intercompany Edit" extends "Intercompany - Edit"
{
    IncludedPermissionSets = "IC NA - Objects";
}
#endif
