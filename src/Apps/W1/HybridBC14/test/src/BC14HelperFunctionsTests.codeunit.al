// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using System.Integration;

codeunit 148149 "BC14 Helper Functions Tests"
{
    // [FEATURE] [BC14 Cloud Migration Helper Functions]

    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure TestSetProcessesRunning()
    var
        BC14UpgradeSettings: Record "BC14 Upgrade Settings";
        BC14HelperFunctions: Codeunit "BC14 Helper Functions";
    begin
        // [SCENARIO] SetProcessesRunning correctly updates the Migration In Progress flag.

        // [GIVEN] Upgrade settings are initialized
        if BC14UpgradeSettings.Get() then
            BC14UpgradeSettings.Delete();
        BC14UpgradeSettings.GetOrInsertBC14UpgradeSettings(BC14UpgradeSettings);

        // [WHEN] SetProcessesRunning is called with true
        BC14HelperFunctions.SetProcessesRunning(true);

        // [THEN] Migration In Progress should be true
        Clear(BC14UpgradeSettings);
        BC14UpgradeSettings.Get();
        Assert.AreEqual(true, BC14UpgradeSettings."Migration In Progress", 'Migration In Progress - Should be true');

        // [WHEN] SetProcessesRunning is called with false
        BC14HelperFunctions.SetProcessesRunning(false);

        // [THEN] Migration In Progress should be false
        Clear(BC14UpgradeSettings);
        BC14UpgradeSettings.Get();
        Assert.AreEqual(false, BC14UpgradeSettings."Migration In Progress", 'Migration In Progress - Should be false');
    end;

    [Test]
    procedure TestRunPreMigrationCleanup()
    var
        DataMigrationStatus: Record "Data Migration Status";
        DataMigrationEntity: Record "Data Migration Entity";
        BC14HelperFunctions: Codeunit "BC14 Helper Functions";
    begin
        // [SCENARIO] RunPreMigrationCleanup removes previous migration data.

        // [GIVEN] Some previous migration status and entity records exist
        DataMigrationStatus.Init();
        DataMigrationStatus."Migration Type" := BC14HelperFunctions.GetMigrationTypeTok();
        DataMigrationStatus."Destination Table ID" := Database::"G/L Account";
        DataMigrationStatus.Insert();

        DataMigrationEntity.Init();
        DataMigrationEntity."Table ID" := Database::"G/L Account";
        DataMigrationEntity.Insert();

        // [WHEN] RunPreMigrationCleanup is called
        BC14HelperFunctions.RunPreMigrationCleanup();

        // [THEN] The records are deleted
        DataMigrationStatus.SetRange("Migration Type", BC14HelperFunctions.GetMigrationTypeTok());
        Assert.IsTrue(DataMigrationStatus.IsEmpty(), 'Data Migration Status records should be deleted');
        Assert.IsTrue(DataMigrationEntity.IsEmpty(), 'Data Migration Entity records should be deleted');
    end;

    [Test]
    procedure TestGetGeneralJournalTemplateName()
    var
        BC14HelperFunctions: Codeunit "BC14 Helper Functions";
        TemplateName: Code[10];
    begin
        // [SCENARIO] GetGeneralJournalTemplateName returns a valid template name.

        // [WHEN] GetGeneralJournalTemplateName is called
        TemplateName := BC14HelperFunctions.GetGeneralJournalTemplateName();

        // [THEN] A non-empty template name is returned
        Assert.AreNotEqual('', TemplateName, 'General Journal Template Name should not be empty');
    end;

    [Test]
    procedure TestEnsureGenJournalBatchExists()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        BC14HelperFunctions: Codeunit "BC14 Helper Functions";
        TemplateName: Code[10];
        BatchName: Code[10];
    begin
        // [SCENARIO] EnsureGenJournalBatchExists creates a batch if it doesn't exist.

        // [GIVEN] A template name
        TemplateName := BC14HelperFunctions.GetGeneralJournalTemplateName();
        BatchName := 'BC14TEST';

        // Remove batch if it exists
        if GenJournalBatch.Get(TemplateName, BatchName) then
            GenJournalBatch.Delete();

        // [WHEN] EnsureGenJournalBatchExists is called
        BC14HelperFunctions.EnsureGenJournalBatchExists(BatchName, 'Test Migration Batch');

        // [THEN] The batch exists with the correct values
        Assert.IsTrue(GenJournalBatch.Get(TemplateName, BatchName), 'Journal batch should exist after calling EnsureGenJournalBatchExists');
        Assert.AreEqual('Test Migration Batch', GenJournalBatch.Description, 'Batch description should match');
    end;

    [Test]
    procedure TestEnsureGenJournalBatchExistsIsIdempotent()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        BC14HelperFunctions: Codeunit "BC14 Helper Functions";
        TemplateName: Code[10];
        BatchName: Code[10];
    begin
        // [SCENARIO] Calling EnsureGenJournalBatchExists multiple times does not fail.

        // [GIVEN] A batch that already exists
        TemplateName := BC14HelperFunctions.GetGeneralJournalTemplateName();
        BatchName := 'BC14TEST';

        BC14HelperFunctions.EnsureGenJournalBatchExists(BatchName, 'Test Migration Batch');

        // [WHEN] EnsureGenJournalBatchExists is called again
        BC14HelperFunctions.EnsureGenJournalBatchExists(BatchName, 'Test Migration Batch');

        // [THEN] No error occurs and the batch still exists
        Assert.IsTrue(GenJournalBatch.Get(TemplateName, BatchName), 'Journal batch should still exist');
    end;
}
