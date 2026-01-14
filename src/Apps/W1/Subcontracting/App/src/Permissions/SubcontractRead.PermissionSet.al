// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

permissionset 99001502 "Subcontract. - Read"
{
    Caption = 'Subcontracting - Read';
    Access = Public;
    Assignable = true;

    IncludedPermissionSets = "Subcontract. - Objs";

    Permissions =
        tabledata "Subc. Management Setup" = R,
        tabledata "Subcontractor Price" = R;
}