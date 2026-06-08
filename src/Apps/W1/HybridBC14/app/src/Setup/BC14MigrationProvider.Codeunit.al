// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.DataMigration;
using Microsoft.Utilities;

codeunit 46850 "BC14 Migration Provider" implements "Custom Migration Provider", "Custom Migration Table Mapping"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure GetDisplayName(): Text[250]
    begin
        exit(DisplayNameLbl);
    end;

    procedure GetDescription(): Text
    begin
        exit(DescriptionLbl);
    end;

    procedure GetAppId(): Guid
    begin
        exit(AppIdLbl);
    end;

    /// <summary>
    /// Sets up the replication table mappings for all per-company tables we replicate:
    /// Setup/Configuration, Master Data, Transaction, and Historical.
    /// Called by the platform from Hybrid Cloud Management.FinishCloudMigrationSetup, after
    /// EnableReplication has wired up the ADF pipelines and the SaaS production companies
    /// have been created -- which is the earliest point per-company data has somewhere to
    /// land.
    /// </summary>
    procedure SetupReplicationTableMappings()
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.SetupReplicationTableMappings();
    end;

    /// <summary>
    /// No-op: BC14 reimplementation has no per-database setup tables to replicate during the
    /// platform's setup phase. The setup-phase pipeline runs before SaaS production companies
    /// are created, so per-company setup up tables cannot use this channel -- they are registered in 
    /// SetupReplicationTableMappings instead.
    /// </summary>
    procedure SetupMigrationSetupTableMappings()
    begin
    end;

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
