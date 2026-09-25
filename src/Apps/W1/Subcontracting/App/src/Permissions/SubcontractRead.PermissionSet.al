// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

permissionset 20502 "Subcontract. - Read"
{
    Caption = 'Subcontracting - Read';
    Access = Public;
    Assignable = true;

    IncludedPermissionSets = "Subcontract. - Objs";

    Permissions =
        tabledata "Subc. Standard Task Comment" = R,
        tabledata "Subc. Routing Comment Line" = R,
        tabledata "Subc. Prod. Rtng. Comment" = R,
        tabledata "Subcontractor Price" = R,
        tabledata "Subcontractor WIP Ledger Entry" = R;
}
