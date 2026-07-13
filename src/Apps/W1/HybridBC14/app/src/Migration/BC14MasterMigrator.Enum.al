// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

/// <summary>
/// Master Data phase migrators (G/L Account, Customer, Vendor, Item, and their satellite tables).
/// Each value implements the shared "BC14 Migrator" interface. Execution order within the phase
/// is determined by the order in which migrators are added to the phase list (see
/// PopulateMasterMigrators in codeunit "BC14 Migration Runner"), not by the enum value.
/// </summary>
enum 46887 "BC14 Master Migrator" implements "BC14 Migrator"
{
    Extensible = true;

    value(0; "G/L Account")
    {
        Caption = 'G/L Account';
        Implementation = "BC14 Migrator" = "BC14 GL Account Migrator";
    }
    value(1; "Customer")
    {
        Caption = 'Customer';
        Implementation = "BC14 Migrator" = "BC14 Customer Migrator";
    }
    value(2; "Vendor")
    {
        Caption = 'Vendor';
        Implementation = "BC14 Migrator" = "BC14 Vendor Migrator";
    }
    value(3; "Item")
    {
        Caption = 'Item';
        Implementation = "BC14 Migrator" = "BC14 Item Migrator";
    }
    value(4; "Customer Bank Account")
    {
        Caption = 'Customer Bank Account';
        Implementation = "BC14 Migrator" = "BC14 Cust. Bank Acct. Migrator";
    }
    value(5; "Vendor Bank Account")
    {
        Caption = 'Vendor Bank Account';
        Implementation = "BC14 Migrator" = "BC14 Vend. Bank Acct. Migrator";
    }
    value(6; "Ship-to Address")
    {
        Caption = 'Ship-to Address';
        Implementation = "BC14 Migrator" = "BC14 Ship-to Address Migrator";
    }
    value(7; "BOM Component")
    {
        Caption = 'BOM Component';
        Implementation = "BC14 Migrator" = "BC14 BOM Component Migrator";
    }
    value(8; "Resource")
    {
        Caption = 'Resource';
        Implementation = "BC14 Migrator" = "BC14 Resource Migrator";
    }
}
