// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

enum 50180 "BC14 Transaction Migrator" implements "ITransactionMigrator"
{
    Extensible = true;
    DefaultImplementation = "ITransactionMigrator" = "BC14 G/L Entry Migrator";

    value(0; "G/L Entries")
    {
        Caption = 'G/L Entries';
        Implementation = "ITransactionMigrator" = "BC14 G/L Entry Migrator";
    }
}
