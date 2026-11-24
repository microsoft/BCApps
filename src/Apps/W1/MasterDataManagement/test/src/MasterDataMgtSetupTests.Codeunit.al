codeunit 139770 "Master Data Mgt. Setup Tests"
{
    Subtype = Test;
    RequiredTestIsolation = Disabled;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [Master Data Management] [Setup]
    end;

    var
        Assert: Codeunit Assert;
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryMasterDataMgt: Codeunit "Library - Master Data Mgt.";
        InitializeHandled: Boolean;
        IncorrectTablesListErr: Label 'Synchronization tables list is incorrect.';
        UnexpectedConfirmErr: Label 'Unexpected confirmation dialog: %1', Locked = true;
        SystemTableErr: Label 'System tables can''t be synchronized', Locked = true;
        TableIdAttributeTxt: Label 'IntegrationTableMapping_TableID="%1"', Locked = true, Comment = '%1 = table ID';
        IntegrationTableIdAttributeTxt: Label 'IntegrationTableMapping_IntegrationTableID="%1"', Locked = true, Comment = '%1 = table ID';

    [Test]
    [HandlerFunctions('SynchronizationEnabledMessageHandler')]
    procedure EnableSetup()
    var
        MasterDataManagementSetup: Record "Master Data Management Setup";
        MasterDataMgtSetupTests: Codeunit "Master Data Mgt. Setup Tests";
    begin
        Initialize();
        MasterDataManagementSetup.Init();
        MasterDataManagementSetup."Company Name" := CopyStr(LibraryRandom.RandText(30), 1, MaxStrLen(MasterDataManagementSetup."Company Name"));
        MasterDataManagementSetup.Validate("Is Enabled", true);
        BindSubscription(MasterDataMgtSetupTests);
        MasterDataManagementSetup.Insert(true);
        UnbindSubscription(MasterDataMgtSetupTests);

        VerifyDefaultSetup();
    end;

    local procedure VerifyDefaultSetup()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        JobQueueEntry: Record "Job Queue Entry";
        MasterDataMgtSubscriber: Record "Master Data Mgt. Subscriber";
        SynchronizationTableNos: List of [Integer];
        TableNo: Integer;
    begin
        SynchronizationTableNos.Add(Database::Customer);
        SynchronizationTableNos.Add(Database::Vendor);
        SynchronizationTableNos.Add(Database::Contact);
        SynchronizationTableNos.Add(Database::Currency);
        SynchronizationTableNos.Add(Database::"Currency Exchange Rate");
        SynchronizationTableNos.Add(Database::"No. Series");
        SynchronizationTableNos.Add(Database::"No. Series Line");
        SynchronizationTableNos.Add(Database::"Country/Region");
        SynchronizationTableNos.Add(Database::"Post Code");
        SynchronizationTableNos.Add(Database::"Sales & Receivables Setup");
        SynchronizationTableNos.Add(Database::"Marketing Setup");
        SynchronizationTableNos.Add(Database::"Purchases & Payables Setup");
        SynchronizationTableNos.Add(Database::"Payment Terms");
        SynchronizationTableNos.Add(Database::"Shipment Method");
        SynchronizationTableNos.Add(Database::"Shipping Agent");
        SynchronizationTableNos.Add(Database::"Salesperson/Purchaser");

        foreach TableNo in SynchronizationTableNos do begin
            IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::"Master Data Management");
            IntegrationTableMapping.SetRange("Table ID", TableNo);
            IntegrationTableMapping.SetRange("Integration Table ID", TableNo);
            IntegrationTableMapping.SetRange("Delete After Synchronization", false);
            Assert.AreEqual(IntegrationTableMapping.Count(), 1, '');
            IntegrationTableMapping.FindFirst();
            Assert.AreEqual(IntegrationTableMapping.Direction, IntegrationTableMapping.Direction::FromIntegrationTable, '');
            IntegrationFieldMapping.SetRange("Integration Table Mapping Name", IntegrationTableMapping.Name);
            IntegrationFieldMapping.SetRange(Status, IntegrationFieldMapping.Status::Enabled);
            Assert.IsTrue(IntegrationFieldMapping.Count() > 0, '');
            IntegrationFieldMapping.SetRange(Status);
            if IntegrationFieldMapping.FindSet() then
                repeat
                    Assert.AreEqual(IntegrationFieldMapping.Direction, IntegrationFieldMapping.Direction::FromIntegrationTable, '');
                until IntegrationFieldMapping.Next() = 0;
            JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Integration Synch. Job Runner");
            JobQueueEntry.SetRange("Record ID to Process", IntegrationTableMapping.RecordId());
            JobQueueEntry.SetRange("Recurring Job", true);
            Assert.AreEqual(JobQueueEntry.Count(), 1, '');
        end;

        MasterDataMgtSubscriber.SetRange("Company Name", CompanyName());
        Assert.AreEqual(MasterDataMgtSubscriber.Count(), 1, '');
    end;

    [Test]
    procedure EnableSetupFailsIfCurrentCompanyChosen()
    var
        MasterDataManagementSetup: Record "Master Data Management Setup";
    begin
        Initialize();
        MasterDataManagementSetup.Init();
        asserterror MasterDataManagementSetup.Validate("Company Name", CopyStr(CompanyName(), 1, MaxStrLen(MasterDataManagementSetup."Company Name")));
        Assert.ExpectedError('You are currently signed into this company');
    end;

    [Test]
    [HandlerFunctions('SynchronizationEnabledMessageHandler')]
    procedure EnableCrossEnvironmentAllowsSameSourceCompanyName()
    var
        MasterDataManagementSetup: Record "Master Data Management Setup";
        MasterDataMgtSubscriber: Record "Master Data Mgt. Subscriber";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] Cross-env enables with a source company whose name equals the current company (different environment),
        //            and never writes to the source subscriber table.
        Initialize();
        MasterDataManagementSetup.Init();
        MasterDataManagementSetup."Source Environment Name" := 'CONTOSO-PROD';
        MasterDataManagementSetup."Source Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(MasterDataManagementSetup."Source Company Name"));
        MasterDataManagementSetup."Source OAuth Client Id" := '11111111-2222-3333-4444-555555555555';
        MasterDataManagementSetup."Source Client Secret Key" := CreateGuid(); // simulate a stored secret
        MasterDataManagementSetup.Insert();

        MasterDataManagementSetup.Validate("Is Enabled", true);
        MasterDataManagementSetup.Modify(true);

        // [THEN] no subscriber row was written for the current company
        MasterDataMgtSubscriber.SetRange("Company Name", CompanyName());
        Assert.AreEqual(0, MasterDataMgtSubscriber.Count(), 'Cross-env enable must not write to the source subscriber table');

        // cleanup: disable to remove the detector job
        MasterDataManagementSetup.Validate("Is Enabled", false);
        MasterDataManagementSetup.Modify(true);
    end;

    [Test]
    procedure EnableCrossEnvironmentRequiresConnectionDetails()
    var
        MasterDataManagementSetup: Record "Master Data Management Setup";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] Enabling cross-env without a configured connection is blocked with a clear error.
        Initialize();
        MasterDataManagementSetup.Init();
        MasterDataManagementSetup."Source Environment Name" := 'CONTOSO-PROD'; // env set, but URL/company/client id/secret missing
        MasterDataManagementSetup.Insert();

        asserterror MasterDataManagementSetup.Validate("Is Enabled", true);
        Assert.ExpectedError('connection details');
    end;

    [Test]
    [HandlerFunctions('ExitNotEnabledConfirmHandler')]
    procedure SameEnvironmentShowsSourceCompanyHidesCrossEnvFields()
    var
        MasterDataManagementSetup: Record "Master Data Management Setup";
        MasterDataManagementSetupPage: TestPage "Master Data Management Setup";
    begin
        // [FEATURE] [AI test 0.4]
        // [FEATURE] [Master Data Management] [Setup] [UI]
        // [SCENARIO 650747] With same-environment setup, the setup page shows the same-environment source company field and hides the cross-environment source fields.
        Initialize();

        // [GIVEN] A same-environment setup (no source environment configured)
        MasterDataManagementSetup.Init();
        MasterDataManagementSetup."Company Name" := CopyStr(LibraryRandom.RandText(30), 1, MaxStrLen(MasterDataManagementSetup."Company Name"));
        MasterDataManagementSetup.Insert();

        // [WHEN] The setup page is opened
        MasterDataManagementSetupPage.OpenEdit();

        // [THEN] The same-environment source company field is shown and the cross-environment source fields are hidden
        Assert.IsTrue(MasterDataManagementSetupPage."Company Name".Visible(), 'Same-environment source company field should be visible.');
        Assert.IsFalse(MasterDataManagementSetupPage."Source Environment Name".Visible(), 'Cross-environment source environment field should be hidden.');
        Assert.IsFalse(MasterDataManagementSetupPage."Source Company Name".Visible(), 'Cross-environment source company field should be hidden.');

        MasterDataManagementSetupPage.Close();
    end;

    [Test]
    [HandlerFunctions('ExitNotEnabledConfirmHandler')]
    procedure CrossEnvironmentShowsSourceFieldsHidesSameEnvField()
    var
        MasterDataManagementSetup: Record "Master Data Management Setup";
        MasterDataManagementSetupPage: TestPage "Master Data Management Setup";
    begin
        // [FEATURE] [AI test 0.4]
        // [FEATURE] [Master Data Management] [Setup] [UI]
        // [SCENARIO 650747] With cross-environment setup configured, the setup page shows the cross-environment source fields and hides the same-environment source company field when the page is opened.
        Initialize();

        // [GIVEN] A cross-environment setup with a configured connection
        MasterDataManagementSetup.Init();
        MasterDataManagementSetup."Source Environment Name" := 'CONTOSO-PROD';
        MasterDataManagementSetup."Source Company Name" := CopyStr(LibraryRandom.RandText(30), 1, MaxStrLen(MasterDataManagementSetup."Source Company Name"));
        MasterDataManagementSetup."Source OAuth Client Id" := '11111111-2222-3333-4444-555555555555';
        MasterDataManagementSetup."Source Client Secret Key" := CreateGuid(); // simulate a stored secret
        MasterDataManagementSetup.Insert();

        // [WHEN] The setup page is opened
        MasterDataManagementSetupPage.OpenEdit();

        // [THEN] The cross-environment source fields are shown and the same-environment source company field is hidden
        Assert.IsTrue(MasterDataManagementSetupPage."Source Environment Name".Visible(), 'Cross-environment source environment field should be visible.');
        Assert.IsTrue(MasterDataManagementSetupPage."Source Company Name".Visible(), 'Cross-environment source company field should be visible.');
        Assert.IsFalse(MasterDataManagementSetupPage."Company Name".Visible(), 'Same-environment source company field should be hidden.');

        MasterDataManagementSetupPage.Close();
    end;

    [Test]
    [HandlerFunctions('SynchronizationEnabledMessageHandler,ConfirmHandlerYes')]
    procedure DisableSetupKeepCouplingTable()
    var
        MasterDataManagementSetup: Record "Master Data Management Setup";
        MasterDataMgtCoupling: Record "Master Data Mgt. Coupling";
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        JobQueueEntry: Record "Job Queue Entry";
        MasterDataMgtSetupTests: Codeunit "Master Data Mgt. Setup Tests";
        MasterDataMgtSynchTests: Codeunit "Master Data Mgt. Synch. Tests";
        EmptyGuid: Guid;
    begin
        Initialize();
        MasterDataManagementSetup.Init();
        MasterDataManagementSetup."Company Name" := CopyStr(LibraryRandom.RandText(30), 1, MaxStrLen(MasterDataManagementSetup."Company Name"));
        MasterDataManagementSetup.Validate("Is Enabled", true);
        BindSubscription(MasterDataMgtSetupTests);
        BindSubscription(MasterDataMgtSynchTests);
        MasterDataManagementSetup.Insert(true);
        UnbindSubscription(MasterDataMgtSetupTests);
        UnbindSubscription(MasterDataMgtSynchTests);

        // insert a dummy coupling
        MasterDataMgtCoupling."Integration System ID" := EmptyGuid;
        MasterDataMgtCoupling."Local System ID" := EmptyGuid;
        MasterDataMgtCoupling.Insert();

        LibraryVariableStorage.Enqueue('keep the table setup and coupling');
        MasterDataManagementSetup.Validate("Is Enabled", false);
        BindSubscription(MasterDataMgtSetupTests);
        MasterDataManagementSetup.Modify(true);
        UnbindSubscription(MasterDataMgtSetupTests);

        // mappings are deleted, job queue entries are on hold, the coupling was kept
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Integration Synch. Job Runner");
        JobQueueEntry.SetRange("Recurring Job", true);
        JobQueueEntry.SetFilter(Status, '<>' + Format(JobQueueEntry.Status::"On Hold"));
        Assert.AreEqual(0, JobQueueEntry.Count(), '');
        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::"Master Data Management");
        Assert.IsTrue(IntegrationTableMapping.Count() > 0, '');
        Assert.IsTrue(IntegrationFieldMapping.Count() > 0, '');
        Assert.AreEqual(1, MasterDataMgtCoupling.Count(), '');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SynchronizationEnabledMessageHandler,ConfirmHandlerYes')]
    procedure ResetConfigurationResetsDefaults()
    var
        MasterDataManagementSetup: Record "Master Data Management Setup";
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        JobQueueEntry: Record "Job Queue Entry";
        MasterDataMgtSetupTests: Codeunit "Master Data Mgt. Setup Tests";
        MasterDataManagementSetupPage: TestPage "Master Data Management Setup";
    begin
        Initialize();
        MasterDataManagementSetup.Init();
        MasterDataManagementSetup."Company Name" := CopyStr(LibraryRandom.RandText(30), 1, MaxStrLen(MasterDataManagementSetup."Company Name"));
        MasterDataManagementSetup.Validate("Is Enabled", true);
        BindSubscription(MasterDataMgtSetupTests);
        MasterDataManagementSetup.Insert(true);
        UnbindSubscription(MasterDataMgtSetupTests);

        // mappings and job queue entries are deleted
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Integration Synch. Job Runner");
        JobQueueEntry.SetRange("Recurring Job", true);
        JobQueueEntry.DeleteAll();
        IntegrationFieldMapping.DeleteAll();
        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::"Master Data Management");
        IntegrationTableMapping.DeleteAll();

        // reset configuration
        MasterDataManagementSetupPage.OpenEdit();
        LibraryVariableStorage.Enqueue('restore the default synchronization table setup');
        MasterDataManagementSetupPage.ResetConfiguration.Invoke();
        VerifyDefaultSetup();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SynchronizationEnabledMessageHandler')]
    procedure ExportImportSetup()
    var
        MasterDataManagementSetup: Record "Master Data Management Setup";
        IntegrationTableMapping: Record "Integration Table Mapping";
        JobQueueEntry: Record "Job Queue Entry";
        MasterDataMgtSetupTests: Codeunit "Master Data Mgt. Setup Tests";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
    begin
        Initialize();
        MasterDataManagementSetup.Init();
        MasterDataManagementSetup."Company Name" := CopyStr(LibraryRandom.RandText(30), 1, MaxStrLen(MasterDataManagementSetup."Company Name"));
        MasterDataManagementSetup.Validate("Is Enabled", true);
        BindSubscription(MasterDataMgtSetupTests);
        MasterDataManagementSetup.Insert(true);
        UnbindSubscription(MasterDataMgtSetupTests);

        // export setup
        TempBlob.CreateOutStream(OutStr);
        XMLPORT.Export(XMLPORT::ExportMDMSetup, OutStr);
        TempBlob.CreateInStream(InStr, TEXTENCODING::UTF16);

        // mappings and job queue entries are deleted
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Integration Synch. Job Runner");
        JobQueueEntry.SetRange("Recurring Job", true);
        JobQueueEntry.DeleteAll();
        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::"Master Data Management");
        if IntegrationTableMapping.FindSet() then
            repeat
                IntegrationTableMapping.Delete(true);
            until IntegrationTableMapping.Next() = 0;

        // reimport setup
        XMLPORT.Import(XMLPORT::ImportMDMSetup, InStr);
        VerifyDefaultSetup();
    end;

    [Test]
    [HandlerFunctions('SynchronizationEnabledMessageHandler,TableObjectsHandler')]
    procedure SynchronizeAdditionalTable()
    var
        MasterDataManagementSetup: Record "Master Data Management Setup";
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        JobQueueEntry: Record "Job Queue Entry";
        MasterDataMgtSetupTests: Codeunit "Master Data Mgt. Setup Tests";
        TempBlob: Codeunit "Temp Blob";
        MasterDataSynchTables: TestPage "Master Data Synch. Tables";
        MasterDataSynchFields: TestPage "Master Data Synch. Fields";
        InStr: InStream;
        OutStr: OutStream;
    begin
        Initialize();
        MasterDataManagementSetup.Init();
        MasterDataManagementSetup."Company Name" := CopyStr(LibraryRandom.RandText(30), 1, MaxStrLen(MasterDataManagementSetup."Company Name"));
        MasterDataManagementSetup.Validate("Is Enabled", true);
        BindSubscription(MasterDataMgtSetupTests);
        MasterDataManagementSetup.Insert(true);
        UnbindSubscription(MasterDataMgtSetupTests);

        // Add one more table to synch
        MasterDataSynchTables.OpenEdit();
        LibraryVariableStorage.Enqueue(Database::"Activity Log");
        MasterDataSynchFields.Trap();
        MasterDataSynchTables.New();
        MasterDataSynchTables.TableCaptionValue.AssistEdit();
        MasterDataSynchFields.Close();

        // export setup
        TempBlob.CreateOutStream(OutStr);
        XMLPORT.Export(XMLPORT::ExportMDMSetup, OutStr);
        TempBlob.CreateInStream(InStr, TEXTENCODING::UTF16);

        // mappings and job queue entries are deleted
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Integration Synch. Job Runner");
        JobQueueEntry.SetRange("Recurring Job", true);
        JobQueueEntry.DeleteAll();
        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::"Master Data Management");
        if IntegrationTableMapping.FindSet() then
            repeat
                IntegrationTableMapping.Delete(true);
            until IntegrationTableMapping.Next() = 0;

        // reimport setup and verify that the additional table and field mappings are also there
        XMLPORT.Import(XMLPORT::ImportMDMSetup, InStr);
        VerifyDefaultSetup();
        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::"Master Data Management");
        IntegrationTableMapping.SetRange("Table ID", Database::"Activity Log");
        IntegrationTableMapping.SetRange("Integration Table ID", Database::"Activity Log");
        IntegrationTableMapping.SetRange("Delete After Synchronization", false);
        Assert.AreEqual(1, IntegrationTableMapping.Count(), 'Expected a synchronization table for Activity Log table');
        IntegrationTableMapping.FindFirst();
        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", IntegrationTableMapping.Name);
        Assert.IsTrue(IntegrationFieldMapping.Count() > 0, 'Expected synchronization fields for the added table (Activity Log).');
        IntegrationFieldMapping.SetRange(Status, IntegrationFieldMapping.Status::Enabled);
        Assert.IsTrue(IntegrationFieldMapping.Count() = 0, 'All synchronization fields for the added table should be disabled by default.');
        IntegrationFieldMapping.SetRange(Status);
        IntegrationFieldMapping.SetRange("Field Caption", '');
        Assert.IsTrue(IntegrationFieldMapping.Count() = 0, 'All synchronization fields for the added table should have a caption.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SynchronizationEnabledMessageHandler,ConfirmHandlerNo')]
    procedure DisableSetupDeleteCouplingTable()
    var
        MasterDataManagementSetup: Record "Master Data Management Setup";
        MasterDataMgtCoupling: Record "Master Data Mgt. Coupling";
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        JobQueueEntry: Record "Job Queue Entry";
        MasterDataMgtSetupTests: Codeunit "Master Data Mgt. Setup Tests";
        MasterDataMgtSynchTests: Codeunit "Master Data Mgt. Synch. Tests";
        EmptyGuid: Guid;
    begin
        Initialize();
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Integration Synch. Job Runner");
        JobQueueEntry.DeleteAll();
        MasterDataManagementSetup.Init();
        MasterDataManagementSetup."Company Name" := CopyStr(LibraryRandom.RandText(30), 1, MaxStrLen(MasterDataManagementSetup."Company Name"));
        MasterDataManagementSetup.Validate("Is Enabled", true);
        BindSubscription(MasterDataMgtSetupTests);
        BindSubscription(MasterDataMgtSynchTests);
        MasterDataManagementSetup.Insert(true);
        UnbindSubscription(MasterDataMgtSetupTests);
        UnbindSubscription(MasterDataMgtSynchTests);

        // insert a dummy coupling
        MasterDataMgtCoupling."Integration System ID" := EmptyGuid;
        MasterDataMgtCoupling."Local System ID" := EmptyGuid;
        MasterDataMgtCoupling.Insert();

        LibraryVariableStorage.Enqueue('keep the table setup and coupling');
        MasterDataManagementSetup.Validate("Is Enabled", false);
        BindSubscription(MasterDataMgtSetupTests);
        MasterDataManagementSetup.Modify(true);
        UnbindSubscription(MasterDataMgtSetupTests);

        // mappings are deleted, job queue entries are on hold, the coupling was deleted
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Integration Synch. Job Runner");
        JobQueueEntry.SetRange("Recurring Job", true);
        JobQueueEntry.SetFilter(Status, '<>' + Format(JobQueueEntry.Status::"On Hold"));
        Assert.AreEqual(0, JobQueueEntry.Count(), '');
        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::"Master Data Management");
        Assert.AreEqual(0, IntegrationTableMapping.Count(), '');
        Assert.AreEqual(0, IntegrationFieldMapping.Count(), '');
        Assert.AreEqual(0, MasterDataMgtCoupling.Count(), '');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure NoDuplicatesAddedToSetupOnSelectingTableWithCyclicReference()
    var
        SynchTables: List of [Integer];
        RelatedTablesToAdd: List of [Integer];
        TablesToAddText: Text;
    begin
        // [SCENARIO] When selecting a table that has a self-reference or other reference that create a cycle, duplicate records are not added to the setup list

        Initialize();

        LibraryMasterDataMgt.FindRelatedTables(SynchTables, RelatedTablesToAdd, TablesToAddText, Database::"MDM Test Table A");

        Assert.AreEqual(1, RelatedTablesToAdd.Count, IncorrectTablesListErr);
        Assert.IsTrue(RelatedTablesToAdd.Contains(Database::"MDM Test Table B"), IncorrectTablesListErr);
    end;

    [Test]
    [HandlerFunctions('SynchronizationEnabledMessageHandler')]
    procedure SavingEnabledSetupAgainDoesNotAskToResetConfiguration()
    var
        MasterDataManagementSetup: Record "Master Data Management Setup";
        IntegrationTableMapping: Record "Integration Table Mapping";
        MasterDataMgtSetupTests: Codeunit "Master Data Mgt. Setup Tests";
        MappingCount: Integer;
    begin
        // [FEATURE] [Master Data Management] [Setup]
        // [SCENARIO] Saving an enabled setup again without changing whether it is enabled, as the setup page does after the
        //            connection wizard enabled synchronization, does not enable it again and does not ask to reset the
        //            synchronization tables that enabling just created.
        Initialize();
        DeleteSynchJobQueueEntries();

        // [GIVEN] an enabled setup, which created the default synchronization tables
        MasterDataManagementSetup.Init();
        MasterDataManagementSetup."Company Name" := CopyStr(LibraryRandom.RandText(30), 1, MaxStrLen(MasterDataManagementSetup."Company Name"));
        MasterDataManagementSetup.Validate("Is Enabled", true);
        BindSubscription(MasterDataMgtSetupTests);
        MasterDataManagementSetup.Insert(true);
        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::"Master Data Management");
        MappingCount := IntegrationTableMapping.Count();
        Assert.IsTrue(MappingCount > 0, 'Precondition: enabling should create the default synchronization tables');

        // [WHEN] the enabled setup is read again and saved
        MasterDataManagementSetup.Get();
        MasterDataManagementSetup.Modify(true); // an unhandled confirmation fails the test

        // [THEN] the synchronization tables are kept and the setup stays enabled
        UnbindSubscription(MasterDataMgtSetupTests);
        Assert.AreEqual(MappingCount, IntegrationTableMapping.Count(), 'The synchronization tables should be kept');
        MasterDataManagementSetup.Get();
        Assert.IsTrue(MasterDataManagementSetup."Is Enabled", 'The setup should stay enabled');

        DeleteSynchJobQueueEntries();
    end;

    [Test]
    procedure SavingDisabledSetupDoesNotAskToKeepCouplings()
    var
        MasterDataManagementSetup: Record "Master Data Management Setup";
        MasterDataMgtCoupling: Record "Master Data Mgt. Coupling";
        MasterDataMgtSetupTests: Codeunit "Master Data Mgt. Setup Tests";
    begin
        // [FEATURE] [Master Data Management] [Setup]
        // [SCENARIO] Saving a disabled setup, as the connection wizard does on Test Connection and Finish, does not disable it
        //            again and does not ask whether to keep the couplings.
        Initialize();

        // [GIVEN] a disabled setup with an existing coupling
        BindSubscription(MasterDataMgtSetupTests);
        MasterDataManagementSetup.Init();
        MasterDataManagementSetup."Company Name" := CopyStr(LibraryRandom.RandText(30), 1, MaxStrLen(MasterDataManagementSetup."Company Name"));
        MasterDataManagementSetup.Insert(true);
        MasterDataMgtCoupling."Integration System ID" := CreateGuid();
        MasterDataMgtCoupling."Local System ID" := CreateGuid();
        MasterDataMgtCoupling.Insert();

        // [WHEN] the disabled setup is saved
        MasterDataManagementSetup.Get();
        MasterDataManagementSetup.Modify(true); // an unhandled confirmation fails the test
        UnbindSubscription(MasterDataMgtSetupTests);

        // [THEN] the coupling is kept
        Assert.AreEqual(1, MasterDataMgtCoupling.Count(), 'The coupling should be kept');
    end;

    [Test]
    procedure ImportSetupRejectsSystemTable()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        MasterDataMgtSetupDefault: Codeunit "Master Data Mgt. Setup Default";
        FieldNumbers: List of [Integer];
        SetupXml: Text;
    begin
        // [FEATURE] [Master Data Management] [Setup] [Security]
        // [SCENARIO 660382] Import Setup applies the same table checks as Add Table, so a crafted setup file can't add a
        //                   system table to the synchronization, neither as an updated nor as a new synchronization table.
        Initialize();
        // [GIVEN] a setup file whose synchronization table was changed to a system table
        MasterDataMgtSetupDefault.GenerateIntegrationTableMapping(IntegrationTableMapping, FieldNumbers, 'MDM_SYSTEMTABLE', Database::"Payment Terms", '', false, false);
        SetupXml := ExportSetup();
        SetupXml := SetupXml.Replace(StrSubstNo(TableIdAttributeTxt, Database::"Payment Terms"), StrSubstNo(TableIdAttributeTxt, Database::User));
        SetupXml := SetupXml.Replace(StrSubstNo(IntegrationTableIdAttributeTxt, Database::"Payment Terms"), StrSubstNo(IntegrationTableIdAttributeTxt, Database::User));
        Assert.IsTrue(StrPos(SetupXml, StrSubstNo(TableIdAttributeTxt, Database::User)) > 0, 'Precondition: the setup file should reference the system table');

        // [WHEN] the file updates the existing synchronization table [THEN] the import is rejected
        asserterror ImportSetup(SetupXml);
        Assert.ExpectedError(SystemTableErr);
        IntegrationTableMapping.Get('MDM_SYSTEMTABLE');
        Assert.AreEqual(Database::"Payment Terms", IntegrationTableMapping."Table ID", 'The synchronization table must not be changed to a system table');

        // [WHEN] the file adds the system table as a new synchronization table [THEN] the import is rejected
        IntegrationTableMapping.Delete(true);
        asserterror ImportSetup(SetupXml);
        Assert.ExpectedError(SystemTableErr);
        Assert.IsFalse(IntegrationTableMapping.Get('MDM_SYSTEMTABLE'), 'The system table must not be added');
    end;

    [Test]
    procedure GenerateMappingRejectsSystemTable()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        MasterDataMgtSetupDefault: Codeunit "Master Data Mgt. Setup Default";
        FieldNumbers: List of [Integer];
    begin
        // [FEATURE] [Master Data Management] [Setup] [Security]
        // [SCENARIO 660382] Generating a synchronization table for a system table is refused, whoever calls it.
        Initialize();

        // [WHEN] a synchronization table is generated for a system table [THEN] it is refused
        asserterror MasterDataMgtSetupDefault.GenerateIntegrationTableMapping(IntegrationTableMapping, FieldNumbers, 'MDM_SYSTEMTABLE', Database::User, '', false, false);
        Assert.ExpectedError(SystemTableErr);
        Assert.IsFalse(IntegrationTableMapping.Get('MDM_SYSTEMTABLE'), 'The system table must not be added');
    end;

    [Test]
    [HandlerFunctions('TableObjectsExcludesSystemTablesHandler')]
    procedure AddTableDoesNotOfferSystemTables()
    var
        MasterDataSynchTables: TestPage "Master Data Synch. Tables";
    begin
        // [FEATURE] [Master Data Management] [Setup] [Security] [UI]
        // [SCENARIO 660382] The Add Table picker on Synchronization Tables doesn't offer system tables.
        Initialize();

        // [WHEN] the user adds a table to the synchronization
        MasterDataSynchTables.OpenEdit();
        MasterDataSynchTables.New();
        MasterDataSynchTables.TableCaptionValue.AssistEdit();

        // [THEN] the table picker excludes system tables (verified in TableObjectsExcludesSystemTablesHandler)
        MasterDataSynchTables.Close();
    end;

    local procedure ExportSetup() SetupXml: Text
    var
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
        Line: Text;
    begin
        TempBlob.CreateOutStream(OutStr);
        XMLPORT.Export(XMLPORT::ExportMDMSetup, OutStr);
        TempBlob.CreateInStream(InStr, TEXTENCODING::UTF16);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            SetupXml += Line + ' ';
        end;
    end;

    local procedure ImportSetup(SetupXml: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
    begin
        TempBlob.CreateOutStream(OutStr, TEXTENCODING::UTF16);
        OutStr.WriteText(SetupXml);
        TempBlob.CreateInStream(InStr, TEXTENCODING::UTF16);
        XMLPORT.Import(XMLPORT::ImportMDMSetup, InStr);
    end;

    local procedure DeleteSynchJobQueueEntries()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Integration Synch. Job Runner");
        JobQueueEntry.DeleteAll();
    end;

    local procedure Initialize()
    var
        MasterDataManagementSetup: Record "Master Data Management Setup";
        IntegrationTableMapping: Record "Integration Table Mapping";
        MasterDataMgtCoupling: Record "Master Data Mgt. Coupling";
        MasterDataMgtSubscriber: Record "Master Data Mgt. Subscriber";
        MasterDataMgtSynchTests: Codeunit "Master Data Mgt. Synch. Tests";
    begin
        OnBeforeInitialize(InitializeHandled);
        if InitializeHandled then
            exit;

        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();

        BindSubscription(MasterDataMgtSynchTests);
        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::"Master Data Management");
        if IntegrationTableMapping.FindSet() then
            repeat
                IntegrationTableMapping.Delete(true);
            until IntegrationTableMapping.Next() = 0;
        MasterDataMgtCoupling.DeleteAll();
        MasterDataManagementSetup.DeleteAll();
        MasterDataMgtSubscriber.DeleteAll();
        UnbindSubscription(MasterDataMgtSynchTests);
        Commit();
        OnAfterInitialize(InitializeHandled);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Master Data Management", 'OnAddSubsidiarySubscriptionToMasterCompany', '', false, false)]
    local procedure HandleOnAddSubsidiarySubscriptionToMasterCompany(MasterCompanyName: Text[30]; SubsidiaryCompanyName: Text[30]; var IsHandled: Boolean)
    var
        MasterDataMgtSubscriber: Record "Master Data Mgt. Subscriber";
    begin
        MasterDataMgtSubscriber.Init();
        MasterDataMgtSubscriber."Company Name" := SubsidiaryCompanyName;
        if MasterDataMgtSubscriber.Insert() then;
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Master Data Management", 'OnRemoveSubsidiarySubscriptionFromMasterCompany', '', false, false)]
    local procedure HandleOnRemoveSubsidiarySubscriptionFromMasterCompany(MasterCompanyName: Text[30]; SubsidiaryCompanyName: Text[30]; var IsHandled: Boolean)
    var
        MasterDataMgtSubscriber: Record "Master Data Mgt. Subscriber";
    begin
        MasterDataMgtSubscriber.SetRange("Company Name", SubsidiaryCompanyName);
        MasterDataMgtSubscriber.DeleteAll();
        IsHandled := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    internal procedure TableObjectsHandler(var TableObjects: TestPage "Table Objects")
    var
        TableNo: Variant;
        TableID: Text;
    begin
        LibraryVariableStorage.Dequeue(TableNo);
        TableID := Format(TableNo);
        TableObjects.FILTER.SetFilter("Object ID", TableID);
        TableObjects.Last();
        TableObjects.OK().Invoke();
    end;

    [ModalPageHandler]
    internal procedure TableObjectsExcludesSystemTablesHandler(var TableObjects: TestPage "Table Objects")
    begin
        Assert.IsTrue(StrPos(TableObjects.Filter.GetFilter("Object ID"), '<2000000000') = 1, 'The table picker should exclude system tables');
        TableObjects.Cancel().Invoke();
    end;

    [ConfirmHandler]
    internal procedure ConfirmHandlerYes(Question: Text; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, LibraryVariableStorage.DequeueText()) > 0, StrSubstNo(UnexpectedConfirmErr, Question));
        Reply := true;
    end;

    [ConfirmHandler]
    internal procedure ConfirmHandlerNo(Question: Text; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, LibraryVariableStorage.DequeueText()) > 0, StrSubstNo(UnexpectedConfirmErr, Question));
        Reply := false;
    end;

    [ConfirmHandler]
    internal procedure ExitNotEnabledConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        // The setup page asks to confirm closing while synchronization is not enabled; accept to let the page close.
        Reply := true;
    end;

    [MessageHandler]
    procedure SynchronizationEnabledMessageHandler(Message: Text)
    begin
        if StrPos(Message, 'is enabled') <> 0 then
            exit;
        if StrPos(Message, 'default setup') <> 0 then
            exit;
        Assert.Fail(StrSubstNo('Unexpected message: %1', Message));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitialize(var InitializeHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitialize(var InitializeHandled: Boolean)
    begin
    end;
}
