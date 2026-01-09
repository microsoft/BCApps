// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

permissionset 99001502 "Prod. Subcon. - Read"
{
    Caption = 'Prouction Subcontracting - Read';
    Access = Public;
    Assignable = true;

    IncludedPermissionSets = "Prod. Subcon. - Objs";

    Permissions =
        tabledata "Sub. Management Setup" = R,
        tabledata "Subcontractor Price" = R;
}