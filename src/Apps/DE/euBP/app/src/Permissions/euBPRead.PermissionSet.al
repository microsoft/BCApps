// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.euBP;

permissionset 6547 "euBP - Read"
{
    Caption = 'euBP - Read', MaxLength = 30;
    Access = Public;
    Assignable = true;

    IncludedPermissionSets = "euBP - Objects";

    Permissions = tabledata "euBP Setup" = R;
}
