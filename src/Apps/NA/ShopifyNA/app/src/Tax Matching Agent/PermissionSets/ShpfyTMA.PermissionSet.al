// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using Microsoft.Finance.SalesTax;

permissionset 30470 "Shpfy TMA"
{
    Caption = 'Shopify Tax Matching Agent';
    Assignable = true;

    IncludedPermissionSets = "Shpfy - Edit";

    Permissions =
        tabledata "Tax Area" = rimd,
        tabledata "Tax Area Line" = rimd,
        tabledata "Tax Detail" = rimd,
        tabledata "Tax Jurisdiction" = rimd,
        page "Shpfy TMA Review" = X,
        page "Shpfy TMA Order Tax Lines Part" = X,
        codeunit "Shpfy TMA Register" = X,
        codeunit "Shpfy TMA Matcher" = X,
        codeunit "Shpfy Tax Area Builder" = X,
        codeunit "Shpfy TMA Events" = X,
        codeunit "Shpfy Tax Match Function" = X,
        codeunit "Shpfy TMA Install" = X,
        codeunit "Shpfy TMA Upgrade" = X,
        codeunit "Shpfy TMA Activity Log" = X,
        codeunit "Shpfy TMA Notify" = X;
}
