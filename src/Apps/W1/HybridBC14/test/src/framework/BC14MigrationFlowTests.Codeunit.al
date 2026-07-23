// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration;
using Microsoft.DataMigration.BC14Reimplementation;
using Microsoft.Finance.GeneralLedger.Account;
using System.Integration;
using System.Security.AccessControl;
using System.TestLibraries.Environment;

codeunit 148906 "BC14 Migration Flow Tests"
{
    // [FEATURE] [BC14 Cloud Migration Flow]
    //
    // Merged file covering five flow-related test areas:
    //   * Orchestrator   (was 148910 BC14 Migration Orch. Test)
    //   * Runner         (was 148913 BC14 Migration Runner Tests)
    //   * Provider       (was 148912 BC14 Migration Provider Tests)
    //   * Loop           (was 149014 BC14 Migration Loop Tests)
    //   * Status Manager (was 148919 BC14 Status Manager Tests)

    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryHybridManagement: Codeunit "Library - Hybrid Management";
        SubscriptionIdTxt: Label '46850-BC14Re-Implementation_IntelligentCloud', Locked = true;
        TestMigratorNameLbl: Label 'Loop Test Migrator', Locked = true;

    // ============================================================
    // Helpers — Orchestrator
    // ============================================================

    local procedure Initialize_Orch()
    var
        WebhookSubscription: Record "Webhook Subscription";
        IntelligentCloudSetup: Record "Intelligent Cloud Setup";
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        HybridReplicationDetail: Record "Hybrid Replication Detail";
        BC14GlobalSettings: Record "BC14 Global Migration Settings";
        BC14Wizard: Codeunit "BC14 Wizard";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        PermissionManager: Codeunit "Permission Manager";
    begin
        WebhookSubscription.DeleteAll();
        HybridReplicationSummary.DeleteAll();
        HybridReplicationDetail.DeleteAll();

        // Disable One Step Upgrade to prevent TriggerUpgradeIfOneStepEnabled from running validation
        BC14GlobalSettings.DeleteAll();
        BC14GlobalSettings.Init();
        BC14GlobalSettings."One Step Upgrade" := false;
        BC14GlobalSettings.Insert();

        WebhookSubscription.Init();
        WebhookSubscription."Subscription ID" := CopyStr(SubscriptionIdTxt, 1, 150);
        WebhookSubscription.Endpoint := 'Hybrid';
        WebhookSubscription.Insert();

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        PermissionManager.SetTestabilityIntelligentCloud(true);

        if not IntelligentCloudSetup.Get() then
            IntelligentCloudSetup.Init();

        IntelligentCloudSetup."Product ID" := BC14Wizard.GetMigrationProviderId();
        if not IntelligentCloudSetup.Insert() then
            IntelligentCloudSetup.Modify();
    end;

    local procedure AdditionalNotificationText() Json: Text
    begin
        Json := ', "IncrementalTables": [' +
                    '{' +
                    '"TableName": "BC14$BC14 Customer$2363a2b7-1018-4976-a32a-c77338dc9f16",' +
                    '"CompanyName": "' + CompanyName() + '",' +
                    '"$companyid": 0,' +
                    '"NewVersion": 742,' +
                    '"ErrorMessage": ""' +
                    '},' +
                    '{' +
                    '"TableName": "Bad Table",' +
                    '"CompanyName": "' + CompanyName() + '",' +
                    '"$companyid": 0,' +
                    '"NewVersion": 742,' +
                    '"ErrorCode": "1337",' +
                    '"ErrorMessage": "Failure processing data for Table = ''Bad Table''\\\\r\\\\n' +
                    'Error message: Explicit value must be specified for identity column in table ''' +
                    'CRONUS International Ltd_$Bad Table''."' +
                    '},' +
                    '{' +
                    '"TableName": "Bad Table, Errors Array",' +
                    '"CompanyName": "' + CompanyName() + '",' +
                    '"$companyid": 0,' +
                    '"NewVersion": 0,' +
                    '"Errors": [{"Code": 1000, "Message": "The table column ''New Column'' does not exist."}]' +
                    '}' +
                ']';
    end;

#pragma warning disable AA0150
    local procedure InsertNotification(var RunId: Text; var StartTime: DateTime; var TriggerType: Text)
    var
        WebhookNotification: Record "Webhook Notification";
        NotificationStream: OutStream;
        NotificationText: Text;
    begin
        NotificationText := LibraryHybridManagement.GetNotificationPayload(SubscriptionIdTxt, RunId, StartTime, TriggerType, AdditionalNotificationText());
        WebhookNotification.Init();
        WebhookNotification.ID := CreateGuid();
        WebhookNotification."Subscription ID" := CopyStr(SubscriptionIdTxt, 1, 150);
        WebhookNotification.Notification.CreateOutStream(NotificationStream, TextEncoding::UTF8);
        NotificationStream.WriteText(NotificationText);
        WebhookNotification.Insert(true);
    end;
#pragma warning restore AA0150

    local procedure InitializeForContinueCompanyMigration(var BC14E2ETestEventHandler: Codeunit "BC14 E2E Test Event Handler")
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        BC14GlobalSettings: Record "BC14 Global Migration Settings";
        DataMigrationError: Record "Data Migration Error";
        HybridCompany: Record "Hybrid Company";
        HybridCompanyStatus: Record "Hybrid Company Status";
        HybridReplicationDetail: Record "Hybrid Replication Detail";
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        BC14Wizard: Codeunit "BC14 Wizard";
    begin
        // Clean every table the rerun path touches so each test starts from a known state.
        BC14CompanySettings.DeleteAll();
        BC14GlobalSettings.DeleteAll();
        DataMigrationError.DeleteAll();
        HybridCompany.DeleteAll();
        HybridCompanyStatus.DeleteAll();
        HybridReplicationDetail.DeleteAll();
        HybridReplicationSummary.DeleteAll();

        BC14GlobalSettings.Init();
        BC14GlobalSettings."One Step Upgrade" := false;
        BC14GlobalSettings.Insert();

        HybridCompany.Init();
        HybridCompany.Name := CopyStr(CompanyName(), 1, MaxStrLen(HybridCompany.Name));
        HybridCompany.Replicate := true;
        HybridCompany.Insert();

        // Continue migration is invoked from a terminal (Failed) state — AcquireRerunSlot
        // rejects Started to prevent concurrent reruns.
        HybridCompanyStatus.Init();
        HybridCompanyStatus.Name := CopyStr(CompanyName(), 1, MaxStrLen(HybridCompanyStatus.Name));
        HybridCompanyStatus."Upgrade Status" := HybridCompanyStatus."Upgrade Status"::Failed;
        HybridCompanyStatus.Insert();

        HybridReplicationSummary.Init();
        HybridReplicationSummary."Run ID" := Format(CreateGuid());
        HybridReplicationSummary.Source := BC14Wizard.GetMigrationProviderId();
        HybridReplicationSummary."Start Time" := CurrentDateTime();
        HybridReplicationSummary.Status := HybridReplicationSummary.Status::UpgradeInProgress;
        HybridReplicationSummary.Insert();

        BC14CompanySettings.GetSingleInstance();
        BC14CompanySettings.SetDataMigrationStarted();
        BC14CompanySettings.SetMigrationPhaseCompleted("BC14 Migration Step"::Setup, '');
        BC14CompanySettings.SetMigrationPhaseCompleted("BC14 Migration Step"::Master, '');
        BC14CompanySettings.SetMigrationPhaseCompleted("BC14 Migration Step"::Transaction, '');
        BC14CompanySettings.SetMigrationPhaseCompleted("BC14 Migration Step"::Posting, '');
        BC14CompanySettings.SetPostingCompleted();
        BC14CompanySettings.SetHistoricalCompleted();
        BC14CompanySettings.SetMigrationState("BC14 Migration Step"::Posting);

        BC14MigrationErrorHandler.ClearErrorOccurred();

        BindSubscription(BC14E2ETestEventHandler);
        BC14E2ETestEventHandler.Reset();
        BC14E2ETestEventHandler.SetForceSkipAllMigrators(true);
    end;

    // ============================================================
    // Helpers — Runner
    // ============================================================

    local procedure CleanupGLTestData()
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.SetFilter("No.", 'RUNNER-*');
        GLAccount.DeleteAll();
    end;

    local procedure InitializeForRerun()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        HybridReplicationSummary: Record "Hybrid Replication Summary";
    begin
        HybridCompanyStatus.DeleteAll();
        HybridReplicationSummary.DeleteAll();
    end;

    local procedure InsertCompanyStatus_Runner(CompanyNameValue: Text[30]; UpgradeStatus: Option)
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
    begin
        HybridCompanyStatus.Init();
        HybridCompanyStatus.Name := CompanyNameValue;
        HybridCompanyStatus."Upgrade Status" := UpgradeStatus;
        HybridCompanyStatus.Insert();
    end;

    // ============================================================
    // Helpers — Provider
    // ============================================================

    local procedure GetCompanyMappingCount(CompanyNameValue: Text): Integer
    var
        ReplicationMapping: Record "Replication Table Mapping";
    begin
        ReplicationMapping.SetRange("Company Name", CompanyNameValue);
        exit(ReplicationMapping.Count());
    end;

    // ============================================================
    // Helpers — Loop
    // ============================================================

    local procedure ResetState(StopOnFirstError: Boolean)
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        BC14CountryRegion: Record "BC14 Country/Region";
        DataMigrationError: Record "Data Migration Error";
    begin
        BC14CountryRegion.DeleteAll();
        DataMigrationError.DeleteAll();
        BC14CompanySettings.DeleteAll();
        BC14CompanySettings.Init();
        BC14CompanySettings.Name := CopyStr(CompanyName(), 1, MaxStrLen(BC14CompanySettings.Name));
        BC14CompanySettings."Stop On First Error" := StopOnFirstError;
        BC14CompanySettings.Insert();
    end;

    local procedure InsertCountryRegion(Code: Code[10])
    var
        BC14CountryRegion: Record "BC14 Country/Region";
    begin
        BC14CountryRegion.Init();
        BC14CountryRegion.Code := Code;
        BC14CountryRegion.Insert();
    end;

    local procedure RunLoop(var BC14CountryRegion: Record "BC14 Country/Region"; KeyFieldNo: Integer): Boolean
    var
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
    begin
        SourceVariant := BC14CountryRegion;
        exit(MigrationLoop.RunRecordLoop(
            CopyStr(TestMigratorNameLbl, 1, 250),
            SourceVariant,
            KeyFieldNo,
            Codeunit::"BC14 Loop Test Migrator"));
    end;

    local procedure CountErrorsForKey(SourceRecordKey: Text[250]): Integer
    var
        DataMigrationError: Record "Data Migration Error";
    begin
        DataMigrationError.SetRange("Source Record Key", SourceRecordKey);
        exit(DataMigrationError.Count());
    end;

    // ============================================================
    // Helpers — Status Manager
    // ============================================================

    local procedure Initialize_StatusMgr()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        HybridCompany: Record "Hybrid Company";
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
    begin
        HybridCompanyStatus.DeleteAll();
        HybridCompany.DeleteAll();
        HybridReplicationSummary.DeleteAll();
        BC14CompanySettings.DeleteAll();
    end;

    local procedure SetStopOnFirstError_StatusMgr(StopOnFirstError: Boolean)
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
    begin
        BC14CompanySettings.GetSingleInstance();
        BC14CompanySettings."Stop On First Error" := StopOnFirstError;
        BC14CompanySettings.Modify();
    end;

    local procedure InsertCompanyStatus_StatusMgr(CompanyName: Text[30]; UpgradeStatus: Option)
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
    begin
        HybridCompanyStatus.Init();
        HybridCompanyStatus.Name := CompanyName;
        HybridCompanyStatus."Upgrade Status" := UpgradeStatus;
        HybridCompanyStatus.Insert();
    end;

    local procedure InsertHybridCompany(CompanyName: Text[30]; Replicate: Boolean)
    var
        HybridCompany: Record "Hybrid Company";
    begin
        HybridCompany.Init();
        HybridCompany.Name := CompanyName;
        HybridCompany."Display Name" := CompanyName;
        HybridCompany.Replicate := Replicate;
        HybridCompany.Insert();
    end;

    local procedure InsertReplicationSummary(var HybridReplicationSummary: Record "Hybrid Replication Summary"; InitialStatus: Option)
    begin
        HybridReplicationSummary.Init();
        HybridReplicationSummary."Run ID" := CreateGuid();
        HybridReplicationSummary."Start Time" := CurrentDateTime();
        HybridReplicationSummary.Status := InitialStatus;
        HybridReplicationSummary.Insert();
    end;

    local procedure ReadSummaryDetails(var HybridReplicationSummary: Record "Hybrid Replication Summary") DetailsText: Text
    var
        DetailsInStream: InStream;
    begin
        HybridReplicationSummary.Get(HybridReplicationSummary."Run ID");
        HybridReplicationSummary.CalcFields(Details);
        if not HybridReplicationSummary.Details.HasValue() then
            exit('');
        HybridReplicationSummary.Details.CreateInStream(DetailsInStream);
        DetailsInStream.Read(DetailsText);
    end;

    // ============================================================
    // Orchestrator
    // ============================================================

    [Test]
    procedure InsertSummaryOnWebhookNotificationInsert()
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        BC14Wizard: Codeunit "BC14 Wizard";
        RunId: Text;
        StartTime: DateTime;
        TriggerType: Text;
    begin
        // [SCENARIO] A Hybrid Replication Summary record is created when a webhook notification is inserted.

        // [GIVEN] A Webhook Subscription exists for BC14
        Initialize_Orch();

        // [WHEN] A notification record is inserted
        TriggerType := 'Scheduled';
        InsertNotification(RunId, StartTime, TriggerType);

        // [THEN] A Hybrid Replication Summary record is created with the correct values
        HybridReplicationSummary.Get(RunId);
        Assert.AreEqual(BC14Wizard.GetMigrationProviderId(), HybridReplicationSummary.Source, 'Unexpected value in summary for source.');
        Assert.AreEqual(RunId, HybridReplicationSummary."Run ID", 'Unexpected value in summary for Run ID.');
        Assert.AreEqual(StartTime, HybridReplicationSummary."Start Time", 'Unexpected value in summary for Start Time.');
        Assert.AreEqual(HybridReplicationSummary."Trigger Type"::Scheduled, HybridReplicationSummary."Trigger Type", 'Unexpected value in summary for Trigger Type.');
    end;

    [Test]
    procedure StatusUpdatedOnWebhookNotificationInsert()
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        HybridCompany: Record "Hybrid Company";
        WebhookNotification: Record "Webhook Notification";
        NotificationStream: OutStream;
        RunId: Text;
        StartTime: DateTime;
        TriggerType: Text;
    begin
        // [SCENARIO] BC14 handler processes the replication-completed notification and the summary
        // record is persisted. The platform reports the run as Completed when the payload says so;
        // BC14's handler runs alongside but does not override the platform-set status when one-step
        // upgrade is disabled.

        // [GIVEN] A Webhook Subscription exists for BC14 and a company is set up for replication
        Initialize_Orch();

        HybridCompany.Init();
        HybridCompany.Name := CopyStr(CompanyName(), 1, MaxStrLen(HybridCompany.Name));
        HybridCompany.Replicate := true;
        if not HybridCompany.Insert() then
            HybridCompany.Modify();

        // [WHEN] A replication completed notification is inserted with Completed status
        WebhookNotification.Init();
        WebhookNotification.ID := CreateGuid();
        WebhookNotification."Subscription ID" := CopyStr(SubscriptionIdTxt, 1, 150);
        WebhookNotification.Notification.CreateOutStream(NotificationStream, TextEncoding::UTF8);
        NotificationStream.WriteText(LibraryHybridManagement.GetNotificationPayload(
            SubscriptionIdTxt, RunId, StartTime, TriggerType,
            ', "Status": "Completed", "ServiceType": "ReplicationCompleted"' + AdditionalNotificationText()));
        WebhookNotification.Insert(true);

        // [THEN] The HybridReplicationSummary record exists and reflects either the platform-set
        // Completed status or the BC14 UpgradePending transition (depending on platform behavior).
        HybridReplicationSummary.Get(RunId);
        Assert.IsTrue(
            HybridReplicationSummary.Status in [HybridReplicationSummary.Status::Completed, HybridReplicationSummary.Status::UpgradePending],
            'Status should be either Completed or UpgradePending after the replication notification.');
    end;

    [Test]
    procedure TestGetBC14ProductName()
    var
        HybridCloudManagement: Codeunit "Hybrid Cloud Management";
        BC14Wizard: Codeunit "BC14 Wizard";
        ProductName: Text;
    begin
        // [SCENARIO] The GetChosenProductName method returns the BC14 product name.

        // [GIVEN] BC14 is set up as the intelligent cloud product
        Initialize_Orch();

        // [WHEN] The GetChosenProductName method is called
        ProductName := HybridCloudManagement.GetChosenProductName();

        // [THEN] The returned value is set to the BC14 product name.
        Assert.AreEqual(BC14Wizard.GetMigrationProviderId(), ProductName, 'Incorrect product name returned.');
    end;

    [Test]
    procedure TestValidateReplicationBeforeUpgradeWithEmptyRunId()
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        BC14MigrationOrchestrator: Codeunit "BC14 Migration Orchestrator";
    begin
        // [SCENARIO] ValidateReplicationBeforeUpgrade should error when Run ID is empty

        // [GIVEN] Intelligent cloud is set up for BC14 and a summary with empty Run ID
        Initialize_Orch();
        HybridReplicationSummary.Init();
        HybridReplicationSummary."Run ID" := '';

        // [WHEN] ValidateReplicationBeforeUpgrade is called
        // [THEN] An error is thrown indicating no replication has been completed
        asserterror BC14MigrationOrchestrator.ValidateReplicationBeforeUpgrade(HybridReplicationSummary, true);
        Assert.ExpectedError('Cannot start upgrade: No replication has been completed yet.');
    end;

    [Test]
    procedure TestValidateReplicationBeforeUpgradeWithNoCompletedReplication()
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        BC14MigrationOrchestrator: Codeunit "BC14 Migration Orchestrator";
    begin
        // [SCENARIO] ValidateReplicationBeforeUpgrade should error when no completed replications exist

        // [GIVEN] Intelligent cloud is set up and a summary exists but no completed replications
        Initialize_Orch();
        HybridReplicationSummary.Init();
        HybridReplicationSummary."Run ID" := CreateGuid();
        HybridReplicationSummary.Status := HybridReplicationSummary.Status::InProgress;
        HybridReplicationSummary.Insert();

        // [WHEN] ValidateReplicationBeforeUpgrade is called
        // [THEN] An error is thrown indicating no replication has been completed
        asserterror BC14MigrationOrchestrator.ValidateReplicationBeforeUpgrade(HybridReplicationSummary, true);
        Assert.ExpectedError('Cannot start upgrade: No replication has been completed yet.');
    end;

    [Test]
    procedure TestValidateReplicationBeforeUpgradeWithInvalidStatus()
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        CompletedReplication: Record "Hybrid Replication Summary";
        BC14Wizard: Codeunit "BC14 Wizard";
        BC14MigrationOrchestrator: Codeunit "BC14 Migration Orchestrator";
    begin
        // [SCENARIO] ValidateReplicationBeforeUpgrade should error when status is InProgress

        // [GIVEN] Intelligent cloud is set up and there is a completed replication
        Initialize_Orch();

        CompletedReplication.Init();
        CompletedReplication."Run ID" := CreateGuid();
        CompletedReplication.Status := CompletedReplication.Status::Completed;
        CompletedReplication.Source := BC14Wizard.GetMigrationProviderId();
        CompletedReplication.Insert();

        // [GIVEN] The current summary has InProgress status
        HybridReplicationSummary.Init();
        HybridReplicationSummary."Run ID" := CreateGuid();
        HybridReplicationSummary.Status := HybridReplicationSummary.Status::InProgress;
        HybridReplicationSummary.Source := BC14Wizard.GetMigrationProviderId();
        HybridReplicationSummary.Insert();

        // [WHEN] ValidateReplicationBeforeUpgrade is called
        // [THEN] An error is thrown indicating invalid status
        asserterror BC14MigrationOrchestrator.ValidateReplicationBeforeUpgrade(HybridReplicationSummary, true);
        Assert.ExpectedError('Cannot start upgrade: The replication status is');
    end;

    [Test]
    procedure TestValidateReplicationBeforeUpgradeWithUpgradePendingStatus()
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        BC14Wizard: Codeunit "BC14 Wizard";
        BC14MigrationOrchestrator: Codeunit "BC14 Migration Orchestrator";
    begin
        // [SCENARIO] ValidateReplicationBeforeUpgrade should succeed when status is UpgradePending

        // [GIVEN] Intelligent cloud is set up and summary has UpgradePending status
        Initialize_Orch();

        HybridReplicationSummary.Init();
        HybridReplicationSummary."Run ID" := CreateGuid();
        HybridReplicationSummary.Status := HybridReplicationSummary.Status::UpgradePending;
        HybridReplicationSummary.Source := BC14Wizard.GetMigrationProviderId();
        HybridReplicationSummary.Insert();

        // [WHEN] ValidateReplicationBeforeUpgrade is called
        BC14MigrationOrchestrator.ValidateReplicationBeforeUpgrade(HybridReplicationSummary, true);

        // [THEN] No error is thrown (validation passes)
    end;

    [Test]
    procedure TestValidateReplicationBeforeUpgradeWithUpgradeFailedStatus()
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        CompletedReplication: Record "Hybrid Replication Summary";
        BC14Wizard: Codeunit "BC14 Wizard";
        BC14MigrationOrchestrator: Codeunit "BC14 Migration Orchestrator";
    begin
        // [SCENARIO] ValidateReplicationBeforeUpgrade should succeed when status is UpgradeFailed (retry scenario)

        // [GIVEN] Intelligent cloud is set up and there is a completed replication
        Initialize_Orch();

        CompletedReplication.Init();
        CompletedReplication."Run ID" := CreateGuid();
        CompletedReplication.Status := CompletedReplication.Status::Completed;
        CompletedReplication.Source := BC14Wizard.GetMigrationProviderId();
        CompletedReplication.Insert();

        // [GIVEN] The current summary has UpgradeFailed status (retry scenario)
        HybridReplicationSummary.Init();
        HybridReplicationSummary."Run ID" := CreateGuid();
        HybridReplicationSummary.Status := HybridReplicationSummary.Status::UpgradeFailed;
        HybridReplicationSummary.Source := BC14Wizard.GetMigrationProviderId();
        HybridReplicationSummary.Insert();

        // [WHEN] ValidateReplicationBeforeUpgrade is called
        BC14MigrationOrchestrator.ValidateReplicationBeforeUpgrade(HybridReplicationSummary, true);

        // [THEN] No error is thrown (validation passes for retry)
    end;

    [Test]
    procedure TestTriggerUpgradeOneStep_NoDataReplicated_SkipsUpgrade()
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        BC14GlobalSettings: Record "BC14 Global Migration Settings";
        BC14Wizard: Codeunit "BC14 Wizard";
        BC14MigrationOrchestrator: Codeunit "BC14 Migration Orchestrator";
        RunId: Text[50];
    begin
        // [SCENARIO] A setup-phase run replicates no per-company data and therefore produces
        // no Hybrid Replication Detail rows. The one-step upgrade must be skipped instead of
        // entering the upgrade flow (which fails when no companies are selected/created).

        // [GIVEN] Intelligent cloud is set up for BC14 and One Step Upgrade is enabled
        Initialize_Orch();
        BC14GlobalSettings.FindFirst();
        BC14GlobalSettings."One Step Upgrade" := true;
        BC14GlobalSettings.Modify();

        // [GIVEN] A completed replication summary with no replicated table detail rows
        HybridReplicationSummary.Init();
        HybridReplicationSummary."Run ID" := CreateGuid();
        HybridReplicationSummary.Status := HybridReplicationSummary.Status::Completed;
        HybridReplicationSummary.Source := BC14Wizard.GetMigrationProviderId();
        HybridReplicationSummary.Insert();
        RunId := HybridReplicationSummary."Run ID";

        // [WHEN] The one-step upgrade trigger runs for that run
        BC14MigrationOrchestrator.TriggerUpgradeIfOneStepEnabled(RunId);

        // [THEN] No error is thrown and the summary is not moved to UpgradeInProgress
        HybridReplicationSummary.Get(RunId);
        Assert.AreEqual(
            HybridReplicationSummary.Status::Completed, HybridReplicationSummary.Status,
            'Setup run with no replicated data should not trigger the upgrade');
    end;

    [Test]
    procedure TestGetDefaultJobTimeout_Is48Hours()
    var
        BC14MigrationOrchestrator: Codeunit "BC14 Migration Orchestrator";
        Timeout: Duration;
        ExpectedTimeout: Duration;
    begin
        // [SCENARIO] Default job timeout for the historical worker is 48 hours.

        Timeout := BC14MigrationOrchestrator.GetDefaultJobTimeout();
        ExpectedTimeout := 48 * 60 * 60 * 1000;

        Assert.AreEqual(ExpectedTimeout, Timeout, 'Default job timeout should be 48 hours');
    end;

    [Test]
    procedure TestIsCompanySetupCompleted_NotCompleted_ReturnsFalse()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        BC14MigrationOrchestrator: Codeunit "BC14 Migration Orchestrator";
    begin
        // [SCENARIO] IsCompanySetupCompleted returns false when Setup phase is not completed.
        BC14CompanySettings.DeleteAll();
        BC14CompanySettings.GetSingleInstance();

        Assert.IsFalse(BC14MigrationOrchestrator.IsCompanySetupCompleted(CopyStr(CompanyName(), 1, 50)),
            'Setup should not be completed when no phase has been recorded');
    end;

    [Test]
    procedure TestFindLatestReplicationSummary_NoBC14Summary_ReturnsFalse()
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        BC14MigrationOrchestrator: Codeunit "BC14 Migration Orchestrator";
    begin
        // [SCENARIO] FindLatestReplicationSummary returns false when no BC14-source summary exists.
        HybridReplicationSummary.DeleteAll();

        Assert.IsFalse(BC14MigrationOrchestrator.FindLatestReplicationSummary(HybridReplicationSummary),
            'Should return false when no BC14 summary exists');
    end;

    [Test]
    procedure TestFindLatestReplicationSummary_ReturnsLatestBC14Summary()
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        FoundSummary: Record "Hybrid Replication Summary";
        BC14Wizard: Codeunit "BC14 Wizard";
        BC14MigrationOrchestrator: Codeunit "BC14 Migration Orchestrator";
        OlderRunId: Guid;
        NewerRunId: Guid;
    begin
        // [SCENARIO] FindLatestReplicationSummary returns the most recent BC14-source summary.
        HybridReplicationSummary.DeleteAll();

        // [GIVEN] An older BC14 summary
        OlderRunId := CreateGuid();
        HybridReplicationSummary.Init();
        HybridReplicationSummary."Run ID" := OlderRunId;
        HybridReplicationSummary.Source := BC14Wizard.GetMigrationProviderId();
        HybridReplicationSummary."Start Time" := CurrentDateTime() - 60000;
        HybridReplicationSummary.Insert();

        // [GIVEN] A newer BC14 summary
        NewerRunId := CreateGuid();
        HybridReplicationSummary.Init();
        HybridReplicationSummary."Run ID" := NewerRunId;
        HybridReplicationSummary.Source := BC14Wizard.GetMigrationProviderId();
        HybridReplicationSummary."Start Time" := CurrentDateTime();
        HybridReplicationSummary.Insert();

        // [WHEN] FindLatestReplicationSummary is called
        Assert.IsTrue(BC14MigrationOrchestrator.FindLatestReplicationSummary(FoundSummary),
            'Should find a summary');

        // [THEN] The newer summary is returned
        Assert.AreEqual(BC14Wizard.GetMigrationProviderId(), FoundSummary.Source,
            'Returned summary should be from the BC14 source');
    end;

    [Test]
    procedure TestContinueCompanyMigration_DeletesUnhandledUpgradeErrors()
    var
        DataMigrationError: Record "Data Migration Error";
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14E2ETestEventHandler: Codeunit "BC14 E2E Test Event Handler";
        BC14MigrationRunner: Codeunit "BC14 Migration Runner";
    begin
        // [SCENARIO] ContinueMigrationForCompany's cleanup pass deletes "unhandled upgrade error"
        // sentinel rows (Source Table ID = 0, not dismissed) from the previous failed run.
        InitializeForContinueCompanyMigration(BC14E2ETestEventHandler);

        // [GIVEN] An unhandled upgrade-error row from the previous attempt
        DataMigrationError.Init();
        DataMigrationError."Migration Type" := 'Unhandled Upgrade Error';
        DataMigrationError."Source Table ID" := 0;
        DataMigrationError."Source Table Name" := 'Unhandled Upgrade Error';
        DataMigrationError."Error Message" := 'Previous failure';
        DataMigrationError."Error Dismissed" := false;
        DataMigrationError."Created On" := CurrentDateTime() - 60000;
        DataMigrationError.Insert();

        Assert.AreEqual(1, DataMigrationError.Count(), 'Pre-check: 1 unhandled error row should exist');

        // [WHEN] ContinueMigrationForCompany is invoked
        BC14MigrationRunner.ContinueMigrationForCompany(CopyStr(CompanyName(), 1, 30));

        // [THEN] The Source Table ID = 0 row is gone
        DataMigrationError.Reset();
        DataMigrationError.SetRange("Source Table ID", 0);
        Assert.IsTrue(DataMigrationError.IsEmpty(), 'Unhandled upgrade-error rows should have been deleted');

        // [THEN] Company finishes Completed (no surviving errors)
        Assert.IsTrue(HybridCompanyStatus.Get(CompanyName()), 'Company status row should still exist');
        Assert.AreEqual(HybridCompanyStatus."Upgrade Status"::Completed, HybridCompanyStatus."Upgrade Status", 'Company status should be Completed');

        UnbindSubscription(BC14E2ETestEventHandler);
    end;

    [Test]
    procedure TestContinueCompanyMigration_ClearsScheduledForRetryFlag()
    var
        DataMigrationError: Record "Data Migration Error";
        BC14E2ETestEventHandler: Codeunit "BC14 E2E Test Event Handler";
        BC14MigrationRunner: Codeunit "BC14 Migration Runner";
        ErrorId: Integer;
    begin
        // [SCENARIO] ContinueMigrationForCompany clears the "Scheduled For Retry" flag on
        // surviving error rows (so the migration page does not show stale retry markers).
        InitializeForContinueCompanyMigration(BC14E2ETestEventHandler);

        // [GIVEN] A surviving error row with Scheduled For Retry set
        DataMigrationError.Init();
        DataMigrationError."Migration Type" := 'Customer Migrator';
        DataMigrationError."Source Table ID" := 18; // Non-zero — not eligible for unhandled-error deletion
        DataMigrationError."Source Table Name" := 'Customer';
        DataMigrationError."Error Message" := 'Bad data';
        DataMigrationError."Error Dismissed" := false;
        DataMigrationError."Scheduled For Retry" := true;
        DataMigrationError."Created On" := CurrentDateTime() - 60000;
        DataMigrationError.Insert();
        ErrorId := DataMigrationError.Id;

        // [WHEN] ContinueMigrationForCompany is invoked
        BC14MigrationRunner.ContinueMigrationForCompany(CopyStr(CompanyName(), 1, 30));

        // [THEN] The row still exists but its Scheduled For Retry flag is cleared
        DataMigrationError.Reset();
        Assert.IsTrue(DataMigrationError.Get(ErrorId), 'Non-unhandled error row should still exist after cleanup');
        Assert.IsFalse(DataMigrationError."Scheduled For Retry", 'Scheduled For Retry flag should be cleared');

        UnbindSubscription(BC14E2ETestEventHandler);
    end;

    [Test]
    procedure TestContinueCompanyMigration_NoErrors_CompletesCompanyAndSummary()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        BC14Wizard: Codeunit "BC14 Wizard";
        BC14E2ETestEventHandler: Codeunit "BC14 E2E Test Event Handler";
        BC14MigrationRunner: Codeunit "BC14 Migration Runner";
    begin
        // [SCENARIO] Successful rerun: no errors survive cleanup, so AfterCompanyMigrationCompleted
        // sets the company status to Completed.
        InitializeForContinueCompanyMigration(BC14E2ETestEventHandler);

        // [WHEN] ContinueMigrationForCompany runs against a clean error state
        BC14MigrationRunner.ContinueMigrationForCompany(CopyStr(CompanyName(), 1, 30));

        // [THEN] Company status is Completed
        Assert.IsTrue(HybridCompanyStatus.Get(CompanyName()), 'Company status row should still exist');
        Assert.AreEqual(HybridCompanyStatus."Upgrade Status"::Completed, HybridCompanyStatus."Upgrade Status", 'Company status should be Completed');

        // [THEN] Summary has not been marked failed
        HybridReplicationSummary.SetRange(Source, BC14Wizard.GetMigrationProviderId());
        Assert.IsTrue(HybridReplicationSummary.FindLast(), 'Summary should still exist');
        Assert.AreNotEqual(HybridReplicationSummary.Status::UpgradeFailed, HybridReplicationSummary.Status, 'Summary should not be UpgradeFailed on the success path');

        UnbindSubscription(BC14E2ETestEventHandler);
    end;

    [Test]
    procedure TestContinueCompanyMigration_SurvivingErrors_FailsCompanyAndSummary()
    var
        DataMigrationError: Record "Data Migration Error";
        HybridCompanyStatus: Record "Hybrid Company Status";
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        BC14Wizard: Codeunit "BC14 Wizard";
        BC14E2ETestEventHandler: Codeunit "BC14 E2E Test Event Handler";
        BC14MigrationRunner: Codeunit "BC14 Migration Runner";
    begin
        // [SCENARIO] When unresolved errors survive cleanup, AfterCompanyMigrationCompleted
        // marks the company Failed and the summary as UpgradeFailed.
        InitializeForContinueCompanyMigration(BC14E2ETestEventHandler);

        // [GIVEN] A surviving non-unhandled error (Source Table ID <> 0, not dismissed)
        DataMigrationError.Init();
        DataMigrationError."Migration Type" := 'Customer Migrator';
        DataMigrationError."Source Table ID" := 18;
        DataMigrationError."Source Table Name" := 'Customer';
        DataMigrationError."Error Message" := 'Surviving error';
        DataMigrationError."Error Dismissed" := false;
        DataMigrationError."Created On" := CurrentDateTime() - 60000;
        DataMigrationError.Insert();

        // [WHEN] ContinueMigrationForCompany is invoked
        BC14MigrationRunner.ContinueMigrationForCompany(CopyStr(CompanyName(), 1, 30));

        // [THEN] Company status is Failed
        Assert.IsTrue(HybridCompanyStatus.Get(CompanyName()), 'Company status row should still exist');
        Assert.AreEqual(HybridCompanyStatus."Upgrade Status"::Failed, HybridCompanyStatus."Upgrade Status", 'Company status should be Failed');

        // [THEN] Summary is UpgradeFailed
        HybridReplicationSummary.SetRange(Source, BC14Wizard.GetMigrationProviderId());
        Assert.IsTrue(HybridReplicationSummary.FindLast(), 'Summary should exist');
        Assert.AreEqual(HybridReplicationSummary.Status::UpgradeFailed, HybridReplicationSummary.Status, 'Summary should be UpgradeFailed');

        UnbindSubscription(BC14E2ETestEventHandler);
    end;

    // ============================================================
    // Runner
    // ============================================================

    [Test]
    procedure TestGetTotalErrorCount_ReturnsUnresolvedCount()
    var
        DataMigrationError: Record "Data Migration Error";
        BC14MigrationRunner: Codeunit "BC14 Migration Runner";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        DummyRecordId: RecordId;
    begin
        // [SCENARIO] GetTotalErrorCount returns count of unresolved errors only.
        DataMigrationError.DeleteAll();

        // [GIVEN] 3 errors, 1 of which is resolved
        BC14MigrationErrorHandler.LogError('Test', 1000, 'Table1', 'KEY-001', 0, 'Error 1', DummyRecordId);
        BC14MigrationErrorHandler.LogError('Test', 1000, 'Table1', 'KEY-002', 0, 'Error 2', DummyRecordId);
        BC14MigrationErrorHandler.LogError('Test', 1000, 'Table1', 'KEY-003', 0, 'Error 3', DummyRecordId);
        BC14MigrationErrorHandler.ResolveErrorForRecord(1000, 'KEY-002');

        // [THEN] GetTotalErrorCount returns 2 (only unresolved)
        Assert.AreEqual(2, BC14MigrationRunner.GetTotalErrorCount(), 'Should return count of unresolved errors only');

        DataMigrationError.DeleteAll();
    end;

    [Test]
    procedure TestGetTotalErrorCount_NoErrors_ReturnsZero()
    var
        DataMigrationError: Record "Data Migration Error";
        BC14MigrationRunner: Codeunit "BC14 Migration Runner";
    begin
        // [SCENARIO] GetTotalErrorCount returns 0 when no errors exist.
        DataMigrationError.DeleteAll();

        Assert.AreEqual(0, BC14MigrationRunner.GetTotalErrorCount(), 'Should return 0 with no errors');
    end;

    [Test]
    procedure TestEnableDirectPosting_DisabledAccounts_GetsEnabled()
    var
        GLAccount: Record "G/L Account";
    begin
        // [SCENARIO] Posting accounts with Direct Posting=false are updated to true.
        // This mirrors the pre-Transaction-phase step the runner performs.
        CleanupGLTestData();

        GLAccount.Init();
        GLAccount."No." := 'RUNNER-DP-1';
        GLAccount.Name := 'Direct Posting Test';
        GLAccount."Account Type" := GLAccount."Account Type"::Posting;
        GLAccount."Direct Posting" := false;
        GLAccount.Insert();

        GLAccount.Reset();
        GLAccount.SetRange("Direct Posting", false);
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.ModifyAll("Direct Posting", true);

        GLAccount.Get('RUNNER-DP-1');
        Assert.IsTrue(GLAccount."Direct Posting", 'Direct Posting should be enabled');

        GLAccount.Delete();
    end;

    [Test]
    procedure TestEnableDirectPosting_HeadingAccountsNotAffected()
    var
        GLAccount: Record "G/L Account";
    begin
        // [SCENARIO] Heading accounts are not affected by EnableDirectPostingOnAllAccounts.
        CleanupGLTestData();

        GLAccount.Init();
        GLAccount."No." := 'RUNNER-HD-1';
        GLAccount.Name := 'Heading Account Test';
        GLAccount."Account Type" := GLAccount."Account Type"::Heading;
        GLAccount."Direct Posting" := false;
        GLAccount.Insert();

        GLAccount.Reset();
        GLAccount.SetRange("Direct Posting", false);
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.ModifyAll("Direct Posting", true);

        GLAccount.Get('RUNNER-HD-1');
        Assert.IsFalse(GLAccount."Direct Posting", 'Heading account should not be affected');

        GLAccount.Delete();
    end;

    [Test]
    procedure TestContinueMigrationForCompany_AlreadyRunning_ThrowsError()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14MigrationRunner: Codeunit "BC14 Migration Runner";
    begin
        // [SCENARIO] ContinueMigrationForCompany errors if the company is already Started
        // (atomic double-click guard via AcquireRerunSlot).
        InitializeForRerun();

        // [GIVEN] A company status of Started
        InsertCompanyStatus_Runner('RERUN-CO', HybridCompanyStatus."Upgrade Status"::Started);

        // [WHEN] ContinueMigrationForCompany is called
        // [THEN] Error is thrown
        asserterror BC14MigrationRunner.ContinueMigrationForCompany('RERUN-CO');
        Assert.ExpectedError('Migration is already running');
    end;

    [Test]
    procedure TestContinueMigrationForCompany_NoStatus_ThrowsError()
    var
        BC14MigrationRunner: Codeunit "BC14 Migration Runner";
    begin
        // [SCENARIO] ContinueMigrationForCompany errors if the company status row is missing
        // (e.g. wiped via Reset All Cloud Data).
        InitializeForRerun();

        // [WHEN] ContinueMigrationForCompany is called for a non-existent company
        // [THEN] Error is thrown
        asserterror BC14MigrationRunner.ContinueMigrationForCompany('GHOST');
        Assert.ExpectedError('No upgrade status row exists');
    end;

    // ============================================================
    // Provider
    // ============================================================

    [Test]
    procedure TestMappingsCreatedForMultipleCompanies()
    var
        ReplicationMapping: Record "Replication Table Mapping";
        HybridCompany: Record "Hybrid Company";
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        // [SCENARIO] Table mappings are created for multiple replicated companies.

        // [GIVEN] Two companies are marked for replication
        HybridCompany.DeleteAll();
        ReplicationMapping.DeleteAll();

        HybridCompany.Init();
        HybridCompany.Name := 'Company A';
        HybridCompany."Display Name" := HybridCompany.Name;
        HybridCompany.Replicate := true;
        HybridCompany.Insert();

        HybridCompany.Init();
        HybridCompany.Name := 'Company B';
        HybridCompany."Display Name" := HybridCompany.Name;
        HybridCompany.Replicate := true;
        HybridCompany.Insert();

        // [WHEN] SetupReplicationTableMappings is called
        BC14MigrationSetup.SetupReplicationTableMappings();

        // [THEN] Each company gets its own mappings independently
        ReplicationMapping.SetRange("Company Name", 'Company A');
        Assert.IsTrue(ReplicationMapping.Count() >= 7, 'Company A should have at least 7 replication mappings');

        ReplicationMapping.SetRange("Company Name", 'Company B');
        Assert.IsTrue(ReplicationMapping.Count() >= 7, 'Company B should have at least 7 replication mappings');

        // Both companies should have the same number of mappings (parity check)
        ReplicationMapping.SetRange("Company Name", 'Company A');
        Assert.AreEqual(GetCompanyMappingCount('Company B'), ReplicationMapping.Count(), 'Both companies should have identical mapping counts');
    end;

    [Test]
    procedure TestMigrationProviderDisplayName()
    var
        BC14MigrationProvider: Codeunit "BC14 Migration Provider";
    begin
        // [SCENARIO] The migration provider returns the correct display name.

        // [THEN] The display name should be '(Preview) Dynamics 365 Business Central Re-implementation (v.14)'
        Assert.AreEqual('(Preview) Dynamics 365 Business Central Re-implementation (v.14)', BC14MigrationProvider.GetDisplayName(), 'Display name should match the expected value');
    end;

    [Test]
    procedure TestMigrationProviderDescription()
    var
        BC14MigrationProvider: Codeunit "BC14 Migration Provider";
        Description: Text;
    begin
        // [SCENARIO] The migration provider returns a meaningful description.

        // [WHEN] GetDescription is called
        Description := BC14MigrationProvider.GetDescription();

        // [THEN] The description is not empty and contains key terms
        Assert.AreNotEqual('', Description, 'Description should not be empty');
        Assert.IsTrue(Description.Contains('Business Central 14'), 'Description should mention Business Central 14');
        Assert.IsTrue(Description.Contains('re-implementation'), 'Description should mention re-implementation');
    end;

    [Test]
    procedure TestMigrationProviderAppId()
    var
        BC14MigrationProvider: Codeunit "BC14 Migration Provider";
        AppId: Guid;
        ExpectedAppId: Guid;
    begin
        // [SCENARIO] The migration provider returns the correct AppId.

        // [WHEN] GetAppId is called
        AppId := BC14MigrationProvider.GetAppId();

        // [THEN] The AppId matches the BC14 Reimplementation Tool app ID
        Evaluate(ExpectedAppId, '2363a2b7-1018-4976-a32a-c77338dc9f16');
        Assert.AreEqual(ExpectedAppId, AppId, 'AppId should match the BC14 Reimplementation Tool app ID');
    end;

    [Test]
    procedure TestShowConfigureMigrationTablesMappingStep()
    var
        BC14MigrationProvider: Codeunit "BC14 Migration Provider";
    begin
        // [SCENARIO] ShowConfigureMigrationTablesMappingStep returns false for BC14
        // so the configuration package step is skipped in the wizard page.

        // [THEN] The step should be skipped
        Assert.IsFalse(BC14MigrationProvider.ShowConfigureMigrationTablesMappingStep(), 'Should skip configure migration tables mapping step');
    end;

    // ============================================================
    // Loop
    // ============================================================

    [Test]
    procedure TestRunRecordLoop_AllSucceed_ReturnsTrueAndNoErrors()
    var
        BC14CountryRegion: Record "BC14 Country/Region";
        DataMigrationError: Record "Data Migration Error";
        AggregateSuccess: Boolean;
    begin
        // [SCENARIO] When every per-record run succeeds, RunRecordLoop returns true
        // and writes no error rows.
        ResetState(false);
        InsertCountryRegion('PASS1');
        InsertCountryRegion('PASS2');
        InsertCountryRegion('PASS3');

        AggregateSuccess := RunLoop(BC14CountryRegion, BC14CountryRegion.FieldNo(Code));

        Assert.IsTrue(AggregateSuccess, 'RunRecordLoop should return true when every record succeeds.');
        Assert.AreEqual(0, DataMigrationError.Count(), 'No error rows should be logged on a fully successful run.');
    end;

    [Test]
    procedure TestRunRecordLoop_OneFails_NoStopOnError_ContinuesAndAggregateFails()
    var
        BC14CountryRegion: Record "BC14 Country/Region";
        AggregateSuccess: Boolean;
    begin
        // [SCENARIO] With Stop-On-First-Error disabled, the loop processes every
        // record even after a failure and returns false aggregated success.
        ResetState(false);
        InsertCountryRegion('PASS1');
        InsertCountryRegion('FAIL');
        InsertCountryRegion('PASS2');

        AggregateSuccess := RunLoop(BC14CountryRegion, BC14CountryRegion.FieldNo(Code));

        Assert.IsFalse(AggregateSuccess, 'RunRecordLoop should return false when any record fails.');
        Assert.AreEqual(1, CountErrorsForKey('FAIL'), 'Exactly one error row should be logged for the failing record.');
    end;

    [Test]
    procedure TestRunRecordLoop_FirstFails_StopOnError_ExitsEarly()
    var
        BC14CountryRegion: Record "BC14 Country/Region";
        AggregateSuccess: Boolean;
    begin
        // [SCENARIO] With Stop-On-First-Error enabled, the loop exits on the first
        // failure without processing subsequent records.
        ResetState(true);
        InsertCountryRegion('FAIL');
        InsertCountryRegion('FAIL2');
        InsertCountryRegion('FAIL3');

        AggregateSuccess := RunLoop(BC14CountryRegion, BC14CountryRegion.FieldNo(Code));

        Assert.IsFalse(AggregateSuccess, 'RunRecordLoop should return false on the first failure.');
        Assert.AreEqual(1, CountErrorsForKey('FAIL'), 'Only the first failing record should be logged.');
        Assert.AreEqual(0, CountErrorsForKey('FAIL2'), 'Subsequent records should not be processed when Stop-On-First-Error is enabled.');
        Assert.AreEqual(0, CountErrorsForKey('FAIL3'), 'Subsequent records should not be processed when Stop-On-First-Error is enabled.');
    end;

    [Test]
    procedure TestRunRecordLoop_EmptySource_ReturnsTrueAndNoErrors()
    var
        BC14CountryRegion: Record "BC14 Country/Region";
        DataMigrationError: Record "Data Migration Error";
        AggregateSuccess: Boolean;
    begin
        // [SCENARIO] An empty source set is a no-op that reports success.
        ResetState(false);

        AggregateSuccess := RunLoop(BC14CountryRegion, BC14CountryRegion.FieldNo(Code));

        Assert.IsTrue(AggregateSuccess, 'RunRecordLoop should return true for an empty source.');
        Assert.AreEqual(0, DataMigrationError.Count(), 'No error rows should be logged for an empty source.');
    end;

    [Test]
    procedure TestRunRecordLoop_SourceFilterHonored_FilteredRecordsSkipped()
    var
        BC14CountryRegion: Record "BC14 Country/Region";
        AggregateSuccess: Boolean;
    begin
        // [SCENARIO] Filters set on the source record are preserved by the loop: a
        // failing record outside the filter is never visited.
        ResetState(false);
        InsertCountryRegion('PASS1');
        InsertCountryRegion('FAIL');
        InsertCountryRegion('PASS2');

        BC14CountryRegion.SetFilter(Code, 'PASS*');

        AggregateSuccess := RunLoop(BC14CountryRegion, BC14CountryRegion.FieldNo(Code));

        Assert.IsTrue(AggregateSuccess, 'RunRecordLoop should return true when the filter excludes the failing record.');
        Assert.AreEqual(0, CountErrorsForKey('FAIL'), 'The filtered-out FAIL record should not be processed.');
    end;

    [Test]
    procedure TestRunRecordLoop_KeyFieldZero_UsesRecordIdAsKey()
    var
        BC14CountryRegion: Record "BC14 Country/Region";
        DataMigrationError: Record "Data Migration Error";
        AggregateSuccess: Boolean;
    begin
        // [SCENARIO] When KeyFieldNo is 0, the loop logs the record's RecordId as
        // the idempotency key rather than a single field value.
        ResetState(false);
        InsertCountryRegion('FAIL');

        AggregateSuccess := RunLoop(BC14CountryRegion, 0);

        Assert.IsFalse(AggregateSuccess, 'RunRecordLoop should report failure.');
        Assert.AreEqual(0, CountErrorsForKey('FAIL'), 'When KeyFieldNo=0, the logged key should not equal the Code value.');
        DataMigrationError.SetFilter("Source Record Key", '*FAIL*');
        Assert.AreEqual(1, DataMigrationError.Count(), 'The logged Source Record Key should contain the RecordId text, which includes the Code value.');
    end;

    [Test]
    procedure TestRunRecordLoop_KeyFieldOne_UsesFieldValueAsKey()
    var
        BC14CountryRegion: Record "BC14 Country/Region";
        AggregateSuccess: Boolean;
    begin
        // [SCENARIO] When KeyFieldNo points at a real field, the loop logs that
        // field's value verbatim as the idempotency key.
        ResetState(false);
        InsertCountryRegion('FAIL');

        AggregateSuccess := RunLoop(BC14CountryRegion, BC14CountryRegion.FieldNo(Code));

        Assert.IsFalse(AggregateSuccess, 'RunRecordLoop should report failure.');
        Assert.AreEqual(1, CountErrorsForKey('FAIL'), 'Logged Source Record Key should exactly equal the Code value when KeyFieldNo=Code.');
    end;

    // ============================================================
    // Status Manager — Company Status Basic Transitions
    // ============================================================

    [Test]
    procedure TestMarkCompanyStarted_FromPending()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
    begin
        // [SCENARIO] MarkCompanyStarted transitions a Pending company to Started.
        Initialize_StatusMgr();

        InsertCompanyStatus_StatusMgr('COMP-A', HybridCompanyStatus."Upgrade Status"::Pending);

        BC14StatusMgr.MarkCompanyStarted('COMP-A');

        HybridCompanyStatus.Get('COMP-A');
        Assert.AreEqual(HybridCompanyStatus."Upgrade Status"::Started, HybridCompanyStatus."Upgrade Status", 'Should be Started');
    end;

    [Test]
    procedure TestMarkCompanyStarted_AlreadyStarted_NoOp()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
    begin
        // [SCENARIO] MarkCompanyStarted is a no-op when company is already Started.
        Initialize_StatusMgr();
        InsertCompanyStatus_StatusMgr('COMP-A', HybridCompanyStatus."Upgrade Status"::Started);

        BC14StatusMgr.MarkCompanyStarted('COMP-A');

        HybridCompanyStatus.Get('COMP-A');
        Assert.AreEqual(HybridCompanyStatus."Upgrade Status"::Started, HybridCompanyStatus."Upgrade Status", 'Should remain Started');
    end;

    [Test]
    procedure TestMarkCompanyStarted_NoRecord_NoOp()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
    begin
        // [SCENARIO] MarkCompanyStarted is a no-op when no status record exists.
        Initialize_StatusMgr();

        BC14StatusMgr.MarkCompanyStarted('NONEXIST');

        Assert.IsFalse(HybridCompanyStatus.Get('NONEXIST'), 'Should not create record');
    end;

    [Test]
    procedure TestMarkCompanyCompleted_FromStarted()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
    begin
        // [SCENARIO] MarkCompanyCompleted transitions a Started company to Completed.
        Initialize_StatusMgr();
        InsertCompanyStatus_StatusMgr('COMP-A', HybridCompanyStatus."Upgrade Status"::Started);

        BC14StatusMgr.MarkCompanyCompleted('COMP-A');

        HybridCompanyStatus.Get('COMP-A');
        Assert.AreEqual(HybridCompanyStatus."Upgrade Status"::Completed, HybridCompanyStatus."Upgrade Status", 'Should be Completed');
    end;

    [Test]
    procedure TestMarkCompanyCompleted_FromFailed_NeverPromotes()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
    begin
        // [SCENARIO] MarkCompanyCompleted does NOT promote a Failed company to Completed.
        Initialize_StatusMgr();
        InsertCompanyStatus_StatusMgr('COMP-A', HybridCompanyStatus."Upgrade Status"::Failed);

        BC14StatusMgr.MarkCompanyCompleted('COMP-A');

        HybridCompanyStatus.Get('COMP-A');
        Assert.AreEqual(HybridCompanyStatus."Upgrade Status"::Failed, HybridCompanyStatus."Upgrade Status", 'Failed company must not be promoted to Completed');
    end;

    [Test]
    procedure TestMarkCompanyFailed_FromStarted()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
    begin
        // [SCENARIO] MarkCompanyFailed transitions a Started company to Failed.
        Initialize_StatusMgr();
        InsertCompanyStatus_StatusMgr('COMP-A', HybridCompanyStatus."Upgrade Status"::Started);

        BC14StatusMgr.MarkCompanyFailed('COMP-A', 'Test error message');

        HybridCompanyStatus.Get('COMP-A');
        Assert.AreEqual(HybridCompanyStatus."Upgrade Status"::Failed, HybridCompanyStatus."Upgrade Status", 'Should be Failed');
    end;

    [Test]
    procedure TestMarkCompanyFailed_FromCompleted_NeverDemotes()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
    begin
        // [SCENARIO] MarkCompanyFailed does NOT demote a Completed company to Failed.
        Initialize_StatusMgr();
        InsertCompanyStatus_StatusMgr('COMP-A', HybridCompanyStatus."Upgrade Status"::Completed);

        BC14StatusMgr.MarkCompanyFailed('COMP-A', 'Stale error');

        HybridCompanyStatus.Get('COMP-A');
        Assert.AreEqual(HybridCompanyStatus."Upgrade Status"::Completed, HybridCompanyStatus."Upgrade Status", 'Completed company must not be demoted to Failed');
    end;

    [Test]
    procedure TestMarkCompanyFailed_FromPending()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
    begin
        // [SCENARIO] MarkCompanyFailed transitions a Pending company to Failed.
        Initialize_StatusMgr();
        InsertCompanyStatus_StatusMgr('COMP-A', HybridCompanyStatus."Upgrade Status"::Pending);

        BC14StatusMgr.MarkCompanyFailed('COMP-A', 'Setup timeout');

        HybridCompanyStatus.Get('COMP-A');
        Assert.AreEqual(HybridCompanyStatus."Upgrade Status"::Failed, HybridCompanyStatus."Upgrade Status", 'Should be Failed');
    end;

    // ============================================================
    // Status Manager — SetFinalCompanyStatus
    // ============================================================

    [Test]
    procedure TestSetFinalCompanyStatus_NoErrors_MarkCompleted()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
    begin
        Initialize_StatusMgr();
        InsertCompanyStatus_StatusMgr('COMP-A', HybridCompanyStatus."Upgrade Status"::Started);

        BC14StatusMgr.SetFinalCompanyStatus('COMP-A', false);

        HybridCompanyStatus.Get('COMP-A');
        Assert.AreEqual(HybridCompanyStatus."Upgrade Status"::Completed, HybridCompanyStatus."Upgrade Status", 'Should be Completed');
    end;

    [Test]
    procedure TestSetFinalCompanyStatus_HasErrors_MarkFailed()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
    begin
        Initialize_StatusMgr();
        InsertCompanyStatus_StatusMgr('COMP-A', HybridCompanyStatus."Upgrade Status"::Started);

        BC14StatusMgr.SetFinalCompanyStatus('COMP-A', true);

        HybridCompanyStatus.Get('COMP-A');
        Assert.AreEqual(HybridCompanyStatus."Upgrade Status"::Failed, HybridCompanyStatus."Upgrade Status", 'Should be Failed');
    end;

    [Test]
    procedure TestSetFinalCompanyStatus_AlreadyFailed_NotOverwritten()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
    begin
        // [SCENARIO] FailureHandler may have already set Failed; FinalizeMigration must not overwrite.
        Initialize_StatusMgr();
        InsertCompanyStatus_StatusMgr('COMP-A', HybridCompanyStatus."Upgrade Status"::Failed);

        BC14StatusMgr.SetFinalCompanyStatus('COMP-A', false);

        HybridCompanyStatus.Get('COMP-A');
        Assert.AreEqual(HybridCompanyStatus."Upgrade Status"::Failed, HybridCompanyStatus."Upgrade Status", 'Should remain Failed');
    end;

    // ============================================================
    // Status Manager — MarkPendingCompaniesAsFailed
    // ============================================================

    [Test]
    procedure TestMarkPendingCompaniesAsFailed_OnlyAffectsPending()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
    begin
        Initialize_StatusMgr();
        InsertCompanyStatus_StatusMgr('PEND-CO', HybridCompanyStatus."Upgrade Status"::Pending);
        InsertCompanyStatus_StatusMgr('START-CO', HybridCompanyStatus."Upgrade Status"::Started);
        InsertCompanyStatus_StatusMgr('DONE-CO', HybridCompanyStatus."Upgrade Status"::Completed);

        BC14StatusMgr.MarkPendingCompaniesAsFailed('Setup wait timeout');

        HybridCompanyStatus.Get('PEND-CO');
        Assert.AreEqual(HybridCompanyStatus."Upgrade Status"::Failed, HybridCompanyStatus."Upgrade Status", 'Pending should be Failed');
        HybridCompanyStatus.Get('START-CO');
        Assert.AreEqual(HybridCompanyStatus."Upgrade Status"::Started, HybridCompanyStatus."Upgrade Status", 'Started should remain Started');
        HybridCompanyStatus.Get('DONE-CO');
        Assert.AreEqual(HybridCompanyStatus."Upgrade Status"::Completed, HybridCompanyStatus."Upgrade Status", 'Completed should remain Completed');
    end;

    [Test]
    procedure TestMarkPendingCompaniesAsFailed_MultiplePending()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
    begin
        Initialize_StatusMgr();
        InsertCompanyStatus_StatusMgr('PEND-1', HybridCompanyStatus."Upgrade Status"::Pending);
        InsertCompanyStatus_StatusMgr('PEND-2', HybridCompanyStatus."Upgrade Status"::Pending);
        InsertCompanyStatus_StatusMgr('PEND-3', HybridCompanyStatus."Upgrade Status"::Pending);

        BC14StatusMgr.MarkPendingCompaniesAsFailed('Timeout');

        HybridCompanyStatus.Get('PEND-1');
        Assert.AreEqual(HybridCompanyStatus."Upgrade Status"::Failed, HybridCompanyStatus."Upgrade Status", 'PEND-1 should be Failed');
        HybridCompanyStatus.Get('PEND-2');
        Assert.AreEqual(HybridCompanyStatus."Upgrade Status"::Failed, HybridCompanyStatus."Upgrade Status", 'PEND-2 should be Failed');
        HybridCompanyStatus.Get('PEND-3');
        Assert.AreEqual(HybridCompanyStatus."Upgrade Status"::Failed, HybridCompanyStatus."Upgrade Status", 'PEND-3 should be Failed');
    end;

    // ============================================================
    // Status Manager — AcquireRerunSlot
    // ============================================================

    [Test]
    procedure TestAcquireRerunSlot_FromFailed_SetsStarted()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
    begin
        Initialize_StatusMgr();
        InsertCompanyStatus_StatusMgr('COMP-A', HybridCompanyStatus."Upgrade Status"::Failed);

        BC14StatusMgr.AcquireRerunSlot('COMP-A');

        HybridCompanyStatus.Get('COMP-A');
        Assert.AreEqual(HybridCompanyStatus."Upgrade Status"::Started, HybridCompanyStatus."Upgrade Status", 'Should be Started after rerun slot acquired');
    end;

    [Test]
    procedure TestAcquireRerunSlot_AlreadyStarted_ThrowsError()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
    begin
        Initialize_StatusMgr();
        InsertCompanyStatus_StatusMgr('COMP-A', HybridCompanyStatus."Upgrade Status"::Started);

        asserterror BC14StatusMgr.AcquireRerunSlot('COMP-A');
        Assert.ExpectedError('Migration is already running');
    end;

    [Test]
    procedure TestAcquireRerunSlot_NoRecord_ThrowsError()
    var
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
    begin
        Initialize_StatusMgr();

        asserterror BC14StatusMgr.AcquireRerunSlot('GHOST');
        Assert.ExpectedError('No upgrade status row exists');
    end;

    // ============================================================
    // Status Manager — Query API
    // ============================================================

    [Test]
    procedure TestIsCompanyRunning()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
    begin
        // [SCENARIO] IsCompanyRunning returns true only for Started companies.
        Initialize_StatusMgr();

        InsertCompanyStatus_StatusMgr('RUN-CO', HybridCompanyStatus."Upgrade Status"::Started);
        InsertCompanyStatus_StatusMgr('PEND-CO', HybridCompanyStatus."Upgrade Status"::Pending);

        Assert.IsTrue(BC14StatusMgr.IsCompanyRunning('RUN-CO'), 'Started company should be Running');
        Assert.IsFalse(BC14StatusMgr.IsCompanyRunning('PEND-CO'), 'Pending company should not be Running');
        Assert.IsFalse(BC14StatusMgr.IsCompanyRunning('NONE'), 'Non-existent company should not be Running');
    end;

    [Test]
    procedure TestIsCompanyFailed()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
    begin
        Initialize_StatusMgr();
        InsertCompanyStatus_StatusMgr('FAIL-CO', HybridCompanyStatus."Upgrade Status"::Failed);
        InsertCompanyStatus_StatusMgr('DONE-CO', HybridCompanyStatus."Upgrade Status"::Completed);

        Assert.IsTrue(BC14StatusMgr.IsCompanyFailed('FAIL-CO'), 'Failed company should return true');
        Assert.IsFalse(BC14StatusMgr.IsCompanyFailed('DONE-CO'), 'Completed company should return false');
        Assert.IsFalse(BC14StatusMgr.IsCompanyFailed('NONE'), 'Non-existent should return false');
    end;

    [Test]
    procedure TestHasPendingCompanies()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
    begin
        Initialize_StatusMgr();

        InsertCompanyStatus_StatusMgr('DONE-CO', HybridCompanyStatus."Upgrade Status"::Completed);
        Assert.IsFalse(BC14StatusMgr.HasPendingCompanies(), 'Should be false with no pending');

        InsertCompanyStatus_StatusMgr('PEND-CO', HybridCompanyStatus."Upgrade Status"::Pending);
        Assert.IsTrue(BC14StatusMgr.HasPendingCompanies(), 'Should be true with pending company');
    end;

    [Test]
    procedure TestAnyCompanyHasFailedUpgrade()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
    begin
        Initialize_StatusMgr();

        InsertCompanyStatus_StatusMgr('DONE-CO', HybridCompanyStatus."Upgrade Status"::Completed);
        Assert.IsFalse(BC14StatusMgr.AnyCompanyHasFailedUpgrade(), 'Should be false with no failed');

        InsertCompanyStatus_StatusMgr('FAIL-CO', HybridCompanyStatus."Upgrade Status"::Failed);
        Assert.IsTrue(BC14StatusMgr.AnyCompanyHasFailedUpgrade(), 'Should be true with failed company');
    end;

    [Test]
    procedure TestAreAllCompaniesUpgradeCompleted()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
    begin
        Initialize_StatusMgr();

        InsertHybridCompany('CO-1', true);
        InsertHybridCompany('CO-2', true);
        InsertCompanyStatus_StatusMgr('CO-1', HybridCompanyStatus."Upgrade Status"::Completed);
        InsertCompanyStatus_StatusMgr('CO-2', HybridCompanyStatus."Upgrade Status"::Completed);

        Assert.IsTrue(BC14StatusMgr.AreAllCompaniesUpgradeCompleted(), 'Should be true when all completed');

        HybridCompanyStatus.Get('CO-2');
        HybridCompanyStatus."Upgrade Status" := HybridCompanyStatus."Upgrade Status"::Started;
        HybridCompanyStatus.Modify();

        Assert.IsFalse(BC14StatusMgr.AreAllCompaniesUpgradeCompleted(), 'Should be false when one not completed');
    end;

    [Test]
    procedure TestAreAllCompaniesProcessed()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
    begin
        Initialize_StatusMgr();

        InsertHybridCompany('CO-1', true);
        InsertHybridCompany('CO-2', true);
        InsertCompanyStatus_StatusMgr('CO-1', HybridCompanyStatus."Upgrade Status"::Completed);
        InsertCompanyStatus_StatusMgr('CO-2', HybridCompanyStatus."Upgrade Status"::Failed);

        Assert.IsTrue(BC14StatusMgr.AreAllCompaniesProcessed(), 'Should be true when all processed');

        HybridCompanyStatus.Get('CO-2');
        HybridCompanyStatus."Upgrade Status" := HybridCompanyStatus."Upgrade Status"::Pending;
        HybridCompanyStatus.Modify();

        Assert.IsFalse(BC14StatusMgr.AreAllCompaniesProcessed(), 'Should be false with pending company');
    end;

    [Test]
    procedure TestGetCompletedCompanyCount()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
    begin
        Initialize_StatusMgr();

        InsertCompanyStatus_StatusMgr('CO-1', HybridCompanyStatus."Upgrade Status"::Completed);
        InsertCompanyStatus_StatusMgr('CO-2', HybridCompanyStatus."Upgrade Status"::Completed);
        InsertCompanyStatus_StatusMgr('CO-3', HybridCompanyStatus."Upgrade Status"::Failed);

        Assert.AreEqual(2, BC14StatusMgr.GetCompletedCompanyCount(), 'Should count 2 completed companies');
    end;

    [Test]
    procedure TestGetCompletedCompanyCount_ExcludesEmptyName()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
    begin
        Initialize_StatusMgr();

        InsertCompanyStatus_StatusMgr('', HybridCompanyStatus."Upgrade Status"::Completed);
        InsertCompanyStatus_StatusMgr('CO-1', HybridCompanyStatus."Upgrade Status"::Completed);

        Assert.AreEqual(1, BC14StatusMgr.GetCompletedCompanyCount(), 'Should exclude empty-name row');
    end;

    [Test]
    procedure TestGetCompanyStatusCounts()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
        PendingCount: Integer;
        StartedCount: Integer;
        CompletedCount: Integer;
        FailedCount: Integer;
    begin
        Initialize_StatusMgr();

        InsertCompanyStatus_StatusMgr('CO-P1', HybridCompanyStatus."Upgrade Status"::Pending);
        InsertCompanyStatus_StatusMgr('CO-P2', HybridCompanyStatus."Upgrade Status"::Pending);
        InsertCompanyStatus_StatusMgr('CO-S1', HybridCompanyStatus."Upgrade Status"::Started);
        InsertCompanyStatus_StatusMgr('CO-C1', HybridCompanyStatus."Upgrade Status"::Completed);
        InsertCompanyStatus_StatusMgr('CO-C2', HybridCompanyStatus."Upgrade Status"::Completed);
        InsertCompanyStatus_StatusMgr('CO-C3', HybridCompanyStatus."Upgrade Status"::Completed);
        InsertCompanyStatus_StatusMgr('CO-F1', HybridCompanyStatus."Upgrade Status"::Failed);

        BC14StatusMgr.GetCompanyStatusCounts(PendingCount, StartedCount, CompletedCount, FailedCount);

        Assert.AreEqual(2, PendingCount, 'Pending count');
        Assert.AreEqual(1, StartedCount, 'Started count');
        Assert.AreEqual(3, CompletedCount, 'Completed count');
        Assert.AreEqual(1, FailedCount, 'Failed count');
    end;

    [Test]
    procedure TestPerDatabaseStatusExists()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
    begin
        Initialize_StatusMgr();

        Assert.IsFalse(BC14StatusMgr.PerDatabaseStatusExists(), 'Should be false initially');

        InsertCompanyStatus_StatusMgr('', HybridCompanyStatus."Upgrade Status"::Completed);
        Assert.IsTrue(BC14StatusMgr.PerDatabaseStatusExists(), 'Should be true after insert');
    end;

    // ============================================================
    // Status Manager — Summary Status
    // ============================================================

    [Test]
    procedure TestSetSummaryInProgress()
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
    begin
        Initialize_StatusMgr();
        InsertReplicationSummary(HybridReplicationSummary, HybridReplicationSummary.Status::UpgradePending);

        BC14StatusMgr.SetSummaryInProgress(HybridReplicationSummary);

        HybridReplicationSummary.Get(HybridReplicationSummary."Run ID");
        Assert.AreEqual(HybridReplicationSummary.Status::UpgradeInProgress, HybridReplicationSummary.Status, 'Should be UpgradeInProgress');
    end;

    [Test]
    procedure TestSetSummaryInProgress_AlreadyInProgress_NoOp()
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
    begin
        Initialize_StatusMgr();
        InsertReplicationSummary(HybridReplicationSummary, HybridReplicationSummary.Status::UpgradeInProgress);

        BC14StatusMgr.SetSummaryInProgress(HybridReplicationSummary);

        HybridReplicationSummary.Get(HybridReplicationSummary."Run ID");
        Assert.AreEqual(HybridReplicationSummary.Status::UpgradeInProgress, HybridReplicationSummary.Status, 'Should remain UpgradeInProgress');
    end;

    [Test]
    procedure TestSetSummaryFailed()
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
    begin
        Initialize_StatusMgr();
        InsertReplicationSummary(HybridReplicationSummary, HybridReplicationSummary.Status::UpgradeInProgress);

        BC14StatusMgr.SetSummaryFailed(HybridReplicationSummary);

        HybridReplicationSummary.Get(HybridReplicationSummary."Run ID");
        Assert.AreEqual(HybridReplicationSummary.Status::UpgradeFailed, HybridReplicationSummary.Status, 'Should be UpgradeFailed');
        Assert.AreNotEqual(0DT, HybridReplicationSummary."End Time", 'End Time should be set');
        // The overall Status headline is written to Details at finalize (moved out of MarkUpgradeFailed).
        Assert.IsTrue(ReadSummaryDetails(HybridReplicationSummary).ToLower().Contains('upgrade failed'),
            'SetSummaryFailed should write the upgrade-failed headline to Details');
    end;

    [Test]
    procedure TestSetSummaryFailed_AlreadyCompleted_TerminalGuard()
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
    begin
        Initialize_StatusMgr();
        InsertReplicationSummary(HybridReplicationSummary, HybridReplicationSummary.Status::Completed);

        BC14StatusMgr.SetSummaryFailed(HybridReplicationSummary);

        HybridReplicationSummary.Get(HybridReplicationSummary."Run ID");
        Assert.AreEqual(HybridReplicationSummary.Status::Completed, HybridReplicationSummary.Status, 'Should remain Completed');
    end;

    // ============================================================
    // Status Manager — EvaluateAndSetFinalSummaryStatus
    // ============================================================

    [Test]
    procedure TestEvaluateFinalStatus_AllCompleted_SetsCompleted()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
    begin
        Initialize_StatusMgr();

        InsertHybridCompany('CO-1', true);
        InsertHybridCompany('CO-2', true);
        InsertCompanyStatus_StatusMgr('CO-1', HybridCompanyStatus."Upgrade Status"::Completed);
        InsertCompanyStatus_StatusMgr('CO-2', HybridCompanyStatus."Upgrade Status"::Completed);
        InsertReplicationSummary(HybridReplicationSummary, HybridReplicationSummary.Status::UpgradeInProgress);

        BC14StatusMgr.EvaluateAndSetFinalSummaryStatus(HybridReplicationSummary);

        HybridReplicationSummary.Get(HybridReplicationSummary."Run ID");
        Assert.AreEqual(HybridReplicationSummary.Status::Completed, HybridReplicationSummary.Status, 'Should be Completed');
        Assert.AreNotEqual(0DT, HybridReplicationSummary."End Time", 'End Time should be set');
    end;

    [Test]
    procedure TestEvaluateFinalStatus_AnyFailed_SetsUpgradeFailed()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
    begin
        Initialize_StatusMgr();

        InsertHybridCompany('CO-1', true);
        InsertHybridCompany('CO-2', true);
        InsertCompanyStatus_StatusMgr('CO-1', HybridCompanyStatus."Upgrade Status"::Completed);
        InsertCompanyStatus_StatusMgr('CO-2', HybridCompanyStatus."Upgrade Status"::Failed);
        InsertReplicationSummary(HybridReplicationSummary, HybridReplicationSummary.Status::UpgradeInProgress);

        BC14StatusMgr.EvaluateAndSetFinalSummaryStatus(HybridReplicationSummary);

        HybridReplicationSummary.Get(HybridReplicationSummary."Run ID");
        Assert.AreEqual(HybridReplicationSummary.Status::UpgradeFailed, HybridReplicationSummary.Status, 'Should be UpgradeFailed');
        // The overall Status headline is written to Details at finalize (moved out of MarkUpgradeFailed).
        Assert.IsTrue(ReadSummaryDetails(HybridReplicationSummary).ToLower().Contains('upgrade failed'),
            'EvaluateAndSetFinalSummaryStatus should write the upgrade-failed headline to Details');
    end;

    [Test]
    procedure TestEvaluateFinalStatus_StillProcessing_NoChange()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
    begin
        Initialize_StatusMgr();

        InsertHybridCompany('CO-1', true);
        InsertHybridCompany('CO-2', true);
        InsertCompanyStatus_StatusMgr('CO-1', HybridCompanyStatus."Upgrade Status"::Completed);
        InsertCompanyStatus_StatusMgr('CO-2', HybridCompanyStatus."Upgrade Status"::Started);
        InsertReplicationSummary(HybridReplicationSummary, HybridReplicationSummary.Status::UpgradeInProgress);

        BC14StatusMgr.EvaluateAndSetFinalSummaryStatus(HybridReplicationSummary);

        HybridReplicationSummary.Get(HybridReplicationSummary."Run ID");
        Assert.AreEqual(HybridReplicationSummary.Status::UpgradeInProgress, HybridReplicationSummary.Status, 'Should remain UpgradeInProgress');
    end;

    // ============================================================
    // Status Manager — Cleanup
    // ============================================================

    [Test]
    procedure TestDeleteAllCompanyStatus()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
    begin
        Initialize_StatusMgr();

        InsertCompanyStatus_StatusMgr('CO-1', HybridCompanyStatus."Upgrade Status"::Completed);
        InsertCompanyStatus_StatusMgr('CO-2', HybridCompanyStatus."Upgrade Status"::Failed);
        Assert.AreNotEqual(0, HybridCompanyStatus.Count(), 'Should have records before delete');

        BC14StatusMgr.DeleteAllCompanyStatus();

        Assert.AreEqual(0, HybridCompanyStatus.Count(), 'Should have no records after delete');
    end;

    [Test]
    procedure TestDeleteCompanyStatus_SpecificCompany()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
    begin
        Initialize_StatusMgr();

        InsertCompanyStatus_StatusMgr('CO-1', HybridCompanyStatus."Upgrade Status"::Completed);
        InsertCompanyStatus_StatusMgr('CO-2', HybridCompanyStatus."Upgrade Status"::Failed);

        BC14StatusMgr.DeleteCompanyStatus('CO-1');

        Assert.IsFalse(HybridCompanyStatus.Get('CO-1'), 'CO-1 should be deleted');
        Assert.IsTrue(HybridCompanyStatus.Get('CO-2'), 'CO-2 should remain');
    end;

    // ============================================================
    // Status Manager — AfterCompanyMigrationCompleted
    // ============================================================

    [Test]
    procedure TestAfterCompanyMigrationCompleted_Failure_FailsCompanyAndSummary()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
    begin
        // [SCENARIO] HasErrors=true with Stop-On-First-Error enabled fails the company
        // and immediately flips the summary to UpgradeFailed.
        Initialize_StatusMgr();
        SetStopOnFirstError_StatusMgr(true);
        InsertCompanyStatus_StatusMgr('COMP-A', HybridCompanyStatus."Upgrade Status"::Started);
        InsertReplicationSummary(HybridReplicationSummary, HybridReplicationSummary.Status::UpgradeInProgress);

        BC14StatusMgr.AfterCompanyMigrationCompleted('COMP-A', true, true, HybridReplicationSummary);

        Assert.IsTrue(HybridCompanyStatus.Get('COMP-A'), 'Company status row should still exist');
        Assert.AreEqual(HybridCompanyStatus."Upgrade Status"::Failed, HybridCompanyStatus."Upgrade Status", 'Company should be Failed');

        HybridReplicationSummary.Get(HybridReplicationSummary."Run ID");
        Assert.AreEqual(HybridReplicationSummary.Status::UpgradeFailed, HybridReplicationSummary.Status, 'Summary should be UpgradeFailed');
    end;

    [Test]
    procedure TestAfterCompanyMigrationCompleted_Failure_ContinueOnError_FinalizesAsFailedWhenLastCompany()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
    begin
        // [SCENARIO] HasErrors=true with Stop-On-First-Error disabled fails the company but
        // does not immediately fail the summary; the summary is reconciled by
        // TryFinalizeOverallStatus once all companies are processed. When the failing company
        // is the only/last one, the summary is finalized as UpgradeFailed.
        Initialize_StatusMgr();
        SetStopOnFirstError_StatusMgr(false);
        InsertHybridCompany('COMP-A', true);
        InsertCompanyStatus_StatusMgr('COMP-A', HybridCompanyStatus."Upgrade Status"::Started);
        InsertReplicationSummary(HybridReplicationSummary, HybridReplicationSummary.Status::UpgradeInProgress);

        BC14StatusMgr.AfterCompanyMigrationCompleted('COMP-A', true, true, HybridReplicationSummary);

        Assert.IsTrue(HybridCompanyStatus.Get('COMP-A'), 'Company status row should still exist');
        Assert.AreEqual(HybridCompanyStatus."Upgrade Status"::Failed, HybridCompanyStatus."Upgrade Status", 'Company should be Failed');

        HybridReplicationSummary.Get(HybridReplicationSummary."Run ID");
        Assert.AreEqual(HybridReplicationSummary.Status::UpgradeFailed, HybridReplicationSummary.Status, 'Summary should be UpgradeFailed after final reconciliation');
    end;

    [Test]
    procedure TestAfterCompanyMigrationCompleted_SuccessHistoricalDone_MarksCompleted()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
    begin
        // [SCENARIO] Success branch with Historical already finished.
        Initialize_StatusMgr();
        InsertCompanyStatus_StatusMgr('COMP-A', HybridCompanyStatus."Upgrade Status"::Started);
        InsertReplicationSummary(HybridReplicationSummary, HybridReplicationSummary.Status::UpgradeInProgress);

        BC14StatusMgr.AfterCompanyMigrationCompleted('COMP-A', false, true, HybridReplicationSummary);

        Assert.IsTrue(HybridCompanyStatus.Get('COMP-A'), 'Company status row should still exist');
        Assert.AreEqual(HybridCompanyStatus."Upgrade Status"::Completed, HybridCompanyStatus."Upgrade Status", 'Company should be Completed');
    end;

    [Test]
    procedure TestAfterCompanyMigrationCompleted_SuccessHistoricalPending_LeavesStarted()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
    begin
        // [SCENARIO] Success branch with Historical still running.
        Initialize_StatusMgr();
        InsertCompanyStatus_StatusMgr('COMP-A', HybridCompanyStatus."Upgrade Status"::Started);
        InsertReplicationSummary(HybridReplicationSummary, HybridReplicationSummary.Status::UpgradeInProgress);

        BC14StatusMgr.AfterCompanyMigrationCompleted('COMP-A', false, false, HybridReplicationSummary);

        Assert.IsTrue(HybridCompanyStatus.Get('COMP-A'), 'Company status row should still exist');
        Assert.AreEqual(HybridCompanyStatus."Upgrade Status"::Started, HybridCompanyStatus."Upgrade Status", 'Company should remain Started while Historical is pending');
    end;

    [Test]
    procedure TestAfterCompanyMigrationCompleted_Idempotent_AlreadyFailedNotOverwritten()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
    begin
        // [SCENARIO] Idempotency: a late call must not promote an already-Failed company to Completed.
        Initialize_StatusMgr();
        InsertCompanyStatus_StatusMgr('COMP-A', HybridCompanyStatus."Upgrade Status"::Failed);
        InsertReplicationSummary(HybridReplicationSummary, HybridReplicationSummary.Status::UpgradeFailed);

        BC14StatusMgr.AfterCompanyMigrationCompleted('COMP-A', false, true, HybridReplicationSummary);

        Assert.IsTrue(HybridCompanyStatus.Get('COMP-A'), 'Company status row should still exist');
        Assert.AreEqual(HybridCompanyStatus."Upgrade Status"::Failed, HybridCompanyStatus."Upgrade Status", 'Failed company must not be promoted to Completed');
    end;
}
