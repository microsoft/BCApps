// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration;
using Microsoft.DataMigration.BC14Reimplementation;
using System.Integration;

codeunit 148905 "BC14 Helper Function Tests"
{
    /// <summary>
    /// Initializes the BC14 migration settings for the current company.
    /// Creates the BC14CompanyMigrationInfo and BC14 Global Migration Settings records.
    /// </summary>
    procedure CreateConfigurationSettings()
    var
        BC14CompanyMigrationInfo: Record "BC14CompanyMigrationInfo";
        BC14GlobalSettings: Record "BC14 Global Migration Settings";
        CompanyNameText: Text[30];
    begin
#pragma warning disable AA0139
        CompanyNameText := CompanyName();
#pragma warning restore AA0139

        if not BC14CompanyMigrationInfo.Get(CompanyNameText) then begin
            BC14CompanyMigrationInfo.Name := CompanyNameText;
            BC14CompanyMigrationInfo.Insert(true);
        end;

        BC14GlobalSettings.GetOrInsertGlobalSettings(BC14GlobalSettings);
    end;

    /// <summary>
    /// Deletes all settings records for BC14 migration.
    /// </summary>
    procedure DeleteAllSettings()
    var
        BC14CompanyMigrationInfo: Record "BC14CompanyMigrationInfo";
        BC14GlobalSettings: Record "BC14 Global Migration Settings";
    begin
        BC14CompanyMigrationInfo.DeleteAll();
        if BC14GlobalSettings.Get() then
            BC14GlobalSettings.Delete();
    end;

    /// <summary>
    /// Cleans up all migration-related data (errors, settings, buffer tables).
    /// </summary>
    procedure CleanupMigrationData()
    var
        DataMigrationError: Record "Data Migration Error";
        BC14CompanyMigrationInfo: Record "BC14CompanyMigrationInfo";
        BC14GlobalSettings: Record "BC14 Global Migration Settings";
    begin
        DataMigrationError.DeleteAll();
        BC14CompanyMigrationInfo.DeleteAll();
        if BC14GlobalSettings.Get() then
            BC14GlobalSettings.Delete();
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
    /// Creates a set of BC14CompanyMigrationInfo entries for testing.
    /// Company 1 = defaults, Company 2 = all modules enabled, Company 3 = defaults.
    /// </summary>
    procedure CreateSettingsTableEntries()
    var
        BC14CompanyMigrationInfo: Record "BC14CompanyMigrationInfo";
        CompanyNameText: Text[30];
    begin
        CompanyNameText := 'Company 1';
        BC14CompanyMigrationInfo.Init();
        BC14CompanyMigrationInfo.Name := CompanyNameText;
        BC14CompanyMigrationInfo.Insert();

        CompanyNameText := 'Company 2';
        BC14CompanyMigrationInfo.Init();
        BC14CompanyMigrationInfo.Name := CompanyNameText;
        BC14CompanyMigrationInfo.Insert();
        TurnOnAllSettings(BC14CompanyMigrationInfo);

        CompanyNameText := 'Company 3';
        BC14CompanyMigrationInfo.Init();
        BC14CompanyMigrationInfo.Name := CompanyNameText;
        BC14CompanyMigrationInfo.Insert();
    end;

    /// <summary>
    /// Turns on all module settings for the given BC14CompanyMigrationInfo record.
    /// </summary>
    procedure TurnOnAllSettings(var BC14CompanyMigrationInfo: Record "BC14CompanyMigrationInfo")
    begin
        BC14CompanyMigrationInfo.Validate("Migrate GL Module", true);
        BC14CompanyMigrationInfo.Validate("Migrate Receivables Module", true);
        BC14CompanyMigrationInfo.Validate("Migrate Payables Module", true);
        BC14CompanyMigrationInfo.Validate("Migrate Inventory Module", true);
        BC14CompanyMigrationInfo.Validate("Skip Posting Journal Batches", false);
        BC14CompanyMigrationInfo.Modify();
    end;
}
