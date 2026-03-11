// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

permissionset 99001503 "Subcontract. - Edit"
{
    Caption = 'Subcontracting - Edit';
    Access = Public;
    Assignable = true;

    IncludedPermissionSets = "Subcontract. - Read";

    Permissions =
        tabledata "Subc. Management Setup" = IMD,
        tabledata "Subcontractor Price" = IMD;
}