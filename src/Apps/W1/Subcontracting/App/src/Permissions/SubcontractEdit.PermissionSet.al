// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

#pragma warning disable AS0072, AS0136
permissionset 20503 "Subcontract. - Edit"
{
    Caption = 'Subcontracting - Edit';
    Access = Public;
    Assignable = true;

    IncludedPermissionSets = "Subcontract. - Read";

    Permissions =
        tabledata "Subcontractor Price" = IMD,
        tabledata "Subcontractor WIP Ledger Entry" = IMD;
}
#pragma warning restore AS0072, AS0136
