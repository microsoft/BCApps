// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using Microsoft.Finance.SalesTax;

/// <summary>
/// Permission set for the Shopify Tax Matching Agent.
/// Includes Shopify edit permissions plus access to Tax Area and Tax Jurisdiction tables.
/// </summary>
permissionset 30470 "Shpfy Tax Agent"
{
    Caption = 'Shopify Tax Agent';
    Assignable = true;

    IncludedPermissionSets = "Shpfy - Edit";

    Permissions =
        table "Shpfy Tax Agent Setup" = X,
        tabledata "Shpfy Tax Agent Setup" = RIMD,
        tabledata "Tax Area" = RIMD,
        tabledata "Tax Area Line" = RIMD,
        tabledata "Tax Detail" = RIMD,
        tabledata "Tax Jurisdiction" = RIMD,
        codeunit "Shpfy Tax Agent" = X,
        codeunit "Shpfy Tax Agent Task Exec." = X,
        codeunit "Shpfy Tax Agent Events" = X,
        page "Shpfy Tax Agent Setup" = X;
}
