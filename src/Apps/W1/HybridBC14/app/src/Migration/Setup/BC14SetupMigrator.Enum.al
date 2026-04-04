// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

enum 50181 "BC14 Setup Migrator" implements "ISetupMigrator"
{
    Extensible = true;
    DefaultImplementation = "ISetupMigrator" = "BC14 Null Setup Migrator";

    value(0; "Dimension")
    {
        Caption = 'Dimension';
        Implementation = "ISetupMigrator" = "BC14 Dimension Migrator";
    }
    value(1; "Dimension Value")
    {
        Caption = 'Dimension Value';
        Implementation = "ISetupMigrator" = "BC14 Dim. Value Migrator";
    }
    value(2; "Payment Terms")
    {
        Caption = 'Payment Terms';
        Implementation = "ISetupMigrator" = "BC14 Payment Terms Migrator";
    }
    value(3; "Payment Method")
    {
        Caption = 'Payment Method';
        Implementation = "ISetupMigrator" = "BC14 Payment Method Migrator";
    }
    value(4; "Currency")
    {
        Caption = 'Currency';
        Implementation = "ISetupMigrator" = "BC14 Currency Migrator";
    }
    value(5; "Currency Exchange Rate")
    {
        Caption = 'Currency Exchange Rate';
        Implementation = "ISetupMigrator" = "BC14 Curr. Exch. Rate Migrator";
    }
    value(6; "Accounting Period")
    {
        Caption = 'Accounting Period';
        Implementation = "ISetupMigrator" = "BC14 Acct. Period Migrator";
    }
}
