// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AA0210
namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration;
using Microsoft.DataMigration.BC14;
using System.Integration;
using System.TestLibraries.Utilities;

codeunit 148141 "BC14 Cloud Migration E2E Test"
{
    // [FEATURE] [BC14 Cloud Migration E2E]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        BC14Wizard: Codeunit "BC14 Wizard";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Initialized: Boolean;
        SubscriptionFormatTxt: Label '%1_IntelligentCloud', Comment = '%1 - The source product id', Locked = true;
        DateTimeStringFormatTok: Label '%1-%2-%3', Locked = true;

    local procedure Initialize()
    var
        BC14UpgradeSettings: Record "BC14 Upgrade Settings";
        HybridCompany: Record "Hybrid Company";
        HybridCompanyStatus: Record "Hybrid Company Status";
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        HybridReplicationDetail: Record "Hybrid Replication Detail";
        IntelligentCloud: Record "Intelligent Cloud";
        IntelligentCloudSetup: Record "Intelligent Cloud Setup";
        WebhookNotification: Record "Webhook Notification";
        HybridCloudManagement: Codeunit "Hybrid Cloud Management";
    begin
        HybridCompany.DeleteAll();
        HybridCompanyStatus.DeleteAll();
        HybridReplicationSummary.DeleteAll();
        HybridReplicationDetail.DeleteAll();
        IntelligentCloud.DeleteAll();
        IntelligentCloudSetup.DeleteAll();
        WebhookNotification.DeleteAll();

        BC14UpgradeSettings.GetOrInsertBC14UpgradeSettings(BC14UpgradeSettings);
        BC14UpgradeSettings."One Step Upgrade" := false;
        BC14UpgradeSettings.Modify(true);

        LibraryVariableStorage.AssertEmpty();

        if Initialized then
            exit;

        HybridCloudManagement.RefreshIntelligentCloudStatusTable();
        Initialized := true;
        Commit();
    end;

    [Test]
    [HandlerFunctions('TestConfirmationHandler,TestMessageHandler')]
    procedure TestStatusIsSetToUpgradePending()
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        HybridCompany: Record "Hybrid Company";
        DummyHybridCompanyStatus: Record "Hybrid Company Status";
        CloudMigE2EEventHandler: Codeunit "Cloud Mig E2E Event Handler";
        BC14E2ETestEventHandler: Codeunit "BC14 E2E Test Event Handler";
        CloudMigrationManagement: TestPage "Cloud Migration Management";
    begin
        // [SCENARIO] After replication completes, the status is set to UpgradePending.
        // Running the data upgrade then sets the status to Completed.

        // [GIVEN] Cloud Migration has been succesfully setup for BC14
        Initialize();
        BindSubscription(CloudMigE2EEventHandler);
        BindSubscription(BC14E2ETestEventHandler);
        InsertSetupRecords();

        // [GIVEN] User invokes run replication now
        CloudMigrationManagement.OpenEdit();
        LibraryVariableStorage.Enqueue(true);
        CloudMigrationManagement.RunReplicationNow.Invoke();
        CloudMigrationManagement.Close();

        HybridCompany.SetRange(Replicate, true);
        HybridCompany.FindLast();
        HybridReplicationSummary.SetCurrentKey("Start Time");
        HybridReplicationSummary.FindLast();

        // [WHEN] Webhook updates the status after replication completes
        InsertWebhookCompletedReplication(HybridReplicationSummary."Run ID", HybridCompany.Name);

        // [THEN] Cloud Migration is successfully completed and state is set to Pending
        VerifyHybridReplicationSummaryIsPending();
        VerifyHybridCompanyStatusRecords(DummyHybridCompanyStatus."Upgrade Status"::Pending);

        // [WHEN] User invokes data upgrade
        CloudMigrationManagement.OpenEdit();
        LibraryVariableStorage.Enqueue(true);
        CloudMigrationManagement.RunDataUpgrade.Invoke();
        CloudMigrationManagement.Close();

        // [THEN] Upgrade completes and all company statuses are set to Completed
        VerifyHybridReplicationSummaryIsCompleted();
        VerifyHybridCompanyStatusRecords(DummyHybridCompanyStatus."Upgrade Status"::Completed);
    end;

    // todo: add more E2E tests here for other scenarios such as failure cases, one-step upgrade, etc.

    [ConfirmHandler]
    procedure TestConfirmationHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [MessageHandler]
    procedure TestMessageHandler(Message: Text[1024])
    begin
    end;

    local procedure InsertWebhookCompletedReplication(RunID: Text; CompanyNameValue: Text)
    var
        WebhookNotification: Record "Webhook Notification";
        NotificationOutStream: OutStream;
        TodayDate: Date;
        DateTimeString: Text;
    begin
        WebhookNotification.ID := CreateGuid();
        WebhookNotification."Sequence Number" := 1;
        WebhookNotification."Subscription ID" := CopyStr(StrSubstNo(SubscriptionFormatTxt, BC14Wizard.GetMigrationProviderId()), 1, 150);
        WebhookNotification.Notification.CreateOutStream(NotificationOutStream);
        TodayDate := DT2Date(CurrentDateTime);
        DateTimeString := StrSubstNo(DateTimeStringFormatTok, Date2DMY(TodayDate, 3), Date2DMY(TodayDate, 2), Date2DMY(TodayDate, 1));
        NotificationOutStream.WriteText(GetBC14CloudSuccessfulNotification(RunID, CompanyNameValue, DateTimeString));
        WebhookNotification.Insert();
    end;

    local procedure VerifyHybridReplicationSummaryIsPending()
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        Assert: Codeunit Assert;
    begin
        HybridReplicationSummary.SetCurrentKey("End Time");
        HybridReplicationSummary.Ascending(false);
        HybridReplicationSummary.FindFirst();

        Assert.AreEqual(HybridReplicationSummary.Status::UpgradePending, HybridReplicationSummary.Status, 'Upgrade status should have been set to UpgradePending');
    end;

    local procedure VerifyHybridReplicationSummaryIsCompleted()
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        Assert: Codeunit Assert;
    begin
        HybridReplicationSummary.SetCurrentKey("End Time");
        HybridReplicationSummary.Ascending(false);
        HybridReplicationSummary.FindFirst();

        Assert.AreEqual(HybridReplicationSummary.Status::Completed, HybridReplicationSummary.Status, 'Upgrade status should have been set to Completed');
    end;

    local procedure VerifyHybridCompanyStatusRecords(ExpectedUpgradeStatus: Option)
    var
        HybridCompany: Record "Hybrid Company";
        HybridCompanyStatus: Record "Hybrid Company Status";
        Assert: Codeunit Assert;
    begin
        HybridCompany.SetRange(Replicate, true);
        HybridCompany.FindSet();

        repeat
            Assert.IsTrue(HybridCompanyStatus.Get(HybridCompany.Name), 'Hybrid company status was not found for company ' + HybridCompany.Name);
            Assert.AreEqual(ExpectedUpgradeStatus, HybridCompanyStatus."Upgrade Status", 'Wrong status on Hybrid Company Status for company ' + HybridCompany.Name);
        until HybridCompany.Next() = 0;
    end;

    local procedure InsertSetupRecords()
    var
        HybridCompany: Record "Hybrid Company";
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        IntelligentCloud: Record "Intelligent Cloud";
        IntelligentCloudSetup: Record "Intelligent Cloud Setup";
    begin
        HybridCompany.Name := CopyStr(CompanyName(), 1, MaxStrLen(HybridCompany.Name));
        HybridCompany."Display Name" := HybridCompany.Name;
        HybridCompany.Replicate := true;
        HybridCompany.Insert();

        if IntelligentCloud.Get() then
            IntelligentCloud.Delete();

        IntelligentCloud.Enabled := true;
        IntelligentCloud.Insert();

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

    local procedure GetBC14CloudSuccessfulNotification(RunId: Text; NameOfCompany: Text; StartDate: Text): Text
    begin
        exit(
            '{ "@odata.type": "#Microsoft.Dynamics.NAV.Hybrid.Notification",' +
            ' "SubscriptionId": "' + CopyStr(StrSubstNo(SubscriptionFormatTxt, BC14Wizard.GetMigrationProviderId()), 1, 150) + '",' +
            ' "ChangeType": "Changed",' +
            ' "RunId": "' + RunId + '",' +
            ' "StartTime": "' + StartDate + 'T23:59:59.3759312Z",' +
            ' "TriggerType": "Manual",' +
            ' "Status": "Completed",' +
            ' "ServiceType": "ReplicationCompleted",' +
            ' "IncrementalTables": [' +
            '{ "TableName": "' + NameOfCompany + '$BC14 Customer$2363a2b7-1018-4976-a32a-c77338dc9f16",' +
            ' "CompanyName": "' + NameOfCompany + '", "Errors": "" },' +
            '{ "TableName": "' + NameOfCompany + '$BC14 G/L Account$2363a2b7-1018-4976-a32a-c77338dc9f16",' +
            ' "CompanyName": "' + NameOfCompany + '", "Errors": "" }' +
            ']}'
        );
    end;
}
