// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

/// <summary>
/// Viewer permission set for BC14 Cloud Migration.
/// This permission set provides read-only access to monitor migration status and errors.
/// Safe to assign to users who need to view migration progress without making changes.
/// </summary>
permissionset 50151 "BC14MigrationViewer"
{
    Assignable = true;
    Caption = 'BC14 Cloud Migration - Viewer';

    Permissions =
        // Configuration tables - Read-only for monitoring
        tabledata "BC14CompanyMigrationSettings" = R,
        tabledata "BC14 Migration Error Overview" = R,
        tabledata "BC14 Migration Errors" = R,
        tabledata "BC14 Migration Record Status" = R,
        tabledata "BC14 Global Migration Settings" = R,
        // Master Data Buffer tables - Read-only for verification
        tabledata "BC14 Customer" = R,
        tabledata "BC14 Vendor" = R,
        tabledata "BC14 Item" = R,
        tabledata "BC14 G/L Account" = R,
        tabledata "BC14 G/L Entry" = R,
        // Setup Buffer tables - Read-only for verification
        tabledata "BC14 Dimension" = R,
        tabledata "BC14 Dimension Value" = R,
        tabledata "BC14 Payment Terms" = R,
        tabledata "BC14 Payment Method" = R,
        tabledata "BC14 Currency" = R,
        tabledata "BC14 Currency Exchange Rate" = R,
        tabledata "BC14 Accounting Period" = R,
        // Historical Buffer tables - Read-only for verification
        tabledata "BC14 Posted Sales Inv Header" = R,
        tabledata "BC14 Posted Sales Inv Line" = R,
        // Historical Archive tables - Read-only for verification
        tabledata "BC14 Arch. Sales Inv. Header" = R,
        tabledata "BC14 Arch. Sales Inv. Line" = R;
}
