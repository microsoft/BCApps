// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

using Microsoft.DataMigration;
using Microsoft.Utilities;

codeunit 50150 "BC14 Migration Provider" implements "Custom Migration Provider", "Custom Migration Table Mapping"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// Gets a display name for the migration type.
    /// </summary>
    procedure GetDisplayName(): Text[250]
    begin
        exit(DisplayNameLbl);
    end;

    /// <summary>
    /// Gets a description for the migration type.
    /// </summary>
    procedure GetDescription(): Text
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>
    /// Gets the AppId of the custom migration provider implementation.
    /// </summary>
    procedure GetAppId(): Guid
    begin
        exit(AppIdLbl);
    end;

    /// <summary>
    /// Sets up the replication table mappings for Master Data, Transaction, and Historical tables.
    /// </summary>
    procedure SetupReplicationTableMappings()
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.SetupReplicationTableMappings();
    end;

    /// <summary>
    /// Sets up the migration setup table mappings for Setup/Configuration tables.
    /// These foundational tables (Dimensions, Payment Terms, etc.) are migrated first.
    /// </summary>
    procedure SetupMigrationSetupTableMappings()
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.SetupMigrationSetupTableMappings();
    end;

    /// <summary>
    /// Returns the demo data type for the cloud migration.
    /// </summary>
    procedure GetDemoDataType(): Enum "Company Demo Data Type"
    begin
        exit(Enum::"Company Demo Data Type"::"Production - Setup Data Only");
    end;

    var
        DisplayNameLbl: Label 'Business Central 14 Re-implementation';
        DescriptionLbl: Label 'Moves the data from Business Central 14 on-premises to Business Central online. This is a re-implementation migration, a subset of the data will be migrated.';
        AppIdLbl: Label '2363a2b7-1018-4976-a32a-c77338dc9f16', Locked = true;

    procedure GetReplicationTableMappingName(): Text
    var
        CustomMigrationProvider: Codeunit "Custom Migration Provider";
    begin
        exit(CustomMigrationProvider.GetReplicationTableMappingName());
    end;

    procedure GetMigrationSetupTableMappingName(): Text
    var
        CustomMigrationProvider: Codeunit "Custom Migration Provider";
    begin
        exit(CustomMigrationProvider.GetMigrationSetupTableMappingName());
    end;

    procedure GetCompaniesTableName(): Text
    var
        CustomMigrationProvider: Codeunit "Custom Migration Provider";
    begin
        exit(CustomMigrationProvider.GetCompaniesTableName());
    end;

    procedure ShowConfigureMigrationTablesMappingStep(): Boolean
    begin
        exit(false);
    end;
}
