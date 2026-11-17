// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExciseTaxes;

permissionset 7452 "ExciseTaxes - Edit"
{
    Caption = 'Excise Taxes - Edit';
    Access = Public;
    Assignable = true;

    IncludedPermissionSets = "ExciseTaxes - Read";

    Permissions =
        tabledata "Excise Tax Type" = IMD,
#if not CLEAN30
        tabledata "Excise Tax Item/FA Rate" = IMD,
#endif
        tabledata "Excise Tax Rate" = IMD,
        tabledata "Item Excise Tax" = IMD,
        tabledata "Excise Tax Entry Permission" = IMD;
}