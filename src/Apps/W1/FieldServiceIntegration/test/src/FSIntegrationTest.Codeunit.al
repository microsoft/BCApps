// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.Integration.DynamicsFieldService;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.UOM;
using Microsoft.Integration.D365Sales;
using Microsoft.Integration.Dataverse;
using Microsoft.Integration.DynamicsFieldService;
using Microsoft.Integration.SyncEngine;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Setup;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Posting;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Service.Archive;
using Microsoft.Service.Document;
using Microsoft.Service.Setup;
using Microsoft.Service.Test;
using Microsoft.TestLibraries.DynamicsFieldService;
using System.Security.AccessControl;
using System.Security.Encryption;
using System.TestLibraries.Environment.Configuration;
using System.TestLibraries.Utilities;
using System.Threading;

codeunit 139204 "FS Integration Test"
{
    Subtype = Test;
    TestType = Uncategorized;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [FS Integration] [Connection Setup]
    end;

    var
        CRMProductName: Codeunit "CRM Product Name";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        FSIntegrationTestLibrary: Codeunit "FS Integration Test Library";
        Assert: Codeunit Assert;
        LibraryCRMIntegration: Codeunit "Library - CRM Integration";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryResource: Codeunit "Library - Resource";
        LibraryJob: Codeunit "Library - Job";
        LibraryRandom: Codeunit "Library - Random";
        ConnectionErr: Label 'The connection setup cannot be validated. Verify the settings and try again.';
        ConnectionSuccessMsg: Label 'The connection test was successful';
        JobQueueEntryStatusReadyErr: Label 'Job Queue Entry status should be Ready.';
        JobQueueEntryStatusOnHoldErr: Label 'Job Queue Entry status should be On Hold.';
        SetupSuccessfulMsg: Label 'The default setup for %1 synchronization has completed successfully.', Comment = '%1 - Dynamics 365 Field Service';
        HourUnitOfMeasureMustBePickedErr: label 'Field Service uses a fixed unit of measure for bookable resources - hour. You must pick a corresponding resource unit of measure.';
        SynchronizeEmptySetErr: Label 'Attempted to synchronize an empty set of records.';
        IsInitialized: Boolean;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RegisterConnection()
    var
        FSConnectionSetup: Record "FS Connection Setup";
        ConnectionName: Code[10];
    begin
        Initialize();

        ConnectionName := 'No. 1';
        UnregisterTableConnection(TableConnectionType::CRM, ConnectionName);

        // Get a disabled and unregistered connection
        CreateFSConnectionSetup(ConnectionName, 'invalid.dns.int', false);
        AssertConnectionNotRegistered(ConnectionName);

        // Enable it without registering it
        FSConnectionSetup.Get(ConnectionName);
        FSConnectionSetup."Is Enabled" := true;
        FSConnectionSetup.Modify(false);

        AssertConnectionNotRegistered(ConnectionName);

        // Register
        FSIntegrationTestLibrary.RegisterConnection(FSConnectionSetup);
        // Second attempt of registration skips registration if it exists
        FSIntegrationTestLibrary.RegisterConnection(FSConnectionSetup);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UnregisterConnection()
    var
        FSConnectionSetup: Record "FS Connection Setup";
        ConnectionName: Code[10];
    begin
        Initialize();

        ConnectionName := 'No. 1';
        UnregisterTableConnection(TableConnectionType::CRM, ConnectionName);

        // Get an enabled and registered connection
        CreateFSConnectionSetup(ConnectionName, 'invalid.dns.int', true);
        FSConnectionSetup.Get(ConnectionName);
        FSIntegrationTestLibrary.RegisterConnection(FSConnectionSetup);

        // Unregister and check
        FSIntegrationTestLibrary.UnregisterConnection(FSConnectionSetup);
        AssertConnectionNotRegistered(ConnectionName);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure JournalTemplateNameRequiredToEnable()
    var
        FSConnectionSetup: Record "FS Connection Setup";
        Any: Codeunit Any;
        DummyPassword: Text;
    begin
        // [FEATURE] [UT]
        Initialize();

        DummyPassword := Any.AlphanumericText(20);
        FSConnectionSetup.Init();
        FSConnectionSetup."User Name" := 'tester@domain.net';
        FSIntegrationTestLibrary.SetPassword(FSConnectionSetup, DummyPassword);
        FSConnectionSetup.Insert();

        asserterror FSConnectionSetup.Validate("Is Enabled", true);
        Assert.ExpectedError(FSConnectionSetup.FieldCaption("Job Journal Template"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure JournalTemplateNameNotRequiredToEnable()
    var
        FSConnectionSetup: Record "FS Connection Setup";
    begin
        // [FEATURE] [UT] Service Order Integration
        // [SCENARIO] Journal Template is not required to enable the Service integration type.
        // [GIVEN] FS Connection Setup, where "Is Enabled" = No.
        Initialize();
        InitSetup(false, '');

        // [GIVEN] Setup without Job Journal Template and Integration Type = Service.
        FSConnectionSetup."Integration Type" := FSConnectionSetup."Integration Type"::"Service and projects";
        FSConnectionSetup.Modify();

        // [THEN] Validate that the connection is enabled without error message (regarding job journal).
        asserterror FSConnectionSetup.Validate("Is Enabled", true);
        Assert.ExpectedError('You must enable the connection in page Dynamics 365 Sales Integration Setup');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure JournalBatchRequiredToEnable()
    var
        FSConnectionSetup: Record "FS Connection Setup";
        JobJournalTemplate: Record "Job Journal Template";
        Any: Codeunit Any;
        DummyPassword: Text;
    begin
        // [FEATURE] [UT]
        Initialize();
        LibraryJob.CreateJobJournalTemplate(JobJournalTemplate);
        JobJournalTemplate.Insert();
        DummyPassword := Any.AlphanumericText(20);
        FSConnectionSetup.Init();
        FSConnectionSetup."Server Address" := '@@test@@';
        FSIntegrationTestLibrary.SetPassword(FSConnectionSetup, DummyPassword);
        FSConnectionSetup."Job Journal Template" := JobJournalTemplate.Name;
        FSConnectionSetup.Insert();

        asserterror FSConnectionSetup.Validate("Is Enabled", true);
        Assert.ExpectedError(FSConnectionSetup.FieldCaption("Job Journal Batch"));
        if JobJournalTemplate.Find() then
            JobJournalTemplate.Delete();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure JournalBatchNotRequiredToEnable()
    var
        FSConnectionSetup: Record "FS Connection Setup";
        JobJournalTemplate: Record "Job Journal Template";
    begin
        // [FEATURE] [UT] Service Order Integration
        // [SCENARIO] Journal Batch is not required to enable the Service integration type.
        // [GIVEN] FS Connection Setup, where "Is Enabled" = No.
        Initialize();
        InitSetup(false, '');

        // [GIVEN] Setup without Job Journal Batch and Integration Type = Service.
        LibraryJob.CreateJobJournalTemplate(JobJournalTemplate);
        JobJournalTemplate.Insert();
        FSConnectionSetup."Job Journal Template" := JobJournalTemplate.Name;
        FSConnectionSetup."Integration Type" := FSConnectionSetup."Integration Type"::"Service and projects";
        FSConnectionSetup.Modify();

        // [THEN] Validate that the connection is enabled without error message (regarding job journal).
        asserterror FSConnectionSetup.Validate("Is Enabled", true);
        Assert.ExpectedError('You must enable the connection in page Dynamics 365 Sales Integration Setup');
        if JobJournalTemplate.Find() then
            JobJournalTemplate.Delete();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure HourUOMRequiredToEnable()
    var
        FSConnectionSetup: Record "FS Connection Setup";
        JobJournalTemplate: Record "Job Journal Template";
        JobJournalBatch: Record "Job Journal Batch";
        Any: Codeunit Any;
        DummyPassword: Text;
    begin
        // [FEATURE] [UT]
        Initialize();
        LibraryCRMIntegration.RegisterTestTableConnection();
        LibraryJob.CreateJobJournalTemplate(JobJournalTemplate);
        LibraryJob.CreateJobJournalBatch(JobJournalTemplate.Name, JobJournalBatch);
        DummyPassword := Any.AlphanumericText(20);

        FSConnectionSetup.Init();
        FSConnectionSetup."Server Address" := '@@test@@';
        FSIntegrationTestLibrary.SetPassword(FSConnectionSetup, DummyPassword);
        FSConnectionSetup."Job Journal Template" := JobJournalTemplate.Name;
        FSConnectionSetup."Job Journal Batch" := JobJournalBatch.Name;
        FSConnectionSetup.Insert();

        asserterror FSConnectionSetup.Validate("Is Enabled", true);
        Assert.ExpectedError(HourUnitOfMeasureMustBePickedErr);
        if JobJournalBatch.Find() then
            JobJournalBatch.Delete();
        if JobJournalTemplate.Find() then
            JobJournalTemplate.Delete();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ManualNoSeriesRequiredToSelectService()
    var
        FSConnectionSetup: Record "FS Connection Setup";
    begin
        // [FEATURE] [UI] Service Order Integration.
        // [SCENARIO] User selects "Service" in "Integration Type" field, but "Manual No. Series" is not selected.
        // [GIVEN] FS Connection Setup, where "Is Enabled" = Yes.
        Initialize();
        InitSetup(true, '');

        // [GIVEN] No Series of Service Order is not set to manual.
        InitServiceManagementSetup(false, false, false);

        // [WHEN] Set Integration Type to "Service".
        // [THEN] Error message "Manual No. Series is required for Service integration." appears.
        FSConnectionSetup.Get();
        asserterror FSConnectionSetup.Validate("Integration Type", FSConnectionSetup."Integration Type"::"Service and projects");
        Assert.ExpectedError('Please make sure that the No. Series setup is correct.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ManualNoSeriesNotRequiredToSelectProject()
    var
        FSConnectionSetup: Record "FS Connection Setup";
    begin
        // [FEATURE] [UI] Service Order Integration.
        // [SCENARIO] User selects "Project" in "Integration Type" field, but "Manual No. Series" is not selected.
        Initialize();
        // [GIVEN] FS Connection Setup, where "Is Enabled" = Yes.
        InitSetup(true, '');
        // [GIVEN] No Series of Service Order is not set to manual.
        InitServiceManagementSetup(false, false, false);

        // [WHEN] Set Integration Type to "Project".
        // [THEN] No error message appears.
        FSConnectionSetup.Get();
        FSConnectionSetup.Validate("Integration Type", FSConnectionSetup."Integration Type"::Projects);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ArchiveOfServiceOrdersIsAutomaticallyEnabled()
    var
        FSConnectionSetup: Record "FS Connection Setup";
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        // [FEATURE] [UI] Service Order Integration.
        // [SCENARIO] Archive Orders should be enabled for Service integration type.
        // [GIVEN] Disabled FS Connection Setup.
        Initialize();

        // [GIVEN] Service Managment Archive Flag is set to false.
        InitServiceManagementSetup(false, false, false);
        ServiceMgtSetup.Get();
        Assert.IsFalse(ServiceMgtSetup."Archive Orders", 'Archive Orders should be disabled.');

        // [WHEN] Field Service Integration is enabled.
        InitSetup(true, '');
        FSConnectionSetup.Get();
        FSConnectionSetup."Integration Type" := FSConnectionSetup."Integration Type"::"Service and projects";
        FSConnectionSetup.Modify(false);
        FSIntegrationTestLibrary.ResetConfiguration(FSConnectionSetup);

        // [THEN] Service Managment Archive Flag is set to true.
        ServiceMgtSetup.Get();
        Assert.IsTrue(ServiceMgtSetup."Archive Orders", 'Archive Orders should be enabled.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ArchiveOfServiceOrdersIsNotAutomaticallyEnabled()
    var
        FSConnectionSetup: Record "FS Connection Setup";
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        // [FEATURE] [UI] Service Order Integration
        // [SCENARIO] Archive Orders should not be enabled for default integration type.
        // [GIVEN] Disabled FS Connection Setup.
        Initialize();

        // [GIVEN] Service Managment Archive Flag is set to false.
        InitServiceManagementSetup(false, false, false);
        ServiceMgtSetup.Get();
        Assert.IsFalse(ServiceMgtSetup."Archive Orders", 'Archive Orders should be disabled.');

        // [WHEN] Field Service Integration is enabled.
        InitSetup(true, '');
        FSConnectionSetup.Get();
        FSIntegrationTestLibrary.ResetConfiguration(FSConnectionSetup);

        // [THEN] Service Managment Archive Flag is set to false for default integration type.
        ServiceMgtSetup.Get();
        Assert.IsFalse(ServiceMgtSetup."Archive Orders", 'Archive Orders should be enabled.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OneServiceItemLinePerOrderIsDisabled()
    var
        FSConnectionSetup: Record "FS Connection Setup";
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        // [FEATURE] [UI] Service Order Integration
        // [SCENARIO] One Service Item Line Per Order becomes enabled and this is not allowed.
        // [GIVEN] Disabled FS Connection Setup.
        Initialize();
        InitSetup(true, '');
        FSConnectionSetup.Get();
        FSConnectionSetup."Integration Type" := FSConnectionSetup."Integration Type"::"Service and projects";
        FSConnectionSetup.Modify(false);

        // [GIVEN] Service Managment Flag is set to false.
        InitServiceManagementSetup(false, false, false);

        // [WHEN] One Service Item Line Per Order becomes enabled.
        // [THEN] Error message "One Service Item Line Per Order is not allowed for Field Service Integration." appears.
        ServiceMgtSetup.Get();
        asserterror ServiceMgtSetup.Validate("One Service Item Line/Order", true);
        Assert.ExpectedError(FSConnectionSetup.FieldCaption("Is Enabled"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WorkingConnectionRequiredToEnable()
    var
        FSConnectionSetup: Record "FS Connection Setup";
        JobJournalTemplate: Record "Job Journal Template";
        JobJournalBatch: Record "Job Journal Batch";
        UnitOfMeasure: Record "Unit of Measure";
        Any: Codeunit Any;
        DummyPassword: Text;
    begin
        // [FEATURE] [UT]
        Initialize();
        LibraryCRMIntegration.RegisterTestTableConnection();
        LibraryJob.CreateJobJournalTemplate(JobJournalTemplate);
        LibraryJob.CreateJobJournalBatch(JobJournalTemplate.Name, JobJournalBatch);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryCRMIntegration.UnbindMockConnection();
        DummyPassword := Any.AlphanumericText(20);

        // Enter details in the page and enable the connection
        FSConnectionSetup.Init();
        FSConnectionSetup."Server Address" := 'https://nocrmhere.gov';
        FSConnectionSetup.Validate("User Name", 'tester@domain.net');
        FSIntegrationTestLibrary.SetPassword(FSConnectionSetup, DummyPassword);
        FSConnectionSetup."Job Journal Template" := JobJournalTemplate.Name;
        FSConnectionSetup."Job Journal Batch" := JobJournalBatch.Name;
        FSConnectionSetup."Hour Unit of Measure" := UnitOfMeasure.Code;
        FSConnectionSetup.Insert();

        asserterror FSConnectionSetup.Validate("Is Enabled", true);
        Assert.ExpectedError(ConnectionErr);
    end;

    [Test]
    procedure EnableConnectionCanResetIntegrationTableMappingsIfEmpty()
    var
        FSConnectionSetup: Record "FS Connection Setup";
        JobJournalTemplate: Record "Job Journal Template";
        JobJournalBatch: Record "Job Journal Batch";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        // [FEATURE] [Table Mapping] [UI]
        Initialize();
        LibraryCRMIntegration.RegisterTestTableConnection();
        LibraryCRMIntegration.EnsureCRMSystemUser();
        LibraryCRMIntegration.CreateCRMOrganization();
        LibraryJob.CreateJobJournalTemplate(JobJournalTemplate);
        LibraryJob.CreateJobJournalBatch(JobJournalTemplate.Name, JobJournalBatch);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        // [GIVEN] Table Mapping is empty
        Assert.TableIsEmpty(Database::"Integration Table Mapping");

        // [GIVEN] Connection is disabled
        FSConnectionSetup.DeleteAll();
        InitSetup(false, '');

        // [WHEN] Enable the connection
        FSConnectionSetup.Get();
        FSConnectionSetup."Job Journal Template" := JobJournalTemplate.Name;
        FSConnectionSetup."Job Journal Batch" := JobJournalBatch.Name;
        FSConnectionSetup."Hour Unit of Measure" := UnitOfMeasure.Code;
        FSConnectionSetup.Validate("Is Enabled", true);

        // [THEN] Table Mapping is filled
        Assert.TableIsNotEmpty(Database::"Integration Table Mapping");
    end;

    [Test]
    [HandlerFunctions('MessageOk')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CanTestConnectionWhenNotIsEnabled()
    var
        FSConnectionSetup: Record "FS Connection Setup";
        DummyPassword: Text;
    begin
        Initialize();
        LibraryCRMIntegration.RegisterTestTableConnection();
        LibraryCRMIntegration.EnsureCRMSystemUser();
        FSConnectionSetup.DeleteAll();
        FSConnectionSetup.Init();
        FSConnectionSetup."Server Address" := '@@test@@';
        FSConnectionSetup.Validate("User Name", 'tester@domain.net');
        DummyPassword := 'value';
        FSIntegrationTestLibrary.SetPassword(FSConnectionSetup, DummyPassword);
        FSConnectionSetup.Insert();

        FSIntegrationTestLibrary.PerformTestConnection(FSConnectionSetup);
    end;

    [Test]
    [HandlerFunctions('ConfirmYes,MessageOk')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InvokeResetConfigurationCreatesNewMappings()
    var
        JobQueueEntry: Record "Job Queue Entry";
        IntegrationTableMapping: Record "Integration Table Mapping";
        FSConnectionSetup: TestPage "FS Connection Setup";
    begin
        // [FEATURE] [Table Mapping] [UI]
        Initialize();

        // [GIVEN] Connection to CRM established
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        LibraryCRMIntegration.ConfigureCRM();

        // [GIVEN] No Integration Table Mapping records
        // [GIVEN] No Job Queue Entry records
        IntegrationTableMapping.DeleteAll(true);
        JobQueueEntry.DeleteAll();

        CreateFSConnectionSetup('', '@@test@@', true);

        // [GIVEN] FS Connection Setup page
        FSConnectionSetup.OpenEdit();

        // [WHEN] "Use Default Synchronization Setup" action is invoked
        FSConnectionSetup.ResetConfiguration.Invoke();

        // [THEN] Integration Table Mapping and Job Queue Entry tables are not empty
        Assert.AreNotEqual(0, IntegrationTableMapping.Count(), 'Expected the reset mappings to create new mappings');
        Assert.AreNotEqual(0, JobQueueEntry.Count(), 'Expected the reset mappings to create new job queue entries');

        // [THEN] Message "The default setup for Dynamics 365 Sales synchronization has completed successfully." appears
        Assert.ExpectedMessage(StrSubstNo(SetupSuccessfulMsg, CRMProductName.FSServiceName()), LibraryVariableStorage.DequeueText());
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EnableLocationMandatoryCreatesLocationMappingForEnabledFieldServiceSetup()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // [FEATURE] [Table Mapping] [UI]
        Initialize();

        // [GIVEN] Connection to CRM established
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        LibraryCRMIntegration.ConfigureCRM();

        // [GIVEN] No Integration Table Mapping records
        IntegrationTableMapping.DeleteAll(true);

        // [GIVEN] Enable FS Connection Setup
        CreateFSConnectionSetup('', '@@test@@', true);

        // [WHEN] Enable Location Mandatory
        EnableLocationMandatoryOnInventorySetup();

        // [THEN] Integration Table Mapping for Location is created        
        Assert.AreEqual(1, IntegrationTableMapping.Count(), 'Expects Location mappings to be created.');
    end;

    local procedure CreateFSConnectionSetup(PrimaryKey: Code[10]; HostName: Text; IsEnabledVar: Boolean)
    var
        FSConnectionSetup: Record "FS Connection Setup";
    begin
        if FSConnectionSetup.Get(PrimaryKey) then
            FSConnectionSetup.Delete();
        FSConnectionSetup.Init();
        FSConnectionSetup."Primary Key" := PrimaryKey;
        FSConnectionSetup."Server Address" := CopyStr(HostName, 1, MaxStrLen(FSConnectionSetup."Server Address"));
        FSConnectionSetup."Is Enabled" := IsEnabledVar;
        FSConnectionSetup."Authentication Type" := FSConnectionSetup."Authentication Type"::Office365;
        FSConnectionSetup.Validate("User Name", 'UserName@asEmail.net');
        // Empty username triggers username/password dialog
        FSConnectionSetup.Insert(true);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ActionSyncJobs()
    var
        FSConnectionSetup: TestPage "FS Connection Setup";
        JobQueueEntries: TestPage "Job Queue Entries";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] Action "Synch. Job Queue Entries" opens page with CRM synch. jobs.
        Initialize();
        // [GIVEN] FS Connection Setup, where "Is Enabled" = Yes
        InitSetup(true, '');
        // [GIVEN] 4 Job Queue Entries: 3 are for CRM Integration, 3 of them active
        InsertJobQueueEntries();
        // [WHEN] Run action "Synch. Job Queue Entries" on FS Connection Setup page
        FSConnectionSetup.OpenView();
        JobQueueEntries.Trap();
        FSConnectionSetup."Synch. Job Queue Entries".Invoke();
        // [THEN] Page "Job Queue Entries" is open, where are 3 jobs
        Assert.IsTrue(JobQueueEntries.First(), 'First');
        Assert.IsTrue(JobQueueEntries.Next(), 'Second');
        Assert.IsTrue(JobQueueEntries.Next(), 'Third');
        Assert.IsFalse(JobQueueEntries.Next(), 'Fourth should fail');
    end;

    [Test]
    [HandlerFunctions('MessageDequeue')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AllJobsActive()
    var
        FSConnectionSetupPage: TestPage "FS Connection Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] FS Connection Setup page shows '3 of 3' when all jobs are active
        Initialize();
        // [GIVEN] FS Connection Setup, where "Is Enabled" = Yes
        InitSetup(true, '');
        // [GIVEN] 4 Job Queue Entries: 3 are for CRM Integration, 3 of them active
        InsertJobQueueEntries();

        // [WHEN] Open FS Connection Setup page
        FSConnectionSetupPage.OpenView();

        // [THEN] Control "Active scheduled synchronization jobs" is '3 of 3'
        FSConnectionSetupPage.ScheduledSynchJobsActive.AssertEquals('3 of 3');

        // [WHEN] DrillDown on '3 of 3'
        LibraryVariableStorage.Enqueue('all scheduled synchronization jobs are ready or already processing.');
        FSConnectionSetupPage.ScheduledSynchJobsActive.DrillDown();
        // [THEN] Message : "all scheduled synchronization jobs are ready or already processing."
        // handled by MessageDequeue
    end;

    [Test]
    [HandlerFunctions('MessageDequeue')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestConnectionAction()
    var
        FSConnectionSetup: Record "FS Connection Setup";
        FSConnectionSetupPage: TestPage "FS Connection Setup";
    begin
        // [FEATURE] [UI]
        Initialize();
        LibraryCRMIntegration.RegisterTestTableConnection();
        LibraryCRMIntegration.EnsureCRMSystemUser();

        FSConnectionSetup.DeleteAll();
        InitSetup(true, '');
        // [GIVEN] Open FS Connection Setup page
        FSConnectionSetupPage.OpenEdit();
        // [WHEN] Run "Test Connection" action
        LibraryVariableStorage.Enqueue(ConnectionSuccessMsg);
        FSConnectionSetupPage."Test Connection".Invoke();
        // [THEN] Message: "The connection test was successful"
        // handled by MessageDequeue
    end;

    [Test]
    procedure StartInitialSynchAction()
    var
        FSConnectionSetupPage: TestPage "FS Connection Setup";
        CRMFullSynchReviewPage: TestPage "CRM Full Synch. Review";
    begin
        // [FEATURE] [UI]
        Initialize();
        LibraryCRMIntegration.ConfigureCRM();
        CreateTableMapping();
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        InitSetup(true, '');
        // [GIVEN] Open FS Connection Setup page
        FSConnectionSetupPage.OpenEdit();
        // [WHEN] run action StartInitialSynch
        CRMFullSynchReviewPage.Trap();
        FSConnectionSetupPage.StartInitialSynchAction.Invoke();
        // [THEN] CRMFullSynchReview page is open
        CRMFullSynchReviewPage.Close();
    end;

    [Test]
    procedure EnableJobQueueEntriesOnEnableFSConnection()
    var
        FSConnectionSetup: Record "FS Connection Setup";
        JobJournalTemplate: Record "Job Journal Template";
        JobJournalBatch: Record "Job Journal Batch";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        // [SCENARIO] Enabling CRM Connection move all CRM Job Queue Entries in "Ready" status
        Initialize();
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        LibraryJob.CreateJobJournalTemplate(JobJournalTemplate);
        LibraryJob.CreateJobJournalBatch(JobJournalTemplate.Name, JobJournalBatch);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);

        // [GIVEN] Connection Setup with Integration Table Mapping and Job Queue Entries
        CreateFSConnectionSetup();
        FSConnectionSetup.DeleteAll();
        InitSetup(false, '');

        // [WHEN] Enable the connection
        FSConnectionSetup.Get();
        FSConnectionSetup."Job Journal Template" := JobJournalTemplate.Name;
        FSConnectionSetup."Job Journal Batch" := JobJournalBatch.Name;
        FSConnectionSetup."Hour Unit of Measure" := UnitOfMeasure.Code;
        FSConnectionSetup.Validate("Is Enabled", true);
        FSConnectionSetup.Modify(true);

        // [THEN] All Job Queue Entries has Status = Ready
        VerifyJobQueueEntriesStatusIsReady();
        FSConnectionSetup.Validate("Is Enabled", false);
        FSConnectionSetup.Modify(true);
        FSConnectionSetup.Delete();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DisableJobQueueEntriesOnDisableFSConnection()
    var
        FSConnectionSetup: Record "FS Connection Setup";
    begin
        // [SCENARIO] Disabling CRM Connection move all CRM Job Queue Entries in "On Hold" status
        Initialize();

        // [GIVEN] FS Connection Setup with Integration Table Mapping and CRM Job Queue Entries
        CreateFSConnectionSetup();
        FSConnectionSetup.DeleteAll();
        InitSetup(true, '');

        // [WHEN] Disable the connection
        FSConnectionSetup.Get();
        FSConnectionSetup.Validate("Is Enabled", false);
        FSConnectionSetup.Modify(true);

        // [THEN] All CRM Job Queue Entries has Status = On Hold
        VerifyJobQueueEntriesStatusIsOnHold();
    end;

    [Test]
    [HandlerFunctions('FSAssistedSetupModalHandler,ConfirmYes')]
    procedure RunAssistedSetupFromFSConnectionSetup()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        FSConnectionSetupPage: TestPage "FS Connection Setup";
    begin
        // [SCENARIO 266927] FS Connection Assisted Setup can be opened from FS Connection Setup page
        Initialize();
        CRMConnectionSetup.Init();
        CRMConnectionSetup."Unit Group Mapping Enabled" := true;
        CRMConnectionSetup.Insert();

        InitSetup(true, '');
        // [GIVEN] FS Connection Setup page is opened, Server Address "SA"
        FSConnectionSetupPage.OpenEdit();
        FSConnectionSetupPage."Server Address".SetValue('TEST');

        // [WHEN] Assisted Setup is invoked
        FSConnectionSetupPage."Assisted Setup".Invoke();

        // [THEN] FS Connection Setup wizard is opened and Server Address = "SA"
        // Wizard page is opened in FSAssistedSetupModalHandler
        Assert.ExpectedMessage(FSConnectionSetupPage."Server Address".Value, LibraryVariableStorage.DequeueText());
        if CRMConnectionSetup.Get() then
            CRMConnectionSetup.Delete();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UpdateWorkOrderProductDefaultEstimated()
    var
        WorkOrderProduct: Record "FS Work Order Product";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [UI] Service Order Integration
        // [SCENARIO] User updates quantities on work order lines that are not posted in BC.
        // [GIVEN] FS Connection Setup, where "Is Enabled" = Yes.
        Initialize();
        InitSetup(true, '');

        // [GIVEN] Existing Service Line.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());

        // [GIVEN] Quantities on work order lines.
        WorkOrderProduct.LineStatus := WorkOrderProduct.LineStatus::Estimated;
        WorkOrderProduct.EstimateQuantity := 3;
        WorkOrderProduct.Quantity := 2;
        WorkOrderProduct.QtyToBill := 1;

        // [WHEN] Update quantities on work order lines that are not posted in BC.
        FSIntegrationTestLibrary.UpdateQuantities(WorkOrderProduct, ServiceLine, false);

        // [THEN] Quantities should be updated accordingly.
        Assert.AreEqual(WorkOrderProduct.EstimateQuantity, ServiceLine.Quantity, 'Quantity should be ' + Format(WorkOrderProduct.EstimateQuantity));
        Assert.AreEqual(0, ServiceLine."Qty. to Ship", 'Qty. to Ship should be 0');
        Assert.AreEqual(0, ServiceLine."Qty. to Invoice", 'Qty. to Invoice should be 0');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UpdateWorkOrderProductDefaultUsed()
    var
        WorkOrderProduct: Record "FS Work Order Product";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [UI] Service Order Integration
        // [SCENARIO] User updates quantities on work order lines that are not posted in BC.
        // [GIVEN] FS Connection Setup, where "Is Enabled" = Yes.
        Initialize();
        InitSetup(true, '');

        // [GIVEN] Existing Service Line.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());

        // [GIVEN] Quantities on work order lines.
        WorkOrderProduct.LineStatus := WorkOrderProduct.LineStatus::Used;
        WorkOrderProduct.EstimateQuantity := 3;
        WorkOrderProduct.Quantity := 2;
        WorkOrderProduct.QtyToBill := 1;

        // [WHEN] Update quantities on work order lines that are not posted in BC.
        FSIntegrationTestLibrary.UpdateQuantities(WorkOrderProduct, ServiceLine, false);

        // [THEN] Quantities should be updated accordingly.
        Assert.AreEqual(WorkOrderProduct.Quantity, ServiceLine.Quantity, 'Quantity should be ' + Format(WorkOrderProduct.Quantity));
        Assert.AreEqual(WorkOrderProduct.Quantity, ServiceLine."Qty. to Ship", 'Qty. to Ship should be ' + Format(WorkOrderProduct.Quantity));
        Assert.AreEqual(WorkOrderProduct.QtyToBill, ServiceLine."Qty. to Invoice", 'Qty. to Invoice should be ' + Format(WorkOrderProduct.QtyToBill));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UpdateWorkOrderProductToShipHigherThanExpected()
    var
        WorkOrderProduct: Record "FS Work Order Product";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [UI] Service Order Integration
        // [SCENARIO] User updates quantities on work order lines that are not posted in BC.
        // [GIVEN] FS Connection Setup, where "Is Enabled" = Yes.
        Initialize();
        InitSetup(true, '');

        // [GIVEN] Existing Service Line.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());

        // [GIVEN] Quantities on work order lines.
        WorkOrderProduct.LineStatus := WorkOrderProduct.LineStatus::Used;
        WorkOrderProduct.EstimateQuantity := 3;
        WorkOrderProduct.Quantity := 10;
        WorkOrderProduct.QtyToBill := 1;

        // [WHEN] Update quantities on work order lines that are not posted in BC.
        FSIntegrationTestLibrary.UpdateQuantities(WorkOrderProduct, ServiceLine, false);

        // [THEN] Quantities should be updated accordingly. Qty to Ship increases Quantity.
        Assert.AreEqual(WorkOrderProduct.Quantity, ServiceLine.Quantity, 'Quantity should be ' + Format(WorkOrderProduct.Quantity));
        Assert.AreEqual(WorkOrderProduct.Quantity, ServiceLine."Qty. to Ship", 'Qty. to Ship should be ' + Format(WorkOrderProduct.Quantity));
        Assert.AreEqual(WorkOrderProduct.QtyToBill, ServiceLine."Qty. to Invoice", 'Qty. to Invoice should be ' + Format(WorkOrderProduct.QtyToBill));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UpdateWorkOrderProductToInvoiceHigherThanExpected()
    var
        WorkOrderProduct: Record "FS Work Order Product";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [UI] Service Order Integration
        // [SCENARIO] User updates quantities on work order lines that are not posted in BC.
        // [GIVEN] FS Connection Setup, where "Is Enabled" = Yes.
        Initialize();
        InitSetup(true, '');

        // [GIVEN] Existing Service Line.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());

        // [GIVEN] Quantities on work order lines.
        WorkOrderProduct.LineStatus := WorkOrderProduct.LineStatus::Used;
        WorkOrderProduct.EstimateQuantity := 3;
        WorkOrderProduct.Quantity := 2;
        WorkOrderProduct.QtyToBill := 10;

        // [WHEN] Update quantities on work order lines that are not posted in BC.
        FSIntegrationTestLibrary.UpdateQuantities(WorkOrderProduct, ServiceLine, false);

        // [THEN] Quantities should be updated accordingly. Qty to Invoice increases all other quantities.
        Assert.AreEqual(WorkOrderProduct.QtyToBill, ServiceLine.Quantity, 'Quantity should be ' + Format(WorkOrderProduct.QtyToBill));
        Assert.AreEqual(WorkOrderProduct.QtyToBill, ServiceLine."Qty. to Ship", 'Qty. to Ship should be ' + Format(WorkOrderProduct.QtyToBill));
        Assert.AreEqual(WorkOrderProduct.QtyToBill, ServiceLine."Qty. to Invoice", 'Qty. to Invoice should be ' + Format(WorkOrderProduct.QtyToBill));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UpdateWorkOrderProductAlreadyPosted()
    var
        WorkOrderProduct: Record "FS Work Order Product";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [UI] Service Order Integration
        // [SCENARIO] User updates quantities on work order lines that are not posted in BC.
        // [GIVEN] FS Connection Setup, where "Is Enabled" = Yes.
        Initialize();
        InitSetup(true, '');

        // [GIVEN] Existing Service Line.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());

        // [GIVEN] Quantities on work order lines.
        WorkOrderProduct.LineStatus := WorkOrderProduct.LineStatus::Used;
        WorkOrderProduct.EstimateQuantity := 5;
        WorkOrderProduct.Quantity := 3;
        WorkOrderProduct.QtyToBill := 2;
        ServiceLine."Quantity Shipped" := 2;
        ServiceLine."Quantity Invoiced" := 1;

        // [WHEN] Update quantities on work order lines that are partly posted in BC.
        FSIntegrationTestLibrary.UpdateQuantities(WorkOrderProduct, ServiceLine, false);

        // [THEN] Quantities should be updated accordingly. Posted quantities are considered.
        Assert.AreEqual(WorkOrderProduct.Quantity, ServiceLine.Quantity, 'Quantity should be ' + Format(WorkOrderProduct.Quantity));
        Assert.AreEqual(WorkOrderProduct.Quantity - ServiceLine."Quantity Shipped", ServiceLine."Qty. to Ship", 'Qty. to Ship should be ' + Format(WorkOrderProduct.Quantity - ServiceLine."Quantity Shipped"));
        Assert.AreEqual(WorkOrderProduct.QtyToBill - ServiceLine."Quantity Invoiced", ServiceLine."Qty. to Invoice", 'Qty. to Invoice should be ' + Format(WorkOrderProduct.QtyToBill - ServiceLine."Quantity Invoiced"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UpdateWorkOrderServiceDefaultEstimated()
    var
        WorkOrderService: Record "FS Work Order Service";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [UI] Service Order Integration
        // [SCENARIO] User updates quantities on work order lines that are not posted in BC.
        // [GIVEN] FS Connection Setup, where "Is Enabled" = Yes.
        Initialize();
        InitSetup(true, '');

        // [GIVEN] Existing Service Line.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());

        // [GIVEN] Quantities on work order lines.
        WorkOrderService.LineStatus := WorkOrderService.LineStatus::Estimated;
        WorkOrderService.EstimateDuration := 180;
        WorkOrderService.Duration := 120;
        WorkOrderService.DurationToBill := 60;

        // [WHEN] Update quantities on work order lines that are not posted in BC.
        FSIntegrationTestLibrary.UpdateQuantities(WorkOrderService, ServiceLine, false);

        // [THEN] Quantities should be updated accordingly.
        Assert.AreEqual(WorkOrderService.EstimateDuration / 60, ServiceLine.Quantity, 'Quantity should be ' + Format(WorkOrderService.EstimateDuration / 60));
        Assert.AreEqual(0, ServiceLine."Qty. to Ship", 'Qty. to Ship should be 0');
        Assert.AreEqual(0, ServiceLine."Qty. to Invoice", 'Qty. to Invoice should be 0');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UpdateWorkOrderServiceDefault()
    var
        WorkOrderService: Record "FS Work Order Service";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [UI] Service Order Integration
        // [SCENARIO] User updates quantities on work order lines that are not posted in BC.
        // [GIVEN] FS Connection Setup, where "Is Enabled" = Yes.
        Initialize();
        InitSetup(true, '');

        // [GIVEN] Existing Service Line.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());

        // [GIVEN] Quantities on work order lines.
        WorkOrderService.LineStatus := WorkOrderService.LineStatus::Used;
        WorkOrderService.EstimateDuration := 180;
        WorkOrderService.Duration := 120;
        WorkOrderService.DurationToBill := 60;

        // [WHEN] Update quantities on work order lines that are not posted in BC.
        FSIntegrationTestLibrary.UpdateQuantities(WorkOrderService, ServiceLine, false);

        // [THEN] Quantities should be updated accordingly.
        Assert.AreEqual(WorkOrderService.Duration / 60, ServiceLine.Quantity, 'Quantity should be ' + Format(WorkOrderService.Duration / 60));
        Assert.AreEqual(WorkOrderService.Duration / 60, ServiceLine."Qty. to Ship", 'Qty. to Ship should be ' + Format(WorkOrderService.Duration / 60));
        Assert.AreEqual(WorkOrderService.DurationToBill / 60, ServiceLine."Qty. to Invoice", 'Qty. to Invoice should be ' + Format(WorkOrderService.DurationToBill / 60));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UpdateWorkOrderServiceToShipHigherThanExpected()
    var
        WorkOrderService: Record "FS Work Order Service";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [UI] Service Order Integration
        // [SCENARIO] User updates quantities on work order lines that are not posted in BC.
        // [GIVEN] FS Connection Setup, where "Is Enabled" = Yes.
        Initialize();
        InitSetup(true, '');

        // [GIVEN] Existing Service Line.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());

        // [GIVEN] Quantities on work order lines.
        WorkOrderService.LineStatus := WorkOrderService.LineStatus::Used;
        WorkOrderService.EstimateDuration := 180;
        WorkOrderService.Duration := 240;
        WorkOrderService.DurationToBill := 60;

        // [WHEN] Update quantities on work order lines that are not posted in BC.
        FSIntegrationTestLibrary.UpdateQuantities(WorkOrderService, ServiceLine, false);

        // [THEN] Quantities should be updated accordingly. Qty to Ship increases Quantity.
        Assert.AreEqual(WorkOrderService.Duration / 60, ServiceLine.Quantity, 'Duration should be ' + Format(WorkOrderService.Duration / 60));
        Assert.AreEqual(WorkOrderService.Duration / 60, ServiceLine."Qty. to Ship", 'Qty. to Ship should be ' + Format(WorkOrderService.Duration / 60));
        Assert.AreEqual(WorkOrderService.DurationToBill / 60, ServiceLine."Qty. to Invoice", 'Qty. to Invoice should be ' + Format(WorkOrderService.DurationToBill / 60));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UpdateWorkOrderServiceToInvoiceHigherThanExpected()
    var
        WorkOrderService: Record "FS Work Order Service";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [UI] Service Order Integration
        // [SCENARIO] User updates quantities on work order lines that are not posted in BC.
        // [GIVEN] FS Connection Setup, where "Is Enabled" = Yes.
        Initialize();
        InitSetup(true, '');

        // [GIVEN] Existing Service Line.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());

        // [GIVEN] Quantities on work order lines.
        WorkOrderService.LineStatus := WorkOrderService.LineStatus::Used;
        WorkOrderService.EstimateDuration := 180;
        WorkOrderService.Duration := 120;
        WorkOrderService.DurationToBill := 240;

        // [WHEN] Update quantities on work order lines that are not posted in BC.
        FSIntegrationTestLibrary.UpdateQuantities(WorkOrderService, ServiceLine, false);

        // [THEN] Quantities should be updated accordingly. Qty to Invoice increases all other quantities.
        Assert.AreEqual(WorkOrderService.DurationToBill / 60, ServiceLine.Quantity, 'Quantity should be ' + Format(WorkOrderService.DurationToBill / 60));
        Assert.AreEqual(WorkOrderService.DurationToBill / 60, ServiceLine."Qty. to Ship", 'Qty. to Ship should be ' + Format(WorkOrderService.DurationToBill / 60));
        Assert.AreEqual(WorkOrderService.DurationToBill / 60, ServiceLine."Qty. to Invoice", 'Qty. to Invoice should be ' + Format(WorkOrderService.DurationToBill / 60));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UpdateWorkOrderServiceAlreadyPosted()
    var
        WorkOrderService: Record "FS Work Order Service";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [UI] Service Order Integration
        // [SCENARIO] User updates quantities on work order lines that are not posted in BC.
        // [GIVEN] FS Connection Setup, where "Is Enabled" = Yes.
        Initialize();
        InitSetup(true, '');

        // [GIVEN] Existing Service Line.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());

        // [GIVEN] Quantities on work order lines.
        WorkOrderService.LineStatus := WorkOrderService.LineStatus::Used;
        WorkOrderService.EstimateDuration := 300;
        WorkOrderService.Duration := 180;
        WorkOrderService.DurationToBill := 120;
        ServiceLine."Quantity Shipped" := 2;
        ServiceLine."Quantity Invoiced" := 1;

        // [WHEN] Update quantities on work order lines that are partly posted in BC.
        FSIntegrationTestLibrary.UpdateQuantities(WorkOrderService, ServiceLine, false);

        // [THEN] Quantities should be updated accordingly. Posted Quantities are considered.
        Assert.AreEqual(WorkOrderService.Duration / 60, ServiceLine.Quantity, 'Quantity should be ' + Format(WorkOrderService.Duration / 60));
        Assert.AreEqual(WorkOrderService.Duration / 60 - ServiceLine."Quantity Shipped", ServiceLine."Qty. to Ship", 'Qty. to Ship should be ' + Format(WorkOrderService.Duration / 60 - ServiceLine."Quantity Shipped"));
        Assert.AreEqual(WorkOrderService.DurationToBill / 60 - ServiceLine."Quantity Invoiced", ServiceLine."Qty. to Invoice", 'Qty. to Invoice should be ' + Format(WorkOrderService.DurationToBill / 60 - ServiceLine."Quantity Invoiced", ServiceLine."Qty. to Invoice"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UpdateFSBookableResourceBookingDefault()
    var
        FSBookableResourceBooking: Record "FS Bookable Resource Booking";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [UI] Service Order Integration
        // [SCENARIO] User updates quantities on booking lines that are not posted in BC.
        // [GIVEN] FS Connection Setup, where "Is Enabled" = Yes.
        Initialize();
        InitSetup(true, '');

        // [GIVEN] Existing Service Line.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());

        // [GIVEN] Quantities on booking lines.
        FSBookableResourceBooking.Duration := 120;

        // [WHEN] Update quantities on booking lines that are not posted in BC.
        FSIntegrationTestLibrary.UpdateQuantities(FSBookableResourceBooking, ServiceLine);

        // [THEN] Quantities should be updated accordingly. 
        Assert.AreEqual(FSBookableResourceBooking.Duration / 60 - ServiceLine."Quantity Consumed", ServiceLine."Qty. to Consume", 'Qty. to Consume should be ' + Format(FSBookableResourceBooking.Duration / 60));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UpdateFSBookableResourceBookingAlreadyExistingQuantities()
    var
        FSBookableResourceBooking: Record "FS Bookable Resource Booking";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [UI] Service Order Integration
        // [SCENARIO] User updates quantities on booking lines that are not posted in BC.
        // [GIVEN] FS Connection Setup, where "Is Enabled" = Yes.
        Initialize();
        InitSetup(true, '');

        // [GIVEN] Existing Service Line.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Resource, LibraryResource.CreateResourceNo());

        // [GIVEN] Quantities on booking lines.
        FSBookableResourceBooking.Duration := 180;
        ServiceLine.Validate(Quantity, 5);
        ServiceLine.Validate("Qty. to Consume", 3);

        // [WHEN] Update quantities on booking lines that are not posted in BC.
        FSIntegrationTestLibrary.UpdateQuantities(FSBookableResourceBooking, ServiceLine);

        // [THEN] Quantities should be updated accordingly. Existing Quantities are reset.
        Assert.AreEqual(FSBookableResourceBooking.Duration / 60 - ServiceLine."Quantity Consumed", ServiceLine."Qty. to Consume", 'Qty. to Consume should be ' + Format(FSBookableResourceBooking.Duration / 60 - ServiceLine."Quantity Consumed"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IgnorePostedJobJournalLinesInFilterForProductEstimatedQuantity()
    var
        FSConnectionSetup: Record "FS Connection Setup";
        FSWorkOrderProduct: Record "FS Work Order Product";
        RecordRef: RecordRef;
        IgnoreRecord: Boolean;
    begin
        // [FEATURE] [UI] Service Order Integration
        // [SCENARIO] User adds quantity with LineStatus=Estimated in FS.
        // [GIVEN] FS Connection Setup, where "Is Enabled" = Yes.
        Initialize();
        InitSetup(true, '');
        FSConnectionSetup.Get();
        FSConnectionSetup."Integration Type" := "FS Integration Type"::Projects;
        FSConnectionSetup.Modify(false);

        // [GIVEN] Existing Work Order Line
        FSWorkOrderProduct.LineStatus := FSWorkOrderProduct.LineStatus::Estimated;
        FSWorkOrderProduct.EstimateQuantity := 5;
        FSWorkOrderProduct.Quantity := 5;

        // [GIVEN] Existing Work Order Line as reference
        RecordRef.GetTable(FSWorkOrderProduct);

        // [WHEN] Filter is build -> ignore estimated lines
        FSIntegrationTestLibrary.IgnorePostedJobJournalLinesOnQueryPostFilterIgnoreRecord(RecordRef, IgnoreRecord);

        // [THEN] Record should be ignored.
        Assert.IsTrue(IgnoreRecord, 'Record should be ignored.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IgnorePostedJobJournalLinesInFilterForServiceEstimatedQuantity()
    var
        FSConnectionSetup: Record "FS Connection Setup";
        FSWorkOrderService: Record "FS Work Order Service";
        RecordRef: RecordRef;
        IgnoreRecord: Boolean;
    begin
        // [FEATURE] [UI] Service Order Integration
        // [SCENARIO] User adds quantity with LineStatus=Estimated in FS.
        // [GIVEN] FS Connection Setup, where "Is Enabled" = Yes.
        Initialize();
        InitSetup(true, '');
        FSConnectionSetup.Get();
        FSConnectionSetup."Integration Type" := "FS Integration Type"::Projects;
        FSConnectionSetup.Modify(false);

        // [GIVEN] Existing Work Order Line
        FSWorkOrderService.LineStatus := FSWorkOrderService.LineStatus::Estimated;
        FSWorkOrderService.EstimateDuration := 300;
        FSWorkOrderService.Duration := 300;

        // [GIVEN] Existing Work Order Line as reference
        RecordRef.GetTable(FSWorkOrderService);

        // [WHEN] Filter is build -> ignore estimated lines
        FSIntegrationTestLibrary.IgnorePostedJobJournalLinesOnQueryPostFilterIgnoreRecord(RecordRef, IgnoreRecord);

        // [THEN] Record should be ignored.
        Assert.IsTrue(IgnoreRecord, 'Record should be ignored.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IgnorePostedJobJournalLinesInFilterForProductUsedQuantity()
    var
        FSConnectionSetup: Record "FS Connection Setup";
        FSWorkOrderProduct: Record "FS Work Order Product";
        RecordRef: RecordRef;
        IgnoreRecord: Boolean;
    begin
        // [FEATURE] [UI] Service Order Integration
        // [SCENARIO] User adds quantity with LineStatus=Used in FS.
        // [GIVEN] FS Connection Setup, where "Is Enabled" = Yes.
        Initialize();
        InitSetup(true, '');
        FSConnectionSetup.Get();
        FSConnectionSetup."Integration Type" := "FS Integration Type"::Projects;
        FSConnectionSetup.Modify(false);

        // [GIVEN] Existing Work Order Line
        FSWorkOrderProduct.LineStatus := FSWorkOrderProduct.LineStatus::Used;
        FSWorkOrderProduct.EstimateQuantity := 5;
        FSWorkOrderProduct.Quantity := 5;

        // [GIVEN] Existing Work Order Line as reference
        RecordRef.GetTable(FSWorkOrderProduct);

        // [WHEN] Filter is build 
        FSIntegrationTestLibrary.IgnorePostedJobJournalLinesOnQueryPostFilterIgnoreRecord(RecordRef, IgnoreRecord);

        // [THEN] Record should not be ignored.
        Assert.IsFalse(IgnoreRecord, 'Record should not be ignored.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IgnorePostedJobJournalLinesInFilterForServiceUsedQuantity()
    var
        FSConnectionSetup: Record "FS Connection Setup";
        FSWorkOrderService: Record "FS Work Order Service";
        RecordRef: RecordRef;
        IgnoreRecord: Boolean;
    begin
        // [FEATURE] [UI] Service Order Integration
        // [SCENARIO] User adds quantity with LineStatus=Used in FS.
        // [GIVEN] FS Connection Setup, where "Is Enabled" = Yes.
        Initialize();
        InitSetup(true, '');
        FSConnectionSetup.Get();
        FSConnectionSetup."Integration Type" := "FS Integration Type"::Projects;
        FSConnectionSetup.Modify(false);

        // [GIVEN] Existing Work Order Line
        FSWorkOrderService.LineStatus := FSWorkOrderService.LineStatus::Used;
        FSWorkOrderService.EstimateDuration := 300;
        FSWorkOrderService.Duration := 300;

        // [GIVEN] Existing Work Order Line as reference
        RecordRef.GetTable(FSWorkOrderService);

        // [WHEN] Filter is build -> consider used lines
        FSIntegrationTestLibrary.IgnorePostedJobJournalLinesOnQueryPostFilterIgnoreRecord(RecordRef, IgnoreRecord);

        // [THEN] Record should not be ignored.
        Assert.IsFalse(IgnoreRecord, 'Record should not be ignored.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IgnoreArchivedServiceOrdersInFilterNotArchivedYet()
    var
        FSConnectionSetup: Record "FS Connection Setup";
        FSWorkOrder: Record "FS Work Order";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        CRMIntegrationRecord: Record "CRM Integration Record";
        RecordRef: RecordRef;
        IgnoreRecord: Boolean;
    begin
        // [FEATURE] [UI] Service Order Integration
        // [SCENARIO] Ignore Archived Service Orders in Filter.
        // [GIVEN] FS Connection Setup, where "Is Enabled" = Yes.
        Initialize();
        InitSetup(true, '');
        FSConnectionSetup.Get();
        FSConnectionSetup."Integration Type" := "FS Integration Type"::"Service and projects";
        FSConnectionSetup.Modify(false);

        // [GIVEN] Existing Service Header
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());

        // [GIVEN] Existing Work Order Line as reference
        FSWorkOrder.WorkOrderId := CreateGuid();
        CRMIntegrationRecord.CoupleCRMIDToRecordID(FSWorkOrder.WorkOrderId, ServiceHeader.RecordId());

        // [GIVEN] Existing Work Order Line as reference
        RecordRef.GetTable(ServiceHeader);

        // [WHEN] Filter is build -> consider used lines
        FSIntegrationTestLibrary.IgnoreArchievedServiceOrdersOnQueryPostFilterIgnoreRecord(RecordRef, IgnoreRecord);

        // [THEN] Servie Order should be ignored
        Assert.IsFalse(IgnoreRecord, 'Record should not be ignored.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MarkArchivedServiceOrder()
    var
        FSConnectionSetup: Record "FS Connection Setup";
        ServiceHeader: Record "Service Header";
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        // [FEATURE] [UI] Service Order Integration
        // [SCENARIO] Service Header becomes linked to archive.
        // [GIVEN] FS Connection Setup, where "Is Enabled" = Yes.
        Initialize();
        InitSetup(true, '');
        FSConnectionSetup.Get();
        FSConnectionSetup."Integration Type" := "FS Integration Type"::"Service and projects";
        FSConnectionSetup.Modify(false);

        // [GIVEN] Archive Service Orders is enabled
        InitServiceManagementSetup(true, true, false);

        // [GIVEN] Existing Service Header
        LibraryService.CreateServiceDocumentForCustomerNo(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());

        // [GIVEN] Existing Work Order as reference.
        CRMIntegrationRecord."Table ID" := Database::"Service Header";
        CRMIntegrationRecord."Integration ID" := ServiceHeader.SystemId;
        CRMIntegrationRecord.Insert(false);

        // [WHEN] Marked as archived.
        FSIntegrationTestLibrary.MarkArchivedServiceOrder(ServiceHeader);

        // [THEN] Integration Record should be marked as archived.
        Clear(CRMIntegrationRecord);
        CRMIntegrationRecord.SetRange("Table ID", Database::"Service Header");
        CRMIntegrationRecord.SetRange("Integration ID", ServiceHeader.SystemId);
        CRMIntegrationRecord.FindFirst();

        Assert.IsTrue(CRMIntegrationRecord."Archived Service Order", 'Record should be marked as archived.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MarkArchivedServiceOrderLine()
    var
        FSConnectionSetup: Record "FS Connection Setup";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceLineArchive: Record "Service Line Archive";
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        // [FEATURE] [UI] Service Order Integration
        // [SCENARIO] Service Line becomes linked to archive.
        // [GIVEN] FS Connection Setup, where "Is Enabled" = Yes.
        Initialize();
        InitSetup(true, '');
        FSConnectionSetup.Get();
        FSConnectionSetup."Integration Type" := "FS Integration Type"::"Service and projects";
        FSConnectionSetup.Modify(false);

        // [GIVEN] Archive Service Orders is enabled
        InitServiceManagementSetup(true, true, false);

        // [GIVEN] Existing Service Header
        LibraryService.CreateServiceDocumentForCustomerNo(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindFirst();

        // [GIVEN] Existing Work Order as reference.
        CRMIntegrationRecord."Table ID" := Database::"Service Line";
        CRMIntegrationRecord."Integration ID" := ServiceLine.SystemId;
        CRMIntegrationRecord.Insert(false);

        // [WHEN] Marked as archived.
        ServiceLineArchive."Document Type" := ServiceLine."Document Type";
        ServiceLineArchive."Document No." := ServiceLine."Document No.";
        ServiceLineArchive."Line No." := ServiceLine."Line No.";
        ServiceLineArchive.Insert(false);
        FSIntegrationTestLibrary.MarkArchivedServiceOrderLine(ServiceLine, ServiceLineArchive);

        // [THEN] Service Line and Service Line Archive should be linked.
        Clear(CRMIntegrationRecord);
        CRMIntegrationRecord.SetRange("Table ID", Database::"Service Line");
        CRMIntegrationRecord.SetRange("Integration ID", ServiceLine.SystemId);
        CRMIntegrationRecord.FindFirst();

        Assert.AreEqual(CRMIntegrationRecord."Archived Service Line Id", ServiceLineArchive.SystemId, 'Archived Service Line Id should be ' + Format(ServiceLineArchive.SystemId));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ArchiveServiceOrder()
    var
        FSConnectionSetup: Record "FS Connection Setup";
        ServiceHeader: Record "Service Header";
        ArchivedServiceOrders: List of [Code[20]];
    begin
        // [FEATURE] [UI] Service Order Integration
        // [SCENARIO] Service Header becomes archived.
        // [GIVEN] FS Connection Setup, where "Is Enabled" = Yes.
        Initialize();
        InitSetup(true, '');
        FSConnectionSetup.Get();
        FSConnectionSetup."Integration Type" := "FS Integration Type"::"Service and projects";
        FSConnectionSetup.Modify(false);

        // [GIVEN] Archive Service Orders is enabled
        InitServiceManagementSetup(true, true, false);

        // [GIVEN] Existing Service Header
        LibraryService.CreateServiceDocumentForCustomerNo(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());

        // [WHEN] Archive Service Order.
        FSIntegrationTestLibrary.ArchiveServiceOrder(ServiceHeader, ArchivedServiceOrders);

        // [THEN] Version should increase
        ServiceHeader.Get(ServiceHeader."Document Type"::Order, ServiceHeader."No.");
        ServiceHeader.CalcFields("No. of Archived Versions");
        Assert.AreEqual(1, ServiceHeader."No. of Archived Versions", 'Record should be marked as archived.');
    end;


    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ArchiveServiceOrderWithDisabledSetupFlag()
    var
        FSConnectionSetup: Record "FS Connection Setup";
        ServiceHeader: Record "Service Header";
        ArchivedServiceOrders: List of [Code[20]];
    begin
        // [FEATURE] [UI] Service Order Integration
        // [SCENARIO] Service Header becomes archived but setup flag is disabled. 
        // [GIVEN] FS Connection Setup, where "Is Enabled" = Yes.
        Initialize();
        InitSetup(true, '');
        FSConnectionSetup.Get();
        FSConnectionSetup."Integration Type" := "FS Integration Type"::"Service and projects";
        FSConnectionSetup.Modify(false);

        // [GIVEN] Archive Service Orders is disabled
        InitServiceManagementSetup(true, false, false);

        // [GIVEN] Existing Service Header
        LibraryService.CreateServiceDocumentForCustomerNo(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());

        // [WHEN] Archive Service Order.
        FSIntegrationTestLibrary.ArchiveServiceOrder(ServiceHeader, ArchivedServiceOrders);

        // [THEN] Version should not increase
        ServiceHeader.Get(ServiceHeader."Document Type"::Order, ServiceHeader."No.");
        ServiceHeader.CalcFields("No. of Archived Versions");
        Assert.AreEqual(0, ServiceHeader."No. of Archived Versions", 'Record should not be marked as archived.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ArchiveServiceOrderMultiple()
    var
        FSConnectionSetup: Record "FS Connection Setup";
        ServiceHeader: Record "Service Header";
        ArchivedServiceOrders: List of [Code[20]];
        I: Integer;
    begin
        // [FEATURE] [UI] Service Order Integration
        // [SCENARIO] Service Header becomes archived multiple times.
        // [GIVEN] FS Connection Setup, where "Is Enabled" = Yes.
        Initialize();
        InitSetup(true, '');
        FSConnectionSetup.Get();
        FSConnectionSetup."Integration Type" := "FS Integration Type"::"Service and projects";
        FSConnectionSetup.Modify(false);

        // [GIVEN] Archive Service Orders is enabled
        InitServiceManagementSetup(true, true, false);

        // [GIVEN] Existing Service Header
        LibraryService.CreateServiceDocumentForCustomerNo(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());

        // [WHEN] Archive Service Order.
        for I := 1 to 5 do
            FSIntegrationTestLibrary.ArchiveServiceOrder(ServiceHeader, ArchivedServiceOrders);

        // [THEN] Version should increase
        ServiceHeader.Get(ServiceHeader."Document Type"::Order, ServiceHeader."No.");
        ServiceHeader.CalcFields("No. of Archived Versions");
        Assert.AreEqual(1, ServiceHeader."No. of Archived Versions", 'Record should be marked as archived.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UpdateWorkOrderProduct()
    var
        ServiceLineArchive: Record "Service Line Archive";
        FSWorkOrderProduct: Record "FS Work Order Product";
    begin
        // [FEATURE] [UI] Service Order Integration
        // [SCENARIO] Archive Service Orders transfer to FS.
        // [GIVEN] FS Connection Setup, where "Is Enabled" = Yes.
        Initialize();
        InitSetup(true, '');

        // [GIVEN] Existing Service Line Archive.
        ServiceLineArchive."Qty. to Ship" := 1;
        ServiceLineArchive."Quantity Shipped" := 2;
        ServiceLineArchive."Qty. to Invoice" := 3;
        ServiceLineArchive."Quantity Invoiced" := 4;
        ServiceLineArchive."Qty. to Consume" := 5;
        ServiceLineArchive."Quantity Consumed" := 6;

        // [GIVEN] ExistingWork Order Product.
        FSWorkOrderProduct.Insert();

        // [WHEN] Update quantities on booking lines that are not posted in BC.
        FSIntegrationTestLibrary.UpdateWorkOrderProduct(ServiceLineArchive, FSWorkORderProduct);

        // [THEN] Quantities should be updated accordingly.
        Assert.AreEqual(ServiceLineArchive."Qty. to Ship" + ServiceLineArchive."Quantity Shipped", FSWorkOrderProduct.QuantityShipped, 'Quantity should be ' + Format(ServiceLineArchive."Qty. to Ship" + ServiceLineArchive."Quantity Shipped"));
        Assert.AreEqual(ServiceLineArchive."Qty. to Invoice" + ServiceLineArchive."Quantity Invoiced", FSWorkOrderProduct.QuantityInvoiced, 'Qty. to Invoice should be ' + Format(ServiceLineArchive."Qty. to Invoice" + ServiceLineArchive."Quantity Invoiced"));
        Assert.AreEqual(ServiceLineArchive."Qty. to Consume" + ServiceLineArchive."Quantity Consumed", FSWorkOrderProduct.QuantityConsumed, 'Qty. to Consume should be ' + Format(ServiceLineArchive."Qty. to Consume" + ServiceLineArchive."Quantity Consumed"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UpdateWorkOrderService()
    var
        ServiceLineArchive: Record "Service Line Archive";
        FSWorkOrderService: Record "FS Work Order Service";
    begin
        // [FEATURE] [UI] Service Order Integration
        // [SCENARIO] Archive Service Orders transfer to FS.
        // [GIVEN] FS Connection Setup, where "Is Enabled" = Yes.
        Initialize();
        InitSetup(true, '');

        // [GIVEN] Existing Service Line Archive.
        ServiceLineArchive."Qty. to Ship" := 1;
        ServiceLineArchive."Quantity Shipped" := 2;
        ServiceLineArchive."Qty. to Invoice" := 3;
        ServiceLineArchive."Quantity Invoiced" := 4;
        ServiceLineArchive."Qty. to Consume" := 5;
        ServiceLineArchive."Quantity Consumed" := 6;

        // [GIVEN] ExistingWork Order Service.
        FSWorkOrderService.Insert();

        // [WHEN] Update quantities on booking lines that are not posted in BC.
        FSIntegrationTestLibrary.UpdateWorkOrderService(ServiceLineArchive, FSWorkOrderService);

        // [THEN] Quantities should be updated accordingly.
        Assert.AreEqual((ServiceLineArchive."Qty. to Ship" + ServiceLineArchive."Quantity Shipped") * 60, FSWorkOrderService.DurationShipped, 'Duration should be ' + Format(ServiceLineArchive."Qty. to Ship" + ServiceLineArchive."Quantity Shipped"));
        Assert.AreEqual((ServiceLineArchive."Qty. to Invoice" + ServiceLineArchive."Quantity Invoiced") * 60, FSWorkOrderService.DurationInvoiced, 'Duration Invoiced should be ' + Format(ServiceLineArchive."Qty. to Invoice" + ServiceLineArchive."Quantity Invoiced"));
        Assert.AreEqual((ServiceLineArchive."Qty. to Consume" + ServiceLineArchive."Quantity Consumed") * 60, FSWorkOrderService.DurationConsumed, 'Duration Consumed should be ' + Format(ServiceLineArchive."Qty. to Consume" + ServiceLineArchive."Quantity Consumed"));
    end;

    [Test]
    procedure QuantityConsumedIsNotWrittenIntoWorkOrderRecordForPostingPreview()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        WorkOrderProduct: Record "FS Work Order Product";
        CRMIntegrationRecord: Record "CRM Integration Record";
        JobJnlPost: Codeunit "Job Jnl.-Post";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        // [SCENARIO 524900] Quantity Consumed is not written into Work Order record for Posting Preview
        // [GIVEN] FS Connection Setup, where "Is Enabled" = Yes.
        Initialize();
        InitSetup(true, '');

        // [GIVEN] Create Project and Project Task
        CreateJobAndJobTask(Job, JobTask);

        // [GIVEN] Create Project Journal Line
        CreateJobJournalLine(JobJournalLine, JobTask, CreateItem());

        // [GIVEN] Create Work Order Product
        CreateWorkOrderProduct(WorkOrderProduct);
        WorkOrderProduct.EstimateQuantity := JobJournalLine.Quantity;
        WorkOrderProduct.Modify();

        // [GIVEN] Create CRM Integration Record
        CRMIntegrationRecord.CoupleCRMIDToRecordID(WorkOrderProduct.WorkOrderProductId, JobJournalLine.RecordId());
        CRMIntegrationRecord.Get(WorkOrderProduct.WorkOrderProductId, JobJournalLine.SystemId);

        // [WHEN] Run Posting Preview procedure
        BindSubscription(JobJnlPost);
        asserterror GenJnlPostPreview.Preview(JobJnlPost, JobJournalLine);
        UnbindSubscription(JobJnlPost);

        // [THEN] Verify that Quantity Consumed is not written into Work Order record.
        WorkOrderProduct.Get(CRMIntegrationRecord."CRM ID");
        Assert.AreEqual(0, WorkOrderProduct.QuantityConsumed, 'Quantity Consumed should not be written into Work Order record for Posting Preview action.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure InitialItemSynchronizationDisablesCustomerAssetConversion()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMProduct: Record "CRM Product";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        CRMUom: Record "CRM Uom";
        Currency: Record Currency;
        IntegrationTableMapping: Record "Integration Table Mapping";
        Item: Record Item;
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
        JobID: Guid;
    begin
        // [FEATURE] [Item-Product Mapping]
        // [SCENARIO] The first synchronization of an item disables native Field Service customer asset creation.
        Initialize();
        InitializeItemProductSynchronization();

        // [GIVEN] An uncoupled item whose unit of measure and currency are coupled to Dataverse.
        CRMSetupDefaults.ResetItemProductMapping('ITEM-PRODUCT', false);
        CreateItemWithCoupledUnitOfMeasure(Item, CRMUom);
        LibraryCRMIntegration.CreateCoupledCurrencyAndTransactionCurrency(Currency, CRMTransactioncurrency);
        IntegrationTableMapping.Get('ITEM-PRODUCT');

        // [WHEN] The item is synchronized to a new Field Service product.
        JobID := CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Item.RecordId(), true, true);

        // [THEN] Native Field Service customer asset creation is disabled on the new product.
        VerifySuccessfulIntegrationSynchJob(JobID, 1, 0);
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(Item.RecordId()), 'The item should be coupled to a product.');
        CRMProduct.Get(CRMIntegrationRecord."CRM ID");
        Assert.IsFalse(CRMProduct.ConvertToCustomerAsset, 'Convert to Customer Asset should be disabled.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ItemSynchronizationDisablesCustomerAssetConversion()
    var
        Item: Record Item;
        CRMProduct: Record "CRM Product";
        CRMUom: Record "CRM Uom";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
        JobID: Guid;
    begin
        // [FEATURE] [Item-Product Mapping]
        // [SCENARIO] Synchronizing an item disables native Field Service customer asset creation.
        Initialize();
        InitializeItemProductSynchronization();

        // [GIVEN] A coupled item and product where Convert to Customer Asset is Yes and the existing mapping has no conversion rule.
        CRMSetupDefaults.ResetItemProductMapping('ITEM-PRODUCT', false);
        CreateItemWithCoupledUnitOfMeasure(Item, CRMUom);
        LibraryCRMIntegration.CoupleItem(Item, CRMUom, CRMProduct);
        CRMProduct.ConvertToCustomerAsset := true;
        CRMProduct.Modify();

        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", 'ITEM-PRODUCT');
        IntegrationFieldMapping.SetRange("Integration Table Field No.", CRMProduct.FieldNo(ConvertToCustomerAsset));
        IntegrationFieldMapping.DeleteAll();
        IntegrationTableMapping.Get('ITEM-PRODUCT');

        // [WHEN] The item is synchronized to the Field Service product.
        JobID := CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Item.RecordId(), true, false);

        // [THEN] Native Field Service customer asset creation is disabled.
        VerifySuccessfulIntegrationSynchJob(JobID, 0, 1);
        CRMProduct.Get(CRMProduct.ProductId);
        Assert.IsFalse(CRMProduct.ConvertToCustomerAsset, 'Convert to Customer Asset should be disabled.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ItemProductMappingDisablesCustomerAssetConversion()
    var
        CRMProduct: Record "CRM Product";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
    begin
        // [FEATURE] [Item-Product Mapping]
        // [SCENARIO] The item-product mapping always disables native Field Service customer asset creation.
        Initialize();
        InitSetup(true, '');

        // [WHEN] The default item-product mapping is reset.
        CRMSetupDefaults.ResetItemProductMapping('ITEM-PRODUCT', false);

        // [THEN] Convert to Customer Asset is mapped to constant false in the outbound direction.
        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", 'ITEM-PRODUCT');
        IntegrationFieldMapping.SetRange("Integration Table Field No.", CRMProduct.FieldNo(ConvertToCustomerAsset));
        Assert.IsTrue(IntegrationFieldMapping.FindFirst(), 'The Convert to Customer Asset mapping should exist.');
        Assert.AreEqual(0, IntegrationFieldMapping."Field No.", 'The mapping should use a constant value.');
        Assert.AreEqual(IntegrationFieldMapping.Direction::ToIntegrationTable, IntegrationFieldMapping.Direction, 'The mapping should be outbound.');
        Assert.AreEqual('false', IntegrationFieldMapping."Constant Value", 'The mapping should disable Convert to Customer Asset.');
    end;

    [Test]
    procedure ModifiedServiceItemLineRespectsHeaderFilter()
    var
        ServiceHeader: Record "Service Header";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // [FEATURE] [AI test 0.3] [FS Integration] [Mapping Filters]
        // [SCENARIO 649829] A modified item line cannot export an excluded service order.
        Initialize();

        // [GIVEN] Order "S" has a modified item line but is excluded by the header mapping.
        PrepareModifiedChildExport(ServiceHeader, IntegrationTableMapping, true, false);

        // [WHEN] The scheduled synchronization scans modified child lines.
        RunScheduledServiceOrderSync(IntegrationTableMapping);

        // [THEN] "S" is not submitted to auxiliary synchronization.
        VerifySynchronizationSelection(ServiceHeader.RecordId(), false, 0);
    end;

    [Test]
    procedure ModifiedServiceLineRespectsHeaderFilter()
    var
        ServiceHeader: Record "Service Header";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // [FEATURE] [AI test 0.3] [FS Integration] [Mapping Filters]
        // [SCENARIO 649829] A modified service line cannot export an excluded service order.
        Initialize();

        // [GIVEN] Order "S" has a modified service line but is excluded by the header mapping.
        PrepareModifiedChildExport(ServiceHeader, IntegrationTableMapping, false, false);

        // [WHEN] The scheduled synchronization scans modified child lines.
        RunScheduledServiceOrderSync(IntegrationTableMapping);

        // [THEN] "S" is not submitted to auxiliary synchronization.
        VerifySynchronizationSelection(ServiceHeader.RecordId(), false, 0);
    end;

    [Test]
    procedure ModifiedServiceItemLineExportsMatchingHeader()
    var
        ServiceHeader: Record "Service Header";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // [FEATURE] [AI test 0.3] [FS Integration] [Mapping Filters]
        // [SCENARIO 649829] A modified item line exports a matching, otherwise unchanged order.
        Initialize();

        // [GIVEN] Order "S" matches the mapping and only its item line is newer than the watermark.
        PrepareModifiedChildExport(ServiceHeader, IntegrationTableMapping, true, true);

        // [WHEN] The scheduled synchronization scans modified child lines.
        RunScheduledServiceOrderSync(IntegrationTableMapping);

        // [THEN] "S" is submitted exactly once.
        VerifySynchronizationSelection(ServiceHeader.RecordId(), true, 1);
    end;

    [Test]
    procedure ModifiedServiceLineExportsMatchingHeader()
    var
        ServiceHeader: Record "Service Header";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // [FEATURE] [AI test 0.3] [FS Integration] [Mapping Filters]
        // [SCENARIO 649829] A modified service line exports a matching, otherwise unchanged order.
        Initialize();

        // [GIVEN] Order "S" matches the mapping and only its service line is newer than the watermark.
        PrepareModifiedChildExport(ServiceHeader, IntegrationTableMapping, false, true);

        // [WHEN] The scheduled synchronization scans modified child lines.
        RunScheduledServiceOrderSync(IntegrationTableMapping);

        // [THEN] "S" is submitted exactly once.
        VerifySynchronizationSelection(ServiceHeader.RecordId(), true, 1);
    end;

    [Test]
    procedure AuxiliaryProductImportRespectsLineStatus()
    var
        ServiceHeader: Record "Service Header";
        FSWorkOrder: Record "FS Work Order";
        ExcludedProduct: Record "FS Work Order Product";
        IncludedProduct: Record "FS Work Order Product";
    begin
        // [FEATURE] [AI test 0.3] [FS Integration] [Mapping Filters]
        // [SCENARIO 649829] Only used products in the current work order are imported.
        Initialize();

        // [GIVEN] Products "P1" and "P2" differ in Line Status, with a used product on another order.
        PrepareProductImport(ServiceHeader, FSWorkOrder, ExcludedProduct, IncludedProduct, false);

        // [WHEN] The unchanged parent work order synchronizes its children.
        RunAuxiliaryServiceOrderSync(ServiceHeader, FSWorkOrder, true);

        // [THEN] Only "P2" is selected.
        VerifyFilteredPair(ExcludedProduct.RecordId(), IncludedProduct.RecordId());
    end;

    [Test]
    procedure AuxiliaryProductUpdateKeepsExcludedCoupling()
    var
        ServiceHeader: Record "Service Header";
        FSWorkOrder: Record "FS Work Order";
        ExcludedProduct: Record "FS Work Order Product";
        IncludedProduct: Record "FS Work Order Product";
    begin
        // [FEATURE] [AI test 0.3] [FS Integration] [Mapping Filters]
        // [SCENARIO 649829] Product mapping filters also gate coupled updates without deleting their lines.
        Initialize();

        // [GIVEN] Both products are coupled, but "P1" is excluded by Line Status.
        PrepareProductImport(ServiceHeader, FSWorkOrder, ExcludedProduct, IncludedProduct, true);

        // [WHEN] The unchanged parent work order synchronizes its children.
        RunAuxiliaryServiceOrderSync(ServiceHeader, FSWorkOrder, true);

        // [THEN] "P1" remains coupled and unchanged, and only "P2" is selected.
        VerifyCoupledServiceLinePreserved(ExcludedProduct.WorkOrderProductId);
        VerifyFilteredPair(ExcludedProduct.RecordId(), IncludedProduct.RecordId());
    end;

    [Test]
    procedure AuxiliaryServiceImportRespectsDuration()
    var
        ServiceHeader: Record "Service Header";
        FSWorkOrder: Record "FS Work Order";
        ExcludedService: Record "FS Work Order Service";
        IncludedService: Record "FS Work Order Service";
    begin
        // [FEATURE] [AI test 0.3] [FS Integration] [Mapping Filters]
        // [SCENARIO 649829] Service duration filters apply to auxiliary imports.
        Initialize();

        // [GIVEN] Services "S1" and "S2" differ in Duration, with a matching service on another order.
        PrepareServiceImport(ServiceHeader, FSWorkOrder, ExcludedService, IncludedService, false);

        // [WHEN] The unchanged parent work order synchronizes its children.
        RunAuxiliaryServiceOrderSync(ServiceHeader, FSWorkOrder, true);

        // [THEN] Only "S2" is selected.
        VerifyFilteredPair(ExcludedService.RecordId(), IncludedService.RecordId());
    end;

    [Test]
    procedure AuxiliaryServiceUpdateKeepsExcludedCoupling()
    var
        ServiceHeader: Record "Service Header";
        FSWorkOrder: Record "FS Work Order";
        ExcludedService: Record "FS Work Order Service";
        IncludedService: Record "FS Work Order Service";
    begin
        // [FEATURE] [AI test 0.3] [FS Integration] [Mapping Filters]
        // [SCENARIO 649829] Service duration filters gate coupled updates without deleting their lines.
        Initialize();

        // [GIVEN] Both services are coupled, but "S1" is excluded by Duration.
        PrepareServiceImport(ServiceHeader, FSWorkOrder, ExcludedService, IncludedService, true);

        // [WHEN] The unchanged parent work order synchronizes its children.
        RunAuxiliaryServiceOrderSync(ServiceHeader, FSWorkOrder, true);

        // [THEN] "S1" remains coupled and unchanged, and only "S2" is selected.
        VerifyCoupledServiceLinePreserved(ExcludedService.WorkOrderServiceId);
        VerifyFilteredPair(ExcludedService.RecordId(), IncludedService.RecordId());
    end;

    [Test]
    procedure AuxiliaryBookingImportRespectsDuration()
    var
        ServiceHeader: Record "Service Header";
        FSWorkOrder: Record "FS Work Order";
        ExcludedBooking: Record "FS Bookable Resource Booking";
        IncludedBooking: Record "FS Bookable Resource Booking";
    begin
        // [FEATURE] [AI test 0.3] [FS Integration] [Mapping Filters]
        // [SCENARIO 649829] Additional booking filters intersect the completed-booking restriction.
        Initialize();

        // [GIVEN] Completed bookings "B1" and "B2" differ in Duration.
        PrepareBookingImport(ServiceHeader, FSWorkOrder, ExcludedBooking, IncludedBooking, false);

        // [WHEN] The unchanged parent work order synchronizes its children.
        RunAuxiliaryServiceOrderSync(ServiceHeader, FSWorkOrder, true);

        // [THEN] Only "B2" is selected, not bookings on other orders or with other statuses.
        VerifyFilteredPair(ExcludedBooking.RecordId(), IncludedBooking.RecordId());
    end;

    [Test]
    procedure AuxiliaryBookingUpdateKeepsExcludedCoupling()
    var
        ServiceHeader: Record "Service Header";
        FSWorkOrder: Record "FS Work Order";
        ExcludedBooking: Record "FS Bookable Resource Booking";
        IncludedBooking: Record "FS Bookable Resource Booking";
    begin
        // [FEATURE] [AI test 0.3] [FS Integration] [Mapping Filters]
        // [SCENARIO 649829] Booking filters gate coupled updates without deleting their resource lines.
        Initialize();

        // [GIVEN] Both bookings are coupled, but "B1" is excluded by Duration.
        PrepareBookingImport(ServiceHeader, FSWorkOrder, ExcludedBooking, IncludedBooking, true);

        // [WHEN] The unchanged parent work order synchronizes its children.
        RunAuxiliaryServiceOrderSync(ServiceHeader, FSWorkOrder, true);

        // [THEN] "B1" remains coupled and unchanged, and only "B2" is selected.
        VerifyCoupledServiceLinePreserved(ExcludedBooking.BookableResourceBookingId);
        VerifyFilteredPair(ExcludedBooking.RecordId(), IncludedBooking.RecordId());
    end;

    [Test]
    procedure AuxiliaryIncidentImportRespectsMapping()
    var
        ServiceHeader: Record "Service Header";
        FSWorkOrder: Record "FS Work Order";
        ExcludedIncident: Record "FS Work Order Incident";
        IncludedIncident: Record "FS Work Order Incident";
    begin
        // [FEATURE] [AI test 0.3] [FS Integration] [Mapping Filters]
        // [SCENARIO 649829] Incident imports apply the selected integration-table filter.
        Initialize();

        // [GIVEN] Incidents "I1" and "I2" differ in Name.
        InitializeAuxiliarySynchronization();
        CreateCoupledServiceOrder(ServiceHeader, FSWorkOrder);
        CreateAuxiliaryIncident(ExcludedIncident, FSWorkOrder, 'EXCLUDED');
        CreateAuxiliaryIncident(IncludedIncident, FSWorkOrder, 'INCLUDED');
        SetMappingFieldRange('SRVORDERITEMLINE', IncludedIncident.FieldNo(Name), 'INCLUDED', true);

        // [WHEN] The unchanged parent work order synchronizes its children.
        RunAuxiliaryServiceOrderSync(ServiceHeader, FSWorkOrder, true);

        // [THEN] Only "I2" is selected.
        VerifyFilteredPair(ExcludedIncident.RecordId(), IncludedIncident.RecordId());
    end;

    [Test]
    procedure AuxiliaryProductIdFilterCannotWidenScope()
    var
        ServiceHeader: Record "Service Header";
        OtherServiceHeader: Record "Service Header";
        FSWorkOrder: Record "FS Work Order";
        OtherWorkOrder: Record "FS Work Order";
        CurrentProduct: Record "FS Work Order Product";
        OtherProduct: Record "FS Work Order Product";
    begin
        // [FEATURE] [AI test 0.3] [FS Integration] [Mapping Filters]
        // [SCENARIO 649829] Conflicting product GUID filters intersect rather than replace the selected IDs.
        Initialize();

        // [GIVEN] The mapping selects "P2" on another order, not the current order's "P1".
        InitializeAuxiliarySynchronization();
        CreateCoupledServiceOrder(ServiceHeader, FSWorkOrder);
        CreateCoupledServiceOrder(OtherServiceHeader, OtherWorkOrder);
        CreateAuxiliaryProduct(CurrentProduct, FSWorkOrder, false);
        CreateAuxiliaryProduct(OtherProduct, OtherWorkOrder, true);
        SetMappingFieldRange('SRVORDERLINE-ITEM', OtherProduct.FieldNo(WorkOrderProductId), OtherProduct.WorkOrderProductId, true);

        // [WHEN] The current work order synchronizes its children.
        RunAuxiliaryServiceOrderSync(ServiceHeader, FSWorkOrder, true);

        // [THEN] Neither product is selected and no empty set is delegated.
        VerifySynchronizationSelection(CurrentProduct.RecordId(), false, 0);
    end;

    [Test]
    procedure AuxiliaryServiceParentFilterCannotWidenScope()
    var
        ServiceHeader: Record "Service Header";
        OtherServiceHeader: Record "Service Header";
        FSWorkOrder: Record "FS Work Order";
        OtherWorkOrder: Record "FS Work Order";
        CurrentService: Record "FS Work Order Service";
        OtherService: Record "FS Work Order Service";
    begin
        // [FEATURE] [AI test 0.3] [FS Integration] [Mapping Filters]
        // [SCENARIO 649829] A mapping's parent filter cannot select services belonging to another order.
        Initialize();

        // [GIVEN] The mapping selects another work order.
        InitializeAuxiliarySynchronization();
        CreateCoupledServiceOrder(ServiceHeader, FSWorkOrder);
        CreateCoupledServiceOrder(OtherServiceHeader, OtherWorkOrder);
        CreateAuxiliaryService(CurrentService, FSWorkOrder, 30);
        CreateAuxiliaryService(OtherService, OtherWorkOrder, 60);
        SetMappingFieldRange('SRVORDERLINE-SERVICE', OtherService.FieldNo(WorkOrder), OtherWorkOrder.WorkOrderId, true);

        // [WHEN] The current work order synchronizes its children.
        RunAuxiliaryServiceOrderSync(ServiceHeader, FSWorkOrder, true);

        // [THEN] No service is selected and no empty set is delegated.
        VerifySynchronizationSelection(CurrentService.RecordId(), false, 0);
    end;

    [Test]
    procedure AuxiliaryBookingStatusConflictSelectsNothing()
    var
        ServiceHeader: Record "Service Header";
        FSWorkOrder: Record "FS Work Order";
        CompletedBooking: Record "FS Bookable Resource Booking";
        ScheduledBooking: Record "FS Bookable Resource Booking";
    begin
        // [FEATURE] [AI test 0.3] [FS Integration] [Mapping Filters]
        // [SCENARIO 649829] A scheduled-status mapping cannot overwrite the completed-booking restriction.
        Initialize();

        // [GIVEN] The mapping selects scheduled bookings, while auxiliary sync requires completed bookings.
        InitializeAuxiliarySynchronization();
        CreateCoupledServiceOrder(ServiceHeader, FSWorkOrder);
        CreateAuxiliaryBooking(CompletedBooking, FSWorkOrder, 60, true);
        CreateAuxiliaryBooking(ScheduledBooking, FSWorkOrder, 60, false);
        SetMappingFieldRange('SRVORDERLINE-RESOURC', ScheduledBooking.FieldNo(BookingStatus), ScheduledBooking.BookingStatus, true);

        // [WHEN] The current work order synchronizes its children.
        RunAuxiliaryServiceOrderSync(ServiceHeader, FSWorkOrder, true);

        // [THEN] No booking is selected and no empty set is delegated.
        VerifySynchronizationSelection(CompletedBooking.RecordId(), false, 0);
    end;

    [Test]
    procedure SkippedBookingsDoNotProduceUnboundedImport()
    var
        ServiceHeader: Record "Service Header";
        OtherServiceHeader: Record "Service Header";
        FSWorkOrder: Record "FS Work Order";
        OtherWorkOrder: Record "FS Work Order";
        SkippedBooking: Record "FS Bookable Resource Booking";
        OtherBooking: Record "FS Bookable Resource Booking";
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        // [FEATURE] [AI test 0.3] [FS Integration] [Mapping Filters]
        // [SCENARIO 649829] An empty GUID list after skip-reimport processing is not an unbounded booking view.
        Initialize();

        // [GIVEN] The only current booking is marked to skip reimport; another order has a booking.
        InitializeAuxiliarySynchronization();
        CreateCoupledServiceOrder(ServiceHeader, FSWorkOrder);
        CreateCoupledServiceOrder(OtherServiceHeader, OtherWorkOrder);
        CreateAuxiliaryBooking(SkippedBooking, FSWorkOrder, 60, true);
        CreateAuxiliaryBooking(OtherBooking, OtherWorkOrder, 60, true);
        CRMIntegrationRecord."CRM ID" := SkippedBooking.BookableResourceBookingId;
        CRMIntegrationRecord."Table ID" := Database::"Service Line";
        CRMIntegrationRecord."Skip Reimport" := true;
        CRMIntegrationRecord."Last Synch. Modified On" := SkippedBooking.ModifiedOn + 60000;
        CRMIntegrationRecord.Insert();

        // [WHEN] The current work order synchronizes its children.
        RunAuxiliaryServiceOrderSync(ServiceHeader, FSWorkOrder, true);

        // [THEN] Neither booking is selected and no empty set is delegated.
        VerifySynchronizationSelection(SkippedBooking.RecordId(), false, 0);
    end;

    [Test]
    procedure EmptyBookingMappingKeepsParentAndStatus()
    var
        ServiceHeader: Record "Service Header";
        FSWorkOrder: Record "FS Work Order";
        ExcludedBooking: Record "FS Bookable Resource Booking";
        IncludedBooking: Record "FS Bookable Resource Booking";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // [FEATURE] [AI test 0.3] [FS Integration] [Mapping Filters]
        // [SCENARIO 649829] An empty mapping filter retains the production parent and completed-status restrictions.
        Initialize();

        // [GIVEN] Two completed bookings on this order and decoys with other parents or statuses.
        PrepareBookingImport(ServiceHeader, FSWorkOrder, ExcludedBooking, IncludedBooking, false);
        IntegrationTableMapping.Get('SRVORDERLINE-RESOURC');
        IntegrationTableMapping.SetIntegrationTableFilter('');
#pragma warning disable AA0214
        IntegrationTableMapping.Modify();
#pragma warning restore AA0214

        // [WHEN] The work order synchronizes without an additional mapping filter.
        RunAuxiliaryServiceOrderSync(ServiceHeader, FSWorkOrder, true);

        // [THEN] Both current completed bookings remain selected.
        VerifySynchronizationSelection(ExcludedBooking.RecordId(), true, 2);
        VerifySynchronizationSelection(IncludedBooking.RecordId(), true, 2);
    end;

    [Test]
    procedure AuxiliaryProductExportRespectsLineFilter()
    var
        ServiceHeader: Record "Service Header";
        FSWorkOrder: Record "FS Work Order";
        ExcludedLine: Record "Service Line";
        IncludedLine: Record "Service Line";
    begin
        // [FEATURE] [AI test 0.3] [FS Integration] [Mapping Filters]
        // [SCENARIO 649829] Auxiliary product exports apply the service-line table filter.
        Initialize();

        // [GIVEN] Lines "L1" and "L2" differ in Description, with a matching line on another order.
        PrepareLineExport(ServiceHeader, FSWorkOrder, ExcludedLine, IncludedLine, false);

        // [WHEN] The unchanged service order synchronizes its children.
        RunAuxiliaryServiceOrderSync(ServiceHeader, FSWorkOrder, false);

        // [THEN] Only "L2" is selected.
        VerifyFilteredPair(ExcludedLine.RecordId(), IncludedLine.RecordId());
    end;

    [Test]
    procedure AuxiliaryServiceExportRespectsLineFilter()
    var
        ServiceHeader: Record "Service Header";
        FSWorkOrder: Record "FS Work Order";
        ExcludedLine: Record "Service Line";
        IncludedLine: Record "Service Line";
    begin
        // [FEATURE] [AI test 0.3] [FS Integration] [Mapping Filters]
        // [SCENARIO 649829] Auxiliary service exports apply the service-line table filter.
        Initialize();

        // [GIVEN] Lines "L1" and "L2" differ in Description, with a matching line on another order.
        PrepareLineExport(ServiceHeader, FSWorkOrder, ExcludedLine, IncludedLine, true);

        // [WHEN] The unchanged service order synchronizes its children.
        RunAuxiliaryServiceOrderSync(ServiceHeader, FSWorkOrder, false);

        // [THEN] Only "L2" is selected.
        VerifyFilteredPair(ExcludedLine.RecordId(), IncludedLine.RecordId());
    end;

    [Test]
    procedure AuxiliaryIncidentExportRespectsItemLineFilter()
    var
        ServiceHeader: Record "Service Header";
        FSWorkOrder: Record "FS Work Order";
        ExcludedLine: Record "Service Item Line";
        IncludedLine: Record "Service Item Line";
        BookingLine: Record "Service Item Line";
    begin
        // [FEATURE] [AI test 0.3] [FS Integration] [Mapping Filters]
        // [SCENARIO 649829] Item-line filters intersect the non-booking restriction for incident exports.
        Initialize();

        // [GIVEN] Item lines "L1" and "L2" differ in Description, and "L3" is a booking line.
        InitializeAuxiliarySynchronization();
        CreateCoupledServiceOrder(ServiceHeader, FSWorkOrder);
        CreateAuxiliaryItemLine(ExcludedLine, ServiceHeader, 'EXCLUDED', false);
        CreateAuxiliaryItemLine(IncludedLine, ServiceHeader, 'INCLUDED', false);
        CreateAuxiliaryItemLine(BookingLine, ServiceHeader, 'INCLUDED', true);
        SetMappingFieldRange('SRVORDERITEMLINE', IncludedLine.FieldNo(Description), 'INCLUDED', false);

        // [WHEN] The unchanged service order synchronizes its children.
        RunAuxiliaryServiceOrderSync(ServiceHeader, FSWorkOrder, false);

        // [THEN] Only "L2" is selected.
        VerifyFilteredPair(ExcludedLine.RecordId(), IncludedLine.RecordId());
    end;

    [Test]
    procedure AuxiliaryExportParentFilterCannotWidenScope()
    var
        ServiceHeader: Record "Service Header";
        OtherServiceHeader: Record "Service Header";
        FSWorkOrder: Record "FS Work Order";
        OtherWorkOrder: Record "FS Work Order";
        CurrentLine: Record "Service Line";
        OtherLine: Record "Service Line";
    begin
        // [FEATURE] [AI test 0.3] [FS Integration] [Mapping Filters]
        // [SCENARIO 649829] A mapping's document filter cannot replace the auxiliary export parent.
        Initialize();

        // [GIVEN] The mapping selects a line on another service order.
        InitializeAuxiliarySynchronization();
        CreateCoupledServiceOrder(ServiceHeader, FSWorkOrder);
        CreateCoupledServiceOrder(OtherServiceHeader, OtherWorkOrder);
        CreateAuxiliaryServiceLine(CurrentLine, ServiceHeader, false, false, 'EXCLUDED');
        CreateAuxiliaryServiceLine(OtherLine, OtherServiceHeader, false, false, 'INCLUDED');
        SetMappingFieldRange('SRVORDERLINE-ITEM', OtherLine.FieldNo("Document No."), OtherServiceHeader."No.", false);

        // [WHEN] The current service order synchronizes its children.
        RunAuxiliaryServiceOrderSync(ServiceHeader, FSWorkOrder, false);

        // [THEN] No service line is selected and no empty set is delegated.
        VerifySynchronizationSelection(CurrentLine.RecordId(), false, 0);
    end;

    [Test]
    procedure TargetSpecificExportRespectsMappingFilter()
    var
        ServiceHeader: Record "Service Header";
        FSWorkOrder: Record "FS Work Order";
        ExcludedLine: Record "Service Line";
        IncludedLine: Record "Service Line";
        ServiceLineRecordRef: RecordRef;
    begin
        // [FEATURE] [AI test 0.3] [FS Integration] [Mapping Filters]
        // [SCENARIO 649829] The target-specific export filters its supplied record set.
        Initialize();

        // [GIVEN] A product mapping excludes "L1" from the current order's line view.
        PrepareLineExport(ServiceHeader, FSWorkOrder, ExcludedLine, IncludedLine, false);
        ExcludedLine.FilterGroup(2);
        ExcludedLine.SetRange("Document Type", ServiceHeader."Document Type");
        ExcludedLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLineRecordRef.GetTable(ExcludedLine);
        FSIntegrationTestLibrary.ClearSynchronizationCandidates();
        BindSubscription(FSIntegrationTestLibrary);

        // [WHEN] The target-specific export runs.
        FSIntegrationTestLibrary.SynchRecordsToIntegrationTable(ServiceLineRecordRef, Database::"FS Work Order Product", false, false);
        UnbindSubscription(FSIntegrationTestLibrary);

        // [THEN] Only "L2" reaches per-record synchronization.
        Assert.AreEqual(2, ServiceLineRecordRef.FilterGroup(), 'The caller filter group must be preserved.');
        VerifyFilteredPair(ExcludedLine.RecordId(), IncludedLine.RecordId());
    end;

    [Test]
    procedure UnfilteredSynchronizationRejectsEmptySet()
    var
        ServiceLine: Record "Service Line";
        FSIntTableSubscriber: Codeunit "FS Int. Table Subscriber";
        ServiceLineRecordRef: RecordRef;
    begin
        // [FEATURE] [AI test 0.3] [FS Integration] [Mapping Filters]
        // [SCENARIO 649829] The existing public synchronization API retains its empty-set error behavior.
        Initialize();

        // [GIVEN] The Field Service mappings exist and the supplied service-line set is empty.
        InitializeAuxiliarySynchronization();
        ServiceLine.SetRange(SystemId, CreateGuid());
        ServiceLineRecordRef.GetTable(ServiceLine);

        // [WHEN] The unfiltered public synchronization API is called.
        asserterror FSIntTableSubscriber.SynchRecordsToIntegrationTable(ServiceLineRecordRef, Database::"FS Work Order Product", false, false);

        // [THEN] The established empty-set error is raised.
        Assert.ExpectedError(SynchronizeEmptySetErr);
    end;

    [Test]
    procedure DefaultProductImportKeepsParentScope()
    var
        ServiceHeader: Record "Service Header";
        FSWorkOrder: Record "FS Work Order";
        FirstProduct: Record "FS Work Order Product";
        SecondProduct: Record "FS Work Order Product";
        ProductFilter: Record "FS Work Order Product";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // [FEATURE] [AI test 0.3] [FS Integration] [Mapping Filters]
        // [SCENARIO 649829] Default product filters accept both statuses without leaking another parent's products.
        Initialize();

        // [GIVEN] Two products on this order and a third on another order, with default filters restored.
        PrepareProductImport(ServiceHeader, FSWorkOrder, FirstProduct, SecondProduct, false);
        IntegrationTableMapping.Get('SRVORDERLINE-ITEM');
        ProductFilter.SetView(IntegrationTableMapping.GetIntegrationTableFilter());
        ProductFilter.SetRange(LineStatus);
        IntegrationTableMapping.SetIntegrationTableFilter(ProductFilter.GetView(false));
#pragma warning disable AA0214
        IntegrationTableMapping.Modify();
#pragma warning restore AA0214

        // [WHEN] The unchanged work order synchronizes its children.
        RunAuxiliaryServiceOrderSync(ServiceHeader, FSWorkOrder, true);

        // [THEN] Both current products remain selected.
        VerifySynchronizationSelection(FirstProduct.RecordId(), true, 2);
        VerifySynchronizationSelection(SecondProduct.RecordId(), true, 2);
    end;

    [Test]
    procedure DefaultBookingImportKeepsParentAndStatus()
    var
        ServiceHeader: Record "Service Header";
        FSWorkOrder: Record "FS Work Order";
        FirstBooking: Record "FS Bookable Resource Booking";
        SecondBooking: Record "FS Bookable Resource Booking";
        BookingFilter: Record "FS Bookable Resource Booking";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // [FEATURE] [AI test 0.3] [FS Integration] [Mapping Filters]
        // [SCENARIO 649829] Default booking filters preserve completed status and parent restrictions.
        Initialize();

        // [GIVEN] Two completed bookings on this order and other-parent/status decoys.
        PrepareBookingImport(ServiceHeader, FSWorkOrder, FirstBooking, SecondBooking, false);
        IntegrationTableMapping.Get('SRVORDERLINE-RESOURC');
        BookingFilter.SetView(IntegrationTableMapping.GetIntegrationTableFilter());
        BookingFilter.SetRange(Duration);
        IntegrationTableMapping.SetIntegrationTableFilter(BookingFilter.GetView(false));
#pragma warning disable AA0214
        IntegrationTableMapping.Modify();
#pragma warning restore AA0214

        // [WHEN] The unchanged work order synchronizes its children using the default mapping.
        RunAuxiliaryServiceOrderSync(ServiceHeader, FSWorkOrder, true);

        // [THEN] Only the two current completed bookings are selected.
        VerifySynchronizationSelection(FirstBooking.RecordId(), true, 2);
        VerifySynchronizationSelection(SecondBooking.RecordId(), true, 2);
    end;

    [Test]
    procedure DefaultProductExportKeepsParentScope()
    var
        ServiceHeader: Record "Service Header";
        FSWorkOrder: Record "FS Work Order";
        FirstLine: Record "Service Line";
        SecondLine: Record "Service Line";
        LineFilter: Record "Service Line";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // [FEATURE] [AI test 0.3] [FS Integration] [Mapping Filters]
        // [SCENARIO 649829] Default product export filters preserve the service-order parent scope.
        Initialize();

        // [GIVEN] Two item lines on this order and a third on another order, with default filters restored.
        PrepareLineExport(ServiceHeader, FSWorkOrder, FirstLine, SecondLine, false);
        IntegrationTableMapping.Get('SRVORDERLINE-ITEM');
        LineFilter.SetView(IntegrationTableMapping.GetTableFilter());
        LineFilter.SetRange(Description);
        IntegrationTableMapping.SetTableFilter(LineFilter.GetView(false));
#pragma warning disable AA0214
        IntegrationTableMapping.Modify();
#pragma warning restore AA0214

        // [WHEN] The unchanged service order synchronizes its children.
        RunAuxiliaryServiceOrderSync(ServiceHeader, FSWorkOrder, false);

        // [THEN] Both current lines remain selected.
        VerifySynchronizationSelection(FirstLine.RecordId(), true, 2);
        VerifySynchronizationSelection(SecondLine.RecordId(), true, 2);
    end;

    [Test]
    procedure EmptyAuxiliaryOrderDoesNotDelegate()
    var
        ServiceHeader: Record "Service Header";
        FSWorkOrder: Record "FS Work Order";
    begin
        // [FEATURE] [AI test 0.3] [FS Integration] [Mapping Filters]
        // [SCENARIO 649829] An order without auxiliary records does not submit an empty synchronization request.
        Initialize();

        // [GIVEN] A coupled order without child records.
        InitializeAuxiliarySynchronization();
        CreateCoupledServiceOrder(ServiceHeader, FSWorkOrder);

        // [WHEN] The unchanged work order synchronizes its children.
        RunAuxiliaryServiceOrderSync(ServiceHeader, FSWorkOrder, true);

        // [THEN] Nothing is submitted to the record-set synchronization API.
        VerifySynchronizationSelection(FSWorkOrder.RecordId(), false, 0);
    end;

    local procedure Initialize()
    var
        AssistedSetupTestLibrary: Codeunit "Assisted Setup Test Library";
        CryptographyManagement: Codeunit "Cryptography Management";
    begin
        ResetFSEnvironment();
        LibraryCRMIntegration.ResetEnvironment();
        LibraryVariableStorage.Clear();
        if CryptographyManagement.IsEncryptionEnabled() then
            CryptographyManagement.DisableEncryption(true);
        Assert.IsFalse(EncryptionEnabled(), 'Encryption should be disabled');

        UnregisterTableConnection(TableConnectionType::CRM, '');
        UnregisterTableConnection(TableConnectionType::CRM, GetDefaultTableConnection(TableConnectionType::CRM));
        Assert.AreEqual(
          '', GetDefaultTableConnection(TableConnectionType::CRM),
          'DEFAULTTABLECONNECTION should not be registered');

        AssistedSetupTestLibrary.DeleteAll();
        AssistedSetupTestLibrary.CallOnRegister();
        InitializeCDSConnectionSetup();

        if IsInitialized then
            exit;

        IsInitialized := true;
        SetTenantLicenseStateToTrial();
    end;

    local procedure VerifySuccessfulIntegrationSynchJob(JobID: Guid; ExpectedInserted: Integer; ExpectedModified: Integer)
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
    begin
        IntegrationSynchJob.Get(JobID);
        IntegrationSynchJobErrors.SetRange("Integration Synch. Job ID", JobID);
        if IntegrationSynchJobErrors.FindFirst() then
            Assert.Fail('Unexpected synchronization error: ' + IntegrationSynchJobErrors.Message);
        IntegrationSynchJob.TestField(Failed, 0);
        IntegrationSynchJob.TestField(Inserted, ExpectedInserted);
        IntegrationSynchJob.TestField(Modified, ExpectedModified);
    end;

    local procedure CreateItemWithCoupledUnitOfMeasure(var Item: Record Item; var CRMUom: Record "CRM Uom")
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        UnitGroup: Record "Unit Group";
        CRMUomschedule: Record "CRM Uomschedule";
    begin
        LibraryCRMIntegration.CreateCoupledItemUnitGroupAndUomSchedule(UnitGroup, CRMUomschedule);
        Item.GetBySystemId(UnitGroup."Source Id");
        ItemUnitOfMeasure.Get(Item."No.", Item."Base Unit of Measure");
        LibraryCRMIntegration.CoupleItemUnitOfMeasure(ItemUnitOfMeasure, CRMUomschedule, CRMUom);
    end;

    local procedure InitializeItemProductSynchronization()
    var
        CDSCompany: Record "CDS Company";
        CDSConnectionSetup: Record "CDS Connection Setup";
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        InitSetup(true, '');
        LibraryCRMIntegration.ConfigureCRM();
        LibraryCRMIntegration.CreateCRMOrganization();
        CRMConnectionSetup.Get();
        CRMConnectionSetup.Validate("Is Enabled", false);
        CRMConnectionSetup.Modify(true);
        CRMConnectionSetup.Validate("Is Enabled", true);
        CRMConnectionSetup.Modify(true);
        CDSConnectionSetup.Get();
        CDSConnectionSetup.SetBaseCurrencyData();
        LibraryCRMIntegration.EnsureCDSCompany(CDSCompany);
    end;

    procedure ResetFSEnvironment()
    var
        FSConnectionSetup: Record "FS Connection Setup";
    begin
        FSConnectionSetup.DeleteAll();
    end;

    local procedure InitializeCDSConnectionSetup()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        ClearClientSecret: Text;
        ClientSecret: SecretText;
    begin
        CDSConnectionSetup.DeleteAll();
        CDSConnectionSetup."Is Enabled" := true;
        CDSConnectionSetup."Server Address" := '@@test@@';
        CDSConnectionSetup."User Name" := 'user@test.net';
        CDSConnectionSetup."Authentication Type" := CDSConnectionSetup."Authentication Type"::Office365;
        CDSConnectionSetup."Proxy Version" := LibraryCRMIntegration.GetLastestSDKVersion();
        CDSConnectionSetup.Validate("Client Id", 'ClientId');
        CDSConnectionSetup.Validate("Redirect URL", 'RedirectURL');
        ClearClientSecret := 'ClientSecret';
        ClientSecret := ClearClientSecret;
        CDSConnectionSetup.SetClientSecret(ClientSecret);
    end;

    local procedure InitializeAuxiliarySynchronization()
    var
        FSConnectionSetup: Record "FS Connection Setup";
        FSBookingStatus: Record "FS Booking Status";
        FSBooking: Record "FS Bookable Resource Booking";
    begin
        InitSetup(true, '');
        LibraryCRMIntegration.RegisterTestTableConnection();
        FSConnectionSetup.Get();
        FSConnectionSetup."Integration Type" := FSConnectionSetup."Integration Type"::"Service and projects";
        FSConnectionSetup.Modify();
        FSIntegrationTestLibrary.ResetConfiguration(FSConnectionSetup);

        FSBookingStatus.DeleteAll();
        FSBookingStatus.BookingStatusId := CreateGuid();
        FSBookingStatus.FieldServiceStatus := FSBookingStatus.FieldServiceStatus::Completed;
        FSBookingStatus.Insert();
        SetMappingFieldRange('SRVORDERLINE-RESOURC', FSBooking.FieldNo(BookingStatus), FSBookingStatus.BookingStatusId, true);
        Clear(FSBookingStatus);
        FSBookingStatus.BookingStatusId := CreateGuid();
        FSBookingStatus.FieldServiceStatus := FSBookingStatus.FieldServiceStatus::Scheduled;
        FSBookingStatus.Insert();
        FSBookingStatus.SetRange(FieldServiceStatus, FSBookingStatus.FieldServiceStatus::Completed);
        Assert.AreEqual(1, FSBookingStatus.Count(), 'A completed booking status must exist in the active mock connection.');
    end;

    local procedure CreateCoupledServiceOrder(var ServiceHeader: Record "Service Header"; var FSWorkOrder: Record "FS Work Order")
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        FSWorkOrder.Init();
        FSWorkOrder.WorkOrderId := CreateGuid();
        FSWorkOrder.Name := ServiceHeader."No.";
        FSWorkOrder.IntegrateToService := true;
        FSWorkOrder.ModifiedOn := CurrentDateTime();
        FSWorkOrder.Insert();
        CRMIntegrationRecord.CoupleCRMIDToRecordID(FSWorkOrder.WorkOrderId, ServiceHeader.RecordId());
        CRMIntegrationRecord.Get(FSWorkOrder.WorkOrderId, ServiceHeader.SystemId);
        CRMIntegrationRecord."Last Synch. Modified On" := CurrentDateTime() + 60000;
        CRMIntegrationRecord."Last Synch. CRM Modified On" := CurrentDateTime() + 60000;
        CRMIntegrationRecord.Modify();
    end;

    local procedure CreateAuxiliaryIncident(var FSWorkOrderIncident: Record "FS Work Order Incident"; FSWorkOrder: Record "FS Work Order"; IncidentName: Text[100])
    begin
        FSWorkOrderIncident.Init();
        FSWorkOrderIncident.WorkOrderIncidentId := CreateGuid();
        FSWorkOrderIncident.WorkOrder := FSWorkOrder.WorkOrderId;
        FSWorkOrderIncident.Name := IncidentName;
        FSWorkOrderIncident.ModifiedOn := CurrentDateTime();
        FSWorkOrderIncident.Insert();
    end;

    local procedure CreateAuxiliaryProduct(var FSWorkOrderProduct: Record "FS Work Order Product"; FSWorkOrder: Record "FS Work Order"; Used: Boolean)
    var
        FSWorkOrderIncident: Record "FS Work Order Incident";
    begin
        CreateAuxiliaryIncident(FSWorkOrderIncident, FSWorkOrder, 'PRODUCT');
        FSWorkOrderProduct.Init();
        FSWorkOrderProduct.WorkOrderProductId := CreateGuid();
        FSWorkOrderProduct.WorkOrder := FSWorkOrder.WorkOrderId;
        FSWorkOrderProduct.WorkOrderIncident := FSWorkOrderIncident.WorkOrderIncidentId;
        if Used then
            FSWorkOrderProduct.LineStatus := FSWorkOrderProduct.LineStatus::Used
        else
            FSWorkOrderProduct.LineStatus := FSWorkOrderProduct.LineStatus::Estimated;
        FSWorkOrderProduct.ModifiedOn := CurrentDateTime();
        FSWorkOrderProduct.Insert();
    end;

    local procedure CreateAuxiliaryService(var FSWorkOrderService: Record "FS Work Order Service"; FSWorkOrder: Record "FS Work Order"; Duration: Integer)
    var
        FSWorkOrderIncident: Record "FS Work Order Incident";
    begin
        CreateAuxiliaryIncident(FSWorkOrderIncident, FSWorkOrder, 'SERVICE');
        FSWorkOrderService.Init();
        FSWorkOrderService.WorkOrderServiceId := CreateGuid();
        FSWorkOrderService.WorkOrder := FSWorkOrder.WorkOrderId;
        FSWorkOrderService.WorkOrderIncident := FSWorkOrderIncident.WorkOrderIncidentId;
        FSWorkOrderService.Duration := Duration;
        FSWorkOrderService.ModifiedOn := CurrentDateTime();
        FSWorkOrderService.Insert();
    end;

    local procedure CreateAuxiliaryBooking(var FSBooking: Record "FS Bookable Resource Booking"; FSWorkOrder: Record "FS Work Order"; Duration: Integer; Completed: Boolean)
    var
        FSBookingStatus: Record "FS Booking Status";
    begin
        if Completed then
            FSBookingStatus.SetRange(FieldServiceStatus, FSBookingStatus.FieldServiceStatus::Completed)
        else
            FSBookingStatus.SetRange(FieldServiceStatus, FSBookingStatus.FieldServiceStatus::Scheduled);
        FSBookingStatus.FindFirst();
        FSBooking.Init();
        FSBooking.BookableResourceBookingId := CreateGuid();
        FSBooking.WorkOrder := FSWorkOrder.WorkOrderId;
        FSBooking.BookingStatus := FSBookingStatus.BookingStatusId;
        FSBooking.Duration := Duration;
        FSBooking.ModifiedOn := CurrentDateTime();
        FSBooking.Insert();
    end;

    local procedure CreateAuxiliaryItemLine(var ServiceItemLine: Record "Service Item Line"; ServiceHeader: Record "Service Header"; Description: Text[100]; BookingLine: Boolean)
    begin
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        ServiceItemLine.Description := Description;
        ServiceItemLine."FS Bookings" := BookingLine;
        ServiceItemLine.Modify();
    end;

    local procedure CreateAuxiliaryServiceLine(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; ServiceItem: Boolean; ResourceLine: Boolean; Description: Text[100])
    var
        Item: Record Item;
        ServiceItemLine: Record "Service Item Line";
    begin
        CreateAuxiliaryItemLine(ServiceItemLine, ServiceHeader, Description, ResourceLine);
        if ResourceLine then
            LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Resource, LibraryResource.CreateResourceNo())
        else begin
            LibraryInventory.CreateItem(Item);
            if ServiceItem then begin
                Item.Validate(Type, Item.Type::Service);
                Item.Modify(true);
            end;
            LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        end;
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Description := Description;
        ServiceLine.Modify(true);
    end;

    local procedure CoupleAuxiliaryServiceLine(ServiceHeader: Record "Service Header"; IntegrationId: Guid; ServiceItem: Boolean; ResourceLine: Boolean)
    var
        ServiceLine: Record "Service Line";
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        CreateAuxiliaryServiceLine(ServiceLine, ServiceHeader, ServiceItem, ResourceLine, 'PRESERVED');
        CRMIntegrationRecord.CoupleCRMIDToRecordID(IntegrationId, ServiceLine.RecordId());
    end;

    local procedure SetMappingFieldRange(MappingName: Code[20]; FieldNo: Integer; FieldValue: Variant; IntegrationFilter: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        FilterRecordRef: RecordRef;
        FilterFieldRef: FieldRef;
    begin
        IntegrationTableMapping.Get(MappingName);
        if IntegrationFilter then begin
            FilterRecordRef.Open(IntegrationTableMapping."Integration Table ID");
            FilterRecordRef.SetView(IntegrationTableMapping.GetIntegrationTableFilter());
        end else begin
            FilterRecordRef.Open(IntegrationTableMapping."Table ID");
            FilterRecordRef.SetView(IntegrationTableMapping.GetTableFilter());
        end;
        FilterFieldRef := FilterRecordRef.Field(FieldNo);
        FilterFieldRef.SetRange(FieldValue);
        if IntegrationFilter then
            IntegrationTableMapping.SetIntegrationTableFilter(FilterRecordRef.GetView(false))
        else
            IntegrationTableMapping.SetTableFilter(FilterRecordRef.GetView(false));
        IntegrationTableMapping.Modify();
        FilterRecordRef.Close();
    end;

    local procedure PrepareProductImport(var ServiceHeader: Record "Service Header"; var FSWorkOrder: Record "FS Work Order"; var ExcludedProduct: Record "FS Work Order Product"; var IncludedProduct: Record "FS Work Order Product"; Coupled: Boolean)
    var
        OtherServiceHeader: Record "Service Header";
        OtherWorkOrder: Record "FS Work Order";
        OtherProduct: Record "FS Work Order Product";
    begin
        InitializeAuxiliarySynchronization();
        CreateCoupledServiceOrder(ServiceHeader, FSWorkOrder);
        CreateCoupledServiceOrder(OtherServiceHeader, OtherWorkOrder);
        CreateAuxiliaryProduct(ExcludedProduct, FSWorkOrder, false);
        CreateAuxiliaryProduct(IncludedProduct, FSWorkOrder, true);
        CreateAuxiliaryProduct(OtherProduct, OtherWorkOrder, true);
        SetMappingFieldRange('SRVORDERLINE-ITEM', IncludedProduct.FieldNo(LineStatus), IncludedProduct.LineStatus, true);
        if Coupled then begin
            CoupleAuxiliaryServiceLine(ServiceHeader, ExcludedProduct.WorkOrderProductId, false, false);
            CoupleAuxiliaryServiceLine(ServiceHeader, IncludedProduct.WorkOrderProductId, false, false);
        end;
    end;

    local procedure PrepareServiceImport(var ServiceHeader: Record "Service Header"; var FSWorkOrder: Record "FS Work Order"; var ExcludedService: Record "FS Work Order Service"; var IncludedService: Record "FS Work Order Service"; Coupled: Boolean)
    var
        OtherServiceHeader: Record "Service Header";
        OtherWorkOrder: Record "FS Work Order";
        OtherService: Record "FS Work Order Service";
    begin
        InitializeAuxiliarySynchronization();
        CreateCoupledServiceOrder(ServiceHeader, FSWorkOrder);
        CreateCoupledServiceOrder(OtherServiceHeader, OtherWorkOrder);
        CreateAuxiliaryService(ExcludedService, FSWorkOrder, 30);
        CreateAuxiliaryService(IncludedService, FSWorkOrder, 60);
        CreateAuxiliaryService(OtherService, OtherWorkOrder, 60);
        SetMappingFieldRange('SRVORDERLINE-SERVICE', IncludedService.FieldNo(Duration), 60, true);
        if Coupled then begin
            CoupleAuxiliaryServiceLine(ServiceHeader, ExcludedService.WorkOrderServiceId, true, false);
            CoupleAuxiliaryServiceLine(ServiceHeader, IncludedService.WorkOrderServiceId, true, false);
        end;
    end;

    local procedure PrepareBookingImport(var ServiceHeader: Record "Service Header"; var FSWorkOrder: Record "FS Work Order"; var ExcludedBooking: Record "FS Bookable Resource Booking"; var IncludedBooking: Record "FS Bookable Resource Booking"; Coupled: Boolean)
    var
        OtherServiceHeader: Record "Service Header";
        OtherWorkOrder: Record "FS Work Order";
        OtherBooking: Record "FS Bookable Resource Booking";
        ScheduledBooking: Record "FS Bookable Resource Booking";
    begin
        InitializeAuxiliarySynchronization();
        CreateCoupledServiceOrder(ServiceHeader, FSWorkOrder);
        CreateCoupledServiceOrder(OtherServiceHeader, OtherWorkOrder);
        CreateAuxiliaryBooking(ExcludedBooking, FSWorkOrder, 30, true);
        CreateAuxiliaryBooking(IncludedBooking, FSWorkOrder, 60, true);
        CreateAuxiliaryBooking(OtherBooking, OtherWorkOrder, 60, true);
        CreateAuxiliaryBooking(ScheduledBooking, FSWorkOrder, 60, false);
        SetMappingFieldRange('SRVORDERLINE-RESOURC', IncludedBooking.FieldNo(Duration), 60, true);
        if Coupled then begin
            CoupleAuxiliaryServiceLine(ServiceHeader, ExcludedBooking.BookableResourceBookingId, false, true);
            CoupleAuxiliaryServiceLine(ServiceHeader, IncludedBooking.BookableResourceBookingId, false, true);
        end;
    end;

    local procedure PrepareLineExport(var ServiceHeader: Record "Service Header"; var FSWorkOrder: Record "FS Work Order"; var ExcludedLine: Record "Service Line"; var IncludedLine: Record "Service Line"; ServiceItem: Boolean)
    var
        OtherServiceHeader: Record "Service Header";
        OtherWorkOrder: Record "FS Work Order";
        OtherLine: Record "Service Line";
        MappingName: Code[20];
    begin
        InitializeAuxiliarySynchronization();
        CreateCoupledServiceOrder(ServiceHeader, FSWorkOrder);
        CreateCoupledServiceOrder(OtherServiceHeader, OtherWorkOrder);
        CreateAuxiliaryServiceLine(ExcludedLine, ServiceHeader, ServiceItem, false, 'EXCLUDED');
        CreateAuxiliaryServiceLine(IncludedLine, ServiceHeader, ServiceItem, false, 'INCLUDED');
        CreateAuxiliaryServiceLine(OtherLine, OtherServiceHeader, ServiceItem, false, 'INCLUDED');
        if ServiceItem then
            MappingName := 'SRVORDERLINE-SERVICE'
        else
            MappingName := 'SRVORDERLINE-ITEM';
        SetMappingFieldRange(MappingName, IncludedLine.FieldNo(Description), 'INCLUDED', false);
    end;

    local procedure PrepareModifiedChildExport(var ServiceHeader: Record "Service Header"; var IntegrationTableMapping: Record "Integration Table Mapping"; ItemLine: Boolean; Matching: Boolean)
    var
        FSWorkOrder: Record "FS Work Order";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ModifiedAt: DateTime;
    begin
        InitializeAuxiliarySynchronization();
        CreateCoupledServiceOrder(ServiceHeader, FSWorkOrder);
        if ItemLine then
            CreateAuxiliaryItemLine(ServiceItemLine, ServiceHeader, 'ORIGINAL', false)
        else
            LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        ModifiedAt := ServiceHeader.SystemModifiedAt;
        // Cross the SQL timestamp boundary so the parent is not included by the initial pass.
        Sleep(20);
        if ItemLine then begin
            ServiceItemLine.Description := 'MODIFIED';
            ServiceItemLine.Modify(false);
            Assert.IsTrue(ServiceItemLine.SystemModifiedAt > ModifiedAt, 'The child must be newer than the header watermark.');
        end else begin
            ServiceLine.Description := 'MODIFIED';
            ServiceLine.Modify(false);
            Assert.IsTrue(ServiceLine.SystemModifiedAt > ModifiedAt, 'The child must be newer than the header watermark.');
        end;
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        Assert.AreEqual(ModifiedAt, ServiceHeader.SystemModifiedAt, 'Only the child may change after the header watermark.');
        if Matching then
            SetMappingFieldRange('SRVORDER', ServiceHeader.FieldNo("No."), ServiceHeader."No.", false)
        else
            SetMappingFieldRange('SRVORDER', ServiceHeader.FieldNo("No."), 'EXCLUDED', false);
        IntegrationTableMapping.Get('SRVORDER');
        IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::ToIntegrationTable;
        IntegrationTableMapping."Synch. Int. Tbl. Mod. On Fltr." := ModifiedAt;
        IntegrationTableMapping.Modify();
    end;

    local procedure RunScheduledServiceOrderSync(IntegrationTableMapping: Record "Integration Table Mapping")
    var
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
    begin
        FSIntegrationTestLibrary.ClearSynchronizationCandidates();
        BindSubscription(FSIntegrationTestLibrary);
        CRMIntegrationTableSynch.Run(IntegrationTableMapping);
        UnbindSubscription(FSIntegrationTestLibrary);
    end;

    local procedure RunAuxiliaryServiceOrderSync(ServiceHeader: Record "Service Header"; FSWorkOrder: Record "FS Work Order"; FromFieldService: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationRecSynchInvoke: Codeunit "Integration Rec. Synch. Invoke";
        IntegrationRecordSynch: Codeunit "Integration Record Synch.";
        SourceRecordRef: RecordRef;
        DestinationRecordRef: RecordRef;
        SynchAction: Option "None",Insert,Modify,ForceModify,IgnoreUnchanged,Fail,Skip,Delete,Uncouple,Couple;
        JobId: Guid;
    begin
        IntegrationTableMapping.Get('SRVORDER');
        if FromFieldService then begin
            SourceRecordRef.GetTable(FSWorkOrder);
            DestinationRecordRef.GetTable(ServiceHeader);
            IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::FromIntegrationTable;
        end else begin
            SourceRecordRef.GetTable(ServiceHeader);
            DestinationRecordRef.GetTable(FSWorkOrder);
            IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::ToIntegrationTable;
        end;
        IntegrationRecSynchInvoke.SetContext(
            IntegrationTableMapping, SourceRecordRef, DestinationRecordRef, IntegrationRecordSynch,
            SynchAction::Modify, false, JobId, TableConnectionType::CRM);
        FSIntegrationTestLibrary.ClearSynchronizationCandidates();
        BindSubscription(FSIntegrationTestLibrary);
        IntegrationRecSynchInvoke.Run();
        UnbindSubscription(FSIntegrationTestLibrary);
        Assert.AreEqual(1, FSIntegrationTestLibrary.GetUnchangedServiceOrderCount(), 'The real unchanged-parent synchronization path must run.');
    end;

    local procedure VerifySynchronizationSelection(CandidateRecordId: RecordId; ExpectedSelected: Boolean; ExpectedCount: Integer)
    var
        CandidateSelectionErr: Label 'Mapping filters must control auxiliary selection of %1.', Comment = '%1 = candidate record ID';
    begin
        Assert.AreEqual(ExpectedSelected, FSIntegrationTestLibrary.WasSelectedForSynchronization(CandidateRecordId),
            StrSubstNo(CandidateSelectionErr, CandidateRecordId));
        Assert.AreEqual(ExpectedCount, FSIntegrationTestLibrary.GetSynchronizationCandidateCount(CandidateRecordId.TableNo()),
            'Auxiliary synchronization must not select records outside the mapping and parent scope.');
        Assert.AreEqual(0, FSIntegrationTestLibrary.GetEmptySynchronizationRequestCount(), 'Do not delegate empty record sets to the synchronization API.');
    end;

    local procedure VerifyFilteredPair(ExcludedRecordId: RecordId; IncludedRecordId: RecordId)
    begin
        VerifySynchronizationSelection(IncludedRecordId, true, 1);
        VerifySynchronizationSelection(ExcludedRecordId, false, 1);
    end;

    local procedure VerifyCoupledServiceLinePreserved(IntegrationId: Guid)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        ServiceLine: Record "Service Line";
    begin
        CRMIntegrationRecord.SetRange("CRM ID", IntegrationId);
        CRMIntegrationRecord.SetRange("Table ID", Database::"Service Line");
        Assert.IsTrue(CRMIntegrationRecord.FindFirst(), 'Exclusion must not delete the existing coupling.');
        Assert.IsTrue(ServiceLine.GetBySystemId(CRMIntegrationRecord."Integration ID"), 'Exclusion must not delete the coupled line.');
        Assert.AreEqual('PRESERVED', ServiceLine.Description, 'An excluded coupled line must remain unchanged.');
    end;

    local procedure AssertConnectionNotRegistered(ConnectionName: Code[10])
    var
        FSConnectionSetup: Record "FS Connection Setup";
    begin
        FSConnectionSetup.Get(ConnectionName);
        FSIntegrationTestLibrary.RegisterConnection(FSConnectionSetup);
        FSIntegrationTestLibrary.UnregisterConnection(FSConnectionSetup);
    end;

    local procedure CreateTableMapping()
    var
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        IntegrationTableMapping.Init();
        IntegrationTableMapping."Table ID" := Database::Currency;
        IntegrationTableMapping."Integration Table ID" := Database::"CRM Transactioncurrency";
        IntegrationTableMapping.Validate("Integration Table UID Fld. No.", CRMTransactioncurrency.FieldNo(TransactionCurrencyId));
        IntegrationTableMapping."Synch. Codeunit ID" := Codeunit::"CRM Integration Table Synch.";

        IntegrationTableMapping.Name := 'FIRST';
        IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::FromIntegrationTable;
        IntegrationTableMapping.Insert();

        IntegrationTableMapping.Name := 'SECOND';
        IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::Bidirectional;
        IntegrationTableMapping.Insert();
    end;

    local procedure CreateIntTableMappingWithJobQueueEntries()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        IntegrationTableMapping.DeleteAll();
        CreateTableMapping();
        JobQueueEntry.DeleteAll();
        InsertJobQueueEntries();
        InsertJobQueueEntriesWithError();
        IntegrationTableMapping.FindFirst();
        JobQueueEntry.ModifyAll("Record ID to Process", IntegrationTableMapping.RecordId);
    end;

    local procedure CreateFSConnectionSetup()
    begin
        LibraryCRMIntegration.RegisterTestTableConnection();
        LibraryCRMIntegration.EnsureCRMSystemUser();
        LibraryCRMIntegration.CreateCRMOrganization();
        CreateIntTableMappingWithJobQueueEntries();
    end;

    local procedure InitSetup(Enable: Boolean; Version: Text[30])
    var
        FSConnectionSetup: Record "FS Connection Setup";
        JobJournalTemplate: Record "Job Journal Template";
        JobJournalBatch: Record "Job Journal Batch";
        UnitOfMeasure: Record "Unit of Measure";
        DummyPassword: Text;
    begin
        FSConnectionSetup.Init();
        FSConnectionSetup."Is Enabled" := Enable;
        FSConnectionSetup."Is FS Solution Installed" := Enable;
        FSConnectionSetup."Server Address" := '@@test@@';
        FSConnectionSetup.Validate("User Name", 'tester@domain.net');
        DummyPassword := 'Password';
        FSIntegrationTestLibrary.SetPassword(FSConnectionSetup, DummyPassword);
        FSConnectionSetup."FS Version" := Version;
        if Enable then begin
            LibraryJob.CreateJobJournalTemplate(JobJournalTemplate);
            LibraryJob.CreateJobJournalBatch(JobJournalTemplate.Name, JobJournalBatch);
            LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
            FSConnectionSetup."Job Journal Template" := JobJournalTemplate.Name;
            FSConnectionSetup."Job Journal Batch" := JobJournalBatch.Name;
            FSConnectionSetup."Hour Unit of Measure" := UnitOfMeasure.Code;
        end;
        FSConnectionSetup.Insert();

        if FSConnectionSetup."Is Enabled" then
            FSIntegrationTestLibrary.RegisterConnection(FSConnectionSetup);
    end;

    procedure InitServiceManagementSetup(ManualNoSeries: Boolean; ArchiveOrdersEnabled: Boolean; OneServiceItemLinePerOrder: Boolean)
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";

        ServiceMgtSetup: Record "Service Mgt. Setup";
        NewNoSeries: Code[20];
    begin
        NewNoSeries := 'ServiceOrder';

        // create new No. Series
        NoSeries.Code := NewNoSeries;
        NoSeries."Manual Nos." := ManualNoSeries;
        NoSeries."Default Nos." := true;
        NoSeries.Insert(true);

        // create new No. Series Line
        NoSeriesLine."Series Code" := NoSeries.Code;
        NoSeriesLine."Starting Date" := 20100101D;
        NoSeriesLine."Starting No." := '00001';
        NoSeriesLine."Increment-by No." := 1;
        NoSeriesLine.Insert(true);

        // update ServiceMgtSetup record
        ServiceMgtSetup.Get();
        ServiceMgtSetup."Service Order Nos." := NewNoSeries;
        ServiceMgtSetup."Archive Orders" := ArchiveOrdersEnabled;
        ServiceMgtSetup."One Service Item Line/Order" := OneServiceItemLinePerOrder;
        ServiceMgtSetup.Modify(true);
    end;

    local procedure InsertJobQueueEntries()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.DeleteAll();
        InsertJobQueueEntry(Codeunit::"Integration Synch. Job Runner", JobQueueEntry.Status::Ready);
        InsertJobQueueEntry(Codeunit::"Integration Synch. Job Runner", JobQueueEntry.Status::"In Process");
        InsertJobQueueEntry(Codeunit::"CRM Statistics Job", JobQueueEntry.Status::Ready);
    end;

    local procedure InsertJobQueueEntriesWithError()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        InsertJobQueueEntry(Codeunit::"CRM Statistics Job", JobQueueEntry.Status::Error);
    end;

    local procedure InsertJobQueueEntry(ID: Integer; Status: Option)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.Init();
        JobQueueEntry.ID := CreateGuid();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := ID;
        JobQueueEntry.Status := Status;
        JobQueueEntry.Insert();
    end;

    local procedure VerifyJobQueueEntriesStatusIsReady()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Integration Synch. Job Runner");
        JobQueueEntry.FindSet();
        repeat
            if JobQueueEntry.Description.Contains(CRMProductName.FSServiceName()) then
                Assert.IsTrue(JobQueueEntry.Status = JobQueueEntry.Status::Ready, JobQueueEntryStatusReadyErr);
        until JobQueueEntry.Next() = 0;
    end;

    local procedure VerifyJobQueueEntriesStatusIsOnHold()
    var
        JobQueueEntry: Record "Job Queue Entry";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CheckSetOnHold: Boolean;
    begin
        JobQueueEntry.FindSet();
        repeat
            CheckSetOnHold := true;
            if IntegrationTableMapping.Get(JobQueueEntry."Record ID to Process") then
                if IntegrationTableMapping."Table ID" in [Database::Contact, Database::Customer, Database::"Salesperson/Purchaser", Database::Vendor, Database::Currency] then
                    CheckSetOnHold := false;
            if CheckSetOnHold then
                Assert.IsTrue(JobQueueEntry.Status = JobQueueEntry.Status::"On Hold", JobQueueEntryStatusOnHoldErr);
        until JobQueueEntry.Next() = 0;
    end;

    local procedure CreateJobAndJobTask(var Job: Record Job; var JobTask: Record "Job Task")
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
    end;

    local procedure CreateJobJournalLine(var JobJournalLine: Record "Job Journal Line"; JobTask: Record "Job Task"; No: Code[20])
    begin
        LibraryJob.CreateJobJournalLineForType("Job Line Type"::Billable, JobJournalLine.Type::Item, JobTask, JobJournalLine);
        JobJournalLine.Validate("No.", No);
        JobJournalLine.Validate(Quantity, LibraryRandom.RandInt(10));  // Use Random because value is not important.
        JobJournalLine.Modify(true);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2));  // Using Random value for Unit Price because value is not important.
        Item.Validate("Last Direct Cost", LibraryRandom.RandDec(100, 2));  // Using Random value for Last Direct Cost because value is not important.
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateWorkOrderProduct(var WorkOrderProduct: Record "FS Work Order Product")
    begin
        WorkOrderProduct.Init();
        WorkOrderProduct.WorkOrderProductId := CreateGuid();
        WorkOrderProduct.Insert();
    end;

    [ConfirmHandler]
    procedure ConfirmNo(Question: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ConfirmHandler]
    procedure ConfirmYes(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    procedure MessageOk(Message: Text)
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;

    [MessageHandler]
    procedure MessageDequeue(Message: Text)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Message);
    end;

    [ModalPageHandler]
    procedure CRMOptionMappingModalHandler(var CRMOptionMappingPage: TestPage "CRM Option Mapping")
    begin
        Assert.IsFalse(CRMOptionMappingPage.Editable, 'The page should be NOT editable');
        CRMOptionMappingPage.First();
        CRMOptionMappingPage.Record.AssertEquals(LibraryVariableStorage.DequeueText());
        CRMOptionMappingPage."Option Value".AssertEquals(LibraryVariableStorage.DequeueInteger());
        CRMOptionMappingPage."Option Value Caption".AssertEquals(LibraryVariableStorage.DequeueText());
    end;

    [PageHandler]
    procedure CRMSystemUserListHandler(var CRMSystemuserList: TestPage "CRM Systemuser List")
    begin
        LibraryVariableStorage.Enqueue(CRMSystemuserList.SalespersonPurchaserCode.Editable());
        LibraryVariableStorage.Enqueue(CRMSystemuserList.Couple.Visible());
    end;

    [ModalPageHandler]
    procedure SDKVersionListModalHandler(var SDKVersionList: TestPage "SDK Version List")
    begin
        SDKVersionList.GotoKey(LibraryVariableStorage.DequeueInteger());
        SDKVersionList.OK().Invoke();
    end;

    [SendNotificationHandler]
    procedure ConnectionBrokenNotificationHandler(var ConnectionBrokenNotification: Notification): Boolean
    begin
        LibraryVariableStorage.Enqueue(ConnectionBrokenNotification.Message);
    end;

    [ModalPageHandler]
    procedure FSAssistedSetupModalHandler(var FSConnectionSetupWizard: TestPage "FS Connection Setup Wizard")
    begin
        LibraryVariableStorage.Enqueue(FSConnectionSetupWizard.ServerAddress.Value);
    end;

    local procedure SetTenantLicenseStateToTrial()
    var
        TenantLicenseState: Record "Tenant License State";
    begin
        TenantLicenseState."Start Date" := CurrentDateTime;
        TenantLicenseState.State := TenantLicenseState.State::Trial;
        TenantLicenseState.Insert();
    end;

    local procedure EnableLocationMandatoryOnInventorySetup()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Location Mandatory", true);
        InventorySetup.Modify(true);
    end;
}
