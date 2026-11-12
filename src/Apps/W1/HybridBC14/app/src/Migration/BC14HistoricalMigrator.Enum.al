// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

/// <summary>
/// Historical phase migrators (posted documents brought across read-only for reference).
/// Each value implements the shared "BC14 Migrator" interface. Execution order within the phase
/// is determined by the order in which migrators are added to the phase list (see
/// PopulateHistoricalMigrators in codeunit "BC14 Migration Runner"), not by the enum value.
/// </summary>
enum 46889 "BC14 Historical Migrator" implements "BC14 Migrator"
{
    Extensible = true;

    value(0; "Posted Sales Invoice")
    {
        Caption = 'Posted Sales Invoice';
        Implementation = "BC14 Migrator" = "BC14 Posted Sales Inv Migr.";
    }
    value(1; "Old G/L Entry")
    {
        Caption = 'Old G/L Entry';
        Implementation = "BC14 Migrator" = "BC14 Old G/L Entry Migr.";
    }
    value(2; "Old Customer Ledger Entry")
    {
        Caption = 'Old Customer Ledger Entry';
        Implementation = "BC14 Migrator" = "BC14 Old Cust. Ledger Migr.";
    }
    value(3; "Old Vendor Ledger Entry")
    {
        Caption = 'Old Vendor Ledger Entry';
        Implementation = "BC14 Migrator" = "BC14 Old Vend. Ledger Migr.";
    }
    value(4; "Old Item Ledger Entry")
    {
        Caption = 'Old Item Ledger Entry';
        Implementation = "BC14 Migrator" = "BC14 Old Item Ledger Migr.";
    }
}
