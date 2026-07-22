// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

/// <summary>
/// Transaction phase migrators (open ledger entries staged as new journal lines).
/// Each value implements the shared "BC14 Migrator" interface. Execution order within the phase
/// is determined by the order in which migrators are added to the phase list (see
/// PopulateTransactionMigrators in codeunit "BC14 Migration Runner"), not by the enum value.
/// </summary>
enum 46888 "BC14 Transaction Migrator" implements "BC14 Migrator"
{
    Extensible = true;

    value(0; "G/L Entries")
    {
        Caption = 'G/L Entries';
        Implementation = "BC14 Migrator" = "BC14 G/L Entry Migrator";
    }
    value(1; "Customer Ledger Entries")
    {
        Caption = 'Customer Ledger Entries';
        Implementation = "BC14 Migrator" = "BC14 Cust. Ledger Migrator";
    }
}
