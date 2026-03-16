// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration;
using Microsoft.DataMigration.BC14;
using System.Integration;

codeunit 148146 "BC14 Helper Function Tests"
{
    /// <summary>
    /// Initializes the BC14 migration settings for the current company.
    /// Creates the BC14CompanyAdditionalSettings and BC14 Upgrade Settings records.
    /// </summary>
    procedure CreateConfigurationSettings()
    var
        BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
        BC14UpgradeSettings: Record "BC14 Upgrade Settings";
        CompanyNameText: Text[30];
    begin
#pragma warning disable AA0139
        CompanyNameText := CompanyName();
#pragma warning restore AA0139

        if not BC14CompanyAdditionalSettings.Get(CompanyNameText) then begin
            BC14CompanyAdditionalSettings.Name := CompanyNameText;
            BC14CompanyAdditionalSettings.Insert(true);
        end;

        BC14UpgradeSettings.GetOrInsertBC14UpgradeSettings(BC14UpgradeSettings);
    end;

    /// <summary>
    /// Deletes all settings records for BC14 migration.
    /// </summary>
    procedure DeleteAllSettings()
    var
        BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
        BC14UpgradeSettings: Record "BC14 Upgrade Settings";
    begin
        BC14CompanyAdditionalSettings.DeleteAll();
        if BC14UpgradeSettings.Get() then
            BC14UpgradeSettings.Delete();
    end;

    /// <summary>
    /// Cleans up all migration-related data (errors, settings, buffer tables).
    /// </summary>
    procedure CleanupMigrationData()
    var
        BC14MigrationErrors: Record "BC14 Migration Errors";
        BC14MigrationErrorOverview: Record "BC14 Migration Error Overview";
        BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
        BC14UpgradeSettings: Record "BC14 Upgrade Settings";
    begin
        BC14MigrationErrors.DeleteAll();
        BC14MigrationErrorOverview.DeleteAll();
        BC14CompanyAdditionalSettings.DeleteAll();
        if BC14UpgradeSettings.Get() then
            BC14UpgradeSettings.Delete();
    end;

    /// <summary>
    /// Creates a standard set of setup records required by the migration E2E flow:
    /// HybridCompany, IntelligentCloud, IntelligentCloudSetup, and HybridReplicationSummary.
    /// </summary>
    procedure CreateStandardSetupRecords()
    var
        HybridCompany: Record "Hybrid Company";
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        IntelligentCloud: Record "Intelligent Cloud";
        IntelligentCloudSetup: Record "Intelligent Cloud Setup";
        BC14Wizard: Codeunit "BC14 Wizard";
    begin
        HybridCompany.Name := CopyStr(CompanyName(), 1, MaxStrLen(HybridCompany.Name));
        HybridCompany."Display Name" := HybridCompany.Name;
        HybridCompany.Replicate := true;
        if not HybridCompany.Insert() then
            HybridCompany.Modify();

        if IntelligentCloud.Get() then
            IntelligentCloud.Delete();

        IntelligentCloud.Enabled := true;
        IntelligentCloud.Insert();

        if IntelligentCloudSetup.Get() then
            IntelligentCloudSetup.Delete();

        IntelligentCloudSetup."Product ID" := BC14Wizard.GetMigrationProviderId();
        IntelligentCloudSetup."Company Creation Task Status" := IntelligentCloudSetup."Company Creation Task Status"::Completed;
        IntelligentCloudSetup."Replication Enabled" := true;
        IntelligentCloudSetup.Insert();

        HybridReplicationSummary."Run ID" := CreateGuid();
        HybridReplicationSummary."Start Time" := CurrentDateTime() - 10000;
        HybridReplicationSummary."End Time" := CurrentDateTime() - 5000;
        HybridReplicationSummary.ReplicationType := HybridReplicationSummary.ReplicationType::Normal;
        HybridReplicationSummary.Status := HybridReplicationSummary.Status::Completed;
        HybridReplicationSummary.Source := BC14Wizard.GetMigrationProviderId();
        HybridReplicationSummary."Trigger Type" := HybridReplicationSummary."Trigger Type"::Scheduled;
        HybridReplicationSummary.Insert();
    end;

    /// <summary>
    /// Creates a set of BC14CompanyAdditionalSettings entries for testing.
    /// Company 1 = defaults, Company 2 = all modules enabled, Company 3 = defaults.
    /// </summary>
    procedure CreateSettingsTableEntries()
    var
        BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
        CompanyNameText: Text[30];
    begin
        CompanyNameText := 'Company 1';
        BC14CompanyAdditionalSettings.Init();
        BC14CompanyAdditionalSettings.Name := CompanyNameText;
        BC14CompanyAdditionalSettings.Insert();

        CompanyNameText := 'Company 2';
        BC14CompanyAdditionalSettings.Init();
        BC14CompanyAdditionalSettings.Name := CompanyNameText;
        BC14CompanyAdditionalSettings.Insert();
        TurnOnAllSettings(BC14CompanyAdditionalSettings);

        CompanyNameText := 'Company 3';
        BC14CompanyAdditionalSettings.Init();
        BC14CompanyAdditionalSettings.Name := CompanyNameText;
        BC14CompanyAdditionalSettings.Insert();
    end;

    /// <summary>
    /// Turns on all module settings for the given BC14CompanyAdditionalSettings record.
    /// </summary>
    procedure TurnOnAllSettings(var BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings")
    begin
        BC14CompanyAdditionalSettings.Validate("Migrate GL Module", true);
        BC14CompanyAdditionalSettings.Validate("Migrate Receivables Module", true);
        BC14CompanyAdditionalSettings.Validate("Migrate Payables Module", true);
        BC14CompanyAdditionalSettings.Validate("Migrate Inventory Module", true);
        BC14CompanyAdditionalSettings.Validate("Skip Posting Journal Batches", false);
        BC14CompanyAdditionalSettings.Modify();
    end;
}
