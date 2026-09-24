// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExciseTaxes;

permissionset 7451 "ExciseTaxes - Read"
{
    Caption = 'Excise Taxes - Read';
    Access = Public;
    Assignable = true;

    IncludedPermissionSets = "ExciseTaxes - Objects";

    Permissions =
        tabledata "Excise Tax Type" = R,
#if not CLEAN30
        tabledata "Excise Tax Item/FA Rate" = R,
#endif
        tabledata "Excise Tax Rate" = R,
        tabledata "Item Excise Tax" = R,
        tabledata "Excise Tax Entry Permission" = R;
}