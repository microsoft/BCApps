// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

enum 50170 "BC14 Master Migrator" implements "IMasterMigrator"
{
    Extensible = true;
    DefaultImplementation = "IMasterMigrator" = "BC14 GL Account Migrator";

    value(0; "G/L Account")
    {
        Caption = 'G/L Account';
        Implementation = "IMasterMigrator" = "BC14 GL Account Migrator";
    }
    value(1; "Customer")
    {
        Caption = 'Customer';
        Implementation = "IMasterMigrator" = "BC14 Customer Migrator";
    }
    value(2; "Vendor")
    {
        Caption = 'Vendor';
        Implementation = "IMasterMigrator" = "BC14 Vendor Migrator";
    }
    value(3; "Item")
    {
        Caption = 'Item';
        Implementation = "IMasterMigrator" = "BC14 Item Migrator";
    }
}
