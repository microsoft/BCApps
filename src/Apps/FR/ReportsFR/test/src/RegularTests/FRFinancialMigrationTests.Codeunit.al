#if not CLEAN30
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using System.Environment;
using System.Environment.Configuration;
using System.IO;
using System.TestLibraries.Upgrade;
using System.Upgrade;
using System.Utilities;

#pragma warning disable AL0432, AS0105
codeunit 148013 "FR Financial Migration Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Migration: Codeunit "Library - Reports FR";
        UpgradeTagLibrary: Codeunit "Upgrade Tag Library";
        UpgradeTag: Codeunit "Upgrade Tag";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        OtherCompanyTok: Label '653672 Migration Target', Locked = true;
        StoredFieldPreservationErr: Label 'Stored field %1 must survive migration.', Comment = '%1 = stored field number';
        FixtureCompanyTok: Label '653672 Migration Source', Locked = true;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StoredConfigurationAndIdentitySurvive()
    var
        LegacyName: Record "FR Acc. Schedule Name";
        LegacyLine: Record "FR Acc. Schedule Line";
        ScheduleName: Record "FR Financial Schedule Name";
        ScheduleLine: Record "FR Financial Schedule Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] Every stored schedule field and integration identity survives the first migration.
        Initialize();

        // [GIVEN] Customized legacy schedule S with line L.
        CreateLegacySchedule(LegacyName, LegacyLine);

        // [WHEN] The first-release migration runs.
        Migration.Migrate();

        // [THEN] Headers, lines and identities are preserved and the legacy source is retained.
        ScheduleName.Get(LegacyName.Name);
        ScheduleLine.Get(LegacyLine."Schedule Name", LegacyLine."Line No.");
        VerifyStoredFields(LegacyName, ScheduleName);
        VerifyStoredFields(LegacyLine, ScheduleLine);
        Assert.IsTrue(LegacyName.Get(LegacyName.Name), 'The legacy header must be retained.');
        Assert.IsTrue(LegacyLine.Get(LegacyLine."Schedule Name", LegacyLine."Line No."), 'The legacy line must be retained.');
        Assert.IsTrue(Migration.IsMigrated(), 'The company must be marked migrated.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmptyCompanyMigratesWithoutDefaults()
    var
        ScheduleName: Record "FR Financial Schedule Name";
        ScheduleLine: Record "FR Financial Schedule Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] Empty-company migration does not invent customer definitions.
        Initialize();

        // [GIVEN] No legacy schedules exist.
        // [WHEN] The first-release migration runs.
        Migration.Migrate();

        // [THEN] Both destination tables are empty and migration is complete.
        Assert.IsTrue(ScheduleName.IsEmpty(), 'Migration must not create a default header.');
        Assert.IsTrue(ScheduleLine.IsEmpty(), 'Migration must not create a default line.');
        Assert.IsTrue(Migration.IsMigrated(), 'Empty-company migration must complete.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RepeatedMigrationPreservesDestinationEdits()
    var
        LegacyName: Record "FR Acc. Schedule Name";
        LegacyLine: Record "FR Acc. Schedule Line";
        ScheduleName: Record "FR Financial Schedule Name";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] Retrying a completed migration never overwrites later destination edits.
        Initialize();

        // [GIVEN] S has migrated and its destination description has changed.
        CreateLegacySchedule(LegacyName, LegacyLine);
        Migration.Migrate();
        ScheduleName.Get(LegacyName.Name);
        ScheduleName.Description := 'Edited after migration';
        ScheduleName.Modify(false);

        // [WHEN] Migration is invoked again.
        Migration.Migrate();

        // [THEN] The edited destination remains authoritative.
        ScheduleName.Get(LegacyName.Name);
        Assert.AreEqual('Edited after migration', ScheduleName.Description, 'Migration must be idempotent.');
        Assert.AreEqual(1, ScheduleName.Count(), 'Retry must not duplicate the header.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DifferentDestinationIsRejected()
    var
        LegacyName: Record "FR Acc. Schedule Name";
        LegacyLine: Record "FR Acc. Schedule Line";
        ScheduleName: Record "FR Financial Schedule Name";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] A differing destination definition fails without declaring completion.
        Initialize();

        // [GIVEN] S exists in both stores with conflicting configuration.
        CreateLegacySchedule(LegacyName, LegacyLine);
        ScheduleName.TransferFields(LegacyName);
        ScheduleName.Description := 'Conflicting destination';
        ScheduleName.Insert(false);

        // [WHEN] Migration encounters the conflict.
        asserterror Migration.Migrate();

        // [THEN] The diagnostic is actionable and the tag is absent.
        Assert.ExpectedError('conflicting destination record');
        Assert.ExpectedErrorCode('Dialog');
        Assert.IsFalse(Migration.IsMigrated(), 'Conflicts must not set the completion tag.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OrphanLegacyLineIsRejected()
    var
        LegacyLine: Record "FR Acc. Schedule Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] Orphan legacy lines are reported rather than silently discarded.
        Initialize();

        // [GIVEN] L references a missing header.
        LegacyLine."Schedule Name" := 'ORPHAN';
        LegacyLine."Line No." := 10000;
        LegacyLine.Insert(false);

        // [WHEN] Migration validates the legacy configuration.
        asserterror Migration.Migrate();

        // [THEN] Migration reports the orphan and does not mark completion.
        Assert.ExpectedError('line without a schedule header');
        Assert.ExpectedErrorCode('Dialog');
        Assert.IsFalse(Migration.IsMigrated(), 'An orphan must block activation.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InterruptedMigrationDoesNotSetTag()
    var
        LegacyName: Record "FR Acc. Schedule Name";
        LegacyLine: Record "FR Acc. Schedule Line";
        FailureSubscriber: Codeunit "Library - Reports FR";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] Failure immediately before completion cannot leave a successful upgrade tag.
        Initialize();

        // [GIVEN] S is valid and an interruption will occur before completion.
        CreateLegacySchedule(LegacyName, LegacyLine);
        FailureSubscriber.SetInjectFailure();
        BindSubscription(FailureSubscriber);

        // [WHEN] Migration is interrupted after copying.
        asserterror Migration.Migrate();

        // [THEN] The interruption is visible and completion is not recorded.
        Assert.ExpectedError('Injected migration interruption');
        Assert.ExpectedErrorCode('Dialog');
        Assert.IsFalse(Migration.IsMigrated(), 'Interrupted migration must not set its tag.');
        UnbindSubscription(FailureSubscriber);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TemporaryLegacyRecordsRemainUsable()
    var
        TemporaryLegacyName: Record "FR Acc. Schedule Name" temporary;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] Migration does not block temporary compatibility buffers.
        Initialize();

        // [GIVEN] The company has completed migration.
        Migration.Migrate();

        // [WHEN] A temporary compatibility buffer is populated.
        TemporaryLegacyName.Name := 'TEMP';
        TemporaryLegacyName.Insert();

        // [THEN] No persistent legacy write was made.
        Assert.AreEqual(1, TemporaryLegacyName.Count(), 'Temporary records must remain supported.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UnmigratedSessionCannotWriteMigratedCompany()
    var
        LegacyName: Record "FR Acc. Schedule Name";
        OtherCompany: Text[30];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] ChangeCompany cannot bypass the migrated company's legacy write guard.
        Initialize();

        // [GIVEN] The session company is unmigrated and the dedicated second company is migrated.
        OtherCompany := PrepareOtherCompany();
        CreateOtherCompanyHeader(LegacyName, OtherCompany);
        Migration.Migrate();
        UpgradeTag.CopyUpgradeTags(CopyStr(CompanyName(), 1, 30), OtherCompany);
        UpgradeTagLibrary.DeleteUpgradeTag(Migration.GetUpgradeTag(), CopyStr(CompanyName(), 1, 30));
        LegacyName.Description := 'Forbidden cross-company edit';

        // [WHEN] A compatibility consumer writes with ChangeCompany.
        asserterror LegacyName.Modify(false);

        // [THEN] The guard uses the record's company rather than the session company.
        Assert.ExpectedError('legacy schedule tables are read-only');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MigratedSessionCanWriteUnmigratedCompany()
    var
        LegacyName: Record "FR Acc. Schedule Name";
        OtherCompany: Text[30];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] A migrated session does not incorrectly block an unmigrated target company.
        Initialize();

        // [GIVEN] The session company is migrated but the dedicated second company is not.
        OtherCompany := PrepareOtherCompany();
        CreateOtherCompanyHeader(LegacyName, OtherCompany);
        Migration.Migrate();
        LegacyName.Description := 'Allowed legacy edit';

        // [WHEN] A compatibility consumer updates the unmigrated target.
        LegacyName.Modify(false);

        // [THEN] Its legacy store remains writable.
        LegacyName.Get(LegacyName.Name);
        Assert.AreEqual('Allowed legacy edit', LegacyName.Description, 'The target company controls authority.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ConfigurationPackageGraphAndBlobSurvive()
    var
        LegacyName: Record "FR Acc. Schedule Name";
        LegacyLine: Record "FR Acc. Schedule Line";
        Package: Record "Config. Package";
        FieldMap: Record "Config. Field Map";
        PackageData: Record "Config. Package Data";
        PackageError: Record "Config. Package Error";
        ScheduleName: Record "FR Financial Schedule Name";
        ConfigLine: Record "Config. Line";
        Input: InStream;
        Value: Text;
        MappingID: BigInteger;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] Every package child, record reference, BLOB and mapping identity follows the copied configuration.
        Initialize();

        // [GIVEN] S has a complete configuration package graph with a BLOB and a record-specific error.
        CreateLegacySchedule(LegacyName, LegacyLine);
        CreatePackageGraph(Package, LegacyName, FieldMap);
        MappingID := FieldMap.ID;

        // [WHEN] The first-release migration remaps the graph twice.
        Migration.Migrate();
        Migration.MigrateConfigurationPackages(Package.Code);

        // [THEN] References and content survive without creating a second field mapping.
        VerifyPackageGraph(Package.Code);
        FieldMap.Get(MappingID);
        Assert.AreEqual(Database::"FR Financial Schedule Name", FieldMap."Table ID", 'The stable mapping ID must be retained.');
        PackageData.Get(Package.Code, Database::"FR Financial Schedule Name", 1, 1);
        PackageData.CalcFields("BLOB Value");
        PackageData."BLOB Value".CreateInStream(Input, TextEncoding::UTF8);
        Input.ReadText(Value);
        Assert.AreEqual('Preserved package payload', Value, 'Package BLOB content must survive.');
        ScheduleName.Get(LegacyName.Name);
        PackageError.Get(Package.Code, Database::"FR Financial Schedule Name", 1, 1);
        Assert.AreEqual(ScheduleName.RecordId(), PackageError."Record ID", 'The error must point to the replacement record.');
        ConfigLine.SetRange("Package Code", Package.Code);
        ConfigLine.FindFirst();
        Assert.AreEqual(Database::"FR Financial Schedule Name", ConfigLine."Table ID", 'Worksheet table references must be mapped.');
        Assert.AreEqual(Page::"FR Financial Schedule Names", ConfigLine."Page ID", 'Worksheet page references must be mapped.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FieldMappingCollisionHasActionableDiagnostic()
    var
        Package: Record "Config. Package";
        FieldMap: Record "Config. Field Map";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] A logical field-map collision is rejected even though both records have distinct primary IDs.
        Initialize();

        // [GIVEN] P contains incompatible mappings for the legacy and destination field.
        CreatePackage(Package);
        FieldMap."Package Code" := Package.Code;
        FieldMap."Table ID" := 10800;
        FieldMap."Field ID" := 1;
        FieldMap."Old Value" := 'OLD';
        FieldMap."New Value" := 'LEGACY';
        FieldMap.Insert(false);
        FieldMap.ID := 0;
        FieldMap."Table ID" := Database::"FR Financial Schedule Name";
        FieldMap."New Value" := 'CONFLICT';
        FieldMap.Insert(false);

        // [WHEN] The package graph is remapped.
        asserterror Migration.MigrateConfigurationPackages(Package.Code);

        // [THEN] The user receives the same explicit reconciliation prerequisite as other package collisions.
        Assert.ExpectedError('configuration package already contains');
        Assert.ExpectedErrorCode('Dialog');
        Assert.IsFalse(Migration.IsMigrated(), 'A mapping collision must not activate the destination.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ConfigurationPackageCollisionRejectsCompletion()
    var
        Package: Record "Config. Package";
        PackageTable: Record "Config. Package Table";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] A package containing both identities blocks activation rather than overwriting either definition.
        Initialize();

        // [GIVEN] P contains both the legacy and destination table definitions.
        CreatePackage(Package);
        PackageTable."Package Code" := Package.Code;
        PackageTable."Table ID" := 10800;
        PackageTable.Insert(false);
        PackageTable."Table ID" := Database::"FR Financial Schedule Name";
        PackageTable.Insert(false);

        // [WHEN] Migration finds the collision.
        asserterror Migration.Migrate();

        // [THEN] The error identifies the package prerequisite and completion remains absent.
        Assert.ExpectedError('configuration package already contains');
        Assert.ExpectedErrorCode('Dialog');
        Assert.IsFalse(Migration.IsMigrated(), 'A package collision must not set the tag.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InterruptedCommittedFixtureCanRetry()
    var
        ScheduleName: Record "FR Financial Schedule Name";
        LegacyName: Record "FR Acc. Schedule Name";
        FailureSubscriber: Codeunit "Library - Reports FR";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] A committed legacy definition survives interruption and is migrated exactly once on retry.
        Initialize();

        // [GIVEN] The dedicated company's committed fixture survives the rollback of an injected failure.
        FailureSubscriber.SetInjectFailure();
        BindSubscription(FailureSubscriber);

        // [WHEN] Migration is interrupted and then retried without the failing subscriber.
        asserterror Migration.Migrate();
        Assert.ExpectedError('Injected migration interruption');
        Assert.ExpectedErrorCode('Dialog');
        UnbindSubscription(FailureSubscriber);
        Assert.IsFalse(Migration.IsMigrated(), 'The failed transaction must not complete migration.');
        Assert.IsTrue(ScheduleName.IsEmpty(), 'The failed transaction must not retain partial destination data.');
        Migration.Migrate();

        // [THEN] The committed source and its integration identity remain available.
        LegacyName.Get('PERSISTENT');
        ScheduleName.Get(LegacyName.Name);
        Assert.AreEqual(LegacyName.SystemId, ScheduleName.SystemId, 'Retry must preserve the committed source identity.');
        Assert.IsTrue(Migration.IsMigrated(), 'Retry must complete successfully.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NonzeroDimensionSetIdentitySurvives()
    var
        LegacyName: Record "FR Acc. Schedule Name";
        LegacyLine: Record "FR Acc. Schedule Line";
        ScheduleLine: Record "FR Financial Schedule Line";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        TempDimensionSetEntry: Record "Dimension Set Entry" temporary;
        DimensionManagement: Codeunit DimensionManagement;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] A real nonzero dimension-set reference remains identical after copy migration.
        Initialize();

        // [GIVEN] L references a dimension set whose value exists.
        CreateLegacySchedule(LegacyName, LegacyLine);
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        TempDimensionSetEntry."Dimension Code" := Dimension.Code;
        TempDimensionSetEntry."Dimension Value Code" := DimensionValue.Code;
        TempDimensionSetEntry."Dimension Value ID" := DimensionValue."Dimension Value ID";
        TempDimensionSetEntry.Insert();
        LegacyLine."Dimension Set ID" := DimensionManagement.GetDimensionSetID(TempDimensionSetEntry);
        LegacyLine.Modify(false);

        // [WHEN] Migration copies the stored configuration.
        Migration.Migrate();

        // [THEN] The exact dimension-set identity survives rather than being rebuilt or cleared.
        ScheduleLine.Get(LegacyLine."Schedule Name", LegacyLine."Line No.");
        Assert.IsTrue(LegacyLine."Dimension Set ID" > 0, 'The fixture must use a real dimension set.');
        Assert.AreEqual(LegacyLine."Dimension Set ID", ScheduleLine."Dimension Set ID", 'Dimension-set identity must survive.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure VolumeMigrationAndReportingLeaveLedgerUnchanged()
    var
        LegacyName: Record "FR Acc. Schedule Name";
        LegacyLine: Record "FR Acc. Schedule Line";
        ScheduleName: Record "FR Financial Schedule Name";
        ScheduleLine: Record "FR Financial Schedule Line";
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        TempLedger: Record "G/L Entry" temporary;
        ScheduleReport: Report "FR Financial Schedule";
        Data: Codeunit "Temp Blob";
        Output: OutStream;
        HeaderNo: Integer;
        LineNo: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] A 100-header/1000-line migration and report preserve every stored field of 1000 ledger entries.
        Initialize();

        // [GIVEN] A representative synthetic configuration and ledger are snapshotted before migration.
        LibraryERM.CreateGLAccount(GLAccount);
        CreateVolumeLedger(GLAccount."No.", TempLedger);
        for HeaderNo := 1 to 100 do begin
            LegacyName.Init();
            LegacyName.Name := CopyStr(Format(HeaderNo, 0, 9), 1, MaxStrLen(LegacyName.Name));
            LegacyName."Caption Column 1" := 'Current';
            LegacyName.Insert(false);
            for LineNo := 1 to 10 do begin
                LegacyLine.Init();
                LegacyLine."Schedule Name" := LegacyName.Name;
                LegacyLine."Line No." := LineNo * 10000;
                LegacyLine.Totaling := GLAccount."No.";
                LegacyLine.Insert(false);
            end;
        end;

        // [WHEN] Migration completes and all 1000 lines are reported.
        Migration.Migrate();
        ScheduleLine.SetRange("Date Filter", 20260101D, 20261231D);
        ScheduleReport.SetTableView(ScheduleLine);
        Data.CreateOutStream(Output);
        ScheduleReport.SaveAs('', ReportFormat::Xml, Output);

        // [THEN] The configuration counts and every ledger field and identity are unchanged.
        Assert.AreEqual(100, ScheduleName.Count(), 'All headers must migrate.');
        Assert.AreEqual(1000, ScheduleLine.Count(), 'All lines must migrate.');
        Assert.IsTrue(Data.Length() > 0, 'The full schedule dataset must be produced.');
        Assert.AreEqual(TempLedger.Count(), GLEntry.Count(), 'Migration and reporting must not insert or delete ledger entries.');
        TempLedger.FindSet();
        repeat
            GLEntry.Get(TempLedger."Entry No.");
            VerifyStoredFields(TempLedger, GLEntry);
        until TempLedger.Next() = 0;
    end;

    local procedure Initialize()
    var
        LegacyName: Record "FR Acc. Schedule Name";
        LegacyLine: Record "FR Acc. Schedule Line";
        ScheduleName: Record "FR Financial Schedule Name";
        ScheduleLine: Record "FR Financial Schedule Line";
    begin
        if Migration.IsMigrated() then
            UpgradeTagLibrary.DeleteUpgradeTag(Migration.GetUpgradeTag(), CopyStr(CompanyName(), 1, 30));
        LegacyLine.DeleteAll(false);
        LegacyName.DeleteAll(false);
        ScheduleLine.DeleteAll(false);
        ScheduleName.DeleteAll(false);
    end;

    local procedure CreateVolumeLedger(AccountNo: Code[20]; var TempLedger: Record "G/L Entry" temporary)
    var
        GLEntry: Record "G/L Entry";
        EntryNo: Integer;
        FirstEntryNo: Integer;
    begin
        if GLEntry.FindLast() then
            FirstEntryNo := GLEntry."Entry No." + 1
        else
            FirstEntryNo := 1;
        for EntryNo := FirstEntryNo to FirstEntryNo + 999 do begin
            GLEntry.Init();
            GLEntry."Entry No." := EntryNo;
            GLEntry."G/L Account No." := AccountNo;
            GLEntry."Posting Date" := 20260115D;
            GLEntry."Debit Amount" := 1;
            GLEntry.Amount := 1;
            GLEntry.Letter := 'ABC';
            GLEntry."Letter Date" := 20260131D;
            GLEntry.Insert(false);
        end;
        GLEntry.Reset();
        GLEntry.FindSet();
        repeat
            TempLedger := GLEntry;
            TempLedger.Insert(false, true);
        until GLEntry.Next() = 0;
    end;

    local procedure CreatePackage(var Package: Record "Config. Package")
    begin
        Package.Code := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, MaxStrLen(Package.Code));
        Package.Insert(false);
    end;

    local procedure CreatePackageGraph(var Package: Record "Config. Package"; LegacyName: Record "FR Acc. Schedule Name"; var FieldMap: Record "Config. Field Map")
    var
        PackageTable: Record "Config. Package Table";
        PackageField: Record "Config. Package Field";
        PackageRecord: Record "Config. Package Record";
        PackageData: Record "Config. Package Data";
        PackageFilter: Record "Config. Package Filter";
        PackageError: Record "Config. Package Error";
        ProcessingRule: Record "Config. Table Processing Rule";
        ConfigLine: Record "Config. Line";
        Output: OutStream;
    begin
        CreatePackage(Package);
        PackageTable."Package Code" := Package.Code;
        PackageTable."Table ID" := 10800;
        PackageTable."Parent Table ID" := 10801;
        PackageTable."Page ID" := 10800;
        PackageTable.Insert(false);
        PackageField."Package Code" := Package.Code;
        PackageField."Table ID" := 10800;
        PackageField."Field ID" := 1;
        PackageField."Relation Table ID" := 10801;
        PackageField.Insert(false);
        PackageRecord."Package Code" := Package.Code;
        PackageRecord."Table ID" := 10800;
        PackageRecord."No." := 1;
        PackageRecord.Insert(false);
        PackageData."Package Code" := Package.Code;
        PackageData."Table ID" := 10800;
        PackageData."No." := 1;
        PackageData."Field ID" := 1;
        PackageData.Value := LegacyName.Name;
        PackageData."BLOB Value".CreateOutStream(Output, TextEncoding::UTF8);
        Output.WriteText('Preserved package payload');
        PackageData.Insert(false);
        ProcessingRule."Package Code" := Package.Code;
        ProcessingRule."Table ID" := 10800;
        ProcessingRule."Rule No." := 1;
        ProcessingRule.Insert(false);
        PackageFilter."Package Code" := Package.Code;
        PackageFilter."Table ID" := 10800;
        PackageFilter."Processing Rule No." := 1;
        PackageFilter."Field ID" := 1;
        PackageFilter."Field Filter" := LegacyName.Name;
        PackageFilter.Insert(false);
        PackageError."Package Code" := Package.Code;
        PackageError."Table ID" := 10800;
        PackageError."Record No." := 1;
        PackageError."Field ID" := 1;
        PackageError."Record ID" := LegacyName.RecordId();
        PackageError.Insert(false);
        FieldMap."Package Code" := Package.Code;
        FieldMap."Table ID" := 10800;
        FieldMap."Field ID" := 1;
        FieldMap."Old Value" := 'OLD';
        FieldMap."New Value" := LegacyName.Name;
        FieldMap.Insert(false);
        if ConfigLine.FindLast() then
            ConfigLine."Line No." += 10000
        else
            ConfigLine."Line No." := 10000;
        ConfigLine."Package Code" := Package.Code;
        ConfigLine."Table ID" := 10800;
        ConfigLine."Page ID" := 10800;
        ConfigLine.Insert(false);
    end;

    local procedure VerifyPackageGraph(PackageCode: Code[20])
    var
        PackageTable: Record "Config. Package Table";
        PackageField: Record "Config. Package Field";
        PackageRecord: Record "Config. Package Record";
        PackageFilter: Record "Config. Package Filter";
        ProcessingRule: Record "Config. Table Processing Rule";
    begin
        PackageTable.Get(PackageCode, Database::"FR Financial Schedule Name");
        Assert.AreEqual(Database::"FR Financial Schedule Line", PackageTable."Parent Table ID", 'Parent table references must be mapped.');
        Assert.AreEqual(Page::"FR Financial Schedule Names", PackageTable."Page ID", 'The maintenance page must be mapped.');
        PackageField.Get(PackageCode, Database::"FR Financial Schedule Name", 1);
        Assert.AreEqual(Database::"FR Financial Schedule Line", PackageField."Relation Table ID", 'Related table references must be mapped.');
        Assert.IsTrue(PackageRecord.Get(PackageCode, Database::"FR Financial Schedule Name", 1), 'The package record must be mapped.');
        Assert.IsTrue(PackageFilter.Get(PackageCode, Database::"FR Financial Schedule Name", 1, 1), 'The package filter must be mapped.');
        Assert.IsTrue(ProcessingRule.Get(PackageCode, Database::"FR Financial Schedule Name", 1), 'The processing rule must be mapped.');
        Assert.IsFalse(PackageTable.Get(PackageCode, 10800), 'The package must no longer target the legacy table.');
    end;

    local procedure CreateLegacySchedule(var LegacyName: Record "FR Acc. Schedule Name"; var LegacyLine: Record "FR Acc. Schedule Line")
    begin
        LegacyName.Name := 'CUSTOM';
        LegacyName.Description := 'Customized financial schedule';
        LegacyName."Caption Column 1" := 'Assets';
        LegacyName."Caption Column 2" := 'Liabilities';
        LegacyName."Caption Column 3" := 'Current';
        LegacyName."Caption Column Previous Year" := 'Previous';
        LegacyName.Insert(false);
        LegacyLine."Schedule Name" := LegacyName.Name;
        LegacyLine."Line No." := 20000;
        LegacyLine."Row No." := 'R10';
        LegacyLine.Description := 'Customized calculation';
        LegacyLine.Totaling := 'R01..R09';
        LegacyLine."Totaling Type" := LegacyLine."Totaling Type"::Rows;
        LegacyLine."Totaling Debtor" := '1000..1999';
        LegacyLine."Totaling Creditor" := '2000..2999';
        LegacyLine."Totaling 2" := '3000..3999';
        LegacyLine."Calculate with" := LegacyLine."Calculate with"::"Opposite Sign";
        LegacyLine."New Page" := true;
        LegacyLine.Insert(false);
        LegacyLine.SetRange("Date Filter", 20260101D, 20261231D);
    end;

    local procedure PrepareOtherCompany(): Text[30]
    var
        Company: Record Company;
    begin
        if not Company.Get(OtherCompanyTok) then
            Error('The two-company migration acceptance tests require an initialized FR company named 653672 Migration Target.');
        if Company.Name = CompanyName() then
            Error('Run the two-company migration acceptance tests from a different company than 653672 Migration Target.');
        if UpgradeTag.HasUpgradeTag(Migration.GetUpgradeTag(), Company.Name) then
            UpgradeTagLibrary.DeleteUpgradeTag(Migration.GetUpgradeTag(), Company.Name);
        exit(Company.Name);
    end;

    local procedure CreateOtherCompanyHeader(var LegacyName: Record "FR Acc. Schedule Name"; OtherCompany: Text[30])
    begin
        LegacyName.ChangeCompany(OtherCompany);
        LegacyName.Name := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        LegacyName.Insert(false);
    end;

    local procedure VerifyStoredFields(Source: Variant; Destination: Variant)
    var
        SourceRef: RecordRef;
        DestinationRef: RecordRef;
        SourceField: FieldRef;
        FieldIndex: Integer;
    begin
        SourceRef.GetTable(Source);
        DestinationRef.GetTable(Destination);
        for FieldIndex := 1 to SourceRef.FieldCount() do begin
            SourceField := SourceRef.FieldIndex(FieldIndex);
            if (SourceField.Class = FieldClass::Normal) and (SourceField.Number < 2000000000) then
                Assert.AreEqual(
                    Format(SourceField.Value, 0, 9), Format(DestinationRef.Field(SourceField.Number).Value, 0, 9),
                    StrSubstNo(StoredFieldPreservationErr, SourceField.Number));
        end;
        Assert.AreEqual(
            SourceRef.Field(SourceRef.SystemIdNo).Value, DestinationRef.Field(DestinationRef.SystemIdNo).Value,
            'Integration SystemId must survive migration.');
    end;

    procedure PrepareUnmigratedFixture()
    var
        LegacyName: Record "FR Acc. Schedule Name";
        LegacyLine: Record "FR Acc. Schedule Line";
        ScheduleName: Record "FR Financial Schedule Name";
        ScheduleLine: Record "FR Financial Schedule Line";
        Status: Record "Feature Data Update Status";
    begin
        if CompanyName() <> FixtureCompanyTok then
            Error('This fixture setup is restricted to the dedicated 653672 Migration Source company.');
        if Migration.IsMigrated() then
            UpgradeTagLibrary.DeleteUpgradeTag(Migration.GetUpgradeTag(), CopyStr(CompanyName(), 1, 30));
        LegacyLine.DeleteAll(false);
        LegacyName.DeleteAll(false);
        ScheduleLine.DeleteAll(false);
        ScheduleName.DeleteAll(false);
        LegacyName.Name := 'PERSISTENT';
        LegacyName.Description := 'Committed legacy migration fixture';
        LegacyName."Caption Column 1" := 'Current';
        LegacyName."Caption Column 2" := 'Secondary';
        LegacyName."Caption Column 3" := 'Combined';
        LegacyName."Caption Column Previous Year" := 'Previous';
        LegacyName.Insert(false);
        LegacyLine."Schedule Name" := LegacyName.Name;
        LegacyLine."Line No." := 10000;
        LegacyLine."Row No." := 'P1';
        LegacyLine.Description := 'Committed legacy fixture row';
        LegacyLine.Insert(false);
        if not Status.Get('FRReports', CompanyName()) then begin
            Status."Feature Key" := 'FRReports';
            Status."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(Status."Company Name"));
            Status.Insert();
        end;
        Status."Data Update Required" := true;
        Status."Feature Status" := Status."Feature Status"::Pending;
        Status.Modify();
    end;

}
#pragma warning restore AL0432, AS0105
#endif
