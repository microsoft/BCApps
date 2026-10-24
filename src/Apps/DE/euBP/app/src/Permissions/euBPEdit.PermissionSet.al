// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.euBP;

permissionset 6548 "euBP - Edit"
{
    Caption = 'euBP - Edit', MaxLength = 30;
    Access = Public;
    Assignable = true;

    IncludedPermissionSets = "euBP - Read";

    Permissions = tabledata "euBP Setup" = IMD;
}
