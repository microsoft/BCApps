// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

/// <summary>
/// Admin permission set for BC14 Cloud Migration.
/// This permission set should only be assigned to administrators who need full control
/// over the migration process, including modifying configuration and deleting error logs.
/// </summary>
permissionset 50150 "BC14 Migration Admin"
{
    Assignable = false;
    Caption = 'BC14 Cloud Migration - Admin';

    Permissions =
        // Configuration tables - Full access for admin
        tabledata "BC14CompanyMigrationSettings" = RIMD,
        tabledata "BC14 Migration Error Overview" = RIMD,
        tabledata "BC14 Migration Errors" = RIMD,
        tabledata "BC14 Migration Record Status" = RIMD,
        tabledata "BC14 Global Migration Settings" = RIMD,
        // Master Data Buffer tables - Full access for migration operations
        tabledata "BC14 Customer" = RIMD,
        tabledata "BC14 Vendor" = RIMD,
        tabledata "BC14 Item" = RIMD,
        tabledata "BC14 G/L Account" = RIMD,
        tabledata "BC14 G/L Entry" = RIMD,
        // Setup Buffer tables - Full access for migration operations
        tabledata "BC14 Dimension" = RIMD,
        tabledata "BC14 Dimension Value" = RIMD,
        tabledata "BC14 Payment Terms" = RIMD,
        tabledata "BC14 Payment Method" = RIMD,
        tabledata "BC14 Currency" = RIMD,
        tabledata "BC14 Currency Exchange Rate" = RIMD,
        tabledata "BC14 Accounting Period" = RIMD,
        // Historical Buffer tables - Full access for migration operations
        tabledata "BC14 Posted Sales Inv Header" = RIMD,
        tabledata "BC14 Posted Sales Inv Line" = RIMD,
        // Historical Archive tables - Full access for migration operations
        tabledata "BC14 Arch. Sales Inv. Header" = RIMD,
        tabledata "BC14 Arch. Sales Inv. Line" = RIMD;
}
