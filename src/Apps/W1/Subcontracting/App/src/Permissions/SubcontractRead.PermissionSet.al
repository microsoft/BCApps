// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

#pragma warning disable AS0072, AS0136
permissionset 20502 "Subcontract. - Read"
{
    Caption = 'Subcontracting - Read';
    Access = Public;
    Assignable = true;

    IncludedPermissionSets = "Subcontract. - Objs";

    Permissions =
        tabledata "Subcontractor Price" = R,
        tabledata "Subcontractor WIP Ledger Entry" = R;
}
#pragma warning restore AS0072, AS0136
