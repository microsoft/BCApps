// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.WithholdingTax;

using Microsoft.WithholdingTax.Employee;

permissionset 6785 "WHT - Read"
{
    Caption = 'Withholding Tax - Read';
    Access = Public;
    Assignable = true;

    IncludedPermissionSets = "WHT - Objects";

    Permissions =
        tabledata "Temp Withholding Tax Entry" = R,
        tabledata "Wthldg. Tax Bus. Post. Group" = R,
        tabledata "Withholding Tax Cert. Buffer" = R,
        tabledata "Withholding Tax Entry" = R,
        tabledata "Withholding Tax Posting Buffer" = R,
        tabledata "Withholding Tax Posting Setup" = R,
        tabledata "Wthldg. Tax Prod. Post. Group" = R,
        tabledata "Withholding Tax Revenue Types" = R,
        tabledata "Withholding Tax Group" = R,
        tabledata "Withholding Tax Group Line" = R,
        tabledata "WHT Threshold Accumulator" = R;
}