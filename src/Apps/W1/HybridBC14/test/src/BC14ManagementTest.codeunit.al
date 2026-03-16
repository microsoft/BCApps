// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration;
using Microsoft.DataMigration.BC14;
using System.Integration;
using System.Security.AccessControl;
using System.TestLibraries.Environment;

codeunit 148140 "BC14 Management Test"
{
    // [FEATURE] [BC14 Cloud Migration Management]
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryHybridManagement: Codeunit "Library - Hybrid Management";
        SubscriptionIdTxt: Label '50150-BC14Re-Implementation_IntelligentCloud', Locked = true;

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
        Initialize();

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
    procedure InsertDetailsOnWebhookNotificationInsert()
    var
        HybridReplicationDetail: Record "Hybrid Replication Detail";
        RunId: Text;
        StartTime: DateTime;
        TriggerType: Text;
    begin
        // [SCENARIO] Hybrid Replication Detail records are created for each table in the notification.

        // [GIVEN] A Webhook Subscription exists for BC14
        Initialize();

        // [WHEN] A notification record is inserted
        InsertNotification(RunId, StartTime, TriggerType);

        // [THEN] The correct Hybrid Replication Detail records are created.
        HybridReplicationDetail.SetRange("Run ID", RunId);
        Assert.AreEqual(3, HybridReplicationDetail.Count(), 'Unexpected number of detail records.');

        HybridReplicationDetail.Get(RunId, 'BC14$BC14 Customer$2363a2b7-1018-4976-a32a-c77338dc9f16', CompanyName());
        Assert.IsTrue(HybridReplicationDetail."Error Message" = '', 'Successful table should not report errors.');
        Assert.AreEqual(HybridReplicationDetail.Status::Successful, HybridReplicationDetail.Status, 'Successful table should have success status.');

        HybridReplicationDetail.Get(RunId, 'Bad Table', CompanyName());
        Assert.IsFalse(HybridReplicationDetail."Error Message" = '', 'Failed table should report errors.');
        Assert.AreEqual('1337', HybridReplicationDetail."Error Code", 'Incorrectly parsed error code.');
        Assert.AreEqual(HybridReplicationDetail.Status::Failed, HybridReplicationDetail.Status, 'Failed table should have failed status.');

        HybridReplicationDetail.Get(RunId, 'Bad Table, Errors Array', CompanyName());
        Assert.AreEqual('The table column ''New Column'' does not exist.', HybridReplicationDetail."Error Message", 'Incorrectly parsed error message');
        Assert.AreEqual('1000', HybridReplicationDetail."Error Code", 'Incorrectly parsed error code');
        Assert.AreEqual(HybridReplicationDetail.Status::Failed, HybridReplicationDetail.Status, 'Failed table should have failed status.');
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
        Initialize();

        // [WHEN] The GetChosenProductName method is called
        ProductName := HybridCloudManagement.GetChosenProductName();

        // [THEN] The returned value is set to the BC14 product name.
        Assert.AreEqual(BC14Wizard.GetMigrationProviderId(), ProductName, 'Incorrect product name returned.');
    end;

    [Test]
    procedure TableMappingActionIsAvailable()
    var
        CloudMigrationManagement: TestPage "Cloud Migration Management";
    begin
        // [SCENARIO] The "Manage Custom Tables" action is visible and enabled for BC14 migrations.

        // [GIVEN] Intelligent cloud is set up for BC14
        Initialize();

        // [WHEN] The Cloud Migration Management page is launched
        CloudMigrationManagement.Trap();
        Page.Run(Page::"Cloud Migration Management");

        // [THEN] The action to manage mapped tables is enabled and visible
        Assert.IsTrue(CloudMigrationManagement.ManageCustomTables.Visible(), 'Map tables action is not visible');
        Assert.IsTrue(CloudMigrationManagement.ManageCustomTables.Enabled(), 'Map tables action is not enabled');
    end;

    local procedure Initialize()
    var
        WebhookSubscription: Record "Webhook Subscription";
        IntelligentCloudSetup: Record "Intelligent Cloud Setup";
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        HybridReplicationDetail: Record "Hybrid Replication Detail";
        BC14Wizard: Codeunit "BC14 Wizard";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        PermissionManager: Codeunit "Permission Manager";
    begin
        WebhookSubscription.DeleteAll();
        HybridReplicationSummary.DeleteAll();
        HybridReplicationDetail.DeleteAll();

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
}
