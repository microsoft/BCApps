codeunit 139098 "Power BI Synchronizer Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        PowerBITestSubscriber: Codeunit "Power BI Test Subscriber";
        PowerBIBlobIdTxt: Label 'bcbcbcbc-bcbc-bcbc-1111-000000000000', Locked = true;
        FailStep: Option NotSet,CheckLicense,StartImport,GetImport,UpdateParams,GetDatasource,UpdateCreds,RefreshDataset,Never;

    #region DeployableReportTests

    [Test]
    procedure TestDeployableReportSuccess()
    var
        PowerBIDeployment: Record "Power BI Deployment";
        PowerBIDeploymentState: Record "Power BI Deployment State";
        PowerBIDeploymentBuffer: Record "Power BI Deployment Buffer";
    begin
        // [SCENARIO] Deployable report uploads successfully with no failures
        // [GIVEN] A deployable report is pending deployment
        SetupBase();
        SetupDeployableReport();
        PowerBITestSubscriber.SetFailAtStep(FailStep::Never);

        // [WHEN] The synchronizer runs
        // [THEN] The report run should be successful and reach Completed status with expected deployment states recorded
        Assert.IsTrue(RunSynchronizer(), 'Synchronizer should succeed');

        PowerBIDeployment.Get(Enum::"Power BI Deployable Report"::"Test Report");
        Assert.AreEqual(
            Enum::"Power BI Upload Status"::Completed,
            PowerBIDeployment.GetUploadStatus(),
            'Unexpected upload status');
        Assert.AreEqual(1, PowerBIDeployment."Deployed Version", 'Unexpected deployed version');

        PowerBIDeploymentState.SetRange("Report Id", Enum::"Power BI Deployable Report"::"Test Report");
        Assert.RecordCount(PowerBIDeploymentState, 5); // ImportStarted, ImportFinished, ParametersUpdated, DataRefreshed, Completed

        // [THEN] The deployment buffer should be loaded accordingly
        PowerBIDeploymentBuffer.LoadReports();
        PowerBIDeploymentBuffer.Get(Enum::"Power BI Deployable Report"::"Test Report");
        Assert.AreNotEqual(0DT, PowerBIDeploymentBuffer."Last Deployed", 'Last Deployed should be set after successful deployment');
    end;

    [Test]
    procedure TestDeployableReportFailAtStartImport_NoRetry()
    var
        PowerBIDeployment: Record "Power BI Deployment";
        PowerBIDeploymentState: Record "Power BI Deployment State";
        PowerBIDeploymentBuffer: Record "Power BI Deployment Buffer";
    begin
        // [SCENARIO] Deployable report fails at the start of import with no retry scheduled
        // [GIVEN] A deployable report is pending deployment
        SetupBase();
        SetupDeployableReport();
        PowerBITestSubscriber.SetFailAtStep(FailStep::StartImport);

        // [WHEN] The synchronizer runs
        // [THEN] The synchronizer should complete with a failed status for the report and record the failure in deployment state
        Assert.IsTrue(RunSynchronizer(), 'Synchronizer should succeed (report fails gracefully)');

        PowerBIDeployment.Get(Enum::"Power BI Deployable Report"::"Test Report");
        Assert.AreEqual(
            Enum::"Power BI Upload Status"::Failed,
            PowerBIDeployment.GetUploadStatus(),
            'Unexpected upload status');

        PowerBIDeploymentState.SetRange("Report Id", Enum::"Power BI Deployable Report"::"Test Report");
        Assert.RecordCount(PowerBIDeploymentState, 1);
        PowerBIDeploymentState.FindFirst();
        Assert.AreEqual(
            Enum::"Power BI Upload Status"::NotStarted,
            PowerBIDeploymentState."Status Reached",
            'Unexpected status reached');
        Assert.AreNotEqual(0DT, PowerBIDeploymentState."Failed At", 'Failed At should be set');

        // [THEN] The deployment buffer should show Last Deployed as 0DT after failure
        PowerBIDeploymentBuffer.LoadReports();
        PowerBIDeploymentBuffer.Get(Enum::"Power BI Deployable Report"::"Test Report");
        Assert.AreEqual(0DT, PowerBIDeploymentBuffer."Last Deployed", 'Last Deployed should be blank after failure');
    end;

    [Test]
    procedure TestDeployableReportFailAtStartImport_WithRetry()
    var
        PowerBIDeployment: Record "Power BI Deployment";
        PowerBIDeploymentState: Record "Power BI Deployment State";
    begin
        // [SCENARIO] Deployable report fails at the start of import JQ retries are still to be run
        // [GIVEN] A deployable report is pending deployment and the synchronizer is configured to retry on failure
        SetupBase();
        SetupDeployableReport();
        PowerBITestSubscriber.SetFailAtStep(FailStep::StartImport);
        PowerBITestSubscriber.SetRetryDateTime(CurrentDateTime());

        // [WHEN] The synchronizer runs
        // [THEN] The synchronizer should error to signal to the JQ engine that retry is needed
        Assert.IsFalse(RunSynchronizerWithRetries(), 'Synchronizer should error to signal retry needed');

        PowerBIDeployment.Get(Enum::"Power BI Deployable Report"::"Test Report");
        Assert.AreEqual(
            Enum::"Power BI Upload Status"::NotStarted,
            PowerBIDeployment.GetUploadStatus(),
            'Unexpected upload status');
        Assert.AreNotEqual(0DT, PowerBIDeployment."Retry After", 'Retry After should be set');

        PowerBIDeploymentState.SetRange("Report Id", Enum::"Power BI Deployable Report"::"Test Report");
        Assert.RecordCount(PowerBIDeploymentState, 0);
    end;

    [Test]
    procedure TestDeployableReportFailAtGetImport_NoRetry()
    var
        PowerBIDeployment: Record "Power BI Deployment";
        PowerBIDeploymentState: Record "Power BI Deployment State";
    begin
        // [SCENARIO] Deployable report fails at the get import step, there are no longer JQ retries left
        // [GIVEN] A deployable report is pending deployment and the synchronizer is configured to not retry on failure
        SetupBase();
        SetupDeployableReport();
        PowerBITestSubscriber.SetFailAtStep(FailStep::GetImport);

        // [WHEN] The synchronizer runs
        // [THEN] The synchronizer should complete with a failed status for the report and record the failure in deployment state
        Assert.IsTrue(RunSynchronizer(), 'Synchronizer should succeed');

        PowerBIDeployment.Get(Enum::"Power BI Deployable Report"::"Test Report");
        Assert.AreEqual(
            Enum::"Power BI Upload Status"::Failed,
            PowerBIDeployment.GetUploadStatus(),
            'Unexpected upload status');

        PowerBIDeploymentState.SetRange("Report Id", Enum::"Power BI Deployable Report"::"Test Report");
        Assert.RecordCount(PowerBIDeploymentState, 1);
        PowerBIDeploymentState.FindFirst();
        Assert.AreEqual(
            Enum::"Power BI Upload Status"::ImportStarted,
            PowerBIDeploymentState."Status Reached",
            'Unexpected status reached');
        Assert.AreNotEqual(0DT, PowerBIDeploymentState."Failed At", 'Failed At should be set');
    end;

    [Test]
    procedure TestDeployableReportFailAtRefreshDataset_NoRetry()
    var
        PowerBIDeployment: Record "Power BI Deployment";
        PowerBIDeploymentState: Record "Power BI Deployment State";
        PowerBIDeploymentBuffer: Record "Power BI Deployment Buffer";
    begin
        // [SCENARIO] Deployable report fails at the refresh dataset step, there are no longer JQ retries left
        SetupBase();
        SetupDeployableReport();
        PowerBITestSubscriber.SetFailAtStep(FailStep::RefreshDataset);

        // [WHEN] The synchronizer runs
        // [THEN] The synchronizer should complete with a failed status for the report and record the failure in deployment state
        Assert.IsTrue(RunSynchronizer(), 'Synchronizer should succeed');

        PowerBIDeployment.Get(Enum::"Power BI Deployable Report"::"Test Report");
        Assert.AreEqual(
            Enum::"Power BI Upload Status"::Failed,
            PowerBIDeployment.GetUploadStatus(),
            'Unexpected upload status');

        // ImportStarted, ImportFinished, ParametersUpdated (with FailedAt from RefreshDataset failure)
        PowerBIDeploymentState.SetRange("Report Id", Enum::"Power BI Deployable Report"::"Test Report");
        Assert.RecordCount(PowerBIDeploymentState, 3);

        PowerBIDeploymentState.FindLast();
        Assert.AreEqual(
            Enum::"Power BI Upload Status"::ParametersUpdated,
            PowerBIDeploymentState."Status Reached",
            'Unexpected status reached');
        Assert.AreNotEqual(0DT, PowerBIDeploymentState."Failed At", 'Failed At should be set');

        // [THEN] The deployment buffer should show the step where failure was recorded
        PowerBIDeploymentBuffer.LoadReports();
        PowerBIDeploymentBuffer.Get(Enum::"Power BI Deployable Report"::"Test Report");
        Assert.AreEqual('Parameters Updated', PowerBIDeploymentBuffer."Current Step", 'Current Step should show the step where failure was recorded');
    end;

    #endregion

    #region AggregatorTests

    [Test]
    procedure TestAggregatorNoPendingReports()
    var
        ReportAggregator: Codeunit "Power BI Report Aggregator";
    begin
        // [SCENARIO] When there are no pending reports, the aggregator should return false on LoadAllPending
        SetupBase();

        Assert.IsFalse(ReportAggregator.LoadAllPending('TestContext'), 'Should have no pending reports');
    end;

    [Test]
    procedure TestAggregatorPendingSystemBlob()
    var
        Report: Interface "Power BI Uploadable Report";
        ReportAggregator: Codeunit "Power BI Report Aggregator";
    begin
        // [SCENARIO] System blob that is pending upload should be returned by the aggregator
        SetupBase();
        SetupSystemBlob();

        Assert.IsTrue(ReportAggregator.LoadAllPending('TestContext'), 'Should have pending reports');
        Assert.AreEqual(1, ReportAggregator.PendingCount(), 'Unexpected pending count');
        Assert.IsTrue(ReportAggregator.Next(Report), 'Next should return true');
    end;

    [Test]
    procedure TestAggregatorCompletedSystemBlobExcluded()
    var
        PowerBIReportUploads: Record "Power BI Report Uploads";
        ReportAggregator: Codeunit "Power BI Report Aggregator";
    begin
        // [SCENARIO] System blob that is already completed should be excluded from pending list
        SetupBase();
        SetupSystemBlob();

        PowerBIReportUploads.Init();
        PowerBIReportUploads."PBIX BLOB ID" := PowerBIBlobIdTxt;
        PowerBIReportUploads."User ID" := UserSecurityId();
        PowerBIReportUploads."Report Upload Status" := PowerBIReportUploads."Report Upload Status"::Completed;
        PowerBIReportUploads.Insert();

        Assert.IsFalse(ReportAggregator.LoadAllPending('TestContext'), 'Completed blob should be excluded');
    end;

    [Test]
    procedure TestAggregatorPendingDeployableReport()
    var
        Report: Interface "Power BI Uploadable Report";
        ReportAggregator: Codeunit "Power BI Report Aggregator";
    begin
        // [SCENARIO] Deployable report is pending deployment and returned by the aggregator
        SetupBase();
        SetupDeployableReport();

        Assert.IsTrue(ReportAggregator.LoadAllPending('TestContext'), 'Should have pending reports');
        Assert.AreEqual(1, ReportAggregator.PendingCount(), 'Unexpected pending count');
        Assert.IsTrue(ReportAggregator.Next(Report), 'Next should return true');
    end;

    [Test]
    procedure TestAggregatorCompletedDeployableExcluded()
    var
        PowerBIDeployment: Record "Power BI Deployment";
        ReportAggregator: Codeunit "Power BI Report Aggregator";
    begin
        // [SCENARIO] Deployable report that is already completed should be excluded from pending list, even if version matches
        SetupBase();
        SetupDeployableReport();

        // Mark as completed with matching version
        PowerBIDeployment.Get(Enum::"Power BI Deployable Report"::"Test Report");
        PowerBIDeployment.RecordStep(Enum::"Power BI Upload Status"::Completed);
        PowerBIDeployment."Deployed Version" := 1; // Matches test report's GetVersion()
        PowerBIDeployment.Modify();

        Assert.IsFalse(ReportAggregator.LoadAllPending('TestContext'), 'Completed deployable should be excluded');
    end;

    [Test]
    procedure TestAggregatorDeployableVersionUpgradeNotAutoPending()
    var
        PowerBIDeployment: Record "Power BI Deployment";
        ReportAggregator: Codeunit "Power BI Report Aggregator";
    begin
        // [SCENARIO] Deployable report with a new version available should not be automatically made pending without explicit user action
        SetupBase();
        SetupDeployableReport();

        // [GIVEN] A deployable report is marked as completed with an older version than the current report version
        // Mark as completed with old version (test report returns 1, deployed is 0)
        PowerBIDeployment.Get(Enum::"Power BI Deployable Report"::"Test Report");
        PowerBIDeployment.RecordStep(Enum::"Power BI Upload Status"::Completed);
        // Deployed Version stays at 0 (default), less than test report's version (1)
        PowerBIDeployment.Modify();

        // [WHEN] The aggregator loads pending reports
        // Version upgrades require explicit user action via the Update button; they should not be auto-pending
        Assert.IsFalse(ReportAggregator.LoadAllPending('TestContext'), 'Version upgrade should not automatically make report pending');
        // [THEN] The report should not be included in the pending list, an explicit update action is required to make it pending
    end;

    [Test]
    procedure TestAggregatorMultipleReports()
    var
        Report: Interface "Power BI Uploadable Report";
        ReportAggregator: Codeunit "Power BI Report Aggregator";
    begin
        // [SCENARIO] When there are multiple pending reports, the aggregator should return all of them
        SetupBase();
        SetupSystemBlob();
        SetupDeployableReport();

        Assert.IsTrue(ReportAggregator.LoadAllPending('TestContext'), 'Should have pending reports');
        Assert.AreEqual(2, ReportAggregator.PendingCount(), 'Unexpected pending count');

        Assert.IsTrue(ReportAggregator.Next(Report), 'First Next should return true');
        Assert.IsTrue(ReportAggregator.Next(Report), 'Second Next should return true');
        Assert.IsFalse(ReportAggregator.Next(Report), 'Third Next should return false');
    end;

    #endregion

    #region SynchronizerEdgeCases

    [Test]
    procedure TestSynchronizerNoPendingReports()
    begin
        // [SCENARIO] When there are no pending reports, the synchronizer should complete successfully without doing anything
        SetupBase();
        PowerBITestSubscriber.SetFailAtStep(FailStep::Never);

        Assert.IsTrue(RunSynchronizer(), 'Synchronizer should succeed with no reports');
    end;

    [Test]
    procedure TestSynchronizerMultipleReportTypes()
    var
        PowerBIReportUploads: Record "Power BI Report Uploads";
        PowerBIDeployment: Record "Power BI Deployment";
    begin
        // [SCENARIO] When there are multiple types of pending reports, the synchronizer should process all of them successfully
        SetupBase();
        // [GIVEN] Both a system blob and a deployable report are pending
        SetupSystemBlob();
        SetupDeployableReport();
        PowerBITestSubscriber.SetFailAtStep(FailStep::Never);

        // [WHEN] The synchronizer runs
        Assert.IsTrue(RunSynchronizer(), 'Synchronizer should succeed');

        // [THEN] System blob should be completed
        Assert.RecordCount(PowerBIReportUploads, 1);
        PowerBIReportUploads.FindFirst();
        Assert.AreEqual(
            PowerBIReportUploads."Report Upload Status"::Completed,
            PowerBIReportUploads."Report Upload Status",
            'System blob should be completed');

        // [THEN] Deployable report should be completed
        PowerBIDeployment.Get(Enum::"Power BI Deployable Report"::"Test Report");
        Assert.AreEqual(
            Enum::"Power BI Upload Status"::Completed,
            PowerBIDeployment.GetUploadStatus(),
            'Deployable report should be completed');
        Assert.AreEqual(1, PowerBIDeployment."Deployed Version", 'Unexpected deployed version');
    end;

    [Test]
    procedure TestDeployableReportExplicitVersionUpgrade()
    var
        PowerBIDeployment: Record "Power BI Deployment";
        PowerBIDeploymentState: Record "Power BI Deployment State";
    begin
        // [SCENARIO] Deployable report with a new version available is upgraded to the new version when the user explicitly triggers an update
        SetupBase();
        // [GIVEN] A deployable report is marked as completed with an older version than the current report version
        SetupDeployableReport();
        PowerBITestSubscriber.SetFailAtStep(FailStep::Never);

        // [GIVEN] The report is marked as completed with an older version (test report returns version 1, deployed is 0)
        // Simulate a previously completed deployment at version 0
        PowerBIDeployment.Get(Enum::"Power BI Deployable Report"::"Test Report");
        PowerBIDeployment.RecordStep(Enum::"Power BI Upload Status"::Completed);
        // Deployed Version stays at 0; test report returns version 1 → upgrade available
        PowerBIDeployment.Modify();
        Commit();

        // [WHEN] The synchronizer runs 
        // The synchronizer should NOT auto-redeploy; the report stays completed
        Assert.IsTrue(RunSynchronizer(), 'Synchronizer should succeed with nothing to do');
        // [THEN] The report should still be completed with the old version, as auto-redeploy is not triggered by a version mismatch alone
        PowerBIDeployment.Get(Enum::"Power BI Deployable Report"::"Test Report");
        Assert.AreEqual(
            Enum::"Power BI Upload Status"::Completed,
            PowerBIDeployment.GetUploadStatus(),
            'Report should still be completed (no auto-redeploy)');
        Assert.AreEqual(0, PowerBIDeployment."Deployed Version", 'Version should not have changed');

        // [WHEN] The user explicitly triggers an update
        // Simulate the user clicking "Update" on the Deployments page
        PowerBIDeployment.ResetDeployment();
        Commit();

        Assert.IsTrue(RunSynchronizer(), 'Synchronizer should succeed for explicit version upgrade');
        // [THEN] The report should be redeployed and reach Completed status with the new version

        PowerBIDeployment.Get(Enum::"Power BI Deployable Report"::"Test Report");
        Assert.AreEqual(
            Enum::"Power BI Upload Status"::Completed,
            PowerBIDeployment.GetUploadStatus(),
            'Unexpected upload status');
        Assert.AreEqual(1, PowerBIDeployment."Deployed Version", 'Version should be updated after explicit upgrade');

        PowerBIDeploymentState.SetRange("Report Id", Enum::"Power BI Deployable Report"::"Test Report");
        Assert.RecordCount(PowerBIDeploymentState, 5);
    end;

    [Test]
    procedure TestResetDeploymentClearsState()
    var
        PowerBIDeployment: Record "Power BI Deployment";
        PowerBIDeploymentState: Record "Power BI Deployment State";
    begin
        // [SCENARIO] When a deployment is reset, the deployment status and state should be cleared to allow for a fresh redeployment
        SetupBase();
        SetupDeployableReport();
        PowerBITestSubscriber.SetFailAtStep(FailStep::RefreshDataset);
        // [GIVEN] A deployable report that has failed deployment
        Assert.IsTrue(RunSynchronizer(), 'Synchronizer should succeed');

        PowerBIDeployment.Get(Enum::"Power BI Deployable Report"::"Test Report");
        Assert.AreEqual(
            Enum::"Power BI Upload Status"::Failed,
            PowerBIDeployment.GetUploadStatus(),
            'Should be failed before reset');

        // [WHEN] The deployment is reset to allow for a redeployment attempt
        PowerBIDeployment.ResetDeployment();

        // [THEN] The deployment status should be reset to NotStarted and all deployment states should be cleared
        Assert.AreEqual(
            Enum::"Power BI Upload Status"::NotStarted,
            PowerBIDeployment.GetUploadStatus(),
            'Should be NotStarted after reset');

        PowerBIDeploymentState.SetRange("Report Id", Enum::"Power BI Deployable Report"::"Test Report");
        Assert.RecordCount(PowerBIDeploymentState, 0);
    end;

    #endregion

    #region WorkspaceTests

    [Test]
    procedure TestDeployableReportDeploysToConfiguredWorkspace()
    var
        PowerBIDeployment: Record "Power BI Deployment";
        WorkspaceId: Guid;
    begin
        // [SCENARIO] A deployable report configured with a target workspace is uploaded to that workspace
        SetupBase();

        // [GIVEN] A writable shared workspace exists and a deployable report is configured to deploy to it
        WorkspaceId := CreateGuid();
        PowerBITestSubscriber.AddWorkspace(WorkspaceId, 'Shared Workspace');
        SetupDeployableReportInWorkspace(WorkspaceId);
        PowerBITestSubscriber.SetFailAtStep(FailStep::Never);

        // [WHEN] The synchronizer runs
        Assert.IsTrue(RunSynchronizer(), 'Synchronizer should succeed');

        // [THEN] The report completes and the configured workspace id is the one passed to the Power BI service
        PowerBIDeployment.Get(Enum::"Power BI Deployable Report"::"Test Report");
        Assert.AreEqual(
            Enum::"Power BI Upload Status"::Completed,
            PowerBIDeployment.GetUploadStatus(),
            'Unexpected upload status');
        Assert.AreEqual(
            WorkspaceId,
            PowerBITestSubscriber.GetLastTargetWorkspaceId(),
            'The report should be deployed to the configured workspace');
    end;

    [Test]
    procedure TestDeployableReportDeploysToMyWorkspaceWhenNoWorkspaceConfigured()
    var
        PowerBIDeployment: Record "Power BI Deployment";
    begin
        // [SCENARIO] A deployable report with no configured workspace is uploaded to "My Workspace" (null workspace id)
        SetupBase();

        // [GIVEN] A deployable report with no target workspace configured
        SetupDeployableReport();
        PowerBITestSubscriber.SetFailAtStep(FailStep::Never);

        // [WHEN] The synchronizer runs
        Assert.IsTrue(RunSynchronizer(), 'Synchronizer should succeed');

        // [THEN] The report completes and a null (My Workspace) id is passed to the Power BI service
        PowerBIDeployment.Get(Enum::"Power BI Deployable Report"::"Test Report");
        Assert.AreEqual(
            Enum::"Power BI Upload Status"::Completed,
            PowerBIDeployment.GetUploadStatus(),
            'Unexpected upload status');
        Assert.IsTrue(
            IsNullGuid(PowerBITestSubscriber.GetLastTargetWorkspaceId()),
            'The report should be deployed to My Workspace (null workspace id)');
    end;

    [Test]
    procedure TestDeployableReportFailsWhenConfiguredWorkspaceMissing()
    var
        PowerBIDeployment: Record "Power BI Deployment";
        MissingWorkspaceId: Guid;
    begin
        // [SCENARIO] A deployable report configured with a workspace the user can no longer access fails without uploading
        SetupBase();

        // [GIVEN] The configured workspace is NOT among the user's writable workspaces
        MissingWorkspaceId := CreateGuid();
        PowerBITestSubscriber.AddWorkspace(CreateGuid(), 'Some Other Workspace');
        SetupDeployableReportInWorkspace(MissingWorkspaceId);
        PowerBITestSubscriber.SetFailAtStep(FailStep::Never);

        // [WHEN] The synchronizer runs
        Assert.IsTrue(RunSynchronizer(), 'Synchronizer should succeed (report fails gracefully)');

        // [THEN] The report is marked as failed and nothing was uploaded to the Power BI service
        PowerBIDeployment.Get(Enum::"Power BI Deployable Report"::"Test Report");
        Assert.AreEqual(
            Enum::"Power BI Upload Status"::Failed,
            PowerBIDeployment.GetUploadStatus(),
            'The report should fail when its configured workspace is missing');
        Assert.IsTrue(
            IsNullGuid(PowerBITestSubscriber.GetLastTargetWorkspaceId()),
            'No upload should be attempted when the configured workspace is invalid');
    end;

    [Test]
    procedure TestWorkspaceExistsIsTrueForMyWorkspace()
    var
        PowerBIWorkspaceMgt: Codeunit "Power BI Workspace Mgt.";
        EmptyWorkspaceId: Guid;
    begin
        // [SCENARIO] "My Workspace" (null id) is always considered a valid target
        SetupBase();

        // [THEN] WorkspaceExists returns true for a null workspace id
        Assert.IsTrue(
            PowerBIWorkspaceMgt.WorkspaceExists(EmptyWorkspaceId),
            'My Workspace (null workspace id) should always be valid');
    end;

    [Test]
    procedure TestWorkspaceExistsDistinguishesWritableWorkspaces()
    var
        PowerBIWorkspaceMgt: Codeunit "Power BI Workspace Mgt.";
        WritableWorkspaceId: Guid;
    begin
        // [SCENARIO] WorkspaceExists reflects whether a workspace is in the user's writable set
        SetupBase();

        // [GIVEN] One writable workspace is available
        WritableWorkspaceId := CreateGuid();
        PowerBITestSubscriber.AddWorkspace(WritableWorkspaceId, 'HQ Workspace');

        // [THEN] It exists for the writable workspace and not for an unknown one
        Assert.IsTrue(
            PowerBIWorkspaceMgt.WorkspaceExists(WritableWorkspaceId),
            'A writable workspace should exist');
        Assert.IsFalse(
            PowerBIWorkspaceMgt.WorkspaceExists(CreateGuid()),
            'An unknown workspace should not exist');
    end;

    [Test]
    procedure TestGetWritableWorkspacesIncludesMyWorkspaceAndSharedWorkspaces()
    var
        TempPowerBISelectionElement: Record "Power BI Selection Element" temporary;
        PowerBIWorkspaceMgt: Codeunit "Power BI Workspace Mgt.";
        WritableWorkspaceId: Guid;
    begin
        // [SCENARIO] GetWritableWorkspaces returns the personal workspace plus every writable shared workspace
        SetupBase();

        // [GIVEN] One writable shared workspace is available
        WritableWorkspaceId := CreateGuid();
        PowerBITestSubscriber.AddWorkspace(WritableWorkspaceId, 'HQ Workspace');

        // [WHEN] Retrieving the writable workspaces
        PowerBIWorkspaceMgt.GetWritableWorkspaces(TempPowerBISelectionElement);

        // [THEN] Both the personal ("My Workspace", null id) and the shared workspace are returned
        Assert.AreEqual(2, TempPowerBISelectionElement.Count(), 'Expected My Workspace plus one shared workspace');

        // [THEN] The shared workspace is listed with its id preserved
        TempPowerBISelectionElement.SetRange(Name, 'HQ Workspace');
        Assert.AreEqual(1, TempPowerBISelectionElement.Count(), 'The shared workspace should be listed by name');
        TempPowerBISelectionElement.FindFirst();
        Assert.AreEqual(WritableWorkspaceId, TempPowerBISelectionElement.ID, 'The shared workspace should keep its id');
    end;

    [Test]
    procedure TestCompanyInformationClearsWorkspaceNameWhenIdCleared()
    var
        CompanyInformation: Record "Company Information";
        WorkspaceId: Guid;
        EmptyWorkspaceId: Guid;
    begin
        // [SCENARIO] Clearing the Power BI Workspace Id on Company Information clears the stored workspace name
        WorkspaceId := CreateGuid();

        // [GIVEN] Company Information with a configured Power BI workspace id and name
        CompanyInformation.Init();
        CompanyInformation."Power BI Workspace Id" := WorkspaceId;
        CompanyInformation."Power BI Workspace Name" := 'HQ Workspace';

        // [WHEN] The workspace id is validated back to an empty value
        CompanyInformation.Validate("Power BI Workspace Id", EmptyWorkspaceId);

        // [THEN] The workspace name is cleared as well
        Assert.AreEqual('', CompanyInformation."Power BI Workspace Name", 'Workspace name should be cleared when the id is cleared');
    end;

    [Test]
    procedure TestDeployActionCopiesWorkspaceFromCompanyInformation()
    var
        PowerBIDeployment: Record "Power BI Deployment";
        WorkspaceId: Guid;
        ReportDeployments: TestPage "Power BI Report Deployments";
    begin
        // [SCENARIO] Deploying from the Report Deployments page stamps the Company Information workspace onto the deployment
        SetupBase();

        // [GIVEN] A writable workspace configured on Company Information, and it is an evaluation company so the action is enabled
        WorkspaceId := CreateGuid();
        PowerBITestSubscriber.AddWorkspace(WorkspaceId, 'HQ Workspace');
        SetCompanyInformationWorkspace(WorkspaceId, 'HQ Workspace');
        SetEvaluationCompany(true);
        PowerBITestSubscriber.SetFailAtStep(FailStep::Never);

        // [WHEN] The user selects the test report and deploys it
        ReportDeployments.OpenView();
        ReportDeployments.GoToKey(Enum::"Power BI Deployable Report"::"Test Report");
        ReportDeployments.Deploy.Invoke();
        ReportDeployments.Close();

        // [THEN] The created deployment carries the workspace configured on Company Information
        PowerBIDeployment.Get(Enum::"Power BI Deployable Report"::"Test Report");
        Assert.AreEqual(WorkspaceId, PowerBIDeployment."Power BI Workspace Id", 'Deployment should use the Company Information workspace id');
        Assert.AreEqual('HQ Workspace', PowerBIDeployment."Power BI Workspace Name", 'Deployment should use the Company Information workspace name');
    end;

    #endregion

    #region Helpers

    local procedure SetupBase()
    var
        AzureADMgtSetup: Record "Azure AD Mgt. Setup";
        PowerBIBlob: Record "Power BI Blob";
        PowerBIDefaultSelection: Record "Power BI Default Selection";
        PowerBIReportUploads: Record "Power BI Report Uploads";
        PowerBIDeployment: Record "Power BI Deployment";
        PowerBIDeploymentState: Record "Power BI Deployment State";
        PowerBIContextSettings: Record "Power BI Context Settings";
        PowerBIDisplayedElement: Record "Power BI Displayed Element";
        PowerBICustomerReports: Record "Power BI Customer Reports";
        JobQueueEntry: Record "Job Queue Entry";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        if UnbindSubscription(PowerBITestSubscriber) then;
        Clear(PowerBITestSubscriber);
        if BindSubscription(PowerBITestSubscriber) then;

        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Power BI Report Synchronizer");
        JobQueueEntry.DeleteAll();

        PowerBIReportUploads.DeleteAll();
        PowerBIContextSettings.DeleteAll();
        PowerBIDisplayedElement.DeleteAll();
        PowerBIBlob.DeleteAll();
        PowerBIDefaultSelection.DeleteAll();
        PowerBICustomerReports.DeleteAll();
        PowerBIDeploymentState.DeleteAll();
        PowerBIDeployment.DeleteAll();

        if not AzureADMgtSetup.Get() then begin
            AzureADMgtSetup.Init();
            AzureADMgtSetup.Insert();
        end;

        AzureADMgtSetup."Auth Flow Codeunit ID" := 0;
        AzureADMgtSetup.Modify();
    end;

    local procedure SetupSystemBlob()
    var
        PowerBIBlob: Record "Power BI Blob";
        PowerBIDefaultSelection: Record "Power BI Default Selection";
        OutStream: OutStream;
    begin
        PowerBIBlob.Init();
        PowerBIBlob.Id := PowerBIBlobIdTxt;
        PowerBIBlob.Name := 'Test system blob';
        PowerBIBlob."Blob File".CreateOutStream(OutStream);
        OutStream.Write('Test PBIX content');
        PowerBIBlob.Insert();

        PowerBIDefaultSelection.Init();
        PowerBIDefaultSelection.Id := PowerBIBlobIdTxt;
        PowerBIDefaultSelection.Context := 'TestContext';
        PowerBIDefaultSelection.Selected := true;
        PowerBIDefaultSelection.Insert();
    end;

    local procedure SetupDeployableReport()
    var
        EmptyWorkspaceId: Guid;
    begin
        SetupDeployableReportInWorkspace(EmptyWorkspaceId);
    end;

    local procedure SetupDeployableReportInWorkspace(WorkspaceId: Guid)
    var
        PowerBIDeployment: Record "Power BI Deployment";
    begin
        PowerBIDeployment.Init();
        PowerBIDeployment."Report Id" := Enum::"Power BI Deployable Report"::"Test Report";
        PowerBIDeployment."Power BI Workspace Id" := WorkspaceId;
        PowerBIDeployment.Insert();
    end;

    local procedure SetCompanyInformationWorkspace(WorkspaceId: Guid; WorkspaceName: Text[200])
    var
        CompanyInformation: Record "Company Information";
    begin
        if not CompanyInformation.Get() then begin
            CompanyInformation.Init();
            CompanyInformation.Insert();
        end;
        CompanyInformation."Power BI Workspace Id" := WorkspaceId;
        CompanyInformation."Power BI Workspace Name" := WorkspaceName;
        CompanyInformation.Modify();
    end;

    local procedure SetEvaluationCompany(IsEvaluation: Boolean)
    var
        Company: Record Company;
    begin
        Company.Get(CompanyName());
        Company."Evaluation Company" := IsEvaluation;
        Company.Modify();
    end;

    local procedure RunSynchronizer(): Boolean
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.Init();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := Codeunit::"Power BI Report Synchronizer";
        JobQueueEntry."Parameter String" := 'TestContext';
        JobQueueEntry."Maximum No. of Attempts to Run" := 1;
        JobQueueEntry."No. of Attempts to Run" := 1;

        Commit();
        ClearLastError();
        exit(Codeunit.Run(Codeunit::"Power BI Report Synchronizer", JobQueueEntry));
    end;

    local procedure RunSynchronizerWithRetries(): Boolean
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.Init();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := Codeunit::"Power BI Report Synchronizer";
        JobQueueEntry."Parameter String" := 'TestContext';
        JobQueueEntry."Maximum No. of Attempts to Run" := 3;
        JobQueueEntry."No. of Attempts to Run" := 1;

        Commit();
        ClearLastError();
        exit(Codeunit.Run(Codeunit::"Power BI Report Synchronizer", JobQueueEntry));
    end;

    #endregion
}
