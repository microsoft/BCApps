// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

permissionset 20503 "Subcontract. - Edit"
{
    Caption = 'Subcontracting - Edit';
    Access = Public;
    Assignable = true;

    IncludedPermissionSets = "Subcontract. - Read";

    Permissions =
        tabledata "Subc. Standard Task Comment" = IMD,
        tabledata "Subc. Routing Comment Line" = IMD,
        tabledata "Subc. Prod. Rtng. Comment" = IMD,
        tabledata "Subcontractor Price" = IMD,
        tabledata "Subcontractor WIP Ledger Entry" = IMD;
}
