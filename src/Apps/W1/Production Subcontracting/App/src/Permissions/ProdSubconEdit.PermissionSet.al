// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

permissionset 99001503 "Prod. Subcon. - Edit"
{
    Caption = 'Production Subcontracting - Edit';
    Access = Public;
    Assignable = true;

    IncludedPermissionSets = "Prod. Subcon. - Read";

    Permissions =
        tabledata "Sub. Management Setup" = IMD,
        tabledata "Subcontractor Price" = IMD;
}